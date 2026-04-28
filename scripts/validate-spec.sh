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
  $prog [--subset] <cli.js> [http-spec]

ARGUMENTS:
  cli.js     Path to formatted cli.js
  http-spec  Path to .http file (default: specs/claude-code-api-complete.http)

OPTIONS:
  --subset   Only validate that spec endpoints exist in code (ignore extra endpoints in code).

EXAMPLES:
  $prog package/cli.js
  $prog --subset package/cli.js specs/claude-oauth-api.http
EOF
}

MODE="complete"
if [ "${1:-}" = "--subset" ]; then
  MODE="subset"
  shift
fi

[ $# -ge 1 ] || { usage; exit 2; }
[ "$1" = "-h" ] || [ "$1" = "--help" ] && { usage; exit 0; }

CLI_JS="$1"
HTTP_SPEC="${2:-specs/claude-code-api-complete.http}"

[ -f "$CLI_JS" ] || die "file not found: $CLI_JS"
[ -f "$HTTP_SPEC" ] || die "file not found: $HTTP_SPEC"

command -v rg >/dev/null 2>&1 || die "missing dependency: rg"

log "Validating: $HTTP_SPEC against $CLI_JS"
log "Mode: $MODE"
log ""

# Count endpoints in .http file
SPEC_COUNT=$(grep -cE '^(GET|POST|PUT|PATCH|DELETE|HEAD) \{\{' "$HTTP_SPEC" || echo 0)
log "Endpoints in spec: $SPEC_COUNT"

# Extract paths from .http file
SPEC_PATHS=$(mktemp)
SPEC_RAW=$(mktemp)
grep -oE '^(GET|POST|PUT|PATCH|DELETE|HEAD) \{\{[^}]+\}\}/[^ ]+' "$HTTP_SPEC" > "$SPEC_RAW" 2>/dev/null || true
sed 's/^[A-Z][A-Z]* {{[^}]*}}//' "$SPEC_RAW" \
  | sed 's/\?.*//' \
  | sed 's/{{[^}]*}}/.*/g' \
  | sort -u > "$SPEC_PATHS"

# Extract paths from cli.js
# Note: modern builds use template strings (backticks) and `${...}` interpolation.
CODE_PATHS=$(mktemp)
CODE_RAW=$(mktemp)

# Relative paths in string literals
rg -o '"/(api|v1)/[^"]+' "$CLI_JS" >> "$CODE_RAW" 2>/dev/null || true
rg -o "'/(api|v1)/[^']+" "$CLI_JS" >> "$CODE_RAW" 2>/dev/null || true
rg -o '`/(api|v1)/[^`]+' "$CLI_JS" >> "$CODE_RAW" 2>/dev/null || true

# Common OAuth metadata path (used via `new URL("/.well-known/oauth-authorization-server", origin)`)
rg -o '"/\.well-known/oauth-authorization-server[^"]*' "$CLI_JS" >> "$CODE_RAW" 2>/dev/null || true
rg -o "'/\.well-known/oauth-authorization-server[^']*" "$CLI_JS" >> "$CODE_RAW" 2>/dev/null || true
rg -o '`/\.well-known/oauth-authorization-server[^`]*' "$CLI_JS" >> "$CODE_RAW" 2>/dev/null || true

# Full URLs for Anthropic hosts (strip host -> path)
rg -o 'https://api\.anthropic\.com/[^"[:space:]]+' "$CLI_JS" 2>/dev/null | sed 's|https://api.anthropic.com||' >> "$CODE_RAW" || true
rg -o 'https://console\.anthropic\.com/[^"[:space:]]+' "$CLI_JS" 2>/dev/null | sed 's|https://console.anthropic.com||' >> "$CODE_RAW" || true
rg -o 'https://platform\.claude\.com/[^"[:space:]]+' "$CLI_JS" 2>/dev/null | sed 's|https://platform.claude.com||' >> "$CODE_RAW" || true

# Narrow claude.ai extraction: only the domain info API endpoint (not browser/navigation URLs)
rg -o 'https://claude\.ai/api/web/domain_info[^"[:space:]]*' "$CLI_JS" 2>/dev/null | sed 's|https://claude.ai||' >> "$CODE_RAW" || true
rg -o 'https://claude\.ai/oauth/[^"[:space:]]+' "$CLI_JS" 2>/dev/null | sed 's|https://claude.ai||' >> "$CODE_RAW" || true

# Template string fragments that include BASE_API_URL interpolation
rg -o 'BASE_API_URL}/api/[^"[:space:]]+' "$CLI_JS" 2>/dev/null | sed 's|BASE_API_URL}||' >> "$CODE_RAW" || true
rg -o 'BASE_API_URL}/v1/[^"[:space:]]+' "$CLI_JS" 2>/dev/null | sed 's|BASE_API_URL}||' >> "$CODE_RAW" || true

# Stable API path fragments that are built from non-literal hosts (e.g. `${host}/api/...`).
rg -o '/api/event_logging/batch' "$CLI_JS" >> "$CODE_RAW" 2>/dev/null || true
rg -o '/v1/mcp_servers\\?limit=1000' "$CLI_JS" >> "$CODE_RAW" 2>/dev/null || true
rg -o '/v1/mcp/\\{server_id\\}' "$CLI_JS" >> "$CODE_RAW" 2>/dev/null || true
rg -o '/v1/oauth/hello' "$CLI_JS" >> "$CODE_RAW" 2>/dev/null || true

sed -e 's/\"//g' -e "s/'//g" -e 's/`//g' -e 's/[),;]$//' -e 's/\?.*//' -e 's/\${[^}]*}/.*/g' "$CODE_RAW" \
  | sed 's|^/\.well-known/oauth-authorization-server\..*|/.well-known/oauth-authorization-server|' \
  | sort -u > "$CODE_PATHS"

# Scope CODE_PATHS to endpoints we actually spec in this repo.
# Avoid false positives from bundled deps with generic `/v1/*` paths (e.g. Segment, AWS, Google libs).
CODE_PATHS_SCOPED=$(mktemp)
grep -E '^/api/(oauth|claude_code|claude_cli|organization|web|event_logging|hello)|^/oauth/|^/v1/(messages|files|models|skills|sessions|session_ingress|environment_providers|oauth|toolbox|complete|mcp|mcp_servers|token)|^/\.well-known/oauth-authorization-server' "$CODE_PATHS" \
  > "$CODE_PATHS_SCOPED" || true

CODE_COUNT=$(wc -l < "$CODE_PATHS_SCOPED" | tr -d ' ')
log "Paths in code: $CODE_COUNT"
log ""

UNDOC=""
UNDOC_COUNT=0
if [ "$MODE" = "complete" ]; then
  # Find undocumented (in code but not in spec)
  UNDOC=$(mktemp)
  while IFS= read -r path; do
    case "$path" in
      /oauth/*) continue ;; # Browser navigation URLs, not CLI HTTP calls
    esac
    found=0
    while IFS= read -r spec_path; do
      if echo "$path" | grep -qE "^${spec_path}$"; then
        found=1
        break
      fi
    done < "$SPEC_PATHS"
    [ "$found" -eq 0 ] && echo "$path"
  done < "$CODE_PATHS_SCOPED" > "$UNDOC"

  UNDOC_COUNT=$(wc -l < "$UNDOC" | tr -d ' ')
fi

# Find phantom (in spec but not in code)
PHANTOM=$(mktemp)
while IFS= read -r spec_path; do
  found=0
  while IFS= read -r path; do
    # Either direction can establish coverage because both sides may contain wildcards (`.*`).
    if echo "$path" | grep -qE "^${spec_path}$"; then
      found=1
      break
    fi
    if echo "$spec_path" | grep -qE "^${path}$"; then
      found=1
      break
    fi
  done < "$CODE_PATHS_SCOPED"
  [ "$found" -eq 0 ] && echo "$spec_path"
done < "$SPEC_PATHS" > "$PHANTOM"

PHANTOM_COUNT=$(wc -l < "$PHANTOM" | tr -d ' ')

# Report
if [ "$MODE" = "complete" ] && [ "$UNDOC_COUNT" -gt 0 ]; then
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
rm -f "$SPEC_RAW" "$CODE_RAW" "$SPEC_PATHS" "$CODE_PATHS" "$CODE_PATHS_SCOPED" "$PHANTOM"
[ -n "$UNDOC" ] && rm -f "$UNDOC"

# Summary
log "=== SUMMARY ==="
log "Spec endpoints: $SPEC_COUNT"
log "Code paths:     $CODE_COUNT"
log "Undocumented:   $UNDOC_COUNT"
log "Phantom:        $PHANTOM_COUNT"

if [ "$PHANTOM_COUNT" -eq 0 ] && { [ "$MODE" = "subset" ] || [ "$UNDOC_COUNT" -eq 0 ]; }; then
  log ""
  log "OK - spec matches code"
  exit 0
else
  log ""
  log "DRIFT DETECTED - spec and code differ"
  exit 1
fi
