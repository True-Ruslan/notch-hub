# M2.1 Shelf Foundation — Automated Acceptance

Status: **IN PROGRESS — final exact-head CI evidence pending**

Date: 2026-09-08
PR: #88
Branch: `feat/m2-1-shelf-foundation`

## Acceptance policy

The product owner explicitly waived physical acceptance as a merge/release blocker for NotchHub because the application is personal-use only. M2.1 therefore uses automation-first acceptance.

The required lifecycle is:

**implemented → automated-accepted → merged → released**

`AUTOMATED-ACCEPTED` may be recorded only after every gate below is green on the exact final PR head SHA.

## Core behavior gates

Required deterministic Swift coverage:

- `ShelfItem` Codable round-trip;
- missing persistence store => empty Shelf;
- corrupt persistence => fail-closed empty Shelf;
- atomic persistence round-trip;
- duplicate add suppression;
- first-seen multi-file ordering;
- invalid existing bookmark isolation;
- remove mutates only Shelf collection/persistence;
- stale bookmark resolution refreshes stored bookmark bytes;
- persistence failure produces bounded error state;
- destination defaults Home, selects Shelf, resets Home.

## Security gates

Required exact policy:

- shipping app effective entitlements are exactly:
  - `com.apple.security.app-sandbox = true`;
  - `com.apple.security.files.user-selected.read-only = true`;
- MediaBridgeProbe effective entitlements remain exactly sandbox-only using its separate plist;
- production media candidate retains its separate reviewed entitlement contract;
- no user-selected read-write entitlement;
- no Downloads/broad file entitlement;
- no network client/server entitlement;
- no Automation/Apple Events entitlement;
- no camera/microphone/Bluetooth entitlement;
- no source-file delete/move/trash API in Shelf implementation;
- no Shelf timer, polling loop, global event monitor, URLSession, or network primitive;
- Open/Reveal use balanced short-lived security-scoped access;
- `ShelfStore` never arms security-scoped access while idle;
- security audit remains green.

## Real UI automation gates

The XCUITest suite launches the exact separately built UI-test application and must cover:

1. **Home routing**
   - launch shipping-smoke fixture;
   - explicitly expand;
   - `home.openShelf` exists;
   - click Shelf;
   - `shelf.surface`, `shelf.addFiles`, `shelf.emptyDropZone`, `shelf.home` exist;
   - click Home;
   - Expanded Home returns.

2. **Media routing**
   - launch deterministic media fixture;
   - explicitly expand;
   - media title is authoritative;
   - `media.openShelf` exists;
   - click Shelf;
   - Shelf surface exists;
   - hidden media transport controls are unavailable while Shelf owns Expanded;
   - click Home;
   - authoritative media surface returns.

3. **Destination reset**
   - open Shelf;
   - collapse by leaving panel;
   - wait for stable Compact;
   - explicitly expand again;
   - Shelf is absent and Home destination is restored.

All pre-existing media, hover, Settings and transition UI regression tests must remain green.

### Why system file-picker interaction is not an XCUI gate

The automated suite intentionally does not manipulate the system `NSOpenPanel` or arbitrary runner files. System-dialog/TCC automation is comparatively flaky and can introduce real machine side effects. The file semantics are instead split into deterministic layers:

- source-policy tests verify picker configuration (files + folders + multi-select) and local URL drop handling;
- core fake-codec tests verify persistence/dedup/stale bookmark behavior;
- source-policy tests prove Remove contains no filesystem mutation authority;
- signed-package checks prove the exact read-only user-selected entitlement actually reaches the built app.

This keeps the automation hermetic while still testing the security boundary that matters.

## macOS/package gates

Required on final SHA:

- macOS 26 warnings-as-errors build;
- full Swift test suite;
- coverage-instrumented Swift suite;
- real external-app macOS UI regression suite;
- Swift format strict lint;
- shell syntax validation;
- release/public-workflow policy tests;
- security audit;
- performance source audit;
- MediaBridgeProbe build/verification and archive round-trip;
- ProductionMediaTransportCandidate build/verification and archive round-trip;
- release NotchHub DMG build;
- exact source/media provenance checks;
- `codesign --verify --deep --strict`;
- Hardened Runtime flag;
- exact shipping effective entitlement dictionary;
- system-library-only executable check;
- no development media/performance tooling in shipping app;
- DMG verification;
- shipping-media preflight collector;
- deterministic artifact size collection;
- active feature-size budget;
- idle performance-harness compatibility smoke.

## Final evidence

To be filled only after the final PR head stops changing and its complete CI run is green:

- final PR head SHA: **PENDING**
- CI run number/id: **PENDING**
- macOS 26 compatibility: **PENDING**
- Build, test and package: **PENDING**
- macOS UI regression: **PENDING**
- total Swift tests: **PENDING**
- total XCUITests: **PENDING**
- effective shipping entitlements: **PENDING exact-package verification**
- feature-size gate: **PENDING**

Do not replace any `PENDING` value with a success claim until it is supported by the exact final GitHub Actions run.
