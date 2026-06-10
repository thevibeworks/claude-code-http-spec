#!/bin/sh
# shellcheck shell=sh
# Version: 1.0.0
# Extract stable string literals (API paths + beta flags) from a Claude Code
# release binary.
#
# Modern releases (>= v2.1.117) ship as a Bun-compiled binary. String literals
# survive in the constant pool, so `strings` + grep is the extraction method.
# All output lists are byte-sorted-unique (LC_ALL=C sort -u) so they diff
# deterministically across versions.

set -eu
umask 077
export LC_ALL=C

prog=${0##*/}
VERSION=1.0.0

log() { printf '%s\n' "$*"; }
err() { printf '%s\n' "$*" >&2; }
die() { err "$prog: error: $*"; exit 1; }
require() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

usage() {
  cat <<EOF
$prog $VERSION - Extract API paths and beta flags from a release binary

USAGE:
  $prog [-b BINARY] VERSION

ARGUMENTS:
  VERSION       Version label for the output dir, e.g. 2.1.170

OPTIONS:
  -b BINARY     Path to the unpacked 'claude' binary
                (default: ../claude-code-reverse/binary_<VERSION>/claude)

OUTPUT:
  extractions/v<VERSION>/raw/paths.txt
  extractions/v<VERSION>/raw/beta_flags.txt
  extractions/v<VERSION>/raw/pkg_version.txt

EXAMPLES:
  $prog 2.1.170
  $prog -b /path/to/claude 2.1.170
EOF
}

BINARY=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -V|--version) printf '%s %s\n' "$prog" "$VERSION"; exit 0 ;;
    -b) BINARY="$2"; shift ;;
    -*) die "unknown option: $1" ;;
    *) break ;;
  esac
  shift
done

[ $# -ge 1 ] || { usage; exit 2; }
VER="$1"

[ -n "$BINARY" ] || BINARY="../claude-code-reverse/binary_${VER}/claude"
[ -f "$BINARY" ] || die "binary not found: $BINARY (pass -b PATH)"

require strings
require grep

OUT="extractions/v${VER}/raw"
mkdir -p "$OUT"

STR=$(mktemp)
trap 'rm -f "$STR"' EXIT
log "Reading strings from: $BINARY"
strings -n 6 "$BINARY" > "$STR"

# API path literals: quoted "/api/..." or "/v1/..." fragments.
log "Extracting API paths..."
grep -oE '"/(api|v1)/[^"]+' "$STR" | LC_ALL=C sort -u > "$OUT/paths.txt" || true

# Beta flags: lowercase token ending in a dated suffix YYYY-MM-DD.
log "Extracting beta flags..."
grep -oE '[a-z][-a-z]*-20[0-9]{2}-[0-9]{2}-[0-9]{2}' "$STR" | LC_ALL=C sort -u > "$OUT/beta_flags.txt" || true

# Package version, if discoverable in the binary string pool.
PKGVER=$(grep -oE 'claude-cli/[0-9]+\.[0-9]+\.[0-9]+' "$STR" | head -1 | sed 's#claude-cli/##' || true)
[ -n "$PKGVER" ] || PKGVER="$VER"
{
  printf 'version: %s\n' "$PKGVER"
  printf 'source: binary (Bun compiled)\n'
} > "$OUT/pkg_version.txt"

PATHS=$(wc -l < "$OUT/paths.txt" | tr -d ' ')
BETAS=$(wc -l < "$OUT/beta_flags.txt" | tr -d ' ')

log ""
log "paths.txt:      $PATHS"
log "beta_flags.txt: $BETAS"
log ""
log "Next: scripts/compare-release.sh <previous> $VER"
