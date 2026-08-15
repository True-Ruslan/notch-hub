# Project state

Last updated: 2026-08-15
Published version: `0.1.0` Personal Release
Primary physical target: macOS 26.6 / Mac16,8
Protected branch: `main`

## Current state

NotchHub is a native, local-first macOS productivity hub built around the physical MacBook notch. Security, privacy, performance and energy use are first-class constraints. Runtime behavior remains event-driven unless a separately measured decision proves otherwise.

Published state remains immutable `v0.1.0`. M1/P0.1/M6 source work below is unreleased.

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
- Regression/UI Automation Foundation — merged via PR #34 as `bd9566f690d314ed40fd6f3723a319291ceb4a58`; post-merge `main` CI #1053 passed all three canonical jobs.

Current PR #33 base is `main` at `bd9566f690d314ed40fd6f3723a319291ceb4a58`.

## Active work — M6.6 PR #33

PR #33 `M6.6: app media gesture session TDD` is **implemented / regression-integrated / focused repair automated-green before final docs sync / physical retest pending / draft / not merged / not released**.

Current interaction contract:

- stable `compact <-> peek <-> expanded` under one transition authority;
- hover dwell remains exactly 120 ms and opens Peek only;
- usable media is no longer required for Peek: no-media hover opens a lightweight generic Peek and requests the normal hover haptic once;
- one bounded media probe may enrich Peek without creating a persistent compact/Peek observer;
- explicit click or physical DOWN expands; a single stable SwiftUI tap recognizer lives above the compact/Peek presentation switch so hover dwell cannot destroy an in-flight click;
- exact physical top-edge `maxY` counts as inside the interactive panel, preventing false pointer-exit cancellation of DOWN;
- expanded pointer exit returns non-haptically to exact compact;
- UP/DOWN interactive transitions must settle to exact endpoints even if moving geometry leaves the pointer before local terminal scroll delivery;
- horizontal previous/next, seek, source identity and cursor isolation preserve the existing bounded/event-driven architecture.

No global scroll/button/keyboard monitor, event tap, polling loop, repeating timer, display link, new process boundary or sensitive permission authority was introduced.

## Latest physical rejection — candidate #1101

Exact candidate `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101 / run `31871250982` was rejected on Mac16,8/macOS 26.6 on 2026-08-15.

Observed with music/media off:

1. holding the pointer over the physical notch produced no Peek and no haptic, while explicit click still opened expanded;
2. expanded pointer-exit correctly auto-collapsed, confirming the earlier M1 repair remained PASS;
3. DOWN started exactly at the physical top screen edge moved slightly and immediately returned to compact;
4. DOWN started slightly lower near the notch center was stable;
5. UP collapse was stable;
6. no haptic was felt in those no-media/vertical paths.

Root cause/decision:

- half-open `CGRect.contains` rejected the pointer at exact `frame.maxY`;
- the old pending no-media contract deliberately gated Peek on usable media;
- external XCUI later exposed an explicit-click race when hover could switch compact -> Peek while a child tap recognizer was in flight.

The physical decision now requires generic no-media Peek + one hover haptic, inclusive exact-top-edge interaction, and explicit-click stability across compact/Peek transitions.

## 2026-08-15 focused repair evidence

The repair followed fail-first coverage and preserved security/performance boundaries.

- focused unit RED reproduced no-media gating and exact-edge containment;
- `NotchPointerPolicy.containsInteractivePointer` now treats the physical top/right boundary inclusively for interactive retention;
- `MediaPeekSession` opens generic Peek before the bounded probe, so `.noSession` no longer collapses the hover preview;
- compile-time-only haptic diagnostics observe the same transition-coordinator request point as the production AppKit performer and are excluded from shipping artifacts;
- local `NSTrackingArea` provides primary hover entry/move/exit without polling;
- attempted mouse-button interception was rejected by the existing security baseline and removed; no new mouse-button authority remains;
- explicit expansion uses one stable parent SwiftUI tap recognizer above the compact/Peek presentation switch.

Exact behavior head `63b0f2f96f879123f3883db7311c90a20d3a4328` / CI #1140 / run `31889213155` passed 352 Swift tests / 74 suites and 11/11 external XCUI journeys. Its only failing canonical gate was the previous DMG size ceiling.

The size review then added exactly one 4096-byte DMG allowance quantum while leaving app/executable allowances unchanged. Pre-docs head `3e617698a503590dbc18958960a5335753734ccc` / CI #1147 / run `31889961194` passed all three canonical jobs, including strict acceptance traceability, security/source audit, production transport/archive, Sandbox/Hardened Runtime/signing/preflight, size budget, performance smoke and external XCUI.

CI #1147 shipping evidence:

- shipping-media artifact `9248335486`;
- DMG artifact `9248336772`;
- UI result artifact `9248334093`;
- executable `580832 B`;
- app `883039 B`;
- DMG `555152 B`.

The current documentation-synchronized head must pass the same exact three-job CI before its artifact provenance is frozen for target-Mac physical testing. No further source commit is allowed after that freeze unless a new defect is found.

## Security/resource invariants

- App Sandbox-only entitlement and Hardened Runtime remain mandatory.
- No Accessibility, Input Monitoring, Automation, Screen Recording, network, telemetry, history persistence or arbitrary command authority was added.
- Universal Media retains the reviewed fixed `/usr/bin/perl` + pinned adapter/framework boundary.
- Settled compact and Peek own zero persistent adapter; settled expanded owns the expected presentation-scoped runtime; normal Quit must leave no orphan.
- Gesture/Peek/transition hot paths add no polling, repeating timer, display link, global scroll monitor, event tap, per-event process creation or logging.
- UI fixtures and injectable haptic/runtime seams are compile-time test-only; shipping composition still creates concrete `ShippingMediaRuntime`.

## Performance state

`performance/baseline-v0.1.0.json` and all historical feature budgets remain immutable provenance records.

The active cumulative envelope is now `performance/m6-6-physical-acceptance-20260815-repair-size-budget.json`, provenanced from source `63b0f2f96f879123f3883db7311c90a20d3a4328` / CI #1140 / run `31889213155` / artifact `9248133083`.

Measured evidence: app `883039 B`, DMG `555132 B`, executable `580832 B`. Allowance over immutable `v0.1.0`: app `614400 B`, DMG `466944 B`, executable `315392 B`. Only the DMG allowance increased relative to the preceding cumulative envelope, by one 4096-byte review quantum.

Shared-runner size/performance checks remain compatibility gates. Target-Mac CPU/RSS/threads/wakeups/energy acceptance remains P1 and does not begin before M6.6 is physically accepted and merged.

## Not yet accepted

- real no-media and media hover -> Peek physical haptic on Mac16,8;
- stationary-pointer relaunch Hover Peek/haptic;
- explicit click while hover dwell can transition compact -> Peek;
- exact-top-edge physical DOWN with no twitch/self-collapse;
- UP/DOWN settlement under pointer/panel separation;
- full remaining `NH-MEDIA-PEEK-*`, affected `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, `NH-MEDIA-SOURCE-ICON-*`, lifecycle and permission matrix;
- PR #33 remains draft and unmerged;
- no release claim is made;
- P1 and multi-display hardening remain blocked by current M6.6 acceptance.

## Next optimal step

1. Pass all three canonical CI jobs on this documentation-synchronized PR #33 head.
2. Freeze that exact source SHA and CI-produced shipping artifact/DMG provenance in PR #33 **without another repository commit**.
3. Perform the focused target-Mac retest from `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`: no-media hover+haptic, stationary relaunch, explicit click, exact-top-edge DOWN, pointer-exit and UP/DOWN settlement.
4. If the focused block passes, continue the remaining horizontal gesture, seek, source-icon, lifecycle and permission matrix on the same exact candidate.
5. Only after full physical PASS may PR #33 become ready, merge, receive post-merge `main` verification and unblock P1.
