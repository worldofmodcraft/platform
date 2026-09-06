# Task 041: The site's second copy of the contract schemas has no sync mechanism

- **Mission:** SITE-V1 — **Status:** **draft** (manager, 2026-09-06). **Not spec-approved.**
- **Budget:** small, to be confirmed at spec time
- **Graph:** edge **E10** (`registry-data → site-build`, "read side of the entry and page schemas").
  The edge names `contracts/entry.schema.json` and `contracts/page.schema.json` in the **registry**
  as its contract. The site holds its own copies of those files.

## The finding
Raised by the reviewer of registry PR #5 and verified by the manager, 2026-09-06:

```
$ ls /home/ludwig/site/schemas/
README.md  entry.schema.json  manifest.schema.json  page.schema.json

$ diff -q /home/ludwig/site/schemas/page.schema.json     /home/ludwig/registry/contracts/page.schema.json
$ diff -q /home/ludwig/site/schemas/manifest.schema.json /home/ludwig/registry/contracts/manifest.schema.json
   (no output from either — byte-identical today)
```

**They agree right now, and that is the problem, because nothing makes them agree.** Registry PR #5
(task 034) tightens `screenshots[]` in both registry schemas to reject `../`. The moment it merges,
the site's copies still carry the permissive pattern and nothing anywhere will notice. E10 names a
contract that lives in one repository and is *duplicated*, unversioned and uncompared, into another.

The site defends itself at runtime (task 009's `isSafeModSuppliedRelativePath` does an exact `..`
segment check before every `path.join`), so this is not a live hole today. It is a **drift
mechanism**: the next divergence may not be one the runtime happens to cover.

## Intended scope
Decide and implement how the site obtains the schemas — the options being a build-time checkout of
the registry (the deploy workflow already has a registry checkout, currently commented out), a
generated vendored copy with a CI check that fails on drift, or a published contracts artefact.
Whichever is chosen, **a drift check must exist and must be able to fail**; a copy nobody compares
is what created this task.

## Related
Task 034 (registry PR #5) is what makes the copies diverge. Task 008 uncomments the deploy
workflow's registry checkout, which may supply the mechanism for free — sequence after it if so.
