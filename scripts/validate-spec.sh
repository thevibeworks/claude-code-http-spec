#!/bin/sh
# shellcheck shell=sh
# Validate .http spec against cli.js extraction

set -eu

prog=${0##*/}

log() { printf '%s\n' "$*"; }
err() { printf '%s\n' "$*" >&2; }
die() { err "$prog: error: $*"; exit 1; }

usage() {
  cat <<EOF
$prog - Validate API spec against CLI source

USAGE:
  $prog <cli.js> [http-spec]

ARGUMENTS:
  cli.js     Path to formatted cli.js
  http-spec  Path to .http file (default: claude-code-api-complete.http)

EXAMPLES:
  $prog package/cli.js
  $prog package/cli.js claude-oauth-api.http
EOF
}

[ $# -ge 1 ] || { usage; exit 2; }
[ "$1" = "-h" ] || [ "$1" = "--help" ] && { usage; exit 0; }

CLI_JS="$1"
HTTP_SPEC="${2:-claude-code-api-complete.http}"

[ -f "$CLI_JS" ] || die "file not found: $CLI_JS"
[ -f "$HTTP_SPEC" ] || die "file not found: $HTTP_SPEC"

command -v rg >/dev/null 2>&1 || die "missing dependency: rg"

log "Validating: $HTTP_SPEC against $CLI_JS"
log ""

# Count endpoints in .http file
SPEC_COUNT=$(grep -cE '^(GET|POST|PUT|PATCH|DELETE|HEAD) \{\{' "$HTTP_SPEC" || echo 0)
log "Endpoints in spec: $SPEC_COUNT"

# Extract paths from .http file
SPEC_PATHS=$(mktemp)
grep -oE '(GET|POST|PUT|PATCH|DELETE|HEAD) \{\{[^}]+\}\}/[^ ]+' "$HTTP_SPEC" \
  | sed 's|.*}}/|/|' \
  | sed 's/\?.*//; s/{{[^}]*}}/.*/g' \
  | sort -u > "$SPEC_PATHS"

# Extract paths from cli.js
CODE_PATHS=$(mktemp)
{
  rg -o '"/(api|v1)/[^"]+' "$CLI_JS" 2>/dev/null || true
  rg -o 'https://api\.anthropic\.com/[^"]+' "$CLI_JS" 2>/dev/null | sed 's|https://api\.anthropic\.com||' || true
} | sed 's/"//g; s/\?.*//; s/${[^}]*}/.*/g' | sort -u > "$CODE_PATHS"

CODE_COUNT=$(wc -l < "$CODE_PATHS" | tr -d ' ')
log "Paths in code: $CODE_COUNT"
log ""

# Find undocumented (in code but not in spec)
UNDOC=$(mktemp)
while IFS= read -r path; do
  found=0
  while IFS= read -r spec_path; do
    if echo "$path" | grep -qE "^${spec_path}$"; then
      found=1
      break
    fi
  done < "$SPEC_PATHS"
  [ "$found" -eq 0 ] && echo "$path"
done < "$CODE_PATHS" > "$UNDOC"

UNDOC_COUNT=$(wc -l < "$UNDOC" | tr -d ' ')

# Find phantom (in spec but not in code)
PHANTOM=$(mktemp)
while IFS= read -r spec_path; do
  # Convert spec pattern to grep pattern
  pattern=$(echo "$spec_path" | sed 's/\./\\./g; s/\*/.*/g')
  if ! grep -qE "$pattern" "$CODE_PATHS" 2>/dev/null; then
    echo "$spec_path"
  fi
done < "$SPEC_PATHS" > "$PHANTOM"

PHANTOM_COUNT=$(wc -l < "$PHANTOM" | tr -d ' ')

# Report
if [ "$UNDOC_COUNT" -gt 0 ]; then
  log "=== UNDOCUMENTED ($UNDOC_COUNT) ==="
  log "In code but not in spec:"
  cat "$UNDOC"
  log ""
fi

if [ "$PHANTOM_COUNT" -gt 0 ]; then
  log "=== PHANTOM ($PHANTOM_COUNT) ==="
  log "In spec but not in code:"
  cat "$PHANTOM"
  log ""
fi

# Cleanup
rm -f "$SPEC_PATHS" "$CODE_PATHS" "$UNDOC" "$PHANTOM"

# Summary
log "=== SUMMARY ==="
log "Spec endpoints: $SPEC_COUNT"
log "Code paths:     $CODE_COUNT"
log "Undocumented:   $UNDOC_COUNT"
log "Phantom:        $PHANTOM_COUNT"

if [ "$UNDOC_COUNT" -eq 0 ] && [ "$PHANTOM_COUNT" -eq 0 ]; then
  log ""
  log "OK - spec matches code"
  exit 0
else
  log ""
  log "DRIFT DETECTED - spec and code differ"
  exit 1
fi
