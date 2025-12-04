# API Extraction Workflow

Sequential runbook for extracting HTTP endpoints from Claude Code CLI.
Agent executes top-to-bottom. Gates require pass before proceeding.

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

```bash
cd package
mkdir -p extraction

# URLs
rg -o 'https://[^"'\''`]+' cli.js | sort -u > extraction/all_urls.txt

# API paths
rg '"/(api|v1)/[^"]+' cli.js -o | sort -u > extraction/path_literals.txt

# Org-scoped paths
rg '/organizations/[^"'\''`]+' cli.js -o | sort -u > extraction/org_paths.txt

# Headers
rg '"(Authorization|Content-Type|User-Agent|anthropic-beta|anthropic-version|x-api-key|x-organization-uuid)"' cli.js -o | sort -u > extraction/headers.txt

# Beta flags
rg '"[a-z-]+-[0-9]{4}-[0-9]{2}-[0-9]{2}"' cli.js -o | sort -u > extraction/beta_flags.txt

# OAuth scopes
rg '"user:[^"]*"' cli.js -o | sort -u > extraction/scopes.txt

# Grant types
rg 'grant_type' cli.js -C 3 > extraction/grant_types.txt

# Version
rg -o 'claude-cli/[0-9]+\.[0-9]+\.[0-9]+' cli.js -m 1 > extraction/version.txt
```

Or use script:
```bash
./scripts/extract-api-endpoints.sh package/cli.js
```

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
