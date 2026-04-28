# v2.1.63 Extraction Summary

Extracted: 2026-02-28
Package: @anthropic-ai/claude-code@2.1.63 (30MB, cli.js 12MB → 12829 lines formatted)

## Changes from v2.1.22

### New Endpoints
- `POST /api/claude_code_shared_session_transcripts` - shared session transcript upload
- `WSS /api/ws/speech_to_text/voice_stream` - voice mode (speech-to-text via WebSocket)
- `WSS wss://bridge.claudeusercontent.com` - Remote Control bridge (access CLI from web/mobile)

### Removed Endpoints
- `GET /api/organization/{orgId}/claude_code_sonnet_1m_access` - gone, no longer in cli.js

### New Beta Flags
- `compact-2026-01-12` - server-side context compaction (Opus 4.6 only, 150K trigger threshold)
- `effort-2025-11-24` - effort parameter (output_config.effort: low|medium|high|max)
- `environments-2025-11-01` - environment runners
- `context-1m-2025-08-07` - 1M context window (in docs, Opus 4.6 / Sonnet 4.6)

### Graduated to GA (removed from beta code paths)
- interleaved-thinking-2025-05-14
- context-management-2025-06-27
- structured-outputs-2025-09-17
- structured-outputs-2025-12-15
- web-search-2025-03-05
- tool-examples-2025-10-29
- advanced-tool-use-2025-11-20
- fine-grained-tool-streaming-2025-05-14
- tool-search-tool-2025-10-19
- mcp-servers-2025-12-04
- message-batches-2024-09-24
- token-counting-2024-11-01

### New Models
- claude-opus-4-6 (Opus 4.6)
- claude-sonnet-4-6 (Sonnet 4.6)
- claude-opus-4-1-20250805 (Opus 4.1)
- claude-opus-4-5-20251101 (Opus 4.5)
- claude-sonnet-4-5-20250929 (Sonnet 4.5)

### New Headers
- `anthropic-ratelimit-unified-status` (and -reset, -fallback)
- `anthropic-ratelimit-unified-overage-status` (and -reset, -disabled-reason)
- `anthropic-ratelimit-unified-representative-claim`
- `anthropic-marketplace`
- `anthropic-plugins`
- `anthropic-dangerous-direct-browser-access`
- `x-claude-remote-container-id`
- `x-claude-remote-session-id`
- `x-environment-runner-version`

### Version Bumps
- Stainless SDK: 0.70.0 → 0.74.0
- CLI: 2.1.22 → 2.1.63
- Package size: 26.5MB → 30.0MB
- cli.js: ~8.9MB → 12MB

### New Tool Versions (in SDK help text)
- `web_search_20260209` - updated web search with dynamic filtering
- `web_fetch_20260209` - updated web fetch with dynamic filtering

### New Features
- Voice Mode: speech-to-text via WebSocket, local audio only
- Remote Control: CLI accessible from claude.ai/code or mobile app
- Shared Session Transcripts: share conversation logs externally
- Server-side Context Compaction: auto-summarize at 150K tokens
- Effort Parameter: control thinking depth (low/medium/high/max)
- Dynamic Filtering: code execution for search result filtering (web tools)
- Unified Rate Limiting: new header family for rate limit info

### WebSocket URLs
- `wss://bridge.claudeusercontent.com` (production)
- `wss://bridge-staging.claudeusercontent.com` (staging)
- `ws://localhost:8765` (local)

### UUIDs
- 9d1c250a-e61b-44d9-88ed-5944d1962f5e (client ID, unchanged)
- aebc6443-996d-45c2-90f0-388ff96faa56 (new)
