# Changelog

All notable changes to NotchHub are documented here. The active version is stored in `VERSION`; published tags/releases are immutable.

## [Unreleased]

Published release remains `v0.1.0`. Everything below is source work not yet published as a new version.

### M6.6 — current draft PR #33

Status: **IMPLEMENTED / INTEGRATED WITH REGRESSION FOUNDATION / AUTOMATED GREEN / PHYSICAL RETEST PENDING / NOT MERGED / NOT RELEASED**.

Added:

- local App-owned media gesture session with bounded horizontal visuals and public AppKit arm haptic;
- stable `compact`, `peek`, `expanded` presentation states under the existing Core transition authority;
- 120 ms media-only Hover Peek plus 140 ms pointer-exit grace;
- click and physical DOWN as explicit expansion paths;
- bounded one-shot media probing/commands in compact and Peek while persistent runtime remains expanded-only;
- source-app identity badge through public `NSWorkspace` and bounded in-memory cache;
- capability-gated draggable seek in Peek and expanded, identity-locked across track/source changes;
- balanced seek cursor ownership without pointer warp/lock;
- strict native regression/UI automation integrated with M6.6;
- cumulative provenance-backed integration size budget over immutable P0.

Physical acceptance history:

- first complete candidate `d008f698b323963f084eedce601620ee957ef442` / CI #872 rejected; focused RED -> GREEN cycles repaired hover arbitration, physical vertical direction, stale seek identity and visual continuity;
- Hover Peek evidence `7daffde9b7c2a734e2ddfa234b1ee744b0d96d9e` / CI #939 and subsequent size-policy repair completed;
- docs-synchronized candidate `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945 rejected on stationary-startup Hover Peek;
- startup RED `553cf973722dfb214f0fcb741ddb6c9b0b44ff02` / CI #947 -> GREEN `d17bd27be72c8c3bd022fb2c3613050c398c622e` / CI #948;
- candidate `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951 passed automation but was rejected for expanded pointer-exit and interactive lost-terminal behavior.

#### 2026-08-13 expanded pointer-exit / interactive settlement repair

Target testing showed that PR #33 had regressed accepted M1 semantics: after DOWN expansion, moving the pointer out of expanded no longer collapsed the panel. Physical UP could also leave a clipped intermediate panel when shrinking geometry moved out from under the pointer before the local hosting view received `.ended`/`.cancelled`.

The repair is intentionally local and event-driven:

- restored expanded retention policy: outside expanded retention -> non-haptic compact;
- `.pointerExitCollapse` is the sole intent allowed to retarget an owned interactive transition;
- local precise-scroll handling passes current `NSEvent.mouseLocation` through the interactive update;
- after synchronous frame updates, actual `panel.frame` is checked and pointer/panel separation settles to exact compact;
- existing mouse-move observation provides the same fail-safe for real pointer motion while interaction is owned;
- no global scroll monitor, event tap, watchdog timer, polling loop, display link or new permission authority was introduced.

TDD evidence:

- RED `0a42a701fcf4fa2f59972a68d2a3b9243203a202` / CI #959: exactly five new regression tests failed while the previous suite passed;
- GREEN `64d3e6c2beadacaeda69c8ac06f173ac26aace3e`;
- the hover/haptic symptom remains a physical retest condition and is not falsely attributed to this repair.

#### 2026-08-15 regression foundation integration

Regression/UI Automation Foundation PR #34 was merged to `main` as `bd9566f690d314ed40fd6f3723a319291ceb4a58`; post-merge main CI #1053 passed all three canonical jobs.

Because frozen PR #33 then diverged from its updated base, temporary draft PR #35 was used only as a fail-closed integration workspace. It is not intended for merge.

Integration work:

- expanded strict acceptance traceability to **116 discovered / 116 mapped / 0 unmapped** using a current evidence overlay and explicit approved supersessions;
- preserved historical accepted M1 evidence while intentionally superseded hover behavior is represented as replacement by Hover Peek rather than restored incorrectly;
- kept new M6.6 gates pending/rejected until physical acceptance;
- restored stable `notch.surface.compact`, `notch.surface.peek`, `notch.surface.expanded` accessibility identities and source/media identifiers;
- aligned native XCUI journeys with current product contract: hover does not open full Home; explicit click opens expanded; pointer-exit/control/retained-context journeys use the exact app;
- integrated compile-time-only deterministic media/haptic fixtures with shipping-marker isolation checks;
- adapted deterministic runtime to M6.6 session identity and seek;
- retained concrete `ShippingMediaRuntime` creation solely in shipping `AppComposition` while `MediaGestureSession` now consumes the `MediaRuntimeSession` protocol for expanded previous/next/seek testability;
- updated stale historical regression evidence without changing accepted semantics;
- created `performance/m6-6-regression-foundation-integration-size-budget.json` from exact CI #1089 / run `31869841148`, source `452f78b0e42c5302702393e9c45c563849661ca4`, artifact `9243156724`, with tight 4 KiB-rounded allowance over immutable `v0.1.0`.

TDD/verification evidence:

- first full combined baseline `e5cdc58776f80f1fc6f57e22959a07704d895fbe` / CI #1095: all three canonical jobs SUCCESS;
- protocol-runtime RED `3b79448697d614b7f022009653eca655a31bad4f` / CI #1096;
- protocol-runtime GREEN `f49f94d5ab51dcec5dccb97b6c0997ec631b1261` / CI #1099: all three canonical jobs SUCCESS;
- verified descendant was non-force fast-forwarded into real PR #33;
- PR #33 CI #1100 / run `31870867724` on exact `f49f94d5ab51dcec5dccb97b6c0997ec631b1261`: all three jobs SUCCESS, **347 tests / 72 suites PASS**, strict **116/116 PASS**, native external-app XCUI **9/9 PASS**, production transport/archive, release/security/Sandbox/Hardened Runtime/signing/preflight, combined size and performance-smoke gates PASS.

This documentation synchronization creates a new source SHA. That exact docs-synchronized head must pass fresh CI before it becomes the frozen physical candidate.

PR #33 remains draft and unmerged until one exact candidate passes all applicable target-Mac gates.

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
- Regression/UI Automation Foundation merged via PR #34 and is now a mandatory three-job CI product gate.
- App Sandbox-only + Hardened Runtime remain mandatory; no telemetry/direct app network/sensitive input permission surface has been added.

## [0.1.0] - 2026-08-07

### Added

- Initial native macOS NotchHub application foundation.
- Hardware-notch geometry and compact/expanded states.
- App Sandbox + Hardened Runtime and strict CI/security/release packaging.
- Personal Release DMG with checksum/provenance metadata.

### Acceptance

`NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, `NH-HOVER-003` and Personal Release acceptance passed on the target Mac. `v0.1.0` is immutable and intentionally ad-hoc signed/not notarized.
