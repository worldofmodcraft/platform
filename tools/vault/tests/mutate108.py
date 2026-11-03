"""Mutation table for docs/tasks/108-verify.sh --mutate (MANAGER.md section 2c rule 2).

usage: python3 -I mutate108.py list                 -> one mutation name per line
       python3 -I mutate108.py apply NAME SRC DST   -> write the mutated copy, print the tests that must turn red
A mutation whose anchor text is not found exactly once is an error: a check on nothing must fail.
"""
import sys

AC1 = "TestAC1Notes.test_ac1_notes_at_the_root_verbatim_with_last_commit"
M = {
    "design-notes-dropped": (
        "    notes.update(render_design_docs(repo, ref_name, sha, set(notes)))\n", "    pass  # mutated\n", [AC1]),
    "design-source-commit": (
        "        commit = last_commit(repo, sha, [path])\n        notes[\"%s.md\" % stem]",
        "        commit = sha\n        notes[\"%s.md\" % stem]", [AC1]),
    "design-name-rule": (
        "if not DESIGN_STEM_RE.match(stem):", "if False:",
        ["TestAC2Names.test_ac2_unaccepted_name_is_an_error_not_a_silent_skip"]),
    "design-forbidden-name": (
        "if folded in FORBIDDEN_NAMES:", "if False:",
        ["TestAC2Names.test_ac2_forbidden_hand_written_name_is_refused"]),
    "design-non-regular": (
        "        if meta.split()[0] not in (\"100644\", \"100755\"):\n            raise WomError(\"design doc",
        "        if False:\n            raise WomError(\"design doc",
        ["TestAC2Names.test_ac2_symlink_in_git_is_not_a_regular_file"]),
    "design-collision": (
        "if folded in taken:  # CHECK:design-collision", "if False:  # mutated",
        ["TestAC3Collision.test_ac3_stem_equal_to_a_planned_root_name_is_an_error",
         "TestAC3Collision.test_ac3_collision_names_the_planned_note"]),
    "design-frontmatter": (
        "if body.lstrip(\"\\ufeff\").startswith(\"---\"):  # CHECK:design-frontmatter", "if False:  # mutated",
        ["TestAC4Frontmatter.test_ac4_design_doc_with_own_frontmatter_fails_and_writes_nothing"]),
    "secret-scan": (
        "scan_secrets(notes)  # CHECK:secret-scan", "pass  # mutated",
        ["TestAC5Secrets.test_ac5_secret_in_a_design_doc_blocks_the_run_and_is_never_printed"]),
    "check-ignores-design": (
        "rel in PLANNED_TOP_LEVEL or rel in design_names or", "rel in PLANNED_TOP_LEVEL or",
        ["TestAC7Vault.test_ac7_check_ignores_planned_design_notes"]),
    "skip-identical": (
        "if existing == data:  # CHECK:skip-identical", "if False:  # mutated",
        ["TestAC7Vault.test_ac7_idempotent_and_never_deletes"]),
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
