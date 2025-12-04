# HTTP Request Validation Workflow

Systematic process for validating Python scripts against Claude Code CLI source.

## Overview

```
Script (Python) ──┐
                  ├──> Compare ──> Discrepancies ──> Fix
CLI (cli.js)   ───┘
```

## Phase 1: Extract Requests from Scripts

### 1.1 Identify HTTP Calls in Script

```bash
# Find all HTTP-related code
grep -n "httpx\.\|requests\.\|urllib" script.py

# Find URL constants
grep -n "https://\|http://" script.py

# Find header definitions
grep -n "headers\s*=\|Authorization\|Content-Type\|User-Agent" script.py
```

### 1.2 Document Each Request

For each HTTP call, extract:

| Element | Example |
|---------|---------|
| Method | `POST` |
| URL | `https://console.anthropic.com/v1/oauth/token` |
| Query params | `?beta=true` |
| Headers | `Content-Type: application/json` |
| Body/Payload | `{"grant_type": "authorization_code", ...}` |
| Auth mechanism | `Bearer <token>` or `x-api-key: <key>` |

### 1.3 Standard HTTP Format

Document in raw HTTP format:

```http
POST /v1/oauth/token HTTP/1.1
Host: console.anthropic.com
Content-Type: application/json
Authorization: Bearer <token>

{
    "grant_type": "authorization_code",
    "code": "<auth_code>",
    "client_id": "<client_id>"
}
```

## Phase 2: Extract Requests from CLI Source

### 2.1 Find Endpoint Constants

```bash
# OAuth endpoints
rg "oauth/authorize|oauth/token|oauth/profile" cli.js -C 3

# API endpoints
rg "api/oauth|api/hello|v1/messages" cli.js -C 3

# URL constants (grouped object)
rg "BASE_API_URL|TOKEN_URL|AUTHORIZE_URL" cli.js -C 5
```

### 2.2 Find Request Implementation

```bash
# Token exchange - find by payload pattern
rg "grant_type.*authorization_code" cli.js -C 15

# Token refresh - find by payload pattern
rg "grant_type.*refresh_token" cli.js -C 15

# Profile API - find by endpoint
rg '"/api/oauth/profile"' cli.js -C 10

# Messages API - find by endpoint and model param
rg '"/v1/messages"' cli.js -C 10
```

### 2.3 Find Header Definitions

```bash
# anthropic-beta header
rg "anthropic-beta" cli.js -C 3

# OAuth beta flag value
rg "oauth-2025" cli.js

# User-Agent patterns
rg "claude-cli/|claude-code/" cli.js -C 3

# Stainless headers
rg "X-Stainless" cli.js -C 5

# Auth headers
rg "Authorization.*Bearer|x-api-key" cli.js -C 3

# anthropic-version header
rg "anthropic-version" cli.js -C 3
```

### 2.4 Find Body/Payload Structures

```bash
# Token exchange payload fields
rg "code_verifier|redirect_uri" cli.js -C 5

# Scope parameters
rg '"user:inference"|"user:profile"|"user:sessions"' cli.js -C 3

# Messages API payload
rg '"messages"|"model"|"max_tokens"' cli.js -C 5
```

### 2.5 Find Version Constants

```bash
# Package version (look for version string pattern)
rg 'claude-cli/[0-9]+\.[0-9]+' cli.js

# Stainless SDK version
rg '"0\.[0-9]+\.[0-9]+"' cli.js | grep -i stainless

# anthropic-version API version
rg '"2023-[0-9]+-[0-9]+"' cli.js
```

## Phase 3: Compare and Validate

### 3.1 Create Comparison Table

For each request, create side-by-side comparison:

| Element | Script | CLI | Match |
|---------|--------|-----|-------|
| URL | `https://...` | `https://...` | Y/N |
| Method | POST | POST | Y |
| Header X | value | value | Y/N |
| Body field | value | value | Y/N |

### 3.2 Classify Discrepancies

| Severity | Criteria | Example |
|----------|----------|---------|
| **HIGH** | Breaks functionality | Missing required scope |
| **MEDIUM** | May cause issues | Missing optional param |
| **LOW** | Cosmetic/version | Outdated version string |
| **INFO** | Documentation only | Different but equivalent |

### 3.3 Validate Each Element

**URLs:**
- Exact host match
- Path match
- Query params match

**Headers:**
- Required headers present
- Header values match
- Case sensitivity (HTTP headers case-insensitive, but be consistent)

**Body:**
- All required fields present
- Field names exact match
- Field values/types correct
- No extra fields that cause rejection

**Auth:**
- Correct auth mechanism (Bearer vs x-api-key)
- Token format correct

## Phase 4: Document in .http File

### 4.1 File Structure

```http
# API Reference
# Version: X.Y.Z
# Search patterns for validation (not line numbers)

### ============================================================================
### VARIABLES
### ============================================================================
@baseUrl = https://api.anthropic.com
@token = YOUR_TOKEN

### ============================================================================
### 1. ENDPOINT NAME
### ============================================================================
# Validation: rg "pattern" cli.js
# Description of endpoint

# @name request_name
METHOD {{baseUrl}}/path
Header: value

{
    "body": "here"
}

### ============================================================================
### VALIDATION SUMMARY
### ============================================================================
# Discrepancies table
```

### 4.2 Include Source References

Use search patterns, not line numbers (they change every build):

```bash
# Good - stable patterns
rg "grant_type.*authorization_code" cli.js
rg '"user:inference"' cli.js
rg "oauth-2025" cli.js

# Bad - breaks on rebuild
# Line 67351: ml0 function
# cli.js:244077
```

## Phase 5: Fix Scripts

### 5.1 Priority Order

1. **HIGH** - Fix immediately (breaks auth/functionality)
2. **MEDIUM** - Fix soon (may cause edge case failures)
3. **LOW** - Fix when convenient (cosmetic)

### 5.2 Fix Checklist

For each fix:
- [ ] Identify exact line(s) to change
- [ ] Verify fix matches CLI exactly
- [ ] Test after fix
- [ ] Update version constants if applicable

### 5.3 Common Fixes

**Missing scope:**
```python
# Before
SCOPES = ["user:profile", "user:inference"]

# After (verify: rg '"user:sessions"' cli.js)
SCOPES = ["user:profile", "user:inference", "user:sessions:claude_code"]
```

**Missing request param:**
```python
# Before
payload = {
    "grant_type": "refresh_token",
    "refresh_token": token,
    "client_id": CLIENT_ID,
}

# After (verify: rg "grant_type.*refresh_token" cli.js -A 10)
payload = {
    "grant_type": "refresh_token",
    "refresh_token": token,
    "client_id": CLIENT_ID,
    "scope": "user:profile user:inference user:sessions:claude_code",
}
```

**Version update:**
```python
# Before
USER_AGENT = "claude-cli/2.0.25 (external, cli)"
STAINLESS_VERSION = "0.60.0"

# After (verify: rg "claude-cli/[0-9]" cli.js)
USER_AGENT = "claude-cli/2.0.55 (external, cli)"
STAINLESS_VERSION = "0.70.0"
```

## Quick Reference: CLI Search Patterns

| What | Search Pattern |
|------|----------------|
| URL constants | `rg "BASE_API_URL\|TOKEN_URL\|CLIENT_ID" cli.js` |
| Scopes | `rg '"user:inference"\|"user:profile"\|"user:sessions"' cli.js` |
| OAuth beta | `rg "oauth-2025" cli.js` |
| Token exchange | `rg "grant_type.*authorization_code" cli.js` |
| Token refresh | `rg "grant_type.*refresh_token" cli.js` |
| Profile API | `rg '"/api/oauth/profile"' cli.js` |
| Messages API | `rg '"/v1/messages"' cli.js` |
| PKCE | `rg "code_verifier\|code_challenge" cli.js` |
| User-Agent | `rg "claude-cli/" cli.js` |
| Stainless headers | `rg "X-Stainless" cli.js` |
| anthropic-version | `rg "anthropic-version" cli.js` |

## Automation Ideas

```bash
# Extract all endpoints from cli.js
rg -o 'https://[^"]+' cli.js | sort -u

# Extract all header names
rg -o '"[A-Za-z-]+":' cli.js | grep -i 'anthropic\|stainless\|user-agent' | sort -u

# Find all scope strings
rg -o '"user:[^"]*"' cli.js | sort -u

# Find version strings
rg 'claude-cli/[0-9]+\.[0-9]+\.[0-9]+' cli.js | head -5

# Compare scope arrays between script and CLI
diff <(grep -o '"user:[^"]*"' script.py | sort -u) \
     <(rg -o '"user:[^"]*"' cli.js | sort -u)
```
