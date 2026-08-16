# Media Peek Acceptance

Status: AUTOMATED REPAIR GREEN / FINAL DOCS-SYNC CI PENDING / TARGET-MAC PHYSICAL RETEST PENDING
Date: 2026-08-16
Target: macOS 26.6 / Mac16,8
Scope: M6.6 PR #33 Hover Peek physical-acceptance repair

This ledger is additive. Existing `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, and `NH-MEDIA-SOURCE-ICON-*` IDs are not renumbered or weakened.

## Current contract

- Stable presentation states remain `compact`, `peek`, and `expanded` under the existing single panel/transition authority.
- Hover activation dwell remains exactly 120 ms.
- Peek pointer-exit grace remains exactly 140 ms.
- Hover previews Peek; click or physical DOWN explicitly expands.
- A pointer already stationary inside the compact hover region when the app is shown/restarted remains eligible for the normal 120 ms dwell; no leave/re-enter is required.
- **Usable media is no longer a prerequisite for Peek.** A valid hover dwell first opens a lightweight generic Peek and requests the normal hover haptic exactly once. Media enrichment is optional: one bounded probe may start only after authoritative Peek settlement, and it is suppressed when a physical mouse press is already in progress so enrichment cannot block or steal explicit click expansion. `.noSession` leaves the generic Peek visible rather than collapsing it.
- Settled compact and Peek own zero persistent media observer; only settled expanded owns the presentation-scoped shipping runtime.
- Leaving expanded retention returns to exact compact non-haptically, preserving accepted M1 behavior.
- Interactive expansion/collapse always settles to an exact stable endpoint when current geometry moves out from under the pointer; an intermediate frame is never a valid settled state.
- The exact top screen/panel `maxY` boundary counts as inside the interactive panel. A DOWN gesture started with the pointer physically against the top screen edge must not self-cancel as a false pointer exit.
- Explicit tap expansion is owned by one stable SwiftUI surface above **both** the generic/media outer branch and the compact/Peek presentation switch, so hover/media arrival cannot destroy a click already in flight. The persistent AppKit hosting view accepts first mouse for the nonactivating panel, but does not become click authority.
- Seek hides the cursor only while a valid seek interaction owns it; no pointer warp/lock is used in production.
- Vertical DOWN/UP gestures intentionally add no new haptic. Hover-to-Peek and supported horizontal arm semantics remain the haptic paths.
- Pointer delivery remains event-driven: local `NSTrackingArea` is the primary hover path; the existing narrow `.mouseMoved` fallback remains unchanged. No global scroll/button/keyboard monitor, mouse-button event authority, event tap, polling loop, repeating timer, display link, retry/sleep masking, or new sensitive permission is introduced. The settled-Peek enrichment guard reads `NSEvent.pressedMouseButtons` only to avoid starting optional subprocess work during an already-active press.

The superseding no-media decision is documented in `docs/superpowers/specs/2026-08-15-no-media-hover-peek-physical-repair.md`. The 2026-08-12 Hover Peek design remains historical design context where it conflicts with this later physical-acceptance decision.

## Candidate provenance rule

The physical candidate is the final documentation-synchronized PR head only after that exact head passes all three canonical CI jobs:

- `macOS 26 compatibility`;
- `macOS UI regression`;
- `Build, test and package`.

Its source SHA, workflow run, shipping artifact, DMG artifact/digest, measured sizes and contained DMG hash are then frozen in PR #33 without another repository commit.

## Physical rejection history

### Candidate `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945

Rejected on Mac16,8/macOS 26.6. A stationary relaunch could fail to arm Hover Peek because `NotchPanelController.show()` synchronized `NSEvent.mouseLocation` with activation disabled. Focused RED `553cf973722dfb214f0fcb741ddb6c9b0b44ff02` / CI #947 reproduced the defect; GREEN `d17bd27be72c8c3bd022fb2c3613050c398c622e` / CI #948 removed only that startup suppression.

### Candidate `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951

Rejected despite green automation:

1. normal hover in the broken physical session did not produce the expected haptic/Peek transition;
2. physical DOWN could expand, but moving the pointer outside expanded did not auto-collapse;
3. physical UP collapse could remain at an intermediate frame if shrinking geometry moved away before local scroll delivered `.ended`/`.cancelled`.

The pointer-exit failure regressed accepted M1 behavior. The lost-terminal repair restored expanded pointer-exit collapse and synchronous actual-frame settlement without adding global input capture.

### Candidate `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101 / run `31871250982`

Rejected on 2026-08-15 on Mac16,8/macOS 26.6. Music/media was off for the whole test.

Observed:

1. holding the pointer over the physical notch for several seconds produced no Peek and no haptic; explicit click still opened full expanded UI;
2. removing the pointer from expanded correctly returned to compact — the prior pointer-exit repair remained PASS;
3. DOWN started exactly against the top screen edge moved the panel slightly and immediately returned to compact;
4. DOWN started slightly lower, around the center of the physical notch, was stable and reliable;
5. UP collapse was stable;
6. no haptic was felt in the tested paths.

Root causes and product decision:

- exact top-edge DOWN used half-open `CGRect.contains`, so a pointer exactly on `frame.maxY` was treated as outside and synchronously retargeted to compact;
- the old pending no-media contract intentionally gated Peek on usable media, so `.noSession` could never satisfy the new physical requirement;
- external XCUI later exposed click races whenever tap ownership lived below a presentation/root branch that could be replaced during click synthesis;
- a proposed mouse-button event boundary was rejected by the existing security baseline and removed. The final solution keeps no new mouse-button authority and uses one normal SwiftUI tap recognizer on the stable outer media-aware root.

## Focused TDD repair evidence

The 2026-08-15 repair was developed fail-first and then exercised through the exact external application:

- unit RED reproduced no-media gating and exact `maxY` containment;
- `NotchPointerPolicy.containsInteractivePointer` uses inclusive interactive containment for the physical boundary;
- `MediaPeekSession` opens generic Peek before the bounded media probe, so `.noSession` no longer blocks hover activation;
- compile-time-only UI diagnostics record haptic requests at the same transition-coordinator boundary as the production AppKit haptic performer; shipping-marker verification proves these fixtures do not enter the production binary;
- a local `NSTrackingArea` supplies primary event-driven hover entry/move/exit without polling;
- the external UI harness parks the real test pointer deterministically between journeys and separately verifies stationary-pointer relaunch behavior;
- first behavior head `63b0f2f96f879123f3883db7311c90a20d3a4328` / CI #1140 / run `31889213155` passed 352 Swift tests / 74 suites and 11/11 external XCUI journeys; its package job failed only because the DMG exceeded the previous cumulative ceiling by 2172 B;
- the cumulative size envelope changes only the DMG allowance by one 4096-byte review quantum. App and executable allowances are unchanged; immutable `v0.1.0` and all historical budgets remain untouched;
- pre-docs head `3e617698a503590dbc18958960a5335753734ccc` / CI #1147 / run `31889961194` passed all three canonical jobs;
- docs head `a91e196d0ed51fb73a49b680eac1321100cdadb5` / CI #1152 / run `31890935022` was **automatically rejected before physical use**: compatibility/package stayed green, but two external XCUI journeys lost their first explicit click because media/root replacement could still destroy the recognizer;
- focused RED `ac1f004b9a0d2a0fd54c16cb7c0041933d3523df` / CI #1153 / run `31891311328`: 354 tests / 75 suites, with only the new root tap-ownership regression test failing;
- GREEN `16feb0433f7fdfb18d5eacfcce66707959e6211a` / CI #1155 / run `31891464496`: tap authority moved to the stable outer `MediaNotchRootView` `ZStack`; nested generic `NotchRootView` retains standalone tap behavior by default but disables its child tap in media-aware composition; all three canonical jobs and the native external-app XCUI suite PASS without retries/sleeps.

CI #1155 shipping evidence:

- shipping-media artifact `9248700272`, digest `sha256:509826b1c36b46d406a87621bbe83b4aa039c2aff40422b9be1ce46ecef99d2f`;
- DMG artifact `9248701623`, digest `sha256:860b36a3ae6a740490e177847634e5d76ed9be913afb89ec7cc87a7128e4f050`;
- UI result artifact `9248698799`, digest `sha256:83522a4ec996649d5dcc5e0f99332bf921fb322efe1d86f8e9f3f4182ec85730`;
- executable `580912 B`;
- app `883119 B`;
- DMG `555204 B`;
- historical cumulative budget `performance/m6-6-physical-acceptance-20260815-repair-size-budget.json` passed unchanged at that point.

### 2026-08-16 first-click and Peek-probe race repair

A later exact-app stress run exposed two separate contributors to swallowed explicit clicks in the nonactivating panel:

1. the persistent hosting view did not explicitly accept first mouse, so AppKit activation could consume a first click before SwiftUI received it;
2. after first-mouse acceptance was repaired, a repeated 10-cycle XCUI journey still found a deeper race. `XCUIElement.click()` moves the real pointer into the notch before the click completes. Hover could therefore open Peek and start the real bounded shipping media probe while the click was in flight. Cancelling that probe owns synchronous process teardown on the main actor; the failing #1191 click spent about 5.4 seconds in event synthesis instead of the normal sub-second path and never reached `expanded`.

Fail-first evidence and repair:

- first-mouse RED `7acd508...` proved the hosting view lacked first-click policy; GREEN `73dba83...` added only `acceptsFirstMouse(for:) = true`, preserving SwiftUI tap authority and adding no input monitor;
- final first-click size envelope is `performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json`; historical envelopes remain immutable. The active allowance is app `614400 B`, DMG `471040 B`, executable `315392 B` over immutable `v0.1.0`;
- exact source `122019646547b828b18fd4cc1d8776ff929fb588` / CI #1191 / run `31914764732` passed compatibility and the complete package/security/performance job, but external XCUI correctly failed `testTenHoverExitCyclesNeverLeaveStaleSurface`; `testUnsupportedCapabilitiesStayDisabledAndDoNotChangeTrack` passed;
- settlement-policy RED `6072b06f4564b1ef4c90d327e52187f743009705` / CI #1192 / run `31937746016`: 357 tests ran and exactly the new `boundedPeekProbeStartsOnlyAfterPeekSettlement` policy failed;
- the first settlement-only repair `ab62544...` moved `probe.acquire` out of `handleHoverRequest` and into authoritative Peek settlement. Its #1194 compatibility/package jobs passed, but external smoke became abnormally long and the superseded run was cancelled, so that descendant was **not** accepted as evidence;
- the final repair additionally suppresses optional Peek enrichment when `NSEvent.pressedMouseButtons != 0` at settled Peek. This is a read-only side-effect guard: it neither handles mouse-down/up nor creates a monitor, event tap, retry, sleep, polling loop or new permission. The stable SwiftUI tap remains the sole click expansion authority;
- exact technical source `8656a0d921252c8ab5847716ad5e3d65a6540301` / CI #1196 / run `31938446872` passed all three canonical jobs, all 357 Swift tests and native external-app XCUI 11/11. The 10-cycle stress journey passed, unsupported-capability behavior passed, and the prior ~5.4 s click-synthesis stall disappeared; observed stress clicks returned to approximately 0.3–0.4 s event-synthesis/idle completion;
- #1196 package/security/performance evidence passed the existing active first-click budget without expansion: app `883087 B`, DMG `557138 B`, executable `580880 B`;
- #1196 UI result artifact `9261436160`, digest `sha256:b6eab0dd2453a0080bd40734cacb5f07a42eb4b77f5ec7b916b4e03a7ece9944`;
- #1196 shipping-media artifact `9261415381`, digest `sha256:990b5de2883263c311bff63b2849ba5d521f98b2588200bd68840b4c3c805151`;
- #1196 DMG artifact `9261416876`, digest `sha256:4ea12ca928cdbf6283608625dea6c7abf0e859007495a0826fca1b24f60eb160`;
- #1196 performance metadata artifact `9261416671`, digest `sha256:7c37ccbe6f55a5d3aa90c2fede9b8b9e55a5f4da50e5511602abdc5f027d0d27`;
- #1196 production transport candidate `9261398118`, digest `sha256:0bc1e3d025db44070a98edf65ae5ce88b778c23935de67134f05be2418442a1b`;
- #1196 MediaBridge probe candidate `9261391923`, digest `sha256:30ddbb1084d7d0e3cc35291e8a3c91ec6a3fdd4235af3a5cd0a8a125586e9a07`.

This documentation change creates a descendant source SHA, so #1196 is technical repair evidence rather than the final physical candidate. The final docs-synchronized head must independently pass all three canonical jobs before candidate provenance is frozen.

This automated evidence does **not** convert physical haptic feedback, physical trackpad direction/geometry, lifecycle `pgrep`, or permission behavior into a PASS. Those remain target-Mac acceptance requirements.

## Stable acceptance IDs

| ID | Gate | Required result | Automated | Physical |
|---|---|---|---|---|
| `NH-MEDIA-PEEK-001` | Hover destination + stationary restart | With usable media, 120 ms hover opens Peek only and requests the expected Peek haptic exactly once; hover never opens full expanded UI. Relaunch with the pointer already stationary on the notch behaves the same without extra movement. | Unit + external XCUI GREEN through #1196 | FAIL on prior candidates; RETEST REQUIRED |
| `NH-MEDIA-PEEK-002` | No-media hover | With no retained/fresh media, the same valid 120 ms dwell opens a generic lightweight Peek, requests one hover haptic, never opens expanded, and does not start persistent media observation. A bounded `.noSession` result may leave the generic Peek visible. | Unit + external XCUI GREEN through #1196 | PENDING |
| `NH-MEDIA-PEEK-003` | Fast pointer pass | Pointer transit shorter than dwell does not expand or leave Peek stuck. | Covered | PENDING |
| `NH-MEDIA-PEEK-004` | 140 ms grace | Exit/re-entry before 140 ms keeps Peek; remaining outside through the deadline returns to compact. | Covered | PENDING |
| `NH-MEDIA-PEEK-005` | Explicit expansion | Free-surface click and physical DOWN from Peek each open expanded exactly once; compact click also explicitly expands even while hover/media state changes during the click. | Root-ownership RED #1153 -> GREEN #1155; first-mouse + settled/press-aware probe repair; #1196 external XCUI 11/11 + 10-cycle stress PASS | PENDING |
| `NH-MEDIA-PEEK-006` | Peek horizontal gestures | LEFT -> next and RIGHT -> previous use bounded one-shot work; hover cannot steal an owned gesture. | Covered | PENDING |
| `NH-MEDIA-PEEK-007` | Peek seek | Timeline seek works in Peek without expanding and suppresses notch gestures while active. | Covered | PENDING |
| `NH-MEDIA-PEEK-008` | Seek cursor | Cursor hides only after valid seek begin and is restored on every commit/cancel/identity/app lifecycle path; no production warp/lock. | Covered | PENDING |
| `NH-MEDIA-PEEK-009` | Track continuity | Track/source changes update the active media branch without an obvious Home/interface blink while media remains valid. | Covered | PENDING |
| `NH-MEDIA-PEEK-010` | Downward continuity | Compact DOWN follows interactive expansion. Starting exactly at the physical top screen edge is valid; no false pointer-exit twitch/self-collapse or intermediate settled frame is allowed. | Focused unit GREEN; external regression suite GREEN through #1196 | FAIL on #1101 exact-edge case; RETEST REQUIRED |
| `NH-MEDIA-PEEK-011` | Expanded collapse + pointer exit | Expanded physical UP returns to exact compact. Leaving expanded retention also returns to compact non-haptically. Interactive collapse cannot remain at an intermediate frame when visible geometry moves away or terminal local scroll delivery is lost. | Prior RED -> GREEN + external XCUI through #1196 | FAIL on older candidate; pointer-exit PASS on #1101; RETEST REQUIRED |
| `NH-MEDIA-PEEK-012` | Lifecycle | Settled compact, settled Peek, cancelled/retargeted transitions and normal Quit leave no unexpected persistent `mediaremote-adapter.pl` process. Optional Peek enrichment starts only after settled Peek and is suppressed during an already-active mouse press; cancelled ownership remains bounded. | Unit/process teardown + package/security GREEN through #1196 | PENDING |
| `NH-MEDIA-PEEK-013` | Permissions | No Accessibility, Input Monitoring, Automation or Screen Recording prompts are introduced. | Security/policy GREEN through #1196 | PENDING |

## Focused target-Mac procedure

Use only the exact final docs-synchronized candidate frozen in PR #33 after its exact head passes all three canonical CI jobs.

1. **Music/media OFF.** Start from stable compact, enter the physical notch and hold. After normal dwell, require generic Peek + one physical haptic. Full expanded/Home must not open from hover alone.
2. With music still off, relaunch while the pointer is already stationary over the physical notch. Without leaving/re-entering, require the same generic Peek + one physical haptic.
3. From compact, click normally while hover is eligible and, separately, while media presentation is appearing/changing. Require full expanded exactly once; neither 120 ms Peek activation nor generic/media branch replacement/probe teardown may swallow or noticeably stall the click.
4. Return to compact. Put the pointer completely against the physical top screen edge and perform DOWN. Require stable follow-finger expansion with no small downward twitch followed by self-collapse.
5. Repeat DOWN with the pointer slightly lower near the notch center. Require the same stable behavior.
6. From expanded, simply move the pointer outside. Require a non-haptic automatic return to exact compact.
7. Expand again and perform physical UP with a relatively stationary pointer. Require exact compact; no clipped intermediate frame may remain if shrinking geometry moves away.
8. Repeat UP while deliberately moving the pointer outside during the owned gesture. Again require exact compact.
9. Repeat the hover/click/DOWN/UP/pointer-exit cycle several times. Any missing physical haptic, swallowed/stalled click, top-edge twitch, stuck geometry or unexpected full hover expansion remains a blocker.
10. Only after this focused block passes continue the remaining horizontal gesture, seek, source-icon, lifecycle and permission matrix on the same exact candidate.

## Acceptance rule

Any required physical failure keeps PR #33 draft and unmerged. Automated haptic-request evidence is not a substitute for feeling the physical haptic on Mac16,8.

Only after all applicable `NH-MEDIA-PEEK-*`, `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*` and `NH-MEDIA-SOURCE-ICON-*` gates pass on one exact candidate may M6.6 be marked physically accepted and PR #33 become merge-eligible.
