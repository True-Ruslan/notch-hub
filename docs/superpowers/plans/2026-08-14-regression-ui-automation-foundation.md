# Regression and UI Automation Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a native macOS XCTest/XCUIAutomation regression layer, deterministic UI-test composition, acceptance traceability, and a required CI gate without changing accepted product behavior or shipping trust boundaries.

**Architecture:** Keep SwiftPM as the production build system and Swift Testing as the fast logic/integration layer. Add a small checked-in Xcode project containing only a UI-testing bundle and the minimum test host Xcode requires; UI tests launch the exact SwiftPM-built `NotchHub.app` via `XCUIApplication(url:)`. Test-only external-boundary fixtures are compiled into a separate UI-test app build under `NOTCHHUB_UI_TESTING`; normal Personal/Release builds compile no fixture code and are verified not to contain fixture markers.

**Tech Stack:** Swift 6, Swift Package Manager, Swift Testing, XCTest, XCUIAutomation, AppKit, SwiftUI accessibility identifiers, Python 3 policy tests, Bash build scripts, GitHub Actions `macos-26`, `xcodebuild`, `.xcresult` artifacts.

## Global Constraints

- Primary target: macOS 26.6 / Mac16,8; package deployment floor remains macOS 14.
- Foundation branch starts from stable `main`; PR #33 remains draft and is not modified during this plan.
- No product-feature behavior changes in this plan: no hover/gesture threshold tuning, no M6.6 repair, no new media semantics.
- No third-party UI automation framework while XCUIAutomation is sufficient.
- No global scroll capture, `CGEventTap`, Accessibility/Input Monitoring/Automation/Screen Recording authority, synthetic media keys, polling loops, repeating watchdog timers, or display links.
- Shipping app remains App Sandbox-only + Hardened Runtime with the fixed reviewed media transport boundary.
- UI-test fixture code is compile-time excluded from shipping builds and may substitute only nondeterministic external boundaries.
- UI tests use predicate/state waits, not arbitrary `sleep` calls or automatic retries.
- Screenshots and `.xcresult` are diagnostics, not pixel-perfect correctness gates.
- Every task follows RED -> minimum GREEN -> focused tests -> full relevant regression -> commit.

---

## Planned file structure

```text
NotchHubUITests.xcodeproj/
  project.pbxproj
  xcshareddata/xcschemes/NotchHubUITests.xcscheme
Tests/
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
  test-ui-automation-policy.py
  test_acceptance_coverage.py
.github/workflows/ci.yml
Resources/Info.plist
Package.swift
```

`NotchHubUITests.xcodeproj` does not compile a second copy of production NotchHub sources. The real application under test comes from `scripts/build-ui-test-app.sh` and is launched by exact URL.

---

### Task 1: Prove a real external NotchHub app can be launched by XCUIAutomation

**Files:**
- Create: `NotchHubUITests.xcodeproj/project.pbxproj`
- Create: `NotchHubUITests.xcodeproj/xcshareddata/xcschemes/NotchHubUITests.xcscheme`
- Create: `Tests/UITests/NotchHubUITests.swift`
- Create: `Tests/UITests/Support/NotchHubUIApplication.swift`
- Create: `scripts/build-ui-test-app.sh`
- Test: `Tests/UITests/NotchHubUITests.swift`

**Interfaces:**
- Consumes: existing `scripts/build-app.sh`, bundle identifier `ru.trueruslan.notchhub`, `NHSourceCommit` in `Info.plist`.
- Produces: `NotchHubUIApplication.launch(mode:)`, deterministic app-path/provenance smoke test, Xcode scheme `NotchHubUITests`.

- [ ] **Step 1: Add a UI-test app build wrapper with exact provenance**

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

SOURCE_COMMIT="$SOURCE_COMMIT" \
NOTCHHUB_UI_TESTING=1 \
  bash "$ROOT_DIR/scripts/build-app.sh" debug

mv "$ROOT_DIR/build/NotchHub.app" "$APP"
test "$(plutil -extract NHSourceCommit raw "$APP/Contents/Info.plist")" = "$SOURCE_COMMIT"

echo "$APP"
```

At this step the script is expected to fail because `build-app.sh` does not yet understand `NOTCHHUB_UI_TESTING`; that behavior is implemented in Task 2.

- [ ] **Step 2: Add the minimal Xcode UI testing project**

Configure a macOS UI Testing Bundle target named `NotchHubUITests` using XCTest, deployment target 14.0, Swift 6, and a shared scheme named `NotchHubUITests`. The project may include the smallest empty macOS test-host target required by Xcode, but production NotchHub source files must not be members of that host target.

Required project invariants to verify after creation:

```bash
xcodebuild -list -project NotchHubUITests.xcodeproj
```

Expected output contains:

```text
Targets:
    NotchHubUITests
Schemes:
    NotchHubUITests
```

If Xcode requires a host target, it may additionally list `NotchHubUITestHost`; no NotchHub production source path may appear in `project.pbxproj`.

- [ ] **Step 3: Add a launch helper that targets an exact app URL**

Create `Tests/UITests/Support/NotchHubUIApplication.swift`:

```swift
import Foundation
import XCTest

@MainActor
struct NotchHubUIApplication {
    enum Mode {
        case shippingSmoke
        case deterministicMedia
    }

    let app: XCUIApplication

    init(mode: Mode) throws {
        let environment = ProcessInfo.processInfo.environment
        guard let rawPath = environment["NOTCHHUB_UI_APP_PATH"] else {
            throw XCTSkip("NOTCHHUB_UI_APP_PATH is required")
        }

        let url = URL(fileURLWithPath: rawPath, isDirectory: true)
        app = XCUIApplication(url: url)
        app.launchEnvironment["NOTCHHUB_UI_FIXTURE"] =
            mode == .deterministicMedia ? "media-standard" : "shipping-smoke"
    }

    func launch() {
        app.launch()
    }
}
```

The `NOTCHHUB_UI_FIXTURE` launch variable is harmless in the shipping build because Task 2 ensures no production code reads or embeds it unless `NOTCHHUB_UI_TESTING` was compiled.

- [ ] **Step 4: Write the first UI smoke test**

Create `Tests/UITests/NotchHubUITests.swift`:

```swift
import XCTest

final class NotchHubUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

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

- [ ] **Step 5: Run the smoke test and preserve the first failure**

Run:

```bash
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-ui-test-app.sh
NOTCHHUB_UI_APP_PATH="$PWD/build/ui-test/NotchHub.app" \
  xcodebuild test \
  -project NotchHubUITests.xcodeproj \
  -scheme NotchHubUITests \
  -destination 'platform=macOS' \
  -resultBundlePath build/NotchHubUITests-smoke.xcresult
```

Expected at this point: RED from the not-yet-supported `NOTCHHUB_UI_TESTING` build path or Xcode target configuration. Do not weaken the test to obtain green.

- [ ] **Step 6: Commit the isolated UI-test project proof**

```bash
git add NotchHubUITests.xcodeproj Tests/UITests scripts/build-ui-test-app.sh
git commit -m "Test: add native macOS UI automation harness"
```

---

### Task 2: Add compile-time-isolated UI-test build support and shipping leak policy

**Files:**
- Modify: `scripts/build-app.sh`
- Create: `scripts/test-ui-automation-policy.py`
- Modify: `.github/workflows/ci.yml`
- Test: `scripts/test-ui-automation-policy.py`

**Interfaces:**
- Consumes: `NOTCHHUB_UI_TESTING=1` from `build-ui-test-app.sh`.
- Produces: compiler condition `NOTCHHUB_UI_TESTING`; policy function `assert_shipping_binary_has_no_ui_test_markers(app_path)`.

- [ ] **Step 1: Write RED policy tests before changing the build script**

Create `scripts/test-ui-automation-policy.py` with tests that require:

```python
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILD_APP = (ROOT / "scripts/build-app.sh").read_text(encoding="utf-8")
CI = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")


def test_build_script_supports_explicit_ui_test_compilation_condition():
    assert "NOTCHHUB_UI_TESTING" in BUILD_APP
    assert "-DNOTCHHUB_UI_TESTING" in BUILD_APP


def test_normal_ci_shipping_build_never_enables_ui_test_condition():
    shipping_sections = [line for line in CI.splitlines() if "build-dmg.sh" in line]
    assert shipping_sections
    assert "NOTCHHUB_UI_TESTING=1" not in CI
```

Run:

```bash
python3 -m unittest scripts/test-ui-automation-policy.py -v
```

Expected: RED because `build-app.sh` has no compilation-condition support yet.

- [ ] **Step 2: Add the narrow compiler flag in `build-app.sh`**

Replace the direct `swift build` call with:

```bash
swift_args=(
  build
  -c "$CONFIGURATION"
  --product NotchHub
  -Xlinker -dead_strip
)

if [[ "${NOTCHHUB_UI_TESTING:-0}" == "1" ]]; then
  swift_args+=( -Xswiftc -DNOTCHHUB_UI_TESTING )
fi

swift "${swift_args[@]}"
```

Keep every existing media bootstrap/signing/provenance step unchanged.

- [ ] **Step 3: Add artifact-level leak checks**

Extend `scripts/test-ui-automation-policy.py` with a callable CLI mode:

```python
def assert_shipping_binary_has_no_ui_test_markers(app_path: Path) -> None:
    binary = app_path / "Contents/MacOS/NotchHub"
    data = binary.read_bytes()
    forbidden = (
        b"NOTCHHUB_UI_FIXTURE",
        b"media-standard",
        b"ui-test.hapticCount",
    )
    leaked = [marker.decode() for marker in forbidden if marker in data]
    if leaked:
        raise AssertionError(f"shipping binary contains UI-test markers: {leaked}")
```

Add `argparse` support for:

```bash
python3 scripts/test-ui-automation-policy.py --verify-shipping-app build/NotchHub.app
```

- [ ] **Step 4: Make the isolated smoke test GREEN**

Run:

```bash
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-ui-test-app.sh
NOTCHHUB_UI_APP_PATH="$PWD/build/ui-test/NotchHub.app" \
  xcodebuild test \
  -project NotchHubUITests.xcodeproj \
  -scheme NotchHubUITests \
  -destination 'platform=macOS' \
  -resultBundlePath build/NotchHubUITests-smoke.xcresult
```

Expected: PASS for `testLaunchesExactExternalApplicationBuild`.

- [ ] **Step 5: Verify a normal release app contains no fixture markers**

Run:

```bash
unset NOTCHHUB_UI_TESTING
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-app.sh release
python3 scripts/test-ui-automation-policy.py --verify-shipping-app build/NotchHub.app
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add scripts/build-app.sh scripts/test-ui-automation-policy.py
git commit -m "Test: isolate UI fixture compilation from shipping builds"
```

---

### Task 3: Extract a true external media-runtime boundary and deterministic fixture

**Files:**
- Create: `Sources/NotchHubApp/MediaRuntimeSession.swift`
- Create: `Sources/NotchHubApp/AppComposition.swift`
- Create: `Sources/NotchHubApp/UITestSupport/UITestConfiguration.swift`
- Create: `Sources/NotchHubApp/UITestSupport/UITestMediaRuntime.swift`
- Modify: `Sources/NotchHubApp/AppDelegate.swift`
- Test: `Tests/NotchHubCoreTests/AppCompositionPolicyTests.swift` or the existing app source-policy test file used by the repository.

**Interfaces:**
- Produces:

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
    static func shipping() -> AppComposition
#if NOTCHHUB_UI_TESTING
    static func uiTesting(configuration: UITestConfiguration) -> AppComposition
#endif
}
```

- `ShippingMediaRuntime` conforms to `MediaRuntimeSession` without behavior changes.
- Fixture track sequence: A -> B -> C, previous/next supported, fixed 240 s duration, initial position 42 s, source display name `NotchHub UI Fixture`.

- [ ] **Step 1: Add source-policy RED proving test support is compile-time guarded**

Add a test that scans every file under `Sources/NotchHubApp/UITestSupport/` and requires the first non-comment declaration region to be enclosed by:

```swift
#if NOTCHHUB_UI_TESTING
...
#endif
```

The test must also assert `AppComposition.shipping()` is the only composition referenced outside a guarded block in normal `AppDelegate` initialization.

Run the focused source-policy test. Expected: RED because the files/interfaces do not exist.

- [ ] **Step 2: Introduce `MediaRuntimeSession` without changing shipping behavior**

Create `MediaRuntimeSession.swift`:

```swift
import NotchHubMediaCore

@MainActor
protocol MediaRuntimeSession: AnyObject {
    func start()
    func stop()
    func togglePlayPause()
    func goPrevious()
    func goNext()
}

extension ShippingMediaRuntime: MediaRuntimeSession {}
```

- [ ] **Step 3: Add `AppComposition.shipping()`**

Create `AppComposition.swift` with a single shipping factory:

```swift
import NotchHubMediaCore

@MainActor
struct AppComposition {
    let makeMediaRuntime: (ShippingMediaPresentationModel) -> any MediaRuntimeSession

    static func shipping() -> Self {
        Self(makeMediaRuntime: { ShippingMediaRuntime(presentationModel: $0) })
    }
}
```

Change `AppDelegate` runtime storage from `ShippingMediaRuntime?` to `(any MediaRuntimeSession)?` and construct through `AppComposition`. Preserve the existing expanded-only start/stop lifecycle exactly.

- [ ] **Step 4: Add deterministic fixture configuration under the compiler guard**

Create `UITestConfiguration.swift`:

```swift
#if NOTCHHUB_UI_TESTING
import Foundation

struct UITestConfiguration: Equatable {
    enum Fixture: String { case shippingSmoke = "shipping-smoke", mediaStandard = "media-standard" }
    let fixture: Fixture

    static func current(environment: [String: String] = ProcessInfo.processInfo.environment) -> Self {
        let raw = environment["NOTCHHUB_UI_FIXTURE"] ?? Fixture.shippingSmoke.rawValue
        return Self(fixture: Fixture(rawValue: raw) ?? .shippingSmoke)
    }
}
#endif
```

Create `UITestMediaRuntime.swift` under the same guard. It must synchronously seed `ShippingMediaPresentationModel` with fixture A on `start()`, advance A/B/C on `goNext()`, move backward on `goPrevious()`, and toggle playback state on `togglePlayPause()`. Do not use timers, network, subprocesses, or sleeps.

- [ ] **Step 5: Add guarded UI-test composition**

In `AppComposition.swift`:

```swift
#if NOTCHHUB_UI_TESTING
static func uiTesting(configuration: UITestConfiguration) -> Self {
    switch configuration.fixture {
    case .shippingSmoke:
        return shipping()
    case .mediaStandard:
        return Self(makeMediaRuntime: { UITestMediaRuntime(presentationModel: $0) })
    }
}
#endif
```

In `AppDelegate`, select composition using one small guarded block:

```swift
#if NOTCHHUB_UI_TESTING
let composition = AppComposition.uiTesting(configuration: .current())
#else
let composition = AppComposition.shipping()
#endif
```

- [ ] **Step 6: Run Swift tests and shipping leak verification**

```bash
swift test --parallel
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-app.sh release
python3 scripts/test-ui-automation-policy.py --verify-shipping-app build/NotchHub.app
```

Expected: PASS, with no fixture marker in the shipping binary.

- [ ] **Step 7: Commit**

```bash
git add Sources/NotchHubApp Tests scripts/test-ui-automation-policy.py
git commit -m "Test: add deterministic UI media composition seam"
```

---

### Task 4: Add stable accessibility identifiers and test diagnostics

**Files:**
- Modify: `Sources/NotchHubApp/MediaNotchRootView.swift`
- Modify: `Sources/NotchHubCore/Notch/NotchRootView.swift` if the Home surface owns the corresponding root views.
- Create: `Sources/NotchHubApp/UITestSupport/UITestHapticRecorder.swift`
- Create: `Tests/UITests/Support/NotchHubUIAssertions.swift`
- Test: `Tests/UITests/NotchHubUITests.swift`

**Interfaces:**
- Stable identifiers:
  - `notch.surface.compact`
  - `notch.surface.expanded`
  - reserved for PR #33 later: `notch.surface.peek`
  - `media.artwork`
  - `media.title`
  - `media.artist`
  - `media.playPause`
  - `media.previous`
  - `media.next`
  - `media.progress`
  - reserved later: `media.seek`, `media.sourceIcon`
- Test-only diagnostic identifier: `ui-test.hapticCount`.

- [ ] **Step 1: Write a RED UI test for stable compact accessibility**

Add:

```swift
@MainActor
func testDeterministicMediaLaunchExposesCompactSurfaceByStableIdentifier() throws {
    let subject = try NotchHubUIApplication(mode: .deterministicMedia)
    subject.launch()

    let compact = subject.app.otherElements["notch.surface.compact"]
    XCTAssertTrue(compact.waitForExistence(timeout: 2))
    XCTAssertFalse(subject.app.otherElements["notch.surface.expanded"].exists)
}
```

Run the test. Expected: RED because identifiers do not exist.

- [ ] **Step 2: Add identifiers to real production views**

Attach identifiers based on `panelModel.contentPresentation`, not visible text. Add identifiers to controls and media metadata without changing visual layout.

Example for controls:

```swift
Button(action: onPrevious) { ... }
    .accessibilityIdentifier("media.previous")
```

- [ ] **Step 3: Add assertion helpers that wait for state rather than sleep**

Create `NotchHubUIAssertions.swift`:

```swift
import XCTest

@MainActor
func XCTAssertSurface(
    _ identifier: String,
    in app: XCUIApplication,
    timeout: TimeInterval = 2,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let element = app.otherElements[identifier]
    XCTAssertTrue(element.waitForExistence(timeout: timeout), "missing \(identifier)", file: file, line: line)
}
```

- [ ] **Step 4: Add a test-only haptic recorder seam only if end-to-end haptic count cannot be observed otherwise**

Under `#if NOTCHHUB_UI_TESTING`, implement `UITestHapticRecorder` with an integer count and expose it as a hidden-but-accessible diagnostic element/value `ui-test.hapticCount`. Do not replace the production AppKit haptic performer in shipping composition.

At this foundation stage the recorder may remain unused on `main` if M1 haptic wiring cannot be safely adapted without behavior change; the legacy backfill plan activates it only through the test composition.

- [ ] **Step 5: Re-run UI smoke and Swift regression**

```bash
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-ui-test-app.sh
NOTCHHUB_UI_APP_PATH="$PWD/build/ui-test/NotchHub.app" \
  xcodebuild test -project NotchHubUITests.xcodeproj -scheme NotchHubUITests \
  -destination 'platform=macOS' \
  -resultBundlePath build/NotchHubUITests-accessibility.xcresult
swift test --parallel
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources/NotchHubApp Sources/NotchHubCore Tests/UITests
git commit -m "Test: expose stable accessibility regression contract"
```

---

### Task 5: Build reusable XCUI hover, click, pointer-exit, and scroll helpers with diagnostics

**Files:**
- Create: `Tests/UITests/Support/NotchHubUIDiagnostics.swift`
- Modify: `Tests/UITests/Support/NotchHubUIApplication.swift`
- Modify: `Tests/UITests/NotchHubUITests.swift`

**Interfaces:**
- Produces:

```swift
extension NotchHubUIApplication {
    func surface(_ identifier: String) -> XCUIElement
    func hoverSurface(_ identifier: String)
    func movePointerOutsidePanel()
    func scroll(on identifier: String, deltaX: CGFloat, deltaY: CGFloat)
    func attachFailureDiagnostics(named: String)
}
```

- [ ] **Step 1: Write a RED pointer interaction test**

Add a smoke journey that launches deterministic media mode, hovers the compact surface, moves to a coordinate outside the panel, and verifies the app remains responsive. Do not assert M6.6 Peek behavior on `main`.

- [ ] **Step 2: Implement pointer/scroll helpers using XCUIAutomation only**

Use:

```swift
surface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).hover()
surface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    .scroll(byDeltaX: deltaX, deltaY: deltaY)
```

For pointer exit, move to a deterministic coordinate on `XCUIApplication(bundleIdentifier: "com.apple.finder")` only if Finder interaction is stable on the runner; otherwise use the app window coordinate offset outside its frame while staying on-screen. The helper must assert the destination screen point is outside the current panel frame before hovering there.

- [ ] **Step 3: Add failure attachments**

`NotchHubUIDiagnostics.swift` must attach:

```swift
let screenshot = XCUIScreen.main.screenshot()
let attachment = XCTAttachment(screenshot: screenshot)
attachment.lifetime = .keepAlways
add(attachment)
```

Also attach `app.debugDescription` as UTF-8 text on failure.

- [ ] **Step 4: Ensure no arbitrary sleeps exist in UI tests**

Add a source-policy assertion in `scripts/test-ui-automation-policy.py` rejecting these patterns under `Tests/UITests`:

```text
sleep(
Thread.sleep
Task.sleep
usleep(
```

- [ ] **Step 5: Run tests**

```bash
python3 -m unittest scripts/test-ui-automation-policy.py -v
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-ui-test-app.sh
NOTCHHUB_UI_APP_PATH="$PWD/build/ui-test/NotchHub.app" \
  xcodebuild test -project NotchHubUITests.xcodeproj -scheme NotchHubUITests \
  -destination 'platform=macOS' -resultBundlePath build/NotchHubUITests-input.xcresult
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Tests/UITests scripts/test-ui-automation-policy.py
git commit -m "Test: add deterministic macOS UI interaction helpers"
```

---

### Task 6: Add machine-checkable acceptance coverage manifest infrastructure

**Files:**
- Create: `Tests/Acceptance/coverage.yml`
- Create: `scripts/test_acceptance_coverage.py`
- Modify: `.github/workflows/ci.yml` only after the validator is green.
- Test: `scripts/test_acceptance_coverage.py`

**Interfaces:**
- Manifest schema:

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

- Allowed layers: `unit`, `integration`, `ui`, `policy`, `shipping`, `physical`.
- Allowed statuses: `accepted`, `pending`, `rejected`.

- [ ] **Step 1: Write validator unit tests with temporary fixture directories**

The tests must cover:

```python
def test_missing_acceptance_id_fails(): ...
def test_unknown_manifest_id_fails(): ...
def test_duplicate_manifest_id_fails(): ...
def test_accepted_deterministic_case_without_automation_fails(): ...
def test_physical_only_case_requires_reason(): ...
def test_missing_referenced_test_symbol_or_command_fails(): ...
def test_pending_case_may_have_partial_coverage(): ...
```

Use `tempfile.TemporaryDirectory()`; do not depend on repository state for unit tests.

- [ ] **Step 2: Implement acceptance-ID discovery**

Scan every Markdown file under `docs/testing/` with regex:

```python
ACCEPTANCE_ID = re.compile(r"\bNH-[A-Z0-9]+(?:-[A-Z0-9]+)*-\d{3}\b")
```

Return a mapping from ID to source file and fail if the same stable ID is declared by two different ledgers.

- [ ] **Step 3: Implement YAML parsing without adding a runtime dependency**

Because PyYAML is not currently a project dependency, constrain `coverage.yml` to the simple schema above and parse it with a small deterministic parser in the policy script, or store the identical schema as JSON if a zero-dependency YAML parser becomes disproportionate. If JSON is chosen during execution, update the spec and plan docs in the same commit; do not silently add PyYAML to CI.

- [ ] **Step 4: Seed only infrastructure cases, do not fake legacy completeness**

At the end of this task, `coverage.yml` may contain all discovered IDs with honest `pending` coverage debt generated by the backfill plan. Do **not** enable the strict repository-wide completeness check in required CI until Plan 2 closes accepted baseline coverage.

The validator itself must already support strict mode:

```bash
python3 scripts/test_acceptance_coverage.py --mode strict
```

and audit mode:

```bash
python3 scripts/test_acceptance_coverage.py --mode audit
```

Audit mode still fails schema errors, duplicate/unknown IDs, and broken test references; it reports accepted deterministic missing coverage as debt without returning nonzero.

- [ ] **Step 5: Run validator tests and audit**

```bash
python3 -m unittest scripts/test_acceptance_coverage.py -v
python3 scripts/test_acceptance_coverage.py --mode audit
```

Expected: unit tests PASS; audit emits a deterministic missing-coverage report for Plan 2.

- [ ] **Step 6: Commit**

```bash
git add Tests/Acceptance scripts/test_acceptance_coverage.py
git commit -m "Test: add acceptance coverage traceability validator"
```

---

### Task 7: Add required macOS UI regression CI job with diagnostics

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `scripts/test-ui-automation-policy.py`
- Test: existing CI policy tests plus new source assertions.

**Interfaces:**
- Required job name: `macOS UI regression`.
- Artifacts: `NotchHub-UI-Test.xcresult`, UI-test screenshots/debug attachments inside xcresult, exact app build metadata.

- [ ] **Step 1: Add RED workflow-policy assertions**

Require `.github/workflows/ci.yml` to contain exactly one job with:

```yaml
name: macOS UI regression
runs-on: macos-26
```

and commands containing:

```text
scripts/build-ui-test-app.sh
xcodebuild test
-resultBundlePath build/NotchHub-UI-Test.xcresult
scripts/test-ui-automation-policy.py
```

Also require immutable-SHA `actions/checkout` and `actions/upload-artifact`, consistent with current repository policy.

Run the policy test. Expected: RED.

- [ ] **Step 2: Add the CI job**

The job sequence must be:

```yaml
- checkout with persist-credentials: false
- report sw_vers / xcodebuild -version / swift --version
- python UI automation policy tests
- build exact UI-test app with SOURCE_COMMIT=${{ github.event.pull_request.head.sha || github.sha }}
- xcodebuild test on platform=macOS with resultBundlePath
- verify app NHSourceCommit equals exact source SHA
- upload xcresult with if: always()
```

Use a job timeout no larger than 25 minutes initially. Do not add automatic retries.

- [ ] **Step 3: Keep shipping verification independent**

The existing `Build, test and package` job continues to build a normal release app and must call:

```bash
python3 scripts/test-ui-automation-policy.py --verify-shipping-app build/NotchHub.app
```

after the release app exists and before packaging succeeds.

- [ ] **Step 4: Run local source policies and Xcode smoke**

```bash
python3 -m unittest scripts/test-ui-automation-policy.py -v
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-ui-test-app.sh
NOTCHHUB_UI_APP_PATH="$PWD/build/ui-test/NotchHub.app" \
  xcodebuild test -project NotchHubUITests.xcodeproj -scheme NotchHubUITests \
  -destination 'platform=macOS' -resultBundlePath build/NotchHub-UI-Test.xcresult
```

Expected: PASS.

- [ ] **Step 5: Commit and push for CI evidence**

```bash
git add .github/workflows/ci.yml scripts/test-ui-automation-policy.py
git commit -m "CI: require native macOS UI regression testing"
```

Push and preserve the first complete `macOS UI regression` job result and xcresult artifact as foundation evidence.

---

### Task 8: Document the testing foundation and freeze the handoff to legacy backfill

**Files:**
- Modify: `docs/TESTING.md`
- Modify: `docs/DEVELOPMENT.md`
- Modify: `docs/PROJECT_STATE.md`
- Modify: `docs/ROADMAP.md`
- Modify: `CHANGELOG.md`
- Test: `scripts/test_acceptance_coverage.py`, `scripts/test-ui-automation-policy.py`, full required CI.

**Interfaces:**
- Produces the explicit gate: no PR #33 repair/new feature work until Plan 2 strict acceptance coverage is green.

- [ ] **Step 1: Update `docs/TESTING.md` with the five testing layers**

Document:

```text
Swift Testing -> integration -> XCUIAutomation -> shipping/policy -> physical target-Mac
```

State that UI tests use real app launch and native pointer/scroll automation, while physical haptic feel and real-notch ergonomics remain manual.

- [ ] **Step 2: Update development policy**

Add the mandatory feature rule:

```text
acceptance ID -> RED at highest reliable layer -> minimum GREEN -> full regression CI -> physical acceptance where applicable -> merge
```

Old accepted deterministic behavior without executable evidence is blocking debt.

- [ ] **Step 3: Update project state and roadmap without claiming baseline closure**

State:

- UI automation foundation: implemented/tested once CI is green;
- legacy accepted baseline: **backfill pending**;
- PR #33: still draft/physically rejected;
- next step: execute `2026-08-14-legacy-regression-baseline-backfill.md`;
- P1 and product features remain blocked.

- [ ] **Step 4: Run all foundation verification**

```bash
swift test --parallel
python3 -m unittest scripts/test-ui-automation-policy.py -v
python3 -m unittest scripts/test_acceptance_coverage.py -v
python3 scripts/test_acceptance_coverage.py --mode audit
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-ui-test-app.sh
NOTCHHUB_UI_APP_PATH="$PWD/build/ui-test/NotchHub.app" \
  xcodebuild test -project NotchHubUITests.xcodeproj -scheme NotchHubUITests \
  -destination 'platform=macOS' -resultBundlePath build/NotchHub-UI-Test.xcresult
unset NOTCHHUB_UI_TESTING
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-app.sh release
python3 scripts/test-ui-automation-policy.py --verify-shipping-app build/NotchHub.app
```

Expected: everything PASS except the **audit report** may list honest legacy coverage debt; audit mode itself exits 0.

- [ ] **Step 5: Commit docs**

```bash
git add docs CHANGELOG.md
git commit -m "Docs: establish mandatory UI regression foundation"
```

- [ ] **Step 6: Do not merge yet**

Keep the foundation PR open while Plan 2 backfills all accepted deterministic baseline cases. Strict coverage mode must become green before the foundation PR is ready to merge.

---

## Plan completion gate

Plan 1 is complete only when:

- a real SwiftPM-built NotchHub app is driven through XCTest/XCUIAutomation on macOS;
- the `macOS UI regression` CI job is green and produces `.xcresult` diagnostics;
- deterministic media UI fixture mode works without network/third-party player dependency;
- shipping builds prove fixture markers are absent;
- stable accessibility identifiers exist for the accepted `main` surfaces/controls;
- acceptance coverage discovery/validation exists in audit + strict modes;
- no product behavior was changed to accommodate the tests;
- PR #33 remains untouched and draft;
- Plan 2 is the only allowed next development work.
