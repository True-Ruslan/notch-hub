# M2.1 Shelf Foundation Implementation Plan

> **Acceptance policy changed 2026-09-08 by product owner:** NotchHub is personal-use only. Physical acceptance is no longer a merge/release blocker. The authoritative gate is strong automated acceptance.

**Goal:** Implement the first persistent, read-only, security-scoped file Shelf and bounded Home/Shelf routing inside the existing NotchHub panel.

**Architecture:** Preserve panel geometry and media lifecycle. Add a first-party destination model in `NotchHubCore`, actor-backed Shelf persistence plus security-scoped bookmark codec/store, and App-layer SwiftUI `ShelfView`. A separate `ShelfRoutingRootView` wraps the unchanged media root so Compact/Peek remain media-first and Shelf can replace only Expanded content. All file access is user-selected, read-only, short-lived, and event-driven.

**Tech Stack:** Swift 6, SwiftUI, AppKit (`NSOpenPanel`, `NSWorkspace`), Foundation security-scoped bookmarks, Swift Testing, XCUITest, existing GitHub Actions/macOS packaging pipeline.

**Spec:** `docs/superpowers/specs/2026-09-08-m2-1-shelf-foundation-design.md`

## Global constraints

- Primary target: macOS 26.6; package deployment floor remains macOS 14.
- NotchHub remains MIT; do not copy GPL-3.0 boring.notch source/tests/implementation-specific structures.
- Shipping entitlements are exactly `com.apple.security.app-sandbox=true` plus `com.apple.security.files.user-selected.read-only=true`.
- MediaBridgeProbe uses its own exact sandbox-only entitlement file.
- Do not add read-write file access, Accessibility, Input Monitoring, Automation, Screen Recording, network, Bluetooth, camera, microphone, global drag/keyboard/scroll monitors, or dynamic code loading.
- Do not add Shelf polling/timers/background filesystem scanners.
- `NotchPanelController` / `NotchPanelTransitionCoordinator` remain sole geometry/transition authorities.
- Remove from Shelf never deletes/moves/renames the source file.
- Bookmark/persistence filesystem work stays off the main actor; UI state changes stay on the main actor.

---

## Task 1 — Lock core contracts with RED tests

**Files:**
- `Tests/NotchHubCoreTests/ShelfItemTests.swift`
- `Tests/NotchHubCoreTests/ShelfPersistenceRepositoryTests.swift`
- `Tests/NotchHubCoreTests/ShelfStoreTests.swift`
- `Tests/NotchHubCoreTests/NotchDestinationModelTests.swift`

- [x] Add tests before production types.
- [x] Capture compile RED from missing M2.1 symbols in CI.
- [x] Add compile-only skeletons.
- [x] Capture behavioral RED for empty persistence/store implementations.

Evidence: CI history on PR #88 contains both compile RED and behavioral RED before GREEN implementation.

---

## Task 2 — Security-scoped data model and codec

**Files:**
- `Sources/NotchHubCore/Shelf/ShelfItem.swift`
- `Sources/NotchHubCore/Shelf/ShelfBookmarkCodec.swift`

- [x] Implement minimal `ShelfItem` (`id`, bookmark bytes, display name, directory flag).
- [x] Create bookmarks with `.withSecurityScope` + `.securityScopeAllowOnlyReadAccess`.
- [x] Resolve with `.withSecurityScope`.
- [x] Return refreshed bookmark bytes when stale.
- [x] Keep source paths out of persisted model/logging.

---

## Task 3 — Actor-backed atomic persistence

**Files:**
- `Sources/NotchHubCore/Shelf/ShelfPersistenceRepository.swift`

- [x] Default Application Support location under `NotchHub/Shelf/items.json`.
- [x] Missing/corrupt store fails closed to empty collection.
- [x] Atomic JSON writes.
- [x] No fallback filesystem scan.

---

## Task 4 — Event-driven ShelfStore

**Files:**
- `Sources/NotchHubCore/Shelf/ShelfStore.swift`

- [x] One-shot load.
- [x] Explicit-event add preparation off main actor.
- [x] Duplicate suppression by resolved standardized URLs.
- [x] Preserve first-seen order.
- [x] Invalid bookmark isolation.
- [x] Serial persistence after mutations.
- [x] Bounded persistence-error state.
- [x] Stale bookmark replacement/persistence.
- [x] Remove only changes Shelf collection.

---

## Task 5 — Bounded first-party destination model

**Files:**
- `Sources/NotchHubCore/UI/NotchDestinationModel.swift`

- [x] `.home` / `.shelf` only.
- [x] Default Home.
- [x] Explicit selection.
- [x] Reset to Home.

---

## Task 6 — App-layer Shelf surface and routing

**Files:**
- `Sources/NotchHubApp/Shelf/ShelfView.swift`
- `Sources/NotchHubApp/Shelf/ShelfRoutingRootView.swift`
- `Sources/NotchHubCore/UI/NotchRootView.swift`
- `Sources/NotchHubApp/AppDelegate.swift`
- `Tests/NotchHubCoreTests/ShelfUIPolicyTests.swift`

Implementation refinement versus the initial plan: `MediaNotchRootView` is intentionally **not modified**. A separate routing layer wraps it, reducing media regression risk and making the isolation machine-checkable.

- [x] Capture UI-policy RED while `ShelfView`/routing do not exist.
- [x] Implement stable accessibility identifiers.
- [x] Make existing Home Shelf tile actionable through a bounded environment action.
- [x] Add `NSOpenPanel` configured for files, folders and multi-selection.
- [x] Add local SwiftUI URL drop target only.
- [x] Add Open / Show in Finder / Remove actions.
- [x] Balance `startAccessingSecurityScopedResource` / stop only for explicit Open/Reveal actions.
- [x] Add `ShelfRoutingRootView` to replace content only in Expanded + Shelf destination.
- [x] Add small Expanded-media Shelf action in the router overlay.
- [x] Suppress hidden-media scroll handling while Shelf is selected.
- [x] Reset destination when leaving Expanded.
- [x] Isolate UI-test Shelf persistence from real user data.

---

## Task 7 — Least-privilege entitlement and exact policy gates

**Files:**
- `Resources/NotchHub.entitlements`
- `Resources/MediaBridgeProbe.entitlements`
- `scripts/build-media-bridge-probe-app.sh`
- `scripts/security-audit.sh`
- `scripts/shipping_media_acceptance.py`
- `.github/workflows/ci.yml`
- `.github/workflows/personal-release.yml`
- `.github/workflows/trusted-release.yml`
- `Tests/NotchHubCoreTests/ShelfSecurityPolicyTests.swift`
- legacy feature-policy tests that assert the shared shipping entitlement baseline

- [x] Add security RED requiring exact shipping two-key set and negative entitlement assertions.
- [x] Add user-selected read-only to shipping app only.
- [x] Split MediaBridgeProbe to a dedicated exact sandbox-only entitlement file.
- [x] Keep production media candidate policy separate.
- [x] Update security audit exact dictionaries.
- [x] Update CI signed-package exact dictionary.
- [x] Update Personal Release exact dictionary.
- [x] Update Trusted Release exact dictionary.
- [x] Update shipping preflight collector exact dictionary.
- [x] Preserve negative checks for read-write/network/Automation/broad file authority.

---

## Task 8 — Automation-first UI acceptance

**Files:**
- `Tests/UITests/NotchHubUITests.swift`
- `docs/testing/M2_1_SHELF_FOUNDATION_ACCEPTANCE.md`

- [x] Add real external-app XCUI test: Expanded Home → Shelf → Home.
- [x] Add real external-app XCUI test: Expanded Media → Shelf → Media.
- [x] Verify hidden media transport controls disappear while Shelf owns Expanded.
- [x] Add real external-app XCUI collapse → Compact → re-expand destination-reset test.
- [ ] Confirm all new and existing XCUI tests GREEN on macOS 26 final SHA.
- [ ] Record exact final CI/run evidence in acceptance document.

System picker/file mutations are deliberately not automated at UI level. Bookmark/persistence/file-mutation semantics remain deterministic core/security tests; exact signed package entitlements are verified separately. This gives stronger signal than flaky system-dialog/TCC UI automation.

---

## Task 9 — Performance and package regression gate

- [ ] Confirm warnings-as-errors build GREEN on macOS 26 final SHA.
- [ ] Confirm full Swift test suite GREEN.
- [ ] Confirm security audit GREEN.
- [ ] Confirm probe/candidate builds and entitlement isolation GREEN.
- [ ] Confirm release DMG builds and codesign/Hardened Runtime checks GREEN.
- [ ] Confirm shipping preflight/provenance/system-library checks GREEN.
- [ ] Confirm active feature-size budget still passes; if M2.1 legitimately exceeds the previous M7 feature budget, add a measured/provenanced M2.1 budget rather than weakening the global baseline.
- [ ] Confirm performance harness smoke GREEN.

---

## Task 10 — Documentation and repository state

**Files:**
- `docs/testing/M2_1_SHELF_FOUNDATION_ACCEPTANCE.md`
- `docs/PROJECT_STATE.md`
- `docs/ROADMAP.md`
- `CHANGELOG.md`
- `SECURITY.md`
- `docs/ARCHITECTURE.md`

- [ ] Document exact read-only Shelf boundary and probe entitlement isolation.
- [ ] Record product-owner automation-first acceptance decision.
- [ ] Record final test/CI evidence only after the final SHA is green.
- [ ] Mark M2.1 `IMPLEMENTED / AUTOMATED-ACCEPTED` before merge, never `MERGED` before GitHub confirms merge.

---

## Task 11 — Final PR verification and merge

- [ ] Review complete PR diff against design spec and clean-room licensing constraint.
- [ ] Inspect all final required GitHub Actions on exact head SHA.
- [ ] Inspect review threads/comments for unresolved defects.
- [ ] Fix any defect test-first and obtain fresh final GREEN CI.
- [ ] Mark PR ready for review.
- [ ] Merge only with the exact verified head SHA and required checks green.
- [ ] After merge, verify `main` CI before describing M2.1 as merged/accepted.

Final lifecycle for M2.1 and subsequent personal-use slices:

**implemented → automated-accepted → merged → released**.
