# P1 Target-Mac Resource Audit Plan

Date: 2026-08-18
Primary target: Mac16,8 / macOS 26.6.x
Current physical environment: Mac16,8 / macOS 26.6.1
Measured runtime: `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`
Measurement tooling: `28965561f81c71ea58a352301fbe08554c644044`
Status: active — measurement foundation merged; corrected runtime re-frozen; platform and locale tooling corrections merged; complete target-Mac recollection next

## Goal

Measure the corrected merged whole application on the real target Mac before any broader multi-monitor hardening or new product module. The audit must distinguish reproducible machine evidence from manual hardware/tool observation and must not add runtime telemetry, privileged helpers, polling, or broader input authority.

## Phase 1 — evidence foundation — DONE

PR #36 established and merged a development/release-only evidence boundary:

1. keep the existing `/bin/ps` collector for CPU, RSS and thread count;
2. validate exact Idle/Hover/Stability configuration owned by `PERFORMANCE.md`;
3. require one exact measured-app source SHA, one measurement-tool SHA and target platform provenance across all reports;
4. record only normalized aggregate values in the combined evidence bundle;
5. summarize idle wakeups through Activity Monitor and energy/compositor observations through supported Apple developer tools;
6. reject arbitrary free-form/manual fields, malformed manual types and raw trace payloads from machine-readable evidence;
7. run the evidence-contract regression inside canonical `swift test` so it cannot silently fall out of CI.

TDD RED evidence is preserved by CI #1245 and #1258. Final PR head `8f2e1c51ba8d69a66165a8e0db5f64f029cc3fcd` passed CI #1260 3/3 GREEN. Squash-merged foundation source `5cd9a2a47d87a433155f53b3aa0510000f2fce85` passed post-merge main CI #1261 3/3 GREEN.

This phase changed no shipping runtime source.

## Corrective runtime provenance gate — DONE

Before target collection started, a real multi-monitor launch regression invalidated the old P1 runtime as the canonical measurement target: the panel could bind to `NSScreen.main` even when the built-in hardware-notch display was available.

PR #40 repaired the selection policy using public AppKit only and preserved the no-notch fallback. Provenance is intentionally split by lifecycle stage:

- exact runtime `46f069e57997eab060c79c3d9e279da944d6e263` was physically re-checked on Mac16,8/macOS 26.6 with an external monitor attached — hardware-notch binding PASS;
- every later commit through the final PR head changed only size-policy/CI/test metadata, with no further shipping `Sources/` change;
- final PR head `b19801be1201a43572f5ea6574d32edfc9174dc5` passed CI #1274 3/3 GREEN;
- PR #40 squash-merged as `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`;
- final PR head and merge commit share Git tree `f1884e9727d3d5794fb0122e86d9d0b85c3d9d21`.

The previous frozen P1 runtime `bb6df211699c5aef7bac7d50866f3e24b2fe165b` remains historical M6.6 merge evidence but is superseded for P1 measurement. Canonical P1 collection measures the corrected **merged** runtime `e8d77968...`; the exact physical acceptance claim remains pinned to `46f069e...`.

## Patch-family tooling provenance gate — DONE

Before physical resource collection began, the target Mac was observed on macOS `26.6.1`. `perf-baseline.py` already recorded exact `sw_vers -productVersion`, but the evidence bundler still required the literal platform string `26.6`.

PR #44 corrected this without changing the sampler or shipping runtime:

1. exact model remains `Mac16,8`;
2. accepted OS family is canonical `26.6` / `26.6.x` only;
3. the exact observed patch string is preserved in normalized evidence;
4. Idle/Hover/Stability/manual evidence must agree on the same exact platform;
5. adjacent minor versions, malformed/extra/leading-zero components and wrong hardware fail closed;
6. the existing `P1TargetResourceEvidencePolicyTests` Swift bridge runs the P1 Python suites inside canonical `swift test`;
7. release policy remains intact: a temporary alternate `pull_request` workflow used to establish isolated RED/GREEN evidence was removed, preserving one reviewed untrusted PR execution path.

Final PR #44 head `b1ff7dab8a1f386c04d9d5e2792ba27ca9f89b6a` passed CI #1283 3/3 GREEN. PR #44 squash-merged as tooling `99a75dbe0664120a572bd8229d4fe461790ee07b`.

## Locale-stable sampler provenance gate — DONE

The first target attempt on tooling `99a75dbe...` produced a valid diagnostic Idle report on exact Mac16,8/macOS 26.6.1. Its summary was CPU median/max `0.0/0.0%`, RSS median/max `56,416/58,464 KiB`, and thread median/max `3/7`. The observed `threadMax=7` exceeded the existing direct Idle gate `<=6`; that finding remains diagnostic history.

Hover then produced no evidence file because `/bin/ps` inherited the interactive locale and returned a comma decimal separator, while `parse_ps_sample` correctly rejects locale-dependent numeric text. PR #47 fixed the measurement boundary:

1. copy the parent environment for process sampling;
2. force `LC_ALL=C` only for `/bin/ps` CPU/RSS and `/bin/ps -M` thread sampling;
3. preserve unrelated environment variables;
4. leave the measured NotchHub process environment unchanged;
5. keep the parser strict/fail-closed;
6. run the new locale regression through the existing canonical Swift-to-Python P1 bridge;
7. change no shipping runtime source, permission, entitlement, telemetry, networking or polling behavior.

RED head `63af71dc9a614837fa2fe67f31d0cd0b5e3c0aa9` failed CI #1287 exactly because both ps calls inherited the parent environment without an explicit `env`. GREEN head `5e1d870f67972d5799c34e77acc1a8c1f4de9f7b` passed CI #1288 3/3 GREEN, including coverage, release/security/performance policy, Performance harness compatibility smoke and UI regression. PR #47 squash-merged as current measurement tooling `28965561f81c71ea58a352301fbe08554c644044`.

The prior `99a75dbe...` Idle report remains diagnostic evidence, but it cannot be combined with new reports because `measurementToolCommit` is part of the closed provenance contract. Complete canonical collection must therefore restart from Idle on tooling `28965561...`. This is a provenance requirement, not permission to rerun until a favorable result appears; if the thread excess repeats, it remains a blocker.

## Phase 2 — target-Mac collection — NEXT

Measure exact corrected merged runtime source `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251` using exact P1 measurement-tool commit `28965561f81c71ea58a352301fbe08554c644044` in a separate detached tooling worktree.

Current collection environment is exact `Mac16,8 / macOS 26.6.1`. The validator accepts the 26.6 patch family but every file in one bundle must preserve the same exact patch version. If the OS changes before completion, start a fresh complete bundle rather than mixing sessions.

Required evidence:

- Idle: 10 s warmup + 60 s compact untouched, 1 s samples;
- Hover: 10 s warmup + 60 s, 1 s samples, repeated fixed 5-second hover/interaction cycle;
- Stability: 10 s warmup + 600 s compact untouched, 5 s samples;
- idle wakeups: 60-second Activity Monitor observation;
- energy: 60-second Instruments Power Profiler observation, or Activity Monitor Energy only when Instruments is unavailable;
- compositor: 10 explicit interaction cycles observed with Instruments Core Animation.

The canonical collection path does not require `sudo`, `powermetrics`, `timerfires`, Accessibility, Input Monitoring, Automation, Screen Recording, or any app entitlement change.

## Phase 3 — variance and diagnosis

Before setting new absolute cross-session ceilings:

1. characterize normal target variance without rerunning merely for a favorable sample;
2. compare the current merged runtime against immutable `v0.1.0` only where the metric is genuinely comparable;
3. preserve same-session A/B for noisy steady RSS/CPU evidence;
4. retain existing direct within-run stability gates for RSS growth and threads;
5. treat repeated direct-gate failures such as Idle thread max `>6` as blockers requiring investigation;
6. investigate any manual energy/compositor anomaly rather than averaging it away through repeated runs.

## Phase 4 — optimization decisions

Only evidence-backed regressions justify runtime changes. Candidate areas include:

- the existing narrow global `.mouseMoved` fallback versus reliable local tracking;
- observer/process lifecycle costs;
- unnecessary SwiftUI/AppKit invalidation or compositor work;
- avoidable memory retention or cache growth.

Any optimization must preserve M6.6 physical behavior, hardware-notch screen binding and the existing permission/security boundary. A lower resource number does not justify unreliable hover, broader input capture, polling, or weakened lifecycle checks.

## Exit criteria

P1 can be accepted only when:

- canonical target evidence is complete for exact measured runtime `e8d77968...` using exact tooling `28965561...`;
- all evidence in one bundle agrees on exact `Mac16,8` and one canonical macOS 26.6 patch version;
- CPU/RSS/thread reports pass provenance and scenario validation;
- long-run RSS/thread growth stays bounded by existing evidence-based rules;
- direct thread gates pass or any failure is explained and remediated through evidence-backed work;
- idle wakeups are explicitly recorded and reviewed;
- energy and compositor observations report no unexplained anomaly;
- repeated-run variance is characterized before introducing new absolute budgets;
- no performance collector is bundled into `NotchHub.app`;
- normal correctness/security/UI CI remains green;
- any required optimization is separately tested and physically re-accepted if it changes runtime behavior.

P1 completion does not itself publish a new release. `v0.1.0` remains immutable until an explicit later Personal Release decision.
