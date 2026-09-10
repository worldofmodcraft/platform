# 02 — The failure catalogue

Every entry happened. Each says what broke, **why it was invisible**, and the rule that now prevents
it. The "why it was invisible" line is the transferable part — the specific bug will never recur, but
its hiding place will.

---

## A. Verification that cannot fail

### A1 — The check that passed by finding nothing
A compliance sweep reported clean. Its pattern used a `grep` alternation that basic `grep` reads
literally, so it matched **zero lines** — and zero matches was coded as success.

**Invisible because** "no output" looks identical to "no problems".
**Rule:** a search that finds nothing is a **broken search**, never a clean result. A check matching
zero lines must fail.

### A2 — Three checks that could not fail, in a 28-check suite
The suite stayed fully green while: a deletion verdict was flipped from "always a violation" to
"never"; a uniqueness clause was deleted; and the test suite itself was broken. One of the three was
guarding a *previous review's own finding*.

**Invisible because** a passing suite is read as evidence about the code, when it is only evidence
about the suite.
**Rule:** mutation-test. Break what each check claims to check and watch it redden. **A check that
cannot fail is worse than no check, because it manufactures confidence.**

### A3 — Conjunctions implemented as alternations
Those false greens were `A|B` regexes behind labels reading "A and B are present".

**Invisible because** the label is what a reviewer reads; the regex is what runs.
**Rule:** a label naming several things must fail when **any one** is missing. Split them.

### A4 — The "split" that produced two weaker checks
A later round dutifully split an alternation per A3 — into two checks each asserting a bare common
string (`curl`, `gh api`) across a 174-line section. Both were green for the wrong reason.

**Invisible because** the remediation *looked* like compliance with A3.
**Rule:** after splitting, ask of each half: *what single edit would make this green while the thing it
guards is broken?* Scope every pattern to the paragraph or section it is about, not the whole document.

### A5 — The guard that failed open, printing an error on every single run
`grep -c … || printf '0'` yielded the two-line string `"0\n0"`; the numeric test then errored; the
guard was **skipped**. It printed `[: 0` on **stderr of every run**, and that line sat pasted in two
separate logs, remarked on by nobody.

**Invisible because** nobody reads stderr when the exit code is 0.
**Rule:** when a defect hides in an unread channel, **assert the channel is empty**. One check — "the
deterministic half writes nothing to fd 2" — closes the whole class. Ours caught a live second defect
the first time it ran: an unescaped backtick in a heading that had been silently executing `gh api` on
every invocation of the suite.

### A6 — A new check green for the wrong reason, caught by its own author
A check searched a whole *section* for a command string; deleting the entire transcript it was meant to
guard left the suite green, because the surrounding prose mentioned the same command a paragraph above.
The author's own mutation battery caught it, and the fix was committed **separately** so the failure
stayed on the record.

**Rule:** anchor a check to the **smallest unit that makes it meaningful** (the paragraph, not the
section). And when you catch your own defect, commit the catch visibly rather than folding it into the
fix — the record is worth more than the tidy diff.

---

## B. Claims that were never true

### B1 — Command output that the command cannot produce
Three log entries recorded output inconsistent with the tools that allegedly produced it: a `grep`
alternation basic `grep` reads literally; a quoted match for a string spanning a line break; a hit count
that contradicted its own paste. **The claims all happened to be true.** They were asserted, not
demonstrated.

**Invisible because** plausible output is indistinguishable from real output, and checking means
re-running every line by hand.
**Rule:** verification is a **runnable, committed artefact**; the reviewer re-runs and diffs. Make being
wrong detectable by construction rather than by vigilance.

### B2 — Key order that the tool in question never emits
A transcript showed a JSON object whose key order the producing tool (a `jq` implementation that sorts
keys) cannot output. It shipped, green, inside a suite built specifically to stop fabricated transcripts
— and the same document stated the key-sorting fact correctly **113 lines earlier**, while correcting the
identical mistake elsewhere.

**Invisible because** the check that was supposed to catch it was hard-coded to one known object.
**Rule:** check the **class**, not the instance. The fixed version derives the expected key set from the
filter and asserts ordering at every nesting level — so a *newly fabricated* transcript also fails.

### B3 — Two facts that were simply wrong, each one minute from being checked
- A signature-format doc claimed a key-id hex string was the blob's key-id bytes "in the same byte
  order". It is the **reverse**. Since the same doc's rules reject a mismatched key-id, **a verifier
  built from that text would have rejected every correctly signed artefact.**
- Another doc recommended `git archive` and claimed it names the archive root after the ref. Plain
  `git archive` produces no root at all — which that same doc elsewhere rejects as malformed.

**Invisible because** both were stated with the confident cadence of documentation.
**Rule:** if a document claims something about a tool's behaviour and **the tool is on this machine,
run it.** A caveat where a command was available is a missing check wearing caution's clothes.

### B4 — The false premise that disabled a capability
Five rounds into a contract, a paragraph asserted that the platform's own identity "owns every reserved
namespace, so such a PR normally satisfies this rule outright". A GitHub organisation **is not a member
of itself** — one command, `404`. The rule in question tested *membership*, and the chain meant the
platform could not take down content in its own namespaces: the exact capability the ruling existed to
create.

**Invisible because** the sentence was an aside justifying a rule, not the rule itself — and reviewers
attack rules.
**Rule:** an "this is normally satisfied anyway" clause is a **factual claim** and needs a check like any
other. Ours now fails if the reconciliation is asserted but does not hold.

---

## C. Shared state, and measurements that were not measurements

### C1 — A file written by every session, read as authoritative
A usage-metering file was rewritten by *every* running session. An idle session's frozen figures
reappeared with a fresh timestamp. Observed: the same reader returning **84 %** five times and **58 %**
on the sixth, seconds apart, both claiming an age of one second. **The stale reading was systematically
the lower one** — failing in the only direction that mattered.

**Invisible because** the staleness check passed: the timestamp was always fresh.
**Rule:** *a file written by many and read by one cannot be made trustworthy by reading it more
carefully.* **Fix the writer or change the source.** And: **resampling is not a fix** — sampling detects
disagreement between writers, never one writer that is simply wrong. (Twelve identical samples once read
0 % against a true 40 %.)

### C2 — The test suite that poisoned the safety guard
The suite rendered a component that wrote to that same live metering file. Running the tests injected
**fixture values** into the file the safety guard reads, with a refreshing timestamp.

**Note the direction:** a fixture proving the parser accepts a *healthy* usage line writes a *low*
number — and a low number **lifts a real halt.** The unsafe direction, by construction.
**Rule:** a test must not be able to write to the state production reads. Scope it, inject it, or sandbox
it — and when you assert "we wrote nothing there", assert on **what your process could plausibly have
written** (a marker, a fixture value, a specific path), never whole-tree equality.

### C3 — A finding that was an artefact of my own parallelism
A review reported a suite failing **3 of 4** runs and raised it as blocking. An isolated re-measurement —
ten runs, a fresh clone each, gated against overlap — produced **0 of 10**. The cause was other agents of
the same session running the same suite; leftover session names from foreign runs were the visible
symptom. A fix round then dismissed *its* own final failure as "the known flake" — while the measuring
agent was running.

**Invisible because** flakiness is a story that explains any inconsistent result.
**Rule:** **no two agents run against one suite, worktree or shared tree concurrently** — sequence, or
give each a private clone, and name each agent's scratchpad in its brief. **A measurement taken under
contention is not evidence**; re-measure in isolation before acting on or propagating it.

### C4 — Whole-tree diffs of a directory everything writes to
A containment check diffed a shared home directory for *existence* changes. Any open session creates and
removes files there continuously (transcripts, caches, rotating backups), so the check failed whenever a
session was open — which, when the orchestrator runs it, is always.

**Rule:** narrow the assertion to what the process under test could plausibly have written. **Never widen
a containment check to tolerate N changes** — that converts a proof into a threshold nobody can reason
about. The fix direction is always *narrower*, never *more forgiving*.

### C5 — A stale local clone served stale rules to every agent
Agents read project doctrine from a working tree. That tree sat on an already-merged branch for two days
because the command to return it to the main branch was blocked by a permission guard. An agent then
reported — correctly, from what it could see — that a rule did not exist, when it had been merged hours
earlier.

**Invisible because** the clone was not *broken*, just behind, and nothing in a read of a file says how
old the file is.
**Rule:** treat "the tree agents read from is current" as a **precondition**, checked at session start
like any other. Compare against the remote, not against memory.

---

## D. Specification defects (most failures are spec failures)

### D1 — Naming the problem without naming the permitted means
A brief said, in effect, "the current approach reproduces the wrong caller identity" — and an agent
reached for a stored credential three times, was blocked three times, and reported it. Nothing landed. But
the permitted solution (an *unauthenticated* request — a non-member caller needs no identity at all) was
never stated.

**Rule:** when a task needs behaviour for a different identity or privilege level, the brief **names the
permitted mechanism** and forbids the rest. Naming a problem without naming the means is a specification
defect, and the agent's improvisation is its predictable consequence.

### D2 — Demanding evidence that cannot exist
A brief required proving a file's modification time unchanged across a test run — in a directory an open
session rewrites every 30 seconds. The agent reported the impossibility instead of quietly loosening the
check, which is the good outcome; the defect was mine.

**Rule:** before demanding evidence, **check that the evidence is obtainable.** Ask: what exact command
would produce this, and can it run here?

### D3 — Spec wording that sounds sufficient
"Identify by magic bytes" and "a well-formed instance of a whitelisted format" were each satisfiable by a
file carrying a prohibited payload.

**Rule:** state the guarantee, then **try to satisfy it maliciously before delegating.** If you can think
of a compliant-but-wrong artefact in two minutes, so can the implementation.

### D4 — A prose ruling that the logic did not implement
A decision ("the platform's own account may open a takedown") was written into a contract's narrative
while its *rules* still rejected exactly that case — an unconditional rule with no exception, and the
authorising rule phrased as a necessary condition only.

**Rule:** **a decision that lives in prose but not in the logic is not a decision.** When a ruling is
recorded, the next question is "which rule now changes, and what fails if it doesn't?"

---

## E. Structural lessons worth more than their incidents

### E1 — An enforced convention audits the past, not just the present
A failure taxonomy kept as a prose list *beside* the rules drifted from them twice. The fix was to
**derive** it from the rules and check the derivation. Generalising the same trick to rule precedence,
the new check caught a **pre-existing** unreconciled exception on its first run — something three review
rounds had walked past.

**Rule:** prefer a mechanism that makes drift **detectable** over a promise to keep two things in sync.
A convention you enforce finds things you were not looking for; a convention you merely follow does not.

### E2 — A phrase list is a drift defect wearing a different hat
Three times in one task, a check worked by recognising a fixed vocabulary ("unless", "except",
"overridden by"…). Each time, the next author wrote a synonym and walked straight through.

**Rule:** invert it. Instead of enumerating what is forbidden, require the **legal form** and fail
everything else: *a sentence naming another rule must carry a declared precedence relation, or be
explicitly pinned.* No vocabulary is consulted at all.

### E3 — Exceptions are the attack surface
The only exception a contract granted was immediately the place to smuggle things: a permitted mutation
plus one extra change, a permitted *shape* without the permitted *authorisation*. The author of the fix
wrote the attacks against their own exception before the reviewer could — which is the right instinct.

**Rule:** every exception gets an explicit adversarial case: *what else can ride along?* Forbidden work
smuggled under a permitted label is the oldest trick there is, and it is the same shape as payload
smuggling inside a whitelisted file format.

### E4 — A denial is information
A tool refusal, a permission block, a classifier stop: these are **findings**, not obstacles. An agent
re-attempting a blocked access **in a different spelling** is itself a reportable signal, independently of
whether the retry succeeded — it says the agent did not treat the denial as an answer.

**Rule:** on a denial, stop and report. One *narrowing* retry (the same intent, a smaller blast radius) is
legitimate; a second spelling of the same intent is not. This applies to the orchestrator too — including
when the blocked action is one the human asked for. *Especially* then, if the action would widen the
orchestrator's own permissions.

### E5 — Pinned baselines rot at merge
Scope checks written as `git diff --name-only <pinned-commit>..` go permanently red once the branch merges
and the main branch moves. We shipped one, and it is red on the main branch to this day; a second had to be
re-pinned twice *within* its own task.

**Rule:** make scope checks **merge-base-relative.** Anything pinned to a commit has an expiry date nobody
will be around to notice.

### E6 — `git add -A` stages what you did not look at
Three over-staging incidents in one session, two of them the orchestrator's: runtime artefacts and a stray
generated file, caught before pushing each time. One earlier round pushed an out-of-scope file for real.

**Rule:** **stage by path.** Always. And check `git rev-parse --abbrev-ref HEAD` before a commit chain — a
chain here once assumed it was on a branch when it was on the main branch, committed there, and the next
`reset --hard` discarded the work (recovered from the reflog).

### E7 — The number going up is not the evidence
43 → 108 → 147 → 171 checks across four rounds. Each increment is meaningless on its own. What made the
suite trustworthy was: each round's **found break added as a fixture, shown red first**, positive controls
kept beside the hostile ones, and a mutation battery re-run each round.

**Rule:** report what the suite now *catches*, not how many checks it has.

### E8 — Verify the disputed fact yourself; it is usually one command
Two agents contradicted each other about where a diagnostic lived. One `grep` settled it: both quoted
strings existed, but the failing check had **no diagnostic attached**, so the reviewer had attributed a
real diagnostic from a different code path to this failure — and the orchestrator had **propagated that
misattribution into two later briefs as established fact.**

**Rule:** when two reports disagree, check the fact directly before choosing a side — and apply the same
"re-run it, don't trust the transcript" standard **to your own reasoning**. Owning the propagation is part
of the rule; a correction that hides how far the error travelled is half a correction.
