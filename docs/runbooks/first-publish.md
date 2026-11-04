# First publish of `test:hello-world` — the runbook

**Last reviewed: 2026-11-04 (task 010b).** Written for Ludwig. Plain commands, copy and paste one block at a time.
Stage 1 of 2: **Part 1 is ready to use today.** Parts 2 to 5 are written from what is built (registry `main` at
`428df02`) and are marked wherever nothing was observed; task 010c re-rehearses them after task 008b-3b and removes the
marks. Source of the mod files: `docs/test-mod/hello-world/` (task 010a).

## How to read this page

Every numbered step has three labelled parts:

- **Do** — the exact command or click. Each grey block is one unit: copy the whole block, paste it, press Enter.
- **You should see** — what the screen shows when it worked.
- **This proves** — what that result tells you.

Markers in *You should see*:

- No marker: the text was copied from a real run on 2026-11-04 in a scratch area on the manager's machine. That run
  used a folder on disk in place of GitHub, and an address on disk shows where GitHub's address will be. A
  commit hash (40 letters and digits, such as `f4fd0dd1...`) is different on every run, so **yours will differ**; that is normal.
- The word UNVERIFIED in square brackets, followed by "expected, not observed" — nobody has seen this yet. Treat it as a guess and tell the manager if the screen differs.
- `[NOT REHEARSED]` — the step talks to GitHub itself and cannot be tried without really publishing, so it was not run.

If a screen differs from "You should see", **stop and tell the manager what you see.** Do not improvise and do not retry
in a different way.

**Rules for the whole runbook**

1. You are never asked to copy, paste or type a password, token or key anywhere. If a command asks you for a password
   or a token, press Ctrl+C and tell the manager.
2. Use the **Ubuntu** (WSL) terminal, the same one the manager works in. Windows PowerShell is not used.
3. Two GitHub accounts are stored on this computer: `womcraft` (the project's account, normally the active one) and
   `mbmludric` (yours). Every section that switches to `mbmludric` **ends with a step that switches back to `womcraft`.**
   If anything goes wrong in the middle of such a section, do the switch-back step first and then tell the manager.
4. This is the real registry. A published version is permanent (ADR-0041). Do not repeat a publish step to "try again".

---

## Part 1 — Create the mod repository, fill it, tag it, push it (task step M4)

Result: a public repository `mbmludric/wom-test-hello-world` with one commit and the tag `v1.0.0`, and the 40-character
commit hash handed to the manager. Steps 1.1 to 1.9 only change files on your own computer and use no GitHub account.
Steps 1.10 to 1.16 talk to GitHub.

### Step 1.1 — Bring the platform copy up to date

**Do**

```
git -C ~/wom fetch origin
```

**You should see**

Nothing at all, or a few lines starting with `From` or `*`. A command line prompt again with no word `fatal` or `error`.
(Observed: no output.)

**This proves** your `~/wom` folder knows the current `main` of the platform repository, which holds the mod files from task 010a.

### Step 1.2 — Make the working folders

**Do**

```
mkdir ~/wom-first-publish
mkdir ~/wom-first-publish/wom-test-hello-world
```

**You should see**

Nothing at all. (Observed: no output.) If you see `File exists`, you have started this runbook before: stop and tell the manager.

**This proves** the work area is new and empty, so no old file can end up in the repository.

### Step 1.3 — Copy the fill script and the mod files

**Do**

```
git -C ~/wom show origin/main:tools/test-mod/fill_placeholders.py > ~/wom-first-publish/fill_placeholders.py
git -C ~/wom archive origin/main docs/test-mod/hello-world | tar -x -C ~/wom-first-publish/wom-test-hello-world --strip-components=3
cd ~/wom-first-publish/wom-test-hello-world
find . -type f | sort
```

**You should see**

Exactly these six lines, in this order:

```
./LICENSE
./README.md
./assets/screenshots/gallery.png
./assets/screenshots/spare.png
./assets/screenshots/welcome.png
./mod.lua
```

**This proves** the repository folder holds the six files of the mod and nothing else. (`spare.png` is meant to be there: the
page change in Part 4 uses it. The fill script is kept outside the folder on purpose, so it never enters the repository.)

### Step 1.4 — Find the one place that still needs your account name

**Do**

```
cd ~/wom-first-publish/wom-test-hello-world
grep -rn OWNER-PLACEHOLDER .
```

**You should see**

Exactly one line:

```
./mod.lua:9:  source = "https://github.com/OWNER-PLACEHOLDER/wom-test-hello-world",
```

**This proves** the search works and the placeholder is where the task said it would be. A search that finds nothing here would mean the wrong files were copied.

### Step 1.5 — Fill in your account name

**Do**

```
cd ~/wom-first-publish/wom-test-hello-world
python3 ~/wom-first-publish/fill_placeholders.py mod --account mbmludric
```

**You should see**

One line:

```
filled mod.lua
```

If you see a line starting `REFUSED:`, nothing was changed; copy the line to the manager.

**This proves** the script accepted `mbmludric` as an account name and wrote the file. The script checks by itself that no placeholder is left.

### Step 1.6 — Check the result with your own eyes

**Do**

```
cd ~/wom-first-publish/wom-test-hello-world
grep -n "source =" mod.lua
grep -rn OWNER-PLACEHOLDER . ; echo "grep exit: $?"
```

**You should see**

```
9:  source = "https://github.com/mbmludric/wom-test-hello-world",
grep exit: 1
```

**This proves** `mod.lua` now names your repository, and the second search finds no placeholder anywhere (`grep exit: 1` means "found nothing", which is what you want here).

### Step 1.7 — Start the repository and tell git who you are, for this folder only

**Do**

```
cd ~/wom-first-publish/wom-test-hello-world
git init -b main
git config user.name "mbmludric"
git config user.email "37807560+mbmludric@users.noreply.github.com"
git config --local --get-regexp "^user"
```

**You should see**

```
Initialized empty Git repository in /home/ludwig/wom-first-publish/wom-test-hello-world/.git/
user.name mbmludric
user.email 37807560+mbmludric@users.noreply.github.com
```

(The first line shows your own home folder; the rehearsal ran in a scratch folder, so only that path was replaced here.)

**This proves** the repository exists and its commit will carry your GitHub name and GitHub's private "noreply" address (`37807560` is the numeric id of `mbmludric`), not your real email address.

### Step 1.8 — Make the one commit

**Do**

```
cd ~/wom-first-publish/wom-test-hello-world
git add -A
git status --short
git commit -m "test:hello-world 1.0.0 (World of Modcraft pipeline canary)"
```

**You should see**

First the list of files about to be committed, then git's report:

```
A  LICENSE
A  README.md
A  assets/screenshots/gallery.png
A  assets/screenshots/spare.png
A  assets/screenshots/welcome.png
A  mod.lua
[main (root-commit) f4fd0dd] test:hello-world 1.0.0 (World of Modcraft pipeline canary)
 6 files changed, 83 insertions(+)
 create mode 100644 LICENSE
 create mode 100644 README.md
 create mode 100644 assets/screenshots/gallery.png
 create mode 100644 assets/screenshots/spare.png
 create mode 100644 assets/screenshots/welcome.png
 create mode 100644 mod.lua
```

Your `f4fd0dd` will be different. Everything else should match, including `6 files changed, 83 insertions(+)`.

**This proves** all six files, and only those, are in the one commit.

### Step 1.9 — Tag it `v1.0.0` and read the commit hash

**Do**

```
cd ~/wom-first-publish/wom-test-hello-world
git tag v1.0.0
git show-ref --tags
git rev-parse HEAD
git rev-parse "v1.0.0^{commit}"
```

**You should see**

Three lines. The first is the tag with the full hash; the second and third are the same 40-character hash again:

```
f4fd0dd1010e148276668202cd0158016df83505 refs/tags/v1.0.0
f4fd0dd1010e148276668202cd0158016df83505
f4fd0dd1010e148276668202cd0158016df83505
```

Your hash differs from this one. The three hashes on your screen must be identical to each other.

**This proves** the tag `v1.0.0` points at your commit. That 40-character hash is what the registry will build. **Keep this terminal window open;** the hash is needed again in step 1.15 and in Part 2.

### Step 1.10 — Check the repository name is still free

**Do**

```
curl -s -o /dev/null -w "status=%{http_code}\n" https://api.github.com/repos/mbmludric/wom-test-hello-world
```

**You should see**

```
status=404
```

(Observed 2026-11-04. `404` means "no such repository yet".) If you see `status=200`, the repository already exists: stop and tell the manager.

**This proves** nobody has created the repository since the manager checked, so the next steps will not collide with anything.

### Step 1.11 — Switch to your own GitHub account

[NOT REHEARSED] Changing the account on this machine changes real login state.

**Do**

```
gh auth status
gh auth switch --user mbmludric
gh auth status
```

**You should see**

[UNVERIFIED — expected, not observed] The first `gh auth status` lists two accounts for github.com, `womcraft` and `mbmludric`, with `womcraft` marked active. After the switch, the second `gh auth status` lists the same two accounts with `mbmludric` marked active. The output shows account names only; no token is displayed and none is requested.

**This proves** the next GitHub commands run as you, not as the project's account. Start of the part that **must** end with step 1.16.

### Step 1.12 — Create the empty public repository on GitHub

[NOT REHEARSED] This creates a real repository.

**Do**

```
gh repo create mbmludric/wom-test-hello-world --public --description "Permanent pipeline canary mod for World of Modcraft (test:hello-world)"
curl -s -o /dev/null -w "status=%{http_code}\n" https://api.github.com/repos/mbmludric/wom-test-hello-world
```

**You should see**

[UNVERIFIED — expected, not observed] A line saying the repository `mbmludric/wom-test-hello-world` was created, with its web address `https://github.com/mbmludric/wom-test-hello-world`, then:

```
status=200
```

**This proves** the repository exists and is public (the `curl` call carries no login, so it can only see a public repository).

### Step 1.13 — Push the commit and the tag

[NOT REHEARSED] The pushes go to GitHub. They were rehearsed against a folder on disk standing in for GitHub.

**Do**

```
cd ~/wom-first-publish/wom-test-hello-world
git remote add origin https://github.com/mbmludric/wom-test-hello-world.git
git push -u origin main
git push origin v1.0.0
```

**You should see**

[UNVERIFIED — expected, not observed] Against GitHub, the same lines as in the rehearsal below, except that each `To` line names `https://github.com/mbmludric/wom-test-hello-world.git`, and git may print extra "Enumerating objects" lines. In the rehearsal, the output was:

```
To file:///tmp/r010b-home-Q52ad5/remote/wom-test-hello-world.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
To file:///tmp/r010b-home-Q52ad5/remote/wom-test-hello-world.git
 * [new tag]         v1.0.0 -> v1.0.0
```

If git asks for a username or a password, press Ctrl+C. Do not type anything. Do step 1.16, then tell the manager.

**This proves** the commit (as branch `main`) and the tag are on GitHub. Pushing uses the login that `gh` already holds for the active account, which is why step 1.11 came first.

### Step 1.14 — Ask GitHub what it now holds

**Do**

```
git ls-remote https://github.com/mbmludric/wom-test-hello-world.git
```

**You should see**

[UNVERIFIED — expected, not observed] Against GitHub, three lines in this shape, with your 40-character hash from step 1.9 at the start of each line. In the rehearsal the output was:

```
f4fd0dd1010e148276668202cd0158016df83505	HEAD
f4fd0dd1010e148276668202cd0158016df83505	refs/heads/main
f4fd0dd1010e148276668202cd0158016df83505	refs/tags/v1.0.0
```

**This proves** GitHub's copy has your commit on `main` and under the tag `v1.0.0`, and that anybody can read it without logging in (this command sends no login).

### Step 1.15 — Print the commit hash for the manager

**Do**

```
git -C ~/wom-first-publish/wom-test-hello-world rev-parse HEAD
```

**You should see**

One line of exactly 40 characters (digits 0-9 and letters a-f), for example:

```
f4fd0dd1010e148276668202cd0158016df83505
```

**This proves** you have the value the registry entry in Part 2 needs. **Send that one line to the manager** with the words "M4 part 1 done". The hash is public information; it is not a secret.

### Step 1.16 — Switch back to the project account (always do this)

[NOT REHEARSED]

**Do**

```
gh auth switch --user womcraft
gh auth status
```

**You should see**

[UNVERIFIED — expected, not observed] `gh auth status` lists the same two accounts, with `womcraft` marked active again.

**This proves** the machine is back in the state all project work expects (all project GitHub work runs as `womcraft`). End of Part 1.

---

## Part 2 — Open the registry pull request

**Needs:** Part 1 finished, and the membership of `mbmludric` in the organisation `worldofmodcraft` (task step M6, recorded
as done on 2026-10-26). The namespace `test` is reserved; the registry accepts a change there only from an organisation
member (ADR-0119). The file steps (2.3) were rehearsed on disk; everything that talks to GitHub was not.

### Step 2.1 — Switch to your own GitHub account

[NOT REHEARSED]

**Do**

```
gh auth switch --user mbmludric
gh auth status
```

**You should see**

[UNVERIFIED — expected, not observed] `mbmludric` marked active in the list of accounts.

**This proves** the fork and the pull request below are made by `mbmludric`. Start of the part that **must** end with step 2.5.

### Step 2.2 — Make your own copy (a fork) of the registry

[NOT REHEARSED]

**Do**

```
cd ~/wom-first-publish
gh repo fork worldofmodcraft/registry --clone
```

**You should see**

[UNVERIFIED — expected, not observed] Lines saying that the fork `mbmludric/registry` was created and cloned, and a new folder `~/wom-first-publish/registry`.

**This proves** you have a copy of the registry you may push to. (Your account only has read access to the organisation's own repository, so this is the supported way, see `CONTRIBUTING.md` in the registry.)

### Step 2.3 — Add the two registry files and fill in the commit hash

**Do**

```
cd ~/wom-first-publish/registry
git fetch https://github.com/worldofmodcraft/registry main
git switch -c add-test-hello-world FETCH_HEAD
mkdir -p mods/test.hello-world
git -C ~/wom archive origin/main docs/test-mod/registry-pr | tar -x -C mods/test.hello-world --strip-components=3
ls mods/test.hello-world
grep -n "commit\|source_url" mods/test.hello-world/entry.json
python3 ~/wom-first-publish/fill_placeholders.py entry --account mbmludric --commit "$(git -C ~/wom-first-publish/wom-test-hello-world rev-parse HEAD)" --file mods/test.hello-world/entry.json
grep -n "commit\|source_url" mods/test.hello-world/entry.json
```

**You should see**

Your terminal prints, in order (the rehearsal ran against a copy of the registry on disk, so the `From` line differs and
the hash is the rehearsal's):

```
Switched to a new branch 'add-test-hello-world'
entry.json
page.json
11:      "commit": "0000000000000000000000000000000000000000",
12:      "source_url": "https://github.com/OWNER-PLACEHOLDER/wom-test-hello-world",
filled mods/test.hello-world/entry.json
11:      "commit": "f4fd0dd1010e148276668202cd0158016df83505",
12:      "source_url": "https://github.com/mbmludric/wom-test-hello-world",
```

The `From` and `* branch main -> FETCH_HEAD` lines of `git fetch` come before these, and they differ on GitHub. Your last hash must equal the hash from step 1.15.

**This proves** the registry entry for `test:hello-world` version `1.0.0` now names your repository and your exact commit, with no placeholder left (the fill script checks that itself and refuses otherwise).

### Step 2.4 — Commit and push the branch to your fork

[NOT REHEARSED] The push goes to GitHub. It was rehearsed against a folder on disk.

**Do**

```
cd ~/wom-first-publish/registry
git config user.name "mbmludric"
git config user.email "37807560+mbmludric@users.noreply.github.com"
git add mods/test.hello-world
git status --short
git commit -m "Add test:hello-world 1.0.0 (pipeline canary)"
git push -u origin add-test-hello-world
```

**You should see**

[UNVERIFIED — expected, not observed] Against GitHub the same as the rehearsal, with the `To` line naming your fork. The rehearsal printed (hash and address differ for you):

```
A  mods/test.hello-world/entry.json
A  mods/test.hello-world/page.json
[add-test-hello-world c9d21d2] Add test:hello-world 1.0.0 (pipeline canary)
 2 files changed, 30 insertions(+)
 create mode 100644 mods/test.hello-world/entry.json
 create mode 100644 mods/test.hello-world/page.json
To /tmp/r010b-home-Q52ad5/remote/registry-fork.git
   428df02..c9d21d2  add-test-hello-world -> add-test-hello-world
branch 'add-test-hello-world' set up to track 'origin/add-test-hello-world'.
```

**This proves** the pull request will contain exactly two new files, both under `mods/test.hello-world/`, and nothing else (the registry rejects a mix with other paths).

### Step 2.5 — Open the pull request, then switch back

[NOT REHEARSED]

**Do**

```
cd ~/wom-first-publish/registry
gh pr create --repo worldofmodcraft/registry --base main --head mbmludric:add-test-hello-world --title "Add test:hello-world 1.0.0" --body "First publish of the pipeline canary mod test:hello-world, version 1.0.0. Runbook: docs/runbooks/first-publish.md in the platform repository."
gh auth switch --user womcraft
gh auth status
```

**You should see**

[UNVERIFIED — expected, not observed] The address of the new pull request, of the form `https://github.com/worldofmodcraft/registry/pull/` followed by a number. Then `gh auth status` showing `womcraft` active.

**This proves** the pull request is open and the machine is back on the project account. Send the pull request address to the manager.

### Step 2.6 — Read the check named `gate`

[NOT REHEARSED] The check runs on GitHub only.

**Do**

Open the pull request address from step 2.5 in your browser. Scroll to the bottom and wait for the check named **gate** to finish. Read the comment the bot posts.

**You should see**

[UNVERIFIED — expected, not observed] A comment from the check, followed by a green mark on `gate`. Per `CONTRIBUTING.md`, the comment reports four checkers (kind of change, entry schema, append-only rules, ownership) and a green `gate` means "the automatic checks pass", never "approved". If a rule rejects the change, the comment names the rule and says how to fix it.

**This proves** the registry's own rules accept the entry, including that the author is a member of the organisation (ADR-0119 section 3). If `gate` is red or "could not decide", do not edit anything: copy the comment text to the manager.

### Step 2.7 — Hand the merge to the manager

**Do**

Tell the manager "gate is green" (or red, with the text). Do not click **Merge** yourself.

**You should see**

[UNVERIFIED — expected, not observed] The manager answers that the pull request is merged. In the browser the pull request page shows the purple "Merged" label.

**This proves** a human decision (the manager's) stands between a green check and a published mod (`CONTRIBUTING.md`: "A maintainer merges").

---

## Part 3 — Watch the pipeline publish it

**Needs:** Part 2 merged. Every step in this part is [NOT REHEARSED]: it needs the real registry, the pipeline and the
write-back pull request, and the write-back half is not built yet (task 008b-3b). These steps are placeholders for what
task 010c will re-rehearse. No command in this part needs a GitHub account switch.

### Step 3.1 — Watch the pipeline run

[NOT REHEARSED] Write-back is task 008b-3b.

**Do**

Open `https://github.com/worldofmodcraft/registry/actions` in your browser and open the newest run named **pipeline**.

**You should see**

[UNVERIFIED — expected, not observed] A run for the merge of your pull request that finishes with a green mark. If it is red, copy the address of the run to the manager.

**This proves** the pipeline picked up the merged entry and built the commit from step 1.9.

### Step 3.2 — Find the archive Release

[NOT REHEARSED] Write-back is task 008b-3b.

**Do**

Open `https://github.com/worldofmodcraft/archive/releases` in your browser.

**You should see**

[UNVERIFIED — expected, not observed] A Release for `test:hello-world` version `1.0.0` with a source archive attached.

**This proves** the project's own copy of the source exists, so the registry no longer depends on your repository.

### Step 3.3 — Find the write-back pull request

[NOT REHEARSED] Write-back is task 008b-3b.

**Do**

Open `https://github.com/worldofmodcraft/registry/pulls` in your browser.

**You should see**

[UNVERIFIED — expected, not observed] A pull request opened by the pipeline's GitHub App that adds the five result fields (archive address, SHA-256, signature, key id, publish time) to your entry and changes the status from `pending` to `published`. Tell the manager when you see it; the manager merges it.

**This proves** the pipeline wrote its result back through the registry's normal pull-request path (ADR-0121).

---

## Part 4 — Check the mod page, then change it with a `page.json` pull request

**Needs:** Part 3 finished and the site rebuilt. **Wait up to ten minutes after any deployment** before judging a page: GitHub
Pages answers can lag by up to ten minutes (`docs/manager/OPERATIONS.md`, Pages section), so an old page does not mean it failed.

### Step 4.1 — Open the mod page

[NOT REHEARSED] The site shows published mods only after write-back (task 008b-3b).

**Do**

Open `https://worldofmodcraft.com/mods/test/hello-world` in your browser.

**You should see**

[UNVERIFIED — expected, not observed] The mod's description, its rendered README, the screenshot gallery, tags, the licence, version 1.0.0 with its commit hash and a link to the archived source, and the install button (the launcher is "coming soon") — the items mission criterion 7.4 lists.

**This proves** the site renders the registry and the archive. Tell the manager which of these you can and cannot see.

### Step 4.2 — Prepare the page change

The change adds one sentence to the description and adds the spare screenshot, which was shipped inside the 1.0.0 archive for this purpose.

[NOT REHEARSED] Needs the merged registry. The edit itself was rehearsed on disk.

**Do**

```
gh auth switch --user mbmludric
cd ~/wom-first-publish/registry
git fetch https://github.com/worldofmodcraft/registry main
git switch -c page-json-update FETCH_HEAD
python3 -I - <<'PY'
import json
p = "mods/test.hello-world/page.json"
d = json.load(open(p))
d["description"] = d["description"] + " Updated to prove that a page change publishes without a new version."
d["screenshots"].append("assets/screenshots/spare.png")
with open(p, "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")
PY
git diff --stat
git diff | grep "^[+-] "
```

**You should see**

After the switch, the `git diff --stat` shows one file and 3 insertions and 2 deletions, and the `git diff` filter shows one changed description line and one added screenshot line (rehearsal on disk):

```
 mods/test.hello-world/page.json | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)
-  "description": "The permanent pipeline canary: a mod with no code whose only job is to prove that publishing works end to end, from a git tag to a signed archive and this page.",
+  "description": "The permanent pipeline canary: a mod with no code whose only job is to prove that publishing works end to end, from a git tag to a signed archive and this page. Updated to prove that a page change publishes without a new version.",
-    "assets/screenshots/gallery.png"
+    "assets/screenshots/gallery.png",
+    "assets/screenshots/spare.png"
```

**This proves** only `page.json` changed. A pull request that touches only `page.json` is allowed for the mod's owner and starts no build (`CONTRIBUTING.md`).

### Step 4.3 — Commit, push, open the pull request, switch back

[NOT REHEARSED]

**Do**

```
cd ~/wom-first-publish/registry
git add mods/test.hello-world/page.json
git commit -m "Update test:hello-world page: description and spare screenshot"
git push -u origin page-json-update
gh pr create --repo worldofmodcraft/registry --base main --head mbmludric:page-json-update --title "Update test:hello-world page" --body "Page change only: longer description and one more screenshot. No new version."
gh auth switch --user womcraft
gh auth status
```

**You should see**

[UNVERIFIED — expected, not observed] A pull request address, then `womcraft` marked active. In the browser, `gate` turns green, listing the change as page-only. Send the address to the manager, who merges it.

**This proves** the page change travels through the same gate, and the machine is back on the project account.

### Step 4.4 — See the changed page, with no new version

[NOT REHEARSED]

**Do**

After the manager says the pull request is merged, wait ten minutes, then open `https://worldofmodcraft.com/mods/test/hello-world` again.

**You should see**

[UNVERIFIED — expected, not observed] The longer description and three screenshots instead of two. The version list still shows only 1.0.0.

**This proves** a page change updates the live page without a new version (mission criterion 7.5).

---

## Part 5 — Optional: watch the gates refuse

Not needed for the publish. These are the "negative checks" of mission criterion 7.1; they belong to task 039 and are
written here for later.

### Step 5.1 — Ask GitHub what an outsider sees (no login, no switch)

**Do**

```
curl -s -o /dev/null -w "status=%{http_code} redirect=%{redirect_url}\n" https://api.github.com/orgs/worldofmodcraft/members/womcraft
```

**You should see**

```
status=302 redirect=https://api.github.com/organizations/324218296/public_members/womcraft
```

(Observed 2026-11-04.)

**This proves** how an anonymous caller sees the organisation's member list: `302` means "you are not allowed to see", not "not a member". The registry check therefore asks with the pull request author's own standing and treats "cannot tell" as a refusal (ADR-0119).

### Step 5.2 — Try a pull request the gate must refuse

[NOT REHEARSED] Needs the real registry and a second GitHub account that is not a member; no such account exists in this runbook.

**Do**

Nothing yet. The manager will give exact steps when task 039's negative checks are scheduled.

**You should see**

[UNVERIFIED — expected, not observed] A red `gate` with a comment naming the rule that refused.

**This proves** nothing yet; it is a placeholder so that the optional negative checks have a place here.
