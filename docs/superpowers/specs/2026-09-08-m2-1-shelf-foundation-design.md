# M2.1 Shelf Foundation Design

Status: **APPROVED FOR IMPLEMENTATION — AUTOMATION-FIRST ACCEPTANCE**

## Context

M2 Shelf is the next product module after the media/performance/settings foundation. The implementation is informed by the observable product behavior and engineering lessons of `TheBoredTeam/boring.notch`, but NotchHub remains MIT-licensed while boring.notch is GPL-3.0. No boring.notch source code, tests, or implementation-specific code structure may be copied into NotchHub. This slice is a clean-room implementation against NotchHub's own architecture and requirements.

The current app is local-first, sandboxed, event-driven, media-first in Compact/Peek, and deliberately strict about permissions and resource use. M2.1 must preserve those properties.

On 2026-09-08 the product owner explicitly waived physical acceptance as a merge/release blocker for this personal-use application. From M2.1 onward, sufficiently strong automated acceptance is the authoritative gate unless a future feature explicitly reintroduces a required physical check.

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

The implementation uses a separate App-layer `ShelfRoutingRootView` around the existing media root. `MediaNotchRootView` remains unaware of `ShelfStore` and `NotchDestinationModel`. The router injects a bounded SwiftUI environment action for the existing Home Shelf tile and overlays one small `media.openShelf` action only while Expanded media is visible. While Shelf is selected, AppDelegate suppresses delivery of media scroll commands to the hidden media surface.

## Data model

`ShelfItem` is a Codable/Sendable value containing:

- `id: UUID`;
- `bookmarkData: Data`;
- `displayName: String`;
- `isDirectory: Bool`.

No source path is logged. The security-scoped bookmark is the authoritative persisted locator.

## App Sandbox and least privilege

Apple's App Sandbox requires User Selected File access for URLs selected through `NSOpenPanel`, and persistent re-access requires security-scoped bookmarks. M2.1 therefore adds exactly one new shipping entitlement:

- `com.apple.security.files.user-selected.read-only = true`.

The complete shipping entitlement set becomes exactly:

- `com.apple.security.app-sandbox = true`;
- `com.apple.security.files.user-selected.read-only = true`.

No read-write, Downloads, Full Disk Access, Accessibility, Input Monitoring, Automation/Apple Events, Screen Recording, network, camera, microphone, Bluetooth, or executable-file entitlement is added.

The development MediaBridgeProbe is intentionally split onto `Resources/MediaBridgeProbe.entitlements` and remains exactly sandbox-only. The Production Media Transport Candidate retains its existing separate entitlement policy. Shipping, probe, and candidate binaries therefore cannot accidentally inherit each other's entitlement expansion.

CI/release/security policy checks assert these exact sets rather than merely checking for presence of individual keys.

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

- Default file location: Application Support inside the app sandbox, under `NotchHub/Shelf/items.json`.
- The persisted payload is the minimal Codable `[ShelfItem]` array.
- Writes use atomic replacement.
- Missing store => empty Shelf.
- Corrupt/unreadable store => empty Shelf, fail closed, no crash.
- Save failures may leave the current in-memory view intact but surface a bounded store error flag; they never trigger fallback filesystem scanning.

Bookmark creation/resolution and resource-value lookup run off the main actor during explicit user operations. There is no timer, polling loop, or background scanner.

UI-test builds use an isolated per-process temporary Shelf persistence path so the real user's Shelf can never be read or mutated by automated UI regression tests.

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

- tray/download icon;
- short drop instruction;
- explicit statement that only a read-only reference is stored;
- local file-URL drop target.

Populated state:

- vertically scrollable compact rows;
- system file/folder icon;
- display name;
- Open;
- Show in Finder;
- Remove.

Stable accessibility identifiers cover the Shelf surface, primary controls, per-item actions, Home entry, and Expanded-media entry.

## Performance constraints

- zero periodic Shelf timers;
- zero idle filesystem polling;
- zero clipboard polling;
- zero global event monitors added by M2.1;
- persistence and bookmark preparation are explicit-event driven;
- main-thread work is limited to SwiftUI state updates, native picker presentation, and `NSWorkspace` user actions;
- no third-party runtime dependency is added;
- hidden media scroll commands are suppressed while Shelf is selected.

## Automated acceptance

Physical acceptance is intentionally **not** required for M2.1. The merge gate is the combined automated evidence below.

### Core behavioral evidence

- `ShelfItem` Codable round-trip;
- missing/corrupt persistence fallback;
- atomic persistence round-trip;
- duplicate suppression and first-seen ordering;
- multi-file add behavior;
- removal mutates only the Shelf collection;
- stale bookmark refresh updates persisted bookmark bytes;
- invalid bookmark isolation;
- persistence failure produces bounded error state;
- destination starts Home, selects Shelf, and resets Home.

### Security/policy evidence

- shipping entitlements are exactly sandbox + user-selected read-only;
- read-write, Downloads, broad file, network, Automation, camera/mic/Bluetooth entitlements are absent;
- MediaBridgeProbe remains exact sandbox-only on a separate entitlement file;
- Shelf sources contain no delete/move/trash authority, timer, global event monitor, URLSession, or network primitive;
- explicit Open/Reveal actions contain balanced start/stop security-scope calls;
- Store never holds security scope during idle;
- existing source-level security audit remains green.

### Real UI evidence

The exact external UI-test application on macOS 26 must automatically exercise:

- Expanded Home → Shelf → Home;
- presence of Shelf surface/Add/empty-state accessibility contracts;
- Expanded Media → Shelf → Media with hidden media controls unavailable while Shelf is active;
- collapse from Shelf → Compact → re-expand, proving destination resets to Home;
- all pre-existing hover/media/settings UI regressions.

Automated UI tests deliberately do not click the system `NSOpenPanel` or mutate arbitrary runner files. File/bookmark semantics are covered deterministically below the UI layer; this avoids flaky system-dialog/TCC automation while retaining exact signed-package entitlement verification.

### Package/release evidence

- macOS 26 build with warnings-as-errors;
- complete Swift test suite and coverage-instrumented suite;
- real external-app XCUI regression suite;
- security audit and workflow policy tests;
- effective signed shipping entitlement exact-set verification;
- Hardened Runtime and codesign verification;
- media helper/candidate isolation and provenance checks;
- system-library-only shipping executable check;
- DMG verification;
- feature-size/performance gates;
- no unresolved PR review defects.

Status progression from M2.1 onward is:

**implemented → automated-accepted → merged → released**.
