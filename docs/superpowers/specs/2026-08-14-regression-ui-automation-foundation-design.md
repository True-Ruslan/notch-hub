# Regression and UI Automation Foundation Design

Status: APPROVED IN PRODUCT DIRECTION / WRITTEN SPEC PENDING REVIEW
Date: 2026-08-14
Target: NotchHub Personal Release on macOS 26.6 / Mac16,8
Scope: testing foundation and regression hardening before further M6.6 repair or any later feature work

## 1. Decision

NotchHub adopts a mandatory multi-layer regression strategy before feature development continues.

The selected approach is **Option A**:

- keep Swift Testing for deterministic unit and integration behavior;
- add native macOS **XCTest + XCUIAutomation** UI/E2E coverage;
- make the UI regression suite a required protected-branch CI gate;
- backfill executable automated coverage for all previously accepted deterministic behavior before continuing M6.6 repair or adding later features;
- require every future user-visible feature and every fixed user-visible bug to add the appropriate regression coverage before production code changes are accepted.

Repeated target-Mac failures proved that the current 333-test suite can remain green while real interaction is broken. A test is therefore not sufficient merely because it exercises a class; it must exercise the highest reliable layer at which the contract is observable.

PR #33 remains draft and physically unaccepted. Its current hover/haptic/jump/direction defects are not repaired until this foundation and the accepted baseline are established.

## 2. Branch and PR isolation

The testing foundation is implemented in a **separate PR from `main`**, not inside PR #33.

Required sequence:

1. Branch the foundation from the current stable `main`.
2. Build and merge the testing foundation independently.
3. Prove the accepted M1 and M6.1-M6.5 deterministic baseline against `main` semantics.
4. Update/rebase PR #33 onto the merged foundation.
5. Run the new regression suite against PR #33.
6. Treat any failure of previously accepted behavior as a regression RED.
7. Only then repair M6.6 one proven RED at a time.

This prevents an unaccepted feature branch from redefining the baseline it is supposed to preserve.

## 3. Goals

The foundation must provide:

1. Native XCTest/XCUIAutomation UI automation on macOS.
2. Reproducible CI execution on `macos-26`.
3. Exact application-build provenance for every UI run.
4. Stable accessibility identifiers for user-observable states and controls.
5. Deterministic media fixtures for CI interaction tests without a real third-party player.
6. Explicit separation between deterministic automation and genuinely physical-only acceptance.
7. Machine-checkable traceability from every stable acceptance ID to executable evidence.
8. Regression coverage for all previously accepted deterministic M1 and M6.1-M6.5 behavior before new product work resumes.
9. RED -> GREEN tests for every current M6.6 physical defect before implementation changes.
10. XCResult, screenshots, logs, and exact source SHA on UI failure.
11. Preservation of security, privacy, performance, Sandbox, Hardened Runtime, and event-driven constraints.

## 4. Non-goals

This foundation does not:

- declare M6.6 accepted or merge PR #33;
- add product features;
- change hover dwell, gesture thresholds, panel geometry, haptic semantics, seek behavior, or media transport merely to make tests easier;
- replace physical target-Mac acceptance;
- claim to measure physical Taptic Engine feel;
- add global input capture, Accessibility/Input Monitoring authority, CGEventTap, polling, display links, repeating watchdogs, or synthetic media keys;
- add third-party UI automation frameworks while XCUIAutomation is sufficient;
- use pixel-perfect screenshot snapshots as the initial correctness gate.

Screenshots are diagnostics. Stable accessibility state, geometry, commands, lifecycle, and user-observable outcomes are correctness assertions.

## 5. Testing layers

### 5.1 Swift Testing — pure deterministic behavior

Swift Testing remains the default for:

- geometry and pointer regions;
- presentation and transition state machines;
- stale generation/completion rejection;
- gesture threshold, hysteresis, axis arbitration, momentum, cancellation, and commit logic;
- semantic gesture-direction normalization;
- media capability/presentation normalization;
- seek identity and cancellation;
- process ownership and teardown;
- cache bounds;
- deterministic policy/security invariants.

Fakes are allowed only at true external boundaries. Tests must prefer observable production behavior over mock-call choreography.

### 5.2 Application integration/component tests

Integration tests exercise production components together where a process-level UI launch adds no useful signal.

Examples:

- pointer policy -> hover request -> media availability -> transition request;
- gesture session -> coordinator -> command boundary;
- transition coordinator -> panel model -> settled presentation callback;
- seek model -> transaction -> command boundary;
- application lifecycle -> runtime ownership;
- semantic haptic request -> injectable AppKit haptic seam.

Deterministic timing uses an injectable clock/scheduler rather than arbitrary sleeps.

### 5.3 XCTest + XCUIAutomation — real application interaction

XCUIAutomation is the Playwright-equivalent layer for NotchHub.

It launches a real macOS `.app` and exercises AppKit/SwiftUI composition, window geometry, hit testing, pointer movement, hover, scroll delivery, launch/relaunch, and presentation changes together.

The test bundle launches the exact selected build with `XCUIApplication(url:)`. Apple supports URL-based application launching on macOS, which avoids compiling a divergent second copy of NotchHub merely to host UI tests.

### 5.4 Shipping/policy/security/performance

Existing required coverage remains:

- production media probe/transport candidates;
- release/security/performance/media policy;
- warnings-as-errors;
- strict source/plist/shell validation;
- Sandbox-only entitlement;
- Hardened Runtime/signing;
- fixed pinned media boundary;
- shipping preflight;
- immutable historical baselines and active feature-size budgets;
- performance-harness smoke.

UI automation is additive and never replaces these gates.

### 5.5 Physical target-Mac acceptance

Manual acceptance is reserved for behavior automation cannot honestly prove:

- alignment to the physical notch;
- actual trackpad feel and edge ergonomics;
- physical haptic sensation;
- compositor smoothness/jank perception where deterministic geometry evidence is insufficient;
- actual macOS permission/trust surfaces;
- real third-party player behavior beyond deterministic fixture coverage;
- target-hardware energy/resource behavior.

Every physical-only entry requires an explicit reason. "Hard to automate" is not enough when XCUIAutomation can reliably observe the outcome.

## 6. Exact UI test project structure

Add exactly:

```text
NotchHubUITests.xcodeproj
Tests/UITests/
  NotchHubUIApplication.swift
  NotchHubUITestAssertions.swift
  NotchHubUITestDiagnostics.swift
  NotchHubPanelUITests.swift
  NotchHubHoverPeekUITests.swift
  NotchHubMediaGestureUITests.swift
  NotchHubSeekUITests.swift
  NotchHubLifecycleUITests.swift
```

Shared scheme name:

```text
NotchHubUITests
```

The Xcode project owns only the UI test bundle/scheme. It must not compile a duplicate production source tree.

CI builds NotchHub through the existing production path (`scripts/build-app.sh`) and passes the exact app path to the test process through:

```text
NOTCHHUB_UI_TEST_APP_PATH
```

The UI helper constructs:

```swift
XCUIApplication(url: URL(fileURLWithPath: appPath))
```

The UI test must verify `NHSourceCommit` in the application bundle before interaction begins.

## 7. Two application modes for UI tests

### 7.1 Shipping-composition smoke

Launch the normal production-composition app built through the current shipping path.

This suite verifies behavior that does not require a live media session:

- launch/termination;
- stable compact presentation;
- explicit expansion where available without media;
- accepted pointer-exit settlement;
- no stuck intermediate geometry;
- accessibility reachability;
- absence of unexpected permission prompts in normal launch;
- observable lifecycle invariants that do not require synthetic media.

It does not pretend an empty CI runner proves third-party media integration.

### 7.2 Deterministic fixture build

Add a UI-test-only build path:

```text
scripts/build-ui-test-app.sh
build/NotchHub-UITesting.app
```

This build compiles the same production sources with exactly one compile-time condition:

```text
NOTCHHUB_UI_TESTING
```

Fixture behavior is selectable only in that build through:

```text
--ui-test-fixture <fixture-name>
```

Personal/Release builds must not compile or honor this path.

The fixture may replace only nondeterministic external boundaries:

- media probe;
- persistent media runtime/transport;
- compact one-shot media command transport;
- haptic recorder when end-to-end semantic haptic verification is needed.

The following remain real production code in UI fixture runs:

- `NotchPanelController`;
- pointer/hover policy;
- transition coordinator;
- gesture coordinator/session;
- SwiftUI views;
- AppKit hosting/window code;
- seek ownership logic;
- accessibility and user interaction routing.

Initial deterministic media state:

```text
track A -> track B -> track C
previous = supported
next = supported
seek = supported
fixed duration + initial position
stable source identity + icon fixture
explicit no-session fixture
explicit unsupported-capability fixture
explicit track/source-switch fixture
```

No fixture requires network access.

## 8. Shipping-exclusion policy for test support

Release-policy tests must fail if any of these appear in a Personal/Release artifact:

- `NOTCHHUB_UI_TESTING` fixture implementation symbols/resources;
- `--ui-test-fixture` handling;
- deterministic media fixture data;
- test-only haptic diagnostic UI;
- any UI-test-only control endpoint.

UI-test support may not add a sensitive entitlement or runtime permission to NotchHub.

## 9. Accessibility regression contract

Freeze these initial identifiers:

```text
notch.surface.compact
notch.surface.peek
notch.surface.expanded
media.artwork
media.title
media.artist
media.playPause
media.previous
media.next
media.seek
media.sourceIcon
```

They must not depend on localized visible text.

UI tests primarily assert:

- existence/disappearance;
- frame/containment relationships;
- enabled/disabled state;
- accessible value where it represents a user-visible outcome;
- fixture track identity after a command;
- final stable panel endpoint after an interaction.

A hidden test-only accessibility diagnostic is permitted only for an otherwise non-observable semantic output such as haptic-request count, and only in the `NOTCHHUB_UI_TESTING` build.

## 10. Waiting and flake policy

UI tests must not use arbitrary sleeps for synchronization.

Allowed synchronization:

- `waitForExistence(timeout:)`;
- predicate expectations;
- application-state waits;
- stable frame/state predicates;
- deterministic fixture events.

A timeout is an upper bound, not a fixed delay.

Automatic assertion retries are prohibited. A rerun may be initiated manually only to diagnose suspected runner infrastructure; the original failure remains evidence until root cause is known.

No polling/watchdog loop may be added to production code to make UI tests pass.

## 11. Gesture semantics

Tests are expressed in terms of user motion and user outcome, never only raw event sign.

Frozen current product semantics:

- physical LEFT -> next track;
- physical RIGHT -> previous track;
- physical DOWN from compact -> expansion interaction;
- physical UP from expanded -> collapse interaction.

The lower-level normalizer receives parameterized Swift tests for both values of `NSEvent.isDirectionInvertedFromDevice` and representative positive/negative raw deltas.

XCUIAutomation verifies canonical synthetic horizontal/vertical scroll end to end against the deterministic fixture. Target-Mac acceptance still verifies real hardware direction under the user's actual macOS scrolling preference.

A future semantic direction change requires explicit product approval; tests may not be rewritten merely to match an accidental inversion.

## 12. Haptic evidence

Automated evidence must prove:

- exactly one semantic haptic request when the contract requires it;
- none for unsupported/cancelled paths;
- no double fire from hover/gesture arbitration;
- App composition wires semantic requests to the production AppKit haptic performer.

The fixture build may expose a test-only haptic request count to prove full wiring.

Physical acceptance separately proves that the haptic is actually perceptible/appropriate on Mac16,8. Automation never marks physical haptic feel as PASS.

## 13. Acceptance coverage manifest

Create exactly:

```text
Tests/Acceptance/coverage.yml
```

Every stable acceptance ID discovered under `docs/testing/*.md` must have exactly one manifest entry.

Schema:

```yaml
id: NH-...
source: docs/testing/...
status: accepted|pending|rejected
coverage:
  - layer: unit|integration|ui|policy|shipping|physical
    test: stable-test-identifier-or-command
physicalOnlyReason: optional-explicit-reason
```

Add validator:

```text
scripts/test-acceptance-coverage.py
```

It fails when:

- a documented acceptance ID is absent from the manifest;
- the manifest references an unknown ID;
- the same ID has conflicting entries;
- an accepted deterministic ID lacks automated executable evidence;
- a physical-only entry lacks a defensible reason;
- a referenced automated test/command no longer exists.

This is traceability, not a vanity line-coverage percentage.

## 14. Mandatory accepted-baseline backfill

Before M6.6 repair resumes, every previously accepted deterministic case from stable `main` must have executable coverage.

The inventory includes all stable acceptance IDs under `docs/testing/`, including contracts represented by:

- M1 notch geometry, hover, expansion/collapse, haptic, pointer exit;
- M6.1-M6.5 media transport, shipping composition, presentation, retained state, lifecycle, controls, and UI acceptance;
- `MEDIA_UI_ACCEPTANCE.md`;
- `MEDIA_BRIDGE_PROBE_ACCEPTANCE.md`;
- `PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`;
- `SHIPPING_MEDIA_COMPOSITION_ACCEPTANCE.md`;
- every other stable `NH-*` ID under `docs/testing/`.

Backfill is first validated against stable `main`, not PR #33.

Rules:

1. Preserve the accepted contract rather than current feature-branch behavior.
2. Add the missing test without changing production semantics.
3. If the accepted `main` implementation unexpectedly fails its own new regression test, preserve the RED and treat it as baseline technical debt that must be resolved before the baseline is declared closed.
4. Never weaken an acceptance ledger to make a newer implementation green without explicit product approval.

Baseline closure requires every accepted deterministic ID to have executable evidence and all required baseline CI to pass.

## 15. Initial UI journeys

The first UI suite must include these escaped-risk journeys.

### Panel/application

- launch -> stable compact;
- terminate/relaunch -> stable compact without stale state;
- explicit expansion -> exact expanded;
- accepted pointer exit -> exact compact;
- repeated cycles -> no stuck intermediate frame;
- interrupted interactive transition -> an allowed stable endpoint only.

### Hover/Peek

- compact + media -> hover dwell -> Peek only;
- hover alone never opens full Home/expanded;
- fast pointer pass -> no Peek;
- leave/re-enter within grace -> Peek retained;
- final leave -> compact;
- relaunch with pointer on notch -> accepted hover behavior;
- no-session hover -> no fabricated media Peek.

### Media gestures

- LEFT -> A to B;
- RIGHT -> B to A;
- unsupported direction -> no command/haptic;
- short/reversed gesture -> no command;
- one arm transition -> one haptic request;
- commit -> no second haptic;
- repeated gestures -> no direction inversion/stale accumulation.

### Vertical gestures

- DOWN tracks toward expanded and commits by accepted semantics;
- insufficient/cancelled DOWN -> exact compact;
- UP tracks toward compact and commits by accepted semantics;
- pointer/panel separation during either direction -> no intermediate stuck geometry;
- horizontal capture -> no simultaneous vertical movement;
- seek ownership -> panel gestures excluded.

### Seek/continuity

- supported seek commits once;
- unsupported seek cannot drag;
- track/source identity change cancels stale seek;
- cursor restores after commit, cancellation, source switch, resign-active, and teardown;
- repeated track changes do not flash Home or restore stale presentation.

### Lifecycle

- compact -> zero persistent adapter;
- Peek -> zero persistent adapter;
- expanded -> expected owned runtime only;
- compact again -> runtime released;
- Quit -> no owned adapter process.

If a process assertion is not reliable through XCUIAutomation, it remains a shipping/integration command test mapped to the same acceptance ID.

## 16. Current M6.6 defects become RED after baseline

After the foundation merges and PR #33 is updated onto it, convert each current physical symptom into a focused RED at the highest reliable layer:

1. hover does not reliably produce Peek/haptic;
2. presentation visibly jumps or reaches an invalid transient/stable state;
3. horizontal previous/next directions are reversed in the observed target session;
4. any remaining interactive expansion/collapse ownership failure.

No M6.6 implementation repair precedes its RED.

If CI UI automation cannot reproduce a hardware-specific symptom, require a deterministic lower-layer RED plus a focused physical gate documenting the remaining hardware uncertainty.

## 17. CI contract

Add an exact third required check:

```text
macOS UI regression
```

Run on `macos-26` with read-only repository permissions and pinned immutable actions.

The job must:

1. build the selected NotchHub app mode;
2. verify `NHSourceCommit` provenance;
3. run `xcodebuild test` with shared scheme `NotchHubUITests`;
4. write results to `build/ui-tests/NotchHubUITests.xcresult`;
5. preserve screenshots/logs on failure;
6. emit a compact machine-readable test summary;
7. fail on any assertion failure without automatic retry.

The existing `macOS 26 compatibility` and `Build, test and package` checks remain required.

Public PR CI remains secret-free and does not require Developer ID credentials.

## 18. Security and performance boundaries

The foundation may not widen runtime authority.

Preserve:

- App Sandbox-only;
- Hardened Runtime;
- fixed pinned media boundary;
- no global scroll monitor/event tap;
- no new sensitive permission;
- no network/telemetry/listening-history persistence;
- no polling or repeating runtime watchdog;
- no test-only branch in Personal/Release hot paths;
- immutable historical performance baselines.

Accessibility identifiers are static metadata, not periodic work.

Shared-runner UI timing may diagnose regressions but does not become the target-Mac CPU/RSS/energy acceptance threshold.

## 19. Analogue-reference policy

Before changing a nontrivial user-facing interaction architecture, inspect at least two relevant current open-source macOS implementations when public source exists.

Record:

- repository and inspected commit/ref;
- license;
- relevant files/patterns;
- what problem the analogue solves;
- what NotchHub adopts independently;
- what NotchHub rejects and why.

Boring Notch is already useful as a reference because its public code makes physical pan directions explicit (`left/right/up/down`) and separates hover, gesture progress, and haptic triggers. Its timeout-based scroll-end fallback is an example of a pattern NotchHub should not copy blindly because it conflicts with the project's stricter event-driven/resource policy.

No incompatible-license implementation is copied into NotchHub. Analogues inform design and edge-case discovery; NotchHub acceptance contracts and tests remain independent.

## 20. Development rule after foundation

Every future behavior change follows:

1. define/update acceptance ID;
2. choose the highest reliable automated layer;
3. add focused test first;
4. preserve RED evidence;
5. implement minimum GREEN;
6. run affected lower layers;
7. run full required CI including `macOS UI regression`;
8. run only genuinely physical acceptance manually;
9. mark accepted only when all applicable evidence passes;
10. merge accepted scope only;
11. release only from merged/release-qualified state.

A feature without appropriate automated coverage is incomplete. A regression in previously accepted behavior blocks the feature that introduced it.

## 21. Rollout order

### Phase A — isolated test infrastructure PR

From stable `main`:

- add `NotchHubUITests.xcodeproj` and shared scheme;
- add UI test scripts/helpers;
- add accessibility identifiers;
- add deterministic fixture build and shipping-exclusion checks;
- add `Tests/Acceptance/coverage.yml` and validator;
- add `macOS UI regression` CI job and diagnostics.

Production behavior remains unchanged except non-behavioral accessibility/testability seams.

### Phase B — accepted baseline backfill

Still independently of PR #33:

- inventory every stable acceptance ID;
- map existing evidence;
- add missing unit/integration/UI/shipping/policy tests;
- justify legitimate physical-only gates;
- obtain a fully green accepted baseline.

### Phase C — apply foundation to PR #33

Update/rebase PR #33 onto the merged foundation and run the complete suite. Failures of accepted cases are explicit regressions.

### Phase D — M6.6 RED -> GREEN repair

Convert current target failures to tests and repair one proven RED at a time. No unrelated feature expansion.

### Phase E — exact target-Mac acceptance

Freeze one exact CI-produced candidate only after every automated layer is green. Any physical FAIL returns to another RED -> GREEN cycle.

### Phase F — resume roadmap

Only after M6.6 is accepted and merged may P1 or later product work resume.

## 22. Definition of done

The foundation is complete only when:

- XCTest/XCUIAutomation runs reproducibly on macOS 26 CI;
- `macOS UI regression` is a required protected-branch check;
- UI failures preserve XCResult/screenshots/logs;
- deterministic fixture code is compile-time absent from Personal/Release artifacts;
- release-policy tests prove that absence;
- required stable accessibility identifiers exist;
- `Tests/Acceptance/coverage.yml` is machine-validated;
- every previously accepted deterministic stable ID has executable automated evidence;
- every physical-only gate has an explicit defensible reason;
- stable `main` baseline is green;
- no new permission, global input authority, polling, repeating watchdog, network, telemetry, or release trust-boundary regression exists.

Only then does M6.6 repair resume.

## 23. References

Apple native automation:

- https://developer.apple.com/documentation/xcuiautomation/xcuiapplication
- https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/init(bundleidentifier:)
- https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/init(url:)

Inspected analogue reference:

- `rantoniuk/TheBoredTeam-boring.notch`
- `boringNotch/extensions/PanGesture.swift`
- `boringNotch/ContentView.swift`

Reference patterns only; no analogue source is copied into NotchHub.
