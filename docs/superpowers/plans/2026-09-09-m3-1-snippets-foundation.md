# M3.1 Snippets Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a first-class sandbox-local Snippets module with Add/Edit/Delete and explicit write-only Copy, without clipboard observation, new permissions, network authority, polling, or background work.

**Architecture:** `NotchHubCore` owns the snippet value model, versioned actor-backed persistence, main-actor store, destination state, and clipboard-writing protocol. `NotchHubApp` owns native SwiftUI composition and the one AppKit `NSPasteboard` writer. The existing Shelf-specific routing wrapper is generalized to route Home/Shelf/Snippets while media internals remain module-independent.

**Tech Stack:** Swift 6 / Swift 6.3.3 CI toolchain, SwiftUI, AppKit, Combine, Swift Testing, XCTest/XCUITest, Foundation JSON persistence, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-09-m3-1-snippets-foundation-design.md`

## Global Constraints

- Primary product target: native macOS 26.6; package minimum remains macOS 14.
- Shipping entitlements remain exactly `com.apple.security.app-sandbox = true` and `com.apple.security.files.user-selected.read-only = true`.
- Snippets may not read/observe the clipboard, create clipboard history, or inspect `NSPasteboard.changeCount`.
- No Accessibility, Automation/Apple Events, Input Monitoring, Screen Recording, new file entitlement, or network entitlement.
- No direct network/WebKit API, subprocess, third-party runtime dependency, telemetry, or snippet-content logging.
- No timer, polling loop, filesystem watcher, global input monitor, or background retry.
- Text is sandbox-local under `Application Support/NotchHub/Snippets/snippets.json` and writes atomically.
- UI-test persistence is process-isolated and must never touch the user's real snippet database.
- External XCUI does not click Copy or perform any real system clipboard side effect.
- Follow strict TDD: every production behavior begins with a failing test/policy gate observed in canonical CI before minimal GREEN implementation.
- M3.1 remains stacked on M2.3 until the existing v0.6.0 → M2.2 → M2.3 merge chain completes.

---

### Task 1: Versioned snippet model and persistence

**Files:**
- Create: `Tests/NotchHubCoreTests/SnippetPersistenceRepositoryTests.swift`
- Create after RED: `Sources/NotchHubCore/Snippets/SnippetItem.swift`
- Create after RED: `Sources/NotchHubCore/Snippets/SnippetPersistenceRepository.swift`

**Interfaces:**
- Produces:
  - `SnippetItem: Codable, Equatable, Identifiable, Sendable`
  - `SnippetPersistenceLoad: Equatable, Sendable`
  - `SnippetPersisting: Sendable`
  - `SnippetPersistenceRepository: SnippetPersisting`
  - `SnippetPersistenceRepository.defaultFileURL(fileManager:)`

- [ ] **Step 1: Write the failing persistence tests**

Add tests that require these exact public APIs:

```swift
let item = SnippetItem(
    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
    text: "docker compose up -d",
    createdAt: Date(timeIntervalSince1970: 10),
    updatedAt: Date(timeIntervalSince1970: 20)
)

let repository = SnippetPersistenceRepository(fileURL: fileURL)
try await repository.save([item])
let load = await repository.load()
#expect(load.items == [item])
#expect(load.hadError == false)
```

Also assert:

```swift
#expect((await missingRepository.load()) == SnippetPersistenceLoad(items: [], hadError: false))
#expect((await corruptRepository.load()) == SnippetPersistenceLoad(items: [], hadError: true))
#expect((await unsupportedSchemaRepository.load()) == SnippetPersistenceLoad(items: [], hadError: true))
```

Decode the saved JSON in the test and assert top-level `schemaVersion == 1` and an `items` array exists.

- [ ] **Step 2: Obtain canonical RED**

Commit only the tests and push to the draft PR. Wait for canonical CI and confirm the Swift job fails because `SnippetItem`, `SnippetPersistenceLoad`, and `SnippetPersistenceRepository` do not exist. A syntax/configuration failure does not count as RED.

- [ ] **Step 3: Implement the minimal model and repository**

Create:

```swift
public struct SnippetItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var text: String
    public let createdAt: Date
    public var updatedAt: Date
}

public struct SnippetPersistenceLoad: Equatable, Sendable {
    public let items: [SnippetItem]
    public let hadError: Bool
}

public protocol SnippetPersisting: Sendable {
    func load() async -> SnippetPersistenceLoad
    func save(_ items: [SnippetItem]) async throws
}
```

Repository private archive:

```swift
private struct SnippetArchive: Codable {
    let schemaVersion: Int
    let items: [SnippetItem]
}
```

`load()` rules: missing file → `([], false)`; decode failure/schema other than 1 → `([], true)`. `save()` creates the parent directory and writes schema-v1 JSON with `.atomic`.

`defaultFileURL()` must resolve to `Application Support/NotchHub/Snippets/snippets.json`.

- [ ] **Step 4: Obtain canonical GREEN**

Confirm the exact implementation head passes the new persistence tests in macOS 26 compatibility. Also ensure existing Shelf tests remain green.

- [ ] **Step 5: Commit**

Commit message: `feat: add versioned Snippets persistence`

---

### Task 2: SnippetStore mutation semantics

**Files:**
- Create: `Tests/NotchHubCoreTests/SnippetStoreTests.swift`
- Create after RED: `Sources/NotchHubCore/Snippets/SnippetStore.swift`

**Interfaces:**
- Consumes: `SnippetItem`, `SnippetPersisting`, `SnippetPersistenceLoad`
- Produces:

```swift
@MainActor
public final class SnippetStore: ObservableObject {
    @Published public private(set) var items: [SnippetItem]
    @Published public private(set) var hasPersistenceError: Bool

    public func loadIfNeeded() async
    public func add(text: String, now: Date = .now) async -> Bool
    public func update(id: UUID, text: String, now: Date = .now) async -> Bool
    public func remove(id: UUID) async
}
```

- [ ] **Step 1: Write failing store tests**

Use a test actor implementing `SnippetPersisting` and cover separately:

1. one-shot load;
2. successful add creates one item, preserves exact text, and sets equal created/updated timestamps;
3. whitespace-only add returns `false`, mutates nothing, and performs no save;
4. update preserves `id` and `createdAt`, changes text and `updatedAt`;
5. whitespace-only update returns `false` without mutation/save;
6. unknown id update returns `false`;
7. remove persists only when an item actually existed;
8. load error sets `hasPersistenceError`;
9. successful later save clears `hasPersistenceError`;
10. save failure keeps the already-mutated in-memory state and sets the bounded error flag.

- [ ] **Step 2: Obtain canonical RED**

Commit tests only. Verify CI fails for the missing `SnippetStore` API rather than test syntax.

- [ ] **Step 3: Implement minimal `SnippetStore`**

Use `@MainActor`, a private `didLoad`, and no timer/task loop. Validation must use:

```swift
private func isValidSnippetText(_ text: String) -> Bool {
    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}
```

Do not trim stored text.

- [ ] **Step 4: Obtain canonical GREEN**

Verify the full new store suite passes and existing tests remain green.

- [ ] **Step 5: Commit**

Commit message: `feat: add Snippets store semantics`

---

### Task 3: Snippets destination and generic product routing contract

**Files:**
- Modify: `Tests/NotchHubCoreTests/NotchDestinationModelTests.swift`
- Create: `Tests/NotchHubCoreTests/SnippetRoutingPolicyTests.swift`
- Modify after RED: `Sources/NotchHubCore/UI/NotchDestinationModel.swift`
- Modify after RED: `Sources/NotchHubCore/UI/NotchRootView.swift`
- Create after RED: `Sources/NotchHubApp/ProductRoutingRootView.swift`
- Delete after replacement is compiling: `Sources/NotchHubApp/Shelf/ShelfRoutingRootView.swift`

**Interfaces:**
- `NotchDestination` adds `.snippets`.
- Core adds:

```swift
public struct NotchSelectSnippetsAction: Sendable {
    public init(_ action: @escaping @MainActor @Sendable () -> Void)
    @MainActor public func callAsFunction()
}
```

and environment value `notchSelectSnippetsAction`.

- `ProductRoutingRootView` becomes the app-level Home/Shelf/Snippets composition seam.

- [ ] **Step 1: Write RED destination/routing policy tests**

Extend the destination test:

```swift
model.select(.snippets)
#expect(model.destination == .snippets)
model.reset()
#expect(model.destination == .home)
```

Policy tests must assert source contracts:

- `NotchRootView` has an actionable Snippets button with `home.openSnippets` and invokes `onSelectSnippets()`;
- `ProductRoutingRootView` renders Snippets only when Expanded + `.snippets`;
- it injects both Shelf and Snippets environment actions into Home/media content;
- it resets destination outside Expanded;
- media source files do not import/reference `SnippetStore` or `NotchDestinationModel`.

- [ ] **Step 2: Obtain canonical RED**

Commit tests only and verify missing `.snippets`, `NotchSelectSnippetsAction`, and `ProductRoutingRootView` drive the expected failure.

- [ ] **Step 3: Implement destination/action/routing skeleton**

Add `.snippets`, add the new environment action, turn the existing Home Snippets tile into a plain `Button`, and create `ProductRoutingRootView` by extracting/generalizing the existing Shelf routing logic.

At this stage `ProductRoutingRootView` may accept a placeholder `snippetsContent` closure rather than concrete `SnippetsView`; no snippet production UI belongs in this task.

Suggested initializer boundary:

```swift
init(
    panelModel: NotchPanelModel,
    layoutModel: NotchPanelLayoutModel,
    mediaModel: ShippingMediaPresentationModel,
    destinationModel: NotchDestinationModel,
    shelfStore: ShelfStore,
    quickLookController: ShelfQuickLookController,
    shareController: ShelfShareController,
    @ViewBuilder snippetsContent: () -> SnippetsContent,
    @ViewBuilder homeContent: () -> HomeContent
)
```

The media overlay should use a small `HStack` with Shelf and Snippets buttons, identifiers `media.openShelf` and `media.openSnippets`.

- [ ] **Step 4: Obtain canonical GREEN**

Verify destination and routing policy tests pass without changes to media domain/transport behavior.

- [ ] **Step 5: Commit**

Commit message: `refactor: generalize product routing for Snippets`

---

### Task 4: Explicit write-only clipboard boundary and SnippetsView

**Files:**
- Create: `Tests/NotchHubCoreTests/SnippetClipboardPolicyTests.swift`
- Create: `Tests/NotchHubCoreTests/SnippetUIPolicyTests.swift`
- Create after RED: `Sources/NotchHubCore/Snippets/SnippetClipboardWriting.swift`
- Create after RED: `Sources/NotchHubApp/Snippets/SystemSnippetClipboardWriter.swift`
- Create after RED: `Sources/NotchHubApp/Snippets/SnippetsView.swift`

**Interfaces:**
- Produces:

```swift
@MainActor
public protocol SnippetClipboardWriting {
    @discardableResult
    func write(_ text: String) -> Bool
}

@MainActor
final class SystemSnippetClipboardWriter: SnippetClipboardWriting
```

`SnippetsView` consumes `SnippetStore`, `any SnippetClipboardWriting`, a top inset, and `onHome`.

- [ ] **Step 1: Write RED clipboard/security/UI policy tests**

The clipboard source-policy test must require production writer source to contain:

```swift
NSPasteboard.general
clearContents()
setString(text, forType: .string)
```

and reject these tokens across Snippets production source:

```text
string(forType:
data(forType:
propertyList(forType:
pasteboardItems
readObjects(
changeCount
Timer(
scheduledTimer
URLSession
WKWebView
addGlobalMonitorForEvents
AXIsProcessTrusted
NSAppleEventDescriptor
print(
NSLog(
```

The UI policy test requires identifiers from the spec and requires row actions to call explicit store/copy methods. It must also assert no system clipboard call exists directly in `SnippetsView.swift`; only the injected writer may own AppKit clipboard access.

- [ ] **Step 2: Obtain canonical RED**

Commit policy tests only. Verify they fail because the clipboard protocol/writer/view are absent.

- [ ] **Step 3: Implement the minimal clipboard writer**

Exactly:

```swift
@MainActor
func write(_ text: String) -> Bool {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    return pasteboard.setString(text, forType: .string)
}
```

No reads, history, observer, diagnostics, retry, or logging.

- [ ] **Step 4: Implement `SnippetsView`**

Use local `@State` editor state. Add and Edit both use the same in-surface editor with `TextEditor`; Save calls `SnippetStore.add` or `update`, Cancel discards draft state.

Derived row label helper:

```swift
private func displayTitle(for text: String) -> String {
    text.split(whereSeparator: \ .isNewline)
        .map(String.init)
        .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })?
        .prefix(60)
        .description ?? "Untitled snippet"
}
```

Implement Delete with a SwiftUI confirmation dialog/alert that stores only the pending UUID, never snippet content in logs/diagnostics.

Copy calls only `clipboardWriter.write(item.text)` and does not mutate persistence.

- [ ] **Step 5: Obtain canonical GREEN**

Verify clipboard/security/UI policy tests pass and canonical warnings-as-errors compilation accepts the SwiftUI/AppKit actor boundary.

- [ ] **Step 6: Commit**

Commit message: `feat: add local Snippets UI and explicit copy`

---

### Task 5: App composition, isolated UI-test storage, and external routing regression

**Files:**
- Modify: `Sources/NotchHubApp/AppDelegate.swift`
- Modify: `Sources/NotchHubApp/ProductRoutingRootView.swift`
- Modify: `Tests/UITests/NotchHubUITests.swift`
- Modify if needed for source policy: `Tests/NotchHubCoreTests/SnippetRoutingPolicyTests.swift`

**Interfaces:**
- `AppDelegate` owns one `SnippetStore` and one `SystemSnippetClipboardWriter` for app lifetime.
- Production path: `SnippetPersistenceRepository.defaultFileURL()`.
- UI-test path: `FileManager.default.temporaryDirectory/NotchHub-UITests-<pid>/Snippets/snippets.json`.

- [ ] **Step 1: Write RED external XCUI tests**

Add exactly these no-side-effect scenarios:

```text
testExpandedHomeRoutesToSnippetsAndBackWithoutClipboardSideEffects
testExpandedMediaCanExplicitlyRouteToSnippetsAndReturnToMedia
testSnippetsDestinationResetsAfterCollapseBeforeNextExpansion
```

Assert `snippets.surface`, `snippets.add`, `snippets.empty`, and `snippets.home`; do not click Copy and do not type sensitive content.

Update routing policy so `AppDelegate` must use a process-isolated Snippets path under `#if NOTCHHUB_UI_TESTING`.

- [ ] **Step 2: Obtain canonical RED**

Commit XCUI/policy tests before AppDelegate composition. Verify the expected missing Snippets routing/composition behavior fails.

- [ ] **Step 3: Implement AppDelegate composition**

Add a SnippetStore factory adjacent to ShelfStore, capture it in `applicationDidFinishLaunching`, instantiate one `SystemSnippetClipboardWriter`, and pass a concrete `SnippetsView` closure into `ProductRoutingRootView`.

Do not eagerly read the system clipboard and do not add termination work beyond releasing app-owned references.

- [ ] **Step 4: Obtain canonical GREEN**

Require:

- external application XCUI scenarios pass;
- existing Shelf routing/reset tests still pass;
- existing media and Settings XCUITests still pass;
- macOS 26 compilation/tests remain green.

- [ ] **Step 5: Commit**

Commit message: `feat: compose M3.1 Snippets into NotchHub`

---

### Task 6: Security/docs/acceptance and exact-head verification

**Files:**
- Create: `docs/testing/M3_1_SNIPPETS_FOUNDATION_ACCEPTANCE.md`
- Modify: `SECURITY.md`
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/ROADMAP.md`
- Modify PR body/metadata without changing source head after final evidence.
- Conditionally create only if canonical artifact proves necessary: `performance/m3-1-snippets-foundation-size-budget.json` and its policy test/gate update.

**Interfaces:**
- No new runtime interface; this task records and machine-enforces the final contract.

- [ ] **Step 1: Add acceptance/security architecture documentation**

Acceptance doc must distinguish:

```text
IMPLEMENTED / exact-head CI pending
```

until the final exact head actually passes.

Record:

- local-only sensitive text persistence;
- no snippet-content logging;
- write-only clipboard boundary;
- no clipboard history/read/observer;
- no new entitlement/permission/network/polling/global-monitor authority;
- UI-test storage isolation;
- XCUI intentionally avoids real clipboard side effects.

- [ ] **Step 2: Update ROADMAP without overstating merge/release status**

M3.1 may be marked implemented while its final CI is pending, then automated-accepted only after exact-head evidence. Do not mark merged/released until GitHub proves those states.

- [ ] **Step 3: Run final exact-head canonical CI**

Verify all three required jobs are `SUCCESS` on the exact current head:

1. `macOS 26 compatibility`;
2. `macOS UI regression` including external XCUI smoke;
3. `Build, test and package` including release/security/performance policy, source audit, warnings-as-errors, coverage, DMG, Hardened Runtime, App Sandbox/effective entitlements, provenance, deterministic artifact size, active size budget, performance harness, artifact uploads.

- [ ] **Step 4: Handle size only from evidence if required**

If and only if the existing active feature-size gate fails while all correctness/security checks are green, retrieve that exact run's deterministic artifact-size metadata. Create a new M3.1 provenance-backed budget using the immutable historical baseline plus a narrowly rounded allowance leaving approximately 40–50 KB headroom, following the M2.1 precedent. Add a policy test that validates exact provenance and keeps historical budgets immutable. Then obtain a new exact-head full GREEN run.

Do not increase a budget speculatively.

- [ ] **Step 5: Final review state**

Confirm:

- PR head has not moved since successful CI;
- unresolved review threads = 0;
- submitted blocking reviews = 0;
- PR is mergeable against its current stacked base;
- dependency/release ordering still blocks merge until v0.6.0 → M2.2 → M2.3 is integrated.

Update PR body with exact head SHA, CI run ID/number, 3/3 job evidence, security/performance result, lifecycle `IMPLEMENTED → AUTOMATED-ACCEPTED → NOT MERGED → NOT RELEASED`, then mark ready-for-review.

- [ ] **Step 6: Commit source documentation before the final verification run**

Commit message: `docs: record M3.1 Snippets acceptance contract`

PR-body evidence updates happen after the final GREEN run and must not modify the source head.

## Plan self-review result

- Spec coverage: all M3.1 product, persistence, routing, clipboard, security, UI-test isolation, XCUI, performance, and release-order requirements map to Tasks 1–6.
- Placeholder scan: no `TBD`, `TODO`, or unspecified implementation step remains.
- Type consistency: `SnippetItem`, `SnippetPersistenceLoad`, `SnippetPersisting`, `SnippetStore`, `SnippetClipboardWriting`, `.snippets`, `ProductRoutingRootView`, and accessibility identifiers are consistent across tasks.
- Scope remains one testable vertical subsystem slice; search/history/direct paste/sync are explicitly deferred.
