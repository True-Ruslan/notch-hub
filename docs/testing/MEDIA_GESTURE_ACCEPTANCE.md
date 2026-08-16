# M6.6 Media Gesture, Haptic and Seek Acceptance

Status: IMPLEMENTED / AUTOMATED-TESTED / PHYSICAL RETEST PENDING
Date: 2026-08-16
Primary target: macOS 26.6 / Mac16,8
PR: #33 — `M6.6: app media gesture session TDD`

The stable IDs below remain frozen. Automated GREEN is necessary but does not constitute target-Mac physical acceptance.

## Non-negotiable boundaries

- Gesture input remains local to a NotchHub-owned view; no global scroll/button/keyboard monitor, event tap, synthetic media keys, or sensitive input permission.
- `NotchPanelTransitionCoordinator` remains the sole panel transition authority.
- Settled compact and Peek own zero persistent media adapter processes. Bounded one-shot capability/command/probe work is allowed only behind the reviewed fixed transport boundary.
- Bounded Peek cancellation is nonblocking for the UI actor; owned subprocess termination remains bounded by one-shot graceful/forced deadlines. Persistent expanded-runtime and explicit Quit teardown retain synchronous lifecycle verification.
- Expanded observation remains presentation-scoped.
- Unsupported/unknown capabilities fail closed.
- No progress/media polling, repeating timer, display link, or sleep loop.
- Horizontal haptic occurs only when entering armed; no vertical gesture haptic is added.
- Seek is available only with authoritative capability and trustworthy timing and remains isolated from track/panel gestures.
- Physical direction is independent of macOS scroll-direction preference: LEFT means `next`, RIGHT means `previous`, DOWN means expansion, UP means collapse.
- Explicit click remains a stable SwiftUI tap path; no mouse-button event authority was introduced.

## Stable IDs

| ID | Required result | Automated | Physical |
|---|---|---|---|
| `NH-MEDIA-GESTURE-001` | Local-only event surface; no new sensitive authority. | GREEN through #1209 | PENDING |
| `NH-MEDIA-GESTURE-002` | Short/reverted horizontal gesture commits no command and no haptic. | GREEN | PENDING |
| `NH-MEDIA-GESTURE-003` | Compact physical LEFT -> one `next` on release after one arm haptic when supported. | Direction RED #1157 -> GREEN #1158; regression GREEN through #1209 | Historical candidate `6c210919...` was rejected; RETEST REQUIRED |
| `NH-MEDIA-GESTURE-004` | Compact physical RIGHT -> one `previous` on release after one arm haptic when supported. | Direction RED #1157 -> GREEN #1158; regression GREEN through #1209 | Historical candidate `6c210919...` was rejected; RETEST REQUIRED |
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
| `NH-MEDIA-GESTURE-016` | One-shot operations are lifecycle-owned; compact/Peek and Quit leave no orphan. | Synchronous + nonblocking lifecycle regressions GREEN through #1209 | PENDING |
| `NH-MEDIA-GESTURE-017` | Sandbox/Hardened Runtime/security/performance invariants remain intact. | GREEN through #1209 | PENDING |
| `NH-MEDIA-GESTURE-018` | Real source matrix follows macOS Now Playing; absent capability is recorded honestly. | GREEN | PENDING |

## Physical direction rejection and repair

The target-Mac recording supplied on 2026-08-15 documents a real-media sequence on rejected candidate `6c2109195042759b951217f489a201a82dd044cd` / CI #1156 / run `31892019346` in which physical LEFT selected the previous direction and physical RIGHT selected the next direction. This remains physical rejection evidence for `NH-MEDIA-GESTURE-003/004` on that historical candidate only.

Root cause was isolated to `MediaGestureInputNormalizer`. The semantic coordinator already mapped negative semantic X to `next` and positive X to `previous`; typed command mapping was also correct. Horizontal AppKit scroll sign had not been converted into the frozen physical LEFT/RIGHT semantic sign.

Focused TDD:

- RED `f5cb5e3d1f13c7dc5564ce24068e83007f97bb1b` / CI #1157: the complete suite failed only the two new physical-direction assertions; vertical Y remained correct.
- GREEN `50b82dae49f3ce6c6e194b1ab9775bd5cd5dd430` / CI #1158: horizontal normalization became `x: -scrollingDeltaX * preferenceScale`; Y, thresholds, haptics, lifecycle and transport were unchanged. All 354 tests and all three canonical CI jobs were GREEN.

The corrected direction has not yet been physically retested on the final candidate, so IDs 003/004 remain pending/retest-required rather than accepted.

## Explicit-click / Hover Peek teardown hardening

Subsequent native XCUI work exposed an interaction boundary relevant to gesture acceptance because click, Hover Peek and bounded one-shot work share the same compact/Peek surface.

- Stable outer SwiftUI tap ownership was established through RED #1153 -> GREEN #1155.
- The persistent nonactivating AppKit host gained only `acceptsFirstMouse(for:) = true`; it did not become mouse-button authority.
- CI #1191 then exposed a deeper race: Hover Peek could start bounded media work while an XCUI click was in flight; synchronous subprocess teardown on `@MainActor` could block click processing for ~5.4 seconds.
- Settled-only probe startup and a later read-only `NSEvent.pressedMouseButtons` guard were insufficient. Docs-synchronized CI #1200 reproduced the same **5.444 s** click stall, proving the timing guard was not a correctness mechanism.
- The final repair introduced `stopNonBlocking()` only for bounded Peek ownership. Cancellation returns immediately from the UI path while subprocess termination is completed through bounded one-shot graceful/forced deadlines. Existing synchronous stop semantics remain for persistent expanded runtime and Quit.
- `NSEvent.pressedMouseButtons` was removed from correctness logic. No button monitor, event tap, polling, retry, sleep, or permission expansion was added.

Behavioral regression `nonblockingStopCancelsOneShotBeforeDeferredTerminationDeadlines` proves the bounded caller does not invoke `waitUntilExit`; separate teardown tests continue to prove synchronous fail-closed lifecycle behavior.

## Current automated baseline

Exact technical source `45e5e8d863f16ff3416b55a41884af1bc655fb5c` / CI #1209 / run `31941027502` is 3/3 GREEN:

- warnings-as-errors build;
- **359 Swift tests / 77 suites**;
- strict acceptance traceability `116/116`;
- exact external-app native XCUI **11/11**;
- 10-cycle Hover Peek/exit/click stress GREEN with repeated click synthesis/idle around **0.36–0.44 s** instead of the historical ~5.44 s stall;
- MediaBridge probe and production transport candidates/archive GREEN;
- source/security policy, App Sandbox-only, Hardened Runtime/signing/preflight GREEN;
- current cumulative size budget and shared-runner performance smoke GREEN.

Technical #1209 shipping sizes: app `883119 B`, DMG `560255 B`, executable `580912 B`. The active `performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json` required no expansion.

This documentation update creates a new source SHA, so #1209 remains technical repair evidence rather than the frozen physical candidate.

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
