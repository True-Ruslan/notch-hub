# Regression and UI Automation Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans task-by-task. Completion claims require fresh exact-head verification evidence.

**Status:** **TASKS 1-8 COMPLETE AND AUTOMATED-TESTED / TASK 9 FINAL EXACT-HEAD CI PENDING**

**Goal:** Add a native macOS XCTest/XCUIAutomation regression layer, deterministic UI-test composition, acceptance traceability, and a required CI gate without changing accepted product behavior or shipping trust boundaries.

**Architecture:** SwiftPM remains the only production build system. A checked-in Xcode project contains a minimal non-production macOS host plus the `NotchHubUITests` bundle. Tests launch the exact SwiftPM-built `NotchHub.app` with `XCUIApplication(url:)`. Deterministic fixture code substitutes only external media/haptic boundaries and is compiled solely when `NOTCHHUB_UI_TESTING` is set; normal Personal/Release builds are verified to contain none of its markers.

**Tech Stack:** Swift 6, SwiftPM, Swift Testing, XCTest, XCUIAutomation, AppKit, SwiftUI accessibility, Python 3 policy tests, Bash, GitHub Actions `macos-26`, `xcodebuild`, `.xcresult`.

## Global constraints

- Primary target: macOS 26.6 / Mac16,8; package deployment floor remains macOS 14.
- Work remains on the separate foundation branch from stable `main`; PR #33 remains draft and untouched.
- No M6.6 repair, hover/gesture tuning, new media semantics or other product feature belongs in this plan.
- No third-party UI automation framework while XCUIAutomation is sufficient.
- No global `.scrollWheel` capture, `CGEventTap`, Accessibility/Input Monitoring/Automation/Screen Recording authority, synthetic media keys, polling, repeating watchdog timers or display links.
- Shipping app remains App Sandbox-only + Hardened Runtime with the fixed reviewed media transport boundary.
- Fixture code is compile-time excluded from shipping builds and may replace only nondeterministic external boundaries.
- UI synchronization uses XCTest predicates/state waits, never arbitrary sleeps or automatic retries.
- Screenshots and `.xcresult` are diagnostics, not pixel snapshot correctness gates.
- New production seams are allowed only when they expose a true external boundary and preserve shipping behavior exactly.

## Delivered file structure

```text
NotchHubUITests.xcodeproj/
  project.pbxproj
  xcshareddata/xcschemes/NotchHubUITests.xcscheme
Tests/
  UITestHost/UITestHostApp.swift
  UITests/
    NotchHubUITests.swift
    Support/
      NotchHubUIApplication.swift
      NotchHubUIAssertions.swift
      NotchHubUIDiagnostics.swift
  Acceptance/coverage.yml
Sources/NotchHubApp/
  AppComposition.swift
  MediaRuntimeSession.swift
  UITestSupport/
    UITestConfiguration.swift
    UITestMediaRuntime.swift
    UITestHapticRecorder.swift
scripts/
  build-ui-test-app.sh
  test_ui_project_policy.py
  test_ui_automation_policy.py
  test_acceptance_coverage.py
.github/workflows/ci.yml
```

The Xcode host contains no NotchHub production source and is never a shipping artifact. UI tests launch `build/ui-test/NotchHub.app` by exact URL.

---

### Task 1: Native Xcode UI-test harness and external-app launch proof

Status: **COMPLETE / AUTOMATED-TESTED**

- [x] Write project-structure RED policy.
- [x] Create minimal Xcode host + UI-test project and shared scheme.
- [x] Add exact-app build wrapper.
- [x] Add exact-URL `XCUIApplication` helper.
- [x] Add external-app shipping smoke.
- [x] Verify project policy, `xcodebuild -list`, exact app build and external-app XCUI on macOS 26 CI.

Evidence: the harness was exercised repeatedly on `macos-26`; exact pre-documentation implementation candidate `7654775b3ae0416d115f8f2ca7118e947cf97e13` passed the canonical UI job in run `31811958254`.

---

### Task 2: Compile-time fixture isolation and shipping leak enforcement

Status: **COMPLETE / AUTOMATED-TESTED**

- [x] Write RED policy tests.
- [x] Add `NOTCHHUB_UI_TESTING` compiler condition to the existing SwiftPM shipping build wrapper.
- [x] Add shipping artifact leak verifier.
- [x] Prove RED -> GREEN and shipping marker absence.
- [x] Commit isolated changes.

The shipping build path uses the compiler condition only when `NOTCHHUB_UI_TESTING=1`; ordinary Personal/Release builds compile without fixture code.

---

### Task 3: Deterministic media composition seam

Status: **COMPLETE / AUTOMATED-TESTED**

- [x] Add RED source-policy assertions.
- [x] Introduce `MediaRuntimeSession` boundary with shipping conformance.
- [x] Add `AppComposition.shipping()` and preserve AppDelegate lifecycle ownership.
- [x] Add guarded deterministic fixture configuration.
- [x] Select UI composition in one compile-time guarded block.
- [x] Verify full Swift tests and release leak policy.
- [x] Commit.

Fixture behavior is deterministic A/B/C media state with no timer, subprocess, network, file I/O or polling. Shipping composition still binds to `ShippingMediaRuntime`.

---

### Task 4: Accessibility and UI diagnostic contract

Status: **COMPLETE / AUTOMATED-TESTED**

- [x] Add stable notch/media accessibility identifiers.
- [x] Add guarded haptic diagnostic counter only where no visible equivalent exists.
- [x] Compile-time isolate haptic injection so production retains direct `AppKitNotchHapticPerformer` ownership.
- [x] Add predicate-based assertion helpers and screenshot/hierarchy diagnostics.
- [x] Prove fixture/haptic diagnostics are absent from shipping artifact.
- [x] Preserve the existing shipping size envelope where possible and create a separate provenanced cumulative foundation envelope only for the residual deterministic artifact delta.
- [x] Commit.

The final foundation budget does not rewrite immutable P0 or historical M6 budgets.

---

### Task 5: Acceptance coverage manifest and audit validator

Status: **COMPLETE FOR FOUNDATION / LEGACY BACKFILL DEFERRED TO PLAN 2**

- [x] Discover stable `NH-*` IDs from `docs/testing/*.md`.
- [x] Parse manifest entries and validate ID uniqueness/source/status/layers/test references.
- [x] Implement `--mode audit` and `--mode strict`.
- [x] Keep foundation CI in audit mode until legacy backfill is complete.
- [x] Seed one verified real test mapping rather than fabricating legacy coverage.
- [x] Commit.

Current audit state: 70 stable IDs discovered, 1 verified manifest mapping, 69 explicit legacy gaps. Strict mode is intentionally fail-closed until Plan 2.

---

### Task 6: First real shipping and deterministic UI journeys

Status: **COMPLETE / AUTOMATED-TESTED**

- [x] Shipping mode: launch/terminate/stable compact smoke.
- [x] Deterministic mode: launch exact fixture app and expose exact surface/media state.
- [x] Exercise real `XCUIElement.hover()` through the 120 ms product hover path.
- [x] Exercise real Next / Previous / Play-Pause UI clicks and wait for accessibility state changes.
- [x] Use only real XCUI input APIs rather than direct state-machine injection.
- [x] Use predicate waits; no fixed sleeps.
- [x] Commit.

---

### Task 7: UI failure diagnostics and no-flake policy

Status: **COMPLETE / AUTOMATED-TESTED**

- [x] Attach screenshot on failure.
- [x] Preserve accessibility hierarchy and `.xcresult`.
- [x] Pass and verify exact source SHA through `NHSourceCommit` / `NOTCHHUB_UI_SOURCE_COMMIT`.
- [x] Store exact SHA as diagnostic attachment.
- [x] Reject arbitrary sleeps and automatic retries by policy.
- [x] Fix fail-closed helper initialization without weakening exact-SHA validation.
- [x] Commit.

---

### Task 8: Mandatory UI regression and acceptance audit in canonical CI

Status: **COMPLETE / AUTOMATED-TESTED**

- [x] Required job name is exactly `macOS UI regression`.
- [x] Run on `macos-26`.
- [x] Run UI project/policy tests, acceptance audit, exact fixture build, shipping leak verification, XCUI suite and `.xcresult` upload.
- [x] Pass exact PR-head SHA to UI build/provenance validation.
- [x] Keep acceptance manifest in audit mode until Plan 2 closes legacy debt.
- [x] Preserve existing `macOS 26 compatibility` and `Build, test and package` jobs.
- [x] Move UI regression into canonical `.github/workflows/ci.yml` and remove the temporary branch-only workflow.
- [x] Full three-job canonical CI PASS on exact implementation candidate `7654775b3ae0416d115f8f2ca7118e947cf97e13`, run `31811958254`.

---

### Task 9: Foundation documentation and review gate

Status: **FINAL EXACT-HEAD CI PENDING**

- [x] Document testing pyramid and mandatory UI regression in `docs/TESTING.md` / `docs/DEVELOPMENT.md`.
- [x] Document fixture/shipping separation and physical-only boundaries.
- [x] Synchronize `docs/PROJECT_STATE.md`, `docs/ROADMAP.md` and `CHANGELOG.md` with actual GitHub/PR state.
- [x] Record that feature work remains frozen until Plan 2 strict legacy backfill passes.
- [x] Review the PR production-source diff for accidental product-behavior/trust-boundary changes.
- [ ] Run fresh exact-head canonical policy + Swift + UI CI after the final documentation commit.
- [ ] Record the final exact SHA/run and mark Plan 1 complete.

#### Task 9 production-diff review — 2026-08-14

Review scope included all production-source files changed by PR #34 plus shipping build/security scripts.

Findings:

- `AppComposition.shipping()` constructs the existing `ShippingMediaRuntime`; AppDelegate retains start/stop lifecycle authority.
- Deterministic runtime selection exists only inside `#if NOTCHHUB_UI_TESTING`.
- `NotchPanelController` shipping branch retains the direct `AppKitNotchHapticPerformer`; injectable haptic ownership is compiled only for UI testing.
- `ShippingMediaPresentationModel.applyUITestPresentation` exists only under the testing compiler condition.
- SwiftUI production changes add stable accessibility identifiers/containment only; notch geometry, transition authority, media command callbacks and presentation semantics are unchanged.
- `scripts/build-app.sh` adds `-DNOTCHHUB_UI_TESTING` only for explicit test builds.
- `scripts/security-audit.sh` is strengthened to verify the new shipping composition seam still binds AppDelegate lifecycle to `ShippingMediaRuntime` and still rejects development-only media tooling.
- No new entitlement, permission, network path, global scroll capture, event tap, polling/repeating timer/display link or arbitrary executable surface was introduced.

Review verdict: **no accidental product-feature or shipping trust-boundary change identified; final exact-head CI remains the last Plan 1 gate.**

---

## Plan 1 exit and hand-off to Plan 2

Plan 1 is complete only when the final documentation head passes all three canonical jobs. It is **not** itself permission to resume M6.6.

After Plan 1 completion, execute `docs/superpowers/plans/2026-08-14-legacy-regression-baseline-backfill.md` on the isolated foundation branch. PR #34 remains draft until every stable accepted ID is represented, every deterministic accepted behavior has executable evidence, physical-only reasons are narrowly justified, and `scripts/test_acceptance_coverage.py --mode strict` passes in canonical CI.

Only after PR #34 is accepted/merged and post-merge `main` CI passes may PR #33 be rebased/resumed for a fresh exact M6.6 candidate and target-Mac physical acceptance.
