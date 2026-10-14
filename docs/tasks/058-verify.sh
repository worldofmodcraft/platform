#!/usr/bin/env bash
# Task 058 verification artefact (MANAGER.md 2c): criteria 1, 2 and 8.  Loopback only, no network beyond 127.0.0.1.
#   docs/tasks/058-verify.sh            run the client matrix + filename checks; exit 0 iff all pass
#   docs/tasks/058-verify.sh --mutate   also break the probe three ways and require the named check to turn red
# Criteria 3-6 are live/human and are not scripted.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
M="$REPO/tools/probe/archive-url/matrix.py"
echo "== environment"; python3 -I --version; node --version; curl --version | head -1; wget --version | head -1
echo "== baseline (must be green)"
out="$(python3 -I "$M")"; rc=$?
printf '%s\n' "$out" | tail -n 25
if [ $rc -ne 0 ]; then echo "VERIFY FAIL: baseline red (rc=$rc)"; exit 1; fi
[ "${1:-}" = "--mutate" ] || { echo "VERIFY OK (baseline only)"; exit 0; }
FAIL=0
mut() { # name, env value, regex the RED lines must match
  local o rc
  o="$(WOM058_MUTATE="$2" python3 -I "$M")"; rc=$?
  echo "== mutation $1 (rc=$rc)"; printf '%s\n' "$o" | grep -E '^RED:|^RESULT:' | head -n 6
  if [ $rc -eq 0 ] || ! printf '%s\n' "$o" | grep -Eq "^RED: $3"; then echo "MUTATION NOT CAUGHT: $1"; FAIL=1; fi
}
mut "redirect status broken in server fixture (302/301 answer 200)" status "C1 positive control 302"
mut "SHA comparison dropped" sha "C3 meta-refresh is NOT followed"
mut "client errors swallowed" swallow "C6 "
if [ $FAIL -eq 0 ]; then echo "VERIFY OK (baseline green; 3/3 mutations caught)"; else echo "VERIFY FAIL"; exit 1; fi
