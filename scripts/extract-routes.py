#!/usr/bin/env python3
"""extract-routes.py - method + path + beta flag for every HTTP call site.

`extract-binary.sh` recovers *path literals* from the constant pool. That tells
you an endpoint exists; it does not tell you the method, and getting a method
wrong is the most damaging kind of error in a spec.

The compiled binary embeds the whole minified bundle as printable text, so the
call sites themselves are readable. Two client shapes cover the surface:

  Stainless SDK       this._client.post(Fa`/v1/tunnels/${e}/certificates?...`, {
                        body: o, ...r,
                        headers: yi([{"anthropic-beta": [...n ?? [], "mcp-tunnels-2026-06-22"]...
  axios instance      fs.get(`${BASE_API_URL}/api/oauth/usage`, { headers: ... })

Both give method, path and (for the SDK) the beta flag the resource pins.
Neither depends on a minified identifier: the SDK shape is anchored on the
literal `_client.`, and the axios variable is detected as the identifier that
most often precedes a `/api/` or `/v1/` call.

Interpolations are normalised to `{param}` so paths are stable across builds
(`${e}` and `${encodeURIComponent(t)}` both become `{param}`).

Usage:
  extract-routes.py <binary> [--sdk out.tsv] [--axios out.tsv] [--all out.tsv]

Output columns: method, path, beta_flag, source
"""
import argparse
import re
import sys
from collections import Counter, OrderedDict

SDK_RE = re.compile(
    r"_client\.(get|post|put|patch|delete|head|getAPIList)\("
    r"\s*(?:[A-Za-z0-9_$]{0,4})?[`\"']([^`\"'\n]{1,200}?)[`\"']"
)
# Client-var candidates: <ident>.<method>( "<...>/api/..." | `${...}/api/...`
CANDIDATE_RE = re.compile(
    r"\b([A-Za-z0-9_$]{1,4})\.(?:get|post|put|patch|delete|head)\(\s*[`\"']"
    r"(?:[^`\"'\n]{0,24}\$\{[^}]*\}|https://[a-z.]+)?/(?:api|v1)/"
)
BETA_RE = re.compile(r'"anthropic-beta":.{0,140}?"([a-z][a-z0-9-]*-20\d\d-\d\d-\d\d)"')
# axios call sites name their auth mode; the mode decides the whole header set.
AUTH_RE = re.compile(r'auth:\s*"([a-z-]+)"')
# >=100 to skip unrelated small `timeout:` fields that fall inside the window;
# real HTTP timeouts here are milliseconds in the hundreds or thousands.
TIMEOUT_RE = re.compile(r'timeout:\s*([1-9]\d{2,})')
INTERP_RE = re.compile(r"\$\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}")
# Many paths are hoisted into a const first (`udf="/api/.../plugins/search"`)
# and the call site passes the identifier, so a literal-only scan misses them.
CONST_RE = re.compile(r"\b([A-Za-z0-9_$]{1,8})\s*=\s*[\"'](/(?:api|v1)/[^\"'\n]{1,160})[\"']")


def norm(path: str) -> str:
    """`${encodeURIComponent(e)}` -> `{param}`; strip a leading host/base."""
    path = INTERP_RE.sub("{param}", path)
    path = re.sub(r"^\{param\}", "", path)
    path = re.sub(r"^https://[^/]+", "", path)
    return path


def beta_after(data: str, pos: int, span: int = 600) -> str:
    m = BETA_RE.search(data, pos, pos + span)
    return m.group(1) if m else ""


def opts_after(data: str, pos: int, span: int = 300) -> tuple:
    """(auth mode, timeout ms) from the options object of an axios call."""
    win = data[pos:pos + span]
    a = AUTH_RE.search(win)
    t = TIMEOUT_RE.search(win)
    return (a.group(1) if a else "", t.group(1) if t else "")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("binary")
    ap.add_argument("--sdk")
    ap.add_argument("--axios")
    ap.add_argument("--all")
    args = ap.parse_args()

    data = open(args.binary, "rb").read().decode("latin-1")

    # ident -> path, for call sites that pass a hoisted constant. An identifier
    # bound to two different paths is ambiguous and is dropped rather than
    # guessed.
    consts, ambiguous = {}, set()
    for m in CONST_RE.finditer(data):
        ident, path = m.group(1), m.group(2)
        if ident in consts and consts[ident] != path:
            ambiguous.add(ident)
        consts[ident] = path
    for ident in ambiguous:
        consts.pop(ident, None)
    const_call = re.compile(
        r"(?:_client|\b[A-Za-z0-9_$]{1,4})\.(get|post|put|patch|delete|head|getAPIList)\("
        r"\s*(" + "|".join(re.escape(i) for i in sorted(consts, key=len, reverse=True)) + r")\s*[,)]"
    ) if consts else None

    sdk = OrderedDict()
    for m in SDK_RE.finditer(data):
        path = norm(m.group(2))
        if not path.startswith("/"):
            continue
        method = "GET" if m.group(1) == "getAPIList" else m.group(1).upper()
        sdk.setdefault((method, path), beta_after(data, m.end()))

    counts = Counter(m.group(1) for m in CANDIDATE_RE.finditer(data))
    clients = [v for v, n in counts.items() if n >= 3]
    axios = OrderedDict()
    if clients:
        pat = re.compile(
            r"\b(" + "|".join(re.escape(c) for c in clients) + r")"
            r"\.(get|post|put|patch|delete|head)\(\s*[`\"']([^`\"'\n]{1,200}?)[`\"']"
        )
        for m in pat.finditer(data):
            path = norm(m.group(3))
            if not path.startswith("/"):
                continue
            axios.setdefault(
                (m.group(2).upper(), path),
                (beta_after(data, m.end()),) + opts_after(data, m.end()),
            )

    if const_call is not None:
        for m in const_call.finditer(data):
            path = norm(consts[m.group(2)])
            method = "GET" if m.group(1) == "getAPIList" else m.group(1).upper()
            axios.setdefault(
                (method, path),
                (beta_after(data, m.end()),) + opts_after(data, m.end()),
            )

    print(f"path constants     : {len(consts)} resolved, {len(ambiguous)} ambiguous (dropped)",
          file=sys.stderr)
    print(f"SDK client calls   : {len(sdk)} routes", file=sys.stderr)
    print(f"axios clients      : {', '.join(sorted(clients)) or '(none detected)'}", file=sys.stderr)
    print(f"axios calls        : {len(axios)} routes", file=sys.stderr)

    # One row shape everywhere: method, path, beta, auth, timeout_ms, source.
    # SDK resources take auth from the client, not per call, so those columns
    # are empty rather than guessed.
    def rows_of(src):
        if src == "sdk":
            return [(m, p, b, "", "", "sdk") for (m, p), b in sdk.items()]
        return [(m, p, b, a, t, "axios") for (m, p), (b, a, t) in axios.items()]

    def dump(path, rows):
        if not path:
            return
        with open(path, "w") as f:
            f.write("method\tpath\tbeta\tauth\ttimeout_ms\tsource\n")
            for r in sorted(rows, key=lambda r: (r[1], r[0])):
                f.write("\t".join(r) + "\n")

    dump(args.sdk, rows_of("sdk"))
    dump(args.axios, rows_of("axios"))
    if args.all:
        merged = OrderedDict()
        for r in rows_of("sdk") + rows_of("axios"):
            merged.setdefault((r[0], r[1]), r)
        dump(args.all, list(merged.values()))
        print(f"merged             : {len(merged)} routes", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
