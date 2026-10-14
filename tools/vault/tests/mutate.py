"""Mutation table for docs/tasks/051-verify.sh --mutate (MANAGER.md section 2c rule 2).

usage: python3 -I mutate.py list                 -> one mutation name per line
       python3 -I mutate.py apply NAME SRC DST   -> write the mutated copy, print the tests that must turn red
A mutation whose anchor text is not found exactly once is an error: a check on nothing must fail.
"""
import sys

T = "TestAC"
M = {
    "generated-true": (
        "if not is_generated(existing):  # CHECK:generated-true", "if False:  # mutated",
        [T + "3Guards.test_ac3_unmarked_target_refused", T + "3Guards.test_ac3_generated_false_refused"]),
    "secret-scan": (
        "scan_secrets(notes)  # CHECK:secret-scan", "pass  # mutated",
        [T + "4Secrets.test_ac4_each_pattern_blocks_everything"]),
    "two-phase": (
        "    plan = validate(vault, real_vault, notes)\n    written, unchanged = write_plan(vault, plan)  # CHECK:two-phase\n",
        "    written, unchanged = [], []\n    for _rel in sorted(notes):\n"
        "        _w, _u = write_plan(vault, validate(vault, real_vault, {_rel: notes[_rel]}))\n"
        "        written += _w\n        unchanged += _u\n    plan = notes\n",
        [T + "3Guards.test_ac3_two_phase_nothing_written_when_last_target_invalid"]),
    "containment": (
        "if not _under(real_target, real_vault):  # CHECK:containment", "if False:  # mutated",
        [T + "5Vaults.test_ac5_containment_symlinked_subdir", T + "5Vaults.test_ac5_containment_symlinked_target"]),
    "vault-symlink": (
        "if os.path.islink(raw):  # CHECK:vault-symlink", "if False:  # mutated",
        [T + "5Vaults.test_ac5_vault_symlink"]),
    "forbidden-names": (
        "if base in FORBIDDEN_NAMES:  # CHECK:forbidden-names", "if False:  # mutated",
        [T + "3Guards.test_ac3_forbidden_names_rejected_before_any_open"]),
    "ownership": (
        "if proc.returncode == 0:  # CHECK:ownership", "if proc.returncode == 99:  # mutated",
        [T + "6Ownership.test_ac6_task_mode_and_ownership_lifecycle"]),
    "lock": (
        "fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)  # CHECK:lock", "pass  # mutated",
        [T + "7Lock.test_ac7_lock_serializes", T + "7Lock.test_ac7_lock_timeout_after_30s"]),
    "skip-identical": (
        "if existing == data:  # CHECK:skip-identical", "if False:  # mutated",
        [T + "2Idempotence.test_ac2_second_run_writes_nothing_and_minimal_rewrite"]),
    "test-mode-refusal": (
        "if not _under(real, tmp_real):  # CHECK:test-mode-tmp", "if False:  # mutated",
        [T + "5Vaults.test_ac5_testmode_vault_outside_tmpdir"]),
    "nontest-tmp-refusal": (
        "if real == \"/tmp\" or real.startswith(\"/tmp/\") or real.startswith(os.path.realpath(\"/tmp\") + \"/\"):  # CHECK:nontest-tmp",
        "if False:  # mutated",
        [T + "5Vaults.test_ac5_nontest_refuses_tmp"]),
    "never-deletes": (
        "    os.replace(tmp, path)\n", "    os.replace(tmp, path)\n    os.unlink(tmp) if False else None\n",
        ["TestStatic.test_script_never_deletes"]),
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
