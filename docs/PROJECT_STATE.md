# Project state

Last updated: 2026-08-16
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

PR #33 `M6.6: app media gesture session TDD` is **implemented / regression-integrated / technical automated-green / final docs-synchronized CI pending / physical retest pending / draft / not merged / not released**.

Current interaction contract:

- stable `compact <-> peek <-> expanded` under one transition authority;
- hover dwell remains exactly 120 ms and opens Peek only;
- usable media is no longer required for Peek: no-media hover opens a lightweight generic Peek and requests the normal hover haptic once;
- optional media enrichment is deferred until authoritative Peek settlement and is suppressed if a physical mouse press is already in progress, so subprocess acquisition/teardown cannot block an explicit click;
- settled compact and Peek still own zero persistent media observer; only settled expanded owns the presentation-scoped shipping runtime;
- explicit click remains one stable SwiftUI tap path. The persistent AppKit host accepts first mouse for the nonactivating panel but does not become mouse-button authority;
- explicit click or physical DOWN expands;
- exact physical top-edge `maxY` counts as inside the interactive panel, preventing false pointer-exit cancellation of DOWN;
- expanded pointer exit returns non-haptically to exact compact;
- UP/DOWN interactive transitions settle to exact endpoints even if moving geometry leaves the pointer before local terminal scroll delivery;
- physical horizontal direction is frozen as LEFT -> `next`, RIGHT -> `previous`, independent of macOS scroll-direction preference;
- seek, source identity and cursor isolation preserve the existing bounded/event-driven architecture.

No global scroll/button/keyboard monitor, mouse-button event authority, event tap, polling loop, repeating timer, display link, new process boundary or sensitive permission authority was introduced. `NSEvent.pressedMouseButtons` is read only at settled Peek to suppress optional enrichment during an already-active press. No UI-test retries or sleeps are used to hide interaction failures.

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

## External-XCUI and first-click stabilization

The first automation issue was locator instability: `openExpandedExplicitly()` clicked transient `notch.surface.compact`, which could disappear between mouse-down and mouse-up. Rejected alternatives included application-relative coordinates, raw CoreGraphics click synthesis and an outer SwiftUI AX container that broke state accessibility and exceeded the active DMG envelope. The accepted harness exposes a stable test-only accessibility target on the already-persistent AppKit hosting view while keeping the real SwiftUI tap product path.

Exact source `2235c3b3bb7eb69961d76f7b1a5f1afa9307f270` / CI #1177 / run `31904548631` passed all three canonical jobs after that locator repair.

A later canonical run exposed a separate product first-click boundary: the nonactivating hosting view did not explicitly accept first mouse. Focused RED `7acd508...` -> GREEN `73dba83...` added only `acceptsFirstMouse(for:) = true`; no monitor/input authority was introduced.

That tiny production change required a new immutable cumulative size envelope because the DMG crossed the previous intentionally tight ceiling. `performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json` increased only the DMG allowance by one 4096-byte review quantum. All historical budgets remain immutable and inactive.

## 2026-08-16 bounded Peek-probe / click race repair

After first-mouse acceptance, exact source `122019646547b828b18fd4cc1d8776ff929fb588` / CI #1191 / run `31914764732` passed compatibility and the complete build/test/package/security/performance job but failed one external XCUI journey: `testTenHoverExitCyclesNeverLeaveStaleSurface`. The separate unsupported-capability journey passed.

The failing stress click spent about **5.4 seconds** in XCTest event synthesis/idle instead of the normal sub-second path and never reached `expanded`.

Root cause:

- `XCUIElement.click()` moves the real pointer into the notch before completing the click;
- the ordinary 120 ms hover path could therefore settle generic Peek while the click was in flight;
- `MediaPeekSession.handleHoverRequest` immediately started the real bounded shipping media probe;
- retarget/cancellation then owned synchronous process teardown on the main actor, so optional Peek enrichment could block the explicit click path for several seconds.

Fail-first repair evidence:

- RED `6072b06f4564b1ef4c90d327e52187f743009705` / CI #1192 / run `31937746016`: **357 tests**, exactly one failure — the new `boundedPeekProbeStartsOnlyAfterPeekSettlement` policy;
- settlement-only descendant `ab62544...` moved `probe.acquire` out of hover request and into authoritative `.peek` settlement. Compatibility/package were green, but external smoke became abnormally long; that superseded run was cancelled and is not acceptance evidence;
- final source `8656a0d921252c8ab5847716ad5e3d65a6540301` additionally suppresses optional Peek enrichment when `NSEvent.pressedMouseButtons != 0` at settled Peek. This is read-only side-effect gating, not click authority; there is no `.leftMouseDown/.leftMouseUp` handling, monitor, event tap, polling, retry, sleep or permission expansion.

Technical exact-head CI #1196 / run `31938446872` on `8656a0d...` is **3/3 GREEN**:

- `macOS 26 compatibility` — PASS, all **357 Swift tests**;
- `macOS UI regression` — PASS, exact external-app XCUI **11/11**, including `testTenHoverExitCyclesNeverLeaveStaleSurface` and unsupported-capability behavior;
- `Build, test and package` — PASS, including strict 116/116 traceability, source/security baseline, production transport/archive, Sandbox/Hardened Runtime/signing/preflight, existing active first-click size budget and shared-runner performance smoke.

The stress log shows the prior ~5.4 s click stall is gone: representative repeated stress clicks complete event synthesis/idle in roughly **0.3–0.4 s**.

#1196 artifact provenance:

- UI `.xcresult`: artifact `9261436160`, digest `sha256:b6eab0dd2453a0080bd40734cacb5f07a42eb4b77f5ec7b916b4e03a7ece9944`;
- shipping-media candidate: `9261415381`, digest `sha256:990b5de2883263c311bff63b2849ba5d521f98b2588200bd68840b4c3c805151`;
- DMG: `9261416876`, digest `sha256:4ea12ca928cdbf6283608625dea6c7abf0e859007495a0826fca1b24f60eb160`;
- performance metadata: `9261416671`, digest `sha256:7c37ccbe6f55a5d3aa90c2fede9b8b9e55a5f4da50e5511602abdc5f027d0d27`;
- production transport candidate: `9261398118`, digest `sha256:0bc1e3d025db44070a98edf65ae5ce88b778c23935de67134f05be2418442a1b`;
- MediaBridge probe candidate: `9261391923`, digest `sha256:30ddbb1084d7d0e3cc35291e8a3c91ec6a3fdd4235af3a5cd0a8a125586e9a07`.

#1196 measured shipping sizes: app `883087 B`, DMG `557138 B`, executable `580880 B`.

This state-file synchronization creates a new source SHA. Therefore #1196 is technical repair evidence, **not** the frozen physical candidate. The final documentation-synchronized head must independently pass all three canonical jobs before its SHA/artifact provenance is frozen without another repository commit.

## Earlier 2026-08-15 repair history

Candidate `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101 was physically rejected with media off because no-media hover produced no Peek/haptic and exact-top-edge DOWN self-collapsed. Repairs introduced generic no-media Peek + hover haptic request, inclusive exact-edge pointer retention and preserved expanded pointer-exit collapse.

Documentation head `a91e196d0ed51fb73a49b680eac1321100cdadb5` / CI #1152 was automatically rejected before physical use because two external XCUI journeys could lose the first explicit click during generic/media root replacement. Focused RED `ac1f004b9a0d2a0fd54c16cb7c0041933d3523df` / CI #1153 -> GREEN `16feb0433f7fdfb18d5eacfcce66707959e6211a` / CI #1155 moved explicit tap authority to the stable outer `MediaNotchRootView`; #1155 passed all canonical jobs without retries/sleeps or new input authority.

## Security/resource invariants

- App Sandbox-only entitlement and Hardened Runtime remain mandatory.
- No Accessibility permission request, Input Monitoring, Automation, Screen Recording, network, telemetry, history persistence or arbitrary command authority was added.
- Universal Media retains the reviewed fixed `/usr/bin/perl` + pinned adapter/framework boundary.
- Settled compact and Peek own zero persistent adapter; optional bounded Peek enrichment starts only after settled Peek and is skipped during an already-active mouse press; settled expanded owns the expected presentation-scoped runtime; normal Quit must leave no orphan.
- Gesture/Peek/transition hot paths add no polling, repeating timer, display link, global scroll/button monitor, event tap, per-event process creation or logging.
- UI fixtures and injectable haptic/runtime/accessibility seams are compile-time test-only; shipping composition still creates concrete `ShippingMediaRuntime`.

## Performance state

`performance/baseline-v0.1.0.json` and all historical feature budgets remain immutable provenance records.

The active cumulative envelope is now `performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json`. It preserves app allowance `614400 B` and executable allowance `315392 B` over immutable `v0.1.0`; DMG allowance is `471040 B`, one 4096-byte review quantum above the 2026-08-15 repair envelope.

Technical #1196 measured app `883087 B`, DMG `557138 B`, executable `580880 B`, all within that unchanged active envelope. The 2026-08-16 Peek-probe/click repair required **no further size-budget expansion**.

Shared-runner size/performance checks remain compatibility gates. Target-Mac CPU/RSS/threads/wakeups/energy acceptance remains P1 and does not begin before M6.6 is physically accepted and merged.

## Not yet accepted

- physical LEFT -> next and RIGHT -> previous after the direction repair, in compact and expanded; Peek parity remains pending;
- physical arm haptic for supported horizontal gestures;
- real no-media and media hover -> Peek physical haptic on Mac16,8;
- stationary-pointer relaunch Hover Peek/haptic;
- explicit click while hover/media arrival can replace/enrich presentation branches — automated 10-cycle stress is green, but target-Mac physical confirmation is still required;
- exact-top-edge physical DOWN with no twitch/self-collapse;
- UP/DOWN settlement under pointer/panel separation;
- lifecycle adapter cleanup after real Quit, including explicit empty post-Quit `pgrep` evidence;
- remaining `NH-MEDIA-PEEK-*`, affected `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, `NH-MEDIA-SOURCE-ICON-*` and permission matrix;
- PR #33 remains draft and unmerged;
- no release claim is made;
- P1 and multi-display hardening remain blocked by current M6.6 acceptance.

## Next optimal step

1. Pass all three canonical CI jobs on **this final documentation-synchronized PR #33 head**.
2. If and only if that exact head is 3/3 GREEN, freeze its source SHA and CI-produced shipping artifact/DMG provenance in PR #33 **without another repository commit**.
3. On the target Mac with real media playing, retest physical LEFT -> next and RIGHT -> previous repeatedly in compact and expanded, then Peek; confirm one arm haptic per supported armed transition.
4. Exercise compact click while Hover Peek/media enrichment overlaps, requiring one prompt expanded transition with no visible stall or swallowed click.
5. Continue the remaining Hover Peek, exact-edge DOWN, pointer-exit, UP/DOWN settlement, seek, source-icon, lifecycle/process and permission matrix on the same exact candidate. After real Quit, explicitly run `pgrep -lf 'mediaremote-adapter\.pl' || true` and require empty output.
6. Only after full physical PASS may PR #33 become ready, merge, receive post-merge `main` verification and unblock P1.
