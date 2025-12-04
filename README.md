# claude-code-http-spec

HTTP API specification for Claude Code CLI, extracted from `@anthropic-ai/claude-code`.

## Files

```
claude-code-api-complete.http   # Complete API reference
claude-oauth-api.http           # OAuth flow reference
API-EXTRACTION-PIPELINE.md      # Reproducible extraction workflow
API-EXTRACTION-METHODOLOGY.md   # Search patterns reference

sbin/
  extract-api-endpoints.sh      # Automated extraction
  compare-api-versions.sh       # Version diff

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
./sbin/extract-api-endpoints.sh package/cli.js

# Compare versions
./sbin/compare-api-versions.sh old/cli.js new/cli.js
```

## Methodology

Search for **stable string literals**, not obfuscated function names (they change every build).

```bash
# Verify endpoint exists
rg '"/api/oauth/profile"' cli.js

# If nothing returns, don't document it
```

## Principles

1. **Code is truth** - Only document endpoints found in source code
2. **Stable patterns** - Search URL paths and literals, not `XQ`, `o9`, `yk`
3. **Verify existence** - Every endpoint needs a matching `rg` pattern
4. **Version lock** - Endpoints change between releases
