# Performance Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a reproducible, security-preserving performance/resource baseline and executable performance policy before feature-heavy M1 work, then use measured data from the target MacBook/macOS 26.6 to define honest CPU/RAM/resource budgets.

**Architecture:** Keep performance validation split into deterministic CI invariants and real-hardware runtime measurement. Add a pure Python-stdlib policy/audit module with unit tests, a target-Mac sampling harness that records process metrics without shipping telemetry, and a versioned baseline JSON that is created only after real measurements are collected and reviewed.

**Tech Stack:** Swift 6, Swift Package Manager, AppKit/SwiftUI, Python 3 standard library, Bash, macOS `ps`, `du`, `stat`, GitHub Actions.

## Completion status — 2026-08-07

**P0 accepted.** The implementation followed this plan with truthful RED→GREEN evidence. Canonical evidence is stored in `PERFORMANCE.md`, `performance/baseline-v0.1.0.json`, `docs/TESTING.md`, and `docs/PROJECT_STATE.md`.

Key completion evidence:

- target-Mac `NH-PERF-IDLE-001`, `NH-PERF-HOVER-001`, and `NH-PERF-STABILITY-001` accepted on macOS 26.6 / `Mac16,8` against Personal Release `v0.1.0`;
- immutable `v0.1.0` release metadata supplied exact executable/app/DMG sizes and release provenance;
- `NH-PERF-STATE-001` covers exactly 100,000 deterministic presentation/pointer decisions;
- RED CI #91 proved the release-size comparison API did not exist before implementation;
- GREEN CI #94 passed 22 performance-policy tests and the integrated deterministic release-size gate;
- shared CI deliberately does not enforce CPU/RSS/thread values from hosted runner hardware.

The detailed task sequence below is retained as implementation history rather than rewritten into a post-hoc specification.

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
- Create `performance/baseline-v0.1.0.json` only after target measurements are collected and accepted.
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

- [x] **Step 1: Write RED tests for forbidden runtime primitives**
- [x] **Step 2: Run RED audit tests**
- [x] **Step 3: Implement source scanner**
- [x] **Step 4: Run GREEN audit tests**
- [x] **Step 5: Add CLI `audit` and test exit codes**
- [x] **Step 6: Commit Task 1**

---

### Task 2: Honest process-metric parser and aggregation

**Files:**
- Modify: `scripts/performance_policy.py`
- Modify: `scripts/test_performance_policy.py`

- [x] **Step 1: Write RED parser tests**
- [x] **Step 2: Implement strict parser**
- [x] **Step 3: Write RED aggregation tests**
- [x] **Step 4: Implement aggregation**
- [x] **Step 5: Run GREEN tests**
- [x] **Step 6: Commit Task 2**

---

### Task 3: Target-Mac baseline harness

**Files:**
- Create: `scripts/perf-baseline.py`
- Modify: `scripts/test_performance_policy.py`

- [x] **Step 1: Write RED argument-validation tests**
- [x] **Step 2: Implement config validation**
- [x] **Step 3: Write RED command-output parser fixture test**
- [x] **Step 4: Implement harness process lifecycle**
- [x] **Step 5: Implement sampling** — Darwin `thcount` incompatibility found in CI and corrected to `/bin/ps -M` thread-row counting without dropping the metric.
- [x] **Step 6: Emit deterministic JSON schema**
- [x] **Step 7: Smoke-test harness on GitHub macOS runner without making numbers a gate**
- [x] **Step 8: Commit Task 3**

---

### Task 4: PERFORMANCE.md and stable acceptance IDs

- [x] **Step 1: Create `PERFORMANCE.md` without numerical budgets yet**
- [x] **Step 2: Add stable scenarios to `docs/TESTING.md`**
- [x] **Step 3: Update architecture resource-efficiency section**
- [x] **Step 4: Commit Task 4**

---

### Task 5: CI performance policy and deterministic stress coverage

- [x] **Step 1: Write RED Swift stress test**
- [x] **Step 2: Run RED only if a small testability seam is missing** — current pure policy already supported characterization coverage, so no fake RED was manufactured.
- [x] **Step 3: Add performance audit to CI**
- [x] **Step 4: Add short harness compatibility smoke**
- [x] **Step 5: Extend security audit boundary**
- [x] **Step 6: Run full CI equivalent**
- [x] **Step 7: Commit Task 5**

---

### Task 6: Collect canonical M0.1 baseline on target MacBook

- [x] **Step 1: Build/install exact candidate and record source SHA** — measured already accepted downloaded Personal Release `v0.1.0` source `8e913dcddfdec7d9aa920df8c37afb23b8c40884`.
- [x] **Step 2: Run `NH-PERF-IDLE-001`**
- [x] **Step 3: Run `NH-PERF-HOVER-001`**
- [x] **Step 4: Run `NH-PERF-STABILITY-001`**
- [x] **Step 5: Record `NH-PERF-SIZE-001`** from immutable release `build-metadata.json`.
- [x] **Step 6: Review raw measurements for noise/outliers before setting budgets**
- [x] **Step 7: Derive initial budgets**
- [x] **Step 8: Create `performance/baseline-v0.1.0.json`**
- [x] **Step 9: Commit Task 6**

---

### Task 7: Evidence-based budget checker

- [x] **Step 1: Write RED budget-comparison tests** — RED CI #91 failed exactly because `compare_size_summary_to_baseline` was absent.
- [x] **Step 2: Implement budget comparison and CLI** — existing flat `check-budget` retained for target-Mac summaries; added schema-aware `check-size-budget` for deterministic artifacts.
- [x] **Step 3: Add deterministic artifact-size gate to CI**
- [x] **Step 4: Add target-Mac acceptance instructions for CPU/RAM budgets**
- [x] **Step 5: Run GREEN tests/full CI** — CI #94 PASS.
- [x] **Step 6: Commit Task 7**

---

### Task 8: Source-of-truth milestone update and PR acceptance

- [x] **Step 1: Update roadmap** — P0 accepted; M1 next.
- [x] **Step 2: Update project state**
- [x] **Step 3: Update README/CHANGELOG**
- [x] **Step 4: Complete PR #5 and require complete CI**
- [ ] **Step 5: Squash-merge only after all checks and final read-only review pass**

---

### Task 9: Begin M1 with global pointer monitor optimization

This is intentionally **not part of P0**. It starts only after PR #5 is merged.

- [ ] Capture current monitor behavior as regression tests/adapter contract before changing production code.
- [ ] Investigate reliable local AppKit tracking against the accepted P0 hover baseline.
- [ ] Implement delayed hover/haptic work under `docs/specs/M1_NOTCH_INTERACTION.md` only after the tracking decision is evidence-backed.
