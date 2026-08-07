# Performance Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a reproducible, security-preserving performance/resource baseline and executable performance policy before feature-heavy M1 work, then use measured data from the target MacBook/macOS 26.6 to define honest CPU/RAM/resource budgets.

**Architecture:** Keep performance validation split into deterministic CI invariants and real-hardware runtime measurement. Add a pure Python-stdlib policy/audit module with unit tests, a target-Mac sampling harness that records process metrics without shipping telemetry, and a versioned baseline JSON that is created only after real measurements are collected and reviewed.

**Tech Stack:** Swift 6, Swift Package Manager, AppKit/SwiftUI, Python 3 standard library, Bash, macOS `ps`, `du`, `stat`, GitHub Actions.

## Global Constraints

- Primary physical target is macOS `26.6` on the user’s MacBook.
- Performance/resource efficiency is a first-class product requirement alongside `SECURITY.md`.
- Runtime architecture is event-driven by default; polling, repeating timers, busy loops, display links, broad global input observation, and background sync require explicit reviewed justification.
- Performance optimization must never broaden permissions, disable Sandbox/Hardened Runtime, add privileged helpers, add telemetry, or weaken security gates.
- Shared GitHub runners must not enforce tight CPU/RAM thresholds because hardware/load noise would make the gate dishonest.
- Tight numerical budgets are derived only after reproducible target-Mac measurements exist.
- Development measurement scripts are not bundled into `NotchHub.app` and do not run in production.
- No third-party Python/Swift dependencies are introduced for performance measurement.

---

## File Structure

- Create `PERFORMANCE.md` — authoritative performance/resource contract, methodology, measured baseline, budgets, and regression policy.
- Create `scripts/performance_policy.py` — deterministic source-policy scanner and metric aggregation helpers.
- Create `scripts/test_performance_policy.py` — Python `unittest` coverage for scanner, parser, aggregation, and budget comparison.
- Create `scripts/perf-baseline.py` — target-Mac development harness that launches/attaches to NotchHub, samples CPU/RSS/thread count, and emits JSON; never bundled in app.
- Create `performance/baseline-v0.1.0.json` only after target-Mac measurements are collected and accepted.
- Modify `.github/workflows/ci.yml` — run performance policy tests/audit and record release-candidate size metadata; add budget check only after baseline exists.
- Modify `scripts/security-audit.sh` — ensure performance tooling stays development-only and cannot introduce runtime telemetry/process execution into `Sources/`.
- Modify `docs/TESTING.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `docs/PROJECT_STATE.md`, `README.md`, `CHANGELOG.md`.
- Later M1 optimization task modifies `Sources/NotchHubCore/Notch/NotchPanelController.swift` only after baseline is established.

---

### Task 1: Deterministic performance policy scanner

**Files:**
- Create: `scripts/performance_policy.py`
- Create: `scripts/test_performance_policy.py`

**Interfaces:**
- Produces: `find_runtime_policy_violations(root: pathlib.Path) -> list[str]`
- Produces: `parse_ps_sample(line: str) -> ProcessSample`
- Produces dataclass: `ProcessSample(cpu_percent: float, rss_kib: int, thread_count: int)`
- Produces: `summarize_samples(samples: list[ProcessSample]) -> dict[str, float | int]`
- Produces: `compare_summary_to_budget(summary: dict, budget: dict) -> list[str]`
- Produces CLI subcommands: `audit`, `summarize`, `check-budget`.

- [ ] **Step 1: Write RED tests for forbidden runtime primitives**

Use temporary directories/files and prove the scanner detects each of these source patterns when present in `Sources/**/*.swift`:

```text
while true
Timer.scheduledTimer
Timer.publish
DispatchSource.makeTimerSource
Task.sleep
Thread.sleep
usleep(
sleep(
CVDisplayLink
CADisplayLink
```

Also prove ordinary `for` loops, one-shot `DispatchQueue.main.async`, and comments/docs outside `Sources/` do not fail the audit.

- [ ] **Step 2: Run RED audit tests**

Run: `cd scripts && python3 -m unittest -v test_performance_policy.py`

Expected: FAIL because module does not exist.

- [ ] **Step 3: Implement source scanner**

Use Python stdlib `pathlib` + compiled regexes. Return `path:line: rule` violations sorted deterministically. Scanner is conservative but only scans runtime Swift files. Any future legitimate primitive must be changed through an explicit, versioned allowlist design rather than an inline magic comment in this task.

- [ ] **Step 4: Run GREEN audit tests**

Expected: PASS.

- [ ] **Step 5: Add CLI `audit` and test exit codes**

`python3 scripts/performance_policy.py audit Sources` exits `0` with `Performance policy checks passed.` when clean, `1` with violations on stderr otherwise.

- [ ] **Step 6: Commit Task 1**

Commit message: `test: define runtime performance policy`

---

### Task 2: Honest process-metric parser and aggregation

**Files:**
- Modify: `scripts/performance_policy.py`
- Modify: `scripts/test_performance_policy.py`

**Interfaces:**
- Consumes raw sample lines formatted as exactly three whitespace-separated fields: CPU percent, RSS KiB, thread count.
- Produces summary keys: `sampleCount`, `cpuMedianPercent`, `cpuMaxPercent`, `rssMedianKiB`, `rssMaxKiB`, `threadMedian`, `threadMax`.

- [ ] **Step 1: Write RED parser tests**

Examples:

```python
sample = parse_ps_sample(" 0.3  18432  7 ")
self.assertEqual(0.3, sample.cpu_percent)
self.assertEqual(18432, sample.rss_kib)
self.assertEqual(7, sample.thread_count)
```

Reject missing fields, `nan`, negative values, zero/negative thread count, and locale comma decimals.

- [ ] **Step 2: Implement strict parser**

Use `math.isfinite`, explicit bounds, no locale-sensitive parsing.

- [ ] **Step 3: Write RED aggregation tests**

For five fixed samples, assert exact median/max values using `statistics.median`. Empty input raises `ValueError`; do not synthesize zero metrics.

- [ ] **Step 4: Implement aggregation**

Preserve CPU as float; RSS/thread values may have fractional medians for even counts, so document JSON types and use floats for medians where needed.

- [ ] **Step 5: Run GREEN tests**

Run: `cd scripts && python3 -m unittest -v test_performance_policy.py`

Expected: PASS.

- [ ] **Step 6: Commit Task 2**

Commit message: `test: add process metric aggregation`

---

### Task 3: Target-Mac baseline harness

**Files:**
- Create: `scripts/perf-baseline.py`
- Modify: `scripts/test_performance_policy.py`

**Interfaces:**
- CLI: `python3 scripts/perf-baseline.py --app build/NotchHub.app --scenario idle --warmup-seconds 10 --duration-seconds 60 --interval-seconds 1 --output build/perf-idle.json`
- CLI: same with `--scenario hover` and `--attach-pid <pid>` for user-driven interaction.
- Produces JSON containing scenario, timestamps/durations, source commit, macOS version, hardware model identifier if available from `system_profiler SPHardwareDataType`, sample interval/count, metric summary, and no user-identifying file/content data.

- [ ] **Step 1: Write RED argument-validation tests**

Factor pure `validate_config(...)` in `performance_policy.py` or importable helper. Reject duration <= 0, interval <= 0, warmup < 0, interval > duration, unknown scenario, missing app/PID.

- [ ] **Step 2: Implement config validation**

No measurement yet.

- [ ] **Step 3: Write RED command-output parser fixture test**

Represent macOS `ps` output as fixture strings passed to `parse_ps_sample`. Do not shell out in unit tests.

- [ ] **Step 4: Implement harness process lifecycle**

For `--app`, launch executable directly from `NotchHub.app/Contents/MacOS/NotchHub` using development-only Python `subprocess.Popen`; this script is outside `Sources/` and must never be bundled. Ensure `try/finally` terminates only the process it launched. For `--attach-pid`, never terminate the attached process.

- [ ] **Step 5: Implement sampling**

Use `/bin/ps -p <pid> -o %cpu= -o rss= -o thcount=` once per interval. If the target macOS rejects `thcount`, fail with a precise message and do not silently drop thread metrics. Use `time.monotonic()` for schedule calculations; avoid tight loops.

- [ ] **Step 6: Emit deterministic JSON schema**

Include `schemaVersion: 1`, `scenario`, `sourceCommit`, platform info, requested timings, actual sample count, and `summary`. Exclude usernames, paths outside the app argument, window titles, pointer coordinates, clipboard, files, or telemetry identifiers.

- [ ] **Step 7: Smoke-test harness on GitHub macOS runner without making numbers a gate**

CI may run a short 5-second harness only to prove command compatibility/schema generation. Do not compare CPU/RAM to a threshold on shared runners.

- [ ] **Step 8: Commit Task 3**

Commit message: `feat: add local performance baseline harness`

---

### Task 4: PERFORMANCE.md and stable acceptance IDs

**Files:**
- Create: `PERFORMANCE.md`
- Modify: `docs/TESTING.md`
- Modify: `docs/ARCHITECTURE.md`

**Interfaces:**
- Produces stable scenario contracts before measurement numbers are recorded.

- [ ] **Step 1: Create `PERFORMANCE.md` without numerical budgets yet**

Document:

- event-driven invariant;
- no unreviewed polling/timers/busy loops;
- lifecycle/cancellation requirements;
- bounded caches/collections;
- no runtime telemetry;
- separation between deterministic CI and physical metrics;
- exact baseline commands;
- rule that budgets cannot be invented before baseline;
- regression policy after budgets exist.

- [ ] **Step 2: Add stable scenarios to `docs/TESTING.md`**

Define:

- `NH-PERF-IDLE-001`: warmup 10 s, untouched compact mode 60 s, 1 s sampling.
- `NH-PERF-HOVER-001`: warmup 10 s, 60 s measurement while user repeats 5-second cycle: enter/expand, move inside, leave/collapse, remainder idle; sampler is automatic, interaction is manual.
- `NH-PERF-STABILITY-001`: idle 10 minutes sampled every 5 s to detect sustained RSS/thread growth.
- `NH-PERF-SIZE-001`: executable/app/DMG byte sizes recorded from accepted release candidate.
- `NH-PERF-STATE-001`: deterministic 100,000 pure presentation-policy transitions in test code with no retained history/state growth; correctness/collection invariants, not wall-clock timing.

- [ ] **Step 3: Update architecture resource-efficiency section**

State that OS notifications/tracking areas are preferred over periodic work and that module adapters must expose cancellation/lifecycle explicitly.

- [ ] **Step 4: Commit Task 4**

Commit message: `docs: define performance and resource contract`

---

### Task 5: CI performance policy and deterministic stress coverage

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `Tests/NotchHubCoreTests/NotchPointerPolicyTests.swift` or create `Tests/NotchHubCoreTests/NotchPerformanceInvariantTests.swift`
- Modify: `scripts/security-audit.sh`

**Interfaces:**
- Consumes: `performance_policy.py audit`.
- Produces deterministic CI gate, not noisy timing threshold.

- [ ] **Step 1: Write RED Swift stress test**

Create `NotchPerformanceInvariantTests` that performs exactly 100,000 deterministic compact/expanded pointer decisions using fixed points/layout and asserts expected final state/counts. Do not assert elapsed time. The purpose is to prove the policy has no hidden collection/state accumulation API and remains safe under high transition count.

- [ ] **Step 2: Run RED only if a small testability seam is missing**

If current pure policy already supports this test, the test may pass immediately; in that case do not fake a RED. Instead record it as characterization coverage and reserve RED/GREEN for actual policy violations. TDD honesty takes precedence over ritual.

- [ ] **Step 3: Add performance audit to CI**

Run:

```bash
(cd scripts && python3 -m unittest -v test_performance_policy.py)
python3 scripts/performance_policy.py audit Sources
```

before build/package steps.

- [ ] **Step 4: Add short harness compatibility smoke**

Build app, run `perf-baseline.py` for 5 seconds with 1-second interval on runner, validate JSON schema only. Do not fail based on CPU/RSS magnitude.

- [ ] **Step 5: Extend security audit boundary**

Assert `perf-baseline.py` and performance tooling are not referenced/copied from `Sources`, `Resources`, `build-app.sh`, or app bundle packaging paths.

- [ ] **Step 6: Run full CI equivalent**

Expected: all security/correctness/package/performance-policy checks PASS.

- [ ] **Step 7: Commit Task 5**

Commit message: `ci: enforce performance policy invariants`

---

### Task 6: Collect canonical M0.1 baseline on target MacBook

**Files:**
- Create after measurement: `performance/baseline-v0.1.0.json`
- Modify: `PERFORMANCE.md`
- Modify: `docs/PROJECT_STATE.md`

**Interfaces:**
- Consumes accepted Personal Release or exact release-candidate DMG/source commit.
- Produces canonical target-Mac baseline and evidence-based budgets.

- [ ] **Step 1: Build/install exact candidate and record source SHA**

Use the same artifact intended for/produced by Personal Release. Do not baseline a debug build.

- [ ] **Step 2: Run `NH-PERF-IDLE-001`**

Command shape:

```bash
python3 scripts/perf-baseline.py --attach-pid <PID> --scenario idle --warmup-seconds 10 --duration-seconds 60 --interval-seconds 1 --output build/perf-idle.json
```

Do not interact with the app during the measurement window.

- [ ] **Step 3: Run `NH-PERF-HOVER-001`**

Run 60-second sampler while following the fixed interaction cycle documented in `TESTING.md`.

- [ ] **Step 4: Run `NH-PERF-STABILITY-001`**

Run 10 minutes at 5-second interval while idle. Record RSS/thread first quartile/median/max plus start/end values in baseline summary so monotonic growth is visible.

- [ ] **Step 5: Record `NH-PERF-SIZE-001`**

Use exact byte sizes for executable, `.app` directory aggregate, and DMG. Store values in baseline JSON.

- [ ] **Step 6: Review raw measurements for noise/outliers before setting budgets**

Do not commit raw process logs containing local paths. Commit only summarized, non-sensitive metrics and measurement configuration.

- [ ] **Step 7: Derive initial budgets**

For each metric, set:

- an absolute ceiling comfortably above measured maximum;
- a regression allowance relative to baseline large enough to tolerate measurement noise;
- separate idle and active budgets where meaningful.

Document the exact derivation in `PERFORMANCE.md`. If measurements are unstable, do not create a gate; fix methodology first.

- [ ] **Step 8: Create `performance/baseline-v0.1.0.json`**

Schema must identify source commit, macOS 26.6, scenario configs, summaries, size values, and budgets. No serial number, username, home path, or other machine identifier beyond generic model family if intentionally useful.

- [ ] **Step 9: Commit Task 6**

Commit message: `perf: establish macOS 26.6 resource baseline`

---

### Task 7: Evidence-based budget checker

**Files:**
- Modify: `scripts/performance_policy.py`
- Modify: `scripts/test_performance_policy.py`
- Modify: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes baseline JSON and deterministic artifact sizes in CI.
- Produces fail-closed size/resource-policy comparison where reproducible.

- [ ] **Step 1: Write RED budget-comparison tests**

Test exact cases: under budget = no violations; one metric over absolute ceiling = named violation; one metric over regression allowance = named violation; missing required metric/schema mismatch = failure.

- [ ] **Step 2: Implement `compare_summary_to_budget` and `check-budget` CLI**

No fuzzy silent defaults. Baseline schema version must match exactly.

- [ ] **Step 3: Add deterministic artifact-size gate to CI**

Compare executable/app/DMG sizes against baseline size budgets because byte sizes are reproducible enough for CI. Do not add CPU/RAM hardware thresholds to shared runner CI.

- [ ] **Step 4: Add target-Mac acceptance instructions for CPU/RAM budgets**

`PERFORMANCE.md` explains how future release candidates run the same harness and `check-budget` locally against baseline.

- [ ] **Step 5: Run GREEN tests/full CI**

Expected: PASS on accepted baseline.

- [ ] **Step 6: Commit Task 7**

Commit message: `perf: enforce evidence-based resource budgets`

---

### Task 8: Source-of-truth milestone update and PR B acceptance

**Files:**
- Modify: `docs/ROADMAP.md`
- Modify: `docs/PROJECT_STATE.md`
- Modify: `README.md`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Produces new-chat-restorable state: Personal Release exists, Performance Foundation accepted, M1 pointer/global-monitor optimization next.

- [ ] **Step 1: Update roadmap**

Mark Performance Foundation accepted only after baseline/budgets exist. Move M1 to active next milestone.

- [ ] **Step 2: Update project state**

Record exact baseline version/source commit, accepted scenario results, budgets, known measurement limitations, and next optimal step.

- [ ] **Step 3: Update README/CHANGELOG**

Expose `PERFORMANCE.md`, baseline harness, and no-telemetry distinction; add notable infrastructure changes.

- [ ] **Step 4: Open PR B and require complete CI**

PR body must distinguish deterministic CI gates from target-Mac measurements and include baseline summary without overstating precision.

- [ ] **Step 5: Squash-merge only after all checks and hardware baseline acceptance pass**

No additional M1 feature code in this PR.

---

### Task 9: Begin M1 with global pointer monitor optimization

**Files:**
- Modify later: `Sources/NotchHubCore/Notch/NotchPanelController.swift`
- Create/modify tests as dictated by chosen AppKit tracking design.

**Interfaces:**
- Consumes accepted M0/M0.1 hover behavior and Performance Foundation baseline.
- Produces reduced idle wakeup/input-observation surface without correctness regression.

- [ ] **Step 1: Capture current monitor behavior as regression tests/adapter contract before changing production code**

Do not remove global monitor until an alternative design can be proved against `NH-HOVER-001/002/003` semantics.

- [ ] **Step 2: Prototype `NSTrackingArea`/window-local tracking behind a small adapter**

No `CGEventTap`, Accessibility, Input Monitoring, keyboard capture, or broader permissions.

- [ ] **Step 3: Re-run deterministic tests, security audit, target hardware hover matrix, and performance baseline comparison**

Accept replacement only if behavior remains PASS and measured resource/input-observation profile is equal or better.

- [ ] **Step 4: If local tracking is less reliable, retain narrow global `.mouseMoved` monitor and document measured trade-off**

Optimization is not allowed to make UI correctness worse merely to remove an API.
