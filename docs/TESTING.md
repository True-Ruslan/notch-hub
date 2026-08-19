# Testing

## Policy

Automate every deterministic behavior that can be validated reliably. Manual acceptance is reserved for physical notch geometry, real pointer/trackpad feel, compositor continuity, haptic feel, macOS permission/trust surfaces, third-party integration and target-hardware resources.

A green pipeline is necessary but never substitutes for target-Mac acceptance. Manual success never substitutes for reproducible automated coverage.

## Required CI

Canonical protected-branch-intended jobs:

- `macOS 26 compatibility`;
- `macOS UI regression`;
- `Build, test and package`.

CI covers warnings-as-errors builds, Swift tests, exact external-app XCUI, acceptance-traceability policy, release/security/performance/media policy, strict formatting/plist/shell checks, Sandbox/Hardened Runtime/signing/system-library verification, shipping media preflight, deterministic artifact sizes, active provenance-backed feature budget, performance-harness schema smoke and artifacts.

Repository-side enforcement for `main` is currently tracked separately in issue #42 because GitHub reports the branch unprotected. The CI requirements above remain the project contract and must not be weakened merely because repository protection is temporarily missing.

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

## P1 target resource evidence foundation and tooling corrections

Status: **MERGED / CANONICAL CI VERIFIED / TARGET-MAC EVIDENCE PENDING**.

PR #36 established the development/release-only evidence foundation as historical tooling SHA:

`5cd9a2a47d87a433155f53b3aa0510000f2fce85`

Final PR #36 head `8f2e1c51ba8d69a66165a8e0db5f64f029cc3fcd` passed CI #1260 3/3 GREEN. Squash-merged foundation source `5cd9a2a4...` passed post-merge CI #1261 3/3 GREEN.

The foundation changed no `Sources/` file. Canonical deterministic coverage includes `P1TargetResourceEvidencePolicyTests`, which launches Python P1 tests inside normal `swift test` so the evidence contract cannot silently fall outside the canonical gate.

Before physical collection began, the target Mac was observed on macOS `26.6.1`. The sampler already recorded exact `sw_vers -productVersion`, but the bundler still hard-coded literal `26.6`. PR #44 corrected that tooling contract:

- exact model remains `Mac16,8`;
- accepted OS family is canonical `26.6` / `26.6.x` only;
- exact patch version is preserved, not normalized away;
- Idle/Hover/Stability/manual evidence must all report the same exact platform;
- adjacent minor versions, malformed/extra/leading-zero version components and wrong models fail closed;
- `P1TargetResourceEvidencePolicyTests` runs both `test_p1_target_resource_evidence.py` and `test_p1_target_platform_family.py` inside canonical Swift tests;
- a temporary separate PR workflow used only to establish isolated RED/GREEN evidence was removed after release policy correctly rejected a second untrusted pull-request execution path.

Final PR #44 head `b1ff7dab8a1f386c04d9d5e2792ba27ca9f89b6a` passed CI #1283 3/3 GREEN and squash-merged as tooling `99a75dbe0664120a572bd8229d4fe461790ee07b`.

The first real collection attempt then exposed a second tooling defect. Idle completed and remains valid diagnostic evidence, including thread median/max `3/7`, but Hover produced no evidence file because `/bin/ps` inherited an interactive locale and returned a comma decimal separator while `parse_ps_sample` correctly requires dot-decimal input.

PR #47 fixed the sampler boundary rather than weakening parsing:

- `scripts/perf-baseline.py` copies the parent environment for process sampling and sets `LC_ALL=C` only for the two `/bin/ps` child processes;
- unrelated environment variables remain available;
- the measured NotchHub process environment is unchanged;
- strict parser behavior is unchanged;
- `test_perf_baseline_locale.py` proves both sampling subprocesses receive deterministic locale settings even under a non-C parent locale;
- `P1TargetResourceEvidencePolicyTests` now runs all three P1 Python suites in the existing canonical Swift gate.

RED head `63af71dc9a614837fa2fe67f31d0cd0b5e3c0aa9` failed CI #1287 exactly because both ps calls had `env=None`; the existing P1 suites remained green. GREEN head `5e1d870f67972d5799c34e77acc1a8c1f4de9f7b` passed CI #1288 3/3 GREEN, including coverage-instrumented tests, release/security/performance policy, Performance harness compatibility smoke and UI regression. PR #47 squash-merged as current P1 measurement tooling:

`28965561f81c71ea58a352301fbe08554c644044`

Older tooling SHAs remain immutable provenance but are superseded for new physical P1 collection.

## P1 physical/resource collection boundary

The canonical P1 audit must use two distinct detached sources:

- measured corrected merged runtime: `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`;
- measurement tooling: `28965561f81c71ea58a352301fbe08554c644044`.

The current physical target environment is `Mac16,8 / macOS 26.6.1`. The validator accepts the macOS 26.6 patch family but requires every report and the manual evidence to preserve the same exact patch version within one bundle.

The previous runtime `bb6df211699c5aef7bac7d50866f3e24b2fe165b` remains historical M6.6 merge evidence but is superseded for P1 measurement by the later hardware-notch screen-selection correction. Later docs-only commits do not replace the current runtime/tooling provenance anchors. Canonical target procedure is `docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md`.

The Idle report collected with prior tooling `99a75dbe...` remains diagnostic evidence, including `threadMax=7` against the current Idle gate `<=6`. It must not be mixed into a bundle whose other reports use `28965561...`. The complete canonical Idle/Hover/Stability set must therefore be recollected on the new tooling SHA. This is provenance-driven recollection, not permission to repeat runs until a favorable value appears; a repeated thread excess remains a blocker.

Shared-runner CPU/RSS magnitudes are compatibility evidence, not target-Mac acceptance. P1 uses the real Mac16,8/macOS 26.6.x target for CPU/RSS/threads/wakeups/energy/compositor review while preserving exact patch provenance.

The canonical P1 path does not automatically run privileged collectors such as `sudo powermetrics` or `timerfires`, does not add app permissions, and does not commit raw Instruments traces. Numeric budgets are introduced only after repeatable real-hardware evidence supports them.
