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

- [ ] **Step 1: Write the project-structure RED policy**

Create `scripts/test_ui_project_policy.py`:

```python
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "NotchHubUITests.xcodeproj/project.pbxproj"
SCHEME = ROOT / "NotchHubUITests.xcodeproj/xcshareddata/xcschemes/NotchHubUITests.xcscheme"

class UIProjectPolicyTests(unittest.TestCase):
    def test_project_and_shared_scheme_exist(self):
        self.assertTrue(PROJECT.is_file())
        self.assertTrue(SCHEME.is_file())

    def test_project_contains_only_test_host_and_ui_test_targets(self):
        text = PROJECT.read_text(encoding="utf-8")
        self.assertIn("NotchHubUITestHost", text)
        self.assertIn("NotchHubUITests", text)
        self.assertNotIn("Sources/NotchHubApp", text)
        self.assertNotIn("Sources/NotchHubCore", text)
        self.assertNotIn("Sources/NotchHubMediaCore", text)

if __name__ == "__main__":
    unittest.main()
```

Run:

```bash
python3 scripts/test_ui_project_policy.py -v
```

Expected: RED because the project does not exist.

- [ ] **Step 2: Create the minimal Xcode project**

Create a macOS app target `NotchHubUITestHost` containing only:

```swift
import SwiftUI

@main
struct UITestHostApp: App {
    var body: some Scene {
        WindowGroup { EmptyView() }
    }
}
```

Create a macOS UI Testing Bundle `NotchHubUITests` targeting the host, Swift 6, macOS deployment target 14.0. The shared scheme builds the host and test bundle. Do not add any production source file membership.

Verify:

```bash
python3 scripts/test_ui_project_policy.py -v
xcodebuild -list -project NotchHubUITests.xcodeproj
```

Expected: PASS; output lists both targets and scheme `NotchHubUITests`.

- [ ] **Step 3: Add the exact-app build wrapper**

Create `scripts/build-ui-test-app.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_COMMIT="${SOURCE_COMMIT:-$(git -C "$ROOT_DIR" rev-parse HEAD)}"
OUTPUT_DIR="$ROOT_DIR/build/ui-test"
APP="$OUTPUT_DIR/NotchHub.app"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
SOURCE_COMMIT="$SOURCE_COMMIT" NOTCHHUB_UI_TESTING=1 \
  bash "$ROOT_DIR/scripts/build-app.sh" debug
mv "$ROOT_DIR/build/NotchHub.app" "$APP"
test "$(plutil -extract NHSourceCommit raw "$APP/Contents/Info.plist")" = "$SOURCE_COMMIT"
echo "$APP"
```

At Task 1 the unknown environment variable is intentionally ignored by the unchanged shipping build script; compile-time fixture behavior is added and tested separately in Task 2.

- [ ] **Step 4: Add exact-URL application helper**

Create `Tests/UITests/Support/NotchHubUIApplication.swift`:

```swift
import Foundation
import XCTest

@MainActor
struct NotchHubUIApplication {
    enum Mode { case shippingSmoke, deterministicMedia }
    let app: XCUIApplication

    init(mode: Mode) throws {
        guard let rawPath = ProcessInfo.processInfo.environment["NOTCHHUB_UI_APP_PATH"] else {
            throw XCTSkip("NOTCHHUB_UI_APP_PATH is required")
        }
        app = XCUIApplication(url: URL(fileURLWithPath: rawPath, isDirectory: true))
        app.launchEnvironment["NOTCHHUB_UI_FIXTURE"] =
            mode == .deterministicMedia ? "media-standard" : "shipping-smoke"
    }

    func launch() { app.launch() }
}
```

- [ ] **Step 5: Add and run external-app smoke test**

```swift
import XCTest

final class NotchHubUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testLaunchesExactExternalApplicationBuild() throws {
        let subject = try NotchHubUIApplication(mode: .shippingSmoke)
        subject.launch()
        XCTAssertNotEqual(subject.app.state, .notRunning)
        subject.app.terminate()
        XCTAssertEqual(subject.app.state, .notRunning)
    }
}
```

Run:

```bash
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-ui-test-app.sh
NOTCHHUB_UI_APP_PATH="$PWD/build/ui-test/NotchHub.app" \
  xcodebuild test -project NotchHubUITests.xcodeproj -scheme NotchHubUITests \
  -destination 'platform=macOS' \
  -resultBundlePath build/NotchHubUITests-smoke.xcresult
```

Expected: PASS. If the external URL launch itself fails, fix only Xcode/UI-test plumbing; do not add production behavior changes.

- [ ] **Step 6: Commit**

```bash
git add NotchHubUITests.xcodeproj Tests/UITestHost Tests/UITests \
  scripts/build-ui-test-app.sh scripts/test_ui_project_policy.py
git commit -m "Test: add native macOS UI automation harness"
```

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

Require `scripts/build-app.sh` to contain both `NOTCHHUB_UI_TESTING` and `-DNOTCHHUB_UI_TESTING`; require current shipping workflows not to set `NOTCHHUB_UI_TESTING=1`.

```python
class UIAutomationPolicyTests(unittest.TestCase):
    def test_build_script_has_explicit_test_compilation_condition(self):
        self.assertIn("NOTCHHUB_UI_TESTING", BUILD_APP)
        self.assertIn("-DNOTCHHUB_UI_TESTING", BUILD_APP)

    def test_shipping_workflows_never_enable_fixture_build(self):
        self.assertNotIn("NOTCHHUB_UI_TESTING=1", CI)
        self.assertNotIn("NOTCHHUB_UI_TESTING=1", PERSONAL_RELEASE)
        self.assertNotIn("NOTCHHUB_UI_TESTING=1", TRUSTED_RELEASE)
```

Run and preserve RED.

- [ ] **Step 2: Add the compiler condition to the existing SwiftPM call**

```bash
swift_args=(build -c "$CONFIGURATION" --product NotchHub -Xlinker -dead_strip)
if [[ "${NOTCHHUB_UI_TESTING:-0}" == "1" ]]; then
  swift_args+=( -Xswiftc -DNOTCHHUB_UI_TESTING )
fi
swift "${swift_args[@]}"
```

Do not change media bootstrap, provenance, signing, entitlements, or stripping.

- [ ] **Step 3: Add artifact leak verifier**

The CLI must inspect the shipping executable bytes and reject:

```python
FORBIDDEN_MARKERS = (
    b"NOTCHHUB_UI_FIXTURE",
    b"media-standard",
    b"media-unsupported",
    b"ui-test.hapticCount",
)
```

Normal release build must pass the verifier.

- [ ] **Step 4: Run RED -> GREEN proof**

```bash
python3 scripts/test_ui_automation_policy.py -v
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-ui-test-app.sh
unset NOTCHHUB_UI_TESTING
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-app.sh release
python3 scripts/test_ui_automation_policy.py --verify-shipping-app build/NotchHub.app
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/build-app.sh scripts/test_ui_automation_policy.py
git commit -m "Test: isolate UI fixtures from shipping builds"
```

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

Require every `Sources/NotchHubApp/UITestSupport/*.swift` file to be guarded by `#if NOTCHHUB_UI_TESTING`, and require shipping composition to be the only unguarded composition path.

- [ ] **Step 2: Add `MediaRuntimeSession` and shipping conformance**

```swift
import NotchHubMediaCore

@MainActor
protocol MediaRuntimeSession: AnyObject {
    func start(); func stop(); func togglePlayPause(); func goPrevious(); func goNext()
}

extension ShippingMediaRuntime: MediaRuntimeSession {}
```

- [ ] **Step 3: Add `AppComposition.shipping()` and adapt `AppDelegate`**

Change runtime storage to `(any MediaRuntimeSession)?`, construct it through the composition factory, and preserve current expanded-only start/stop behavior byte-for-byte in semantics.

- [ ] **Step 4: Add guarded deterministic fixture configuration**

```swift
#if NOTCHHUB_UI_TESTING
import Foundation

struct UITestConfiguration: Equatable {
    enum Fixture: String {
        case shippingSmoke = "shipping-smoke"
        case mediaStandard = "media-standard"
        case mediaUnsupported = "media-unsupported"
    }
    let fixture: Fixture

    static func current(environment: [String: String] = ProcessInfo.processInfo.environment) -> Self {
        let raw = environment["NOTCHHUB_UI_FIXTURE"] ?? Fixture.shippingSmoke.rawValue
        return Self(fixture: Fixture(rawValue: raw) ?? .shippingSmoke)
    }
}
#endif
```

Implement `UITestMediaRuntime` under the same compiler guard using synchronous in-memory fixture transitions only.

- [ ] **Step 5: Select UI composition in one compiler-guarded block**

```swift
#if NOTCHHUB_UI_TESTING
let composition = AppComposition.uiTesting(configuration: .current())
#else
let composition = AppComposition.shipping()
#endif
```

- [ ] **Step 6: Verify full Swift tests and release leak policy**

```bash
swift test --parallel
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-ui-test-app.sh
unset NOTCHHUB_UI_TESTING
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-app.sh release
python3 scripts/test_ui_automation_policy.py --verify-shipping-app build/NotchHub.app
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Sources/NotchHubApp Tests/NotchHubCoreTests
git commit -m "Test: add deterministic UI media composition seam"
```

---

### Task 4: Freeze the accessibility and UI diagnostic contract

**Files:**
- Modify: `Sources/NotchHubApp/MediaNotchRootView.swift`
- Modify: `Sources/NotchHubCore/UI/NotchRootView.swift`
- Create: `Sources/NotchHubApp/UITestSupport/UITestHapticRecorder.swift`
- Create: `Tests/UITests/Support/NotchHubUIAssertions.swift`
- Modify: `Tests/UITests/NotchHubUITests.swift`

**Stable identifiers:**

```text
notch.surface.compact
notch.surface.expanded
notch.surface.peek       # reserved for later M6.6 rebase
media.artwork
media.title
media.artist
media.playPause
media.previous
media.next
media.progress
media.seek               # reserved for later M6.6 rebase
media.sourceIcon         # reserved for later M6.6 rebase
ui-test.hapticCount      # test build only
```

- [ ] **Step 1: Write RED UI assertion for `notch.surface.compact`**

Launch deterministic media mode and require the compact identifier to exist while expanded does not.

- [ ] **Step 2: Add identifiers to real production views without visual changes**

Identifiers derive from stable state/control meaning, never localized text or child index.

- [ ] **Step 3: Add predicate-based assertion helper**

```swift
@MainActor
func XCTAssertSurface(_ identifier: String, in app: XCUIApplication,
                      timeout: TimeInterval = 2,
                      file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(app.otherElements[identifier].waitForExistence(timeout: timeout),
                  "missing \(identifier)", file: file, line: line)
}
```

- [ ] **Step 4: Add test-only haptic recorder type**

Under `#if NOTCHHUB_UI_TESTING`, provide an integer semantic request counter. Do not route stable `main` behavior through it yet unless Plan 2 needs the seam for accepted M1 haptic wiring; the shipping artifact must still contain no marker.

- [ ] **Step 5: Verify UI, Swift, and shipping leak tests**

Run the UI smoke, `swift test --parallel`, and shipping leak verifier. Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources Tests/UITests
git commit -m "Test: expose stable accessibility regression contract"
```

---

### Task 5: Add deterministic XCUI input helpers and always-on failure diagnostics

**Files:**
- Modify: `Tests/UITests/Support/NotchHubUIApplication.swift`
- Create: `Tests/UITests/Support/NotchHubUIDiagnostics.swift`
- Modify: `scripts/test_ui_automation_policy.py`

**Interfaces:**

```swift
func surface(_ identifier: String) -> XCUIElement
func hoverSurface(_ identifier: String)
func movePointerOutside(_ element: XCUIElement)
func scroll(on identifier: String, deltaX: CGFloat, deltaY: CGFloat)
func attachFailureDiagnostics(named: String)
```

- [ ] **Step 1: Write RED source policy rejecting sleeps under `Tests/UITests/`**

Reject `Thread.sleep`, `Task.sleep`, `usleep(`, and bare `sleep(`.

- [ ] **Step 2: Implement input helpers using XCUIAutomation**

Use the element center for hover/scroll. Pointer exit is deterministic and app-local:

```swift
let outside = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 2.0))
XCTAssertFalse(element.frame.contains(outside.screenPoint))
outside.hover()
```

No Finder/System Settings dependency is introduced.

- [ ] **Step 3: Attach screenshot and accessibility hierarchy on failures**

Use `XCUIScreen.main.screenshot()` plus `app.debugDescription`, both with `.keepAlways` lifetime.

- [ ] **Step 4: Run policies and UI smoke**

```bash
python3 scripts/test_ui_automation_policy.py -v
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-ui-test-app.sh
NOTCHHUB_UI_APP_PATH="$PWD/build/ui-test/NotchHub.app" \
  xcodebuild test -project NotchHubUITests.xcodeproj -scheme NotchHubUITests \
  -destination 'platform=macOS' -resultBundlePath build/NotchHubUITests-input.xcresult
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Tests/UITests scripts/test_ui_automation_policy.py
git commit -m "Test: add deterministic macOS UI interaction helpers"
```

---

### Task 6: Add acceptance traceability validator in audit and strict modes

**Files:**
- Create: `Tests/Acceptance/coverage.yml`
- Create: `scripts/test_acceptance_coverage.py`

**Manifest schema:**

```yaml
version: 1
cases:
  - id: NH-EXAMPLE-001
    source: docs/testing/EXAMPLE.md
    status: accepted
    coverage:
      - layer: unit
        test: NotchHubCoreTests.ExampleTests.example
    physicalOnlyReason: null
```

Allowed statuses: `accepted`, `pending`, `rejected`. Allowed layers: `unit`, `integration`, `ui`, `policy`, `shipping`, `physical`.

The parser supports only this deliberately small indentation/list/scalar subset of YAML; no anchors, aliases, folded strings, implicit booleans, or arbitrary YAML tags are accepted. This keeps the validator dependency-free and fail-closed.

- [ ] **Step 1: Write validator RED unit tests using temporary fixtures**

Required tests:

```text
missing acceptance ID fails
unknown manifest ID fails
duplicate manifest ID fails
accepted deterministic case without automation fails in strict mode
physical-only entry requires a non-generic reason
missing referenced test symbol/command fails
pending/rejected case may have partial coverage
audit mode reports deterministic debt but exits zero
```

- [ ] **Step 2: Implement stable ID discovery**

Scan every `docs/testing/*.md` with:

```python
ACCEPTANCE_ID = re.compile(r"\bNH-[A-Z0-9]+(?:-[A-Z0-9]+)*-\d{3}\b")
```

Fail on duplicate declarations from different ledgers.

- [ ] **Step 3: Implement the constrained manifest parser and reference validation**

Test references must resolve to a real source file/symbol or an exact repository command. Do not accept free-form prose as automated evidence.

- [ ] **Step 4: Seed honest current statuses and run audit**

Do not fake legacy completeness. Run:

```bash
python3 scripts/test_acceptance_coverage.py --mode audit
```

Expected: schema/reference validation PASS and a deterministic accepted-coverage debt report that Plan 2 will close.

- [ ] **Step 5: Commit**

```bash
git add Tests/Acceptance scripts/test_acceptance_coverage.py
git commit -m "Test: add acceptance coverage traceability validator"
```

---

### Task 7: Add the required `macOS UI regression` GitHub Actions job

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `scripts/test_ui_automation_policy.py`

**Required job:** `macOS UI regression`, `runs-on: macos-26`, timeout <= 25 minutes, no automatic retries.

- [ ] **Step 1: Write RED workflow policy**

Require the workflow to contain the job name, `scripts/build-ui-test-app.sh`, `xcodebuild test`, `build/NotchHub-UI-Test.xcresult`, immutable-SHA checkout/upload-artifact actions, and `persist-credentials: false`.

- [ ] **Step 2: Add the CI job**

Order:

```text
checkout
report sw_vers/xcodebuild/swift
run UI project/policy unit tests
build exact UI-test app with PR head SHA
run xcodebuild UI tests
verify NHSourceCommit equals head SHA
upload xcresult with if: always()
```

- [ ] **Step 3: Add shipping fixture-leak verification to `Build, test and package`**

After the normal release app exists, run:

```bash
python3 scripts/test_ui_automation_policy.py --verify-shipping-app build/NotchHub.app
```

- [ ] **Step 4: Run all local policy/UI checks and commit**

```bash
python3 scripts/test_ui_project_policy.py -v
python3 scripts/test_ui_automation_policy.py -v
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-ui-test-app.sh
NOTCHHUB_UI_APP_PATH="$PWD/build/ui-test/NotchHub.app" \
  xcodebuild test -project NotchHubUITests.xcodeproj -scheme NotchHubUITests \
  -destination 'platform=macOS' -resultBundlePath build/NotchHub-UI-Test.xcresult
```

Expected: PASS.

```bash
git add .github/workflows/ci.yml scripts
git commit -m "CI: require native macOS UI regression testing"
```

---

### Task 8: Document foundation status and hand off exclusively to legacy backfill

**Files:**
- Modify: `docs/TESTING.md`
- Modify: `docs/DEVELOPMENT.md`
- Modify: `docs/PROJECT_STATE.md`
- Modify: `docs/ROADMAP.md`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Document the five evidence layers**

```text
Swift Testing -> integration -> XCUIAutomation -> shipping/policy -> physical target-Mac
```

- [ ] **Step 2: Freeze the development rule**

```text
acceptance ID -> RED at highest reliable layer -> minimum GREEN -> full regression CI -> physical gate where needed -> merge
```

- [ ] **Step 3: Record exact status without overclaiming**

```text
UI automation foundation: implemented + automated-tested once CI is green.
Legacy M1/M6.1-M6.5 coverage: backfill pending.
PR #33: draft / physical FAIL / not merged.
Next work: 2026-08-14-legacy-regression-baseline-backfill.md only.
```

- [ ] **Step 4: Run full foundation verification**

```bash
swift test --parallel
python3 scripts/test_ui_project_policy.py -v
python3 scripts/test_ui_automation_policy.py -v
python3 scripts/test_acceptance_coverage.py --mode audit
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-ui-test-app.sh
NOTCHHUB_UI_APP_PATH="$PWD/build/ui-test/NotchHub.app" \
  xcodebuild test -project NotchHubUITests.xcodeproj -scheme NotchHubUITests \
  -destination 'platform=macOS' -resultBundlePath build/NotchHub-UI-Test.xcresult
unset NOTCHHUB_UI_TESTING
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-app.sh release
python3 scripts/test_ui_automation_policy.py --verify-shipping-app build/NotchHub.app
```

Expected: all commands PASS; audit may report honest legacy debt and exits zero.

- [ ] **Step 5: Commit docs and keep the foundation PR open**

```bash
git add docs CHANGELOG.md
git commit -m "Docs: establish mandatory UI regression foundation"
```

Do not merge until Plan 2 switches acceptance validation to strict and all accepted deterministic baseline cases are green.

---

## Plan completion gate

Plan 1 is complete only when a real SwiftPM-built NotchHub app is driven through XCUIAutomation on macOS, the new CI job is green with `.xcresult` diagnostics, deterministic fixture mode works without external players/network, shipping artifacts prove fixture markers absent, acceptance validation works in audit/strict modes, and no product behavior was changed. The only allowed next work is `2026-08-14-legacy-regression-baseline-backfill.md`.
