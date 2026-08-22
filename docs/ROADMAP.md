# Roadmap

Primary target: Mac16,8 / macOS 26.6.x. Current physical environment: macOS 26.6.2. Published Personal Release: `v0.1.0`.

States are explicit: **implemented -> automated-tested -> physically accepted -> merged -> released**. Green CI does not substitute for target-Mac acceptance when physical UI, permissions, third-party behavior or resources are part of the contract.

## Completed foundations

- **M0 Engineering Foundation — ACCEPTED / MERGED**.
- **R0.1 Personal Release — ACCEPTED / RELEASED**: immutable `v0.1.0`.
- **P0 Performance Foundation — ACCEPTED / MERGED**.
- **P0.1 Public repository readiness — ACCEPTED**.
- **M1 primary interaction foundation — ACCEPTED / MERGED**; broader active-display/fullscreen/Spaces/notchless/multi-monitor hardening remains a later slice.
- **Regression/UI Automation Foundation — IMPLEMENTED / TESTED / MERGED** via PR #34 as `bd9566f690d314ed40fd6f3723a319291ceb4a58`.

## M6 — Universal Media / System Now Playing

- **M6.1 transport feasibility — ACCEPTED**.
- **M6.2 production media boundary — ACCEPTED / MERGED**.
- **M6.3 concrete system transport — ACCEPTED / MERGED**.
- **M6.4 shipping composition — ACCEPTED / MERGED**.
- **M6.5 Media-first UI — ACCEPTED / MERGED**.

### M6.6 — gestures, haptics, interactive notch, seek and Hover Peek

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / NOT RELEASED**.

Original full physical source acceptance remains permanently pinned to exact runtime `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3`. PR #33 squash-merged as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`; published release remains immutable `v0.1.0`.

Later real target-Mac checks found and repaired three independent runtime defects while preserving the accepted interaction/security boundary:

- hardware-notch launch screen selection — PR #40, merged `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`;
- exact compositor endpoint settlement — PR #51, physically accepted head `329b867595b6ffe127fa3552f51bef8412865f37`, merged `1f56c3e5da8a46509a3472a52da12a1abfb16a8c`;
- broad global pointer wakeups plus rapid-exit loss — PR #53, physically accepted head `bddd0503d972c652752a0e1463f3495685accc83`, merged `11dad43364a969f4d5f8c1a92e1281b5b41c8a74`.

Final PR #53 physical acceptance on Mac16,8/macOS 26.6.2 covered rapid exit 30/30, compositor 10/10, reversal recovery, hardware-notch binding and same-candidate wakeup A/B. The accepted head and squash merge share Git tree `8f0a7fee0b02599520a5776133f51c1215da7d98`.

## P1 — whole-app performance/resource review

Status: **ACCEPTED — COMPLETE TARGET-MAC EVIDENCE / DIRECT GATES PASS / NO SPECULATIVE OPTIMIZATION REQUIRED**.

Accepted provenance:

- measured runtime: `11dad43364a969f4d5f8c1a92e1281b5b41c8a74`;
- measurement/evidence tooling: `fc7562b0799faa4dd80e8c47263354a8bd16bd6a`;
- exact target: `Mac16,8 / macOS 26.6.2`;
- closed issue #38 contains the live collection and final acceptance trail.

Final evidence:

- Idle — CPU median/max `0.0/0.0%`; RSS median/max `58,432/58,496 KiB`; threads median/max `3/6`; Idle thread gate PASS.
- Hover — CPU median/max `6.8/32.3%`; RSS median/max `75,936/76,784 KiB`; threads median/max `6/6`; CPU median target and thread gate PASS. One-second CPU max remains diagnostic under the accepted policy.
- Stability — CPU median/max `0.0/0.0%`; RSS `58,816 -> 54,848 KiB` (`-3,968 KiB`); threads `3 -> 3`, max `5`; all direct growth/thread gates PASS.
- Activity Monitor Idle Wake Ups, 60 s — `0.0/s`, explicitly reviewed with no anomaly.
- Activity Monitor Energy fallback, 60 s — `no-anomaly-observed`; Energy Impact `0.0`, App Nap `No`, Preventing Sleep `No`.
- Manual visual compositor — exactly 10 cycles PASS; reversal recovery PASS; no freeze/stuck panel or frame/corner/flicker anomaly.
- Normalized evidence bundle — validation PASS, `reviewRequired=false`, final direct-gate review PASS.

Earlier 26.6.1 and pre-fix measurements remain historical diagnostic evidence and are not mixed with the accepted 26.6.2 bundle.

P1 lifecycle is complete as an acceptance gate. It is not a release event; published version remains `v0.1.0`.

## M1 — active-display / multi-monitor migration

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / NOT RELEASED**.

Event-driven display-topology migration: observes `NSApplication.didChangeScreenParametersNotification`, resolves `NSScreen.screens` fresh on topology change while preserving hardware-notch-first selection and the accepted `NSScreen.main`/first-screen fallback, migrates Compact/Peek/Expanded through one shared `NotchPanelLayoutModel`, retargets in-flight programmatic and interactive transitions by generation, and resets the bounded pointer-escape monitor across migration. No private display APIs, repeating timers, display links, telemetry or new permissions were added.

Automated candidate `dd945dc3ca009f8d9429ad044d50a01a2ea1bb62`; CI #1344 3/3 GREEN; full Swift suite 392 tests GREEN.

Physical acceptance on `Mac16,8 / macOS 26.6.2` with an external monitor connected — 11/11 PASS, covering connect/disconnect/reconfigure across Compact/Peek/Expanded, interruption of programmatic and interactive transitions, no-notch fallback, repeated migration cycles, post-migration pointer/hover scoping and no new permission prompts. Full checklist recorded in PR #56.

PR #56 squash-merged as `c7d2bdb9cae744d439d240f22acd14140bacedd3`; issue #55 closed. Published release remains immutable `v0.1.0`.

## Repository governance

Issue #42 remains open because `main` is intended to be protected but GitHub currently reports it unprotected. Restoring branch governance remains a repository-quality priority and should be completed when repository capabilities permit. Do not treat the current unprotected state as accepted architecture.

## Product modules after media/performance foundation

- **M2 Shelf**.
- **M3 Snippets**.
- **M4 Calendar**.
- **M5 Translator**.
- **M7 Product shell**.
- **M8 Trusted distribution — optional**.

## Current priority

1. Keep issue #42 visible for branch-protection restoration.
2. M1 active-display/multi-monitor migration is accepted; select and specify the next bounded product-hardening slice or module (e.g. remaining fullscreen/Spaces/notchless hardening, or the next M2+ product module) rather than speculative resource optimization.
3. Require target-Mac physical acceptance before any shipping behavior change that CI cannot honestly prove.
4. Keep the published Personal Release at immutable `v0.1.0` until an explicit release decision.
