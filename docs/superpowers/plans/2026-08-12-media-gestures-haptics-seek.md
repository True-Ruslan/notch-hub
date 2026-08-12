# M6.6 Media Gestures, Haptics and Seek Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add local trackpad previous/next gestures, semantic haptics, vertical panel gestures and capability-gated draggable seek while preserving the accepted zero-persistent-adapter compact lifecycle and security/performance boundaries.

**Architecture:** Keep gesture recognition as a deterministic player-agnostic state machine in `NotchHubMediaCore`; adapt only local `NSHostingView.scrollWheel(with:)` events in the App/Core composition layer. Expanded Media uses its live `ShippingMediaRuntime`; compact gestures use bounded one-shot capability validation and one-shot typed commands without starting persistent observation. Panel expansion/collapse continues exclusively through `NotchPanelTransitionCoordinator`.

**Tech Stack:** Swift 6, AppKit, SwiftUI, Swift Testing, existing `NotchHubCore` / `NotchHubMediaCore`, existing fixed `/usr/bin/perl` MediaRemote compatibility boundary.

## Global Constraints

- Primary physical target: macOS `26.6` / `Mac16,8`.
- Follow `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md` and stable `NH-MEDIA-GESTURE-001...018` IDs.
- TDD for every behavior change: commit RED evidence before minimal GREEN production code.
- No global `.scrollWheel` monitor, `CGEventTap`, Accessibility, Input Monitoring, Automation, Screen Recording or synthetic media keys.
- No new network, telemetry, persistence, arbitrary executable/path/argument or player-specific fallback surface.
- App Sandbox-only and Hardened Runtime remain mandatory.
- `NotchPanelTransitionCoordinator` remains the sole panel-frame/presentation transition authority.
- Settled compact owns zero persistent media observation process.
- Compact gesture operations may use only bounded one-shot calls through the already pinned `/usr/bin/perl` + adapter/framework boundary.
- One-shot work must be teardown-owned so normal Quit cannot leave a child process.
- Expanded observation starts only after settled expansion and stops/releases after settled compact exactly as M6.4/M6.5 accepted.
- No polling, repeating timer, display link, sleep loop or busy loop for gestures/progress.
- Horizontal threshold: `clamp(0.28 * interactiveWidth, 70...120 pt)`; disarm hysteresis: `20 pt`.
- Vertical initial engineering threshold: `70 pt`, subject to one explicit target-Mac tuning pass before final acceptance.
- Horizontal command executes only on physical `.ended` while armed; momentum cannot arm or commit.
- Horizontal armed transition requests one public AppKit `.levelChange` haptic; staying armed and commit request no second haptic.
- Seek is actionable only when authoritative seek capability and trustworthy position/duration are present.

---

## File map

### New files

- `Sources/NotchHubMediaCore/MediaGestureCoordinator.swift` — pure deterministic gesture state machine and semantic effects; no AppKit/private transport.
- `Tests/NotchHubMediaCoreTests/MediaGestureCoordinatorTests.swift` — threshold, phase, momentum, hysteresis, capability, arbitration and seek-isolation tests.
- `Sources/NotchHubMediaCore/ShippingMediaCompactCommandDispatcher.swift` — validated one-shot capability + previous/next dispatcher for settled compact; never starts observation.
- `Tests/NotchHubMediaCoreTests/ShippingMediaCompactCommandDispatcherTests.swift` — bundle validation, capability gating, one-shot send and cancellation ownership.
- `Sources/NotchHubApp/MediaGestureSession.swift` — App-owned adapter between pure gesture effects, local events, haptic performer, panel intents and compact/expanded command paths.

### Modified files

- `Sources/NotchHubMediaCore/MediaRemoteProcessClient.swift` — own/cancel active one-shot operations on `stop()`/teardown.
- `Tests/NotchHubMediaCoreTests/MediaRemoteProcessClientTests.swift` and `MediaRemoteProcessTeardownTests.swift` — concurrent/in-flight one-shot cancellation and stale completion safety.
- `Sources/NotchHubMediaCore/ShippingMediaRuntime.swift` — add typed `seek(to:)` entry point; preserve existing command path.
- `Tests/NotchHubMediaCoreTests/ShippingMediaRuntimePresentationPolicyTests.swift` — prove M6.6 command surface stays typed and presentation-scoped.
- `Sources/NotchHubCore/UI/NotchHostingViewFactory.swift` — optional local scroll-wheel callback on the owned hosting view; no global monitor.
- `Tests/NotchHubCoreTests/NotchHostingViewFactoryTests.swift` — prove local callback ownership and unchanged hosting/frame behavior.
- `Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift` — add symmetric non-haptic programmatic collapse request beside existing programmatic expansion.
- `Sources/NotchHubCore/Notch/NotchPanelController.swift` — expose narrow public `requestExpansion()` / `requestCollapse()` methods that route through coordinator.
- `Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift` and `NotchPanelOwnershipTests.swift` — transition authority and no-direct-frame regression coverage.
- `Sources/NotchHubApp/MediaNotchRootView.swift` — visual horizontal tracking and capability-gated seek UI.
- `Sources/NotchHubApp/AppDelegate.swift` — own `MediaGestureSession` + compact dispatcher and route semantic effects without changing media observation lifecycle.
- `Tests/NotchHubCoreTests/MediaAppCompositionPolicyTests.swift` — fail-closed source-level rules: no global scroll monitor/synthetic keys; compact dispatcher and panel requests use approved seams.
- `CHANGELOG.md`, `docs/PROJECT_STATE.md`, `docs/ROADMAP.md`, `docs/TESTING.md` — exact implementation/CI/physical state only after evidence exists.

---

### Task 1: Own and cancel every one-shot media process

**Files:**
- Modify: `Sources/NotchHubMediaCore/MediaRemoteProcessClient.swift`
- Test: `Tests/NotchHubMediaCoreTests/MediaRemoteProcessClientTests.swift`
- Test: `Tests/NotchHubMediaCoreTests/MediaRemoteProcessTeardownTests.swift`

**Interfaces:**
- Existing consumer: `MediaRemoteProcessClient.send(_:) async -> MediaCommandResult`
- Existing consumer: `MediaRemoteProcessClient.capabilities() async throws -> MediaCommandCapabilities`
- Existing lifecycle: `MediaRemoteProcessClient.stop()`
- New invariant: `stop()` synchronously terminates/invalidates all owned observation and one-shot process handles; later termination/timeout callbacks cannot double-resume continuations.

- [ ] **Step 1: Write RED teardown tests**

Add fakes that leave `send` and `capabilities` processes running, call `stop()`, and assert each owned process receives bounded termination, no operation remains active, and a later fake termination callback is harmless. Add a two-concurrent-one-shot case to prove ownership is not a single optional slot.

- [ ] **Step 2: Run exact focused tests and preserve RED evidence**

Run in CI:

```bash
swift test --filter MediaRemoteProcessClientTests
swift test --filter MediaRemoteProcessTeardownTests
```

Expected RED: current `stop()` owns only `observationProcess`, so in-flight one-shot handles are not terminated by lifecycle teardown.

- [ ] **Step 3: Implement minimal owned one-shot registry**

Keep one-shot process handles in a MainActor-owned dictionary keyed by monotonically increasing operation ID. Each `MediaRemoteOneShotOperation` must remove itself exactly once on finish/timeout/cancellation. Add a cancellation path used by `stop()` that applies `MediaRemoteProcessTerminationPolicy.stop`, clears callbacks, and resumes its continuation once with a typed failure.

Do not change executable/path/argument construction or timeout bounds.

- [ ] **Step 4: Run focused + full suites**

```bash
swift test --filter MediaRemoteProcessClientTests
swift test --filter MediaRemoteProcessTeardownTests
swift test --parallel
python3 scripts/performance_policy.py audit Sources
```

Expected: GREEN with no new polling/runtime-policy finding.

- [ ] **Step 5: Commit**

```bash
git add Sources/NotchHubMediaCore/MediaRemoteProcessClient.swift Tests/NotchHubMediaCoreTests/MediaRemoteProcessClientTests.swift Tests/NotchHubMediaCoreTests/MediaRemoteProcessTeardownTests.swift
git commit -m "Fix: own media one-shot teardown"
```

---

### Task 2: Build the pure horizontal/vertical gesture state machine

**Files:**
- Create: `Sources/NotchHubMediaCore/MediaGestureCoordinator.swift`
- Create: `Tests/NotchHubMediaCoreTests/MediaGestureCoordinatorTests.swift`

**Interfaces:**

Define player-agnostic public gesture types so the App does not import private transport details:

```swift
public enum MediaGestureSurface: Sendable, Equatable {
    case compact
    case expanded
}

public enum MediaGesturePhase: Sendable, Equatable {
    case began
    case changed
    case ended
    case cancelled
}

public enum MediaGestureDirection: Sendable, Equatable {
    case previous
    case next
}

public struct MediaGestureSample: Sendable, Equatable {
    public let phase: MediaGesturePhase
    public let deltaX: Double
    public let deltaY: Double
    public let interactiveWidth: Double
    public let isMomentum: Bool
}

public enum MediaGestureCapability: Sendable, Equatable {
    case pending
    case supported
    case unavailable
}

public enum MediaGestureEffect: Sendable, Equatable {
    case requestCompactCapability(gestureID: UInt64, direction: MediaGestureDirection)
    case requestArmHaptic
    case commit(MediaGestureDirection)
    case requestExpansion
    case requestCollapse
    case visualOffset(Double)
    case resetVisualOffset
}

@MainActor
public final class MediaGestureCoordinator {
    public init()
    public func handle(
        _ sample: MediaGestureSample,
        surface: MediaGestureSurface,
        previous: MediaGestureCapability,
        next: MediaGestureCapability,
        seekActive: Bool
    ) -> [MediaGestureEffect]
    public func resolveCompactCapability(
        gestureID: UInt64,
        direction: MediaGestureDirection,
        supported: Bool
    ) -> [MediaGestureEffect]
    public func invalidate() -> [MediaGestureEffect]
}
```

Coordinator owns cumulative physical deltas, gesture generation, capture axis/direction, armed/disarmed state and latest validated compact capability. It does not execute commands or haptics.

- [ ] **Step 1: Write RED state-machine tests**

Cover `NH-MEDIA-GESTURE-002...012`: threshold clamp at 70/intermediate/120, short cancel, no command during changed, commit once on ended, cancellation, 20 pt disarm/re-arm, exactly-one haptic effect per arm transition, momentum rejection, diagonal rejection, horizontal/vertical arbitration, unsupported/unknown gating, late/stale compact capability resolution, compact down and expanded up.

Use only deterministic samples; no `NSEvent`, timers or sleeps.

- [ ] **Step 2: Run RED in CI**

```bash
swift test --filter MediaGestureCoordinatorTests
```

Expected RED: gesture types/coordinator do not exist.

- [ ] **Step 3: Implement minimum state machine**

Rules to encode exactly:

```text
idle -> tracking -> armed -> committed | cancelled
threshold = min(120, max(70, interactiveWidth * 0.28))
hysteresis disarm boundary = threshold - 20
vertical threshold = 70
```

Incremental deltas are accumulated only for non-momentum physical events. Capture horizontal only after clear X dominance; freeze captured direction for that physical gesture. Compact horizontal capture emits one capability request for its generation/direction; it cannot arm until matching supported resolution arrives. Expanded uses passed live capabilities. Ended while unarmed cancels. Momentum never starts/captures/arms/commits.

- [ ] **Step 4: GREEN full suite**

```bash
swift test --filter MediaGestureCoordinatorTests
swift test --parallel
```

- [ ] **Step 5: Commit**

```bash
git add Sources/NotchHubMediaCore/MediaGestureCoordinator.swift Tests/NotchHubMediaCoreTests/MediaGestureCoordinatorTests.swift
git commit -m "Feat: add deterministic media gesture engine"
```

---

### Task 3: Add local-only scroll delivery and panel gesture intents

**Files:**
- Modify: `Sources/NotchHubCore/UI/NotchHostingViewFactory.swift`
- Modify: `Tests/NotchHubCoreTests/NotchHostingViewFactoryTests.swift`
- Modify: `Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift`
- Modify: `Sources/NotchHubCore/Notch/NotchPanelController.swift`
- Modify: `Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift`
- Modify: `Tests/NotchHubCoreTests/NotchPanelOwnershipTests.swift`

**Interfaces:**

Extend only the custom-root factory overload:

```swift
public typealias NotchLocalScrollHandler = @MainActor (NSEvent) -> Void

public static func make<Root: View>(
    rootView: Root,
    onScrollWheel: NotchLocalScrollHandler? = nil
) -> NSView
```

The owned `NSHostingView` subclass overrides `scrollWheel(with:)`; if a handler exists it forwards that event locally, otherwise it calls `super`. No `NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel)` exists anywhere.

Add controller methods:

```swift
public func requestExpansion()
public func requestCollapse()
```

They call symmetric coordinator programmatic request methods with `layoutState.currentLayout`; both are non-haptic at panel-transition level because gesture-arm haptics are owned by M6.6 semantics.

- [ ] **Step 1: RED local-delivery/ownership tests**

Assert factory source owns local `scrollWheel(with:)`, no global scroll registration is added, and controller methods delegate to transition coordinator rather than calling `NSPanel.setFrame`.

- [ ] **Step 2: RED transition test**

Add deterministic programmatic collapse test symmetric to existing `requestProgrammaticExpansion`: one transition, no expansion haptic, standard stale-generation behavior.

- [ ] **Step 3: Implement minimal local seam and symmetric panel requests**

Do not alter existing `.mouseMoved` monitor behavior in this slice.

- [ ] **Step 4: Run Core tests**

```bash
swift test --filter NotchHostingViewFactoryTests
swift test --filter NotchPanelTransitionCoordinatorTests
swift test --filter NotchPanelOwnershipTests
swift test --parallel
```

- [ ] **Step 5: Commit**

```bash
git add Sources/NotchHubCore Tests/NotchHubCoreTests
git commit -m "Feat: add local media gesture input seam"
```

---

### Task 4: Add compact one-shot capability validation and command dispatch

**Files:**
- Create: `Sources/NotchHubMediaCore/ShippingMediaCompactCommandDispatcher.swift`
- Create: `Tests/NotchHubMediaCoreTests/ShippingMediaCompactCommandDispatcherTests.swift`
- Reuse: `Sources/NotchHubMediaCore/ShippingMediaRuntime.swift` bundle-path validation types without duplicating provenance policy.

**Interfaces:**

```swift
public enum ShippingMediaCompactAction: Sendable, Equatable {
    case previous
    case next
}

@MainActor
public final class ShippingMediaCompactCommandDispatcher {
    public init()
    public func isSupported(_ action: ShippingMediaCompactAction) async -> Bool
    @discardableResult
    public func send(_ action: ShippingMediaCompactAction) async -> Bool
    public func stop()
}
```

Production resolves the same pinned app resources/provenance as `ShippingMediaRuntime`, owns one `MediaRemoteProcessClient`, calls `capabilities()` only as a one-shot, maps only previous/next, and calls process-client `send` as a one-shot. It never calls `startObservation()`.

- [ ] **Step 1: RED dispatcher tests**

With an injected fake process client, prove:

- previous/next capability mapping is exact;
- unsupported/unknown/failure -> false;
- send maps only to `.previous` / `.next`;
- no observation start occurs;
- malformed/missing bundle resources fail closed;
- `stop()` cancels in-flight one-shots through Task 1 ownership.

- [ ] **Step 2: Run RED**

```bash
swift test --filter ShippingMediaCompactCommandDispatcherTests
```

- [ ] **Step 3: Implement minimal dispatcher**

Do not expose toggle, seek, arbitrary numeric media command or resource path as a compact public action.

- [ ] **Step 4: Full media suite + security policy**

```bash
swift test --filter ShippingMediaCompactCommandDispatcherTests
swift test --parallel
./scripts/security-audit.sh
python3 scripts/performance_policy.py audit Sources
```

- [ ] **Step 5: Commit**

```bash
git add Sources/NotchHubMediaCore/ShippingMediaCompactCommandDispatcher.swift Tests/NotchHubMediaCoreTests/ShippingMediaCompactCommandDispatcherTests.swift
git commit -m "Feat: add bounded compact media commands"
```

---

### Task 5: Wire local gestures and haptics into App composition

**Files:**
- Create: `Sources/NotchHubApp/MediaGestureSession.swift`
- Modify: `Sources/NotchHubApp/AppDelegate.swift`
- Modify: `Sources/NotchHubApp/MediaNotchRootView.swift`
- Modify: `Tests/NotchHubCoreTests/MediaAppCompositionPolicyTests.swift`

**Interfaces:**

`MediaGestureSession` owns one `MediaGestureCoordinator`, one `ShippingMediaCompactCommandDispatcher`, and semantic closures supplied by AppDelegate:

```swift
@MainActor
final class MediaGestureSession {
    var visualOffsetX: Double { get }
    var visualOffsetDidChange: (@MainActor (Double) -> Void)?

    func handle(
        event: NSEvent,
        surface: MediaGestureSurface,
        presentation: ShippingMediaPresentation?
    )
    func setSeekActive(_ active: Bool)
    func invalidate()
}
```

Effect mapping:

- `.requestCompactCapability` -> async `dispatcher.isSupported`; feed result back with matching gesture ID/direction;
- `.requestArmHaptic` -> `NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)` exactly once per effect;
- compact `.commit` -> one-shot dispatcher send;
- expanded `.commit` -> existing `ShippingMediaRuntime.goPrevious/goNext`;
- `.requestExpansion/.requestCollapse` -> new narrow `NotchPanelController` methods;
- visual offset -> UI-only offset; no authoritative media state mutation.

- [ ] **Step 1: RED source/composition policy**

Require App composition to provide local scroll handler, own/invalidate one gesture session, contain no global scroll mask, no synthetic key event, and no direct panel-frame calls.

- [ ] **Step 2: Implement local NSEvent mapping**

Accept only physical `event.phase` began/changed/ended/cancelled. Mark any non-empty `event.momentumPhase` as momentum. Use `scrollingDeltaX/Y` as incremental deltas and current content width as `interactiveWidth`.

- [ ] **Step 3: Add restrained visual tracking**

Compact: bias artwork/status only within the existing wing content; never move/cover the physical notch center. Expanded: offset the media card/content more visibly but clamp to the current interactive width. Reset on cancel/end/new authoritative presentation.

- [ ] **Step 4: Run composition/full suites**

```bash
swift test --filter MediaAppCompositionPolicyTests
swift test --parallel
swift format lint --recursive --strict --configuration .swift-format Sources Tools Tests Package.swift
```

- [ ] **Step 5: Commit**

```bash
git add Sources/NotchHubApp Tests/NotchHubCoreTests/MediaAppCompositionPolicyTests.swift
git commit -m "Feat: wire local media gestures and haptics"
```

---

### Task 6: Add capability-gated seek transaction

**Files:**
- Modify: `Sources/NotchHubMediaCore/ShippingMediaRuntime.swift`
- Modify: `Tests/NotchHubMediaCoreTests/ShippingMediaRuntimePresentationPolicyTests.swift`
- Modify: `Sources/NotchHubApp/MediaNotchRootView.swift`
- Modify: `Sources/NotchHubApp/MediaGestureSession.swift`
- Modify: `Tests/NotchHubCoreTests/MediaAppCompositionPolicyTests.swift`

**Interfaces:**

Add:

```swift
public func seek(to seconds: Double)
```

to `ShippingMediaRuntime`, mapped only to existing typed `.seek(seconds:)`.

In the view, maintain local seek preview only for the active drag. The authoritative `ShippingMediaPresentation.positionSeconds` is never overwritten.

- [ ] **Step 1: RED runtime typed-surface test**

Prove `seek(to:)` maps to `.seek(seconds:)` and does not expose raw adapter microseconds/arguments to App code.

- [ ] **Step 2: RED UI policy tests**

Require draggable control only when `presentation.canSeek`, position and duration are valid. Require seek interaction to call `setSeekActive(true)` on begin and `false` on every completion/cancel path.

- [ ] **Step 3: Implement seek preview/commit**

Use a SwiftUI drag on the progress control, clamp preview to `0...duration`, display preview while dragging, and call `seek(to:)` exactly once at successful drag end. Clear preview immediately after commit so failure naturally shows the unchanged authoritative position; later provider state confirms actual success. Cancellation clears preview without command.

- [ ] **Step 4: Prove seek isolation**

While `seekActive == true`, `MediaGestureCoordinator.handle` emits no horizontal/vertical gesture effect. Add deterministic regression test.

- [ ] **Step 5: Full suite and commit**

```bash
swift test --parallel
python3 scripts/performance_policy.py audit Sources
./scripts/security-audit.sh

git add Sources/NotchHubMediaCore Sources/NotchHubApp Tests
git commit -m "Feat: add capability-gated media seek"
```

---

### Task 7: Exact-head CI, size/security evidence and target-Mac candidate

**Files:**
- Modify only if deterministic size growth requires it: add a new M6.6 feature-size budget file rather than editing immutable P0 or historical M6.4/M6.5 budgets.
- Modify docs only after exact evidence exists.

- [ ] **Step 1: Run complete PR CI**

Required gates include macOS 26 compatibility, full Swift tests, warnings-as-errors, package/release/security/performance/media policy checks, DMG, Sandbox/Hardened Runtime/signature verification, shipping preflight, size policy and performance smoke.

- [ ] **Step 2: Handle size growth fail-closed**

If current M6.5 size envelope fails, first remove duplication/dead code. Only if remaining growth is necessary, add `performance/m6-6-media-gestures-size-budget.json` with measured minimal allowance over immutable `performance/baseline-v0.1.0.json`; do not widen CPU/RSS/thread budgets.

- [ ] **Step 3: Freeze exact candidate evidence**

Record source SHA, CI run, artifact IDs/digests, contained DMG SHA-256 and executable/app/DMG byte sizes in `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`.

- [ ] **Step 4: Run target-Mac `NH-MEDIA-GESTURE-001...018`**

Use the exact candidate. Explicitly record unsupported capabilities rather than emulating them. Include compact steady zero-process check and Quit-during-one-shot check.

- [ ] **Step 5: Update state only after physical PASS**

Update `CHANGELOG.md`, `docs/PROJECT_STATE.md`, `docs/ROADMAP.md`, `docs/TESTING.md`, architecture/security notes as necessary. Mark M6.6 accepted only after target-Mac evidence; then merge and verify post-merge `main` CI.

---

## Self-review

Spec coverage is complete for local compact/expanded horizontal gestures, vertical expand/collapse, threshold/hysteresis, momentum and diagonal rejection, capability gating, haptic semantics, seek isolation/transaction, zero-persistent-adapter compact behavior, teardown ownership, security constraints and hardware acceptance.

The only intentional design delta is the concrete compact capability mechanism: a bounded current-system one-shot capability query is required before compact arming because M6.5 retained compact state is intentionally not live-observed. This resolves the direct-compact-swipe requirement without weakening the accepted M6.4 zero-persistent-adapter lifecycle.

No global scroll capture, synthetic media keys, new permissions, polling, per-player integration, live compact observer or hidden release/version change is included.

## Execution choice

This repository/session has no independent subagent execution surface available. Execute this plan inline using `superpowers:executing-plans`, preserving RED -> GREEN evidence and review checkpoints task by task.
