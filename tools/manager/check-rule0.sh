#!/usr/bin/env bash
# Task 079: does the rule-0 block of CLAUDE.md still match its reviewed reference copy, byte for byte?
#   check-rule0.sh [<claude-md> [<reference-md>]]     defaults: CLAUDE.md and docs/manager/rule0.reference.md in the repo root
# Block = from the line starting "0. **THE TOKEN GUARD" up to, not including, the line starting "1. **English everywhere**".
# Reference = everything after the single marker line "<!-- RULE0-REFERENCE-BEGIN -->".
# Exit 0 = identical; 1 = differs (unified diff printed); 2 = file, block, marker or reference missing or ambiguous (never a skip).
set -u
die() { echo "check-rule0: $*" >&2; exit 2; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
claude=${1:-$root/CLAUDE.md}; ref=${2:-$root/docs/manager/rule0.reference.md}
[ $# -le 2 ] || die "usage: check-rule0.sh [<claude-md> [<reference-md>]]"
[ -f "$claude" ] && [ -r "$claude" ] || die "cannot read '$claude'"
[ -f "$ref" ] && [ -r "$ref" ] || die "cannot read reference '$ref'"
START='^0\. \*\*THE TOKEN GUARD'; END='^1\. \*\*English everywhere'; MARK='<!-- RULE0-REFERENCE-BEGIN -->'
[ "$(grep -c -- "$START" "$claude")" -eq 1 ] || die "'$claude' must have exactly one line starting '0. **THE TOKEN GUARD'"
[ "$(grep -c -- "$END" "$claude")" -eq 1 ] || die "'$claude' must have exactly one line starting '1. **English everywhere'"
s=$(grep -n -- "$START" "$claude" | cut -d: -f1); e=$(grep -n -- "$END" "$claude" | cut -d: -f1)
[ "$s" -lt "$e" ] || die "rule 1 comes before rule 0 in '$claude'"
[ "$(grep -c -x -F -- "$MARK" "$ref")" -eq 1 ] || die "reference '$ref' must contain exactly one marker line '$MARK'"
m=$(grep -n -x -F -- "$MARK" "$ref" | cut -d: -f1)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/rule0-XXXXXX"); trap 'rm -rf -- "$tmp"' EXIT
sed -n "${s},$((e - 1))p" "$claude" >"$tmp/live"
tail -n +"$((m + 1))" "$ref" >"$tmp/ref"
[ -s "$tmp/ref" ] || die "reference '$ref' is empty after the marker"
if cmp -s "$tmp/live" "$tmp/ref"; then exit 0; fi
diff -u --label "reference" --label "CLAUDE.md" "$tmp/ref" "$tmp/live"
echo "check-rule0: the rule-0 block of CLAUDE.md differs from docs/manager/rule0.reference.md. Rule 0 changes only together with a reviewed change to the reference; that PR touches docs/manager/, so MANAGER.md section 7 requires Ludwig's written approval." >&2
exit 1
