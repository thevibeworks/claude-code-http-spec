#!/bin/sh
# shellcheck shell=sh
# Version: 0.2.0
# Extract HTTP endpoints from Claude Code CLI using stable string patterns

set -eu
umask 077

prog=${0##*/}
VERSION=0.2.0

EXIT_OK=0
EXIT_ERROR=1
EXIT_USAGE=2

QUIET=0
OUTPUT_DIR="extraction"

log() { [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"; }
err() { printf '%s\n' "$*" >&2; }
die() { err "$prog: error: $*"; exit "$EXIT_ERROR"; }

usage() {
  cat <<EOF
$prog - Extract HTTP endpoints from Claude Code CLI

USAGE:
  $prog [OPTIONS] <cli.js>

OPTIONS:
  -o, --output DIR   Output directory (default: extraction/)
  -q, --quiet        Suppress non-error output
  -h, --help         Show this help
  -V, --version      Show version

EXAMPLES:
  $prog package/cli.js
  $prog -o ./out package/cli.js

WORKFLOW:
  1. npm pack @anthropic-ai/claude-code@latest
  2. tar -xzf anthropic-ai-claude-code-*.tgz
  3. npx prettier --write package/cli.js
  4. $prog package/cli.js
  5. Review extraction/ directory

METHODOLOGY:
  Searches for STABLE string literals (URLs, paths, headers)
  NOT obfuscated function names (which change every build)
EOF
}

version() { printf '%s %s\n' "$prog" "$VERSION"; }
require() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

# Run extraction and warn if no matches
run_extract() {
  pattern="$1"
  outfile="$2"
  rg -o "$pattern" "$CLI_JS" 2>/dev/null | sort -u > "$outfile" || true
  if [ ! -s "$outfile" ]; then
    err "  warning: no matches for ${outfile##*/}"
  fi
}

while [ $# -gt 0 ]; do
  case $1 in
    -h|--help) usage; exit "$EXIT_OK" ;;
    -V|--version) version; exit "$EXIT_OK" ;;
    -q|--quiet) QUIET=1 ;;
    -o|--output) OUTPUT_DIR="$2"; shift ;;
    --) shift; break ;;
    -*) die "unknown option: $1" ;;
    *) break ;;
  esac
  shift
done

if [ $# -eq 0 ]; then
  usage
  exit "$EXIT_USAGE"
fi

CLI_JS="$1"
[ -f "$CLI_JS" ] || die "file not found: $CLI_JS"

require rg

mkdir -p "$OUTPUT_DIR"

log "Extracting from: $CLI_JS"
log "Output directory: $OUTPUT_DIR"
log ""
log "Using stable string patterns (not obfuscated function names)"

# --- URL extraction (stable) ---

log ""
log "=== URL EXTRACTION ==="

log "Extracting all URLs..."
run_extract 'https://[^"'\''`]+' "$OUTPUT_DIR/all_urls.txt"

log "Extracting Anthropic API URLs..."
run_extract 'https://api\.anthropic\.com[^"'\''`]*' "$OUTPUT_DIR/api_urls.txt"

log "Extracting Console URLs..."
run_extract 'https://console\.anthropic\.com[^"'\''`]*' "$OUTPUT_DIR/console_urls.txt"

log "Extracting API path strings..."
run_extract '"/(api|v1)/[^"]+' "$OUTPUT_DIR/path_literals.txt"

log "Extracting org-scoped paths..."
run_extract '/organizations/[^"'\''`]+' "$OUTPUT_DIR/org_paths.txt"

# --- Header and payload extraction ---

log ""
log "=== HEADERS & PAYLOADS ==="

log "Extracting HTTP headers..."
run_extract '"(Authorization|Content-Type|User-Agent|anthropic-beta|anthropic-version|x-api-key|x-organization-uuid)"' "$OUTPUT_DIR/headers.txt"

log "Extracting beta flags..."
run_extract '"[a-z-]+-[0-9]{4}-[0-9]{2}-[0-9]{2}"' "$OUTPUT_DIR/beta_flags.txt"

log "Extracting OAuth scopes..."
run_extract '"user:[^"]*"' "$OUTPUT_DIR/scopes.txt"

log "Extracting grant types..."
rg 'grant_type' "$CLI_JS" -C 2 > "$OUTPUT_DIR/grant_types.txt" 2>/dev/null || true
if [ ! -s "$OUTPUT_DIR/grant_types.txt" ]; then
  err "  warning: no matches for grant_types.txt"
fi

# --- Version metadata ---

log ""
log "=== METADATA ==="

CLI_VERSION=$(rg -o 'claude-cli/[0-9]+\.[0-9]+\.[0-9]+' "$CLI_JS" -m 1 2>/dev/null | sed 's/claude-cli\///' || echo "unknown")
log "CLI version: $CLI_VERSION"

cat > "$OUTPUT_DIR/METADATA" <<EOF
CLI_VERSION=$CLI_VERSION
CLI_FILE=$CLI_JS
EXTRACTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
PATH_COUNT=$(wc -l < "$OUTPUT_DIR/path_literals.txt" 2>/dev/null | tr -d ' ' || echo 0)
URL_COUNT=$(wc -l < "$OUTPUT_DIR/all_urls.txt" 2>/dev/null | tr -d ' ' || echo 0)
EOF

# --- Summary ---

log ""
log "=== EXTRACTION SUMMARY ==="

count_lines() {
  if [ -f "$1" ]; then
    wc -l < "$1" | tr -d ' '
  else
    echo "0"
  fi
}

log "All URLs:         $(count_lines "$OUTPUT_DIR/all_urls.txt") unique"
log "API URLs:         $(count_lines "$OUTPUT_DIR/api_urls.txt") unique"
log "Console URLs:     $(count_lines "$OUTPUT_DIR/console_urls.txt") unique"
log "Path literals:    $(count_lines "$OUTPUT_DIR/path_literals.txt") unique"
log "Org-scoped:       $(count_lines "$OUTPUT_DIR/org_paths.txt") unique"
log "Beta flags:       $(count_lines "$OUTPUT_DIR/beta_flags.txt") unique"
log "Scopes:           $(count_lines "$OUTPUT_DIR/scopes.txt") unique"

log ""
log "Output saved to: $OUTPUT_DIR/"
log ""
log "Next steps:"
log "  1. Review path_literals.txt for endpoint paths"
log "  2. Verify each with: rg 'path_string' $CLI_JS"
log "  3. Update claude-code-api-complete.http"
