#!/bin/sh
# shellcheck shell=sh
# Version: 0.1.0
# Compare API endpoints between two Claude Code CLI versions

set -eu
umask 077

prog=${0##*/}
VERSION=0.1.0

EXIT_OK=0
EXIT_ERROR=1
EXIT_USAGE=2

QUIET=0

log() { [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"; }
err() { printf '%s\n' "$*" >&2; }
die() { err "$prog: error: $*"; exit "$EXIT_ERROR"; }

usage() {
  cat <<EOF
$prog - Compare API endpoints between Claude Code versions

USAGE:
  $prog [OPTIONS] <old_cli.js> <new_cli.js>

OPTIONS:
  -q, --quiet        Suppress non-error output
  -h, --help         Show this help
  -V, --version      Show version

EXAMPLES:
  $prog old/cli.js new/cli.js
  $prog package-2.0.25/cli.js package-2.0.55/cli.js

OUTPUT:
  Shows added, removed, and unchanged endpoints between versions.
EOF
}

version() { printf '%s %s\n' "$prog" "$VERSION"; }
require() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

while [ $# -gt 0 ]; do
  case $1 in
    -h|--help) usage; exit "$EXIT_OK" ;;
    -V|--version) version; exit "$EXIT_OK" ;;
    -q|--quiet) QUIET=1 ;;
    --) shift; break ;;
    -*) die "unknown option: $1" ;;
    *) break ;;
  esac
  shift
done

if [ $# -lt 2 ]; then
  usage
  exit "$EXIT_USAGE"
fi

OLD_CLI="$1"
NEW_CLI="$2"

[ -f "$OLD_CLI" ] || die "file not found: $OLD_CLI"
[ -f "$NEW_CLI" ] || die "file not found: $NEW_CLI"

require rg
require comm

# Create temp files
OLD_ENDPOINTS=$(mktemp)
NEW_ENDPOINTS=$(mktemp)
trap 'rm -f "$OLD_ENDPOINTS" "$NEW_ENDPOINTS"' EXIT

# Extract endpoints from both
log "Extracting endpoints from old version..."
{
  rg -o '"/(api|v1)/[^"]+' "$OLD_CLI" 2>/dev/null || true
  rg -o 'https://api\.anthropic\.com/[^"]+' "$OLD_CLI" 2>/dev/null | sed 's|https://api\.anthropic\.com||' || true
} | sed 's/"//g' | sort -u > "$OLD_ENDPOINTS"

log "Extracting endpoints from new version..."
{
  rg -o '"/(api|v1)/[^"]+' "$NEW_CLI" 2>/dev/null || true
  rg -o 'https://api\.anthropic\.com/[^"]+' "$NEW_CLI" 2>/dev/null | sed 's|https://api\.anthropic\.com||' || true
} | sed 's/"//g' | sort -u > "$NEW_ENDPOINTS"

OLD_COUNT=$(wc -l < "$OLD_ENDPOINTS" | tr -d ' ')
NEW_COUNT=$(wc -l < "$NEW_ENDPOINTS" | tr -d ' ')

log ""
log "=== ENDPOINT COMPARISON ==="
log "Old version: $OLD_COUNT endpoints"
log "New version: $NEW_COUNT endpoints"
log ""

# Find added endpoints
ADDED_FILE=$(mktemp)
comm -13 "$OLD_ENDPOINTS" "$NEW_ENDPOINTS" > "$ADDED_FILE"
ADDED_COUNT=$(wc -l < "$ADDED_FILE" | tr -d ' ')

if [ "$ADDED_COUNT" -gt 0 ]; then
  log "=== ADDED ($ADDED_COUNT) ==="
  cat "$ADDED_FILE"
  log ""
fi

# Find removed endpoints
REMOVED_FILE=$(mktemp)
comm -23 "$OLD_ENDPOINTS" "$NEW_ENDPOINTS" > "$REMOVED_FILE"
REMOVED_COUNT=$(wc -l < "$REMOVED_FILE" | tr -d ' ')

if [ "$REMOVED_COUNT" -gt 0 ]; then
  log "=== REMOVED ($REMOVED_COUNT) ==="
  cat "$REMOVED_FILE"
  log ""
fi

rm -f "$ADDED_FILE" "$REMOVED_FILE"

# Summary
UNCHANGED=$((OLD_COUNT - REMOVED_COUNT))
log "=== SUMMARY ==="
log "Added:     $ADDED_COUNT"
log "Removed:   $REMOVED_COUNT"
log "Unchanged: $UNCHANGED"

if [ "$ADDED_COUNT" -gt 0 ] || [ "$REMOVED_COUNT" -gt 0 ]; then
  log ""
  log "Action: Update claude-code-api-complete.http with changes"
fi
