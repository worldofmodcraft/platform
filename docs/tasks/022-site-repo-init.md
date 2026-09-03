# Task 022: Initialise and protect `worldofmodcraft/site`

- **Mission:** SITE-V1 — **Status:** spec-approved (manager, 2026-09-03)
- **Agent / model:** manager (infrastructure, no production code)
- **Budget:** small (<= 1 session)
- **Branch / worktree:** task/022-site-repo-init (platform repo; the site work is the repo itself)
- **Graph:** prepares node **N7** (`site-build`) so task 009 has a base to branch from. Introduces
  no new edges.

## Objective
`worldofmodcraft/site` has a `main` branch with a minimal, meaningful seed commit, and that branch
carries the same protection as `registry` and `platform` (PRs only, no force-push, no deletion,
administrators included, zero required approvals). Task 009 can then create a worktree from
`main`, work on `task/009-site-build`, and merge through a PR like every other task.

## Why this is a task and not a shell command
MANAGER.md guardrail 9: anything that creates or changes a remote, publishes anything, or rewrites
history is at minimum a small spec-approved task, however trivial it looks. This creates the
default branch of a public repository — the least reversible category of act available — and the
one time this project skipped that gate (session 1, task 012) it was skipped in exactly this
situation. The seed commit is also the one commit on this repository that can never be made by
pull request, because a PR needs a base branch that does not yet exist; that exception is stated
here deliberately so it is a recorded decision rather than a convenient silence.

## Context to load
- ADR-0039 (registry as a git repo), ADR-0006 (openness), ADR-0049 (licensing), ADR-0056 (English)
- Mission spec section 4, D3 (what the site repository is for)
- `docs/manager/OPERATIONS.md` — the branch-protection loop and the identities table
- `docs/tasks/done/013-branch-protection.md` — the protection settings applied to the other repos

## File scope (declared)
- In `worldofmodcraft/site` (new content): `README.md`, `.gitignore`, `LICENSE`
- In this repo: `docs/tasks/022-site-repo-init.md` (this file), `docs/manager/OPERATIONS.md`
  (the repositories table's "not cloned yet" row becomes true)

## Acceptance criteria
Each demonstrated by a command actually run, with its real output in the log.

1. `worldofmodcraft/site` has a `main` branch whose tree contains exactly `README.md`,
   `.gitignore` and `LICENSE`, committed as `womcraft <womcraft@snabbpost.com>`.
2. `README.md` states what the repository is, that its content is generated from the registry,
   and links the platform repository — no invented facts, no claims about a site that is not yet
   serving.
3. `LICENSE` matches the licence ADR-0049 specifies for platform code, and the choice is stated in
   the log with the ADR clause it comes from.
4. `.gitignore` covers the Node/Astro build outputs task 009 will produce (`node_modules/`,
   `dist/`, `.astro/`) and nothing speculative beyond that.
5. Branch protection on `main` matches `registry`: pull requests required, force-push blocked,
   deletion blocked, administrators included, zero required approvals. Demonstrated by reading the
   protection back from the API, not by asserting it was set.
6. A direct push to protected `main` is refused. Demonstrated by attempting one and pasting the
   refusal, with proof afterwards that no stray commit was left behind.
7. A local clone exists at `~/site` and `OPERATIONS.md`'s repositories table reflects it.

## Forbidden here
Beyond MANAGER.md 3.7:
- Any Astro scaffolding, page, workflow, `CNAME` or design work — that is task 009. This task
  creates a branch and a licence, nothing that task 009 would have to undo.
- Enabling GitHub Pages: it stays blocked until content exists (OPERATIONS.md), and enabling it
  against an empty site is how a half-served domain gets cached.
- Force-pushing anything, or any second commit on `main` outside a pull request.
