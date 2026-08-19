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

For production behavior and new acceptance infrastructure:

1. add a focused regression test;
2. preserve a RED run proving the intended missing behavior;
3. implement the minimum GREEN change;
4. run full CI/security/performance verification;
5. only then advance to another independent defect.

Race, stale-callback, boundary and teardown behavior must be tested deterministically without arbitrary sleeps where practical.

## M6.6 automated acceptance baseline

The original physically accepted runtime source is `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3`.

Canonical CI #1241 / run `32075976405` passed all three jobs, 366 Swift tests / 80 suites, 11/11 native external-app XCUI tests, strict acceptance traceability, production transport/archive verification, release security/signing/preflight, active size budget and shared-runner performance smoke.

The horizontal regression stack includes `MediaGestureInputNormalizerTests`, `MediaGestureCoordinatorTests` and `MediaGesturePhysicalPipelineTests`, covering raw AppKit direction through normalization, follow-finger visuals and typed commands across macOS scroll-direction preference states.

Hover/Peek, interaction, seek/source and lifecycle regressions cover exact dwell/grace, generic no-media Peek, stale activation rejection, exact-top-edge containment, endpoint settlement, capability gating, identity invalidation, balanced cursor ownership, bounded source lookup, transport stop races and stale callback rejection.

## M6.6 physical acceptance and merge

On 2026-08-18 Mac16,8/macOS 26.6, the complete requested physical matrix passed on exact source `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3` after CI #1241 was green.

Acceptance-record head `c9fbd0605b33a318bb4371ae0f2c928120356adf` passed CI #1243 3/3 GREEN without changing production code. PR #33 was squash-merged as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`; post-merge main CI #1244 ultimately passed all three jobs on that exact source.

M6.6 is merged but not released.

## M6.6 hardware-notch screen-selection correction

A later real multi-monitor launch check found that the panel could bind to external `NSScreen.main` while a hardware-notch screen was available. The correction followed the same split automation/physical policy:

- focused regression tests prove that a hardware-notch display wins over the preferred/main external display while preserving no-notch fallback;
- exact runtime `46f069e57997eab060c79c3d9e279da944d6e263` was built with matching `NHSourceCommit` and physically re-checked on Mac16,8/macOS 26.6 with external monitor attached — PASS;
- commits after `46f069e...` through the final PR head changed only policy/tests/CI metadata and no shipping `Sources/` file;
- final PR head `b19801be1201a43572f5ea6574d32edfc9174dc5` passed CI #1274 3/3 GREEN, including `macOS 26 compatibility`, `macOS UI regression`, `Build, test and package`, active size budget, Sandbox and Hardened Runtime checks;
- PR #40 squash-merged as `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`, sharing Git tree `f1884e9727d3d5794fb0122e86d9d0b85c3d9d21` with the final PR head.

Do not rewrite the exact physical claim from `46f069e...` to the squash SHA. The merged runtime is `e8d77968...`; the physically executed correction remains `46f069e...`.

## Acceptance traceability

Authoritative M6.6 ledgers:

- `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`;
- `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`;
- `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`.

Machine-readable coverage lives in `Tests/Acceptance/coverage.yml` plus `coverage-current.json`; `scripts/test_acceptance_coverage.py --mode strict` must remain green. Accepted IDs must cite concrete automated coverage, physical evidence, or both.

Original full M6.6 physical source acceptance stays pinned to `8744b9e...`; the later hardware-notch screen-selection correction has its own exact physical source `46f069e...`. Documentation descendants and squash merges do not rewrite either exact target-Mac claim.

## P1 target resource evidence foundation

Status: **MERGED / POST-MERGE CI VERIFIED / TARGET-MAC EVIDENCE PENDING**.

PR #36 merged the development/release-only evidence foundation as exact tooling SHA:

`5cd9a2a47d87a433155f53b3aa0510000f2fce85`

Final PR head `8f2e1c51ba8d69a66165a8e0db5f64f029cc3fcd` passed CI #1260 3/3 GREEN. Squash-merged main/tooling source `5cd9a2a4...` passed post-merge CI #1261 3/3 GREEN.

The foundation changed no `Sources/` file. Canonical deterministic coverage includes `P1TargetResourceEvidencePolicyTests`, which launches `scripts/test_p1_target_resource_evidence.py` inside normal `swift test` so the Python evidence contract cannot silently fall outside the protected gate.

TDD evidence:

- CI #1245 / head `6b7e90ff17803ef2678ff518b84fe82c8a39e06f`: missing `p1_target_resource_evidence` implementation was the sole new failure;
- CI #1258 / head `98cd0974da8e1a71b6322d168e9f28834fe72a0c`: malformed list/dict manual fields exposed uncontrolled `TypeError`; final code converts these to fail-closed `EvidenceError`;
- final pre-merge and post-merge canonical gates are GREEN.

The evidence contract validates exact measured runtime source, one shared measurement-tool commit, exact Mac16,8/macOS 26.6 platform, fixed idle/hover/stability timing/sample counts, attached-process mode, finite metrics, required stability summary and closed manual methods/findings. Normalized evidence omits timestamps/raw traces and does not invent energy/compositor thresholds. Explicit manual anomaly sets `reviewRequired: true`.

## P1 physical/resource collection boundary

The canonical P1 audit must use two distinct detached sources:

- measured corrected merged runtime: `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`;
- measurement tooling: `5cd9a2a47d87a433155f53b3aa0510000f2fce85`.

The previous runtime `bb6df211699c5aef7bac7d50866f3e24b2fe165b` remains historical M6.6 merge evidence but is superseded for P1 measurement by the later hardware-notch screen-selection correction. Later docs-only commits do not replace the current runtime/tooling provenance anchors. Canonical target procedure is `docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md`.

Shared-runner CPU/RSS magnitudes are compatibility evidence, not target-Mac acceptance. P1 uses the real Mac16,8/macOS 26.6 for CPU/RSS/threads/wakeups/energy/compositor review.

The canonical P1 path does not automatically run privileged collectors such as `sudo powermetrics` or `timerfires`, does not add app permissions, and does not commit raw Instruments traces. Numeric budgets are introduced only after repeatable real-hardware evidence supports them.
