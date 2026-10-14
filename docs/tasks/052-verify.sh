#!/usr/bin/env bash
# Task 052 verification artefact (MANAGER.md section 2c).  Runs ONLY against temporary directories:
# temp repos, a temp remote, a temp vault and a temp HOME.  It never touches the real vault, /mnt or
# ~/.config/wom, and it never installs hooks anywhere but into temp repos (the installer refuses otherwise).
#   docs/tasks/052-verify.sh            AC1-AC5
#   docs/tasks/052-verify.sh --mutate   additionally break a temp copy of the tool once per guard (AC6)
# AC7 (live, with Ludwig) is human and is not covered here.  AC8 is a documented gap.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
FAIL=0
say() { printf '%s\n' "$*"; }
red() { say "FAIL: $*"; FAIL=1; }
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then say "ok: $d"; else red "$d"; fi; }

case "${TMPDIR:-/tmp}" in /mnt|/mnt/*) say "refusing to run: TMPDIR is under /mnt/"; exit 3;; /*) ;; *) say "refusing to run: TMPDIR is not absolute"; exit 3;; esac
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wom052-XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
case "$(realpath -- "$TMP")" in /mnt/*) say "refusing to run: temp dir resolves under /mnt/"; exit 3;; esac

# A private environment: temp HOME, test mode, git without any global config.
export HOME="$TMP/home"; mkdir -p "$HOME"
export WOM_VAULT_TEST=1 PYTHONDONTWRITEBYTECODE=1
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null LC_ALL=C.UTF-8
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
unset WOM_VAULT WOM_GUARD_MNT_ROOT
say "== environment: temp root $TMP, git $(git --version | cut -d' ' -f3), python $(python3 -I -c 'import sys;print(sys.version.split()[0])')"

RUNID=main
SRC="$REPO"   # the tree under test: must hold tools/vault/ and .claude/

# ------------------------------------------------------------------ world builder
# new_world NAME: bare remote + seed clone A (the "other developer") + clone B (the machine under test).
new_world() {
  W="$TMP/w-$RUNID/$1"; A="$W/a"; B="$W/b"; mkdir -p "$W"; export WOM_VAULT="$W/vault"; mkdir -p "$WOM_VAULT"
  git init -q --bare -b main "$W/remote.git"
  git init -q -b main "$A"
  mkdir -p "$A/docs/manager" "$A/docs/tasks" "$A/tools/vault"
  printf 'ops v1\n' > "$A/docs/manager/OPERATIONS.md"
  printf 'commands v1\n' > "$A/docs/manager/COMMANDS.md"
  printf '# Mission log\n## SESSION 1 - first\nbody\n' > "$A/docs/tasks/MISSION-worldofmodcraft-site-v1-log.md"
  printf '# Task 060: Alpha\n\n- **Status:** in-progress\n\n## Task 060 log\n- started\n' > "$A/docs/tasks/060-alpha.md"
  cp -a "$SRC/tools/vault/wom_vault.py" "$SRC/tools/vault/install-git-hooks.sh" "$SRC/tools/vault/refresh-main.sh" "$SRC/tools/vault/git-hooks" "$A/tools/vault/"
  git -C "$A" add -A && git -C "$A" commit -q -m "seed"
  git -C "$A" remote add origin "$W/remote.git" && git -C "$A" push -q origin main
  git clone -q "$W/remote.git" "$B"
}
a_commit() { # a_commit FILE TEXT MSG : change a file in A and push to the remote
  printf '%s\n' "$2" >> "$A/$1"; git -C "$A" add -A && git -C "$A" commit -q -m "$3" && git -C "$A" push -q origin main
}
install_hooks() { "$B/tools/vault/install-git-hooks.sh" --repo "$B" >"$W/install.out" 2>&1; }
vault_files() { (cd "$WOM_VAULT" && find . -type f | sort); }
add_task_wt() { git -C "$B" worktree add -q -b task/060-alpha "$W/wt60" main; }

# ------------------------------------------------------------------ checks
ac1() {
  say "== AC1: commit on task/NNN-* writes Tasks/NNN.md; other branch writes nothing; pull writes main; fetch does not"
  new_world ac1; install_hooks || red "AC1 installer failed: $(cat "$W/install.out")"
  git -C "$B" worktree add -q -b feature/x "$W/wtx" main; add_task_wt
  printf 'x\n' >> "$W/wtx/docs/manager/COMMANDS.md"; git -C "$W/wtx" add -A
  git -C "$W/wtx" commit -q -m "other branch" 2>"$W/other.err"
  check "AC1 commit on a non-task branch writes nothing" test -z "$(vault_files)"
  check "AC1 and the hook is silent there" test ! -s "$W/other.err"
  printf -- '- second entry\n' >> "$W/wt60/docs/tasks/060-alpha.md"; git -C "$W/wt60" add -A
  git -C "$W/wt60" commit -q -m "task commit" 2>"$W/task.err"; say "   task commit stderr: $(tr '\n' '|' < "$W/task.err")"
  check "AC1 commit on task/060-alpha writes exactly Tasks/060.md" test "$(vault_files)" = "./Tasks/060.md"
  check "AC1 the note carries the new log entry" grep -qF -- '- second entry' "$WOM_VAULT/Tasks/060.md"
  check "AC1 the hook printed pinned_commit" grep -qF 'wom-vault: pinned_commit=' "$W/task.err"
  # real git pull of main
  a_commit docs/manager/OPERATIONS.md "ops v2 pulled" "ops v2"
  git -C "$B" pull -q --ff-only origin main 2>"$W/pull.err"; say "   pull stderr: $(tr '\n' '|' < "$W/pull.err")"
  check "AC1 a real git pull of main writes Gotchas.md with the new text" grep -qF 'ops v2 pulled' "$WOM_VAULT/Gotchas.md"
  check "AC1 and Status.md" test -f "$WOM_VAULT/Status.md"
  # gap: a fetch into a non-checked-out main fires no post-merge
  new_world gap; install_hooks; git -C "$B" checkout -q --detach
  a_commit docs/manager/OPERATIONS.md "ops v2 fetched" "ops v2"
  git -C "$B" fetch -q origin main:main
  check "AC1 (gap) git fetch origin main:main advanced main" test "$(git -C "$B" log -1 --format=%s main)" = "ops v2"
  check "AC1 (gap) ...and wrote nothing to the vault" test -z "$(vault_files)"
  "$B/tools/vault/refresh-main.sh" --repo "$B" >"$W/refresh2.out" 2>&1; rc=$?
  check "AC1 refresh-main.sh (main NOT checked out anywhere) exits 0" test "$rc" = 0
  check "AC1 ...used git fetch origin main:main" grep -qF 'main is not checked out anywhere' "$W/refresh2.out"
  check "AC1 ...and updated main's notes" grep -qF 'ops v2 fetched' "$WOM_VAULT/Gotchas.md"
  # layout 1: main checked out in a worktree; hooks NOT installed, so the write is refresh-main's own
  new_world lay1; "$B/tools/vault/install-git-hooks.sh" --repo "$B" --pin-only >/dev/null 2>&1; add_task_wt
  a_commit docs/manager/OPERATIONS.md "ops v2 layout1" "ops v2"
  (cd "$W/wt60" && "$B/tools/vault/refresh-main.sh") >"$W/refresh1.out" 2>&1; rc=$?
  check "AC1 refresh-main.sh (main checked out in a worktree), run from a task worktree, exits 0" test "$rc" = 0
  check "AC1 ...pulled in main's worktree" grep -qF 'main is checked out at' "$W/refresh1.out"
  check "AC1 ...main's checkout advanced" test "$(git -C "$B" log -1 --format=%s)" = "ops v2"
  check "AC1 ...and updated main's notes" grep -qF 'ops v2 layout1' "$WOM_VAULT/Gotchas.md"
}

ac1b() {
  say "== AC1b: pinned copy byte-identical, stale warning, re-pin"
  new_world ac1b; install_hooks; add_task_wt
  check "AC1b pinned copy is byte-identical to git show main:tools/vault/wom_vault.py" \
    cmp <(git -C "$B" show main:tools/vault/wom_vault.py) "$B/.git/wom-vault/wom_vault.py"
  check "AC1b pinned_commit is the last commit touching tools/vault/" \
    test "$(cat "$B/.git/wom-vault/pinned_commit")" = "$(git -C "$B" log -1 --format=%H main -- tools/vault/)"
  old="$(cat "$B/.git/wom-vault/pinned_commit")"
  a_commit tools/vault/wom_vault.py "# a newer tool" "tool change"
  git -C "$B" pull -q --ff-only origin main 2>"$W/pull.err"
  check "AC1b after a new tools/vault commit the hook warns pinned copy is stale" grep -qF 'wom-vault: pinned copy is stale; run refresh-main.sh' "$W/pull.err"
  printf -- '- stale probe\n' >> "$W/wt60/docs/tasks/060-alpha.md"; git -C "$W/wt60" add -A
  git -C "$W/wt60" commit -q -m "while stale" 2>"$W/stale.err"
  check "AC1b a task commit while stale also warns" grep -qF 'wom-vault: pinned copy is stale; run refresh-main.sh' "$W/stale.err"
  check "AC1b the pinned copy was NOT silently replaced" test "$(cat "$B/.git/wom-vault/pinned_commit")" = "$old"
  "$B/tools/vault/refresh-main.sh" --repo "$B" >"$W/refresh.out" 2>&1; rc=$?
  check "AC1b refresh-main.sh exits 0" test "$rc" = 0
  check "AC1b pinned_commit now matches main" test "$(cat "$B/.git/wom-vault/pinned_commit")" = "$(git -C "$B" log -1 --format=%H main -- tools/vault/)"
  check "AC1b pinned copy is the new bytes" cmp <(git -C "$B" show main:tools/vault/wom_vault.py) "$B/.git/wom-vault/wom_vault.py"
  printf -- '- third\n' >> "$W/wt60/docs/tasks/060-alpha.md"; git -C "$W/wt60" add -A
  git -C "$W/wt60" commit -q -m "after refresh" 2>"$W/after.err"
  check "AC1b the stale warning is gone" bash -c '! grep -qF "pinned copy is stale" "$1"' _ "$W/after.err"
  check "AC1b and the hook prints the new pinned_commit" grep -qF "pinned_commit=$(cat "$B/.git/wom-vault/pinned_commit")" "$W/after.err"
}

ac2() {
  say "== AC2: unconfigured vault is skipped and logged; a broken vault fails loudly"
  new_world ac2; install_hooks; add_task_wt
  printf -- '- u\n' >> "$W/wt60/docs/tasks/060-alpha.md"; git -C "$W/wt60" add -A
  env -u WOM_VAULT git -C "$W/wt60" commit -q -m "unconfigured" 2>"$W/un.err"; rc=$?
  check "AC2 (test mode, no WOM_VAULT) the commit succeeds" test "$rc" = 0
  check "AC2 stderr says not configured, skipped" grep -qF 'wom-vault: not configured, skipped' "$W/un.err"
  check "AC2 the skip is logged with its reason" grep -qF 'not configured' "$B/.git/wom-vault/skips.log"
  check "AC2 nothing was written to the vault" test -z "$(vault_files)"
  mkdir -p "$W/emptyhome"
  printf -- '- u2\n' >> "$W/wt60/docs/tasks/060-alpha.md"; git -C "$W/wt60" add -A
  env -u WOM_VAULT -u WOM_VAULT_TEST HOME="$W/emptyhome" git -C "$W/wt60" commit -q -m "unconfigured nontest" 2>"$W/un2.err"; rc=$?
  check "AC2 (non-test, empty HOME) the commit succeeds" test "$rc" = 0
  check "AC2 ...with the same stderr line" grep -qF 'wom-vault: not configured, skipped' "$W/un2.err"
  check "AC2 ...and a second logged skip" test "$(wc -l < "$B/.git/wom-vault/skips.log")" -ge 2
  printf -- '- b\n' >> "$W/wt60/docs/tasks/060-alpha.md"; git -C "$W/wt60" add -A
  WOM_VAULT="$W/does-not-exist" git -C "$W/wt60" commit -q -m "broken" 2>"$W/br.err"; rc=$?
  check "AC2 a broken vault does not block the commit (git ignores post-commit)" test "$rc" = 0
  check "AC2 ...and the error is on stderr" grep -qF 'WOM_VAULT does not exist' "$W/br.err"
  (cd "$W/wt60" && WOM_VAULT="$W/does-not-exist" "$B/.git/hooks/post-commit") >/dev/null 2>"$W/br2.err"; rc=$?
  check "AC2 run directly, the hook exits non-zero for a broken vault" test "$rc" != 0
  check "AC2 ...with the error on stderr" grep -qF 'WOM_VAULT does not exist' "$W/br2.err"
}

ac3() {
  say "== AC3: installer scope, refusal of a foreign hook, idempotence, test-mode refusal"
  new_world ac3; mkdir -p "$B/.git/hooks"
  find "$B" -path "$B/.git" -prune -o -print | sort > "$W/tree.before"; find "$B/.git" -type f | sort > "$W/git.before"
  sums_remote="$(find "$W/remote.git" "$A" -type f | sort | xargs md5sum | md5sum)"
  install_hooks; rc=$?
  check "AC3 installer exits 0" test "$rc" = 0
  find "$B" -path "$B/.git" -prune -o -print | sort > "$W/tree.after"; find "$B/.git" -type f | sort > "$W/git.after"
  check "AC3 working tree untouched" cmp "$W/tree.before" "$W/tree.after"
  check "AC3 other repos untouched" test "$sums_remote" = "$(find "$W/remote.git" "$A" -type f | sort | xargs md5sum | md5sum)"
  added="$(comm -13 "$W/git.before" "$W/git.after" | sed "s|^$B/.git/||" | tr '\n' ' ')"
  say "   files added under the git dir: $added"
  check "AC3 only hooks/post-commit hooks/post-merge wom-vault/pinned_commit wom-vault/wom_vault.py were added" \
    test "$added" = "hooks/post-commit hooks/post-merge wom-vault/pinned_commit wom-vault/wom_vault.py "
  s1="$(cd "$B/.git" && md5sum hooks/post-commit hooks/post-merge wom-vault/* | md5sum)"
  install_hooks; rc=$?
  check "AC3 second run exits 0 (idempotent)" test "$rc" = 0
  check "AC3 ...and changes nothing" test "$s1" = "$(cd "$B/.git" && md5sum hooks/post-commit hooks/post-merge wom-vault/* | md5sum)"
  new_world ac3b; printf '#!/bin/sh\necho mine\n' > "$B/.git/hooks/post-commit"; chmod +x "$B/.git/hooks/post-commit"
  install_hooks; rc=$?
  check "AC3 an existing non-WoM hook makes the installer exit non-zero" test "$rc" != 0
  check "AC3 ...naming the file" grep -qF 'is not a WoM hook' "$W/install.out"
  check "AC3 ...the foreign hook is untouched" test "$(cat "$B/.git/hooks/post-commit")" = "$(printf '#!/bin/sh\necho mine')"
  check "AC3 ...and nothing else was installed" test ! -e "$B/.git/hooks/post-merge" -a ! -e "$B/.git/wom-vault"
  new_world ac3c; mkdir -p "$TMP/other-tmp"
  TMPDIR="$TMP/other-tmp" "$B/tools/vault/install-git-hooks.sh" --repo "$B" >"$W/install.out" 2>&1; rc=$?
  check "AC3 test mode refuses a git dir not under the temp dir (exit non-zero)" test "$rc" != 0
  check "AC3 ...saying so" grep -qF 'test mode: refusing git dir' "$W/install.out"
  check "AC3 ...and wrote nothing" test ! -e "$B/.git/hooks/post-commit" -a ! -e "$B/.git/wom-vault"
}

GUARD_REL=".claude/hooks/vault-guard.sh"
gj() { python3 -I -c 'import json,sys; t,k,p,c=sys.argv[1:5]; print(json.dumps({"tool_name":t,"tool_input":{k:p},"cwd":c}))' "$@"; }
run_guard() { # run_guard HOME JSON [VAR=VAL...] ; prints the exit status
  local h="$1" j="$2"; shift 2
  printf '%s' "$j" | env -i PATH="$PATH" HOME="$h" "$@" "$SRC/$GUARD_REL" >/dev/null 2>"$TMP/guard.err"; echo $?
}
expect_guard() { # expect_guard WANT DESC HOME JSON [env...]
  local want="$1" d="$2"; shift 2; local got; got="$(run_guard "$@")"
  if [ "$got" = "$want" ]; then say "ok: AC4 $d (exit $got)"; else red "AC4 $d (wanted exit $want, got $got: $(head -c 200 "$TMP/guard.err"))"; fi
}
ac4() {
  say "== AC4: vault-guard fixtures"
  local G="$TMP/w-$RUNID/g"; mkdir -p "$G/home/.config/wom" "$G/vault/sub" "$G/vault/My Notes" "$G/repo" "$G/mnt/d/WomVault"
  printf '%s\n' "$G/vault" > "$G/home/.config/wom/vault-path"
  ln -s "$G/vault" "$G/link"
  local H="$G/home" V="$G/vault"
  expect_guard 2 "absolute path inside" "$H" "$(gj Write file_path "$V/Status.md" "$G/repo")"
  expect_guard 2 "relative path from a cwd inside" "$H" "$(gj Edit file_path "Note.md" "$V")"
  expect_guard 2 "relative ../ from a cwd inside" "$H" "$(gj Edit file_path "../x.md" "$V/sub")"
  expect_guard 2 ".. traversal into the vault" "$H" "$(gj Write file_path "$G/repo/../vault/x.md" "$G/repo")"
  expect_guard 2 "path with spaces" "$H" "$(gj MultiEdit file_path "$V/My Notes/a b.md" "$G/repo")"
  expect_guard 2 "upper-case variant" "$H" "$(gj Write file_path "$(printf '%s' "$V" | tr '[:lower:]' '[:upper:]')/x.md" "$G/repo")"
  expect_guard 2 "lower-case variant" "$H" "$(gj Write file_path "$(printf '%s' "$V" | tr '[:upper:]' '[:lower:]')/x.md" "$G/repo")"
  expect_guard 2 "symlink into the vault" "$H" "$(gj Write file_path "$G/link/x.md" "$G/repo")"
  expect_guard 2 "notebook_path inside" "$H" "$(gj NotebookEdit notebook_path "$V/n.ipynb" "$G/repo")"
  expect_guard 0 "notebook_path outside" "$H" "$(gj NotebookEdit notebook_path "$G/repo/n.ipynb" "$G/repo")"
  expect_guard 0 "path outside the vault" "$H" "$(gj Write file_path "$G/repo/file.txt" "$G/repo")"
  expect_guard 0 "sibling that merely shares a prefix" "$H" "$(gj Write file_path "${V}-other/x.md" "$G/repo")"
  expect_guard 2 "invalid JSON" "$H" "this is not json"
  expect_guard 2 "Write without any path" "$H" '{"tool_name":"Write","tool_input":{}}'
  expect_guard 2 "WOM_VAULT from the environment, no config file" "$G/nohome" "$(gj Write file_path "$V/x.md" "$G/repo")" "WOM_VAULT=$V"
  # drive-letter forms: a test-only mount root under TMPDIR stands in for /mnt, so no real drive is ever looked at
  mkdir -p "$G/dhome/.config/wom"; printf 'D:\\WomVault\n' > "$G/dhome/.config/wom/vault-path"
  local DE=(WOM_VAULT_TEST=1 "TMPDIR=$TMP" "WOM_GUARD_MNT_ROOT=$G/mnt")
  expect_guard 2 "D:\\ path (vault configured as D:\\)" "$G/dhome" "$(gj Write file_path 'D:\WomVault\x.md' "$G/repo")" "${DE[@]}"
  expect_guard 2 "d:/ mixed-slash path" "$G/dhome" "$(gj Write file_path 'd:/WomVault/sub/x.md' "$G/repo")" "${DE[@]}"
  expect_guard 2 "D:\\ path, other case" "$G/dhome" "$(gj Write file_path 'D:\WOMVAULT\x.md' "$G/repo")" "${DE[@]}"
  expect_guard 0 "D:\\ path outside the vault" "$G/dhome" "$(gj Write file_path 'D:\Other\x.md' "$G/repo")" "${DE[@]}"
  expect_guard 2 "/mnt/d form of the same vault, via the config as a Linux path" "$H" "$(gj Write file_path "$G/mnt/d/WomVault/x.md" "$G/repo")" "WOM_VAULT=$G/mnt/d/WomVault"
  if python3 -I -B - "$SRC/.claude/hooks/vault_guard.py" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("g", sys.argv[1]); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
assert m.normalise("D:\\a\\B", "/x") == "/mnt/d/a/B", m.normalise("D:\\a\\B", "/x")
assert m.normalise("d:/a/B", "/x") == "/mnt/d/a/B"
PY
  then say "ok: AC4 D:\\ and d:/ normalise to /mnt/d/... (pure string function, no filesystem access)"; else red "AC4 drive-letter normalisation"; fi
  # configured but unresolvable
  mkdir -p "$G/ghome/.config/wom"; printf '%s\n' "$G/gone-vault" > "$G/ghome/.config/wom/vault-path"
  expect_guard 2 "configured-but-missing vault: a path under it" "$G/ghome" "$(gj Write file_path "$G/gone-vault/x.md" "$G/repo")"
  expect_guard 2 "configured-but-missing vault: upper-case variant" "$G/ghome" "$(gj Write file_path "$(printf '%s' "$G/gone-vault" | tr '[:lower:]' '[:upper:]')/x.md" "$G/repo")"
  expect_guard 0 "configured-but-missing vault: a repo path" "$G/ghome" "$(gj Write file_path "$G/repo/file.txt" "$G/repo")"
  # unconfigured
  mkdir -p "$G/uhome"
  expect_guard 0 "unconfigured vault allows" "$G/uhome" "$(gj Write file_path "$V/x.md" "$G/repo")"
  check "AC4 ...and the skip is counted in guard-skips.log" test "$(wc -l < "$G/uhome/.config/wom/guard-skips.log")" -ge 1
  # the wrapper fails closed for its own missing sibling
  mkdir -p "$G/lonely"; cp "$SRC/$GUARD_REL" "$G/lonely/vault-guard.sh"
  printf '{}' | "$G/lonely/vault-guard.sh" >/dev/null 2>&1; rc=$?
  if [ "$rc" = 2 ]; then say "ok: AC4 a wrapper without vault_guard.py blocks (exit 2)"; else red "AC4 wrapper without vault_guard.py exited $rc"; fi
}

ac5() {
  say "== AC5: wiring"
  local S="$SRC/.claude/settings.json"
  check "AC5 settings.json is valid JSON" python3 -I -c 'import json,sys; json.load(open(sys.argv[1]))' "$S"
  check "AC5 PreToolUse matcher covers Write, Edit, MultiEdit and NotebookEdit" python3 -I - "$S" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
ms = [e["matcher"] for e in d["hooks"]["PreToolUse"]]
need = {"Write", "Edit", "MultiEdit", "NotebookEdit"}
assert any(need <= set(m.split("|")) for m in ms), ms
PY
  cmd="$(python3 -I -c 'import json,sys; d=json.load(open(sys.argv[1])); print([h["command"] for e in d["hooks"]["PreToolUse"] for h in e["hooks"]][0])' "$S" 2>/dev/null)"
  say "   command: $cmd"
  path="${cmd//\"/}"; path="${path//\$CLAUDE_PROJECT_DIR/$SRC}"
  check "AC5 the command path exists" test -f "$path"
  check "AC5 ...and is executable" test -x "$path"
  check "AC5 the python half exists" test -f "$SRC/.claude/hooks/vault_guard.py"
  check "AC5 the committed git mode of the wrapper is executable" bash -c 'git -C "$1" ls-files -s -- .claude/hooks/vault-guard.sh | grep -q "^100755"' _ "$REPO"
}

run_checks() { ac1; ac1b; ac2; ac3; ac4; ac5; }

say "== AC1-AC5 (tree under test: $SRC)"
run_checks
if ! git -C "$REPO" ls-files -- tools/vault .claude docs/tasks/052-verify.sh | grep -E '__pycache__|\.pyc$' >/dev/null; then say "ok: no bytecode is tracked in this task's scope"; else red "bytecode is tracked in this task's scope"; fi

# ------------------------------------------------------------------ AC6: mutations
mutate() { # NAME FILE(relative to tree) ANCHOR REPLACEMENT EXPECTED-AC-PREFIX
  local name="$1" file="$2" anchor="$3" repl="$4" want="$5" d="$TMP/mut/$1"
  mkdir -p "$d/tools" "$d/.claude"; cp -a "$REPO/tools/vault" "$d/tools/"; cp -a "$REPO/.claude/hooks" "$REPO/.claude/settings.json" "$d/.claude/"
  rm -rf "$d/tools/vault/tests" "$d/tools/vault/__pycache__"
  python3 -I - "$d/$file" "$anchor" "$repl" <<'PY' || { red "mutation $name: anchor not found exactly once"; return; }
import sys
p, a, r = sys.argv[1:4]
t = open(p).read()
if t.count(a) != 1:
    sys.exit("anchor count %d" % t.count(a))
open(p, "w").write(t.replace(a, r))
PY
  if cmp -s "$REPO/$file" "$d/$file"; then red "mutation $name left the file identical"; return; fi
  ( SRC="$d"; RUNID="m-$name"; FAIL=0; run_checks; exit "$FAIL" ) > "$TMP/mut/$name.out" 2>&1; local rc=$?
  if [ "$rc" = 0 ]; then red "MUTANT SURVIVED: $name (every check stayed green)"
  elif grep -E "^FAIL: $want" "$TMP/mut/$name.out" >/dev/null; then say "ok: mutant '$name' killed -> $(grep -E '^FAIL:' "$TMP/mut/$name.out" | head -3 | cut -c1-110 | tr '\n' ';')"
  else red "mutant '$name' failed, but not in $want: $(grep -E '^FAIL:' "$TMP/mut/$name.out" | head -3)"; fi
}

if [ "${1:-}" = "--mutate" ]; then
  say "== AC6: mutation run (the unmutated copy must be green; each mutant must turn the matching checks red)"
  mkdir -p "$TMP/mut/control/tools" "$TMP/mut/control/.claude"; cp -a "$REPO/tools/vault" "$TMP/mut/control/tools/"; cp -a "$REPO/.claude/hooks" "$REPO/.claude/settings.json" "$TMP/mut/control/.claude/"
  ( SRC="$TMP/mut/control"; RUNID=control; FAIL=0; run_checks; exit "$FAIL" ) > "$TMP/mut/control.out" 2>&1 && say "ok: control (unmutated copy) is green" || { red "control copy is red"; grep '^FAIL' "$TMP/mut/control.out" | head; }
  mutate casefold .claude/hooks/vault_guard.py 'return s.casefold()  # CHECK:casefold' 'return s  # mutated' 'AC4'
  mutate realpath .claude/hooks/vault_guard.py 'return os.path.realpath(p)  # CHECK:realpath' 'return os.path.abspath(p)  # mutated' 'AC4'
  mutate fail-closed .claude/hooks/vault_guard.py 'if inside(lex, vlex) or inside(rp, vlex):  # CHECK:fail-closed-match' 'if False:  # mutated' 'AC4'
  mutate branch-filter tools/vault/git-hooks/post-commit 'case "$branch" in task/[0-9][0-9][0-9]-*) ;; *) exit 0;; esac # CHECK:branch-filter' ': # mutated' 'AC1'
  mutate installer-refusal tools/vault/install-git-hooks.sh 'case "$common/" in "$tmp"/*) ;; *) die' 'case "$common/" in *) ;; *) die' 'AC3'
  mutate installer-nonwom tools/vault/install-git-hooks.sh 'if [ -L "$dest" ] || ! grep -q -- "^$MARK" "$dest" 2>/dev/null; then # CHECK:installer-nonwom' 'if false; then # mutated' 'AC3'
  mutate stale-warning-merge tools/vault/git-hooks/post-merge 'elif [ "$latest" != "$pinned" ]; then # CHECK:stale' 'elif false; then # mutated' 'AC1b'
  mutate stale-warning tools/vault/git-hooks/post-commit 'elif [ "$latest" != "$pinned" ]; then # CHECK:stale' 'elif false; then # mutated' 'AC1b'
fi

if [ "$FAIL" -eq 0 ]; then say "== 052-verify: ALL CHECKS PASSED"; else say "== 052-verify: FAILED"; exit 1; fi
