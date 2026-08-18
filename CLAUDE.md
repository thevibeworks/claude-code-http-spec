# CLAUDE.md

## Workflow

Follow `WORKFLOW.md` step-by-step when updating specs.
Gates at Step 4 and Step 7 - stop and report if they fail.

## What NOT to do

- Don't use line numbers (change every build)
- Don't use obfuscated names like `XQ`, `o9`, `yk` in documentation
- Don't infer endpoints from runtime logs (using a capture to *check* header
  sets already read from the binary is fine, and is what SECTION 43 does)
- Don't guess a method you couldn't read -- use `# PATH-ONLY` instead
- Don't document without `rg` verification

## Validation

Releases ship as a compiled binary, not `cli.js`. Render it first:

```bash
scripts/binary-literals.sh <binary> /tmp/literals.txt

# If this returns nothing, the endpoint doesn't exist
rg '/api/oauth/profile' /tmp/literals.txt

# Method + auth mode + timeout + beta flag, per call site
scripts/extract-routes.py <binary> --all extractions/vX.Y.Z/raw/routes.tsv

# Both gates, both specs
scripts/validate-spec.sh --routes extractions/vX.Y.Z/raw/routes.tsv \
  /tmp/literals.txt specs/claude-code-api-complete.http
scripts/validate-spec.sh --subset --routes extractions/vX.Y.Z/raw/routes.tsv \
  /tmp/literals.txt specs/claude-oauth-api.http
```

## File Types

- `*.http` - API requests (HTTP client format)
- `*.md` - Documentation
- `scripts/` - Shell scripts
- `archive/` - Deprecated docs (don't update)
