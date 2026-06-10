# Contributing

This repo documents the HTTP API surface of the `@anthropic-ai/claude-code`
release by extracting **stable string literals** from the published npm
package. It is release documentation and compatibility tracking, not a runtime
tool. Every documented fact must trace back to a literal in a specific
published version.

## Quick Start

```bash
git clone https://github.com/thevibeworks/claude-code-http-spec.git
cd claude-code-http-spec

# Pull a release, extract, compare to previous, validate the gates.
scripts/fetch-release.sh latest
scripts/extract-binary.sh <version>
scripts/compare-release.sh <previous> <version>
scripts/validate-extraction.sh <version>
```

`scripts/validate-extraction.sh` is the gate. It must exit 0 before any
extraction is published.

## Ground Rules

- **Literals only.** Document URL paths, beta flags, header names, env-var
  names, and published model IDs that appear as literal strings in the
  release. Do not infer endpoints from runtime logs, and do not document
  obfuscated minifier names (they change every build).
- **Pin `LC_ALL=C`** for both `sort` and `comm`. An ambient UTF-8 locale makes
  `comm` fabricate phantom diffs even when both inputs are byte-sorted. This is
  the single most common mistake; the scripts pin it for you.
- **Never commit the binary or unpacked package.** They are large and
  redistributable artifacts. Record name, version, sha512 integrity, the
  unpacked file list, and the binary size in a manifest instead. `.gitignore`
  is configured to keep them out.
- **Hold unreleased model codenames.** If extraction surfaces a model codename
  that is not on the public allowlist in `scripts/validate-extraction.sh`, the
  validator fails loudly. Do not publish it. Record what was held in
  `FLAGGED.md` and redact it from any curated artifact. See that file for the
  current policy.
- **No secrets, ever.** The validator scans for API keys, bearer tokens,
  refresh tokens, home-directory paths, and private-key headers. If it flags
  something, the extraction does not ship.

## Adding a New Version

1. `scripts/fetch-release.sh <version>` — writes a manifest under
   `extractions/v<version>/MANIFEST.txt` (metadata + hashes only).
2. `scripts/extract-binary.sh <version>` — writes `raw/paths.txt` and
   `raw/beta_flags.txt`, byte-sorted and unique.
3. `scripts/compare-release.sh <previous> <version>` — writes the
   added/removed deltas into `SUMMARY.md`.
4. `scripts/validate-extraction.sh <version>` — must exit 0.
5. Update `specs/*.http` and `README.md` so the documented version matches.

## Style

- Shell scripts are POSIX `sh` where practical, `set -eu`, one job each.
- Keep raw lists machine-diffable: one literal per line, `LC_ALL=C sort -u`.
- Match the existing layout under `extractions/v<version>/`.

## Bug Reports

Open an issue with:

1. The release version in question (`claude --version`, or the npm version).
2. The literal or endpoint that looks wrong, and the file path where it lives.
3. The `rg` / `strings` pattern that does or does not reproduce it.
