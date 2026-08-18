# Claude Code HTTP API — v2.1.234

Source: `@anthropic-ai/claude-code-linux-x64@2.1.234`.

## The correction this release forced

Every previous revision of this repo carried the same caveat:

> Header sets, request bodies and timeouts are **not** recoverable from a
> binary. Those are read from v2.1.76, the last release with a readable bundle,
> and carried forward explicitly labelled.

That was wrong, and it has been wrong since v2.1.117. The compiled binary
embeds the entire minified JavaScript bundle as printable text. It reads as one
enormous line, which is why `rg -A/-B` context looked empty and the conclusion
"not recoverable" seemed reasonable. Cut a fixed **byte window** instead and the
call site is right there, complete:

```js
fs.get("/v1/ultrareview/quota", {auth: "teleport-org", timeout: 3000})
```

```js
this._client.post(Fa`/v1/tunnels/${e}/certificates?beta=true`, {
  body: o, ...r,
  headers: yi([{"anthropic-beta": [...n ?? [], "mcp-tunnels-2026-06-22"]...
```

So methods, header sets, auth modes, timeouts and beta flags for v2.1.234 are
read from v2.1.234, not carried forward from a two-year-old release. The same
method works retroactively on v2.1.197 and earlier binaries.

## New tooling

| Script | What it recovers |
|--------|------------------|
| `scripts/extract-routes.py` | method + path + beta flag + auth mode + timeout, per call site |
| `scripts/extract-calls.py` | printable byte window around each endpoint anchor |
| `scripts/binary-literals.sh` | binary → one-literal-per-line text, the input `validate-spec.sh` needs |

`extract-routes.py` hardcodes no minified identifier. It anchors the SDK shape
on the literal `_client.`, detects the axios instances as the identifiers that
most often precede an `/api/` or `/v1/` call, and resolves paths that were
hoisted into a constant before the call.

## Auth modes

The single most useful thing recovered. axios call sites name their auth mode,
and the mode decides the whole header set. From
`calls/auth-modes.txt`:

| `auth:` | Headers |
|---------|---------|
| `teleport-org` | `Authorization`, `Content-Type`, `anthropic-version`, `anthropic-client-platform`, `x-organization-uuid` — **and** substitutes the literal `:orgUUID` in the path |
| `session-jwt` | `Authorization: Bearer <session access token>`, nothing else |
| `claude-ai-oauth` | `Authorization`, `anthropic-beta: oauth-2025-04-20` |
| `none` | no auth headers |
| `async` / unset | resolved OAuth headers (`Authorization` + `anthropic-beta: oauth-2025-04-20`), or `x-api-key` under API-key auth |

This also explains a long-standing oddity: paths in the constant pool contain
`:orgUUID` verbatim because the auth layer, not the call site, substitutes it.

Two pre-flight refusals apply to every axios call before a request is made:
essential-traffic-only mode blocks it unless the call opts out, and a
non-first-party provider blocks it with reason `data-residency`.

## Counts

| Metric | Value |
|--------|-------|
| Path literals (`raw/paths.txt`) | 101 (+33 / −1 vs v2.1.197) |
| Beta flags (`raw/beta_flags.txt`) | 53 (+9 / −1 vs v2.1.197) |
| Call-site routes (`raw/routes.tsv`) | 242 (129 SDK, 114 axios) |
| Routes with a beta flag | 120 |
| Endpoints in `claude-code-api-complete.http` | 281 |

`scripts/validate-spec.sh --routes raw/routes.tsv` reports **0 undocumented,
0 phantom** for both `claude-code-api-complete.http` and (in `--subset` mode)
`claude-oauth-api.http`.

## Added surface

New first-class families, all verified by method:

- **Self-hosted runners** — `/v1/code/runners/self-hosted/*`: registration,
  spawn-hint long-poll (30s), session release, report-failure, deregister.
  Pairs with the 24 `SELF_HOSTED_RUNNER_*` env vars in the same release.
- **MCP tunnels** — `/v1/tunnels/*`, 10 routes, all pinning
  `mcp-tunnels-2026-06-22`. Includes `reveal_token` and `rotate_token`.
- **Dreams** — `/v1/dreams/*`, 5 routes, `dreaming-2026-04-21`.
- **Deployments** — `/v1/deployments/*` and `/v1/deployment_runs/*`,
  `managed-agents-2026-04-01`. Includes pause/unpause/run/archive.
- **Design** — `/v1/design/consent`, `/grants`, `/mcp`. The consent GET is a
  pre-flight; on failure the client falls back to a 403-seeded cache rather
  than blocking. `/v1/design/mcp` is `auth: "none"` with a 60s timeout.
- **Ultrareview** — `/v1/ultrareview/quota` and `/preflight`, both
  `auth: "teleport-org"`. `CLAUDE_CODE_ULTRAREVIEW_QUOTA_FIXTURE` short-circuits
  the quota call entirely: the env value is parsed as JSON and no request goes
  out.
- **Frames** — `/api/frame/*` grew comments, contract, blob and subscribe
  routes. Uploads run through a relay probe, so a 429 with `retry-after` is
  expected and retried once.
- **Local / org memory** — `/v1/code/local/memory/mounts` and `/credential`.
- **Plugin and skill discovery** — `/plugins/search`, `/skills/search`,
  `/plugin_ratings` and its appearance-outcome reporting.
- **MCP connectors** — `/mcp/connectors/{list,search,suggest}` under the org
  OAuth path.

New beta flags (9): `agent-memory-2026-07-22`, `auto-mode-classifier-2026-07-16`,
`dreaming-2026-04-21`, `mcp-tunnels-2026-06-22`,
`mid-conversation-tool-changes-2026-07-01`, `per-turn-control-2026-07-01`,
`pre-2026-07-28`, `prompt-caching-evict-2026-05-12`,
`server-side-fallback-2026-07-01`. Removed: `summarize-connector-text-2026-03-13`.

## Gateway protocol document

The binary embeds the self-hosted gateway wire contract
(`CLAUDE_CODE_USE_GATEWAY`) verbatim as a string literal. Recovered whole to
`GATEWAY-PROTOCOL.md`. It grew from 9,598 bytes in v2.1.197 to 13,246 here, and
the new material is all contract detail rather than new endpoints:

- **Usage-limit headers** — the exact 429 shape, including
  `anthropic-ratelimit-unified-overage-*` headers and the warning that sending
  `representative-claim` / `overage-status` makes the client compose its own
  message and *drop* yours.
- **TLS** — the client pins the SHA-256 fingerprint of the gateway's leaf
  certificate per hostname after first-connect confirmation, and re-prompts on
  mismatch. Rotating a certificate costs every user one prompt.
- **Client guarantees** — OAuth paths always come from discovery (never
  hardcoded), fixed paths resolve against `{base}` and never a redirect, the
  OTLP exporter is locked to `{base}/v1/{signal}` regardless of the user's
  `OTEL_*` env, and a 404 from `/v1/models` or `/managed/settings` is a clean
  "not implemented" with no retry storm.
- **Proxying to Bedrock, Vertex, Foundry** — model-ID translation,
  `anthropic-beta` moving from header to request body for Bedrock, re-emitting
  AWS binary event-stream as Anthropic-shaped SSE (and synthesising `ping`
  events, which the provider SDKs drop), and returning `501 not_supported` from
  `count_tokens` so the client falls back to a Haiku `max_tokens:1` probe.

`specs/claude-code-gateway.http` validates as "phantom" by design: it specifies
the *server* side, and the CLI resolves those paths from the gateway's own
discovery document rather than hardcoding them. Validate it against
`GATEWAY-PROTOCOL.md`, not against client literals. A note in the spec says so.

## Removed surface

Verified absent from the binary, commented out in the specs rather than deleted:

- `/api/claude_code/discovery/team_usage`
- `/api/claude_code/team_memory` (GET and POST)
- `/api/claude_code/user_settings`
- `/api/oauth/claude_cli/client_data`
- `/v1/code/egress/gateway`
- `/v1/code/upstreamproxy`
- `/v1/code/` (bare root; every surviving path under it is a full route)

## Cross-check against live traffic

`WORKFLOW.md`'s rule stands — endpoints are never *inferred* from runtime logs.
This goes the other way: a local MITM capture of one interactive v2.1.234
session was used to check the header sets that were read from the binary.
Section 43 of `claude-code-api-complete.http` records the result. No
identifiers, tokens, request-ids or organization UUIDs from that capture are
reproduced anywhere in this repository.

The capture confirms the auth-mode table exactly:

- `/v1/code/triggers` and `/v1/ultrareview/quota` went out with
  `authorization` + `content-type` + `anthropic-version` +
  `anthropic-client-platform` + `x-organization-uuid` — the `teleport-org` set,
  matching `auth: "teleport-org"` at both call sites.
- The `/api/oauth/*` calls went out with `authorization` +
  `anthropic-beta: oauth-2025-04-20` and no organization header — the default
  OAuth set.
- `/mcp-registry/v0/servers` went out with no `authorization` header at all,
  matching `auth: "none"`.

It also pins down the two User-Agents, which map to the two client shapes:
`claude-cli/2.1.234 (external, cli)` for axios, `claude-code/2.1.234` for the
SDK client.

Volume, for a sense of what a session actually costs: 132 calls to
`/api/event_logging/v2/batch`, 123 to `/v1/messages`, and 83 to a Datadog logs
intake at `http-intake.logs.us5.datadoghq.com/api/v2/logs` (`dd-api-key`
header) — a narrower host than the generic `datadoghq.com` previously recorded.

## Coverage honesty

`raw/routes.tsv` holds 242 call-site routes. 161 of them were new to the spec
and are written up in Section 42 with method, beta flag, auth mode and timeout.
137 sit in a named family with prose; 24 are grouped under "Other v2.1.234
routes" with the same verified fields but no prose yet.

A further 47 path literals exist in the constant pool whose call site builds the
path through a helper `extract-routes.py` does not follow. Those are declared
with `# PATH-ONLY` lines: the path is verified, the method is not, and the spec
says so instead of guessing. `validate-spec.sh` counts a `PATH-ONLY` line as
documented for the completeness gate, so "0 undocumented" means *every path
literal is accounted for*, not that every method is known — 47 of them are
explicitly marked unknown.
