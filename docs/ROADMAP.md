# Roadmap

Primary target: macOS 26.6 / Mac16,8. Published Personal Release: `v0.1.0`.

States are explicit: **implemented -> automated-tested -> physically accepted -> merged -> released**. Green CI does not substitute for target-Mac acceptance when physical UI, permissions, third-party behavior or resources are part of the contract.

## Completed foundations

- **M0 Engineering Foundation — ACCEPTED / MERGED**.
- **R0.1 Personal Release — ACCEPTED / RELEASED**: immutable `v0.1.0`.
- **P0 Performance Foundation — ACCEPTED / MERGED**.
- **P0.1 Public repository readiness — ACCEPTED**.
- **M1 primary interaction foundation — ACCEPTED / MERGED**; active-display/fullscreen/Spaces/notchless/multi-monitor hardening remains deferred.
- **Regression/UI Automation Foundation — IMPLEMENTED / TESTED / MERGED** via PR #34 as `bd9566f690d314ed40fd6f3723a319291ceb4a58`; post-merge main CI #1053 passed all three canonical jobs.

## M6 — Universal Media / System Now Playing

- **M6.1 transport feasibility — ACCEPTED**.
- **M6.2 production media boundary — ACCEPTED / MERGED**.
- **M6.3 concrete system transport — ACCEPTED / MERGED**.
- **M6.4 shipping composition — ACCEPTED / MERGED**.
- **M6.5 Media-first UI — ACCEPTED / MERGED**.

### M6.6 — gestures, haptics, interactive notch, seek and Hover Peek

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / NOT RELEASED**.

Physical source acceptance remains permanently pinned to exact runtime:

`8744b9e6239fa28a6d1094f6f4e7669e4ada25b3`

PR #33 was squash-merged with expected-head protection as:

`bb6df211699c5aef7bac7d50866f3e24b2fe165b`

Post-merge `main` CI #1244 passed all three canonical jobs on that exact merge source. M6.6 remains unreleased; published release is still immutable `v0.1.0`.

Accepted behavior includes stable compact/Peek/expanded ownership, exact hover dwell/grace, media and no-media Peek, prompt explicit click, physical DOWN/UP/pointer-exit transitions, LEFT -> Next / RIGHT -> Previous follow-finger gestures, seek/source identity/cursor isolation, bounded transport teardown, unchanged Sandbox/Hardened Runtime and no new sensitive permissions.

## P1 — whole-app performance/resource review

Status: **ACTIVE — MEASUREMENT FOUNDATION MERGED / TARGET-MAC EVIDENCE PENDING**.

P1 measurement foundation merged via PR #36 as exact tooling source:

`5cd9a2a47d87a433155f53b3aa0510000f2fce85`

Pre-merge CI #1260 and post-merge `main` CI #1261 both passed all three canonical jobs. The foundation changed development tooling/tests/docs only and no `Sources/` file.

The initial P1 audit intentionally measures exact merged M6.6 runtime:

`bb6df211699c5aef7bac7d50866f3e24b2fe165b`

with exact measurement tooling:

`5cd9a2a47d87a433155f53b3aa0510000f2fce85`

These SHAs have distinct roles and must remain separate. Later docs-only state commits do not redefine either provenance claim.

Phase order:

1. **DONE** — establish fail-closed provenance/privacy validation for target CPU/RSS/thread reports plus wakeup/energy/compositor observations;
2. **NEXT** — collect exact target-Mac evidence on Mac16,8/macOS 26.6;
3. characterize repeated-run variance and same-session comparability before adding new absolute budgets;
4. investigate only evidence-backed resource/compositor regressions;
5. optimize runtime only if measurements justify it, preserving M6.6 behavior and the current permission/security boundary.

The canonical P1 path remains non-privileged: no automatic `sudo powermetrics`, `timerfires`, privileged helper, telemetry or new entitlement. See `docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md` and `docs/superpowers/plans/2026-08-18-p1-target-mac-resource-audit.md`.

Broader active-display/multi-monitor hardening remains after the P1 resource gate.

## Product modules after media/performance foundation

- **M2 Shelf**.
- **M3 Snippets**.
- **M4 Calendar**.
- **M5 Translator**.
- **M7 Product shell**.
- **M8 Trusted distribution — optional**.

## Current priority

1. Collect target-Mac idle/hover/stability CPU/RSS/thread evidence using runtime `bb6df211...` and tooling `5cd9a2a4...`.
2. Collect 60-second idle wakeup + energy evidence and 10-cycle compositor evidence.
3. Validate the normalized P1 evidence bundle and characterize variance before introducing any new absolute cross-session resource threshold.
4. If evidence identifies a material regression, implement one isolated RED -> GREEN optimization and rerun affected physical acceptance; otherwise accept P1 without speculative runtime changes.
5. Only after P1 acceptance proceed to broader multi-monitor/active-display hardening or the next product module.
