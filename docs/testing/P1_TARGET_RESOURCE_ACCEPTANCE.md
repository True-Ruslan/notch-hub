# P1 Target-Mac Resource Acceptance

Primary target: `Mac16,8` / macOS `26.6`
Measured runtime source for the initial P1 audit: `bb6df211699c5aef7bac7d50866f3e24b2fe165b`

This runbook collects whole-app performance/resource evidence without changing the shipping application or granting additional permissions.

## Evidence boundary

Machine-readable process metrics are collected by `scripts/perf-baseline.py` through Darwin `/bin/ps` only:

- CPU percentage;
- RSS in KiB;
- thread count.

Wakeups, energy and compositor observations remain explicit target-Mac evidence. The canonical path does **not** automatically invoke privileged collectors and does not store raw Instruments traces in the repository evidence bundle.

Do not commit the raw files under `build/`.

## 1. Prepare exact runtime and tooling

Use an exact app built from source:

```bash
RUNTIME_SHA="bb6df211699c5aef7bac7d50866f3e24b2fe165b"
git rev-parse "$RUNTIME_SHA"
```

Run the measurement commands from the accepted P1 tooling checkout. `perf-baseline.py` records that checkout as `measurementToolCommit`, while `--source-commit` pins the separately measured app runtime.

Quit any other NotchHub instance, launch the exact `RUNTIME_SHA` app normally, then obtain the PID:

```bash
PID="$(pgrep -x NotchHub)"
test -n "$PID"
ps -p "$PID" -o pid=,comm=
```

If more than one NotchHub process exists, stop and resolve that ambiguity rather than guessing a PID.

## 2. `NH-PERF-IDLE-001`

Keep NotchHub compact and untouched throughout the measurement.

```bash
python3 scripts/perf-baseline.py \
  --attach-pid "$PID" \
  --source-commit "$RUNTIME_SHA" \
  --scenario idle \
  --warmup-seconds 10 \
  --duration-seconds 60 \
  --interval-seconds 1 \
  --output build/p1-perf-idle.json
```

## 3. `NH-PERF-HOVER-001`

Start the sampler, then manually repeat the same five-second interaction cycle throughout the 60-second window: enter/Peek/expand or retain as appropriate, remain inside briefly, leave/collapse, then leave the remainder of the five-second cycle idle. Do not use automation or synthetic input.

```bash
python3 scripts/perf-baseline.py \
  --attach-pid "$PID" \
  --source-commit "$RUNTIME_SHA" \
  --scenario hover \
  --warmup-seconds 10 \
  --duration-seconds 60 \
  --interval-seconds 1 \
  --output build/p1-perf-hover.json
```

## 4. `NH-PERF-STABILITY-001`

Return the app to compact, then leave it untouched for the full run:

```bash
python3 scripts/perf-baseline.py \
  --attach-pid "$PID" \
  --source-commit "$RUNTIME_SHA" \
  --scenario stability \
  --warmup-seconds 10 \
  --duration-seconds 600 \
  --interval-seconds 5 \
  --output build/p1-perf-stability.json
```

The existing direct gates remain authoritative for long-run growth:

- RSS end-minus-start must not exceed `+8192 KiB`;
- thread growth must remain within the existing accepted ceiling;
- unexplained sustained accumulation blocks acceptance even when one steady snapshot looks favorable.

## 5. Idle wakeups — 60 seconds

Use Activity Monitor on the target Mac:

1. open **Activity Monitor**;
2. select the **Energy** view;
3. locate the exact running NotchHub process;
4. keep NotchHub compact and untouched for 60 seconds;
5. record the displayed **Idle Wake Ups** value as wakeups/second.

This is observation evidence, not telemetry. Do not grant NotchHub any permission for this measurement.

## 6. Energy — 60 seconds

Preferred method: Xcode Instruments **Power Profiler**.

- profile the exact running NotchHub process;
- keep the app compact and untouched for 60 seconds;
- classify the observation as `no-anomaly-observed` only when there is no unexplained sustained/background activity attributable to NotchHub;
- otherwise use `anomaly-observed` and investigate before acceptance.

If Power Profiler is unavailable, Activity Monitor Energy may be recorded using method `activity-monitor-energy`; do not invent a numerical cross-session threshold from one run.

The canonical P1 path does not require `sudo powermetrics` or `timerfires`.

## 7. Compositor — 10 interaction cycles

Use Xcode Instruments **Core Animation** against the exact running process. Perform ten normal interaction cycles covering compact -> Peek/Expanded -> Compact behavior, including representative horizontal/vertical movement.

Record:

- `no-anomaly-observed` when no unexplained recurring hitch/compositor anomaly is visible;
- `anomaly-observed` if a reproducible issue appears.

Do not convert a single noisy trace into a new hard numerical budget without repeated evidence.

## 8. Manual evidence JSON

Create `build/p1-manual-resource-evidence.json` locally:

```json
{
  "schemaVersion": 1,
  "sourceCommit": "bb6df211699c5aef7bac7d50866f3e24b2fe165b",
  "platform": {
    "macOSVersion": "26.6",
    "modelIdentifier": "Mac16,8"
  },
  "idleWakeups": {
    "method": "activity-monitor-idle-wake-ups",
    "observationSeconds": 60,
    "wakeupsPerSecond": 0.0
  },
  "energy": {
    "method": "instruments-power-profiler",
    "observationSeconds": 60,
    "finding": "no-anomaly-observed"
  },
  "compositor": {
    "method": "instruments-core-animation",
    "interactionCycles": 10,
    "finding": "no-anomaly-observed"
  }
}
```

Replace only the measured wakeup value and findings with observed values. Do not add notes, usernames, paths, window titles, raw trace data, media metadata or other free-form fields; the validator rejects extra schema surface.

## 9. Build normalized evidence bundle

```bash
python3 scripts/p1_target_resource_evidence.py \
  --source-commit "$RUNTIME_SHA" \
  --idle build/p1-perf-idle.json \
  --hover build/p1-perf-hover.json \
  --stability build/p1-perf-stability.json \
  --manual-evidence build/p1-manual-resource-evidence.json \
  --output build/p1-target-resource-evidence.json
```

The command fails closed when:

- source/tool provenance differs across reports;
- platform is not exact `Mac16,8 / 26.6`;
- scenario timing/sample counts differ from the canonical contract;
- reports use a non-attached measurement mode;
- required stability data is missing;
- manual methods/findings are unsupported;
- non-finite metrics or unknown/manual free-form keys appear.

The normalized bundle intentionally omits timestamps and raw trace payloads. `reviewRequired: true` means a manual energy/compositor anomaly was explicitly observed; it is a blocker for investigation, not something to rerun away.

## Acceptance rule

This evidence bundle is **not itself an automatic P1 PASS**. It proves provenance, completeness, schema and privacy safety. P1 acceptance additionally requires reviewing target values against the evidence-based policy in `PERFORMANCE.md`, characterizing repeated-run variance where needed, and resolving any `reviewRequired` finding.
