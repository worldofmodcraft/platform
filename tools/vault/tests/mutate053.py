"""Mutation table for docs/tasks/053-verify.sh --mutate (MANAGER.md section 2c rule 2).

usage: python3 -I mutate053.py list                 -> one mutation name per line
       python3 -I mutate053.py apply NAME SRC DST   -> write the mutated copy, print the tests that must turn red
A mutation whose anchor text is not found exactly once is an error: a check on nothing must fail.
"""
import sys

M = {
    "journal-tz": (
        "tz = ZoneInfo(JOURNAL_TZ)  # CHECK:journal-tz", "tz = __import__(\"datetime\").timezone.utc  # mutated",
        ["TestAC2Days.test_ac2_stockholm_day_boundaries"]),
    "skip-identical": (
        "if existing == data:  # CHECK:skip-identical", "if False:  # mutated",
        ["TestAC2Days.test_ac2_only_the_affected_notes_are_rewritten"]),
    "adr-frontmatter": (
        "if body.lstrip(\"\\ufeff\").startswith(\"---\"):  # CHECK:adr-frontmatter", "if False:  # mutated",
        ["TestAC3AdrFrontmatter.test_ac3_adr_starting_with_dashes_fails_validation_and_writes_nothing"]),
    "secret-scan": (
        "scan_secrets(notes)  # CHECK:secret-scan", "pass  # mutated",
        ["TestAC4Secrets.test_ac4_secret_in_adr_or_commit_subject_blocks_the_run"]),
    "id-conflict-main": (
        "if tid in conflicts:  # CHECK:id-conflict-main", "if False:  # mutated",
        ["TestAC7DuplicateIds.test_ac7_main_skips_names_the_conflict_and_task_mode_refuses"]),
    "id-conflict-status": (
        "    if conflicts:\n        conflict_section =", "    if False:\n        conflict_section =",
        ["TestAC7DuplicateIds.test_ac7_main_skips_names_the_conflict_and_task_mode_refuses"]),
    "id-conflict-task": (
        "if len(owners[tid]) > 1:  # CHECK:id-conflict-task", "if False:  # mutated",
        ["TestAC7DuplicateIds.test_ac7_main_skips_names_the_conflict_and_task_mode_refuses",
         "TestAC7DuplicateIds.test_ac7_main_leaves_an_existing_note_untouched_and_conflict_clears"]),
    "non-regular": (
        "if mode is not None and not stat.S_ISREG(mode):  # CHECK:non-regular", "if False:  # mutated",
        ["TestAC8NonRegular.test_ac8_symlink_target_is_refused_without_opening_it",
         "TestAC8NonRegular.test_ac8_fifo_directory_and_dangling_link"]),
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
