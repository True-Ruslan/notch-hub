# Regression and UI Automation Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a native macOS XCTest/XCUIAutomation regression layer, deterministic UI-test composition, acceptance traceability, and a required CI gate without changing accepted product behavior or shipping trust boundaries.

**Architecture:** SwiftPM remains the only production build system. A small checked-in Xcode project contains a minimal non-production macOS host used only to satisfy Xcode UI-test target plumbing plus the `NotchHubUITests` bundle; the tests themselves launch the exact SwiftPM-built `NotchHub.app` with `XCUIApplication(url:)`. Deterministic fixture code substitutes only external media/haptic boundaries and is compiled solely when `NOTCHHUB_UI_TESTING` is set; normal Personal/Release builds are verified to contain none of its markers.

**Tech Stack:** Swift 6, Swift Package Manager, Swift Testing, XCTest, XCUIAutomation, AppKit, SwiftUI accessibility, Python 3 policy tests, Bash, GitHub Actions `macos-26`, `xcodebuild`, `.xcresult`.

## Global Constraints

- Primary target: macOS 26.6 / Mac16,8; package deployment floor remains macOS 14.
- Work occurs on the separate foundation branch from stable `main`; PR #33 remains draft and untouched.
- No M6.6 repair, hover/gesture tuning, new media semantics, or other product features.
- No third-party UI automation framework while XCUIAutomation is sufficient.
- No global `.scrollWheel` capture, `CGEventTap`, Accessibility/Input Monitoring/Automation/Screen Recording authority, synthetic media keys, polling, repeating watchdog timers, or display links.
- Shipping app remains App Sandbox-only + Hardened Runtime with the fixed reviewed media transport boundary.
- Fixture code is compile-time excluded from shipping builds and may replace only nondeterministic external boundaries.
- UI synchronization uses XCTest predicates/state waits, never arbitrary sleeps or automatic retries.
- Screenshots and `.xcresult` are diagnostics, not pixel snapshot correctness gates.
- New production seams are allowed only when they expose a true external boundary and preserve shipping behavior exactly.

---

## Planned file structure

```text
NotchHubUITests.xcodeproj/
  project.pbxproj
  xcshareddata/xcschemes/NotchHubUITests.xcscheme
Tests/
  UITestHost/
    UITestHostApp.swift
  UITests/
    NotchHubUITests.swift
    Support/
      NotchHubUIApplication.swift
      NotchHubUIAssertions.swift
      NotchHubUIDiagnostics.swift
  Acceptance/
    coverage.yml
Sources/
  NotchHubApp/
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

### Task 1: Establish the native Xcode UI-test harness and external-app launch proof

Status: IN PROGRESS — implementation prepared; awaiting macOS 26 CI execution.

**Files:**
- Create: `scripts/test_ui_project_policy.py`
- Create: `NotchHubUITests.xcodeproj/project.pbxproj`
- Create: `NotchHubUITests.xcodeproj/xcshareddata/xcschemes/NotchHubUITests.xcscheme`
- Create: `Tests/UITestHost/UITestHostApp.swift`
- Create: `Tests/UITests/NotchHubUITests.swift`
- Create: `Tests/UITests/Support/NotchHubUIApplication.swift`
- Create: `scripts/build-ui-test-app.sh`

**Interfaces:**
- Xcode targets: `NotchHubUITestHost` and `NotchHubUITests`.
- Shared scheme: `NotchHubUITests`.
- App under test: exact URL from `NOTCHHUB_UI_APP_PATH`.
- Existing shipping bundle ID remains `ru.trueruslan.notchhub`.

- [x] **Step 1: Write the project-structure RED policy**
- [x] **Step 2: Create the minimal Xcode project**
- [x] **Step 3: Add the exact-app build wrapper**
- [x] **Step 4: Add exact-URL application helper**
- [x] **Step 5: Add external-app smoke test**
- [ ] **Step 6: Verify on macOS 26 CI and close Task 1**

Task 1 is considered complete only after `python3 scripts/test_ui_project_policy.py -v`, `xcodebuild -list`, exact app build, and the external-app XCUI smoke all PASS on the PR `macos-26` runner.

---

### Task 2: Add compile-time fixture isolation and shipping leak enforcement

**Files:**
- Create: `scripts/test_ui_automation_policy.py`
- Modify: `scripts/build-app.sh`

**Interfaces:**
- Input env: `NOTCHHUB_UI_TESTING=1`.
- Compiler condition: `NOTCHHUB_UI_TESTING`.
- CLI: `python3 scripts/test_ui_automation_policy.py --verify-shipping-app build/NotchHub.app`.

- [ ] **Step 1: Write RED policy tests**
- [ ] **Step 2: Add the compiler condition to the existing SwiftPM call**
- [ ] **Step 3: Add artifact leak verifier**
- [ ] **Step 4: Run RED -> GREEN proof**
- [ ] **Step 5: Commit**

---

### Task 3: Introduce the deterministic media composition seam

**Files:**
- Create: `Sources/NotchHubApp/MediaRuntimeSession.swift`
- Create: `Sources/NotchHubApp/AppComposition.swift`
- Create: `Sources/NotchHubApp/UITestSupport/UITestConfiguration.swift`
- Create: `Sources/NotchHubApp/UITestSupport/UITestMediaRuntime.swift`
- Modify: `Sources/NotchHubApp/AppDelegate.swift`
- Modify/Test: `Tests/NotchHubCoreTests/MediaAppCompositionPolicyTests.swift`

**Interfaces:**

```swift
@MainActor
protocol MediaRuntimeSession: AnyObject {
    func start()
    func stop()
    func togglePlayPause()
    func goPrevious()
    func goNext()
}

@MainActor
struct AppComposition {
    let makeMediaRuntime: (ShippingMediaPresentationModel) -> any MediaRuntimeSession
    static func shipping() -> Self
#if NOTCHHUB_UI_TESTING
    static func uiTesting(configuration: UITestConfiguration) -> Self
#endif
}
```

Fixture contract: A/B/C tracks, previous/next supported, duration 240 s, initial position 42 s, source `NotchHub UI Fixture`; no timers, subprocesses, network, file I/O, or polling.

- [ ] **Step 1: Add RED source-policy assertions to `MediaAppCompositionPolicyTests.swift`**
- [ ] **Step 2: Add `MediaRuntimeSession` and shipping conformance**
- [ ] **Step 3: Add `AppComposition.shipping()` and adapt `AppDelegate`**
- [ ] **Step 4: Add guarded deterministic fixture configuration**
- [ ] **Step 5: Select UI composition in one compiler-guarded block**
- [ ] **Step 6: Verify full Swift tests and release leak policy**
- [ ] **Step 7: Commit**

---

### Task 4: Freeze the accessibility and UI diagnostic contract

**Files:**
- Modify: `Sources/NotchHubApp/MediaNotchRootView.swift`
- Modify: `Sources/NotchHubCore/UI/NotchRootView.swift`
- Create: `Sources/NotchHubApp/UITestSupport/UITestHapticRecorder.swift`
- Create: `Tests/UITests/Support/NotchHubUIAssertions.swift`
- Create: `Tests/UITests/Support/NotchHubUIDiagnostics.swift`

- [ ] Add stable surface/media accessibility identifiers.
- [ ] Add guarded haptic diagnostic counter only where no visible equivalent exists.
- [ ] Add predicate-based assertion helpers and screenshot/XCResult diagnostics.
- [ ] Prove fixture diagnostics are absent from shipping artifact.
- [ ] Commit.

---

### Task 5: Add acceptance coverage manifest and audit validator

**Files:**
- Create: `Tests/Acceptance/coverage.yml`
- Create: `scripts/test_acceptance_coverage.py`

- [ ] Discover stable `NH-*` IDs from `docs/testing/*.md`.
- [ ] Parse manifest entries and validate ID uniqueness/source/status/layers/test references.
- [ ] Implement `--mode audit` and `--mode strict`.
- [ ] Keep foundation phase in audit mode until legacy backfill is complete.
- [ ] Commit.

---

### Task 6: Add first real shipping and deterministic UI journeys

**Files:**
- Modify: `Tests/UITests/NotchHubUITests.swift`
- Modify: `Tests/UITests/Support/NotchHubUIApplication.swift`
- Modify: fixture/app accessibility files from Tasks 3–4.

- [ ] Shipping mode: launch/terminate/stable compact smoke.
- [ ] Deterministic mode: launch with fixture, expose exact surface/media state.
- [ ] Use real XCUI hover/click/scroll APIs only; no direct state-machine injection from UI tests.
- [ ] No fixed sleeps.
- [ ] Commit.

---

### Task 7: Harden UI failure diagnostics and no-flake policy

**Files:**
- Modify: UI test support files.
- Create/modify policy test rejecting `sleep`, retries, and production-source membership in UI project.

- [ ] Attach screenshot on failure.
- [ ] Preserve `.xcresult`.
- [ ] Assert exact source SHA visible in diagnostic metadata/environment.
- [ ] Reject arbitrary sleeps/automatic retries.
- [ ] Commit.

---

### Task 8: Make UI regression and acceptance audit mandatory in CI

**Files:**
- Modify: `.github/workflows/ci.yml` or use the isolated `UI Regression` workflow introduced during execution.

- [ ] Required check name is exactly `macOS UI regression`.
- [ ] Run on `macos-26`.
- [ ] Run project/policy tests, build exact fixture app, execute XCUI suite, upload `.xcresult`/screenshots.
- [ ] Run acceptance manifest in audit mode until Plan 2 closes legacy debt.
- [ ] Existing required checks remain untouched.
- [ ] Full CI PASS.

---

### Task 9: Foundation documentation and review gate

**Files:**
- Modify: `docs/TESTING.md`
- Modify: `docs/DEVELOPMENT.md`
- Modify: `docs/PROJECT_STATE.md`
- Modify: `docs/ROADMAP.md`
- Modify: `CHANGELOG.md`

- [ ] Document testing pyramid and mandatory UI regression.
- [ ] Document fixture/shipping separation and physical-only boundaries.
- [ ] Record that feature work remains frozen until Plan 2 strict legacy backfill passes.
- [ ] Run all policy + Swift + UI CI.
- [ ] Review diff for product-behavior changes: expected none.
- [ ] Commit.
