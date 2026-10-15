# Task 066: A pinned, reproducible ajv 8 for the registry's verify scripts

- **Mission:** SITE-V1 (verification reproducibility) — **Status:** draft (booked 2026-10-15; Ludwig chose option A)
- **Repo:** registry. **Agent / model:** to be decided at the spec gate (scaffolder or implementer / sonnet). **Budget:** small

## Objective
`057-verify.sh` (V1) and `062-verify.sh` need ajv 8. Today the only copy on the machine is `/tmp/fc041/node_modules`
(ajv 8.20.0), which a reboot can wipe. After this task the registry has a dev-tools folder with a `package.json` and
lock file pinning ajv to an exact version, a documented `npm ci` command, the verify scripts default to that location
(the env override stays), and a missing install fails with a message naming the command. No ajv enters any checker's
runtime path.
