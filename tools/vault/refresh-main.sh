#!/usr/bin/env bash
# Manager step (task 052): bring local main up to date, re-pin the tool, refresh main's vault notes.
#   tools/vault/refresh-main.sh [--repo PATH]
# Run after each `gh pr merge` and at handover.  Any failure exits non-zero.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="."
case "${1:-}" in --repo) [ $# -ge 2 ] || { echo "refresh-main: --repo needs a path" >&2; exit 2; }; repo="$2";; "") ;; *) echo "usage: refresh-main.sh [--repo PATH]" >&2; exit 2;; esac
die() { echo "refresh-main: $*" >&2; exit 1; }
git -C "$repo" rev-parse --git-common-dir >/dev/null 2>&1 || die "$repo is not a git repository"
# Where is main checked out?  (first worktree whose branch is refs/heads/main)
main_wt="$(git -C "$repo" worktree list --porcelain | awk '/^worktree /{w=substr($0,10)} /^branch refs\/heads\/main$/{print w; exit}')"
if [ -n "$main_wt" ]; then
  echo "refresh-main: main is checked out at $main_wt: git pull --ff-only"
  git -C "$main_wt" pull --ff-only origin main
else
  echo "refresh-main: main is not checked out anywhere: git fetch origin main:main"
  git -C "$repo" fetch origin main:main
fi
"$HERE/install-git-hooks.sh" --repo "$repo" --pin-only
common="$(cd "$repo" && cd "$(git rev-parse --git-common-dir)" && pwd -P)"
python3 -I "$common/wom-vault/wom_vault.py" write --ref main --repo "$repo"
