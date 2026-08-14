# Legacy Regression Baseline Backfill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert every previously accepted deterministic M1 and M6.1-M6.5 behavior into executable regression evidence and make strict acceptance traceability a required CI gate before PR #33 or any new feature work resumes.

**Architecture:** Reuse existing Swift Testing, policy, shipping, probe, and new XCUIAutomation layers instead of rewriting tests. First inventory every stable `NH-*` acceptance ID and map existing executable evidence; then add only the missing highest-value unit/integration/UI regressions. Finish by switching acceptance coverage validation from audit to strict and proving all required CI green on the foundation PR.

**Tech Stack:** Swift Testing, XCTest/XCUIAutomation foundation from Plan 1, Python acceptance manifest validator, existing Bash/Python shipping acceptance harnesses, GitHub Actions macOS 26.

## Global Constraints

- This plan executes only after `2026-08-14-regression-ui-automation-foundation.md` is implemented on the separate foundation branch from `main`.
- PR #33 remains draft, untouched, physically unaccepted, and is not rebased until this plan is complete and merged.
- Accepted M1 and M6.1-M6.5 product semantics are authoritative; tests must not be rewritten to match regressions.
- M6.6 acceptance IDs remain `pending` or `rejected` until PR #33 is later rebased and repaired; they do not need to be green to merge the foundation.
- Existing valid tests count as evidence; do not duplicate them merely to increase test count.
- Every accepted deterministic acceptance ID must have at least one automated layer (`unit`, `integration`, `ui`, `policy`, or `shipping`).
- Physical-only evidence requires an explicit reason and may not be used for behavior XCUIAutomation can reliably observe.
- No product feature additions and no unrelated refactors.
- No arbitrary sleeps or automatic retries in UI tests.
- No weakening of security, performance, immutable baselines, or shipping composition checks.

---

## Baseline sources

The backfill must inventory all stable IDs under `docs/testing/`, including at minimum:

```text
docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md
docs/testing/MEDIA_UI_ACCEPTANCE.md
docs/testing/PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md
docs/testing/SHIPPING_MEDIA_COMPOSITION_ACCEPTANCE.md
docs/testing/MEDIA_GESTURE_ACCEPTANCE.md      # M6.6: keep pending/rejected
docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md  # if present after branch updates: M6.6 pending/rejected
docs/testing/MEDIA_PEEK_ACCEPTANCE.md         # if present after branch updates: M6.6 pending/rejected
```

M1 contract source is `docs/specs/M1_NOTCH_INTERACTION.md` plus its accepted evidence recorded in `docs/TESTING.md`, `docs/PROJECT_STATE.md`, and M1 implementation plans. If an accepted M1 behavior has no stable `NH-*` ID yet, this plan adds a stable ID before adding its manifest entry; IDs describe already accepted behavior and do not change semantics.

---

### Task 1: Produce a deterministic acceptance inventory and classify every case

**Files:**
- Modify: `scripts/test_acceptance_coverage.py`
- Modify: `Tests/Acceptance/coverage.yml`
- Create: `build/acceptance-audit.json` at execution time only; do not commit build output.
- Modify: one M1 acceptance ledger under `docs/testing/` if accepted M1 cases lack stable IDs.

**Interfaces:**
- Produces audit records with fields:

```json
{
  "id": "NH-...",
  "source": "docs/testing/...",
  "status": "accepted|pending|rejected",
  "existingEvidence": [],
  "missingAutomation": true
}
```

- [ ] **Step 1: Add machine-readable audit output test**

Extend validator tests so:

```bash
python3 scripts/test_acceptance_coverage.py --mode audit --report build/acceptance-audit.json
```

creates valid JSON sorted by acceptance ID and containing every discovered stable ID exactly once.

Write the failing unit test first with a temporary docs/manifest fixture.

- [ ] **Step 2: Implement `--report` and run the real audit**

```bash
python3 scripts/test_acceptance_coverage.py \
  --mode audit \
  --report build/acceptance-audit.json
python3 -m json.tool build/acceptance-audit.json >/dev/null
```

Expected: PASS command plus a non-empty honest debt list.

- [ ] **Step 3: Add stable M1 acceptance IDs if missing**

Create or extend `docs/testing/NOTCH_INTERACTION_ACCEPTANCE.md` with already accepted semantics only. Minimum stable cases to represent:

```text
NH-NOTCH-001 hardware-notch compact geometry
NH-HOVER-001 deliberate hover dwell expands according to accepted M1 policy
NH-HOVER-002 quick pass does not expand
NH-HOVER-003 pointer exit returns to compact
NH-HOVER-004 hover expansion emits one semantic expansion haptic
NH-HOVER-005 no duplicate haptic while remaining inside the activation region
NH-NOTCH-TRANSITION-001 expansion settles exact expanded frame
NH-NOTCH-TRANSITION-002 collapse settles exact compact frame
NH-NOTCH-TRANSITION-003 stale animation completion cannot restore old geometry
NH-NOTCH-TRANSITION-004 Reduce Motion settles exact endpoint
NH-NOTCH-LIFECYCLE-001 invalidate removes monitors/owned callbacks
```

If an ID already exists elsewhere, reuse it rather than creating a duplicate.

- [ ] **Step 4: Populate manifest statuses without claiming coverage yet**

For every discovered ID, set the ledger-derived status. Existing M6.6 IDs stay pending/rejected. Accepted M1/M6.1-M6.5 IDs get `accepted` even if their coverage list is initially incomplete; audit mode records the debt.

- [ ] **Step 5: Commit the inventory separately**

```bash
git add Tests/Acceptance scripts/test_acceptance_coverage.py docs/testing
git commit -m "Test: inventory accepted NotchHub regression contracts"
```

---

### Task 2: Map existing deterministic M1 Core tests before adding anything new

**Files:**
- Modify: `Tests/Acceptance/coverage.yml`
- Modify only when a real gap exists:
  - `Tests/NotchHubCoreTests/NotchGeometryTests.swift`
  - `Tests/NotchHubCoreTests/NotchInteractionCoordinatorTests.swift`
  - `Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift`
  - `Tests/NotchHubCoreTests/NotchPanelTransitionPolicyChangeTests.swift`
  - `Tests/NotchHubCoreTests/NotchPanelTransitionStressTests.swift`
  - `Tests/NotchHubCoreTests/NotchPointerPolicyTests.swift`
  - `Tests/NotchHubCoreTests/NotchPointerMonitorTests.swift`
  - `Tests/NotchHubCoreTests/NotchPanelOwnershipTests.swift`
  - `Tests/NotchHubCoreTests/NotchPerformanceInvariantTests.swift`

**Interfaces:**
- Consumes accepted M1 IDs from Task 1.
- Produces manifest entries pointing to exact existing/new test symbols.

- [ ] **Step 1: For each M1 ID, search existing tests before writing a test**

Use exact symbol/file search:

```bash
rg -n 'hover|pointer|haptic|transition|compact|expanded|stale|Reduce Motion|invalidate' \
  Tests/NotchHubCoreTests
```

Record an existing test only when its assertion directly proves the acceptance result. A similarly named test is not sufficient.

- [ ] **Step 2: Add RED tests only for uncovered deterministic semantics**

Examples of required tests if no equivalent exists:

```swift
@Test
func pointerExitFromExpandedRequestsNonHapticCollapse() {
    // arrange accepted expanded pointer policy
    // assert exactly one collapse intent and zero haptic intents
}

@Test
func staleExpansionCompletionCannotOverrideNewerCollapse() {
    // capture generation A completion, request collapse generation B,
    // invoke A completion, assert compact target remains authoritative
}
```

Use existing test harness types in the target rather than introducing a parallel fake architecture.

- [ ] **Step 3: Run focused M1 tests**

```bash
swift test --filter NotchGeometryTests
swift test --filter NotchInteractionCoordinatorTests
swift test --filter NotchPanelTransitionCoordinatorTests
swift test --filter NotchPointerPolicyTests
```

Expected: PASS after any necessary RED -> GREEN test-only coverage additions. Production code should not change on stable `main` unless a newly written test exposes an actual accepted-baseline regression.

- [ ] **Step 4: Update manifest with exact test symbols**

Example:

```yaml
- id: NH-NOTCH-TRANSITION-003
  source: docs/testing/NOTCH_INTERACTION_ACCEPTANCE.md
  status: accepted
  coverage:
    - layer: unit
      test: NotchHubCoreTests.NotchPanelTransitionCoordinatorTests.staleCompletionCannotOverrideNewerTransition
  physicalOnlyReason: null
```

- [ ] **Step 5: Commit**

```bash
git add Tests/NotchHubCoreTests Tests/Acceptance/coverage.yml
git commit -m "Test: trace accepted M1 core behavior to executable evidence"
```

---

### Task 3: Add M1 XCUI end-to-end journeys for behavior synthetic Core tests cannot prove

**Files:**
- Modify: `Tests/UITests/NotchHubUITests.swift`
- Modify: `Tests/UITests/Support/NotchHubUIApplication.swift`
- Modify: `Tests/Acceptance/coverage.yml`

**Interfaces:**
- Uses stable identifiers from Plan 1.
- Produces UI test methods:

```text
testLaunchStartsAtStableCompactSurface
testHoverDwellExpandsUsingRealPointerDelivery
testQuickHoverPassDoesNotExpand
testExpandedPointerExitReturnsToCompact
testRepeatedOpenCloseNeverLeavesIntermediateSurface
```

- [ ] **Step 1: Write `testLaunchStartsAtStableCompactSurface`**

```swift
@MainActor
func testLaunchStartsAtStableCompactSurface() throws {
    let subject = try NotchHubUIApplication(mode: .shippingSmoke)
    subject.launch()
    XCTAssertSurface("notch.surface.compact", in: subject.app)
    XCTAssertFalse(subject.app.otherElements["notch.surface.expanded"].exists)
}
```

Run it and keep RED if actual app accessibility/wiring does not expose the state correctly.

- [ ] **Step 2: Add real hover dwell and quick-pass tests**

Use `XCUIElement.hover()` / coordinates and predicate waits only. Do not call coordinator methods directly.

The quick-pass test must move the pointer away before the accepted dwell completes and assert expanded never appears during a bounded predicate observation window; implement the observation as an XCTest expectation on `exists == false`, not `sleep`.

- [ ] **Step 3: Add expanded pointer-exit regression**

Drive expansion through the accepted user entry point available on stable `main`, then use `movePointerOutsidePanel()` and assert exact stable compact accessibility state.

- [ ] **Step 4: Add repeated-cycle stale-state regression**

Perform 10 open/close cycles. After every cycle assert exactly one stable surface exists and no previous surface remains. Do not assert pixel-perfect intermediate animation frames.

- [ ] **Step 5: Run UI suite repeatedly without retry masking**

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

Three independent runs must PASS. This loop is validation, not an automatic CI retry.

- [ ] **Step 6: Map the corresponding M1 IDs and commit**

```bash
git add Tests/UITests Tests/Acceptance/coverage.yml
git commit -m "Test: cover accepted M1 user journeys with XCUIAutomation"
```

---

### Task 4: Trace M6.1 media bridge probe acceptance to existing tests and policy

**Files:**
- Modify: `Tests/Acceptance/coverage.yml`
- Modify only for genuine gaps:
  - `Tests/MediaBridgeProbeCoreTests/ProbeInvocationTests.swift`
  - `Tests/MediaBridgeProbeCoreTests/ProbeMediaCapabilitiesTests.swift`
  - `Tests/MediaBridgeProbeCoreTests/ProbeMediaCommandTests.swift`
  - `Tests/MediaBridgeProbeCoreTests/ProbeMediaPayloadTests.swift`
  - `Tests/MediaBridgeProbeCoreTests/ProbeObservationEvidenceTests.swift`
  - `Tests/MediaBridgeProbeCoreTests/ProbeProcessTests.swift`
  - `Tests/MediaBridgeProbeCoreTests/ProbeReportTests.swift`
  - `scripts/test_media_bridge_probe_acceptance.py`
  - `scripts/test_media_bridge_probe_ci.py`

**Interfaces:**
- Acceptance source: `docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md`.

- [ ] **Step 1: Map every accepted probe ID to existing executable evidence**

Prefer existing `Probe*Tests` and the existing CI/build/verify scripts. Use `shipping` or `policy` layer for checks that only become true on the built probe application.

- [ ] **Step 2: Add a RED test for any uncovered accepted probe contract**

Typical gaps to check explicitly:

```text
fixed adapter commit/provenance
bounded capabilities output schema
no metadata leakage in observation evidence
clean process teardown
Sandbox/Hardened Runtime verification
```

- [ ] **Step 3: Run all probe evidence**

```bash
swift test --filter MediaBridgeProbeCoreTests
python3 scripts/test_media_bridge_probe_acceptance.py -v
python3 scripts/test_media_bridge_probe_ci.py -v
bash scripts/build-media-bridge-probe-app.sh
bash scripts/verify-media-bridge-probe.sh
```

Expected: PASS.

- [ ] **Step 4: Commit manifest/test gaps**

```bash
git add Tests/MediaBridgeProbeCoreTests Tests/Acceptance scripts
git commit -m "Test: trace accepted media bridge probe behavior"
```

---

### Task 5: Trace production media transport acceptance and lifecycle

**Files:**
- Modify: `Tests/Acceptance/coverage.yml`
- Modify only for gaps:
  - `Tests/NotchHubMediaCoreTests/ProductionMediaTransportCandidateBundlePathsTests.swift`
  - `Tests/NotchHubMediaCoreTests/ProductionMediaTransportCandidateInvocationTests.swift`
  - `Tests/NotchHubMediaCoreTests/ProductionMediaTransportCandidateRunnerTests.swift`
  - `Tests/NotchHubMediaCoreTests/ProductionMediaTransportCandidateTeardownTests.swift`
  - `Tests/NotchHubMediaCoreTests/ProductionMediaTransportCandidateTests.swift`
  - `Tests/NotchHubMediaCoreTests/MediaRemoteProcessClientTests.swift`
  - `Tests/NotchHubMediaCoreTests/MediaRemoteProcessTeardownTests.swift`
  - `scripts/test_production_media_transport_acceptance.py`
  - `scripts/test_production_media_transport_candidate_ci.py`

**Interfaces:**
- Acceptance source: `docs/testing/PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`.

- [ ] **Step 1: Map fixed command/path/provenance/security contracts to existing tests**

Do not create UI tests for process-spawn internals when unit/shipping evidence is stronger.

- [ ] **Step 2: Verify one-shot/teardown failure paths are represented**

If missing, add deterministic tests proving:

```swift
@Test func stopTerminatesOwnedProcessAndClearsCallbacks() { ... }
@Test func staleProcessCompletionCannotPublishAfterStop() { ... }
```

- [ ] **Step 3: Run transport evidence**

```bash
swift test --filter ProductionMediaTransportCandidate
swift test --filter MediaRemoteProcess
python3 scripts/test_production_media_transport_acceptance.py -v
python3 scripts/test_production_media_transport_candidate_ci.py -v
bash scripts/build-production-media-transport-candidate.sh
bash scripts/verify-production-media-transport-candidate.sh
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add Tests/NotchHubMediaCoreTests Tests/Acceptance scripts
git commit -m "Test: trace accepted production media transport behavior"
```

---

### Task 6: Trace shipping media composition and expanded-only runtime ownership

**Files:**
- Modify: `Tests/Acceptance/coverage.yml`
- Modify only for gaps:
  - `Tests/NotchHubCoreTests/MediaAppCompositionPolicyTests.swift`
  - `Tests/NotchHubMediaCoreTests/ShippingMediaBundlePathsTests.swift`
  - `Tests/NotchHubMediaCoreTests/ShippingMediaRuntimePresentationPolicyTests.swift`
  - `Tests/NotchHubMediaCoreTests/SystemMediaBridgeTests.swift`
  - `scripts/test_shipping_media_composition.py`
  - `scripts/test_shipping_media_acceptance.py`
  - `scripts/test_shipping_media_idle_lifecycle.py`
  - `scripts/test_shipping_media_compact_resources.py`

**Interfaces:**
- Acceptance source: `docs/testing/SHIPPING_MEDIA_COMPOSITION_ACCEPTANCE.md`.

- [ ] **Step 1: Map shipping artifact/path/security cases to policy/shipping evidence**

Explicitly include the accepted invariant that settled compact owns zero persistent media adapter process while settled expanded owns only the reviewed runtime path.

- [ ] **Step 2: Add missing lifecycle unit/integration tests before changing any composition**

If existing tests do not directly prove start/stop counts, add injected fake runtime assertions around `AppDelegate` composition seam introduced by Plan 1.

- [ ] **Step 3: Run shipping composition evidence**

```bash
swift test --filter MediaAppCompositionPolicyTests
swift test --filter ShippingMediaRuntimePresentationPolicyTests
python3 scripts/test_shipping_media_composition.py -v
python3 scripts/test_shipping_media_acceptance.py -v
python3 scripts/test_shipping_media_idle_lifecycle.py -v
python3 scripts/test_shipping_media_compact_resources.py -v
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add Tests Tests/Acceptance scripts
git commit -m "Test: trace accepted shipping media lifecycle"
```

---

### Task 7: Backfill M6.5 media-first UI behavior with deterministic XCUI media fixture

**Files:**
- Modify: `Tests/UITests/NotchHubUITests.swift`
- Modify: `Sources/NotchHubApp/UITestSupport/UITestMediaRuntime.swift`
- Modify: `Tests/Acceptance/coverage.yml`
- Modify only for deterministic gaps: `Tests/NotchHubMediaCoreTests/ShippingMediaPresentationModelTests.swift`

**Interfaces:**
- Acceptance source: `docs/testing/MEDIA_UI_ACCEPTANCE.md`.
- Uses fixture tracks A/B/C and stable media accessibility IDs.

- [ ] **Step 1: Add RED UI test for expanded media presentation**

```swift
@MainActor
func testExpandedMediaShowsFixtureMetadataAndControls() throws {
    let subject = try NotchHubUIApplication(mode: .deterministicMedia)
    subject.launch()
    subject.openUsingAcceptedMainInteraction()
    XCTAssertSurface("notch.surface.expanded", in: subject.app)
    XCTAssertEqual(subject.app.staticTexts["media.title"].value as? String, "Track A")
    XCTAssertTrue(subject.app.buttons["media.playPause"].exists)
    XCTAssertTrue(subject.app.buttons["media.previous"].exists)
    XCTAssertTrue(subject.app.buttons["media.next"].exists)
}
```

Use accessible value/label consistently; freeze the exact accessibility contract in the helper rather than relying on localized visible strings.

- [ ] **Step 2: Add previous/play-pause/next control journeys**

Drive actual buttons through XCUIAutomation and assert fixture state changes:

```text
A --next--> B
B --previous--> A
playing --playPause--> paused
paused --playPause--> playing
```

- [ ] **Step 3: Add disabled-capability fixture and regression**

Extend `UITestConfiguration.Fixture` with `media-unsupported` and expose previous/next disabled. UI tests assert buttons are not enabled and interaction does not mutate track identity.

All added fixture code stays under `#if NOTCHHUB_UI_TESTING`.

- [ ] **Step 4: Add compact retained-presentation regression where accepted by M6.5**

Launch deterministic media, expand, observe A, return compact, and assert the accepted compact media presentation remains coherent without starting a persistent production media observer. Combine UI evidence with existing runtime lifecycle unit/shipping evidence; do not attempt to inspect subprocess internals through UI.

- [ ] **Step 5: Run UI + presentation tests**

```bash
swift test --filter ShippingMediaPresentationModelTests
SOURCE_COMMIT="$(git rev-parse HEAD)" bash scripts/build-ui-test-app.sh
NOTCHHUB_UI_APP_PATH="$PWD/build/ui-test/NotchHub.app" \
  xcodebuild test -project NotchHubUITests.xcodeproj -scheme NotchHubUITests \
  -destination 'platform=macOS' -resultBundlePath build/NotchHub-MediaUI.xcresult
```

Expected: PASS.

- [ ] **Step 6: Map all accepted `MEDIA_UI_ACCEPTANCE` IDs and commit**

```bash
git add Sources/NotchHubApp/UITestSupport Tests/UITests Tests/NotchHubMediaCoreTests Tests/Acceptance
git commit -m "Test: cover accepted media UI journeys end to end"
```

---

### Task 8: Mark physical-only accepted cases honestly and keep M6.6 pending/rejected

**Files:**
- Modify: `Tests/Acceptance/coverage.yml`
- Modify: `docs/testing/*.md` only to clarify evidence classification, never to change accepted results.

**Interfaces:**
- Physical-only reasons must be specific strings such as:

```text
"Requires perception of physical Taptic Engine output on Mac16,8; automation verifies semantic haptic request only."
"Requires visual alignment against the physical MacBook notch hardware edge; virtual runner geometry cannot prove physical bezel alignment."
```

- [ ] **Step 1: Review every `physical` manifest layer**

Reject generic reasons such as `manual test`, `hardware`, or `hard to automate`.

- [ ] **Step 2: Split mixed cases when necessary**

If one acceptance ID combines deterministic behavior and physical feel, give it both automated and physical evidence rather than marking the whole case physical-only.

Example:

```yaml
coverage:
  - layer: integration
    test: NotchHubCoreTests.NotchInteractionCoordinatorTests.hoverExpansionRequestsExactlyOneHaptic
  - layer: physical
    test: target-mac:M1-hover-haptic-feel
physicalOnlyReason: "Physical layer verifies perceptibility only; semantic request is automated."
```

- [ ] **Step 3: Verify all M6.6 IDs remain pending/rejected**

No M6.6 case becomes `accepted` because of foundation tests. Their new tests may exist later after PR #33 rebases.

- [ ] **Step 4: Run audit and commit**

```bash
python3 scripts/test_acceptance_coverage.py --mode audit
```

Expected: the remaining accepted deterministic debt list is empty before moving to Task 9.

```bash
git add Tests/Acceptance docs/testing
git commit -m "Test: classify physical-only acceptance evidence honestly"
```

---

### Task 9: Switch acceptance coverage from audit to strict required CI

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `scripts/test-ui-automation-policy.py` or the existing CI policy test file.
- Modify: `Tests/Acceptance/coverage.yml`

**Interfaces:**
- Required CI command:

```bash
python3 scripts/test_acceptance_coverage.py --mode strict
```

- [ ] **Step 1: Write RED CI-policy assertion requiring strict mode**

The policy test must fail while CI still runs audit mode or omits the validator.

- [ ] **Step 2: Run strict mode locally before editing CI**

```bash
python3 scripts/test_acceptance_coverage.py --mode strict
```

Expected: PASS. If it fails, return to the owning earlier task; do not weaken strict mode.

- [ ] **Step 3: Add strict validation to required jobs**

Run strict coverage early in both:

```text
macOS 26 compatibility
macOS UI regression
```

It needs to run only once in `Build, test and package` if duplicate runtime is material, but protected branch must have at least one required job whose failure blocks merge. Prefer the `macOS UI regression` job as the primary owner and keep a lightweight schema/unit-policy check in the normal build job.

- [ ] **Step 4: Run local policy suite**

```bash
python3 -m unittest scripts/test_acceptance_coverage.py -v
python3 -m unittest scripts/test-ui-automation-policy.py -v
python3 scripts/test_acceptance_coverage.py --mode strict
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/ci.yml scripts Tests/Acceptance
git commit -m "CI: require complete acceptance regression traceability"
```

---

### Task 10: Full baseline verification and foundation PR readiness

**Files:**
- Modify: `docs/TESTING.md`
- Modify: `docs/PROJECT_STATE.md`
- Modify: `docs/ROADMAP.md`
- Modify: `CHANGELOG.md`
- No production behavior changes.

**Interfaces:**
- Produces merge-ready testing foundation PR and the only valid next action: merge foundation, then rebase/update PR #33 and run the new suite.

- [ ] **Step 1: Run every deterministic layer locally**

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
python3 scripts/test-ui-automation-policy.py --verify-shipping-app build/NotchHub.app
bash scripts/security-audit.sh
```

Expected: all commands PASS.

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

Expected: all three PASS without retry logic inside the suite.

- [ ] **Step 3: Update docs with exact status language**

Record:

```text
implemented -> tested -> accepted -> merged -> released
```

For the foundation before merge:

```text
Regression/UI foundation: implemented + automated-tested, merge pending.
Legacy M1/M6.1-M6.5 deterministic baseline: fully traceable + automated-green.
M6.6 PR #33: still physical FAIL / draft / not merged.
```

Do not call testing foundation `accepted` until its PR review/CI is complete and it is merged.

- [ ] **Step 4: Push and require all GitHub checks green**

Required checks include at least:

```text
macOS 26 compatibility
Build, test and package
macOS UI regression
```

Inspect `.xcresult` artifact on any UI failure; do not rerun blindly.

- [ ] **Step 5: Commit final docs**

```bash
git add docs CHANGELOG.md
git commit -m "Docs: close accepted regression baseline backfill"
```

- [ ] **Step 6: Merge gate**

Foundation PR may become ready only when:

```text
strict acceptance coverage PASS
all Swift/Python tests PASS
all XCUI tests PASS
shipping fixture leak check PASS
security/performance/release gates PASS
all required GitHub Actions PASS
```

After merge and green `main` CI, update/rebase PR #33 onto the merged foundation. Its hover/haptic/jump/direction problems must then be captured as new RED UI/integration tests before any M6.6 production repair.

---

## Plan completion gate

Plan 2 is complete only when every accepted deterministic M1 and M6.1-M6.5 acceptance ID has executable traceability, strict coverage validation is green and required in CI, the critical user journeys run through real XCUIAutomation, physical-only evidence is narrowly justified, and PR #33 remains unaccepted. No new product feature work is allowed before this foundation is merged into `main` and PR #33 is tested against it.
