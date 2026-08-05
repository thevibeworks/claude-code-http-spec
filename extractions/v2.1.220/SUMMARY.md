# Extraction Summary: v2.1.220

Source: `@anthropic-ai/claude-code-linux-x64@2.1.220` (Bun binary)
Previous extraction: v2.1.197 (binary)

## Architecture Note

Same distribution shape as v2.1.197: no `cli.js` in the platform package,
extraction via `strings` on the Bun-compiled binary. The npm wrapper
`@anthropic-ai/claude-code@2.1.220` remains a thin shim (no bundled JS) with no
extractable strings of its own.

## API Path Changes vs v2.1.197

Paths: 83 total, 15 added, 1 removed.

The 15 additions fall into four groups:

**Frames** — `/api/frame/contract/latest`, `/api/frame/deploy/prepare`,
`/api/frame/frames?limit=200`, `/api/frame/upload`. v2.1.197 had already
introduced `/api/frame/deploy/{complete,direct,init}` and `/api/frame/track`;
this release adds upload, contract lookup, a listing endpoint, and a `prepare`
step ahead of the existing deploy verbs.

**Org-scoped discovery** — `/api/oauth/organizations/:orgUUID/` gains
`mcp/connectors/{list,search,suggest}`, `plugins/search`, and `skills/search`.
Connectors, plugins and skills all become searchable per organization, with
`suggest` implying a recommendation path rather than plain lookup.

**Memory** — `/v1/code/memory/`, plus `/v1/code/local/memory/credential` and
`/v1/code/local/memory/mounts`. The `local/` split alongside the plain
`/v1/code/memory/` route points at memory that can be backed either
server-side or by a local mount, with its own credential endpoint.

**Design** — `/v1/design/{consent,grants,mcp}`. v2.1.197 had only the bare
`/v1/design/`; this fills it in with a consent/grant pair and an MCP route.

One removal: `/api/claude_code/discovery/team_usage`. Team usage discovery
disappears in the same release that adds org-scoped search under
`/api/oauth/organizations/`, which is consistent with that surface being
re-homed rather than dropped — though the literals alone do not prove it.

## Beta Flag Changes vs v2.1.197

Beta flags: 49 total, 5 added, 1 removed.

Additions:

- `per-turn-control-2026-07-01`, `mid-conversation-tool-changes-2026-07-01`,
  `server-side-fallback-2026-07-01` — three flags sharing a 1 July date,
  suggesting one coordinated turn-handling change: control applied per turn,
  tool definitions mutable mid-conversation, and a server-side fallback path.
- `auto-mode-classifier-2026-07-16` — a classifier behind the auto-mode
  selection.
- `prompt-caching-evict-2026-05-12` — explicit cache eviction, dated well
  before the others, so likely a longer-running beta only now surfacing in the
  extracted set.

One removal: `summarize-connector-text-2026-03-13`, a March flag — the usual
shape for a beta that either graduated to default or was abandoned.

See `COMPARE.txt` for the full added/removed lists and `MANIFEST.txt`
for the resolved version and hashes.

If a model codename was held, see `FLAGGED.md`.
