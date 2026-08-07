# Performance and resource-efficiency policy

NotchHub is intended to remain available continuously near system UI. CPU, memory, threads, wakeups/background activity, artifact size, and lifecycle efficiency are therefore product requirements alongside security and correctness.

Primary measurement target: MacBook with hardware notch, macOS 26.6.

## Runtime invariants

Runtime code is event-driven by default.

The following require an explicit reviewed performance justification, bounded lifecycle, tests, and documentation in the same PR:

- polling loops;
- repeating `Timer` / timer publishers;
- `DispatchSourceTimer`;
- repeating sleep-based work;
- display links;
- permanent busy loops;
- broad system-wide observation when a reliable local OS event exists.

A compact, untouched NotchHub must not create self-initiated periodic work merely to remain ready. OS-delivered events are measured separately and should be minimized.

Observers, notification tokens, event monitors, tasks, security-scoped resources, and future subscriptions must have explicit ownership and cancellation. Future caches and collections must be bounded by count/size and have an eviction or replacement rule.

Performance work must never justify weaker App Sandbox/Hardened Runtime settings, broader input capture, privileged helpers, hidden networking, runtime telemetry, or dynamic code loading.

## Deterministic CI boundary

CI may fail on reproducible invariants, including:

- unreviewed polling/timer/sleep/display-link primitives in `Sources/**/*.swift`;
- deterministic policy or parser regressions;
- lifecycle/state behavior that can be proven without wall-clock timing;
- development performance tooling being copied or referenced into the shipped app bundle;
- artifact-size regressions after a stable baseline and budget exist.

Shared GitHub runners must **not** enforce tight CPU, RSS, thread, wakeup, or energy thresholds. Their load and hardware are too variable for honest release gates.

`scripts/performance_policy.py` and `scripts/test_performance_policy.py` provide the deterministic scanner, process-sample parser/aggregation, and budget-comparison helpers. `scripts/perf-baseline.py` is development/release tooling only and is never bundled into NotchHub.

## Target-Mac measurement harness

The harness samples only process-level metrics through `/bin/ps`:

- CPU percent;
- resident set size (RSS) in KiB;
- thread count.

Its JSON output also records scenario configuration, macOS version, a generic hardware model identifier, measured-app source commit, and measurement-tool commit.

It deliberately does **not** record usernames, home paths, file names/content, clipboard/snippet content, window titles, pointer coordinates/history, calendar/media data, serial numbers, or telemetry identifiers.

Raw local measurement outputs under `build/` are development artifacts and are not committed. Only reviewed aggregate baseline values may enter `performance/`.

## Stable performance scenarios

### `NH-PERF-IDLE-001`

- measured app: accepted Personal Release `v0.1.0` (`8e913dcddfdec7d9aa920df8c37afb23b8c40884`);
- warmup: 10 s;
- measurement: 60 s;
- sample interval: 1 s;
- interaction: none; panel remains compact and untouched.

### `NH-PERF-HOVER-001`

- warmup: 10 s;
- measurement: 60 s;
- sample interval: 1 s;
- manually repeat a fixed 5-second interaction cycle: enter/expand, move inside/retain, leave/collapse, then leave the remainder of the cycle idle;
- sampler runs independently from the interaction and never synthesizes input.

### `NH-PERF-STABILITY-001`

- warmup: 10 s;
- measurement: 600 s;
- sample interval: 5 s;
- interaction: none;
- review start/end, median, and maximum RSS/thread behavior for sustained growth.

### `NH-PERF-SIZE-001`

Record exact bytes for:

- `NotchHub.app/Contents/MacOS/NotchHub`;
- aggregate regular-file bytes in `NotchHub.app`;
- `NotchHub.dmg`.

### `NH-PERF-STATE-001`

Run exactly 100,000 deterministic pointer/presentation policy decisions in Swift test code. Assert behavior/state invariants only; do not use elapsed wall-clock time as a CI threshold.

## Canonical commands

Install and launch the accepted downloaded Personal Release `v0.1.0`, then obtain its PID without restarting it from the harness. From a checkout containing the P0 tooling:

```bash
PID="$(pgrep -x NotchHub | head -n 1)"
SOURCE_SHA="8e913dcddfdec7d9aa920df8c37afb23b8c40884"

python3 scripts/perf-baseline.py \
  --attach-pid "$PID" \
  --source-commit "$SOURCE_SHA" \
  --scenario idle \
  --warmup-seconds 10 \
  --duration-seconds 60 \
  --interval-seconds 1 \
  --output build/perf-idle.json

python3 scripts/perf-baseline.py \
  --attach-pid "$PID" \
  --source-commit "$SOURCE_SHA" \
  --scenario hover \
  --warmup-seconds 10 \
  --duration-seconds 60 \
  --interval-seconds 1 \
  --output build/perf-hover.json

python3 scripts/perf-baseline.py \
  --attach-pid "$PID" \
  --source-commit "$SOURCE_SHA" \
  --scenario stability \
  --warmup-seconds 10 \
  --duration-seconds 600 \
  --interval-seconds 5 \
  --output build/perf-stability.json
```

If more than one process matches, identify the PID of the accepted installed Personal Release explicitly rather than measuring an arbitrary process.

## Baseline and budgets

Canonical baseline file: `performance/baseline-v0.1.0.json`.

It is created only after the macOS 26.6 measurements above are reviewed for stability and noise. Numerical CPU/RSS/thread budgets must **not** be invented before those measurements exist.

For each accepted metric, the initial budget must document:

1. the measured baseline and observed maximum/range;
2. an absolute ceiling above the accepted measurements;
3. a regression allowance large enough to cover normal measurement noise;
4. whether the metric is a deterministic CI gate or target-Mac acceptance gate.

If the measurements are unstable, methodology is fixed before any threshold is added.

## Regression policy

After the first baseline is accepted:

- reproducible artifact-size limits may become CI gates;
- deterministic scanner/state/lifecycle invariants remain mandatory CI gates;
- CPU/RSS/thread comparisons remain target-Mac evidence unless a future measurement method proves sufficiently stable for automation;
- material regression requires investigation before acceptance, even when an absolute ceiling is not crossed.

A performance optimization is accepted only when existing notch/hover/security behavior remains correct and measured resource use is equal or better. In particular, M1 may replace the current global `.mouseMoved` observer with local AppKit tracking only after correctness and resource measurements support the change.
