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

The first target-Mac/macOS 26.6 cycle reported the requested interaction tests as PASS, but exposed two additional real visual defects that were not represented by the original acceptance matrix:

1. **Expanded controls visibility — FAIL**
   - panel became a large black expanded surface while primary controls were not visible during the active hover;
   - controls appeared only as the pointer moved away/collapse started and were positioned under the physical notch.

2. **Compact physical-notch contour — FAIL**
   - black pixels from the compact app surface filled the visible rounded-corner cutouts around the physical notch;
   - the notch therefore appeared visually square instead of retaining its native rounded silhouette.

Additional UX feedback from the same hardware cycle:

- haptic worked, but a slightly more noticeable feel was preferred;
- activation should require the cursor to move slightly deeper inside the notch instead of triggering directly at the physical edge;
- no separate complaint was made about the `120 ms` dwell, so that candidate remains unchanged pending the revised retest.

These findings mean the original M1 candidate was **not accepted**, despite the core interaction checks otherwise passing.

### Revised visual/interaction candidate

The current PR #10 candidate now:

- does not paint an opaque black compact background over the visible rounded-corner pixels of a hardware notch; non-notch fallback remains opaque;
- starts expanded content below hardware-notch occlusion at `compactFrame.height + 12 pt`; non-notch fallback retains 20 pt;
- updates the AppKit panel frame immediately with the SwiftUI state instead of running an independent AppKit frame animation that could expose mismatched panel/content states;
- keeps polished animation/Reduced Motion as a later dedicated M1 hardening step rather than sacrificing state correctness now;
- changes compact activation geometry from an outward `2 pt` padding to an inward **4 pt activation inset** candidate;
- keeps expanded retention padding unchanged;
- changes the one public AppKit haptic pattern from `.generic` to **`.levelChange`** as the target-Mac tuning candidate; there is still exactly one haptic request, never a double-hit strength simulation.

### TDD / CI evidence

Original interaction RED -> GREEN evidence remains preserved:

- RED CI #147/#148 for absent interaction production seams;
- RED CI #150 for absent pointer-monitor lifecycle seam;
- CI #157 caught executable-size overrun by `356 B`; P0 budget was not widened;
- CI #158 restored the implementation under budget;
- independent review found setup-time activation/haptic risk;
- RED CI #165 and GREEN CI #167 fixed setup synchronization without broadening the surface.

Hardware-feedback revision evidence:

- RED CI #172: hardware-notch visual contract absent before implementation;
- visual implementations remained correctness/security green but CI #177, #181, and #187 rejected excessive executable/app growth;
- **the size budget was never widened**; the implementation architecture was simplified instead;
- CI #188 passed the full pipeline after the visual solution was reduced to existing layout/view boundaries: executable `251,856 B`, app `254,853 B`, DMG `83,143 B`;
- RED CI #189 reproduced edge-grazing activation: a point only 2 pt inside the physical compact edge still activated;
- GREEN CI #191 on source head `ab782262c16163742bb115671f7908255fc08e4a` passed **27/27 Swift tests**, release/performance policy, runtime performance audit, security baseline, warnings-as-errors, packaging/signature/Sandbox/Hardened Runtime/DMG, harness smoke, and unchanged size budgets;
- CI #191 candidate sizes: executable `251,856 B`, app `254,853 B`, DMG `83,117 B`.

Shared-runner CPU/RSS/thread smoke remains schema/compatibility evidence only.

### Revised hardware acceptance still required

Before this PR can be accepted/merged, rerun on the target MacBook/macOS 26.6:

- `NH-NOTCH-001` — compact alignment/width remains correct;
- `NH-HOVER-001/002/003` — expansion, retention and collapse remain correct after frame synchronization change;
- `NH-HOVER-DELAY-001` — normal cross-display transit stays compact/no haptic with the new 4 pt inset;
- `NH-HOVER-DELAY-002` — deliberate hover still opens reliably with 120 ms dwell + 4 pt inset;
- `NH-HAPTIC-001` — one `.levelChange` haptic is present and the slightly stronger feel is acceptable;
- `NH-HAPTIC-002` — quick/cancelled/retention/collapse still produce no physical haptic;
- `NH-VISUAL-001` — compact mode preserves the physical notch's native rounded silhouette with no black corner protrusion;
- `NH-VISUAL-002` — expanded controls are visible below the physical notch while the pointer is still holding the panel open.

The `120 ms` dwell, `4 pt` activation inset, and `.levelChange` haptic are therefore **current candidates**, not final accepted values until this revised hardware pass.

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

1. Finish exact-head CI after source-of-truth documentation synchronization.
2. Run the short revised target-Mac acceptance matrix above and record results honestly.
3. If `120 ms`, `4 pt`, and `.levelChange` feel correct, accept those values; otherwise tune only the failing value and rerun deterministic + hardware acceptance.
4. Once the interaction/visual slice is accepted, run the separate `NSTrackingArea`/window-local tracking experiment against accepted P0 `NH-PERF-HOVER-001`; remove global `.mouseMoved` only with equal-or-better correctness/resource evidence.
5. Continue M1 with active-display migration, Spaces/fullscreen, screen-configuration handling, animation/Reduced Motion, click/pin, and gesture hardening.
