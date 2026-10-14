# Commands

The commands Ludwig uses most, with the exact text to type. Mirrored into the vault as `Commands.md`.

## Vault projection (task 051; contract in `docs/tools/vault-projection.md`)

Run from `~/wom` (or any worktree). The vault path comes from `WOM_VAULT` or `~/.config/wom/vault-path`.

```
python3 -I tools/vault/wom_vault.py check --save-baseline "$HOME/wom-vault-baseline.json"
python3 -I tools/vault/wom_vault.py write --ref main
python3 -I tools/vault/wom_vault.py check --baseline "$HOME/wom-vault-baseline.json"
```

1. The first line records name, size and modified time of every file in the vault that the tool does not generate.
2. The second writes the generated notes from the `main` branch.
3. The third must say `0 differences`: it proves no hand-written note was touched.

Inside a task worktree on a `task/NNN-*` branch: `python3 -I tools/vault/wom_vault.py write --ref HEAD`
writes only that task's note.

Self-test of the tool (touches only temporary folders): `docs/tasks/051-verify.sh`, and with
`--mutate` it also proves each safety check can fail.
