# Media Peek Acceptance

Status: AUTOMATED POINTER-EXIT REPAIR GREEN / FINAL DOCS-SYNC CI PENDING / TARGET-MAC PHYSICAL RETEST PENDING
Date: 2026-08-13
Target: macOS 26.6 / Mac16,8
Scope: M6.6 PR #33 Hover Peek follow-up

This ledger is additive. Existing `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, and `NH-MEDIA-SOURCE-ICON-*` IDs are not renumbered or weakened.

## Contract

- Stable presentation states are `compact`, `peek`, and `expanded` under the existing single panel/transition authority.
- Hover activation dwell remains exactly 120 ms.
- Peek pointer-exit grace is exactly 140 ms.
- Hover previews Peek; click or physical DOWN explicitly expands.
- A pointer already inside the compact hover region when the app is shown/restarted remains eligible for the normal 120 ms dwell; no extra mouse movement is required.
- Peek is media-only and appears only with retained or freshly confirmed media context.
- Settled compact and Peek own zero persistent media observer; only settled expanded owns the presentation-scoped shipping runtime.
- Leaving the expanded retention region returns to compact non-haptically, preserving the physically accepted M1 interaction contract.
- Interactive expansion/collapse must always settle to an exact stable endpoint when the current visible panel moves out from under the pointer; an intermediate frame is never a valid settled state.
- Seek hides the cursor only while a valid seek interaction owns it; no pointer warp/lock is used.
- Existing gesture semantics remain LEFT -> next, RIGHT -> previous, DOWN -> expand, expanded UP -> compact.

## Candidate provenance rule

The final physical candidate is the current PR head after this documentation sync once that exact head passes both required CI jobs. Its source SHA, workflow run, artifact IDs/digests, sizes and contained DMG SHA-256 are frozen in PR #33 without another repository commit.

## Physical rejection history

### Candidate `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945

Rejected on Mac16,8/macOS 26.6. A stationary relaunch could fail to arm Hover Peek because `NotchPanelController.show()` synchronized `NSEvent.mouseLocation` with activation disabled. Focused RED `553cf973722dfb214f0fcb741ddb6c9b0b44ff02` / CI #947 reproduced the defect; GREEN `d17bd27be72c8c3bd022fb2c3613050c398c622e` / CI #948 removed only that startup suppression.

### Candidate `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951

Also rejected on the target Mac despite green automation.

Observed:

1. normal hover in the broken physical session did not produce the expected haptic/Peek transition;
2. physical DOWN could expand, but moving the pointer outside the expanded panel did not auto-collapse it;
3. physical UP collapse could remain at an intermediate frame if the shrinking panel moved out from under the pointer before the local scroll stream delivered `.ended`/`.cancelled`.

The second item is a confirmed regression of accepted M1 behavior: PR #33 had changed expanded pointer policy to retain `.expanded` unconditionally and changed its tests to expect no pointer-exit collapse.

The third item has a confirmed ownership gap: local scroll is delivered only through the hosting view. If geometry leaves the pointer before the terminal scroll phase reaches that view, the interactive transition previously had no independent synchronous settlement path.

The first hover/haptic symptom is intentionally not assigned a new root cause yet. A partially owned interactive transition can suppress normal hover state. It must be retested from a clean stable compact state after this repair; if it still fails, it becomes a separate focused RED -> GREEN defect.

## Pointer-exit / lost-terminal TDD repair

- clean test-only RED `0a42a701fcf4fa2f59972a68d2a3b9243203a202` / CI #959: 333 tests / 69 suites; exactly five new regression tests failed while the pre-existing suite passed;
- production GREEN `64d3e6c2beadacaeda69c8ac06f173ac26aace3e`: restored accepted expanded pointer-exit collapse, allowed only `.pointerExitCollapse` to retarget an owned interactive transition to compact, and passed the current `NSEvent.mouseLocation` through the local interactive path so actual `panel.frame` can settle synchronously when it leaves the pointer;
- format-only `de5624b7d344e15772fdf0759fbe4b5027a5b1d4` / CI #961: both required jobs PASS; 333 tests / 69 suites PASS, including all five new regression tests plus strict source/security/performance/media/signing/preflight/size/performance-smoke gates.

No global scroll monitor, event tap, repeating watchdog, polling loop, display link, new process boundary or sensitive permission authority was introduced.

## Stable acceptance IDs

| ID | Gate | Required result | Automated | Physical |
|---|---|---|---|---|
| `NH-MEDIA-PEEK-001` | Hover destination + stationary restart | With usable media, 120 ms hover dwell opens Peek only and performs the expected Peek haptic; hover alone never opens full expanded UI. Relaunch while the pointer is already stationary inside the physical notch must behave the same without extra movement. | Startup RED #947 -> GREEN #948; retained after #961 | FAIL on prior candidates; RETEST REQUIRED |
| `NH-MEDIA-PEEK-002` | No-media hover | With no retained/fresh media context, hover remains compact and shows no generic Peek. | Covered | PENDING |
| `NH-MEDIA-PEEK-003` | Fast pointer pass | Pointer transit shorter than dwell does not expand or leave Peek stuck. | Covered | PENDING |
| `NH-MEDIA-PEEK-004` | 140 ms grace | Exit/re-entry before 140 ms keeps Peek; remaining outside through the deadline returns to compact. | Covered | PENDING |
| `NH-MEDIA-PEEK-005` | Explicit expansion | Free-surface click and physical DOWN from Peek each open expanded exactly once; compact click also explicitly expands. | Covered | PENDING |
| `NH-MEDIA-PEEK-006` | Peek horizontal gestures | LEFT -> next and RIGHT -> previous use bounded one-shot work; hover cannot steal an owned gesture. | Covered | PENDING |
| `NH-MEDIA-PEEK-007` | Peek seek | Timeline seek works in Peek without expanding and suppresses notch gestures while active. | Covered | PENDING |
| `NH-MEDIA-PEEK-008` | Seek cursor | Cursor hides only after valid seek begin and is restored on every commit/cancel/identity/app lifecycle path; no warp/lock. | Covered | PENDING |
| `NH-MEDIA-PEEK-009` | Track continuity | Track/source changes update the active media branch without an obvious Home/interface blink while media remains valid. | Covered | PENDING |
| `NH-MEDIA-PEEK-010` | Downward continuity | Compact DOWN follows the existing interactive expansion and never settles at an intermediate frame if pointer/panel separation occurs. | RED #959 -> GREEN #961 | RETEST REQUIRED |
| `NH-MEDIA-PEEK-011` | Expanded collapse + pointer exit | Expanded physical UP returns to exact compact. Leaving expanded retention also returns to compact non-haptically. Interactive collapse must not remain at an intermediate frame when the visible panel moves out from under the pointer or terminal local scroll delivery is lost. | RED #959 -> GREEN #961 | FAIL on `c9b...`; RETEST REQUIRED |
| `NH-MEDIA-PEEK-012` | Lifecycle | Settled compact, settled Peek, cancelled/retargeted transitions and normal Quit leave no unexpected persistent `mediaremote-adapter.pl` process. | Covered | PENDING |
| `NH-MEDIA-PEEK-013` | Permissions | No Accessibility, Input Monitoring, Automation or Screen Recording prompts are introduced. | Covered | PENDING |

## Focused target-Mac procedure

Use only the exact final candidate frozen in PR #33 after this docs-sync head passes CI.

1. Start from stable compact with usable media. Enter the physical notch and hold: after 120 ms, Peek and its expected haptic must occur; full Home/expanded must not appear from hover alone.
2. Relaunch while the pointer is already stationary on the notch. Without moving it away, confirm the same Peek/haptic after normal dwell.
3. Expand with DOWN, then move the pointer outside the expanded retention region without an UP gesture. Confirm a non-haptic automatic return to exact compact.
4. Expand again. Perform physical UP slowly enough that the shrinking panel moves away from a stationary pointer before the gesture naturally terminates. It must continue/retarget to exact compact; no clipped intermediate frame may remain.
5. Repeat UP while deliberately moving the pointer outside during the owned gesture. Again require exact compact.
6. From compact, begin a DOWN follow-finger expansion and deliberately separate pointer/panel before terminal delivery. It must settle safely to compact rather than remain intermediate.
7. Repeat steps 1-6 several times. Any stuck geometry, missing compact settlement, or hover failure remains a blocker.
8. Only after this focused block passes continue the remaining gesture/seek/source-icon/lifecycle/permission matrix.

## Acceptance rule

Any required physical failure keeps PR #33 draft and unmerged. Fixes require a new focused RED -> GREEN cycle, a new exact CI candidate, and retest of affected/regression gates.

Only after all applicable `NH-MEDIA-PEEK-*`, `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*` and `NH-MEDIA-SOURCE-ICON-*` gates pass on one exact candidate may M6.6 be marked physically accepted and PR #33 become merge-eligible.
