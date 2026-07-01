# claude-code-http-spec

> A version-tracked record of the HTTP API surface that the published
> `@anthropic-ai/claude-code` release talks to.

[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![version](https://img.shields.io/badge/documented-v2.1.197-success)](extractions/v2.1.197/SUMMARY.md)
[![deps](https://img.shields.io/badge/deps-strings%20%2B%20rg-blue)](scripts/)

This repo documents which API paths, beta flags, headers, OAuth scopes, and
model identifiers a given Claude Code release references, by reading the
**stable string literals** that ship inside the public npm package. It is
release documentation and compatibility tracking: every fact traces back to a
literal in a specific published version, and the extraction is deterministic
and re-runnable.

It does not call any Anthropic endpoint, and it stores no binaries or
credentials. The output is plain text you can diff across versions.

## Currently Documented

**v2.1.197** — see [extractions/v2.1.197/SUMMARY.md](extractions/v2.1.197/SUMMARY.md).
69 API paths, 45 beta flags. 12 paths and 3 beta flags added since v2.1.170.

The binary also embeds a complete, verbatim self-hosted gateway protocol
specification (`CLAUDE_CODE_USE_GATEWAY`) — not inferred, the literal ~9.6KB
Markdown doc the CLI ships internally. Recovered whole to
[extractions/v2.1.197/GATEWAY-PROTOCOL.md](extractions/v2.1.197/GATEWAY-PROTOCOL.md),
with a runnable request set at
[specs/claude-code-gateway.http](specs/claude-code-gateway.http).

Since v2.1.117 the release ships as a Bun-compiled binary rather than a
readable `cli.js`. String literals still live in the binary's constant pool,
so `strings` + `rg` remains the extraction method for paths, beta flags, model
IDs, and env-var names.

## What It Extracts

| Output | File | How |
|--------|------|-----|
| API paths | `extractions/v<ver>/raw/paths.txt` | quoted `"/api/..."` / `"/v1/..."` literals |
| Beta flags | `extractions/v<ver>/raw/beta_flags.txt` | tokens ending in a dated `YYYY-MM-DD` suffix |
| Call contexts | `extractions/v<ver>/calls/*.txt` | bounded windows around each endpoint literal |
| Headers / scopes / URLs | `extractions/v<ver>/raw/*.txt` | literal header names, `user:`/`org:` scopes, hardcoded URLs |
| Finalized reference | `specs/*.http` | curated, runnable HTTP-client requests built from the above |

## Confidence Model

What a literal can and cannot prove:

- **High confidence (literal present).** The string exists in this exact
  published version. A documented path/flag/scope is backed by a verifiable
  `rg` pattern against the release. This is the bar for everything in
  `raw/` and `specs/`.
- **Medium confidence (context-inferred).** Method, headers, and request body
  are read from the bounded text window around the literal (`calls/*.txt`).
  Minifier variable names in those windows are noise, not facts — they change
  every build and are never treated as documentation.
- **Not claimed.** Anything seen only at runtime, anything inferred from logs,
  and anything that cannot be reproduced with a literal pattern. If it is not
  in a release string, it is not documented.

Held back on purpose: model codenames that are not yet released are **not**
published. The validator flags them and they are recorded in
[FLAGGED.md](FLAGGED.md).

## Usage

```bash
# 1. Record a release manifest (name/version/sha512/file-list/binary-size).
#    Downloads the tarballs, hashes them, then discards them. No binary kept.
scripts/fetch-release.sh latest

# 2. Extract paths + beta flags from the release binary (LC_ALL=C sort -u).
scripts/extract-binary.sh 2.1.170            # auto-finds ../claude-code-reverse/binary_2.1.170/claude
scripts/extract-binary.sh -b /path/to/claude 2.1.170

# 3. Compare against the previous documented version.
scripts/compare-release.sh 2.1.139 2.1.170

# 4. Validate the gates. Must exit 0 before publishing.
scripts/validate-extraction.sh 2.1.170
```

Verify any single documented literal directly against a release:

```bash
strings binary_2.1.170/claude | rg '/api/oauth/profile'
```

For older wrapper packages that still shipped a readable `cli.js`, the same
patterns apply to that file (`rg '/api/oauth/profile' package/cli.js`).

## Validation Gates

`scripts/validate-extraction.sh` is the publish gate. It enforces:

| Gate | Check |
|------|-------|
| a | `LC_ALL=C` pinned for `sort` **and** `comm`; raw lists verified C-ordered. An ambient UTF-8 locale makes `comm` fabricate phantom diffs — this is the top footgun. |
| b | No secrets or home paths: API keys, bearer tokens, refresh tokens, `/Users/`, `/home/`, private-key headers. |
| c | Unreleased-codename gate: any model codename not on the public allowlist (`opus`, `sonnet`, `haiku`, `fable`) is flagged loudly and fails the run. |
| d | `SUMMARY.md` counts match the raw file line counts. |
| e | All raw lists are byte-sorted-unique. |
| f | File-size / line-length cap (rejects multi-MB bundled lines). |

## Layout

```text
extractions/v<ver>/
  MANIFEST.txt        Release metadata + hashes (no binary)
  SUMMARY.md          Human-readable delta vs previous version
  raw/                Sorted-unique literal lists (paths, beta flags, ...)
  calls/              Bounded context windows around each endpoint
specs/
  claude-code-api-complete.http   Curated, runnable API reference
  claude-oauth-api.http           OAuth flow reference
scripts/
  fetch-release.sh        Pack + hash a release into a manifest
  extract-binary.sh       Paths + beta flags via strings/rg
  compare-release.sh      comm-based added/removed deltas
  validate-extraction.sh  The publish gate (see above)
.github/workflows/
  deterministic-extract.yml   Scheduled + manual: fetch->extract->compare->validate->PR
WORKFLOW.md           Step-by-step extraction runbook
FLAGGED.md            Held unreleased model codenames + policy
archive/              Deprecated docs (not maintained)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Short version: literals only, pin
`LC_ALL=C`, never commit the binary, hold unreleased codenames, and make
`scripts/validate-extraction.sh` pass before publishing.

## License

[MIT](LICENSE)
