# M6.6 Media Gesture, Haptic and Seek Acceptance

Status: IMPLEMENTED / AUTOMATED-TESTED / PHYSICAL RETEST PENDING
Date: 2026-08-12
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

## Repair-specific deterministic coverage

After the failed first physical candidate, automated coverage additionally proves:

- physical X/Y deltas are normalized independently of macOS scroll-direction preference; RIGHT remains previous, LEFT remains next, DOWN remains expansion and UP remains collapse;
- media compact wings do not broaden the physical-notch hover activation region;
- trackpad `.mayBegin`/`.began` cancels pending hover dwell before local gesture recognition;
- seek captures authoritative media generation + source identity and rejects a different track/source even when it also supports seek;
- ordinary source revision updates inside the same media session do not invalidate seek unnecessarily;
- media/Home/session changes use bounded event-driven visual continuity only; no stale presentation timer is introduced;
- horizontal visual offset returns with a short bounded ease-out while lifecycle resets remain immediate.

Full RED/GREEN evidence is recorded in `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md` and `CHANGELOG.md`.

## Target procedure

Use the exact final CI candidate. Verify both directions in compact and expanded states, short/reverse/threshold/re-arm/diagonal/momentum cases, seek capability and source-change cancellation, hover parity, source icon, permissions and lifecycle.

After compact operations and after Quit:

```bash
pgrep -lf 'mediaremote-adapter\.pl' || true
```

Expected: empty output.

## Acceptance rule

M6.6 remains **not accepted** until all applicable stable gates have explicit target-Mac evidence on one exact candidate. PR #33 remains draft until then.
