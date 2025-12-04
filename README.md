# claude-code-http-spec

HTTP API specification for Claude Code CLI, extracted from `@anthropic-ai/claude-code`.

## Contents

```
claude-code-api-complete.http   # Complete API reference (76 endpoints)
claude-oauth-api.http           # OAuth flow reference
API-EXTRACTION-METHODOLOGY.md   # Search patterns and methodology
API-EXTRACTION-PIPELINE.md      # Reproducible extraction workflow
VALIDATION-WORKFLOW.md          # Script validation process

sbin/
  extract-api-endpoints.sh      # Automated extraction tool
  compare-api-versions.sh       # Version diff tool

archive/
  ALL-API-ENDPOINTS.md          # Old reference (v2.0.25, mixed sources)
  ENDPOINT-TESTING-REPORT.md    # Runtime log analysis
```

## Quick Start

```bash
# Extract endpoints from a new CLI version
npm pack @anthropic-ai/claude-code@latest
tar -xzf anthropic-ai-claude-code-*.tgz
npx prettier --write package/cli.js

./sbin/extract-api-endpoints.sh package/cli.js
```

## Version

Current: v2.0.55 (76 verified endpoints)

## Methodology

Search for **stable string literals** (URLs, paths, headers), not obfuscated function names.

```bash
# Verify endpoint exists
rg '"/api/oauth/profile"' cli.js

# If nothing returns, endpoint doesn't exist
```

See `API-EXTRACTION-PIPELINE.md` for the full workflow.
