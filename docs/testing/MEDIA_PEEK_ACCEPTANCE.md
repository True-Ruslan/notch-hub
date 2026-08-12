# Media Peek Acceptance

Status: AUTOMATED-TESTED / DOCS-SYNC EXACT CANDIDATE CI PENDING / TARGET-MAC PHYSICAL ACCEPTANCE PENDING
Date: 2026-08-13
Target: macOS 26.6 / Mac16,8
Scope: M6.6 PR #33 Hover Peek follow-up

This ledger is additive. Existing `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, and `NH-MEDIA-SOURCE-ICON-*` IDs are not renumbered or weakened.

## Contract

- Stable presentation states are `compact`, `peek`, and `expanded` under the existing single panel/transition authority.
- Hover activation dwell remains exactly 120 ms.
- Peek pointer-exit grace is exactly 140 ms.
- Hover previews; click or physical DOWN explicitly expands.
- Peek is media-only and appears only with retained or freshly confirmed media context.
- Settled compact and Peek own zero persistent media observer; only expanded owns the presentation-scoped shipping runtime.
- Seek hides the cursor only while a valid seek interaction owns it; no pointer warp/lock is used.
- Existing gesture semantics remain LEFT -> next, RIGHT -> previous, DOWN -> expand, expanded UP -> compact.

## Automated evidence

The Hover Peek implementation is automated-tested before this documentation sync:

- `7daffde9b7c2a734e2ddfa234b1ee744b0d96d9e` / CI #939: functional/security/signing/preflight PASS with exact artifact-size evidence `562,368 / 864,574 / 555,272 B` executable/app/DMG; the previous physical-repair size envelope was the only failing gate;
- `4bc15c4757727922817b4aaac35c7991c852019a` / CI #940: clean size-policy RED, 327 tests / 68 suites, exactly the missing Hover Peek budget failed;
- `performance/m6-6-hover-peek-size-budget.json`: provenance-bound to CI #939 evidence; prior feature budgets are historical and unchanged;
- `745baa55b7a53519b3832f21305fa9c357ce05fa` / CI #944: both required jobs PASS with the Hover Peek budget active, including 327 Swift tests, release/security/performance/media policy, Sandbox/Hardened Runtime, signing, shipping preflight, deterministic size enforcement and performance smoke.

The docs-synchronized head created by this ledger update must also pass both required jobs before it becomes the physical acceptance candidate. Exact candidate SHA, workflow/artifact IDs and digests are recorded in PR #33 after that CI completes.

## Stable acceptance IDs

| ID | Gate | Required result | Automated | Physical |
|---|---|---|---|---|
| `NH-MEDIA-PEEK-001` | Hover destination | With usable media, 120 ms hover dwell opens Peek only; hover alone never opens full expanded UI. | Covered; pre-docs CI #944 PASS | PENDING |
| `NH-MEDIA-PEEK-002` | No-media hover | With no retained/fresh media context, hover remains compact and shows no generic Peek. | Covered; pre-docs CI #944 PASS | PENDING |
| `NH-MEDIA-PEEK-003` | Fast pointer pass | Pointer transit shorter than dwell does not open expanded UI or leave Peek stuck. | Covered; pre-docs CI #944 PASS | PENDING |
| `NH-MEDIA-PEEK-004` | 140 ms grace | Exit/re-entry before 140 ms keeps Peek; remaining outside through the deadline returns to compact. | Covered; pre-docs CI #944 PASS | PENDING |
| `NH-MEDIA-PEEK-005` | Explicit expansion | Free-surface click and physical DOWN from Peek each open expanded exactly once; compact click also explicitly expands. | Covered; pre-docs CI #944 PASS | PENDING |
| `NH-MEDIA-PEEK-006` | Peek horizontal gestures | LEFT -> next and RIGHT -> previous use bounded one-shot capability/command work; hover cannot steal an owned gesture. | Covered; pre-docs CI #944 PASS | PENDING |
| `NH-MEDIA-PEEK-007` | Peek seek | Timeline seek works in Peek without expanding and suppresses notch gestures while active. | Covered; pre-docs CI #944 PASS | PENDING |
| `NH-MEDIA-PEEK-008` | Seek cursor | Cursor hides after valid seek begin and is restored after commit/cancel/session change/app resign/invalidation/Quit; no pointer warp/lock. | Covered; pre-docs CI #944 PASS | PENDING |
| `NH-MEDIA-PEEK-009` | Track continuity | Track/source changes update the current media branch without an obvious Home/interface blink while media remains valid. | Covered; pre-docs CI #944 PASS | PENDING |
| `NH-MEDIA-PEEK-010` | Downward continuity | Compact DOWN follows the existing interactive expansion and reaches expanded without a transient Home frame. | Covered; pre-docs CI #944 PASS | PENDING |
| `NH-MEDIA-PEEK-011` | Expanded collapse | Expanded physical UP returns directly to compact; pointer exit alone does not close expanded. | Covered; pre-docs CI #944 PASS | PENDING |
| `NH-MEDIA-PEEK-012` | Lifecycle | Settled compact, settled Peek, cancelled expansion and normal Quit leave no unexpected persistent `mediaremote-adapter.pl` process. | Policy/lifecycle covered; pre-docs CI #944 PASS | PENDING |
| `NH-MEDIA-PEEK-013` | Permissions | No Accessibility, Input Monitoring, Automation or Screen Recording prompts are introduced. | Policy covered; pre-docs CI #944 PASS | PENDING |

## Focused target-Mac procedure

Use one exact docs-synchronized CI-produced candidate. Record the candidate source SHA, workflow run, shipping artifact ID/digest and contained DMG SHA-256 before testing.

1. Play media in the known-good source and move the pointer into the physical notch. Confirm 120 ms hover opens only the approximately 360×96 Peek, not full expanded UI.
2. Rapidly cross the notch and leave before dwell. Confirm no full expansion and no stuck Peek.
3. Open Peek, leave briefly and return inside 140 ms; it must stay open. Leave and stay out; it must collapse after the grace.
4. In Peek, test LEFT -> next and RIGHT -> previous, including a short/reversed swipe. Confirm one arm haptic only when armed and no hover interference.
5. Click free Peek surface; confirm one full expansion. Return to compact, reopen Peek and use physical DOWN; confirm one full expansion.
6. From compact, use physical DOWN directly; confirm follow-finger expansion without an intermediate Home blink. From expanded, use physical UP; confirm direct return to compact.
7. In Peek, drag timeline. Confirm seek preview follows the drag, the system cursor is hidden only during the drag, and release restores it. Repeat cancellation/source-change teardown and confirm the cursor always returns.
8. Switch tracks repeatedly in expanded and Peek. Confirm media content updates in place without obvious Home/interface blinking.
9. With no usable media context, hover the notch. Confirm no Peek appears; click/down must still open full NotchHub explicitly.
10. Verify lifecycle with `pgrep -lf 'mediaremote-adapter\.pl' || true`: settled compact and settled Peek must be empty; settled expanded may own one expected persistent adapter; normal Quit must return to empty.
11. Confirm no Accessibility, Input Monitoring, Automation or Screen Recording permission prompt appeared.

## Acceptance rule

A failure in any required physical gate keeps PR #33 draft and unmerged. Fixes require a new focused RED -> GREEN cycle, new exact CI candidate and retest of affected/regression gates.

Only after all applicable `NH-MEDIA-PEEK-*`, `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*` and `NH-MEDIA-SOURCE-ICON-*` gates pass on one exact candidate may M6.6 be marked physically accepted and PR #33 become merge-eligible.
