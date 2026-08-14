# Legacy Regression Baseline Backfill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert every previously accepted deterministic M1 and M6.1-M6.5 behavior into executable regression evidence and make strict acceptance traceability a required CI gate before PR #33 or any new feature work resumes.

**Architecture:** Reuse existing Swift Testing, probe, policy, shipping, and new XCUIAutomation evidence rather than duplicating tests. Inventory every stable `NH-*` ID, map existing executable evidence first, add only missing user-observable XCUI journeys, classify truly physical-only evidence narrowly, then switch acceptance validation from audit to strict. Any unexpected lower-level accepted contract with no executable evidence is a blocking RED: stop that task, add a focused test against the accepted contract, and do not change production behavior merely to satisfy the manifest.

**Tech Stack:** Swift Testing, XCTest/XCUIAutomation from Plan 1, Python acceptance validator, existing Bash/Python media acceptance harnesses, GitHub Actions `macos-26`.

## Global Constraints

- Execute only after `2026-08-14-regression-ui-automation-foundation.md` is implemented on the separate foundation branch from `main`.
- PR #33 remains draft, untouched, physically unaccepted, and is not rebased until this plan is merged.
- Accepted M1 and M6.1-M6.5 semantics are authoritative; tests may not be rewritten to match a regression.
- M6.6 IDs remain `pending` or `rejected`; foundation automation does not make them accepted.
- Existing valid tests count as evidence; do not duplicate them for test-count optics.
- Every accepted deterministic ID requires at least one automated layer: `unit`, `integration`, `ui`, `policy`, or `shipping`.
- `physical` evidence requires a specific reason and cannot replace behavior XCUIAutomation can reliably observe.
- No product features, unrelated refactors, arbitrary UI sleeps, automatic retries, security weakening, performance-baseline rewrites, or shipping-boundary broadening.

---

## Baseline sources

Inventory every stable ID discovered under `docs/testing/`. On stable `main` the key accepted ledgers are:

```text
docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md
docs/testing/MEDIA_UI_ACCEPTANCE.md
docs/testing/PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md
docs/testing/SHIPPING_MEDIA_COMPOSITION_ACCEPTANCE.md
```

`docs/testing/MEDIA_GESTURE_ACCEPTANCE.md` contains M6.6 work and remains pending/rejected. M1 semantics come from `docs/specs/M1_NOTCH_INTERACTION.md`, existing M1 tests, and accepted evidence recorded in project/testing docs. If accepted M1 behavior lacks stable IDs, create `docs/testing/NOTCH_INTERACTION_ACCEPTANCE.md` before mapping it.

---

### Task 1: Build a complete machine-readable acceptance inventory

**Files:**
- Modify: `scripts/test_acceptance_coverage.py`
- Modify: `Tests/Acceptance/coverage.yml`
- Create if needed: `docs/testing/NOTCH_INTERACTION_ACCEPTANCE.md`
- Runtime-only report: `build/acceptance-audit.json`

**Interfaces:**

```json
{
  "id": "NH-NOTCH-001",
  "source": "docs/testing/NOTCH_INTERACTION_ACCEPTANCE.md",
  "status": "accepted",
  "existingEvidence": [],
  "missingAutomation": true
}
```

- [ ] **Step 1: Add RED coverage-validator test for `--report`**

The unit test uses a temporary docs/manifest fixture and asserts that:

```bash
python3 scripts/test_acceptance_coverage.py --mode audit --report <path>
```

writes sorted valid JSON containing each discovered ID exactly once.

- [ ] **Step 2: Implement `--report` and run the real audit**

```bash
python3 scripts/test_acceptance_coverage.py \
  --mode audit \
  --report build/acceptance-audit.json
python3 -m json.tool build/acceptance-audit.json >/dev/null
```

Expected: command PASS plus an honest debt list.

- [ ] **Step 3: Freeze stable M1 IDs where missing**

Create/reuse these accepted contracts without changing semantics:

```text
NH-NOTCH-001 physical-notch compact geometry
NH-HOVER-001 deliberate hover dwell expands under accepted M1 policy
NH-HOVER-002 quick pointer pass does not expand
NH-HOVER-003 expanded pointer exit returns to compact
NH-HOVER-004 hover expansion emits exactly one semantic expansion-haptic request
NH-HOVER-005 remaining inside activation region does not duplicate expansion haptic
NH-NOTCH-TRANSITION-001 expansion settles exact expanded frame
NH-NOTCH-TRANSITION-002 collapse settles exact compact frame
NH-NOTCH-TRANSITION-003 stale completion cannot restore older geometry
NH-NOTCH-TRANSITION-004 Reduce Motion settles exact endpoint
NH-NOTCH-LIFECYCLE-001 invalidation releases monitors/callback ownership
```

Before adding any ID, run:

```bash
rg -n 'NH-(NOTCH|HOVER)' docs/testing docs/specs/M1_NOTCH_INTERACTION.md
```

Reuse an existing stable ID when present.

- [ ] **Step 4: Seed ledger-derived statuses only**

Accepted M1/M6.1-M6.5 IDs are `accepted`; M6.6 IDs remain their current pending/rejected status. Do not fabricate automated coverage.

- [ ] **Step 5: Commit**

```bash
git add Tests/Acceptance scripts/test_acceptance_coverage.py docs/testing
git commit -m "Test: inventory accepted NotchHub regression contracts"
```

---

### Task 2: Trace accepted M1 deterministic contracts to existing Swift tests

**Files:**
- Modify: `Tests/Acceptance/coverage.yml`
- Existing evidence candidates:
  - `Tests/NotchHubCoreTests/NotchGeometryTests.swift`
  - `Tests/NotchHubCoreTests/NotchInteractionCoordinatorTests.swift`
  - `Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift`
  - `Tests/NotchHubCoreTests/NotchPanelTransitionPolicyChangeTests.swift`
  - `Tests/NotchHubCoreTests/NotchPanelTransitionStressTests.swift`
  - `Tests/NotchHubCoreTests/NotchPointerPolicyTests.swift`
  - `Tests/NotchHubCoreTests/NotchPointerMonitorTests.swift`
  - `Tests/NotchHubCoreTests/NotchPanelOwnershipTests.swift`
  - `Tests/NotchHubCoreTests/NotchPerformanceInvariantTests.swift`

**Interfaces:** manifest references exact test symbols as `Module.Suite.testName`.

- [ ] **Step 1: Produce a symbol map before editing tests**

```bash
rg -n '@Test|func test|hover|pointer|haptic|transition|compact|expanded|stale|reduce|invalidate' \
  Tests/NotchHubCoreTests > build/m1-test-symbols.txt
```

For each accepted M1 ID, read the actual assertions. Similar naming is not evidence.

- [ ] **Step 2: Add exact existing evidence to the manifest**

Example shape:

```yaml
- id: NH-NOTCH-TRANSITION-003
  source: docs/testing/NOTCH_INTERACTION_ACCEPTANCE.md
  status: accepted
  coverage:
    - layer: unit
      test: NotchHubCoreTests.NotchPanelTransitionCoordinatorTests.staleCompletionCannotOverrideNewerTransition
  physicalOnlyReason: null
```

Use the actual existing symbol name discovered in Step 1; the example above is schema illustration and is not committed unless that symbol exists.

- [ ] **Step 3: Turn any unexpected deterministic gap into an explicit blocking RED**

Run:

```bash
python3 scripts/test_acceptance_coverage.py --mode audit --report build/acceptance-audit.json
```

If an accepted M1 deterministic ID still has no automated evidence, stop Task 2. Add one focused Swift test in the existing owning test file, run it to RED, then make only the minimum test-support/production correction required by the already accepted contract. Preserve that RED/GREEN evidence in the commit message or PR notes. Do not proceed while the gap remains.

- [ ] **Step 4: Run the M1 deterministic suite**

```bash
swift test --filter NotchGeometryTests
swift test --filter NotchInteractionCoordinatorTests
swift test --filter NotchPanelTransitionCoordinatorTests
swift test --filter NotchPointerPolicyTests
swift test --filter NotchPointerMonitorTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Tests/NotchHubCoreTests Tests/Acceptance/coverage.yml
git commit -m "Test: trace accepted M1 deterministic behavior"
```

---

### Task 3: Add M1 XCUI user journeys that lower layers cannot honestly prove

**Files:**
- Modify: `Tests/UITests/Support/NotchHubUIApplication.swift`
- Modify: `Tests/UITests/NotchHubUITests.swift`
- Modify: `Tests/Acceptance/coverage.yml`

**Interfaces:** add these helpers:

```swift
@MainActor
func openExpandedViaAcceptedHover(timeout: TimeInterval = 2) {
    let compact = surface("notch.surface.compact")
    compact.hover()
    XCTAssertSurface("notch.surface.expanded", in: app, timeout: timeout)
}

@MainActor
func waitForStableCompact(timeout: TimeInterval = 2) {
    XCTAssertSurface("notch.surface.compact", in: app, timeout: timeout)
    XCTAssertFalse(app.otherElements["notch.surface.expanded"].exists)
}
```

- [ ] **Step 1: Add launch-state regression**

```swift
@MainActor
func testLaunchStartsAtStableCompactSurface() throws {
    let subject = try NotchHubUIApplication(mode: .shippingSmoke)
    subject.launch()
    subject.waitForStableCompact()
}
```

- [ ] **Step 2: Add real hover-dwell expansion regression**

```swift
@MainActor
func testHoverDwellExpandsThroughRealPointerDelivery() throws {
    let subject = try NotchHubUIApplication(mode: .shippingSmoke)
    subject.launch()
    subject.openExpandedViaAcceptedHover()
}
```

This drives the real AppKit/SwiftUI pointer path; it does not call a coordinator directly.

- [ ] **Step 3: Add quick-pass non-expansion regression without sleep**

Move pointer to compact, immediately move it outside, then use an inverted predicate expectation:

```swift
let expanded = subject.app.otherElements["notch.surface.expanded"]
let appears = XCTNSPredicateExpectation(
    predicate: NSPredicate(format: "exists == true"),
    object: expanded
)
appears.isInverted = true
XCTAssertEqual(XCTWaiter().wait(for: [appears], timeout: 0.35), .completed)
```

The timeout is a bounded observation window, not a fixed wait before asserting.

- [ ] **Step 4: Add pointer-exit auto-collapse regression**

```swift
@MainActor
func testExpandedPointerExitReturnsToStableCompact() throws {
    let subject = try NotchHubUIApplication(mode: .shippingSmoke)
    subject.launch()
    subject.openExpandedViaAcceptedHover()
    subject.movePointerOutside(subject.surface("notch.surface.expanded"))
    subject.waitForStableCompact()
}
```

- [ ] **Step 5: Add repeated-cycle stale-state regression**

Run 10 hover-expand/pointer-exit-collapse cycles. After every cycle call `waitForStableCompact()`. Any intermediate/stale surface is a failure.

- [ ] **Step 6: Run three independent UI executions**

```bash
for i in 1 2 3; do
  rm -rf "build/NotchHub-M1-$i.xcresult"
  SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-ui-test-app.sh
  NOTCHHUB_UI_APP_PATH="$PWD/build/ui-test/NotchHub.app" \
    xcodebuild test -project NotchHubUITests.xcodeproj -scheme NotchHubUITests \
    -destination 'platform=macOS' \
    -resultBundlePath "build/NotchHub-M1-$i.xcresult" || exit 1
done
```

Expected: all three PASS. This is validation evidence, not retry masking.

- [ ] **Step 7: Map M1 UI IDs and commit**

```bash
git add Tests/UITests Tests/Acceptance/coverage.yml
git commit -m "Test: cover accepted M1 user journeys with XCUIAutomation"
```

---

### Task 4: Trace M6.1 media bridge probe acceptance to executable evidence

**Files:**
- Modify: `Tests/Acceptance/coverage.yml`
- Existing evidence:
  - `Tests/MediaBridgeProbeCoreTests/ProbeInvocationTests.swift`
  - `Tests/MediaBridgeProbeCoreTests/ProbeMediaCapabilitiesTests.swift`
  - `Tests/MediaBridgeProbeCoreTests/ProbeMediaCommandTests.swift`
  - `Tests/MediaBridgeProbeCoreTests/ProbeMediaPayloadTests.swift`
  - `Tests/MediaBridgeProbeCoreTests/ProbeObservationEvidenceTests.swift`
  - `Tests/MediaBridgeProbeCoreTests/ProbeProcessTests.swift`
  - `Tests/MediaBridgeProbeCoreTests/ProbeReportTests.swift`
  - `scripts/test_media_bridge_probe_acceptance.py`
  - `scripts/test_media_bridge_probe_ci.py`

- [ ] **Step 1: Map every accepted ID from `MEDIA_BRIDGE_PROBE_ACCEPTANCE.md`**

Use unit evidence for payload/command/process semantics and shipping/policy evidence for built-app provenance, Sandbox/Hardened Runtime, and archive verification.

- [ ] **Step 2: Run all evidence**

```bash
swift test --filter MediaBridgeProbeCoreTests
python3 scripts/test_media_bridge_probe_acceptance.py -v
python3 scripts/test_media_bridge_probe_ci.py -v
bash scripts/build-media-bridge-probe-app.sh
bash scripts/verify-media-bridge-probe.sh
```

Expected: PASS.

- [ ] **Step 3: Run audit; any uncovered accepted deterministic ID is a blocking RED**

Do not proceed until it has an exact executable reference.

- [ ] **Step 4: Commit**

```bash
git add Tests/Acceptance/coverage.yml Tests/MediaBridgeProbeCoreTests scripts
git commit -m "Test: trace accepted media bridge probe behavior"
```

---

### Task 5: Trace production media transport and process lifecycle acceptance

**Files:**
- Modify: `Tests/Acceptance/coverage.yml`
- Existing evidence:
  - `Tests/NotchHubMediaCoreTests/ProductionMediaTransportCandidateBundlePathsTests.swift`
  - `Tests/NotchHubMediaCoreTests/ProductionMediaTransportCandidateInvocationTests.swift`
  - `Tests/NotchHubMediaCoreTests/ProductionMediaTransportCandidateRunnerTests.swift`
  - `Tests/NotchHubMediaCoreTests/ProductionMediaTransportCandidateTeardownTests.swift`
  - `Tests/NotchHubMediaCoreTests/ProductionMediaTransportCandidateTests.swift`
  - `Tests/NotchHubMediaCoreTests/MediaRemoteProcessClientTests.swift`
  - `Tests/NotchHubMediaCoreTests/MediaRemoteProcessTeardownTests.swift`
  - `scripts/test_production_media_transport_acceptance.py`
  - `scripts/test_production_media_transport_candidate_ci.py`

- [ ] **Step 1: Map every accepted ID from `PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`**

Prefer lower-level unit tests for invocation/teardown and shipping evidence for bundle/provenance/signing contracts.

- [ ] **Step 2: Run all transport evidence**

```bash
swift test --filter ProductionMediaTransportCandidate
swift test --filter MediaRemoteProcess
python3 scripts/test_production_media_transport_acceptance.py -v
python3 scripts/test_production_media_transport_candidate_ci.py -v
bash scripts/build-production-media-transport-candidate.sh
bash scripts/verify-production-media-transport-candidate.sh
```

Expected: PASS.

- [ ] **Step 3: Run audit and stop on any uncovered accepted deterministic ID**

No production change is allowed solely to satisfy traceability; first prove the accepted behavior with a focused RED test.

- [ ] **Step 4: Commit**

```bash
git add Tests/Acceptance/coverage.yml Tests/NotchHubMediaCoreTests scripts
git commit -m "Test: trace accepted production media transport behavior"
```

---

### Task 6: Trace shipping media composition and expanded-only ownership

**Files:**
- Modify: `Tests/Acceptance/coverage.yml`
- Existing evidence:
  - `Tests/NotchHubCoreTests/MediaAppCompositionPolicyTests.swift`
  - `Tests/NotchHubMediaCoreTests/ShippingMediaBundlePathsTests.swift`
  - `Tests/NotchHubMediaCoreTests/ShippingMediaRuntimePresentationPolicyTests.swift`
  - `Tests/NotchHubMediaCoreTests/SystemMediaBridgeTests.swift`
  - `scripts/test_shipping_media_composition.py`
  - `scripts/test_shipping_media_acceptance.py`
  - `scripts/test_shipping_media_idle_lifecycle.py`
  - `scripts/test_shipping_media_compact_resources.py`

- [ ] **Step 1: Map every accepted ID from `SHIPPING_MEDIA_COMPOSITION_ACCEPTANCE.md`**

Explicitly cover the accepted invariant: settled compact owns zero persistent adapter process; settled expanded owns only the reviewed runtime boundary; normal termination releases ownership.

- [ ] **Step 2: Run composition evidence**

```bash
swift test --filter MediaAppCompositionPolicyTests
swift test --filter ShippingMediaRuntimePresentationPolicyTests
python3 scripts/test_shipping_media_composition.py -v
python3 scripts/test_shipping_media_acceptance.py -v
python3 scripts/test_shipping_media_idle_lifecycle.py -v
python3 scripts/test_shipping_media_compact_resources.py -v
```

Expected: PASS.

- [ ] **Step 3: Run audit and stop on any uncovered accepted deterministic ID**

- [ ] **Step 4: Commit**

```bash
git add Tests/Acceptance/coverage.yml Tests scripts
git commit -m "Test: trace accepted shipping media lifecycle"
```

---

### Task 7: Backfill accepted M6.5 media-first UI journeys with deterministic XCUI media

**Files:**
- Modify: `Tests/UITests/Support/NotchHubUIApplication.swift`
- Modify: `Tests/UITests/NotchHubUITests.swift`
- Modify: `Sources/NotchHubApp/UITestSupport/UITestMediaRuntime.swift`
- Modify: `Tests/Acceptance/coverage.yml`
- Existing deterministic support: `Tests/NotchHubMediaCoreTests/ShippingMediaPresentationModelTests.swift`

**Interfaces:**
- Fixture track sequence: `Track A -> Track B -> Track C`.
- Add helper:

```swift
@MainActor
func titleElement() -> XCUIElement {
    app.staticTexts["media.title"]
}
```

- [ ] **Step 1: Add RED expanded-media UI test**

```swift
@MainActor
func testExpandedMediaShowsFixtureMetadataAndControls() throws {
    let subject = try NotchHubUIApplication(mode: .deterministicMedia)
    subject.launch()
    subject.openExpandedViaAcceptedHover()
    XCTAssertEqual(subject.titleElement().label, "Track A")
    XCTAssertTrue(subject.app.buttons["media.playPause"].exists)
    XCTAssertTrue(subject.app.buttons["media.previous"].exists)
    XCTAssertTrue(subject.app.buttons["media.next"].exists)
}
```

If this is RED, fix only test fixture/accessibility wiring on the foundation branch; do not alter accepted media UI semantics.

- [ ] **Step 2: Add actual button-control journeys**

```swift
subject.app.buttons["media.next"].click()
XCTAssertEqual(subject.titleElement().label, "Track B")
subject.app.buttons["media.previous"].click()
XCTAssertEqual(subject.titleElement().label, "Track A")
```

Add play/pause assertions using a stable accessibility value on `media.playPause` such as `playing` / `paused`; freeze that value in the production view accessibility contract without changing visuals.

- [ ] **Step 3: Add unsupported-capability mode**

Plan 1 already defines `media-unsupported`. Launch it, expand, assert `media.previous` and `media.next` exist but `isEnabled == false`, click attempts do not change `media.title` from `Track A`.

- [ ] **Step 4: Add accepted compact retained-state journey**

Launch deterministic media, expand and verify A, move pointer outside to stable compact, then verify the compact media surface remains coherent. Persistent-process ownership is proven by Task 6 shipping/unit evidence, not by a UI-only guess.

- [ ] **Step 5: Run UI and presentation evidence**

```bash
swift test --filter ShippingMediaPresentationModelTests
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-ui-test-app.sh
NOTCHHUB_UI_APP_PATH="$PWD/build/ui-test/NotchHub.app" \
  xcodebuild test -project NotchHubUITests.xcodeproj -scheme NotchHubUITests \
  -destination 'platform=macOS' -resultBundlePath build/NotchHub-MediaUI.xcresult
```

Expected: PASS.

- [ ] **Step 6: Map all accepted `MEDIA_UI_ACCEPTANCE.md` IDs and commit**

```bash
git add Sources/NotchHubApp/UITestSupport Tests/UITests \
  Tests/NotchHubMediaCoreTests Tests/Acceptance/coverage.yml
git commit -m "Test: cover accepted media UI journeys end to end"
```

---

### Task 8: Classify physical-only evidence narrowly and honestly

**Files:**
- Modify: `Tests/Acceptance/coverage.yml`
- Modify only for evidence wording: `docs/testing/*.md`

- [ ] **Step 1: Reject generic physical-only reasons**

Forbidden examples:

```text
manual test
hardware
hard to automate
```

Accepted examples:

```text
Requires perception of physical Taptic Engine output on Mac16,8; automation verifies semantic haptic request only.
Requires visual alignment against the physical MacBook notch edge; virtual runner geometry cannot prove bezel alignment.
```

- [ ] **Step 2: Give mixed cases both automated and physical evidence**

Semantic haptic request is automated; perceptibility/feel remains physical. Geometry math/frame settlement is automated; physical bezel alignment remains physical.

- [ ] **Step 3: Verify M6.6 status remains pending/rejected**

No M6.6 ID is changed to accepted.

- [ ] **Step 4: Run audit**

```bash
python3 scripts/test_acceptance_coverage.py --mode audit --report build/acceptance-audit.json
```

Expected: **zero accepted deterministic missing-automation cases**. Any remaining item blocks Task 9.

- [ ] **Step 5: Commit**

```bash
git add Tests/Acceptance/coverage.yml docs/testing
git commit -m "Test: classify physical acceptance evidence honestly"
```

---

### Task 9: Switch acceptance traceability to strict required CI

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `scripts/test_ui_automation_policy.py`

- [ ] **Step 1: Write RED workflow-policy test requiring strict mode**

Require:

```text
python3 scripts/test_acceptance_coverage.py --mode strict
```

in the `macOS UI regression` job and at least one normal required job.

- [ ] **Step 2: Prove strict mode locally before changing CI**

```bash
python3 scripts/test_acceptance_coverage.py --mode strict
```

Expected: PASS. If not, return to the owning prior task; do not weaken strict validation.

- [ ] **Step 3: Add strict validation to CI and run policy tests**

```bash
python3 scripts/test_ui_automation_policy.py -v
python3 scripts/test_acceptance_coverage.py --mode strict
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ci.yml scripts/test_ui_automation_policy.py
git commit -m "CI: require complete acceptance regression traceability"
```

---

### Task 10: Full baseline verification and foundation PR readiness

**Files:**
- Modify: `docs/TESTING.md`
- Modify: `docs/PROJECT_STATE.md`
- Modify: `docs/ROADMAP.md`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Run every deterministic layer**

```bash
swift test --parallel
python3 -m unittest discover -s scripts -p 'test_*.py' -v
python3 scripts/test_acceptance_coverage.py --mode strict
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-ui-test-app.sh
NOTCHHUB_UI_APP_PATH="$PWD/build/ui-test/NotchHub.app" \
  xcodebuild test -project NotchHubUITests.xcodeproj -scheme NotchHubUITests \
  -destination 'platform=macOS' -resultBundlePath build/NotchHub-Baseline.xcresult
unset NOTCHHUB_UI_TESTING
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-app.sh release
python3 scripts/test_ui_automation_policy.py --verify-shipping-app build/NotchHub.app
bash scripts/security-audit.sh
```

Expected: all PASS.

- [ ] **Step 2: Run UI suite three independent times as flake evidence**

```bash
for i in 1 2 3; do
  rm -rf "build/NotchHub-Baseline-$i.xcresult"
  NOTCHHUB_UI_APP_PATH="$PWD/build/ui-test/NotchHub.app" \
    xcodebuild test -project NotchHubUITests.xcodeproj -scheme NotchHubUITests \
    -destination 'platform=macOS' \
    -resultBundlePath "build/NotchHub-Baseline-$i.xcresult" || exit 1
done
```

Expected: all three PASS without internal retry logic.

- [ ] **Step 3: Update docs with exact state language**

Before merge:

```text
Regression/UI foundation: implemented + automated-tested, merge pending.
Accepted M1/M6.1-M6.5 deterministic baseline: fully traceable + automated-green.
M6.6 PR #33: physical FAIL / draft / not merged.
Next after merge: rebase/update PR #33 onto foundation and run new regression suite.
```

- [ ] **Step 4: Push and require all GitHub checks green**

Required checks:

```text
macOS 26 compatibility
Build, test and package
macOS UI regression
```

Any UI failure is investigated from `.xcresult`; do not blindly rerun.

- [ ] **Step 5: Commit docs**

```bash
git add docs CHANGELOG.md
git commit -m "Docs: close accepted regression baseline backfill"
```

- [ ] **Step 6: Merge gate**

Foundation PR may become ready only when strict traceability, all Swift/Python/XCUI tests, shipping fixture-exclusion, security/performance/release gates, and all required GitHub checks pass. After merge and green `main`, PR #33 is rebased/updated and its hover/haptic/jump/direction defects become new RED tests before any production repair.

---

## Plan completion gate

Plan 2 is complete only when every accepted deterministic M1 and M6.1-M6.5 ID has executable traceability, strict validation is required and green, critical user journeys run through real XCUIAutomation, physical-only evidence is narrowly justified, and PR #33 remains unaccepted. No product feature work resumes before this foundation is merged into `main`.
