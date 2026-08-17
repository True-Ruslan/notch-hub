# Project state

Last updated: 2026-08-17
Published version: `0.1.0` Personal Release
Primary physical target: macOS 26.6 / Mac16,8
Protected branch: `main`

## Product state

NotchHub is a native, local-first macOS productivity hub built around the physical MacBook notch. Security, privacy, performance, energy use and deterministic interaction behavior are first-class constraints. Runtime work remains event-driven unless separately measured evidence justifies otherwise.

Published state remains immutable `v0.1.0`. M6.6 below is unreleased source work.

### Merged foundations

- M0 Engineering Foundation — accepted/merged.
- R0.1 Personal Release `v0.1.0` — accepted/released.
- P0 Performance Foundation — accepted/merged; immutable baseline preserved.
- P0.1 Public repository readiness — accepted.
- M1 primary interaction/transition foundation — accepted/merged; active-display/fullscreen/Spaces/notchless/multi-monitor hardening remains deferred.
- M6.1 transport feasibility — accepted.
- M6.2 normalized media boundary — accepted/merged.
- M6.3 production system transport — accepted/merged.
- M6.4 shipping media composition/lazy lifecycle — accepted/merged.
- M6.5 Media-first UI — accepted/merged.
- M6.6 prerequisite tasks through vertical visual tracking — merged.
- Regression/UI Automation Foundation — merged via PR #34 as `bd9566f690d314ed40fd6f3723a319291ceb4a58`; post-merge `main` CI #1053 passed all canonical jobs.

Current PR #33 base is `main` at `bd9566f690d314ed40fd6f3723a319291ceb4a58`.

## Active work — M6.6 PR #33

PR #33 `M6.6: app media gesture session TDD` is **implemented / regression-integrated / minimal technical candidate 3/3 automated-green / final docs-sync CI pending / physical retest pending / draft / not merged / not released**.

Current interaction contract:

- stable `compact <-> peek <-> expanded` under one transition authority;
- hover dwell is exactly 120 ms; Peek exit grace is exactly 140 ms;
- valid hover opens lightweight generic Peek even without usable media; optional media enrichment begins only after authoritative Peek settlement;
- settled compact and Peek own zero persistent media observer; only settled expanded owns the presentation-scoped shipping runtime;
- explicit click remains one stable SwiftUI tap path; persistent AppKit hosting accepts first mouse but does not own mouse-button semantics;
- physical DOWN expands; physical UP collapses; exact top-screen/panel `maxY` is inside the interaction region;
- expanded pointer exit returns non-haptically to exact compact;
- interactive transitions settle to exact endpoints even when moving geometry leaves the pointer before terminal local scroll delivery;
- physical horizontal direction is LEFT -> `next`, RIGHT -> `previous`, independent of macOS scroll-direction preference;
- seek, source identity and cursor isolation remain bounded/event-driven;
- bounded Peek cancellation is nonblocking for the UI actor, with transport stop races and late callbacks fail-closed;
- persistent expanded-runtime and application-Quit teardown retain synchronous fail-closed lifecycle verification.

No global scroll/button/keyboard monitor, mouse-button event authority, event tap, polling loop, repeating timer, display link, UI-test retry/sleep masking, new process executable boundary, network authority, telemetry, or sensitive permission was introduced.

## Physical evidence still controlling acceptance

Historical target-Mac evidence remains authoritative for the candidates on which it was recorded:

- `6c2109195042759b951217f489a201a82dd044cd` / CI #1156: physical LEFT/RIGHT track gestures were reversed relative to the frozen contract. This is physical rejection evidence for that candidate; the corrected direction has not yet been physically retested on the final candidate.
- `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101: no-media Hover Peek/haptic and exact-top-edge DOWN were rejected. The automated repairs are green, but target-Mac retest remains required.

Video/automation cannot establish felt haptic feedback or post-Quit helper cleanup. Those gates remain pending.

## Proven repairs retained in the minimal candidate

### Horizontal direction

Root cause was isolated to AppKit precise-scroll normalization. The semantic coordinator and typed command boundary already preserved `next`/`previous` correctly.

- RED `f5cb5e3d1f13c7dc5564ce24068e83007f97bb1` / CI #1157 failed the new physical-direction assertions.
- GREEN `50b82dae49f3ce6c6e194b1ab9775bd5cd5dd430` / CI #1158 changed horizontal normalization to `x: -scrollingDeltaX * preferenceScale`; vertical semantics, thresholds and haptics were unchanged.

### Hover Peek / first-click teardown

Native XCUI proved that entering the notch before click synthesis can settle Hover Peek and overlap bounded media work. Synchronous subprocess teardown on `@MainActor` could then block click processing for about 5.4 s. A later `NSEvent.pressedMouseButtons` timing guard produced one green run but #1200 reproduced a 5.444 s stall, so the guard was rejected.

Final architecture:

- generic Peek opens after valid dwell;
- bounded enrichment begins only after authoritative `.peek` settlement;
- bounded Peek release uses `stopNonBlocking()` after callback detachment;
- in-flight one-shot work is cancelled immediately without `waitUntilExit` on the caller/UI actor;
- graceful/forced process termination remains bounded by one-shot deadlines;
- synchronous `stop()` remains for persistent expanded runtime and explicit Quit verification;
- `NSEvent.pressedMouseButtons` is absent from correctness logic.

### Stop-race and transport integration hardening

After the initial #1209 repair, additional regression work closed lifecycle races and clarified Peek completion semantics:

- `MediaRemoteSystemTransportStopRaceTests` proves stop-before-queued-capability work prevents late one-shot launch and stale transport activity cannot escape ownership;
- `ShippingMediaPeekProbeTransportIntegrationTests` proves first usable snapshot can complete bounded Peek without waiting for later capability work and that transport teardown stays bounded;
- metadata-only Peek completion and late capability behavior are covered without adding persistent observation;
- all of these tests are included in the current 363-test suite.

### Removal of unproven primary-press seam

An experimental primary-press production seam was evaluated but was not required by the proven repair. It was removed completely in `c4377436afa5fcb8e9eb9f9d3d8bc952f3647271`:

- no primary-press state remains in `NotchInteractionCoordinator`;
- no AppKit `mouseDown`/`mouseUp` reporting seam remains;
- no controller wiring or dedicated production mouse-button semantics remain;
- its speculative regression test was removed.

The minimal candidate keeps only the proven first-mouse acceptance, stable SwiftUI click authority, nonblocking Peek teardown and corrected XCUI harness behavior.

## Technical #1230 evidence

Exact technical source `c4377436afa5fcb8e9eb9f9d3d8bc952f3647271` / CI #1230 / run `32000799095` is **3/3 GREEN** before this documentation synchronization:

- `macOS 26 compatibility` — GREEN, warnings-as-errors, **363 Swift tests / 79 suites**, MediaBridge probe/archive and production transport/archive;
- `macOS UI regression` — GREEN, strict acceptance traceability `116/116`, exact external application, shipping-fixture isolation, native XCUI **11/11**;
- `Build, test and package` — GREEN, source/security policy, App Sandbox-only, Hardened Runtime/signing/preflight, unchanged cumulative size budget and shared-runner performance smoke;
- `testTenHoverExitCyclesNeverLeaveStaleSurface` — GREEN; repeated stress click event synthesis is roughly **0.35–0.44 s**, with no recurrence of the historical ~5.44 s stall.

Technical artifact provenance:

- UI `.xcresult`: `9278554509`, `sha256:b4ff2e92b1991d054f0efb20a603b8882d9ad4c74a15901341a0be61ec109bfe`;
- shipping-media candidate: `9278444863`, `sha256:9e4dc9d64c39d6d4bcfac59169c220df36d8935832b71bb760a6efc3d2ae6315`;
- DMG: `9278448535`, `sha256:57ee01c1520c853ee6377ae604d32fc5b245dfbc76209da16f20e2c0f3d232e7`;
- performance metadata: `9278447870`, `sha256:9f24bc6fee371b88d6ff88782f024f9d4e5b334d448894bf34127b381fa90216`;
- production transport candidate: `9278387131`, `sha256:49729b55d295a4649777c14e83da6ba3011aa0750850ec409ad2d067e2b8106d`;
- MediaBridge probe candidate: `9278368378`, `sha256:0cf2699b3af0a82e4ad9035bb6ae4840700ea7cef8911661b6be7a075a20c543`.

Measured shipping sizes: app `882895 B`, DMG `559550 B`, executable `580688 B`.

This state-file synchronization creates a new source SHA. Therefore #1230 is technical evidence, **not** the frozen physical candidate. The exact documentation-synchronized head must independently pass all three canonical jobs before its SHA/artifacts are frozen in PR #33 without another repository commit.

## Security and resource invariants

- App Sandbox-only entitlement and Hardened Runtime remain mandatory.
- No Accessibility, Input Monitoring, Automation, Screen Recording, networking, telemetry, history persistence or arbitrary command authority is added.
- Universal Media retains the reviewed fixed `/usr/bin/perl` + pinned adapter/framework boundary.
- Settled compact and Peek own zero persistent adapter; optional Peek enrichment is bounded and cancellation is nonblocking for UI; settled expanded owns the expected presentation-scoped runtime; normal Quit must leave no orphan.
- Gesture/Peek/transition hot paths add no polling, repeating timer, display link, global scroll/button monitor, event tap, per-event subprocess creation, or production logging.
- UI fixtures and diagnostics remain compile-time test-only; shipping composition still creates concrete production runtime.

## Performance state

`performance/baseline-v0.1.0.json` and all historical feature budgets remain immutable provenance records.

The active cumulative envelope remains `performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json`: app allowance `614400 B`, DMG allowance `471040 B`, executable allowance `315392 B` over immutable `v0.1.0`.

Technical #1230 measured app `882895 B`, DMG `559550 B`, executable `580688 B`, all inside the unchanged active envelope. The cleanup required **no budget expansion**.

Shared-runner performance is compatibility evidence only. Target-Mac CPU/RSS/threads/wakeups/energy acceptance remains P1 and starts only after M6.6 physical acceptance and merge.

## Not yet accepted

- physical LEFT -> next and RIGHT -> previous after direction repair in compact, Peek and expanded;
- physical arm haptic for supported horizontal gestures;
- real no-media and media hover -> Peek physical haptic;
- stationary-pointer relaunch Hover Peek/haptic;
- compact click while Hover Peek/media enrichment overlaps;
- exact-top-edge physical DOWN with no twitch/self-collapse;
- UP/DOWN settlement under pointer/panel separation;
- seek/cursor/source-continuity physical matrix;
- lifecycle cleanup after real Quit, including explicit empty `pgrep` evidence;
- permission matrix;
- remaining `NH-MEDIA-PEEK-*`, affected `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, and `NH-MEDIA-SOURCE-ICON-*` physical gates;
- PR #33 remains draft and unmerged;
- no new release claim is made;
- P1 and multi-display hardening remain blocked by M6.6 acceptance.

## Next optimal step

1. Pass all three canonical CI jobs on this exact documentation-synchronized PR #33 head.
2. If and only if that exact head is 3/3 GREEN, freeze its SHA, run and CI-produced artifact provenance in PR #33 **without another repository commit**.
3. Physically retest that frozen candidate on Mac16,8/macOS 26.6 with real media: LEFT/RIGHT direction, arm haptic, Hover Peek/no-media/stationary restart, click-during-enrichment, exact-edge DOWN, pointer-exit/UP settlement, seek/source continuity, permission surface and process lifecycle.
4. After real Quit, run `pgrep -lf 'mediaremote-adapter\.pl' || true` and require empty output.
5. Only after full physical evidence is green may PR #33 become ready, merge, receive post-merge `main` verification and unblock P1/multi-display hardening.
