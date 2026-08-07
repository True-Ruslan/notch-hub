# Project state

Last updated: 2026-08-07
Current version: `0.1.0` (Personal Release published and accepted)
Primary physical target: macOS `26.6`
Protected branch: `main`
P0 completion PR: #5 `Performance Foundation`
Next milestone after P0 merge: M1 `Notch Core hardening and interaction`

## Product

NotchHub is a personal, native, local-first macOS productivity hub built around the MacBook notch. Planned modules are Shelf, Snippets, Calendar, Translator, and media controls with Yandex Music as the primary player.

NotchNook is a public product/UI research reference only; NotchHub remains an independent implementation.

## Accepted foundation

**M0 — Engineering foundation: ACCEPTED and merged.**

Real-hardware final acceptance on the target MacBook/macOS 26.6:

- `NH-OS26-001`: PASS from the earlier sandbox/Hardened Runtime cycle;
- `NH-NOTCH-001`: PASS;
- `NH-HOVER-001`: PASS;
- `NH-HOVER-002`: PASS;
- `NH-HOVER-003`: PASS.

M0 includes the Swift 6 native shell, public notch geometry, deterministic pointer policy, AppKit-owned panel sizing, App Sandbox + Hardened Runtime, zero third-party Swift runtime dependencies, strict CI/security/package gates, and the accepted real-hardware regression fixes.

## R0.1 Personal Release

Status: **ACCEPTED**.

`v0.1.0` was published from accepted commit `8e913dcddfdec7d9aa920df8c37afb23b8c40884` as an immutable Personal Release and passed downloaded-release acceptance on the target MacBook/macOS 26.6. Personal Release remains ad-hoc signed, sandboxed, Hardened Runtime protected, checksum/provenance verified, and intentionally not notarized. Trusted Release remains an optional future tier.

## P0 Performance Foundation

Status: **ACCEPTED EVIDENCE; final PR #5 exact-head CI/review/merge gate pending**.

Canonical sources:

- `PERFORMANCE.md` — policy, accepted measurements, budgets, and regression rules;
- `performance/baseline-v0.1.0.json` — machine-readable canonical baseline;
- `docs/TESTING.md` — acceptance matrix and RED→GREEN evidence;
- `docs/ROADMAP.md` — milestone exit gate and M1 sequencing.

Implemented P0 foundation:

- event-driven runtime policy and source audit against unreviewed busy loops/timers/sleeps/display links;
- strict CPU/RSS/thread sampling/aggregation and Darwin `ps -M` thread measurement;
- development-only target-Mac sampler with explicit app/tool provenance;
- exactly 100,000 deterministic pointer/presentation decisions in CI without wall-clock threshold;
- exact immutable release artifact-size baseline;
- target-Mac CPU/RSS/thread acceptance ceilings;
- fail-closed artifact-size checker with 15% relative allowance plus independent absolute ceilings;
- shared-CI size regression gate;
- executable security proof that measurement tooling is not bundled into runtime packaging.

### Accepted target-Mac runtime baseline

Measured against accepted `v0.1.0` on macOS 26.6 / `Mac16,8`, using tooling commit `dfd4f87f8e5be04b467172d720d22bfc054c06d0`:

- `NH-PERF-IDLE-001`: CPU median/max `0.0% / 0.7%`, RSS median/max `33,648 / 33,808 KiB`, threads median/max `4 / 4`;
- `NH-PERF-HOVER-001`: CPU median/max `5.95% / 22.3%`, RSS median/max `38,456 / 38,816 KiB`, threads median/max `6 / 7`;
- `NH-PERF-STABILITY-001`: CPU median/max `0.0% / 6.8%`, RSS median/max `30,992 / 34,384 KiB`, threads median/max `3 / 7`;
- stability RSS `34,256 -> 30,544 KiB` (`-3,712 KiB`): no sustained memory growth observed;
- stability threads `4 -> 5`, max `7`: no runaway accumulation.

Measurement windows matched the stable contracts: idle `60.017 s / 60 samples`, hover `60.018 s / 60 samples`, stability `600.013 s / 120 samples`.

### Accepted immutable-release size baseline

Published `v0.1.0` metadata:

- executable `220,560 B`;
- app aggregate `223,555 B`;
- DMG `73,955 B`;
- build number `1`;
- release source `8e913dcddfdec7d9aa920df8c37afb23b8c40884`;
- DMG SHA-256 `cf53be6081b1836551fcbbb91b85fed800de4c089451961f3c6a21f6b77768bc`;
- Xcode 26.6 / Swift 6.3.3 provenance.

Runtime CPU/RSS/thread limits remain target-Mac acceptance gates. Shared GitHub runners never substitute for physical resource evidence. Artifact byte sizes are deterministic and are enforced in CI.

### RED→GREEN evidence

- RED CI #54: performance module absent as intended;
- RED CI #73: stability summarizer absent as intended;
- integration RED CI #75: Darwin `thcount` incompatibility discovered and fixed without dropping thread measurement;
- RED CI #91: size-budget comparison API absent as intended;
- GREEN CI #94: 12/12 release-policy tests, 22/22 performance-policy tests, performance/security audits, 11/11 Swift tests, package/signature/Sandbox/Hardened Runtime/DMG checks, deterministic size capture, size budget gate, harness smoke, and artifact upload all PASS.

CI #94 candidate sizes were executable `214,016 B`, app `217,012 B`, DMG `73,378 B`; all passed the canonical size budget.

## Security baseline

`SECURITY.md` is authoritative. P0 introduces no new runtime entitlement, telemetry, analytics, networking, subprocess/shell, dynamic loading, private API, privileged helper, or broader global input capture. Development performance tooling remains outside `NotchHub.app`.

## Approved M1 interaction requirements

After P0 merge:

- investigate replacing global `.mouseMoved` with reliable window-local AppKit tracking, accepting it only if correctness and target-Mac resource evidence are equal or better than the P0 baseline;
- add a cancellable hover dwell, initial candidate `120 ms`, without polling/repeating timers;
- add one public AppKit haptic via `NSHapticFeedbackManager.defaultPerformer` only on a successful deliberate compact → expanded transition;
- no haptic on cancellation, duplicate movement, retention, collapse, programmatic transitions, or stale callbacks;
- no `CGEventTap`, Accessibility, Input Monitoring, private APIs, custom drivers, or synthetic input.

Authoritative M1 spec: `docs/specs/M1_NOTCH_INTERACTION.md`.

## Known limitations

- initial target-Mac runtime ceilings are based on one canonical run per scenario and intentionally include conservative headroom;
- current global `.mouseMoved` path remains until M1 proves a reliable equal-or-better local alternative;
- active-display migration, Spaces/fullscreen policy, animation tuning, product modules, and optional trusted distribution remain later work.

## Next optimal step

1. Complete final exact-head CI and independent read-only review for PR #5; squash-merge only if both pass.
2. Start M1 with deterministic tracking-adapter regression tests and measured local AppKit tracking investigation.
3. Implement delayed hover + haptic test-first under `docs/specs/M1_NOTCH_INTERACTION.md`.
