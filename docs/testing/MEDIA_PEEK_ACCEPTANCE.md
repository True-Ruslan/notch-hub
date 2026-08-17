# Media Peek Acceptance

Status: MINIMAL TECHNICAL CANDIDATE 3/3 AUTOMATED-GREEN / FINAL DOCS-SYNC CI PENDING / TARGET-MAC PHYSICAL RETEST PENDING
Date: 2026-08-17
Target: macOS 26.6 / Mac16,8
Scope: M6.6 PR #33 Hover Peek / explicit-click physical-acceptance repair

This ledger is additive. Existing `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, and `NH-MEDIA-SOURCE-ICON-*` IDs are not renumbered or weakened. Automated CI is necessary but does not replace target-Mac physical evidence.

## Current contract

- Stable presentation states remain `compact`, `peek`, and `expanded` under the existing single panel/transition authority.
- Hover activation dwell remains exactly 120 ms; Peek pointer-exit grace remains exactly 140 ms.
- Hover opens Peek only. Click or physical DOWN explicitly expands.
- A pointer already stationary inside the compact hover region when the app is shown/restarted remains eligible for the normal dwell.
- Usable media is not required for Peek. A valid dwell opens lightweight generic Peek first; optional media enrichment may begin only after authoritative Peek settlement.
- Settled compact and Peek own zero persistent media observer. Only settled expanded owns the presentation-scoped shipping runtime.
- Bounded Peek acquisition/cancellation never synchronously waits for subprocess exit on the UI actor. Cancellation detaches callbacks and uses `stopNonBlocking()`; owned process termination remains bounded by one-shot graceful and forced deadlines.
- Stop-before-queued-capability and stale-callback races fail closed; a first usable snapshot may finish Peek without waiting for later capability work.
- Persistent expanded-runtime and application-Quit lifecycle retain the existing synchronous `stop()` contract and fail-closed teardown verification.
- Explicit expansion remains one stable SwiftUI tap path. The persistent AppKit host accepts first mouse for the nonactivating panel but does not become mouse-button authority.
- Exact top-screen/panel `maxY` is inside the interactive panel; physical DOWN from that edge must not self-cancel as a false pointer exit.
- Leaving expanded retention returns to exact compact non-haptically. Interactive expansion/collapse cannot settle at an intermediate frame.
- Seek cursor ownership remains balanced and local; no pointer warp/lock is used.
- No global scroll/button/keyboard monitor, mouse-button event authority, event tap, polling loop, repeating timer, display link, retry/sleep masking, or new sensitive permission is introduced.
- `NSEvent.pressedMouseButtons` is not part of the correctness mechanism. The earlier timing guard and a later experimental primary-press seam are absent from the minimal candidate.

## Why the teardown repair was required

Native XCUI moves the real pointer into the notch before click synthesis completes. Generic Peek may therefore settle and overlap bounded media work while an explicit click is in flight.

The original bounded-probe cancellation path synchronously waited for process teardown from `@MainActor`. CI #1191 recorded a click spending about 5.4 seconds in event synthesis/idle before expansion was lost. A later read-only `NSEvent.pressedMouseButtons` timing guard proved probabilistic: CI #1200 reproduced the same journey with a **5.444 s** stall.

Correctness now lives at the subprocess lifecycle boundary:

1. `ShippingMediaPeekProbe` releases active transport through `stopNonBlocking()`.
2. Transport callbacks/state are invalidated immediately before nonblocking ownership teardown.
3. In-flight one-shot operations cancel immediately without `waitUntilExit` on the caller/UI path.
4. Graceful termination, forced termination if required, and final cleanup use bounded one-shot deadlines.
5. Existing synchronous `stop()` remains for persistent expanded runtime and explicit lifecycle/Quit verification.
6. SwiftUI tap remains the only click-expansion authority.

This is bounded event-driven cleanup, not polling.

## Additional race hardening and minimalization

After the initial #1209 repair, focused regressions strengthened the real transport boundary:

- `MediaRemoteSystemTransportStopRaceTests` covers stopping before queued capability work starts and prevents late one-shot launch after ownership is gone.
- `ShippingMediaPeekProbeTransportIntegrationTests` covers first-usable-snapshot completion and bounded release against the real transport seam.
- metadata-only Peek completion and late capability behavior remain bounded and do not create a persistent Peek observer.

An experimental primary-press state / AppKit `mouseDown`+`mouseUp` reporting seam was then removed in `c4377436afa5fcb8e9eb9f9d3d8bc952f3647271` because the proven repair does not require a second mouse-button authority.

## Technical #1230 evidence

Exact technical source `c4377436afa5fcb8e9eb9f9d3d8bc952f3647271` / CI #1230 / run `32000799095` is **3/3 GREEN** before this documentation synchronization:

- macOS 26 compatibility: warnings-as-errors, **363 Swift tests / 79 suites**, probe candidate/archive and production transport/archive GREEN;
- macOS UI regression: strict `116/116` traceability, shipping-fixture isolation, native exact external-app XCUI **11/11 GREEN**;
- Build/test/package: source/security policy, App Sandbox-only, Hardened Runtime/signing/preflight, active feature-size budget and shared-runner performance smoke GREEN;
- `testTenHoverExitCyclesNeverLeaveStaleSurface` is GREEN; its repeated stress clicks synthesize in roughly **0.35–0.44 s**, with no recurrence of the prior ~5.44 s stall.

## #1230 technical artifact provenance

These artifacts belong to the technical minimal head, not yet the final physical candidate because this documentation update creates a new SHA.

- UI `.xcresult`: artifact `9278554509`, digest `sha256:b4ff2e92b1991d054f0efb20a603b8882d9ad4c74a15901341a0be61ec109bfe`.
- Shipping-media candidate: artifact `9278444863`, digest `sha256:9e4dc9d64c39d6d4bcfac59169c220df36d8935832b71bb760a6efc3d2ae6315`.
- DMG: artifact `9278448535`, digest `sha256:57ee01c1520c853ee6377ae604d32fc5b245dfbc76209da16f20e2c0f3d232e7`.
- Performance metadata: artifact `9278447870`, digest `sha256:9f24bc6fee371b88d6ff88782f024f9d4e5b334d448894bf34127b381fa90216`.
- Production transport candidate: artifact `9278387131`, digest `sha256:49729b55d295a4649777c14e83da6ba3011aa0750850ec409ad2d067e2b8106d`.
- MediaBridge probe candidate: artifact `9278368378`, digest `sha256:0cf2699b3af0a82e4ad9035bb6ae4840700ea7cef8911661b6be7a075a20c543`.
- Measured shipping sizes: app `882895 B`, DMG `559550 B`, executable `580688 B`.
- Existing `performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json` remains active and required no expansion.

## Candidate provenance rule

The physical candidate is the **documentation-synchronized PR head** only after that exact SHA independently passes all three canonical jobs:

- `macOS 26 compatibility`;
- `macOS UI regression`;
- `Build, test and package`.

After that exact head is 3/3 GREEN, freeze its source SHA, workflow run, CI-produced shipping artifact/DMG provenance and measured sizes in PR #33 **without another repository commit**.

## Stable acceptance IDs

| ID | Gate | Required result | Automated | Physical |
|---|---|---|---|---|
| `NH-MEDIA-PEEK-001` | Hover destination + stationary restart | With usable media, 120 ms hover opens Peek only and requests the expected Peek haptic exactly once; relaunch with pointer already stationary behaves the same. | Unit + external XCUI GREEN through #1230 | REJECTED on historical physical candidates; RETEST REQUIRED |
| `NH-MEDIA-PEEK-002` | No-media hover | Valid 120 ms no-media dwell opens generic Peek, requests one hover haptic, never expands, and starts no persistent media observation. | Unit + external XCUI GREEN through #1230 | PENDING |
| `NH-MEDIA-PEEK-003` | Fast pointer pass | Transit shorter than dwell does not expand or leave Peek stuck. | GREEN | PENDING |
| `NH-MEDIA-PEEK-004` | 140 ms grace | Exit/re-entry before 140 ms keeps Peek; staying outside through deadline returns to compact. | GREEN | PENDING |
| `NH-MEDIA-PEEK-005` | Explicit expansion | Free-surface click and physical DOWN from Peek each expand exactly once; compact click remains prompt while hover/media enrichment overlaps. | Root ownership + first mouse + nonblocking teardown; #1230 XCUI 11/11 and 10-cycle stress GREEN | PENDING |
| `NH-MEDIA-PEEK-006` | Peek horizontal gestures | LEFT -> next and RIGHT -> previous use bounded one-shot work; hover cannot steal an owned gesture. | GREEN | PENDING |
| `NH-MEDIA-PEEK-007` | Peek seek | Timeline seek works in Peek without expanding and suppresses notch gestures while active. | GREEN | PENDING |
| `NH-MEDIA-PEEK-008` | Seek cursor | Cursor hides only after valid seek begin and restores on every terminal/isolation path; no warp/lock. | GREEN | PENDING |
| `NH-MEDIA-PEEK-009` | Track continuity | Track/source changes update active media without obvious Home/interface blink while media stays valid. | GREEN | PENDING |
| `NH-MEDIA-PEEK-010` | Downward continuity | Compact DOWN follows interactive expansion; exact top edge is valid with no twitch/self-collapse or intermediate settled frame. | Unit + external regression GREEN through #1230 | REJECTED on historical exact-edge candidate; RETEST REQUIRED |
| `NH-MEDIA-PEEK-011` | Expanded collapse + pointer exit | Expanded UP returns to exact compact; leaving retention also collapses non-haptically; no intermediate settled frame. | Prior RED -> GREEN + external XCUI through #1230 | REJECTED on historical candidate; later pointer-exit evidence improved; RETEST REQUIRED |
| `NH-MEDIA-PEEK-012` | Lifecycle | Compact, Peek, cancelled/retargeted transitions and Quit leave no unexpected persistent adapter. Bounded Peek cancellation is nonblocking for UI while subprocess ownership remains bounded. | Unit + stop-race + integration + package/security GREEN through #1230 | PENDING |
| `NH-MEDIA-PEEK-013` | Permissions | No Accessibility, Input Monitoring, Automation or Screen Recording prompts are introduced. | Security/policy GREEN through #1230 | PENDING |

## Focused target-Mac procedure

Use only the exact final docs-synchronized candidate frozen in PR #33 after all three canonical CI jobs are GREEN.

1. With real media playing, hover to Peek repeatedly, including stationary-pointer relaunch; verify one physical hover haptic and no accidental full expansion.
2. With media absent, repeat Hover Peek and verify generic Peek plus one physical haptic.
3. Repeatedly click compact while Hover Peek/media enrichment can overlap; expansion must be prompt, single, and visibly stall-free.
4. From Peek, verify click and physical DOWN each expand exactly once.
5. Verify exact-top-edge DOWN, expanded pointer-exit, UP collapse and no intermediate settled geometry.
6. Verify Peek LEFT -> next and RIGHT -> previous, seek/cursor isolation and track/source continuity.
7. After compact/Peek bounded operations and after real Quit, run:

```bash
pgrep -lf 'mediaremote-adapter\.pl' || true
```

Expected: empty output.

8. Confirm Accessibility, Input Monitoring, Automation and Screen Recording remain unrequested.

## Acceptance rule

Any required physical failure keeps PR #33 draft and unmerged. Automated haptic-request evidence is not a substitute for feeling the physical haptic on Mac16,8.

Only after all applicable `NH-MEDIA-PEEK-*`, `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*` and `NH-MEDIA-SOURCE-ICON-*` gates are physically green on one exact candidate may M6.6 be marked accepted and PR #33 become merge-eligible.
