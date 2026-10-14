# Task 053: Decision and journal notes in the vault projection

- **Mission:** tooling (task 047, part C, step 2b; split out of 051 after the spec review) — **Status:** spec-approved (Ludwig, in session, 2026-10-14; spec v3)
- **Agent / model:** implementer / per agent frontmatter (ROUTING.md)
- **Budget:** small
- **Branch / worktree:** task/053-vault-adr-journal / ~/wt/task-053
- **Blocked by:** 051 merged (it extends `tools/vault/wom_vault.py` and inherits every write rule and the contract of 051)

## Objective
Mode `main` also writes `Decisions.md`, one `ADR/<file>.md` per ADR and `Journal/YYYY-MM-DD.md`. These
notes follow 051's contract, and their idempotence and secret-scan behaviour are proven by
`docs/tasks/053-verify.sh`.

## Contract additions (amend `docs/tools/vault-projection.md`)
| Note | Derived from | `source_commit` |
|---|---|---|
| `Decisions.md` | `docs/decisions/INDEX.json`: one row per ADR with id, title and a `[[ADR/<file stem>]]` link | last commit touching INDEX.json |
| `ADR/<file>.md` | `docs/decisions/NNNN-*.md`, body verbatim (ADRs carry no YAML frontmatter; checked on 0103, 2026-10-14). The generated frontmatter is prepended. If an ADR ever starts with `---`, the run fails validation instead of merging two frontmatter blocks. | last commit touching that file |
| `Journal/YYYY-MM-DD.md` | Every commit reachable from main, merges included, grouped by committer date in `Europe/Stockholm` (`zoneinfo`; system tzdata present). One line per commit, newest first: short sha, subject. | the newest commit of that day |

Each day file is re-rendered on every run and written only if its bytes changed, so a new commit
rewrites only its own day (051 write rule 3).

**Checked 2026-10-14 on main `3e2b6ef`:** none of the 120 ADR files starts with `---`. History is
108 commits over 8 Stockholm days. The first live run therefore writes about 130 notes in one LiveSync
burst (120 ADR notes, 8 Journal days, and the 051 set). That is accepted as a one-off; later runs write
only what changed. `ADR/` and `Journal/` are created under 051 write rule 5.

## File scope (declared)
`tools/vault/wom_vault.py`, `tools/vault/tests/**`, `docs/tools/vault-projection.md`, `docs/tasks/053-verify.sh`, this file's log.

## Acceptance criteria (all script-verified by `053-verify.sh`, output pasted in the log)
1. In a fixture repo: the note set includes `Decisions.md`, one ADR note per ADR file, and one Journal file
   per commit day, with exact contents checked against `git log` output.
2. A commit dated on a new day, or with a timestamp that crosses midnight UTC versus Stockholm time, lands
   in the correct Stockholm day. Only that day's file and `Decisions.md` / `ADR/*` notes whose source
   changed are rewritten.
3. An ADR fixture starting with `---` fails validation with nothing written.
4. A secret-pattern string inside an ADR fixture or a commit subject (built at runtime) blocks the whole
   run, as in 051 AC4.
5. `053-verify.sh --mutate` turns the checks for criteria 2 and 3 red. The script passes in a fresh clone.
6. All of 051's verify suite still passes (re-run, output pasted).

## Forbidden here
Everything forbidden in 051. In addition: changing any 051 write rule, and reading the vault beyond 051 rule 6.

## Dependency graph
Same node and edge as 051. The contract document is amended, not replaced.
