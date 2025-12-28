# claude-code-http-spec

HTTP API specification for Claude Code CLI, extracted from `@anthropic-ai/claude-code`.

## Structure

```
specs/                           # Finalized .http files
  claude-code-api-complete.http  # Complete API reference (75+ endpoints)
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

**v2.0.76** - 75+ endpoints, 31 call contexts extracted

### Changes from v2.0.69
- NEW beta flags:
  - `fine-grained-tool-streaming-2025-05-14`
  - `mcp-servers-2025-12-04`
  - `tool-search-tool-2025-10-19`
- NEW endpoint: `/v1/toolbox/shttp/mcp/{server_id}` (MCP HTTP proxy)
- Stainless SDK: 0.70.0 (unchanged)

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
npm pack @anthropic-ai/claude-code@latest
tar -xzf anthropic-ai-claude-code-*.tgz
npx prettier --write package/cli.js

# 2. Run extraction (outputs to extractions/vX.X.X/)
# See WORKFLOW.md Step 3

# 3. Compare versions
diff -r extractions/v2.0.55 extractions/v2.0.58
```

## Workflow

See `WORKFLOW.md` for full agent-executable runbook.

Core rule: Extract **stable string literals**, not obfuscated variable names.

```bash
# Verify endpoint exists
rg '"/api/oauth/profile"' package/cli.js

# Extract full call context
rg '/api/oauth/profile' package/cli.js -B 10 -A 20
```
