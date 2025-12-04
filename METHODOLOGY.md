# API Extraction Pipeline

Reproducible process for extracting and validating HTTP endpoints from Claude Code CLI.

## Principles

1. **Code is truth** - Only document endpoints found in source code
2. **Runtime validates** - Use runtime logs to verify, not discover
3. **Patterns over positions** - Search patterns, not line numbers
4. **Version locked** - Always note CLI version; endpoints change between releases

## Pipeline Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  1. EXTRACT     │────▶│  2. VERIFY      │────▶│  3. DOCUMENT    │
│  (code-only)    │     │  (patterns)     │     │  (.http file)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                      │                       │
         ▼                      ▼                       ▼
   package/cli.js         rg patterns            endpoint list
                          return matches          with payloads
```

## Phase 1: Extract Package

```bash
# Always start fresh
VERSION="latest"  # or specific version like "2.0.55"
npm pack @anthropic-ai/claude-code@${VERSION}
rm -rf package && tar -xzf anthropic-ai-claude-code-*.tgz

# Format for readable patterns (IMPORTANT)
cd package && npx prettier --write cli.js
```

## Phase 2: Extract All HTTP Patterns

Search for **stable string literals** (URLs, paths, headers) not obfuscated function names.

```bash
cd package

# === URL EXTRACTION (stable across builds) ===

# 1. All hardcoded URLs
rg -o 'https://[^"'\''`]+' cli.js | sort -u > extraction/all_urls.txt

# 2. API path strings
rg '"/(api|v1)/[^"]+' cli.js -o | sort -u > extraction/path_literals.txt

# 3. Organization-scoped paths
rg '/organizations/[^"'\''`]+' cli.js -o | sort -u > extraction/org_paths.txt

# === HEADER & PAYLOAD EXTRACTION ===

# 4. HTTP headers
rg '"(Authorization|Content-Type|User-Agent|anthropic-beta|anthropic-version|x-api-key|x-organization-uuid)"' cli.js -o | sort -u > extraction/headers.txt

# 5. Beta feature flags
rg '"[a-z-]+-[0-9]{4}-[0-9]{2}-[0-9]{2}"' cli.js -o | sort -u > extraction/beta_flags.txt

# 6. OAuth scopes
rg '"user:[^"]*"' cli.js -o | sort -u > extraction/scopes.txt

# 7. Grant types (OAuth payloads)
rg 'grant_type' cli.js -C 3 > extraction/grant_types.txt
```

## Phase 3: Verify Each Endpoint

For every endpoint found, it MUST have a verifiable pattern:

```bash
# GOOD - endpoint exists (search returns matches)
rg '"/api/oauth/profile"' cli.js
# Returns: matches with the path string

# BAD - endpoint doesn't exist (phantom)
rg '/code/sessions"' cli.js
# Returns: nothing - this endpoint was inferred, not real
```

**Rule**: If `rg 'endpoint_path' cli.js` returns nothing, DO NOT document it.

## Phase 4: Document with Verification

Each endpoint in the .http file should include its verification pattern:

```http
### 2.1 OAuth Profile
# Verify: rg '"/api/oauth/profile"' cli.js
# Found at: dynamic URL construction with BASE_API_URL

GET {{baseUrl}}/api/oauth/profile
Authorization: Bearer {{accessToken}}
```

## Phase 5: Runtime Validation (Optional)

Use runtime logs to VALIDATE (not discover) endpoints:

```bash
# Capture HTTP traffic during CLI use
CLAUDE_CODE_DEBUG=1 claude-code 2>&1 | tee session.log

# Or use mitmproxy/Charles for full request/response capture
```

**Important**: Runtime logs validate that documented endpoints work, but should NOT be used to discover new endpoints (leads to phantom entries).

## Comparison Workflow (Version Upgrades)

When upgrading to a new CLI version:

```bash
# 1. Extract both versions
npm pack @anthropic-ai/claude-code@OLD_VERSION
npm pack @anthropic-ai/claude-code@NEW_VERSION

# 2. Extract URLs from both
rg -o '"/(api|v1)/[^"]+' old/cli.js | sort -u > old_endpoints.txt
rg -o '"/(api|v1)/[^"]+' new/cli.js | sort -u > new_endpoints.txt

# 3. Find differences
diff old_endpoints.txt new_endpoints.txt
# or
comm -13 old_endpoints.txt new_endpoints.txt  # Added in new
comm -23 old_endpoints.txt new_endpoints.txt  # Removed in new
```

## Anti-Patterns

### 1. DON'T use line numbers
```bash
# BAD - changes every build
# Line 67351: token exchange function

# GOOD - stable pattern
rg "grant_type.*authorization_code" cli.js
```

### 2. DON'T use obfuscated function names
```bash
# BAD - changes every build
# ml0() handles profile fetch

# GOOD - search by behavior/string
rg '"/api/oauth/profile"' cli.js
```

### 3. DON'T infer endpoints from runtime logs alone
```bash
# BAD - may be incomplete or misread
# Saw /api/oauth/organizations/xxx/code/sessions in network tab

# GOOD - verify in code first
rg '/code/sessions' cli.js  # Returns nothing = doesn't exist
```

### 4. DON'T document without verification
```bash
# BAD - assumed endpoint
POST /v1/oauth/revoke  # "Should exist per RFC 7009"

# GOOD - verify dynamically discovered
rg 'revocation_endpoint' cli.js  # Found - uses OAuth metadata
```

## Quick Reference: Stable Search Patterns

Search for string literals, not obfuscated function names.

| What | Pattern |
|------|---------|
| All URLs | `rg -o 'https://[^"'\'']+' cli.js \| sort -u` |
| API paths | `rg '"/(api\|v1)/[^"]+' cli.js -o \| sort -u` |
| OAuth endpoints | `rg 'oauth/authorize\|oauth/token\|oauth/profile' cli.js` |
| Session endpoints | `rg '/v1/sessions\|session_ingress' cli.js` |
| Org-scoped paths | `rg '/organizations/' cli.js` |
| Beta flags | `rg '"[a-z-]+-[0-9]{4}-[0-9]{2}-[0-9]{2}"' cli.js -o` |
| OAuth scopes | `rg '"user:[^"]*"' cli.js -o` |
| Version strings | `rg 'claude-cli/[0-9]' cli.js` |
| Grant types | `rg 'grant_type' cli.js` |

## Validation Checklist

Before finalizing documentation:

- [ ] Every endpoint has a `rg` pattern that finds it
- [ ] No line numbers in documentation
- [ ] No obfuscated names (XQ, o9, etc.) in prose
- [ ] Version matches package.json
- [ ] Headers traced from actual code, not assumed
- [ ] Request bodies verified against code
- [ ] Dynamic endpoints (from metadata) noted as such

## Files Structure

```
./
├── METHODOLOGY.md                 # This file
├── claude-code-api-complete.http  # API reference
├── claude-oauth-api.http          # OAuth reference
├── scripts/
│   ├── extract-api-endpoints.sh   # Extraction
│   ├── compare-api-versions.sh    # Version diff
│   └── validate-spec.sh           # Spec validation
└── archive/                       # Deprecated
```

## Lessons Learned

### v2.0.25 → v2.0.55 Differences

| Previous Doc Claimed | Reality in v2.0.55 |
|---------------------|-------------------|
| `/api/oauth/organizations/{}/code/sessions` | Doesn't exist - was `/v1/sessions` |
| `/api/organization/{}/claude_code_recommended_subscription` | NOT FOUND |
| `/api/organizations/{}/claude_code_data_sharing` | NOT FOUND |

**Root cause**: Previous work mixed runtime logs (partial) with code analysis, leading to phantom endpoints.

### Why Phantoms Happened

1. **Partial network trace** - Saw `/organizations/xxx/...` in traffic, assumed full path
2. **Version drift** - Endpoint existed in older version, removed later
3. **Inference** - "This should exist based on API patterns"

### Prevention

- Always verify with `rg 'exact_path' cli.js`
- Never document what you can't find in code
- Runtime logs validate, don't discover
