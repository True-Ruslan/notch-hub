# Changelog

All notable changes to NotchHub are documented here. The active version is stored in `VERSION`; published tags/releases are immutable.

## [Unreleased]

Published release remains `v0.1.0`. Everything below is source work not yet published as a new version.

### M6.6 — current draft PR #33

Status: **IMPLEMENTED / REGRESSION-INTEGRATED / TECHNICAL AUTOMATED-GREEN / FINAL DOCS-SYNC CI PENDING / PHYSICAL RETEST PENDING / NOT MERGED / NOT RELEASED**.

Added and hardened:

- local App-owned media gesture session with bounded horizontal visuals and public AppKit arm haptic;
- stable `compact`, `peek`, `expanded` presentation states under the existing Core transition authority;
- exactly 120 ms Hover Peek activation plus 140 ms pointer-exit grace;
- generic no-media Peek with one hover-haptic request after valid dwell;
- click and physical DOWN as explicit expansion paths, with stable outer SwiftUI tap ownership;
- persistent nonactivating AppKit host first-mouse acceptance without mouse-button authority;
- bounded one-shot media probing/commands in compact and Peek while persistent runtime remains expanded-only;
- bounded Peek cancellation that is nonblocking for the UI actor while subprocess ownership is still terminated through finite graceful/forced deadlines;
- exact-top-edge inclusive pointer retention for interactive DOWN;
- physical horizontal normalization independent of macOS scroll-direction preference: LEFT -> `next`, RIGHT -> `previous`;
- source-app identity badge through public `NSWorkspace` with bounded in-memory cache;
- capability-gated draggable seek in Peek and expanded, identity-locked across track/source changes;
- balanced seek cursor ownership without pointer warp/lock;
- strict native regression/UI automation and provenance-backed cumulative size budgets.

No global scroll/button/keyboard monitor, mouse-button event authority, event tap, polling loop, repeating timer, display link, UI-test retry/sleep masking, network/telemetry authority or new sensitive permission was added.

#### Physical acceptance history

- `d008f698b323963f084eedce601620ee957ef442` / CI #872 — rejected; later RED -> GREEN cycles repaired hover arbitration, vertical direction, stale seek identity and visual continuity.
- `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945 — rejected on stationary-startup Hover Peek; startup RED #947 -> GREEN #948.
- `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951 — rejected for expanded pointer-exit and interactive lost-terminal behavior.
- `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101 — rejected on 2026-08-15 for no-media Hover Peek/haptic and exact-top-edge DOWN self-collapse; expanded pointer-exit and ordinary DOWN/UP remained stable.
- `6c2109195042759b951217f489a201a82dd044cd` / CI #1156 — automated-green but physically rejected on 2026-08-15 because real-media LEFT/RIGHT track gestures were reversed relative to the frozen contract.

Historical physical failures remain retest requirements; later CI does not promote them to accepted.

#### Expanded pointer-exit / interactive settlement

Target testing found that expanded pointer exit no longer collapsed and physical UP could leave an intermediate clipped frame when shrinking geometry moved away before local terminal scroll delivery.

The repair restored expanded retention collapse and synchronously settles from actual panel geometry when needed, without global input capture. TDD: RED `0a42a701fcf4fa2f59972a68d2a3b9243203a202` / CI #959 -> GREEN `64d3e6c2beadacaeda69c8ac06f173ac26aace3e`.

#### Regression/UI Automation Foundation integration

PR #34 merged to `main` as `bd9566f690d314ed40fd6f3723a319291ceb4a58`; post-merge main CI #1053 was green.

M6.6 subsequently integrated fail-closed acceptance traceability, exact-app native XCUI, compile-time-only deterministic media/haptic fixtures, shipping-marker isolation, stable accessibility identities and protocol-based expanded runtime injection while concrete shipping composition remained unchanged.

#### Hover Peek / exact-edge / tap-ownership repair

Target testing of #1101 established that no-media hover must open generic Peek and that exact top-edge DOWN must be treated as inside the interactive surface. External XCUI additionally proved that click authority below replaceable presentation branches could lose an in-flight click.

Repair:

- no-media hover opens generic Peek first;
- interactive containment includes the exact physical top/right boundary;
- local `NSTrackingArea` remains the primary event-driven hover path;
- explicit expansion tap is owned by the stable outer `MediaNotchRootView`;
- proposed mouse-button interception was rejected rather than whitelisted.

Focused root-ownership RED #1153 -> GREEN #1155. Exact source `2235c3b3bb7eb69961d76f7b1a5f1afa9307f270` / CI #1177 later passed all canonical jobs with the stable UI-test-only AppKit hit target and unchanged shipping tap semantics.

#### Physical LEFT/RIGHT direction repair

The target-Mac video on rejected candidate `6c210919...` showed physical LEFT selecting the previous direction and RIGHT selecting the next direction.

Root cause was limited to AppKit precise-scroll normalization. The semantic coordinator and typed command mapping were already correct; vertical normalization was also correct.

- RED `f5cb5e3d1f13c7dc5564ce24068e83007f97bb1b` / CI #1157 failed only the new physical-direction assertions.
- GREEN `50b82dae49f3ce6c6e194b1ab9775bd5cd5dd430` / CI #1158 changed horizontal normalization to `x: -scrollingDeltaX * preferenceScale`; all 354 tests and canonical jobs were green.

The corrected direction remains physical-retest pending.

#### 2026-08-16 first-click and bounded Peek teardown repair

Two independent product-level click problems were isolated.

First, the persistent nonactivating host did not explicitly accept first mouse. Focused RED `7acd508...` -> GREEN `73dba83...` added only `acceptsFirstMouse(for:) = true`. SwiftUI tap remained click authority.

That production change required one reviewed DMG-size quantum in `performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json`; app/executable allowances were unchanged and older budgets remain immutable.

Second, exact source `122019646547b828b18fd4cc1d8776ff929fb588` / CI #1191 exposed a deeper race in `testTenHoverExitCyclesNeverLeaveStaleSurface`: XCUI moves the real pointer into the notch before completing click synthesis, so Hover Peek could settle and start bounded media work while the click was in flight. Cancellation synchronously waited for subprocess teardown on `@MainActor`; the failing click spent about **5.4 s** in event synthesis/idle and never reached expanded.

Fail-first progression:

- RED `6072b06f4564b1ef4c90d327e52187f743009705` / CI #1192 required `probe.acquire` only after authoritative Peek settlement.
- Settlement-only descendant `ab62544...` remained insufficient; its superseded external smoke became abnormally long and was cancelled.
- A read-only `NSEvent.pressedMouseButtons` guard produced one green run (#1196) but was not deterministic. Docs-synchronized CI #1200 reproduced the same journey with a **5.444 s** click stall, so the timing guard was rejected.
- RED policy head around `4f48126...` / CI #1201 required a nonblocking bounded teardown seam and removal of the timing guard.
- `b03b6f0ece0150f2007063ec9c5cc65b35ac8d87` / CI #1208 compiled with warnings-as-errors and ran **359 tests / 77 suites**. The new behavioral nonblocking lifecycle regression was green; the only failure was an obsolete source-policy assertion requiring the old synchronous `activeTransport.stop()` literal.

Final architecture:

- bounded Peek release calls `stopNonBlocking()` after callback detachment;
- in-flight bounded one-shot operations cancel immediately without `waitUntilExit` on the UI/caller path;
- actual process termination remains owned and bounded through one-shot graceful and forced deadlines;
- existing synchronous `stop()` remains for persistent expanded runtime and explicit Quit lifecycle verification;
- `NSEvent.pressedMouseButtons` is removed from correctness logic;
- no polling, repeating timer, sleep loop, event monitor/tap, mouse-button authority or permission expansion is introduced.

Exact technical source `45e5e8d863f16ff3416b55a41884af1bc655fb5c` / CI #1209 / run `31941027502` is **3/3 GREEN**:

- warnings-as-errors and **359 Swift tests / 77 suites**;
- strict acceptance traceability `116/116`;
- exact external-app native XCUI **11/11**, including the 10-cycle stress journey;
- repeated stress click synthesis/idle approximately **0.36–0.44 s**, with no recurrence of the historical ~5.44 s stall;
- probe/production transport archive verification, source/security policy, App Sandbox-only, Hardened Runtime/signing/preflight, active size budget and performance smoke all green.

#1209 technical artifacts:

- UI `.xcresult` `9262099134` / `sha256:45cd11b6f5004050ac28247206e8b626d2773bc28c4e6eeb602332db402701aa`;
- shipping-media candidate `9262076392` / `sha256:f1df7f4c2e6462c98cb80d4bade0789b57b41e0a8c220260ccc95b80a21834f1`;
- DMG `9262077564` / `sha256:00e28036c06f781f8e6d049dd51014339c26bf1671d3db7d43a316ceb4983e00`;
- performance metadata `9262077482` / `sha256:2acc92e8072540a383883223d00cd4b41d7442fe34c107f3b50c04debf57bf43`;
- production transport candidate `9262058205` / `sha256:732a6d0d8d4641d17bf1311cf0e23d5f5715d1b4dc466ecb3948b9343972e832`;
- MediaBridge probe candidate `9262047374` / `sha256:3cea823cd3fa6410e81bfb1622aed2ede287c6f1af627ffb97593d4064eeb1cd`.

Measured shipping sizes: app `883119 B`, DMG `560255 B`, executable `580912 B`; the existing first-click cumulative budget passed unchanged.

This changelog/docs synchronization creates a new source SHA. #1209 is technical evidence, not the frozen target-Mac candidate. The final docs-synchronized head must independently pass all three canonical jobs before source/artifact provenance is frozen in PR #33 without another repository commit.

### Earlier M6.6 prerequisites

- Task 0 collapse-layout retarget hardening physically accepted and merged via PR #22.
- Task 1 one-shot lifecycle ownership automated-accepted and merged via PR #24.
- Deterministic gesture engine, local gesture seam and bounded compact commands merged via PRs #26-#28.
- Interactive transition authority and vertical visual tracking merged via PRs #31-#32.

### M6.1-M6.5

- M6.1 system Now Playing feasibility accepted on target hardware.
- M6.2 normalized media controller/bridge boundary accepted and merged.
- M6.3 fixed pinned production media transport accepted and merged.
- M6.4 shipping composition/lazy expanded-only runtime accepted and merged.
- M6.5 Media-first compact/expanded UI accepted and merged.

### Engineering/security/performance foundations

- M0 native Swift 6 / SwiftUI + AppKit foundation, hardware-notch geometry, deterministic hover and strict CI/security/release policy accepted and merged.
- M1 primary interaction/transition foundation accepted and merged.
- P0 immutable performance/artifact baseline and target measurement methodology accepted; historical baseline files remain immutable.
- Regression/UI Automation Foundation merged via PR #34 and is a mandatory three-job CI product gate.
- App Sandbox-only + Hardened Runtime remain mandatory; no telemetry/direct app network/sensitive input permission surface has been added.

## [0.1.0] - 2026-08-07

### Added

- Initial native macOS NotchHub application foundation.
- Hardware-notch geometry and compact/expanded states.
- App Sandbox + Hardened Runtime and strict CI/security/release packaging.
- Personal Release DMG with checksum/provenance metadata.

### Acceptance

`NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, `NH-HOVER-003` and Personal Release acceptance passed on the target Mac. `v0.1.0` is immutable and intentionally ad-hoc signed/not notarized.
