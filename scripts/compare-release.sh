#!/bin/sh
# shellcheck shell=sh
# Version: 1.0.0
# Compare extracted paths and beta flags between two release versions.
#
# Uses comm against byte-sorted inputs:
#   comm -13 OLD NEW  -> added in NEW
#   comm -23 OLD NEW  -> removed from OLD
#
# LC_ALL=C is pinned for BOTH sort and comm. An ambient UTF-8 locale makes comm
# fabricate phantom diffs even when both inputs are byte-sorted; this is the #1
# footgun in this pipeline.

set -eu
umask 077
export LC_ALL=C

prog=${0##*/}
VERSION=1.0.0

log() { printf '%s\n' "$*"; }
err() { printf '%s\n' "$*" >&2; }
die() { err "$prog: error: $*"; exit 1; }

usage() {
  cat <<EOF
$prog $VERSION - Compare paths and beta flags between two release versions

USAGE:
  $prog OLD_VERSION NEW_VERSION

ARGUMENTS:
  OLD_VERSION   e.g. 2.1.139
  NEW_VERSION   e.g. 2.1.170

OUTPUT:
  Prints added/removed for paths and beta flags. Written deltas can be pasted
  into extractions/v<NEW_VERSION>/SUMMARY.md.
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  -V|--version) printf '%s %s\n' "$prog" "$VERSION"; exit 0 ;;
esac

[ $# -ge 2 ] || { usage; exit 2; }
OLD="$1"
NEW="$2"

OLD_DIR="extractions/v${OLD}/raw"
NEW_DIR="extractions/v${NEW}/raw"

compare_one() {
  name="$1"
  old_f="$OLD_DIR/$name"
  new_f="$NEW_DIR/$name"
  [ -f "$old_f" ] || die "missing: $old_f"
  [ -f "$new_f" ] || die "missing: $new_f"

  # Re-sort defensively under C so comm never sees a mis-ordered input.
  o=$(mktemp); n=$(mktemp)
  LC_ALL=C sort -u "$old_f" > "$o"
  LC_ALL=C sort -u "$new_f" > "$n"

  added=$(LC_ALL=C comm -13 "$o" "$n")
  removed=$(LC_ALL=C comm -23 "$o" "$n")
  rm -f "$o" "$n"

  total=$(wc -l < "$new_f" | tr -d ' ')
  na=$(printf '%s' "$added" | grep -c . || true)
  nr=$(printf '%s' "$removed" | grep -c . || true)

  log "## ${name%.txt}: $total total, $na added, $nr removed (v$OLD -> v$NEW)"
  log ""
  log "### Added"
  if [ "$na" -gt 0 ]; then printf '%s\n' "$added" | sed 's/^/- /'; else log "None."; fi
  log ""
  log "### Removed"
  if [ "$nr" -gt 0 ]; then printf '%s\n' "$removed" | sed 's/^/- /'; else log "None."; fi
  log ""
}

compare_one "paths.txt"
compare_one "beta_flags.txt"
