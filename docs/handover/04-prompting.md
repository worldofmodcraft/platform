# 04 — Writing a task brief for an agent

A brief is a specification, not a request. Most agent failures are brief failures, which is why
escalation improves the spec *before* it reaches for a stronger model.

---

## The skeleton

1. **Role and boundary.** Which worktree/branch, at which commit. What must not be touched. The
   scratch directory, named explicitly.
2. **Why this task exists**, in two or three sentences — including what previously went wrong. An agent
   that knows the stakes calibrates its own care; one that doesn't treats every line as equally
   important.
3. **What to read first**, in order, with paths. Point at the **source of the rules**, never at your
   own paraphrase of them (see "Anti-pattern 6").
4. **The work**, item by item, each with *why* as well as *what*.
5. **How it must be demonstrated.** The verification rules, explicitly, including the order of
   operations: fixture first, shown red, then the fix, then green.
6. **Scope boundaries.** What is out of scope, and what to do on hitting one (stop and report — never
   "use judgement").
7. **Bookkeeping.** Where the log goes, what it must contain, how to book questions rather than
   interrupt.
8. **The exit condition.** At ~60 % context: finish the sub-step, write the log so another agent can
   resume from it alone, end the run.
9. **What to report back:** a per-item verdict, the evidence, and anything unverified.

## Phrases worth reusing verbatim

- *"Assume there is something. If you conclude otherwise, state what you did that would have caught a
  defect had one existed."*
- *"A fixture that would have passed against the broken code proves nothing — put the defect back and
  watch it redden before believing it guards anything."*
- *"A search that finds nothing is a broken search, never a clean result."*
- *"Re-run every command whose output the log quotes, and diff. A quoted result you did not reproduce is
  not evidence."*
- *"If a document claims something about a tool's behaviour and the tool is on this machine, run it."*
- *"A denial is a stop signal, not a retry prompt. Record it and stop."*
- *"Mark the basis of the rule, never soften the rule: 'this is required; this is why we believe it; that
  belief is untested here.'"*
- *"Stage by path. Never `git add -A`."*
- *"Finder is never fixer: if you find a defect, report it; do not fix it."*

## Anti-patterns, each one paid for

**1. Naming the problem without naming the permitted means.**
"The current approach reproduces the wrong caller identity" → an agent reached for a stored credential
three times. The permitted answer (an *unauthenticated* request) was never stated. **If a task touches
identity, privilege, or anything guarded, enumerate the permitted mechanisms and forbid the rest.**

**2. Demanding evidence that cannot exist.**
A brief required proving a file's mtime unchanged across a run, in a directory rewritten every 30
seconds. **Before demanding evidence, name the command that would produce it and check it can run.**

**3. Leaving "use your judgement" in a boundary.**
Scope boundaries are binary: in, or stop and report. An agent asked to judge will judge, reasonably, and
produce something outside the task.

**4. Asking for a goal without the demonstration.**
"Make the check robust" produces a check that looks robust. "Break what this check guards and show it
red, then restore byte-identically" produces a check that is.

**5. Letting a count stand in for evidence.**
"Get the suite green" invites a bigger green number. Ask instead for *what the suite now catches*, with
the breaking case as a committed fixture.

**6. Paraphrasing the rules into the brief instead of pointing at them.**
For a while, a rule that had not yet merged was hand-copied into every brief. That is precisely the
failure mode the rule existed to prevent — doctrine living where someone retyped it. It also bloated
every dispatch and, we think, eventually tripped a safety classifier on the pasted credential
vocabulary. **Merge the rule, then point at it.** If you must inline something because it is not yet
available, say so and say why.

**7. Two agents, one resource.**
Dispatching parallel agents that touch the same suite, worktree, or shared tree. Sequence them, or give
each a private clone — and say so in the brief.

**8. A brief with no stated exit condition.**
Without the 60 %-context rule the agent runs until it degrades, then hands over by summary — losing
exactly the operational detail that matters.

## Reviewing what comes back

Do not accept a report at face value, and do not dismiss one either.

- **Check the cheap decisive facts yourself.** Usually one `grep`. When two agents disagree, this settles
  it in seconds — and it has caught a reviewer misattributing real evidence to the wrong failure, a claim
  that had already been propagated into two later briefs before anyone checked.
- **Verify scope mechanically:** `git show --stat <commit>` against the task's declared file list. It
  catches over-staging immediately.
- **Re-run the verification artefact**, or have the reviewer do it and diff. Treat a large operation as
  something to budget for, not something to skip.
- **Read the "could not verify" section first.** It is the most honest part of any report, and an empty
  one on a hard task is itself a finding.
- **A report that volunteers its own mistake is a better report, not a worse one.** One round here
  flagged that a brief's own premise was wrong; another committed its self-caught defect separately so the
  failure stayed on the record. Reward that explicitly — the alternative is agents that smooth.
