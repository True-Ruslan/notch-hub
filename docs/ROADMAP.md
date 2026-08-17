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

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED ON EXACT `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3` / PR #33 DRAFT / NOT MERGED / NOT RELEASED**.

Exact source acceptance:

- CI #1241 / run `32075976405` — all three canonical jobs GREEN;
- 366 Swift tests / 80 suites GREEN;
- external exact-app XCUI 11/11 GREEN;
- target Mac16,8/macOS 26.6 final matrix — PASS;
- post-Quit `mediaremote-adapter.pl` process check — empty;
- Accessibility / Input Monitoring / Automation / Screen Recording — NONE.

Accepted behavior includes:

- stable `compact`, `peek`, `expanded` ownership under one transition authority;
- exactly 120 ms hover dwell and 140 ms Peek exit grace;
- media and generic no-media Hover Peek with physical haptic and no hover-only expansion;
- stationary-pointer relaunch Peek;
- persistent media runtime only in expanded;
- prompt single explicit click expansion even when hover/media enrichment overlaps;
- exact-top-edge and center DOWN follow-finger expansion without twitch/self-collapse;
- expanded pointer-exit and physical UP exact Compact settlement;
- physical LEFT -> `next`, RIGHT -> `previous`, independent of macOS scroll-direction preference, with visuals following the fingers;
- source icon/fallback, seek preview/commit/cancel, cursor restoration and source/track identity cancellation;
- nonblocking bounded Peek teardown with stop-race and transport-integration regressions;
- unchanged Sandbox/Hardened Runtime and sensitive-permission boundary.

Deterministic timing/arbitration/resource subcontracts remain protected by automated tests; physical-only properties are recorded against the exact candidate in the acceptance ledgers.

Acceptance ledgers:

- `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`;
- `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`;
- `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`.

The follow-up acceptance-record commit may change only documentation/coverage metadata. It does not move physical evidence away from source `8744b9e...`.

## P1 — whole-app performance/resource review

Status: **BLOCKED UNTIL PR #33 MERGE + POST-MERGE MAIN CI**.

Planned: target-Mac CPU/RSS/threads/wakeups/energy/compositor review, repeated-run variance characterization, and real active-display/multi-monitor reality checks. Any new global `.mouseMoved` fallback remains prohibited unless measured evidence demonstrates a concrete need and the security/performance tradeoff is reviewed.

## Product modules after media/performance foundation

- **M2 Shelf**.
- **M3 Snippets**.
- **M4 Calendar**.
- **M5 Translator**.
- **M7 Product shell**.
- **M8 Trusted distribution — optional**.

## Current priority

1. Land the M6.6 acceptance-record synchronization with no production-code change and no coverage-policy weakening.
2. Require all three canonical CI jobs GREEN on that record commit.
3. Keep PR #33 Draft until explicit merge authorization.
4. On authorization, mark ready and merge with expected-head protection; verify post-merge `main` CI.
5. Then close M6.6 as merged and start P1 before any broad multi-monitor hardening or new product module.
