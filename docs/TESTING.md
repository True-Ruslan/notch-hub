# Testing

## Goal

Automate every deterministic behavior that can be validated reliably. Manual acceptance is reserved for physical notch geometry, real pointer feel, compositor/window-animation continuity, physical haptic feel, exact macOS trust/permission surfaces, third-party app integration, and target-hardware resource measurements.

A green pipeline is necessary but is not proof of real-device UX or target-Mac efficiency. Manual success likewise never replaces deterministic automated coverage that can reasonably exist.

## Required CI gate

Protected-branch check: `Build, test and package`, dependent on `macOS 26 compatibility`.

Current CI validates:

1. Swift package structure.
2. deterministic Personal/Trusted release-policy tests.
3. deterministic performance-policy/parser/aggregation/budget tests.
4. strict Swift formatting.
5. shell/plist syntax.
6. executable repository security baseline.
7. deterministic runtime performance-policy source audit.
8. macOS 26 compilation with warnings as errors.
9. macOS 26 complete Swift test suite.
10. packaging-runner compilation with warnings as errors.
11. complete Swift tests with coverage instrumentation, including state/reversal stress.
12. release app/DMG packaging.
13. semantic version/build-number stamping.
14. ad-hoc code-signature verification.
15. Hardened Runtime verification.
16. exact effective App Sandbox entitlement verification.
17. linked-library inspection; system libraries only at the current milestone.
18. DMG integrity through `hdiutil verify`.
19. deterministic executable/app/DMG byte-size capture.
20. fail-closed comparison against `performance/baseline-v0.1.0.json`.
21. short development-harness compatibility/schema smoke on a shared runner, with no CPU/RAM magnitude gate.
22. artifact upload.

Do not lower assertions, delete useful tests, weaken security/release/performance policy, widen accepted budgets, or weaken production behavior merely to make CI green.

## Policy boundaries

### Release/security

Deterministic release/security checks cover strict SemVer/tag derivation, mandatory Personal Release trust warnings, Gatekeeper-bypass rejection, exact provenance metadata, manual protected-`main` release authority, App Sandbox/Hardened Runtime, immutable release semantics, system-only runtime linkage, no unreviewed subprocess/network/dynamic-loading surface, and separation from the optional future Trusted Release tier.

### Performance

`PERFORMANCE.md` and `performance/baseline-v0.1.0.json` are authoritative. CI deterministically enforces source-policy and artifact-size rules; shared-runner CPU/RSS/thread magnitudes are **not** target-Mac acceptance data.

Accepted immutable `v0.1.0` baseline:

- executable `220,560 B`;
- app aggregate `223,555 B`;
- DMG `73,955 B`;
- target-Mac idle CPU median/max `0.0% / 0.7%`;
- hover CPU median/max `5.95% / 22.3%`;
- stability CPU median/max `0.0% / 6.8%`;
- stability RSS delta `-3,712 KiB`.

## Test design

Prefer deterministic policies/state machines for geometry, release/security policy, resource policy, dwell behavior, transition lifecycle, accessibility duration policy, and AppKit boundary configuration.

Tests should:

- state one behavior in the name;
- assert externally meaningful results;
- avoid arbitrary sleeps;
- include boundary/error/denied/stale-callback cases;
- reproduce reported deterministic regressions before fixes where practical;
- never fabricate RED when behavior is already correctly testable;
- use injected schedulers/output closures around OS boundaries;
- intentionally invoke cancelled/stale callbacks when race safety is part of the contract;
- never use noisy shared-runner timing/resource values as tight gates.

No arbitrary global coverage percentage is used.

## M1 deterministic interaction/transition contract

Authoritative specification: `docs/specs/M1_NOTCH_INTERACTION.md`.
Transition hardening plan: `docs/superpowers/plans/2026-08-08-m1-transition-animation-hardening.md`.

### Pointer intent / dwell

The suite proves:

- quick transit shorter than the accepted `120 ms` dwell emits no expansion intent/haptic;
- setup/current-pointer synchronization is non-activating;
- deliberate hover emits one eligible expansion intent only when threshold completes;
- duplicate `mouseMoved` events keep one pending activation;
- cancelled dwell cannot later win from a stale callback;
- re-entry starts a fresh dwell;
- expanded retention emits no new intent;
- pointer exit emits non-haptic collapse intent;
- invalidation cancels pending work;
- compact activation has **4 pt inward protection on left/right/bottom and no top inset**;
- a point 2 pt inside the bottom edge is rejected and 4 pt is accepted;
- a point 1 pt below the top screen edge at notch center is accepted;
- points only 2 pt inside left/right remain rejected even at the top edge.

### Transition lifecycle

The suite proves:

- expansion settles only after its matching completion;
- collapse retains expanded SwiftUI content until matching completion;
- stale expansion/collapse completions cannot win after reversal;
- duplicate desired expansion does not duplicate transition/haptic;
- programmatic expansion remains non-haptic;
- invalidation makes later completion harmless;
- Reduce Motion retarget creates no second haptic;
- 10,000 reversal requests retain only latest-generation authority without production history accumulation.

### AppKit animation/chrome

The suite proves:

- zero-duration path reaches exact frame/radius endpoint synchronously once;
- positive-duration path installs public Core Animation radius output and does not complete synchronously;
- accepted normal duration is `0.20 s` with ease-in-out timing;
- cancellation freezes current presentation-layer radius before removing the prior animation;
- at least 32 immediate endpoint cycles retain exact frame and AppKit mask/radius invariants;
- outer clipping is owned by the layer-backed AppKit hosting view;
- compact/expanded radii remain `12 pt / 22 pt`;
- hardware-notch compact surface is opaque black;
- expanded hardware-notch content begins below occlusion.

### Accessibility motion policy

- normal motion resolves to `0.20 s`;
- Reduce Motion resolves to `0 s`;
- controller observes `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification` through selector ownership;
- block observer token/closure ownership is absent;
- observer removal is explicit at controller teardown.

### Pointer monitor lifecycle/performance

- exactly one local and one global `.mouseMoved` monitor are registered;
- repeated start cannot duplicate registrations;
- invalidation removes both tokens exactly once;
- live `.mouseMoved` delivery contains no per-event `Task { @MainActor ... }` allocation;
- main-thread AppKit callbacks route through `MainActor.assumeIsolated`;
- no broader input mask or sensitive permission is introduced.

The implementation remains event-driven: one pending dwell work item at most; no polling, repeating timer, display link, sleep loop, or custom per-frame animation loop.

## Real-hardware / distribution acceptance matrix

| ID | Scenario | Expected result | Status / automation |
| --- | --- | --- | --- |
| `NH-NOTCH-001` | Compact panel on physical-notch MacBook | Center/width match physical notch | **PASS** on CI #319 artifact; geometry automated |
| `NH-HOVER-001` | Deliberate compact hover | One expansion; no oscillation | **PASS**; lifecycle automated |
| `NH-HOVER-002` | Move within expanded retention | Remains expanded | **PASS**; policy automated |
| `NH-HOVER-003` | Move outside retention | Collapse once and stay compact | **PASS**; state machine automated |
| `NH-HOVER-DELAY-001` | Quick transit through/near notch toward second display | Stays compact; zero haptic | **PASS on #319**, targeted regression required after top-edge refinement |
| `NH-HOVER-DELAY-002` | Deliberate hover | Opens once after 120 ms | **PASS; 120 ms accepted** |
| `NH-HOVER-TOP-001` | Built-in display, pointer deliberately held against top screen edge over notch | Opens once after 120 ms with one haptic; no oscillation | **PENDING targeted physical check**; asymmetric geometry automated |
| `NH-HAPTIC-001` | Successful deliberate hover | Exactly one acceptable tactile event | **PASS; `.levelChange` accepted** |
| `NH-HAPTIC-002` | Cancelled transit/retention/collapse | No haptic | **PASS** |
| `NH-VISUAL-001` | Compact physical-notch state | Black rounded surface; no square leakage | **PASS** |
| `NH-VISUAL-002` | Hold expanded state | Controls visible below notch | **PASS** |
| `NH-VISUAL-003` | At least 20 open/collapse cycles | Rounded chrome remains rounded | **PASS**; 32-cycle deterministic regression |
| `NH-ANIM-001` | Normal expansion/collapse | Both directions smooth | **PASS; 0.20 s accepted** |
| `NH-ANIM-002` | Reverse expansion -> collapse | No snap/flicker/stale endpoint/extra haptic | **PASS** |
| `NH-ANIM-003` | Reverse collapse -> expansion | Same continuity rules | **PASS** |
| `NH-ANIM-004` | Rapid hover/leave churn | No stuck phase/stale completion | **PASS**; 10k stress automated |
| `NH-MOTION-001` | Reduce Motion enabled before transition | Immediate exact endpoint | **PASS** |
| `NH-MOTION-002` | Toggle Reduce Motion during transition | Immediate desired endpoint, no duplicate haptic/flicker | **PASS** |
| Startup pointer overlap | Launch while pointer already overlaps notch | No startup-only activation/haptic | **PASS** |
| `NH-SPACE-001` | Switch Spaces/fullscreen | Behavior matches future M1 policy | Planned M1 |
| `NH-DISPLAY-001` | Connect/move between displays | Correct target-display geometry/migration | Planned M1 |

## M1 acceptance evidence — 2026-08-08

### Broad hardware acceptance

Exact target-Mac artifact:

- source SHA `f6de06f5d045fc9375b3b31b0a7feb97a13cebe4`;
- CI #319 / run `31257399497`;
- `NotchHub-dmg` artifact ID `9021802122`.

Physical result: every broad interaction, visual, haptic, animation/reversal, rapid-churn, Reduce Motion and startup check listed above passed. This accepts `120 ms`, `.levelChange`, `0.20 s`, the transition authority, AppKit chrome ownership and the existing side/bottom activation depth.

The only follow-up requested from this successful cycle was deliberate activation at the very top screen edge when not using a second-display transit.

### Top-edge refinement TDD

Requirement: keep 4 pt protection on left/right/bottom, remove top inset entirely.

- RED commit `f4d19fc7e508fe11a35aae6fb56f80e0fa7ec13e` / CI #320 ran **52 tests** and failed only `compactPointerAtTopScreenEdgeActivatesWithoutTopInset`; left/right/bottom boundary tests and every previous behavior stayed green.
- GREEN source `c7c10033d223197309eafeba63e67b30ae29ba33` / CI #321 passed **52/52 Swift tests**, macOS 26 compatibility, release/security/performance/package/signature/Sandbox/Hardened Runtime/DMG checks and the unchanged P0 size budget.
- CI #321 sizes: executable `250,000 B`, app `252,997 B`, DMG `84,468 B`.

After documentation, a fresh exact-head CI artifact is required. Only two physical checks remain:

1. `NH-HOVER-TOP-001` — deliberate top-edge activation works.
2. `NH-HOVER-DELAY-001` — quick cross-display transit still does not open/haptic.

If both pass, PR #10 may move from Draft toward protected squash integration without re-running the already accepted broad hardware matrix.

## Historical TDD highlights

Earlier RED/GREEN evidence remains in Git history and `CHANGELOG.md`: initial interaction seams (#147/#148/#150), size-gate correction (#157/#158), setup synchronization (#165/#167), visual regressions (#172/#189/#196/#204), transition authority and reversal hardening (#225/#231/#273/#279/#283/#292), size optimization (#295/#305/#308), and pointer hot-path optimization (#309/#310).

The invariant throughout is unchanged: hardware success does not replace deterministic tests, and green CI does not claim physical behavior it cannot observe.
