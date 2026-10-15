"""Mutation table for docs/tasks/061-verify.sh --mutate (MANAGER.md section 2c rule 2).

usage: python3 -I mutate061.py list                 -> one mutation name per line
       python3 -I mutate061.py apply NAME SRC DST   -> write the mutated copy, print the tests that must turn red
A mutation whose anchor text is not found exactly once is an error: a check on nothing must fail.
"""
import sys

AC1 = "TestAC1Notes.test_ac1_exactly_the_two_notes_verbatim_with_last_commit"
M = {
    "runbook-notes-dropped": (
        "    notes.update(runbooks)\n", "    pass  # mutated\n", [AC1]),
    "runbook-source-commit": (
        "        commit = last_commit(repo, sha, [path])\n        notes[\"Runbooks/", "        commit = sha\n        notes[\"Runbooks/", [AC1]),
    "runbook-status-line": (
        "if runbooks:  # AC6: no runbooks, no line", "if False:  # mutated",
        ["TestAC1Notes.test_ac1_status_has_a_runbooks_line_linking_each_note"]),
    "runbook-frontmatter": (
        "if body.lstrip(\"\\ufeff\").startswith(\"---\"):  # CHECK:runbook-frontmatter", "if False:  # mutated",
        ["TestAC2Frontmatter.test_ac2_runbook_with_own_frontmatter_fails_and_writes_nothing"]),
    "secret-scan": (
        "scan_secrets(notes)  # CHECK:secret-scan", "pass  # mutated",
        ["TestAC3Secrets.test_ac3_secret_in_a_runbook_blocks_the_run_and_is_never_printed"]),
    "non-regular": (
        "if mode is not None and not stat.S_ISREG(mode):  # CHECK:non-regular", "if False:  # mutated",
        ["TestAC4NonRegular.test_ac4_symlink_fifo_dir_and_dangling_are_refused_before_any_open"]),
    "skip-identical": (
        "if existing == data:  # CHECK:skip-identical", "if False:  # mutated",
        ["TestAC5Idempotence.test_ac5_second_run_writes_nothing_and_one_edit_rewrites_one_note"]),
}


def main(argv):
    if argv[1:] == ["list"]:
        print("\n".join(M))
        return 0
    if len(argv) == 5 and argv[1] == "apply":
        old, new, tests = M[argv[2]]
        src = open(argv[3], encoding="utf-8").read()
        if src.count(old) != 1:
            print("mutation %s: anchor found %d times, need exactly 1" % (argv[2], src.count(old)), file=sys.stderr)
            return 2
        out = src.replace(old, new)
        if out == src:
            print("mutation %s changed nothing" % argv[2], file=sys.stderr)
            return 2
        open(argv[4], "w", encoding="utf-8").write(out)
        print(" ".join(tests))
        return 0
    print(__doc__, file=sys.stderr)
    return 2


sys.exit(main(sys.argv))
