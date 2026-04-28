# Claude Code v2.1.22 API Extraction Summary

Extracted: 2026-01-28
Package: @anthropic-ai/claude-code@2.1.22
CLI.js size: 11.7MB (formatted)

## Key Changes from v2.0.76

### URL Migration
- `console.anthropic.com` → `platform.claude.com` for OAuth endpoints

### New Endpoints
- `GET /v1/mcp_servers?limit=1000` - List MCP servers
- `POST /v1/mcp/{server_id}` - MCP server proxy (via mcp-proxy.anthropic.com)
- `POST /v1/toolbox/shttp/mcp/{server_id}` - MCP server toolbox
- `GET /api/claude_code/policy_limits` - Policy limits (first party)
- `GET /api/claude_code/user_settings` - User settings
- `WSS /v1/sessions/ws/{id}/subscribe` - Session WebSocket

### New Beta Flags
- `mcp-servers-2025-12-04`
- `structured-outputs-2025-12-15`

### New Scope
- `user:mcp_servers` - Required for MCP server access

### New Infrastructure
- MCP Proxy URL: `https://mcp-proxy.anthropic.com`
- MCP Proxy Path: `/v1/mcp/{server_id}`

## Axios Variable
Build-specific: `Jc6` (v2.1.22)

## Stainless SDK Version
`0.70.0` (unchanged)
