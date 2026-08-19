# P1 Target-Mac Resource Acceptance

Status: PENDING — canonical P1 target-Mac measurements are not collected yet.

Primary target: `Mac16,8` / macOS `26.6.x`
Current physical environment: macOS `26.6.1`
Measured runtime source: `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`
Accepted measurement tooling: `28965561f81c71ea58a352301fbe08554c644044`

This runbook collects whole-app performance/resource evidence without changing the shipping application or granting additional permissions.

The stable Idle/Hover/Stability scenario identifiers and their historical definitions remain owned by `PERFORMANCE.md`; this runbook intentionally does not redeclare those acceptance IDs. Current-runtime P1 values are not accepted until the exact target evidence below is collected and reviewed.

The P1 platform policy treats `26.6` and canonical integer patch releases `26.6.x` as one supported target family while preserving the **exact observed version** in every report and in the normalized evidence bundle. Idle, Hover, Stability and manual evidence must all report the same exact patch version. Adjacent minor versions, malformed versions, extra version components, leading-zero components and non-`Mac16,8` hardware fail closed.

## Runtime refreeze provenance

The previous P1 runtime `bb6df211699c5aef7bac7d50866f3e24b2fe165b` is historical M6.6 merge evidence and is **superseded for canonical P1 measurement** because a real multi-monitor launch regression was later found: the panel could bind to `NSScreen.main` instead of the available hardware-notch display.

The correction has separate physical, CI and merge provenance and those claims must not be collapsed:

- exact runtime physically re-checked on `Mac16,8 / macOS 26.6` with an external monitor attached: `46f069e57997eab060c79c3d9e279da944d6e263` — hardware-notch display binding PASS;
- commits after `46f069e...` through the PR head changed only size-policy/CI/test metadata and no shipping `Sources/` file;
- final PR #40 head `b19801be1201a43572f5ea6574d32edfc9174dc5` passed CI #1274 3/3 GREEN;
- PR #40 squash-merged as `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`;
- final PR head and squash-merge share exact Git tree `f1884e9727d3d5794fb0122e86d9d0b85c3d9d21`.

Therefore P1 measures the **corrected merged runtime SHA** `e8d77968...`. The physical claim remains pinned to `46f069e...`; measuring the merged SHA does not rewrite that historical hardware evidence.

## Tooling refreeze provenance

PR #36 originally established the P1 evidence foundation as tooling source `5cd9a2a47d87a433155f53b3aa0510000f2fce85`.

PR #44 then corrected the platform validator for the real target after macOS advanced to `26.6.1`:

- accepts only canonical `26.6` / `26.6.x` versions while preserving the exact patch string;
- all scenario reports and manual evidence must agree on that exact platform;
- exact model remains `Mac16,8`;
- malformed/adjacent versions and platform mismatches fail closed;
- the existing Swift test bridge runs the P1 Python contract inside canonical `swift test`.

Final PR #44 head `b1ff7dab8a1f386c04d9d5e2792ba27ca9f89b6a` passed CI #1283 3/3 GREEN and squash-merged as tooling `99a75dbe0664120a572bd8229d4fe461790ee07b`.

The first target collection attempt on `99a75dbe...` produced one valid diagnostic Idle report, then exposed a separate measurement-tool defect during Hover: `/bin/ps` inherited an interactive locale and emitted a comma decimal separator, while the strict parser correctly rejected non-canonical numeric text. Hover produced **no evidence file**.

PR #47 repaired the sampler boundary without weakening the parser:

- copy the parent environment for the process-sampling subprocesses;
- force `LC_ALL=C` only for `/bin/ps` CPU/RSS and `/bin/ps -M` thread sampling;
- preserve unrelated environment variables;
- do not change the launched NotchHub process environment;
- keep `parse_ps_sample` strict/fail-closed;
- add locale regression coverage through the existing canonical Swift-to-Python P1 test bridge;
- change no shipping `Sources/`, app permission, entitlement, networking, telemetry, polling or product behavior.

RED head `63af71dc9a614837fa2fe67f31d0cd0b5e3c0aa9` failed CI #1287 exactly because both `/bin/ps` calls had `env=None`. GREEN head `5e1d870f67972d5799c34e77acc1a8c1f4de9f7b` passed CI #1288 3/3 GREEN, including coverage-instrumented tests, release/security policy, Performance harness compatibility smoke and UI regression. PR #47 squash-merged as current tooling `28965561f81c71ea58a352301fbe08554c644044`.

Therefore canonical P1 collection now uses **measurement tooling SHA `28965561...`**. Older tooling SHAs remain immutable history but are superseded for new P1 evidence.

The Idle report previously collected with `99a75dbe...` remains diagnostic history: CPU median/max `0.0/0.0%`, RSS median/max `56,416/58,464 KiB`, threads median/max `3/7`. The `threadMax=7` observation exceeded the existing direct Idle gate `<=6` and must not be erased or rerun away. However, because `measurementToolCommit` is part of the closed evidence contract, that old Idle report **must not be mixed** with new Hover/Stability reports. The complete final Idle/Hover/Stability bundle must be recollected using `28965561...` only; if the thread excess repeats, it remains a P1 blocker for investigation.

## Evidence boundary

Machine-readable process metrics are collected by `scripts/perf-baseline.py` through Darwin `/bin/ps` only:

- CPU percentage;
- RSS in KiB;
- thread count.

The sampler forces a deterministic `C` locale only for its `/bin/ps` child processes so numeric text is locale-independent. It does not alter the measured application environment.

Wakeups, energy and compositor observations remain explicit target-Mac evidence. The canonical path does **not** automatically invoke privileged collectors and does not store raw Instruments traces in the repository evidence bundle.

Do not commit the raw files under `build/`.

## 1. Prepare separate exact runtime and tooling checkouts

The P1 audit measures the corrected merged runtime while using the separately accepted P1 measurement tooling. These are **two different immutable Git commits** and must not be collapsed into one checkout.

```bash
RUNTIME_SHA="e8d77968abd9ba7a5aaed6c63d108a67b8d8a251"
TOOLING_SHA="28965561f81c71ea58a352301fbe08554c644044"
```

Do not replace either with a moving branch name. Later documentation-only commits do not redefine these provenance anchors.

Before measurement, record and validate the exact physical platform:

```bash
MODEL="$(sysctl -n hw.model)"
MACOS="$(sw_vers -productVersion)"

printf 'Model: %s\nmacOS: %s\n' "$MODEL" "$MACOS"

if [ "$MODEL" != "Mac16,8" ]; then
  echo "MODEL — FAIL"
else
  echo "MODEL — PASS"
fi

if printf '%s\n' "$MACOS" | grep -Eq '^26\.6(\.[0-9]+)?$'; then
  echo "MACOS FAMILY — PASS"
else
  echo "MACOS FAMILY — FAIL"
fi
```

The validator independently enforces canonical integer components, so values such as `26.06.1`, `26.6.01`, `26.6.1.1`, `26.5.x` and `26.7` are rejected even if a looser shell pattern would otherwise be attempted. Current physical collection is expected to record exact version `26.6.1`.

From a clean repository checkout, fetch the exact commits and create or verify two detached worktrees. Do not globally enable `set -e` or `set -euo pipefail` in an interactive Terminal session.

```bash
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

git fetch origin

git worktree add --detach ../notch-hub-p1-runtime "$RUNTIME_SHA"
git worktree add --detach ../notch-hub-p1-tooling "$TOOLING_SHA"

test "$(git -C ../notch-hub-p1-runtime rev-parse HEAD)" = "$RUNTIME_SHA"
test "$(git -C ../notch-hub-p1-tooling rev-parse HEAD)" = "$TOOLING_SHA"
```

If either worktree already exists, inspect its cleanliness and exact SHA before replacing it; do not delete a dirty worktree automatically.

Build the **measured application only from the runtime worktree**:

```bash
(
  cd ../notch-hub-p1-runtime
  ./scripts/build-app.sh
)

test "$(plutil -extract NHSourceCommit raw \
  ../notch-hub-p1-runtime/build/NotchHub.app/Contents/Info.plist)" = "$RUNTIME_SHA"
```

Quit any other NotchHub instance, then launch exactly that app and require exactly one process:

```bash
pkill -x NotchHub 2>/dev/null || true
open ../notch-hub-p1-runtime/build/NotchHub.app

PID="$(pgrep -x NotchHub)"
test -n "$PID"
test "$(pgrep -x NotchHub | wc -l | tr -d ' ')" = "1"
ps -p "$PID" -o pid=,comm=
```

If the exact-process checks fail, stop and resolve the ambiguity rather than guessing a PID.

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

Create `build/p1-manual-resource-evidence.json` locally using the **exact same macOS version recorded by the three sampler reports**. For the current target session that value is `26.6.1`:

```json
{
  "schemaVersion": 1,
  "sourceCommit": "e8d77968abd9ba7a5aaed6c63d108a67b8d8a251",
  "platform": {
    "macOSVersion": "26.6.1",
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

Replace only the measured wakeup value and findings with observed values. If macOS is updated before all evidence is collected, do not mix sessions: start a new complete bundle on one exact patch version. Do not add notes, usernames, paths, window titles, raw trace data, media metadata or other free-form fields; the validator rejects extra schema surface.

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
- platform is not exact `Mac16,8` plus canonical macOS `26.6` / `26.6.x`;
- exact macOS patch version differs across Idle/Hover/Stability/manual evidence;
- scenario timing/sample counts differ from the canonical contract;
- reports use a non-attached measurement mode;
- required stability data is missing;
- manual methods/findings are unsupported;
- non-finite metrics or unknown/manual free-form keys appear.

The normalized bundle intentionally omits timestamps and raw trace payloads. `reviewRequired: true` means a manual energy/compositor anomaly was explicitly observed; it is a blocker for investigation, not something to rerun away.

## Acceptance rule

This evidence bundle is **not itself an automatic P1 PASS**. It proves provenance, completeness, schema and privacy safety. P1 acceptance additionally requires reviewing target values against the evidence-based policy in `PERFORMANCE.md`, characterizing repeated-run variance where needed, and resolving any `reviewRequired` finding.
