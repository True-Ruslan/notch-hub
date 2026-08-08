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
- reproducible application-payload size regressions and absolute package-size regressions against the canonical baseline.

Shared GitHub runners must **not** enforce tight CPU, RSS, thread, wakeup, or energy thresholds. Their load and hardware are too variable for honest release gates.

`scripts/performance_policy.py` and `scripts/test_performance_policy.py` provide the deterministic scanner, process-sample parser/aggregation, runtime budget comparison, and fail-closed release-size budget checker. `scripts/perf-baseline.py` is development/release tooling only and is never bundled into NotchHub.

## Target-Mac measurement harness

The harness samples only process-level metrics through `/bin/ps`:

- CPU percent;
- resident set size (RSS) in KiB;
- thread count.

Its JSON output also records scenario configuration, macOS version, a generic hardware model identifier, measured-app source commit, and measurement-tool commit.

It deliberately does **not** record usernames, home paths, file names/content, clipboard/snippet content, window titles, pointer coordinates/history, calendar/media data, serial numbers, or telemetry identifiers.

Raw local measurement outputs under `build/` are development artifacts and are not committed. Only reviewed aggregate baseline values enter `performance/`.

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

Executable and aggregate `.app` payload bytes are reproducible CI metrics. The compressed UDZO DMG byte count is still recorded on every run and is subject to an absolute ceiling, but repeated CI evidence has shown small container-level byte variance even when the executable and `.app` payload are identical. It therefore is not used as a tight relative regression metric.

### `NH-PERF-STATE-001`

Run exactly 100,000 deterministic pointer/presentation policy decisions in Swift test code. Assert behavior/state invariants only; do not use elapsed wall-clock time as a CI threshold.

## Accepted v0.1.0 baseline — 2026-08-07

Canonical baseline: `performance/baseline-v0.1.0.json`.

The runtime measurements were collected by attaching the P0 harness at tooling commit `dfd4f87f8e5be04b467172d720d22bfc054c06d0` to the already accepted Personal Release `v0.1.0` source commit `8e913dcddfdec7d9aa920df8c37afb23b8c40884` on macOS 26.6, model family `Mac16,8`.

Measurement quality checks passed:

- requested/actual windows: idle `60.0/60.017 s`, hover `60.0/60.018 s`, stability `600.0/600.013 s`;
- exact sample counts: idle `60`, hover `60`, stability `120`;
- exact configured intervals: idle/hover `1 s`, stability `5 s`;
- all three records identify the same accepted app source commit, tooling commit, OS version, and hardware model family.

### Runtime measurements

| Scenario | CPU median | CPU max | RSS median | RSS max | Threads median | Threads max |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Idle | `0.0%` | `0.7%` | `33,648 KiB` | `33,808 KiB` | `4` | `4` |
| Hover | `5.95%` | `22.3%` | `38,456 KiB` | `38,816 KiB` | `6` | `7` |
| Stability | `0.0%` | `6.8%` | `30,992 KiB` | `34,384 KiB` | `3` | `7` |

Stability-specific evidence:

- RSS start: `34,256 KiB`;
- RSS first quartile: `28,976 KiB`;
- RSS end: `30,544 KiB`;
- RSS end-minus-start: `-3,712 KiB` (`-3.625 MiB`);
- thread start / first quartile / end: `4 / 3 / 5`.

The 10-minute run therefore shows no sustained RSS accumulation. The working set decreases rather than grows, while thread count stays small with bounded transient variation. Idle median CPU is zero. Hover is intentionally the heavier path and is the key comparison baseline for the later P1 investigation of the current global `.mouseMoved` monitor versus reliable window-local tracking.

### Accepted release artifact sizes

`NH-PERF-SIZE-001` is sourced from the immutable GitHub Release `v0.1.0` `build-metadata.json`, not from a later CI rebuild. Provenance matches source commit `8e913dcddfdec7d9aa920df8c37afb23b8c40884`, Personal build `1`, release DMG SHA-256 `cf53be6081b1836551fcbbb91b85fed800de4c089451961f3c6a21f6b77768bc`, Xcode 26.6, and Swift 6.3.3.

| Artifact | Accepted baseline |
| --- | ---: |
| Executable | `220,560 B` |
| `.app` aggregate regular-file bytes | `223,555 B` |
| DMG | `73,955 B` |

The release was built on the publication runner recorded as macOS 26.5.2; this is release-build provenance and is distinct from the runtime acceptance target macOS 26.6.

## Initial target-Mac budgets

These are **target-Mac acceptance ceilings**, not shared-runner CI CPU/RSS/thread gates. They are deliberately simple and conservative because the first baseline contains strong within-run sampling but only one canonical run per scenario; future accepted measurements may tighten them after run-to-run noise is characterized.

| Scenario | Metric | Baseline evidence | Initial ceiling | Gate |
| --- | --- | ---: | ---: | --- |
| Idle | CPU median | `0.0%` | `0.5%` | target Mac |
| Idle | CPU max | `0.7%` | `2.0%` | target Mac |
| Idle | RSS max | `33,808 KiB` | `43,008 KiB` (`42 MiB`) | target Mac |
| Idle | Threads max | `4` | `6` | target Mac |
| Hover | CPU median | `5.95%` | `8.0%` | target Mac |
| Hover | CPU max | `22.3%` | `30.0%` | target Mac |
| Hover | RSS max | `38,816 KiB` | `49,152 KiB` (`48 MiB`) | target Mac |
| Hover | Threads max | `7` | `9` | target Mac |
| Stability | CPU median | `0.0%` | `0.5%` | target Mac |
| Stability | CPU max | `6.8%` | `10.0%` | target Mac |
| Stability | RSS max | `34,384 KiB` | `45,056 KiB` (`44 MiB`) | target Mac |
| Stability | RSS end-minus-start | `-3,712 KiB` | `+8,192 KiB` max growth | target Mac |
| Stability | Threads max | `7` | `9` | target Mac |
| Stability | Thread end-minus-start | `+1` | `+2` max growth | target Mac |

Budget derivation intentionally rounds upward from observed values instead of fitting tightly to a single run:

- RSS ceilings provide roughly 25–31% headroom above the observed maxima;
- hover CPU ceilings provide roughly 34% headroom above measured median/max values;
- idle/stability CPU ceilings include larger absolute headroom because isolated one-second CPU spikes are noisier than sustained medians;
- thread ceilings allow two additional transient threads above observed maxima;
- stability allows up to 8 MiB positive RSS drift over ten minutes even though the accepted baseline drift is negative, preventing a one-run baseline from becoming an unrealistically tight leak detector.

Crossing a target-Mac ceiling blocks acceptance until investigated. A material regression should still be investigated even below a ceiling, especially if M1/P1 changes pointer observation. Shared GitHub runners continue to validate only deterministic policy/schema/package behavior.

## Artifact-size budget

Artifact size remains a mandatory CI concern, but the gate distinguishes reproducible application payload bytes from compressed container bytes.

Two independent constraints are recorded in the canonical baseline:

1. **Relative regression allowance for reproducible payload metrics:** executable and aggregate `.app` bytes may not grow more than `15%` from the accepted `v0.1.0` baseline without an explicit baseline/budget review.
2. **Absolute safety ceiling for every artifact:** executable, `.app`, and DMG each retain the existing `120%`-derived hard ceilings rounded upward to 4 KiB boundaries.

| Artifact | Baseline | Relative gate | Absolute ceiling |
| --- | ---: | ---: | ---: |
| Executable | `220,560 B` | `253,644 B` (15%) | `266,240 B` |
| `.app` | `223,555 B` | `257,088 B` maximum whole-byte value (15%) | `270,336 B` |
| DMG | `73,955 B` | not used; compressed container bytes vary | `90,112 B` |

The executable and `.app` relative gates remain unchanged and intentionally tighter than their absolute ceilings. The DMG absolute ceiling is also unchanged.

The DMG policy correction is evidence-driven rather than a feature-budget increase. During M6.1 probe development, CI #374 produced executable/app sizes `250,320 B / 253,317 B` while the DMG was `85,220 B`, 172 bytes above the former relative threshold of `85,048 B`. Re-running the failed job on the exact same source without changing code passed the old gate. A later CI #381 again produced the identical executable/app sizes but DMG `85,219 B`. The application payload was therefore stable while the compressed UDZO container crossed the tight relative threshold independently of application growth.

The canonical baseline now declares `relativeRegressionMetrics` explicitly. The checker rejects a missing, empty, duplicate, non-string, or unknown relative-metric list. All three required artifacts must still exist as non-negative integer measurements and all three always pass their absolute ceilings.

CI records the actual candidate sizes in `build/perf-size.json` and executes:

```bash
python3 scripts/performance_policy.py check-size-budget \
  --summary build/perf-size.json \
  --baseline performance/baseline-v0.1.0.json
```

The checker rejects unsupported baseline schema versions, missing required size metrics, non-integer byte sizes, non-finite/negative regression settings, malformed relative-metric policy, and malformed ceilings. Tests independently cover relative-limit, absolute-limit, compressed-DMG, and malformed-policy behavior.

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

If more than one process matches, identify the PID of the accepted installed release explicitly rather than measuring an arbitrary process.

For a future release candidate, run the same stable scenario and compare its `summary` with the corresponding flat `budget` object in `performance/baseline-v0.1.0.json` using `scripts/performance_policy.py check-budget`. Stability drift is also reviewed from `stabilitySummary` because start/end growth is not a plain sample maximum.

## Baseline and budgets

Canonical baseline file: `performance/baseline-v0.1.0.json`.

It is complete and records:

1. accepted release/source/build provenance;
2. target Mac/runtime measurement provenance and configuration;
3. idle/hover/stability summaries and stability growth evidence;
4. exact immutable-release executable/app/DMG byte sizes;
5. target-Mac runtime acceptance ceilings;
6. reproducible executable/app relative-size gates plus absolute executable/app/DMG ceilings.

CPU/RSS/thread ceilings remain target-Mac acceptance gates. Reproducible application-payload size limits and absolute package-size ceilings are shared-CI gates.

If future repeated measurements show that a runtime or packaging threshold is unstable, methodology or the metric classification is corrected from evidence rather than repeatedly rerunning or weakening production behavior merely to obtain green status. Intentional feature growth that needs more executable/app relative budget or any absolute artifact ceiling requires an explicit reviewed baseline/budget update; CI must never silently widen it.

## Regression policy

After the first baseline is accepted:

- reproducible executable/app relative-size limits are CI gates;
- executable/app/DMG absolute size limits are CI gates;
- deterministic scanner/state/lifecycle invariants remain mandatory CI gates;
- CPU/RSS/thread comparisons remain target-Mac evidence unless a future measurement method proves sufficiently stable for automation;
- material regression requires investigation before acceptance, even when an absolute ceiling is not crossed.

A performance optimization is accepted only when existing notch/hover/security behavior remains correct and measured resource use is equal or better. In particular, P1 may replace the current global `.mouseMoved` observer with local AppKit tracking only after correctness and resource measurements support the change.
