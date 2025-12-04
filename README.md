# claude-code-http-spec

HTTP API specification for Claude Code CLI, extracted from `@anthropic-ai/claude-code`.

## Files

```
claude-code-api-complete.http   # Complete API reference
claude-oauth-api.http           # OAuth flow reference
WORKFLOW.md                     # Extraction workflow (agent runbook)

scripts/
  extract-api-endpoints.sh      # Automated extraction
  compare-api-versions.sh       # Version diff
  validate-spec.sh              # Spec validation

archive/                        # Deprecated (v2.0.25, used runtime logs)
```

## Version

**v2.0.55** - 76 endpoints indexed, 66 with complete request examples

## Quick Start

```bash
# Extract from new CLI version
npm pack @anthropic-ai/claude-code@latest
tar -xzf anthropic-ai-claude-code-*.tgz
npx prettier --write package/cli.js
./scripts/extract-api-endpoints.sh package/cli.js

# Compare versions
./scripts/compare-api-versions.sh old/cli.js new/cli.js
```

## Workflow

See `WORKFLOW.md` for full agent-executable runbook.

Core rule: Search **stable string literals**, not obfuscated names.

```bash
# Verify endpoint exists
rg '"/api/oauth/profile"' cli.js
# If nothing returns, don't document it
```
