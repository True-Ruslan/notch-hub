# Roadmap

Primary target: Mac16,8 / macOS 26.6.x. Current physical environment: macOS 26.6.1. Published Personal Release: `v0.1.0`.

States are explicit: **implemented -> automated-tested -> physically accepted -> merged -> released**. Green CI does not substitute for target-Mac acceptance when physical UI, permissions, third-party behavior or resources are part of the contract.

## Completed foundations

- **M0 Engineering Foundation — ACCEPTED / MERGED**.
- **R0.1 Personal Release — ACCEPTED / RELEASED**: immutable `v0.1.0`.
- **P0 Performance Foundation — ACCEPTED / MERGED**.
- **P0.1 Public repository readiness — ACCEPTED**.
- **M1 primary interaction foundation — ACCEPTED / MERGED**; active-display/fullscreen/Spaces/notchless/broader multi-monitor hardening remains deferred.
- **Regression/UI Automation Foundation — IMPLEMENTED / TESTED / MERGED** via PR #34 as `bd9566f690d314ed40fd6f3723a319291ceb4a58`; post-merge main CI #1053 passed all three canonical jobs.

## M6 — Universal Media / System Now Playing

- **M6.1 transport feasibility — ACCEPTED**.
- **M6.2 production media boundary — ACCEPTED / MERGED**.
- **M6.3 concrete system transport — ACCEPTED / MERGED**.
- **M6.4 shipping composition — ACCEPTED / MERGED**.
- **M6.5 Media-first UI — ACCEPTED / MERGED**.

### M6.6 — gestures, haptics, interactive notch, seek and Hover Peek

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / NOT RELEASED**.

Original full physical source acceptance remains permanently pinned to exact runtime:

`8744b9e6239fa28a6d1094f6f4e7669e4ada25b3`

PR #33 was squash-merged with expected-head protection as:

`bb6df211699c5aef7bac7d50866f3e24b2fe165b`

Post-merge `main` CI #1244 passed all three canonical jobs on that exact merge source. M6.6 remains unreleased; published release is still immutable `v0.1.0`.

Accepted behavior includes stable compact/Peek/expanded ownership, exact hover dwell/grace, media and no-media Peek, prompt explicit click, physical DOWN/UP/pointer-exit transitions, LEFT -> Next / RIGHT -> Previous follow-finger gestures, seek/source identity/cursor isolation, bounded transport teardown, unchanged Sandbox/Hardened Runtime and no new sensitive permissions.

#### Corrective hardware-notch screen selection

A later real multi-monitor check exposed a launch correctness regression: `NSScreen.main` could resolve to an external display while the built-in hardware-notch display remained available.

PR #40 repaired this using public AppKit notch geometry and preserved no-notch fallback behavior:

- exact runtime `46f069e57997eab060c79c3d9e279da944d6e263` physically passed on Mac16,8/macOS 26.6 with external monitor attached;
- no shipping `Sources/` change occurred after that physical re-check;
- final PR head `b19801be1201a43572f5ea6574d32edfc9174dc5` passed CI #1274 3/3 GREEN;
- squash merge `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251` has the same Git tree `f1884e9727d3d5794fb0122e86d9d0b85c3d9d21` as the final PR head.

The physical claim stays pinned to `46f069e...`; the corrected merged runtime is `e8d77968...`.

## P1 — whole-app performance/resource review

Status: **ACTIVE — MEASUREMENT FOUNDATION MERGED / CORRECTED RUNTIME RE-FROZEN / PATCH-FAMILY VALIDATOR MERGED / LOCALE-STABLE TOOLING RE-FROZEN / TARGET-MAC EVIDENCE PENDING**.

PR #36 established the P1 measurement foundation as historical tooling source:

`5cd9a2a47d87a433155f53b3aa0510000f2fce85`

Pre-merge CI #1260 and post-merge `main` CI #1261 both passed all three canonical jobs. The foundation changed development tooling/tests/docs only and no `Sources/` file.

The canonical P1 audit measures exact corrected merged runtime:

`e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`

with current exact measurement tooling from PR #47:

`28965561f81c71ea58a352301fbe08554c644044`

PR #44 was required before physical collection because the target Mac had advanced to macOS `26.6.1`, exposing an overly literal exact-`26.6` validator. The fix preserves exact patch provenance while accepting only canonical `26.6` / `26.6.x` versions and exact `Mac16,8`; all scenario/manual files must agree on the same exact patch version. Final PR #44 head `b1ff7dab8a1f386c04d9d5e2792ba27ca9f89b6a` passed CI #1283 3/3 GREEN before squash merge as `99a75dbe0664120a572bd8229d4fe461790ee07b`.

The first target attempt on `99a75dbe...` produced valid diagnostic Idle evidence, including `threadMax=7` against the direct Idle gate `<=6`, but Hover then failed before producing an evidence file because `/bin/ps` inherited a locale that emitted a comma decimal separator. PR #47 fixed the sampler boundary by forcing `LC_ALL=C` only for both `/bin/ps` sampling subprocesses while preserving the parent environment, leaving the measured application environment and strict parser unchanged. RED head `63af71dc9a614837fa2fe67f31d0cd0b5e3c0aa9` failed CI #1287 exactly on the new locale regression; GREEN head `5e1d870f67972d5799c34e77acc1a8c1f4de9f7b` passed CI #1288 3/3 GREEN, including Performance harness compatibility smoke. PR #47 squash-merged as current tooling `28965561f81c71ea58a352301fbe08554c644044`.

The runtime/tooling SHAs have distinct roles and must remain separate. The previous P1 runtime `bb6df211...` remains historical M6.6 merge evidence but is superseded for measurement because of the later screen-selection correction. Tooling `5cd9a2a...` and `99a75dbe...` likewise remain historical provenance but are superseded for new P1 evidence by `28965561...`. Later docs-only state commits do not redefine either current provenance claim.

Phase order:

1. **DONE** — establish fail-closed provenance/privacy validation for target CPU/RSS/thread reports plus wakeup/energy/compositor observations;
2. **DONE** — correct the discovered hardware-notch display binding regression and re-freeze the merged runtime provenance;
3. **DONE** — make the platform validator patch-aware without losing exact macOS provenance;
4. **DONE** — make `/bin/ps` sampling locale-stable without weakening the strict parser or changing the measured app environment, and re-freeze tooling to PR #47 merge;
5. **NEXT** — recollect the complete Idle/Hover/Stability set on exact Mac16,8/macOS 26.6.1 using runtime `e8d77968...` and tooling `28965561...`;
6. collect wakeup/energy/compositor evidence and build the normalized bundle using the same exact platform/tooling provenance;
7. characterize repeated-run variance and same-session comparability before adding new absolute budgets;
8. investigate only evidence-backed resource/compositor regressions;
9. optimize runtime only if measurements justify it, preserving accepted M6.6 behavior and the current permission/security boundary.

The earlier Idle result from `99a75dbe...` remains diagnostic history and must not be mixed into the final bundle. Recollection on `28965561...` is required by provenance, not to seek a more favorable value; if `threadMax > 6` repeats, it remains a blocker.

The canonical P1 path remains non-privileged: no automatic `sudo powermetrics`, `timerfires`, privileged helper, telemetry or new entitlement. See `docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md` and `docs/superpowers/plans/2026-08-18-p1-target-mac-resource-audit.md`.

Broader active-display/multi-monitor hardening remains after the P1 resource gate.

## Product modules after media/performance foundation

- **M2 Shelf**.
- **M3 Snippets**.
- **M4 Calendar**.
- **M5 Translator**.
- **M7 Product shell**.
- **M8 Trusted distribution — optional**.

## Current priority

1. Replace the old P1 tooling checkout with exact `28965561...`; keep runtime `e8d77968...` unchanged.
2. Recollect complete target-Mac Idle/Hover/Stability CPU/RSS/thread evidence on exact current platform Mac16,8/macOS 26.6.1 with one tooling SHA.
3. Preserve the old `99a75dbe...` Idle result as diagnostic history; do not mix it into the final bundle or rerun merely for a favorable result.
4. Collect 60-second idle wakeup + energy evidence and 10-cycle compositor evidence.
5. Validate the normalized P1 evidence bundle and characterize variance before introducing any new absolute cross-session resource threshold.
6. If evidence identifies a material regression, implement one isolated RED -> GREEN optimization and rerun affected physical acceptance; otherwise accept P1 without speculative runtime changes.
7. Only after P1 acceptance proceed to broader multi-monitor/active-display hardening or the next product module.
