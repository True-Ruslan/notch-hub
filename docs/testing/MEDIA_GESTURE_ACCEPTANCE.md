# M6.6 Media Gesture, Haptic and Seek Acceptance

Status: IMPLEMENTED / AUTOMATED-TESTED / PHYSICAL RETEST PENDING
Date: 2026-08-15
Primary target: macOS 26.6 / Mac16,8

The stable IDs below remain frozen. Green CI is necessary but does not constitute target-Mac acceptance.

## Non-negotiable boundaries

- Gesture input is local to a NotchHub-owned view; no global `.scrollWheel`, event tap, synthetic media keys or sensitive input permission.
- `NotchPanelTransitionCoordinator` remains the sole panel transition authority.
- Settled compact owns zero persistent media adapter processes; compact previous/next uses bounded one-shot capability/command operations only.
- Expanded observation remains presentation-scoped.
- Unsupported/unknown capabilities fail closed.
- No progress/media polling, repeating timer, display link or sleep loop.
- Horizontal haptic occurs only when entering armed; no vertical gesture haptic is added.
- Seek is available only with authoritative capability and trustworthy timing, and is isolated from track/panel gestures.
- Physical direction is independent of the user's macOS scroll-direction preference: LEFT means `next`, RIGHT means `previous`, DOWN means expansion and UP means collapse.

## Stable IDs

| ID | Required result |
|---|---|
| `NH-MEDIA-GESTURE-001` | Local-only event surface; no new sensitive authority. |
| `NH-MEDIA-GESTURE-002` | Short/reverted horizontal gesture commits no command and no haptic. |
| `NH-MEDIA-GESTURE-003` | Compact physical LEFT -> one `next` on release after one arm haptic when supported. |
| `NH-MEDIA-GESTURE-004` | Compact physical RIGHT -> one `previous` on release after one arm haptic when supported. |
| `NH-MEDIA-GESTURE-005` | Expanded direction/threshold/commit parity with follow-finger visual tracking. |
| `NH-MEDIA-GESTURE-006` | 28% / 70...120 pt threshold and 20 pt disarm hysteresis; one haptic per armed transition. |
| `NH-MEDIA-GESTURE-007` | Momentum cannot capture, arm, re-arm or commit. |
| `NH-MEDIA-GESTURE-008` | Diagonal ambiguity is rejected; captured horizontal gesture cannot expand/collapse. |
| `NH-MEDIA-GESTURE-009` | Compact physical DOWN requests expansion only. |
| `NH-MEDIA-GESTURE-010` | Expanded physical UP requests collapse only. |
| `NH-MEDIA-GESTURE-011` | Unsupported/unknown/failed/late previous-next cannot arm, haptic or commit. |
| `NH-MEDIA-GESTURE-012` | Compact arming uses bounded fresh one-shot capability validation, not persistent observation or retained capability trust. |
| `NH-MEDIA-GESTURE-013` | Progress is draggable only when seek is authoritatively supported with valid timing. |
| `NH-MEDIA-GESTURE-014` | Seek preview is local; one typed seek on valid completion; cancellation/failure does not fabricate success. |
| `NH-MEDIA-GESTURE-015` | Seek ownership excludes track and panel gestures. Track/source/capability identity change cancels the transaction. |
| `NH-MEDIA-GESTURE-016` | One-shot operations are lifecycle-owned; compact and Quit leave no orphan. |
| `NH-MEDIA-GESTURE-017` | Sandbox/Hardened Runtime/security/performance invariants remain intact. |
| `NH-MEDIA-GESTURE-018` | Real source matrix follows macOS Now Playing; absent capability is recorded honestly. |

## Video evidence — 2026-08-15

The target-Mac recording supplied by the user documents this exact sequence on rejected candidate `6c2109195042759b951217f489a201a82dd044cd`:

1. real music/media playback was already active;
2. NotchHub was then fully Quit while that playback context existed;
3. the recording also demonstrates horizontal track-change gestures mapped opposite to the frozen product contract:
   - physical LEFT selected the previous direction instead of `next`;
   - physical RIGHT selected the next direction instead of `previous`.

Acceptance interpretation is intentionally narrow:

- this is physical **FAIL** evidence for `NH-MEDIA-GESTURE-003/004` on `6c2109195042759b951217f489a201a82dd044cd`;
- it confirms that a full application Quit occurred in the recorded sequence after media playback had already started;
- the recording does **not** by itself prove that every helper/adapter process terminated after Quit; the explicit post-Quit `pgrep` gate remains required;
- video cannot establish whether the physical arm haptic was felt;
- Peek-only direction, permissions and all other unobserved M6.6 gates remain unaccepted;
- the corrected direction implementation is CI-verified but still requires a new physical retest on one exact repaired candidate.

## 2026-08-15 target-Mac direction rejection and repair

Exact source `6c2109195042759b951217f489a201a82dd044cd` / CI #1156 / run `31892019346` passed all three canonical CI jobs, strict traceability, exact-app XCUI, security/source policy, production transport/archive, Sandbox/Hardened Runtime/signing/preflight, size budget and shared-runner performance smoke. It was nevertheless physically rejected on Mac16,8/macOS 26.6 after the real-media video test above showed horizontal track gestures moving to the opposite track from the frozen LEFT/RIGHT contract.

Root cause was isolated to the AppKit precise-scroll normalization boundary. `MediaGestureCoordinator` already maps semantic negative X to `next` and positive X to `previous`, and the typed command boundary preserves those labels. The normalizer compensated for macOS scroll-direction preference but failed to convert horizontal scroll sign into the physical LEFT/RIGHT semantic sign; vertical normalization was already correct.

Focused TDD evidence:

- RED `f5cb5e3d1f13c7dc5564ce24068e83007f97bb1b` / CI #1157 / run `31897906228`: build and strict policy passed; the full 354-test / 75-suite run failed only the two new physical-direction assertions. LEFT normalized to positive X instead of negative X and RIGHT normalized to negative X instead of positive X; Y remained correct in both cases.
- GREEN `50b82dae49f3ce6c6e194b1ab9775bd5cd5dd430` / CI #1158 / run `31898052051`: the only production change is `x: -scrollingDeltaX * preferenceScale`; Y, coordinator direction mapping, thresholds, haptics, lifecycle and transport are unchanged. All 354 Swift tests pass, including both scroll-preference states, and all three canonical CI jobs pass with exact external-app XCUI, strict acceptance traceability, security/source policy, production transport/archive, Sandbox/Hardened Runtime/signing/preflight, size budget and performance smoke.

## 2026-08-15 external-XCUI boundary stabilization

The documentation descendant after #1158 exposed a separate automation defect: `openExpandedExplicitly()` addressed `click()` to the transient `notch.surface.compact` accessibility element, which can be replaced between synthetic mouse-down and mouse-up when presentation state changes. This caused product journeys to fail before their actual assertions even though the direction repair itself remained green.

Rejected experiments were kept fail-closed rather than hidden with retries or sleeps:

- application-relative coordinate click did not provide a stable screen coordinate for the borderless notch panel;
- raw CoreGraphics `CGEvent` click, including a Y-coordinate conversion experiment, did not reliably activate the real notch tap path;
- an outer SwiftUI accessibility container hid/broke the dynamic `compact`/`peek`/`expanded` state elements and exceeded the active DMG size budget; it was fully reverted and the budget was not relaxed.

Final automated repair uses the already-persistent AppKit `NSHostingView` as a **compile-time UI-test-only** accessibility hit target under `#if NOTCHHUB_UI_TESTING`. Shipping builds do not contain that identifier/seam. XCTest performs one ordinary click on this stable host; dynamic SwiftUI state identifiers remain unchanged; no retry, fixed sleep, event tap, raw synthetic shipping input path or new permission authority was added.

Current automated baseline is exact source `2235c3b3bb7eb69961d76f7b1a5f1afa9307f270` / CI #1177 / run `31904548631`: all three canonical jobs pass, including the complete Swift suite, strict acceptance traceability (`116/116`), exact external-app XCUI, shipping-fixture isolation, source/security validation, production transport/archive, Sandbox/Hardened Runtime/signing/preflight, unchanged size budget and performance smoke.

This source is **automated-green only**. The documentation commit that records this evidence creates a new SHA; that exact descendant must independently pass the same three canonical jobs before a new physical candidate is frozen.

## Repair-specific deterministic coverage

Automated coverage proves:

- physical X/Y deltas are normalized independently of macOS scroll-direction preference; LEFT remains next, RIGHT remains previous, DOWN remains expansion and UP remains collapse;
- media compact wings do not broaden the physical-notch hover activation region;
- trackpad `.mayBegin`/`.began` cancels pending hover dwell before local gesture recognition;
- seek captures authoritative media generation + source identity and rejects a different track/source even when it also supports seek;
- ordinary source revision updates inside the same media session do not invalidate seek unnecessarily;
- media/Home/session changes use bounded event-driven visual continuity only; no stale presentation timer is introduced;
- horizontal visual offset returns with a short bounded ease-out while lifecycle resets remain immediate.

## Target procedure

Use only the next exact docs-synchronized candidate frozen in PR #33 after all three canonical jobs pass.

1. Start real media playback.
2. In compact, physical LEFT must commit exactly one `next` track on release when supported; physical RIGHT must commit exactly one `previous` track.
3. Repeat both directions several times and confirm the arm haptic is felt exactly once per armed transition.
4. Repeat LEFT/RIGHT in Peek and expanded to verify direction parity and follow-finger visuals.
5. Continue short/reverse/threshold/re-arm/diagonal/momentum cases, seek capability/source-change cancellation, Hover Peek parity, source icon, permissions and lifecycle.
6. After compact operations and after a real Quit, run:

```bash
pgrep -lf 'mediaremote-adapter\.pl' || true
```

Expected: empty output.

## Acceptance rule

M6.6 remains **not accepted** until all applicable stable gates have explicit target-Mac evidence on one exact candidate. PR #33 remains draft until then.
