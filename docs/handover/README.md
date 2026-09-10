# How we develop with AI — a handover

Four files. Written to be handed to an AI assistant (ChatGPT, Codex, Claude, anything) together with
its human operator, so both can work this way on **any** software project. Nothing here needs this
repository's history.

| File | What it is | Read it when |
|---|---|---|
| `00-start-here.md` | What the rulebook is, which layer binds you, and which of the ~120 decision records actually transfer to another project. Written for an assistant being handed the whole thing. | Before anything else, if you were handed the full `decisions/` and `doctrine/` trees. |
| `01-method.md` | The process: roles, the spec gate, how work is verified, how reviews run, how context and budget are managed. | First. It is the whole system. |
| `02-lessons.md` | The failure catalogue. Every entry happened; each says what broke, why it was invisible, and the rule that now prevents it. | Second, and again whenever something "passes" and you feel relief. |
| `03-environment.md` | Concrete tooling hazards: shell, git, GitHub, permissions, usage metering, agent isolation. Separates machine-specific from general. | When setting up, and when something behaves oddly. |
| `04-prompting.md` | How to write a task brief for an agent, with the anti-patterns that cost us rounds. | Before delegating anything. |

## The one-paragraph version

An AI assistant is fast, confident, and *systematically* over-trusting of its own output. Speed is
not the bottleneck; **false confidence** is. So the process is built so that being wrong is
*detectable by construction rather than by vigilance*: every piece of work has a written spec before
it starts, every claim about a command's behaviour ships the runnable command, every check must be
proven able to fail, the person who finds a bug is never the one who fixes it, and the author of work
is never its reviewer. None of this is about distrusting the model in particular — a human team that
asserted results instead of demonstrating them would need the same guardrails. It is about removing
the places where a plausible-looking lie can survive.

## The honest cost

This is not cheap. On this project, a single ~1000-line contract document took **five fix rounds and
five independent adversarial reviews**, and every review found real blocking defects — including
three rounds where the *fix round itself* introduced new defects in the rules it had just written.
Each review cost roughly 200k tokens.

Read that two ways, both true:

- **The process works.** The fifth review caught a false factual claim that would have shipped a
  contract making a legally-mandated capability silently impossible. No amount of care by the author
  would have caught it; re-running one command did.
- **The process is expensive, and the document was probably too ambitious for one task.** Five rounds
  is also a signal that the work was mis-scoped — which the method says to treat as information, not
  as something to push through quietly.

Calibrate accordingly. Use the full ceremony where being wrong is expensive or hard to reverse
(security boundaries, contracts other code is built against, anything public, anything that deletes
data). Use less where a mistake is cheap and obvious. **The dial is "how reversible is this", not
"how big is this".**

## If you read nothing else

1. **A search that finds nothing is a broken search, not a clean result.**
2. **A check that cannot fail is worse than no check** — it manufactures confidence. Break the thing
   it guards and watch it go red, or you do not have a check.
3. **Never state what a command outputs. Run it, and paste what it actually printed.**
4. **State lives on disk; context is cache.** Hand over by file, never by summary from a tired
   context window.
5. **A denial is information, not an obstacle.** If a tool, permission, or guard blocks you, report
   it. Re-attempting in a different spelling is itself the finding.
