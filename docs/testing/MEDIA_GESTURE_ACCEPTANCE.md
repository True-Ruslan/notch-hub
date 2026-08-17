# M6.6 Media Gesture, Haptic and Seek Acceptance

Status: ACCEPTED ON EXACT SOURCE `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3` / CI #1241 3/3 GREEN / NOT MERGED / NOT RELEASED
Date: 2026-08-18
Primary target: macOS 26.6 / Mac16,8
PR: #33 — `M6.6: app media gesture session TDD`

The stable IDs below remain frozen. Automated evidence proves deterministic state/command behavior; physical evidence is used only where actual trackpad direction, haptic output, compositor behavior, OS permission surfaces, real-source behavior or process cleanup require the target Mac.

## Non-negotiable boundaries

- Gesture input remains local to a NotchHub-owned view; no global scroll/button/keyboard monitor, event tap, synthetic media keys, or sensitive input permission.
- `NotchPanelTransitionCoordinator` remains the sole panel transition authority.
- Settled compact and Peek own zero persistent media adapter processes.
- Bounded Peek cancellation is nonblocking for the UI actor; persistent expanded-runtime and explicit Quit teardown retain synchronous lifecycle verification.
- Expanded observation remains presentation-scoped.
- Unsupported/unknown capabilities fail closed.
- No progress/media polling, repeating timer, display link, retry or sleep loop.
- Horizontal haptic occurs only when entering armed; no vertical gesture haptic is added.
- Seek is available only with authoritative capability and trustworthy timing and remains isolated from track/panel gestures.
- Physical direction is independent of macOS scroll-direction preference: LEFT means `next`, RIGHT means `previous`, DOWN means expansion, UP means collapse.
- Horizontal presentation follows the physical finger direction.
- Explicit click remains the stable SwiftUI tap path; no mouse-button event authority is present.

## Stable IDs

| ID | Required result | Acceptance evidence |
|---|---|---|
| `NH-MEDIA-GESTURE-001` | Local-only event surface; no new sensitive authority. | PASS — policy/source tests + final permission matrix NONE. |
| `NH-MEDIA-GESTURE-002` | Short/reverted horizontal gesture commits no command and no haptic. | PASS — deterministic coordinator regression. |
| `NH-MEDIA-GESTURE-003` | Physical LEFT -> exactly one `next` on release after one arm haptic when supported; visual follows LEFT. | PASS — automated pipeline + exact-candidate physical LEFT cycle. |
| `NH-MEDIA-GESTURE-004` | Physical RIGHT -> exactly one `previous` on release after one arm haptic when supported; visual follows RIGHT. | PASS — automated pipeline + exact-candidate physical RIGHT cycle. |
| `NH-MEDIA-GESTURE-005` | Compact/Peek/expanded direction, threshold, commit and follow-finger visual parity. | PASS — coordinator/Peek/pipeline regressions + final real trackpad cycle. |
| `NH-MEDIA-GESTURE-006` | 28% / 70...120 pt threshold and 20 pt disarm hysteresis; one haptic per armed transition. | PASS — threshold/hysteresis regressions; supported physical arm haptic confirmed once per final directional cycle. |
| `NH-MEDIA-GESTURE-007` | Momentum cannot capture, arm, re-arm or commit. | PASS — deterministic momentum regression + final no-extra-switch smoke. |
| `NH-MEDIA-GESTURE-008` | Diagonal ambiguity is rejected; captured horizontal gesture cannot expand/collapse. | PASS — deterministic arbitration regressions; no separate physical-only requirement. |
| `NH-MEDIA-GESTURE-009` | Compact physical DOWN requests expansion only. | PASS — deterministic intent regression + exact-top-edge/center physical DOWN matrix. |
| `NH-MEDIA-GESTURE-010` | Expanded physical UP requests collapse only. | PASS — deterministic intent regression + final physical UP matrix. |
| `NH-MEDIA-GESTURE-011` | Unsupported/unknown/failed/late previous-next cannot arm, haptic or commit. | PASS — fail-closed capability regressions; no separate physical-only requirement. |
| `NH-MEDIA-GESTURE-012` | Compact arming uses bounded fresh one-shot capability validation, not persistent observation or retained capability trust. | PASS — coordinator + composition policy regressions. |
| `NH-MEDIA-GESTURE-013` | Progress is draggable only when seek is authoritatively supported with valid timing. | PASS — seek policy regression + final real seek matrix. |
| `NH-MEDIA-GESTURE-014` | Seek preview is local; one typed seek on valid completion; cancellation/failure does not fabricate success. | PASS — seek UI/composition regression + final preview/commit/cancel physical matrix. |
| `NH-MEDIA-GESTURE-015` | Seek ownership excludes track and panel gestures; track/source/capability identity change cancels the transaction. | PASS — identity/isolation regressions + final track/source cancellation check. |
| `NH-MEDIA-GESTURE-016` | One-shot operations are lifecycle-owned; compact/Peek and Quit leave no orphan. | PASS — stop-race/integration regressions + empty post-Quit `pgrep` on exact candidate. |
| `NH-MEDIA-GESTURE-017` | Sandbox/Hardened Runtime/security/performance invariants remain intact. | PASS — canonical package/security gates + target permission matrix NONE. |
| `NH-MEDIA-GESTURE-018` | Real source matrix follows macOS Now Playing; absent capability is recorded honestly. | PASS — real source/source-icon/continuity physical matrix + existing transport tests. |

## Exact physical evidence

Canonical source `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3` / CI #1241 / run `32075976405` passed all three canonical jobs, 366 Swift tests / 80 suites and external exact-app XCUI 11/11.

On 2026-08-18 Mac16,8/macOS 26.6, the final requested matrix passed:

- RIGHT -> Previous/back and animation follows RIGHT;
- LEFT -> Next and animation follows LEFT;
- one supported horizontal arm haptic per qualifying directional cycle;
- Hover Peek with and without media, including stationary-pointer relaunch;
- exact-top-edge DOWN, center DOWN, pointer-exit collapse and physical UP settlement;
- seek preview/commit/cancel, cursor restoration and source/track identity cancellation;
- source icon/fallback;
- sensitive permission matrix NONE;
- post-Quit helper process check empty.

## Regression coverage

1. `MediaGestureInputNormalizerTests` freezes physical LEFT/RIGHT signs across both macOS scroll-direction preference states and independently protects vertical DOWN/UP signs.
2. `MediaGestureCoordinatorTests` freezes LEFT -> Next, RIGHT -> Previous, thresholds, hysteresis, haptic, momentum, diagonal arbitration, compact capability validation and vertical panel intent.
3. `MediaGesturePhysicalPipelineTests` binds raw AppKit horizontal delta -> normalization -> visual offset -> typed command for both scroll-direction preference states.
4. `MediaGesturePeekTests`, `MediaSeekAppCompositionPolicyTests`, `ShippingMediaSeekTransactionTests`, cursor composition tests and transport lifecycle suites cover Peek parity, seek isolation and teardown deterministically.

## Acceptance provenance

Physical acceptance is attached to runtime source `8744b9e...`. A later documentation/coverage-only acceptance-record commit does not replace that runtime SHA and requires no new physical claim. PR #33 remains unmerged and unreleased until a separate merge decision.
