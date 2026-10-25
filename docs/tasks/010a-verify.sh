#!/usr/bin/env bash
# Task 010a verification (MANAGER.md section 2c). Run from the worktree root, foreground, one script at a time.
#   docs/tasks/010a-verify.sh
#     LIVE on HEAD : criteria 1-4 on docs/test-mod (tools/test-mod/tests/check_tree.py), the unit tests of the two tools
#     MUTATIONS    : criterion 11 - every check for 1, 2, 3, 4 must go red on a broken copy (never on this tree)
#     OWN-CHANGE   : file scope and secret scan on the FIXED range PIN_BASE..PIN_FINAL (REVIEW-CHECKLIST item 12)
# Criterion 8 (visual review of the three screenshots) is human and is recorded in the log, not scripted here.
# The registry tools come from `git archive origin/main` of the registry repository, extracted into a mktemp -d; its working
# tree is never read or written. Set WOM_REGISTRY_REPO to another clone; if the directory is absent, a public clone is used.
set -u
export PYTHONDONTWRITEBYTECODE=1 LC_ALL=C.UTF-8
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$HERE" || exit 2
PIN_BASE="2b2872c382c1728b500b9684757f99162b407464"
PIN_FINAL="1ea5ba4ee3db687a19b412b267b1b96fd0d4bb8f"
fails=0
ok()  { echo "  ok   $*"; }
bad() { echo "  FAIL $*"; fails=$((fails + 1)); }
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wom010a-XXXXXX")"
trap 'rm -r -- "$TMP"' EXIT

STAGE=docs/test-mod
GEN=tools/test-mod/make_screenshots.py
FILL=tools/test-mod/fill_placeholders.py
CHK=tools/test-mod/tests/check_tree.py

echo "== registry tools (git archive of origin/main, never the working tree)"
REG="$TMP/registry"; mkdir "$REG"
REG_REPO="${WOM_REGISTRY_REPO:-/home/ludwig/registry}"
if [ -d "$REG_REPO/.git" ]; then
  REG_REF=origin/main; REG_SRC="$REG_REPO"
else
  git clone -q --depth 1 https://github.com/worldofmodcraft/registry "$TMP/regclone" || { echo "cannot obtain the registry"; exit 2; }
  REG_REF=HEAD; REG_SRC="$TMP/regclone"
fi
REG_COMMIT="$(git -C "$REG_SRC" rev-parse "$REG_REF")"
git -C "$REG_SRC" archive "$REG_REF" | tar -x -C "$REG" || { echo "archive failed"; exit 2; }
echo "  registry commit: $REG_COMMIT"
[ -f "$REG/tools/validation/scan_assets.py" ] && ok "registry tools extracted" || { bad "registry tools missing"; exit 2; }

# check ONLY STAGE : run the checker; echo its exit code
check() { python3 -I "$CHK" --stage "$1" --registry "$REG" --generator "${GEN_OVERRIDE:-$GEN}" --fill-script "${FILL_OVERRIDE:-$FILL}" --only "$2" >"$TMP/out" 2>&1; echo $?; }

echo "== criteria 1-4 live on HEAD (staging tree $STAGE)"
python3 -I "$CHK" --stage "$STAGE" --registry "$REG" --generator "$GEN" --fill-script "$FILL" --only 1,1build,2,3,4 >"$TMP/live.out" 2>&1; rc=$?
grep -c '^  ok ' "$TMP/live.out" | sed 's/^/  checks passed: /'
if [ "$rc" = 0 ] && ! grep -q '^  FAIL' "$TMP/live.out"; then ok "check_tree.py --only 1,1build,2,3,4 -> exit 0"; else bad "check_tree.py -> exit $rc"; grep '^  FAIL' "$TMP/live.out" | head -10; fi

echo "== unit tests of make_screenshots.py and fill_placeholders.py on HEAD"
python3 -m unittest discover -s tools/test-mod/tests -p 'test_*.py' >"$TMP/unit.out" 2>&1; rc=$?
tail -3 "$TMP/unit.out" | sed 's/^/  /'
[ "$rc" = 0 ] && ok "unittest discover -> exit 0" || bad "unit tests -> exit $rc"

echo "== criterion 11 mutations: each broken copy must make the checker exit 1 (a crash, exit 2, is not red enough)"
# mut NAME ONLY CMD : copy the staging tree to $TMP/mNAME, apply CMD (cwd = the copy), confirm it changed something, expect exit 1
n=0
mut() {
  local name=$1 only=$2 cmd=$3 d rc
  n=$((n + 1)); d="$TMP/m$n"; mkdir "$d"; cp -r "$STAGE" "$d/test-mod"
  ( cd "$d/test-mod" && eval "$cmd" ) >/dev/null 2>&1
  if diff -rq "$STAGE" "$d/test-mod" >/dev/null 2>&1 && [ -z "${FILL_OVERRIDE:-}" ] && [ -z "${GEN_OVERRIDE:-}" ]; then bad "$name: the mutation changed nothing"; return; fi
  rc=$(check "$d/test-mod" "$only")
  if [ "$rc" = 1 ]; then ok "$name -> exit 1 ($(grep -m1 '^  FAIL' "$TMP/out" | cut -c8-110))"; else bad "$name -> exit $rc, expected 1"; tail -3 "$TMP/out" | cut -c1-160; fi
}
H=hello-world; P=registry-pr
echo " -- criterion 1"
mut "1 planted DBC-magic file"      1 "printf 'WDBC' > $H/planted.bin; head -c 60 /dev/zero >> $H/planted.bin"
mut "1 license not OSI (Proprietary)" 1 "sed -i 's/license = \"MIT\"/license = \"Proprietary\"/' $H/mod.lua"
mut "1 wrong id"                    1 "sed -i 's/id = \"test:hello-world\"/id = \"test:other\"/' $H/mod.lua"
mut "1 string concatenation in mod.lua" 1 "sed -i 's|source = \"https://github.com/OWNER-PLACEHOLDER/wom-test-hello-world\"|source = \"https://github.com/\" .. \"x\"|' $H/mod.lua"
mut "1 a listed screenshot deleted"  1 "rm $H/assets/screenshots/gallery.png"
mut "1 PNG truncated (no IEND at the end)" 1 "f=$H/assets/screenshots/welcome.png; head -c \$(( \$(stat -c %s \$f) - 5 )) \$f > \$f.t && mv \$f.t \$f"
mut "1 screenshot path escapes with .." 1 "sed -i 's|\"assets/screenshots/gallery.png\"|\"../gallery.png\"|' $H/mod.lua"
mut "1 README loses its table"       1 "sed -i '/^| --- /d' $H/README.md"
mut "1 README loses the canary words" 1 "sed -i 's/permanent pipeline canary/permanent thing/g' $H/README.md"
mut "1 ai_assisted dropped"          1 "sed -i '/ai_assisted/d' $H/mod.lua"
mut "1 build: scanner-rejected file in the commit" 1build "printf 'WDBC' > $H/planted.bin; head -c 60 /dev/zero >> $H/planted.bin"
echo " -- criterion 2"
mut "2 gallery.png replaced by spare.png (valid PNG, wrong pixels)" 2 "cp $H/assets/screenshots/spare.png $H/assets/screenshots/gallery.png"
mut "2 file named like an extracted game asset" 2 "cp $H/LICENSE $H/Interface.blp"
mut "2 Blizzard magic bytes in a file" 2 "printf 'MPQ\\032' > $H/data.bin; head -c 60 /dev/zero >> $H/data.bin"
echo " -- criterion 3"
mut "3 page.json lists spare.png (not a subset)" 3 "sed -i 's|\"assets/screenshots/gallery.png\"|\"assets/screenshots/spare.png\"|' $P/page.json"
mut "3 page.json screenshot with .." 3 "sed -i 's|\"assets/screenshots/gallery.png\"|\"../gallery.png\"|' $P/page.json"
mut "3 entry version gets a fifth key" 3 "sed -i 's|\"status\": \"pending\"|\"status\": \"pending\", \"source_archive\": \"https://example.invalid/x\"|' $P/entry.json"
mut "3 entry owner id changed" 3 "sed -i 's/324218296/324218297/' $P/entry.json"
mut "3 entry commit not 40 hex" 3 "sed -i 's/0000000000000000000000000000000000000000/zz/' $P/entry.json"
mut "3 page.json loses a required field" 3 "sed -i '/\"deprecated\"/d; s/\"links\": \\[\\],/\"links\": []/' $P/page.json"
echo " -- criterion 4"
mut "4 placeholder token leaks into README" 4 "echo 'see https://github.com/OWNER-PLACEHOLDER/x' >> $H/README.md"
mut "4 token missing from mod.lua (search would find nothing)" 4 "sed -i 's/OWNER-PLACEHOLDER/someone/' $H/mod.lua"
mut "4 token missing from entry.json" 4 "sed -i 's/0000000000000000000000000000000000000000/1111111111111111111111111111111111111111/' $P/entry.json"
# the fill script mutated so it leaves the commit token behind AND no longer asserts: criterion 4 must notice by itself
sed -e 's/out = out.replace(COMMIT_TOKEN, check_commit(commit))/pass/' -e 's/raise Refused(f"token {tok!r} is still present after filling")/pass/' "$FILL" >"$TMP/fill-mutant.py"
cmp -s "$FILL" "$TMP/fill-mutant.py" && bad "fill-script mutant is identical to the original"
FILL_OVERRIDE="$TMP/fill-mutant.py" mut "4 fill script leaves the commit token and does not assert" 4 "true"
unset FILL_OVERRIDE

echo "== own change on the fixed range $PIN_BASE..$PIN_FINAL"
if [ "$PIN_FINAL" = "__FINAL__" ]; then bad "PIN_FINAL not recorded"; else
  if git cat-file -e "$PIN_BASE^{commit}" 2>/dev/null && git cat-file -e "$PIN_FINAL^{commit}" 2>/dev/null; then
    extra=$(git diff --name-only "$PIN_BASE" "$PIN_FINAL" | grep -v -E '^(docs/test-mod/hello-world/.+|docs/test-mod/registry-pr/(entry|page)\.json|tools/test-mod/(make_screenshots|fill_placeholders)\.py|tools/test-mod/tests/.+|docs/tasks/010a-test-mod-contents\.md|docs/tasks/010a-verify\.sh)$')
    [ -z "$extra" ] && ok "only files in the declared scope changed" || bad "out-of-scope files: $extra"
    git diff --name-only "$PIN_BASE" "$PIN_FINAL" | grep -q -E '__pycache__|\.pyc$|\.(key|pub|minisig)$' && bad "bytecode or key-like file in the change" || ok "no bytecode, key or signature file in the change"
    git diff --quiet "$PIN_BASE" "$PIN_FINAL" -- CLAUDE.md docs/manager docs/decisions docs/runbooks && ok "CLAUDE.md, manager docs, decisions and runbooks untouched" || bad "protected docs changed"
    PLANT="untrusted comment: minisign encrypted ""secret key"   # two literals, so this file passes secret scans
    if git grep -I -n -e "$PLANT" -e "PRIVATE KEY" -e "ghp_" -e "github_pat_" "$PIN_FINAL" -- docs/test-mod tools/test-mod docs/tasks/010a-test-mod-contents.md >/dev/null; then bad "secret-shaped string in the change"; else ok "no secret-shaped string in the changed tree"; fi
    n_png=$(git ls-tree -r --name-only "$PIN_FINAL" -- docs/test-mod/hello-world/assets/screenshots | grep -c '\.png$')
    [ "$n_png" = 3 ] && ok "three PNGs committed" || bad "$n_png PNGs committed, expected 3"
  else
    bad "PIN_BASE or PIN_FINAL is not in this clone (fetch the task branch)"
  fi
fi
[ -x "docs/tasks/010a-verify.sh" ] && ok "this script is executable" || bad "010a-verify.sh is not executable"
[ "$(git ls-files -s docs/tasks/010a-verify.sh | cut -c1-6)" = 100755 ] && ok "recorded as mode 100755 in git" || bad "not mode 100755 in git"

echo; echo "registry commit used: $REG_COMMIT"
[ "$fails" -eq 0 ] && { echo "010a-verify: ALL OK"; exit 0; } || { echo "010a-verify: $fails FAIL"; exit 1; }
