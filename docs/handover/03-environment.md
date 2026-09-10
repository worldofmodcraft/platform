# 03 — Environment and tooling hazards

Two columns of value here. **General** entries transfer to any project; **local** entries are this
machine's specifics, kept as worked examples of the general hazard.

---

## 1. Where the assistant runs (local)

WSL2 on Windows. The assistant runs in Linux; some targets build and run on Windows. The Windows
filesystem is reachable at `/mnt/c/...` (the Windows user here is `ludwi`, so
`/mnt/c/Users/ludwi/Desktop`). Copying a file there is how the assistant hands something to the human's
Windows tools.

**General:** when an assistant runs in one OS and the human works in another, **state the bridge
explicitly in the environment doc** — paths, how to invoke a process across the boundary, and which
steps need human hands. Otherwise each session rediscovers it, usually by getting it wrong.

## 2. Toolchain: assume nothing is installed (general, with local example)

**Local:** Python 3 **standard library only** — no test framework, no schema library, no imaging
library. Tests run with `python3 -m unittest discover`. Node is a userland install at a non-standard
path, on `PATH` via the shell profile but **absent in non-login shells**, so scripts use the absolute
path.

**General:**
- **Write down the actual toolchain**, including what is *not* available. An assistant will otherwise
  reach for the popular library and produce code nobody can run.
- **Any script that may run from cron, CI, or a non-login shell uses absolute paths.** "It works in my
  terminal" is a statement about that terminal's environment.

## 3. Git and the hosting platform

### Branch protection is the enforcement, not the intention (general)
**Local:** every repository requires a pull request, blocks force-push and deletion, and **includes
administrators**; required approvals are zero, so the assistant may merge its own PR under a written
authority rule. A direct push is refused outright.

The loop, every time:
```bash
git checkout -b <branch>
# ...edits...
git commit            # stage by path, never -A
git push -u origin <branch>
# open a PR, then merge it as a BARE command
```

**General:** "main is reachable only by reviewed merge" must be enforced by the platform, not by
discipline — an assistant that *can* push to main eventually will. And: **if protection ever genuinely
blocks legitimate work, lift it temporarily and loudly — never grant a quiet permanent exemption.**

### Two git footguns that cost real work (general)
- **Check the current branch before a commit chain.** `git rev-parse --abbrev-ref HEAD`. A chain here
  assumed it was on a branch, committed to main, and the following `reset --hard` discarded the work
  (recovered from the reflog).
- **Never `git add -A`.** Stage by path. Three over-staging incidents in one session; one earlier round
  pushed an out-of-scope file for real.
- **A local clone that is behind is a correctness problem, not untidiness** — agents read project rules
  out of that working tree. Verify against the remote (`git rev-parse origin/main` vs your HEAD) at
  session start. See `02-lessons.md` C5.

### Scope checks must be merge-base-relative (general)
A verification script that pins a baseline commit (`git diff --name-only <sha>..`) goes **permanently
red** once the branch merges and main moves. Use the merge base.

## 4. Permission layers: know which one refused you (general, important)

**Local:** two independent gates exist. Static **permission rules** in a settings file, and a dynamic
**classifier** that judges each command in context. They fail differently and they are fixed
differently:

- A **permission rule that does not match fails silently** — so rules are written in *both* accepted
  spellings.
- A **classifier refusal** is not fixed by widening a permission rule. It needs the classifier's own
  allow-list, or a differently shaped command.
- **Chaining trips the classifier when the bare command passes.** Observed repeatedly: `cmd-a ; cmd-b`
  refused, the identical `cmd-b` alone accepted immediately. **The fix is to stop chaining, not to widen
  a permission.**
- The classifier also guards **the settings file itself**, and that is correct: an assistant editing the
  file that governs what it may do is exactly what should require a human.
- **Footgun:** in the classifier's allow-list, omitting the literal `$defaults` entry **replaces** the
  built-in rules instead of adding to them — silently stripping every default guardrail while looking
  like a one-line addition.

**General:**
1. **Read the refusal text** and say which layer refused. "Blocked" is not a diagnosis.
2. **One narrowing retry is legitimate** (same intent, smaller blast radius, e.g. unchain a chain). A
   *second spelling of the same intent* is not — report instead. See `02-lessons.md` E4.
3. **Never route around a denial with a different tool** to accomplish the same effect, *especially* when
   the action would widen your own permissions. Hand it to the human with the exact change to make.
4. Settings usually load at session start, so **treat the first refusal-free run as the proof** a rule
   works — not the fact that you wrote it.

## 5. Credentials (general)

No agent — and not the orchestrator — reads, prints, copies or uses a token, secret or private key
unless a **spec-approved task states why it is needed** and the human has approved it in session. This
covers the obvious (`<tool> auth token`, `--show-token`) and the less obvious (reading the CLI's config
or credential files, switching authenticated accounts).

- **When a task needs to reproduce behaviour for a different identity, the brief names the permitted
  mechanism** — an unauthenticated request, a fixture, a recorded response — and forbids the rest. See
  `02-lessons.md` D1.
- **A re-attempt after a block is itself reportable**, even when the retry also fails.
- A secret **actually present in output** is a stop-everything event: halt, audit what landed (commits,
  files, pushes, logs), report. A blocked *attempt* is contained: stop that agent, audit, log, continue.
- Remember where agent output **goes**: a task log bound for a public repository is a publication
  channel, and the process requires agents to paste command output into it.

## 6. Metering and any "current state" file (general — one of the most valuable entries)

**Local:** usage figures are only trustworthy from the human running the usage command and pasting the
numbers. A local file that looked authoritative is written by *every* running session, so it
under-reports — and **in the unsafe direction**. Also: the usage command reports **three** windows
(short rolling, weekly all-models, weekly per-model); the binding one is **whichever is most
constrained**, and logging only one is how a session talks itself into continuing.

**General:**
- **A file written by many processes and read by one cannot be made reliable by reading it more
  carefully.** Fix the writer, or change the source.
- **A fresh timestamp is not freshness** if every writer refreshes it.
- **Resampling detects disagreement between writers, never one writer that is simply wrong.**
- Know **which direction** your metering errs. Ours erred low, and low lifts a halt.
- **An idle session cannot know its own quota.** Any figure that arrives only in a live data feed is
  *absent* after an idle period — so a session that has been asleep starts in UNKNOWN, and UNKNOWN must
  mean stop-and-ask, not assume-it's-fine. Build the "ask for the figure, log it as the day's opening
  checkpoint, then proceed" ritual explicitly; non-delegating work (reading, verifying, writing,
  merging) may fill the gap.

## 7. Agent isolation (general)

- **A scratch directory per agent, named in the brief.** Two agents that default to the same scratch
  path will clobber each other's clones mid-run. It happened.
- **Worktrees for file isolation; sequencing for resource isolation.** See `01-method.md` §6 — a test
  suite and a shared home directory are resources, and concurrent runs invalidate measurements.
- **Check the agent's tool allow-list against what the task requires.** Ours has a read-only reviewer
  role whose shell allow-list covers a few common test runners — and therefore **cannot run this
  project's own verification scripts**, which is precisely what a reviewer is required to re-run.
  Adversarial reviews go to a full-tool agent at the same tier or higher instead. *Role separation is
  satisfied by independence and capability, not by an agent's name.*
- **Never ask a peer session to perform something your own permissions refused.** That laundering defeats
  the human's decision.

## 8. Things only the human can do (general)

Keep an explicit, maintained list, and split it into **blocked** (cannot be done yet — do not ask) and
**pending** (they can do it any time). Conflating them wastes their attention, which is the scarcest
resource in the whole system. State each as a copy-pasteable command or a click-path, and **repeat the
exact command rather than referring to one earlier in the conversation** — assume nothing scrolled past
was read.

## 9. Edge behaviour is not settings behaviour (general, from a CDN/DNS example)

**Local:** a static-hosting settings change was not observable at the edge for up to ten minutes
(`cache-control: max-age=600`). Reading the API back confirmed the **setting**; it never confirmed the
**behaviour** — plain HTTP kept succeeding for about eight minutes after enforcement was enabled. Also:
a boolean sent as a string was rejected by the API, and setting a custom domain silently reverted the
HTTPS-enforcement flag because the existing certificate did not cover the new name.

**General:** **confirming a setting is not confirming a behaviour.** Poll the real endpoint before
reporting anything as done, and re-check flags after any change that could invalidate their
preconditions.
