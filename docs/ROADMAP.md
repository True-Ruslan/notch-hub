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

Evidence:

- source CI #1241 / run `32075976405` — all three canonical jobs GREEN;
- 366 Swift tests / 80 suites GREEN;
- external exact-app XCUI 11/11 GREEN;
- complete Mac16,8/macOS 26.6 physical matrix PASS;
- post-Quit `mediaremote-adapter.pl` process check empty;
- Accessibility / Input Monitoring / Automation / Screen Recording NONE.

Acceptance-record head `c9fbd0605b33a318bb4371ae0f2c928120356adf` passed CI #1243 3/3 GREEN without production changes.

PR #33 was then squash-merged with expected-head protection as:

`bb6df211699c5aef7bac7d50866f3e24b2fe165b`

Post-merge `main` CI #1244 ultimately passed all three canonical jobs on that exact merge source. The first packaging attempt hit a runner-local `hdiutil ... Resource temporarily unavailable` failure after successful build/tests/signing; only the failed job was rerun on the unchanged source and passed. This is retained as CI infrastructure evidence, not classified as an application regression.

Accepted behavior includes:

- stable `compact`, `peek`, `expanded` ownership under one transition authority;
- exactly 120 ms hover dwell and 140 ms Peek exit grace;
- media and generic no-media Hover Peek with physical haptic and no hover-only expansion;
- stationary-pointer relaunch Peek;
- persistent media runtime only in settled expanded;
- prompt single explicit click expansion even when hover/media enrichment overlaps;
- exact-top-edge and center DOWN follow-finger expansion without twitch/self-collapse;
- expanded pointer-exit and physical UP exact Compact settlement;
- physical LEFT -> `next`, RIGHT -> `previous`, independent of macOS scroll-direction preference, with visuals following the fingers;
- source icon/fallback, seek preview/commit/cancel, cursor restoration and source/track identity cancellation;
- nonblocking bounded Peek teardown with stop-race and transport-integration regressions;
- unchanged Sandbox/Hardened Runtime and sensitive-permission boundary.

M6.6 is merged source work only; published release remains immutable `v0.1.0`.

## P1 — whole-app performance/resource review

Status: **ACTIVE — Draft PR #36 `P1: target-Mac resource audit foundation`**.

P1 starts with measurement infrastructure and target evidence, not behavioral optimization.

Phase order:

1. establish fail-closed provenance/privacy validation for exact target CPU/RSS/thread reports plus wakeup/energy/compositor observations;
2. collect exact merged M6.6 runtime evidence on Mac16,8/macOS 26.6;
3. characterize repeated-run variance and same-session comparability before adding new absolute budgets;
4. investigate only evidence-backed resource/compositor regressions;
5. optimize runtime only if measurements justify it, preserving M6.6 behavior and the current permission/security boundary.

The canonical P1 path remains non-privileged: no automatic `sudo powermetrics`, `timerfires`, privileged helper, telemetry or new entitlement. See `docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md` and `docs/superpowers/plans/2026-08-18-p1-target-mac-resource-audit.md`.

Broader active-display/multi-monitor hardening remains after the P1 resource gate. Any new global `.mouseMoved` fallback remains prohibited unless measured evidence demonstrates a concrete need and the security/performance tradeoff is explicitly reviewed.

## Product modules after media/performance foundation

- **M2 Shelf**.
- **M3 Snippets**.
- **M4 Calendar**.
- **M5 Translator**.
- **M7 Product shell**.
- **M8 Trusted distribution — optional**.

## Current priority

1. Finish PR #36 automated evidence foundation with canonical CI GREEN.
2. Freeze the accepted P1 measurement-tool SHA without changing shipping runtime behavior.
3. Collect target-Mac CPU/RSS/threads/wakeups/energy/compositor evidence against merged runtime `bb6df211...`.
4. Review repeated-run variance and existing evidence-based stability/thread gates.
5. If measurements expose a material issue, implement one isolated RED -> GREEN optimization and re-run affected physical acceptance; otherwise close P1 without speculative runtime changes.
6. Only after P1 acceptance proceed to broader multi-monitor/active-display hardening or the next product module.
