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
- explicit click or physical DOWN expands; explicit-click ownership now lives on the stable outer media-aware root above both generic/media and compact/Peek branch replacement, so hover/media arrival cannot destroy an in-flight click;
- exact physical top-edge `maxY` counts as inside the interactive panel, preventing false pointer-exit cancellation of DOWN;
- expanded pointer exit returns non-haptically to exact compact;
- UP/DOWN interactive transitions must settle to exact endpoints even if moving geometry leaves the pointer before local terminal scroll delivery;
- horizontal previous/next, seek, source identity and cursor isolation preserve the existing bounded/event-driven architecture.

No global scroll/button/keyboard monitor, event tap, polling loop, repeating timer, display link, new process boundary or sensitive permission authority was introduced. No UI-test retries or sleeps are used to hide interaction failures.

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
- external XCUI later exposed explicit-click races when a recognizer lived below presentation/root branch replacement.

The physical decision now requires generic no-media Peek + one hover haptic, inclusive exact-top-edge interaction, and explicit-click stability across all hover/media presentation changes.

## 2026-08-15 focused repair evidence

The repair followed fail-first coverage and preserved security/performance boundaries.

- focused unit RED reproduced no-media gating and exact-edge containment;
- `NotchPointerPolicy.containsInteractivePointer` treats the physical top/right boundary inclusively for interactive retention;
- `MediaPeekSession` opens generic Peek before the bounded probe, so `.noSession` no longer collapses the hover preview;
- compile-time-only haptic diagnostics observe the same transition-coordinator request point as the production AppKit performer and are excluded from shipping artifacts;
- local `NSTrackingArea` provides primary hover entry/move/exit without polling;
- attempted mouse-button interception was rejected by the existing security baseline and removed; no new mouse-button authority remains;
- the first click repair moved the recognizer above compact/Peek inside the media branch.

Behavior head `63b0f2f96f879123f3883db7311c90a20d3a4328` / CI #1140 / run `31889213155` passed 352 Swift tests / 74 suites and 11/11 external XCUI journeys. Its only failing canonical gate was the previous DMG size ceiling. The size review then added exactly one 4096-byte DMG allowance quantum while leaving app/executable allowances unchanged. Pre-docs head `3e617698a503590dbc18958960a5335753734ccc` / CI #1147 / run `31889961194` passed all three canonical jobs.

### First-launch/root-replacement click race

Documentation-synchronized head `a91e196d0ed51fb73a49b680eac1321100cdadb5` / CI #1152 / run `31890935022` was **automatically rejected** before physical testing. Compatibility and package jobs were green, but native external XCUI failed two explicit-click journeys. The first click could start while the app still rendered the generic root, then media/Peek arrival replaced the entire generic/media branch before the gesture completed.

Focused TDD:

- RED `ac1f004b9a0d2a0fd54c16cb7c0041933d3523df` / CI #1153 / run `31891311328`: 354 tests / 75 suites, with only the new root-ownership regression test failing;
- GREEN `16feb0433f7fdfb18d5eacfcce66707959e6211a` / CI #1155 / run `31891464496`: explicit expansion tap authority moved to the stable outer `MediaNotchRootView` `ZStack`; nested generic `NotchRootView` can disable its child tap in media-aware composition while retaining its standalone default behavior;
- #1155 passed all three canonical jobs, the full Swift suite, strict acceptance traceability, security/source policy, production transport/archive, Sandbox/Hardened Runtime/signing/preflight, unchanged size budget, performance smoke and the native external-app XCUI suite;
- no retry, sleep, mouse-button monitor, event tap or security exception was added.

CI #1155 shipping evidence:

- shipping-media artifact `9248700272` (`sha256:509826b1c36b46d406a87621bbe83b4aa039c2aff40422b9be1ce46ecef99d2f`);
- DMG artifact `9248701623` (`sha256:860b36a3ae6a740490e177847634e5d76ed9be913afb89ec7cc87a7128e4f050`);
- UI result artifact `9248698799` (`sha256:83522a4ec996649d5dcc5e0f99332bf921fb322efe1d86f8e9f3f4182ec85730`);
- executable `580912 B`;
- app `883119 B`;
- DMG `555204 B`.

This documentation sync creates a new source SHA. That exact docs-synchronized head must pass the same three canonical jobs before its source/artifact provenance is frozen for target-Mac testing. No source commit is allowed after the freeze unless a new defect is found.

## Security/resource invariants

- App Sandbox-only entitlement and Hardened Runtime remain mandatory.
- No Accessibility, Input Monitoring, Automation, Screen Recording, network, telemetry, history persistence or arbitrary command authority was added.
- Universal Media retains the reviewed fixed `/usr/bin/perl` + pinned adapter/framework boundary.
- Settled compact and Peek own zero persistent adapter; settled expanded owns the expected presentation-scoped runtime; normal Quit must leave no orphan.
- Gesture/Peek/transition hot paths add no polling, repeating timer, display link, global scroll monitor, event tap, per-event process creation or logging.
- UI fixtures and injectable haptic/runtime seams are compile-time test-only; shipping composition still creates concrete `ShippingMediaRuntime`.

## Performance state

`performance/baseline-v0.1.0.json` and all historical feature budgets remain immutable provenance records.

The active cumulative envelope remains `performance/m6-6-physical-acceptance-20260815-repair-size-budget.json`, provenanced from source `63b0f2f96f879123f3883db7311c90a20d3a4328` / CI #1140 / run `31889213155` / artifact `9248133083`.

Measured budget evidence: app `883039 B`, DMG `555132 B`, executable `580832 B`. Allowance over immutable `v0.1.0`: app `614400 B`, DMG `466944 B`, executable `315392 B`. Only the DMG allowance increased relative to the preceding cumulative envelope, by one 4096-byte review quantum. CI #1155 passed this same envelope unchanged with app `883119 B`, DMG `555204 B`, executable `580912 B`.

Shared-runner size/performance checks remain compatibility gates. Target-Mac CPU/RSS/threads/wakeups/energy acceptance remains P1 and does not begin before M6.6 is physically accepted and merged.

## Not yet accepted

- real no-media and media hover -> Peek physical haptic on Mac16,8;
- stationary-pointer relaunch Hover Peek/haptic;
- explicit click while hover/media arrival can replace presentation branches;
- exact-top-edge physical DOWN with no twitch/self-collapse;
- UP/DOWN settlement under pointer/panel separation;
- full remaining `NH-MEDIA-PEEK-*`, affected `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, `NH-MEDIA-SOURCE-ICON-*`, lifecycle and permission matrix;
- PR #33 remains draft and unmerged;
- no release claim is made;
- P1 and multi-display hardening remain blocked by current M6.6 acceptance.

## Next optimal step

1. Pass all three canonical CI jobs on this final documentation-synchronized PR #33 head.
2. Freeze that exact source SHA and CI-produced shipping artifact/DMG provenance in PR #33 **without another repository commit**.
3. Perform the focused target-Mac retest from `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`: no-media hover+haptic, stationary relaunch, explicit click during hover/media branch changes, exact-top-edge DOWN, pointer-exit and UP/DOWN settlement.
4. If the focused block passes, continue the remaining horizontal gesture, seek, source-icon, lifecycle and permission matrix on the same exact candidate.
5. Only after full physical PASS may PR #33 become ready, merge, receive post-merge `main` verification and unblock P1.
