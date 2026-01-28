# v2.0.76 Extraction Manifest

**Extracted:** 2025-12-27
**Source:** @anthropic-ai/claude-code@2.0.76 (npm pack)
**CLI Size:** 11MB (formatted)

## Summary

| Metric | Count |
|--------|-------|
| URLs | 290 |
| API Paths | 15 |
| Headers | 19 |
| Beta Flags | 16 |
| OAuth Scopes | 4 |
| HTTP Methods | 45 (GET:10, POST:32, PUT:2, DELETE:1) |

## Changes from v2.0.69

### New Beta Flags (+3)
- `fine-grained-tool-streaming-2025-05-14` - Fine-grained tool streaming
- `mcp-servers-2025-12-04` - MCP servers support
- `tool-search-tool-2025-10-19` - Tool search functionality

### New API Paths (+1)
- `/v1/toolbox/shttp/mcp/{server_id}` - MCP server HTTP proxy endpoint

### Previously Undocumented (present since v2.0.69)
- `/v1/token` - AWS Signin OAuth2 token endpoint (Bedrock auth)

### SDK Version
- Stainless SDK: 0.70.0 (unchanged)

## Beta Flags (16 total)

```
"advanced-tool-use-2025-11-20"
"bedrock-2023-05-31"
"context-management-2025-06-27"
"files-api-2025-04-14"
"fine-grained-tool-streaming-2025-05-14"   # NEW
"interleaved-thinking-2025-05-14"
"mcp-servers-2025-12-04"                   # NEW
"message-batches-2024-09-24"
"oauth-2025-04-20"
"skills-2025-10-02"
"structured-outputs-2025-09-17"
"token-counting-2024-11-01"
"tool-examples-2025-10-29"
"tool-search-tool-2025-10-19"              # NEW
"vertex-2023-10-16"
"web-search-2025-03-05"
```

## OAuth Scopes (4 total)

```
"org:create_api_key"
"user:inference"
"user:profile"
"user:sessions:claude_code"
```

## API Paths (15 total)

```
"/api/
"/api/claude_code_grove/settings"
"/api/hello"
"/api/oauth/
"/api/oauth/account/settings"
"/api/oauth/claude_cli/create_api_key"
"/api/oauth/claude_cli/roles"
"/api/oauth/profile"
"/api/oauth/usage"
"/v1/files"
"/v1/messages"
"/v1/messages/batches"
"/v1/models"
"/v1/token"                            # AWS Signin (since v2.0.69, now documented)
"/v1/toolbox/shttp/mcp/{server_id}     # NEW
```

## Extraction Commands

```bash
# Verify new MCP endpoint
rg 'toolbox/shttp/mcp' cli.js -B 15 -A 25

# Verify AWS Signin endpoint
rg 'CreateOAuth2Token|signin\.aws' cli.js -B 10 -A 20

# Verify new beta flags
rg 'mcp-servers-2025-12-04' cli.js
rg 'tool-search-tool-2025-10-19' cli.js
rg 'fine-grained-tool-streaming-2025-05-14' cli.js
```
