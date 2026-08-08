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

## Release-policy boundary

`scripts/test_release_policy.py` and `scripts/release_policy.py` cover:

- strict release SemVer/tag derivation;
- mandatory Personal Release trust warning;
- unsafe Gatekeeper-bypass text rejection;
- exact provenance/build metadata schema;
- manual protected-`main` Personal Release authority;
- ad-hoc signature + Sandbox/Hardened Runtime requirements;
- immutable release semantics;
- separation from the future Developer ID/notarized Trusted Release tier;
- prohibition of ambiguous legacy release workflows.

The same boundary is rechecked by `scripts/security-audit.sh`.

## Security test boundary

The executable security baseline verifies, among other things:

- zero external Swift runtime dependencies;
- no runtime subprocess/shell execution APIs;
- no direct network/WebKit surface;
- no dynamic code loading/private-symbol bridging primitives;
- no global keyboard/button/drag/scroll/modifier monitoring;
- no embedded common credential/private-key formats;
- exactly the expected Sandbox entitlement set;
- no dangerous Hardened Runtime exception entitlements;
- no LaunchAgents/LaunchDaemons/privileged-helper surfaces;
- immutable full-SHA GitHub Action references;
- no `pull_request_target` workflows;
- explicit Personal/Trusted release-tier boundaries;
- performance measurement tooling remains development-only and outside `NotchHub.app`.

Future capabilities that legitimately require a currently forbidden surface must update policy and tests explicitly in the same reviewed PR.

## Performance test boundary

`PERFORMANCE.md` is authoritative for runtime policy, accepted target-Mac values, budgets, and methodology. `performance/baseline-v0.1.0.json` is the canonical machine-readable baseline.

Deterministic policy tests cover:

- forbidden unreviewed polling/timer/sleep/display-link primitives in runtime Swift sources;
- strict `/bin/ps` CPU/RSS/thread parsing;
- Darwin `ps -M` thread-row parsing;
- median/max aggregation;
- stability start/end/quartile evidence;
- harness configuration validation;
- malformed/non-finite budget input rejection;
- release-size success/failure below/above relative and absolute limits;
- fail-closed baseline schema/version and required-metric validation.

`scripts/perf-baseline.py` is development/release tooling only. CI runs a short compatibility/schema smoke and does **not** enforce shared-runner CPU/RSS/thread magnitudes. Canonical runtime values come only from the target MacBook/macOS 26.6. Artifact sizes are deterministic enough to gate in shared CI.

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

No arbitrary global coverage percentage is used. Coverage instrumentation identifies untested deterministic logic.

## P0 performance contracts

| ID | Scenario | Expected result | Automation |
| --- | --- | --- | --- |
| `NH-PERF-IDLE-001` | Accepted Personal Release, 10 s warmup then untouched compact mode for 60 s sampled every 1 s | Stable idle CPU/RSS/thread summary; no app-initiated periodic work | Sampling automated on target Mac; environment manual |
| `NH-PERF-HOVER-001` | 60 s sampler while repeating documented 5-second expand/retain/collapse cycle | Active summary captured without synthesized input; accepted hover behavior intact | Sampling automated; interaction manual |
| `NH-PERF-STABILITY-001` | 10 min untouched run sampled every 5 s | No unexplained sustained RSS/thread growth | Sampling automated on target Mac; interpretation reviewed |
| `NH-PERF-SIZE-001` | Accepted release executable/app/DMG | Exact byte sizes recorded; later candidates stay within reviewed budget | Release metadata + shared-CI deterministic gate |
| `NH-PERF-STATE-001` | Exactly 100,000 pure pointer/presentation decisions | Correct final/count invariants, no retained history API, no wall-clock assertion | Fully automated Swift test |

Accepted immutable `v0.1.0` size baseline:

- executable `220,560 B`;
- app aggregate `223,555 B`;
- DMG `73,955 B`.

Shared-runner CPU/RAM/thread values never substitute for target-Mac acceptance.

## M1 deterministic interaction/transition contract

Authoritative specification: `docs/specs/M1_NOTCH_INTERACTION.md`.
Transition hardening plan: `docs/superpowers/plans/2026-08-08-m1-transition-animation-hardening.md`.

The current PR #10 suite proves:

### Pointer intent / dwell

- quick transit shorter than dwell emits no expansion intent/haptic;
- setup/current-pointer synchronization is non-activating;
- deliberate hover emits one eligible expansion intent only when threshold completes;
- duplicate `mouseMoved` events keep one pending activation;
- cancelled dwell cannot later win from a stale callback;
- re-entry starts a fresh dwell;
- expanded retention emits no new intent;
- pointer exit emits non-haptic collapse intent;
- invalidation cancels pending work;
- 2 pt edge depth is rejected while the 4 pt candidate is accepted.

### Transition lifecycle

- expansion settles only after its matching completion;
- collapse retains expanded SwiftUI content until its matching completion;
- stale expansion completion cannot win after collapse reversal;
- stale collapse completion cannot win after expansion reversal;
- duplicate desired expansion does not duplicate transition/haptic;
- programmatic expansion remains non-haptic;
- invalidation cancels active output and makes later completion harmless;
- animation policy changes retarget only in-flight transitions;
- Reduce Motion retarget creates no second haptic;
- 10,000 reversal requests retain only latest-generation authority without production history accumulation.

### AppKit animation/chrome

- zero-duration path reaches exact frame/radius endpoint synchronously once;
- positive-duration path installs public Core Animation radius output and does not complete synchronously;
- standard duration candidate is `0.20 s` with ease-in-out timing;
- cancellation freezes current presentation-layer radius before removing the previous radius animation;
- at least 32 immediate endpoint cycles retain exact frame and AppKit mask/radius invariants;
- outer clipping is owned by the layer-backed AppKit hosting view, not a competing SwiftUI outer clip;
- compact/expanded radii remain `12 pt / 22 pt`;
- hardware-notch compact surface is opaque black;
- expanded hardware-notch content begins below occlusion.

### Accessibility motion policy

- normal motion resolves to `0.20 s`;
- Reduce Motion resolves to `0 s`;
- controller observes `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification` through selector ownership;
- block observer token/closure ownership is absent;
- duplicate actual-value state is suppressed before transition retarget;
- observer removal is explicit at controller teardown.

### Pointer monitor lifecycle/performance

- exactly one local and one global `.mouseMoved` monitor are registered;
- repeated start cannot duplicate registrations;
- invalidation removes both tokens exactly once;
- production live `.mouseMoved` delivery contains no `Task { @MainActor ... }` allocation per event;
- main-thread AppKit monitor callbacks route synchronously through `MainActor.assumeIsolated`;
- no broader input mask or sensitive permission was introduced.

The implementation remains event-driven: one pending dwell work item at most; no polling, repeating timer, display link, sleep loop, or custom per-frame animation loop.

The `120 ms` dwell, `4 pt` inset, `.levelChange` haptic, and `0.20 s` animation duration remain physical candidates until target-Mac acceptance.

## Real-hardware / distribution acceptance matrix

Record results in `docs/PROJECT_STATE.md`.

| ID | Scenario | Expected result | Automation |
| --- | --- | --- | --- |
| `NH-BOOT-001` | Install/open CI-produced DMG | App launches and panel appears | Packaging automated; launch UX manual |
| `NH-OS26-001` | Run exact artifact on target macOS 26.6 | App launches sandboxed, no unexpected permission prompt | macOS 26 CI automated; exact 26.6 hardware manual |
| `NH-NOTCH-001` | Observe compact panel on hardware-notch MacBook | Center/width match physical notch | Geometry unit-tested; physical alignment manual |
| `NH-HOVER-001` | Enter compact activation region and intentionally hold | One expansion; no oscillation | Policy/lifecycle automated; physical pointer delivery manual |
| `NH-HOVER-002` | Move within expanded retention | Remains expanded | Policy automated; physical delivery manual |
| `NH-HOVER-003` | Move outside retention | Frame/content collapse once and stay compact | State machine automated; physical window behavior manual |
| `NH-SANDBOX-001` | Exercise normal panel in Sandbox build | No crash/unexpected permission/loss of behavior | Entitlement/signing automated; runtime manual |
| `NH-PERSONAL-RELEASE-001` | Download versioned Personal Release | Checksum/trust/install/open behavior accepted | Policy/provenance automated; downloaded trust path manual |
| `NH-HOVER-DELAY-001` | Move through/near notch toward another display without stopping | Stays compact; zero haptic | Scheduler/depth automated; real cross-display feel manual |
| `NH-HOVER-DELAY-002` | Deliberately hover at least 4 pt inside compact notch | Opens once after accepted dwell, no flicker/oscillation | State/time/depth automated; final tuning manual |
| `NH-HAPTIC-001` | Deliberate hover on compatible Force Touch trackpad | Exactly one acceptable tactile event on successful expansion | Request count automated; tactile result manual |
| `NH-HAPTIC-002` | Quick/cancelled hover, retention and collapse | No haptic | Policy/output automated; physical negative check manual |
| `NH-VISUAL-001` | Observe compact physical-notch state | Black rounded compact surface visible; no square leakage | Opacity/clipping policy automated; exact pixels manual |
| `NH-VISUAL-002` | Hold pointer in expanded state | Primary controls visible below notch throughout active hold | Content staging/inset automated; physical occlusion manual |
| `NH-VISUAL-003` | At least 20 open/collapse cycles | Rounded chrome remains rounded every cycle | 32-cycle backing-layer regression automated; physical pixels manual |
| `NH-ANIM-001` | Normal deliberate expansion/collapse | Both directions visibly smooth at accepted duration | Lifecycle/system-output automated; compositor continuity manual |
| `NH-ANIM-002` | Reverse expansion -> collapse while animation is active | New direction starts from current visible state; no snap/flicker/stale endpoint/extra unintended haptic | Generation/radius-freeze automated; physical frame continuity manual |
| `NH-ANIM-003` | Reverse collapse -> expansion while animation is active | Same continuity rules; no stale endpoint | Generation/radius-freeze automated; physical frame continuity manual |
| `NH-ANIM-004` | Repeated rapid hover/leave churn | No stuck phase or stale completion | 10k reversal stress automated; physical delivery manual |
| `NH-MOTION-001` | Enable Reduce Motion before transition | Exact endpoint is immediate, interaction semantics preserved | Zero-duration policy/endpoint automated; physical behavior manual |
| `NH-MOTION-002` | Toggle Reduce Motion during active transition | Immediately reaches desired endpoint; no duplicate haptic/flicker | Retarget/generation automated; physical continuity manual |
| `NH-SPACE-001` | Switch Spaces/fullscreen | Behavior matches M1 policy | Planned M1 |
| `NH-DISPLAY-001` | Connect/move between displays | Correct target-display geometry/migration | Planned M1 |
| `NH-GATEKEEPER-TRUSTED-001` | Future Trusted Release | Gatekeeper recognizes notarized Developer ID path | Future Trusted workflow + manual downloaded path |

If the public AppKit frame animator visibly snaps/flickers under reversal on real hardware, `NH-ANIM-002/003` is **FAIL**. Do not substitute a custom timer/display link/private API merely to make the scenario pass.

## Acceptance history

### 2026-08-07 — M0 cycles 1–3

- Cycle 1: `NH-HOVER-001` FAIL from compact/expanded oscillation; RED `eb4fb4d`, GREEN `eff9bde` moved authority from raw SwiftUI hover to deterministic screen-space policy.
- Cycle 2: target Mac showed compact width a few pixels too wide and frame remained expanded after content collapse; RED `c518326` reproduced both (`180` vs `176`, hosting sizing options `7` vs empty), GREEN `3bb1bbb` fixed them.
- Cycle 3: target macOS 26.6 `NH-NOTCH-001` and `NH-HOVER-001/002/003` all PASS. **M0 accepted.**

### 2026-08-07 — Personal Release

Downloaded immutable `v0.1.0` passed checksum/install/standard macOS first-launch flow and accepted notch/hover scenarios. **R0.1 accepted.**

### 2026-08-07 — P0 runtime/size foundation

Accepted target-Mac runtime baseline:

- idle CPU median/max `0.0% / 0.7%`, RSS `33,648 / 33,808 KiB`, threads `4 / 4`;
- hover CPU median/max `5.95% / 22.3%`, RSS `38,456 / 38,816 KiB`, threads `6 / 7`;
- stability CPU median/max `0.0% / 6.8%`, RSS `30,992 / 34,384 KiB`, threads `3 / 7`;
- stability RSS `34,256 -> 30,544 KiB` (`-3,712 KiB`).

RED CI #91 established missing release-size comparison; GREEN CI #94 passed policy/security/Swift/package gates and deterministic size enforcement. **P0 accepted.**

### 2026-08-08 — M1 delayed-hover core

- RED commits/CI #147/#148 established missing interaction APIs;
- RED #150 established missing pointer-monitor lifecycle seam;
- initial GREEN added one-shot dwell, stale-generation safety, public haptic output and explicit monitor ownership;
- CI #157 caught executable size `254,000 B` vs allowed `253,644 B`; budget was not widened;
- CI #158 restored size compliance;
- review found setup-time activation risk; RED #165 and GREEN #167 fixed it with explicit non-activating setup synchronization.

### 2026-08-08 — M1 physical visual cycles

First physical M1 cycle: delayed-hover/haptic checks otherwise passed, but expanded controls visibility and compact contour failed; tactile strength and activation depth were tuned to `.levelChange` / `4 pt` candidates while 120 ms remained.

Subsequent deterministic/physical corrections:

- RED #172 established hardware-notch visual contract;
- #177/#181/#187 rejected oversized visual attempts without widening P0 budget;
- #188 restored size compliance;
- RED #189 reproduced edge grazing; GREEN #191 accepted 4 pt candidate in deterministic tests;
- physical cycle then found rounded chrome degrading to square; RED #196 established AppKit clipping ownership, GREEN #199 passed 32 repeated mask/radius cycles;
- next physical cycle found only the white point over wallpaper; RED #204 proved hardware-notch opacity was `0`, GREEN #205 restored opaque black compact rendering.

These physical findings keep M1 unaccepted until the new exact candidate is retested.

### 2026-08-08 — transition/animation hardening

TDD sequence:

- CI #225 RED: intent-only interaction contract absent;
- CI #231 RED: transition lifecycle/output boundary absent;
- CI #273 RED: Reduce Motion policy absent;
- CI #279 RED: public AppKit animation boundary absent;
- CI #283 RED: live controller still had competing presentation ownership;
- CI #292 RED: cancellation did not freeze current visible radius;
- CI #295: functional/security/package checks green, but unchanged P0 size gate failed; no candidate issued;
- implementation was reduced through lean function/closure boundaries rather than weaker requirements;
- CI #305 RED: selector-based accessibility observation contract absent;
- CI #308: all deterministic behavior/security/package checks passed and executable/app were under budget, but DMG still exceeded the unchanged size allowance;
- CI #309 RED: per-event `Task { @MainActor ... }` still existed; all prior 48 Swift tests passed;
- CI #310 GREEN on `12c5ff26dc409dd0391f3b296866c2be9515ce7e`: **49/49 Swift tests**, macOS 26 compatibility, release/security/performance/package/signature/Sandbox/Hardened Runtime/DMG/harness/artifact gates all PASS;
- CI #310 sizes: executable `250,000 B`, app `252,997 B`, DMG `84,422 B`, all within unchanged P0 budget.

Temporary binary-symbol diagnostics were removed immediately afterward. Documentation changes require one final clean exact-head CI before physical acceptance.

## Current acceptance boundary

PR #10 remains Draft and unmerged.

Only the DMG artifact produced by the final **clean exact-head** CI after documentation/diagnostic cleanup may be used for the next target-Mac cycle. That cycle must run the interaction, visual, animation/reversal, rapid-churn, startup, and Reduce Motion scenarios in the matrix above.

Final accepted/tuned values must then be recorded in `docs/PROJECT_STATE.md`, this file, `CHANGELOG.md`, and the M1 spec.
