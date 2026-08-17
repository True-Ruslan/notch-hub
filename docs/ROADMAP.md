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

Status: **IMPLEMENTED / REGRESSION-INTEGRATED / CI #1238 3/3 GREEN / FINAL HORIZONTAL PHYSICAL CONTRACT PASS ON `f2e81d993...` / FULL ONE-SHA PHYSICAL MATRIX PENDING / NOT MERGED / NOT RELEASED**.

Draft PR #33 provides:

- stable `compact`, `peek`, `expanded` ownership under one transition authority;
- exactly 120 ms hover dwell and 140 ms Peek exit grace;
- generic Hover Peek without usable media plus bounded optional enrichment;
- persistent media runtime only in expanded;
- explicit click/DOWN expansion with stable outer SwiftUI tap ownership;
- exact-top-edge inclusive interactive pointer retention;
- local previous/next gestures with physical LEFT -> `next`, RIGHT -> `previous`, independent of macOS scroll-direction preference;
- horizontal visual motion that follows the physical fingers;
- interactive panel follow-finger motion and exact endpoint settlement;
- source icon, seek/cursor isolation and event-driven continuity;
- nonblocking bounded Peek teardown with stop-race and transport-integration regressions.

No new global input authority, polling, repeating timer, display link, retry/sleep masking or sensitive permission was added.

#### Final horizontal closure — 2026-08-18

The horizontal path required multiple evidence-driven repair cycles because command semantics and presentation sign can appear correct independently while remaining wrong as a physical pipeline.

Final source `f2e81d993db37af9548799682ad8f03c7d64ae27` / CI #1238 / run `32072408370` is 3/3 GREEN with 365 Swift tests / 79 suites and external exact-app XCUI 11/11.

Target-Mac physical PASS on exact `f2e81d993...` confirmed:

- RIGHT -> Previous/back and animation follows RIGHT;
- LEFT -> Next and animation follows LEFT;
- below-threshold smoke -> no switch;
- momentum -> no extra switch;
- DOWN/UP smoke remains correct;
- supported horizontal arm haptic occurs once.

The horizontal contract is therefore physically proven on this source candidate. A new `MediaGesturePhysicalPipelineTests` characterization now binds raw AppKit delta, scroll-direction preference normalization, visual offset and typed command in one regression so future sign changes cannot silently compensate across layers.

Because the test/documentation synchronization itself creates a new SHA, M6.6 is not promoted to full accepted yet. The new exact head must pass canonical CI and then receive the remaining one-SHA physical matrix.

Acceptance ledgers:

- `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`;
- `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`;
- `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`.

No P1 work, merge or release is allowed before all applicable physical gates pass on one final exact candidate.

## P1 — whole-app performance/resource review

Status: **BLOCKED UNTIL M6.6 PHYSICAL ACCEPTANCE + MERGE**.

Planned: target-Mac CPU/RSS/threads/wakeups/energy/compositor review, narrow global `.mouseMoved` fallback comparison only if evidence requires it, repeated-run variance characterization, and real active-display/multi-monitor reality checks.

## Product modules after media/performance foundation

- **M2 Shelf**.
- **M3 Snippets**.
- **M4 Calendar**.
- **M5 Translator**.
- **M7 Product shell**.
- **M8 Trusted distribution — optional**.

## Current priority

1. Commit the final horizontal pipeline regression plus documentation synchronization atomically; production code remains unchanged from physically proven `f2e81d993...`.
2. Pass all three canonical CI jobs on that exact new head and verify the expected regression count increase.
3. Freeze exact source SHA + shipping/DMG artifact provenance without another repository commit.
4. Run the remaining target-Mac one-SHA M6.6 matrix: media/no-media Peek + haptics, stationary restart, click-during-enrichment, exact-edge DOWN, pointer-exit/UP settlement, seek/cursor/source continuity, source icon, permissions and post-Quit process cleanup; include a quick LEFT/RIGHT reconfirmation.
5. Any repeatable failure gets its own focused regression -> minimal repair -> new candidate cycle.
6. Only after full physical PASS: mark PR #33 ready, merge, verify post-merge `main` CI, close M6.6 and begin P1.
