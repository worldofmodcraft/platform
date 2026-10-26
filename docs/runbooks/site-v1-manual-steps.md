# SITE-V1 — the steps only Ludwig can do (mission §6)

Every step says what to click, what to enter, and **what you should see when it worked**.
Do them in order; each one unblocks tasks that cannot start without it.
Nothing here is reversible-by-accident: no step deletes anything.

Status key: ☑ done · ☐ waiting on you · ⏸ waiting on a decision first · `[unverified]` = no evidence
found; check it yourself.
**Last reviewed: 2026-10-15 (task 068).** M8 added 2026-10-18 (task 077). Evidence for the markers as of task 060 is in
`docs/tasks/060-runbook-manual-steps.md`, section "Task 060 log". Markers M3, M5, M7 and Q-H were updated by task 068
for Ludwig's manual steps of 2026-10-15; the new evidence is in `docs/tasks/068-runbook-markers-session9.md`, section
"Task 068 log".
**Rule for every step below: you never copy or paste a secret into chat, a file or an issue. Where a
step handles a secret, it goes from GitHub's own page straight into GitHub's own form.**

---

## ☑ M0 — Register worldofmodcraft.com
Done 2026-09-02, at Cloudflare (re-checked 2026-10-15: the domain's nameservers are Cloudflare's). (Checked before you said so: the domain was NXDOMAIN — no
nameservers at all — so this genuinely was step zero, and the mission spec assumed it away.)

---

## ☑ M1 — GitHub organisation, repos, Actions permissions
**This is the gate for all implementation work.** Until the repos exist, no agent can start:
every deliverable in this mission lives in `worldofmodcraft/registry` or `worldofmodcraft/site`.
Budget ~15 minutes.
**Status:** organisation, `registry` and `site` exist (checked 2026-10-15). Two-factor and Actions permissions
are `[unverified]` by us (they are private settings); `docs/manager/OPERATIONS.md` records the org and repos as
"done and verified".

### M1.1 Create the organisation
1. Go to **https://github.com/organizations/plan**
2. Choose **Free**.
3. Organization account name: `worldofmodcraft` — contact email: yours — belongs to **My personal account**.
4. Skip the "invite members" step.

*You should see:* `https://github.com/worldofmodcraft` loads as an organisation page.

### M1.2 Two-factor authentication  — decided: Q1=A
Authenticator app now; a **hardware key is required before the first non-test publish** (booked as
a task, not forgotten). Until then the only thing the key protects is a canary mod.
1. **https://github.com/settings/security** → enable 2FA on your personal account if it is not on.
2. Org → **Settings → Authentication security** → tick **Require two-factor authentication for
   everyone in the worldofmodcraft organization** → Save.

*You should see:* a green "Two-factor authentication is required" banner in that settings panel.

### M1.3 Create the two repositories
At **https://github.com/organizations/worldofmodcraft/repositories/new**, twice:
1. Name `registry` — **Public** — **do not** tick "Add a README", `.gitignore` or a licence.
2. Name `site` — **Public** — same: no initialisation.

They must be empty: the mission pushes a prepared tree into them, and an auto-created README
causes a merge conflict on the very first push.

*You should see:* both repos showing GitHub's "Quick setup — we recommend every repository include a README" empty-repo screen.

### M1.4 Actions permissions (on `registry`)
Repo → **Settings → Actions → General**:
1. **Actions permissions**: "Allow all actions and reusable workflows".
2. **Workflow permissions**: **Read and write permissions** — the pipeline writes the archive
   hash and signature back into the registry entry, and creates the release that stores the
   source tarball. Without this it fails at the last step.
3. **Fork pull request workflows from outside collaborators**: leave at the default
   **"Require approval for first-time contributors"**. This is a security boundary, not a nuisance:
   registry PRs arrive from strangers' forks and run our workflow files.

Repeat 1 and 2 on `site`.

*You should see:* the "Read and write permissions" radio selected on both repos after saving.

---

## ☑ M2 — DNS at Cloudflare
**Done.** Checked 2026-10-15: four A records and the `www` CNAME resolve as listed below, no CAA records exist, and
`https://worldofmodcraft.com` answers HTTP 200 from GitHub Pages. The text below is kept as the record of what was set.
Cloudflare dashboard → select **worldofmodcraft.com** → **DNS → Records**.

Add these **four A records**, each with **Proxy status: DNS only** (click the orange cloud so it
turns grey), TTL Auto. IPs verified against GitHub's official DNS documentation today:

| Type | Name | Content | Proxy |
|---|---|---|---|
| A | `@` | `185.199.108.153` | DNS only |
| A | `@` | `185.199.109.153` | DNS only |
| A | `@` | `185.199.110.153` | DNS only |
| A | `@` | `185.199.111.153` | DNS only |

Optionally also the four IPv6 records (same name `@`, DNS only):
`2606:50c0:8000::153`, `2606:50c0:8001::153`, `2606:50c0:8002::153`, `2606:50c0:8003::153`

And one CNAME so `www` works:

| Type | Name | Target | Proxy |
|---|---|---|---|
| CNAME | `www` | `worldofmodcraft.github.io` | DNS only |

**Why DNS only (grey cloud), explicitly:** GitHub's documentation does not mention Cloudflare
proxying at all — I checked, rather than assuming. Their documented HTTPS flow assumes the name
resolves straight to GitHub Pages so Let's Encrypt can validate it. Proxied (orange cloud) is a
configuration nobody has verified for us, and its classic failure is a redirect loop between
Cloudflare "Flexible" SSL and GitHub's "Enforce HTTPS". Start DNS-only; if you later want
Cloudflare caching in front, we turn it on deliberately and test it as its own change.

**One Cloudflare setting to check:** SSL/TLS → Overview → set **Full (strict)**. It is irrelevant
while the records are DNS-only, and it is the correct value the moment anything becomes proxied.

**CAA records:** GitHub documents that *if* any CAA record exists, at least one must permit
`letsencrypt.org`, or HTTPS will never provision. Cloudflare does not add CAA records by default.
Check DNS → Records for type CAA: if there are none, you are fine and do nothing.

*You should see:* after saving, `https://cloudflare-dns.com/dns-query?name=worldofmodcraft.com&type=A`
returns the four addresses. Tell me when the records are in and I will verify the resolution from here.

---

## ☑ M3 — Signing keypair → Actions secret  — decided: Q3=A (minisign, Ed25519)
**Status: done.** Keypair made (key id `6E5B30596A7A8CC4`, OPERATIONS.md); the `MINISIGN_SECRET_KEY` Actions secret
existed on 2026-09-05 (Ludwig; checked then with `gh secret list`, mission log "M3 is DONE") and Ludwig re-confirmed on
2026-10-15 that it is listed (Q-H below). Do not redo this step. His offline backup of the private key is unconfirmed.
Every command below is one I ran end-to-end against minisign 0.12 before writing it here: I
generated a throwaway key, signed a file, verified it, tampered with the file, confirmed
verification fails with exit code 1, then destroyed the throwaway key.

**Run these in your WSL terminal, in a directory that is NOT a git repository** — for example
`cd ~` first. The private key must never sit inside a repo.

```bash
# 1. Get minisign (no sudo, no install — a single static binary)
cd ~ && curl -fsSL -o minisign.tar.gz \
  https://github.com/jedisct1/minisign/releases/download/0.12/minisign-0.12-linux.tar.gz
tar -xzf minisign.tar.gz && cp minisign-linux/x86_64/minisign ~/.local/bin/ && rm -rf minisign-linux minisign.tar.gz
minisign -v          # should print: minisign 0.12

# 2. Generate the platform keypair, unencrypted so CI can use it unattended
mkdir -p ~/wom-keys && cd ~/wom-keys
minisign -G -W -p worldofmodcraft.pub -s worldofmodcraft.key

# 3. Show the PUBLIC key (safe to share — this goes in docs and later into the kernel)
cat worldofmodcraft.pub
```

The public key's comment line ends in 16 hex characters — that is the **`key_id`** ADR-0041
requires for rotation. Paste the whole `worldofmodcraft.pub` output to me and I will record it in
the docs and the pipeline; it is public by design.

**Then add the private key to Actions secrets** — this is the one value that must never be pasted
into our chat, a file in a repo, or a CI log:
```bash
cat ~/wom-keys/worldofmodcraft.key    # copy this entire output to your clipboard
```
1. Go to `https://github.com/worldofmodcraft/registry/settings/secrets/actions`
2. **New repository secret** → Name: `MINISIGN_SECRET_KEY` → Secret: paste → **Add secret**.
3. Back up `~/wom-keys/worldofmodcraft.key` somewhere offline (password manager or a USB stick).
   If you lose it, every future release needs a new key and a kernel update to trust it.

*You should see:* `MINISIGN_SECRET_KEY` listed under "Repository secrets", showing only the name —
GitHub never displays the value again, which is correct.

**Note:** the secret key file's first line says "minisign encrypted secret key" even with `-W`.
That comment is static text in the format; the key genuinely has no password. Treat the file as
the crown jewels regardless.

---

## ☐ M4 — The `test:hello-world` repository  — decided: Q2=A (`test` is a reserved namespace)
**Status: not done.** `https://github.com/mbmludric/hello-world` returns 404 (checked 2026-10-15), and the staging
files from task 010 are not in the repo yet. **Waiting on task 010.** Do not create the repo yet: task 010 will give
you a tree to push and exact commands (`docs/runbooks/first-publish.md`).
ADR-0119 reserves `mc` and `test` as organisation-owned namespaces, so `test:hello-world` is legal. The URL stays
`worldofmodcraft.com/mods/test/hello-world`. The repo is created under your personal account `mbmludric`, **after M6**.

---

## ☑ M5 — Create the organisation's GitHub App  (decision Q-D, Ludwig 2026-10-14)
**Why:** the build pipeline must open and merge the write-back pull request and notify the site. Pull requests made with
the built-in token do not start other workflows; ones made by an App do. **When:** task 008b's live checks wait for this
(and for M7). **Status: done (Ludwig, 2026-10-15).** The App `worldofmodcraft-pipeline` is created under the organisation, installed
on `registry`, `site` and `archive`, and its key and App ID are stored as registry Actions secrets (step 9). Its public
page `https://github.com/apps/worldofmodcraft-pipeline` answers HTTP 200 (unauthenticated check, 2026-10-15). The steps
below are kept as the record.
All click-paths in M5–M7 are `[unverified — check on screen]`: if a screen differs from the text, follow the screen
and tell the manager what differed. Do M7 first if you can, so the App can be installed on `archive` in step 8.

1. Open `https://github.com/organizations/worldofmodcraft/settings/apps/new`
   (or: github.com → your profile picture → Your organizations → worldofmodcraft → Settings → Developer settings →
   GitHub Apps → New GitHub App).
2. GitHub App name: `worldofmodcraft-pipeline` (if taken, add a suffix and tell the manager the final name).
   Homepage URL: `https://worldofmodcraft.com`.
3. Webhook: untick **Active**.
4. Repository permissions, exactly these and nothing else: **Contents: Read and write**, **Pull requests: Read and
   write**. ("Metadata: Read-only" appears by itself.)
5. Where can this GitHub App be installed: **Only on this account**.
6. Click **Create GitHub App**. On the page that opens, write down the **App ID** (a number; it is not a secret).
7. On the same page, under **Private keys**, click **Generate a private key**. A `.pem` file downloads. **This file is
   a secret. Do not open it, copy its text, or send it to anyone.**
8. Left menu **Install App** → next to worldofmodcraft click **Install** → **Only select repositories** → pick
   `registry`, `site` and `archive` → **Install**.
9. Store the key in GitHub, on `registry`: open `https://github.com/worldofmodcraft/registry/settings/secrets/actions`.
   - **New repository secret** → Name `PIPELINE_APP_PRIVATE_KEY` → for the value, open the `.pem` file in Notepad,
     select all, copy, paste into the Secret box, **Add secret**. This is the only place the text goes.
   - Then open the **Variables** tab → **New repository variable** → Name `PIPELINE_APP_ID` → Value: the App ID
     from step 6 → **Add variable**.
10. Keep the `.pem` file offline next to your minisign key backup, or delete it. If it is lost, generate a new key on the
    App's page.
11. Tell the manager only the App's name (its public page is `https://github.com/apps/<name>`).

*You should see:* the App under organisation → Settings → GitHub Apps with "Installed on 3 repositories", and the
secret name and variable name on registry's Actions secrets page (values are never shown).

---

## ☐ M6 — Your personal account joins the organisation  (decision Q-F, Ludwig 2026-10-14)
**Why:** `test` is a reserved namespace and ADR-0119 §3 accepts a pull request there only from an organisation member;
task 010 plans to open the first-publish PR from `mbmludric`. **When:** before M4 and task 010's runbook.
**Status:** not done — `mbmludric` is documented as a non-member (OPERATIONS.md), and the organisation's public people
page (2026-10-15) lists 1 member, not `mbmludric`. Private members are invisible to us, so this is `[unverified]`.

1. Sign in to github.com as the account that **owns** the organisation. (Which account is the owner is
   `[unverified]`; if unsure, try `mbmludric` first, then your other account.)
2. Open `https://github.com/orgs/worldofmodcraft/people` → **Invite member** → type `mbmludric` → role **Member** →
   send the invitation.
3. Sign in as `mbmludric`, open `https://github.com/orgs/worldofmodcraft/invitation` → **Join worldofmodcraft**.
   The organisation requires two-factor (M1.2); `mbmludric` must have it on at `https://github.com/settings/security`
   or the join is refused.
4. Optional: on the people page, find your own row and set visibility to **Public**. (Whether our checks can see a
   private membership is `[unverified]`; they refuse when they cannot see.)
5. Open organisation → Settings → Member privileges and read what **Base permissions** says. Tell the manager the value.

*You should see:* the people page listing `mbmludric` as Member.

---

## ☑ M7 — Create the `archive` repository  (decision Q-E, Ludwig 2026-10-14)
**Why:** published source tarballs and signatures are stored as Releases in a separate repo. **When:** before task 008b's
live checks (criterion 6). **Status: done (Ludwig, 2026-10-15).** `https://github.com/worldofmodcraft/archive` is public with one commit; an
unauthenticated request answers HTTP 200 (2026-10-15).

1. Open `https://github.com/organizations/worldofmodcraft/repositories/new`
2. Name `archive`. Description `Source tarballs and signatures for published mods`. Visibility **Public**.
3. This time **do tick "Add a README file"** (unlike M1.3). Reason, `[unverified]`: a release needs a commit to point at.
4. No `.gitignore`, no licence. Click **Create repository**.

*You should see:* `https://github.com/worldofmodcraft/archive` with one commit and a README.

---

## ☑ M8 — Protect the archive's Releases and tags  (removal policy item 6, Ludwig 2026-10-17)
**Why:** a published version stays published (ADR-0041, Archiving). If an author's repository is taken down, we stop
serving it publicly but keep the record, so the copy in `archive` must not be deleted by accident. **When:** any time
before the first real publish; the sooner the better. **Status:** done 2026-10-25 by Ludwig (task 081): ruleset `archive-tags-permanent` active on
all tags with Restrict deletions, Restrict updates and Block force pushes (GitHub's default, kept); release immutability
ticked (Ludwig's word; not visible without login). Rulesets did work on the Free plan for this public repository. Every click-path below was taken from GitHub's
documentation on 2026-10-18 (URLs in `docs/tasks/077-runbook-archive-protection.md`, log); if a screen differs from the
text, follow the screen and tell the manager what differed.

**What GitHub offers, and what it does not.** There is **no setting that stops a Release from being deleted.** GitHub's
documentation describes deleting a release (trash icon, "Delete this release") and names no protection against it.
The closest protection is two settings that protect the *tag* and the *files* of a release:
- **Immutable releases** (repository setting): once a release is published, its tag cannot be moved or deleted while the
  release exists, and its attached files cannot be changed or deleted. It does **not** stop someone deleting the release
  itself; after that the tag can be deleted, but the same tag name can never be used again. It applies only to releases
  published after you switch it on. Title and notes can still be edited.
- **Tag ruleset** with *Restrict deletions* and *Restrict updates*: only people on the ruleset's bypass list can delete or
  move tags matching the pattern. It does **not** touch the Release page itself.

`archive` has no releases yet (checked 2026-10-18), so immutability will cover every release published from now on.
Together they mean a published version's tag and files survive, but a Release entry can still be deleted by someone with
permission. Whether the organisation owner can bypass immutable releases is not stated in the documentation
(`[unverified]`); for the ruleset, only actors on the bypass list can, so leave that list empty.

1. Open `https://github.com/worldofmodcraft/archive` → **Settings** (if you cannot see it, click the **...** More menu,
   then **Settings**).
2. Scroll down to the **Releases** section and tick **Enable release immutability**.
3. Left sidebar, under "Code, planning, and automation": click **Rulesets**, then **Rulesets** again, then **New ruleset**,
   then **New tag ruleset**.
4. Ruleset name: `archive-tags-permanent`. Enforcement status: **Active**.
5. Leave the **Bypass list** empty (do not click Add bypass).
6. Under **Target tags** click **Add a target** and choose to include all tags (pattern `*` if the screen asks for a
   pattern). The documentation page does not name the menu choices (`[unverified]`); if the screen differs from this,
   stop and ask the manager.
7. Under **Tag protections** tick **Restrict deletions** and **Restrict updates**. Do not tick anything else
   (creation must stay allowed: the pipeline creates the tags when it publishes a Release).
8. Click **Create**.

*You should see:* on `https://github.com/worldofmodcraft/archive/settings/rulesets` the ruleset `archive-tags-permanent`
listed as Active; on the Settings page the **Enable release immutability** box ticked. These are screens you reach with
your normal browser login; no token and no terminal. Do not delete a tag or Release to "test" it. The documentation says
rulesets are available "for customers on GitHub Team and GitHub Enterprise plans" and does not mention the Free plan or
public repositories (`[unverified]` whether they work on Free; `archive` is public, checked 2026-10-18). If the Rulesets
menu is missing or says the feature needs a paid plan, stop and tell the manager.

---

## ☐ M12 — Archive download address (Cloudflare redirect)  (decision C, Ludwig 2026-10-26; task 091)
**Why:** the registry stores one download URL per published version, and that record is append-only. A URL on a domain we
control can be pointed somewhere else later; a `github.com` URL cannot (task 058, option C). So `archive.worldofmodcraft.com`
answers every request with an HTTP redirect to the matching file in the `archive` repository's Releases.
**When:** before the first real publish (task 008a's URL function writes this address). **Status:** not done. Last reviewed:
2026-10-26 (task 091). Every Cloudflare fact below was read on 2026-10-26 from developers.cloudflare.com (URLs in
`docs/tasks/091-runbook-m12-archive-redirect.md`, log); a statement marked `[unverified]` was not found there. If a screen
differs from the text, follow the screen and tell the manager what differed. No terminal, no token; you are in the Cloudflare
dashboard with your normal login.

**What this does.** A request for `https://archive.worldofmodcraft.com/<tag>/<file>` gets a redirect response from Cloudflare
with `Location: https://github.com/worldofmodcraft/archive/releases/download/<tag>/<file>`. Cloudflare answers by itself; the
hostname has no server behind it. Cloudflare's documentation says redirects "require that you proxy the DNS records of your
domain (or subdomain) through Cloudflare", so the DNS record below is **proxied (orange cloud)**. This is a different record
from the grey-cloud records in M2 and does not change them: `worldofmodcraft.com` and `www` stay DNS only.
Plan: Cloudflare states Single Redirects are available on all plans, and the Free plan allows 10 Single Redirects rules per
zone; this uses one. Wildcard matching, which `wildcard_replace` below is part of, is available on all plans (regular expressions are not on Free; not used here).

**Status code: 302.** A 301 is stored as permanent by browsers and other clients, so repointing the address later (the
reason for this step) would not reach clients that already saw it; a 302 is re-checked each time.

### Step 1 — the DNS record (proxied)
1. Cloudflare dashboard → select **worldofmodcraft.com** → **DNS → Records** → **Add record**.
2. Type **AAAA**; Name `archive`; IPv6 address `100::`; **Proxy status: Proxied** (orange cloud); TTL stays Auto
   (Cloudflare fixes proxied records at 300 seconds). Click **Save**.
   `100::` is a reserved address that routes nowhere: Cloudflare's documentation names `100::` (IPv6) and `192.0.2.0` (IPv4) as
   the placeholder for a hostname that only redirects, usable with Redirect Rules. Nothing is ever fetched from it.
   (The Name/address field labels are not spelled out in the documentation, `[unverified]`; the screen will show them.)
3. Skip this step if, in Step 2, the dashboard offers to create the proxied record for `archive.worldofmodcraft.com` itself
   and you accept it; the result must be the same: a proxied record named `archive`.

### Step 2 — the redirect rule
Use **Custom filter expression**, not **Wildcard pattern**: Cloudflare's wildcard Request URL is matched against the full
address including the query, so its `${2}` would carry `?x=1` along. The expression below works on the path only, so the
query is dropped deterministically.
1. Cloudflare dashboard → **worldofmodcraft.com** → the **Rules** **Overview** page → **Create rule** → **Redirect Rule**.
   (Optional template screen: ignore it.)
2. **Rule name:** `archive-to-github-releases`.
3. Under **When incoming requests match…** choose **Custom filter expression**. Click **Edit expression** (next to the
   Expression Preview) to open the Expression Editor, delete what is there, and enter exactly:
   `http.host eq "archive.worldofmodcraft.com"`
   (You can build the same thing with the drop-downs, field Hostname, operator equals; the Editor text avoids depending on
   the label, which Cloudflare's pages do not spell out, `[unverified]`.)
4. Under **Then…**:
   - **Type:** `Dynamic`
   - **Expression:** `wildcard_replace(http.request.uri.path, "/*", "https://github.com/worldofmodcraft/archive/releases/download/${1}")`
   - **Status code:** `302`
   - **Preserve query string:** leave it **off** (Cloudflare's default is disabled).
5. Click **Deploy** (or **Save as Draft** to stop before it is live).

What the expression does: `http.request.uri.path` is the path only (`/v0/test`), with no query. `wildcard_replace` matches
that whole path against `/*`; `${1}` is the text the `*` matched, `v0/test`, and the result
`https://github.com/worldofmodcraft/archive/releases/download/v0/test` becomes the `Location` header. Because the query is
not part of the source and **Preserve query string** is off, `?x=1` is not carried over. The same call form is in
Cloudflare's own examples (`wildcard_replace(http.request.uri.path, "/*", "/apps/${1}")` on `/calendar` gives
`/apps/calendar`). `http.host eq` matches both `http://` and `https://` requests, so plain HTTP redirects too.
`[unverified]`: the Type/Expression field names in the **Then** box are those of Cloudflare's example pages (Type: Dynamic,
Expression), not of a screenshot of the Free-plan screen.
GitHub tag and asset URLs are case-sensitive (`v0/Test` and `v0/test` are different files). Cloudflare's `wildcard` matching
ignores case, and the documentation does not show whether the text captured by `${1}` keeps the letters exactly as sent
(its examples keep them, `[unverified]` beyond that); the `Test` check below proves it for this rule.

*You should see:* open `https://archive.worldofmodcraft.com/v0/test` in a browser. The address bar changes to
`https://github.com/worldofmodcraft/archive/releases/download/v0/test` and GitHub shows its "Not Found" page (the tag `v0`
does not exist yet; GitHub answers 404 for that address, checked 2026-10-26). Landing on that GitHub address proves the
redirect works; a Cloudflare error page or a browser "site can't be reached" means a step above is missing.
Allow a few minutes after Step 1: Cloudflare's documentation says its free certificates are issued automatically for proxied
hostnames and covers first-level subdomains such as this one, but gives no time, `[unverified]`.

**The manager checks** (unauthenticated, after you say M12 is done; nothing here needs a login):
```
curl -sI https://archive.worldofmodcraft.com/v0/test
curl -sI "https://archive.worldofmodcraft.com/v0/Test?x=1"
curl -sI http://archive.worldofmodcraft.com/v0/test
```
Expected, each: status line `HTTP/2 302` (the third may be `HTTP/1.1 302`), and
`location: https://github.com/worldofmodcraft/archive/releases/download/v0/test` for the first and third;
`location: https://github.com/worldofmodcraft/archive/releases/download/v0/Test` for the second: capital T kept and the
`?x=1` **absent**. If the second shows `v0/test` (case lost) or still carries `?x=1`, the rule is wrong: report it, do not
accept it. The response header `server: cloudflare` shows Cloudflare answered, not GitHub. A 404 from `server: GitHub.com`,
a certificate error, or a `521`/`522` means the record is not proxied or not saved.

**Undo:** delete the rule (Rules → Overview → the rule → delete) and the `archive` DNS record. Nothing else depends on them
until the first publish.

---

## ☑ Q-H — Does the `MINISIGN_SECRET_KEY` secret exist?  (open fact question)
**Answered (Ludwig, 2026-10-15):** "MINISIGN_SECRET_KEY finns" — he looked; nothing was copied. Whether the offline
backup exists was not answered.
**Why:** the pipeline signs with it (task 008b, step 6); M3 was reported done 2026-09-05 but nobody has looked since, and
no agent may check (`gh secret` is forbidden, CLAUDE.md rule 11). **When:** 008b cannot sign without it.
**Look, do not copy: this step only reads names. Do not click any secret, and do not paste or copy any value anywhere.**

1. Open `https://github.com/worldofmodcraft/registry/settings/secrets/actions` while signed in as an organisation owner.
2. Under **Repository secrets**, look for the name `MINISIGN_SECRET_KEY`. GitHub shows only names and dates.
3. Tell the manager one of: "listed" (and its "Updated" date) or "not listed". Do nothing else.
4. If it is **not listed**: tell the manager. Do not redo M3 by yourself; the key id `6E5B30596A7A8CC4` is published, so the
   old private key (the backup at `~/wom-keys/worldofmodcraft.key`) should be re-added rather than a new one made.
   That decision is the manager's and yours together.
5. Also say whether the offline backup of the private key exists (yes/no). Do not open or send the file.

*You should see:* a list of secret names with no values.

---

## After M1: what starts immediately
M1 alone unblocks Task 002 (the asset scanner) and the contracts task. Neither needs the domain,
the key, or the test mod — so the moment the two repos exist, work begins in parallel with your
remaining steps.
