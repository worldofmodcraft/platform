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
# Own-change checks pinned to fixed SHAs (REVIEW-CHECKLIST item 12). Unreachable pin = fail.
BASE=${T080_BASE:-29b3424fc97ba919f598531e9f4f154acc2a0619}
FINAL=${T080_FINAL:-f173739800707d44a32fe495e96a39022c0c84bb}
for c in "$BASE" "$FINAL"; do git cat-file -e "$c^{commit}" 2>/dev/null || { echo "FAIL pin $c unreachable"; fail=1; }; done
if [ "$fail" = 0 ]; then
  git show "$FINAL:docs/decisions/0121-version-lifecycle-pending.md" >/dev/null 2>&1 && echo "PASS ADR-0121 path exists at FINAL" || { echo "FAIL ADR-0121 path at FINAL"; fail=1; }
  git show "$FINAL:docs/architecture/system-overview.md" | grep -qE '(^|[^:A-Za-z0-9_./-])docs/decisions/0121-version-lifecycle-pending.md' && echo "PASS note cites main path at FINAL" || { echo "FAIL note cite at FINAL"; fail=1; }
  git show "$BASE:docs/architecture/system-overview.md" | grep -q 'proposal/adr-0121-version-lifecycle:' && echo "PASS BASE had the branch cite" || { echo "FAIL BASE lacks branch cite"; fail=1; }
  extra=$(git diff --name-only "$BASE" "$FINAL" | grep -vxE 'docs/architecture/system-overview.md|docs/tasks/080-adr0121-cite-fresh-clone.md|docs/tasks/080-verify.sh' || true)
  [ -z "$extra" ] && echo "PASS file scope BASE..FINAL" || { echo "FAIL out-of-scope files: $extra"; fail=1; }
fi
echo "exit=$fail"; exit $fail
