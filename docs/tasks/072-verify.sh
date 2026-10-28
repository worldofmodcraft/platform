#!/usr/bin/env bash
# Task 072 verify: ledger hygiene. Run from the repo root (any worktree of platform), with network-free local refs
# (`git fetch origin` first). Own-change checks read pinned SHAs (REVIEW-CHECKLIST item 12); nothing here reads HEAD.
# Set T072_RUN_ALL=1 to also run every docs/tasks/*-verify.sh one at a time (slow: tens of minutes).
set -u
cd "$(git rev-parse --show-toplevel)"
export PYTHONDONTWRITEBYTECODE=1
# Task 090: BASE/FINAL are fixed pins, no environment override (078/085 rule). REG is a LOCATION (a live read of the registry's origin/main), not a pin.
BASE=d9d48de
FINAL=7df8a50979cc834918871ba948aa9ed7e9eb4352
REG=${T072_REGISTRY:-/home/ludwig/registry}
fail=0
for c in "$BASE" "$FINAL"; do git cat-file -e "$c^{commit}" 2>/dev/null || { echo "FAIL pin $c unreachable"; exit 1; }; done
[ -d "$REG" ] && [ "$(git -C "$REG" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] && [ "$(git -C "$REG" rev-parse --show-toplevel 2>/dev/null)" = "$(cd "$REG" && pwd -P)" ] || { echo "FAIL registry $REG is not a git repository (its own top level)"; exit 1; }
git -C "$REG" rev-parse --verify -q "origin/main^{commit}" >/dev/null 2>&1 || { echo "FAIL registry origin/main does not resolve in $REG"; exit 1; }
git -C "$REG" cat-file -e origin/main 2>/dev/null || { echo "FAIL registry origin/main missing in $REG"; exit 1; }

MAP=$(cat <<'MAPEOF'
007a-registry-checkers-shape.md registry 10 3c94cf2
007b-registry-checker-ownership.md registry 12 70cedca
008a-pipeline-core.md registry 7 a50daac
032-ownership-edge-contract.md registry 4 4d4a204
033-worktree-cleanup.md platform 23 a605ecb
034-schema-traversal.md registry 5 b725b5d
035-verified-facts-rule.md platform 24 387b1b7
036-doctrine-session4.md platform 26 9bd4d7b
037-pages-enablement.md platform 27 93844b8
038-doctrine-session5.md platform 28 97b9fc4
042-credential-rule.md platform 32 8bd0759
046-method-handover.md platform 36 5d1a7f5
048-doctrine-arcane.md platform 50 c323460
052-vault-triggers-and-guard.md platform 47 f9bdf86
054-site-v1-remaining-specs.md platform 42 96ed6b0
056-architecture-note.md platform 43 9e91614
057-version-lifecycle-contract.md registry 8 e009ef0
059-pycache-hygiene.md platform 45 672b44a
062-registry-test-maintenance.md registry 9 eba11b7
063-doctrine-log-entry-check.md platform 55 0a87b17
064-schema-check-end-anchor.md registry 13 79d5377
066-registry-dev-tools-ajv.md registry 14 198dc98
067-repin-032-n5b.md registry 11 ac22c8f
068-runbook-markers-session9.md platform 58 9b86898
069-closed-verify-maintenance.md registry 15 2347ffb
070-closed-verify-head-audit.md registry 16 fb76ee5
071-repin-007b-verify.md registry 17 825da5e
074-adr-removal-policy.md platform 61 0aac566
075-takedown-only-removal.md registry 18 4356583
076-doctrine-removal-and-pinning.md platform 66 bf4710d
077-runbook-archive-protection.md platform 63 2562f88
078-closed-verify-repin-048-051-063.md platform 67 8004828
079-rule0-live-guard.md platform 68 29b3424
080-adr0121-cite-fresh-clone.md platform 69 9a73990
MAPEOF
)

echo "== AC1: every file set to done names a merge that exists on the matching origin/main"
while read -r f repo pr sha; do
  p=docs/tasks/$f
  if [ "$repo" = registry ]; then G="git -C $REG"; else G="git"; fi
  st=$(git show "$FINAL:$p" | sed -n 3,5p | grep -m1 -F '**Status:**')
  case "$st" in *"**Status:** done (merged $repo PR #$pr \`$sha\`"*) ;; *) echo "FAIL $f status line lacks 'done (merged $repo PR #$pr $sha'"; fail=1; continue;; esac
  git show "$FINAL:$p" | grep -qF "status corrected by task 072: done, merged as $repo PR #$pr (\`$sha\`" || { echo "FAIL $f log line missing"; fail=1; continue; }
  $G cat-file -e "$sha^{commit}" 2>/dev/null || { echo "FAIL $f $sha not in $repo"; fail=1; continue; }
  $G merge-base --is-ancestor "$sha" origin/main || { echo "FAIL $f $sha not an ancestor of $repo origin/main"; fail=1; continue; }
  echo "PASS $f -> $repo #$pr $sha"
done <<< "$MAP"

echo "== AC2: each task file's diff BASE..FINAL = status line + appended 072 log lines only"
python3 -I - "$BASE" "$FINAL" <<'PYEOF' || fail=1
import subprocess, sys
base, final = sys.argv[1:3]
names = subprocess.check_output(["git","diff","--name-only",base,final],text=True).split()
ok = True; n = 0
for f in names:
    if not f.startswith("docs/tasks/") or not f.endswith(".md"): continue
    if f.endswith("072-ledger-hygiene.md"): continue
    d = subprocess.check_output(["git","diff","-U0",base,final,"--",f],text=True).split("\n")
    rem = [l for l in d if l.startswith("-") and not l.startswith("---")]
    add = [l for l in d if l.startswith("+") and not l.startswith("+++")]
    good = (len(rem) == 1 and "**Status:**" in rem[0] and len(add) == 2
            and "**Status:** done (merged" in add[0]
            and add[1].startswith("+- 2026-10-25 doc-writer (task 072): status corrected by task 072:"))
    n += 1
    if not good:
        ok = False; print("FAIL", f, "removed", len(rem), "added", len(add))
print(("PASS" if ok else "FAIL"), n, "task files checked")
sys.exit(0 if ok else 1)
PYEOF

echo "== AC3: OPERATIONS.md only gains the new section with items (a)-(g)"
rem=$(git diff -U0 "$BASE" "$FINAL" -- docs/manager/OPERATIONS.md | grep -c '^-[^-]')
[ "$rem" = 0 ] && echo "PASS no line removed or changed" || { echo "FAIL $rem lines removed/changed"; fail=1; }
sec=$(git show "$FINAL:docs/manager/OPERATIONS.md" | sed -n '/^## What session 11 paid for/,$p')
[ -n "$sec" ] && echo "PASS section heading present" || { echo "FAIL section missing"; fail=1; }
for k in a b c d e f g; do printf '%s\n' "$sec" | grep -q "^### ($k) " && echo "PASS item ($k)" || { echo "FAIL item ($k)"; fail=1; }; done
hunks=$(git diff -U0 "$BASE" "$FINAL" -- docs/manager/OPERATIONS.md | grep -c '^@@')
[ "$hunks" = 1 ] && echo "PASS one contiguous addition" || { echo "FAIL $hunks hunks"; fail=1; }

echo "== scope: files changed BASE..FINAL"
extra=$(git diff --name-only "$BASE" "$FINAL" | grep -vE '^docs/tasks/[0-9]{3}[a-c]?-[a-z0-9-]+\.md$|^docs/manager/OPERATIONS.md$' || true)
[ -z "$extra" ] && echo "PASS only docs/tasks/*.md and OPERATIONS.md" || { echo "FAIL out of scope: $extra"; fail=1; }
git diff --name-only "$BASE" "$FINAL" | grep -qE '^docs/tasks/(done/|MISSION)' && { echo "FAIL touched done/ or mission files"; fail=1; } || echo "PASS no done/ or mission files"
git diff --name-status "$BASE" "$FINAL" | grep -E '^[RD]' && { echo "FAIL rename or delete"; fail=1; } || echo "PASS no rename/delete"

if [ "${T072_RUN_ALL:-0}" = 1 ]; then
  echo "== AC4: every docs/tasks/*-verify.sh, one at a time"
  for s in docs/tasks/*-verify.sh; do
    bash "$s" >/tmp/t072-$(basename "$s").out 2>&1; rc=$?
    echo "$s exit=$rc"; [ "$rc" = 0 ] || fail=1
  done
fi
[ "$fail" = 0 ] && echo "== 072-verify: ALL CHECKS PASSED" || echo "== 072-verify: FAILED"
exit $fail
