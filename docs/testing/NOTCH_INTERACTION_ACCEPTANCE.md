# Notch interaction acceptance

Status: **ACCEPTED — PRIMARY M1 INTERACTION / TRANSITION SLICE**

Primary physical target: `Mac16,8` / macOS `26.6`.

This ledger makes the already accepted M1 interaction/transition contract canonical under `docs/testing/` for machine-readable regression traceability. It does **not** create new acceptance, change product semantics, or claim that historical physical evidence is already mapped to automated tests. Plan 2 Tasks 2–3 attach executable unit/integration/XCUI evidence to these stable IDs.

Authoritative behavioral specification: `docs/specs/M1_NOTCH_INTERACTION.md`.

## Stable acceptance IDs

| ID | Accepted contract | Status |
| --- | --- | --- |
| `NH-NOTCH-001` | Hardware-notch compact geometry/chrome matches the physical notch contract. | **PASS** |
| `NH-HOVER-001` | Deliberate compact hover reaches the accepted expansion path once. | **PASS** |
| `NH-HOVER-002` | Expanded retention does not spuriously collapse or re-expand while the pointer remains eligible. | **PASS** |
| `NH-HOVER-003` | Pointer exit from expanded retention returns the panel to compact once. | **PASS** |
| `NH-HOVER-DELAY-001` | Quick cross-display/pointer transit before dwell does not expand. | **PASS** |
| `NH-HOVER-DELAY-002` | Deliberate hover uses the accepted cancellable `120 ms` dwell. | **PASS** |
| `NH-HOVER-TOP-001` | Exact top screen edge at notch center is eligible with inclusive `maxY` semantics. | **PASS** |
| `NH-HAPTIC-001` | One eligible deliberate compact → expanded transition emits one `.levelChange` haptic request. | **PASS** |
| `NH-HAPTIC-002` | Cancelled transit, retention, collapse, startup sync and stale/reversed work do not emit duplicate expansion feedback. | **PASS** |
| `NH-VISUAL-001` | Compact hardware-notch surface remains opaque black with accepted visible chrome. | **PASS** |
| `NH-VISUAL-002` | Expanded content/chrome respects the accepted hardware-notch safe layout and clipping ownership. | **PASS** |
| `NH-VISUAL-003` | Repeated compact ↔ expanded cycles preserve rounded AppKit-owned chrome. | **PASS** |
| `NH-ANIM-001` | Normal expansion/collapse uses the accepted public AppKit/Core Animation transition contract. | **PASS** |
| `NH-ANIM-002` | Expansion → collapse reversal begins from the current visible state without stale endpoint ownership. | **PASS** |
| `NH-ANIM-003` | Collapse → expansion reversal begins from the current visible state without stale endpoint ownership. | **PASS** |
| `NH-ANIM-004` | Rapid/repeated transition activity keeps only the latest generation authoritative and preserves exact endpoints. | **PASS** |
| `NH-MOTION-001` | Reduce Motion resolves transition duration to zero and settles the desired exact endpoint. | **PASS** |
| `NH-MOTION-002` | In-flight Reduce Motion retarget remains lifecycle-safe and does not create a duplicate haptic. | **PASS** |
| `NH-SPACE-001` | Fullscreen/Spaces interaction policy is a later M1 hardening item. | **DEFERRED** |
| `NH-DISPLAY-001` | Active-display/multi-display migration is a later M1 hardening item. | **DEFERRED** |

## Frozen accepted behavior

The accepted M1 interaction baseline remains:

- compact activation protection is inclusive `4 pt` left/right/bottom and inclusive `0 pt` top;
- the exact top edge is eligible;
- deliberate hover dwell is `120 ms` and is cancellable/event-driven;
- eligible expansion haptic is one public AppKit `.levelChange` request;
- standard motion uses the accepted `0.20 s` ease-in-out public AppKit/Core Animation path;
- `NotchPanelTransitionCoordinator` is the sole presentation-transition authority;
- stale transition/dwell completions cannot win;
- Reduce Motion settles the current desired endpoint without duplicate haptic;
- pointer observation remains one local + one narrow global `.mouseMoved` fallback with explicit lifecycle ownership;
- no polling, repeating timer, display link, synthetic input, global scroll capture or sensitive input permission is part of M1.

## Historical physical evidence

Broad hardware acceptance was recorded on exact candidate `f6de06f5d045fc9375b3b31b0a7feb97a13cebe4` / CI #319 for the primary notch/hover/haptic/visual/animation/motion matrix.

The exact-top-edge defect was subsequently reproduced and corrected under RED → GREEN automation. Exact corrected candidate `6d4c13739216503ec97fe3e71eada0fc9b32f298` / CI #332, artifact `9022551570`, physically passed both:

- `NH-HOVER-TOP-001` — exact top screen-edge activation;
- `NH-HOVER-DELAY-001` — quick cross-display transit remains protected.

The detailed TDD history and physical observations remain in `docs/specs/M1_NOTCH_INTERACTION.md`, `docs/TESTING.md`, `CHANGELOG.md`, and Git history.

## Regression-backfill boundary

This ledger intentionally records **statuses only**. It does not fabricate automated evidence.

Plan 2 must next:

1. map accepted deterministic M1 contracts to the exact existing Swift test symbols whose assertions genuinely prove them;
2. add XCUI journeys only where lower layers cannot honestly prove the user-observable contract;
3. use `physicalOnlyReason` only for properties that remain genuinely hardware/compositor/haptic/real-permission dependent;
4. leave `NH-SPACE-001` and `NH-DISPLAY-001` deferred until their roadmap stages rather than treating them as accepted regression debt.
