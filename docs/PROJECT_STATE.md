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

PR #33 `M6.6: app media gesture session TDD` is **implemented / regression-integrated / repaired automated-green before final docs sync / physical retest pending / draft / not merged / not released**.

Current interaction contract:

- stable `compact <-> peek <-> expanded` under one transition authority;
- hover dwell remains exactly 120 ms and opens Peek only;
- usable media is no longer required for Peek: no-media hover opens a lightweight generic Peek and requests the normal hover haptic once;
- one bounded media probe may enrich Peek without creating a persistent compact/Peek observer;
- explicit click or physical DOWN expands;
- exact physical top-edge `maxY` counts as inside the interactive panel, preventing false pointer-exit cancellation of DOWN;
- expanded pointer exit returns non-haptically to exact compact;
- UP/DOWN interactive transitions settle to exact endpoints even if moving geometry leaves the pointer before local terminal scroll delivery;
- physical horizontal direction is frozen as LEFT -> `next`, RIGHT -> `previous`, independent of macOS scroll-direction preference;
- seek, source identity and cursor isolation preserve the existing bounded/event-driven architecture.

No global scroll/button/keyboard monitor, event tap, polling loop, repeating timer, display link, new process boundary or sensitive permission authority was introduced. No UI-test retries or sleeps are used to hide interaction failures.

## Physical video evidence — 2026-08-15

The user-provided target-Mac recording documents the following sequence on exact candidate `6c2109195042759b951217f489a201a82dd044cd` / CI #1156 / run `31892019346`:

1. real music/media playback was already active;
2. NotchHub was then fully Quit while that playback context existed;
3. the horizontal track gestures were physically reversed relative to the frozen product contract: LEFT selected the previous direction instead of `next`, while RIGHT selected the next direction instead of `previous`.

This is physical **FAIL** evidence for `NH-MEDIA-GESTURE-003/004` on candidate `6c210919...`. The recording also establishes that a full NotchHub Quit occurred in the shown sequence after media had started, but it does **not** by itself establish post-Quit helper/adapter teardown; the explicit `pgrep` lifecycle gate remains required. Video likewise cannot establish the felt haptic. Peek direction, permissions and other unobserved M6.6 gates remain unaccepted.

## Horizontal direction root cause and repair

The semantic coordinator was already correct: negative semantic X maps to `next`, positive semantic X maps to `previous`, and typed command mapping preserves those labels. The defect was at the AppKit precise-scroll normalization boundary: X compensated for the user's scroll-direction preference but was not converted from scroll sign to physical LEFT/RIGHT sign. Y normalization was already correct.

Focused TDD evidence:

- RED `f5cb5e3d1f13c7dc5564ce24068e83007f97bb1b` / CI #1157 / run `31897906228`: build and policy gates passed; the 354-test / 75-suite run failed only the two new physical-direction assertions. LEFT produced positive X instead of negative X and RIGHT produced negative X instead of positive X; vertical Y remained correct.
- GREEN `50b82dae49f3ce6c6e194b1ab9775bd5cd5dd430` / CI #1158 / run `31898052051`: the only production change is horizontal normalization `x: -scrollingDeltaX * preferenceScale`; Y, coordinator, thresholds, haptics, lifecycle and transport are unchanged.
- #1158 passed all three canonical jobs, all 354 Swift tests, strict acceptance traceability, exact external-app XCUI, security/source policy, production transport/archive, Sandbox/Hardened Runtime/signing/preflight, release size budget and shared-runner performance smoke.

The corrected direction has **not** yet been physically retested, so LEFT/RIGHT remain pending rather than accepted.

## External-XCUI boundary stabilization

A documentation descendant after #1158 exposed a separate automation defect: `openExpandedExplicitly()` addressed the synthetic click to the transient `notch.surface.compact` accessibility element. When the presentation branch changed between mouse-down and mouse-up, XCTest could lose the click before the actual product assertion.

Several alternatives were deliberately rejected after fail-closed CI evidence:

- application-relative coordinate click did not provide a reliable screen coordinate for the borderless panel;
- raw CoreGraphics click, including a Y-coordinate conversion experiment, did not reliably activate the real tap path;
- an outer SwiftUI AX container hid/broke dynamic state elements and exceeded the active DMG size budget; it was fully reverted and the budget was not relaxed.

The final repair keeps the existing real product tap path and adds a stable accessibility target only to the already-persistent AppKit hosting view under `#if NOTCHHUB_UI_TESTING`. Shipping builds do not contain the test identifier/seam. XCTest performs one ordinary click on the persistent host; dynamic `compact`/`peek`/`expanded` identifiers remain state evidence. No retry, fixed sleep, event tap, raw synthetic shipping input path or new permission authority was added.

Exact pre-docs source `2235c3b3bb7eb69961d76f7b1a5f1afa9307f270` / CI #1177 / run `31904548631` passed **all three canonical jobs** after this repair:

- macOS 26 compatibility — PASS;
- macOS UI regression — PASS, including exact external-app XCUI and shipping-fixture isolation;
- Build, test and package — PASS, including source/security validation, production transport/archive, Sandbox/Hardened Runtime/signing/preflight, unchanged active size budget and performance smoke;
- strict acceptance traceability remains `116/116` with zero unmapped IDs.

The documentation sync creates a new source SHA. That exact descendant must independently pass all three canonical jobs before its source/artifact provenance is frozen for the next target-Mac physical retest.

## Earlier 2026-08-15 repair history

Candidate `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101 was physically rejected with media off because no-media hover produced no Peek/haptic and exact-top-edge DOWN self-collapsed. Repairs introduced generic no-media Peek + hover haptic request, inclusive exact-edge pointer retention and preserved expanded pointer-exit collapse.

Documentation head `a91e196d0ed51fb73a49b680eac1321100cdadb5` / CI #1152 was automatically rejected before physical use because two external XCUI journeys could lose the first explicit click during generic/media root replacement. Focused RED `ac1f004b9a0d2a0fd54c16cb7c0041933d3523df` / CI #1153 -> GREEN `16feb0433f7fdfb18d5eacfcce66707959e6211a` / CI #1155 moved explicit tap authority to the stable outer `MediaNotchRootView`; #1155 passed all canonical jobs without retries/sleeps or new input authority.

## Security/resource invariants

- App Sandbox-only entitlement and Hardened Runtime remain mandatory.
- No Accessibility permission request, Input Monitoring, Automation, Screen Recording, network, telemetry, history persistence or arbitrary command authority was added.
- Universal Media retains the reviewed fixed `/usr/bin/perl` + pinned adapter/framework boundary.
- Settled compact and Peek own zero persistent adapter; settled expanded owns the expected presentation-scoped runtime; normal Quit must leave no orphan.
- Gesture/Peek/transition hot paths add no polling, repeating timer, display link, global scroll monitor, event tap, per-event process creation or logging.
- UI fixtures and injectable haptic/runtime/accessibility seams are compile-time test-only; shipping composition still creates concrete `ShippingMediaRuntime`.

## Performance state

`performance/baseline-v0.1.0.json` and all historical feature budgets remain immutable provenance records.

The active cumulative envelope remains `performance/m6-6-physical-acceptance-20260815-repair-size-budget.json`, provenanced from source `63b0f2f96f879123f3883db7311c90a20d3a4328` / CI #1140 / run `31889213155` / artifact `9248133083`.

Measured budget evidence: app `883039 B`, DMG `555132 B`, executable `580832 B`. Allowance over immutable `v0.1.0`: app `614400 B`, DMG `466944 B`, executable `315392 B`. Only the DMG allowance increased relative to the preceding cumulative envelope, by one 4096-byte review quantum. The direction fix and final compile-time UI-test hosting seam pass this same unchanged size policy; the rejected SwiftUI AX-container experiment did not and was removed rather than expanding the budget.

Shared-runner size/performance checks remain compatibility gates. Target-Mac CPU/RSS/threads/wakeups/energy acceptance remains P1 and does not begin before M6.6 is physically accepted and merged.

## Not yet accepted

- physical LEFT -> next and RIGHT -> previous after the direction repair, in compact and expanded; Peek parity remains pending;
- physical arm haptic for supported horizontal gestures;
- real no-media and media hover -> Peek physical haptic on Mac16,8;
- stationary-pointer relaunch Hover Peek/haptic;
- explicit click while hover/media arrival can replace presentation branches;
- exact-top-edge physical DOWN with no twitch/self-collapse;
- UP/DOWN settlement under pointer/panel separation;
- lifecycle adapter cleanup after real Quit, including explicit empty post-Quit `pgrep` evidence;
- remaining `NH-MEDIA-PEEK-*`, affected `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, `NH-MEDIA-SOURCE-ICON-*` and permission matrix;
- PR #33 remains draft and unmerged;
- no release claim is made;
- P1 and multi-display hardening remain blocked by current M6.6 acceptance.

## Next optimal step

1. Pass all three canonical CI jobs on the final documentation-synchronized PR #33 head.
2. Freeze that exact source SHA and CI-produced shipping artifact/DMG provenance in PR #33 **without another repository commit**.
3. On the target Mac with real media playing, retest physical LEFT -> next and RIGHT -> previous repeatedly in compact and expanded, then Peek; confirm one arm haptic per supported armed transition.
4. Continue the remaining Hover Peek, exact-edge DOWN, pointer-exit, UP/DOWN settlement, seek, source-icon, lifecycle/process and permission matrix on the same exact candidate. After real Quit, explicitly run `pgrep -lf 'mediaremote-adapter\.pl' || true` and require empty output.
5. Only after full physical PASS may PR #33 become ready, merge, receive post-merge `main` verification and unblock P1.
