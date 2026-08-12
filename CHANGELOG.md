# Changelog

All notable changes to NotchHub are documented here. The active version is stored in `VERSION`; published tags/releases are immutable.

## [Unreleased]

Published release remains `v0.1.0`. Everything below is source work not yet published as a new version.

### M6.6 — current draft PR #33

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICAL ACCEPTANCE PENDING / NOT MERGED / NOT RELEASED**.

Added:

- local App-owned media gesture session with bounded horizontal follow-finger visuals and public AppKit arm haptic;
- stable `compact`, `peek`, `expanded` presentation states under the existing Core transition authority;
- 120 ms hover dwell to media-only Peek plus 140 ms pointer-exit grace;
- click and physical DOWN as explicit expansion paths;
- bounded one-shot media probing/commands in compact and Peek while persistent runtime remains expanded-only;
- source-app identity badge resolved with public `NSWorkspace` and bounded in-memory cache;
- capability-gated draggable seek in Peek and expanded through typed media boundaries;
- cursor ownership limited to a valid seek interaction, with balanced restore and no pointer warp/lock;
- dedicated cumulative feature-size budgets for App gesture, source icon, seek, physical-acceptance repair and Hover Peek, all over immutable P0.

Physical acceptance repair after rejected candidate `d008f698b323963f084eedce601620ee957ef442`:

- fixed compact hover arbitration: retained media wings no longer broaden hover activation; precise trackpad gesture preflight cancels pending 120 ms hover dwell;
- fixed physical vertical direction while preserving RIGHT -> previous and LEFT -> next;
- seek captures authoritative media generation + source bundle identity and cannot apply a stale drag to a different track/source;
- seek ownership suppresses track/panel scroll gestures and cancels on presentation identity/capability loss;
- horizontal gesture release gets bounded ease-out visual reset;
- media/Home/session identity changes get bounded event-driven opacity continuity without polling/timer/display-link.

Hover Peek follow-up:

- hover now previews the retained/fresh media session in Peek rather than opening full expanded UI;
- no-media hover remains compact;
- fast pointer transit cannot leave Peek stuck;
- 140 ms exit/re-entry grace keeps Peek stable without persistent observation;
- Peek supports bounded previous/next gesture capability work and draggable seek without forcing expansion;
- compact and settled Peek own zero persistent adapter; expanded remains the only persistent observation state;
- seek cursor ownership is released on commit, cancellation, identity change, app resign, invalidation and Quit;
- media/track transitions preserve the active media branch without intentional Home blinking;
- all hot paths remain local/bounded/event-driven and add no broad scroll monitor or sensitive permission surface.

TDD / policy evidence:

- axis/hover RED `0fd1f8de00ceb1d470c8e83d910356853dd72844`, CI #873;
- axis fix `1f4bc0491b3f8a00d8d48b3763ec308f7b39a91b`, CI #874; hover remained independently RED;
- hover GREEN `1d4937b0467e290eb83033e4762a0bc406d00345`, CI #875;
- seek identity RED `3590640bfa73dfa3b672178111fe3d28e64e6705`, CI #876;
- seek identity GREEN `4c716880dc1e94ce7e1e168d3205d20bc2bfa7e4`, CI #877; only the previous size envelope failed;
- continuity RED `812230ba8c73dd8b85e61ed0030be747ba5cef12`, CI #878;
- final functional repair source `d8fb784eb9eb47c7af34dbd689b6fcfa5aadef12`, CI #881: 277 Swift tests PASS and only old size envelope RED; measured `523,200 / 825,406 / 527,113 B` executable/app/DMG;
- repair size-policy RED `38f73eaa3d13f25743ddaf831a5c66c3aba9fb78`, CI #882: 278 tests / 60 suites, exactly missing repair budget failed;
- repair size-policy GREEN `6403dae0e33281f6dcd5bcbd79ec5147b6580c0a`, CI #883: both required jobs PASS;
- Hover Peek evidence head `7daffde9b7c2a734e2ddfa234b1ee744b0d96d9e`, CI #939: 326 Swift tests and all functional/security/signing/preflight checks PASS; prior repair size envelope only RED; measured `562,368 / 864,574 / 555,272 B` executable/app/DMG;
- Hover Peek size-policy RED `4bc15c4757727922817b4aaac35c7991c852019a`, CI #940: 327 tests / 68 suites with exactly the missing Hover Peek budget failing;
- provenance-backed `performance/m6-6-hover-peek-size-budget.json` added from CI #939 evidence; old repair budget moved to historical-only status without modification;
- Hover Peek size-policy GREEN `745baa55b7a53519b3832f21305fa9c357ce05fa`, CI #944: both required jobs PASS, including 327 Swift tests, security/signing/preflight, active size enforcement and performance smoke.

The rejected first physical result remains authoritative: M6.6 is not accepted until the new docs-synchronized Hover Peek candidate passes all applicable target-Mac gates. PR #33 stays draft.

### Earlier M6.6 prerequisites

- Task 0 collapse-layout retarget hardening physically accepted and merged via PR #22 (`f017addd2efc9aed5b60b1556205bdb8eab23e0e`).
- Task 1 one-shot lifecycle ownership automated-accepted and merged via PR #24 (`957e2f085ebf1fae1b3f741a7f79dd6a45b599b6`).
- Deterministic gesture engine, local gesture seam and bounded compact commands merged via PRs #26-#28.
- Interactive transition authority and vertical visual tracking merged via PRs #31-#32; current `main` pre-PR#33 head is `172805f8cd63dab664d0dbc6747576fb51b13e7a`, CI #836 PASS.

### M6.1-M6.5

- M6.1 system Now Playing feasibility accepted on target hardware.
- M6.2 normalized media controller/bridge boundary accepted and merged.
- M6.3 fixed pinned production media transport accepted and merged.
- M6.4 shipping composition/lazy expanded-only runtime accepted and merged; compact zero-adapter lifecycle established.
- M6.5 Media-first compact/expanded UI accepted and merged; all `NH-MEDIA-UI-001...011` target gates passed.

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
