# ADR-0001: The platform is the goal; the roguelike is the first mod

- **Status:** Accepted
- **Date:** 2026-08-31
- **Area:** Vision
- **Related:** ADR-0002, ADR-0044, ADR-0050

## Context
The project began as a roguelike / Vampire Survivors-style WoW server on AzerothCore. During brainstorming it became clear that the desired outcome is a general modding platform for WoW ("Forge/Fabric for Minecraft", "Skyrim modding for WoW"), where the roguelike is one of many possible experiences.

## Options considered
- A. Keep the roguelike server as the goal; add modding as a convenience layer.
- B. Make the platform the goal; the roguelike becomes the first mod/modpack built on it.

## Decision
**B.** World of Modcraft is the product. The roguelike is the first modpack and the reference implementation that drives the kernel API from real needs.

## Consequences
- The existing roguelike design kit (21 locked decisions, 18 design documents) becomes the specification of the first mod, not of the platform.
- The platform must never be built "in the abstract"; every kernel feature must be pulled by a real mod need (see ADR-0050).

## Interacts with
- ADR-0002 (audience), ADR-0050 (build order), ADR-0044 (modpacks).
