# Project state

Last updated: 2026-08-08
Current version: `0.1.0` (Personal Release published and accepted)
Repository visibility: **Public**
Primary physical target: macOS `26.6`
Protected branch target: `main`
P0 merge commit: `a056aa74bad5d8e193eb4c76a76e6c910344bd09`
Public-readiness hardening merge: `23500e099a0f8b2738f1157c6ae3be71c89df6e1`
Current product milestone: M1 `Notch Core hardening and interaction` — **IN PROGRESS**
Active implementation PR: #10 `M1 delayed hover and haptic interaction core`

## Product

NotchHub is a personal, native, local-first macOS productivity hub built around the MacBook notch. Planned modules are Shelf, Snippets, Calendar, Translator, and media controls with Yandex Music as the primary player.

NotchNook is a public product/UI research reference only; NotchHub remains an independent implementation.

## Accepted foundation

**M0 — Engineering foundation: ACCEPTED and merged.**

Accepted target-Mac evidence from M0:

- `NH-OS26-001`: PASS;
- `NH-NOTCH-001`: PASS;
- `NH-HOVER-001`: PASS;
- `NH-HOVER-002`: PASS;
- `NH-HOVER-003`: PASS.

M0 includes the Swift 6 native shell, public notch geometry, deterministic pointer policy, AppKit-owned panel sizing, App Sandbox + Hardened Runtime, zero third-party Swift runtime dependencies, strict CI/security/package gates, and accepted real-hardware regression fixes.

## R0.1 Personal Release

Status: **ACCEPTED**.

`v0.1.0` was published from accepted commit `8e913dcddfdec7d9aa920df8c37afb23b8c40884` as an immutable Personal Release and passed downloaded-release acceptance on the target MacBook/macOS 26.6. Personal Release remains ad-hoc signed, sandboxed, Hardened Runtime protected, checksum/provenance verified, and intentionally not notarized. Trusted Release remains an optional future tier.

## P0 Performance Foundation

Status: **ACCEPTED AND MERGED**.

PR #5 was exact-head CI green, reviewed, and squash-merged to `main` as `a056aa74bad5d8e193eb4c76a76e6c910344bd09`.

Canonical sources:

- `PERFORMANCE.md`;
- `performance/baseline-v0.1.0.json`;
- `docs/TESTING.md`;
- `docs/ROADMAP.md`.

Accepted target-Mac baseline on macOS 26.6 / `Mac16,8`:

- `NH-PERF-IDLE-001`: CPU median/max `0.0% / 0.7%`, RSS median/max `33,648 / 33,808 KiB`, threads `4 / 4`;
- `NH-PERF-HOVER-001`: CPU median/max `5.95% / 22.3%`, RSS median/max `38,456 / 38,816 KiB`, threads `6 / 7`;
- `NH-PERF-STABILITY-001`: CPU median/max `0.0% / 6.8%`, RSS median/max `30,992 / 34,384 KiB`, threads `3 / 7`;
- stability RSS delta `-3,712 KiB`: no sustained memory growth;
- no runaway thread accumulation.

Accepted immutable `v0.1.0` artifact baseline:

- executable `220,560 B`;
- app aggregate `223,555 B`;
- DMG `73,955 B`.

Runtime CPU/RSS/thread limits remain target-Mac acceptance gates. Shared GitHub runners never substitute for physical resource evidence. Artifact byte sizes are deterministic and enforced in CI with the unchanged P0 budget.

## P0.1 Public repository readiness

Status: **ACCEPTED**.

PR #6 completed public-source audit/hardening and squash-merged to `main` as `23500e099a0f8b2738f1157c6ae3be71c89df6e1`. Repository visibility is public; ordinary public pull-request CI remains read-only/unprivileged; Personal Release publication is isolated from untrusted PR execution; Trusted Release remains intentionally dormant with no Apple credentials/environment provisioned.

P0.1 introduced no runtime or entitlement expansion. Any future change to repository visibility, Actions authority, protection rules, release trust, or credentials requires a fresh focused review.

## M1 interaction core

Status: **REVISED IMPLEMENTATION IN PR #10; SHORT TARGET-MAC RETEST PENDING**.

Authoritative requirements: `docs/specs/M1_NOTCH_INTERACTION.md`.
Implementation plan: `docs/superpowers/plans/2026-08-08-m1-pointer-dwell-haptics.md`.

### Deterministic interaction implementation

Implemented:

- dedicated `NotchInteractionCoordinator` separating pointer delivery, time, haptic output, and presentation state;
- one cancellable one-shot compact -> expanded dwell, current candidate `120 ms`;
- duplicate movement does not duplicate pending activation;
- leaving before threshold cancels immediately;
- generation validation makes stale callbacks harmless;
- re-entry starts a fresh dwell;
- expanded retention/collapse stays independent from activation dwell;
- setup-time pointer synchronization is non-activating;
- exactly one haptic request only for a successful actual-user `compact -> expanded` transition;
- no haptic for quick/cancelled transit, duplicates, retention, collapse, programmatic/setup transitions, or stale callbacks;
- one `DispatchWorkItem` through `DispatchQueue.main.asyncAfter`, with no polling/repeating timer;
- explicit ownership/teardown for one local and one global `.mouseMoved` monitor;
- application termination invalidates pending work and monitors;
- no entitlement, runtime dependency, network, subprocess, Accessibility/Input Monitoring, `CGEventTap`, private API, synthetic input, or broader event mask was added.

### First target-Mac M1 acceptance cycle

The first target-Mac/macOS 26.6 cycle reported the requested interaction tests as PASS, but exposed two additional visual defects:

1. **Expanded controls visibility — FAIL**
   - panel became a large black expanded surface while primary controls were not visible during active hover;
   - controls appeared only as pointer exit/collapse began and were positioned under the physical notch.

2. **Compact contour — FAIL**
   - the original black compact surface could visually produce square corner artifacts around the notch because outer clipping was not owned by the AppKit backing view.

Additional UX feedback from the same hardware cycle:

- haptic worked, but a slightly more noticeable feel was preferred;
- activation should require the cursor to move slightly deeper inside the notch instead of triggering directly at the physical edge;
- no separate complaint was made about the `120 ms` dwell, so that candidate remains unchanged pending the revised retest.

These findings mean the original M1 candidate was **not accepted**, despite the core interaction checks otherwise passing.

### Revised visual/interaction candidate

The current PR #10 candidate now:

- renders an **opaque black compact surface** on hardware-notch and no-notch displays;
- keeps the black compact surface rounded through one AppKit-owned hosting-view mask rather than making it transparent;
- starts expanded content below hardware-notch occlusion at `compactFrame.height + 12 pt`; non-notch fallback retains 20 pt;
- updates the AppKit panel frame immediately with state instead of running an independent frame animation;
- uses an inward **4 pt activation inset** candidate while leaving expanded retention unchanged;
- uses one public `.levelChange` AppKit haptic candidate, never a double-hit strength simulation;
- keeps polished animation/Reduced Motion as a later dedicated M1 hardening step.

### Subsequent target-Mac visual regressions

A later target-Mac cycle showed:

- expanded panel corners were initially rounded;
- after several open/collapse cycles the visible panel chrome became square.

This is tracked as `NH-VISUAL-003` and was **FAIL on the previous candidate**.

Code review identified split ownership: SwiftUI `clipShape` owned visual clipping while AppKit `NSPanel.setFrame` independently owned repeated window resizing. There was no AppKit-level invariant requiring the backing view to remain masked after every transition.

The source candidate therefore moved outer clipping ownership to AppKit:

- SwiftUI no longer owns outer panel clipping;
- the existing `NSHostingView` is explicitly layer-backed;
- AppKit `masksToBounds = true` is required;
- continuous corner radius is applied as `12 pt` compact / `22 pt` expanded;
- the AppKit mask is reasserted on every presentation transition;
- the hosting view explicitly autoresizes with both panel width and height.

The next target-Mac retest then exposed a second, separate regression: **only the white compact indicator was visible over wallpaper and the intended black compact panel was absent**. Root-cause tracing showed this was not a screenshot artifact: `NotchLayout.compactBackgroundOpacity` explicitly returned `0` whenever a hardware notch was detected. That transparency had been introduced as an attempted contour workaround and was incompatible with the intended product UI.

The current source fixes the two concerns independently: compact rendering is opaque black, while AppKit owns and preserves the rounded mask.

### TDD / CI evidence

Original interaction RED -> GREEN evidence remains preserved:

- RED CI #147/#148 for absent interaction production seams;
- RED CI #150 for absent pointer-monitor lifecycle seam;
- CI #157 caught executable-size overrun by `356 B`; P0 budget was not widened;
- CI #158 restored the implementation under budget;
- independent review found setup-time activation/haptic risk;
- RED CI #165 and GREEN CI #167 fixed setup synchronization without broadening the surface.

Hardware-feedback revision evidence:

- RED CI #172 established the hardware-notch visual contract before implementation;
- CI #177, #181, and #187 rejected visual implementations that exceeded the unchanged P0 size budget;
- CI #188 restored the visual solution under budget;
- RED CI #189 reproduced edge-grazing activation;
- GREEN CI #191 passed 27/27 Swift tests with the revised 4 pt activation and `.levelChange` candidate;
- RED commit `8088df8df655183d3fbe1a0cff54d23dfc936034` / CI #196 added the repeated panel-chrome contract before an AppKit presentation-mask API existed and failed exactly on that missing production boundary;
- GREEN source head `446a976591a43a856a2683337cb4df1ada10cc8a` / CI #199 passed **29/29 Swift tests**, including 32 repeated expanded<->compact AppKit mask cycles and hosting-view width/height autoresizing invariants;
- after the physical report that only the white point remained, RED commit `1bb2d1481f31557868651bab6b59745e44ed827b` / CI #204 changed the deterministic hardware-notch compact contract from opacity `0` to required opacity `1` and failed exactly on `0.0 == 1.0`;
- GREEN source head `29627f5f145d5e60ef1873d988cf4c51b91f097f` / CI #205 restored opaque compact rendering while retaining the AppKit repeated-mask fix and passed **29/29 Swift tests**, macOS 26 compatibility, release/performance policy, runtime performance audit, security baseline, warnings-as-errors, Sandbox/Hardened Runtime/signature/DMG verification, harness smoke, and the **unchanged** P0 size budget;
- final exact-head `a524b2f709f64534e9473664a7482c7de015b5d9` / CI #214 repeated the complete pipeline after source-of-truth documentation synchronization and passed **29/29 Swift tests** plus every required quality/security/performance/package gate;
- CI #214 exact-head sizes: executable `248,768 B`, app `251,765 B`, DMG `82,074 B`;
- CI #214 produced `NotchHub-dmg` artifact `9019528633` from exact head `a524b2f709f64534e9473664a7482c7de015b5d9`.

Shared-runner CPU/RSS/thread smoke remains schema/compatibility evidence only.

### Revised hardware acceptance still required

Before this PR can be accepted/merged, rerun on the target MacBook/macOS 26.6:

- `NH-NOTCH-001` — compact alignment/width remains correct;
- `NH-HOVER-001/002/003` — expansion, retention and collapse remain correct;
- `NH-HOVER-DELAY-001` — normal cross-display transit stays compact/no haptic with the 4 pt inset;
- `NH-HOVER-DELAY-002` — deliberate hover still opens reliably with 120 ms dwell + 4 pt inset;
- `NH-HAPTIC-001` — one `.levelChange` haptic is present and its feel is acceptable;
- `NH-HAPTIC-002` — quick/cancelled/retention/collapse produce no physical haptic;
- `NH-VISUAL-001` — compact mode visibly shows the intended **black rounded panel**, aligned with the physical notch, with the white point on black rather than floating over wallpaper and no square-corner leak;
- `NH-VISUAL-002` — expanded controls remain visible below the physical notch while the pointer is holding the panel open;
- `NH-VISUAL-003` — expanded panel keeps its rounded chrome after at least 20 repeated open/collapse cycles, with no transition to square corners.

The `120 ms` dwell, `4 pt` activation inset, and `.levelChange` haptic remain candidates until this revised hardware pass.

## Security baseline

`SECURITY.md` remains authoritative. M1 adds no runtime entitlement, telemetry, analytics, networking, subprocess/shell, dynamic loading, private API, privileged helper, Accessibility/Input Monitoring permission, or broader global input capture. Global observation remains exactly `.mouseMoved`; pointer coordinates/history are not persisted.

## Known limitations / technical debt

- target-Mac runtime ceilings still derive from one canonical run per scenario with conservative headroom;
- narrow global `.mouseMoved` fallback remains and now has explicit lifecycle ownership;
- current AppKit event backend still uses a main-actor task hop for delivered mouse-move events;
- a window-local `NSTrackingArea` replacement is acceptable only after target-Mac cross-display/notch correctness and resource evidence are equal or better than P0;
- animation is intentionally minimal/immediate in the revised candidate; polished animation + Reduced Motion is still M1 work;
- active-display migration, Spaces/fullscreen, screen-configuration handling, notchless mode, click/pin policy, gestures, product modules, and optional trusted distribution remain later work.

## Next optimal step

1. Run the short revised target-Mac acceptance matrix above using exact-head CI #214 artifact `9019528633`, with special emphasis on visible black compact chrome and `NH-VISUAL-003` repeated-cycle stability, and record results honestly.
2. If `120 ms`, `4 pt`, and `.levelChange` feel correct, accept those values; otherwise tune only the failing value and rerun deterministic + hardware acceptance.
3. Once the interaction/visual slice is accepted, run the separate `NSTrackingArea`/window-local tracking experiment against accepted P0 `NH-PERF-HOVER-001`; remove global `.mouseMoved` only with equal-or-better correctness/resource evidence.
4. Continue M1 with active-display migration, Spaces/fullscreen, screen-configuration handling, animation/Reduced Motion, click/pin, and gesture hardening.
