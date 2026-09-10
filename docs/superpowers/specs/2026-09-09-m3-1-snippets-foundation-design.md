# M3.1 Snippets Foundation — Design

## Status

Approved product design for the first Snippets slice. This document intentionally keeps M3.1 small: a sandbox-local text snippet store with explicit user-driven copy, no clipboard observation/history, no direct paste into other applications, and no new entitlement or permission.

Lifecycle target:

**implemented → automated-accepted → merged → released**

## Goal

Add a first-class Snippets module to the Expanded NotchHub surface so the user can create, edit, persist, copy, and delete short reusable text snippets without widening NotchHub's current authority or introducing background work.

## Product scope

M3.1 includes:

- Home → Snippets routing in Expanded;
- Snippets access while media is active in Expanded;
- local persisted text snippets;
- Add;
- Edit;
- explicit Copy;
- explicit Delete with confirmation;
- return to Home/media;
- destination reset when leaving Expanded;
- deterministic automated routing and persistence coverage.

M3.1 deliberately does **not** include:

- clipboard observation, history, polling, or auto-capture;
- reading from the system clipboard;
- direct paste into another application;
- Accessibility, Automation/Apple Events, Input Monitoring, Screen Recording, or any new permission;
- global keyboard shortcuts;
- search, tags, favorites, folders, drag reordering, import/export, cloud sync, sharing, or collaboration;
- URL fetching, WebKit, metadata lookup, or automatic URL opening;
- rich text, images, files, or attachments;
- a separate Snippets window;
- third-party dependencies.

Text/URL snippets belong to M3; Shelf remains file/folder-only.

## Data model

`SnippetItem` is a small value type in `NotchHubCore`:

```swift
public struct SnippetItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var text: String
    public let createdAt: Date
    public var updatedAt: Date
}
```

No separate title is stored in M3.1. The UI derives a compact display title from the first non-empty line of `text`, falling back to `Untitled snippet` only for presentation. Avoiding an independent title field keeps persistence and editing semantics simple and avoids introducing an unnecessary synchronization/migration problem.

The store rejects creation of a snippet whose `text.trimmingCharacters(in: .whitespacesAndNewlines)` is empty. When editing an existing snippet, an empty trimmed value is rejected rather than silently deleting the item.

Text itself is preserved exactly as entered; validation only decides whether a save is allowed.

## Persistence

Snippets use a dedicated actor-backed repository, independent from Shelf:

```text
Application Support/
  NotchHub/
    Snippets/
      snippets.json
```

The on-disk shape is versioned from the first release:

```swift
struct SnippetArchive: Codable, Equatable, Sendable {
    let schemaVersion: Int
    var items: [SnippetItem]
}
```

M3.1 writes `schemaVersion == 1` atomically using `Data.write(..., options: .atomic)`.

`SnippetPersistenceRepository` behavior:

- missing file → empty archive;
- malformed JSON → empty items plus a load-error signal to the store;
- unsupported schema version → empty items plus a load-error signal;
- save failure → preserve in-memory state and expose a bounded persistence-error flag;
- no periodic retry timer;
- no filesystem scan or watcher.

The repository is an actor so file IO cannot race across explicit user actions.

## Store

`SnippetStore` is `@MainActor ObservableObject` and owns UI-facing state only.

Public behavior:

```swift
func loadIfNeeded() async
func add(text: String, now: Date = .now) async -> Bool
func update(id: UUID, text: String, now: Date = .now) async -> Bool
func remove(id: UUID) async
```

Rules:

- `loadIfNeeded()` runs once per store lifecycle;
- add appends a new item with matching `createdAt` / `updatedAt`;
- update preserves `id` and `createdAt`, changing only text and `updatedAt`;
- remove deletes only the local snippet record;
- persistence happens only after explicit mutation;
- no autosave timer, debounce timer, polling, background task, or clipboard observer;
- `hasPersistenceError` is bounded observable state and clears after the next successful load/save.

## Clipboard boundary

Copy is explicit and write-only.

Core exposes a narrow injectable boundary:

```swift
@MainActor
public protocol SnippetClipboardWriting {
    @discardableResult
    func write(_ text: String) -> Bool
}
```

The shipping AppKit implementation is `SystemSnippetClipboardWriter` and may only:

1. obtain `NSPasteboard.general`;
2. call `clearContents()`;
3. call `setString(text, forType: .string)`.

It must not call clipboard read APIs or observe clipboard state. Specifically M3.1 must not use `string(forType:)`, `data(forType:)`, `propertyList(forType:)`, `pasteboardItems`, `readObjects(...)`, `changeCount`, notifications, timers, or polling to inspect clipboard contents.

Copy failure is local to the action. It must not mutate the snippet or widen permissions.

No Accessibility/direct-paste path is introduced.

## Routing and composition

`NotchDestination` expands from:

```swift
.home
.shelf
```

to:

```swift
.home
.shelf
.snippets
```

`NotchDestinationModel` remains the only first-party content-destination owner. It still does not own panel geometry or transitions.

The current `ShelfRoutingRootView` becomes a generic product routing surface (planned name: `ProductRoutingRootView`) because it now routes more than Shelf. This is a targeted refactor required by the new module; media rendering remains independent of Snippets state.

Routing rules:

- Expanded + `.home` → existing media-aware/Home content;
- Expanded + `.shelf` → `ShelfView`;
- Expanded + `.snippets` → `SnippetsView`;
- Compact/Peek/non-expanded → existing content semantics and destination reset to `.home`;
- active Expanded media exposes bounded Shelf and Snippets navigation controls without moving module state into `NotchHubMediaCore`.

Core environment actions remain narrow and main-actor bound:

- existing `NotchSelectShelfAction`;
- new `NotchSelectSnippetsAction`.

The Home Snippets tile becomes a real button using the new environment action.

## Snippets UI

`SnippetsView` is native SwiftUI inside the existing Expanded panel.

Minimum surface:

- header with `Snippets` and Home button;
- Add button;
- empty state when no snippets exist;
- list of saved snippets ordered by insertion order;
- each row shows a derived one-line title/preview and up to a small bounded body preview;
- row actions: Copy, Edit, Delete;
- editor mode uses a `TextEditor` in the same Expanded surface with Save and Cancel;
- Delete uses a native confirmation dialog/alert before mutation.

M3.1 does not create a new `NSWindow`, popover, floating panel, or global hotkey.

Accessibility identifiers are stable and deterministic:

- `home.openSnippets`
- `media.openSnippets`
- `snippets.surface`
- `snippets.home`
- `snippets.add`
- `snippets.empty`
- `snippets.editor`
- `snippets.editor.text`
- `snippets.editor.save`
- `snippets.editor.cancel`
- per-item Copy/Edit/Delete identifiers derived from the item UUID.

## Composition root

`AppDelegate` owns one `SnippetStore` for application lifetime and injects it into product routing.

Production persistence uses `SnippetPersistenceRepository.defaultFileURL()`.

UI-test builds use an isolated temporary Snippets path scoped by process identifier, matching the existing Shelf isolation principle. UI tests therefore never read or mutate the real user's snippet database.

`SystemSnippetClipboardWriter` is injected at the App composition boundary. External XCUI tests do not click Copy, so the canonical runner never modifies the real system clipboard.

## Security and privacy

M3.1 adds no entitlement and no new macOS permission.

Shipping entitlements remain exactly the pre-M3.1 set required by existing features:

- `com.apple.security.app-sandbox = true`;
- `com.apple.security.files.user-selected.read-only = true`.

The second entitlement remains solely for Shelf user-selected files. Snippets use the app's own sandbox Application Support container and require no file entitlement.

M3.1 adds no:

- network client/server entitlement;
- direct network/WebKit request;
- clipboard read/monitoring/history;
- Accessibility/Automation/Input Monitoring/Screen Recording;
- global `NSEvent` monitor;
- timer/polling/filesystem watcher;
- subprocess;
- third-party runtime dependency;
- telemetry/analytics/logging of snippet contents.

Snippet text is sensitive local user content. Production code must not print/log snippet text or include it in diagnostics, crash metadata, analytics, or build artifacts.

## Performance and energy

Idle recurring work added by M3.1: **none**.

Runtime work occurs only on:

- explicit module navigation;
- one initial store load when the Snippets surface first needs data (or at app composition if implementation remains one-shot and negligible);
- explicit Add/Edit/Delete persistence;
- explicit Copy.

No timer, polling loop, file watcher, clipboard watcher, background task, or continuous text processing is allowed.

The existing feature-size budget remains the target. If canonical CI proves M3.1 legitimately exceeds it, any new budget must be evidence-based from that exact CI artifact, preserve the immutable original baseline, and include a narrow reviewed headroom rather than silently increasing historical budgets.

## Error handling

- missing persistence file is normal empty state;
- malformed/unsupported archive is fail-closed to empty UI with `hasPersistenceError = true`;
- failed save keeps in-memory state visible and marks persistence error; it does not retry in background;
- invalid blank Add/Edit stays in editor and performs no persistence;
- failed clipboard write leaves snippet unchanged;
- UI navigation errors cannot affect media runtime or panel transition ownership.

## Automated acceptance

M3.1 acceptance must include:

### Core tests

- `SnippetItem` Codable round-trip;
- schema-v1 persistence round-trip;
- missing file → empty/no error;
- corrupt/unsupported archive → empty + bounded error;
- atomic save behavior through repository contract;
- one-shot load;
- Add/Edit/Delete semantics;
- blank Add/Edit rejection;
- persistence failure flag/recovery;
- `.snippets` destination selection/reset.

### Clipboard/security policy

- fake `SnippetClipboardWriting` proves Copy is write-only and explicit;
- production writer source contains only write-side `NSPasteboard` operations;
- dedicated policy test rejects clipboard read APIs, `changeCount`, clipboard polling/observer patterns, direct network APIs, new global monitors, direct paste/Accessibility additions, and snippet-content logging;
- exact shipping entitlement policy remains unchanged.

### UI/routing policy

- Home Snippets tile is actionable;
- media Expanded exposes Snippets navigation;
- Snippets routing is outside media internals;
- collapse/reset returns destination to Home;
- UI-test persistence path is isolated from the user's Application Support store.

### External application XCUI

At minimum:

1. Expanded Home → Snippets → Home;
2. Expanded media → Snippets → Home/media restored;
3. Snippets destination resets after collapse/re-expand.

XCUI must not automate system clipboard reads/writes, Accessibility, external paste, or other OS-level side effects.

### Canonical CI

The exact final PR head must pass all required repository jobs, including:

- macOS 26 compatibility / warnings-as-errors;
- complete Swift tests;
- external application UI regression;
- release/security/performance/media policy tests;
- source/security audit;
- release DMG build;
- App Sandbox/Hardened Runtime/effective entitlements;
- provenance and deterministic size gate;
- performance harness compatibility.

## Release and stacking policy

M3.1 is developed on `feat/m3-1-snippets-foundation`, stacked on automated-accepted M2.3 head `250193b616522ca161b5116957497a26a6aac35d` while the existing release/merge chain is still blocked by publication of prepared `v0.6.0`.

Do not merge M3.1 ahead of its dependency chain. Once `v0.6.0` is published and M2.2/M2.3 are merged, retarget/rebase M3.1 onto the resulting protected `main`, re-evaluate the effective diff, and obtain fresh exact-head CI before merge if the head/base changes.
