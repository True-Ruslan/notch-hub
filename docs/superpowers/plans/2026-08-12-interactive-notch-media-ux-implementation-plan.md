# Interactive Notch Media UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the approved interactive compact↔expanded notch morph, local media gesture wiring, source-application icon badge, and capability-gated draggable seek without weakening the accepted M6.6 Tasks 0–4 lifecycle/security/performance boundaries.

**Architecture:** Keep `MediaGestureCoordinator` player-agnostic and deterministic; extend it only with vertical visual-tracking effects needed to drive the approved interactive panel motion. Keep `NotchPanelTransitionCoordinator` as the sole owner of panel geometry/transition generation, add a synchronous interactive-presentation driver inside `NotchHubCore`, and let an App-owned `MediaGestureSession` adapt local `NSEvent` scroll samples to Core/Media semantic seams. Source-icon resolution stays in `NotchHubApp` behind public `NSWorkspace`; settled compact keeps zero persistent media observation.

**Tech Stack:** Swift 6, SwiftUI, AppKit, QuartzCore, Swift Testing, existing `NotchHubCore` / `NotchHubMediaCore`, existing fixed `/usr/bin/perl` media boundary.

## Global Constraints

- Primary physical target: macOS `26.6` / `Mac16,8`.
- Approved design source: `docs/superpowers/specs/2026-08-12-interactive-notch-media-ux-design.md`.
- Existing stable media gesture gates `NH-MEDIA-GESTURE-001...018` remain authoritative and are not renumbered/redefined.
- New interactive/source-icon gates are `NH-NOTCH-INTERACTIVE-001...010` and `NH-MEDIA-SOURCE-ICON-001...006` from the approved design spec.
- Strict TDD: every production behavior starts with a committed/observable RED test that fails for the intended missing behavior before GREEN production code is added.
- `NotchPanelTransitionCoordinator` remains the only compact/expanded panel transition authority.
- `NotchHubApp` and SwiftUI must not call `NSPanel.setFrame` directly.
- No global `.scrollWheel` monitor, `CGEventTap`, Accessibility, Input Monitoring, Automation, Screen Recording, synthetic media keys, networking, telemetry, listening-history persistence, or arbitrary command surface.
- App Sandbox-only and Hardened Runtime remain mandatory.
- Settled compact owns zero persistent media observation process.
- Beginning/cancelling interactive compact expansion must not start `ShippingMediaRuntime`; runtime starts only after matching settled `.expanded`.
- Expanded runtime remains alive during interactive collapse and stops/releases only after matching settled `.compact`.
- Compact previous/next continues to use bounded one-shot `ShippingMediaCompactCommandDispatcher`; no persistent observation in compact.
- No per-scroll-event `Task {}`, process creation, icon lookup, image decoding, file I/O, timers, display links, sleeps, or logging.
- Horizontal threshold/hysteresis and one-arm-haptic semantics remain the already-frozen M6.6 values.
- Vertical commit threshold remains `70 pt`.
- Visual interactive travel is `max(140 pt, min(expandedHeight - compactHeight, 220 pt))` until one explicit target-Mac tuning pass; semantic `70 pt` commit threshold is independent.
- TheBoringNotch is product/visual reference only; do not copy GPL-licensed source or derived implementation text.
- `performance/baseline-v0.1.0.json` and historical feature budgets remain immutable. Any cumulative shipping growth beyond the active Task-4 ceiling requires a new provenance-backed RED→GREEN feature-size budget.

---

## File map

### New production files

- `Sources/NotchHubApp/MediaGestureSession.swift` — MainActor local-event adapter, gesture-session lifetime, compact capability task ownership, semantic effect routing, and haptic seam.
- `Sources/NotchHubApp/MediaGestureVisualModel.swift` — minimal ObservableObject for horizontal media visual offset only.
- `Sources/NotchHubApp/SourceApplicationIconResolver.swift` — public-`NSWorkspace` in-memory bounded source-icon resolver.

### Existing production files to modify

- `Sources/NotchHubCore/Notch/NotchPanelAnimationDriver.swift` — add synchronous interactive presentation application beside endpoint animation.
- `Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift` — add interactive expansion/collapse phases, normalized geometry interpolation, settle/cancel handoff, retarget and stale-generation safety.
- `Sources/NotchHubCore/Notch/NotchPanelController.swift` — expose narrow interactive expansion/collapse/update/finish methods; no direct App frame authority.
- `Sources/NotchHubMediaCore/MediaGestureCoordinator.swift` — emit vertical visual offset while vertical axis is captured; preserve frozen semantic commit behavior.
- `Sources/NotchHubMediaCore/ShippingMediaPresentationModel.swift` — preserve authoritative source bundle identifier separately from display name.
- `Sources/NotchHubMediaCore/ShippingMediaRuntime.swift` — expose typed absolute `seek(to:)` through existing controller command path.
- `Sources/NotchHubApp/AppDelegate.swift` — own/bind `MediaGestureSession`, compact dispatcher, visual model and icon resolver; pass local scroll callback to `NotchHostingViewFactory`.
- `Sources/NotchHubApp/MediaNotchRootView.swift` — apply horizontal visual tracking, source icon badge, and capability-gated seek control.

### Tests/policy/docs to modify/create

- `Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift`
- `Tests/NotchHubCoreTests/NotchPanelAnimationDriverTests.swift`
- `Tests/NotchHubCoreTests/NotchPanelOwnershipTests.swift`
- `Tests/NotchHubMediaCoreTests/MediaGestureCoordinatorTests.swift`
- `Tests/NotchHubMediaCoreTests/ShippingMediaPresentationModelTests.swift`
- `Tests/NotchHubMediaCoreTests/ShippingMediaRuntimePresentationPolicyTests.swift`
- `Tests/NotchHubCoreTests/MediaAppCompositionPolicyTests.swift`
- Create `Tests/NotchHubCoreTests/MediaGestureSessionTests.swift` only if app-source test target already compiles `Sources/NotchHubApp`; otherwise extend existing source-policy tests and keep deterministic behavior in Media/Core tests rather than altering package topology.
- `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`
- Create `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`
- `docs/PROJECT_STATE.md`, `docs/ROADMAP.md`, `docs/TESTING.md`, `CHANGELOG.md`
- Size-policy files/scripts only if RED evidence proves the active Task-4 envelope is exceeded.

---

### Task 1: Add deterministic interactive panel transition authority

**Files:**
- Modify: `Sources/NotchHubCore/Notch/NotchPanelAnimationDriver.swift`
- Modify: `Sources/NotchHubCore/Notch/NotchPanelTransitionCoordinator.swift`
- Modify: `Sources/NotchHubCore/Notch/NotchPanelController.swift`
- Test: `Tests/NotchHubCoreTests/NotchPanelTransitionCoordinatorTests.swift`
- Test: `Tests/NotchHubCoreTests/NotchPanelAnimationDriverTests.swift`
- Test: `Tests/NotchHubCoreTests/NotchPanelOwnershipTests.swift`

**Interfaces:**

Add an internal synchronous driver function:

```swift
@MainActor
func applyInteractiveNotchPanelPresentation(
    panel: NSPanel,
    chromeView: NSView,
    frame: CGRect,
    cornerRadius: CGFloat
)
```

It disables implicit layer actions, removes the existing corner-radius animation key, applies the exact corner radius, and calls `panel.setFrame(frame, display: true)` only inside `NotchHubCore`'s animation-driver boundary.

Add controller API:

```swift
@discardableResult
public func beginInteractiveExpansion() -> Bool

@discardableResult
public func beginInteractiveCollapse() -> Bool

public func updateInteractiveTransition(verticalDistance: CGFloat)
public func finishInteractiveTransition(commit: Bool)
```

Add coordinator API:

```swift
@discardableResult
func beginInteractiveTransition(
    from origin: NotchPresentation,
    layout: NotchLayout
) -> Bool

func updateInteractiveTransition(
    verticalDistance: CGFloat,
    layout: NotchLayout
)

func finishInteractiveTransition(
    commit: Bool,
    layout: NotchLayout
)
```

`beginInteractiveTransition` succeeds only from the matching stable phase (`.compact` for origin compact, `.expanded` for origin expanded). It records origin, generation and zero progress. For compact-origin expansion it sets `model.contentPresentation = .expanded` immediately so retained content can morph; collapse keeps expanded content until compact settlement.

`updateInteractiveTransition` computes:

```text
travel = max(140, min(layout.expandedFrame.height - layout.compactFrame.height, 220))
progress = clamp(abs(verticalDistance) / travel, 0...1)
```

and applies `lerp(originEndpoint, destinationEndpoint, progress)` for x/y/width/height plus 12↔22 corner radius.

`finishInteractiveTransition(commit:)` hands off from current visible geometry to existing endpoint animation. Commit targets the destination; cancel targets the origin. Existing generation/completion rules remain authoritative. Interactive plumbing emits no expansion haptic.

- [ ] **Step 1: Write RED transition tests**

Add focused tests proving exact endpoints, intermediate interpolation, clamp, stable-endpoint-only begin, compact-origin content staging, expanded-origin content retention, cancel→origin, commit→destination, no haptic, and `animationPolicyDidChange(layout:)` re-applies current progress against a changed layout rather than using stale geometry.

Representative test shape:

```swift
@Test
func interactiveExpansionAppliesHalfwayGeometryWithoutHaptic() {
    let fixture = makeFixture()

    #expect(fixture.coordinator.beginInteractiveTransition(from: .compact, layout: layout))
    fixture.coordinator.updateInteractiveTransition(verticalDistance: 109, layout: layout)

    #expect(fixture.interactiveDriver.requests.count == 1)
    #expect(fixture.interactiveDriver.requests[0].frame == CGRect(x: 325, y: 759, width: 350, height: 141))
    #expect(fixture.interactiveDriver.requests[0].cornerRadius == 17)
    #expect(fixture.haptics.requestCount == 0)
}
```

Use values derived from the real test layout/travel calculation; do not weaken equality into broad tolerances except where CGFloat interpolation requires a tiny explicit tolerance.

- [ ] **Step 2: Verify RED in CI**

Expected RED: tests fail to compile because interactive transition APIs/driver do not exist. Existing suites must still compile up to those intentional missing symbols.

- [ ] **Step 3: Implement minimal Core interactive state/driver**

Extend `NotchPanelTransitionPhase` with interactive cases carrying normalized progress or store progress separately with explicit `interactiveOrigin`. Keep endpoint `beginTransition` as the only settle animation path. `accept(_:)` must not let pointer intents replace an owned interactive gesture mid-sample; `animationPolicyDidChange` must retarget/reapply interactive geometry using current progress.

- [ ] **Step 4: GREEN focused/full Core verification**

Run via CI-equivalent commands:

```bash
swift test --filter NotchPanelTransitionCoordinatorTests
swift test --filter NotchPanelAnimationDriverTests
swift test --filter NotchPanelOwnershipTests
swift test --parallel
python3 scripts/performance_policy.py audit Sources
./scripts/security-audit.sh
```

Expected: GREEN with no new permission/polling/direct-App-frame authority.

- [ ] **Step 5: Commit/review checkpoint**

Commit only Task-1 production/tests after RED evidence is preserved.

---

### Task 2: Extend the pure gesture engine with vertical visual tracking

**Files:**
- Modify: `Sources/NotchHubMediaCore/MediaGestureCoordinator.swift`
- Test: `Tests/NotchHubMediaCoreTests/MediaGestureCoordinatorTests.swift`

**Interfaces:**

Add one effect without changing existing media semantics:

```swift
public enum MediaGestureEffect: Sendable, Equatable {
    // existing cases...
    case panelVisualOffset(Double)
}
```

Rules:

- emit `.panelVisualOffset(cumulativeY)` only after the gesture has captured the vertical axis;
- momentum emits no visual offset;
- horizontal/seek capture never emits panel offset;
- compact negative/upward offset may be emitted as raw deterministic data, but App composition must not begin compact expansion until the sign is downward;
- expanded positive/downward raw offset similarly must not begin collapse;
- semantic `.requestExpansion` / `.requestCollapse` remains end-only at the frozen `70 pt` threshold;
- no vertical haptic effect is added.

- [ ] **Step 1: RED pure tests**

Add tests for vertical raw cumulative offset, no offset before axis dominance, no offset under momentum, horizontal isolation and unchanged end-only semantic commit.

- [ ] **Step 2: Verify RED**

```bash
swift test --filter MediaGestureCoordinatorTests
```

Expected RED: `panelVisualOffset` missing.

- [ ] **Step 3: Minimal GREEN**

Append the effect in the existing `.vertical` branch of `changeGesture`; do not add timers, async work, haptics or transport knowledge.

- [ ] **Step 4: Full media suite**

```bash
swift test --filter MediaGestureCoordinatorTests
swift test --parallel
```

- [ ] **Step 5: Commit/review checkpoint**

---

### Task 3: Wire local gesture session, haptics and command routing

**Files:**
- Create: `Sources/NotchHubApp/MediaGestureSession.swift`
- Create: `Sources/NotchHubApp/MediaGestureVisualModel.swift`
- Modify: `Sources/NotchHubApp/AppDelegate.swift`
- Modify: `Sources/NotchHubApp/MediaNotchRootView.swift`
- Modify: `Tests/NotchHubCoreTests/MediaAppCompositionPolicyTests.swift`
- Test deterministic Media/Core seams where possible rather than changing package targets solely for App internals.

**Interfaces:**

Create minimal visual state:

```swift
@MainActor
final class MediaGestureVisualModel: ObservableObject {
    @Published private(set) var horizontalOffset: CGFloat = 0
    func setHorizontalOffset(_ value: CGFloat)
    func reset()
}
```

Create an injectable haptic closure and session:

```swift
@MainActor
final class MediaGestureSession {
    init(
        coordinator: MediaGestureCoordinator = MediaGestureCoordinator(),
        compactDispatcher: ShippingMediaCompactCommandDispatcher,
        visualModel: MediaGestureVisualModel,
        performArmHaptic: @escaping @MainActor () -> Void
    )

    func bind(
        panelController: NotchPanelController,
        panelModel: NotchPanelModel,
        runtimeProvider: @escaping @MainActor () -> ShippingMediaRuntime?,
        presentationProvider: @escaping @MainActor () -> ShippingMediaPresentation?
    )

    func handleScrollWheel(_ event: NSEvent)
    func invalidate()
}
```

Implementation rules:

- map only physical `.began/.changed/.ended/.cancelled`; ignore `.mayBegin`, `.stationary` and unsupported phases;
- mark `isMomentum = !event.momentumPhase.isEmpty`; coordinator remains authoritative for rejection;
- capture start surface on `.began` and keep it stable for the whole physical gesture even if Core stages expanded content during interactive expansion;
- map expanded previous/next capability from current authoritative `ShippingMediaPresentation`; compact passes `.pending` and waits for bounded dispatcher capability;
- compact capability request owns at most one `Task` for the current gesture ID/direction; a new gesture/invalidate cancels the old task, and stale completion is harmless because coordinator generation validation remains authoritative;
- `.requestArmHaptic` calls exactly one injected public AppKit haptic performer call;
- `.visualOffset` updates only `MediaGestureVisualModel`;
- `.panelVisualOffset`: start/update Core interactive expansion only for compact+positive offset; start/update collapse only for expanded+negative offset;
- physical end finishes active interactive panel transition with `commit=true` iff matching `.requestExpansion/.requestCollapse` is emitted; otherwise cancel to origin;
- `.cancelled` cancels panel interaction;
- compact `.commit(previous|next)` uses only dispatcher `.send`; expanded commit uses only `ShippingMediaRuntime.goPrevious/goNext`;
- no `Task` is allocated for ordinary changed samples; async tasks occur only at compact capability/command semantic boundaries;
- `invalidate()` cancels capability task, invalidates coordinator visual state, resets visual model, calls `compactDispatcher.stop()`, and drops bindings.

In `AppDelegate`, create session/visual model/dispatcher before `NotchPanelController`, pass `onScrollWheel: { session.handleScrollWheel($0) }` to `NotchHostingViewFactory.make`, then bind controller/model/runtime provider once Core constructs them.

- [ ] **Step 1: RED composition policy tests**

Require source composition to include `onScrollWheel`, `MediaGestureSession`, bounded compact dispatcher and public haptic performer, while continuing to reject global scroll monitors, synthetic keys and direct App `NSPanel.setFrame`.

- [ ] **Step 2: RED deterministic behavior at seams**

Where App internals are not directly buildable in the package test target, add source-level assertions plus pure coordinator/Core tests that make each routing invariant fail before production wiring. Do not create a new library target just to test private App code unless compilation evidence proves it is necessary and low-risk.

- [ ] **Step 3: Minimal GREEN wiring**

Use `NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)` only inside the injected arm-haptic closure.

- [ ] **Step 4: GREEN full/security/performance verification**

```bash
swift test --parallel
python3 scripts/performance_policy.py audit Sources
./scripts/security-audit.sh
```

Also inspect source policy to prove no `.scrollWheel` global monitor, event tap, synthetic key or direct App frame call was introduced.

- [ ] **Step 5: Commit/review checkpoint**

This is the first user-visible gesture wiring and therefore is not physically accepted merely because CI is green.

---

### Task 4: Replace source text with independently resolved source-app icon

**Files:**
- Modify: `Sources/NotchHubMediaCore/ShippingMediaPresentationModel.swift`
- Modify: `Tests/NotchHubMediaCoreTests/ShippingMediaPresentationModelTests.swift`
- Create: `Sources/NotchHubApp/SourceApplicationIconResolver.swift`
- Modify: `Sources/NotchHubApp/AppDelegate.swift`
- Modify: `Sources/NotchHubApp/MediaNotchRootView.swift`
- Modify: `Tests/NotchHubCoreTests/MediaAppCompositionPolicyTests.swift`

**Interfaces:**

Extend presentation:

```swift
public let sourceBundleIdentifier: String?
```

Normalize it from authoritative `snapshot.source.bundleIdentifier`; keep `sourceDisplayName` for accessibility/help semantics.

Resolver:

```swift
@MainActor
final class SourceApplicationIconResolver {
    init(workspace: NSWorkspace = .shared, capacity: Int = 8)
    func icon(for bundleIdentifier: String?) -> NSImage?
}
```

Rules:

- `nil`/blank bundle ID -> nil;
- use `workspace.urlForApplication(withBundleIdentifier:)` and public icon lookup only;
- cache by normalized bundle ID, max 8 entries with deterministic eviction;
- no persistence/filesystem crawl/network/polling;
- lookup happens only when source identity changes, not on every body evaluation.

UI:

- remove persistent `Text(presentation.sourceDisplayName)` from normal expanded chrome;
- overlay a 24 pt badge at artwork lower-trailing corner;
- fallback is neutral `app`/`macwindow` SF Symbol badge, never a misleading guessed app icon;
- attach accessibility/help identity using `sourceDisplayName`;
- compact wings remain unchanged and do not gain another source badge.

- [ ] **Step 1: RED presentation identity tests**

Require exact bundle-ID propagation and normalization independent of display name.

- [ ] **Step 2: RED App/source policy**

Require `NSWorkspace` public resolver and absence of visual source text in the media view while retaining accessibility label/help semantics.

- [ ] **Step 3: Minimal GREEN**

Implement bounded resolver and source-change-driven state in the SwiftUI/App layer.

- [ ] **Step 4: Full GREEN**

```bash
swift test --parallel
python3 scripts/performance_policy.py audit Sources
./scripts/security-audit.sh
```

- [ ] **Step 5: Commit/review checkpoint**

---

### Task 5: Add capability-gated draggable seek and interaction isolation

**Files:**
- Modify: `Sources/NotchHubMediaCore/ShippingMediaRuntime.swift`
- Modify: `Tests/NotchHubMediaCoreTests/ShippingMediaRuntimePresentationPolicyTests.swift`
- Modify: `Sources/NotchHubApp/MediaGestureSession.swift`
- Modify: `Sources/NotchHubApp/MediaNotchRootView.swift`
- Modify: `Tests/NotchHubCoreTests/MediaAppCompositionPolicyTests.swift`

**Interfaces:**

Add typed runtime entry point:

```swift
public func seek(to positionSeconds: Double)
```

It validates finite/non-negative input and sends only existing typed `.seek(positionSeconds:)` through the active expanded controller. Compact dispatcher public surface remains previous/next only.

For the UI, replace passive `ProgressView` with a small seek view only when trustworthy position/duration exist. Behavior:

- when `canSeek == false`, render passive progress only;
- when `canSeek == true`, drag owns a local preview value clamped `0...duration`;
- drag start sets `seekActive=true` in `MediaGestureSession` so scroll track/panel gestures cancel/fail closed during seek;
- drag end emits one `runtime.seek(to:)` and clears seek ownership;
- drag cancel/disappearance restores authoritative position and clears seek ownership;
- no polling/timer is introduced.

- [ ] **Step 1: RED runtime typed-seek policy tests**

Prove exact typed command mapping and invalid-number fail-closed behavior.

- [ ] **Step 2: RED UI/composition tests**

Require `canSeek` gating, passive fallback, one commit path and seek-active isolation seam.

- [ ] **Step 3: Minimal GREEN**

Keep all seek behavior expanded-runtime-only; do not add seek to compact dispatcher.

- [ ] **Step 4: Full GREEN**

```bash
swift test --parallel
python3 scripts/performance_policy.py audit Sources
./scripts/security-audit.sh
```

- [ ] **Step 5: Commit/review checkpoint**

---

### Task 6: Cumulative size policy, documentation and exact physical candidate

**Files:**
- Potential create: `performance/m6-6-interactive-notch-size-budget.json` only after a deliberate RED policy test proves the current Task-4 envelope is exceeded.
- Modify: `scripts/test_feature_size_budget.py` only if new budget required.
- Modify/add size policy Swift tests only if new budget required.
- Modify: `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`
- Create/update: `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`
- Modify: `docs/PROJECT_STATE.md`
- Modify: `docs/ROADMAP.md`
- Modify: `docs/TESTING.md`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Run complete PR-head CI before widening any budget**

Record exact executable/app/DMG sizes from CI. If they fit the active Task-4 envelope, do not create a new budget. If only size gate fails while functional/security/signing/preflight tests pass, preserve that run as RED provenance, add the narrow cumulative interactive-notch budget, and keep historical budgets immutable.

- [ ] **Step 2: Sync factual docs**

Record merged M6.6 Tasks 2–4, approved/merged design checkpoint, exact implementation CI evidence, and clearly mark physical acceptance as pending. Do not label M6.6 accepted before target testing.

- [ ] **Step 3: Produce exact candidate**

Require both CI jobs PASS on one exact source. Record source SHA, run number, shipping artifact ID/digest, contained DMG SHA-256 and sizes.

- [ ] **Step 4: Target-Mac physical acceptance**

Run all applicable `NH-MEDIA-GESTURE-001...018`, `NH-NOTCH-INTERACTIVE-001...010`, and `NH-MEDIA-SOURCE-ICON-001...006` gates on macOS 26.6 / Mac16,8. At minimum verify hover regression, swipe-down/up follow-finger motion, short/reversed cancel, momentum, horizontal previous/next + one haptic, source icon for Yandex Music and Yandex Browser/Chromium, fallback icon, capability-gated seek, permission surface, zero-adapter compact, one expected expanded adapter, cancelled expansion zero-adapter, clean Quit and no handoff frame jump.

- [ ] **Step 5: One explicit feel-tuning pass if needed**

Only `interactiveTravel`/visual damping may be tuned from hardware feel. Commit tuned constants with updated deterministic tests and rerun exact candidate CI. Do not silently change semantic 70 pt vertical threshold or horizontal frozen thresholds.

- [ ] **Step 6: Final merge only after evidence**

Merge the user-visible implementation only after exact PR-head CI plus required physical acceptance. Then verify post-merge `main` CI before marking M6.6 accepted/merged. P1 resource review remains next.

---

## Self-review

- Spec coverage: interactive geometry, arbitration, lifecycle asymmetry, horizontal media tracking/haptics, source icon, seek, security, performance and physical acceptance all map to explicit tasks.
- No placeholders/TODOs are used; all new interfaces required by later tasks are defined above.
- Type consistency: App talks only to public `NotchPanelController`, `MediaGestureCoordinator`, `ShippingMediaRuntime`, `ShippingMediaCompactCommandDispatcher` and presentation types; App never receives transition coordinator/frame ownership directly.
- Frozen contract preservation: no vertical haptic was introduced; compact dispatcher remains previous/next only; settled compact remains zero persistent adapter; existing `NH-MEDIA-GESTURE-001...018` remain unchanged.
- Execution mode: use isolated GitHub feature branches/PR heads as the workspace boundary in this connector-only session; never write implementation directly to protected `main`.
