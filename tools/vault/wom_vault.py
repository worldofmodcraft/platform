#!/usr/bin/env python3
"""Project the repository's notes into the Obsidian vault (task 051).

Contract: docs/tools/vault-projection.md.  Python 3 standard library only.
Run as:  python3 -I tools/vault/wom_vault.py write --ref main
         python3 -I tools/vault/wom_vault.py write --ref HEAD     (inside a task/NNN-* worktree)
         python3 -I tools/vault/wom_vault.py check --save-baseline FILE | --baseline FILE

Design rules (see the contract for the reasons):
  * Source is git objects of a named ref, never the working tree.
  * Phase 1 renders and validates everything; phase 2 writes.  A validation failure writes nothing.
  * The script never deletes anything.
  * The vault is only ever opened at planned target paths.  `check` uses stat only.
"""
import argparse
import fcntl
import json
import os
import re
import subprocess
import sys
import time
import unicodedata

LOCK_TIMEOUT_SECONDS = 30

# Hand-written notes in the real vault.  Hard-coded so validation fails before any read (rule 6).
FORBIDDEN_NAMES = frozenset(
    unicodedata.normalize("NFC", n).casefold()
    for n in ("Agent Session Handover Prompt.md", "MINISIGN.md", "Olika Sessioner.md")
)

# Length- and charset-bounded, so prose that merely names a prefix does not match (rule 4).
SECRET_PATTERNS = (
    ("github-token", re.compile(r"gh[pousr]_[A-Za-z0-9]{36}")),
    ("github-fine-grained-pat", re.compile(r"github_pat_[A-Za-z0-9_]{82}")),
    ("private-key-pem", re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("minisign-secret-key", re.compile(r"untrusted comment: minisign encrypted secret key")),
    ("anthropic-api-key", re.compile(r"sk-ant-[A-Za-z0-9_-]{32,}")),
    ("aws-access-key", re.compile(r"(AKIA|ASIA)[A-Z0-9]{16}")),
)

STATUS_RE = re.compile(r"\*\*Status:\*\*\s*\**([a-z-]+)")
TASK_FILE_RE = re.compile(r"^docs/tasks/(done/)?([0-9]{3})-[^/]*\.md$")
TASK_BRANCH_RE = re.compile(r"^task/([0-9]{3})-")
LOG_HEADING_RE = re.compile(r"^#{1,2} (Task [0-9]{3} log|Log)\s*$")
MISSION_LOG = "docs/tasks/MISSION-worldofmodcraft-site-v1-log.md"
VERBATIM_NOTES = (
    ("Gotchas.md", "docs/manager/OPERATIONS.md"),
    ("Commands.md", "docs/manager/COMMANDS.md"),
    ("Mission Log.md", MISSION_LOG),
)
AGGREGATE_NOTES = ("Status.md", "Tasks.md")
PLANNED_TOP_LEVEL = frozenset(AGGREGATE_NOTES + tuple(n for n, _ in VERBATIM_NOTES))
PLANNED_TASK_NOTE_RE = re.compile(r"^Tasks/[0-9]{3}\.md$")
TASK_NOTE_NAME_RE = re.compile(r"^Tasks/[0-9]{3}\.md$")


class WomError(Exception):
    """A validation or environment failure.  Reported on stderr, exit status 1."""


# --------------------------------------------------------------------------- vault resolution

def _under(path, directory):
    """True when `path` is strictly inside `directory` (both already real paths)."""
    return path != directory and os.path.commonpath([path, directory]) == directory


def resolve_vault():
    """Return (vault_path, real_vault_path, test_mode).  Uses stat/readlink only on the vault."""
    test_mode = os.environ.get("WOM_VAULT_TEST") == "1"
    raw = os.environ.get("WOM_VAULT")
    if test_mode:
        # Test mode ignores ~/.config/wom/vault-path entirely (rule 8).
        if not raw:
            raise WomError("test mode (WOM_VAULT_TEST=1) requires WOM_VAULT in the environment")
    elif not raw:
        cfg = os.path.join(os.path.expanduser("~"), ".config", "wom", "vault-path")
        try:
            with open(cfg, encoding="utf-8") as fh:
                lines = fh.read().splitlines()
        except OSError as exc:
            raise WomError("WOM_VAULT is not set and the config file cannot be read (%s)" % exc.strerror)
        if len(lines) != 1 or not lines[0].strip():
            raise WomError("the vault-path config file must hold exactly one non-empty line")
        raw = lines[0].strip()
    if not os.path.isabs(raw):
        raise WomError("WOM_VAULT must be an absolute path")
    if not os.path.lexists(raw):
        raise WomError("WOM_VAULT does not exist")
    if os.path.islink(raw):  # CHECK:vault-symlink
        raise WomError("WOM_VAULT is itself a symlink")
    if not os.path.isdir(raw):
        raise WomError("WOM_VAULT is not a directory")
    real = os.path.realpath(raw)
    tmp_real = os.path.realpath(os.environ.get("TMPDIR") or "/tmp")
    if test_mode:
        if not _under(real, tmp_real):  # CHECK:test-mode-tmp
            raise WomError("test mode refuses a vault outside the temporary directory")
    else:
        if real == "/tmp" or real.startswith("/tmp/") or real.startswith(os.path.realpath("/tmp") + "/"):  # CHECK:nontest-tmp
            raise WomError("a vault under /tmp is only allowed in test mode")
    return raw, real, test_mode


# --------------------------------------------------------------------------- git access

def git(repo, *args, ok=(0,)):
    proc = subprocess.run(
        ["git", "-C", repo] + list(args),
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        env=dict(os.environ, LC_ALL="C", GIT_OPTIONAL_LOCKS="0"),
    )
    if proc.returncode not in ok:
        first = proc.stderr.decode("utf-8", "replace").strip().splitlines()[:1]
        raise WomError("git %s failed: %s" % (args[0], first[0] if first else "exit %d" % proc.returncode))
    return proc


def git_text(repo, *args):
    return git(repo, *args).stdout.decode("utf-8", "strict").strip()


def resolve_commit(repo, ref):
    proc = git(repo, "rev-parse", "--verify", "--quiet", ref + "^{commit}", ok=(0, 1))
    if proc.returncode != 0:
        raise WomError("ref %r does not resolve to a commit" % ref)
    return proc.stdout.decode().strip()


def read_blob(repo, sha, path):
    proc = git(repo, "cat-file", "blob", "%s:%s" % (sha, path), ok=(0, 128))
    if proc.returncode != 0:
        raise WomError("source %s does not exist at %s" % (path, sha[:12]))
    try:
        text = proc.stdout.decode("utf-8", "strict")
    except UnicodeDecodeError:
        raise WomError("source %s is not valid UTF-8" % path)
    return text.replace("\r\n", "\n")


def last_commit(repo, sha, paths):
    out = git_text(repo, "log", "-1", "--format=%H", sha, "--", *paths)
    if not out:
        raise WomError("no commit touches %s" % ", ".join(paths))
    return out


def commit_date(repo, sha):
    return git_text(repo, "log", "-1", "--format=%cI", sha)


def frontmatter(ref_name, repo, sha, paths):
    return "---\ngenerated: true\nsource_ref: %s\nsource_commit: %s\nsource_path: %s\nupdated: %s\n---\n\n" % (
        ref_name, sha, ", ".join(paths), commit_date(repo, sha))


# --------------------------------------------------------------------------- task metadata

class TaskInfo:
    def __init__(self, tid, path, title, status, in_done):
        self.tid, self.path, self.title, self.status, self.in_done = tid, path, title, status, in_done

    @property
    def is_open(self):
        return not self.in_done and self.status not in ("done", "stopped")

    @property
    def status_text(self):
        return self.status if self.status else "status unparsed"


def parse_task(path, text, tid):
    title = ""
    for line in text.split("\n"):
        if line.startswith("# "):
            title = line[2:].strip()
            break
    m = STATUS_RE.search(text)
    return TaskInfo(tid, path, title or "(no title)", m.group(1) if m else None, path.startswith("docs/tasks/done/"))


def list_tasks(repo, sha):
    raw = git(repo, "ls-tree", "-r", "-z", "--name-only", sha, "--", "docs/tasks").stdout
    tasks = {}
    for path in sorted(p for p in raw.decode("utf-8", "strict").split("\0") if p):
        m = TASK_FILE_RE.match(path)
        if not m:
            continue
        tid = m.group(2)
        if tid in tasks:
            raise WomError("two task files share the id %s: %s and %s" % (tid, tasks[tid].path, path))
        tasks[tid] = parse_task(path, read_blob(repo, sha, path), tid)
    return tasks


def unmerged_task_branches(repo):
    """Local task/NNN-* branches that are not ancestors of main: {id: [branch, ...]}."""
    out = git_text(repo, "for-each-ref", "--format=%(refname:short)", "refs/heads/task/")
    owners = {}
    for br in sorted(b for b in out.splitlines() if b):
        m = TASK_BRANCH_RE.match(br)
        if not m:
            continue
        proc = git(repo, "merge-base", "--is-ancestor", br, "main", ok=(0, 1))
        if proc.returncode == 0:  # CHECK:ownership
            continue
        owners.setdefault(m.group(1), []).append(br)
    return owners


# --------------------------------------------------------------------------- rendering

def split_sections(text):
    """Top-level `## ` sections outside code fences: [(heading, section_text)]."""
    sections, cur, fence = [], None, False
    for line in text.split("\n"):
        if re.match(r"^ {0,3}(```|~~~)", line):
            fence = not fence
        if not fence and line.startswith("## "):
            if cur:
                sections.append(cur)
            cur = (line, [line])
        elif cur:
            cur[1].append(line)
    if cur:
        sections.append(cur)
    return [(h, "\n".join(body).rstrip("\n")) for h, body in sections]


def esc(cell):
    return cell.replace("|", "\\|")


def render_main(repo, ref_name, sha):
    tasks = list_tasks(repo, sha)
    owners = unmerged_task_branches(repo)
    notes, skipped, counters = {}, [], {"status_unparsed": 0, "no_log_entry": 0}
    head_date_fm = lambda paths: frontmatter(ref_name, repo, sha, paths)

    for name, src in VERBATIM_NOTES:
        body = read_blob(repo, sha, src)
        commit = last_commit(repo, sha, [src])
        notes[name] = frontmatter(ref_name, repo, commit, [src]) + body.rstrip("\n") + "\n"

    log = read_blob(repo, sha, MISSION_LOG)
    secs = split_sections(log)
    idx = [i for i, (h, _) in enumerate(secs) if h.startswith("## SESSION")]
    if not idx:
        raise WomError("%s has no section whose heading starts with '## SESSION'" % MISSION_LOG)
    last = idx[-1]
    parts = [secs[last][1]] + [t for h, t in secs[last + 1:] if "For Ludwig" in h]

    def owner_of(t):
        return ", ".join(owners[t.tid]) if t.tid in owners else "main"

    open_rows = ["| Id | Title | Status | Owner | Note |", "|---|---|---|---|---|"]
    all_rows = ["| Id | Title | Status | Note |", "|---|---|---|---|"]
    for tid in sorted(tasks):
        t = tasks[tid]
        if t.status is None:
            counters["status_unparsed"] += 1
        link = "[[Tasks/%s]]" % tid
        all_rows.append("| %s | %s | %s | %s |" % (tid, esc(t.title), t.status_text, link))
        if t.is_open:
            open_rows.append("| %s | %s | %s | %s | %s |" % (tid, esc(t.title), t.status_text, esc(owner_of(t)), link))
    if len(open_rows) == 2:
        open_rows.append("| - | no open tasks | - | - | - |")

    notes["Status.md"] = (head_date_fm([MISSION_LOG, "docs/tasks/"]) + "# Status\n\n" + "\n\n".join(parts)
                          + "\n\n## Open tasks\n\n" + "\n".join(open_rows) + "\n")
    branch_rows = ["| Id | Branch | Note |", "|---|---|---|"]
    for tid in sorted(owners):
        for br in owners[tid]:
            branch_rows.append("| %s | %s | [[Tasks/%s]] |" % (tid, esc(br), tid))
    if len(branch_rows) == 2:
        branch_rows.append("| - | no open task branches | - |")
    notes["Tasks.md"] = (head_date_fm(["docs/tasks/"]) + "# Tasks\n\n" + "\n".join(all_rows)
                         + "\n\n## Open task branches\n\n" + "\n".join(branch_rows) + "\n")

    for tid in sorted(tasks):
        t = tasks[tid]
        if tid in owners:
            skipped.append(tid)
            continue
        # Single-source: the last commit that touched the task file (keeps unchanged tasks untouched).
        commit = last_commit(repo, sha, [t.path])
        notes["Tasks/%s.md" % tid] = (
            frontmatter(ref_name, repo, commit, [t.path])
            + "# Task %s: %s\n\n- Status: %s\n- Task file: `%s`\n" % (tid, t.title, t.status_text, t.path))
    return notes, skipped, counters


def render_task(repo):
    branch = git_text(repo, "rev-parse", "--abbrev-ref", "HEAD")
    m = TASK_BRANCH_RE.match(branch)
    if not m:
        raise WomError("mode task needs a worktree on a task/NNN-* branch (this is %r)" % branch)
    tid = m.group(1)
    if tid not in unmerged_task_branches(repo) or branch not in unmerged_task_branches(repo)[tid]:
        raise WomError("branch %s is merged into main, so main owns Tasks/%s.md" % (branch, tid))
    sha = resolve_commit(repo, "HEAD")
    tasks = list_tasks(repo, sha)
    if tid not in tasks:
        raise WomError("branch %s has no task file for id %s" % (branch, tid))
    t = tasks[tid]
    text = read_blob(repo, sha, t.path)
    counters = {"status_unparsed": 1 if t.status is None else 0, "no_log_entry": 0}
    lines = text.split("\n")
    entry = None
    for i, line in enumerate(lines):
        if LOG_HEADING_RE.match(line):
            bullets = [l for l in lines[i + 1:] if l.startswith("- ")]
            entry = bullets[-1] if bullets else None
            break
    if entry is None:
        counters["no_log_entry"] = 1
        entry = "no log entry"
    ahead = git_text(repo, "log", "--oneline", "main..HEAD")
    body = ("# Task %s: %s\n\n- Branch: `%s`\n- Status: %s\n- Task file: `%s`\n- Last log entry: %s\n\n"
            "## Commits ahead of main\n\n%s\n") % (
        tid, t.title, branch, t.status_text, t.path, entry,
        "\n".join("- " + l for l in ahead.splitlines()) if ahead else "none")
    return {"Tasks/%s.md" % tid: frontmatter(branch, repo, sha, [t.path]) + body}, [], counters


# --------------------------------------------------------------------------- validation

def check_names(requested, mode):
    """Rule 6: the forbidden-name check comes first and runs before any file is read."""
    for rel in requested:
        base = unicodedata.normalize("NFC", os.path.basename(rel)).casefold()
        if base in FORBIDDEN_NAMES:  # CHECK:forbidden-names
            raise WomError("forbidden target name: %s is a hand-written note" % rel)
    for rel in requested:
        planned = rel in PLANNED_TOP_LEVEL or TASK_NOTE_NAME_RE.match(rel)
        if not planned:
            raise WomError("%s is not a note this tool writes" % rel)
        if mode == "task" and not TASK_NOTE_NAME_RE.match(rel):
            raise WomError("mode task writes only Tasks/NNN.md, refusing %s" % rel)


def scan_secrets(notes):
    hits = []
    for rel in sorted(notes):
        for lineno, line in enumerate(notes[rel].split("\n"), 1):
            for pname, rx in SECRET_PATTERNS:
                if rx.search(line):
                    hits.append("%s line %d matches pattern %s" % (rel, lineno, pname))
    if hits:
        raise WomError("secret scan failed (matched text is never printed): " + "; ".join(hits))


def is_generated(data):
    lines = data.decode("utf-8", "replace").split("\n")
    if not lines or lines[0].rstrip("\r") != "---":
        return False
    for line in lines[1:]:
        line = line.rstrip("\r")
        if line == "---":
            return False
        if line == "generated: true":
            return True
    return False


def validate(vault, real_vault, notes):
    """Phase 1 target checks.  Returns {rel: (target_path, new_bytes, existing_bytes_or_None)}."""
    scan_secrets(notes)  # CHECK:secret-scan
    plan = {}
    for rel in sorted(notes):
        target = os.path.join(vault, *rel.split("/"))
        real_target = os.path.realpath(target)
        if not _under(real_target, real_vault):  # CHECK:containment
            raise WomError("target %s resolves outside the vault" % rel)
        parent = os.path.dirname(target)
        if os.path.lexists(parent) and not os.path.isdir(parent):
            raise WomError("%s: parent exists and is not a directory" % rel)
        existing = None
        if os.path.lexists(target):
            if os.path.isdir(target):
                raise WomError("target %s is a directory" % rel)
            with open(target, "rb") as fh:
                existing = fh.read()
            if not is_generated(existing):  # CHECK:generated-true
                raise WomError("target %s exists without 'generated: true' frontmatter" % rel)
        plan[rel] = (target, notes[rel].encode("utf-8"), existing)
    return plan


# --------------------------------------------------------------------------- writing

def atomic_write(path, data):
    d, name = os.path.split(path)
    tmp = os.path.join(d, ".%s.%d.%d.wom-tmp" % (name, os.getpid(), time.monotonic_ns()))
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o644)
    with os.fdopen(fd, "wb") as fh:
        fh.write(data)
        fh.flush()
        os.fsync(fh.fileno())
    os.replace(tmp, path)


def write_plan(vault, plan):
    written, unchanged = [], []
    for rel in sorted(plan):
        target, data, existing = plan[rel]
        if existing == data:  # CHECK:skip-identical
            unchanged.append(rel)
            continue
        parent = os.path.dirname(target)
        if parent != vault and not os.path.isdir(parent):
            os.mkdir(parent)
        atomic_write(target, data)
        written.append(rel)
    return written, unchanged


def acquire_lock(repo):
    common = git_text(repo, "rev-parse", "--git-common-dir")
    lockpath = os.path.join(repo, common, "wom-vault.lock")
    fd = os.open(lockpath, os.O_RDWR | os.O_CREAT, 0o644)
    deadline = time.monotonic() + LOCK_TIMEOUT_SECONDS
    while True:
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)  # CHECK:lock
            return fd
        except BlockingIOError:
            if time.monotonic() >= deadline:
                raise WomError("lock timeout after %d s on %s" % (LOCK_TIMEOUT_SECONDS, lockpath))
            time.sleep(0.05)


# --------------------------------------------------------------------------- commands

def cmd_write(args):
    repo = os.path.abspath(args.repo)
    vault, real_vault, _ = resolve_vault()
    task_mode = args.ref == "HEAD"
    mode = "task" if task_mode else "main"
    requested = args.note or []
    check_names(requested, mode)
    lock_fd = acquire_lock(repo)
    if task_mode:
        notes, skipped, counters = render_task(repo)
        ref_label = "HEAD"
    else:
        sha = resolve_commit(repo, args.ref)
        notes, skipped, counters = render_main(repo, args.ref, sha)
        ref_label = args.ref
    if requested:
        missing = [r for r in requested if r not in notes]
        if missing:
            raise WomError("requested note(s) not planned in this run: %s" % ", ".join(missing))
        notes = {r: notes[r] for r in requested}
    plan = validate(vault, real_vault, notes)
    written, unchanged = write_plan(vault, plan)  # CHECK:two-phase
    for rel in written:
        print("wrote %s" % rel)
    print("wom-vault: mode=%s ref=%s planned=%d written=%d unchanged=%d skipped_branch_owned=%d "
          "status_unparsed=%d no_log_entry=%d" % (
              mode, ref_label, len(plan), len(written), len(unchanged), len(skipped),
              counters["status_unparsed"], counters["no_log_entry"]))
    os.close(lock_fd)
    return 0


def stat_tree(vault):
    entries = {}
    stack = [""]
    while stack:
        rel_dir = stack.pop()
        with os.scandir(os.path.join(vault, rel_dir) if rel_dir else vault) as it:
            for e in it:
                rel = (rel_dir + "/" + e.name) if rel_dir else e.name
                if e.is_dir(follow_symlinks=False):
                    stack.append(rel)
                    continue
                if rel in PLANNED_TOP_LEVEL or PLANNED_TASK_NOTE_RE.match(rel):
                    continue
                st = e.stat(follow_symlinks=False)
                entries[rel] = [st.st_size, st.st_mtime_ns]
    return entries


def cmd_check(args):
    vault, _, _ = resolve_vault()
    now = stat_tree(vault)
    if args.save_baseline:
        with open(args.save_baseline, "w", encoding="utf-8") as fh:
            json.dump(now, fh, sort_keys=True, indent=1)
        print("wom-vault: baseline saved, %d non-generated files" % len(now))
        return 0
    try:
        with open(args.baseline, encoding="utf-8") as fh:
            base = json.load(fh)
    except (OSError, ValueError) as exc:
        raise WomError("cannot read baseline: %s" % exc)
    diffs = []
    for rel in sorted(set(base) | set(now)):
        if rel not in now:
            diffs.append("removed: %s" % rel)
        elif rel not in base:
            diffs.append("added: %s" % rel)
        elif base[rel] != now[rel]:
            diffs.append("changed: %s" % rel)
    for d in diffs:
        print(d)
    print("wom-vault: check compared %d baseline files, %d differences" % (len(base), len(diffs)))
    return 1 if diffs else 0


def main(argv=None):
    ap = argparse.ArgumentParser(prog="wom_vault.py")
    sub = ap.add_subparsers(dest="cmd", required=True)
    w = sub.add_parser("write")
    w.add_argument("--ref", required=True)
    w.add_argument("--note", action="append", help="restrict to this note (may repeat)")
    w.add_argument("--repo", default=".")
    c = sub.add_parser("check")
    g = c.add_mutually_exclusive_group(required=True)
    g.add_argument("--save-baseline")
    g.add_argument("--baseline")
    args = ap.parse_args(argv)
    try:
        return cmd_write(args) if args.cmd == "write" else cmd_check(args)
    except WomError as exc:
        print("wom-vault: error: %s" % exc, file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
