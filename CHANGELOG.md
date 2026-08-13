# Changelog

All notable changes to NotchHub are documented here. The active version is stored in `VERSION`; published tags/releases are immutable.

## [Unreleased]

Published release remains `v0.1.0`. Everything below is source work not yet published as a new version.

### M6.6 — current draft PR #33

Status: **IMPLEMENTED / AUTOMATED REPAIR GREEN / PHYSICAL RETEST PENDING / NOT MERGED / NOT RELEASED**.

Added:

- local App-owned media gesture session with bounded horizontal visuals and public AppKit arm haptic;
- stable `compact`, `peek`, `expanded` presentation states under the existing Core transition authority;
- 120 ms media-only Hover Peek plus 140 ms pointer-exit grace;
- click and physical DOWN as explicit expansion paths;
- bounded one-shot media probing/commands in compact and Peek while persistent runtime remains expanded-only;
- source-app identity badge through public `NSWorkspace` and bounded in-memory cache;
- capability-gated draggable seek in Peek and expanded, identity-locked across track/source changes;
- balanced seek cursor ownership without pointer warp/lock;
- cumulative provenance-backed feature-size budgets over immutable P0.

Physical acceptance history:

- first complete candidate `d008f698b323963f084eedce601620ee957ef442` / CI #872 rejected; focused RED -> GREEN cycles repaired hover arbitration, physical vertical direction, stale seek identity and visual continuity;
- repair size-policy GREEN `6403dae0e33281f6dcd5bcbd79ec5147b6580c0a` / CI #883;
- Hover Peek evidence `7daffde9b7c2a734e2ddfa234b1ee744b0d96d9e` / CI #939, size RED `4bc15c4757727922817b4aaac35c7991c852019a` / CI #940 and size GREEN `745baa55b7a53519b3832f21305fa9c357ce05fa` / CI #944;
- docs-synchronized candidate `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945 rejected on stationary-startup Hover Peek;
- startup RED `553cf973722dfb214f0fcb741ddb6c9b0b44ff02` / CI #947 and GREEN `d17bd27be72c8c3bd022fb2c3613050c398c622e` / CI #948 fixed initial stationary pointer activation without adding periodic work;
- exact candidate `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951 passed automation but was rejected again on target hardware for expanded pointer-exit and interactive lost-terminal behavior.

#### 2026-08-13 expanded pointer-exit / interactive settlement repair

Target testing showed that PR #33 had regressed previously accepted M1 semantics: after DOWN expansion, simply moving the pointer out of expanded no longer collapsed the panel. A physical UP gesture could also leave a clipped intermediate panel when shrinking geometry moved out from under the pointer before the local hosting view received `.ended`/`.cancelled`.

The repair is intentionally local and event-driven:

- restored expanded retention policy: outside expanded retention -> non-haptic compact;
- `.pointerExitCollapse` is the sole intent allowed to retarget an owned interactive transition;
- local precise-scroll handling passes current `NSEvent.mouseLocation` through the interactive update;
- after each synchronous frame update, actual `panel.frame` is checked; if it no longer contains the pointer, transition retargets to exact compact;
- existing mouse-move observation provides the same fail-safe for real pointer motion while interaction is owned;
- no global scroll monitor, event tap, watchdog timer, polling loop, display link or new permission authority was introduced.

TDD evidence:

- clean RED `0a42a701fcf4fa2f59972a68d2a3b9243203a202` / CI #959: 333 tests / 69 suites with exactly five new pointer-exit/lost-terminal regression tests failing and the previous suite passing;
- production GREEN `64d3e6c2beadacaeda69c8ac06f173ac26aace3e`;
- format-only `de5624b7d344e15772fdf0759fbe4b5027a5b1d4` / CI #961: both required jobs PASS; 333 tests / 69 suites PASS; strict format/security/performance/media, Sandbox/Hardened Runtime/signing, shipping preflight, active size budget and performance smoke PASS.

The same physical run also reported missing hover/haptic/Peek from the observed broken state. That symptom remains a focused retest condition rather than being falsely attributed to this repair. If it reproduces from clean stable compact on the next exact candidate, it gets a separate RED -> GREEN cycle.

PR #33 remains draft and unmerged until one exact docs-synchronized candidate passes all applicable target-Mac gates.

### Earlier M6.6 prerequisites

- Task 0 collapse-layout retarget hardening physically accepted and merged via PR #22.
- Task 1 one-shot lifecycle ownership automated-accepted and merged via PR #24.
- Deterministic gesture engine, local gesture seam and bounded compact commands merged via PRs #26-#28.
- Interactive transition authority and vertical visual tracking merged via PRs #31-#32; current `main` pre-PR#33 head is `172805f8cd63dab664d0dbc6747576fb51b13e7a`, CI #836 PASS.

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
