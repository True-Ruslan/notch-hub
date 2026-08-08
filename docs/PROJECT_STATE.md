# Project state

Last updated: 2026-08-08
Current version: `0.1.0` (Personal Release published and accepted)
Repository visibility: **Public**
Primary physical target: macOS `26.6`
Protected branch target: `main`
P0 merge commit: `a056aa74bad5d8e193eb4c76a76e6c910344bd09`
Public-readiness hardening merge: `23500e099a0f8b2738f1157c6ae3be71c89df6e1`
Current product milestone: M1 `Notch Core hardening and interaction` — **IN PROGRESS**
Active implementation PR: #10 `M1 delayed hover and haptic interaction core` — **CURRENT SLICE HARDWARE ACCEPTED / INTEGRATION PENDING**

## Product

NotchHub is a personal, native, local-first macOS productivity hub built around the MacBook notch. Planned modules are Shelf, Snippets, Calendar, Translator, and media controls with Yandex Music as the primary player.

NotchNook is a public product/UI research reference only; NotchHub remains an independent implementation.

## Accepted foundation

### M0 — Engineering foundation

Status: **ACCEPTED AND MERGED**.

Accepted target-Mac evidence:

- `NH-OS26-001`: PASS;
- `NH-NOTCH-001`: PASS;
- `NH-HOVER-001`: PASS;
- `NH-HOVER-002`: PASS;
- `NH-HOVER-003`: PASS.

M0 includes the Swift 6 native shell, public notch geometry, deterministic pointer policy, AppKit-owned panel sizing, App Sandbox + Hardened Runtime, zero third-party Swift runtime dependencies, strict CI/security/package gates, and accepted real-hardware regression fixes.

### R0.1 — Personal Release

Status: **ACCEPTED**.

Immutable `v0.1.0` was published from accepted commit `8e913dcddfdec7d9aa920df8c37afb23b8c40884` and passed downloaded-release acceptance on the target MacBook/macOS 26.6. Personal Release remains ad-hoc signed, sandboxed, Hardened Runtime protected, checksum/provenance verified, and intentionally not notarized. Trusted Release remains an optional future tier.

### P0 — Performance Foundation

Status: **ACCEPTED AND MERGED**.

Accepted target-Mac baseline on macOS 26.6 / `Mac16,8`:

- `NH-PERF-IDLE-001`: CPU median/max `0.0% / 0.7%`, RSS median/max `33,648 / 33,808 KiB`, threads `4 / 4`;
- `NH-PERF-HOVER-001`: CPU median/max `5.95% / 22.3%`, RSS median/max `38,456 / 38,816 KiB`, threads `6 / 7`;
- `NH-PERF-STABILITY-001`: CPU median/max `0.0% / 6.8%`, RSS median/max `30,992 / 34,384 KiB`, threads `3 / 7`;
- 10-minute stability RSS delta `-3,712 KiB`, with no sustained memory/thread growth.

Accepted immutable `v0.1.0` artifact baseline:

- executable `220,560 B`;
- app aggregate `223,555 B`;
- DMG `73,955 B`.

Runtime CPU/RSS/thread limits remain target-Mac acceptance gates. Shared GitHub runners never substitute for physical resource evidence. Artifact byte sizes are deterministic and enforced in CI with the unchanged P0 budget: 15% relative allowance plus the accepted absolute ceilings.

### P0.1 — Public repository readiness

Status: **ACCEPTED**.

Public-source hardening is merged. Ordinary public pull-request CI remains read-only/unprivileged; Personal Release publication is isolated from untrusted PR execution; Trusted Release remains dormant without Apple credentials/environment.

## M1 interaction and transition hardening

Status: **CURRENT INTERACTION / TRANSITION SLICE HARDWARE ACCEPTED**.

Authoritative requirements: `docs/specs/M1_NOTCH_INTERACTION.md`.
Initial dwell/haptic plan: `docs/superpowers/plans/2026-08-08-m1-pointer-dwell-haptics.md`.
Transition/animation hardening plan: `docs/superpowers/plans/2026-08-08-m1-transition-animation-hardening.md`.

### Interaction intent layer

`NotchInteractionCoordinator` owns pointer-intent timing/cancellation. It does not own panel geometry, presentation animation, content rendering, or haptic output.

Accepted/implemented invariants:

- one cancellable one-shot compact -> expanded dwell;
- **accepted dwell: `120 ms`**;
- compact activation requires **4 pt inward depth on left, right and bottom only**;
- **no top inset**: a deliberate pointer held against the exact top screen edge above the notch remains eligible for activation;
- compact hit-testing uses explicit inclusive directional bounds instead of `CGRect.contains`, because Core Graphics excludes `maxX`/`maxY` edges from rectangle membership;
- duplicate movement cannot create duplicate pending activation;
- leaving before threshold cancels immediately;
- generation validation makes cancelled/stale callbacks harmless;
- re-entry starts a fresh full dwell;
- expanded retention/collapse is independent from activation dwell;
- setup/current-pointer synchronization is non-activating;
- one `DispatchWorkItem` via `DispatchQueue.main.asyncAfter`; no polling or repeating timer.

The exact top-edge geometry is now physically accepted through `NH-HOVER-TOP-001` on the exact CI #332 artifact.

### Single transition authority

`NotchPanelTransitionCoordinator` is the sole owner of compact/expanded presentation transitions.

It owns:

- explicit `compact`, `expanding`, `expanded`, and `collapsing` lifecycle phases;
- desired presentation independent from currently staged SwiftUI content;
- expanded content retention during collapse until the matching animation completes;
- cancellation/reversal through generation validation so stale completions cannot win;
- exactly-once haptic eligibility for a deliberate user expansion;
- programmatic expansion without haptic;
- animation-policy retarget while a transition is in flight without a second haptic.

`NotchPanelController` has no competing direct presentation `setFrame` path. `NotchPanelModel` represents content presentation only.

### AppKit animation and visual ownership

Panel animation uses public system APIs only:

- `NSAnimationContext` + `panel.animator().setFrame(...)` for the window frame;
- `CABasicAnimation(keyPath: "cornerRadius")` for backing-layer corner radius;
- shared `.easeInEaseOut` timing;
- **accepted standard duration: `0.20 s`**;
- Reduced Motion resolves duration to `0`, applying the exact endpoint synchronously;
- cancellation freezes the current Core Animation presentation-layer corner radius into the model layer before removing the animation, preventing a radius jump during reversal;
- no display link, frame timer, polling loop, custom interpolation loop, or private animation API.

Outer clipping remains AppKit-owned. The hardware-notch compact surface is opaque black; continuous corner radii remain `12 pt` compact / `22 pt` expanded; the hosting view follows panel width and height while `sizingOptions == []` keeps window geometry AppKit-owned.

### Reduce Motion

`NotchPanelController`, already an `NSObject`, observes `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification` through the selector-based `NotificationCenter` API.

The controller caches the current boolean only to suppress duplicate policy updates. On an actual value change it asks the transition coordinator to retarget the current desired presentation. Teardown removes the observer explicitly.

This replaced a block-observer/token object after size attribution showed unnecessary runtime metadata/closure cost. No accessibility permission or entitlement is requested; this is a public display accessibility preference exposed by AppKit.

### Pointer event hot path

The current narrow input boundary remains exactly one local and one global `.mouseMoved` monitor with explicit ownership and idempotent removal.

The monitor does not allocate `Task { @MainActor ... }` for every mouse-move event. AppKit event-monitor callbacks are delivered on the main thread, so delivery uses `MainActor.assumeIsolated` synchronously. This removes avoidable hot-path task allocation without broadening the observed event mask or permissions.

The global `.mouseMoved` fallback remains intentionally in place until the separate `NSTrackingArea` / window-local experiment proves equal-or-better target-Mac correctness and resource behavior.

### Haptic policy

**Accepted physical feedback:** one public AppKit `.levelChange` request for a successful deliberate compact -> expanded activation.

No haptic is requested for quick/cancelled transit, duplicate pointer movement, retention, collapse, startup synchronization, programmatic expansion, stale completion, or Reduce Motion retargeting. Reversal does not create a second haptic merely because an in-flight transition changes direction.

## Broad hardware acceptance — CI #319 candidate

The broad M1 hardware acceptance used source SHA `f6de06f5d045fc9375b3b31b0a7feb97a13cebe4`, exact-head CI #319 / run `31257399497`, artifact `NotchHub-dmg` ID `9021802122`.

Target MacBook/macOS 26.6 results reported on 2026-08-08:

- `NH-NOTCH-001`: **PASS**;
- `NH-HOVER-001/002/003`: **PASS**;
- `NH-HOVER-DELAY-001`: **PASS** for cross-display transit, with a product refinement requested for deliberate single-display top-edge activation;
- `NH-HOVER-DELAY-002`: **PASS** — `120 ms` feels correct;
- `NH-HAPTIC-001/002`: **PASS** — `.levelChange` accepted;
- `NH-VISUAL-001/002`: **PASS**;
- `NH-VISUAL-003`: **PASS** after repeated cycles;
- `NH-ANIM-001`: **PASS**;
- `NH-ANIM-002/003`: **PASS**;
- `NH-ANIM-004`: **PASS**;
- `NH-MOTION-001`: **PASS**;
- `NH-MOTION-002`: **PASS**;
- startup with pointer already over notch: **PASS** — no automatic activation/haptic;
- accepted tuning: `120 ms` dwell, `.levelChange` haptic, `0.20 s` animation, 4 pt side/bottom activation depth.

This accepted the interaction, visual, animation, reversal, haptic, startup and Reduce Motion architecture on the target hardware. The only requested follow-up was the exact top-edge activation geometry described below.

## Top-edge activation refinement — hardware finding and corrective TDD

Product requirement from the accepted hardware cycle:

- with no second monitor in use, deliberately pushing the cursor to the **very top screen edge** over the notch should still open NotchHub;
- therefore the compact activation zone has **no top inset**;
- the accepted `4 pt` inward protection remains on **left, right and bottom**;
- cross-display quick transit must remain protected by the `120 ms` dwell.

Initial follow-up:

- RED `f4d19fc7e508fe11a35aae6fb56f80e0fa7ec13e` / CI #320 established the asymmetric 4/4/4/0 geometry;
- GREEN `c7c10033d223197309eafeba63e67b30ae29ba33` / CI #321 passed 52/52 Swift tests;
- clean documented source `969a7c52203adf7e3dd8bb5f198a6895b2fb7f7a` / CI #325 passed all automated gates and produced artifact `9022296152`;
- target-Mac `NH-HOVER-TOP-001` on that artifact **FAILED**: holding the pointer against the exact top screen edge did not open the panel.

Root cause:

- the CI test named as a top-edge test actually used `compactFrame.maxY - 1`, not the exact edge;
- production delegated compact membership to `CGRect.contains`;
- Core Graphics rectangle membership includes minimum edges but excludes maximum X/Y edges, so a real point at `pointer.y == compactFrame.maxY` was rejected;
- this was a test-model defect and a production boundary-semantics defect, not a dwell, monitor, animation or haptic failure.

Corrective TDD:

- RED source `3d0d40b5426cb8a8fe0bd19393688a68247637b0` / CI #326 changed the test to exact `y == compactFrame.maxY` and added exact accepted left/right 4 pt boundary checks;
- CI #326 ran 54 tests and failed only the three new exact-boundary assertions while all prior behavior remained green;
- GREEN source `9022ab55221070b4899853fffd3dc6709384ab1b` / CI #327 replaced compact `CGRect.contains` with explicit inclusive directional comparisons;
- CI #327 passed **54/54 Swift tests**, macOS 26 compatibility, release/security/performance/package/signature/Sandbox/Hardened Runtime/DMG checks and the unchanged P0 size budget;
- CI #327 sizes: executable `250,320 B`, app `253,317 B`, DMG `84,679 B`.

## Final targeted hardware acceptance — CI #332 candidate

The corrected exact artifact used source SHA `6d4c13739216503ec97fe3e71eada0fc9b32f298`, CI #332 / run `31260116337`, `NotchHub-dmg` artifact ID `9022551570`, digest `sha256:f79a01f5dd65f6056d3021231667ac15cb7f340d32c4fc8bf383ccea0723a758`.

Target MacBook/macOS 26.6 results reported on 2026-08-08:

- `NH-HOVER-TOP-001`: **PASS** — holding the pointer at the exact top edge over the notch activates once after the accepted dwell;
- `NH-HOVER-DELAY-001`: **PASS** — quick cross-display transit remains compact and produces no haptic.

This accepts the final compact activation geometry as **inclusive 4 pt left/right/bottom, inclusive 0 pt top**, while preserving the accepted `120 ms` dwell and cross-display protection. No broad hardware rerun is required because the corrective change was limited to compact hit-test boundary semantics and both directly affected physical gates passed on the exact artifact.

The hardware acceptance is tied to source `6d4c13739216503ec97fe3e71eada0fc9b32f298`.

## Final acceptance-record verification

Documentation-only acceptance head `705ed9f5ce6dbb706def2c1bcf28519e488e998a` passed CI #337 / run `31260754621`:

- macOS 26 compatibility: PASS;
- **54/54 Swift tests**: PASS;
- **16/16 release-policy tests**: PASS;
- **22/22 performance-policy tests**: PASS;
- security/performance audits: PASS;
- App Sandbox + Hardened Runtime + ad-hoc signature: PASS;
- system-only dynamic linkage and DMG integrity: PASS;
- unchanged P0 artifact-size budget: PASS;
- exact sizes: executable `250,320 B`, app `253,317 B`, DMG `84,684 B`.

No production source changed after the physically accepted CI #332 artifact, so no additional physical run is required before integration.

## Security baseline

`SECURITY.md` remains authoritative. M1 adds no runtime entitlement, telemetry, analytics, networking, subprocess/shell, dynamic loading, private API, privileged helper, Accessibility/Input Monitoring permission, synthetic input, or broader global input capture. Global observation remains exactly `.mouseMoved`; pointer coordinates/history are not persisted.

## Known limitations / technical debt

- target-Mac runtime ceilings still derive from one canonical run per scenario with conservative headroom;
- the narrow global `.mouseMoved` fallback remains and must be evaluated separately against `NSTrackingArea` / window-local tracking;
- GitHub-hosted runner resource values are not representative of the target Mac;
- active-display migration, Spaces/fullscreen, screen-configuration handling, notchless mode, click/pin policy, gestures, product modules, and optional trusted distribution remain later work.

## Next optimal step

1. PR #10 can move to Ready for Review: hardware acceptance and exact-head deterministic verification are complete for the current slice.
2. Integrate PR #10 only after the explicit branch-integration decision required by repository workflow.
3. After this interaction slice is merged, run the measured `NSTrackingArea` / window-local pointer experiment against accepted `NH-PERF-HOVER-001` before deciding whether the global `.mouseMoved` fallback can be removed.
4. Continue M1 with active-display migration, Spaces/fullscreen, screen-configuration changes, click/pin, and gestures.
