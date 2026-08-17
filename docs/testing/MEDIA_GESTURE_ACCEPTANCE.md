# M6.6 Media Gesture, Haptic and Seek Acceptance

Status: IMPLEMENTED / AUTOMATED-GREEN THROUGH CI #1238 / FINAL HORIZONTAL PHYSICAL CONTRACT CONFIRMED ON `f2e81d993db37af9548799682ad8f03c7d64ae27` / FULL ONE-SHA M6.6 PHYSICAL MATRIX STILL PENDING / NOT MERGED / NOT RELEASED
Date: 2026-08-18
Primary target: macOS 26.6 / Mac16,8
PR: #33 — `M6.6: app media gesture session TDD`

The stable IDs below remain frozen. Automated GREEN is necessary but does not substitute for target-Mac physical evidence. Physical evidence from an earlier source candidate is recorded without prematurely promoting a stable ID on the new test/documentation head.

## Non-negotiable boundaries

- Gesture input remains local to a NotchHub-owned view; no global scroll/button/keyboard monitor, event tap, synthetic media keys, or sensitive input permission.
- `NotchPanelTransitionCoordinator` remains the sole panel transition authority.
- Settled compact and Peek own zero persistent media adapter processes. Bounded one-shot work is allowed only behind the reviewed fixed transport boundary.
- Bounded Peek cancellation is nonblocking for the UI actor; persistent expanded-runtime and explicit Quit teardown retain synchronous lifecycle verification.
- Expanded observation remains presentation-scoped.
- Unsupported/unknown capabilities fail closed.
- No progress/media polling, repeating timer, display link, retry or sleep loop.
- Horizontal haptic occurs only when entering armed; no vertical gesture haptic is added.
- Seek is available only with authoritative capability and trustworthy timing and remains isolated from track/panel gestures.
- Physical direction is independent of macOS scroll-direction preference: LEFT means `next`, RIGHT means `previous`, DOWN means expansion, UP means collapse.
- Horizontal presentation follows the physical finger direction: LEFT moves left; RIGHT moves right.
- Explicit click remains a stable SwiftUI tap path; no mouse-button event authority is present.

## Stable IDs

| ID | Required result | Automated | Physical |
|---|---|---|---|
| `NH-MEDIA-GESTURE-001` | Local-only event surface; no new sensitive authority. | GREEN through #1238 | PENDING full exact-candidate matrix |
| `NH-MEDIA-GESTURE-002` | Short/reverted horizontal gesture commits no command and no haptic. | GREEN through #1238 | Partial smoke only; full gate PENDING |
| `NH-MEDIA-GESTURE-003` | Physical LEFT -> exactly one `next` on release after one arm haptic when supported; visual follows LEFT. | GREEN through #1238 | Physically confirmed on `f2e81d993...`; final test/docs-head retest PENDING |
| `NH-MEDIA-GESTURE-004` | Physical RIGHT -> exactly one `previous` on release after one arm haptic when supported; visual follows RIGHT. | GREEN through #1238 | Physically confirmed on `f2e81d993...`; final test/docs-head retest PENDING |
| `NH-MEDIA-GESTURE-005` | Compact/Peek/expanded direction, threshold, commit and follow-finger visual parity. | GREEN through #1238 | Horizontal follow-finger confirmed; full surface parity PENDING |
| `NH-MEDIA-GESTURE-006` | 28% / 70...120 pt threshold and 20 pt disarm hysteresis; one haptic per armed transition. | GREEN through #1238 | Qualifying haptic physically confirmed; complete threshold/hysteresis matrix PENDING |
| `NH-MEDIA-GESTURE-007` | Momentum cannot capture, arm, re-arm or commit. | GREEN through #1238 | No-extra-switch smoke physically confirmed; complete gate PENDING |
| `NH-MEDIA-GESTURE-008` | Diagonal ambiguity is rejected; captured horizontal gesture cannot expand/collapse. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-009` | Compact physical DOWN requests expansion only. | GREEN | DOWN smoke physically confirmed; exact-edge/full gate PENDING |
| `NH-MEDIA-GESTURE-010` | Expanded physical UP requests collapse only. | GREEN | UP smoke physically confirmed; full gate PENDING |
| `NH-MEDIA-GESTURE-011` | Unsupported/unknown/failed/late previous-next cannot arm, haptic or commit. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-012` | Compact arming uses bounded fresh one-shot capability validation, not persistent observation or retained capability trust. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-013` | Progress is draggable only when seek is authoritatively supported with valid timing. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-014` | Seek preview is local; one typed seek on valid completion; cancellation/failure does not fabricate success. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-015` | Seek ownership excludes track and panel gestures; track/source/capability identity change cancels the transaction. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-016` | One-shot operations are lifecycle-owned; compact/Peek and Quit leave no orphan. | Stop-race + integration regressions GREEN | PENDING explicit final lifecycle evidence |
| `NH-MEDIA-GESTURE-017` | Sandbox/Hardened Runtime/security/performance invariants remain intact. | GREEN through #1238 | Permission matrix PENDING on final exact candidate |
| `NH-MEDIA-GESTURE-018` | Real source matrix follows macOS Now Playing; absent capability is recorded honestly. | GREEN | PENDING |

## Final horizontal repair history

Historical candidate `6c2109195042759b951217f489a201a82dd044cd` / CI #1156 proved that green automation alone was insufficient: real-media LEFT/RIGHT commands were reversed.

A later candidate fixed command direction but still rendered the horizontal animation opposite to the fingers. Candidate `e39f501a6388c8a0d53c1360f8b44e1bb72454cd` then made the animation follow the fingers, but physical testing showed the command mapping had become reversed relative to that presentation.

The final root cause was that the horizontal AppKit normalization sign and the presentation sign had been treated as separate compensating inversions. Final repair `f2e81d993db37af9548799682ad8f03c7d64ae27` makes semantic X represent the physical finger direction directly:

- physical RIGHT normalizes to positive X;
- physical LEFT normalizes to negative X;
- `.visualOffset(cumulativeX)` follows the same physical sign;
- negative/LEFT commits `.next`;
- positive/RIGHT commits `.previous`;
- vertical Y normalization is unchanged.

CI #1238 / run `32072408370` passed all three canonical jobs, the 365-test / 79-suite Swift gate, exact external-app XCUI 11/11, production transport/archive, security/source policy, Sandbox/Hardened Runtime/signing/preflight, unchanged size budget and performance smoke.

On 2026-08-18 the target Mac16,8/macOS 26.6 physically confirmed on exact `f2e81d993db37af9548799682ad8f03c7d64ae27`:

- RIGHT -> Previous/back;
- RIGHT animation follows the fingers to the right;
- LEFT -> Next;
- LEFT animation follows the fingers to the left;
- below-threshold horizontal smoke produced no switch;
- momentum produced no extra switch;
- DOWN/UP smoke remained correct;
- supported horizontal arm haptic was felt exactly once.

This is explicit physical evidence for the final horizontal direction/follow-finger contract on `f2e81d993...`. Stable IDs remain pending on the new test/documentation head until that exact head passes CI and is physically rechecked, preserving the one-SHA acceptance rule.

## Regression coverage

The repair is covered at three levels:

1. `MediaGestureInputNormalizerTests` freezes physical LEFT/RIGHT signs across both macOS scroll-direction preference states and independently protects vertical DOWN/UP signs.
2. `MediaGestureCoordinatorTests` freezes LEFT -> Next, RIGHT -> Previous, thresholds, hysteresis, haptic, momentum, diagonal arbitration, compact capability validation and vertical panel intent.
3. `MediaGesturePhysicalPipelineTests` is an end-to-end characterization from raw AppKit horizontal delta through normalization, visual offset and typed command for both scroll-direction preference states. It was added after the final physical confirmation specifically to prevent another compensating-sign regression.

No production behavior is changed by the third layer; the new exact head must independently pass canonical CI before becoming the next candidate.

## Remaining target procedure

After the test/documentation head passes all three canonical CI jobs, freeze that SHA and complete the remaining one-SHA physical matrix:

1. Repeat LEFT/RIGHT once to prove the new test-only/docs-only descendant still corresponds to the confirmed runtime contract.
2. Hover Peek with media and without media, including stationary-pointer relaunch and physical hover haptic.
3. Click while Hover Peek/media enrichment may overlap; verify prompt single expansion.
4. Exact-top-edge DOWN, pointer-exit collapse and UP settlement.
5. Seek capability/preview/commit/cancel, cursor restoration and identity cancellation.
6. Source-icon/source-continuity checks.
7. After bounded compact/Peek work and after real Quit run `pgrep -lf 'mediaremote-adapter\.pl' || true`; require empty output.
8. Confirm Accessibility, Input Monitoring, Automation and Screen Recording remain unrequested.

## Acceptance rule

M6.6 remains not fully accepted until all applicable stable gates have explicit target-Mac evidence on one final exact candidate. PR #33 remains draft until then. No P1, merge or release is allowed before that closure.
