# Changelog

All notable changes to NotchHub are documented here. The active version is stored in `VERSION`; published tags/releases are immutable.

## [Unreleased]

Published release remains `v0.1.0`. Everything below is source work not yet published as a new version.

### M6.6 — current draft PR #33

Status: **IMPLEMENTED / REGRESSION-INTEGRATED / DIRECTION REPAIR AUTOMATED-GREEN BEFORE FINAL DOCS SYNC / PHYSICAL RETEST PENDING / NOT MERGED / NOT RELEASED**.

Added:

- local App-owned media gesture session with bounded horizontal visuals and public AppKit arm haptic;
- stable `compact`, `peek`, `expanded` presentation states under the existing Core transition authority;
- exactly 120 ms Hover Peek activation plus 140 ms pointer-exit grace;
- generic no-media Peek with one hover-haptic request after a valid dwell;
- click and physical DOWN as explicit expansion paths, with explicit tap authority on the stable outer media-aware root above generic/media and compact/Peek replacement;
- bounded one-shot media probing/commands in compact and Peek while persistent runtime remains expanded-only;
- exact-top-edge inclusive pointer retention for interactive DOWN;
- physical horizontal gesture normalization independent of macOS scroll-direction preference: LEFT -> `next`, RIGHT -> `previous`;
- source-app identity badge through public `NSWorkspace` and bounded in-memory cache;
- capability-gated draggable seek in Peek and expanded, identity-locked across track/source changes;
- balanced seek cursor ownership without pointer warp/lock;
- strict native regression/UI automation integrated with M6.6;
- cumulative provenance-backed size budget over immutable P0.

Physical acceptance history:

- first complete candidate `d008f698b323963f084eedce601620ee957ef442` / CI #872 rejected; focused RED -> GREEN cycles repaired hover arbitration, physical vertical direction, stale seek identity and visual continuity;
- docs-synchronized candidate `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945 rejected on stationary-startup Hover Peek; startup RED #947 -> GREEN #948;
- candidate `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951 passed automation but was rejected for expanded pointer-exit and interactive lost-terminal behavior;
- candidate `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101 was rejected on 2026-08-15 for no-media Hover Peek/haptic behavior and exact-top-edge DOWN self-collapse, while expanded pointer-exit and normal-center DOWN/UP remained stable;
- candidate `6c2109195042759b951217f489a201a82dd044cd` / CI #1156 passed all automation but was physically rejected on 2026-08-15 because a real media playback test showed LEFT/RIGHT track gestures reversed relative to the frozen contract.

#### 2026-08-13 expanded pointer-exit / interactive settlement repair

Target testing showed that PR #33 had regressed accepted M1 semantics: after DOWN expansion, moving the pointer out of expanded no longer collapsed the panel. Physical UP could also leave a clipped intermediate panel when shrinking geometry moved out from under the pointer before the local hosting view received `.ended`/`.cancelled`.

The repair restored expanded retention collapse, limited interactive retarget to the pointer-exit fail-safe, passed current mouse location through local precise-scroll updates, and synchronously settled from actual panel geometry when pointer/panel separation could lose terminal local scroll delivery. No global scroll monitor, event tap, watchdog timer, polling loop, display link or new permission authority was introduced.

TDD evidence: RED `0a42a701fcf4fa2f59972a68d2a3b9243203a202` / CI #959 -> GREEN `64d3e6c2beadacaeda69c8ac06f173ac26aace3e`.

#### 2026-08-15 regression foundation integration

Regression/UI Automation Foundation PR #34 was merged to `main` as `bd9566f690d314ed40fd6f3723a319291ceb4a58`; post-merge main CI #1053 passed all three canonical jobs.

Integration work added fail-closed acceptance traceability, exact-app native XCUI, compile-time-only deterministic media/haptic fixtures with shipping-marker isolation, stable accessibility identities, and protocol-based expanded runtime injection while concrete `ShippingMediaRuntime` construction remained shipping-composition authority.

First full combined baseline `e5cdc58776f80f1fc6f57e22959a07704d895fbe` / CI #1095 passed all canonical jobs. Protocol-runtime RED #1096 -> GREEN #1099. PR #33 CI #1100 then independently passed all three jobs with 347 tests / 72 suites, strict 116/116 and native external-app XCUI 9/9.

#### 2026-08-15 Hover Peek / physical-acceptance repair

Target testing of candidate `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101 produced concrete blockers and later automated click races:

- no-media hover remained compact and produced no haptic because the pending design still gated Peek on usable media;
- DOWN starting exactly at the top screen edge used half-open `CGRect.contains` and falsely retargeted to compact;
- external XCUI showed that tap authority below a presentation/root replacement can lose a click while hover/media state changes during synthesis.

Repair:

- no-media hover opens generic Peek first and requests the normal hover haptic once;
- interactive pointer retention includes the exact physical top/right boundary;
- local `NSTrackingArea` is the primary event-driven hover path;
- a proposed mouse-button interception was rejected by the existing security baseline and removed rather than whitelisted;
- explicit click expansion uses one stable SwiftUI tap recognizer on the outer `MediaNotchRootView`, above generic/media and compact/Peek replacement;
- no global scroll/button/keyboard monitor, event tap, polling, repeating timer, display link, UI-test retry/sleep or new sensitive permission was added.

Verification evidence:

- behavior head `63b0f2f96f879123f3883db7311c90a20d3a4328` / CI #1140: 352 Swift tests / 74 suites and external XCUI 11/11 PASS; package failed only because the preceding DMG cumulative ceiling was exceeded by 2172 B;
- size review created `performance/m6-6-physical-acceptance-20260815-repair-size-budget.json`, changing only DMG allowance by one 4096-byte quantum while leaving app/executable allowance unchanged;
- pre-docs head `3e617698a503590dbc18958960a5335753734ccc` / CI #1147: all three canonical jobs PASS;
- docs head `a91e196d0ed51fb73a49b680eac1321100cdadb5` / CI #1152 was automatically rejected because two first-launch explicit-click external XCUI journeys failed;
- focused RED `ac1f004b9a0d2a0fd54c16cb7c0041933d3523df` / CI #1153 -> GREEN `16feb0433f7fdfb18d5eacfcce66707959e6211a` / CI #1155; #1155 passed all canonical jobs, strict/security gates and native external-app XCUI without retries/sleeps.

#### 2026-08-15 horizontal physical-direction repair

Target-Mac video testing of exact automated-green candidate `6c2109195042759b951217f489a201a82dd044cd` / CI #1156 / run `31892019346` used real media playback and showed horizontal track gestures reversed: the physical gesture selected the opposite track from the frozen LEFT -> `next`, RIGHT -> `previous` contract.

Root cause was limited to `MediaGestureInputNormalizer`. The semantic coordinator and typed command mapping were already correct; vertical normalization was also correct. Horizontal normalization compensated for the user's macOS scroll-direction preference but failed to invert AppKit scroll X into the physical LEFT/RIGHT semantic sign.

TDD evidence:

- RED `f5cb5e3d1f13c7dc5564ce24068e83007f97bb1b` / CI #1157 / run `31897906228`: build/policy gates passed; 354 tests / 75 suites ran and only the two new physical-direction assertions failed. LEFT was positive instead of negative X and RIGHT negative instead of positive X; Y remained correct.
- GREEN `50b82dae49f3ce6c6e194b1ab9775bd5cd5dd430` / CI #1158 / run `31898052051`: exactly one production line changed from `x: scrollingDeltaX * preferenceScale` to `x: -scrollingDeltaX * preferenceScale`; Y, semantic direction mapping, thresholds, haptics, lifecycle and transport are unchanged.
- #1158 passed all 354 Swift tests and all three canonical jobs, including strict acceptance traceability, exact external-app XCUI, security/source audit, production transport/archive, Sandbox/Hardened Runtime/signing/preflight, unchanged size gate and performance smoke.

A fresh docs-synchronized descendant must independently pass all three canonical jobs before its exact source/artifact provenance is frozen for the next target-Mac retest. The #1156 artifacts remain historical rejection evidence only.

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
