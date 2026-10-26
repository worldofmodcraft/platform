#!/usr/bin/env bash
# Task 048 verification artefact (MANAGER.md section 2c).
#   docs/tasks/048-verify.sh            checks AC1-AC7: c1 (own change) on the task's PR range PIN_BASE..PIN_FINAL, c2-c7 on HEAD
#   docs/tasks/048-verify.sh --mutate   additionally applies each mutation AC10 names to a temp copy and requires
#                                       the matching check to go red (positive control first: the clean tree must be green)
# AC8 and AC9 are live (tool name; nesting refused; maxTurns run) and AC11 is human: none of them is covered here.
# Read-only on the repository: it exports HEAD to a temp dir and never writes inside the repo. No credentials, no .pyc.
set -uo pipefail
export PYTHONDONTWRITEBYTECODE=1 LC_ALL=C.UTF-8

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
# Task 078 re-pin. c1 ("nothing weakened") is an OWN-CHANGE check: it describes what task 048's PR did, so it measures the PR range
# (PIN_BASE = merge-base(M^1, M^2), PIN_FINAL = M^2, M = c323460 "Merge pull request #50"), never HEAD. Fixed SHAs; no env override.
# An unreachable pin FAILS (exit 2), never skips. c2-c7 and the c5 quotation source are live/historical and stay as they were.
PIN_BASE="8a5f32dfcebfe6eda328066b43eb60204ef3a5ac"
PIN_FINAL="047bc41cac555cc125f2650d1b5cc3159f2f17a9"
BASE="$PIN_BASE"
MODE="${1:-}"
case "$MODE" in ""|--mutate) ;; *) echo "usage: $0 [--mutate]"; exit 2;; esac
for pin in "$PIN_BASE" "$PIN_FINAL"; do
  git -C "$REPO" rev-parse --verify -q "$pin^{commit}" >/dev/null || { echo "FAIL: pinned commit $pin not found (run: git fetch)"; exit 2; }
done

TMP="$(mktemp -d "${TMPDIR:-/tmp}/wom048-XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

DOCS="CLAUDE.md docs/manager/MANAGER.md docs/manager/REVIEW-CHECKLIST.md docs/manager/SPEC-CHECKLIST.md docs/manager/ROUTING.md docs/manager/TASK-TEMPLATE.md"
# Agent -> maxTurns, copied from the spec's table.
declare -A TURNS=( [scaffolder]=30 [doc-writer]=50 [surveyor]=60 [debugger]=60 [debugger-strong]=80 [reviewer]=80
                   [qa-engineer]=80 [implementer]=100 [implementer-strong]=120 [core-surgeon]=120 )

base_show() { git -C "$REPO" show "$BASE:$1"; }

# run_checks TREE : prints "ok cN: ..." / "FAIL cN: ..." lines; exit status is the number of FAIL lines (capped).
run_checks() {
  local T="$1" T1="${2:-$1}" f n=0   # T1 = the tree c1 measures (the pinned FINAL export); T = the live tree for c2-c7
  ok()  { printf 'ok   %s\n' "$*"; }
  bad() { printf 'FAIL %s\n' "$*"; }

  # ---- c1: nothing weakened -------------------------------------------------------------------------------
  local files="$DOCS" a
  for a in "$T1"/.claude/agents/*.md; do [ -e "$a" ] && files="$files .claude/agents/$(basename "$a")"; done
  for f in $files; do
    if [ ! -f "$T1/$f" ]; then bad "c1: $f missing from tree"; continue; fi
    if ! base_show "$f" > "$TMP/base.txt" 2>/dev/null; then ok "c1: $f is new (no base to delete from)"; continue; fi
    n=$(diff "$TMP/base.txt" "$T1/$f" | grep -c '^<' || true)
    if [ "$n" = 0 ]; then ok "c1: $f has 0 deleted lines vs $BASE"; else bad "c1: $f has $n deleted/changed lines vs $BASE"; fi
  done
  # token-guard blocks byte-identical to base apart from the added marker line(s)
  blk_claude() { awk '/^0\. \*\*THE TOKEN GUARD/{p=1;print;next} p&&/^1\. /{exit} p{print}'; }
  blk_mgr()    { awk '/^- \*\*The token guard/{p=1;print;next} p&&/^  /{print;next} p{exit}'; }
  base_show CLAUDE.md | blk_claude > "$TMP/b1"
  grep -v 'SUSPENDED by Ludwig 2026-10-14' "$T1/CLAUDE.md" | blk_claude > "$TMP/t1"
  if [ -s "$TMP/b1" ] && cmp -s "$TMP/b1" "$TMP/t1"; then ok "c1: CLAUDE.md rule 0 block identical to base apart from the marker"; else bad "c1: CLAUDE.md rule 0 block differs from base (or not found)"; fi
  base_show docs/manager/MANAGER.md | blk_mgr > "$TMP/b2"
  grep -v 'SUSPENDED by Ludwig 2026-10-14' "$T1/docs/manager/MANAGER.md" | blk_mgr > "$TMP/t2"
  if [ -s "$TMP/b2" ] && cmp -s "$TMP/b2" "$TMP/t2"; then ok "c1: MANAGER.md token-guard bullet identical to base apart from the marker"; else bad "c1: MANAGER.md token-guard bullet differs from base (or not found)"; fi

  # ---- c2: settings.json ----------------------------------------------------------------------------------
  if python3 -I -c '
import json,sys
d=json.load(open(sys.argv[1]))
assert d["env"]["CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH"]=="1", "env value is not the string 1"
' "$T/.claude/settings.json" 2>"$TMP/err"; then ok "c2: settings.json parses, env CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH == \"1\""; else bad "c2: settings env: $(tail -1 "$TMP/err")"; fi
  if python3 -I -c '
import json,sys
d=json.load(open(sys.argv[1]))
assert d["hooks"]["PreToolUse"], "empty"
' "$T/.claude/settings.json" 2>"$TMP/err"; then ok "c2: 052's hooks.PreToolUse entry still present (positive control)"; else bad "c2: PreToolUse entry missing: $(tail -1 "$TMP/err")"; fi

  # ---- c3: agent files ------------------------------------------------------------------------------------
  local cnt; cnt=$(ls "$T"/.claude/agents/*.md 2>/dev/null | wc -l)
  if [ "$cnt" = 10 ]; then ok "c3: exactly 10 agent files"; else bad "c3: agent file count is $cnt, expected 10"; fi
  local name fm
  for name in "${!TURNS[@]}"; do
    f="$T/.claude/agents/$name.md"
    if [ ! -f "$f" ]; then bad "c3: $name.md missing"; continue; fi
    fm=$(awk 'NR==1&&/^---$/{p=1;next} p&&/^---$/{exit} p{print}' "$f")
    if printf '%s\n' "$fm" | grep -qx 'disallowedTools: Agent'; then ok "c3: $name disallowedTools: Agent"; else bad "c3: $name lacks 'disallowedTools: Agent' in frontmatter"; fi
    if printf '%s\n' "$fm" | grep -qx "maxTurns: ${TURNS[$name]}"; then ok "c3: $name maxTurns: ${TURNS[$name]}"; else bad "c3: $name maxTurns is not ${TURNS[$name]} (got: $(printf '%s\n' "$fm" | grep '^maxTurns' || echo none))"; fi
  done
  # no stray agent files outside the table
  for a in "$T"/.claude/agents/*.md; do
    [ -e "$a" ] || continue; name=$(basename "$a" .md)
    [ -n "${TURNS[$name]:-}" ] || bad "c3: unexpected agent file $name.md (not in the table)"
  done

  # ---- c4: token-guard marker -----------------------------------------------------------------------------
  local m ln1 ln2
  for f in CLAUDE.md docs/manager/MANAGER.md; do
    ln1=$(grep -n 'SUSPENDED by Ludwig 2026-10-14' "$T/$f" | head -1 | cut -d: -f1)
    ln2=$(grep -n "Ludwig's Claude Max subscription is shared" "$T/$f" | head -1 | cut -d: -f1)
    if [ -z "$ln1" ]; then bad "c4: $f has no SUSPENDED marker";
    elif [ -z "$ln2" ]; then bad "c4: $f lost the sentence \"Ludwig's Claude Max subscription is shared\"";
    elif [ "$ln2" -gt "$ln1" ]; then ok "c4: $f marker (line $ln1) precedes the retained sentence (line $ln2)";
    else bad "c4: $f marker (line $ln1) does not precede the retained sentence (line $ln2)"; fi
  done

  # ---- c5: waivers ----------------------------------------------------------------------------------------
  git -C "$REPO" show "$BASE:docs/tasks/MISSION-worldofmodcraft-site-v1-log.md" > "$TMP/src-main.md" 2>/dev/null || : > "$TMP/src-main.md"
  git -C "$REPO" show "session/8-status:docs/tasks/MISSION-worldofmodcraft-site-v1-log.md" > "$TMP/src-s8.md" 2>/dev/null || : > "$TMP/src-s8.md"
  python3 -I - "$T/docs/manager/MANAGER.md" "$TMP/src-main.md" "$TMP/src-s8.md" <<'PY' > "$TMP/c5.out"
import re,sys
mgr=open(sys.argv[1],encoding="utf-8").read().split("\n")
norm=lambda s: re.sub(r"\s+"," ",s.replace("**","")).strip()
srcs=[norm(open(p,encoding="utf-8").read()) for p in sys.argv[2:4]]
start=[i for i,l in enumerate(mgr) if l.startswith("### Waivers recorded as historical")]
if not start:
    print("FAIL c5a: no 'Waivers recorded as historical' subsection in MANAGER.md"); sys.exit()
sec=[]
for l in mgr[start[0]+1:]:
    if re.match(r"#{2,3} ",l): break
    sec.append(l)
entries={}
cur=None
for l in sec:
    m=re.match(r"- \*\*§(\d):\*\*",l)
    if m: cur=m.group(1); entries[cur]=[l]
    elif cur and l.strip() and not l.startswith("- "): entries[cur].append(l)
    else: cur=None if not l.strip() else cur
if sorted(entries)==["5","7","8"]: print("ok   c5a: subsection has the three entries §7, §8, §5")
else: print("FAIL c5a: entries found for sections %s, expected 5, 7, 8"%sorted(entries))
for k in ("7","8","5"):
    if k not in entries: print("FAIL c5b: no entry for §%s"%k); continue
    text=norm(" ".join(entries[k]))
    if "expired" in text.lower(): print("ok   c5b: §%s entry contains 'expired'"%k)
    else: print("FAIL c5b: §%s entry does not contain the word 'expired' itself (the subsection preamble does: %s)"%(k,"yes" if any("expired" in l for l in sec) else "no"))
    q=text.find('"'); r=text.rfind('"')
    if q<0 or r<=q: print("FAIL c5c: §%s entry has no quotation"%k); continue
    frag=text[q+1:r].strip()
    where=[n for n,s in zip(("main","session/8-status"),srcs) if frag in s]
    if len(frag)>40 and where: print("ok   c5c: §%s quotation (%d chars) found verbatim in mission log on %s"%(k,len(frag),where[0]))
    else: print("FAIL c5c: §%s quotation not found verbatim in the source log: %r"%(k,frag[:70]))
PY
  cat "$TMP/c5.out"

  # ---- c6: size caps --------------------------------------------------------------------------------------
  awk '/^5b\./{p=1;print;next} p&&/^[0-9]+[a-z]?\. /{exit} p{print}' "$T/docs/manager/SPEC-CHECKLIST.md" | tr '\n' ' ' > "$TMP/5b"
  if [ -s "$TMP/5b" ]; then ok "c6: SPEC-CHECKLIST has item 5b"; else bad "c6: SPEC-CHECKLIST has no item 5b"; fi
  grep -Eq '(^|[^0-9])5 source files' "$TMP/5b" && ok "c6: 5b names 5 source files" || bad "c6: 5b does not name '5 source files'"
  grep -Eq '(^|[^0-9])300 changed lines' "$TMP/5b" && ok "c6: 5b names 300 changed lines" || bad "c6: 5b does not name '300 changed lines'"
  grep -Eq '(^|[^0-9])10 reading-list' "$TMP/5b" && ok "c6: 5b names 10 reading-list files" || bad "c6: 5b does not name '10 reading-list' files"
  grep -Eqi 'tests, fixtures and verify scripts excluded' "$TMP/5b" && ok "c6: 5b says tests, fixtures and verify scripts are excluded" || bad "c6: 5b lacks the exclusion of tests, fixtures and verify scripts"
  grep -q '^## Size' "$T/docs/manager/TASK-TEMPLATE.md" && ok "c6: TASK-TEMPLATE has a Size section" || bad "c6: TASK-TEMPLATE has no '## Size' section"

  # ---- c7: blind review -----------------------------------------------------------------------------------
  local P="Findings formed before reading the log"
  grep -q "$P" "$T/.claude/agents/reviewer.md" && ok "c7: reviewer.md has the phrase" || bad "c7: reviewer.md lacks '$P'"
  grep -q "put them first in the verdict" "$T/.claude/agents/reviewer.md" && ok "c7: reviewer.md says it comes first in the verdict" || bad "c7: reviewer.md does not say findings come first in the verdict"
  grep -q "$P" "$T/docs/manager/REVIEW-CHECKLIST.md" && ok "c7: REVIEW-CHECKLIST has the phrase" || bad "c7: REVIEW-CHECKLIST lacks '$P'"
  grep -Eq 'comes first' "$T/docs/manager/REVIEW-CHECKLIST.md" && ok "c7: REVIEW-CHECKLIST says the independent pass comes first" || bad "c7: REVIEW-CHECKLIST lacks 'comes first'"
  return 0
}

fresh_tree() { local d="$TMP/tree-$1"; rm -rf "$d"; mkdir -p "$d"; git -C "$REPO" archive "${2:-HEAD}" | tar -x -C "$d"; printf '%s' "$d"; }

echo "== task 048 verify: c1 on PR range $(git -C "$REPO" rev-parse --short "$PIN_BASE")..$(git -C "$REPO" rev-parse --short "$PIN_FINAL"); c2-c7 on HEAD $(git -C "$REPO" rev-parse --short HEAD)"
T0="$(fresh_tree clean)"
F0="$(fresh_tree finalclean "$PIN_FINAL")"
run_checks "$T0" "$F0" | tee "$TMP/clean.out"
CLEAN_FAILS=$(grep -c '^FAIL' "$TMP/clean.out" || true)
echo "== clean tree: $CLEAN_FAILS failing check line(s)"
rc=0; [ "$CLEAN_FAILS" = 0 ] || rc=1
[ "$MODE" = "--mutate" ] || { echo "== AC8, AC9 (live) and AC11 (human) are not covered by this script"; exit $rc; }

# ------------------------------------------------------------------ mutations (AC10)
echo "== mutations: each runs on a temp copy; the expected check must show a FAIL line that the clean tree did not have"
MFAIL=0
# mutate NAME EXPECTED_TAG 'shell snippet run with T set to the tree'
mutate() {
  local name="$1" tag="$2" snippet="$3" T
  local clean1="$T0" T1
  # a c1 mutation edits the pinned FINAL export (what c1 measures); every other mutation edits the HEAD tree
  if [ "$tag" = c1 ]; then T="$(fresh_tree m "$PIN_FINAL")"; clean1="$F0"; else T="$(fresh_tree m)"; fi
  ( cd "$T" && T="$T" eval "$snippet" ) 2>"$TMP/merr"
  if diff -rq "$clean1" "$T" >/dev/null 2>&1; then echo "FAIL mutation '$name': no-op, the tree did not change"; MFAIL=1; return; fi
  if [ "$tag" = c1 ]; then run_checks "$T0" "$T" > "$TMP/mut.out"; else run_checks "$T" "$F0" > "$TMP/mut.out"; fi
  local new; new=$(grep "^FAIL ${tag}" "$TMP/mut.out" | grep -vxFf <(grep '^FAIL' "$TMP/clean.out") | head -1 || true)
  if [ -n "$new" ]; then echo "ok   mutation '$name' -> red: ${new:0:150}"; else echo "FAIL mutation '$name' did NOT turn ${tag} red"; MFAIL=1; fi
}
mutate "delete a line from MANAGER.md"            c1 "sed -i '/^- Absolute stop conditions/d' docs/manager/MANAGER.md"
mutate "alter one char inside the rule-0 block"   c1 "sed -i 's/Stop at 90 %/Stop at 91 %/' CLAUDE.md"
mutate "env value set to 3"                       c2 "sed -i 's/\"CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH\": \"1\"/\"CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH\": \"3\"/' .claude/settings.json"
mutate "remove 052's PreToolUse entry"            c2 "python3 -I -c 'import json;d=json.load(open(\".claude/settings.json\"));d[\"hooks\"].pop(\"PreToolUse\");json.dump(d,open(\".claude/settings.json\",\"w\"))'"
mutate "remove disallowedTools from one agent"    c3 "sed -i '/^disallowedTools: Agent\$/d' .claude/agents/debugger.md"
mutate "change one maxTurns"                      c3 "sed -i 's/^maxTurns: 80\$/maxTurns: 81/' .claude/agents/reviewer.md"
mutate "delete one agent file (count 9)"          c3 "rm .claude/agents/surveyor.md"
mutate "copy one agent file (count 11)"           c3 "cp .claude/agents/surveyor.md .claude/agents/surveyor-copy.md"
mutate "drop the CLAUDE.md marker line"          c4 "sed -i '/SUSPENDED by Ludwig 2026-10-14/d' CLAUDE.md"
mutate "drop the MANAGER.md marker line"         c4 "sed -i '/SUSPENDED by Ludwig 2026-10-14/d' docs/manager/MANAGER.md"
mutate "drop one waiver entry (§8)"              c5 "python3 -I -c 'import re;p=\"docs/manager/MANAGER.md\";s=open(p).read();s=re.sub(r\"- \\*\\*§8:\\*\\*.*?(?=\\n- \\*\\*§5)\",\"\",s,flags=re.S);open(p,\"w\").write(s)'"
mutate "alter one quoted waiver fragment"        c5c "sed -i 's/independent chains continue/independent chains stop/' docs/manager/MANAGER.md"
mutate "drop the 300"                            c6 "sed -i 's/300 changed lines/changed lines/' docs/manager/SPEC-CHECKLIST.md"
mutate "drop blind-review phrase (reviewer.md)"  c7 "sed -i 's/Findings formed before reading the log/Early findings/' .claude/agents/reviewer.md"
mutate "drop blind-review phrase (checklist)"    c7 "sed -i 's/Findings formed before reading the log/Early findings/' docs/manager/REVIEW-CHECKLIST.md"
echo "== mutations: $([ $MFAIL = 0 ] && echo 'all reddened' || echo 'SOME DID NOT REDDEN')"
echo "== AC8, AC9 (live) and AC11 (human) are not covered by this script"
[ $MFAIL = 0 ] && [ $rc = 0 ]
