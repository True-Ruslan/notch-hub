# M2.1 Shelf Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the first persistent, read-only, security-scoped file Shelf and bounded Home/Shelf routing inside the existing NotchHub panel.

**Architecture:** Keep panel geometry and media lifecycle unchanged. Add a pure first-party destination model in `NotchHubCore`, an actor-backed Shelf persistence layer plus security-scoped bookmark codec/store, and an App-layer SwiftUI `ShelfView`. Explicit selection may replace Expanded media content, but Compact/Peek remain media-first. All file access is user-selected, read-only, short-lived, and event-driven.

**Tech Stack:** Swift 6, SwiftUI, AppKit (`NSOpenPanel`, `NSWorkspace`), Foundation security-scoped bookmarks, Swift Testing, existing GitHub Actions/macOS packaging pipeline.

**Spec:** `docs/superpowers/specs/2026-09-08-m2-1-shelf-foundation-design.md`

## Global Constraints

- Primary target: macOS 26.6; package deployment floor remains macOS 14.
- NotchHub remains MIT; do not copy GPL-3.0 boring.notch source/tests/implementation-specific structures.
- Shipping entitlements become exactly `com.apple.security.app-sandbox=true` plus `com.apple.security.files.user-selected.read-only=true`.
- Do not add read-write file access, Accessibility, Input Monitoring, Automation, Screen Recording, network, Bluetooth, camera, microphone, global drag/keyboard/scroll monitors, or dynamic code loading.
- Do not add polling/timers/background filesystem scanners for Shelf.
- `NotchPanelController` / `NotchPanelTransitionCoordinator` remain sole geometry/transition authorities.
- Remove from Shelf never deletes/moves/renames the source file.
- Bookmark/persistence filesystem work stays off the main actor; UI state changes stay on the main actor.

---

### Task 1: Lock the core Shelf contracts with failing tests

**Files:**
- Create: `Tests/NotchHubCoreTests/ShelfItemTests.swift`
- Create: `Tests/NotchHubCoreTests/ShelfPersistenceRepositoryTests.swift`
- Create: `Tests/NotchHubCoreTests/ShelfStoreTests.swift`
- Create: `Tests/NotchHubCoreTests/NotchDestinationModelTests.swift`

**Interfaces:**
- Consumes: existing `Testing` + `Foundation` test stack.
- Produces expected contracts for `ShelfItem`, `ShelfPersistenceRepository`, `ShelfBookmarkCoding`, `ShelfBookmarkResolution`, `ShelfStore`, `NotchDestination`, and `NotchDestinationModel`.

- [ ] **Step 1: Write the failing tests**

Tests require these exact behaviors:

```swift
let item = ShelfItem(id: id, bookmarkData: Data([1, 2, 3]), displayName: "Report.pdf", isDirectory: false)
let data = try JSONEncoder().encode(item)
#expect(try JSONDecoder().decode(ShelfItem.self, from: data) == item)
```

```swift
let repository = ShelfPersistenceRepository(fileURL: tempURL)
#expect(await repository.load() == [])
try await repository.save([item])
#expect(await repository.load() == [item])
try Data("not-json".utf8).write(to: tempURL)
#expect(await repository.load() == [])
```

`ShelfStoreTests` uses a test `ShelfBookmarkCoding` implementation mapping bookmark bytes to URLs and asserts:

- adding `[A, B, A]` produces `[A, B]` in first-seen order;
- adding A again after reload remains deduplicated;
- one unresolvable existing bookmark does not block a valid new URL;
- `remove(id:)` only removes the item from the store/persistence;
- resolving a stale bookmark replaces the stored bookmark bytes with refreshed bytes;
- persistence failure sets a bounded `hasPersistenceError` state instead of crashing.

`NotchDestinationModelTests` asserts default `.home`, explicit `.shelf`, and `reset()` -> `.home`.

- [ ] **Step 2: Push tests before production types exist**

Expected CI result: compile failure limited to the intentionally missing M2.1 symbols. This proves the new test target is active before implementation.

- [ ] **Step 3: Add only compile skeletons**

Create the production files from Tasks 2–4 with signatures only and deliberately minimal behavior (`load -> []`, no additions, destination methods wired) until the test suite compiles and fails on behavior rather than missing symbols.

- [ ] **Step 4: Re-run CI**

Expected: tests compile; at least persistence/store behavior tests FAIL for expected assertions.

---

### Task 2: Implement the security-scoped Shelf data model and bookmark codec

**Files:**
- Create: `Sources/NotchHubCore/Shelf/ShelfItem.swift`
- Create: `Sources/NotchHubCore/Shelf/ShelfBookmarkCodec.swift`
- Test: `Tests/NotchHubCoreTests/ShelfItemTests.swift`
- Test: `Tests/NotchHubCoreTests/ShelfStoreTests.swift`

**Interfaces:**
- Produces:
  - `public struct ShelfItem: Identifiable, Codable, Equatable, Sendable`
  - `public struct ShelfBookmarkResolution: Equatable, Sendable`
  - `public protocol ShelfBookmarkCoding: Sendable`
  - `public struct SecurityScopedShelfBookmarkCodec: ShelfBookmarkCoding`

- [ ] **Step 1: Implement `ShelfItem`**

Exact stored fields: `id`, `bookmarkData`, `displayName`, `isDirectory`. No source path field.

- [ ] **Step 2: Implement bookmark creation**

```swift
try url.bookmarkData(
    options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
    includingResourceValuesForKeys: nil,
    relativeTo: nil
)
```

- [ ] **Step 3: Implement bookmark resolution and stale refresh**

Resolve using `.withSecurityScope`; when stale, recreate a read-only security-scoped bookmark and return it as `refreshedBookmarkData`.

- [ ] **Step 4: Run tests**

Expected: `ShelfItemTests` green; store tests still red until Tasks 3–4.

---

### Task 3: Implement actor-backed atomic persistence

**Files:**
- Create: `Sources/NotchHubCore/Shelf/ShelfPersistenceRepository.swift`
- Test: `Tests/NotchHubCoreTests/ShelfPersistenceRepositoryTests.swift`

**Interfaces:**
- Produces:
  - `public actor ShelfPersistenceRepository`
  - `init(fileURL: URL)`
  - `func load() -> [ShelfItem]`
  - `func save(_ items: [ShelfItem]) throws`
  - `static func defaultFileURL(fileManager: FileManager = .default) -> URL`

- [ ] **Step 1: Implement default container location**

Use `.applicationSupportDirectory` and append `NotchHub/Shelf/items.json`.

- [ ] **Step 2: Implement fail-closed load**

Missing/unreadable/corrupt JSON returns `[]` and never scans the filesystem.

- [ ] **Step 3: Implement atomic save**

Create the parent directory as needed, encode `[ShelfItem]`, write using `.atomic`.

- [ ] **Step 4: Run repository tests**

Expected: missing/corrupt/round-trip tests PASS.

---

### Task 4: Implement the event-driven `ShelfStore`

**Files:**
- Create: `Sources/NotchHubCore/Shelf/ShelfStore.swift`
- Test: `Tests/NotchHubCoreTests/ShelfStoreTests.swift`

**Interfaces:**
- Produces `@MainActor public final class ShelfStore: ObservableObject` with:
  - `@Published public private(set) var items: [ShelfItem]`
  - `@Published public private(set) var hasPersistenceError: Bool`
  - `func loadIfNeeded() async`
  - `func add(urls: [URL]) async`
  - `func remove(id: UUID) async`
  - `func resolve(_ item: ShelfItem) async -> ShelfBookmarkResolution?`

- [ ] **Step 1: Implement one-shot loading**

`loadIfNeeded()` calls actor persistence only once per store instance.

- [ ] **Step 2: Implement off-main explicit add preparation**

Use `Task.detached(priority: .userInitiated)` with the Sendable bookmark codec and value snapshots. Resolve existing bookmarks, build standardized URL identity set, preserve first-seen order, obtain `localizedName`/`isDirectory` resource values, create bookmarks, and return additions.

- [ ] **Step 3: Implement serial persistence after mutations**

After updating main-actor `items`, await the actor repository save. Catch save errors and set `hasPersistenceError=true`; a later successful save clears it.

- [ ] **Step 4: Implement stale refresh**

`resolve(_:)` performs bookmark resolution off-main. If refreshed bytes are returned, replace only that item's bookmark and persist the updated collection before returning the resolution.

- [ ] **Step 5: Run store tests**

Expected: dedup/order/invalid-item/removal/stale-refresh/error-state tests PASS.

---

### Task 5: Add bounded first-party destination state

**Files:**
- Create: `Sources/NotchHubCore/UI/NotchDestinationModel.swift`
- Test: `Tests/NotchHubCoreTests/NotchDestinationModelTests.swift`

**Interfaces:**
- Produces:
  - `public enum NotchDestination: Equatable, Sendable { case home, shelf }`
  - `@MainActor public final class NotchDestinationModel: ObservableObject`
  - `public private(set) var destination: NotchDestination`
  - `public func select(_:)`
  - `public func reset()`

- [ ] **Step 1: Implement exact state transitions**

Default Home; selecting Shelf changes only destination; reset always returns Home.

- [ ] **Step 2: Run destination tests**

Expected: PASS.

---

### Task 6: Add the App-layer Shelf surface and explicit resource actions

**Files:**
- Create: `Sources/NotchHubApp/Shelf/ShelfView.swift`
- Modify: `Sources/NotchHubCore/UI/NotchRootView.swift`
- Modify: `Sources/NotchHubApp/MediaNotchRootView.swift`
- Modify: `Sources/NotchHubApp/AppDelegate.swift`
- Create: `Tests/NotchHubCoreTests/ShelfUIPolicyTests.swift`

**Interfaces:**
- Consumes `ShelfStore`, `NotchDestinationModel`, existing Expanded presentation/layout.
- Produces accessibility identifiers:
  - `shelf.surface`
  - `shelf.addFiles`
  - `shelf.emptyDropZone`
  - `shelf.home`
  - `media.openShelf`
  - `home.openShelf`

- [ ] **Step 1: Write UI source-policy tests first**

Assert the stable identifiers exist, `NSOpenPanel` allows files + directories + multiple selection, Shelf source does not contain `removeItem`, `trashItem`, `moveItem`, periodic timers, or global NSEvent monitors.

- [ ] **Step 2: Make the Home Shelf tile actionable**

Add an optional `onSelectShelf` closure to `NotchRootView` (default no-op for existing factory compatibility) and make only the Shelf tile a plain button with `home.openShelf`.

- [ ] **Step 3: Implement `ShelfView`**

Use the approved header/empty/list layout. `Add Files…` uses nonblocking `NSOpenPanel.begin`; local drag/drop uses SwiftUI `dropDestination(for: URL.self)` and accepts only file URLs. No global observer.

- [ ] **Step 4: Implement explicit actions with balanced security scope**

For Open / Show in Finder: await `store.resolve`, call `startAccessingSecurityScopedResource`, invoke `NSWorkspace`, and defer `stopAccessingSecurityScopedResource` only when start returned true. Remove only calls `store.remove(id:)`.

- [ ] **Step 5: Route only Expanded to Shelf**

`MediaNotchRootView` renders Shelf iff presentation is Expanded and destination is `.shelf`; otherwise existing media/Home logic remains. Add a small Shelf button to Expanded media controls. On any change away from Expanded call `destinationModel.reset()`.

- [ ] **Step 6: Compose one store/model in `AppDelegate`**

Create long-lived `NotchDestinationModel` and `ShelfStore`, pass them to the media root, and call `loadIfNeeded()` asynchronously after launch.

- [ ] **Step 7: Run all Swift tests**

Expected: PASS.

---

### Task 7: Add the least-privilege entitlement and update exact policy gates

**Files:**
- Modify: `Resources/NotchHub.entitlements`
- Modify: `scripts/security-audit.sh`
- Modify: `scripts/shipping_media_acceptance.py`
- Modify: `.github/workflows/ci.yml`
- Modify: `.github/workflows/personal-release.yml`
- Modify: `.github/workflows/trusted-release.yml`
- Create: `Tests/NotchHubCoreTests/ShelfSecurityPolicyTests.swift`
- Modify as required: tests that intentionally assert the shipping app's old one-key entitlement set.

**Interfaces:**
- Shipping exact entitlement set becomes `{app-sandbox: true, files.user-selected.read-only: true}`.
- Media probe/candidate helper binaries retain their existing exact entitlement policies.

- [ ] **Step 1: Write security policy tests first**

Parse `Resources/NotchHub.entitlements` source and assert read-only user-selected access is present while read-write/Downloads/all-files are absent. Assert security/release CI files know the exact two-key shipping set.

- [ ] **Step 2: Add read-only entitlement**

Add only `com.apple.security.files.user-selected.read-only = true` next to app sandbox.

- [ ] **Step 3: Update exact shipping entitlement checks**

Change shipping app assertions in security audit, shipping acceptance, ordinary CI packaging, Personal Release, and Trusted Release to the exact two-key dictionary. Do not change separate probe/candidate entitlement checks.

- [ ] **Step 4: Run security/release tests and CI**

Expected: all existing security gates pass with the new explicitly reviewed least-privilege entitlement and continue to reject unexpected additional keys.

---

### Task 8: Document implementation state and physical acceptance protocol

**Files:**
- Create: `docs/testing/M2_1_SHELF_FOUNDATION_ACCEPTANCE.md`
- Modify: `docs/PROJECT_STATE.md`
- Modify: `docs/ROADMAP.md`
- Modify: `CHANGELOG.md`
- Modify: `SECURITY.md`
- Modify: `docs/ARCHITECTURE.md`

**Interfaces:**
- Records implementation/automated-test status without claiming physical acceptance, merge, or release before they occur.

- [ ] **Step 1: Add acceptance checklist**

Document the exact physical cases from the spec, including persistence after relaunch, source-file survival after Remove, duplicate handling, drag/drop, media coexistence, permissions, and idle CPU observation.

- [ ] **Step 2: Update architecture/security docs**

Record Shelf actor/store/bookmark boundaries and the exact new read-only entitlement justification.

- [ ] **Step 3: Update state/roadmap/changelog conservatively**

Mark M2.1 **IMPLEMENTED / AUTOMATED-TESTED / AWAITING PHYSICAL ACCEPTANCE** only after required CI is green. Do not mark accepted/merged/released.

---

### Task 9: Final PR verification

**Files:** none unless verification finds defects.

- [ ] **Step 1: Review PR diff against the design spec**

Check every spec requirement maps to code/test/docs and verify no boring.notch implementation text/code was copied.

- [ ] **Step 2: Inspect all required GitHub Actions**

Required checks: `Build, test and package`, `macOS 26 compatibility`, `macOS UI regression`; also inspect security/release-policy steps inside the build job.

- [ ] **Step 3: Fix any failures test-first**

For a defect, add/adjust the smallest failing regression test before changing production code, then re-run CI.

- [ ] **Step 4: Stop before merge**

Leave the PR open for the required target-Mac physical acceptance. Merge/release only after the product owner reports the physical checklist PASS.
