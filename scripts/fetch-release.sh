#!/bin/sh
# shellcheck shell=sh
# Version: 1.0.0
# Fetch a Claude Code release and record a metadata manifest.
#
# Records package name/version/sha512 integrity, the unpacked file list, and
# the platform-binary size into extractions/v<version>/MANIFEST.txt.
# It NEVER stores the binary or the unpacked package in the repo; those are
# large, redistributable artifacts and are kept out by .gitignore.

set -eu
umask 077
export LC_ALL=C

prog=${0##*/}
VERSION=1.0.0

PKG_MAIN="@anthropic-ai/claude-code"
PKG_LINUX="@anthropic-ai/claude-code-linux-x64"

log() { printf '%s\n' "$*"; }
err() { printf '%s\n' "$*" >&2; }
die() { err "$prog: error: $*"; exit 1; }
require() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

usage() {
  cat <<EOF
$prog $VERSION - Fetch a Claude Code release and record a manifest

USAGE:
  $prog [VERSION]

ARGUMENTS:
  VERSION   npm version (e.g. 2.1.170) or dist-tag (default: latest)

OUTPUT:
  extractions/v<resolved-version>/MANIFEST.txt
  Downloaded tarballs are removed after hashing. The binary is never kept.

EXAMPLES:
  $prog latest
  $prog 2.1.170
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  -V|--version) printf '%s %s\n' "$prog" "$VERSION"; exit 0 ;;
esac

require npm
require shasum 2>/dev/null || require sha512sum

REQ_VERSION="${1:-latest}"

# Resolve dist-tag -> concrete version.
log "Resolving $PKG_MAIN dist-tags..."
DIST_JSON=$(npm view "$PKG_MAIN" dist-tags --json) || die "npm view failed"
if printf '%s\n' "$REQ_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  RESOLVED="$REQ_VERSION"
else
  RESOLVED=$(printf '%s\n' "$DIST_JSON" | sed -n "s/.*\"$REQ_VERSION\"[[:space:]]*:[[:space:]]*\"\([0-9.]*\)\".*/\1/p")
  [ -n "$RESOLVED" ] || die "could not resolve dist-tag '$REQ_VERSION' from: $DIST_JSON"
fi
log "Resolved version: $RESOLVED"

OUT_DIR="extractions/v${RESOLVED}"
mkdir -p "$OUT_DIR"
MANIFEST="$OUT_DIR/MANIFEST.txt"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

sha512_of() {
  if command -v sha512sum >/dev/null 2>&1; then
    sha512sum "$1" | cut -d' ' -f1
  else
    shasum -a 512 "$1" | cut -d' ' -f1
  fi
}

# Pull a package tarball into $WORK, return its filename via stdout.
pack() {
  pkg="$1"
  ver="$2"
  ( cd "$WORK" && npm pack "${pkg}@${ver}" --silent ) \
    || die "npm pack ${pkg}@${ver} failed"
  ls -1 "$WORK"/*.tgz | tail -1
}

emit_pkg() {
  pkg="$1"
  label="$2"
  tgz=$(pack "$pkg" "$RESOLVED")
  sha=$(sha512_of "$tgz")
  size=$(wc -c < "$tgz" | tr -d ' ')
  {
    printf '[%s]\n' "$label"
    printf 'package: %s@%s\n' "$pkg" "$RESOLVED"
    printf 'tarball: %s\n' "${tgz##*/}"
    printf 'tarball_bytes: %s\n' "$size"
    printf 'sha512: %s\n' "$sha"
  } >> "$MANIFEST"

  # Unpacked file list (names + sizes only; contents are not stored).
  unpack="$WORK/unpack-$label"
  mkdir -p "$unpack"
  tar -xzf "$tgz" -C "$unpack"
  printf 'unpacked_files:\n' >> "$MANIFEST"
  ( cd "$unpack" && find . -type f -printf '%s\t%p\n' 2>/dev/null \
      || find . -type f -exec sh -c 'printf "%s\t%s\n" "$(wc -c <"$1")" "$1"' _ {} \; ) \
    | LC_ALL=C sort -k2 | sed 's/^/  /' >> "$MANIFEST"

  # The platform package carries the binary. Record its size, then drop it.
  bin="$unpack/package/claude"
  if [ -f "$bin" ]; then
    bsize=$(wc -c < "$bin" | tr -d ' ')
    printf 'binary: package/claude\n' >> "$MANIFEST"
    printf 'binary_bytes: %s\n' "$bsize" >> "$MANIFEST"
  fi
  printf '\n' >> "$MANIFEST"
}

{
  printf '# Release manifest\n'
  printf 'resolved_version: %s\n' "$RESOLVED"
  printf 'requested: %s\n' "$REQ_VERSION"
  printf 'recorded_at: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'dist_tags: %s\n' "$DIST_JSON"
  printf '\n'
} > "$MANIFEST"

emit_pkg "$PKG_MAIN" "wrapper"
emit_pkg "$PKG_LINUX" "linux-x64"

log ""
log "Manifest written: $MANIFEST"
log "Tarballs and unpacked trees discarded (not committed)."
log ""
log "Next: scripts/extract-binary.sh $RESOLVED"
