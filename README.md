# claude-code-http-spec

HTTP API specification for Claude Code CLI, extracted from `@anthropic-ai/claude-code`.

## Structure

```
specs/                           # Finalized .http files
  claude-code-api-complete.http  # Complete API reference (70+ endpoints)
  claude-oauth-api.http          # OAuth flow reference

extractions/                     # Version-stamped extractions (git tracked)
  v2.0.58/
    MANIFEST.md                  # Extraction manifest
    raw/                         # Raw grep outputs (urls, headers, etc)
    calls/                       # Full HTTP call contexts (-B 10 -A 20)

scripts/                         # Extraction scripts
archive/                         # Deprecated specs
WORKFLOW.md                      # Extraction workflow (agent runbook)
```

## Version

**v2.1.22** - 70+ endpoints, 36 call contexts extracted

### Changes from v2.0.76
- OAuth host migration: `console.anthropic.com` → `platform.claude.com`
- NEW MCP endpoints:
  - `GET /v1/mcp_servers?limit=1000`
  - `POST /v1/mcp/{server_id}` (via `https://mcp-proxy.anthropic.com`)
  - `POST /v1/toolbox/shttp/mcp/{server_id}`
- NEW first-party endpoints:
  - `GET /api/claude_code/policy_limits`
  - `GET /api/claude_code/user_settings`
- NEW beta flag: `structured-outputs-2025-12-15`
- NEW WebSocket endpoint (documented as URL only): `wss://api.anthropic.com/v1/sessions/ws/{id}/subscribe`
- Stainless SDK: `0.70.0` (unchanged)

### Changes from v2.0.58
- NEW beta flag: `advanced-tool-use-2025-11-20`
- NEW endpoint: `POST /v1/token` (CreateOAuth2Token)
- HTTP client obfuscation: `YQ` → `wQ`

## Precision Requirements

Every documented endpoint MUST have:
- HTTP method (GET/POST/PUT/PATCH/DELETE/HEAD)
- Full URL with query params
- All headers with exact values
- Request body JSON (if any)
- Response shape
- Verification pattern: `rg '"/api/path"' cli.js`

## Quick Start

```bash
# 1. Fetch & extract package
rm -rf package
npm pack @anthropic-ai/claude-code@latest
tar -xzf anthropic-ai-claude-code-*.tgz
npx prettier --write package/cli.js

# 2. Run extraction (outputs to extractions/vX.X.X/)
# See WORKFLOW.md Step 3

# 3. Validate specs
./scripts/validate-spec.sh package/cli.js specs/claude-code-api-complete.http
./scripts/validate-spec.sh --subset package/cli.js specs/claude-oauth-api.http

# 4. Compare versions
diff -r extractions/v2.0.76 extractions/v2.1.22
```

## Workflow

See `WORKFLOW.md` for full agent-executable runbook.

Core rule: Extract **stable string literals**, not obfuscated variable names.

```bash
# Verify endpoint exists
rg '/api/oauth/profile' package/cli.js

# Extract full call context
rg '/api/oauth/profile' package/cli.js -B 10 -A 20
```
