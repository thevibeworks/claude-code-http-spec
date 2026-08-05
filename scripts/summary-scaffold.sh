#!/usr/bin/env bash
# summary-scaffold.sh — write the mechanical half of extractions/v<version>/SUMMARY.md.
#
# Usage:
#   scripts/summary-scaffold.sh <version> [previous-version]
#
# Why this exists: validate-extraction.sh gate (d) cross-checks the counts in
# SUMMARY.md against the raw file line counts, but nothing in the pipeline ever
# wrote a SUMMARY.md. Every run printed
#
#   warn: no SUMMARY.md; skipping count cross-check
#
# so gate (d) had never validated anything, and the PR body told reviewers to
# read a file that did not exist.
#
# Counts are taken from COMPARE.txt — the compare step's own output — NOT from
# the raw files. That is deliberate: gate (d) then compares two independently
# produced numbers (compare-release.sh vs `wc -l` on raw/) and fires if they
# ever disagree. Deriving them from the raw files would make the gate
# tautological, which is the failure mode this is meant to end.
#
# The interpretation — what the new paths mean, what a removal implies — is
# left as TODO(review). Never overwrites an existing SUMMARY.md.
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

version="${1:-}"
prev="${2:-}"
[[ -n "$version" ]] || { echo "usage: $0 <version> [previous-version]" >&2; exit 2; }

ver_bare="${version#v}"
prev_bare="${prev#v}"
dir="$ROOT/extractions/v${ver_bare}"
[[ -d "$dir" ]] || { echo "ERROR: no extraction dir: $dir" >&2; exit 1; }

summary="$dir/SUMMARY.md"
if [[ -f "$summary" ]]; then
  echo "summary: $summary already exists; leaving it alone" >&2
  exit 0
fi

compare="$dir/COMPARE.txt"

# Pull "## <key>: N total, X added, Y removed" out of COMPARE.txt.
compare_line() { grep -iE "^## $1:" "$compare" 2>/dev/null | head -1 || true; }
field() { grep -oE "[0-9]+ $2" <<< "$1" | grep -oE '^[0-9]+' | head -1 || true; }

{
  echo "# Extraction Summary: v${ver_bare}"
  echo
  echo "Source: \`@anthropic-ai/claude-code-linux-x64@${ver_bare}\` (Bun binary)"
  if [[ -n "$prev_bare" ]]; then
    echo "Previous extraction: v${prev_bare} (binary)"
  else
    echo "Previous extraction: none (first documented version)"
  fi
  echo
  echo "## Architecture Note"
  echo
  echo "<!-- TODO(review): distribution shape vs the previous version — wrapper"
  echo "     package, where the extractable strings live, anything that changed"
  echo "     about how the release is packed. -->"

  if [[ -f "$compare" && -n "$prev_bare" ]]; then
    for pair in "paths:Paths:API Path" "beta_flags:Beta flags:Beta Flag"; do
      key="${pair%%:*}"; rest="${pair#*:}"; label="${rest%%:*}"; heading="${rest#*:}"
      line="$(compare_line "$key")"
      [[ -n "$line" ]] || continue
      total="$(field "$line" total)"; added="$(field "$line" added)"; removed="$(field "$line" removed)"
      echo
      echo "## ${heading} Changes vs v${prev_bare}"
      echo
      # Gate (d) matches "<label> ... N total" — keep this wording in step with it.
      echo "${label}: ${total} total, ${added} added, ${removed} removed."
      echo
      echo "<!-- TODO(review): say what the ${added} added and ${removed} removed"
      echo "     entries mean. Full lists are in COMPARE.txt. -->"
    done
  else
    echo
    echo "## Changes"
    echo
    echo "<!-- No COMPARE.txt (first documented version, or compare skipped). -->"
  fi

  echo
  echo "See \`COMPARE.txt\` for the full added/removed lists and \`MANIFEST.txt\`"
  echo "for the resolved version and hashes."
  if [[ -f "$ROOT/FLAGGED.md" ]]; then
    echo
    echo "If a model codename was held, see \`FLAGGED.md\`."
  fi
} > "$summary"

echo "summary: wrote scaffold $summary" >&2
grep -iE '[0-9]+ total' "$summary" | sed 's/^/  /' >&2 || true
