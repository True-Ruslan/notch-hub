# Project state

Last updated: 2026-08-15
Published version: `0.1.0` Personal Release
Primary physical target: macOS 26.6 / Mac16,8
Protected branch: `main`

## Current state

NotchHub is a native, local-first macOS productivity hub built around the physical MacBook notch. Security, privacy, performance and energy use are first-class constraints; runtime behavior is event-driven unless a separate measured decision proves otherwise.

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

PR #33 `M6.6: app media gesture session TDD` is **implemented / integrated with the regression foundation / automated-green / physical retest pending / draft / not merged / not released**.

The branch owns stable `compact <-> peek <-> expanded`, media-only 120 ms Hover Peek with 140 ms grace, explicit click/DOWN expansion, local previous/next gestures and haptics, follow-finger transitions, bounded compact/Peek media work, expanded-only persistent runtime, source icon, seek/cursor isolation and event-driven continuity.

Pre-documentation implementation baseline `f49f94d5ab51dcec5dccb97b6c0997ec631b1261` passed PR #33 CI #1100 / run `31870867724` with all three canonical jobs SUCCESS:

- `macOS 26 compatibility` — PASS;
- `macOS UI regression` — PASS;
- `Build, test and package` — PASS;
- Swift suite — **347 tests / 72 suites PASS**;
- acceptance traceability — **116 discovered / 116 mapped / 0 unmapped** in strict mode;
- native external-app XCUI — **9/9 PASS**;
- release/security/media/signing/Sandbox/Hardened Runtime/preflight/combined-size/performance-smoke gates — PASS.

This documentation sync intentionally creates a new source SHA. That new docs-synchronized head must pass the same exact CI before its source/artifact provenance is frozen for physical testing.

### Regression-foundation integration

The temporary draft PR #35 was used only as a fail-closed integration workspace after PR #34 changed the base beneath frozen PR #33. It is not a product PR and must not be merged to `main`.

Integration added or preserved:

- checked-in native XCTest/XCUIAutomation regression project that launches the exact built `NotchHub.app`;
- compile-time-only `NOTCHHUB_UI_TESTING` media/haptic fixtures with shipping-marker leak checks;
- stable accessibility IDs for compact/Peek/expanded and media controls/source identity;
- strict acceptance inventory with `Tests/Acceptance/coverage-current.json` and explicit approved supersessions, without converting pending/rejected M6.6 gates into accepted ones;
- protocol-based `MediaRuntimeSession` injection for expanded gesture/seek testing while `AppComposition.shipping()` remains the only concrete `ShippingMediaRuntime` construction authority.

The first fully green combined baseline was `e5cdc58776f80f1fc6f57e22959a07704d895fbe` / CI #1095. The protocol-runtime refactor then followed a separate RED `3b79448697d614b7f022009653eca655a31bad4f` / CI #1096 -> GREEN `f49f94d5ab51dcec5dccb97b6c0997ec631b1261` / CI #1099, after which PR #33 was advanced by non-force fast-forward and independently reverified by CI #1100.

## Physical acceptance history

### Stationary-startup hover failure

Candidate `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945 was rejected. Relaunch with the pointer already stationary on the notch could never arm the normal dwell because `show()` passed the initial mouse location with hover activation disabled.

RED `553cf973722dfb214f0fcb741ddb6c9b0b44ff02` / CI #947 reproduced it; GREEN `d17bd27be72c8c3bd022fb2c3613050c398c622e` / CI #948 removed only that startup suppression.

### Expanded pointer-exit / interactive lost-terminal failure

Candidate `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951 passed automation but was rejected on Mac16,8/macOS 26.6:

- clean hover/haptic/Peek did not fire in the observed broken session;
- DOWN expanded successfully, but moving the pointer away left expanded open;
- UP collapse could leave a clipped intermediate panel if shrinking geometry moved out from under the pointer before local scroll delivered its terminal phase.

The pointer-exit failure regressed accepted M1 behavior. The stuck intermediate frame came from relying on local `.ended`/`.cancelled` after geometry could move away from the pointer.

Focused repair evidence:

- RED `0a42a701fcf4fa2f59972a68d2a3b9243203a202` / CI #959: exactly five new regression tests failed while the previous suite passed;
- GREEN `64d3e6c2beadacaeda69c8ac06f173ac26aace3e` restored accepted expanded pointer-exit collapse and synchronous actual-frame settlement;
- subsequent integration and native XCUI coverage preserve that behavior on the current branch.

The hover/haptic symptom is still a physical retest condition. It is not silently considered fixed by automation.

## Security/resource invariants

- App Sandbox-only entitlement and Hardened Runtime remain mandatory.
- No Accessibility, Input Monitoring, Automation, Screen Recording, network, telemetry, history persistence or arbitrary command authority was added.
- Universal Media retains the reviewed fixed `/usr/bin/perl` + pinned adapter/framework boundary.
- Settled compact and Peek own zero persistent adapter; settled expanded owns the expected presentation-scoped runtime; normal Quit must leave no orphan.
- Gesture/Peek/transition hot paths add no polling, repeating timer, display link, global scroll monitor, event tap, per-event process creation or logging.
- UI fixtures and injectable haptic/runtime seams are compile-time test-only; shipping composition still creates concrete `ShippingMediaRuntime`.

## Performance state

`performance/baseline-v0.1.0.json` and historical feature budgets remain immutable provenance records.

The active cumulative integration envelope is `performance/m6-6-regression-foundation-integration-size-budget.json`, provenanced from exact shipping artifact run #1089 / run `31869841148`, source `452f78b0e42c5302702393e9c45c563849661ca4`, artifact `9243156724`. Its measured envelope was app `882687 B`, DMG `552272 B`, executable `580480 B`; allowance is tightly rounded to 4 KiB pages over the immutable `v0.1.0` baseline.

Shared-runner size/performance checks are compatibility gates. Target-Mac CPU/RSS/threads/wakeups/energy acceptance remains separate. P1 does not begin before M6.6 is physically accepted and merged.

## Not yet accepted

- stable compact hover/haptic/Peek, including stationary relaunch;
- expanded pointer exit -> non-haptic exact compact;
- UP/DOWN interactive transitions under pointer/panel separation without intermediate geometry;
- remaining `NH-MEDIA-PEEK-*`, affected `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, `NH-MEDIA-SOURCE-ICON-*`, process ownership and permission checks;
- PR #33 remains draft and unmerged;
- no release claim is made;
- P1 and later multi-display hardening remain blocked by current M6.6 acceptance.

## Next optimal step

1. Run all three canonical CI jobs on this docs-synchronized head.
2. If all green, freeze that exact source SHA and CI-produced shipping artifact/DMG provenance in PR #33 without another source commit.
3. Perform the focused target-Mac retest for clean Hover Peek/haptic, stationary relaunch, expanded pointer exit and lost-terminal UP/DOWN settlement.
4. If the focused block passes, continue the full M6.6 gesture/Peek/seek/source-icon/lifecycle/permission matrix on the same exact candidate.
5. Only after full physical PASS may PR #33 become ready, merge, receive post-merge `main` verification, and unblock P1.
