# Extraction Summary: v2.1.222

Source: `@anthropic-ai/claude-code-linux-x64@2.1.222` (Bun binary)
Previous extraction: v2.1.220 (binary)

## Architecture Note

Unchanged from v2.1.220: no `cli.js` in the platform package, extraction via
`strings` on the Bun-compiled binary. The npm wrapper
`@anthropic-ai/claude-code@2.1.222` remains a thin shim with no extractable
strings of its own.

## API Path Changes vs v2.1.220

Paths: 83 total, 0 added, 0 removed.

No change. The HTTP surface is byte-identical to v2.1.220 — the same 83 paths,
including the `/api/frame/*`, `/v1/design/*` and `/v1/code/local/memory/*`
groups that landed in that release. A two-version gap with zero path movement
suggests v2.1.222 is a behaviour or bugfix release rather than an API one.

## Beta Flag Changes vs v2.1.220

Beta flags: 50 total, 1 added, 0 removed.

One addition:

- `pre-2026-07-28`

Unlike every other flag in the list, this one carries no feature name — it is a
bare date. The established convention here is `<feature>-<date>`
(`per-turn-control-2026-07-01`, `auto-mode-classifier-2026-07-16`), where the
date stamps when the feature's beta was cut. A date with no feature reads as a
cutoff marker: a way to request pre-28-July behaviour across the board rather
than to opt into one named feature. That is inference from the naming shape
alone — the literal does not say what it gates.

Nothing was removed, so the flag is additive to the v2.1.220 set.

See `COMPARE.txt` for the full added/removed lists and `MANIFEST.txt`
for the resolved version and hashes.

If a model codename was held, see `FLAGGED.md`.
