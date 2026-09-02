# ADR-0102: Launcher↔server control — SOAP now, control contract later

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Launcher / Architecture
- **Related:** ADR-0043, ADR-0079, ADR-0112

## Decision
AzerothCore's built-in SOAP endpoint (an early-2000s XML-over-HTTP remote-command interface — old but present, and already proven by the roguelike project's ops scripts) is used by launcher v1 behind an internal interface. The real **kernel control contract** (JSON over local socket, in `contracts/` per ADR-0079: pause, save, status, mod commands, execute_command, graceful shutdown) is written into the IDL and implemented when the kernel builds its RPC machinery; the SOAP path then retires by swapping the implementation behind the interface. No user or mod ever touches SOAP. The web console (ADR-0112) becomes the contract's first consumer.

**Survey bench:** SOAP surface coverage in AC — does it reach pause/save needs or is console injection needed regardless?
