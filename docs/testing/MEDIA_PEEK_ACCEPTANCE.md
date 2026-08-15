# Media Peek Acceptance

Status: AUTOMATED PHYSICAL-REPAIR GREEN / FINAL DOCS-SYNC CI PENDING / TARGET-MAC PHYSICAL RETEST PENDING
Date: 2026-08-15
Target: macOS 26.6 / Mac16,8
Scope: M6.6 PR #33 Hover Peek physical-acceptance repair

This ledger is additive. Existing `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, and `NH-MEDIA-SOURCE-ICON-*` IDs are not renumbered or weakened.

## Current contract

- Stable presentation states remain `compact`, `peek`, and `expanded` under the existing single panel/transition authority.
- Hover activation dwell remains exactly 120 ms.
- Peek pointer-exit grace remains exactly 140 ms.
- Hover previews Peek; click or physical DOWN explicitly expands.
- A pointer already stationary inside the compact hover region when the app is shown/restarted remains eligible for the normal 120 ms dwell; no leave/re-enter is required.
- **Usable media is no longer a prerequisite for Peek.** A valid hover dwell first opens a lightweight generic Peek and requests the normal hover haptic exactly once. One bounded media probe may enrich that Peek when media exists; `.noSession` leaves the generic Peek visible rather than collapsing it.
- Settled compact and Peek own zero persistent media observer; only settled expanded owns the presentation-scoped shipping runtime.
- Leaving expanded retention returns to exact compact non-haptically, preserving accepted M1 behavior.
- Interactive expansion/collapse always settles to an exact stable endpoint when current geometry moves out from under the pointer; an intermediate frame is never a valid settled state.
- The exact top screen/panel `maxY` boundary counts as inside the interactive panel. A DOWN gesture started with the pointer physically against the top screen edge must not self-cancel as a false pointer exit.
- Explicit tap expansion is owned by one stable SwiftUI surface above the compact/Peek presentation switch, so a 120 ms hover transition cannot destroy a click that is already in flight.
- Seek hides the cursor only while a valid seek interaction owns it; no pointer warp/lock is used in production.
- Vertical DOWN/UP gestures intentionally add no new haptic. Hover-to-Peek and supported horizontal arm semantics remain the haptic paths.
- Pointer delivery remains event-driven: local `NSTrackingArea` is the primary hover path; the existing narrow `.mouseMoved` fallback remains unchanged. No global scroll/button/keyboard monitor, event tap, polling loop, repeating timer, display link, or new sensitive permission is introduced.

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
- external XCUI exposed a second race: `compact.click()` moves the pointer onto the notch and can spend roughly one hover dwell before completing; if the tap recognizer lives inside the compact/Peek branch, the branch can change to Peek mid-click and destroy the gesture;
- a proposed mouse-button event boundary was rejected by the existing security baseline and removed. The final solution keeps no new mouse-button authority and places one normal SwiftUI tap recognizer above the compact/Peek switch.

## Focused TDD repair evidence

The 2026-08-15 repair was developed fail-first and then exercised through the exact external application:

- unit RED reproduced no-media gating and exact `maxY` containment;
- `NotchPointerPolicy.containsInteractivePointer` now uses inclusive interactive containment for the physical boundary;
- `MediaPeekSession` opens generic Peek before the bounded media probe, so `.noSession` no longer blocks hover activation;
- compile-time-only UI diagnostics record haptic requests at the same transition-coordinator boundary as the production AppKit haptic performer; shipping-marker verification proves these fixtures do not enter the production binary;
- a local `NSTrackingArea` supplies primary event-driven hover entry/move/exit without polling;
- the external UI harness parks the real test pointer deterministically between journeys and separately verifies stationary-pointer relaunch behavior;
- explicit click expansion is now one stable parent SwiftUI gesture across compact and Peek, with no new `.leftMouseDown` monitor/event authority;
- exact behavior head `63b0f2f96f879123f3883db7311c90a20d3a4328` / CI #1140 / run `31889213155` passed 352 Swift tests / 74 suites and **11/11 external XCUI journeys**. Its package job failed only because the DMG exceeded the previous cumulative ceiling by 2172 B;
- the new cumulative size envelope changes only the DMG allowance by one 4096-byte review quantum. App and executable allowances are unchanged; immutable `v0.1.0` and all historical budgets remain untouched;
- pre-docs exact head `3e617698a503590dbc18958960a5335753734ccc` / CI #1147 / run `31889961194` passed **all three canonical jobs**, including the new size budget, strict acceptance traceability, security/source audit, Sandbox/Hardened Runtime/signing/preflight, performance smoke and external XCUI.

CI #1147 shipping evidence:

- shipping-media artifact: `9248335486`;
- DMG artifact: `9248336772`;
- UI result artifact: `9248334093`;
- executable: `580832 B`;
- app: `883039 B`;
- DMG: `555152 B`;
- active cumulative budget: `performance/m6-6-physical-acceptance-20260815-repair-size-budget.json`.

This automated evidence does **not** convert physical haptic feedback or real trackpad geometry into a PASS. Those remain target-Mac acceptance requirements.

## Stable acceptance IDs

| ID | Gate | Required result | Automated | Physical |
|---|---|---|---|---|
| `NH-MEDIA-PEEK-001` | Hover destination + stationary restart | With usable media, 120 ms hover opens Peek only and requests the expected Peek haptic exactly once; hover never opens full expanded UI. Relaunch with the pointer already stationary on the notch behaves the same without extra movement. | Unit + external XCUI GREEN on #1140/#1147 | FAIL on prior candidates; RETEST REQUIRED |
| `NH-MEDIA-PEEK-002` | No-media hover | With no retained/fresh media, the same valid 120 ms dwell opens a generic lightweight Peek, requests one hover haptic, never opens expanded, and does not start persistent media observation. A bounded `.noSession` result may leave the generic Peek visible. | Unit + external XCUI GREEN on #1140/#1147 | PENDING |
| `NH-MEDIA-PEEK-003` | Fast pointer pass | Pointer transit shorter than dwell does not expand or leave Peek stuck. | Covered | PENDING |
| `NH-MEDIA-PEEK-004` | 140 ms grace | Exit/re-entry before 140 ms keeps Peek; remaining outside through the deadline returns to compact. | Covered | PENDING |
| `NH-MEDIA-PEEK-005` | Explicit expansion | Free-surface click and physical DOWN from Peek each open expanded exactly once; compact click also explicitly expands even when hover dwell overlaps the click. | Unit + external XCUI GREEN on #1140/#1147 | PENDING |
| `NH-MEDIA-PEEK-006` | Peek horizontal gestures | LEFT -> next and RIGHT -> previous use bounded one-shot work; hover cannot steal an owned gesture. | Covered | PENDING |
| `NH-MEDIA-PEEK-007` | Peek seek | Timeline seek works in Peek without expanding and suppresses notch gestures while active. | Covered | PENDING |
| `NH-MEDIA-PEEK-008` | Seek cursor | Cursor hides only after valid seek begin and is restored on every commit/cancel/identity/app lifecycle path; no production warp/lock. | Covered | PENDING |
| `NH-MEDIA-PEEK-009` | Track continuity | Track/source changes update the active media branch without an obvious Home/interface blink while media remains valid. | Covered | PENDING |
| `NH-MEDIA-PEEK-010` | Downward continuity | Compact DOWN follows interactive expansion. Starting exactly at the physical top screen edge is valid; no false pointer-exit twitch/self-collapse or intermediate settled frame is allowed. | Focused unit GREEN; external regression suite GREEN | FAIL on #1101 exact-edge case; RETEST REQUIRED |
| `NH-MEDIA-PEEK-011` | Expanded collapse + pointer exit | Expanded physical UP returns to exact compact. Leaving expanded retention also returns to compact non-haptically. Interactive collapse cannot remain at an intermediate frame when visible geometry moves away or terminal local scroll delivery is lost. | Prior RED -> GREEN + external XCUI | FAIL on older candidate; pointer-exit PASS on #1101; RETEST REQUIRED |
| `NH-MEDIA-PEEK-012` | Lifecycle | Settled compact, settled Peek, cancelled/retargeted transitions and normal Quit leave no unexpected persistent `mediaremote-adapter.pl` process. | Covered | PENDING |
| `NH-MEDIA-PEEK-013` | Permissions | No Accessibility, Input Monitoring, Automation or Screen Recording prompts are introduced. | Security/policy GREEN | PENDING |

## Focused target-Mac procedure

Use only the exact final docs-synchronized candidate frozen in PR #33 after its exact head passes all three canonical CI jobs.

1. **Music/media OFF.** Start from stable compact, enter the physical notch and hold. After normal dwell, require generic Peek + one physical haptic. Full expanded/Home must not open from hover alone.
2. With music still off, relaunch while the pointer is already stationary over the physical notch. Without leaving/re-entering, require the same generic Peek + one physical haptic.
3. From compact, click normally while hover is eligible. Require full expanded exactly once; the 120 ms hover transition must not swallow the click.
4. Return to compact. Put the pointer completely against the physical top screen edge and perform DOWN. Require stable follow-finger expansion with no small downward twitch followed by self-collapse.
5. Repeat DOWN with the pointer slightly lower near the notch center. Require the same stable behavior.
6. From expanded, simply move the pointer outside. Require a non-haptic automatic return to exact compact.
7. Expand again and perform physical UP with a relatively stationary pointer. Require exact compact; no clipped intermediate frame may remain if shrinking geometry moves away.
8. Repeat UP while deliberately moving the pointer outside during the owned gesture. Again require exact compact.
9. Repeat the hover/click/DOWN/UP/pointer-exit cycle several times. Any missing physical haptic, swallowed click, top-edge twitch, stuck geometry or unexpected full hover expansion remains a blocker.
10. Only after this focused block passes continue the remaining horizontal gesture, seek, source-icon, lifecycle and permission matrix on the same exact candidate.

## Acceptance rule

Any required physical failure keeps PR #33 draft and unmerged. Automated haptic-request evidence is not a substitute for feeling the physical haptic on Mac16,8.

Only after all applicable `NH-MEDIA-PEEK-*`, `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*` and `NH-MEDIA-SOURCE-ICON-*` gates pass on one exact candidate may M6.6 be marked physically accepted and PR #33 become merge-eligible.
