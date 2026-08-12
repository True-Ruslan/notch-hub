# M6.6 Media Gesture, Haptic and Seek Acceptance

Status: CONTRACT FROZEN / IMPLEMENTATION PENDING
Date: 2026-08-12
Primary target: macOS 26.6 / Mac16,8
Design source: `docs/superpowers/specs/2026-08-09-universal-media-gestures-haptics-design.md`

## Purpose

This ledger freezes the acceptance contract for M6.6 before gesture production code is added. Automated tests must prove deterministic state-machine, capability, lifecycle and security behavior; target-Mac checks must prove actual trackpad feel, haptic semantics, media-command behavior and clean process teardown.

Issue #20 was completed first as the transition-hardening prerequisite. Exact accepted source `0d40391721ae934653a9c75fc981dd683121cf46` passed CI #776 / run `31567162859` and the focused target-Mac matrix, then PR #22 was squash-merged as `f017addd2efc9aed5b60b1556205bdb8eab23e0e`.

## Non-negotiable boundaries

- Gesture recognition is local to NotchHub's own view/window. No global `.scrollWheel` monitor, `CGEventTap`, Accessibility, Input Monitoring or synthetic media keys.
- `NotchPanelTransitionCoordinator` remains the only compact/expanded panel transition authority.
- Compact steady state keeps the accepted zero-persistent-adapter lifecycle. M6.6 may use bounded one-shot media operations only as a direct consequence of a local user gesture; they must finish/cancel cleanly and leave no child process.
- Expanded observation remains presentation-scoped exactly as accepted in M6.4/M6.5.
- Unsupported or unknown commands fail closed. No emulation or player-specific fallback.
- No media/progress polling, repeating timer, display link, sleep loop or busy loop is added for gesture handling.
- Haptics use public AppKit feedback and are emitted only for semantic state transitions, never every raw `.changed` event.
- Draggable seek exists only with authoritative seek support and trustworthy position/duration.
- Track/source metadata remains local, is not persisted as listening history and is not emitted to production logs.

## Compact command safety delta

M6.5 intentionally stops the persistent media runtime after compact settlement, so retained compact media is not live-observed. Direct compact swipes therefore must not silently keep observation alive or trust a potentially stale capability forever.

The M6.6 compact command path is frozen as follows:

1. a physical local gesture may begin tracking without starting persistent observation;
2. compact horizontal tracking requests the **current** system capability through the already reviewed fixed `/usr/bin/perl` boundary as a bounded one-shot operation;
3. the gesture may enter `armed` only when that one-shot result authoritatively says the requested previous/next command is supported while the same physical gesture is still active and above threshold;
4. unavailable, failed, late, unsupported or unknown capability results leave the gesture unarmed and produce no haptic;
5. release while armed sends exactly one bounded one-shot typed command to the current macOS system Now Playing source;
6. completion, cancellation, timeout and application termination must leave zero owned one-shot or observation processes;
7. this path never starts the persistent `ShippingMediaRuntime` in compact mode.

Expanded Media already owns the accepted observation runtime and may use its live authoritative presentation capabilities for arming and its existing typed command path for commit.

## Gesture constants to test before hardware tuning

Initial engineering values from the approved design:

- horizontal arm threshold: `clamp(0.28 * interactiveWidth, 70 pt ... 120 pt)`;
- disarm hysteresis: `20 pt`;
- horizontal capture requires clear X-axis dominance over Y-axis movement;
- reaching threshold means `armed`, not command execution;
- command execution occurs only on physical gesture end while still armed.

Any threshold/dominance tuning from target-Mac acceptance must be a single explicit change, documented here and frozen into regression tests.

## Stable acceptance IDs

| ID | Gate | Required result |
|---|---|---|
| `NH-MEDIA-GESTURE-001` | Local-only event surface | Scroll/gesture input is received only by a NotchHub-owned view/window; no global scroll monitor, event tap or new sensitive permission surface exists. |
| `NH-MEDIA-GESTURE-002` | Short/reverted horizontal gesture | Below-threshold or reverted gesture commits no command and emits no haptic. |
| `NH-MEDIA-GESTURE-003` | Compact swipe left | With current `next=supported`, physical left swipe arms at threshold, haptics once, and commits exactly one `next` on physical release. |
| `NH-MEDIA-GESTURE-004` | Compact swipe right | With current `previous=supported`, physical right swipe arms at threshold, haptics once, and commits exactly one `previous` on physical release. |
| `NH-MEDIA-GESTURE-005` | Expanded horizontal parity | Expanded Media uses the same direction/threshold/commit semantics as compact while preserving stronger in-content visual tracking only. |
| `NH-MEDIA-GESTURE-006` | Threshold + hysteresis | Entering armed emits one haptic; staying armed emits none; dropping at least 20 pt below threshold disarms; deliberate re-arm may emit one new haptic. |
| `NH-MEDIA-GESTURE-007` | Momentum rejection | Momentum-only events cannot capture, arm, re-arm or commit media commands. |
| `NH-MEDIA-GESTURE-008` | Axis arbitration | Diagonal/non-dominant movement does not accidentally switch tracks; once horizontal is captured, the same gesture cannot expand/collapse. |
| `NH-MEDIA-GESTURE-009` | Compact vertical down | A qualifying local downward gesture requests expansion through existing panel transition authority and sends no media command. |
| `NH-MEDIA-GESTURE-010` | Expanded vertical up | A qualifying local upward gesture requests collapse through existing panel transition authority and sends no media command. |
| `NH-MEDIA-GESTURE-011` | Unsupported/unknown commands | Previous/next that is unsupported, unknown, failed or not confirmed in time cannot arm, haptic or commit. |
| `NH-MEDIA-GESTURE-012` | Compact capability freshness | Compact arming depends on a bounded current-system one-shot capability result; it does not start persistent observation or blindly rely on retained M6.5 capability state. |
| `NH-MEDIA-GESTURE-013` | Seek visibility/actionability | Progress is draggable only when `canSeek == true` and trustworthy position/duration exist; otherwise it remains a passive indicator or is absent exactly as M6.5 requires. |
| `NH-MEDIA-GESTURE-014` | Seek transaction | Drag updates only local preview; release emits one typed absolute seek; cancellation or command failure returns to the latest authoritative position without fabricating success. |
| `NH-MEDIA-GESTURE-015` | Seek isolation | While seek owns the interaction, horizontal previous/next recognition and vertical panel gestures cannot capture or commit. |
| `NH-MEDIA-GESTURE-016` | One-shot lifecycle | Compact capability/command one-shots are bounded, cancellation-safe, normal Quit cancels/tears down in-flight work, settled compact returns to zero adapter/process ownership, and no orphan remains. |
| `NH-MEDIA-GESTURE-017` | Security/performance invariants | App Sandbox-only + Hardened Runtime remain intact; no new entitlement, network, telemetry, history persistence, polling/repeating timer/display link or arbitrary command surface is introduced. |
| `NH-MEDIA-GESTURE-018` | Real source matrix | On the target Mac, gesture/control behavior follows macOS system Now Playing across Yandex Music, Apple Music, Spotify, Safari or Chromium YouTube, plus one additional independent player when installed/available; capability absence is recorded as capability absence, not fabricated as support. |

## Deterministic automated matrix

Automated tests must cover at least:

- pure threshold calculation at minimum/intermediate/maximum widths;
- short swipe cancel;
- physical threshold arm and exactly-one haptic effect;
- no command during `.changed`;
- physical `.ended` while armed -> exactly one semantic command;
- `.cancelled` -> no command;
- disarm/re-arm with 20 pt hysteresis;
- momentum cannot arm or commit;
- diagonal movement cannot capture horizontal;
- horizontal capture suppresses vertical action;
- unsupported/unknown/unavailable capability cannot arm;
- late compact capability result after physical gesture end is ignored;
- stale compact capability result from an older gesture generation is ignored;
- seek session excludes track/panel gestures;
- seek clamps preview/commit to `0...duration` and rejects non-finite/invalid timing;
- seek cancellation/failure restores authoritative position;
- teardown cancels outstanding one-shot operations and stale completions are harmless;
- app composition contains no global `.scrollWheel` monitor or synthetic key fallback;
- existing M6.4/M6.5 lifecycle/security/performance policy suites remain green.

## Target-Mac procedure

Use the exact CI-produced candidate and record its source SHA, Actions run, artifact ID/digest and contained DMG SHA-256 before testing.

For horizontal swipes, verify both compact and expanded behavior with short, threshold, over-threshold, reverse-before-release, deliberate disarm/re-arm, diagonal and momentum cases. Confirm the haptic occurs only when entering armed and not again on commit.

For vertical gestures, verify compact down expands and expanded up collapses without competing horizontal media commands or duplicate haptics.

For seek-capable sources, verify preview, commit, cancellation and source-reported final position. For non-seek-capable sources, verify the progress surface cannot be dragged and produces no seek command.

During compact steady state and after compact gesture operations finish:

```bash
pgrep -lf 'mediaremote-adapter\.pl' || true
```

Expected: no owned process remains. Repeat after normal Quit, including at least one Quit initiated while a compact capability/command gesture operation is in flight.

Confirm macOS did not request Accessibility, Input Monitoring, Automation or Screen Recording permissions.

## Acceptance rule

M6.6 is not accepted merely because CI is green. It becomes `ACCEPTED` only when all applicable `NH-MEDIA-GESTURE-001...018` gates have explicit evidence on the exact candidate, with unsupported third-party capabilities recorded truthfully rather than worked around.
