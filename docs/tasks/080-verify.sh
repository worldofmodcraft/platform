#!/usr/bin/env bash
# Task 080 verify: architecture notes cite no branch absent from origin.
# Run from repo root. Needs network (git ls-remote, public repo, no credentials).
set -u
cd "$(git rev-parse --show-toplevel)"
fail=0
remote=https://github.com/worldofmodcraft/platform
heads=$(git ls-remote --heads "$remote" | sed 's#.*refs/heads/##') || { echo "FAIL ls-remote"; exit 1; }
[ -n "$heads" ] || { echo "FAIL ls-remote returned no heads"; exit 1; }
n=0
while IFS=: read -r file line rest; do
  for cite in $(printf '%s' "$rest" | grep -oE '[A-Za-z0-9_./-]+:docs/[A-Za-z0-9_./-]+'); do
    br=${cite%%:*}; n=$((n+1))
    if printf '%s\n' "$heads" | grep -qxF "$br"; then echo "PASS $file:$line branch '$br' is on origin"
    else echo "FAIL $file:$line cites branch '$br' absent from origin"; fail=1; fi
  done
done < <(grep -rnE '[A-Za-z0-9_./-]+:docs/[A-Za-z0-9_./-]+' docs/architecture)
echo "branch:path cites checked: $n"
# the formerly cited ADR must resolve by path
[ -f docs/decisions/0121-version-lifecycle-pending.md ] && echo "PASS ADR-0121 path resolves" || { echo "FAIL ADR-0121 path"; fail=1; }
grep -q 'docs/decisions/0121-version-lifecycle-pending.md' docs/architecture/system-overview.md && echo "PASS note cites main path" || { echo "FAIL note cite"; fail=1; }
echo "exit=$fail"; exit $fail
