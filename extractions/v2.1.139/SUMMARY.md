# Extraction Summary: v2.1.139

Source: `@anthropic-ai/claude-code-linux-arm64@2.1.139` (Bun binary, 221MB)
Build: 2026-05-11T17:03:24Z, git sha 208bf4b44f987c4c62618ae20ce1715d53693c62
Previous extraction: v2.1.76 (cli.js), v2.1.121 (binary)

## Architecture Note

v2.1.139 is a Bun-compiled binary. No cli.js. Extraction via `strings` on the binary.
The WORKFLOW.md pipeline (rg on cli.js) does not apply. Beta flag extraction uses
`grep -oP '[a-z][-a-z]*-20[0-9]{2}-[0-9]{2}-[0-9]{2}'` since quoted strings are
split differently in the binary.

## New API Paths (vs v2.1.76 spec)

### Billing/Payment (9 endpoints, all new)
- `/api/oauth/organizations/:orgUUID/billing/tax_rate`
- `/api/oauth/organizations/:orgUUID/claude_code/pro_trial`
- `/api/oauth/organizations/:orgUUID/contracts/auto_reload_settings`
- `/api/oauth/organizations/:orgUUID/contracts/prepaid/credits`
- `/api/oauth/organizations/:orgUUID/overage_spend_limit`
- `/api/oauth/organizations/:orgUUID/payment_method`
- `/api/oauth/organizations/:orgUUID/prepaid/bundles`
- `/api/oauth/organizations/:orgUUID/prepaid/credits`
- `/api/oauth/organizations/:orgUUID/setup_overage_billing`

### New SDK Endpoints (6 endpoints)
- `/v1/agents?beta=true` — Managed Agents API (CRUD + versions)
- `/v1/code/egress/gateway` — Egress gateway for CCR
- `/v1/code/upstreamproxy` — Upstream proxy configuration
- `/v1/memory_stores?beta=true` — Memory stores API (CRUD on memories)
- `/v1/user_profiles?beta=true` — User profiles API
- `/v1/vaults?beta=true` — Vaults/credentials API (CRUD)

### Updated/Renamed
- `/api/event_logging/v2/batch` (was `/api/event_logging/batch`)
- `/api/hello/:name` (parameterized variant, new)
- `/api/users/:id` (user lookup, new)

### All use `managed-agents-2026-04-01` beta
The agents, memory_stores, user_profiles, and vaults endpoints all send
`anthropic-beta: managed-agents-2026-04-01` header.

## Removed
- `/api/event_logging/batch` — replaced by v2 path
- `link_vcs_account` — not found (was already phantom in v2.1.76)

## Beta Flags

39 flags (vs 25 in v2.1.76). 15 new, 1 removed.

New:
- `advisor-tool-2026-03-01`
- `cache-diagnosis-2026-04-07`
- `ccr-triggers-2026-01-30`
- `context-hint-2026-04-09`
- `extended-cache-ttl-2025-04-11`
- `fine-grained-tool-streaming-2025-05-14`
- `managed-agents-2026-04-01`
- `mid-conversation-system-2026-04-07`
- `nightly-2025-12-10`
- `oidc-federation-2026-04-01`
- `task-budgets-2026-03-13`
- `token-efficient-tools-2025-02-19`
- `user-profiles-2026-03-24`
- `k-2025-02-19` (fragment — likely `block-2025-02-19` or similar)
- `m-2025-08-07` (fragment — likely `context-1m-2025-08-07`)

Removed:
- `tool-examples-2025-10-29`

## Env Vars

630 vars (vs 596 in v2.1.121). 36 new, 2 removed.
Notable: `CLAUDE_CODE_MAX_TURNS`, `CLAUDE_CODE_PROACTIVE`, `CLAUDE_CODE_SUPERVISED`,
`CLAUDE_CODE_INVESTIGATE_FIRST`, `GH_TOKEN`, `GH_HOST`, `GH_ENTERPRISE_TOKEN`,
`BUGHUNTER_FLEET_SIZE`, `MCP_CONNECT_TIMEOUT_MS`.
