#!/usr/bin/env python3
"""gen-spec-section.py - regenerate the "NEW IN v<version>" section of
specs/claude-code-api-complete.http from the extracted route table.

Why this exists: the section is ~1,700 lines of request blocks derived
mechanically from extractions/v<ver>/raw/routes.tsv. Hand-maintaining that is
how a spec drifts; hand-*reviewing* it is how a reviewer stops reading. This
script is the provenance for those lines -- delete the section, re-run, and you
get the same bytes back.

What is generated vs. authored:

  generated   the request block for each route: method, URL, the header set
              implied by its auth mode, and a comment line carrying
              source / beta / auth / timeout as read from the call site
  authored    FAMILIES below -- the grouping and the prose for each family.
              That is judgement and belongs to a human; edit it here, not in
              the .http file, or the next run drops your edit.

Routes whose call site has its own baseURL (an OAuth server, an SSE relay) are
skipped: rendering them as {{baseUrl}}/revoke would be wrong.

Paths whose method could not be read are emitted as `# PATH-ONLY` lines rather
than guessed; validate-spec.sh counts those as documented and they claim
nothing but existence.

Idempotent: re-running replaces the section in place. Run validate-spec.sh
afterwards -- this script does not gate anything by itself.

Usage:
  scripts/gen-spec-section.py <version> <literals-file>
    version        e.g. 2.1.234; reads extractions/v<version>/raw/routes.tsv
    literals-file  output of scripts/binary-literals.sh, used to find the
                   paths that still need a PATH-ONLY declaration
"""
import argparse
import os
import re
import subprocess
import sys

ap = argparse.ArgumentParser()
ap.add_argument("version")
ap.add_argument("literals")
args = ap.parse_args()

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

VERSION = args.version
LITERALS = args.literals
ROUTES = f"extractions/v{VERSION}/raw/routes.tsv"
if not os.path.exists(ROUTES):
    sys.exit(f"no route table: {ROUTES} (run scripts/extract-routes.py first)")

SPEC = "specs/claude-code-api-complete.http"
spec = open(SPEC).read()

# Drop any previous copy of this section first. `have` below must reflect the
# hand-written spec only -- computed against a spec that still contains the
# generated section, every route reads as already-documented and the rerun
# produces nothing.
_old = re.search(r"\n### =+\n### SECTION 42: NEW IN v[0-9.]+\n.*?(?=### =+\n### SECTION 43)",
                 spec, re.S)
if _old:
    spec = spec[:_old.start() + 1] + spec[_old.end():]
    open(SPEC, "w").write(spec)

def spec_paths():
    raw=re.findall(r'^(?:GET|POST|PUT|PATCH|DELETE|HEAD) \{\{[^}]+\}\}(/[^ \n]+)', spec, re.M)
    out=set()
    for r in raw:
        r=r.split("?")[0]
        out.add(re.sub(r'\{\{[^}]*\}\}', '.*', r))
    return out
have=spec_paths()

def norm(path):
    return path.split("?")[0].replace("{param}", ".*")

rows=[l.rstrip("\n").split("\t") for l in open(ROUTES)][1:]
# Only routes whose host is the Anthropic API base belong in this file. A few
# axios instances carry their own baseURL (an OAuth server, an SSE relay); their
# relative paths would render as {{baseUrl}}/revoke, which is wrong.
KEEP = ("/api/", "/v1/", "/mcp-registry/", "/worker/")
rows=[r for r in rows if "${" not in r[1] and r[1].startswith(KEEP)]
missing=[r for r in rows if norm(r[1]) not in have]

FAMILIES = [
  ("Frames (publish / read / comment)", "/api/frame", """The Artifact publishing surface. Two axios instances with different base URLs
are in play; a `relayProbe` option lets a request fall through to a frame relay,
which is why an upload can come back 429 with `retry-after` and be retried once
against the same path."""),
  ("Self-hosted runner pool", "/v1/code/runners/self-hosted", """Runner registration, spawn-hint polling and session release for the
SELF_HOSTED_RUNNER_* deployment mode added in v2.1.234. Long-poll endpoints use
a 30s timeout; the rest 15s."""),
  ("Worker / session bridge", "/v1/code/sessions", """Worker registration, heartbeat, diagnostics and file sync for a remote
session. The `/worker/*` paths are the same protocol against the worker's own
base URL, authenticating with `session-jwt`."""),
  ("Environment bridge", "/v1/environments", """Two coexisting shapes: the Stainless SDK resource (`?beta=true`, pinned to
managed-agents-2026-04-01) and a plain axios path with no beta flag used by the
bridge process itself."""),
  ("MCP tunnels", "/v1/tunnels", "Tunnel and certificate lifecycle. Every route pins mcp-tunnels-2026-06-22."),
  ("Dreams", "/v1/dreams", "Background 'dreaming' runs. Every route pins dreaming-2026-04-21."),
  ("Deployments and deployment runs", "/v1/deployment", "Managed-agent deployments and their runs. Pins managed-agents-2026-04-01."),
  ("Design (Claude Design integration)", "/v1/design", """Consent and grant management plus an MCP handshake. `/v1/design/mcp` is
`auth: "none"` with a 60s timeout -- it carries its own grant token. The
consent GET is a pre-flight; on failure the client falls back to a 403-seeded
cache rather than blocking."""),
  ("Ultrareview", "/v1/ultrareview", """Quota and preflight for `/code-review ultra`. Both are `auth: "teleport-org"`.
`CLAUDE_CODE_ULTRAREVIEW_QUOTA_FIXTURE`, when set, is parsed as JSON and
returned instead -- no request is made."""),
  ("Code triggers", "/v1/code/triggers", """Scheduled and webhook triggers. `auth: "teleport-org"`; the run call allows
20s. Observed live with anthropic-beta: ccr-triggers-2026-01-30."""),
  ("Code webhook triggers", "/v1/code/webhook-triggers", "Webhook trigger registration."),
  ("Local / org memory", "/v1/code/local/memory", "Org memory mount discovery and credential exchange."),
  ("Agent proxy", "/v1/code/agent-proxy", "Artifact and frame proxying for agent-side fetches."),
  ("SCM connectors", "/v1/code/scm-connectors", "Source-control connector registration and per-connector tunnels."),
  ("Memory stores", "/v1/memory_stores", "Agent memory stores, memories and versions. Every route pins agent-memory-2026-07-22."),
  ("Vaults and credentials", "/v1/vaults", """Credential vaults, including an MCP OAuth validation call. Pins
managed-agents-2026-04-01."""),
  ("User profiles", "/v1/user_profiles", "User profile resources. Pins user-profiles-2026-03-24."),
  ("Managed sessions: resources and threads", "/v1/sessions", "Session resources and threads. Pins managed-agents-2026-04-01."),
  ("Agents (new routes)", "/v1/agents", "Archive and version listing added alongside the existing agent CRUD."),
  ("Skills (new routes)", "/v1/skills", "Version content and per-version delete/read."),
  ("Files / messages (new routes)", "/v1/files", "File content download, batch cancel."),
  ("Messages (new routes)", "/v1/messages", "Batch cancel, in both beta and non-beta form."),
  ("Environment providers", "/v1/environment_providers", "Cloud environment creation."),
  ("MCP registry and connector directory", "/api/directory", 'Public server directory; `auth: "none"`, 5s timeout.'),
  ("MCP registry", "/mcp-registry", 'Unauthenticated, cursor-paginated server registry; `auth: "none"`, 5s timeout.'),
  ("Plugin and skill discovery", "/api/oauth/organizations/:orgUUID/plugin", "Marketplace search, ratings and appearance outcome reporting."),
  ("Org onboarding, projects and devices", "/api/organizations", "Onboarding steps, project docs/files and cowork remote devices."),
  ("Auth and device trust", "/api/auth", "Trusted-device registration."),
  ("CLI bootstrap", "/api/claude_cli/bootstrap", "Per-model bootstrap payload fetched at startup; observed live."),
  ("OAuth token validation and CRI", "/api/oauth/validate", """Scope check used by Claude in Chrome: the token must carry user:profile,
user:office or user:ccr_inference. env-var and setup-token sessions default to
user:inference only, which this endpoint rejects."""),
]
AUTH_HDRS = {
 "teleport-org": ["Authorization: Bearer {{accessToken}}","Content-Type: application/json","anthropic-version: {{version}}","anthropic-client-platform: {{clientPlatform}}","x-organization-uuid: {{orgUuid}}"],
 "session-jwt": ["Authorization: Bearer {{sessionToken}}"],
 "claude-ai-oauth": ["Authorization: Bearer {{accessToken}}","anthropic-beta: {{oauthBeta}}"],
 "none": ["Accept: application/json"],
 "": ["Authorization: Bearer {{accessToken}}","anthropic-beta: {{oauthBeta}}"],
 "async": ["Authorization: Bearer {{accessToken}}","anthropic-beta: {{oauthBeta}}"],
}
out=["", "### ============================================================================",
 f"### SECTION 42: NEW IN v{VERSION}",
 "### ============================================================================", "#",
 "# Generated by scripts/gen-spec-section.py from",
 f"# {ROUTES}, which reads the method,",
 "# path, beta flag, auth mode and timeout straight from the call site in the",
 "# v2.1.234 binary. Re-verify any entry with:",
 "#   scripts/extract-calls.py <binary> out/ && less out/<family>.txt",
 "#",
 "# Auth mode -> header set is in the file header. A route with no auth mode is",
 "# an SDK resource: the client supplies auth, the resource pins the beta flag.",
 ""]
seen=set()
def emit(fam):
    for meth,path,beta,auth,to,src in sorted(fam, key=lambda r:(r[1],r[0])):
        p=path.replace("{param}","{{id}}")
        bits=[f"source={src}"]
        if beta: bits.append(f"beta={beta}")
        if auth: bits.append(f'auth="{auth}"')
        if to: bits.append(f"timeout={to}ms")
        out.append("# " + "  ".join(bits))
        out.append(f"{meth} {{{{baseUrl}}}}{p}")
        hdrs = AUTH_HDRS.get(auth, AUTH_HDRS[""]) if src=="axios" else (
            ["Authorization: Bearer {{accessToken}}","Content-Type: application/json",
             "anthropic-version: {{version}}"] + ([f"anthropic-beta: {beta}"] if beta else []))
        out.extend(hdrs)
        out.append("User-Agent: " + ("claude-cli/{{cliVersion}} (external, cli)" if src=="axios" else "claude-code/{{cliVersion}}"))
        out.append("")

for title, prefix, blurb in FAMILIES:
    fam=[r for r in missing if r[1].startswith(prefix) and (r[0],r[1]) not in seen]
    if not fam: continue
    for r in fam: seen.add((r[0],r[1]))
    out.append("### ----------------------------------------------------------------------------")
    out.append(f"### {title}")
    out.append("### ----------------------------------------------------------------------------")
    out += ["# "+l for l in blurb.strip().split("\n")]
    out.append("")
    emit(fam)
    out.append("")

rest=[r for r in missing if (r[0],r[1]) not in seen]
if rest:
    out.append("### ----------------------------------------------------------------------------")
    out.append("### Other v2.1.234 routes")
    out.append("### ----------------------------------------------------------------------------")
    out.append("# Method, beta flag, auth mode and timeout verified; no prose written yet.")
    out.append("")
    emit(rest)
    out.append("")

# Path literals with no recognised call site: the path is verified to exist in
# the binary, the method is not. Declared with PATH-ONLY so the validator counts
# them as documented without this file claiming a method it has not read.
import subprocess
undoc = subprocess.run(
    ["./scripts/validate-spec.sh", "--routes", ROUTES,
     LITERALS, SPEC],
    capture_output=True, text=True).stdout
block = undoc.split("=== UNDOCUMENTED")[-1].split("=== PHANTOM")[0]
paths = [l.strip() for l in block.splitlines() if l.startswith("/")]
# Anything this run is about to document with a real method does not need a
# PATH-ONLY declaration; keeping both understates what we know.
about_to_document = {norm(r[1]) for r in missing}
paths = [x for x in paths if x not in about_to_document]
if paths:
    out.append("### ----------------------------------------------------------------------------")
    out.append("### Path literals verified, method not recovered")
    out.append("### ----------------------------------------------------------------------------")
    out.append("# These path strings are present in the v2.1.234 binary but the call site")
    out.append("# builds them through a helper that scripts/extract-routes.py does not follow,")
    out.append("# so the method is unknown. Recorded with PATH-ONLY rather than guessed: the")
    out.append("# validator counts a PATH-ONLY line as documented, and it makes no claim about")
    out.append("# method, headers or body.")
    out.append("#")
    for path in paths:
        out.append(f"# PATH-ONLY {{{{baseUrl}}}}{path}")
    out.append("")

txt="\n".join(out)
marker = "### ============================================================================\n### SECTION 43: OBSERVED TRAFFIC"
i = spec.find(marker)
# Normalise the seam so repeated runs are byte-stable: exactly one blank line
# either side of the generated block. Without this each rerun accreted a
# newline and the file was never quite idempotent.
spec = spec[:i].rstrip("\n") + "\n\n" + txt.strip("\n") + "\n\n" + spec[i:]
open(SPEC,"w").write(spec)
print(f"documented {len(seen)} grouped + {len(rest)} other = {len(missing)} new routes", file=sys.stderr)
print(f"PATH-ONLY declarations: {len(paths)}", file=sys.stderr)
