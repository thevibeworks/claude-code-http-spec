# CLAUDE.md

Guidance for Claude Code when working with this repository.

## Repository Overview

HTTP API specification for Claude Code CLI. Documents all HTTP endpoints, headers, payloads extracted from `@anthropic-ai/claude-code`.

## Key Principles

1. **Code is truth** - Only document endpoints found in source code
2. **Stable patterns** - Search for URL paths and string literals, NOT obfuscated function names (they change every build)
3. **Verify existence** - Every endpoint must have a matching `rg 'path' cli.js` pattern
4. **Version lock** - Always note CLI version; endpoints change between releases

## What NOT to do

- Don't use line numbers (change every build)
- Don't use obfuscated names like `XQ`, `o9`, `yk` in documentation
- Don't infer endpoints from runtime logs alone
- Don't document without verification

## Validation Pattern

```bash
# GOOD - endpoint exists
rg '"/api/oauth/profile"' cli.js

# If nothing returns, DO NOT document it
```

## File Purposes

- `*.http` - API reference in HTTP client format
- `*.md` - Methodology and workflow documentation
- `sbin/` - Extraction and comparison scripts
- `archive/` - Old/deprecated documentation

## Upgrade Workflow

```bash
# 1. Get new version
npm pack @anthropic-ai/claude-code@NEW_VERSION
tar -xzf *.tgz && npx prettier --write package/cli.js

# 2. Extract
./sbin/extract-api-endpoints.sh package/cli.js

# 3. Compare
./sbin/compare-api-versions.sh old/cli.js new/cli.js

# 4. Update .http files with changes
```
