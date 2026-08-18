# P1 Target-Mac Resource Acceptance

Status: PENDING — canonical P1 target-Mac measurements are not collected yet.

Primary target: `Mac16,8` / macOS `26.6`
Measured runtime source for the initial P1 audit: `bb6df211699c5aef7bac7d50866f3e24b2fe165b`

This runbook collects whole-app performance/resource evidence without changing the shipping application or granting additional permissions.

The stable Idle/Hover/Stability scenario identifiers and their historical definitions remain owned by `PERFORMANCE.md`; this runbook intentionally does not redeclare those acceptance IDs. Current-runtime P1 values are not accepted until the exact target evidence below is collected and reviewed.

## Evidence boundary

Machine-readable process metrics are collected by `scripts/perf-baseline.py` through Darwin `/bin/ps` only:

- CPU percentage;
- RSS in KiB;
- thread count.

Wakeups, energy and compositor observations remain explicit target-Mac evidence. The canonical path does **not** automatically invoke privileged collectors and does not store raw Instruments traces in the repository evidence bundle.

Do not commit the raw files under `build/`.

## 1. Prepare separate exact runtime and tooling checkouts

The initial P1 audit intentionally measures the already-merged M6.6 runtime while using the separately accepted P1 measurement tooling. These are **two different Git commits** and must not be collapsed into one checkout.

Set the exact runtime source and the final accepted P1 tooling source:

```bash
RUNTIME_SHA="bb6df211699c5aef7bac7d50866f3e24b2fe165b"
TOOLING_SHA="<accepted-P1-tooling-SHA>"
```

`TOOLING_SHA` must be replaced with the exact P1 foundation commit published after its canonical CI/merge gate. Do not use a moving branch name such as `main` or `agent/p1-target-mac-resource-audit` as measurement provenance.

From a clean repository checkout, create two detached worktrees:

```bash
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

git worktree add --detach ../notch-hub-p1-runtime "$RUNTIME_SHA"
git worktree add --detach ../notch-hub-p1-tooling "$TOOLING_SHA"

test "$(git -C ../notch-hub-p1-runtime rev-parse HEAD)" = "$RUNTIME_SHA"
test "$(git -C ../notch-hub-p1-tooling rev-parse HEAD)" = "$TOOLING_SHA"
```

Build the **measured application only from the runtime worktree**:

```bash
(
  cd ../notch-hub-p1-runtime
  ./scripts/build-app.sh
)

test "$(plutil -extract NHSourceCommit raw \
  ../notch-hub-p1-runtime/build/NotchHub.app/Contents/Info.plist)" = "$RUNTIME_SHA"
```

Quit any other NotchHub instance, then launch exactly that app:

```bash
open ../notch-hub-p1-runtime/build/NotchHub.app

PID="$(pgrep -x NotchHub)"
test -n "$PID"
ps -p "$PID" -o pid=,comm=
```

If more than one NotchHub process exists, stop and resolve that ambiguity rather than guessing a PID.

Run **all measurement and evidence commands from the tooling worktree**:

```bash
cd ../notch-hub-p1-tooling
test "$(git rev-parse HEAD)" = "$TOOLING_SHA"
```

`perf-baseline.py` records this tooling checkout as `measurementToolCommit`, while every `--source-commit "$RUNTIME_SHA"` argument pins the separately measured application source. The evidence bundler rejects reports if those provenance roles drift or disagree.

## 2. Idle scenario

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

## 3. Hover scenario

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

## 4. Stability scenario

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
