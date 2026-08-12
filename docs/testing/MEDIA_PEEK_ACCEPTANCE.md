# Media Peek Acceptance

Status: AUTOMATED REPAIR GREEN / NEW DOCS-SYNC EXACT CANDIDATE CI PENDING / TARGET-MAC PHYSICAL RETEST PENDING
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

## Automated evidence

Hover Peek size/policy foundation:

- `7daffde9b7c2a734e2ddfa234b1ee744b0d96d9e` / CI #939: functional/security/signing/preflight PASS with exact artifact-size evidence `562,368 / 864,574 / 555,272 B`; previous repair size envelope only RED;
- `4bc15c4757727922817b4aaac35c7991c852019a` / CI #940: clean size-policy RED, 327 tests / 68 suites, exactly the missing Hover Peek budget failed;
- `performance/m6-6-hover-peek-size-budget.json`: provenance-bound to CI #939 evidence; prior feature budgets remain historical and unchanged;
- `745baa55b7a53519b3832f21305fa9c357ce05fa` / CI #944: both required jobs PASS with 327 Swift tests and the Hover Peek budget active;
- docs-synchronized candidate `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945: both required jobs PASS and became the first Hover Peek physical candidate.

### Physical result for `bbba2860...` — REJECTED

Target testing on Mac16,8/macOS 26.6 rejected the candidate.

Observed:

1. an unexpected full expanded Home/foundation surface appeared during the initial interaction sequence and appeared stuck;
2. after restarting while the pointer was already positioned on the physical notch, the compact panel did not open Peek even though the pointer remained in the hover region.

The second symptom has a proven root cause. `NotchPanelController.show()` synchronized `NSEvent.mouseLocation` with `allowActivation: false`. If the pointer was already stationary on the notch, no later `mouseMoved` event existed to schedule the 120 ms dwell. This violated the hover contract.

The full-expanded observation is recorded but is **not** assigned the same root cause. Source inspection confirms positive hover resolution routes only to `requestPeek`; full expansion is owned by explicit click/DOWN paths. Therefore the next target retest must prove that hover alone never opens full expanded UI. If it repeats without click/DOWN, it becomes a separate focused RED rather than being explained by assumption.

### Stationary startup hover RED -> GREEN

- test-only RED `553cf973722dfb214f0fcb741ddb6c9b0b44ff02` / CI #947: warnings-as-errors build PASS; 328 tests / 68 suites with exactly `showKeepsStationaryPointerEligibleForHoverDwell` failing; package job skipped after the intentional test failure;
- minimum production GREEN `d17bd27be72c8c3bd022fb2c3613050c398c622e`: removed only the startup `allowActivation: false` override; no new monitor, polling, timer, process, input authority or gesture semantic change;
- CI #948 / run `31645020620`: both required jobs PASS, 328 Swift tests PASS, release/security/performance/media policy PASS, Sandbox/Hardened Runtime/signing/preflight PASS, active Hover Peek size enforcement PASS and performance smoke PASS;
- CI #948 sizes: executable/app/DMG `562,368 / 864,574 / 555,281 B`;
- CI #948 shipping artifact `9160475207`, Actions digest `sha256:77b8d08df15f698068ecf45ca13e1b811ff3c3db5b82f74e183ac46299dfcab0`;
- CI #948 standalone DMG artifact `9160479006`, Actions digest `sha256:d36f5f1cd4d9ed71328900338d069838f6fbe3905c182136df3372395467e667`;
- contained CI #948 DMG SHA-256 `51b6b7b947153edd722ba92cc87080e02afc57cb553b96c07cb28423060ff587`.

CI #948 is pre-docs repair evidence, not the final physical candidate. The docs-synchronized head created by this update must pass both required jobs before retest.

## Stable acceptance IDs

| ID | Gate | Required result | Automated | Physical |
|---|---|---|---|---|
| `NH-MEDIA-PEEK-001` | Hover destination + stationary restart | With usable media, 120 ms hover dwell opens Peek only; hover alone never opens full expanded UI. The same holds when NotchHub is shown/restarted while the pointer is already stationary inside the physical notch; no extra pointer movement is required. | Repair RED #947 -> GREEN #948 | FAIL on `bbba...`; RETEST REQUIRED |
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

Use one exact docs-synchronized CI-produced candidate. Record the candidate source SHA, workflow run, shipping artifact ID/digest and contained DMG SHA-256 before testing.

1. With media playing, place the pointer outside the notch, enter the physical notch and hold. Confirm 120 ms hover opens only the approximately 360×96 Peek, never full expanded UI.
2. **Restart/stationary regression:** with media playing and the pointer already inside the physical notch, quit and relaunch the exact candidate without moving the pointer away. After normal 120 ms dwell, Peek must open. No extra leave/re-enter movement may be required.
3. Repeat normal hover several times. If full expanded Home appears without click or physical DOWN, stop: `NH-MEDIA-PEEK-001` remains FAIL and record the exact event sequence as a separate defect.
4. Rapidly cross the notch and leave before dwell. Confirm no full expansion and no stuck Peek.
5. Open Peek, leave briefly and return inside 140 ms; it must stay open. Leave and stay out; it must collapse after grace.
6. In Peek, test LEFT -> next and RIGHT -> previous, including short/reversed swipe. Confirm one arm haptic only when armed and no hover interference.
7. Click free Peek surface; confirm one full expansion. Return to compact, reopen Peek and use physical DOWN; confirm one full expansion.
8. From compact, use physical DOWN directly; confirm follow-finger expansion without an intermediate Home blink. From expanded, use physical UP; confirm direct return to compact.
9. In Peek, drag timeline. Confirm seek preview, cursor hide only during valid drag and restoration after release/cancel/source-change.
10. Switch tracks repeatedly in expanded and Peek. Confirm media content updates in place without obvious Home/interface blinking.
11. With no usable media context, hover the notch. Confirm no Peek; click/down may still explicitly open full NotchHub.
12. Verify `pgrep -lf 'mediaremote-adapter\.pl' || true`: settled compact and settled Peek empty; settled expanded may own one expected adapter; normal Quit returns empty.
13. Confirm no Accessibility, Input Monitoring, Automation or Screen Recording prompt appeared.

## Acceptance rule

A failure in any required physical gate keeps PR #33 draft and unmerged. Fixes require a new focused RED -> GREEN cycle, new exact CI candidate and retest of affected/regression gates.

Only after all applicable `NH-MEDIA-PEEK-*`, `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*` and `NH-MEDIA-SOURCE-ICON-*` gates pass on one exact candidate may M6.6 be marked physically accepted and PR #33 become merge-eligible.
