# Flagged Unreleased Model Codenames

Extraction sometimes surfaces model codenames from a release that are **not on
the public allowlist** in `scripts/validate-extraction.sh` (`opus`, `sonnet`,
`haiku`, `fable`). These are held back from published artifacts by default. The
decision to publish any one of them is made per codename by the maintainer.

Policy:

- The validator (`scripts/validate-extraction.sh`, gate **c**) fails loudly if
  any non-allowlisted codename appears anywhere under the validated
  `extractions/v<version>/` tree.
- Held evidence is **not deleted**. The full, unredacted extraction is kept on
  disk under `extractions/<version>/_held/`, which is **gitignored** — so the
  maintainer retains the source for the per-codename call without publishing it.
- Published artifacts that contained a held codename are **redacted in place**,
  with the token replaced by `[HELD-CODENAME]` so the surrounding structure is
  still useful and the redaction is reversible from the held copy.

## Currently Held

The specific codenames held for a release are recorded **privately** under that
version's gitignored `_held/` directory (e.g. `_held/HELD-INVENTORY.md`) and are
intentionally **not** named in this published file. Listing the name here would
pre-announce an unreleased model — exactly what this policy exists to prevent.

If you are the maintainer, see the `_held/` directory on your local checkout for
the current inventory and restore instructions.

## How to Release a Held Codename

1. Decide the codename is public.
2. Add its family to `ALLOW_RE` in `scripts/validate-extraction.sh`.
3. Replace `[HELD-CODENAME]` in the relevant `calls/*.txt` with the real token
   (the unredacted source is under `_held/`).
4. Re-run `scripts/validate-extraction.sh <version>` and confirm it exits 0.
5. Update `SUMMARY.md` / `README.md` if the codename should be documented.
