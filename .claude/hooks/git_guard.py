"""PreToolUse guard for the Bash tool (task 049; contract and known gaps: docs/tools/git-guard.md).

Reads the hook JSON on stdin.  Exit 0 allows the call; exit 2 blocks it (stderr is shown to the agent).  The
wrapper git-guard.sh maps every other status to 2.  Python 3 standard library only.
Rules: force-push, reset-hard, rm-rf, commit-on-main (everyone); branch-D and vault (agents only).
The command is parsed quote-aware (scan() + shlex), never matched with a regex over the raw string.
A "# CHECK:name" comment marks a line that docs/tasks/049-fixtures/mutate.py breaks on purpose (MANAGER.md 2c).
"""
import json
import os
import re
import shlex
import subprocess
import sys
import time

MAX_DEPTH = 8
PLACEHOLDER = "__SUBST__"
QUOTES = "'\""  # CHECK:quote-sep
SEPS = ";|&"  # CHECK:semi
ASSIGN_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
HEREDOC_RE = re.compile(r"<<(-?)[ \t]*(?:'([^']*)'|\"([^\"]*)\"|\\?([A-Za-z_0-9.\-]+))")
KEYWORDS = (
    "{",  # CHECK:brace
    "}", "!", "if", "then", "else", "elif", "do", "while", "until", "fi", "done",
)
WRAPPERS = {  # wrapper -> options that take a separate argument
    "command": (),  # CHECK:w-command
    "sudo": ("-u", "-g", "-h", "-p", "-C", "-r", "-t", "-U", "-T"),  # CHECK:w-sudo
    "nohup": (),  # CHECK:w-nohup
    "time": (),  # CHECK:w-time
    "exec": ("-a",),  # CHECK:w-exec
    "nice": ("-n",),  # CHECK:w-nice
}
XARGS_OPTARGS = ("-I", "-n", "-P", "-L", "-d", "-E", "-s", "-a", "-J")
SHELLS = ("bash", "sh", "zsh", "dash", "ksh")
LITERALS = ("$WOM_VAULT", "${WOM_VAULT}")  # CHECK:vault-literal
HINT = ("Sanctioned alternatives: rm -r DIR (no force flag), rm -f FILE, git worktree remove, a mktemp -d directory removed "
        "with rm -r; Ludwig can run any blocked command in his own terminal. See docs/tools/git-guard.md.")


class GuardError(Exception):
    """The command cannot be parsed or judged; the hook fails closed (exit 2)."""


def fold(s):
    return s.casefold()  # CHECK:casefold


def base(word):
    return word.rsplit("/", 1)[-1]  # CHECK:pathprefix


# ----------------------------------------------------------------------------------------------- scanning
def match_paren(text, k):
    """Index of the ')' matching the '(' at text[k]; quotes and backslashes are honoured."""
    depth, i, n = 0, k, len(text)
    while i < n:
        c = text[i]
        if c == "\\":
            i += 2
            continue
        if c == "'":
            j = text.find("'", i + 1)
            if j < 0:
                raise GuardError("unterminated single quote inside $( )")
            i = j + 1
            continue
        if c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            i = j + 1
            continue
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise GuardError("unbalanced parenthesis")


def match_backtick(text, k):
    i, n = k, len(text)
    while i < n:
        if text[i] == "\\":
            i += 2
            continue
        if text[i] == "`":
            return i
        i += 1
    raise GuardError("unterminated backtick")


def skip_heredocs(text, i, pending):
    """Skip the bodies of the pending heredocs starting at text[i]; return the index after the last terminator."""
    n = len(text)
    for delim, strip_tabs in pending:
        while i < n:
            end = text.find("\n", i)
            line = text[i:end if end >= 0 else n]
            i = end + 1 if end >= 0 else n
            if (line.lstrip("\t") if strip_tabs else line).rstrip("\r") == delim:
                break
    return i


def scan(text, depth):
    """Split a command string into simple-command strings.  Separators, keywords and '#' inside quotes, heredoc bodies
    and comments are text.  $( ), backticks and double-quoted substitutions are scanned recursively; each is replaced by
    a placeholder in the outer command."""
    if depth > MAX_DEPTH:
        raise GuardError("command nesting is deeper than %d" % MAX_DEPTH)
    segs, cur, pending = [], [], []
    i, n = 0, len(text)

    def flush():
        s = "".join(cur).strip()
        del cur[:]
        if s:
            segs.append(s)

    while i < n:
        c = text[i]
        if c == "\\":
            if text[i + 1:i + 2] == "\n":
                i += 2
                continue
            cur.append(text[i:i + 2])
            i += 2
            continue
        if c in QUOTES:
            if c == "'":
                j = text.find("'", i + 1)
                if j < 0:
                    raise GuardError("unterminated single quote")
                cur.append(text[i:j + 1])
                i = j + 1
                continue
            buf, j = ['"'], i + 1
            while True:
                if j >= n:
                    raise GuardError("unterminated double quote")
                d = text[j]
                if d == "\\":
                    buf.append(text[j:j + 2])
                    j += 2
                elif d == '"':
                    buf.append('"')
                    j += 1
                    break
                elif d == "$" and text[j + 1:j + 2] == "(":
                    end = match_paren(text, j + 1)
                    segs.extend(scan(text[j + 2:end], depth + 1))
                    buf.append(PLACEHOLDER)
                    j = end + 1
                elif d == "`":
                    end = match_backtick(text, j + 1)
                    segs.extend(scan(text[j + 1:end], depth + 1))
                    buf.append(PLACEHOLDER)
                    j = end + 1
                else:
                    buf.append(d)
                    j += 1
            cur.append("".join(buf))
            i = j
            continue
        if c == "#" and (i == 0 or text[i - 1] in " \t\n;&|()"):  # CHECK:comment
            j = text.find("\n", i)
            i = j if j >= 0 else n
            continue
        if c == "$" and text.startswith("$(", i):
            end = match_paren(text, i + 1)
            segs.extend(scan(text[i + 2:end], depth + 1))  # CHECK:subst
            cur.append(PLACEHOLDER)
            i = end + 1
            continue
        if c == "`":
            end = match_backtick(text, i + 1)
            segs.extend(scan(text[i + 1:end], depth + 1))  # CHECK:backtick
            cur.append(PLACEHOLDER)
            i = end + 1
            continue
        if c == "<" and text.startswith("<<", i) and not text.startswith("<<<", i):
            m = HEREDOC_RE.match(text, i)
            if m:
                pending.append((m.group(2) or m.group(3) or m.group(4), m.group(1) == "-"))
                cur.append(m.group(0))
                i = m.end()
                continue
        if c == "\n":
            flush()  # CHECK:newline
            i += 1
            if pending:  # CHECK:heredoc
                i = skip_heredocs(text, i, pending)
                pending = []
            continue
        if c in "()":
            flush()  # CHECK:subshell
            i += 1
            continue
        if c in SEPS:
            if c == "&" and (text[i - 1:i] in ("<", ">") or text[i + 1:i + 2] == ">"):
                cur.append(c)  # a redirection such as 2>&1 or &>, not a separator
            else:
                flush()
            i += 1
            continue
        cur.append(c)
        i += 1
    flush()
    return segs


# ----------------------------------------------------------------------------------------------- judging
class State:
    def __init__(self, cwd, agent):
        self.cwd = cwd
        self.agent = agent
        self.aliases = {}
        self.events = []  # (rule, decision) notes, written to the log

    def note(self, rule, decision):
        self.events.append((rule, decision))


def violation(rule, why):
    return rule, "%s. %s" % (why, HINT)


def lopt(arg, names):
    """True when arg is a long option that is an unambiguous-prefix spelling of one of names (git and GNU rm accept
    abbreviations)."""
    if not arg.startswith("--") or len(arg) < 3:
        return False
    name = arg[2:].split("=", 1)[0]
    return any(n.startswith(name) for n in names)  # CHECK:abbrev


def skip_opts(words, optargs):
    i = 0
    while i < len(words):
        t = words[i]
        if t == "--":
            i += 1
            break
        if t in optargs:
            i += 2
        elif t.startswith("-") and len(t) > 1:
            i += 1
        else:
            break
    return words[i:]


def skip_env(words):
    i = 0
    while i < len(words):
        t = words[i]
        if t in ("-u", "-C", "-S", "--unset", "--chdir"):
            i += 2
        elif t.startswith("-") or ASSIGN_RE.match(t):
            i += 1
        else:
            break
    return words[i:]


def strip_wrappers(words):
    while words:
        w = words[0]
        if w in KEYWORDS:
            words = words[1:]
            continue
        if ASSIGN_RE.match(w):  # CHECK:bare
            words = words[1:]
            continue
        name = base(w)
        if name == "env":  # CHECK:w-env
            words = skip_env(words[1:])
            continue
        if name == "timeout":  # CHECK:w-timeout
            words = skip_opts(words[1:], ("-s", "-k", "--signal", "--kill-after"))[1:]
            continue
        if name == "xargs":  # CHECK:w-xargs
            words = skip_opts(words[1:], XARGS_OPTARGS)
            continue
        if name in WRAPPERS:
            words = skip_opts(words[1:], WRAPPERS[name])
            continue
        return words
    return words


def run_text(text, st, depth):
    """Judge every simple command in text; return the first violation or None."""
    for seg in scan(text, depth):
        try:
            words = shlex.split(seg)  # CHECK:shlex
        except ValueError as exc:
            raise GuardError("cannot tokenise '%s': %s" % (seg[:80], exc))
        v = judge(words, st, depth)
        if v:
            return v
    return None


def judge(words, st, depth):
    if depth > MAX_DEPTH:
        raise GuardError("command nesting is deeper than %d" % MAX_DEPTH)
    words = strip_wrappers(words)
    if not words:
        return None
    prog, args = base(words[0]), words[1:]  # CHECK:scan-args-other
    if prog == "cd":
        targets = [a for a in args if not a.startswith("-")]
        if targets:
            st.cwd = os.path.normpath(os.path.join(st.cwd, os.path.expanduser(targets[0])))  # CHECK:cd
        return None
    if prog in SHELLS:
        for k, a in enumerate(args):
            if a.startswith("-") and not a.startswith("--") and "c" in a[1:] and k + 1 < len(args):
                return run_text(args[k + 1], st, depth + 1)  # CHECK:bash-c
        return None
    if prog == "eval":
        return run_text(" ".join(args), st, depth + 1)  # CHECK:eval
    if prog == "git":
        return judge_git(args, st, depth)
    if prog == "rm":
        return judge_rm(args)
    return None


def judge_rm(args):
    rec = force = False
    for a in args:  # CHECK:rm-onetoken
        if a == "--":
            break
        if a.startswith("--"):  # CHECK:rm-long
            rec = rec or lopt(a, ("recursive",))
            force = force or lopt(a, ("force",))
        elif a.startswith("-") and not a.startswith("--") and len(a) > 1:
            letters = a[1:]  # CHECK:rm-cluster
            rec = rec or "r" in letters or "R" in letters
            force = force or "f" in letters
        if rec and force:
            return violation("rm-rf", "rm with both a recursive and a force flag is refused")
    return None


def branch_of(directory, gitdir):
    """('branch', name) | ('detached', '') | ('no-repo', reason).  Reads HEAD directly; git runs with no user or system
    config so no alias, hook or config can change the answer."""
    if not os.path.isdir(directory):
        return "no-repo", "no such directory"
    if gitdir:
        gd = os.path.join(directory, gitdir)
    else:
        env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": os.environ.get("HOME", "/"),
               "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null", "LC_ALL": "C"}
        p = subprocess.run(["git", "rev-parse", "--git-dir"], cwd=directory, env=env, capture_output=True, timeout=15)
        if p.returncode != 0:
            return "no-repo", "not a git repository"
        gd = os.path.join(directory, p.stdout.decode("utf-8", "replace").strip())
    try:
        with open(os.path.join(gd, "HEAD"), encoding="utf-8") as fh:
            head = fh.read().strip()
    except OSError:
        return "no-repo", "HEAD unreadable"
    if head.startswith("ref: refs/heads/"):
        return "branch", head[len("ref: refs/heads/"):]  # CHECK:branch
    return "detached", ""


def judge_git(args, st, depth):
    cur, gitdir, i = st.cwd, None, 0
    while i < len(args):
        a = args[i]
        if a == "-C" and i + 1 < len(args):
            cur = os.path.normpath(os.path.join(cur, args[i + 1]))  # CHECK:dash-C
            i += 2
        elif a == "-c" and i + 1 < len(args):
            kv = args[i + 1]
            if kv.startswith("alias."):
                name, _, body = kv[len("alias."):].partition("=")
                st.aliases[name] = body  # CHECK:alias-c
            i += 2  # CHECK:git-c
        elif a.startswith("--git-dir="):  # CHECK:git-dir
            gitdir = a.split("=", 1)[1]
            i += 1
        elif a == "--git-dir" and i + 1 < len(args):  # CHECK:git-dir-sp
            gitdir = args[i + 1]
            i += 2
        elif a in ("--work-tree", "--namespace", "--super-prefix", "--config-env") and i + 1 < len(args):
            i += 2
        elif a.startswith("-"):
            i += 1
        else:
            break
    if i >= len(args):
        return None
    sub, rest = args[i], args[i + 1:]  # CHECK:scan-args-commit
    hops = 0
    while sub in st.aliases and hops < 5:
        body = st.aliases[sub]
        hops += 1
        if body.startswith("!"):
            return run_text(body[1:] + " " + " ".join(shlex.quote(r) for r in rest), st, depth + 1)
        ws = shlex.split(body)
        if not ws:
            return None
        sub, rest = ws[0], ws[1:] + rest
    if sub == "config":
        for k, w in enumerate(rest):
            if w.startswith("alias.") and k + 1 < len(rest):
                st.aliases[w[len("alias."):]] = rest[k + 1]  # CHECK:alias-config
        return None
    if sub == "push":
        for a in rest:
            if lopt(a, ("force", "force-with-lease", "force-if-includes")):  # CHECK:force-long
                return violation("force-push", "git push with a force option (%s) is refused" % a)
            if a.startswith("-") and not a.startswith("--") and "f" in a[1:]:  # CHECK:force-short
                return violation("force-push", "git push with a force flag (%s) is refused" % a)
            if a.startswith("+"):  # CHECK:force-plus
                return violation("force-push", "git push of a +refspec (%s), which forces, is refused" % a)
        return None
    if sub == "reset":
        for a in rest:
            if lopt(a, ("hard",)):  # CHECK:reset
                return violation("reset-hard", "git reset --hard is refused")
        return None
    if sub == "commit":
        status, info = branch_of(cur, gitdir)
        if status == "branch" and info in ("main", "master"):
            return violation("commit-on-main", "git commit on branch '%s' is refused; commit on a task branch" % info)
        st.note({"branch": "commit-on-task-branch", "detached": "commit-detached-head", "no-repo": "commit-no-repo"}[status], "allow")
        return None
    if sub == "branch" and st.agent:  # CHECK:agent-invert
        letters, longs = set(), []
        for a in rest:
            if a == "--":
                break
            if a.startswith("--"):
                longs.append(a)
            elif a.startswith("-"):
                letters.update(a[1:])
        force = "f" in letters or any(lopt(a, ("force",)) for a in longs)
        deleting = "d" in letters or any(lopt(a, ("delete",)) for a in longs)
        hit = "D" in letters or (deleting and force)  # CHECK:branch-d
        if hit:
            return violation("branch-D", "git branch -D (forced delete) is refused for subagents; the manager deletes branches")
    return None


# ----------------------------------------------------------------------------------------------- vault (rule 6)
def vault_sources():
    """(paths, broken): the configured vault paths and any config source that exists but cannot be read."""
    paths, broken = [], []
    env = os.environ.get("WOM_VAULT")  # CHECK:vault-env
    if env and env.strip():
        paths.append(env.strip())
    cfg = os.path.join(os.path.expanduser("~"), ".config", "wom", "vault-path")
    try:
        with open(cfg, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
        if len(lines) == 1 and lines[0].strip():
            paths.append(lines[0].strip())
        else:
            broken.append("%s must hold exactly one non-empty line" % cfg)
    except (FileNotFoundError, NotADirectoryError):
        pass
    except (OSError, UnicodeDecodeError) as exc:
        broken.append("%s: %s" % (cfg, exc.__class__.__name__))
    return paths, broken


def renderings(path):
    """The spellings of one vault path an agent might type.  A drive path (D:\\x, D:/x, /mnt/d/x) yields all three."""
    m = re.match(r"^([A-Za-z]):(?:[\\/](.*))?$", path) or re.match(r"^/mnt/([A-Za-z])(?:/(.*))?$", path)
    if not m:
        return [path]  # CHECK:v-path
    letter, rest = m.group(1), (m.group(2) or "").replace("\\", "/").strip("/")
    return [
        "/mnt/%s/%s" % (letter.lower(), rest),  # CHECK:v-mnt
        "%s:/%s" % (letter.upper(), rest),  # CHECK:v-dfwd
        "%s:\\%s" % (letter.upper(), rest.replace("/", "\\")),  # CHECK:v-dback
    ]


def vault_check(command, st):
    paths, broken = vault_sources()
    if broken:
        return violation("vault", "the vault is configured but its config is broken (%s), so an agent's Bash is refused (fail closed)" % "; ".join(broken))
    if not paths:
        st.note("vault-unconfigured", "skip")  # CHECK:unconfigured-log
        return None
    hay = fold(command)
    needles = list(LITERALS)
    for p in paths:
        needles.extend(renderings(p))
    for nd in needles:
        if nd and fold(nd) in hay:
            return violation("vault", "an agent's Bash command mentions the vault (%s); agents never touch the vault" % nd)
    return None


# ----------------------------------------------------------------------------------------------- entry points
def log_events(events, label):
    path = os.path.join(os.path.expanduser("~"), ".config", "wom", "git-guard.log")
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)  # CHECK:log-write
        stamp = time.strftime("%Y-%m-%dT%H:%M:%S%z")
        with open(path, "a", encoding="utf-8") as fh:
            for rule, decision in events:
                fh.write("%s %s %s %s\n" % (stamp, rule, decision, label))
        return True
    except OSError as exc:
        print("git-guard: cannot append to %s (%s)" % (path, exc.strerror), file=sys.stderr)
        return False


def finish(code, events, label, message=None):
    if message:
        print(message, file=sys.stderr)
    if not log_events(events, label):
        print("git-guard: decision not recorded in the log (see above); the decision stands", file=sys.stderr)  # CHECK:log-failure
    return code


def main():
    raw = sys.stdin.buffer.read().decode("utf-8")
    if not raw.strip():
        return finish(2, [("input-empty", "block")], "?", "git-guard: BLOCKED [input]: empty hook input; blocking (fail closed)")  # CHECK:json-empty
    try:
        data = json.loads(raw)
    except ValueError as exc:
        return finish(2, [("input-invalid-json", "block")], "?", "git-guard: BLOCKED [input]: hook input is not valid JSON (%s); blocking (fail closed)" % exc)  # CHECK:json-invalid
    if not isinstance(data, dict):
        return finish(2, [("input-shape", "block")], "?", "git-guard: BLOCKED [input]: hook input is not a JSON object; blocking (fail closed)")
    agent = "agent_type" in data and data["agent_type"] is not None  # CHECK:agent
    if agent:
        label = str(data["agent_type"]).strip().replace(" ", "_") or "(empty)"
    else:
        label = "main"
    if data.get("tool_name") not in (None, "Bash"):
        return finish(0, [("not-bash", "allow")], label)
    tool_input = data.get("tool_input")
    command = tool_input.get("command") if isinstance(tool_input, dict) else None
    if not isinstance(command, str):  # CHECK:no-command
        return finish(2, [("input-no-command", "block")], label, "git-guard: BLOCKED [input]: Bash call without a command string; blocking (fail closed)")
    cwd = data.get("cwd") if isinstance(data.get("cwd"), str) and data.get("cwd") else os.getcwd()
    st = State(cwd, agent)
    v = run_text(command, st, 0)  # CHECK:raw-regex
    if not v and agent:  # CHECK:vault-exempt
        v = vault_check(command, st)
    if v:
        rule, why = v
        st.note(rule, "block")
        return finish(2, st.events, label, "git-guard: BLOCKED [%s]: %s" % (rule, why))
    st.note("none", "allow")
    return finish(0, st.events, label)


def guarded_main():
    try:
        return main()
    except BaseException as exc:  # only exit 2 blocks, so any crash or parse error must be 2
        msg = "git-guard: BLOCKED [internal]: %s: %s; blocking (fail closed)" % (exc.__class__.__name__, exc)
        print(msg, file=sys.stderr)
        log_events([("internal-error", "block")], "?")
        return 2


if __name__ == "__main__":
    sys.exit(guarded_main())
