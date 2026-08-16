# Media Peek Acceptance

Status: AUTOMATED REPAIR GREEN / FINAL DOCS-SYNC CI PENDING / TARGET-MAC PHYSICAL RETEST PENDING
Date: 2026-08-16
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
- Bounded Peek acquisition/cancellation must never synchronously wait for subprocess exit on the UI actor. Cancellation detaches callbacks and uses `stopNonBlocking()`; owned process termination remains bounded by one-shot graceful and forced deadlines.
- Persistent expanded-runtime and application-Quit lifecycle retain the existing synchronous `stop()` contract and fail-closed teardown verification.
- Explicit expansion remains one stable SwiftUI tap path. The persistent AppKit host accepts first mouse for the nonactivating panel but does not become mouse-button authority.
- Exact top-screen/panel `maxY` is inside the interactive panel; physical DOWN from that edge must not self-cancel as a false pointer exit.
- Leaving expanded retention returns to exact compact non-haptically. Interactive expansion/collapse cannot settle at an intermediate frame.
- Seek cursor ownership remains balanced and local; no pointer warp/lock is used.
- No global scroll/button/keyboard monitor, mouse-button event authority, event tap, polling loop, repeating timer, display link, retry/sleep masking, or new sensitive permission is introduced.
- `NSEvent.pressedMouseButtons` is **not** part of the correctness mechanism. The earlier timing guard was removed after it proved nondeterministic.

The superseding no-media behavior is documented in `docs/superpowers/specs/2026-08-15-no-media-hover-peek-physical-repair.md`. Earlier Hover Peek documents remain historical where they conflict with this later physical-acceptance decision.

## Why the final teardown repair was required

The native XCUI click path moves the real pointer into the notch before mouse-down/up synthesis completes. That can legitimately settle generic Peek and start bounded media freshness work while an explicit click is in flight.

The original bounded-probe cancellation path called synchronous process teardown from `@MainActor`. `waitUntilExit(timeout:)` could therefore block SwiftUI/AppKit event processing. Exact run #1191 recorded a click spending about 5.4 seconds in XCTest event synthesis/idle before expansion was lost.

Moving acquisition until authoritative Peek settlement improved the race but did not remove the blocking primitive. A subsequent read-only `NSEvent.pressedMouseButtons` guard also proved probabilistic: docs-synchronized CI #1200 reproduced the same journey with a **5.444 s** click stall. That run is rejection evidence for the timing guard, not acceptance evidence.

The final repair moves correctness to the subprocess lifecycle boundary:

1. `ShippingMediaPeekProbe` releases its active transport through `stopNonBlocking()`.
2. `MediaRemoteSystemTransport.stopNonBlocking()` invalidates transport callbacks/state immediately and delegates nonblocking ownership teardown to the process client.
3. `MediaRemoteProcessClient.stopNonBlocking()` cancels in-flight one-shot operations immediately without `waitUntilExit` on the caller/UI path.
4. Deferred teardown sends graceful termination, then uses one-shot bounded deadlines for forced termination and final ownership cleanup if needed.
5. Existing synchronous `stop()` remains unchanged for persistent expanded runtime and explicit lifecycle/Quit verification.
6. The `NSEvent.pressedMouseButtons` guard was removed entirely; SwiftUI tap remains the only click-expansion authority.

This is event-driven bounded cleanup, not polling: no repeating timer, sleep loop, display link, event monitor, or permission expansion was added.

## Fail-first and technical evidence

- Historical physical candidate `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101 was rejected for no-media Hover Peek/haptic and exact-top-edge DOWN behavior. Those remain physical-retest requirements.
- Root tap ownership RED #1153 -> GREEN #1155 moved explicit tap authority above presentation branch replacement without retries or sleeps.
- First-mouse RED `7acd508...` -> GREEN `73dba83...` added only `acceptsFirstMouse(for:) = true` to the persistent hosting view.
- Exact source `122019646547b828b18fd4cc1d8776ff929fb588` / CI #1191 reproduced the deeper 10-cycle click/Peek race: compatibility/package GREEN, native XCUI failed `testTenHoverExitCyclesNeverLeaveStaleSurface`, with a ~5.4 s click stall.
- Settlement-policy RED `6072b06f4564b1ef4c90d327e52187f743009705` / CI #1192 required bounded probe acquisition only after authoritative `.peek` settlement.
- Settlement-only descendant `ab62544...` remained insufficient; its superseded external smoke became abnormally long and was cancelled.
- Timing-guard descendant `8656a0d...` / CI #1196 was 3/3 GREEN once, but later docs-synchronized CI #1200 reproduced the same 5.444 s stall. Therefore `pressedMouseButtons` was rejected as a correctness mechanism.
- RED policy head around `4f48126...` / CI #1201 required a nonblocking bounded teardown seam and removal of the timing guard.
- Head `b03b6f0ece0150f2007063ec9c5cc65b35ac8d87` / CI #1208 compiled with warnings-as-errors and ran **359 tests / 77 suites**. The new behavioral `nonblockingStopCancelsOneShotBeforeDeferredTerminationDeadlines` regression was GREEN; the only failure was an obsolete source-policy assertion requiring the old literal `activeTransport.stop()`.
- Exact technical source `45e5e8d863f16ff3416b55a41884af1bc655fb5c` / CI #1209 / run `31941027502` is **3/3 GREEN**:
  - macOS 26 compatibility: warnings-as-errors, **359 Swift tests / 77 suites**, probe candidate/archive and production transport/archive GREEN;
  - macOS UI regression: strict `116/116` traceability, shipping-fixture isolation, native external-app XCUI **11/11 GREEN**;
  - Build/test/package: source/security policy, App Sandbox-only, Hardened Runtime/signing/preflight, active feature-size budget and shared-runner performance smoke GREEN.
- `testTenHoverExitCyclesNeverLeaveStaleSurface` is GREEN on #1209. Repeated click synthesis/idle durations are approximately **0.36–0.44 s**, with no recurrence of the prior ~5.44 s stall.

## #1209 technical artifact provenance

These artifacts belong to the technical repair head, not yet the final physical candidate because this documentation update creates a new SHA.

- UI `.xcresult`: artifact `9262099134`, digest `sha256:45cd11b6f5004050ac28247206e8b626d2773bc28c4e6eeb602332db402701aa`.
- Shipping-media candidate: artifact `9262076392`, digest `sha256:f1df7f4c2e6462c98cb80d4bade0789b57b41e0a8c220260ccc95b80a21834f1`.
- DMG: artifact `9262077564`, digest `sha256:00e28036c06f781f8e6d049dd51014339c26bf1671d3db7d43a316ceb4983e00`.
- Performance metadata: artifact `9262077482`, digest `sha256:2acc92e8072540a383883223d00cd4b41d7442fe34c107f3b50c04debf57bf43`.
- Production transport candidate: artifact `9262058205`, digest `sha256:732a6d0d8d4641d17bf1311cf0e23d5f5715d1b4dc466ecb3948b9343972e832`.
- MediaBridge probe candidate: artifact `9262047374`, digest `sha256:3cea823cd3fa6410e81bfb1622aed2ede287c6f1af627ffb97593d4064eeb1cd`.
- Measured shipping sizes: app `883119 B`, DMG `560255 B`, executable `580912 B`.
- Existing `performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json` remains active and required no expansion.

## Candidate provenance rule

The physical candidate is the **final documentation-synchronized PR head** only after that exact SHA independently passes all three canonical jobs:

- `macOS 26 compatibility`;
- `macOS UI regression`;
- `Build, test and package`.

After that exact head is 3/3 GREEN, freeze its source SHA, workflow run, CI-produced shipping artifact/DMG provenance and measured sizes in PR #33 **without another repository commit**.

## Stable acceptance IDs

| ID | Gate | Required result | Automated | Physical |
|---|---|---|---|---|
| `NH-MEDIA-PEEK-001` | Hover destination + stationary restart | With usable media, 120 ms hover opens Peek only and requests the expected Peek haptic exactly once; relaunch with pointer already stationary behaves the same. | Unit + external XCUI GREEN through #1209 | FAIL on prior candidates; RETEST REQUIRED |
| `NH-MEDIA-PEEK-002` | No-media hover | Valid 120 ms no-media dwell opens generic Peek, requests one hover haptic, never expands, and starts no persistent media observation. | Unit + external XCUI GREEN through #1209 | PENDING |
| `NH-MEDIA-PEEK-003` | Fast pointer pass | Transit shorter than dwell does not expand or leave Peek stuck. | GREEN | PENDING |
| `NH-MEDIA-PEEK-004` | 140 ms grace | Exit/re-entry before 140 ms keeps Peek; staying outside through deadline returns to compact. | GREEN | PENDING |
| `NH-MEDIA-PEEK-005` | Explicit expansion | Free-surface click and physical DOWN from Peek each expand exactly once; compact click remains prompt while hover/media enrichment overlaps. | Root ownership + first mouse + nonblocking teardown; #1209 XCUI 11/11 and 10-cycle stress GREEN | PENDING |
| `NH-MEDIA-PEEK-006` | Peek horizontal gestures | LEFT -> next and RIGHT -> previous use bounded one-shot work; hover cannot steal an owned gesture. | GREEN | PENDING |
| `NH-MEDIA-PEEK-007` | Peek seek | Timeline seek works in Peek without expanding and suppresses notch gestures while active. | GREEN | PENDING |
| `NH-MEDIA-PEEK-008` | Seek cursor | Cursor hides only after valid seek begin and restores on every terminal/isolation path; no warp/lock. | GREEN | PENDING |
| `NH-MEDIA-PEEK-009` | Track continuity | Track/source changes update active media without obvious Home/interface blink while media stays valid. | GREEN | PENDING |
| `NH-MEDIA-PEEK-010` | Downward continuity | Compact DOWN follows interactive expansion; exact top edge is valid with no twitch/self-collapse or intermediate settled frame. | Unit + external regression GREEN through #1209 | FAIL on #1101 exact-edge case; RETEST REQUIRED |
| `NH-MEDIA-PEEK-011` | Expanded collapse + pointer exit | Expanded UP returns to exact compact; leaving retention also collapses non-haptically; no intermediate settled frame. | Prior RED -> GREEN + external XCUI through #1209 | FAIL on older candidate; pointer-exit GREEN on #1101; RETEST REQUIRED |
| `NH-MEDIA-PEEK-012` | Lifecycle | Compact, Peek, cancelled/retargeted transitions and Quit leave no unexpected persistent adapter. Bounded Peek cancellation is nonblocking for UI while subprocess ownership remains bounded. | Unit/process teardown + package/security GREEN through #1209 | PENDING |
| `NH-MEDIA-PEEK-013` | Permissions | No Accessibility, Input Monitoring, Automation or Screen Recording prompts are introduced. | Security/policy GREEN through #1209 | PENDING |

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
