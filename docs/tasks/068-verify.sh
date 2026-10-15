#!/usr/bin/env bash
# Task 068 verification: text checks on the runbook markers. No network.
# Usage: 068-verify.sh [--mutate]
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RB="${RUNBOOK:-$here/../runbooks/site-v1-manual-steps.md}"

# section <file> <heading-regex>: print that "## " section up to the next "---" line.
section() { awk -v re="$2" '/^## / && $0 ~ re {on=1} on && /^---$/ {exit} on' "$1"; }

run_checks() {
  local f="$1" s m
  for m in M3 M5 M7 Q-H; do
    s="$(section "$f" "^## .* $m ")"
    # 1. A check mark in the heading and an evidence note naming who/what and when.
    grep -q "^## ☑ $m " <<<"$s"; chk "$m heading is ☑" $?
    grep -Eq '(Ludwig|mission log).*2026-|2026-.*Ludwig' <<<"$s"; chk "$m has evidence note (who/when)" $?
  done
  # 2. M4 and M6 stay open.
  grep -q '^## ☐ M4 ' "$f"; chk "M4 heading stays ☐" $?
  grep -q '^## ☐ M6 ' "$f"; chk "M6 heading stays ☐" $?
  # 3. M5 and M7 status lines no longer say not done / 404.
  s="$(section "$f" "^## .* M5 ")"
  ! grep -Eq 'not done|returns 404' <<<"$s"; chk "M5 has no 'not done'/'returns 404'" $?
  s="$(section "$f" "^## .* M7 ")"
  ! grep -Eq 'not done|returns 404' <<<"$s"; chk "M7 has no 'not done'/'returns 404'" $?
  grep -Eq '^\*\*Last reviewed: 2026-10-15 \(task 068\)' "$f"; chk "Last reviewed names 2026-10-15 and task 068" $?
  # No secret material: no PEM header, no minisign-looking or long base64 run.
  ! grep -Eq -e '-----BEGIN' -e '[A-Za-z0-9+/]{60,}={0,2}' "$f"; chk "no secret-looking value" $?
}

chk() {
  if [ "$2" -eq 0 ]; then echo "PASS  $1"; else echo "FAIL  $1"; fail=1; fi
}

fail=0

if [ "${1:-}" = "--mutate" ]; then
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  bad=0
  mut() { # label, sed-expr; applies to a temp copy only
    cp "$RB" "$tmp/rb.md"; sed -i "$2" "$tmp/rb.md"
    if cmp -s "$RB" "$tmp/rb.md"; then echo "MUTATION $1: NO-OP (copy unchanged)"; bad=1; return; fi
    out="$(run_checks "$tmp/rb.md")"
    if grep -q '^FAIL' <<<"$out"; then
      echo "MUTATION $1: red as expected -> $(grep '^FAIL' <<<"$out" | sed 's/^FAIL  //' | paste -sd';' -)"
    else
      echo "MUTATION $1: STILL GREEN (check is blind)"; bad=1
    fi
  }
  mut "M3 revert to ☐"   's/^## ☑ M3 /## ☐ M3 /'
  mut "M5 revert to ☐"   's/^## ☑ M5 /## ☐ M5 /'
  mut "M7 revert to ☐"   's/^## ☑ M7 /## ☐ M7 /'
  mut "Q-H revert to ☐"  's/^## ☑ Q-H /## ☐ Q-H /'
  mut "M4 flipped to ☑"  's/^## ☐ M4 /## ☑ M4 /'
  mut "M6 flipped to ☑"  's/^## ☐ M6 /## ☑ M6 /'
  mut "M5 old 404 text"  's/answers HTTP 200 (unauthenticated check, 2026-10-15)/returns 404 (2026-10-15)/'
  mut "M7 old 404 text"  's/unauthenticated request answers HTTP 200 (2026-10-15)/unauthenticated request returns 404 (2026-10-15)/'
  mut "M3 evidence gone" '/^## ☑ M3 /,/^---$/{s/Ludwig/someone/g;s/mission log/log/g}'
  mut "Q-H evidence gone" '/^## ☑ Q-H /,/^---$/{s/Ludwig/someone/g}'
  mut "Last reviewed old" 's/(task 068)/(task 060)/'
  mut "secret planted"   '1a RWQ0123456789abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  exit "$bad"
fi

run_checks "$RB"
if [ "$fail" -eq 0 ]; then echo "ALL PASS"; else echo "SOME FAILED"; fi
exit "$fail"
