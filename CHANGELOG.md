# Changelog

All notable changes to NotchHub are documented here. The active version is stored in `VERSION`; published tags/releases are immutable.

## [Unreleased]

Published release remains `v0.1.0`. Everything below is source work not yet published as a new version.

### M6.6 — current draft PR #33

Status: **IMPLEMENTED / REGRESSION-INTEGRATED / AUTOMATED-GREEN BEFORE FINAL DOCS-SYNC CI / PHYSICAL RETEST PENDING / NOT MERGED / NOT RELEASED**.

Added:

- local App-owned media gesture session with bounded horizontal visuals and public AppKit arm haptic;
- stable `compact`, `peek`, `expanded` presentation states under the existing Core transition authority;
- exactly 120 ms Hover Peek activation plus 140 ms pointer-exit grace;
- generic no-media Peek with one hover-haptic request after a valid dwell;
- click and physical DOWN as explicit expansion paths, with explicit tap authority on the stable outer media-aware root above generic/media and compact/Peek replacement;
- bounded one-shot media probing/commands in compact and Peek while persistent runtime remains expanded-only;
- exact-top-edge inclusive pointer retention for interactive DOWN;
- physical horizontal gesture normalization independent of macOS scroll-direction preference: LEFT -> `next`, RIGHT -> `previous`;
- source-app identity badge through public `NSWorkspace` and bounded in-memory cache;
- capability-gated draggable seek in Peek and expanded, identity-locked across track/source changes;
- balanced seek cursor ownership without pointer warp/lock;
- strict native regression/UI automation integrated with M6.6;
- cumulative provenance-backed size budget over immutable P0.

Physical acceptance history:

- first complete candidate `d008f698b323963f084eedce601620ee957ef442` / CI #872 rejected; focused RED -> GREEN cycles repaired hover arbitration, physical vertical direction, stale seek identity and visual continuity;
- docs-synchronized candidate `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945 rejected on stationary-startup Hover Peek; startup RED #947 -> GREEN #948;
- candidate `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951 passed automation but was rejected for expanded pointer-exit and interactive lost-terminal behavior;
- candidate `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101 was rejected on 2026-08-15 for no-media Hover Peek/haptic behavior and exact-top-edge DOWN self-collapse, while expanded pointer-exit and normal-center DOWN/UP remained stable;
- candidate `6c2109195042759b951217f489a201a82dd044cd` / CI #1156 passed all automation but was physically rejected on 2026-08-15 because the target-Mac video with real media playback showed LEFT/RIGHT track gestures reversed relative to the frozen contract.

#### 2026-08-13 expanded pointer-exit / interactive settlement repair

Target testing showed that PR #33 had regressed accepted M1 semantics: after DOWN expansion, moving the pointer out of expanded no longer collapsed the panel. Physical UP could also leave a clipped intermediate panel when shrinking geometry moved out from under the pointer before the local hosting view received `.ended`/`.cancelled`.

The repair restored expanded retention collapse, limited interactive retarget to the pointer-exit fail-safe, passed current mouse location through local precise-scroll updates, and synchronously settled from actual panel geometry when pointer/panel separation could lose terminal local scroll delivery. No global scroll monitor, event tap, watchdog timer, polling loop, display link or new permission authority was introduced.

TDD evidence: RED `0a42a701fcf4fa2f59972a68d2a3b9243203a202` / CI #959 -> GREEN `64d3e6c2beadacaeda69c8ac06f173ac26aace3e`.

#### 2026-08-15 regression foundation integration

Regression/UI Automation Foundation PR #34 was merged to `main` as `bd9566f690d314ed40fd6f3723a319291ceb4a58`; post-merge main CI #1053 passed all three canonical jobs.

Integration work added fail-closed acceptance traceability, exact-app native XCUI, compile-time-only deterministic media/haptic fixtures with shipping-marker isolation, stable accessibility identities, and protocol-based expanded runtime injection while concrete `ShippingMediaRuntime` construction remained shipping-composition authority.

First full combined baseline `e5cdc58776f80f1fc6f57e22959a07704d895fbe` / CI #1095 passed all canonical jobs. Protocol-runtime RED #1096 -> GREEN #1099. PR #33 CI #1100 then independently passed all three jobs with 347 tests / 72 suites, strict 116/116 and native external-app XCUI 9/9.

#### 2026-08-15 Hover Peek / physical-acceptance repair

Target testing of candidate `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101 produced concrete blockers and later automated click races:

- no-media hover remained compact and produced no haptic because the pending design still gated Peek on usable media;
- DOWN starting exactly at the top screen edge used half-open `CGRect.contains` and falsely retargeted to compact;
- external XCUI showed that tap authority below a presentation/root replacement can lose a click while hover/media state changes during synthesis.

Repair:

- no-media hover opens generic Peek first and requests the normal hover haptic once;
- interactive pointer retention includes the exact physical top/right boundary;
- local `NSTrackingArea` is the primary event-driven hover path;
- a proposed mouse-button interception was rejected by the existing security baseline and removed rather than whitelisted;
- explicit click expansion uses one stable SwiftUI tap recognizer on the outer `MediaNotchRootView`, above generic/media and compact/Peek replacement;
- no global scroll/button/keyboard monitor, event tap, polling, repeating timer, display link, UI-test retry/sleep or new sensitive permission was added.

Verification evidence:

- behavior head `63b0f2f96f879123f3883db7311c90a20d3a4328` / CI #1140: 352 Swift tests / 74 suites and external XCUI 11/11 PASS; package failed only because the preceding DMG cumulative ceiling was exceeded by 2172 B;
- size review created `performance/m6-6-physical-acceptance-20260815-repair-size-budget.json`, changing only DMG allowance by one 4096-byte quantum while leaving app/executable allowance unchanged;
- pre-docs head `3e617698a503590dbc18958960a5335753734ccc` / CI #1147: all three canonical jobs PASS;
- docs head `a91e196d0ed51fb73a49b680eac1321100cdadb5` / CI #1152 was automatically rejected because two first-launch explicit-click external XCUI journeys failed;
- focused RED `ac1f004b9a0d2a0fd54c16cb7c0041933d3523df` / CI #1153 -> GREEN `16feb0433f7fdfb18d5eacfcce66707959e6211a` / CI #1155; #1155 passed all canonical jobs, strict/security gates and native external-app XCUI without retries/sleeps.

#### 2026-08-15 horizontal physical-direction video, rejection and repair

The target-Mac video supplied by the user records an important real-world sequence on exact automated-green candidate `6c2109195042759b951217f489a201a82dd044cd` / CI #1156 / run `31892019346`:

1. real music/media playback was already active;
2. NotchHub was then fully Quit while that playback context existed;
3. during the demonstrated horizontal track interactions, physical LEFT selected the previous direction instead of `next`, and physical RIGHT selected the next direction instead of `previous`.

The recording is therefore physical **FAIL** evidence for `NH-MEDIA-GESTURE-003/004` on `6c210919...`. It also confirms that a full NotchHub Quit occurred in the recorded sequence after playback had started, but does not by itself prove helper/adapter-process teardown after Quit; explicit `pgrep` evidence remains required. Video cannot establish felt haptic feedback, and no other unobserved M6.6 gate is promoted to accepted.

Root cause was limited to `MediaGestureInputNormalizer`. The semantic coordinator and typed command mapping were already correct; vertical normalization was also correct. Horizontal normalization compensated for the user's macOS scroll-direction preference but failed to invert AppKit scroll X into the physical LEFT/RIGHT semantic sign.

TDD evidence:

- RED `f5cb5e3d1f13c7dc5564ce24068e83007f97bb1b` / CI #1157 / run `31897906228`: build/policy gates passed; 354 tests / 75 suites ran and only the two new physical-direction assertions failed. LEFT was positive instead of negative X and RIGHT negative instead of positive X; Y remained correct.
- GREEN `50b82dae49f3ce6c6e194b1ab9775bd5cd5dd430` / CI #1158 / run `31898052051`: exactly one production line changed from `x: scrollingDeltaX * preferenceScale` to `x: -scrollingDeltaX * preferenceScale`; Y, semantic direction mapping, thresholds, haptics, lifecycle and transport are unchanged.
- #1158 passed all 354 Swift tests and all three canonical jobs, including strict acceptance traceability, exact external-app XCUI, security/source audit, production transport/archive, Sandbox/Hardened Runtime/signing/preflight, unchanged size gate and performance smoke.

The corrected direction remains **physical-retest pending**; CI does not convert `NH-MEDIA-GESTURE-003/004` to accepted.

#### 2026-08-15 external-XCUI explicit-click stabilization

A docs-only descendant after the direction repair exposed nondeterminism in the test harness rather than the repaired LEFT/RIGHT mapping. `openExpandedExplicitly()` was sending `click()` to transient `notch.surface.compact`; if the SwiftUI presentation element was replaced between XCTest mouse-down and mouse-up, multiple product journeys failed before reaching their actual assertions.

Fail-closed investigation rejected three alternatives rather than hiding the issue:

- application-relative coordinate clicking failed the explicit-expansion journeys;
- raw CoreGraphics `CGEvent` clicking, including a vertical coordinate-conversion attempt, also failed them;
- placing a persistent AX container on the outer SwiftUI root hid/broke the dynamic state accessibility elements and exceeded the active DMG size ceiling by 171 B. That experiment was fully reverted and the performance budget was **not** relaxed.

Final repair keeps the product tap path unchanged and exposes `notch.surface.hitTarget` only on the already-persistent AppKit hosting view under `#if NOTCHHUB_UI_TESTING`. The XCTest helper makes one ordinary `XCUIElement.click()` on that stable host. Shipping builds do not contain this test identifier/seam; dynamic `compact`/`peek`/`expanded` accessibility state remains intact; no retries, fixed sleeps, event tap, raw synthetic shipping input or sensitive permission authority were added.

Exact source `2235c3b3bb7eb69961d76f7b1a5f1afa9307f270` / CI #1177 / run `31904548631` passed **all three canonical jobs** after the final repair: macOS 26 compatibility, exact external-app UI regression with shipping-fixture isolation, and full build/test/package with source/security validation, production transport/archive, Sandbox/Hardened Runtime/signing/preflight, the then-active size budget and performance smoke. Strict acceptance traceability remained 116/116.

#### 2026-08-16 nonactivating first-click and bounded Peek-probe race repair

Later canonical runs exposed that the remaining click nondeterminism was product-level, not merely locator-level.

First, the persistent hosting view did not explicitly accept first mouse. Focused RED `7acd508...` added `hostingViewAcceptsFirstMouseForNonactivatingPanelInteraction`; GREEN `73dba83...` added only `acceptsFirstMouse(for:) = true`. SwiftUI tap remained the explicit click authority and no mouse-button monitor was added.

That production change moved the DMG just beyond the prior intentionally tight envelope. A new immutable cumulative envelope, `performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json`, increased only the DMG allowance by one 4096-byte review quantum; app/executable allowances remained unchanged and all older budgets stayed historical. The active allowances over immutable `v0.1.0` are app `614400 B`, DMG `471040 B`, executable `315392 B`.

Exact source `122019646547b828b18fd4cc1d8776ff929fb588` / CI #1191 / run `31914764732` then passed compatibility and the complete package/security/performance path, while external XCUI correctly failed `testTenHoverExitCyclesNeverLeaveStaleSurface`. The failing click spent about 5.4 seconds inside synthesis/idle where normal clicks were sub-second; the separate unsupported-capability journey passed.

Root cause: `XCUIElement.click()` moves the real pointer over the notch before the click completes. That hover could settle Peek and start the real bounded shipping media probe. Retarget/cancellation then synchronously owned process teardown on the main actor, so optional Peek enrichment could block the click path long enough to swallow expansion.

The final repair keeps enrichment outside the transition/click critical path:

- RED `6072b06f4564b1ef4c90d327e52187f743009705` / CI #1192 / run `31937746016`: 357 tests ran and exactly the new settled-probe policy failed;
- `MediaPeekSession.handleHoverRequest` now opens generic Peek without starting the subprocess probe; `probe.acquire` may start only after authoritative `.peek` settlement;
- settlement-only head `ab62544...` was insufficient: compatibility/package passed but external smoke became abnormally long and the superseded run was cancelled, so it is not acceptance evidence;
- final source `8656a0d921252c8ab5847716ad5e3d65a6540301` additionally suppresses optional Peek enrichment when `NSEvent.pressedMouseButtons != 0` at settled Peek. This is read-only side-effect gating, not mouse-button authority: no `.leftMouseDown/.leftMouseUp` handler, monitor, event tap, polling, retry, sleep or new permission was introduced;
- CI #1196 / run `31938446872` passed all three canonical jobs, all **357 Swift tests** and exact external-app XCUI **11/11**. `testTenHoverExitCyclesNeverLeaveStaleSurface` passed, unsupported-capability behavior passed, and stress click synthesis returned to roughly **0.3–0.4 s** instead of the prior ~5.4 s stall;
- the existing first-click size envelope passed unchanged on #1196 with app `883087 B`, DMG `557138 B`, executable `580880 B`;
- #1196 artifacts: UI result `9261436160` / `sha256:b6eab0dd2453a0080bd40734cacb5f07a42eb4b77f5ec7b916b4e03a7ece9944`; shipping-media candidate `9261415381` / `sha256:990b5de2883263c311bff63b2849ba5d521f98b2588200bd68840b4c3c805151`; DMG `9261416876` / `sha256:4ea12ca928cdbf6283608625dea6c7abf0e859007495a0826fca1b24f60eb160`; performance metadata `9261416671` / `sha256:7c37ccbe6f55a5d3aa90c2fede9b8b9e55a5f4da50e5511602abdc5f027d0d27`; production transport candidate `9261398118` / `sha256:0bc1e3d025db44070a98edf65ae5ce88b778c23935de67134f05be2418442a1b`; MediaBridge probe candidate `9261391923` / `sha256:30ddbb1084d7d0e3cc35291e8a3c91ec6a3fdd4235af3a5cd0a8a125586e9a07`.

This changelog/docs synchronization creates a new source SHA. That exact descendant must independently pass all three canonical jobs before its source/artifact provenance is frozen for target-Mac retest. PR #33 remains draft, unmerged and unreleased; no physical gate is promoted by CI evidence.

### Earlier M6.6 prerequisites

- Task 0 collapse-layout retarget hardening physically accepted and merged via PR #22.
- Task 1 one-shot lifecycle ownership automated-accepted and merged via PR #24.
- Deterministic gesture engine, local gesture seam and bounded compact commands merged via PRs #26-#28.
- Interactive transition authority and vertical visual tracking merged via PRs #31-#32.

### M6.1-M6.5

- M6.1 system Now Playing feasibility accepted on target hardware.
- M6.2 normalized media controller/bridge boundary accepted and merged.
- M6.3 fixed pinned production media transport accepted and merged.
- M6.4 shipping composition/lazy expanded-only runtime accepted and merged.
- M6.5 Media-first compact/expanded UI accepted and merged.

### Engineering/security/performance foundations

- M0 native Swift 6 / SwiftUI + AppKit foundation, hardware-notch geometry, deterministic hover and strict CI/security/release policy accepted and merged.
- M1 primary interaction/transition foundation accepted and merged.
- P0 immutable performance/artifact baseline and target measurement methodology accepted; historical baseline files remain immutable.
- Regression/UI Automation Foundation merged via PR #34 and is now a mandatory three-job CI product gate.
- App Sandbox-only + Hardened Runtime remain mandatory; no telemetry/direct app network/sensitive input permission surface has been added.

## [0.1.0] - 2026-08-07

### Added

- Initial native macOS NotchHub application foundation.
- Hardware-notch geometry and compact/expanded states.
- App Sandbox + Hardened Runtime and strict CI/security/release packaging.
- Personal Release DMG with checksum/provenance metadata.

### Acceptance

`NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, `NH-HOVER-003` and Personal Release acceptance passed on the target Mac. `v0.1.0` is immutable and intentionally ad-hoc signed/not notarized.
