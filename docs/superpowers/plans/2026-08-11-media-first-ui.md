# M6.5 Media-first UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render compact retained media context and expanded Media-first content from the accepted production system-media transport without weakening the accepted M6.4 presentation-scoped lifecycle.

**Architecture:** Keep `NotchHubCore` independent from `NotchHubMediaCore`. Add a generic Core content-host injection seam, expose a presentation-only observable model from `NotchHubMediaCore`, and compose the media-aware SwiftUI root in `NotchHubApp`. The App-owned presentation model survives individual expanded-only runtime instances so compact can retain the last authoritative context while the adapter remains absent.

**Tech Stack:** Swift 6, SwiftUI, AppKit, Combine `ObservableObject`, Swift Testing, Swift Package Manager, GitHub Actions.

## Global Constraints

- Primary physical target: macOS 26.6 / `Mac16,8`; deployment target remains macOS 14+.
- App Sandbox remains the only application entitlement; Hardened Runtime remains mandatory.
- Compact launch/steady/stability owns zero media adapter processes.
- Media runtime starts only after matching settled `.expanded` and stops/releases after matching settled `.compact`.
- No polling/repeating timer/display link/sleep loop/global scroll monitor for media UI/progress.
- No direct network, telemetry, metadata/history persistence/logging, Accessibility, Input Monitoring, Automation, Screen Recording, synthetic media keys, AppleScript or player-specific fallback.
- `NotchHubCore` must not depend on or import `NotchHubMediaCore`.
- Gestures/haptics/draggable seek/live compact observation are out of scope.
- Preserve the existing `NotchPanelTransitionCoordinator` as the sole panel geometry/presentation transition authority.
- Behavior changes use honest RED -> GREEN -> REFACTOR evidence.

---

### Task 1: Add the media-aware content injection seam to Notch Core

**Files:**
- Modify: `Sources/NotchHubCore/UI/NotchHostingViewFactory.swift`
- Modify: `Sources/NotchHubCore/Notch/NotchPanelController.swift`
- Modify: `Tests/NotchHubCoreTests/NotchHostingViewFactoryTests.swift`
- Modify: `Tests/NotchHubCoreTests/NotchPanelOwnershipTests.swift`

**Interfaces:**
- Consumes: existing `NotchPanelModel`, `NotchLayout`, `NSView`, `SwiftUI.View`.
- Produces: `public typealias NotchPanelContentFactory = @MainActor (NotchPanelModel, NotchLayout) -> NSView`; `public init(contentFactory:)`; generic `NotchHostingViewFactory.make(rootView:)` with the same accepted sizing/chrome configuration.

- [ ] **Step 1: Write failing tests**

Extend `NotchHostingViewFactoryTests` with a custom trivial SwiftUI root and assert `sizingOptions == []`, autoresizing width+height, `wantsLayer`, clipping, continuous curve and 12 pt initial radius when created through `NotchHostingViewFactory.make(rootView:)`.

Extend `NotchPanelOwnershipTests` source-policy coverage to require `NotchPanelContentFactory`, `contentFactory(model, resolvedLayout)`, and to reject any `NotchHubMediaCore` import in `NotchPanelController.swift`.

- [ ] **Step 2: Run RED**

Run `swift test --parallel`.

Expected: compile/test failure because the generic public factory and injectable controller initializer do not exist yet.

- [ ] **Step 3: Implement the minimal Core seam**

Refactor the factory to keep the existing specialized default path but centralize accepted chrome setup:

```swift
@MainActor
public enum NotchHostingViewFactory {
    public static func make<Content: View>(rootView: Content) -> NSHostingView<Content> {
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.sizingOptions = []
        hostingView.autoresizingMask = [.width, .height]
        hostingView.wantsLayer = true
        hostingView.layer?.masksToBounds = true
        hostingView.layer?.cornerCurve = .continuous
        hostingView.layer?.cornerRadius = 12
        return hostingView
    }

    static func make(model: NotchPanelModel, layout: NotchLayout) -> NSHostingView<NotchRootView> {
        make(rootView: NotchRootView(
            model: model,
            compactBackgroundOpacity: layout.compactBackgroundOpacity,
            expandedContentTopInset: layout.expandedContentTopInset
        ))
    }
}
```

Add the public content factory and make the current zero-argument initializer delegate to it. The custom factory may replace only the panel content view; transition/pointer/haptic/layout ownership remains in `NotchPanelController`.

- [ ] **Step 4: Run GREEN**

Run `swift test --parallel` and `swift build -Xswiftc -warnings-as-errors`.

Expected: all existing and new Core tests PASS with no warnings.

- [ ] **Step 5: Commit**

```bash
git add Sources/NotchHubCore Tests/NotchHubCoreTests
git commit -m "feat: add notch content composition seam"
```

---

### Task 2: Define deterministic shipping media presentation state

**Files:**
- Create: `Sources/NotchHubMediaCore/ShippingMediaPresentationModel.swift`
- Create: `Tests/NotchHubMediaCoreTests/ShippingMediaPresentationModelTests.swift`

**Interfaces:**
- Consumes: internal authoritative `MediaSubsystemState`, `MediaSessionSnapshot`, capabilities and source identity.
- Produces: public `ShippingMediaPresentation`, public `ShippingMediaPlaybackState`, and `@MainActor public final class ShippingMediaPresentationModel: ObservableObject` with `@Published public private(set) var presentation`.

- [ ] **Step 1: Write failing mapper tests**

Cover these behaviors with real snapshots:

```swift
@Test func playingSessionMapsAuthoritativePresentation()
@Test func pausedSessionMapsPausedPresentation()
@Test func whitespaceMetadataIsOmittedWithoutFabrication()
@Test func unsupportedAndUnknownCapabilitiesRemainDisabled()
@Test func trustworthyProgressIsPreservedAndClamped()
@Test func invalidProgressIsOmitted()
@Test func idleAndUnavailableClearPresentation()
@Test func olderPresentationCannotBeReappliedAfterNewerSequence()
```

The model tracks the latest mapped `MediaSequence` while active so a stale presentation callback cannot overwrite newer UI state. A newer no-session/unavailable state clears presentation and ordering state according to the controller event order that produced it.

- [ ] **Step 2: Run RED**

Run `swift test --parallel`.

Expected: compile failure because `ShippingMediaPresentationModel` and presentation types do not exist.

- [ ] **Step 3: Implement minimal presentation mapping**

Use a public immutable presentation DTO. Keep transport/domain internals private to the module.

Required public surface:

```swift
public enum ShippingMediaPlaybackState: Sendable, Equatable {
    case paused
    case playing
}

public struct ShippingMediaPresentation: Sendable, Equatable {
    public let playbackState: ShippingMediaPlaybackState
    public let title: String?
    public let artist: String?
    public let album: String?
    public let artworkData: Data?
    public let sourceDisplayName: String
    public let canGoPrevious: Bool
    public let canGoNext: Bool
    public let canSeek: Bool
    public let positionSeconds: Double?
    public let durationSeconds: Double?
}
```

`ShippingMediaPresentationModel` exposes no transport command IDs and no source-specific policy. Treat trimmed empty metadata as absent. `sourceDisplayName` uses authoritative display name when non-empty, otherwise the authoritative bundle identifier. Preserve progress only when duration is finite and `> 0` and position is finite and `>= 0`; clamp display position to duration.

- [ ] **Step 4: Run GREEN**

Run `swift test --parallel` and `swift build -Xswiftc -warnings-as-errors`.

Expected: mapper tests and full suite PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/NotchHubMediaCore/ShippingMediaPresentationModel.swift Tests/NotchHubMediaCoreTests/ShippingMediaPresentationModelTests.swift
git commit -m "feat: map media state for presentation"
```

---

### Task 3: Wire ShippingMediaRuntime to presentation callbacks and typed UI commands

**Files:**
- Modify: `Sources/NotchHubMediaCore/ShippingMediaRuntime.swift`
- Create: `Tests/NotchHubMediaCoreTests/ShippingMediaRuntimePresentationPolicyTests.swift`

**Interfaces:**
- Consumes: App-owned `ShippingMediaPresentationModel`.
- Produces: `public convenience init(presentationModel:)`; controller change wiring; collapse-safe retained presentation; `togglePlayPause()`, `goPrevious()`, `goNext()` typed command methods.

- [ ] **Step 1: Write failing policy/tests**

Add source-policy and behavior-facing assertions proving:

- runtime owns a `ShippingMediaPresentationModel` reference rather than exposing `MediaSessionController`;
- `controller.changeHandler` maps `controller.state` + `controller.snapshot` into the presentation model;
- runtime clears presentation when bundle/resource validation fails during an expanded start;
- `stop()` sets `controller.changeHandler = nil` **before** `controller.stop()` so normal compact settlement retains the last authoritative context;
- UI command methods call only `.togglePlayPause`, `.previous`, `.next` through `MediaSessionController.send`;
- no arbitrary command string, shell, polling/timer primitive or new process boundary is introduced.

- [ ] **Step 2: Run RED**

Run `swift test --parallel`.

Expected: tests fail because runtime presentation wiring/typed UI command methods do not exist.

- [ ] **Step 3: Implement runtime wiring**

`ShippingMediaRuntime` receives the App-owned model. On successful controller creation:

```swift
controller.changeHandler = { [weak controller, weak presentationModel] in
    guard let controller, let presentationModel else { return }
    presentationModel.apply(state: controller.state, snapshot: controller.snapshot)
}
```

Before normal stop:

```swift
controller?.changeHandler = nil
controller?.stop()
controller = nil
```

This ordering intentionally retains compact context while preventing the controller's terminal `.unavailable` publication from clearing it. If start cannot validate shipping resources, explicitly clear the model because the expanded media subsystem is unavailable.

Typed UI command helpers may spawn one short-lived `Task` per explicit button action to await the already-async controller command. They must not add periodic work.

- [ ] **Step 4: Run GREEN and security audit**

Run:

```bash
swift test --parallel
swift build -Xswiftc -warnings-as-errors
python3 scripts/performance_policy.py audit Sources
./scripts/security-audit.sh
```

Expected: PASS; the sole production `Process()` boundary remains `MediaRemoteProcessClient.swift`.

- [ ] **Step 5: Commit**

```bash
git add Sources/NotchHubMediaCore/ShippingMediaRuntime.swift Tests/NotchHubMediaCoreTests/ShippingMediaRuntimePresentationPolicyTests.swift
git commit -m "feat: expose shipping media presentation lifecycle"
```

---

### Task 4: Compose compact + expanded Media-first SwiftUI in the App target

**Files:**
- Create: `Sources/NotchHubApp/MediaNotchRootView.swift`
- Modify: `Sources/NotchHubApp/AppDelegate.swift`

**Interfaces:**
- Consumes: `NotchPanelModel`, `NotchLayout`, `ShippingMediaPresentationModel`, typed runtime command helpers, `NotchHostingViewFactory.make(rootView:)`.
- Produces: media-aware shipping root view while leaving Core's default root intact for Core tests/fallback use.

- [ ] **Step 1: Add compile-time composition expectations before production view code**

Extend `ShippingMediaRuntimePresentationPolicyTests`/Core ownership source checks to require the App to own `ShippingMediaPresentationModel`, inject `MediaNotchRootView`, and keep `NotchHubCore` free of `NotchHubMediaCore` imports. This RED must fail before the App changes exist.

- [ ] **Step 2: Run RED**

Run `swift test --parallel`.

Expected: source-policy assertions fail because the App still uses default `NotchPanelController()` and no media-aware root exists.

- [ ] **Step 3: Implement MediaNotchRootView**

Rendering contract:

- compact + no presentation: preserve the existing centered 4 pt indicator;
- compact + presentation: left 24–28 pt artwork/placeholder, right play/pause status symbol, no text/controls/timeline;
- expanded + presentation: artwork, optional title/artist/album, source label, capability-driven previous/play-pause/next buttons, static progress only when both normalized values exist;
- expanded + no presentation: preserve the existing Foundation/Home content;
- artwork decode failure: SF Symbol `music.note` placeholder;
- no animation/timer/polling loop for progress.

Use `Image(nsImage:)` for already-bounded artwork bytes when `NSImage(data:)` succeeds. Do not persist decoded artwork or derive dynamic colors.

- [ ] **Step 4: Update AppDelegate composition**

Own one `ShippingMediaPresentationModel` for application lifetime. Create `NotchPanelController(contentFactory:)` and build its hosting view with `NotchHostingViewFactory.make(rootView:)`.

When settled expanded, create `ShippingMediaRuntime(presentationModel:)`; when settled compact, stop/release the runtime but keep the presentation model alive. Button closures call the current runtime's typed command helpers and become no-ops if runtime is absent.

Do not change the settled-transition lifecycle trigger itself.

- [ ] **Step 5: Run GREEN**

Run:

```bash
swift build -Xswiftc -warnings-as-errors
swift test --parallel
python3 scripts/performance_policy.py audit Sources
./scripts/security-audit.sh
```

Expected: PASS, no new polling/global input/security authority.

- [ ] **Step 6: Commit**

```bash
git add Sources/NotchHubApp Sources/NotchHubCore Tests
git commit -m "feat: add media-first notch UI"
```

---

### Task 5: Synchronize source-of-truth documentation and create target acceptance ledger

**Files:**
- Create: `docs/testing/MEDIA_UI_ACCEPTANCE.md`
- Modify: `README.md`
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/TESTING.md`
- Modify: `docs/PROJECT_STATE.md`
- Modify: `docs/ROADMAP.md`
- Modify: `SECURITY.md`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: exact implementation/CI evidence produced by Tasks 1–4.
- Produces: explicit implemented/tested/not-yet-accepted state and physical `NH-MEDIA-UI-011` procedure.

- [ ] **Step 1: Record implementation state without overclaiming acceptance**

Document `NH-MEDIA-UI-001...010` deterministic status from CI and leave `NH-MEDIA-UI-011` **PENDING TARGET MAC** until physical testing occurs.

`PROJECT_STATE.md` must say M6.5 is implemented/tested in the PR but not accepted/merged/released. Do not advance roadmap to gestures/P1 while target acceptance is pending.

- [ ] **Step 2: Fix stale architecture/security/readme text**

Update stale pre-M6.4 claims that media is not shipping. Preserve the exact accepted security boundary: fixed `/usr/bin/perl`, pinned adapter resources, App Sandbox/Hardened Runtime, no broad permissions/network/telemetry, presentation-scoped runtime.

- [ ] **Step 3: Define physical acceptance procedure**

On `Mac16,8` / macOS 26.6, exact PR artifact:

1. launch compact and verify ordinary compact + no adapter;
2. expand with Yandex Music active; verify artwork/metadata as available, source, playing/paused, capability-driven controls;
3. exercise play/pause and supported previous/next buttons;
4. verify static progress appears only when trustworthy timing exists;
5. close/disappear active media while expanded and verify Home replaces Media without collapse;
6. reactivate media, expand, then collapse; verify retained compact artwork/status while `pgrep`/collector proves adapter absent;
7. repeat with Yandex Browser;
8. verify Accessibility/Input Monitoring/Automation/Screen Recording prompts remain NONE;
9. verify no orphan adapter after normal termination.

- [ ] **Step 4: Commit**

```bash
git add README.md SECURITY.md CHANGELOG.md docs
git commit -m "docs: record M6.5 media UI acceptance state"
```

---

### Task 6: Final automated verification and PR handoff

**Files:**
- No production changes expected unless verification finds a real defect.

- [ ] **Step 1: Run complete local-equivalent gates**

```bash
swift build -Xswiftc -warnings-as-errors
swift test --parallel
(cd scripts && python3 -m unittest -v test_release_policy.py)
(cd scripts && python3 -m unittest -v test_performance_policy.py)
python3 scripts/performance_policy.py audit Sources
./scripts/security-audit.sh
./scripts/build-app.sh
./scripts/build-dmg.sh
```

- [ ] **Step 2: Push/open draft PR and require CI**

Required jobs: `macOS 26 compatibility` and `Build, test and package` both PASS. Record exact head SHA/run/artifact IDs in `MEDIA_UI_ACCEPTANCE.md` once available.

- [ ] **Step 3: Do not mark accepted/merge yet**

Until `NH-MEDIA-UI-011` passes on the target Mac, status remains:

`implemented -> tested -> awaiting physical acceptance -> not merged -> not released`.

Only after target acceptance should the PR receive final exact-head CI/review and squash merge. Gesture/haptic/seek work must not begin before that acceptance.
