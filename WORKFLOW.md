# API Extraction Workflow

Sequential runbook for extracting HTTP endpoints from Claude Code CLI.
Agent executes top-to-bottom. Gates require pass before proceeding.

## HTTP Precision Requirements

For each endpoint, document ALL of:

| Field | Required | Example |
|-------|----------|---------|
| HTTP Method | ✓ | `POST`, `GET`, `PUT`, `PATCH`, `DELETE`, `HEAD` |
| Full URL | ✓ | `{{baseUrl}}/api/oauth/profile` |
| Query Params | if any | `?beta=true&campaign=claude_code_guest_pass` |
| Headers | ✓ | `Authorization`, `Content-Type`, `User-Agent`, `x-organization-uuid` |
| Header Values | ✓ | `Bearer {{token}}`, `application/json`, `claude-cli/2.0.58` |
| Request Body | if any | Full JSON with all fields |
| Response Shape | ✓ | Expected JSON structure with field types |
| Auth Type | ✓ | `Bearer token`, `x-api-key`, `none` |
| Beta Flags | if any | `anthropic-beta: oauth-2025-04-20` |

## Prerequisites

```bash
command -v node && command -v npm && command -v rg && command -v npx
```

## Step 1: Fetch Package

```bash
VERSION="latest"  # or specific: "2.0.55"
npm pack @anthropic-ai/claude-code@${VERSION}
```

Output: `anthropic-ai-claude-code-*.tgz`

## Step 2: Extract & Format (Important)

```bash
rm -rf package && tar -xzf anthropic-ai-claude-code-*.tgz
cd package && npx prettier --write cli.js 2>/dev/null
```

Formatting is critical - patterns won't match minified code.

## Step 3: Run Extraction Patterns

**IMPORTANT**: Extractions go to `extractions/vX.X.X/` in this repo, NOT in `package/`.

```bash
# Set version from package.json
VERSION=$(grep '"version"' package/package.json | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
PKG=package
OUT=extractions/v${VERSION}

mkdir -p $OUT/{raw,calls}

cd $PKG

# === RAW EXTRACTION (to raw/) ===

# URLs - all hardcoded
rg -o 'https://[^"'\''`]+' cli.js | sort -u > ../$OUT/raw/urls.txt

# API paths (literal strings)
rg '"/(api|v1)/[^"]+' cli.js -o | sort -u > ../$OUT/raw/paths.txt

# Headers
rg '"(Authorization|Content-Type|User-Agent|Accept|Cache-Control|anthropic-beta|anthropic-version|x-api-key|x-organization-uuid|X-Stainless-[A-Za-z-]+|Last-Uuid)"' cli.js -o | sort -u > ../$OUT/raw/headers.txt

# Beta flags
rg '"[a-z-]+-[0-9]{4}-[0-9]{2}-[0-9]{2}"' cli.js -o | sort -u > ../$OUT/raw/beta_flags.txt

# OAuth scopes
rg '"(user|org):[^"]*"' cli.js -o | sort -u > ../$OUT/raw/scopes.txt

# HTTP methods
rg 'method:\s*"(GET|POST|PUT|PATCH|DELETE)"' cli.js -o | sort | uniq -c > ../$OUT/raw/http_methods.txt

# Axios calls
rg 'YQ\.(get|post|put|patch|delete|head)\(' cli.js -o | sort | uniq -c > ../$OUT/raw/axios_methods.txt

# Stainless SDK version
rg 'var gp\s*=' cli.js > ../$OUT/raw/stainless_version.txt

# Package version
grep '"version"' package.json > ../$OUT/raw/pkg_version.txt

# === CALL CONTEXT EXTRACTION (to calls/) ===
# Each file: -B 10 -A 20 context around endpoint pattern

# OAuth flow
rg 'grant_type.*authorization_code' cli.js -B 10 -A 20 > ../$OUT/calls/oauth-token-exchange.txt
rg 'grant_type.*refresh_token' cli.js -B 10 -A 20 > ../$OUT/calls/oauth-refresh.txt

# API endpoints (use precise patterns)
rg '/api/oauth/profile' cli.js -B 10 -A 20 > ../$OUT/calls/api-oauth-profile.txt
rg '/api/oauth/usage' cli.js -B 10 -A 20 > ../$OUT/calls/api-oauth-usage.txt
rg '/api/oauth/account/settings' cli.js -B 10 -A 20 > ../$OUT/calls/api-oauth-account-settings.txt
rg 'grove_notice_viewed' cli.js -B 10 -A 20 > ../$OUT/calls/api-oauth-grove-notice.txt
rg 'create_api_key' cli.js -B 10 -A 20 > ../$OUT/calls/api-oauth-create-api-key.txt
rg 'claude_cli/roles' cli.js -B 10 -A 20 > ../$OUT/calls/api-oauth-roles.txt
rg 'client_data' cli.js -B 10 -A 20 > ../$OUT/calls/api-oauth-client-data.txt
rg 'api/claude_code_grove' cli.js -B 10 -A 20 > ../$OUT/calls/api-grove-settings.txt
rg 'first_token_date' cli.js -B 10 -A 20 > ../$OUT/calls/api-first-token-date.txt
rg 'sonnet_1m_access' cli.js -B 10 -A 20 > ../$OUT/calls/api-sonnet-1m-access.txt
rg 'referral' cli.js -B 10 -A 20 | head -100 > ../$OUT/calls/api-referral.txt
rg '/api/hello' cli.js -B 10 -A 20 > ../$OUT/calls/api-hello.txt
rg 'claude_cli_feedback' cli.js -B 10 -A 20 > ../$OUT/calls/api-feedback.txt
rg 'api/claude_code/metrics' cli.js -B 10 -A 20 > ../$OUT/calls/api-metrics.txt
rg 'metrics_enabled' cli.js -B 10 -A 20 > ../$OUT/calls/api-metrics-enabled.txt
rg 'event_logging/batch' cli.js -B 10 -A 20 > ../$OUT/calls/api-event-logging.txt
rg 'link_vcs_account' cli.js -B 10 -A 20 > ../$OUT/calls/api-link-vcs.txt
rg 'code/repos' cli.js -B 10 -A 20 > ../$OUT/calls/api-github-repos.txt
rg 'domain_info' cli.js -B 10 -A 20 > ../$OUT/calls/api-domain-info.txt

# SDK v1 endpoints
rg '"/v1/messages"' cli.js -B 10 -A 30 > ../$OUT/calls/v1-messages.txt
rg 'count_tokens' cli.js -B 10 -A 20 > ../$OUT/calls/v1-count-tokens.txt
rg '"/v1/files"' cli.js -B 10 -A 20 > ../$OUT/calls/v1-files.txt
rg '"/v1/models"' cli.js -B 10 -A 20 > ../$OUT/calls/v1-models.txt
rg 'skills\?beta=true' cli.js -B 10 -A 20 > ../$OUT/calls/v1-skills.txt
rg 'messages/batches' cli.js -B 10 -A 20 > ../$OUT/calls/v1-batches.txt
rg '/v1/sessions' cli.js -B 10 -A 25 > ../$OUT/calls/v1-sessions.txt
rg 'session_ingress' cli.js -B 10 -A 25 > ../$OUT/calls/v1-session-ingress.txt
rg 'environment_providers' cli.js -B 10 -A 20 > ../$OUT/calls/v1-environment-providers.txt

cd ..
echo "Extraction complete: $OUT"
```

Or use script:
```bash
./scripts/extract-api-endpoints.sh
```

## Step 3.5: Extract Full HTTP Details (PRECISION)

For each endpoint found, extract complete HTTP specification:

```bash
# Template for documenting each endpoint
extract_endpoint() {
  local path="$1"
  echo "=== $path ==="

  # 1. Find HTTP method
  echo "Method:"
  rg "$path" cli.js -B 10 | rg -o 'YQ\.(get|post|put|patch|delete|head)\(' | head -1

  # 2. Find query parameters
  echo "Query params:"
  rg "$path" cli.js -A 5 | rg -o '\?[^"'\''`]+' | head -1

  # 3. Find headers object
  echo "Headers:"
  rg "$path" cli.js -B 15 -A 5 | rg -o 'headers:\s*\{[^}]+\}' | head -1

  # 4. Find request body
  echo "Body:"
  rg "$path" cli.js -B 5 -A 25 | rg -o '\{[^{}]*\}' | head -3

  # 5. Find timeout
  echo "Timeout:"
  rg "$path" cli.js -A 10 | rg -o 'timeout:\s*[0-9]+' | head -1
}

# Example: Extract full details for oauth/profile
extract_endpoint "/api/oauth/profile"
```

### Required Fields Checklist

For each endpoint in `.http` file:

- [ ] HTTP method verified: `rg 'YQ\.(get|post|...)' -B 5 | grep 'endpoint'`
- [ ] Full URL with base: `{{baseUrl}}/path` or hardcoded
- [ ] Query params: `?param=value` if any
- [ ] All headers with values
- [ ] Request body JSON (if POST/PUT/PATCH)
- [ ] Response shape documented in comments
- [ ] Verification pattern: `# Verify: rg '"/path"' cli.js`

## Step 4: Verify Endpoints (GATE)

For each endpoint in `extraction/path_literals.txt`, verify it exists:

```bash
# Must return matches
rg '"/api/oauth/profile"' package/cli.js

# If returns nothing = phantom endpoint, do NOT document
```

**GATE**: Every endpoint must have verifiable `rg` pattern.
If any endpoint cannot be verified, STOP and report which ones failed.

## Step 5: Diff Against Current Spec

```bash
# Extract paths from current .http files
grep -hE '^(GET|POST|PUT|PATCH|DELETE) \{\{' *.http | \
  sed 's/.*}}//' | sort -u > current_spec_paths.txt

# Extract paths from new extraction
cat package/extraction/path_literals.txt | \
  sed 's/^"//; s/"$//' | sort -u > new_extracted_paths.txt

# Find differences
comm -13 current_spec_paths.txt new_extracted_paths.txt > added_endpoints.txt
comm -23 current_spec_paths.txt new_extracted_paths.txt > removed_endpoints.txt

echo "Added: $(wc -l < added_endpoints.txt)"
echo "Removed: $(wc -l < removed_endpoints.txt)"
```

Or use script:
```bash
./scripts/compare-api-versions.sh OLD_VERSION NEW_VERSION
```

## Step 6: Update .http Files

For each **added** endpoint in `added_endpoints.txt`:

1. Verify with `rg` pattern (Step 4)
2. Find request body: `rg 'endpoint_path' -A 20 package/cli.js`
3. Find headers: check `extraction/headers.txt`
4. Add to .http file:

```http
### Section: Endpoint Name
# Verify: rg '"/api/path"' cli.js

POST {{baseUrl}}/api/path
Authorization: Bearer {{accessToken}}
Content-Type: application/json

{
  "field": "value"
}
```

For each **removed** endpoint in `removed_endpoints.txt`:

1. Verify gone: `rg '/removed/path' package/cli.js`
2. Remove from .http or move to archive

Update version in file headers.

## Step 7: Validate Spec (GATE)

```bash
./scripts/validate-spec.sh package/cli.js claude-code-api-complete.http
```

**GATE**: Script must exit 0.
If fails, STOP and report:
- Undocumented endpoints (in code, not in spec)
- Phantom endpoints (in spec, not in code)

## Step 8: Prepare Commit (HUMAN REVIEW)

Generate commit message, DO NOT execute:

```
feat(api): update spec to vX.X.X

Changes:
- Added: /api/new/endpoint, /api/another
- Removed: /api/old/endpoint
- Updated: version headers

Extracted from @anthropic-ai/claude-code@X.X.X
```

**Output commit message and WAIT for human approval.**

Human executes:
```bash
git add -A && git commit -m "..."
```

## Step 9: Cleanup

```bash
rm -rf package/
rm -f anthropic-ai-claude-code-*.tgz
rm -f current_spec_paths.txt new_extracted_paths.txt added_endpoints.txt removed_endpoints.txt
```

---

## Quick Reference: Stable Patterns

| What | Pattern |
|------|---------|
| All URLs | `rg -o 'https://[^"'\'']+' cli.js` |
| API paths | `rg '"/(api\|v1)/[^"]+' cli.js -o` |
| OAuth | `rg 'oauth/authorize\|oauth/token\|oauth/profile' cli.js` |
| Sessions | `rg '/v1/sessions\|session_ingress' cli.js` |
| Org paths | `rg '/organizations/' cli.js` |
| Beta flags | `rg '"[a-z-]+-[0-9]{4}-[0-9]{2}-[0-9]{2}"' cli.js -o` |
| Version | `rg 'claude-cli/[0-9]' cli.js` |
| HTTP methods | `rg 'method:\s*"(GET\|POST\|PUT\|PATCH\|DELETE)"' cli.js -o` |
| Axios calls | `rg 'YQ\.(get\|post\|put\|patch\|delete\|head)\(' cli.js` |
| Stainless ver | `rg 'var gp\s*=' cli.js` |
| Timeouts | `rg 'timeout:\s*[0-9]+' cli.js` |
| Grant types | `rg 'grant_type.*"[^"]*"' cli.js -o` |
| Scopes | `rg '"user:[^"]*"\|"org:[^"]*"' cli.js -o` |

## HTTP Precision Patterns

```bash
# Get endpoint with full call context
rg '/api/path' cli.js -B 10 -A 30

# Find all headers for an endpoint
rg '/api/path' cli.js -B 20 | rg 'headers' -A 5

# Find request body structure
rg '/api/path' cli.js -A 30 | rg -o '\{[^{}]*\}'

# Find query parameters
rg '/api/path' cli.js | rg -o '\?[^"'\'']+' | sort -u

# Find User-Agent patterns
rg 'User-Agent' cli.js -A 2 | head -20

# Find Content-Type patterns
rg 'Content-Type' cli.js -A 2 | head -20
```

## Anti-Patterns

```bash
# DON'T: line numbers
# Line 67351: token exchange

# DON'T: obfuscated names
# ml0() handles profile

# DON'T: infer from runtime
# Saw /api/org/xxx in network tab

# DO: string literals
rg '"/api/oauth/profile"' cli.js
```

## Failure Conditions

Stop and report if:

1. `npm pack` fails - package version doesn't exist
2. `prettier` fails - check Node.js version
3. Step 4 gate fails - phantom endpoints detected
4. Step 7 gate fails - spec/code drift
5. Any `rg` returns nothing for documented endpoint
