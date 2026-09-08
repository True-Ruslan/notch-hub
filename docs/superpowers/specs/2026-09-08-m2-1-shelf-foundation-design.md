# M2.1 Shelf Foundation Design

Status: **APPROVED FOR IMPLEMENTATION**

## Context

M2 Shelf is the next product module after the media/performance/settings foundation. The implementation is informed by the observable product behavior and engineering lessons of `TheBoredTeam/boring.notch`, but NotchHub remains MIT-licensed while boring.notch is GPL-3.0. No boring.notch source code, tests, or implementation-specific code structure may be copied into NotchHub. This slice is a clean-room implementation against NotchHub's own architecture and requirements.

The current app is local-first, sandboxed, event-driven, media-first in Compact/Peek, and deliberately strict about permissions and resource use. M2.1 must preserve those properties.

## Goal

Ship the first useful file Shelf: a persistent, sandbox-compatible, read-only collection of user-selected files/folders that is reachable from Expanded, supports native file selection and drag/drop, and never deletes or mutates source files.

## Product scope

M2.1 includes:

- a bounded first-party destination model with `home` and `shelf` only;
- explicit navigation to Shelf from Expanded Home and from Expanded media;
- a Shelf surface in the existing notch panel;
- `Add Files…` using `NSOpenPanel` with files/folders and multi-selection;
- file/folder drag-and-drop onto the visible Shelf surface using SwiftUI's local drop handling only;
- persistent security-scoped bookmarks;
- display name + file/folder distinction only as cached presentation metadata;
- duplicate suppression by resolving existing bookmarks and comparing standardized file URLs during explicit add operations;
- Open, Show in Finder, and Remove from Shelf actions;
- stale-bookmark refresh;
- failure of one invalid/unavailable item must not invalidate the whole Shelf;
- atomic local persistence inside the app container.

M2.1 does **not** include:

- text or URL snippets (reserved for M3 Snippets);
- clipboard observation/history;
- global drag, keyboard, scroll, modifier, or button monitoring;
- automatic Compact drag-to-open;
- AirDrop/share sheets;
- Quick Look;
- multi-selection inside Shelf;
- copy/move/rename/delete of source files;
- image/video conversion;
- linked-folder browsing;
- file promises from Mail/other apps;
- network access;
- plugin/dynamic extension loading.

## Navigation and media precedence

`NotchDestinationModel` owns only the first-party content destination, not panel geometry.

- Compact and Peek continue to use their existing media/Home behavior; Shelf is never rendered there.
- Expanded defaults to `home`.
- Explicit Shelf selection overrides Expanded media presentation while the selection is active.
- Leaving Expanded resets the destination to `home`.
- `NotchPanelController` and `NotchPanelTransitionCoordinator` remain the sole authorities for panel geometry and presentation transitions.
- No Shelf code may directly set `NSPanel` frames or create a second notch panel.

Expanded media gets one small Shelf action alongside its existing transport controls. Expanded Home turns the existing Shelf placeholder tile into a real button. Shelf provides an explicit Home/back action.

## Data model

`ShelfItem` is a Codable/Sendable value containing:

- `id: UUID`;
- `bookmarkData: Data`;
- `displayName: String`;
- `isDirectory: Bool`.

No source path is logged. The security-scoped bookmark is the authoritative persisted locator.

## App Sandbox and least privilege

Apple's App Sandbox requires the User Selected File capability for URLs selected through `NSOpenPanel`, and persistent re-access requires security-scoped bookmarks. M2.1 therefore adds exactly one new shipping entitlement:

- `com.apple.security.files.user-selected.read-only = true`.

The complete shipping entitlement set becomes exactly:

- `com.apple.security.app-sandbox = true`;
- `com.apple.security.files.user-selected.read-only = true`.

No read-write, Downloads, Full Disk Access, Accessibility, Input Monitoring, Automation/Apple Events, Screen Recording, network, camera, microphone, Bluetooth, or executable-file entitlement is added.

CI/release/security policy checks that previously asserted the exact sandbox-only shipping entitlement set must be updated to assert this exact two-key set. Development media probe/candidate entitlements remain unchanged where they describe separate binaries rather than the shipping NotchHub app.

## Security-scoped bookmark lifecycle

The production codec creates bookmarks with:

- `.withSecurityScope`;
- `.securityScopeAllowOnlyReadAccess`.

Resolution uses `.withSecurityScope` and reports whether the bookmark was stale. A stale bookmark is recreated and persisted before subsequent use.

For explicit file actions:

1. resolve the bookmark;
2. call `startAccessingSecurityScopedResource()` on the resolved URL;
3. perform exactly the requested Open/Show in Finder operation;
4. call `stopAccessingSecurityScopedResource()` iff the start call returned `true`.

The Shelf never keeps long-lived security-scope access armed in idle.

Removing an item only removes the persisted Shelf reference. It must not call FileManager deletion/move APIs and must not mutate the source file.

## Persistence

`ShelfPersistenceRepository` is an actor so JSON file I/O is not performed on the main actor.

- Default file location: Application Support inside the app sandbox, under a `NotchHub/Shelf/items.json` path.
- JSON is version-independent at M2.1 because the persisted payload is the Codable `[ShelfItem]` array and the schema is intentionally minimal.
- Writes use atomic replacement.
- Missing store => empty Shelf.
- Corrupt/unreadable store => empty Shelf, fail closed, no crash.
- Save failures may leave the current in-memory view intact but must be surfaced as a bounded store error flag; they must never trigger fallback filesystem scanning.

Bookmark creation/resolution and resource-value lookup run off the main actor during explicit user operations. There is no timer, polling loop, or background scanner.

## Duplicate policy

During an explicit add operation:

- resolve valid existing bookmarks;
- compare `standardizedFileURL` values against the newly selected/dropped URLs;
- preserve existing order;
- append only previously unseen files/folders;
- invalid existing bookmarks remain visible as their stored references and do not crash deduplication.

The implementation does not persist raw source paths solely for deduplication.

## UI

`ShelfView` is App-layer SwiftUI hosted inside the existing Expanded panel.

Header:

- Home/back button;
- `Shelf` title;
- `Add Files…` button.

Empty state:

- `tray` icon;
- short `Drop files here or choose Add Files…` instruction;
- local file-URL drop target.

Populated state:

- vertically scrollable compact rows;
- system file/folder icon;
- display name;
- Open;
- Show in Finder;
- Remove.

Stable accessibility identifiers are required for the Shelf surface and primary controls so macOS UI regression tests can exercise the real panel.

## Performance constraints

- zero periodic Shelf timers;
- zero idle filesystem polling;
- zero clipboard polling;
- zero global event monitors added by M2.1;
- persistence and bookmark preparation are explicit-event driven;
- main-thread work is limited to SwiftUI state updates, `NSOpenPanel` presentation, and `NSWorkspace` user actions;
- no third-party runtime dependency is added.

## Testing and acceptance

Automated coverage must include:

- `ShelfItem` Codable round-trip;
- missing/corrupt persistence fallback;
- atomic persistence round-trip;
- duplicate suppression;
- multi-file add order;
- removal only mutates the collection;
- stale bookmark refresh updates the stored bookmark;
- invalid bookmark isolation;
- destination starts Home, selects Shelf, and resets to Home when leaving Expanded;
- source-policy assertions for read-only entitlement, no read-write entitlement, no new global monitor/polling, and no file-delete/move authority in Shelf source;
- UI-source/accessibility contract tests;
- existing unit/media/security/performance/release tests remain green;
- macOS 26 compatibility job remains green;
- real UI regression job exercises opening Expanded Shelf and the empty-state controls without touching real user defaults/files.

Physical acceptance on the primary target is required before merge/release for:

- select one file and one folder using `Add Files…`;
- relaunch and confirm persistence;
- Open and Show in Finder;
- Remove and confirm the original source remains untouched;
- drag one/multiple Finder items onto visible Shelf;
- duplicate add does not duplicate;
- collapse/re-expand returns to Home;
- media continues working in Compact/Peek and Shelf can explicitly override Expanded media;
- no unexpected privacy permission prompts;
- CPU remains quiescent in idle Shelf/Home states.

Status progression remains: **implemented → automated-tested → physically-accepted → merged → released**.
