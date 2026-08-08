# M1 Reliable Panel Transitions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace endpoint-only panel presentation with one deterministic, Apple-native transition lifecycle that restores smooth opening/closing while making interruption, haptic timing, accessibility, clipping, teardown, and repeated-cycle stability testable correctness properties.

**Architecture:** `NotchInteractionCoordinator` emits explicit interaction intents instead of directly mutating panel state or haptics. A new `NotchPanelTransitionCoordinator` becomes the only transition authority and sequences SwiftUI content, haptic output, AppKit window geometry, and AppKit/Core Animation chrome through a narrow `NotchPanelAnimationDriving` boundary. Production animation uses public AppKit/Core Animation only; tests use a manual animation driver and deterministic completions.

**Tech Stack:** Swift 6, Swift Testing, AppKit (`NSPanel`, `NSAnimationContext`, `NSWorkspace`, `NSHapticFeedbackManager`), SwiftUI/`NSHostingView`, QuartzCore (`CALayer`, `CABasicAnimation`, `CAMediaTimingFunction`), GitHub Actions.

## Global Constraints

- Primary hardware target: MacBook with hardware notch on macOS 26.6.
- Restore approximately the original accepted M0 motion character; initial duration candidate is `0.20 s` with normal ease-in-out timing.
- Keep dwell candidate at `120 ms` and compact activation inset candidate at `4 pt` unless target-Mac evidence justifies changing them.
- Keep haptic pattern candidate `.levelChange`; production synchronization changes from `.now` to public AppKit `.default`.
- Exactly one haptic is allowed for each newly accepted deliberate expansion intent; no haptic for transit cancellation, retention, collapse, setup/programmatic transitions, stale completions, teardown, or duplicate intent.
- Hardware-notch compact surface remains opaque black; the white indicator must sit on black rather than wallpaper.
- AppKit remains the single outer clipping authority; SwiftUI must not regain a competing outer `clipShape`.
- Compact corner-radius candidate remains `12 pt`; expanded candidate remains `22 pt`.
- Expanded content top inset remains `compactFrame.height + 12 pt` on a hardware-notch screen and `20 pt` on the fallback path.
- All UI/transition mutation is `@MainActor`.
- No polling, repeating `Timer`, sleep loop, manual per-frame interpolation, `CADisplayLink`/`CVDisplayLink`, or retained unbounded animation/pointer history.
- No private API, `CGEventTap`, Accessibility/Input Monitoring permission, synthetic input, network/process/plugin surface, new entitlement, or third-party runtime dependency.
- Existing App Sandbox, Hardened Runtime, exact entitlement set, system-library-only linkage, security checks, and P0 performance/size budgets are not weakened to make this implementation pass.
- Global input observation remains exactly the existing `.mouseMoved` boundary; local-tracking replacement is a separate measured M1 follow-up.
- If public AppKit/Core Animation cannot reverse the panel smoothly on target hardware without manual frame stepping or broader privileges, stop implementation at the feasibility gate and return to design review.
- A stateful UI change is not GREEN from endpoints alone: transition, interruption, cancellation, stale callbacks, repeated cycles, accessibility behavior, and teardown are mandatory test axes.

---

## File Structure

### New production files

- `Sources/NotchHubCore/Notch/NotchInteractionIntent.swift` — explicit desired-presentation/cause/haptic-eligibility value passed from interaction to transition authority.
- `Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift` — deterministic transition state machine, generation ownership, content sequencing, and haptic authority.
- `Sources/NotchHubCore/Notch/NotchPanelAnimationDriver.swift` — animation target/handle protocol plus the production `NSPanel` + AppKit/Core Animation driver.
- `Sources/NotchHubCore/Notch/NotchAnimationPolicy.swift` — pure animation policy and accessibility-preference observer/provider.

### Modified production files

- `Sources/NotchHubCore/Notch/NotchInteractionCoordinator.swift` — stop mutating `NotchPanelModel` and stop emitting haptics; emit intents instead.
- `Sources/NotchHubCore/Notch/NotchHapticPerformer.swift` — move synchronization to `.default`; remain a thin public AppKit output.
- `Sources/NotchHubCore/Notch/NotchPanelModel.swift` — represent content presentation only; remove hover/toggle authority from transition lifecycle.
- `Sources/NotchHubCore/Notch/NotchPanelController.swift` — composition only: pointer input -> intent -> transition coordinator; no independent frame transition logic.
- `Sources/NotchHubCore/UI/NotchHostingViewFactory.swift` — retain layer-backed clipping setup, expose endpoint chrome application only where needed by driver/tests, and never independently decide presentation.
- `Sources/NotchHubCore/UI/NotchRootView.swift` — read content presentation, preserving black compact background and expanded safe inset.
- `Sources/NotchHubCore/App/AppDelegate.swift` only if controller teardown needs an explicit final invalidation call beyond the current lifecycle.

### New tests

- `Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift` — pure coordinator/driver/haptic operation-order, reversal, stale completion, invalidation, and stress coverage.
- `Tests/NotchHubCoreTests/NotchAnimationPolicyTests.swift` — standard/reduce-motion policy and accessibility-notification lifecycle.
- `Tests/NotchHubCoreTests/NotchPanelAnimationDriverTests.swift` — real AppKit endpoint/transaction setup and repeated frame/chrome target coverage where deterministic CI can honestly assert state.

### Modified tests

- `Tests/NotchHubCoreTests/NotchInteractionCoordinatorTests.swift` — assert emitted intents instead of immediate model/haptic mutations.
- `Tests/NotchHubCoreTests/NotchPanelModelTests.swift` — content-presentation semantics only.
- `Tests/NotchHubCoreTests/NotchHostingViewFactoryTests.swift` — preserve masks/autoresizing/repeated-cycle regressions under the new ownership boundary.
- Existing geometry/pointer/performance tests remain regression gates.

---

### Task 1: Make interaction output explicit and remove hidden presentation authority

**Files:**
- Create: `Sources/NotchHubCore/Notch/NotchInteractionIntent.swift`
- Modify: `Sources/NotchHubCore/Notch/NotchInteractionCoordinator.swift`
- Modify: `Tests/NotchHubCoreTests/NotchInteractionCoordinatorTests.swift`

**Interfaces:**
- Produces:

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

- `NotchInteractionCoordinator` constructor becomes:

```swift
init(
    scheduler: any NotchActivationScheduling,
    dwellSeconds: TimeInterval = NotchInteractionCoordinator.defaultDwellSeconds,
    emitIntent: @escaping @MainActor (NotchInteractionIntent) -> Void
)
```

- Pointer input becomes:

```swift
func pointerMoved(
    to pointer: CGPoint,
    layout: NotchLayout,
    currentPresentation: NotchPresentation,
    allowActivation: Bool = true
)
```

- Task 2 consumes `NotchInteractionIntent` as its only interaction-to-transition input.

- [ ] **Step 1: Rewrite interaction tests first so the current implementation fails to compile**

Replace model/haptic assertions with an intent recorder. The key RED tests must include these exact contracts:

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
func expandedPointerExitEmitsNonHapticCollapseIntent() {
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

@Test
func setupSynchronizationNeverEmitsExpansionIntent() {
    let fixture = makeFixture()

    fixture.coordinator.pointerMoved(
        to: insideCompact,
        layout: layout,
        currentPresentation: .compact,
        allowActivation: false
    )
    fixture.scheduler.advance(by: 1, invokeCancelled: true)

    #expect(fixture.intents.isEmpty)
}
```

Retain equivalent RED coverage for quick transit, duplicate moves, stale cancelled callback, re-entry full dwell, invalidation, and expanded retention.

- [ ] **Step 2: Run only the interaction suite and record RED evidence**

Run:

```bash
swift test --filter NotchInteractionCoordinatorTests
```

Expected: compile failure because `NotchInteractionIntent`, `currentPresentation`, and the new initializer do not yet exist. Commit the RED tests before production changes.

- [ ] **Step 3: Add the explicit intent type**

Create `NotchInteractionIntent.swift` with exactly the types above. Keep them internal to `NotchHubCore` unless a test or public API genuinely requires broader visibility.

- [ ] **Step 4: Refactor `NotchInteractionCoordinator` to emit intents only**

Remove these dependencies entirely:

```swift
private let model: NotchPanelModel
private let haptics: any NotchHapticPerforming
```

Store `emitIntent`. On a valid dwell completion emit the eligible deliberate expansion intent. On pointer exit while `currentPresentation == .expanded`, emit the non-haptic collapse intent. Do not emit on expanded retention, setup synchronization, duplicate compact movement, cancelled dwell, stale callback, or invalidation.

The generation/cancellation logic remains the coordinator's responsibility.

- [ ] **Step 5: Run the interaction suite GREEN**

Run:

```bash
swift test --filter NotchInteractionCoordinatorTests
```

Expected: all interaction tests PASS with no wall-clock sleep.

- [ ] **Step 6: Run performance source audit before commit**

Run:

```bash
python3 scripts/performance_policy.py audit Sources
```

Expected: `Performance policy checks passed.`

- [ ] **Step 7: Commit Task 1**

```bash
git add Sources/NotchHubCore/Notch/NotchInteractionIntent.swift \
  Sources/NotchHubCore/Notch/NotchInteractionCoordinator.swift \
  Tests/NotchHubCoreTests/NotchInteractionCoordinatorTests.swift
git commit -m "refactor: emit explicit notch interaction intents"
```

---

### Task 2: Introduce the deterministic transition state machine

**Files:**
- Create: `Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift`
- Create: `Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift`
- Modify: `Sources/NotchHubCore/Notch/NotchPanelModel.swift`
- Modify: `Tests/NotchHubCoreTests/NotchPanelModelTests.swift`

**Interfaces:**
- Consumes: `NotchInteractionIntent` from Task 1.
- Produces:

```swift
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

- `NotchPanelTransitionCoordinator` public/internal surface:

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
    func invalidate()
}
```

- `NotchPanelModel` becomes content state only:

```swift
@Published public private(set) var contentPresentation: NotchPresentation = .compact
func setContentPresentation(_ presentation: NotchPresentation)
```

Remove `setHovered(_:)` and `toggle()` from production transition authority.

- [ ] **Step 1: Write RED state-machine tests with a manual driver**

Create a manual driver whose `animate` records `(target, policy, completion)` and whose test-only `complete(index:)` invokes any recorded completion even after the handle has been cancelled. This is required to prove stale callbacks are harmless.

Add at minimum:

```swift
@Test
func expansionSettlesOnlyAfterMatchingCompletion() {
    let fixture = makeTransitionFixture()

    fixture.coordinator.accept(.deliberateExpansion, layout: layout)

    #expect(fixture.coordinator.phase == .expanding)
    #expect(fixture.model.contentPresentation == .expanded)
    #expect(fixture.driver.requests.count == 1)
    #expect(fixture.haptics.requestCount == 1)

    fixture.driver.complete(index: 0)

    #expect(fixture.coordinator.phase == .expanded)
    #expect(fixture.coordinator.desiredPresentation == .expanded)
}

@Test
func collapseRetainsExpandedContentUntilValidCompletion() {
    let fixture = makeExpandedTransitionFixture()

    fixture.coordinator.accept(.pointerExitCollapse, layout: layout)

    #expect(fixture.coordinator.phase == .collapsing)
    #expect(fixture.model.contentPresentation == .expanded)

    fixture.driver.complete(index: 0)

    #expect(fixture.coordinator.phase == .compact)
    #expect(fixture.model.contentPresentation == .compact)
}
```

For test readability define local constants:

```swift
extension NotchInteractionIntent {
    static let deliberateExpansion = NotchInteractionIntent(
        desiredPresentation: .expanded,
        cause: .deliberateHover,
        hapticEligible: true
    )

    static let pointerExitCollapse = NotchInteractionIntent(
        desiredPresentation: .compact,
        cause: .pointerExit,
        hapticEligible: false
    )
}
```

Also add RED tests for:

- expansion completion after a reversal cannot settle expanded;
- collapse completion after a reversal cannot settle compact;
- five rapid alternating intents settle only according to the last generation;
- duplicate intent to the already desired endpoint produces no second animation request;
- only haptic-eligible expansion requests haptic;
- programmatic expansion with `hapticEligible == false` requests zero haptic;
- invalidation during each in-flight direction makes all later completions harmless;
- repeated `invalidate()` is idempotent.

- [ ] **Step 2: Run transition tests and record RED**

Run:

```bash
swift test --filter NotchPanelTransitionCoordinatorTests
```

Expected: compile failure because coordinator/driver/policy types do not yet exist.

- [ ] **Step 3: Implement minimal transition coordinator with generation validation**

Use one monotonically increasing `UInt64 generation`, one optional active animation handle, and `isInvalidated`.

Expansion sequencing must be exactly:

```text
accept intent -> generation++ -> desired=expanded -> phase=expanding
-> model.contentPresentation=expanded
-> driver.animate(expanded target)
-> if eligible, haptic exactly once
-> valid completion -> phase=expanded
```

Collapse sequencing must be exactly:

```text
accept intent -> generation++ -> desired=compact -> phase=collapsing
-> keep contentPresentation=expanded
-> driver.animate(compact target)
-> valid completion -> model.contentPresentation=compact -> phase=compact
```

Each completion captures its scheduled generation and checks:

```swift
guard !isInvalidated,
      generation == scheduledGeneration,
      desiredPresentation == expectedPresentation
else { return }
```

Every replacement transition cancels the prior handle before requesting the new animation. A cancelled handle is not trusted to suppress its callback; generation validation remains mandatory.

- [ ] **Step 4: Refactor `NotchPanelModel` to content-only semantics**

Use `contentPresentation` and `setContentPresentation(_:)`. Update `NotchRootView` references later in Task 5; for this task, update only tests/compilation dependencies needed for the coordinator.

- [ ] **Step 5: Run transition + model tests GREEN**

Run:

```bash
swift test --filter NotchPanelTransitionCoordinatorTests
swift test --filter NotchPanelModelTests
```

Expected: PASS.

- [ ] **Step 6: Add a deterministic rapid-reversal stress test**

Drive at least `10_000` alternating intents with manual completions deliberately invoked out of order. Assert bounded driver request bookkeeping used by the production coordinator itself: the coordinator retains only the current handle/generation and final desired state. The test fake may store requests for assertions; production state must not accumulate history.

- [ ] **Step 7: Commit Task 2**

```bash
git add Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift \
  Sources/NotchHubCore/Notch/NotchPanelModel.swift \
  Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift \
  Tests/NotchHubCoreTests/NotchPanelModelTests.swift
git commit -m "feat: add deterministic notch transition coordinator"
```

---

### Task 3: Add Apple accessibility-driven animation policy

**Files:**
- Create: `Sources/NotchHubCore/Notch/NotchAnimationPolicy.swift`
- Create: `Tests/NotchHubCoreTests/NotchAnimationPolicyTests.swift`

**Interfaces:**
- Produces:

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

- `live()` must use `NSWorkspace.shared.notificationCenter`, observe `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification`, and read `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`.

- [ ] **Step 1: Write RED pure-policy and notification tests**

Tests must prove:

```swift
@Test
func standardPolicyUsesTwoTenthsEaseInOut() {
    #expect(NotchAnimationPolicy.standard.duration == 0.20)
    #expect(NotchAnimationPolicy.standard.timing == .easeInOut)
}

@Test
func reduceMotionPolicyIsImmediateButKeepsSameStateMachineTimingKind() {
    #expect(NotchAnimationPolicy.reducedMotion.duration == 0)
    #expect(NotchAnimationPolicy.reducedMotion.timing == .easeInOut)
}
```

For notification behavior, use a private `NotificationCenter()` and mutable `reduceMotion` Bool captured by `readReduceMotion`. Post `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification`; assert policy changes exactly once to reduced motion, then back to standard. After `invalidate()`, further notifications must have no effect.

- [ ] **Step 2: Run RED**

```bash
swift test --filter NotchAnimationPolicyTests
```

Expected: compile failure because policy/provider do not exist.

- [ ] **Step 3: Implement policy and provider**

The observer must be a normal notification observer, not polling. Store one observer token; `invalidate()` removes it idempotently. The notification handler refreshes policy on `@MainActor` and calls `onPolicyChange` only when the value actually changed.

- [ ] **Step 4: Run GREEN and performance audit**

```bash
swift test --filter NotchAnimationPolicyTests
python3 scripts/performance_policy.py audit Sources
```

Expected: PASS and no forbidden runtime primitive.

- [ ] **Step 5: Commit Task 3**

```bash
git add Sources/NotchHubCore/Notch/NotchAnimationPolicy.swift \
  Tests/NotchHubCoreTests/NotchAnimationPolicyTests.swift
git commit -m "feat: honor macOS reduce motion for notch transitions"
```

---

### Task 4: Implement the public AppKit/Core Animation transition driver

**Files:**
- Create: `Sources/NotchHubCore/Notch/NotchPanelAnimationDriver.swift`
- Create: `Tests/NotchHubCoreTests/NotchPanelAnimationDriverTests.swift`
- Modify: `Sources/NotchHubCore/UI/NotchHostingViewFactory.swift`
- Modify: `Tests/NotchHubCoreTests/NotchHostingViewFactoryTests.swift`

**Interfaces:**
- Implements `NotchPanelAnimationDriving` from Task 2.
- Production initializer:

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

- The handle's `cancel()` suppresses delivery of its completion. Retargeting is accomplished by starting the next AppKit animation to the new target; coordinator generation remains the final authority.

- [ ] **Step 1: Write RED driver tests against real `NSPanel`/`NSHostingView` objects**

Add deterministic tests for the facts CI can honestly inspect:

1. duration `0` immediately sets exact frame and exact endpoint radius and invokes completion once;
2. handle cancellation before a zero-duration completion path prevents callback delivery;
3. every target preserves `wantsLayer`, `masksToBounds`, and `.continuous` corner curve;
4. 32 alternating zero-duration compact/expanded targets preserve exact endpoint radii and hosting bounds/autoresizing;
5. starting a second request cancels/supersedes callback authority only through handles/coordinator, never by retaining unbounded request state.

Do **not** write a CI assertion claiming subjective smoothness or exact intermediate pixels.

- [ ] **Step 2: Run RED**

```bash
swift test --filter NotchPanelAnimationDriverTests
```

Expected: compile failure because production driver does not exist.

- [ ] **Step 3: Implement the zero-duration path first**

For `policy.duration == 0`:

```swift
panel.setFrame(target.frame, display: true)
chromeLayer.removeAnimation(forKey: "NotchHub.cornerRadius")
chromeLayer.cornerRadius = target.cornerRadius
completionIfHandleIsActive()
```

This is the Reduce Motion path and deterministic test anchor.

- [ ] **Step 4: Implement the animated frame path with `NSAnimationContext`**

Use:

```swift
NSAnimationContext.runAnimationGroup { context in
    context.duration = policy.duration
    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    panel.animator().setFrame(target.frame, display: true)
} completionHandler: {
    // dispatch/enter MainActor if required by compiler; handle gate before callback
}
```

Do not use `setFrame(..., animate: true)` because duration/timing/completion ownership must remain explicit.

- [ ] **Step 5: Animate corner radius on the compositor without a frame loop**

At transition start:

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

This uses Core Animation compositor interpolation and no application-managed per-frame work. On retarget, `presentation()?.cornerRadius` is the new animation's source, preventing a radius snap in the chrome path.

- [ ] **Step 6: Keep factory ownership structural, not transitional**

`NotchHostingViewFactory.make(...)` still creates a layer-backed host with width/height autoresizing and `masksToBounds = true`; it may initialize compact endpoint radius once. It must not subscribe to model state or independently change radius after controller construction.

- [ ] **Step 7: Run driver/factory tests GREEN**

```bash
swift test --filter NotchPanelAnimationDriverTests
swift test --filter NotchHostingViewFactoryTests
```

Expected: PASS.

- [ ] **Step 8: Run source-policy/security checks before commit**

```bash
python3 scripts/performance_policy.py audit Sources
./scripts/security-audit.sh
```

Expected: both PASS. If the performance audit rejects Core Animation/AppKit code because of an actually forbidden primitive, fix the implementation; do not weaken the policy without a separate reviewed justification.

- [ ] **Step 9: Commit Task 4**

```bash
git add Sources/NotchHubCore/Notch/NotchPanelAnimationDriver.swift \
  Sources/NotchHubCore/UI/NotchHostingViewFactory.swift \
  Tests/NotchHubCoreTests/NotchPanelAnimationDriverTests.swift \
  Tests/NotchHubCoreTests/NotchHostingViewFactoryTests.swift
git commit -m "feat: add AppKit notch transition driver"
```

---

### Task 5: Integrate one transition authority into the real panel controller

**Files:**
- Modify: `Sources/NotchHubCore/Notch/NotchPanelController.swift`
- Modify: `Sources/NotchHubCore/Notch/NotchPanelModel.swift`
- Modify: `Sources/NotchHubCore/UI/NotchRootView.swift`
- Modify: `Sources/NotchHubCore/Notch/NotchHapticPerformer.swift`
- Modify: `Tests/NotchHubCoreTests/NotchPanelModelTests.swift`
- Modify: `Tests/NotchHubCoreTests/NotchInteractionCoordinatorTests.swift`

**Interfaces:**
- Controller owns exactly one each of:
  - `NotchPointerMonitor`
  - `NotchInteractionCoordinator`
  - `NotchPanelTransitionCoordinator`
  - `AppKitNotchPanelAnimationDriver`
  - `AppKitNotchAnimationPolicyProvider`
- Pointer events query `transitionCoordinator.desiredPresentation` and pass that as `currentPresentation` to interaction coordinator.
- Interaction coordinator's `emitIntent` closure calls `transitionCoordinator.accept(intent, layout: layout)`.
- `NotchPanelController` no longer subscribes to `model.$presentation` and no longer calls `panel.setFrame` from model changes.

- [ ] **Step 1: Add a RED integration-oriented model test**

The model must prove that content can be expanded while transition phase is still expanding and retained during collapse. Model tests themselves remain simple:

```swift
@Test
func contentPresentationChangesOnlyWhenExplicitlySet() {
    let model = NotchPanelModel()
    #expect(model.contentPresentation == .compact)

    model.setContentPresentation(.expanded)
    #expect(model.contentPresentation == .expanded)

    model.setContentPresentation(.compact)
    #expect(model.contentPresentation == .compact)
}
```

The transition coordinator tests from Task 2 remain the actual sequencing proof.

- [ ] **Step 2: Change `NotchRootView` to `contentPresentation`**

Replace all uses of `model.presentation` with `model.contentPresentation`. Preserve current opaque black background behavior and existing expanded safe inset. Do not add a SwiftUI animation modifier for outer panel geometry or outer corner radius.

- [ ] **Step 3: Move haptic synchronization to `.default`**

Production performer becomes:

```swift
NSHapticFeedbackManager.defaultPerformer.perform(
    .levelChange,
    performanceTime: .default
)
```

The transition coordinator is now the only caller. `NotchInteractionCoordinator` must have no haptic reference.

- [ ] **Step 4: Recompose `NotchPanelController`**

Construction order:

1. resolve `NotchLayout`;
2. construct content model;
3. construct `NSPanel` and hosting view;
4. construct live animation-policy provider;
5. construct AppKit animation driver with the real panel/hosting view;
6. construct transition coordinator;
7. construct interaction coordinator with an intent sink to the transition coordinator;
8. start pointer monitor.

Remove `bindModel()` and the current `apply(_ presentation:)` frame owner entirely.

`show()` still performs non-activating pointer synchronization:

```swift
interactionCoordinator.pointerMoved(
    to: NSEvent.mouseLocation,
    layout: layout,
    currentPresentation: transitionCoordinator.desiredPresentation,
    allowActivation: false
)
```

- [ ] **Step 5: Wire accessibility changes without a second state machine**

Set `animationPolicyProvider.onPolicyChange` so an in-flight transition may be re-targeted only through an explicit transition-coordinator method:

```swift
func animationPolicyDidChange(layout: NotchLayout)
```

This method increments generation and reissues the current desired target using the new policy if phase is `.expanding` or `.collapsing`; stable endpoints require no geometry animation. It must not emit haptic.

Add deterministic tests for this method to `NotchPanelTransitionCoordinatorTests` before implementing it.

- [ ] **Step 6: Make teardown complete and idempotent**

`NotchPanelController.invalidate()` must call, in safe order:

```swift
pointerMonitor.invalidate()
interactionCoordinator.invalidate()
transitionCoordinator.invalidate()
animationPolicyProvider.invalidate()
```

No later completion/notification may mutate model/chrome or haptic.

- [ ] **Step 7: Run all Swift tests**

```bash
swift test --parallel
```

Expected: all existing and new tests PASS. Any failure in `NH-HOVER-*`, geometry, pointer policy, or repeated masking is a regression and must be fixed before continuing.

- [ ] **Step 8: Commit Task 5**

```bash
git add Sources/NotchHubCore/Notch/NotchPanelController.swift \
  Sources/NotchHubCore/Notch/NotchPanelModel.swift \
  Sources/NotchHubCore/Notch/NotchHapticPerformer.swift \
  Sources/NotchHubCore/UI/NotchRootView.swift \
  Tests/NotchHubCoreTests/NotchPanelModelTests.swift \
  Tests/NotchHubCoreTests/NotchInteractionCoordinatorTests.swift \
  Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift
git commit -m "refactor: centralize notch panel transition ownership"
```

---

### Task 6: Prove interruption/reversal behavior and enforce the hard feasibility gate

**Files:**
- Modify: `Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift`
- Modify: `Tests/NotchHubCoreTests/NotchPanelAnimationDriverTests.swift`
- Modify production files only if a RED regression exposes a concrete defect in the agreed architecture.

**Interfaces:**
- Uses final coordinator/driver from Tasks 2–5.
- Produces exact candidate evidence for `NH-TRANSITION-001` through `NH-TRANSITION-007` before target-Mac testing.

- [ ] **Step 1: Add RED operation-order tests before any reversal fix**

The manual fixture must record events in an array. Exact expansion order:

```text
phase:expanding
content:expanded
animate:expanded
haptic
```

Valid completion appends:

```text
phase:expanded
```

Exact collapse order:

```text
phase:collapsing
animate:compact
```

Only valid completion may append:

```text
content:compact
phase:compact
```

Add a test that deliberately invokes old expansion completion after collapse request and old collapse completion after a new expansion request; neither may append any settlement event.

- [ ] **Step 2: Add deterministic Reduce Motion re-target tests**

During `.expanding`, change provider policy to reduced motion and call `animationPolicyDidChange(layout:)`. Assert generation replacement, no second haptic, and immediate settlement only through the newest completion/path.

- [ ] **Step 3: Run all deterministic transition tests**

```bash
swift test --filter NotchPanelTransitionCoordinatorTests
swift test --filter NotchPanelAnimationDriverTests
```

Expected: PASS.

- [ ] **Step 4: Push the candidate and require exact-head CI GREEN before hardware testing**

CI must complete:

- macOS compatibility;
- Swift tests;
- release-policy tests;
- performance-policy tests/audit;
- security baseline;
- warnings-as-errors;
- Sandbox/Hardened Runtime/signature/system-library/DMG checks;
- unchanged release size budget;
- performance harness smoke;
- DMG artifact upload.

Do not use a locally built unverified candidate for the feasibility decision if the exact source head has not passed CI.

- [ ] **Step 5: Target-Mac feasibility test — normal transitions**

On the exact CI artifact on macOS 26.6, perform at least 20 deliberate open/collapse cycles and record:

- `NH-TRANSITION-001`: opening is smooth and approximately matches original M0 feel;
- `NH-TRANSITION-002`: closing is smooth and controls do not disappear at start;
- `NH-TRANSITION-007`: corner shape evolves without a visible jump relative to frame motion;
- `NH-VISUAL-001/002/003`: black compact chrome, visible expanded controls, stable rounded corners.

- [ ] **Step 6: Target-Mac feasibility test — reversals**

Repeat at least 10 times each:

1. deliberately trigger expansion and move out during visible growth;
2. trigger expansion, allow it to settle, initiate collapse, then deliberately re-enter during visible shrink;
3. perform several rapid hover/leave changes.

Required:

- `NH-TRANSITION-003`: no snap when reversing expansion to collapse;
- `NH-TRANSITION-004`: no snap when reversing collapse to expansion;
- `NH-TRANSITION-005`: no flicker/oscillation; final visible state follows latest intent.

- [ ] **Step 7: Enforce the hard stop**

If any reversal visibly snaps because the public AppKit window animator cannot retarget from current visual progress, **do not** add timers, display links, manual interpolation, private APIs, or acceptance exceptions. Record the FAIL with exact SHA/artifact and return to design review.

Only proceed to Task 7 if the public-system-animation candidate passes this gate.

- [ ] **Step 8: Commit only evidence/test changes created during Task 6**

Use a commit message such as:

```bash
git commit -m "test: harden notch transition interruption coverage"
```

Do not commit target-Mac PASS claims until the exact candidate actually passed them.

---

### Task 7: Lock reliability, performance, security, and repeated-cycle regression coverage

**Files:**
- Modify: `Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift`
- Modify: `Tests/NotchHubCoreTests/NotchPanelAnimationDriverTests.swift`
- Modify: `Tests/NotchHubCoreTests/NotchPerformanceInvariantTests.swift` only if a bounded transition-state invariant belongs there.
- Modify: `scripts/performance_policy.py` / `scripts/test_performance_policy.py` only if a new forbidden primitive needs executable policy; do not loosen existing rules.

**Interfaces:**
- No new product API. This task converts the accepted architecture into durable regression gates.

- [ ] **Step 1: Add 32-cycle real AppKit endpoint regression**

For each cycle:

```text
compact endpoint -> expanded endpoint -> compact endpoint
```

Assert after every endpoint:

- exact expected frame;
- `wantsLayer == true`;
- `masksToBounds == true`;
- continuous curve;
- endpoint radius `22` expanded / `12` compact;
- hosting view follows width and height;
- compact background policy remains opaque.

- [ ] **Step 2: Add coordinator bounded-state stress**

Drive at least `100_000` desired-state updates using deterministic fake driver completions. Assert the coordinator retains no collection/history proportional to event count and final state is deterministic.

- [ ] **Step 3: Audit source for forbidden runtime animation mechanisms**

Run:

```bash
python3 scripts/performance_policy.py audit Sources
```

If the audit does not already reject any newly relevant manual animation primitives, add fail-closed policy tests **before** modifying the policy implementation. Required forbidden production patterns remain polling/repeating timer/sleep/display-link/manual-loop mechanisms; normal `NSAnimationContext`, `CABasicAnimation`, notifications, and one-shot dwell scheduling remain allowed.

- [ ] **Step 4: Run full local/CI-equivalent validation available in repository**

```bash
swift format lint --recursive --strict --configuration .swift-format Sources Tests Package.swift
swift build -Xswiftc -warnings-as-errors
swift test --parallel --enable-code-coverage
(cd scripts && python3 -m unittest -v test_release_policy.py)
(cd scripts && python3 -m unittest -v test_performance_policy.py)
python3 scripts/performance_policy.py audit Sources
./scripts/security-audit.sh
```

Expected: every command PASS.

- [ ] **Step 5: Check release sizes without widening baseline**

Use the normal CI DMG path and `scripts/performance_policy.py check-size-budget` against `performance/baseline-v0.1.0.json`. If executable/app/DMG exceeds the existing budget, reduce implementation cost or remove unnecessary abstractions. Do not change the accepted P0 budget merely to make M1 fit.

- [ ] **Step 6: Run target-Mac runtime measurements after transition acceptance**

Using the repository performance harness on the exact accepted candidate, rerun at least idle and hover scenarios with the same measurement contract used by `PERFORMANCE.md`. Compare CPU/RSS/thread behavior with accepted P0 ceilings and previous hover baseline. Transition animation must not introduce periodic idle work or sustained resource growth.

- [ ] **Step 7: Commit reliability hardening**

```bash
git add Tests scripts Sources
git commit -m "test: lock reliable notch transition invariants"
```

Only include `Sources`/`scripts` paths if RED-first changes were actually required.

---

### Task 8: Synchronize source of truth and prepare PR #10 for final acceptance

**Files:**
- Modify: `docs/superpowers/specs/2026-08-08-m1-reliable-panel-transitions-design.md`
- Modify: `docs/specs/M1_NOTCH_INTERACTION.md`
- Modify: `docs/PROJECT_STATE.md`
- Modify: `docs/ROADMAP.md`
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/TESTING.md`
- Modify: `CHANGELOG.md`
- Modify PR #10 body after files are committed.

**Interfaces:**
- No production API.
- Documentation must distinguish automated PASS, target-Mac PASS, candidate values, and still-pending M1 work.

- [ ] **Step 1: Mark this written design as fully approved**

Change the design status line to:

```markdown
Status: **APPROVED**
```

Record that the user explicitly approved the written spec on 2026-08-08 before implementation planning/execution.

- [ ] **Step 2: Record exact implementation and acceptance evidence**

For each of `NH-TRANSITION-001` through `NH-TRANSITION-007`, `NH-VISUAL-001/002/003`, `NH-HOVER-DELAY-001/002`, and `NH-HAPTIC-001/002`, record separately:

- automated test name/result;
- exact source SHA / CI run;
- target-Mac result when required;
- any candidate value still subject to tuning.

Do not mark a hardware item PASS from CI evidence alone.

- [ ] **Step 3: Preserve remaining M1 boundaries honestly**

Keep these as separate future M1 work unless already completed with evidence:

- measured local `NSTrackingArea`/window-local pointer experiment versus global `.mouseMoved` fallback;
- multi-display migration;
- Spaces/fullscreen behavior;
- broader animation polish beyond this correctness transition layer;
- gestures/click/pin policy.

- [ ] **Step 4: Run documentation/policy-sensitive CI on exact head**

Push documentation and require a final exact-head CI. Do not create another source-of-truth commit after the tested SHA; place final run/artifact evidence in PR conversation if necessary to preserve the exact tested head.

- [ ] **Step 5: Update PR #10 only after exact-head evidence exists**

PR remains Draft until all acceptance gates required by this transition redesign are PASS. The body must name the exact head SHA, CI run, DMG artifact, target-Mac results, size evidence, performance evidence, and any remaining M1 scope.

- [ ] **Step 6: Commit documentation**

```bash
git add docs CHANGELOG.md
git commit -m "docs: record reliable M1 transition evidence"
```

If this documentation commit becomes the new PR head, run exact-head CI once more and record final CI/artifact evidence in PR conversation rather than creating an endless evidence-only commit chain.

---

## Definition of Done

This redesign is complete only when all of the following are true:

1. `NotchInteractionCoordinator` no longer mutates panel content/window state or directly emits haptic; it emits explicit intents.
2. `NotchPanelTransitionCoordinator` is the sole transition authority with explicit `compact/expanding/expanded/collapsing`, desired presentation, generation validation, and idempotent invalidation.
3. Expanded content is prepared before growth and retained through collapse until valid completion.
4. Frame and corner chrome are submitted as one coordinated system transition; no independent SwiftUI outer-shape authority exists.
5. Normal opening/closing motion is restored and accepted on the target Mac.
6. Expansion->collapse and collapse->expansion interruption are smooth on the target Mac with no visible snap; otherwise implementation has returned to design instead of bypassing the gate.
7. Reduce Motion uses the same state machine with an immediate/reduced system-animation policy and observes AppKit accessibility-display changes.
8. Haptic remains public AppKit only, `.levelChange`, `.default`, exactly once per accepted deliberate expansion.
9. Compact black background, safe expanded content position, and rounded chrome remain correct after at least 32 automated endpoint cycles and 20 real hardware cycles.
10. Stale completions, cancelled work, teardown, rapid reversals, duplicate intents, and policy changes cannot mutate newer state incorrectly.
11. No polling, repeating timer, display link, manual per-frame animation, private API, broader input surface, new entitlement, network/process/plugin surface, or third-party runtime dependency exists.
12. All Swift, release-policy, performance-policy, security, package/signing/Sandbox/Hardened Runtime/DMG checks pass on the exact PR head.
13. Existing P0 size budget is unchanged and passes.
14. Target-Mac runtime resource evidence remains within accepted policy or any deviation is explicitly reviewed rather than hidden.
15. Source-of-truth documentation records exact automated and hardware evidence honestly.
16. PR #10 remains Draft until these gates are satisfied; only then may it become merge-ready.
