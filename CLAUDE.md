# CLAUDE.md

## What NOT to do

- Don't use line numbers (change every build)
- Don't use obfuscated names like `XQ`, `o9`, `yk` in documentation
- Don't infer endpoints from runtime logs
- Don't document without `rg` verification

## Validation

```bash
# If this returns nothing, endpoint doesn't exist
rg '"/api/oauth/profile"' cli.js
```

## File Types

- `*.http` - API requests (HTTP client format)
- `*.md` - Documentation
- `sbin/` - Shell scripts
- `archive/` - Deprecated docs (don't update)
