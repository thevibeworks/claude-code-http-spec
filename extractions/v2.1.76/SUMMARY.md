# Extraction Summary: v2.1.76

Source: `@anthropic-ai/claude-code@2.1.76` (cli.js, 18MB, 605K lines formatted)
Previous extraction: v2.1.63

## Paths

17 API/SDK path patterns extracted. One new vs v2.1.63:
- `"/api/event_logging/batch` (telemetry batch endpoint — already in spec)

All endpoints verified in cli.js.

## Beta Flags

25 beta flags (vs 7 in v2.1.63). New:
- `advanced-tool-use-2025-11-20`
- `afk-mode-2026-01-31`
- `ccr-byoc-2025-07-29`
- `context-management-2025-06-27`
- `fast-mode-2026-02-01`
- `files-api-2025-04-14`
- `interleaved-thinking-2025-05-14`
- `mcp-client-2025-11-20`
- `mcp-servers-2025-12-04`
- `message-batches-2024-09-24`
- `prompt-caching-scope-2026-01-05`
- `redact-thinking-2026-02-12`
- `structured-outputs-2025-11-13`
- `structured-outputs-2025-12-15`
- `token-counting-2024-11-01`
- `tool-examples-2025-10-29`
- `tool-search-tool-2025-10-19`
- `web-search-2025-03-05`

## Headers

Standard set: Authorization, Content-Type, User-Agent, Accept, Cache-Control, anthropic-beta, anthropic-version, x-api-key, x-organization-uuid, Last-Uuid, plus 7 X-Stainless-* headers.

## OAuth Scopes

7 scope strings (vs 113 false positives in v2.1.63 — previous regex was too loose). New vs v2.1.63:
- `user:file_upload`
- `user:sessions:claude_code`
- Compound scope: `user:profile user:inference user:sessions:claude_code user:mcp_servers`

## Spec Impact

Minimal: all new paths already covered in current spec. Beta flags should be updated in spec comments. New scopes should be documented.

## Notes

- Axios var for this build: `z` (was different in prior builds)
- Architecture: still cli.js bundle (last version before Bun binary shift at ~v2.1.88)
