# Extraction Summary: v2.1.170

Source: `@anthropic-ai/claude-code-linux-x64@2.1.170` (Bun binary, 247MB)
Previous extraction: v2.1.139 (binary)

## Architecture Note

v2.1.170 is a Bun-compiled binary. No `cli.js` is present in the platform package.
Extraction uses `strings` on the binary, not the older `rg package/cli.js` workflow.
The npm wrapper package `@anthropic-ai/claude-code@2.1.170` is already unpacked in
`claude-code-reverse/package_2.1.170`; the platform binary matches the registry tarball.

## API Path Changes vs v2.1.139

Paths: 59 total, 18 added, 0 removed.

### Added Paths

- `"/api/claude_cli_feedback`
- `"/api/claude_code/notification/preferences`
- `"/api/claude_code/organizations/metrics_enabled`
- `"/api/claude_code/skills`
- `"/api/claude_code_shared_session_transcripts`
- `"/api/oauth/organizations/:orgUUID/admin_requests`
- `"/api/oauth/organizations/:orgUUID/overage_credit_grant`
- `"/api/oauth/organizations/:orgUUID/plugins/list-plugins?enabled_only=true&compact=true`
- `"/api/oauth/organizations/:orgUUID/skills/list-skills?include_wiggle_skills=true`
- `"/api/oauth/organizations/:orgUUID/sync/github/auth`
- `"/api/organization/claude_code_first_token_date`
- `"/api/organizations/:orgUUID/claude_code/onboarding`
- `"/v1/code/`
- `"/v1/code/agent-proxy`
- `"/v1/code/github/import-token`
- `"/v1/code/triggers`
- `"/v1/filestore/fs/readFile`
- `"/v1/ultrareview/preflight`

### Removed Paths

None.

## Beta Flag Changes vs v2.1.139

Beta flags: 43 total, 4 added, 0 removed.

### Added Beta Flags

- `fallback-credit-2026-06-01`
- `server-side-fallback-2026-06-01`
- `summarize-connector-text-2026-03-13`
- `thinking-token-count-2026-05-13`

### Removed Beta Flags

None.

## Fable 5 / Model Discovery

The binary includes `claude-fable-5` and the `fable` alias, plus Fable-specific
configuration hooks:

- `ANTHROPIC_DEFAULT_FABLE_MODEL`
- `ANTHROPIC_DEFAULT_FABLE_MODEL_NAME`
- `ANTHROPIC_DEFAULT_FABLE_MODEL_DESCRIPTION`
- `DISABLE_PROMPT_CACHING_FABLE`
- `VERTEX_REGION_CLAUDE_FABLE_5`

Provider mappings are present for first-party, Bedrock, and Vertex-style model IDs.
The strings also include launch/usage-credit messaging for Fable 5.
