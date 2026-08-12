# Hover Peek Media Interaction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace direct hover-to-expanded behavior with a real `compact -> peek -> expanded` media interaction model, preserve compact zero-persistent-observation ownership, hide the cursor safely during seek, and remove the remaining media/UI blink defects before M6.6 physical acceptance.

**Architecture:** `peek` becomes a third authoritative `NotchPresentation` owned by the existing Core transition stack (`NotchPanelTransitionCoordinator` + `NotchPanelController`). Hover dwell remains Core-owned, while media eligibility/freshness is resolved in App/MediaCore through one bounded one-shot probe with generation-safe completion. Peek reuses the existing media gesture and seek machinery, but routes non-expanded commands through bounded one-shot transport paths; expanded alone owns the persistent media runtime.

**Tech Stack:** Swift 6 / Swift Package Manager, SwiftUI, AppKit, Combine, Swift Testing, existing NotchHubCore/NotchHubMediaCore process boundary, GitHub Actions.

## Global Constraints

- Target remains macOS 26.6 / Mac16,8 Personal Release.
- Stable presentation states are exactly `compact`, `peek`, `expanded`.
- Hover activation dwell remains exactly `120 ms`.
- Peek pointer-exit grace is exactly `140 ms`.
- Initial target Peek geometry is `360 x 96 pt`, top-anchored to the same physical-notch centerline as compact/expanded geometry.
- Physical LEFT -> next, RIGHT -> previous, DOWN -> expansion, expanded UP -> compact.
- Existing vertical semantic commit threshold remains `70 pt`.
- Hover may open Peek only; hover must never directly open full expanded UI.
- Compact click and Peek free-surface click may explicitly open expanded UI.
- Peek exists only for usable retained/fresh media; there is no generic/Home Peek.
- Peek supports horizontal media gestures and timeline seek, but no previous/next/play-pause buttons and no source-app icon.
- Settled compact and Peek own zero persistent `mediaremote-adapter.pl` observation.
- Persistent `ShippingMediaRuntime` starts only after authoritative settlement to `.expanded`.
- No polling, repeating timers, display links, sleep loops, per-scroll-event `Task {}`, global scroll monitor, `CGEventTap`, synthetic media keys, pointer warp/lock, network, telemetry, history persistence, or new sensitive permissions.
- Seek cursor hiding must use balanced AppKit ownership and restore on every commit/cancel/source/session/panel/app teardown path.
- Security remains App Sandbox-only + Hardened Runtime with the fixed pinned `/usr/bin/perl` media boundary.
- Historical size baselines/budgets remain immutable; any new size envelope requires a provenance-backed RED -> GREEN budget cycle.
- PR #33 remains draft and unmerged until exact-candidate CI and target-Mac physical acceptance pass.

---

## File Structure

### Core panel/state authority

- Modify `Sources/NotchHubCore/Notch/NotchPanelModel.swift` — add `.peek` to the public stable presentation enum.
- Modify `Sources/NotchHubCore/Notch/NotchGeometry.swift` — add authoritative `peekFrame` and preserve it through compact-wing layout derivation.
- Modify `Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift` — add stable Peek transitions while keeping direct compact<->expanded interactive gestures authoritative.
- Modify `Sources/NotchHubCore/Notch/NotchInteractionCoordinator.swift` — replace direct hover expansion with generation-safe hover-Peek request/resolve plus 140 ms Peek collapse grace.
- Modify `Sources/NotchHubCore/Notch/NotchPanelController.swift` — expose narrow hover-resolution/Peek-interaction APIs; keep all panel geometry ownership inside Core.

### Media freshness and bounded Peek ownership

- Create `Sources/NotchHubMediaCore/ShippingMediaPeekProbe.swift` — bounded one-shot current-media acquisition over the existing validated process/transport boundary.
- Modify `Sources/NotchHubMediaCore/ShippingMediaPresentationModel.swift` — extract/reuse deterministic projection and accept one-shot confirmed presentation/no-session results without persistence.
- Modify `Sources/NotchHubMediaCore/ShippingMediaCompactCommandDispatcher.swift` — add bounded seek support for Peek without persistent runtime.
- Modify `Sources/NotchHubMediaCore/MediaGestureCoordinator.swift` — add `.peek` surface semantics while preserving compact/expanded thresholds and directions.

### App composition/UI/ownership

- Create `Sources/NotchHubApp/MediaPeekSession.swift` — App-owned orchestration of hover request token, retained snapshot, one-shot refresh, stale-result rejection, and Peek request/collapse.
- Create `Sources/NotchHubApp/CursorVisibilityController.swift` — balanced `NSCursor.hide()/unhide()` ownership.
- Modify `Sources/NotchHubApp/MediaGestureSession.swift` — route Peek swipe/down/seek semantics, hold Peek collapse during active interaction, and use cursor ownership.
- Modify `Sources/NotchHubApp/MediaNotchRootView.swift` — render one-line Peek, expose free-surface click, share seek surface with Peek, and stop rebuilding media content on track identity changes.
- Modify `Sources/NotchHubApp/AppDelegate.swift` — compose Peek session/probe/cursor controller, route explicit expansion, and keep runtime lifecycle expanded-only.

### Tests and acceptance

- Modify `Tests/NotchHubCoreTests/NotchGeometryTests.swift`.
- Modify `Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift`.
- Modify `Tests/NotchHubCoreTests/NotchInteractionCoordinatorTests.swift`.
- Modify `Tests/NotchHubCoreTests/MediaGestureAppCompositionPolicyTests.swift`.
- Modify `Tests/NotchHubCoreTests/MediaSeekAppCompositionPolicyTests.swift`.
- Modify `Tests/NotchHubCoreTests/MediaInteractionContinuityCompositionPolicyTests.swift`.
- Create `Tests/NotchHubCoreTests/MediaPeekAppCompositionPolicyTests.swift`.
- Modify `Tests/NotchHubMediaCoreTests/MediaGestureCoordinatorTests.swift`.
- Create `Tests/NotchHubMediaCoreTests/ShippingMediaPeekProbeTests.swift`.
- Modify `Tests/NotchHubMediaCoreTests/ShippingMediaRuntimePresentationPolicyTests.swift`.
- Create `Tests/NotchHubCoreTests/CursorVisibilityControllerCompositionPolicyTests.swift`.
- Create `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`.
- Modify `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`, `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`, `docs/TESTING.md`, `docs/PROJECT_STATE.md`, `docs/ROADMAP.md`, and `CHANGELOG.md`.

---

### Task 1: Freeze the three-state panel and Peek geometry contract

**Files:**
- Modify: `Sources/NotchHubCore/Notch/NotchPanelModel.swift:3-16`
- Modify: `Sources/NotchHubCore/Notch/NotchGeometry.swift:3-70`
- Modify: `Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift:4-330`
- Test: `Tests/NotchHubCoreTests/NotchGeometryTests.swift`
- Test: `Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift`

**Interfaces:**
- Produces: `NotchPresentation.peek`, `NotchLayout.peekFrame`, `NotchPanelTransitionCoordinator.requestPeek(layout:)`.
- Preserves: `beginInteractiveTransition(from:.compact/.expanded)`, `70 pt` semantic gesture threshold, existing compact/expanded endpoint frames.

- [ ] **Step 1: Write failing geometry/state tests**

Add tests that assert the target geometry and stable state exist:

```swift
@Test
func hardwareNotchLayoutIncludesTopAnchoredPeekFrame() {
    let layout = NotchGeometry.layout(for: targetMacInput)

    #expect(layout.peekFrame.size == CGSize(width: 360, height: 96))
    #expect(layout.peekFrame.midX == layout.compactFrame.midX)
    #expect(layout.peekFrame.maxY == layout.compactFrame.maxY)
}

@Test
func compactWingExtensionDoesNotMutatePeekFrame() {
    let base = NotchGeometry.layout(for: targetMacInput)
    let extended = base.withCompactHorizontalExtension(36)

    #expect(extended.peekFrame == base.peekFrame)
}
```

Add transition tests for `compact -> peek`, `peek -> compact`, and `peek -> expanded` with stale completion rejection.

- [ ] **Step 2: Run focused tests and verify RED**

Run:

```bash
swift test --filter 'NotchGeometryTests|NotchPanelTransitionCoordinatorTests'
```

Expected: compile/test failure because `.peek`, `peekFrame`, and `requestPeek(layout:)` do not exist.

- [ ] **Step 3: Implement the minimal stable state and geometry**

Change the enum to:

```swift
public enum NotchPresentation: Equatable, Sendable {
    case compact
    case peek
    case expanded
}
```

Extend `NotchLayout` with `peekFrame`. In `NotchGeometry.layout`, calculate a top-anchored frame with target `360 x 96`, clamped so width never exceeds the screen minus the existing horizontal margin and never becomes narrower than the compact hardware width:

```swift
let maximumPeekWidth = max(compactWidth, input.frame.width - horizontalMargin * 2)
let resolvedPeekWidth = min(max(360, compactWidth), maximumPeekWidth)
let resolvedPeekHeight = max(96, compactHeight)
let peekFrame = CGRect(
    x: centerX - resolvedPeekWidth / 2,
    y: input.frame.maxY - resolvedPeekHeight,
    width: resolvedPeekWidth,
    height: resolvedPeekHeight
)
```

Preserve `peekFrame` unchanged in `withCompactHorizontalExtension`.

In the transition coordinator, add a stable `.peek` phase plus bounded endpoint phases for `compact <-> peek`; use an intermediate corner radius of `18`. `requestPeek(layout:)` is valid only from stable compact authority and calls the same animation driver/generation machinery as other endpoint transitions. Peek must not participate in `beginInteractiveTransition`; compact DOWN remains direct compact->expanded and expanded UP remains direct expanded->compact.

- [ ] **Step 4: Run focused tests and verify GREEN**

```bash
swift test --filter 'NotchGeometryTests|NotchPanelTransitionCoordinatorTests'
```

Expected: PASS, including stale-completion tests and all pre-existing compact/expanded transition tests.

- [ ] **Step 5: Commit**

```bash
git add Sources/NotchHubCore/Notch/NotchPanelModel.swift \
        Sources/NotchHubCore/Notch/NotchGeometry.swift \
        Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift \
        Tests/NotchHubCoreTests/NotchGeometryTests.swift \
        Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift
git commit -m 'feat: add authoritative notch peek state'
```

---

### Task 2: Replace hover expansion with tokenized Peek activation and 140 ms grace

**Files:**
- Modify: `Sources/NotchHubCore/Notch/NotchInteractionCoordinator.swift:1-110`
- Modify: `Sources/NotchHubCore/Notch/NotchPanelController.swift:20-270`
- Modify: `Sources/NotchHubCore/Notch/NotchPointerPolicy.swift`
- Test: `Tests/NotchHubCoreTests/NotchInteractionCoordinatorTests.swift`
- Test: `Tests/NotchHubCoreTests/NotchPointerPolicyTests.swift`

**Interfaces:**
- Produces public opaque value `NotchHoverPeekRequest: Equatable, Sendable`.
- Produces `NotchPanelController.hoverPeekRequestHandler`, `resolveHoverPeekRequest(_:mediaAvailable:)`, `setPeekInteractionHeld(_:)`, and `requestExpansion()` from Peek.
- Consumes `NotchPresentation.peek` and `requestPeek(layout:)` from Task 1.

- [ ] **Step 1: Write failing hover/grace tests**

Replace old “deliberate hover expands” expectations with tests for:

```swift
@Test
func hoverDwellEmitsOnePeekRequestAtExactly120Milliseconds() { ... }

@Test
func stalePositiveMediaResolutionAfterPointerExitCannotOpenPeek() { ... }

@Test
func noMediaResolutionLeavesCompactAndProducesNoActivation() { ... }

@Test
func peekExitDoesNotCollapseBefore140Milliseconds() { ... }

@Test
func peekReentryBefore140MillisecondsCancelsCollapse() { ... }

@Test
func heldPeekInteractionSuppressesCollapseUntilReleased() { ... }

@Test
func expandedPointerExitEmitsNoCollapseIntent() { ... }
```

Use the existing manual scheduler pattern; instantiate with `dwellSeconds: 0.12` and `peekCollapseGraceSeconds: 0.14`.

- [ ] **Step 2: Run focused tests and verify RED**

```bash
swift test --filter 'NotchInteractionCoordinatorTests|NotchPointerPolicyTests'
```

Expected: failures because hover still emits direct expansion and expanded pointer exit still collapses immediately.

- [ ] **Step 3: Implement generation-safe hover requests**

Introduce:

```swift
public struct NotchHoverPeekRequest: Equatable, Sendable {
    fileprivate let generation: UInt64
}
```

Change the interaction coordinator so the 120 ms dwell emits a request token rather than a transition intent. Track the latest pointer and request generation. Add:

```swift
func resolveHoverPeekRequest(
    _ request: NotchHoverPeekRequest,
    mediaAvailable: Bool,
    layout: NotchLayout,
    currentPresentation: NotchPresentation
) -> Bool
```

Return `true` only when the request generation is current, presentation is still `.compact`, the latest pointer is still inside the hover activation region, activation is not held by a gesture, and `mediaAvailable == true`. A stale/no-media result returns `false` and clears only its matching pending request.

For `.peek`, pointer exit schedules one cancellation-aware 140 ms collapse callback. Re-entry cancels it. `setPeekInteractionHeld(true)` cancels pending collapse; on `false`, reschedule only if the last pointer is still outside Peek. `.expanded` pointer exit does nothing.

- [ ] **Step 4: Wire the controller without giving App geometry authority**

Add controller API:

```swift
public var hoverPeekRequestHandler: (@MainActor @Sendable (NotchHoverPeekRequest) -> Void)?

public func resolveHoverPeekRequest(
    _ request: NotchHoverPeekRequest,
    mediaAvailable: Bool
)

public func setPeekInteractionHeld(_ held: Bool)
```

A successful resolution calls `transitionCoordinator.requestPeek(layout:)`; the successful transition is the only place that requests the existing hover expansion haptic. `requestExpansion()` must allow both compact->expanded and peek->expanded through transition authority.

- [ ] **Step 5: Run focused tests and verify GREEN**

```bash
swift test --filter 'NotchInteractionCoordinatorTests|NotchPointerPolicyTests|NotchPanelTransitionCoordinatorTests'
```

Expected: PASS; no hover path directly targets `.expanded`.

- [ ] **Step 6: Commit**

```bash
git add Sources/NotchHubCore/Notch/NotchInteractionCoordinator.swift \
        Sources/NotchHubCore/Notch/NotchPanelController.swift \
        Sources/NotchHubCore/Notch/NotchPointerPolicy.swift \
        Tests/NotchHubCoreTests/NotchInteractionCoordinatorTests.swift \
        Tests/NotchHubCoreTests/NotchPointerPolicyTests.swift
git commit -m 'feat: route hover through media peek grace'
```

---

### Task 3: Add bounded one-shot media freshness for cached and no-cache hover

**Files:**
- Create: `Sources/NotchHubMediaCore/ShippingMediaPeekProbe.swift`
- Modify: `Sources/NotchHubMediaCore/ShippingMediaPresentationModel.swift:1-170`
- Create: `Sources/NotchHubApp/MediaPeekSession.swift`
- Modify: `Sources/NotchHubApp/AppDelegate.swift:1-150`
- Create: `Tests/NotchHubMediaCoreTests/ShippingMediaPeekProbeTests.swift`
- Create: `Tests/NotchHubCoreTests/MediaPeekAppCompositionPolicyTests.swift`

**Interfaces:**
- Produces `ShippingMediaPeekProbe.Result = .presentation(ShippingMediaPresentation) | .noSession | .failed`.
- Produces `ShippingMediaPeekProbe.acquire(completion:)` and `cancel()`; every result/timeout/cancel stops the temporary transport.
- Produces `ShippingMediaPresentationModel.applyOneShotPresentation(_:)` and `clearAuthoritativePresentation()`.
- Produces App-owned `MediaPeekSession.handleHoverRequest(_:)`, `cancel()`, and `invalidate()`.

- [ ] **Step 1: Write failing MediaCore probe tests**

Use an injected fake `SystemMediaTransport` and manual one-shot scheduler. Freeze these cases:

```swift
@Test func sessionWithResolvedCapabilitiesReturnsPresentationAndStopsTransport() { ... }
@Test func noSessionReturnsNoSessionAndStopsTransport() { ... }
@Test func failureReturnsFailedAndStopsTransport() { ... }
@Test func timeoutReturnsFailedAndStopsTransport() { ... }
@Test func cancelMakesLateTransportEventHarmless() { ... }
@Test func firstUnknownCapabilitySnapshotCanBeReplacedByResolvedRevisionBeforeCompletion() { ... }
```

Set the internal bounded timeout to exactly `1.0 s`. This is an implementation timeout, not a repeating worker.

- [ ] **Step 2: Run probe tests and verify RED**

```bash
swift test --filter ShippingMediaPeekProbeTests
```

Expected: compile failure because the probe does not exist.

- [ ] **Step 3: Extract deterministic presentation projection**

Move the snapshot->`ShippingMediaPresentation` construction out of `ShippingMediaPresentationModel.apply` into an internal pure helper:

```swift
enum ShippingMediaPresentationProjection {
    static func make(
        state: MediaSubsystemState,
        snapshot: MediaSessionSnapshot?
    ) -> ShippingMediaPresentation?
}
```

Keep all normalization/session-identity semantics identical. `ShippingMediaPresentationModel.apply` delegates to it. Add narrow one-shot setters so the App can apply a confirmed probe result without disk persistence or a second model.

- [ ] **Step 4: Implement the one-shot probe over the existing validated boundary**

The production initializer resolves `ShippingMediaBundlePaths.resolveValidated`, creates `MediaRemoteSystemTransport`, and observes only until one terminal result. Ignore `.ready`. On `.session`, keep the latest snapshot; complete immediately once previous/next/seek capabilities are no longer all `.unknown`, otherwise allow a later revision until the 1.0 s timeout. On timeout with a usable session snapshot, return its projected presentation; otherwise `.failed`. `.noSession` is authoritative and completes immediately. Every finish path clears the handler and calls `stop()` exactly once.

Do not add polling, sleep loops, persistent observers, or per-event processes.

- [ ] **Step 5: Run MediaCore tests and verify GREEN**

```bash
swift test --filter 'ShippingMediaPeekProbeTests|ShippingMediaRuntimePresentationPolicyTests|ShippingMediaSourceIdentityPresentationTests'
```

Expected: PASS with existing normalization/session identity unchanged.

- [ ] **Step 6: Write failing App orchestration policy tests**

Freeze source-level/composition requirements:

- retained presentation causes immediate `resolveHoverPeekRequest(..., mediaAvailable: true)` before refresh completion;
- no retained presentation stays compact until a positive probe result;
- positive stale result cannot open after a newer hover request/cancel;
- `.noSession` clears cached presentation and resolves false/collapses Peek;
- `.failed` does not fabricate no-session or clear a valid cached presentation;
- one hover request starts at most one probe;
- returning to compact/invalidation cancels probe;
- no `Timer.scheduledTimer`, repeating Dispatch timer, display link, or polling loop appears in Peek files.

- [ ] **Step 7: Implement `MediaPeekSession` and compose it in `AppDelegate`**

`MediaPeekSession` stores the current hover request token and one probe generation. Pseudocode:

```swift
func handleHoverRequest(_ request: NotchHoverPeekRequest) {
    cancelProbeOnly()
    activeRequest = request

    if presentationModel.presentation != nil {
        panelController.resolveHoverPeekRequest(request, mediaAvailable: true)
    }

    probe.acquire { [weak self] result in
        self?.finishProbe(result, for: request)
    }
}
```

For `.presentation`, apply it to the shared presentation model and resolve true only for the current token. For `.noSession`, clear authoritative presentation and resolve false; if currently Peek, request collapse through Core. For `.failed`, preserve a cached presentation and do not fabricate loss. `cancel()/invalidate()` reject late results by generation and stop the probe.

`AppDelegate` sets `panelController.hoverPeekRequestHandler` to the session and keeps `updateMediaRuntime(for:)` expanded-only: `.expanded` starts runtime; `.compact` and `.peek` stop/keep runtime nil.

- [ ] **Step 8: Run App composition tests and verify GREEN**

```bash
swift test --filter 'MediaPeekAppCompositionPolicyTests|MediaAppCompositionPolicyTests'
```

Expected: PASS; no persistent runtime is created for Peek.

- [ ] **Step 9: Commit**

```bash
git add Sources/NotchHubMediaCore/ShippingMediaPeekProbe.swift \
        Sources/NotchHubMediaCore/ShippingMediaPresentationModel.swift \
        Sources/NotchHubApp/MediaPeekSession.swift \
        Sources/NotchHubApp/AppDelegate.swift \
        Tests/NotchHubMediaCoreTests/ShippingMediaPeekProbeTests.swift \
        Tests/NotchHubCoreTests/MediaPeekAppCompositionPolicyTests.swift
git commit -m 'feat: add bounded media freshness for hover peek'
```

---

### Task 4: Render interactive one-line Peek and preserve swipe/seek semantics

**Files:**
- Modify: `Sources/NotchHubMediaCore/MediaGestureCoordinator.swift:1-330`
- Modify: `Sources/NotchHubMediaCore/ShippingMediaCompactCommandDispatcher.swift:1-120`
- Modify: `Sources/NotchHubApp/MediaGestureSession.swift:1-360`
- Modify: `Sources/NotchHubApp/MediaNotchRootView.swift:1-330`
- Modify: `Sources/NotchHubApp/AppDelegate.swift`
- Test: `Tests/NotchHubMediaCoreTests/MediaGestureCoordinatorTests.swift`
- Test: `Tests/NotchHubCoreTests/MediaGestureAppCompositionPolicyTests.swift`
- Test: `Tests/NotchHubCoreTests/MediaSeekAppCompositionPolicyTests.swift`
- Test: `Tests/NotchHubCoreTests/MediaPeekAppCompositionPolicyTests.swift`

**Interfaces:**
- Adds `MediaGestureSurface.peek`.
- Extends bounded dispatcher with seek capability/command support.
- `MediaGestureSession.beginSeek()` accepts `.peek` and `.expanded`; Peek commits through bounded dispatcher, expanded commits through runtime.
- `MediaNotchRootView` gains `onExplicitExpansion` and a `.peek` rendering branch.

- [ ] **Step 1: Write failing gesture tests for Peek**

Add coordinator tests:

```swift
@Test func peekLeftArmsNextAndCommitsNext() { ... }
@Test func peekRightArmsPreviousAndCommitsPrevious() { ... }
@Test func peekDownAt70PointsRequestsExpansion() { ... }
@Test func peekUpDoesNotRequestCollapse() { ... }
@Test func peekHorizontalUsesBoundedCapabilityResolutionLikeCompact() { ... }
```

The horizontal threshold/hysteresis and one-arm-haptic semantics must be identical to compact.

- [ ] **Step 2: Run coordinator tests and verify RED**

```bash
swift test --filter MediaGestureCoordinatorTests
```

Expected: compile failure because `.peek` does not exist.

- [ ] **Step 3: Implement Peek semantic surface**

Add `.peek` to `MediaGestureSurface`. Treat `.compact` and `.peek` identically for bounded capability resolution and previous/next dispatch. For vertical commit, `.peek` only recognizes positive DOWN >= `70`; it emits `.requestExpansion`. It never emits `.requestCollapse`. Do not change axis dominance, direction signs, threshold ratios, momentum policy, or haptic effects.

- [ ] **Step 4: Extend bounded dispatcher for seek**

Add:

```swift
public func canSeek() async -> Bool
public func seek(to positionSeconds: Double) async -> Bool
```

`canSeek()` uses `client.capabilities().seek == .supported`. `seek(to:)` validates finite/non-negative input and sends `.seek(seconds:)`. Both retain existing generation/stop fail-closed behavior and never call `startObservation()`.

- [ ] **Step 5: Write failing App tests for input priority and Peek seek**

Freeze:

- beginning any Peek scroll gesture calls `panelController.setPeekInteractionHeld(true)` and end/cancel releases it;
- seek begins only with trustworthy timing/capability and outranks notch gestures;
- Peek seek does not require `ShippingMediaRuntime`;
- expanded seek still requires/uses runtime;
- Peek seek commit uses bounded dispatcher exactly once;
- source/session identity change cancels old seek before it can target a new track;
- `.requestExpansion` from Peek calls `panelController.requestExpansion()` only on semantic release;
- horizontal swipe while Peek never triggers hover collapse.

- [ ] **Step 6: Implement Peek routing in `MediaGestureSession`**

Map panel presentation to surface:

```swift
case .compact: activeSurface = .compact
case .peek: activeSurface = .peek
case .expanded: activeSurface = .expanded
```

For `.peek`, horizontal capability/commit uses the bounded dispatcher. DOWN commit calls `panelController.requestExpansion()`; ignore `.panelVisualOffset` for Peek because the approved design keeps Peek->expanded as a bounded endpoint transition, not a new interactive geometry path. Set/release Peek interaction hold around owned swipe/vertical/seek sessions.

- [ ] **Step 7: Implement the one-line Peek UI**

Add a `.peek` branch in `mediaContent`. Target layout inside the `360 x 96` frame:

```swift
VStack(spacing: 8) {
    HStack(spacing: 10) {
        artwork(presentation, size: 40)
        VStack(alignment: .leading, spacing: 2) {
            Text(presentation.title ?? "Playing")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Text(presentation.artist ?? "")
                .font(.caption)
                .lineLimit(1)
        }
        Spacer(minLength: 8)
        Image(systemName: presentation.playbackState == .playing ? "waveform" : "pause.fill")
    }
    seekProgress(...)
}
.padding(.horizontal, 14)
.padding(.top, 28)
.padding(.bottom, 10)
```

Do not add source icon or transport buttons. Put the seek surface above the free-surface expansion hit area; timeline drag must consume seek and must not trigger expansion. Free non-control Peek surface calls `onExplicitExpansion` exactly once. Compact no-media root also exposes explicit click-to-expand without creating a generic Peek.

`isSeekSurfaceAvailable` becomes true for `.peek` or `.expanded` when presentation timing/capability is trustworthy.

- [ ] **Step 8: Run focused App/Media tests and verify GREEN**

```bash
swift test --filter 'MediaGestureCoordinatorTests|MediaGestureAppCompositionPolicyTests|MediaSeekAppCompositionPolicyTests|MediaPeekAppCompositionPolicyTests'
```

Expected: PASS; existing LEFT/RIGHT, momentum, diagonal, seek-isolation regressions stay green.

- [ ] **Step 9: Commit**

```bash
git add Sources/NotchHubMediaCore/MediaGestureCoordinator.swift \
        Sources/NotchHubMediaCore/ShippingMediaCompactCommandDispatcher.swift \
        Sources/NotchHubApp/MediaGestureSession.swift \
        Sources/NotchHubApp/MediaNotchRootView.swift \
        Sources/NotchHubApp/AppDelegate.swift \
        Tests/NotchHubMediaCoreTests/MediaGestureCoordinatorTests.swift \
        Tests/NotchHubCoreTests/MediaGestureAppCompositionPolicyTests.swift \
        Tests/NotchHubCoreTests/MediaSeekAppCompositionPolicyTests.swift \
        Tests/NotchHubCoreTests/MediaPeekAppCompositionPolicyTests.swift
git commit -m 'feat: add interactive media peek surface'
```

---

### Task 5: Add balanced seek cursor visibility ownership

**Files:**
- Create: `Sources/NotchHubApp/CursorVisibilityController.swift`
- Modify: `Sources/NotchHubApp/MediaGestureSession.swift`
- Modify: `Sources/NotchHubApp/AppDelegate.swift`
- Create: `Tests/NotchHubCoreTests/CursorVisibilityControllerCompositionPolicyTests.swift`
- Modify: `Tests/NotchHubCoreTests/MediaSeekAppCompositionPolicyTests.swift`

**Interfaces:**
- Produces `CursorVisibilityController.acquireHiddenCursor()`, `releaseHiddenCursor()`, `invalidate()`.
- `MediaGestureSession` owns exactly one cursor lease per successful seek transaction.

- [ ] **Step 1: Write failing cursor ownership tests**

Use injected hide/unhide closures and assert:

```swift
@Test func repeatedAcquireHidesOnlyOnce() { ... }
@Test func repeatedReleaseUnhidesOnlyOnce() { ... }
@Test func invalidateRestoresHiddenCursor() { ... }
@Test func failedSeekBeginNeverHidesCursor() { ... }
@Test func seekCommitRestoresCursor() { ... }
@Test func seekCancelRestoresCursor() { ... }
@Test func sourceChangeRestoresCursor() { ... }
@Test func appTeardownRestoresCursor() { ... }
```

Add source-policy assertions that the new file contains `NSCursor.hide()` / `NSCursor.unhide()` but contains no `CGWarpMouseCursorPosition`, `CGAssociateMouseAndMouseCursorPosition`, event tap, relative mode, or cursor recenter loop.

- [ ] **Step 2: Run focused tests and verify RED**

```bash
swift test --filter 'CursorVisibilityControllerCompositionPolicyTests|MediaSeekAppCompositionPolicyTests'
```

Expected: failure because cursor ownership does not exist.

- [ ] **Step 3: Implement balanced cursor controller**

```swift
@MainActor
final class CursorVisibilityController {
    private let hide: @MainActor () -> Void
    private let unhide: @MainActor () -> Void
    private var ownsHiddenCursor = false

    func acquireHiddenCursor() {
        guard !ownsHiddenCursor else { return }
        ownsHiddenCursor = true
        hide()
    }

    func releaseHiddenCursor() {
        guard ownsHiddenCursor else { return }
        ownsHiddenCursor = false
        unhide()
    }

    func invalidate() {
        releaseHiddenCursor()
    }
}
```

Production closures are `NSCursor.hide` and `NSCursor.unhide`.

- [ ] **Step 4: Integrate with seek lifecycle**

Acquire only after `ShippingMediaSeekTransaction` is successfully created and the chosen `.peek` or `.expanded` execution path is valid. Centralize release inside `finishSeekIsolation()` so commit, cancel, source/session change, Peek collapse, transition, invalidation, runtime teardown and Quit all converge on one balanced release. Add `applicationDidResignActive` in `AppDelegate` to call `mediaGestureSession?.cancelSeek()`; this is a local lifecycle safety path, not global input capture.

- [ ] **Step 5: Run focused tests and verify GREEN**

```bash
swift test --filter 'CursorVisibilityControllerCompositionPolicyTests|MediaSeekAppCompositionPolicyTests|ShippingMediaSeekTransactionTests'
```

Expected: PASS; no pointer warp/lock API introduced.

- [ ] **Step 6: Commit**

```bash
git add Sources/NotchHubApp/CursorVisibilityController.swift \
        Sources/NotchHubApp/MediaGestureSession.swift \
        Sources/NotchHubApp/AppDelegate.swift \
        Tests/NotchHubCoreTests/CursorVisibilityControllerCompositionPolicyTests.swift \
        Tests/NotchHubCoreTests/MediaSeekAppCompositionPolicyTests.swift
git commit -m 'feat: hide cursor safely during media seek'
```

---

### Task 6: Remove track-switch and compact-DOWN blink at the state-source boundary

**Files:**
- Modify: `Sources/NotchHubMediaCore/MediaSessionController.swift:1-150`
- Modify: `Sources/NotchHubMediaCore/ShippingMediaRuntime.swift:120-220`
- Modify: `Sources/NotchHubApp/MediaNotchRootView.swift:50-120`
- Test: `Tests/NotchHubMediaCoreTests/MediaSessionControllerTests.swift`
- Test: `Tests/NotchHubMediaCoreTests/ShippingMediaRuntimePresentationPolicyTests.swift`
- Modify: `Tests/NotchHubCoreTests/MediaInteractionContinuityCompositionPolicyTests.swift`

**Interfaces:**
- Adds internal `MediaSessionChangeKind` (`ready`, `session`, `noSession`, `unavailable`) so Shipping runtime can distinguish transport readiness from authoritative media loss.
- Preserves the public `ShippingMediaRuntime` API.

- [ ] **Step 1: Write failing controller/runtime continuity tests**

Freeze the root cause explicitly:

```swift
@Test
func readyBeforeFirstSessionDoesNotClearRetainedPresentation() { ... }

@Test
func authoritativeNoSessionAfterReadyStillClearsRetainedPresentation() { ... }

@Test
func trackRevisionUpdatesExistingPresentationWithoutNilIntermediate() { ... }
```

The second test is essential: simply ignoring `.idle` is invalid because real no-session must still clear.

- [ ] **Step 2: Run MediaCore continuity tests and verify RED**

```bash
swift test --filter 'MediaSessionControllerTests|ShippingMediaRuntimePresentationPolicyTests'
```

Expected: current runtime clears retained presentation on `.ready` because both readiness and no-session collapse to `.idle/nil`.

- [ ] **Step 3: Add explicit change reason without changing public controller state semantics**

Inside `MediaSessionController`, track:

```swift
enum MediaSessionChangeKind {
    case ready
    case session
    case noSession
    case unavailable
}

private(set) var lastChangeKind: MediaSessionChangeKind = .unavailable
```

Set the kind before each publish. Make `.noSession` force one change callback even when `.ready` already published `.idle/nil`, so consumers can distinguish an authoritative no-session from readiness. Existing `state`/`snapshot` behavior remains compatible with current tests.

- [ ] **Step 4: Make Shipping runtime retain media across readiness only**

In `ShippingMediaRuntime` change handler:

```swift
switch controller.lastChangeKind {
case .ready:
    break
case .session:
    presentationModel.apply(state: controller.state, snapshot: controller.snapshot)
case .noSession, .unavailable:
    presentationModel.clear()
}
```

Do not clear retained media just because a newly started expanded runtime reports transport readiness before its first authoritative session/no-session event.

- [ ] **Step 5: Stop SwiftUI media branch recreation on track identity changes**

Remove:

```swift
.id(presentation.sessionIdentity)
```

from the media branch. Keep a stable media view identity while a non-nil presentation exists. Animate only actual media-present vs media-absent branch changes; track/source revisions update fields in place. Retain session identity for seek cancellation, not SwiftUI view identity.

- [ ] **Step 6: Run continuity tests and verify GREEN**

```bash
swift test --filter 'MediaSessionControllerTests|ShippingMediaRuntimePresentationPolicyTests|MediaInteractionContinuityCompositionPolicyTests'
```

Expected: PASS; both track-switch and compact-DOWN startup paths have no avoidable nil/Home intermediate.

- [ ] **Step 7: Commit**

```bash
git add Sources/NotchHubMediaCore/MediaSessionController.swift \
        Sources/NotchHubMediaCore/ShippingMediaRuntime.swift \
        Sources/NotchHubApp/MediaNotchRootView.swift \
        Tests/NotchHubMediaCoreTests/MediaSessionControllerTests.swift \
        Tests/NotchHubMediaCoreTests/ShippingMediaRuntimePresentationPolicyTests.swift \
        Tests/NotchHubCoreTests/MediaInteractionContinuityCompositionPolicyTests.swift
git commit -m 'fix: preserve media continuity across runtime refresh'
```

---

### Task 7: Freeze security/performance source policy and the new acceptance ledger

**Files:**
- Create: `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`
- Modify: `Tests/NotchHubCoreTests/MediaPeekAppCompositionPolicyTests.swift`
- Modify: `Tests/NotchHubCoreTests/MediaGestureAppCompositionPolicyTests.swift`
- Modify: `Tests/NotchHubCoreTests/MediaSeekAppCompositionPolicyTests.swift`
- Modify: `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`
- Modify: `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`
- Modify: `docs/TESTING.md`

**Interfaces:**
- Produces stable `NH-MEDIA-PEEK-001...013` acceptance IDs exactly as approved in the design spec.

- [ ] **Step 1: Add failing source-policy assertions before documentation**

Assert across the final App/Core files:

- no `NSEvent.addGlobalMonitorForEvents`, `NSEvent.addLocalMonitorForEvents` for scroll wheel, `CGEventTap`, synthetic key posting;
- no `Timer.scheduledTimer`, repeating `DispatchSourceTimer`, display link, or sleep loop in Peek/freshness code;
- no `Task {}` is allocated inside the per-scroll-event scalar processing path;
- no pointer warp/lock APIs;
- no new sensitive entitlements/permissions;
- `ShippingMediaPeekProbe` always has an explicit stop/cancel path;
- App runtime switch treats `.peek` like `.compact`, never as persistent runtime ownership.

- [ ] **Step 2: Run policy tests and verify RED if any forbidden pattern exists**

```bash
swift test --filter 'MediaPeekAppCompositionPolicyTests|MediaGestureAppCompositionPolicyTests|MediaSeekAppCompositionPolicyTests'
```

Expected: PASS only when implementation satisfies the frozen architecture; any policy failure must be repaired before docs are marked implemented.

- [ ] **Step 3: Create the Peek acceptance ledger**

Write `docs/testing/MEDIA_PEEK_ACCEPTANCE.md` with all 13 IDs from the approved spec:

`NH-MEDIA-PEEK-001` hover destination; `002` no-media hover; `003` fast pointer pass; `004` 140 ms grace; `005` explicit expansion; `006` Peek horizontal gestures; `007` Peek seek; `008` seek cursor; `009` track continuity; `010` downward continuity; `011` expanded collapse; `012` lifecycle; `013` permissions.

Mark automated evidence separately from physical evidence; do not mark physical PASS before target-Mac testing.

- [ ] **Step 4: Update existing ledgers/testing docs without renumbering frozen IDs**

Record that prior semantic PASS results remain valid unless touched by this implementation; explicitly flag the affected regression subset: hover behavior, expanded/compact transition continuity, seek cursor, Peek gestures, lifecycle and permissions.

- [ ] **Step 5: Commit**

```bash
git add Tests/NotchHubCoreTests/MediaPeekAppCompositionPolicyTests.swift \
        Tests/NotchHubCoreTests/MediaGestureAppCompositionPolicyTests.swift \
        Tests/NotchHubCoreTests/MediaSeekAppCompositionPolicyTests.swift \
        docs/testing/MEDIA_PEEK_ACCEPTANCE.md \
        docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md \
        docs/testing/MEDIA_GESTURE_ACCEPTANCE.md \
        docs/TESTING.md
git commit -m 'test: freeze hover peek acceptance policy'
```

---

### Task 8: Full regression, size provenance, project-state sync, and exact physical candidate

**Files:**
- Modify conditionally only after measured size RED: `.github/workflows/ci.yml`, `scripts/test_feature_size_budget.py`, create `performance/m6-6-hover-peek-size-budget.json`, create matching Swift policy test.
- Modify: `docs/PROJECT_STATE.md`
- Modify: `docs/ROADMAP.md`
- Modify: `CHANGELOG.md`
- Update: PR #33 body.

**Interfaces:**
- Produces one exact source SHA + CI run + shipping artifact + contained DMG hash for physical acceptance.
- Does not merge PR #33.

- [ ] **Step 1: Run the complete local automated suite**

```bash
swift test
python3 scripts/test_feature_size_budget.py
```

Expected: every functional/security/policy test PASS. Historical budget validation must stay immutable.

- [ ] **Step 2: Push the exact functional head and inspect GitHub Actions**

```bash
git push origin agent/m6-6-app-gesture-session
```

Require both existing CI jobs and every signing/Sandbox/Hardened Runtime/preflight step to pass.

- [ ] **Step 3: Handle size policy only from measured CI evidence**

If the current physical-acceptance-repair size envelope still passes, do not create a new budget.

If and only if CI fails solely on the active feature size envelope while all functional/security checks pass, use that exact failed run's source SHA, workflow run ID, artifact ID, and measured executable/app/DMG bytes to create `performance/m6-6-hover-peek-size-budget.json`. Keep `performance/baseline-v0.1.0.json` and every historical M6.x budget byte-for-byte unchanged. Add a RED policy test requiring the exact evidence, then switch active CI to the new budget and rerun to GREEN.

- [ ] **Step 4: Synchronize current-state documentation after functional/size GREEN**

Update `docs/PROJECT_STATE.md`, `docs/ROADMAP.md`, and `CHANGELOG.md` to state:

- approved three-state Hover Peek design implemented;
- automated acceptance GREEN;
- exact target-Mac physical acceptance still pending;
- PR #33 remains draft/unmerged;
- no claim that M6.6 is accepted or released yet.

- [ ] **Step 5: Run exact-head CI again after documentation commit**

```bash
git add docs/PROJECT_STATE.md docs/ROADMAP.md CHANGELOG.md
git commit -m 'docs: record hover peek physical candidate state'
git push origin agent/m6-6-app-gesture-session
```

Require full exact-head CI GREEN because bundled provenance includes `NHSourceCommit` and a docs commit changes candidate bytes.

- [ ] **Step 6: Freeze the physical-candidate evidence in PR #33**

Update the PR body with:

- exact head SHA;
- exact successful CI run number/ID;
- shipping candidate artifact ID/digest;
- standalone DMG artifact ID/digest;
- contained DMG byte size and SHA-256;
- executable/app/DMG measured sizes;
- explicit `DO NOT MERGE — TARGET-MAC PHYSICAL ACCEPTANCE PENDING`.

- [ ] **Step 7: Perform the focused target-Mac matrix on that exact candidate**

Required physical gates:

1. `NH-MEDIA-PEEK-001`: media hover opens Peek only.
2. `002`: no-media hover remains compact.
3. `003`: fast pointer pass never opens full UI/sticks Peek.
4. `004`: leave/re-enter <140 ms stays Peek; >140 ms collapses.
5. `005`: free-surface click and DOWN each expand exactly once.
6. `006`: Peek LEFT -> next, RIGHT -> previous, no hover theft.
7. `007`: Peek timeline seek works without expansion and suppresses notch gesture.
8. `008`: cursor hidden only during active seek and restored on commit/cancel/session change/teardown.
9. `009`: track/source switch has no obvious Home/interface blink.
10. `010`: compact DOWN has no intermediate Home/interface blink.
11. `011`: expanded UP -> compact; expanded pointer exit does nothing.
12. `012`: `pgrep -lf 'mediaremote-adapter\.pl' || true` is empty after settled compact/Peek cleanup and normal Quit; expanded settled state has only the expected persistent runtime.
13. `013`: no Accessibility/Input Monitoring/Automation/Screen Recording prompts.

Also rerun changed legacy gates: short/reversed horizontal cancellation, seek cancellation across track/source, source icon in expanded, lifecycle teardown.

- [ ] **Step 8: Stop at the acceptance gate**

If any physical gate fails, keep PR #33 draft and continue RED -> GREEN on the same branch with a new exact candidate.

If all physical gates pass, record the exact evidence in ledgers/docs. Any resulting docs-only commit requires fresh exact-head CI, but does not require repeating physical behavior testing unless production/shipping behavior changed. Only after that may PR #33 be marked ready for merge; merge and post-merge `main` CI are a separate finalization step.

---

## Plan Self-Review

### Spec coverage

- Three stable states and single geometry authority: Tasks 1-2.
- 120 ms hover dwell, no-media async eligibility, exact 140 ms grace, gesture hold: Task 2.
- Cached/no-cache bounded freshness with no persistent Peek observer: Task 3.
- One-line Peek UI, click/down expansion, LEFT/RIGHT, seek isolation: Task 4.
- Cursor hide without lock/warp and fail-safe restoration: Task 5.
- Track-switch and compact-DOWN continuity defects: Task 6.
- Security/performance/no-polling policies and stable 13-ID ledger: Task 7.
- Immutable historical size policy, exact CI artifact, target-Mac gate, no premature merge: Task 8.

### Placeholder scan

The plan contains no TBD/TODO/unspecified implementation steps. The only conditional branch is the evidence-driven size-budget cycle, whose exact trigger and required evidence are defined.

### Type consistency

- `NotchPresentation.peek` is introduced in Task 1 and consumed by Tasks 2-6.
- `NotchHoverPeekRequest` and controller resolution APIs are introduced in Task 2 and consumed by Task 3.
- `ShippingMediaPeekProbe` and one-shot presentation model APIs are introduced in Task 3 and consumed by App composition only.
- `MediaGestureSurface.peek` and bounded seek APIs are introduced together in Task 4.
- `CursorVisibilityController` is introduced in Task 5 and only consumed by `MediaGestureSession`/App lifecycle.
