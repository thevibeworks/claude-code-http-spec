---
name: New release to document
about: A new Claude Code release should be extracted and compared
title: "[version] document vX.Y.Z"
labels: version
---

**New version**
The npm version to document (e.g. `2.1.171`), or `latest`.

**Previous documented version**
The version it should be compared against (e.g. `2.1.170`).

**Checklist**
- [ ] `scripts/fetch-release.sh <version>` (manifest only; no binary committed)
- [ ] `scripts/extract-binary.sh <version>`
- [ ] `scripts/compare-release.sh <previous> <version>`
- [ ] `scripts/validate-extraction.sh <version>` exits 0
- [ ] Any unreleased codename recorded in `FLAGGED.md` and redacted
- [ ] `specs/*.http` and `README.md` updated to the new version
