# Fullscreen / Spaces / notchless hardening

Status: **SPECIFICATION — IMPLEMENTATION FOLLOWS**.

## Motivation

M1's active-display/multi-monitor migration (accepted, PR #56) covers event-driven topology migration and, in its physical acceptance matrix, explicitly verified the no-notch/notchless-display fallback (item 8, PASS). What M1 deliberately left out of scope — and every M6.x milestone since has continued to defer — is a bounded correctness pass over two remaining real-world scenarios `docs/PROJECT_STATE.md`/`docs/ROADMAP.md` have carried as "deferred" since M1: **the panel's behavior while another app is fullscreen on the same display**, and **the panel's behavior across macOS Spaces switches**. Neither has ever been physically exercised or had its supporting configuration regression-locked by an automated test.

`NotchPanelController.configurePanel()` (`Sources/NotchHubCore/Notch/NotchPanelController.swift:389-400`) already sets the standard AppKit recipe for a utility panel that should survive both scenarios without further code:

```swift
panel.isFloatingPanel = true
panel.becomesKeyOnlyIfNeeded = true
panel.hidesOnDeactivate = false
panel.level = .statusBar
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
```

`.canJoinAllSpaces` keeps the panel present on every Space instead of being tied to whichever Space was active at launch. `.fullScreenAuxiliary` is Apple's documented flag for exactly this case: a utility panel that should still appear over another app's fullscreen Space (without it, fullscreen apps get their own dedicated Space that ordinary windows/panels cannot join). `.stationary` keeps it out of Mission Control's window-shuffling and Exposé rearrangement. `.level = .statusBar` plus `styleMask: [.borderless, .nonactivatingPanel]` (panel init, line 85) keep it from stealing key focus or being treated as an activatable app window, so Space switches driven by clicking another app's window never route through NotchHub.

Two real gaps remain, and this slice is scoped to close exactly them:

1. **No automated regression lock.** No test anywhere constructs the real `NotchPanelController` panel and asserts `collectionBehavior`, `level`, `hidesOnDeactivate` or the panel's `styleMask`. A future refactor (e.g. simplifying `configurePanel()`, or a well-meaning "cleanup" removing what looks like a redundant flag) could silently regress fullscreen/Spaces support with every existing test still green, since none of them touch this configuration at all.
2. **No physical acceptance evidence.** M1's matrix tested connect/disconnect/reconfigure and the no-notch fallback, but never (a) another app running fullscreen on the notch display while NotchHub is interacted with, or (b) switching Spaces (including into/out of a fullscreen Space) while Compact/Peek/Expanded.

## Design

### No new runtime behavior anticipated

Unlike every prior M6.x slice, this one does not add new SwiftUI/AppKit behavior — the existing `configurePanel()` recipe is Apple's own documented pattern for this exact requirement, and it predates this slice (it shipped with the original M1 panel foundation). The work here is: lock the invariant with a real test, then physically confirm the recipe actually holds under real fullscreen/Spaces conditions on the target Mac. If physical testing finds a real defect (matching this project's now-repeated pattern — M6.8's `.repeatForever` freeze, M6.11's Peek clipping/seek-reset), fix it as a small follow-up in the same PR, the same way M6.11 did for defects acceptance found.

### Automated regression lock — real panel construction, not source-scanning

Unlike the SwiftUI-only files in `NotchHubApp` (which have no test target and rely on source-scanning policy tests), `NotchPanelController` lives in `NotchHubCore`, which is fully unit-tested, and `NotchPanelAnimationDriverTests`/`NotchInteractivePanelAnimationDriverTests` already construct real `NSPanel` fixtures directly in-process. This slice adds `NotchPanelController` construction to a new `NotchPanelSpacesFullscreenPolicyTests` (or extends an existing controller-level test file if one already exercises full construction) that:

1. Constructs a real `NotchPanelController` the same way production/other tests do (with test doubles for the model/coordinator dependencies it takes, mirroring existing test setup).
2. Asserts `panel.collectionBehavior` is exactly `[.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]`.
3. Asserts `panel.level == .statusBar`.
4. Asserts `panel.hidesOnDeactivate == false`.
5. Asserts `panel.styleMask` contains `.nonactivatingPanel` and `.borderless`, and does not contain `.titled`/`.closable`/`.resizable` (anything that would make it an activatable, closable, ordinary window).

These assert on the actual constructed object, not a source-text match, so they catch a regression regardless of how `configurePanel()` is refactored — the strongest test this project's existing pattern supports for a real AppKit side effect that cannot itself be driven fully in headless CI (Spaces/fullscreen transitions are a real WindowServer/Space-manager behavior that XCUIAutomation and unit tests cannot simulate).

### No source change expected, but not ruled out

If constructing this test reveals the invariant already holds (which is the expectation, since the code predates this slice unchanged), no production line changes. If physical testing surfaces a real defect — for example the panel losing pointer responsiveness after a Space switch, or `hidesOnDeactivate` interacting badly with a fullscreen transition — the fix stays scoped to `NotchPanelController`/the pointer-monitor boundary already governing interaction, per the existing "Existing constraints that remain authoritative" invariants M1 established (`NotchPanelTransitionCoordinator` remains the sole transition authority; no polling/timer/display-link/private API is introduced to chase this).

## Explicitly out of scope for this slice

- Any new Settings/preference for fullscreen/Spaces behavior — this is a correctness/regression-lock pass, not a new configurable feature.
- Re-testing multi-monitor connect/disconnect/reconfigure or the notchless-display fallback — already covered and accepted by M1's matrix; this slice only adds the two scenarios that matrix never exercised.
- Any change to `NotchScreenSelection`/`NotchPanelLayoutModel` topology-migration logic — unrelated to Spaces/fullscreen and already accepted.

## Acceptance

Automated: canonical CI green; full Swift test suite green; new `NotchPanelSpacesFullscreenPolicyTests` (real panel construction, not source-scanning) green; `scripts/performance_policy.py audit Sources` green with no new timer exception (no new runtime primitive is anticipated).

Physical, on exact `Mac16,8` in the current macOS `26.6` patch family, required before merge (this is explicitly a physical-verification slice; Spaces/fullscreen behavior is WindowServer-level and cannot be proven by CI):

1. With another app (e.g. a browser or Terminal) made fullscreen on the built-in hardware-notch display, NotchHub's Compact remains visible and hover-to-Peek/explicit-click-to-Expanded still work correctly over the fullscreen app.
2. Switching Spaces (left/right, including into and back out of the fullscreen Space from step 1) while NotchHub is settled Compact does not lose, duplicate, or misposition the panel on any Space.
3. Switching Spaces while settled Peek and while settled Expanded does not leave a stuck/stale surface; the panel reflects the correct state on whichever Space it is viewed from.
4. Switching Spaces mid-interaction (an in-flight hover dwell or interactive drag) does not crash, freeze, or leave the transition state machine in an inconsistent phase — the accepted-but-unverified topology-migration cancellation semantics from M1 are the closest existing precedent for how this should degrade.
5. No new Accessibility/Input Monitoring/Automation/Screen Recording permission prompt appears from any of the above.
6. No visible jank/frame drop introduced to ordinary hover/gesture responsiveness away from fullscreen/Spaces edge cases.
7. Clean post-Quit teardown, unaffected.
