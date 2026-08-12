# Media Peek Acceptance

Status: AUTOMATED REPAIR GREEN / FINAL DOCS-ONLY HEAD CI PENDING / TARGET-MAC PHYSICAL RETEST PENDING
Date: 2026-08-13
Target: macOS 26.6 / Mac16,8
Scope: M6.6 PR #33 Hover Peek follow-up

This ledger is additive. Existing `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, and `NH-MEDIA-SOURCE-ICON-*` IDs are not renumbered or weakened.

## Contract

- Stable presentation states are `compact`, `peek`, and `expanded` under the existing single panel/transition authority.
- Hover activation dwell remains exactly 120 ms.
- Peek pointer-exit grace is exactly 140 ms.
- Hover previews; click or physical DOWN explicitly expands.
- A pointer already inside the compact hover region when the app is shown/restarted remains eligible for the normal 120 ms dwell; no extra mouse movement is required to arm hover.
- Peek is media-only and appears only with retained or freshly confirmed media context.
- Settled compact and Peek own zero persistent media observer; only expanded owns the presentation-scoped shipping runtime.
- Seek hides the cursor only while a valid seek interaction owns it; no pointer warp/lock is used.
- Existing gesture semantics remain LEFT -> next, RIGHT -> previous, DOWN -> expand, expanded UP -> compact.

## Candidate provenance rule

The final physical candidate is the **current PR head after this ledger correction**, once that exact head passes both required CI jobs. Its source SHA, workflow run, artifact IDs/digests, sizes and contained DMG SHA-256 are frozen in PR #33 **without another repository commit**. This avoids changing the candidate merely by documenting its own future SHA.

Pre-final docs evidence `2d9e041d05ebb949133565ae828aa8011ef66e32` / CI #949 passed both required jobs with 328 Swift tests and all release/security/performance/media/signing/preflight/size/performance-smoke gates. It proves the repair plus first docs sync, but is not used as the final physical candidate after the ledger correction changed branch head.

## Physical rejection and repair evidence

The prior physical candidate `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945 was rejected on Mac16,8/macOS 26.6.

Observed:

1. an unexpected full expanded Home/foundation surface appeared during the initial interaction sequence and appeared stuck;
2. after restarting while the pointer was already positioned on the physical notch, compact did not open Peek even though the pointer remained in the hover region.

The second symptom has a proven root cause. `NotchPanelController.show()` synchronized `NSEvent.mouseLocation` with `allowActivation: false`. If the pointer was already stationary on the notch, no later `mouseMoved` event existed to schedule the 120 ms dwell.

The full-expanded observation is recorded but is not assigned the same root cause. Positive hover resolution routes only to Peek; full expansion is owned by explicit click/DOWN paths. The retest must prove hover alone never opens full expanded UI. A repeat without click/DOWN is a separate blocker requiring its own RED -> GREEN cycle.

Focused TDD repair:

- RED `553cf973722dfb214f0fcb741ddb6c9b0b44ff02` / CI #947: warnings-as-errors build PASS; 328 tests / 68 suites with exactly `showKeepsStationaryPointerEligibleForHoverDwell` failing;
- GREEN `d17bd27be72c8c3bd022fb2c3613050c398c622e` / CI #948: minimum production change removed only startup activation suppression; both required jobs PASS with 328 tests and all policy/security/package gates;
- docs evidence `2d9e041d05ebb949133565ae828aa8011ef66e32` / CI #949: both required jobs PASS.

## Stable acceptance IDs

| ID | Gate | Required result | Automated | Physical |
|---|---|---|---|---|
| `NH-MEDIA-PEEK-001` | Hover destination + stationary restart | With usable media, 120 ms hover dwell opens Peek only; hover alone never opens full expanded UI. The same holds when NotchHub is shown/restarted while the pointer is already stationary inside the physical notch; no extra pointer movement is required. | RED #947 -> GREEN #948/#949 | FAIL on `bbba...`; RETEST REQUIRED |
| `NH-MEDIA-PEEK-002` | No-media hover | With no retained/fresh media context, hover remains compact and shows no generic Peek. | Covered | PENDING |
| `NH-MEDIA-PEEK-003` | Fast pointer pass | Pointer transit shorter than dwell does not open expanded UI or leave Peek stuck. | Covered | PENDING |
| `NH-MEDIA-PEEK-004` | 140 ms grace | Exit/re-entry before 140 ms keeps Peek; remaining outside through the deadline returns to compact. | Covered | PENDING |
| `NH-MEDIA-PEEK-005` | Explicit expansion | Free-surface click and physical DOWN from Peek each open expanded exactly once; compact click also explicitly expands. | Covered | PENDING |
| `NH-MEDIA-PEEK-006` | Peek horizontal gestures | LEFT -> next and RIGHT -> previous use bounded one-shot capability/command work; hover cannot steal an owned gesture. | Covered | PENDING |
| `NH-MEDIA-PEEK-007` | Peek seek | Timeline seek works in Peek without expanding and suppresses notch gestures while active. | Covered | PENDING |
| `NH-MEDIA-PEEK-008` | Seek cursor | Cursor hides after valid seek begin and is restored after commit/cancel/session change/app resign/invalidation/Quit; no pointer warp/lock. | Covered | PENDING |
| `NH-MEDIA-PEEK-009` | Track continuity | Track/source changes update the current media branch without an obvious Home/interface blink while media remains valid. | Covered | PENDING |
| `NH-MEDIA-PEEK-010` | Downward continuity | Compact DOWN follows the existing interactive expansion and reaches expanded without a transient Home frame. | Covered | PENDING |
| `NH-MEDIA-PEEK-011` | Expanded collapse | Expanded physical UP returns directly to compact; pointer exit alone does not close expanded. | Covered | PENDING |
| `NH-MEDIA-PEEK-012` | Lifecycle | Settled compact, settled Peek, cancelled expansion and normal Quit leave no unexpected persistent `mediaremote-adapter.pl` process. | Covered | PENDING |
| `NH-MEDIA-PEEK-013` | Permissions | No Accessibility, Input Monitoring, Automation or Screen Recording prompts are introduced. | Covered | PENDING |

## Focused target-Mac procedure

Use the exact final candidate frozen in PR #33 after this head's CI succeeds.

1. With media playing, place the pointer outside the notch, enter the physical notch and hold. Confirm 120 ms hover opens only Peek, never full expanded UI.
2. Restart/stationary regression: with media playing and the pointer already inside the physical notch, quit and relaunch the exact candidate without moving the pointer away. After normal 120 ms dwell, Peek must open. No extra leave/re-enter movement may be required.
3. Repeat normal/restart hover several times. If full expanded Home appears without click or physical DOWN, stop and record the exact sequence; `NH-MEDIA-PEEK-001` remains FAIL.
4. Rapidly cross the notch and leave before dwell. Confirm no full expansion and no stuck Peek.
5. Open Peek, leave briefly and return inside 140 ms; it must stay open. Leave and stay out; it must collapse after grace.
6. Continue remaining gesture/seek/lifecycle/permission gates only after the focused blocker passes.

## Acceptance rule

A failure in any required physical gate keeps PR #33 draft and unmerged. Fixes require a new focused RED -> GREEN cycle, new exact CI candidate and retest of affected/regression gates.

Only after all applicable `NH-MEDIA-PEEK-*`, `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*` and `NH-MEDIA-SOURCE-ICON-*` gates pass on one exact candidate may M6.6 be marked physically accepted and PR #33 become merge-eligible.
