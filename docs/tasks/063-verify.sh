#!/usr/bin/env bash
# Task 063 verification (MANAGER.md §2c). Deterministic, no network.
#   docs/tasks/063-verify.sh            run AC1-AC4 against the current tree
#   docs/tasks/063-verify.sh --mutate   also run the AC5 mutations in a temporary clone (never in this tree)
# Base = merge-base(HEAD, origin/main): the task is open, so origin/main is the correct comparison.
# Exit 0 only if every check passes (and, with --mutate, every mutation is caught and every restore is green).
set -u
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$HERE" || exit 2
BASE=${TASK063_BASE:-$(git merge-base HEAD origin/main 2>/dev/null)}
[ -n "$BASE" ] || { echo "verify: cannot determine base (no origin/main / merge-base)" >&2; exit 2; }
DOC=docs/manager/MANAGER.md
TASK=docs/tasks/063-doctrine-log-entry-check.md
SCRIPT=tools/manager/check-log-entry.sh
SCOPE="$DOC
$TASK
docs/tasks/063-verify.sh"

# --- helpers; every check takes a tree root and prints PASS/FAIL lines, returns non-zero on any FAIL ---
fails=0
res() { # res <label> <0|1> <detail>
  if [ "$2" -eq 0 ]; then echo "  PASS $1 ($3)"; else echo "  FAIL $1 ($3)"; fails=$((fails + 1)); fi
}
cnt() { local n; n=$(grep -c -- "$1" "$2" 2>/dev/null); echo "${n:-0}"; }
cntblob() { local n; n=$(git show "$BASE:$DOC" | grep -c -- "$1"); echo "${n:-0}"; }

# bullet line range in file $1 (start = the bullet's first line, end = line before "## 6."); empty on failure
bullet_range() {
  local s e
  s=$(grep -n '^- \*\*Log-entry check after every subagent\*\*' "$1" | head -n1 | cut -d: -f1)
  e=$(grep -n '^## 6\. ' "$1" | head -n1 | cut -d: -f1)
  [ -n "$s" ] && [ -n "$e" ] && [ "$s" -lt "$e" ] && echo "$s $((e - 1))"
}

ac1() { # root
  local r=$1 hunks rng s e bad=0 l
  hunks=$(git -C "$r" diff -U0 "$BASE" -- "$DOC" | grep -c '^@@')
  res "AC1 exactly one hunk" $([ "$hunks" -eq 1 ] && echo 0 || echo 1) "hunks=$hunks, expected 1"
  rng=$(bullet_range "$r/$DOC")
  res "AC1 bullet located in §5 (before '## 6.')" $([ -n "$rng" ] && echo 0 || echo 1) "range='${rng:-none}'"
  [ -n "$rng" ] || return
  s=${rng% *}; e=${rng#* }
  # every new-side hunk range must lie inside the bullet; zero hunks was already failed above
  local n=0
  while read -r l; do
    n=$((n + 1))
    local st len
    st=${l%%,*}; len=1; case "$l" in *,*) len=${l#*,};; esac
    [ "$len" -eq 0 ] && len=1
    if [ "$st" -lt "$s" ] || [ $((st + len - 1)) -gt "$e" ]; then bad=1; fi
  done < <(git -C "$r" diff -U0 "$BASE" -- "$DOC" | sed -n 's/^@@ [^ ]* +\([0-9,]*\) @@.*/\1/p')
  res "AC1 hunk lies inside bullet lines $s-$e" $([ "$n" -ge 1 ] && [ "$bad" -eq 0 ] && echo 0 || echo 1) "hunks seen=$n outside=$bad"
}

ac2() { # root
  local r=$1 p c cb
  for p in "does not exist until 049" "by hand and"; do
    cb=$(cntblob "$p")
    res "AC2 positive control: '$p' on base blob" $([ "$cb" -eq 1 ] && echo 0 || echo 1) "count=$cb, expected 1"
    c=$(cnt "$p" "$r/$DOC")
    res "AC2 '$p' absent from doctrine" $([ "$c" -eq 0 ] && echo 0 || echo 1) "count=$c, expected 0"
  done
}

ac3() { # root; command words come from the script's own header, not retyped
  local r=$1 hdr modes mode nargs pat found=0 want=0 rc
  hdr=$(sed -n '1,8p' "$r/$SCRIPT" | grep -E '^#[[:space:]]+check-log-entry\.sh (count|check) ')
  modes=$(printf '%s\n' "$hdr" | awk '{print $3}')
  res "AC3 header lists both modes (count, check)" $([ "$(printf '%s\n' "$modes" | sort | tr '\n' ' ')" = "check count " ] && echo 0 || echo 1) "modes=$(echo $modes)"
  for mode in $modes; do
    want=$((want + 1))
    nargs=$(printf '%s\n' "$hdr" | awk -v m="$mode" '$3==m' | grep -o '<[^>]*>' | wc -l)
    pat="tools/manager/check-log-entry\\.sh $mode( [^ \`]+){$nargs}\`"
    c=$(grep -cE -- "$pat" "$r/$DOC"); c=${c:-0}
    res "AC3 doctrine quotes '$mode' with $nargs args as in header" $([ "$c" -ge 1 ] && echo 0 || echo 1) "matches=$c"
  done
  # the cited OPERATIONS.md section must exist (the doctrine points to it by name)
  c=$(cnt 'git-guard.log and check-log-entry.sh' "$r/docs/manager/OPERATIONS.md")
  res "AC3 OPERATIONS.md section cited by the doctrine exists" $([ "$c" -ge 1 ] && echo 0 || echo 1) "count=$c"
  # the doctrine wraps this quote across a line break, so join lines before searching
  c=$(tr '\n' ' ' < "$r/$DOC" | sed 's/  */ /g' | grep -o 'OPERATIONS\.md`, "git-guard\.log and check-log-entry\.sh"' | wc -l)
  res "AC3 doctrine cites that section" $([ "$c" -ge 1 ] && echo 0 || echo 1) "count=$c"
  # functional: the quoted commands really run against this task file
  local n; n=$(bash "$r/$SCRIPT" count "$r/$TASK" 2>&1); rc=$?
  res "AC3 'count' runs and prints an integer" $([ "$rc" -eq 0 ] && [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && echo 0 || echo 1) "rc=$rc out=$n"
  bash "$r/$SCRIPT" check "$r/$TASK" $((n - 1)) >/dev/null 2>&1; rc=$?
  res "AC3 'check' with baseline count-1 exits 0" $([ "$rc" -eq 0 ] && echo 0 || echo 1) "rc=$rc"
  bash "$r/$SCRIPT" check "$r/$TASK" "$n" >/dev/null 2>&1; rc=$?
  res "AC3 'check' with baseline=count exits 1" $([ "$rc" -eq 1 ] && echo 0 || echo 1) "rc=$rc"
}

subset_ok() { # stdin: changed paths; prints offenders; returns 1 if none listed or any outside scope
  local p any=0 off=0
  while read -r p; do
    [ -n "$p" ] || continue
    any=1
    printf '%s\n' "$SCOPE" | grep -qxF -- "$p" || { echo "$p"; off=1; }
  done
  [ "$any" -eq 1 ] && [ "$off" -eq 0 ]
}
ac4() { # root
  local r=$1 files off rc
  files=$( { git -C "$r" diff --name-only "$BASE"; git -C "$r" ls-files --others --exclude-standard; } | sort -u)
  off=$(printf '%s\n' "$files" | subset_ok); rc=$?
  res "AC4 changed files ($(echo $files)) subset of scope" $rc "offenders='$(echo $off)'"
  # self-test: the subset check must reject a stray path and an empty set
  printf '%s\n%s\n' "$DOC" "docs/manager/OPERATIONS.md" | subset_ok >/dev/null; rc=$?
  res "AC4 control: out-of-scope path rejected" $([ "$rc" -ne 0 ] && echo 0 || echo 1) "rc=$rc"
  printf '' | subset_ok >/dev/null; rc=$?
  res "AC4 control: empty change set rejected" $([ "$rc" -ne 0 ] && echo 0 || echo 1) "rc=$rc"
}

run_all() { fails=0; ac1 "$1"; ac2 "$1"; ac3 "$1"; ac4 "$1"; return $fails; }

echo "base: $BASE ($(git log -1 --format=%s "$BASE"))"
echo "== AC1-AC4 on $HERE =="
run_all "$HERE"; main_fails=$?
echo "result: $([ $main_fails -eq 0 ] && echo GREEN || echo "RED ($main_fails failing)")"
total=$main_fails

if [ "${1:-}" = "--mutate" ]; then
  echo "== AC5 mutations (temporary clone, this tree untouched) =="
  TMP=$(mktemp -d "${TMPDIR:-/tmp}/063-mutate.XXXXXX") || exit 2
  trap 'rm -rf "$TMP"' EXIT
  git clone -q --no-hardlinks "$HERE" "$TMP/c" && git -C "$TMP/c" checkout -q --detach "$(git rev-parse HEAD)" || { echo "clone failed" >&2; exit 2; }
  C=$TMP/c
  # a committed clone of HEAD may lack uncommitted edits; carry the current working files over so we mutate what is verified
  for f in $DOC $TASK docs/tasks/063-verify.sh; do cp "$HERE/$f" "$C/$f"; done
  # mutation <name> <check fn> <sed expr applied to DOC> -- baseline green, mutated red in the targeted check, restored green
  mutation() {
    local name=$1 fn=$2 expr=$3 out fl
    echo "-- mutation: $name"
    cp "$HERE/$DOC" "$C/$DOC"
    fails=0; $fn "$C" >/dev/null; fl=$fails
    echo "  before: $fn failing=$fl (expected 0)"; [ "$fl" -eq 0 ] || total=$((total + 1))
    sed -i "$expr" "$C/$DOC"
    cmp -s "$HERE/$DOC" "$C/$DOC" && { echo "  FAIL mutation changed nothing"; total=$((total + 1)); return; }
    fails=0; $fn "$C" > "$TMP/out"; fl=$fails; out=$(cat "$TMP/out")
    echo "$out" | grep FAIL | sed 's/^/  /'
    echo "  mutated: $fn failing=$fl (expected >0)"; [ "$fl" -gt 0 ] || { echo "  FAIL mutation not detected"; total=$((total + 1)); }
    cp "$HERE/$DOC" "$C/$DOC"
    fails=0; $fn "$C" >/dev/null; fl=$fails
    echo "  restored: $fn failing=$fl (expected 0)"; [ "$fl" -eq 0 ] || total=$((total + 1))
  }
  # 1: restore the old sentence (both phrases) inside the bullet
  mutation "restore old sentence" ac2 's/^\(  the number in the task log; after the report-back it runs\)$/\1 That script is built in task 049 and does not exist until 049 merges; counted by hand and logged./'
  # 2: count -> counts in the quoted command
  mutation "count -> counts" ac3 's/check-log-entry\.sh count docs/check-log-entry.sh counts docs/'
  # extra (beyond the two required): edit a line outside the bullet; AC1 must go red
  mutation "edit outside the bullet (AC1)" ac1 's/^## 6\. Worktree isolation (anti-derailment rule #2)$/## 6. Worktree isolation (anti-derailment rule #2) x/'
  # extra: stray file in the change set; AC4 must go red
  echo "-- mutation: stray changed file (AC4)"
  echo x >> "$C/docs/manager/OPERATIONS.md"
  fails=0; ac4 "$C" > "$TMP/out"; fl=$fails; out=$(cat "$TMP/out"); echo "$out" | grep FAIL | sed 's/^/  /'
  echo "  mutated: ac4 failing=$fl (expected >0)"; [ "$fl" -gt 0 ] || { echo "  FAIL mutation not detected"; total=$((total + 1)); }
  git -C "$C" checkout -q -- docs/manager/OPERATIONS.md
  fails=0; ac4 "$C" >/dev/null; echo "  restored: ac4 failing=$fails (expected 0)"; [ "$fails" -eq 0 ] || total=$((total + 1))
  echo "result (mutations): $([ $total -eq $main_fails ] && echo "ALL CAUGHT, ALL RESTORED" || echo "PROBLEM")"
fi

echo "OVERALL: $([ $total -eq 0 ] && echo GREEN || echo "RED ($total)")"
[ "$total" -eq 0 ]
