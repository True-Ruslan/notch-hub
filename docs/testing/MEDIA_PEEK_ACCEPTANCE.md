# Media Peek Acceptance

Status: AUTOMATED-GREEN THROUGH CI #1238 / FINAL HORIZONTAL PHYSICAL CONTRACT CONFIRMED ON `f2e81d993...` / FULL PEEK ONE-SHA PHYSICAL MATRIX PENDING
Date: 2026-08-18
Target: macOS 26.6 / Mac16,8
Scope: M6.6 PR #33 Hover Peek / explicit-click / lifecycle acceptance

This ledger is additive. Existing `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, and `NH-MEDIA-SOURCE-ICON-*` IDs are not renumbered or weakened. Automated CI is necessary but does not replace target-Mac physical evidence. Historical rejected gates stay rejected until superseded by explicit physical evidence on the final exact candidate.

## Current contract

- Stable presentation states remain `compact`, `peek`, and `expanded` under the existing single panel/transition authority.
- Hover activation dwell remains exactly 120 ms; Peek pointer-exit grace remains exactly 140 ms.
- Hover opens Peek only. Click or physical DOWN explicitly expands.
- A pointer already stationary inside the compact hover region when the app is shown/restarted remains eligible for the normal dwell.
- Usable media is not required for Peek. A valid dwell opens lightweight generic Peek first; optional media enrichment may begin only after authoritative Peek settlement.
- Settled compact and Peek own zero persistent media observer. Only settled expanded owns the presentation-scoped shipping runtime.
- Bounded Peek acquisition/cancellation never synchronously waits for subprocess exit on the UI actor. Cancellation detaches callbacks and uses `stopNonBlocking()`; owned process termination remains bounded.
- Stop-before-queued-capability and stale-callback races fail closed; a first usable snapshot may finish Peek without waiting for later capability work.
- Persistent expanded-runtime and application-Quit lifecycle retain the synchronous `stop()` contract and fail-closed teardown verification.
- Explicit expansion remains one stable SwiftUI tap path. The persistent AppKit host accepts first mouse but does not become mouse-button authority.
- Exact top-screen/panel `maxY` is inside the interactive panel.
- Leaving expanded retention returns to exact compact non-haptically. Interactive expansion/collapse cannot settle at an intermediate frame.
- Seek cursor ownership remains balanced and local; no pointer warp/lock is used.
- No global scroll/button/keyboard monitor, event tap, polling loop, repeating timer, display link, retry/sleep masking or new sensitive permission is introduced.

## Current automated evidence

Exact source `f2e81d993db37af9548799682ad8f03c7d64ae27` / CI #1238 / run `32072408370` is 3/3 GREEN with 365 Swift tests / 79 suites and external exact-app XCUI 11/11. Source/security policy, App Sandbox-only, Hardened Runtime/signing/preflight, current cumulative size budget and shared-runner performance smoke are also GREEN.

The final horizontal gesture contract was physically confirmed on this exact source on 2026-08-18. That evidence is recorded in `MEDIA_GESTURE_ACCEPTANCE.md` and does not automatically promote Peek-specific physical gates.

## Stable acceptance IDs

| ID | Gate | Required result | Automated | Physical |
|---|---|---|---|---|
| `NH-MEDIA-PEEK-001` | Hover destination + stationary restart | With usable media, 120 ms hover opens Peek only and requests expected Peek haptic exactly once; relaunch with pointer already stationary behaves the same. | GREEN through #1238 | REJECTED on historical physical candidate; final exact-head RETEST REQUIRED |
| `NH-MEDIA-PEEK-002` | No-media hover | Valid 120 ms no-media dwell opens generic Peek, requests one hover haptic, never expands, and starts no persistent media observation. | GREEN | RETEST REQUIRED / PENDING final exact-head evidence |
| `NH-MEDIA-PEEK-003` | Fast pointer pass | Transit shorter than dwell does not expand or leave Peek stuck. | GREEN | PENDING |
| `NH-MEDIA-PEEK-004` | 140 ms grace | Exit/re-entry before 140 ms keeps Peek; staying outside through deadline returns to compact. | GREEN | PENDING |
| `NH-MEDIA-PEEK-005` | Explicit expansion | Free-surface click and physical DOWN from Peek each expand exactly once; compact click remains prompt while hover/media enrichment overlaps. | Root ownership + native XCUI stress GREEN | PENDING |
| `NH-MEDIA-PEEK-006` | Peek horizontal gestures | LEFT -> next and RIGHT -> previous use bounded one-shot work; hover cannot steal an owned gesture. | Core direction contract GREEN through #1238 | Horizontal direction physically confirmed outside full Peek matrix; Peek-specific parity PENDING |
| `NH-MEDIA-PEEK-007` | Peek seek | Timeline seek works in Peek without expanding and suppresses notch gestures while active. | GREEN | PENDING |
| `NH-MEDIA-PEEK-008` | Seek cursor | Cursor hides only after valid seek begin and restores on every terminal/isolation path; no warp/lock. | GREEN | PENDING |
| `NH-MEDIA-PEEK-009` | Track continuity | Track/source changes update active media without obvious Home/interface blink while media stays valid. | GREEN | PENDING |
| `NH-MEDIA-PEEK-010` | Downward continuity | Compact DOWN follows interactive expansion; exact top edge is valid with no twitch/self-collapse or intermediate settled frame. | GREEN | REJECTED on historical exact-edge candidate; final exact-head RETEST REQUIRED |
| `NH-MEDIA-PEEK-011` | Expanded collapse + pointer exit | Expanded UP returns to exact compact; leaving retention also collapses non-haptically; no intermediate settled frame. | GREEN | REJECTED on historical candidate; final exact-head RETEST REQUIRED |
| `NH-MEDIA-PEEK-012` | Lifecycle | Compact, Peek, cancelled/retargeted transitions and Quit leave no unexpected persistent adapter. Bounded Peek cancellation is nonblocking for UI while subprocess ownership remains bounded. | Stop-race + transport-integration + package/security GREEN | PENDING explicit final lifecycle evidence |
| `NH-MEDIA-PEEK-013` | Permissions | No Accessibility, Input Monitoring, Automation or Screen Recording prompts are introduced. | Security/policy GREEN | PENDING final permission matrix |

## Lifecycle hardening retained

Native XCUI exposed a real interaction race: the pointer can enter the notch before click synthesis finishes, allowing generic Peek and bounded media work to overlap an explicit click. Correctness now lives at the lifecycle boundary rather than a timing guard:

1. `ShippingMediaPeekProbe` releases active transport through `stopNonBlocking()`.
2. Transport callbacks/state are invalidated before ownership teardown.
3. In-flight one-shot operations cancel without `waitUntilExit` on the caller/UI path.
4. Graceful termination, forced termination if required and final cleanup remain bounded.
5. Existing synchronous `stop()` remains for persistent expanded runtime and explicit lifecycle/Quit verification.
6. SwiftUI tap remains the only click-expansion authority.

`MediaRemoteSystemTransportStopRaceTests` and `ShippingMediaPeekProbeTransportIntegrationTests` cover the stop-before-queued-capability and first-usable-snapshot transport seams. The experimental `NSEvent.pressedMouseButtons` timing guard and primary-press production seam are absent from the final architecture.

## Final target-Mac procedure

Use only the next exact test/documentation head after all three canonical CI jobs are GREEN.

1. Reconfirm LEFT -> next / RIGHT -> previous with follow-finger motion once.
2. With media playing, hover to Peek repeatedly, including stationary-pointer relaunch; verify one physical hover haptic and no accidental expansion.
3. With media absent, repeat Hover Peek and verify generic Peek plus one physical haptic.
4. Repeatedly click compact while Hover Peek/media enrichment can overlap; expansion must remain prompt and single.
5. From Peek verify click and physical DOWN each expand exactly once, including exact-top-edge DOWN.
6. Verify expanded pointer-exit and physical UP both settle to exact compact.
7. Verify Peek seek/cursor isolation and track/source continuity.
8. After compact/Peek bounded operations and after real Quit run `pgrep -lf 'mediaremote-adapter\.pl' || true`; expected output is empty.
9. Confirm Accessibility, Input Monitoring, Automation and Screen Recording remain unrequested.

## Acceptance rule

Any required physical failure keeps PR #33 draft and unmerged. Automated haptic-request evidence is not a substitute for felt physical haptic output on Mac16,8. M6.6 can become accepted only after the complete applicable M6.6 physical matrix is green on one final exact candidate.
