# M1 Reliable Panel Transitions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace endpoint-only panel presentation with one deterministic, Apple-native transition lifecycle that restores smooth opening/closing while making interruption, haptic timing, accessibility, clipping, teardown, and repeated-cycle stability testable correctness properties.

**Architecture:** `NotchInteractionCoordinator` emits explicit interaction intents instead of mutating window/content state or haptics. `NotchPanelTransitionCoordinator` is the sole transition authority; it sequences content, haptic output, AppKit window geometry, and AppKit/Core Animation chrome through a narrow animation-driver boundary. Production interpolation belongs to AppKit/Core Animation; deterministic tests control fake completions directly.

**Tech Stack:** Swift 6, Swift Testing, AppKit (`NSPanel`, `NSAnimationContext`, `NSWorkspace`, `NSHapticFeedbackManager`), SwiftUI/`NSHostingView`, QuartzCore (`CABasicAnimation`, `CAMediaTimingFunction`), GitHub Actions.

## Global Constraints

- Primary hardware target: MacBook with hardware notch, macOS 26.6.
- Initial motion candidate: `0.20 s`, ease-in-out, approximately matching the accepted M0 feel.
- Dwell remains `120 ms`; compact activation inset remains `4 pt` unless target-Mac evidence justifies tuning.
- Haptic candidate remains `.levelChange`, but synchronization uses public AppKit `.default`, not `.now`.
- Exactly one haptic per newly accepted deliberate expansion; none for cancellation, retention, collapse, setup/programmatic transitions, stale completion, duplicate intent, policy change, or teardown.
- Hardware-notch compact surface remains opaque black. Compact/expanded corner-radius candidates remain `12 pt` / `22 pt`.
- Expanded content inset remains `compactFrame.height + 12 pt` for hardware notch and `20 pt` for fallback.
- AppKit is the sole outer clipping authority; no competing SwiftUI outer `clipShape`.
- All transition/UI mutation is `@MainActor`.
- No polling, repeating `Timer`, sleep loop, manual per-frame interpolation, `CADisplayLink`/`CVDisplayLink`, or unbounded animation/pointer history.
- No private API, `CGEventTap`, Accessibility/Input Monitoring permission, synthetic input, new entitlement, third-party runtime dependency, or new network/process/plugin surface.
- Existing Sandbox, Hardened Runtime, exact entitlements, system-library-only linkage, security gates, and P0 resource/size budgets are not weakened.
- Existing global input observation remains exactly `.mouseMoved`; local tracking is a separate measured M1 follow-up.
- If public AppKit/Core Animation cannot reverse smoothly on the target Mac without manual frame stepping or broader privileges, stop at the feasibility gate and return to design.

---

## File Map

**Create**

- `Sources/NotchHubCore/Notch/NotchInteractionIntent.swift` — interaction intent/cause/eligibility value.
- `Sources/NotchHubCore/Notch/NotchAnimationPolicy.swift` — pure policy plus accessibility provider.
- `Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift` — transition state machine and generation authority.
- `Sources/NotchHubCore/Notch/NotchPanelAnimationDriver.swift` — public AppKit/Core Animation driver.
- `Tests/NotchHubCoreTests/NotchAnimationPolicyTests.swift`
- `Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift`
- `Tests/NotchHubCoreTests/NotchPanelAnimationDriverTests.swift`

**Modify**

- `Sources/NotchHubCore/Notch/NotchInteractionCoordinator.swift`
- `Sources/NotchHubCore/Notch/NotchPanelModel.swift`
- `Sources/NotchHubCore/Notch/NotchPanelController.swift`
- `Sources/NotchHubCore/Notch/NotchHapticPerformer.swift`
- `Sources/NotchHubCore/UI/NotchHostingViewFactory.swift`
- `Sources/NotchHubCore/UI/NotchRootView.swift`
- `Tests/NotchHubCoreTests/NotchInteractionCoordinatorTests.swift`
- `Tests/NotchHubCoreTests/NotchPanelModelTests.swift`
- `Tests/NotchHubCoreTests/NotchHostingViewFactoryTests.swift`
- Source-of-truth docs listed in Task 8.

`AppDelegate.swift` already calls `panelController?.invalidate()` on termination and is not changed unless a concrete RED test proves its existing lifecycle insufficient.

---

### Task 1: Replace hidden model/haptic mutation with explicit interaction intents

**Files:**
- Create: `Sources/NotchHubCore/Notch/NotchInteractionIntent.swift`
- Modify: `Sources/NotchHubCore/Notch/NotchInteractionCoordinator.swift`
- Modify: `Tests/NotchHubCoreTests/NotchInteractionCoordinatorTests.swift`

**Produces:**

```swift
enum NotchInteractionCause: Equatable, Sendable {
    case deliberateHover
    case pointerExit
    case programmatic
}

struct NotchInteractionIntent: Equatable, Sendable {
    let desiredPresentation: NotchPresentation
    let cause: NotchInteractionCause
    let hapticEligible: Bool
}
```

New interaction surface:

```swift
init(
    scheduler: any NotchActivationScheduling,
    dwellSeconds: TimeInterval = NotchInteractionCoordinator.defaultDwellSeconds,
    emitIntent: @escaping @MainActor (NotchInteractionIntent) -> Void
)

func pointerMoved(
    to pointer: CGPoint,
    layout: NotchLayout,
    currentPresentation: NotchPresentation,
    allowActivation: Bool = true
)
```

- [ ] **Step 1: Write RED tests before production changes.** Replace model/haptic fixture assertions with an intent recorder. Required examples:

```swift
@Test
func deliberateHoverEmitsOneEligibleExpansionIntentAtThreshold() {
    let fixture = makeFixture()
    fixture.coordinator.pointerMoved(
        to: insideCompact,
        layout: layout,
        currentPresentation: .compact
    )
    fixture.scheduler.advance(by: 0.12)

    #expect(fixture.intents == [
        NotchInteractionIntent(
            desiredPresentation: .expanded,
            cause: .deliberateHover,
            hapticEligible: true
        )
    ])
}

@Test
func expandedPointerExitEmitsOneNonHapticCollapseIntent() {
    let fixture = makeFixture()
    fixture.coordinator.pointerMoved(
        to: outside,
        layout: layout,
        currentPresentation: .expanded
    )

    #expect(fixture.intents == [
        NotchInteractionIntent(
            desiredPresentation: .compact,
            cause: .pointerExit,
            hapticEligible: false
        )
    ])
}
```

Retain RED coverage for quick transit, setup synchronization, duplicate moves, cancelled stale callback, re-entry full dwell, expanded retention, and invalidation.

- [ ] **Step 2: Run RED.**

```bash
swift test --filter NotchInteractionCoordinatorTests
```

Expected: compile failure on the new intent/currentPresentation/initializer contract.

- [ ] **Step 3: Commit RED tests.**

```bash
git add Tests/NotchHubCoreTests/NotchInteractionCoordinatorTests.swift
git commit -m "test: define explicit notch interaction intents"
```

- [ ] **Step 4: Implement intent type and refactor coordinator.** Remove `NotchPanelModel` and `NotchHapticPerforming` dependencies. A valid dwell emits eligible expansion intent; expanded pointer exit emits non-haptic collapse intent. All cancellation/generation behavior remains local to the interaction coordinator.

- [ ] **Step 5: Run GREEN and source audit.**

```bash
swift test --filter NotchInteractionCoordinatorTests
python3 scripts/performance_policy.py audit Sources
```

Expected: PASS.

- [ ] **Step 6: Commit GREEN.**

```bash
git add Sources/NotchHubCore/Notch/NotchInteractionIntent.swift \
  Sources/NotchHubCore/Notch/NotchInteractionCoordinator.swift \
  Tests/NotchHubCoreTests/NotchInteractionCoordinatorTests.swift
git commit -m "refactor: emit explicit notch interaction intents"
```

---

### Task 2: Define animation policy and deterministic transition interfaces

**Files:**
- Create: `Sources/NotchHubCore/Notch/NotchAnimationPolicy.swift`
- Create: `Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift`
- Create: `Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift`
- Modify: `Sources/NotchHubCore/Notch/NotchPanelModel.swift`
- Modify: `Tests/NotchHubCoreTests/NotchPanelModelTests.swift`

**Produces:**

```swift
enum NotchAnimationTiming: Equatable, Sendable {
    case easeInOut
}

struct NotchAnimationPolicy: Equatable, Sendable {
    let duration: TimeInterval
    let timing: NotchAnimationTiming

    static let standard = NotchAnimationPolicy(duration: 0.20, timing: .easeInOut)
    static let reducedMotion = NotchAnimationPolicy(duration: 0, timing: .easeInOut)
}

enum NotchPanelTransitionPhase: Equatable, Sendable {
    case compact
    case expanding
    case expanded
    case collapsing
}

struct NotchPanelAnimationTarget: Equatable, Sendable {
    let frame: CGRect
    let cornerRadius: CGFloat
}

@MainActor
protocol NotchPanelAnimationHandle: AnyObject {
    func cancel()
}

@MainActor
protocol NotchPanelAnimationDriving: AnyObject {
    func animate(
        to target: NotchPanelAnimationTarget,
        policy: NotchAnimationPolicy,
        completion: @escaping @MainActor () -> Void
    ) -> any NotchPanelAnimationHandle
}

@MainActor
protocol NotchAnimationPolicyProviding: AnyObject {
    var currentPolicy: NotchAnimationPolicy { get }
}
```

Coordinator surface:

```swift
@MainActor
final class NotchPanelTransitionCoordinator {
    private(set) var phase: NotchPanelTransitionPhase
    private(set) var desiredPresentation: NotchPresentation

    init(
        model: NotchPanelModel,
        animationDriver: any NotchPanelAnimationDriving,
        animationPolicy: any NotchAnimationPolicyProviding,
        haptics: any NotchHapticPerforming,
        initialPresentation: NotchPresentation = .compact
    )

    func accept(_ intent: NotchInteractionIntent, layout: NotchLayout)
    func animationPolicyDidChange(layout: NotchLayout)
    func invalidate()
}
```

Model content-only surface:

```swift
@Published public private(set) var contentPresentation: NotchPresentation = .compact
func setContentPresentation(_ presentation: NotchPresentation)
```

- [ ] **Step 1: Write RED coordinator tests with a manual animation driver.** The fake records target/policy/completion and exposes `complete(index:)` even after its handle was cancelled so stale-callback safety is actually tested.

Required tests include normal expansion, collapse content retention, expansion->collapse reversal, collapse->expansion reversal, duplicate desired state, non-haptic programmatic expansion, invalidation in both directions, stale completion after cancellation, and idempotent invalidation.

Core assertions:

```swift
fixture.coordinator.accept(.deliberateExpansion, layout: layout)
#expect(fixture.coordinator.phase == .expanding)
#expect(fixture.model.contentPresentation == .expanded)
#expect(fixture.driver.requests.count == 1)
#expect(fixture.haptics.requestCount == 1)

fixture.driver.complete(index: 0)
#expect(fixture.coordinator.phase == .expanded)
```

Collapse must retain `.expanded` content until the matching completion.

- [ ] **Step 2: Run RED and commit tests.**

```bash
swift test --filter NotchPanelTransitionCoordinatorTests
```

Expected: compile failure because coordinator/driver/policy interfaces do not exist.

```bash
git add Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift
git commit -m "test: define deterministic notch transition lifecycle"
```

- [ ] **Step 3: Implement policy value types, transition interfaces, content-only model, and minimal coordinator.** Use one `UInt64 generation`, one active handle, and `isInvalidated`. Every replacement transition cancels the previous handle and increments generation; every completion validates `!isInvalidated`, generation equality, and expected desired presentation.

Expansion order:

```text
desired=expanded -> phase=expanding -> content=expanded
-> animate expanded target -> haptic if eligible -> valid completion -> phase=expanded
```

Collapse order:

```text
desired=compact -> phase=collapsing -> retain expanded content
-> animate compact target -> valid completion -> content=compact -> phase=compact
```

- [ ] **Step 4: Add deterministic 10,000-intent reversal stress.** Production coordinator must retain only current generation/handle/state; test fake may retain requests for assertions.

- [ ] **Step 5: Run GREEN.**

```bash
swift test --filter NotchPanelTransitionCoordinatorTests
swift test --filter NotchPanelModelTests
```

Expected: PASS.

- [ ] **Step 6: Commit GREEN.**

```bash
git add Sources/NotchHubCore/Notch/NotchAnimationPolicy.swift \
  Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift \
  Sources/NotchHubCore/Notch/NotchPanelModel.swift \
  Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift \
  Tests/NotchHubCoreTests/NotchPanelModelTests.swift
git commit -m "feat: add deterministic notch transition coordinator"
```

---

### Task 3: Observe macOS Reduce Motion without creating a second state machine

**Files:**
- Modify: `Sources/NotchHubCore/Notch/NotchAnimationPolicy.swift`
- Create: `Tests/NotchHubCoreTests/NotchAnimationPolicyTests.swift`
- Modify: `Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift`

**Produces:**

```swift
@MainActor
final class AppKitNotchAnimationPolicyProvider: NotchAnimationPolicyProviding {
    private(set) var currentPolicy: NotchAnimationPolicy
    var onPolicyChange: (@MainActor (NotchAnimationPolicy) -> Void)?

    init(
        notificationCenter: NotificationCenter,
        readReduceMotion: @escaping @MainActor () -> Bool
    )

    static func live() -> AppKitNotchAnimationPolicyProvider
    func invalidate()
}
```

`live()` uses `NSWorkspace.shared.notificationCenter`, observes `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification`, and reads `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`.

- [ ] **Step 1: Write RED policy/provider tests.** Assert standard `0.20/easeInOut`, reduced `0/easeInOut`, notification-driven changes only when the value changes, and no effect after `invalidate()`.

Use a private `NotificationCenter()` and mutable captured Bool; do not mutate real system accessibility settings in tests.

- [ ] **Step 2: Write RED coordinator policy-change tests.** During `.expanding` or `.collapsing`, `animationPolicyDidChange(layout:)` must replace generation and reissue the same desired target with the new policy, with zero additional haptic. At stable endpoints it performs no animation request.

- [ ] **Step 3: Run RED.**

```bash
swift test --filter NotchAnimationPolicyTests
swift test --filter NotchPanelTransitionCoordinatorTests
```

Expected: provider/policy-change behavior missing.

- [ ] **Step 4: Implement provider and policy-change handling.** One notification observer token; idempotent removal. No polling. Coordinator re-targets only when currently `.expanding`/`.collapsing`.

- [ ] **Step 5: Run GREEN + audit.**

```bash
swift test --filter NotchAnimationPolicyTests
swift test --filter NotchPanelTransitionCoordinatorTests
python3 scripts/performance_policy.py audit Sources
```

Expected: PASS.

- [ ] **Step 6: Commit.**

```bash
git add Sources/NotchHubCore/Notch/NotchAnimationPolicy.swift \
  Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift \
  Tests/NotchHubCoreTests/NotchAnimationPolicyTests.swift \
  Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift
git commit -m "feat: honor macOS reduce motion in notch transitions"
```

---

### Task 4: Build the public AppKit/Core Animation driver

**Files:**
- Create: `Sources/NotchHubCore/Notch/NotchPanelAnimationDriver.swift`
- Create: `Tests/NotchHubCoreTests/NotchPanelAnimationDriverTests.swift`
- Modify: `Sources/NotchHubCore/UI/NotchHostingViewFactory.swift`
- Modify: `Tests/NotchHubCoreTests/NotchHostingViewFactoryTests.swift`

**Implements:** `NotchPanelAnimationDriving`.

```swift
@MainActor
final class AppKitNotchPanelAnimationDriver: NotchPanelAnimationDriving {
    init(panel: NSPanel, chromeView: NSView)

    func animate(
        to target: NotchPanelAnimationTarget,
        policy: NotchAnimationPolicy,
        completion: @escaping @MainActor () -> Void
    ) -> any NotchPanelAnimationHandle
}
```

The returned handle gates callback delivery. Cancelling a handle does not claim to stop macOS compositor work; a later request re-targets the same system properties and coordinator generation is the correctness authority.

- [ ] **Step 1: Write RED real-AppKit boundary tests.** Deterministically assert only facts CI can prove: zero-duration path sets exact frame/radius and completes once; layer remains present with `masksToBounds` and continuous curve; 32 zero-duration compact/expanded endpoint cycles preserve frame/radius/autoresizing. Do not claim intermediate-pixel smoothness in CI.

- [ ] **Step 2: Run RED and commit tests.**

```bash
swift test --filter NotchPanelAnimationDriverTests
```

Expected: missing production driver.

```bash
git add Tests/NotchHubCoreTests/NotchPanelAnimationDriverTests.swift
git commit -m "test: define AppKit notch animation boundary"
```

- [ ] **Step 3: Implement zero-duration path.**

```swift
panel.setFrame(target.frame, display: true)
let layer = chromeView.layer!
layer.removeAnimation(forKey: "NotchHub.cornerRadius")
layer.cornerRadius = target.cornerRadius
if !handle.isCancelled { completion() }
```

- [ ] **Step 4: Implement animated geometry via `NSAnimationContext`.**

```swift
NSAnimationContext.runAnimationGroup { context in
    context.duration = policy.duration
    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    panel.animator().setFrame(target.frame, display: true)
} completionHandler: { [weak handle] in
    Task { @MainActor in
        guard let handle, !handle.isCancelled else { return }
        completion()
    }
}
```

The concrete handle is a small `@MainActor` class with `private(set) var isCancelled = false` and idempotent `cancel()`.

- [ ] **Step 5: Animate radius through Core Animation compositor.** Before replacing the radius animation, use current visible radius as source:

```swift
let layer = chromeView.layer!
let visibleRadius = layer.presentation()?.cornerRadius ?? layer.cornerRadius
layer.removeAnimation(forKey: "NotchHub.cornerRadius")
layer.cornerRadius = target.cornerRadius

let animation = CABasicAnimation(keyPath: "cornerRadius")
animation.fromValue = visibleRadius
animation.toValue = target.cornerRadius
animation.duration = policy.duration
animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
layer.add(animation, forKey: "NotchHub.cornerRadius")
```

No display link or manual frame loop is permitted.

- [ ] **Step 6: Keep hosting factory structural only.** It initializes layer-backed clipping, compact endpoint radius, and width/height autoresizing once; it no longer independently reacts to presentation changes.

- [ ] **Step 7: Run GREEN + security/performance checks.**

```bash
swift test --filter NotchPanelAnimationDriverTests
swift test --filter NotchHostingViewFactoryTests
python3 scripts/performance_policy.py audit Sources
./scripts/security-audit.sh
```

Expected: PASS.

- [ ] **Step 8: Commit.**

```bash
git add Sources/NotchHubCore/Notch/NotchPanelAnimationDriver.swift \
  Sources/NotchHubCore/UI/NotchHostingViewFactory.swift \
  Tests/NotchHubCoreTests/NotchPanelAnimationDriverTests.swift \
  Tests/NotchHubCoreTests/NotchHostingViewFactoryTests.swift
git commit -m "feat: add AppKit notch transition driver"
```

---

### Task 5: Integrate exactly one transition authority into the real panel

**Files:**
- Modify: `Sources/NotchHubCore/Notch/NotchPanelController.swift`
- Modify: `Sources/NotchHubCore/Notch/NotchPanelModel.swift`
- Modify: `Sources/NotchHubCore/Notch/NotchHapticPerformer.swift`
- Modify: `Sources/NotchHubCore/UI/NotchRootView.swift`
- Modify: relevant tests from Tasks 1–4.

**Controller ownership:** exactly one pointer monitor, interaction coordinator, transition coordinator, AppKit animation driver, and AppKit animation-policy provider.

- [ ] **Step 1: Add RED content-sequencing/model test.** Model exposes only explicit `contentPresentation`; transition tests remain responsible for proving prepare-before-growth and retain-until-collapse-completion.

- [ ] **Step 2: Switch `NotchRootView` from `model.presentation` to `model.contentPresentation`.** Preserve black compact surface and safe expanded inset. Do not add a SwiftUI animation for outer window geometry/radius.

- [ ] **Step 3: Change haptic output to public AppKit `.default`.**

```swift
NSHapticFeedbackManager.defaultPerformer.perform(
    .levelChange,
    performanceTime: .default
)
```

Only transition coordinator calls this performer.

- [ ] **Step 4: Recompose `NotchPanelController`.** Construction order: layout -> model -> panel/hosting view -> live policy provider -> AppKit driver -> transition coordinator -> interaction coordinator -> pointer monitor.

Interaction closure:

```swift
emitIntent: { [weak transitionCoordinator] intent in
    transitionCoordinator?.accept(intent, layout: resolvedLayout)
}
```

If `layout` later becomes mutable for screen migration, the controller closure must read `self.layout` weakly rather than freeze `resolvedLayout`; for this slice current layout remains stable by scope.

Remove model subscription, `bindModel()`, and controller-owned `apply(_:)` frame changes.

`show()` performs non-activating synchronization using `transitionCoordinator.desiredPresentation`.

- [ ] **Step 5: Wire accessibility callback with no retain cycle.** Provider callback captures controller weakly:

```swift
animationPolicyProvider.onPolicyChange = { [weak self] _ in
    guard let self else { return }
    self.transitionCoordinator.animationPolicyDidChange(layout: self.layout)
}
```

Transition coordinator may retain the provider for current-policy reads; provider must not strongly capture coordinator/controller.

- [ ] **Step 6: Make teardown idempotent.**

```swift
pointerMonitor.invalidate()
interactionCoordinator.invalidate()
transitionCoordinator.invalidate()
animationPolicyProvider.invalidate()
```

No later animation completion or accessibility notification may mutate content/chrome/haptic.

- [ ] **Step 7: Run all Swift tests.**

```bash
swift test --parallel
```

Expected: all existing geometry, hover, pointer, masking, interaction, and new transition tests PASS.

- [ ] **Step 8: Commit.**

```bash
git add Sources/NotchHubCore Tests/NotchHubCoreTests
git commit -m "refactor: centralize notch panel transition ownership"
```

---

### Task 6: Prove interruption semantics and enforce the real-hardware feasibility gate

**Files:**
- Modify: `Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift`
- Modify: `Tests/NotchHubCoreTests/NotchPanelAnimationDriverTests.swift`
- Modify production only for a concrete RED defect consistent with the approved design.

- [ ] **Step 1: Add RED exact-order tests.** Manual fixture records:

Expansion before completion:

```text
phase:expanding
content:expanded
animate:expanded
haptic
```

Valid expansion completion adds only `phase:expanded`.

Collapse before completion:

```text
phase:collapsing
animate:compact
```

Valid collapse completion adds:

```text
content:compact
phase:compact
```

Old expansion/collapse completions invoked after reversal must add nothing.

- [ ] **Step 2: Add rapid reversal and Reduce Motion replacement tests.** Include five alternating desired states and deliberate stale completions. Policy change while in-flight replaces generation and target without a second haptic.

- [ ] **Step 3: Run deterministic suites.**

```bash
swift test --filter NotchPanelTransitionCoordinatorTests
swift test --filter NotchPanelAnimationDriverTests
```

Expected: PASS.

- [ ] **Step 4: Push exact candidate and require full CI GREEN before hardware testing.** Required gates: macOS compatibility, Swift tests, release/performance policy, security, warnings-as-errors, Sandbox/Hardened Runtime/signature/system-linkage/DMG checks, unchanged size budget, harness smoke, DMG upload.

- [ ] **Step 5: Target-Mac normal transition acceptance.** On the exact CI artifact, perform at least 20 open/collapse cycles. Required PASS: `NH-TRANSITION-001`, `002`, `007`, `NH-VISUAL-001/002/003`.

- [ ] **Step 6: Target-Mac reversal acceptance.** At least 10 times each: leave during visible expansion; re-enter during visible collapse; rapid hover/leave changes. Required PASS: `NH-TRANSITION-003/004/005` with no snap/flicker/oscillation.

- [ ] **Step 7: Hard stop on feasibility failure.** If public AppKit window retargeting visibly snaps, record exact SHA/artifact/FAIL and return to design. Do not add timers, display links, manual interpolation, private APIs, broader permissions, or acceptance exceptions.

- [ ] **Step 8: Commit only RED-first test/fix changes produced by this task.**

```bash
git commit -m "test: harden notch transition interruption coverage"
```

---

### Task 7: Lock reliability, security, performance, and size regressions

**Files:**
- Modify transition/driver/performance tests only where concrete new regression coverage is required.
- Modify `scripts/performance_policy.py` and `scripts/test_performance_policy.py` only RED-first if a genuinely new forbidden primitive needs executable enforcement; never loosen existing rules.

- [ ] **Step 1: Preserve 32-cycle real-AppKit endpoint regression.** Every compact/expanded endpoint asserts exact frame, layer presence, `masksToBounds`, continuous curve, `12/22` radius, width/height tracking, and opaque compact policy.

- [ ] **Step 2: Add 100,000-intent bounded-state stress.** Production coordinator must not retain history proportional to events and must finish deterministically at latest desired state.

- [ ] **Step 3: Run full repository validation.**

```bash
swift format lint --recursive --strict --configuration .swift-format Sources Tests Package.swift
swift build -Xswiftc -warnings-as-errors
swift test --parallel --enable-code-coverage
(cd scripts && python3 -m unittest -v test_release_policy.py)
(cd scripts && python3 -m unittest -v test_performance_policy.py)
python3 scripts/performance_policy.py audit Sources
./scripts/security-audit.sh
```

Expected: all PASS.

- [ ] **Step 4: Enforce unchanged size budget through normal CI DMG build.** Compare against `performance/baseline-v0.1.0.json`. If over budget, reduce code/abstractions; do not widen P0 budget merely to fit M1.

- [ ] **Step 5: Rerun target-Mac idle and hover performance measurements on exact accepted candidate.** Use the same measurement contract as `PERFORMANCE.md`; verify no periodic idle work or sustained resource growth and compare CPU/RSS/thread results with accepted ceilings.

- [ ] **Step 6: Commit reliability hardening if files changed.**

```bash
git add Sources Tests scripts
git commit -m "test: lock reliable notch transition invariants"
```

Only stage paths actually changed.

---

### Task 8: Synchronize source of truth and finalize PR evidence

**Files:**
- Modify: `docs/superpowers/specs/2026-08-08-m1-reliable-panel-transitions-design.md`
- Modify: `docs/specs/M1_NOTCH_INTERACTION.md`
- Modify: `docs/PROJECT_STATE.md`
- Modify: `docs/ROADMAP.md`
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/TESTING.md`
- Modify: `CHANGELOG.md`
- Update PR #10 body/conversation after files are committed.

- [ ] **Step 1: Set written design status to `APPROVED` and record explicit final user approval dated 2026-08-08.** This is documentation state only; it must not be used as implementation evidence.

- [ ] **Step 2: Record each acceptance item separately.** For `NH-TRANSITION-001...007`, `NH-VISUAL-001/002/003`, `NH-HOVER-DELAY-001/002`, and `NH-HAPTIC-001/002`, record automated test, exact SHA/CI run, target-Mac result when required, and any still-tunable candidate value. Never infer hardware PASS from CI.

- [ ] **Step 3: Preserve future M1 scope honestly.** Local `NSTrackingArea` experiment, multi-display migration, Spaces/fullscreen, later visual polish, and gestures/click/pin remain separate unless independently completed with evidence.

- [ ] **Step 4: Commit documentation.**

```bash
git add docs CHANGELOG.md
git commit -m "docs: record reliable M1 transition evidence"
```

- [ ] **Step 5: Require final exact-head CI.** After this commit, do not create another source-of-truth commit merely to record its run number. Put final CI/artifact evidence in PR conversation so the tested SHA remains exact.

- [ ] **Step 6: Update PR #10 only after final evidence exists.** PR remains Draft until every transition gate required by this redesign is PASS. Body must state exact head SHA, CI run, DMG artifact, hardware results, size evidence, runtime performance evidence, and remaining M1 work.

---

## Definition of Done

1. Interaction layer emits explicit intents and no longer owns content/window/haptic transition output.
2. One transition coordinator owns phase, desired presentation, generation, content sequencing, haptic eligibility, and completion validation.
3. Explicit phases are `compact`, `expanding`, `expanded`, `collapsing`.
4. Expanded content is installed before growth and retained until valid collapse completion.
5. AppKit/Core Animation system interpolation coordinates frame and corner chrome without an application frame loop.
6. Normal opening/closing and both reversal directions are accepted on target hardware without snap/flicker.
7. Reduce Motion uses the same state machine, receives accessibility-display notifications, and adds no second haptic.
8. Haptic is public AppKit `.levelChange` at `.default`, exactly once per accepted deliberate expansion.
9. Compact black background, safe expanded controls, and rounded chrome remain correct through 32 automated endpoint cycles and 20+ real cycles.
10. Stale completions, cancellation, teardown, rapid reversal, duplicate intent, and policy changes cannot overwrite newer state.
11. No polling/repeating timer/display link/manual per-frame animation/private API/broader input or permission surface exists.
12. All Swift, release, security, performance, packaging/signing/Sandbox/Hardened Runtime/DMG checks pass on exact head.
13. P0 size budget is unchanged and passes.
14. Target-Mac runtime resource evidence remains within accepted policy or any deviation is explicitly reviewed.
15. Documentation distinguishes automated evidence from hardware evidence.
16. PR #10 stays Draft until all required gates are satisfied; only then may it become merge-ready.
