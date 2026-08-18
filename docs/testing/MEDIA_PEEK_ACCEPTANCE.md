# Media Peek Acceptance

Status: ACCEPTED ON EXACT SOURCE `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3` / CI #1241 3/3 GREEN / NOT MERGED / NOT RELEASED
Date: 2026-08-18
Target: macOS 26.6 / Mac16,8
Scope: M6.6 PR #33 Hover Peek / explicit-click / lifecycle acceptance

This ledger is additive. Existing gesture, interactive-notch and source-icon IDs are not renumbered or weakened. Historical rejected candidates remain documented as historical evidence, while every stable Peek gate below records the final accepted contract.

## Current contract

- Stable presentation states remain `compact`, `peek`, and `expanded` under one panel/transition authority.
- Hover activation dwell is exactly 120 ms; Peek pointer-exit grace is exactly 140 ms.
- Hover opens Peek only. Click or physical DOWN explicitly expands.
- A pointer already stationary inside the compact hover region when the app is shown/restarted remains eligible for normal dwell.
- Usable media is not required for Peek. Generic Peek settles first; optional media enrichment begins only after authoritative Peek settlement.
- Settled compact and Peek own zero persistent media observer. Only settled expanded owns the presentation-scoped shipping runtime.
- Bounded Peek acquisition/cancellation never synchronously waits for subprocess exit on the UI actor.
- Persistent expanded-runtime and application-Quit lifecycle retain synchronous fail-closed teardown verification.
- Explicit expansion remains one stable SwiftUI tap path; AppKit hosting does not become mouse-button authority.
- Exact top-screen/panel `maxY` is inside the interactive panel.
- Leaving expanded retention returns exact compact non-haptically. Interactive expansion/collapse cannot settle at an intermediate frame.
- Seek cursor ownership remains balanced/local; no pointer warp/lock is used.
- No global scroll/button/keyboard monitor, event tap, polling loop, repeating timer, display link, retry/sleep masking or new sensitive permission is introduced.

## Stable acceptance IDs

| ID | Gate | Required result | Acceptance evidence |
|---|---|---|---|
| `NH-MEDIA-PEEK-001` | Hover destination + stationary restart | With usable media, 120 ms hover opens Peek only and requests expected Peek haptic exactly once; relaunch with pointer already stationary behaves the same. | PASS — automated dwell/startup regressions + final media-on/stationary physical matrix. |
| `NH-MEDIA-PEEK-002` | No-media hover | Valid 120 ms no-media dwell opens generic Peek, requests one hover haptic, never expands, and starts no persistent media observation. | PASS — generic-Peek regressions + final no-media physical matrix. |
| `NH-MEDIA-PEEK-003` | Fast pointer pass | Transit shorter than dwell does not expand or leave Peek stuck. | PASS — deterministic quick-transit regression; no separate physical-only requirement. |
| `NH-MEDIA-PEEK-004` | 140 ms grace | Exit/re-entry before 140 ms keeps Peek; staying outside through deadline returns compact. | PASS — exact deterministic 140 ms grace/re-entry regressions. |
| `NH-MEDIA-PEEK-005` | Explicit expansion | Free-surface click and physical DOWN from Peek each expand exactly once; compact click remains prompt while hover/media enrichment overlaps. | PASS — native XCUI/root ownership regressions + final overlapping-hover click physical matrix. |
| `NH-MEDIA-PEEK-006` | Peek horizontal gestures | LEFT -> next and RIGHT -> previous use bounded one-shot work; hover cannot steal an owned gesture. | PASS — Peek direction/capability regressions + final real horizontal matrix. |
| `NH-MEDIA-PEEK-007` | Peek seek | Timeline seek works in Peek without expanding and suppresses notch gestures while active. | PASS — seek isolation regressions + final seek physical matrix. |
| `NH-MEDIA-PEEK-008` | Seek cursor | Cursor hides only after valid seek begin and restores on every terminal/isolation path; no warp/lock. | PASS — cursor ownership policy regressions + final cursor restoration check. |
| `NH-MEDIA-PEEK-009` | Track continuity | Track/source changes update active media without obvious Home/interface blink while media stays valid. | PASS — session identity/continuity regressions + final track/source physical check. |
| `NH-MEDIA-PEEK-010` | Downward continuity | Compact DOWN follows interactive expansion; exact top edge is valid with no twitch/self-collapse or intermediate settled frame. | PASS — inclusive-edge/transition regressions + final exact-top-edge physical DOWN. |
| `NH-MEDIA-PEEK-011` | Expanded collapse + pointer exit | Expanded UP returns exact compact; leaving retention also collapses non-haptically; no intermediate settled frame. | PASS — pointer-exit/lost-terminal regressions + final physical pointer-exit/UP matrix. |
| `NH-MEDIA-PEEK-012` | Lifecycle | Compact, Peek, cancelled/retargeted transitions and Quit leave no unexpected persistent adapter; bounded Peek cancellation remains nonblocking. | PASS — stop-race/transport/package regressions + empty post-Quit `pgrep`. |
| `NH-MEDIA-PEEK-013` | Permissions | No Accessibility, Input Monitoring, Automation or Screen Recording prompts are introduced. | PASS — security/policy gates + final target permission matrix NONE. |

## Exact physical evidence

Exact source `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3` / CI #1241 / run `32075976405` is 3/3 GREEN with 366 Swift tests / 80 suites and external exact-app XCUI 11/11.

On 2026-08-18 Mac16,8/macOS 26.6, the requested final physical matrix passed, including media/no-media Hover Peek and haptics, stationary-pointer relaunch, click during enrichment, exact-edge DOWN, pointer-exit/UP settlement, seek/cursor/source continuity, source icon/fallback, permission surface and post-Quit helper cleanup.

## Lifecycle hardening retained

Correctness remains at the lifecycle boundary rather than a timing guard:

1. `ShippingMediaPeekProbe` releases active transport through `stopNonBlocking()`.
2. Transport callbacks/state are invalidated before ownership teardown.
3. In-flight one-shot operations cancel without `waitUntilExit` on the caller/UI path.
4. Graceful termination, forced termination if required and final cleanup remain bounded.
5. Existing synchronous `stop()` remains for persistent expanded runtime and explicit lifecycle/Quit verification.
6. SwiftUI tap remains the only click-expansion authority.

`MediaRemoteSystemTransportStopRaceTests` and `ShippingMediaPeekProbeTransportIntegrationTests` cover the stop-before-queued-capability and first-usable-snapshot seams. The discarded `NSEvent.pressedMouseButtons` timing guard and primary-press production seam remain absent.

## Historical rejection evidence retained

Earlier exact candidates failed stationary Hover Peek, no-media Peek/exact-top-edge DOWN or expanded pointer-exit/lost-terminal behavior. Those failures remain valid historical evidence for those source SHAs; the final accepted candidate supersedes them by passing the repaired physical matrix and the focused regressions.

## Acceptance provenance

Physical acceptance is frozen on runtime source `8744b9e...`. A documentation/coverage-only acceptance-record descendant does not become a new physical candidate. PR #33 remains unmerged and unreleased pending separate authorization.
