#!/bin/sh
# shellcheck shell=sh
# Version: 1.0.0
# Validate an extraction before it is published.
#
# Gates (any failure => non-zero exit):
#   (a) LC_ALL=C ordering for sort AND comm; raw lists verified C-ordered.
#   (b) Secrets / home-path scan (api keys, bearer tokens, refresh tokens,
#       /Users/, /home/, private-key headers).
#   (c) Unreleased-codename gate: any model codename not on the public
#       allowlist is flagged loudly and fails the run.
#   (d) SUMMARY.md counts must match raw file line counts.
#   (e) All raw lists must be byte-sorted-unique.
#   (f) File-size cap: reject multi-MB bundled lines / oversized call files.
#
# Pin LC_ALL=C globally so sort and comm are byte-deterministic. An ambient
# UTF-8 locale makes comm fabricate phantom diffs; that is the #1 footgun here.

set -eu
export LC_ALL=C

prog=${0##*/}
VERSION=1.0.0

# --- Public model allowlist -------------------------------------------------
# Released, public model families. A codename NOT matching this set is treated
# as unreleased and MUST be held (see FLAGGED.md). fable-5 IS released.
# Edit deliberately; expanding this is a publish decision.
ALLOW_RE='^claude-(opus|sonnet|haiku|fable)-'

# Token shape for "model codename" candidates we scan for.
MODEL_TOKEN_RE='claude-[a-z]+-[0-9a-z][0-9a-z-]*'

# --- Size caps (per current, tidy releases) --------------------------------
MAX_FILE_BYTES=1048576   # 1 MB per extraction file
MAX_LINE_BYTES=8192      # 8 KB per line (catches bundled minified blobs)

log()  { printf '%s\n' "$*"; }
ok()   { printf 'OK    %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*" >&2; }
fail() { printf 'FAIL  %s\n' "$*" >&2; FAILED=1; }
die()  { printf '%s: error: %s\n' "$prog" "$*" >&2; exit 2; }

usage() {
  cat <<EOF
$prog $VERSION - Validate an extraction before publishing

USAGE:
  $prog [VERSION]

ARGUMENTS:
  VERSION   e.g. 2.1.170 (default: highest extractions/v* dir)

EXIT:
  0  all gates pass
  1  a gate failed
  2  usage / environment error
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  -V|--version) printf '%s %s\n' "$prog" "$VERSION"; exit 0 ;;
esac

command -v rg >/dev/null 2>&1 || die "missing dependency: rg"

# Resolve version (default: highest version dir).
if [ $# -ge 1 ]; then
  VER="$1"
else
  VER=$(ls -1 extractions 2>/dev/null | sed -n 's/^v//p' \
        | LC_ALL=C sort -t. -k1,1n -k2,2n -k3,3n | tail -1)
  [ -n "$VER" ] || die "no extractions/v* dirs found"
fi

DIR="extractions/v${VER}"
[ -d "$DIR" ] || die "no such extraction: $DIR"

FAILED=0
log "Validating $DIR (LC_ALL=C)"
log ""

# --- Gate (a): LC_ALL=C ordering proof -------------------------------------
log "[a] LC_ALL=C sort/comm ordering"
case "$LC_ALL" in
  C) ok "LC_ALL is pinned to C" ;;
  *) fail "LC_ALL is not C (got '$LC_ALL')" ;;
esac

# --- Gate (e): raw lists sorted-unique (and (a) ordering applied to them) ---
log ""
log "[e] raw lists byte-sorted-unique"
for f in "$DIR"/raw/paths.txt "$DIR"/raw/beta_flags.txt; do
  [ -f "$f" ] || { fail "missing raw list: $f"; continue; }
  if LC_ALL=C sort -u "$f" | cmp -s - "$f"; then
    ok "${f#"$DIR"/} sorted-unique under LC_ALL=C"
  else
    fail "${f#"$DIR"/} is NOT LC_ALL=C sort -u stable"
  fi
done

# --- Gate (f): file-size cap ------------------------------------------------
log ""
log "[f] file-size / line-length cap"
SIZE_OK=1
while IFS= read -r f; do
  bytes=$(wc -c < "$f" | tr -d ' ')
  if [ "$bytes" -gt "$MAX_FILE_BYTES" ]; then
    fail "oversized file ($bytes B > $MAX_FILE_BYTES): ${f#"$DIR"/}"
    SIZE_OK=0
  fi
  longest=$(awk '{ if (length > m) m = length } END { print m+0 }' "$f")
  if [ "$longest" -gt "$MAX_LINE_BYTES" ]; then
    fail "bundled line ($longest B > $MAX_LINE_BYTES): ${f#"$DIR"/}"
    SIZE_OK=0
  fi
done <<EOF
$(find "$DIR" -type f -name '*.txt')
EOF
[ "$SIZE_OK" -eq 1 ] && ok "all files within $MAX_FILE_BYTES B / $MAX_LINE_BYTES B/line"

# --- Gate (b): secrets / home-path scan ------------------------------------
log ""
log "[b] secrets / home-path scan"
SECRET_RE='sk-[A-Za-z0-9]{20,}|Bearer [A-Za-z0-9._-]{20,}|refreshToken|/Users/|/home/|BEGIN (RSA |OPENSSH |)PRIVATE'
HITS=$(rg -n --no-heading -e "$SECRET_RE" "$DIR" 2>/dev/null || true)
if [ -n "$HITS" ]; then
  fail "secret/home-path pattern found:"
  printf '%s\n' "$HITS" | sed 's/^/      /' >&2
else
  ok "no secrets or home paths"
fi

# --- Gate (c): unreleased-codename gate ------------------------------------
log ""
log "[c] unreleased-codename gate"
# -I/--no-filename so candidates are bare tokens, not "path:token".
CANDIDATES=$(rg -oNI -e "$MODEL_TOKEN_RE" "$DIR" 2>/dev/null | LC_ALL=C sort -u || true)
UNRELEASED=""
for tok in $CANDIDATES; do
  # Ignore non-model artifacts that share the prefix.
  case "$tok" in
    claude-code-*) continue ;;
  esac
  if printf '%s\n' "$tok" | grep -qE "$ALLOW_RE"; then
    continue
  fi
  UNRELEASED="$UNRELEASED $tok"
done
if [ -n "$UNRELEASED" ]; then
  fail "UNRELEASED model codename(s) present and must be held (see FLAGGED.md):"
  for tok in $UNRELEASED; do
    printf '      %s\n' "$tok" >&2
    rg -ln -e "$tok" "$DIR" 2>/dev/null | sed 's/^/        in /' >&2
  done
else
  ok "only allowlisted model families present"
fi

# --- Gate (d): SUMMARY counts match raw line counts -------------------------
log ""
log "[d] SUMMARY counts match raw line counts"
SUMMARY="$DIR/SUMMARY.md"
if [ ! -f "$SUMMARY" ]; then
  warn "no SUMMARY.md; skipping count cross-check"
else
  check_count() {
    label="$1"; rawfile="$2"
    [ -f "$rawfile" ] || { fail "missing raw file for $label: $rawfile"; return; }
    raw_n=$(wc -l < "$rawfile" | tr -d ' ')
    # Match a line like: "Paths: 59 total" / "Beta flags: 43 total" (case-insensitive).
    sum_n=$(grep -ioE "${label}[^0-9]*[0-9]+ total" "$SUMMARY" | grep -oE '[0-9]+ total' | grep -oE '[0-9]+' | head -1 || true)
    if [ -z "$sum_n" ]; then
      warn "$label: no 'N total' line in SUMMARY.md (raw=$raw_n)"
      return
    fi
    if [ "$sum_n" = "$raw_n" ]; then
      ok "$label: SUMMARY=$sum_n == raw=$raw_n"
    else
      fail "$label: SUMMARY=$sum_n != raw=$raw_n"
    fi
  }
  check_count "Paths" "$DIR/raw/paths.txt"
  check_count "Beta flags" "$DIR/raw/beta_flags.txt"
fi

log ""
if [ "$FAILED" -eq 0 ]; then
  log "PASS: all gates green for v$VER"
  exit 0
else
  log "FAILED: one or more gates failed for v$VER"
  exit 1
fi
