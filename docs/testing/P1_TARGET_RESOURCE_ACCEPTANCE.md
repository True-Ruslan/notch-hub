# P1 Target-Mac Resource Acceptance

Status: **ACCEPTED — 2026-08-21**

Primary target: `Mac16,8` / macOS `26.6.x`
Accepted physical environment: `Mac16,8 / macOS 26.6.2`
Accepted measured runtime source: `11dad43364a969f4d5f8c1a92e1281b5b41c8a74`
Accepted measurement/evidence tooling: `fc7562b0799faa4dd80e8c47263354a8bd16bd6a`
Issue: #38 — closed completed after final review

This document freezes the accepted whole-app target-Mac performance/resource evidence. It does not create a new release claim: published Personal Release remains immutable `v0.1.0`.

## Acceptance boundary

The P1 evidence contract remains intentionally narrow and privacy-safe:

- process CPU percentage, RSS KiB and thread count are sampled through Darwin `/bin/ps`;
- `/bin/ps` sampler subprocesses use deterministic `LC_ALL=C` without changing the measured NotchHub process environment;
- Idle/Hover/Stability preserve the canonical 10-second warmup plus 60/60/600-second measurement windows and 1/1/5-second sample intervals;
- the normalized bundle requires one exact measured-app source SHA, one exact measurement-tool SHA and one exact target platform across every evidence file;
- the macOS family is canonical `26.6` / `26.6.x`, while the exact observed patch is preserved and must match across the entire bundle;
- manual evidence is closed-schema only: Idle Wake Ups, Energy and Compositor;
- raw traces, usernames, paths, window titles, media metadata and arbitrary notes are excluded from the normalized bundle;
- raw local evidence under `build/` is not committed.

The canonical path adds no telemetry, privileged helper, new entitlement, Accessibility/Input Monitoring/Automation/Screen Recording authority, automatic `sudo powermetrics`, polling loop, repeating timer, display link or synthetic-input automation.

## Final runtime provenance

The final measured runtime is not the original M6.6 merge. Physical acceptance uncovered real defects and each corrective lifecycle remains distinct.

### Hardware-notch initial screen selection — PR #40

A real multi-monitor launch exposed that `NSScreen.main` could be an external display even when the built-in hardware-notch screen was available.

- physical repair source: `46f069e57997eab060c79c3d9e279da944d6e263` — hardware-notch binding PASS on Mac16,8/macOS 26.6 with external monitor attached;
- final PR head: `b19801be1201a43572f5ea6574d32edfc9174dc5`, CI #1274 3/3 GREEN;
- squash merge: `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`;
- final head and merge share Git tree `f1884e9727d3d5794fb0122e86d9d0b85c3d9d21`.

### Exact compositor endpoint settlement — PR #51

Manual compositor acceptance on `e8d77968...` found a real stuck expanded-size panel showing compact content.

- RED: `7e06d24d0b89f4c413c180882ec9d628384e9bce`, expected test failure;
- GREEN/final physically accepted head: `329b867595b6ffe127fa3552f51bef8412865f37`, CI #1298 3/3 GREEN;
- physical acceptance: corrective compositor 10/10 PASS, prior freeze NOT OBSERVED, frame/corner anomalies NONE, reversal recovery PASS;
- squash merge: `1f56c3e5da8a46509a3472a52da12a1abfb16a8c`;
- accepted head and merge share Git tree `8aebcc6db915b77e30c51b1d4fc45e4c3b895bb1`.

The settlement invariant requires a matching current-generation completion to reconcile exact destination frame/corner before publishing settled logical presentation. Stale generations cannot reconcile the current physical endpoint.

### Bounded pointer escape monitoring — PR #53

Activity Monitor diagnostics on the post-PR #51 runtime showed persistent global `.mouseMoved` observation amplifying unrelated external-monitor pointer motion from about `3` to `111` Idle Wake Ups while NotchHub was otherwise inactive.

The first candidate that removed global observation entirely passed automated tests but failed physical rapid-exit interaction: a large black Peek panel could remain stuck. A later one-shot candidate also failed because the first inside global sample could remove the monitor before the true outside escape arrived. Both candidates were rejected rather than merged.

The final design arms global escape observation only during an actual local/tracking interaction, retains it while samples remain inside the current interactive region, delivers the actual outside sample to the existing interaction state machine and then tears down the monitor.

Final physically accepted head:

`bddd0503d972c652752a0e1463f3495685accc83`

Physical acceptance on Mac16,8/macOS 26.6.2:

- rapid exit: 30/30 PASS;
- stuck black panel: NOT OBSERVED;
- normal compositor cycles: 10/10 PASS;
- reversal recovery: PASS;
- hardware-notch binding: PASS;
- frame/corner/flicker anomalies: NONE;
- same-candidate Activity Monitor wakeup A/B: `2` stationary and `2` during unrelated external-monitor pointer motion.

PR #53 squash-merged as the final measured runtime:

`11dad43364a969f4d5f8c1a92e1281b5b41c8a74`

The accepted head and merge share Git tree:

`8f0a7fee0b02599520a5776133f51c1215da7d98`

## Final tooling provenance

P1 tooling evolved independently from the measured runtime.

- PR #36 foundation: `5cd9a2a47d87a433155f53b3aa0510000f2fce85`.
- PR #44 patch-family validator: `99a75dbe0664120a572bd8229d4fe461790ee07b`.
- PR #47 locale-stable `/bin/ps` sampler: `28965561f81c71ea58a352301fbe08554c644044`.
- PR #49 accepted closed manual compositor fallback/evidence contract: `fc7562b0799faa4dd80e8c47263354a8bd16bd6a`.

The final complete bundle uses exact tooling `fc7562b...`. The sampler implementation remains the locale-stable ancestry from PR #47; PR #49 changed the evidence contract/tests rather than the measured app.

## Final physical preflight

Before the accepted measurements:

- runtime worktree exact SHA: `11dad43364a969f4d5f8c1a92e1281b5b41c8a74`;
- tooling worktree exact SHA: `fc7562b0799faa4dd80e8c47263354a8bd16bd6a`;
- built app embedded source SHA matched the runtime;
- model: `Mac16,8`;
- macOS: `26.6.2`;
- exactly one NotchHub process was running from the expected measured app executable;
- hardware-notch display binding with external monitor attached: PASS.

The measurement process PID was `45013` for the coherent Idle/Hover/Stability/manual sequence. PID is execution provenance only and is intentionally not part of the normalized privacy-safe evidence schema.

## Final machine evidence

### Idle

Configuration: 10 s warmup + 60 s measurement, 1 s interval, 60 samples, compact untouched.

- CPU median: `0.0%`;
- CPU max: `0.0%`;
- RSS median: `58,432 KiB`;
- RSS max: `58,496 KiB`;
- thread median: `3`;
- thread max: `6`.

Direct Idle thread gate `threadMax <= 6`: **PASS**.

### Hover

Configuration: 10 s warmup + 60 s measurement, 1 s interval, 60 samples, fixed manual interaction cycle; no synthetic input.

- CPU median: `6.8%`;
- CPU max: `32.3%`;
- RSS median: `75,936 KiB`;
- RSS max: `76,784 KiB`;
- thread median: `6`;
- thread max: `6`.

Steady-state CPU median target `<= 8.0%`: **PASS**.
Direct Hover thread gate `threadMax <= 9`: **PASS**.

The one-second CPU max is retained as diagnostic spike evidence under the current `PERFORMANCE.md` policy. It is not a standalone portable cross-session failure gate.

### Stability

Configuration: 10 s warmup + 600 s measurement, 5 s interval, 120 samples, compact untouched.

- CPU median: `0.0%`;
- CPU max: `0.0%`;
- RSS median: `58,576 KiB`;
- RSS max: `59,520 KiB`;
- RSS start: `58,816 KiB`;
- RSS first quartile: `56,144 KiB`;
- RSS end: `54,848 KiB`;
- RSS end-minus-start: `-3,968 KiB`;
- thread median: `3`;
- thread max: `5`;
- thread start/end: `3 -> 3`;
- thread delta: `0`.

Direct gates:

- Stability RSS delta `<= +8192 KiB`: **PASS**;
- Stability thread max `<= 9`: **PASS**;
- Stability thread end-minus-start `<= +2`: **PASS**.

No unexplained sustained resource accumulation was observed.

## Final manual evidence

### Idle Wake Ups — 60 seconds

Method: `activity-monitor-idle-wake-ups`.

Observed value: `0.0 wakeups/s`.

This value was explicitly reviewed as healthy evidence. P1 does not invent a new hard numerical threshold from one run.

### Energy — 60 seconds

Method: `activity-monitor-energy` fallback because full Instruments Power Profiler was unavailable in the target environment.

Finding: `no-anomaly-observed`.

Observed Activity Monitor context:

- Energy Impact: `0.0`;
- App Nap: `No`;
- Preventing Sleep: `No`;
- displayed 12-hour aggregate: `0.29`.

The 12-hour aggregate is diagnostic historical context only and is not interpreted as the value of the 60-second observation window.

### Compositor — exactly 10 cycles

Method: `manual-visual-compositor`.

Finding: `no-anomaly-observed`.

Physical result:

- corrective compositor: 10/10 PASS;
- interaction recovery after reversal: PASS;
- freeze/stuck panel: NOT OBSERVED;
- frame/corner/flicker anomalies: NONE.

## Closed-schema manual evidence

The accepted local manual evidence had exactly this schema/value surface:

```json
{
  "schemaVersion": 1,
  "sourceCommit": "11dad43364a969f4d5f8c1a92e1281b5b41c8a74",
  "platform": {
    "macOSVersion": "26.6.2",
    "modelIdentifier": "Mac16,8"
  },
  "idleWakeups": {
    "method": "activity-monitor-idle-wake-ups",
    "observationSeconds": 60,
    "wakeupsPerSecond": 0.0
  },
  "energy": {
    "method": "activity-monitor-energy",
    "observationSeconds": 60,
    "finding": "no-anomaly-observed"
  },
  "compositor": {
    "method": "manual-visual-compositor",
    "interactionCycles": 10,
    "finding": "no-anomaly-observed"
  }
}
```

## Normalized bundle validation

`scripts/p1_target_resource_evidence.py` successfully built the final local `build/p1-target-resource-evidence.json` from the exact Idle/Hover/Stability/manual files.

Validated normalized bundle provenance:

- `sourceCommit`: `11dad43364a969f4d5f8c1a92e1281b5b41c8a74`;
- `measurementToolCommit`: `fc7562b0799faa4dd80e8c47263354a8bd16bd6a`;
- platform: `Mac16,8 / macOS 26.6.2`;
- `reviewRequired`: `false`.

Final explicit acceptance review:

- Idle thread max gate: PASS;
- Hover CPU median gate: PASS;
- Hover thread max gate: PASS;
- Stability RSS delta gate: PASS;
- Stability thread max gate: PASS;
- Stability thread delta gate: PASS;
- manual review status: PASS;
- final direct gates: **PASS**.

Bundle validation alone was not treated as acceptance; the aggregate values and manual observations were separately reviewed against `PERFORMANCE.md` before issue #38 was closed.

## Historical evidence policy

Earlier evidence remains useful but is not part of the final accepted bundle:

- old M6.6/runtime measurements;
- the diagnostic 26.6.1 collections;
- the pre-locale-fix `99a75dbe...` Idle report;
- the post-PR #40 and post-PR #51 bundles invalidated by later shipping runtime changes;
- wakeup/compositor observations from rejected pointer-monitor candidates.

These runs are not erased and must not be rewritten as though they measured `11dad433...`. Exact source/platform/tooling provenance remains authoritative.

## Final acceptance decision

P1 is **ACCEPTED**.

The evidence shows no material unresolved whole-app CPU/RSS/thread/wakeup/energy/compositor regression requiring further runtime optimization. In particular, no speculative optimization is authorized solely to improve already-accepted numbers.

P1 lifecycle:

**implemented -> tested -> physically accepted -> merged runtime measured -> accepted**.

This acceptance unblocks the next bounded product-hardening slice, preferably event-driven active-display/multi-monitor migration handling. Any such shipping change starts a new lifecycle and requires its own automated and physical acceptance; it does not inherit P1 acceptance merely because P1 is complete.
