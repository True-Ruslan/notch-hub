# Testing

## Policy

Automate every deterministic behavior that can be validated reliably. Manual acceptance is reserved for physical notch geometry, real pointer/trackpad feel, compositor continuity, haptic feel, macOS permission/trust surfaces, third-party integration and target-hardware resources.

A green pipeline is necessary but never substitutes for target-Mac acceptance. Manual success never substitutes for reproducible automated coverage.

## Required CI

Canonical protected-branch jobs:

- `macOS 26 compatibility`;
- `macOS UI regression`;
- `Build, test and package`.

CI covers warnings-as-errors builds, Swift tests, exact external-app XCUI, acceptance-traceability policy, release/security/performance/media policy, strict formatting/plist/shell checks, Sandbox/Hardened Runtime/signing/system-library verification, shipping media preflight, deterministic artifact sizes, active provenance-backed feature budget, performance-harness schema smoke and artifacts.

Do not weaken tests, security rules, production behavior or historical baselines merely to obtain green CI.

## Regression/UI automation foundation

PR #34 merged the native regression foundation as `bd9566f690d314ed40fd6f3723a319291ceb4a58`; post-merge main CI #1053 passed all three jobs.

The foundation includes exact SwiftPM-built app launch through XCUI, source provenance validation, compile-time-only fixtures, stable accessibility IDs, state-driven synchronization, diagnostics, and fail-closed machine-readable acceptance coverage.

## TDD rule

For production behavior:

1. add a focused regression test;
2. preserve a RED run proving the intended missing behavior;
3. implement the minimum GREEN change;
4. run full CI/security/performance verification;
5. only then advance to another independent defect.

Race, stale-callback, boundary and teardown behavior must be tested deterministically without arbitrary sleeps where practical.

## M6.6 automated acceptance baseline

The physically accepted runtime source is `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3`.

Canonical CI #1241 / run `32075976405` passed:

- all three canonical jobs;
- 366 Swift tests / 80 suites;
- 11/11 native external-app XCUI tests;
- strict acceptance traceability;
- production transport/archive verification;
- release DMG, security, App Sandbox-only entitlement, Hardened Runtime, signing and shipping preflight;
- active cumulative size budget without widening;
- shared-runner performance smoke.

The horizontal regression stack includes:

- `MediaGestureInputNormalizerTests` for physical-axis normalization;
- `MediaGestureCoordinatorTests` for direction, threshold, hysteresis, haptic, momentum, diagonal arbitration, capability validation and vertical intent;
- `MediaGesturePhysicalPipelineTests` for raw AppKit X -> normalization -> follow-finger visual offset -> typed command across both macOS scroll-direction preference states.

Hover/Peek and interaction regressions cover exact 120 ms dwell, 140 ms exit grace, generic no-media Peek, stale activation rejection, local pointer exit, exact-top-edge inclusive containment, interactive exact endpoint settlement and lost-terminal safety.

Seek/source/lifecycle regressions cover capability gating, local preview and commit/cancel behavior, session identity invalidation, balanced cursor ownership, bounded public `NSWorkspace` source lookup, transport stop-before-queued-work races and stale callback rejection.

## M6.6 physical acceptance

On 2026-08-18 Mac16,8/macOS 26.6, the complete requested physical matrix passed on exact source `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3` after CI #1241 was green.

Physical evidence includes:

- RIGHT -> Previous/back, follow-finger RIGHT, one supported arm haptic;
- LEFT -> Next, follow-finger LEFT, one supported arm haptic;
- media-on Hover Peek + haptic and stationary-pointer relaunch;
- no-media generic Hover Peek + haptic;
- prompt single click expansion while hover/media enrichment may overlap;
- exact-top-edge and center DOWN without twitch/self-collapse;
- expanded pointer-exit and physical UP exact Compact settlement;
- seek preview/commit/cancel, cursor restore and track/source identity cancellation;
- source icon and fallback rendering;
- Accessibility / Input Monitoring / Automation / Screen Recording all NONE;
- post-Quit helper cleanup confirmed by empty `pgrep -lf 'mediaremote-adapter\.pl' || true`.

Deterministic-only subcontracts such as exact timer thresholds, hysteresis, diagonal rejection, stale generation rejection and Reduce Motion policy are accepted through automated evidence rather than invented manual evidence.

## Acceptance traceability

Authoritative M6.6 ledgers:

- `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`;
- `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`;
- `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`.

Machine-readable coverage lives in `Tests/Acceptance/coverage.yml` plus `coverage-current.json`; `scripts/test_acceptance_coverage.py --mode strict` must remain green. Accepted IDs must cite concrete automated coverage, physical evidence, or both. Historical rejected evidence is retained in prose but no longer describes the final exact candidate.

The acceptance-record commit is documentation/coverage-only. Physical source acceptance stays pinned to `8744b9e...`; a docs-only descendant is not a replacement runtime candidate.

## Performance boundary

`performance/baseline-v0.1.0.json` and historical feature budgets remain immutable evidence. The active cumulative envelope is `performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json`; CI #1241 passed it without widening.

Shared-runner CPU/RSS magnitudes are compatibility evidence, not target-Mac acceptance. P1 target resource review starts only after PR #33 merge and post-merge `main` CI.
