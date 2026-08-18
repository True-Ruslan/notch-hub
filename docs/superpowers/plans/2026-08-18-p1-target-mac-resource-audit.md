# P1 Target-Mac Resource Audit Plan

Date: 2026-08-18
Primary target: Mac16,8 / macOS 26.6
Runtime baseline for this audit: merged M6.6 main `bb6df211699c5aef7bac7d50866f3e24b2fe165b`
Status: active

## Goal

Measure the merged whole application on the real target Mac before any broader multi-monitor hardening or new product module. The audit must distinguish reproducible machine evidence from manual hardware/tool observation and must not add runtime telemetry, privileged helpers, polling, or broader input authority.

## Phase 1 — evidence foundation

PR #36 establishes a development/release-only evidence boundary:

1. keep the existing `/bin/ps` collector for CPU, RSS and thread count;
2. validate exact `NH-PERF-IDLE-001`, `NH-PERF-HOVER-001` and `NH-PERF-STABILITY-001` configuration;
3. require one exact measured-app source SHA, one measurement-tool SHA and exact `Mac16,8 / 26.6` platform across all reports;
4. record only normalized aggregate values in the combined evidence bundle;
5. summarize idle wakeups through Activity Monitor and energy/compositor observations through supported Apple developer tools;
6. reject arbitrary free-form/manual fields and raw trace payloads from the machine-readable evidence;
7. run the evidence-contract regression inside canonical `swift test` so it cannot silently fall out of CI.

This phase changes no shipping runtime behavior.

## Phase 2 — target-Mac collection

Measure exact merged M6.6 runtime source `bb6df211699c5aef7bac7d50866f3e24b2fe165b` with the accepted P1 measurement-tool commit.

Required evidence:

- `NH-PERF-IDLE-001`: 10 s warmup + 60 s compact untouched, 1 s samples;
- `NH-PERF-HOVER-001`: 10 s warmup + 60 s, 1 s samples, repeated fixed 5-second hover/interaction cycle;
- `NH-PERF-STABILITY-001`: 10 s warmup + 600 s compact untouched, 5 s samples;
- idle wakeups: 60-second Activity Monitor observation;
- energy: 60-second Instruments Power Profiler observation, or Activity Monitor Energy only when Instruments is unavailable;
- compositor: 10 explicit interaction cycles observed with Instruments Core Animation.

The canonical collection path does not require `sudo`, `powermetrics`, `timerfires`, Accessibility, Input Monitoring, Automation, Screen Recording, or any app entitlement change.

## Phase 3 — variance and diagnosis

Before setting new absolute cross-session ceilings:

1. repeat the key idle measurement enough to characterize normal target variance;
2. compare the current merged runtime against the immutable `v0.1.0` baseline only where the metric is genuinely comparable;
3. preserve same-session A/B for noisy steady RSS/CPU evidence;
4. retain the existing direct within-run stability gates for RSS growth and threads;
5. investigate any manual energy/compositor anomaly rather than averaging it away through repeated runs.

Do not rerun merely to obtain a favorable sample.

## Phase 4 — optimization decisions

Only evidence-backed regressions justify runtime changes. Candidate areas include:

- the existing narrow global `.mouseMoved` fallback versus reliable local tracking;
- observer/process lifecycle costs;
- unnecessary SwiftUI/AppKit invalidation or compositor work;
- avoidable memory retention or cache growth.

Any optimization must preserve M6.6 physical behavior and the existing permission/security boundary. A lower resource number does not justify unreliable hover, broader input capture, polling, or weakened lifecycle checks.

## Exit criteria

P1 can be accepted only when:

- canonical target evidence is complete for the exact measured runtime source;
- CPU/RSS/thread reports pass provenance and scenario validation;
- long-run RSS/thread growth stays bounded by the existing evidence-based rules;
- idle wakeups are explicitly recorded and reviewed;
- energy and compositor observations report no unexplained anomaly;
- repeated-run variance is characterized before introducing new absolute budgets;
- no performance collector is bundled into `NotchHub.app`;
- normal correctness/security/UI CI remains green;
- any required optimization is separately tested and physically re-accepted if it changes runtime behavior.

P1 completion does not itself publish a new release. `v0.1.0` remains immutable until an explicit later Personal Release decision.
