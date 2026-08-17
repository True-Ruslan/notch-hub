# Changelog

All notable changes to NotchHub are documented here. The active version is stored in `VERSION`; published tags/releases are immutable.

## [Unreleased]

Published release remains `v0.1.0`. Everything below is source work not yet published as a new version.

### M6.6 — current draft PR #33

Status: **IMPLEMENTED / REGRESSION-INTEGRATED / MINIMAL TECHNICAL CANDIDATE 3/3 AUTOMATED-GREEN / FINAL DOCS-SYNC CI PENDING / PHYSICAL RETEST PENDING / NOT MERGED / NOT RELEASED**.

Added and hardened:

- local App-owned media gesture session with bounded horizontal visuals and public AppKit arm haptic;
- stable `compact`, `peek`, `expanded` presentation states under the existing Core transition authority;
- exactly 120 ms Hover Peek activation plus 140 ms pointer-exit grace;
- generic no-media Peek with one hover-haptic request after valid dwell;
- click and physical DOWN as explicit expansion paths, with stable outer SwiftUI tap ownership;
- persistent nonactivating AppKit host first-mouse acceptance without mouse-button authority;
- bounded one-shot media probing/commands in compact and Peek while persistent runtime remains expanded-only;
- bounded Peek cancellation that is nonblocking for the UI actor while subprocess ownership is still terminated through finite graceful/forced deadlines;
- stop-race hardening that prevents queued capability work or stale callbacks from escaping a stopped transport;
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
- `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101 — rejected on 2026-08-15 for no-media Hover Peek/haptic and exact-top-edge DOWN self-collapse.
- `6c2109195042759b951217f489a201a82dd044cd` / CI #1156 — automated-green but physically rejected on 2026-08-15 because real-media LEFT/RIGHT track gestures were reversed relative to the frozen contract.

Historical physical failures remain retest requirements; later CI does not promote them to accepted.

#### Horizontal direction repair

Root cause was limited to AppKit precise-scroll normalization. The semantic coordinator and typed command mapping were already correct; vertical normalization was also correct.

- RED `f5cb5e3d1f13c7dc5564ce24068e83007f97bb1b` / CI #1157 failed the new physical-direction assertions.
- GREEN `50b82dae49f3ce6c6e194b1ab9775bd5cd5dd430` / CI #1158 changed horizontal normalization to `x: -scrollingDeltaX * preferenceScale`; vertical semantics, thresholds and haptics were unchanged.

The corrected direction remains physical-retest pending.

#### Hover Peek / exact-edge / tap ownership

Target testing established that no-media hover must open generic Peek and exact top-edge DOWN must be considered inside the interactive surface. External XCUI also proved that click authority below replaceable presentation branches could lose an in-flight click.

Repair keeps:

- generic Peek before optional media enrichment;
- inclusive exact-top-edge containment;
- local `NSTrackingArea` hover path;
- explicit expansion tap on the stable outer `MediaNotchRootView`;
- no mouse-button interception or global input authority.

#### First-click and bounded Peek teardown repair

The persistent nonactivating host gained only `acceptsFirstMouse(for:) = true`. A deeper exact-app XCUI race then showed that Hover Peek could start bounded media work while a click was in flight. Synchronous subprocess teardown on `@MainActor` could block event processing for about 5.4 s.

A read-only `NSEvent.pressedMouseButtons` guard produced one green run but docs-synchronized CI #1200 reproduced a **5.444 s** stall, so that timing guard was rejected.

Final architecture:

- bounded probe acquisition begins only after authoritative `.peek` settlement;
- bounded Peek release calls `stopNonBlocking()` after callback detachment;
- in-flight one-shot work cancels immediately without `waitUntilExit` on the caller/UI actor;
- actual process termination remains bounded through one-shot graceful/forced deadlines;
- synchronous `stop()` remains for persistent expanded runtime and Quit verification;
- `NSEvent.pressedMouseButtons` is absent from correctness logic.

#### Stop-race / transport integration hardening

Subsequent regression work strengthened the proven lifecycle boundary:

- `MediaRemoteSystemTransportStopRaceTests` covers stop-before-queued-capability launch and stale post-stop activity;
- `ShippingMediaPeekProbeTransportIntegrationTests` covers first-usable-snapshot completion without waiting for later capability work and bounded transport teardown;
- metadata-only Peek completion and late capability behavior remain bounded and nonpersistent.

These regressions are included in the current **363-test / 79-suite** suite.

#### Removal of speculative primary-press seam

An experimental primary-press seam was evaluated but was not required by the proven repair. Commit `c4377436afa5fcb8e9eb9f9d3d8bc952f3647271` removed it completely:

- no primary-press state in interaction coordination;
- no AppKit `mouseDown`/`mouseUp` reporting seam;
- no controller wiring or dedicated production mouse-button semantics;
- no speculative primary-press regression test.

The minimal candidate retains stable SwiftUI click ownership, first-mouse acceptance, nonblocking Peek teardown and the corrected native UI harness.

#### Current technical baseline — #1230

Exact technical source `c4377436afa5fcb8e9eb9f9d3d8bc952f3647271` / CI #1230 / run `32000799095` is **3/3 GREEN** before this documentation synchronization:

- warnings-as-errors and **363 Swift tests / 79 suites**;
- strict acceptance traceability `116/116`;
- exact external-app native XCUI **11/11**;
- 10-cycle Hover Peek/exit/click stress GREEN with repeated click event synthesis around **0.35–0.44 s**, without recurrence of the historical ~5.44 s stall;
- probe/production transport archive verification, source/security policy, App Sandbox-only, Hardened Runtime/signing/preflight, active size budget and performance smoke all green.

#1230 technical artifacts:

- UI `.xcresult` `9278554509` / `sha256:b4ff2e92b1991d054f0efb20a603b8882d9ad4c74a15901341a0be61ec109bfe`;
- shipping-media candidate `9278444863` / `sha256:9e4dc9d64c39d6d4bcfac59169c220df36d8935832b71bb760a6efc3d2ae6315`;
- DMG `9278448535` / `sha256:57ee01c1520c853ee6377ae604d32fc5b245dfbc76209da16f20e2c0f3d232e7`;
- performance metadata `9278447870` / `sha256:9f24bc6fee371b88d6ff88782f024f9d4e5b334d448894bf34127b381fa90216`;
- production transport candidate `9278387131` / `sha256:49729b55d295a4649777c14e83da6ba3011aa0750850ec409ad2d067e2b8106d`;
- MediaBridge probe candidate `9278368378` / `sha256:0cf2699b3af0a82e4ad9035bb6ae4840700ea7cef8911661b6be7a075a20c543`.

Measured shipping sizes: app `882895 B`, DMG `559550 B`, executable `580688 B`; the existing first-click cumulative budget passed unchanged.

This changelog/docs synchronization creates a new source SHA. #1230 is technical evidence, not the frozen target-Mac candidate. The documentation-synchronized exact head must independently pass all three canonical jobs before source/artifact provenance is frozen in PR #33 without another repository commit.

### Earlier M6.6 prerequisites

- Task 0 collapse-layout retarget hardening physically accepted and merged via PR #22.
- Task 1 one-shot lifecycle ownership automated-accepted and merged via PR #24.
- Deterministic gesture engine, local gesture seam and bounded compact commands merged via PRs #26-#28.
- Interactive transition authority and vertical visual tracking merged via PRs #31-#32.
- Regression/UI Automation Foundation merged via PR #34 and is a mandatory three-job CI product gate.

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
- App Sandbox-only + Hardened Runtime remain mandatory; no telemetry/direct app network/sensitive input permission surface has been added.

## [0.1.0] - 2026-08-07

### Added

- Initial native macOS NotchHub application foundation.
- Hardware-notch geometry and compact/expanded states.
- App Sandbox + Hardened Runtime and strict CI/security/release packaging.
- Personal Release DMG with checksum/provenance metadata.

### Acceptance

`NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, `NH-HOVER-003` and Personal Release acceptance passed on the target Mac. `v0.1.0` is immutable and intentionally ad-hoc signed/not notarized.
