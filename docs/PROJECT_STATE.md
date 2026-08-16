# Project state

Last updated: 2026-08-16
Published version: `0.1.0` Personal Release
Primary physical target: macOS 26.6 / Mac16,8
Protected branch: `main`

## Product state

NotchHub is a native, local-first macOS productivity hub built around the physical MacBook notch. Security, privacy, performance, energy use and deterministic interaction behavior are first-class constraints. Runtime work remains event-driven unless separately measured evidence justifies otherwise.

Published state remains immutable `v0.1.0`. M6.6 below is unreleased source work.

### Merged foundations

- M0 Engineering Foundation — accepted/merged.
- R0.1 Personal Release `v0.1.0` — accepted/released.
- P0 Performance Foundation — accepted/merged; immutable baseline preserved.
- P0.1 Public repository readiness — accepted.
- M1 primary interaction/transition foundation — accepted/merged; active-display/fullscreen/Spaces/notchless/multi-monitor hardening remains deferred.
- M6.1 transport feasibility — accepted.
- M6.2 normalized media boundary — accepted/merged.
- M6.3 production system transport — accepted/merged.
- M6.4 shipping media composition/lazy lifecycle — accepted/merged.
- M6.5 Media-first UI — accepted/merged.
- M6.6 prerequisite tasks through vertical visual tracking — merged.
- Regression/UI Automation Foundation — merged via PR #34 as `bd9566f690d314ed40fd6f3723a319291ceb4a58`; post-merge `main` CI #1053 passed all canonical jobs.

Current PR #33 base is `main` at `bd9566f690d314ed40fd6f3723a319291ceb4a58`.

## Active work — M6.6 PR #33

PR #33 `M6.6: app media gesture session TDD` is **implemented / regression-integrated / technical automated-green / final docs-synchronized CI pending / physical retest pending / draft / not merged / not released**.

Current interaction contract:

- stable `compact <-> peek <-> expanded` under one transition authority;
- hover dwell is exactly 120 ms; Peek exit grace is exactly 140 ms;
- valid hover opens lightweight generic Peek even without usable media; optional media enrichment begins only after authoritative Peek settlement;
- settled compact and Peek own zero persistent media observer; only settled expanded owns the presentation-scoped shipping runtime;
- explicit click remains one stable SwiftUI tap path; persistent AppKit hosting accepts first mouse but does not own mouse-button semantics;
- physical DOWN expands; physical UP collapses; exact top-screen/panel `maxY` is inside the interaction region;
- expanded pointer exit returns non-haptically to exact compact;
- interactive transitions settle to exact endpoints even when moving geometry leaves the pointer before terminal local scroll delivery;
- physical horizontal direction is LEFT -> `next`, RIGHT -> `previous`, independent of macOS scroll-direction preference;
- seek, source identity and cursor isolation remain bounded/event-driven;
- bounded Peek cancellation is nonblocking for the UI actor, while actual subprocess ownership remains bounded by one-shot graceful/forced termination deadlines;
- persistent expanded-runtime and application-Quit teardown retain synchronous fail-closed lifecycle verification.

No global scroll/button/keyboard monitor, mouse-button event authority, event tap, polling loop, repeating timer, display link, UI-test retry/sleep masking, new process executable boundary, network authority, telemetry, or sensitive permission was introduced.

## Physical evidence still controlling acceptance

The user-provided target-Mac recording from 2026-08-15 on historical candidate `6c2109195042759b951217f489a201a82dd044cd` / CI #1156 showed physical LEFT/RIGHT track gestures reversed relative to the frozen contract. It is physical **FAIL** evidence for `NH-MEDIA-GESTURE-003/004` on that candidate.

The normalizer repair is automated-green but has not yet been physically retested on the final candidate. Video also cannot establish the felt haptic or post-Quit helper cleanup, so those gates remain pending.

Historical candidate `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` was also physically rejected for no-media Hover Peek/haptic and exact-top-edge DOWN self-collapse. The relevant automated repairs are green, but target-Mac retest remains required.

## Horizontal direction repair

Root cause was isolated to AppKit precise-scroll normalization. The semantic coordinator and typed command mapping were already correct; horizontal scroll sign needed conversion into the physical LEFT/RIGHT semantic sign.

- RED `f5cb5e3d1f13c7dc5564ce24068e83007f97bb1b` / CI #1157 failed only the new physical-direction assertions.
- GREEN `50b82dae49f3ce6c6e194b1ab9775bd5cd5dd430` / CI #1158 changed horizontal normalization to `x: -scrollingDeltaX * preferenceScale`; Y, thresholds, haptics, lifecycle and transport were unchanged.
- #1158 passed all 354 Swift tests and all canonical CI jobs.

Physical LEFT/RIGHT remains pending until the repaired final candidate is tested on Mac16,8.

## Explicit-click / Hover Peek root cause and final repair

Several exact-app CI cycles isolated the last nondeterministic click failure.

First, the persistent nonactivating hosting view did not explicitly accept first mouse. A focused RED -> GREEN added only `acceptsFirstMouse(for:) = true`; SwiftUI tap remained expansion authority.

CI #1191 then exposed a deeper problem in `testTenHoverExitCyclesNeverLeaveStaleSurface`: a real XCUI click moves the pointer into the notch before click synthesis completes. The ordinary 120 ms hover path could settle generic Peek and start bounded media work while the click was still in flight. Retarget/cancellation synchronously waited for subprocess teardown on `@MainActor`; the failing click spent about **5.4 s** in event synthesis/idle and never reached `expanded`.

A settlement-only acquisition change was necessary but insufficient. A later read-only `NSEvent.pressedMouseButtons` guard also proved nondeterministic: docs-synchronized CI #1200 reproduced the same stress journey with a **5.444 s** click stall. That evidence rejected the timing guard as a correctness mechanism.

Final architecture:

- generic Peek opens immediately after valid dwell;
- bounded enrichment may start only after authoritative `.peek` settlement;
- bounded Peek release calls `stopNonBlocking()` and detaches callbacks before returning from the UI path;
- in-flight one-shot operations are cancelled immediately without `waitUntilExit` on the caller/UI actor;
- actual graceful termination, forced termination if required, and ownership cleanup remain bounded by one-shot scheduled deadlines;
- synchronous `stop()` remains the lifecycle contract for persistent expanded runtime and explicit Quit verification;
- `NSEvent.pressedMouseButtons` was removed from correctness logic entirely.

This introduces no polling/repeating timer/sleep loop, no event monitor/tap, no mouse-button authority and no new permission.

### Fail-first evidence

- CI #1191 / source `122019646547b828b18fd4cc1d8776ff929fb588`: compatibility/package GREEN; external XCUI failed the 10-cycle stress with ~5.4 s click stall.
- RED `6072b06f4564b1ef4c90d327e52187f743009705` / CI #1192: 357 tests, exactly the new settled-probe policy failed.
- Settlement-only descendant `ab62544...` remained insufficient; superseded external smoke became abnormally long and was cancelled.
- Timing-guard descendant `8656a0d...` / CI #1196 was 3/3 GREEN once, but #1200 later reproduced the 5.444 s stall, so that mechanism was rejected.
- RED policy head around `4f48126...` / CI #1201 required nonblocking bounded teardown and removal of the timing guard.
- `b03b6f0ece0150f2007063ec9c5cc65b35ac8d87` / CI #1208: warnings-as-errors GREEN; **359 tests / 77 suites** ran. The new behavioral nonblocking lifecycle regression was GREEN; the sole failure was an obsolete source-policy assertion demanding the old `activeTransport.stop()` literal.
- `45e5e8d863f16ff3416b55a41884af1bc655fb5c` / CI #1209 / run `31941027502`: **3/3 GREEN** after the policy was updated to require `stopNonBlocking()` and reject synchronous stop on bounded Peek.

## Technical #1209 evidence

`45e5e8d863f16ff3416b55a41884af1bc655fb5c` is the current technical repair head before this docs synchronization.

- `macOS 26 compatibility` — GREEN, warnings-as-errors, **359 Swift tests / 77 suites**, MediaBridge probe/archive and production transport/archive.
- `macOS UI regression` — GREEN, strict acceptance traceability `116/116`, exact app, shipping-fixture isolation, native external XCUI **11/11**.
- `Build, test and package` — GREEN, source/security policy, App Sandbox-only, Hardened Runtime/signing/preflight, active cumulative size budget and shared-runner performance smoke.
- `testTenHoverExitCyclesNeverLeaveStaleSurface` — GREEN; repeated stress clicks complete event synthesis/idle in roughly **0.36–0.44 s** rather than the historical ~5.44 s stall.

Technical artifact provenance:

- UI `.xcresult`: `9262099134`, `sha256:45cd11b6f5004050ac28247206e8b626d2773bc28c4e6eeb602332db402701aa`;
- shipping-media candidate: `9262076392`, `sha256:f1df7f4c2e6462c98cb80d4bade0789b57b41e0a8c220260ccc95b80a21834f1`;
- DMG: `9262077564`, `sha256:00e28036c06f781f8e6d049dd51014339c26bf1671d3db7d43a316ceb4983e00`;
- performance metadata: `9262077482`, `sha256:2acc92e8072540a383883223d00cd4b41d7442fe34c107f3b50c04debf57bf43`;
- production transport candidate: `9262058205`, `sha256:732a6d0d8d4641d17bf1311cf0e23d5f5715d1b4dc466ecb3948b9343972e832`;
- MediaBridge probe candidate: `9262047374`, `sha256:3cea823cd3fa6410e81bfb1622aed2ede287c6f1af627ffb97593d4064eeb1cd`.

Measured shipping sizes: app `883119 B`, DMG `560255 B`, executable `580912 B`.

This state-file update creates a new source SHA. Therefore #1209 is technical repair evidence, **not** the frozen physical candidate. The final documentation-synchronized head must independently pass all three canonical jobs before its SHA/artifacts are frozen without another repository commit.

## Security and resource invariants

- App Sandbox-only entitlement and Hardened Runtime remain mandatory.
- No Accessibility, Input Monitoring, Automation, Screen Recording, networking, telemetry, history persistence or arbitrary command authority is added.
- Universal Media retains the reviewed fixed `/usr/bin/perl` + pinned adapter/framework boundary.
- Settled compact and Peek own zero persistent adapter; optional Peek enrichment is bounded and cancellation is nonblocking for UI; settled expanded owns the expected presentation-scoped runtime; normal Quit must leave no orphan.
- Gesture/Peek/transition hot paths add no polling, repeating timer, display link, global scroll/button monitor, event tap, per-event subprocess creation, or production logging.
- UI fixtures and diagnostics remain compile-time test-only; shipping composition still creates concrete production runtime.

## Performance state

`performance/baseline-v0.1.0.json` and all historical feature budgets remain immutable provenance records.

The active cumulative envelope remains `performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json`: app allowance `614400 B`, DMG allowance `471040 B`, executable allowance `315392 B` over immutable `v0.1.0`.

Technical #1209 measured app `883119 B`, DMG `560255 B`, executable `580912 B`, all inside the unchanged active envelope. The final nonblocking teardown repair required **no further budget expansion**.

Shared-runner performance remains compatibility evidence only. Target-Mac CPU/RSS/threads/wakeups/energy acceptance remains P1 and starts only after M6.6 physical acceptance and merge.

## Not yet accepted

- physical LEFT -> next and RIGHT -> previous after direction repair in compact, Peek and expanded;
- physical arm haptic for supported horizontal gestures;
- real no-media and media hover -> Peek physical haptic;
- stationary-pointer relaunch Hover Peek/haptic;
- compact click while Hover Peek/media enrichment overlaps — automated stress is green, target-Mac physical confirmation remains required;
- exact-top-edge physical DOWN with no twitch/self-collapse;
- UP/DOWN settlement under pointer/panel separation;
- seek/cursor/source-continuity physical matrix;
- lifecycle cleanup after real Quit, including explicit empty `pgrep` evidence;
- permission matrix;
- remaining `NH-MEDIA-PEEK-*`, affected `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, and `NH-MEDIA-SOURCE-ICON-*` physical gates;
- PR #33 remains draft and unmerged;
- no new release claim is made;
- P1 and multi-display hardening remain blocked by M6.6 acceptance.

## Next optimal step

1. Complete documentation synchronization for the final nonblocking teardown architecture.
2. Pass all three canonical CI jobs on that exact final docs-synchronized PR #33 head.
3. If and only if that exact head is 3/3 GREEN, freeze its SHA and CI-produced shipping/DMG provenance in PR #33 **without another repository commit**.
4. Physically retest the frozen candidate on Mac16,8/macOS 26.6 with real media: LEFT/RIGHT direction, arm haptic, Hover Peek/no-media/stationary restart, click-during-enrichment, exact-edge DOWN, pointer-exit/UP settlement, seek/source continuity, permission surface and process lifecycle.
5. After real Quit, run `pgrep -lf 'mediaremote-adapter\.pl' || true` and require empty output.
6. Only after full physical evidence is green may PR #33 become ready, merge, receive post-merge `main` verification and unblock P1.
