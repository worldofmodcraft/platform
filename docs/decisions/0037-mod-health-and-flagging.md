# ADR-0037: Mod health panels, conflict detection and flagging

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Site / Telemetry
- **Related:** ADR-0011, ADR-0036, ADR-0042

## Decision
Each mod **version** gets a health panel: active sessions, crash rate per hour played, error rate, leak rate, share of sessions with budget overruns — all normalised by usage. Thresholds produce badges ("Stable", "Issues reported", "Crashes often"). Authors see the same panel plus grouped error signatures (free crash reporting as the incentive to encourage opt-in).

Attribution is computed **per mod and per mod pair**; combinations that correlate with problems become **site-level conflict notes** ("housing 1.x + hardmode <2.0 — known conflict, 340 sessions") shown on both mods and read by the launcher/load-order tool; authors may confirm and copy them into their manifests.

Safeguards: compare against the baseline for the same kernel version; never flag below a minimum session count.

**Flagging = all three:** badge on the mod page, notification to the author, warning in the launcher before install. **Never automatic unpublishing.** Always transparent about why.

Update dialogs may show version-comparative health ("1.3.0: crash rate 4× higher than 1.2.0 so far").
