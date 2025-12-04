# API Extraction Methodology

Systematic process for extracting all HTTP requests from Claude Code CLI.

## Principles

1. **Code-only extraction**: Document only endpoints found in source code - never infer from partial runtime data
2. **Stable patterns**: Use search patterns, not line numbers or obfuscated function names (they change every build)
3. **Verify existence**: Every documented endpoint must have a matching `rg` pattern that finds it
4. **Version awareness**: Endpoints change between versions - always note the source version

## Overview

```
cli.js ──> Pattern Matching ──> Trace Context ──> Verify ──> Document ──> .http file
           (multiple patterns)   (headers/body)   (rg check)
```

## Phase 1: Identify HTTP Call Patterns

The minified CLI uses obfuscated function names that change every build.
Instead of searching for function names, search for **stable string literals**.

### 1.1 Search by URL Path (Most Reliable)

```bash
# Find endpoints by path string (stable across versions)
rg '"/api/oauth/' cli.js
rg '"/v1/messages' cli.js
rg '"/v1/sessions' cli.js

# Find all API path patterns
rg '"/(api|v1)/[^"]+' cli.js -o | sort -u
```

### 1.2 Search by Domain (Hardcoded URLs)

```bash
# All Anthropic API URLs
rg 'api\.anthropic\.com' cli.js

# Console URLs
rg 'console\.anthropic\.com' cli.js

# Claude.ai URLs
rg 'claude\.ai' cli.js
```

### 1.3 Search by HTTP Method Context

```bash
# Find POST with specific paths
rg 'post.*oauth/token|oauth/token.*post' cli.js -i

# Find requests with specific payloads
rg 'grant_type.*authorization_code' cli.js
```

## Phase 2: Extract URL Patterns

### 2.1 All URLs in Code

```bash
# Extract all https URLs
rg -o 'https://[^"'\''`]+' cli.js | sort -u

# Filter by service
rg -o 'https://api\.anthropic\.com[^"'\''`]*' cli.js | sort -u
rg -o 'https://console\.anthropic\.com[^"'\''`]*' cli.js | sort -u
```

### 2.2 Path Strings

```bash
# All /api/* and /v1/* paths
rg '"/(api|v1)/[^"]+' cli.js -o | sort -u

# Organization-scoped paths (have variable segments)
rg '/organizations/' cli.js
rg '/organization/' cli.js
```

### 2.3 URL Constants (by string value)

```bash
# Find by the actual URL values (stable)
rg 'https://api\.anthropic\.com"' cli.js -C 3
rg 'https://console\.anthropic\.com/oauth' cli.js -C 3
```

## Phase 3: Trace Request Context

For each endpoint found, trace backwards to find:

### 3.1 Headers

```bash
# Find header definitions near the call
rg "headers.*:" cli.js -n -C 5 | grep -A 5 -B 5 "XQ\."

# Common headers to look for
rg "Authorization|Content-Type|User-Agent|anthropic-beta|anthropic-version|x-api-key" cli.js -n
```

### 3.2 Request Body

```bash
# Find JSON payloads
rg "XQ\.post\([^,]+,\s*\{" cli.js -n -C 10

# Find specific payload fields
rg "grant_type|code_verifier|refresh_token" cli.js -n -C 5
```

### 3.3 Query Parameters

```bash
# URL params
rg "params:\s*\{" cli.js -n -C 5

# URLSearchParams
rg "searchParams\.append" cli.js -n -C 3
```

## Phase 4: Categorize Endpoints

### By Service

| Service | URL Pattern | Auth |
|---------|-------------|------|
| API | api.anthropic.com | Bearer/x-api-key |
| Console | console.anthropic.com | Bearer |
| Claude.ai | claude.ai | Bearer |
| CDN | downloads.claude.ai | None |
| External | various | Various |

### By Function

| Category | Pattern | Example |
|----------|---------|---------|
| OAuth | `/oauth/`, `/v1/oauth/` | token exchange |
| Account | `/api/oauth/account/` | settings |
| Messages | `/v1/messages` | chat API |
| Sessions | `/v1/sessions` | web sessions |
| Telemetry | `/api/event_logging/` | metrics |

## Phase 5: Document in .http Format

### Structure

```http
### ============================================================================
### SECTION N: CATEGORY NAME
### ============================================================================
# Pattern: rg "search pattern" cli.js

### ----------------------------------------------------------------------------
### N.1 Endpoint Name
### ----------------------------------------------------------------------------
# Description of what this endpoint does

# @name requestName
METHOD {{baseUrl}}/path
Header: value

{
    "body": "here"
}

### Response:
# {
#   "field": "value"
# }
```

### Variables Block

```http
@baseUrl = https://api.anthropic.com
@consoleUrl = https://console.anthropic.com
@version = 2023-06-01
@accessToken = YOUR_TOKEN
```

## Quick Reference Commands

```bash
# === COMPLETE EXTRACTION ===

# 1. All HTTP calls with context
rg "XQ\.(get|post|put|patch|delete|head)\(" cli.js -n -C 10 > http_calls.txt

# 2. All SDK calls
rg "this\._client\.(get|post|delete)" cli.js -n -C 10 > sdk_calls.txt

# 3. All URLs
rg -o 'https://[^"'\'']+' cli.js | sort -u > all_urls.txt

# 4. All headers
rg '"[A-Za-z-]+":' cli.js | grep -i 'auth\|content\|user-agent\|anthropic\|stainless' | sort -u

# 5. Dynamic paths
rg '\$\{o9\(\)\.BASE_API_URL\}' cli.js -o -n > dynamic_paths.txt

# === SPECIFIC SEARCHES ===

# OAuth endpoints
rg "oauth/authorize|oauth/token|oauth/profile" cli.js -n

# API v1 endpoints
rg '"/v1/[^"]+' cli.js -o | sort -u

# Beta flags
rg "anthropic-beta" cli.js -C 2 | grep -o '"[a-z-]*-[0-9-]*"' | sort -u

# Version strings
rg 'VERSION.*"[0-9]' cli.js -n
```

## Endpoint Categories Found (v2.0.55)

### Anthropic API (api.anthropic.com)

```
/api/oauth/profile
/api/claude_cli_profile
/api/oauth/claude_cli/roles
/api/oauth/claude_cli/create_api_key
/api/oauth/claude_cli/client_data
/api/oauth/account/settings
/api/oauth/account/grove_notice_viewed
/api/claude_code_grove
/api/oauth/usage
/api/organization/claude_code_first_token_date
/api/organization/{orgId}/claude_code_sonnet_1m_access
/api/oauth/organizations/{orgId}/referral/eligibility
/api/oauth/organizations/{orgId}/referral/redemptions
/api/oauth/organizations/{orgId}/code/repos/{owner}/{repo}
/api/claude_code/link_vcs_account
/api/claude_code/organizations/metrics_enabled
/api/claude_code/metrics
/api/event_logging/batch
/api/claude_cli_feedback
/api/hello
/v1/messages
/v1/messages/count_tokens
/v1/messages/batches
/v1/messages/batches/{id}
/v1/messages/batches/{id}/cancel
/v1/files
/v1/files/{id}
/v1/files/{id}/content
/v1/models
/v1/models/{id}
/v1/skills
/v1/skills/{id}
/v1/skills/{id}/versions
/v1/skills/{id}/versions/{versionId}
/v1/complete
/v1/sessions
/v1/sessions/{id}
/v1/sessions/{id}/events
/v1/environment_providers
/v1/session_ingress/session/{id}
```

### Console (console.anthropic.com)

```
/oauth/authorize
/v1/oauth/token
/v1/oauth/revoke
/v1/oauth/hello
/.well-known/oauth-authorization-server
```

### Claude.ai

```
/oauth/authorize
/api/web/domain_info
```

### CDN (downloads.claude.ai)

```
/claude-code-releases/{channel}
/claude-code-releases/{version}/manifest.json
/claude-code-releases/{version}/{platform}/{file}
```

### External Services

```
# Datadog
https://http-intake.logs.datadoghq.com/api/v2/logs

# Statsig
https://featureassets.org/v1/initialize
https://api.statsigcdn.com/v1/download_config_specs
https://prodregistryv2.org/v1/rgstr
https://statsigapi.net/v1/sdk_exception

# GitHub
https://raw.githubusercontent.com/anthropics/claude-code/.../CHANGELOG.md

# Docs
https://code.claude.com/docs/en/claude_code_docs_map.md
https://docs.claude.com/en/api/agent_sdk_docs_map.md

# Connectivity
http://1.1.1.1
```

## Versioning

When updating for new CLI versions:

1. Extract new package: `npm pack @anthropic-ai/claude-code@latest && tar -xzf *.tgz`
2. Format: `npx prettier --write package/cli.js`
3. Run extraction: `./references/sbin/extract-api-endpoints.sh package/cli.js`
4. Compare versions: `./references/sbin/compare-api-versions.sh old/cli.js new/cli.js`
5. Update `claude-code-api-complete.http` with changes
6. Update version references

## Automation Scripts

Located in `references/sbin/`:

- `extract-api-endpoints.sh` - Extract all HTTP patterns from cli.js
- `compare-api-versions.sh` - Diff endpoints between two versions

See `references/API-EXTRACTION-PIPELINE.md` for the complete reproducible workflow.

## Anti-Patterns (What NOT to Do)

### 1. Don't use line numbers or obfuscated names

```bash
# BAD - breaks on every build
# Line 67351: ml0 function handles token exchange
# cli.js:244077 contains profile fetch

# GOOD - stable patterns
rg "grant_type.*authorization_code" cli.js
rg '"/api/oauth/profile"' cli.js
```

### 2. Don't infer endpoints from partial runtime data

Previous work combined "runtime logs AND code analysis" which led to phantom endpoints like:
- `/api/oauth/organizations/{org_id}/code/sessions` - NOT IN CODE
- `/api/organization/{org_id}/claude_code_recommended_subscription` - NOT IN CODE
- `/api/organizations/{org_id}/claude_code_data_sharing` - NOT IN CODE

These were either:
- Inferred from partial network traces
- Present in older versions but removed
- Misread from similar path patterns

**Rule**: If `rg 'endpoint_path' cli.js` returns nothing, the endpoint doesn't exist in this version.

### 3. Don't document without verification

Every endpoint in the .http file should include a verification pattern:

```http
### 1.1 OAuth Profile
# Verify: rg '"/api/oauth/profile"' cli.js

GET {{baseUrl}}/api/oauth/profile
```

## Lessons Learned

### Version Differences (v2.0.25 vs v2.0.55)

| Previous Doc Claimed | Actual in v2.0.55 |
|---------------------|-------------------|
| `/api/oauth/organizations/{}/code/sessions` | `/v1/sessions` (different path) |
| `/api/organization/{}/claude_code_recommended_subscription` | NOT FOUND |
| `/api/organizations/{}/claude_code_data_sharing` | NOT FOUND |

### Search Pattern Hierarchy

For comprehensive extraction, search in this order:

1. **Hardcoded full URLs**: `rg 'https://api\.anthropic\.com/[^"]+' cli.js -o | sort -u`
2. **Dynamic BASE_API_URL paths**: `rg '\$\{o9\(\)\.BASE_API_URL\}/[^`]+' cli.js -o | sort -u`
3. **Relative paths in SDK**: `rg 'this\._client\.(get|post)\("[^"]+' cli.js -o | sort -u`
4. **Path constants**: `rg '"/(api|v1)/[^"]+' cli.js -o | sort -u`

### Edge Cases to Check

```bash
# Organization-scoped endpoints (variable in path)
rg '/organizations/\$\{' cli.js -n

# Org ID in path
rg '/organization/\$\{' cli.js -n

# Session-related
rg '/sessions' cli.js -n

# Referral/special programs
rg '/referral/' cli.js -n

# VCS/GitHub integration
rg '/repos/' cli.js -n
rg 'link_vcs' cli.js -n
```

## Validation Checklist

Before finalizing the .http file:

- [ ] Every endpoint has a `rg` pattern that finds it in cli.js
- [ ] No line numbers referenced (use patterns instead)
- [ ] No obfuscated function names (XQ, o9, etc.) in documentation prose
- [ ] Version number matches extracted package
- [ ] Endpoints sorted by category
- [ ] Headers traced from actual usage, not assumed
- [ ] Request bodies verified against code
