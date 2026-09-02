# START HERE — Evening 0 → first manager session

Everything below runs in your **WSL Ubuntu terminal** unless marked (Web). Total time: ~30–45 min.
If any command fails, paste the error to Claude (claude.ai) — do not improvise.

## 0. Prerequisites (you already have these)
- Windows with WSL Ubuntu, GitHub account, Claude Max subscription.

## 1. GitHub organisation (Web)
1. github.com → top-right **+** → **New organization** → Free plan → name: `worldofmodcraft`.
2. Org **Settings → Authentication security**: require two-factor authentication (enable 2FA
   on your own account first if not already — an authenticator app is fine, per ADR-0041).
3. In the org, create two **empty public** repositories (no README, no license — the mission
   fills them): `registry` and `site`.
   (Public-but-unannounced is deliberate: ADR-0060.)

## 2. Install Claude Code (WSL)
```bash
curl -fsSL https://claude.ai/install.sh | bash
```
If that URL has changed, the current command is always at:
https://docs.claude.com/en/docs/claude-code/setup
(npm alternative: `npm install -g @anthropic-ai/claude-code`)

Then verify and log in:
```bash
claude --version
claude
```
On first run, choose **log in with your Claude account** (your Max subscription — NOT an API
key). Exit with `/exit` after login succeeds.

## 3. Unpack this kit
Put the kit folder at `~/wom` inside WSL (the Linux filesystem, not /mnt/c or /mnt/d — git and
Claude Code are much faster there):
```bash
# if you downloaded the zip to Windows Downloads, adjust the path:
mkdir -p ~/wom && cd ~/wom
unzip /mnt/c/Users/<YourWindowsUser>/Downloads/wom-starter.zip -d ~/wom
ls   # you should see: CLAUDE.md  START-HERE.md  docs/  .claude/
```

## 4. Make it a git repo
```bash
cd ~/wom
git init -b main
git add -A
git commit -m "World of Modcraft: decision log (117 ADRs), manager doctrine, SITE-V1 mission"
```
(Pushing this workspace to GitHub is optional for now; the mission creates and pushes the real
`registry` and `site` repos itself.)

## 5. Install the HUD (inside Claude Code)
```bash
cd ~/wom && claude
```
Then, at the Claude Code prompt:
```
/plugin marketplace add jarrodwatts/claude-hud
/plugin
```
…and install **claude-hud** from the menu if the first command didn't already. Restart when
prompted (`/exit`, then `claude` again). You should see context/agent info under the input.
(Alternative HUD if this one misbehaves: `/plugin marketplace add erwint/claude-code-statusline`.)

## 6. Verify the roster and model
Inside Claude Code:
```
/agents     # should list 10 project agents (surveyor, scaffolder, implementer, core-surgeon,
            # reviewer, qa-engineer, debugger, doc-writer + the two -strong variants)
/model      # pick the strongest available model — the manager runs on it (ROUTING.md)
```

## 7. Kick off the mission
Paste this as your first message:

```
Read CLAUDE.md and follow the session start ritual. Then begin
docs/tasks/MISSION-worldofmodcraft-site-v1.md: draw the mission dependency graph first
(ADR-0117), list the §6 manual steps I need to do with exact instructions, and propose your
first spec-gated tasks. Ask me about anything unclear — when in doubt, ask.
```

## 8. What to expect
- The manager reads the doctrine and mission, presents a plan, and asks you the §6 items
  (domain/DNS for worldofmodcraft.com, signing key, test repo) with step-by-step instructions.
- Every piece of work becomes a spec-approved task file in `docs/tasks/`; agents run in git
  worktrees; you'll see them (with token counts) in the HUD.
- Questions come bundled as `## For Ludwig` lists with A/B/C options and a ★ lean — answer
  with number + letter, like always.
- End of session: the manager writes a status report. A session with no written status did
  not happen.

## If something looks wrong
Say so plainly in the session ("this looks wrong, stop") — the doctrine obliges the manager to
stop and ask rather than push through. For anything Claude Code cannot fix, bring the error to
claude.ai and we debug it together.
