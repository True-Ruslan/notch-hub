# Project state

Last updated: 2026-08-20
Published version: `0.1.0` Personal Release
Primary physical target: Mac16,8 / macOS 26.6.x
Current physical environment: Mac16,8 / macOS 26.6.1
Branch governance: `main` is intended to be protected; GitHub currently reports it unprotected and issue #42 tracks restoration
Frozen P1 measured runtime: `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`
Frozen P1 measurement tooling: `28965561f81c71ea58a352301fbe08554c644044`
Active development: P1 target-Mac whole-app resource evidence recollection after locale-stable tooling refreeze

## Product state

NotchHub is a native, local-first macOS productivity hub built around the physical MacBook notch. Security, privacy, performance, energy use and deterministic interaction behavior remain first-class constraints. Runtime work remains event-driven unless measured evidence justifies otherwise.

Published state remains immutable `v0.1.0`. M6.6 and its hardware-notch screen-selection correction are accepted/merged source work but remain unreleased. P1 is the active gate before broader multi-monitor hardening or another product module.

## Merged foundations

- M0 Engineering Foundation — accepted/merged.
- R0.1 Personal Release `v0.1.0` — accepted/released.
- P0 Performance Foundation — accepted/merged; immutable baseline preserved.
- P0.1 Public repository readiness — accepted.
- M1 primary interaction/transition foundation — accepted/merged; active-display/fullscreen/Spaces/notchless/broader multi-monitor hardening remains deferred.
- M6.1 transport feasibility — accepted.
- M6.2 normalized media boundary — accepted/merged.
- M6.3 production system transport — accepted/merged.
- M6.4 shipping media composition/lazy lifecycle — accepted/merged.
- M6.5 Media-first UI — accepted/merged.
- Regression/UI Automation Foundation — merged via PR #34 as `bd9566f690d314ed40fd6f3723a319291ceb4a58`.
- M6.6 gestures/haptics/interactive notch/seek/Hover Peek — accepted/merged via PR #33 as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`.
- M6.6 hardware-notch screen-selection correction — physically accepted/tested/merged via PR #40 as `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`.
- P1 target resource measurement foundation — implemented/tested/merged via PR #36 as `5cd9a2a47d87a433155f53b3aa0510000f2fce85`.
- P1 macOS 26.6 patch-family evidence correction — TDD-tested/merged via PR #44 as `99a75dbe0664120a572bd8229d4fe461790ee07b`.
- P1 locale-stable process sampler — TDD-tested/merged via PR #47 as current tooling `28965561f81c71ea58a352301fbe08554c644044`.

## M6.6 original acceptance and merge provenance

Original full M6.6 physical acceptance remains pinned to exact runtime source:

`8744b9e6239fa28a6d1094f6f4e7669e4ada25b3`

Canonical source evidence:

- CI #1241 / run `32075976405` — 3/3 GREEN;
- 366 Swift tests / 80 suites GREEN;
- external exact-app native XCUI 11/11 GREEN;
- complete target Mac16,8/macOS 26.6 physical matrix PASS;
- Accessibility / Input Monitoring / Automation / Screen Recording NONE;
- post-Quit `pgrep -lf 'mediaremote-adapter\.pl' || true` empty.

Acceptance-record head `c9fbd0605b33a318bb4371ae0f2c928120356adf` passed CI #1243 3/3 GREEN without production changes. PR #33 was squash-merged with expected-head protection as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`; post-merge CI #1244 ultimately passed 3/3 GREEN on that exact source.

## M6.6 hardware-notch screen-selection correction

A later real multi-monitor check found that `NSScreen.main` could be an external display even while the built-in hardware-notch display was available. PR #40 repaired initial panel screen selection using public AppKit notch geometry while preserving the no-notch fallback.

Lifecycle/provenance is explicit:

- runtime implementation physically re-checked on exact source `46f069e57997eab060c79c3d9e279da944d6e263` with Mac16,8/macOS 26.6 and external monitor attached — hardware-notch binding PASS;
- commits after `46f069e...` through the final PR head changed only size-policy/CI/test metadata and no shipping `Sources/` file;
- final PR head `b19801be1201a43572f5ea6574d32edfc9174dc5` passed CI #1274 3/3 GREEN, including release size budget, Sandbox/Hardened Runtime, macOS 26 and UI regression gates;
- PR #40 squash-merged as `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`;
- final PR head and squash merge share Git tree `f1884e9727d3d5794fb0122e86d9d0b85c3d9d21`.

The exact physical claim remains `46f069e...`; the corrected merged runtime is `e8d77968...`.

M6.6 current state is therefore:

**implemented -> automated-tested -> physically accepted -> merged -> not released**.

## Accepted M6.6 interaction contract

- stable `compact <-> peek <-> expanded` under one transition authority;
- hover dwell exactly 120 ms; Peek exit grace exactly 140 ms;
- generic Peek works without usable media; optional media enrichment begins only after authoritative Peek settlement;
- settled compact and Peek own zero persistent media observer; only settled expanded owns the presentation-scoped shipping runtime;
- explicit click remains one stable SwiftUI tap path;
- physical DOWN expands; physical UP collapses; exact top-screen/panel `maxY` remains inside the interaction region;
- expanded pointer exit returns non-haptically to exact compact;
- physical LEFT -> `next`, RIGHT -> `previous`, independent of macOS scroll-direction preference;
- horizontal visuals follow the physical finger direction;
- seek, source identity and cursor isolation remain bounded/event-driven;
- bounded Peek cancellation is nonblocking for the UI actor and stale/late transport work fails closed;
- initial panel binding prefers the available hardware-notch display over `NSScreen.main`, with `NSScreen.main` then first-screen fallback when no hardware notch is present;
- normal Quit leaves no owned media adapter process.

## Security and resource invariants

- App Sandbox-only entitlement and Hardened Runtime remain mandatory.
- No Accessibility, Input Monitoring, Automation, Screen Recording, networking, telemetry, history persistence or arbitrary command authority is added.
- Universal Media retains the reviewed fixed `/usr/bin/perl` + pinned adapter/framework boundary.
- Settled compact and Peek own zero persistent adapter; settled expanded owns the expected presentation-scoped runtime.
- Gesture/Peek/transition/screen-selection hot paths add no polling, repeating timer, display link, event tap, per-event subprocess creation or production logging.
- The existing narrow global `.mouseMoved` fallback predates P1 and is a measurement/optimization candidate, not permission to broaden input capture.
- UI fixtures and diagnostics remain compile-time test-only.

## Performance state — P1 active

`performance/baseline-v0.1.0.json` and all historical feature budgets remain immutable provenance records. The active cumulative size envelope is `performance/m6-6-hardware-notch-screen-selection-size-budget.json`; the older first-click budget remains historical evidence.

Shared-runner CPU/RSS values remain compatibility evidence only. Canonical runtime resource acceptance belongs to exact `Mac16,8` hardware in the macOS `26.6` patch family, with the exact observed patch version preserved in every evidence file. The current machine is on `26.6.1`.

PR #36 established the P1 measurement foundation. Final PR head `8f2e1c51ba8d69a66165a8e0db5f64f029cc3fcd` passed CI #1260 3/3 GREEN. Squash-merged foundation source `5cd9a2a47d87a433155f53b3aa0510000f2fce85` passed post-merge CI #1261 3/3 GREEN.

Before target collection, macOS advanced to `26.6.1`, exposing an overly literal `26.6` platform check. PR #44 corrected the P1 validator without changing the sampler or shipping runtime:

- accepts only canonical `26.6` / `26.6.x` versions;
- preserves exact patch provenance instead of normalizing it away;
- requires exact platform agreement across Idle/Hover/Stability/manual evidence;
- keeps exact model `Mac16,8`;
- rejects adjacent/malformed versions and wrong models;
- extends the existing Swift-to-Python canonical test bridge to both P1 Python suites;
- preserves the single reviewed untrusted `pull_request` CI path after release policy correctly rejected a temporary alternate workflow.

TDD RED/GREEN evidence was captured during PR #44 development. Final head `b1ff7dab8a1f386c04d9d5e2792ba27ca9f89b6a` passed CI #1283 3/3 GREEN. PR #44 squash-merged as tooling source `99a75dbe0664120a572bd8229d4fe461790ee07b`.

The first target collection attempt on `99a75dbe...` produced a valid diagnostic Idle report on exact runtime `e8d77968...` and exact Mac16,8/macOS 26.6.1. Idle CPU median/max were `0.0/0.0%`, RSS median/max were `56,416/58,464 KiB`, and thread median/max were `3/7`; `threadMax=7` exceeded the existing direct Idle gate `<=6`. The report intentionally contains aggregate summaries rather than raw per-sample rows, so the transient location cannot be reconstructed after the run. That observation remains diagnostic history and is not discarded.

The subsequent Hover collection produced no evidence file because `/bin/ps` inherited the interactive locale and emitted a comma decimal separator while the strict parser correctly required locale-independent dot-decimal input. PR #47 fixed the measurement boundary rather than weakening the parser:

- both `/bin/ps` sampling subprocesses receive a copy of the parent environment with `LC_ALL=C`;
- unrelated environment variables are preserved;
- the launched NotchHub app environment is not changed;
- the strict parser remains fail-closed;
- a dedicated locale regression runs through the existing canonical Swift-to-Python P1 bridge;
- no shipping `Sources/`, permission, entitlement, telemetry, networking, polling or product behavior changed.

RED head `63af71dc9a614837fa2fe67f31d0cd0b5e3c0aa9` failed CI #1287 exactly because both `/bin/ps` calls had `env=None`. GREEN head `5e1d870f67972d5799c34e77acc1a8c1f4de9f7b` passed CI #1288 3/3 GREEN, including coverage, release/security policy, Performance harness compatibility smoke and UI regression. PR #47 squash-merged as current P1 tooling source `28965561f81c71ea58a352301fbe08554c644044`.

The canonical P1 target audit therefore measures corrected merged runtime `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251` with tooling `28965561f81c71ea58a352301fbe08554c644044`. Earlier tooling SHAs remain immutable provenance history but are superseded for new target evidence. Because `measurementToolCommit` is part of the evidence contract, the previous Idle report on `99a75dbe...` must not be mixed with reports from `28965561...`; the complete final Idle/Hover/Stability set must be recollected on one tooling SHA.

## Next optimal step

1. Replace the detached P1 tooling checkout with exact tooling `28965561...`; keep runtime `e8d77968...` unchanged.
2. Recollect target-Mac Idle/Hover/Stability CPU/RSS/thread reports on the current exact platform Mac16,8/macOS 26.6.1 using only tooling `28965561...`.
3. Preserve the earlier `99a75dbe...` Idle result as diagnostic evidence; do not use it in the final normalized bundle and do not rerun merely to seek a favorable thread maximum.
4. Collect 60-second idle wakeup/energy evidence and 10-cycle compositor evidence.
5. Build and validate the normalized P1 target-resource evidence bundle; all files must preserve exact `26.6.1` platform provenance and one exact tooling SHA.
6. Characterize variance before introducing any new absolute cross-session resource threshold.
7. If the new canonical Idle again exceeds the thread gate, or other evidence identifies a material regression, investigate one evidence-backed cause at a time with RED -> GREEN; otherwise accept P1 without speculative runtime changes.
8. Only after P1 acceptance proceed to broader active-display/multi-monitor hardening or another product module.

See:

- `docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md`;
- `docs/superpowers/plans/2026-08-18-p1-target-mac-resource-audit.md`;
- issue #38 for live collection status;
- issue #42 for repository branch-protection restoration.
