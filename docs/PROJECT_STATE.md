# Project state

Last updated: 2026-08-07
Current development version: `0.1.0` (unreleased)
Active PR: #1 `Bootstrap native macOS foundation`
Active branch: `agent/bootstrap-macos-foundation`

## Product

NotchHub is a personal native macOS productivity hub built around the MacBook notch. Planned first modules are Shelf, Snippets, Calendar, Translator, and media controls with Yandex Music as the primary player.

## Current milestone

M0 — Engineering foundation.

Status: in progress. Automated foundation is working; real-hardware hover acceptance must be rerun after the first reported regression was fixed.

## Implemented

- Swift 6 / Swift Package Manager project layout
- macOS 14 minimum deployment target
- SwiftUI + AppKit application shell
- accessory/background-style app without a Dock icon
- borderless non-activating `NSPanel`
- hardware-notch geometry derived from public `NSScreen` APIs
- fallback geometry for non-notch displays
- compact/expanded panel state
- screen-space pointer activation/retention policy with hysteresis between compact and expanded regions
- unit tests for geometry, panel state, and pointer retention
- CI for validation, build, tests, `.app`, `.dmg`, signature/integrity verification, and artifact upload
- tag-driven GitHub Release workflow
- ad-hoc application signing for personal testing
- Semantic Versioning policy with repository-root `VERSION`
- `CHANGELOG.md`, development/testing policy, architecture, roadmap, and project-state documentation

## First real-hardware acceptance — 2026-08-07

The first CI-produced DMG launched on the target MacBook, but hover behavior exposed a blocking M0 regression.

- `NH-BOOT-001`: PASS enough to reach and operate the running panel.
- `NH-HOVER-001`: FAIL on bootstrap build — repeated compact/expanded oscillation while hovering.
- Root cause confirmed in code: SwiftUI `onHover` directly controlled presentation while the resulting presentation change resized/animated the same `NSPanel`, creating a feedback path through transient hover exits.
- TDD RED commit: `eb4fb4d` (`test: reproduce hover retention regression`). CI failed exactly on `expandedPointerInsideExpandedRetentionRegionStaysExpanded` with `.compact` instead of `.expanded`.
- GREEN fix commit: `eff9bde` (`fix: stabilize notch hover retention`). CI passed build, all 8 tests, release DMG packaging, bundle verification, and artifact upload.
- Fixed-DMG physical retest: PENDING. Do not mark M0 accepted or PR #1 ready solely from CI.

See `docs/TESTING.md` for stable acceptance scenario IDs and the test/manual boundary.

## Known limitations

- panel is initially attached to `NSScreen.main`; active-display migration is not implemented yet;
- final expansion/collapse timing and animation feel have not been tuned on real hardware;
- UI is a structural preview rather than final product design;
- no feature modules are wired yet;
- release artifacts are ad-hoc signed, not Developer ID signed/notarized;
- Yandex Music integration is planned but not implemented in M0;
- Spaces/fullscreen and multi-display behavior are not yet accepted.

## Quality policy

- TDD is the default for behavior changes and regressions: RED must be observed before GREEN.
- Deterministic production decisions belong in pure/testable code; AppKit/SwiftUI wiring stays thin.
- CI may not be weakened to hide a product defect.
- Manual testing is reserved for unavoidable physical/OS/third-party behavior and is tracked by stable scenario IDs.
- Notable changes update `CHANGELOG.md`.
- Architectural/product/test decisions update the relevant docs in the same PR.

## Next optimal step

1. Produce the latest CI DMG from PR #1 after the quality/versioning commit.
2. Rerun `NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, and `NH-HOVER-003` on the target MacBook.
3. If all required M0 checks pass, mark PR #1 ready and merge by squash.
4. Create the first release/tag `v0.1.0` only after M0 real-hardware acceptance is recorded as PASS.
5. Start M1 with display-change handling, active-screen migration, fullscreen/Spaces behavior, and animation tuning.
