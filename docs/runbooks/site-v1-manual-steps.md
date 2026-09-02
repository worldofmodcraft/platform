# SITE-V1 — the steps only Ludwig can do (mission §6)

Every step says what to click, what to enter, and **what you should see when it worked**.
Do them in order; each one unblocks tasks that cannot start without it.
Nothing here is reversible-by-accident: no step deletes anything.

Status key: ☑ done · ☐ waiting on you · ⏸ waiting on a decision first

---

## ☑ M0 — Register worldofmodcraft.com
Done 2026-09-02, at Cloudflare. (Checked before you said so: the domain was NXDOMAIN — no
nameservers at all — so this genuinely was step zero, and the mission spec assumed it away.)

---

## ☐ M1 — GitHub organisation, repos, Actions permissions
**This is the gate for all implementation work.** Until the repos exist, no agent can start:
every deliverable in this mission lives in `worldofmodcraft/registry` or `worldofmodcraft/site`.
Budget ~15 minutes.

### M1.1 Create the organisation
1. Go to **https://github.com/organizations/plan**
2. Choose **Free**.
3. Organization account name: `worldofmodcraft` — contact email: yours — belongs to **My personal account**.
4. Skip the "invite members" step.

*You should see:* `https://github.com/worldofmodcraft` loads as an organisation page.

### M1.2 Two-factor authentication
ADR-0041 and mission §6.1 say **hardware-key** 2FA on the org account. `START-HERE.md` §1.2 says an
authenticator app is fine. That is a real contradiction between two of your own documents, so I am
not choosing for you — see question **Q1** in the mission log. Do this much now either way:
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

## ☐ M2 — DNS at Cloudflare (do after M1.3; safe to do now)
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

## ⏸ M3 — Signing keypair → Actions secret
**Blocked on decision Q3 (which signature format).** ADR-0041 requires a platform key with a
`key_id` and a written rotation procedure, but never names the algorithm or the tool, and the
choice binds us for years: the kernel and launcher will embed the public key and must verify
these signatures forever. I will give you the exact generation command — a single copy-paste that
never writes the private key to the repo — as soon as you pick. Do not generate a key before then.

---

## ⏸ M4 — The `test:hello-world` repository
**Blocked on decision Q2 (namespace).** The mission calls the test mod `test:hello-world`, but
ADR-0030 and ADR-0039 say a namespace **is** the owner's GitHub username. `test` is nobody's
username, so as written the mission asks the registry CI to accept something its own ownership
rule must reject. I will prepare the complete repository contents — manifest, README, licence,
original placeholder screenshots — for you to push once the namespace is settled.

---

## After M1: what starts immediately
M1 alone unblocks Task 002 (the asset scanner) and the contracts task. Neither needs the domain,
the key, or the test mod — so the moment the two repos exist, work begins in parallel with your
remaining steps.
