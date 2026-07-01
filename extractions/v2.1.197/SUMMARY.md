# Extraction Summary: v2.1.197

Source: `@anthropic-ai/claude-code-linux-x64@2.1.197` (Bun binary, 236MB)
Previous extraction: v2.1.170 (binary)

## Architecture Note

Same distribution shape as v2.1.170: no `cli.js` in the platform package,
extraction via `strings` on the binary. The npm wrapper package
`@anthropic-ai/claude-code@2.1.197` is a ~20KB thin wrapper (`cli-wrapper.cjs`
+ `install.cjs`, no bundled JS) with no extractable strings of its own.

## API Path Changes vs v2.1.170

Paths: 69 total, 12 added, 2 removed.

### Added Paths

- `"/api/claude_code/discovery/team_usage`
- `"/api/frame/deploy/complete`
- `"/api/frame/deploy/direct`
- `"/api/frame/deploy/init`
- `"/api/frame/track`
- `"/v1/code/sessions`
- `"/v1/design/`
- `"/v1/logs`
- `"/v1/metrics`
- `"/v1/organizations/spend_limits`
- `"/v1/sessions`
- `"/v1/traces`

`/v1/sessions` (bare, not under `/v1/code/`) lines up with `/v1/agents`,
`/v1/environments`, and `/v1/deployments` also being present in this binary —
the CLI now talks to the Managed Agents API directly, not just SDK users.
`/api/frame/deploy/*` and `/api/frame/track` are a new subsystem name not seen
before in this repo's history; no further inference attempted (see
Confidence Model in README — this is a literal, not a claim about behavior).

### Removed Paths

- `"/v1/code/egress/gateway`
- `"/v1/code/upstreamproxy`

Matches the `CCR_EGRESS_GATEWAY_ENABLED` / `CCR_UPSTREAM_PROXY_ENABLED` env
vars also disappearing this release (see `claude-code-envs` v2.1.197) — reads
as the old CCR gateway/proxy paths being retired together with their env-var
toggles, not an unrelated coincidence.

## Beta Flag Changes vs v2.1.170

Beta flags: 45 total, 3 added, 1 removed.

### Added Beta Flags

- `code-execution-2025-08-25`
- `computer-use-2025-11-24`
- `server-side-fallback-2026-06-09`

### Removed Beta Flags

- `nightly-2025-12-10`

`server-side-fallback-2026-06-01` (the GA refusal-fallback header for Claude
Fable 5, added in v2.1.170) is still present and unchanged in v2.1.197 — this
release adds `-2026-06-09` alongside it rather than replacing it. Literal
presence only; which header the CLI actually sends in which code path is not
claimed here.

## Sonnet 5 / Model Discovery

The binary includes the `claude-sonnet-5` model ID literal directly (confirmed
via `strings`), plus its provider config surface:

- `VERTEX_REGION_CLAUDE_5_SONNET` (new this release — see
  `claude-code-envs` v2.1.197 for the full env-var side of this)

## Not Done This Pass

`calls/*.txt` (bounded context windows) and `specs/*.http` (the curated
runnable reference) were **not** updated for the 12 new / 2 removed paths or
3 new / 1 removed beta flags above — both are substantial hand-curation work
(confirming method/headers/body per endpoint) beyond what a `strings`-only
pass can responsibly assert. `raw/` + this SUMMARY are the verified-literal
layer; the curated layer is a follow-up.
