#!/bin/sh
# shellcheck shell=sh
# Version: 1.0.0
# Render a release binary as text that the rg-based tooling can read.
#
# Every byte outside printable ASCII becomes a newline. Two things fall out:
#
#   * the constant pool, where literals are separated by NUL padding, becomes
#     one literal per line -- so `rg -o '"/api/[^"]+'` stops running off the end
#     of a string into whatever data follows it;
#   * the embedded JavaScript bundle, which is entirely printable, stays as one
#     very long line, which is what the quote-delimited patterns expect.
#
# This is the input to scripts/validate-spec.sh for a compiled release. Output
# is roughly the size of the binary; write it outside the repo.
#
# Usage:
#   scripts/binary-literals.sh <binary> <out-file>

set -eu
umask 077

prog=${0##*/}

err() { printf '%s\n' "$*" >&2; }
die() { err "$prog: error: $*"; exit 1; }

[ $# -eq 2 ] || { err "usage: $prog <binary> <out-file>"; exit 2; }
[ -f "$1" ] || die "binary not found: $1"

command -v tr >/dev/null 2>&1 || die "missing dependency: tr"

# Complement of printable ASCII (0x20-0x7E) -> newline. LC_ALL=C so tr works on
# bytes rather than trying to decode UTF-8.
LC_ALL=C tr -c '\40-\176' '\n' < "$1" > "$2"

printf '%s -> %s (%s lines)\n' "$1" "$2" "$(wc -l < "$2" | tr -d ' ')"
