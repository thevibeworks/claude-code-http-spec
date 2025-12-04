# Archive

Deprecated documentation. Kept for historical reference only.

## Why Archived

### ALL-API-ENDPOINTS.md (v2.0.25)

**Problem**: Mixed "runtime logs AND code analysis" as sources.

This led to phantom endpoints that don't exist in code:
- `/api/oauth/organizations/{org_id}/code/sessions` - inferred from partial trace
- `/api/organization/{org_id}/claude_code_recommended_subscription` - not in code
- `/api/organizations/{org_id}/claude_code_data_sharing` - not in code

**Lesson**: Runtime logs can mislead. Only document what `rg 'path' cli.js` finds.

### ENDPOINT-TESTING-REPORT.md

Runtime log analysis from actual CLI execution. Useful for understanding response formats but not for discovering endpoints.

### VALIDATION-WORKFLOW.md

Python script validation against CLI source. Moved here because:
- This repo has no Python files
- The workflow is for external Python clients, not this specification

## Current Approach

See `../API-EXTRACTION-PIPELINE.md` for the code-only methodology.
