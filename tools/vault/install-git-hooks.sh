#!/usr/bin/env bash
# Install the vault refresh hooks (task 052) into ONE repository's git common dir, and pin the tool.
#   install-git-hooks.sh [--repo PATH] [--pin-only]
# Writes only into "$(git rev-parse --git-common-dir)": hooks/post-commit, hooks/post-merge and wom-vault/.
# --pin-only re-pins the tool copy and leaves the hooks alone (used by refresh-main.sh).
# Test mode (WOM_VAULT_TEST=1) refuses any git dir that is not under realpath(${TMPDIR:-/tmp}).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARK="# wom-vault-hook v1"
repo="." pin_only=0
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) [ $# -ge 2 ] || { echo "install-git-hooks: --repo needs a path" >&2; exit 2; }; repo="$2"; shift 2;;
    --pin-only) pin_only=1; shift;;
    *) echo "usage: install-git-hooks.sh [--repo PATH] [--pin-only]" >&2; exit 2;;
  esac
done
die() { echo "install-git-hooks: $*" >&2; exit 1; }

common="$(git -C "$repo" rev-parse --git-common-dir 2>/dev/null)" || die "$repo is not a git repository"
common="$(cd "$repo" && cd "$common" && pwd -P)"
if [ "${WOM_VAULT_TEST:-}" = 1 ]; then
  tmp="$(realpath -- "${TMPDIR:-/tmp}")"
  case "$common/" in "$tmp"/*) ;; *) die "test mode: refusing git dir $common (not under $tmp)";; esac # CHECK:installer-refusal
fi
[ -z "$(git -C "$repo" config core.hooksPath || true)" ] || die "core.hooksPath is set; refusing to guess where hooks go"
git -C "$repo" rev-parse --verify -q main >/dev/null || die "no branch 'main' in $repo to pin from"
git -C "$repo" cat-file -e main:tools/vault/wom_vault.py 2>/dev/null || die "main has no tools/vault/wom_vault.py"
pinned_commit="$(git -C "$repo" log -1 --format=%H main -- tools/vault/)"
[ -n "$pinned_commit" ] || die "main has no commit touching tools/vault/"

if [ "$pin_only" = 0 ]; then
  for h in post-commit post-merge; do
    [ -f "$HERE/git-hooks/$h" ] || die "missing $HERE/git-hooks/$h"
    dest="$common/hooks/$h"
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      if [ -L "$dest" ] || ! grep -qxF -- "$MARK" "$dest" 2>/dev/null; then # CHECK:installer-nonwom
        die "$dest exists and is not a WoM hook; refusing to touch it"
      fi
    fi
  done
fi

mkdir -p "$common/wom-vault"
git -C "$repo" show main:tools/vault/wom_vault.py > "$common/wom-vault/.wom_vault.py.new"
mv -f -- "$common/wom-vault/.wom_vault.py.new" "$common/wom-vault/wom_vault.py"
printf '%s\n' "$pinned_commit" > "$common/wom-vault/.pinned_commit.new"
mv -f -- "$common/wom-vault/.pinned_commit.new" "$common/wom-vault/pinned_commit"
echo "pinned tools/vault/wom_vault.py at $pinned_commit in $common/wom-vault/"

if [ "$pin_only" = 0 ]; then
  mkdir -p "$common/hooks"
  for h in post-commit post-merge; do
    cp -- "$HERE/git-hooks/$h" "$common/hooks/.$h.new"
    chmod +x "$common/hooks/.$h.new"
    mv -f -- "$common/hooks/.$h.new" "$common/hooks/$h"
    echo "installed $common/hooks/$h"
  done
fi
