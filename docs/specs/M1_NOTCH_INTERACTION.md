# M1 Notch interaction requirements

Status: **IMPLEMENTED IN PR #10 / REVISED HARDWARE ACCEPTANCE PENDING**
Primary target: MacBook with hardware notch, macOS 26.6

This document is the behavioral contract for delayed hover activation, trackpad haptic feedback, and the notch-adjacent visual surface in M1. The implementation must follow TDD and preserve the security/performance contracts of the project.

The deterministic implementation exists in PR #10. An initial physical cycle confirmed the interaction logic but exposed two visual regressions: expanded controls were not visible during the active hover state, and compact black corner pixels visually squared the physical notch. The revised candidate fixes those defects and therefore requires a short target-Mac retest before acceptance.

## 1. Delayed hover activation

### Goal

Moving the pointer through the hardware-notch region on the way to another display must not immediately open NotchHub. Deliberate hover should still feel fast.

### Required behavior

- Entering the compact activation region starts a **single cancellable dwell**.
- The activation region is intentionally slightly inset from the physical notch bounding box so grazing the lower/side edge is not treated as deliberate intent.
- The current target-Mac candidate inset is **4 pt** on each edge; this is a UX candidate, not a platform invariant.
- The panel remains compact until the dwell threshold is reached.
- Leaving the activation region before the threshold cancels the pending activation immediately.
- A cancelled activation must never fire later because of a stale callback/race.
- Re-entering after cancellation starts a fresh dwell.
- Duplicate `mouseMoved` events while one dwell is pending must not create additional timers/tasks.
- No activation dwell is started while the panel is already expanded.
- Setup-time/current-pointer synchronization is non-activating; launching while the pointer already overlaps the notch must not schedule dwell by itself.
- Retention/collapse behavior remains independent from the activation dwell.

### Initial timing

The current dwell candidate is **120 ms**, with a tuning range around **100–150 ms** based only on real-hardware evidence. The first target-Mac interaction cycle did not report the dwell itself as a failure, so 120 ms remains unchanged for the revised candidate.

The threshold must be represented by a named policy/configuration value, not scattered as a magic number.

### Performance requirements

- Event-driven only: no polling and no repeating timer.
- At most one pending activation task/timer may exist.
- Pending work is cancelled on pointer exit, state invalidation, or controller teardown.
- The implementation must not broaden input observation beyond what is already security-approved merely to implement the delay.
- Tests must use an injected clock/scheduler or equivalent deterministic abstraction; unit tests must not use arbitrary real sleeps.

## 2. Haptic feedback on successful expansion

### Goal

When a deliberate hover actually expands the panel, the Force Touch trackpad should provide one short tactile confirmation.

### API and safety boundary

Use only the public AppKit haptics API through `NSHapticFeedbackManager.defaultPerformer`. AppKit exposes feedback patterns, not an arbitrary strength scalar.

The first target-Mac cycle confirmed that haptic feedback works but requested a slightly more noticeable feel. The revised candidate therefore changes the single public pattern from `.generic` to **`.levelChange`**. It must remain one request per successful activation; do not simulate greater strength with repeated/double haptics.

Timing should remain synchronized with the actual visual state transition. Exact tactile feel is accepted only on real hardware because macOS may legitimately vary or suppress feedback depending on current device, touch state, accessibility, and user preferences.

Do not implement custom low-level trackpad drivers, private haptic APIs, synthetic input, Accessibility tricks, audio imitation, or background haptic loops.

### Required behavior

Haptic feedback is emitted **exactly once** when all conditions are true:

1. activation was initiated by an actual user pointer event entering/remaining in the compact activation region;
2. the dwell threshold completed without cancellation;
3. the state actually transitions `compact -> expanded`.

No haptic feedback is emitted for quick/cancelled transit, duplicate movement, expanded retention, setup/programmatic/layout-driven presentation changes, screen reconfiguration by itself, collapse, or stale callbacks after cancellation.

## 3. Physical notch visual contract

The application must augment the physical notch, not redraw its bounding rectangle in a way that degrades the native silhouette.

Required behavior on hardware-notch displays:

- compact mode must not paint black pixels into the visible rounded-corner cutouts surrounding the physical notch;
- the native physical notch therefore retains its real rounded contour in compact mode;
- expanded primary controls must be visible **while the pointer is intentionally holding the panel open**, not only during collapse/exit;
- expanded interactive content starts below the physical notch occlusion with a small safe spacing;
- the revised candidate uses `compactFrame.height + 12 pt` as the expanded top-content inset on a hardware-notch display;
- non-notch displays retain an opaque compact fallback surface and the normal 20 pt expanded content inset;
- AppKit panel frame and SwiftUI presentation must not animate independently into visibly different states. The revised interaction-core candidate uses an immediate AppKit frame update; polished animation and Reduced Motion behavior remain a later dedicated M1 hardening step.

## 4. Test-first design

The production state machine remains separable from AppKit event delivery. Time and haptic output use deterministic test doubles.

Minimum automated interaction scenarios include:

1. quick transit before threshold stays compact with zero haptic;
2. deliberate hover expands only after threshold;
3. successful hover requests exactly one haptic;
4. duplicate movement does not duplicate pending work/haptic;
5. cancelled activation cannot fire from a stale callback;
6. re-entry starts a fresh dwell;
7. expanded retention does not retrigger haptic;
8. collapse then a later deliberate hover may haptic once again;
9. invalidation cancels pending work;
10. setup-time pointer synchronization does not activate or haptic;
11. a point only 2 pt inside the physical compact edge does not activate with the revised policy;
12. a point 4 pt inside the compact edge does activate;
13. hardware-notch layout resolves transparent compact background behavior and an expanded content inset below the occluded region;
14. no-notch fallback remains opaque with its normal content inset.

## 5. Implementation evidence — 2026-08-08

Core RED -> GREEN evidence remains:

- RED CI #147/#148: interaction APIs absent before production implementation;
- RED CI #150: pointer-monitor lifecycle seam absent before implementation;
- GREEN interaction implementation uses one cancellable `DispatchWorkItem` through `DispatchQueue.main.asyncAfter`, generation/stale-callback protection, explicit monitor ownership, and public AppKit haptics;
- CI #157 correctly rejected a 356 B executable-size overrun; the P0 budget was not widened;
- CI #158 returned the candidate under the existing budget;
- independent review found setup-time activation/haptic risk; RED CI #165 and GREEN CI #167 closed it.

Hardware-feedback revision evidence:

- first physical cycle reported all requested interaction checks otherwise PASS but exposed two additional visual defects: hidden expanded controls during active hover and compact corner pixels visually squaring the notch;
- RED CI #172 established the new hardware-notch visual policy did not yet exist;
- initial visual implementations passed correctness/security checks but CI #177, #181, and #187 rejected their executable/app footprint against the unchanged P0 size budget;
- the budget was never widened; the visual design was simplified instead, including removing independent frame/view animation from this interaction-core path;
- CI #188 passed all gates with executable `251,856 B`, app `254,853 B`, DMG `83,143 B`;
- RED CI #189 then proved the previous edge-grazing activation behavior by failing `compactPointerJustInsidePhysicalEdgeDoesNotActivate`;
- GREEN CI #191 on source head `ab782262c16163742bb115671f7908255fc08e4a` passed **27/27 Swift tests**, release/performance policy, runtime performance audit, security baseline, packaging/signature/Sandbox/Hardened Runtime/DMG checks, and the unchanged size budget;
- CI #191 sizes: executable `251,856 B`, app `254,853 B`, DMG `83,117 B`;
- the production haptic candidate now uses one `.levelChange` public AppKit feedback request.

Shared-runner CPU/RSS/thread values remain compatibility/schema evidence only and are not target-Mac performance acceptance data.

## 6. Real-hardware acceptance

Stable target-Mac IDs:

- `NH-HOVER-DELAY-001`: normal cross-display transit through/near the notch stays compact with zero haptic.
- `NH-HOVER-DELAY-002`: deliberate hover expands once after the accepted dwell/depth threshold with no oscillation.
- `NH-HAPTIC-001`: successful deliberate expansion produces one appropriately noticeable physical haptic on a compatible Force Touch trackpad.
- `NH-HAPTIC-002`: quick/cancelled hover, retention movement, and collapse produce no haptic.
- `NH-VISUAL-001`: compact mode preserves the physical notch's native rounded silhouette; no app-painted black corner pixels make it appear square.
- `NH-VISUAL-002`: while deliberately hovering the expanded panel, the primary controls are visible below the notch and do not appear only after pointer exit/collapse begins.

The revised candidate also requires regression confirmation of `NH-NOTCH-001` and `NH-HOVER-001/002/003`.

## 7. Definition of done

This interaction slice is complete only when:

- deterministic RED-first coverage remains green;
- production behavior stays event-driven and cancellation-safe;
- security capability is not broadened;
- performance policy and the existing size budget remain green;
- target-Mac `NH-NOTCH-001`, `NH-HOVER-001/002/003`, `NH-HOVER-DELAY-001/002`, `NH-HAPTIC-001/002`, and `NH-VISUAL-001/002` pass on macOS 26.6;
- final accepted dwell, activation inset, and haptic pattern are recorded in project state/testing/changelog.

The revised implementation is deterministic-CI ready but is **not yet physically accepted** until that short retest is complete.
