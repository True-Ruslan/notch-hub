# M6.6 Media Gesture, Haptic and Seek Acceptance

Status: IMPLEMENTED / MINIMAL TECHNICAL CANDIDATE 3/3 AUTOMATED-GREEN / FINAL DOCS-SYNC CI PENDING / PHYSICAL RETEST PENDING
Date: 2026-08-17
Primary target: macOS 26.6 / Mac16,8
PR: #33 — `M6.6: app media gesture session TDD`

The stable IDs below remain frozen. Automated GREEN is necessary but does not constitute target-Mac physical acceptance.

## Non-negotiable boundaries

- Gesture input remains local to a NotchHub-owned view; no global scroll/button/keyboard monitor, event tap, synthetic media keys, or sensitive input permission.
- `NotchPanelTransitionCoordinator` remains the sole panel transition authority.
- Settled compact and Peek own zero persistent media adapter processes. Bounded one-shot capability/command/probe work is allowed only behind the reviewed fixed transport boundary.
- Bounded Peek cancellation is nonblocking for the UI actor; owned subprocess termination remains bounded by one-shot graceful/forced deadlines. Stop races and stale callbacks fail closed. Persistent expanded-runtime and explicit Quit teardown retain synchronous lifecycle verification.
- Expanded observation remains presentation-scoped.
- Unsupported/unknown capabilities fail closed.
- No progress/media polling, repeating timer, display link, or sleep loop.
- Horizontal haptic occurs only when entering armed; no vertical gesture haptic is added.
- Seek is available only with authoritative capability and trustworthy timing and remains isolated from track/panel gestures.
- Physical direction is independent of macOS scroll-direction preference: LEFT means `next`, RIGHT means `previous`, DOWN means expansion, UP means collapse.
- Explicit click remains a stable SwiftUI tap path; no mouse-button event authority is present.

## Stable IDs

| ID | Required result | Automated | Physical |
|---|---|---|---|
| `NH-MEDIA-GESTURE-001` | Local-only event surface; no new sensitive authority. | GREEN through #1230 | PENDING |
| `NH-MEDIA-GESTURE-002` | Short/reverted horizontal gesture commits no command and no haptic. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-003` | Compact physical LEFT -> one `next` on release after one arm haptic when supported. | Direction RED #1157 -> GREEN #1158; regression GREEN through #1230 | Historical candidate `6c210919...` was rejected; RETEST REQUIRED |
| `NH-MEDIA-GESTURE-004` | Compact physical RIGHT -> one `previous` on release after one arm haptic when supported. | Direction RED #1157 -> GREEN #1158; regression GREEN through #1230 | Historical candidate `6c210919...` was rejected; RETEST REQUIRED |
| `NH-MEDIA-GESTURE-005` | Expanded direction/threshold/commit parity with follow-finger visual tracking. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-006` | 28% / 70...120 pt threshold and 20 pt disarm hysteresis; one haptic per armed transition. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-007` | Momentum cannot capture, arm, re-arm or commit. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-008` | Diagonal ambiguity is rejected; captured horizontal gesture cannot expand/collapse. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-009` | Compact physical DOWN requests expansion only. | GREEN | PENDING; exact-edge RETEST REQUIRED |
| `NH-MEDIA-GESTURE-010` | Expanded physical UP requests collapse only. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-011` | Unsupported/unknown/failed/late previous-next cannot arm, haptic or commit. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-012` | Compact arming uses bounded fresh one-shot capability validation, not persistent observation or retained capability trust. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-013` | Progress is draggable only when seek is authoritatively supported with valid timing. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-014` | Seek preview is local; one typed seek on valid completion; cancellation/failure does not fabricate success. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-015` | Seek ownership excludes track and panel gestures; track/source/capability identity change cancels the transaction. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-016` | One-shot operations are lifecycle-owned; compact/Peek and Quit leave no orphan. | Synchronous + nonblocking + stop-race regressions GREEN through #1230 | PENDING |
| `NH-MEDIA-GESTURE-017` | Sandbox/Hardened Runtime/security/performance invariants remain intact. | GREEN through #1230 | PENDING |
| `NH-MEDIA-GESTURE-018` | Real source matrix follows macOS Now Playing; absent capability is recorded honestly. | GREEN | PENDING |

## Physical direction rejection and repair

Target-Mac evidence on historical candidate `6c2109195042759b951217f489a201a82dd044cd` / CI #1156 showed physical LEFT selecting the previous direction and physical RIGHT selecting the next direction. This remains rejection evidence for that historical candidate only.

Root cause was isolated to `MediaGestureInputNormalizer`. The semantic coordinator already mapped negative semantic X to `next` and positive X to `previous`; typed command mapping was correct. Horizontal AppKit scroll sign needed conversion into the frozen physical LEFT/RIGHT semantic sign.

Focused TDD:

- RED `f5cb5e3d1f13c7dc5564ce24068e83007f97bb1b` / CI #1157 failed the two new physical-direction assertions while vertical Y remained correct.
- GREEN `50b82dae49f3ce6c6e194b1ab9775bd5cd5dd430` / CI #1158 changed horizontal normalization to `x: -scrollingDeltaX * preferenceScale`; Y, thresholds, haptics, lifecycle and transport were unchanged.

The corrected direction has not yet been physically retested on the final candidate, so IDs 003/004 remain pending/retest-required rather than accepted.

## Explicit-click / Hover Peek lifecycle hardening

Native XCUI exposed a shared compact/Peek interaction race: a real click can move the pointer into the notch before mouse event synthesis finishes, allowing valid Hover Peek work to overlap the click.

- Stable outer SwiftUI tap ownership was established without retries/sleeps.
- The persistent nonactivating AppKit host gained only `acceptsFirstMouse(for:) = true`; it did not become mouse-button authority.
- CI #1191 showed synchronous bounded-process teardown on `@MainActor` could block click processing for about 5.4 seconds.
- Settled-only probe startup and a later read-only `NSEvent.pressedMouseButtons` timing guard were insufficient; CI #1200 reproduced a **5.444 s** stall.
- Correctness moved to `stopNonBlocking()` for bounded Peek ownership. Cancellation returns immediately from the UI path while subprocess termination completes through bounded one-shot graceful/forced deadlines.
- Synchronous stop semantics remain for persistent expanded runtime and Quit.

Additional regression work now covers stop-before-queued-capability launch, stale post-stop callbacks, first-usable-snapshot Peek completion and transport integration. No polling, retry, sleep or new input authority was introduced.

## Removal of speculative mouse-button semantics

A later experimental primary-press seam was evaluated but was not required by the proven lifecycle repair. Exact technical head `c4377436afa5fcb8e9eb9f9d3d8bc952f3647271` removes its state, AppKit `mouseDown`/`mouseUp` reporting, controller wiring and dedicated test. The final minimal architecture therefore retains one click authority: the stable SwiftUI tap path.

## Current technical baseline

Exact technical source `c4377436afa5fcb8e9eb9f9d3d8bc952f3647271` / CI #1230 / run `32000799095` is 3/3 GREEN before this documentation synchronization:

- warnings-as-errors build;
- **363 Swift tests / 79 suites**;
- strict acceptance traceability `116/116`;
- exact external-app native XCUI **11/11**;
- 10-cycle Hover Peek/exit/click stress GREEN with repeated click synthesis roughly **0.35–0.44 s**, instead of the historical ~5.44 s stall;
- MediaBridge probe and production transport candidates/archive GREEN;
- source/security policy, App Sandbox-only, Hardened Runtime/signing/preflight GREEN;
- current cumulative size budget and shared-runner performance smoke GREEN.

Technical #1230 shipping sizes: app `882895 B`, DMG `559550 B`, executable `580688 B`. The active `performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json` required no expansion.

This documentation update creates a new source SHA, so #1230 remains technical evidence rather than the frozen physical candidate. The docs-synchronized exact head must independently pass all three canonical jobs.

## Target procedure

Use only the final documentation-synchronized candidate after its exact SHA passes all three canonical CI jobs.

1. Start real media playback.
2. In compact, repeatedly perform physical LEFT and RIGHT. LEFT must commit exactly one `next`; RIGHT exactly one `previous` when supported.
3. Confirm the arm haptic is felt exactly once per supported armed transition; short/reverted and unsupported gestures must not haptic or commit.
4. Repeat direction/threshold/re-arm/diagonal/momentum cases in Peek and expanded and verify follow-finger visuals.
5. Verify physical DOWN expansion and UP collapse, including exact-top-edge DOWN and pointer/panel separation cases.
6. Verify seek capability, preview, commit/cancel, cursor restoration and track/source identity cancellation.
7. Exercise compact click while Hover Peek/media enrichment can overlap; expansion must remain prompt and single.
8. After bounded compact/Peek work and after real Quit, run:

```bash
pgrep -lf 'mediaremote-adapter\.pl' || true
```

Expected: empty output.

9. Confirm no Accessibility, Input Monitoring, Automation/Apple Events, or Screen Recording permission prompt appears.

## Acceptance rule

M6.6 remains **not accepted** until all applicable stable gates have explicit target-Mac evidence on one exact candidate. Automated haptic-request evidence is not a substitute for the felt physical haptic. PR #33 remains draft until then.
