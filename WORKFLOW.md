# API Extraction Workflow

Sequential runbook for extracting HTTP endpoints from Claude Code CLI.
Agent executes top-to-bottom. Gates require pass before proceeding.

## Reading a compiled release (v2.1.117+)

Releases ship as a Bun-compiled binary, not a readable `cli.js`. The whole
minified JavaScript bundle is still in there as printable text -- it just reads
as one enormous line, so `rg -A/-B` context returns nothing useful and it *looks*
unrecoverable. It is not. Two moves make the binary as readable as the old
bundle:

```bash
# 1. one literal per line, for the rg-based path patterns and the validator
scripts/binary-literals.sh <binary> /tmp/literals.txt

# 2. method + path + beta flag + auth mode + timeout, per call site
scripts/extract-routes.py <binary> --all extractions/vX.Y.Z/raw/routes.tsv

# 3. a printable byte window around each endpoint, for reading bodies/headers
scripts/extract-calls.py <binary> extractions/vX.Y.Z/calls/
```

Header sets, request bodies and timeouts ARE recoverable from a binary. Earlier
revisions of this repo said otherwise and carried them forward from v2.1.76;
that was wrong. Read them from the release you are documenting.

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

# Axios calls (NOTE: obfuscated var name changes per build - find it first)
# v2.0.58: YQ, v2.0.69: wQ - use dynamic detection:
AXIOS_VAR=$(rg -o '[A-Za-z0-9]+\.(get|post|put|patch|delete|head)\(' cli.js | head -1 | cut -d. -f1)
rg "${AXIOS_VAR}\.(get|post|put|patch|delete|head)\(" cli.js -o | sort | uniq -c > ../$OUT/raw/axios_methods.txt

# Stainless SDK version (NOTE: var name changes - v2.0.58: gp, v2.0.69: Wc)
rg 'var [A-Za-z0-9]+\s*=\s*"0\.[0-9]+\.[0-9]+"' cli.js | head -1 > ../$OUT/raw/stainless_version.txt

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
rg 'api/claude_cli_profile' cli.js -B 10 -A 20 > ../$OUT/calls/api-cli-profile.txt
rg 'admin_requests' cli.js -B 10 -A 20 > ../$OUT/calls/api-oauth-admin-requests.txt
rg 'api/oauth/file_upload' cli.js -B 10 -A 30 > ../$OUT/calls/api-oauth-file-upload.txt
rg 'api/oauth/files' cli.js -B 10 -A 30 > ../$OUT/calls/api-oauth-file-download.txt
rg '/v1/oauth/hello' cli.js -B 10 -A 20 > ../$OUT/calls/api-oauth-hello.txt

# OAuth plumbing that determines headers for ALL of the above.
# These are the highest-value windows: three distinct header builders exist
# and mixing them up is the most common spec error.
rg 'BASE_API_URL: "' cli.js -B 20 -A 30 > ../$OUT/calls/oauth-config.txt
rg 'CLAUDE_CODE_CUSTOM_OAUTH_URL' cli.js -B 5 -A 25 > ../$OUT/calls/oauth-custom-url-allowlist.txt
rg '"anthropic-beta": ' cli.js -B 12 -A 4 > ../$OUT/calls/header-builders.txt
rg 'claude-cli/\$\{|claude-code/\$\{' cli.js -B 12 -A 2 > ../$OUT/calls/user-agent-builders.txt
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
- [ ] Verification pattern: `# Verify: rg '/path' cli.js`

## Step 4: Verify Endpoints (GATE)

For each endpoint in `extraction/path_literals.txt`, verify it exists:

```bash
# Must return matches
rg '/api/oauth/profile' package/cli.js

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

The bulk of a version bump is mechanical: one request block per new route, with
the header set implied by its auth mode. That part is generated, so it is
reproducible and nobody has to review 1,700 lines by hand:

```bash
scripts/gen-spec-section.py <version> /tmp/literals.txt
```

It rewrites the "NEW IN v<version>" section in place and is idempotent -- run it
twice, get the same bytes. Generated: the request blocks. Authored: the family
grouping and prose, which live in the `FAMILIES` table inside the script. Edit
prose there, not in the .http file, or the next run drops it.

Curated endpoints -- the ones that earn a request body, a response shape, or a
paragraph of behaviour -- are written by hand in the sections above it, as
before.

### Manual edits

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
./scripts/validate-spec.sh package/cli.js specs/claude-code-api-complete.http

# Subset validation (OAuth-only spec)
./scripts/validate-spec.sh --subset package/cli.js specs/claude-oauth-api.http
```

Pass `--routes` so the call-site table counts as code, alongside the literal
scan. Without it, any path assembled from a template
(`/v1/environments/${id}/work/${w}/ack` -- never a whole literal) reads as a
phantom:

```bash
scripts/binary-literals.sh <binary> /tmp/literals.txt
scripts/validate-spec.sh --routes extractions/vX.Y.Z/raw/routes.tsv \
  /tmp/literals.txt specs/claude-code-api-complete.http
scripts/validate-spec.sh --subset --routes extractions/vX.Y.Z/raw/routes.tsv \
  /tmp/literals.txt specs/claude-oauth-api.http
```

**GATE**: Script must exit 0.
If fails, STOP and report:
- Undocumented endpoints (in code, not in spec)
- Phantom endpoints (in spec, not in code)

When a path literal exists but its call site builds the path through a helper
the route extractor does not follow, do NOT guess a method. Declare it:

```
# PATH-ONLY {{baseUrl}}/api/frame/contract/latest
```

The validator counts that as documented. It claims the path exists and nothing
else -- no method, no headers, no body.

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
| Axios calls | `rg '[A-Za-z0-9]+\.(get\|post\|put\|patch\|delete\|head)\(' cli.js -o \| head -5` (var name changes) |
| Stainless ver | `rg 'var [A-Za-z0-9]+\s*=\s*"0\.[0-9]+\.[0-9]+"' cli.js` (var name changes) |
| Timeouts | `rg 'timeout:\s*[0-9]+' cli.js` |
| Grant types | `rg 'grant_type.*"[^"]*"' cli.js -o` |
| Scopes | `rg '"user:[^"]*"\|"org:[^"]*"' cli.js -o` |

## Known Extraction Blind Spots

The path-literal patterns above key on `"/api/...` or `BASE_API_URL}/api/...`.
Endpoints whose host comes from a *helper call* are invisible to both:

```js
`${ubY()}/api/oauth/file_upload`          // host helper, not BASE_API_URL
`${qPz()}/api/oauth/files/${uuid}/content`
```

`scripts/validate-spec.sh` carries explicit rules for these two. When a new
endpoint is built the same way, add a rule there or it will be reported as a
phantom forever. Sweep for the shape with:

```bash
rg -o '\}/api/[a-z_/]+' cli.js | sort -u
```

Header sets used to be guesswork. They are not any more: axios call sites name
their auth mode, and the mode decides the entire header set.

| `auth:` | Emits |
|---------|-------|
| `teleport-org` | `Authorization` + `Content-Type` + `anthropic-version` + `anthropic-client-platform` + `x-organization-uuid`; also substitutes `:orgUUID` in the path |
| `session-jwt` | `Authorization: Bearer <session access token>`, nothing else |
| `claude-ai-oauth` | `Authorization` + `anthropic-beta: oauth-2025-04-20` |
| `none` | no auth headers |
| `async` / unset | resolved OAuth headers, or `x-api-key` under API-key auth |

`scripts/extract-routes.py` records the mode per route. Two pre-flight refusals
apply to every axios call: essential-traffic-only mode, and a non-first-party
provider (`data-residency`).

Stainless SDK resources take auth from the client, not per call, and pin their
own `anthropic-beta` flag per resource.

Still: never copy a header block from a neighbouring endpoint. Read the call
site, or read the `auth` column.

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
rg '/api/oauth/profile' cli.js
```

## Failure Conditions

Stop and report if:

1. `npm pack` fails - package version doesn't exist
2. `prettier` fails - check Node.js version
3. Step 4 gate fails - phantom endpoints detected
4. Step 7 gate fails - spec/code drift
5. Any `rg` returns nothing for documented endpoint
