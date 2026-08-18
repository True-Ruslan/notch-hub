# Project state

Last updated: 2026-08-18
Published version: `0.1.0` Personal Release
Primary physical target: macOS 26.6 / Mac16,8
Protected branch: `main`
Frozen P1 measured runtime: `bb6df211699c5aef7bac7d50866f3e24b2fe165b`
Frozen P1 measurement tooling: `5cd9a2a47d87a433155f53b3aa0510000f2fce85`
Active development: P1 target-Mac whole-app resource evidence collection

## Product state

NotchHub is a native, local-first macOS productivity hub built around the physical MacBook notch. Security, privacy, performance, energy use and deterministic interaction behavior remain first-class constraints. Runtime work remains event-driven unless measured evidence justifies otherwise.

Published state remains immutable `v0.1.0`. M6.6 is accepted and merged source work but remains unreleased. P1 is the active gate before broad multi-monitor hardening or another product module.

## Merged foundations

- M0 Engineering Foundation — accepted/merged.
- R0.1 Personal Release `v0.1.0` — accepted/released.
- P0 Performance Foundation — accepted/merged; immutable baseline preserved.
- P0.1 Public repository readiness — accepted.
- M1 primary interaction/transition foundation — accepted/merged; active-display/fullscreen/Spaces/notchless/multi-monitor hardening remains deferred.
- M6.1 transport feasibility — accepted.
- M6.2 normalized media boundary — accepted/merged.
- M6.3 production system transport — accepted/merged.
- M6.4 shipping media composition/lazy lifecycle — accepted/merged.
- M6.5 Media-first UI — accepted/merged.
- Regression/UI Automation Foundation — merged via PR #34 as `bd9566f690d314ed40fd6f3723a319291ceb4a58`.
- M6.6 gestures/haptics/interactive notch/seek/Hover Peek — accepted/merged via PR #33 as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`.
- P1 target resource measurement foundation — implemented/tested/merged via PR #36 as `5cd9a2a47d87a433155f53b3aa0510000f2fce85`.

## M6.6 acceptance and merge provenance

Physical acceptance remains pinned to exact runtime source:

`8744b9e6239fa28a6d1094f6f4e7669e4ada25b3`

Canonical source evidence:

- CI #1241 / run `32075976405` — 3/3 GREEN;
- 366 Swift tests / 80 suites GREEN;
- external exact-app native XCUI 11/11 GREEN;
- complete target Mac16,8/macOS 26.6 physical matrix PASS;
- Accessibility / Input Monitoring / Automation / Screen Recording NONE;
- post-Quit `pgrep -lf 'mediaremote-adapter\.pl' || true` empty.

Acceptance-record head `c9fbd0605b33a318bb4371ae0f2c928120356adf` passed CI #1243 3/3 GREEN without production changes. PR #33 was squash-merged with expected-head protection as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`; post-merge CI #1244 ultimately passed 3/3 GREEN on that exact source.

M6.6 state is therefore:

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
- normal Quit leaves no owned media adapter process.

## Security and resource invariants

- App Sandbox-only entitlement and Hardened Runtime remain mandatory.
- No Accessibility, Input Monitoring, Automation, Screen Recording, networking, telemetry, history persistence or arbitrary command authority is added.
- Universal Media retains the reviewed fixed `/usr/bin/perl` + pinned adapter/framework boundary.
- Settled compact and Peek own zero persistent adapter; settled expanded owns the expected presentation-scoped runtime.
- Gesture/Peek/transition hot paths add no polling, repeating timer, display link, event tap, per-event subprocess creation or production logging.
- The existing narrow global `.mouseMoved` fallback predates P1 and is a measurement/optimization candidate, not permission to broaden input capture.
- UI fixtures and diagnostics remain compile-time test-only.

## Performance state — P1 active

`performance/baseline-v0.1.0.json` and all historical feature budgets remain immutable provenance records. The active cumulative size envelope remains `performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json`; M6.6 acceptance and merge passed it without widening.

Shared-runner CPU/RSS values remain compatibility evidence only. Canonical runtime resource acceptance belongs to Mac16,8/macOS 26.6.

P1 measurement foundation merged via PR #36. Final PR head `8f2e1c51ba8d69a66165a8e0db5f64f029cc3fcd` passed CI #1260 3/3 GREEN. Squash-merged tooling source `5cd9a2a47d87a433155f53b3aa0510000f2fce85` passed post-merge CI #1261 3/3 GREEN.

The foundation:

- keeps existing `perf-baseline.py` as the non-privileged CPU/RSS/thread collector;
- validates one exact runtime source, one exact tooling SHA, target platform and fixed scenario configuration;
- records idle wakeups, energy and compositor findings through explicit Apple observation tools;
- rejects arbitrary free-form fields/raw traces and malformed manual evidence types;
- excludes privileged `sudo powermetrics` / `timerfires` from the canonical path;
- runs the evidence contract inside canonical `swift test`;
- changes no shipping runtime source.

TDD RED evidence is preserved by CI #1245 for the absent implementation and CI #1258 for malformed manual JSON type handling.

The initial P1 target audit intentionally measures runtime `bb6df211699c5aef7bac7d50866f3e24b2fe165b` with tooling `5cd9a2a47d87a433155f53b3aa0510000f2fce85`. Later documentation-only commits do not redefine those provenance roles.

## Next optimal step

1. Collect target-Mac idle/hover/stability CPU/RSS/thread reports using the frozen runtime/tooling pair.
2. Collect 60-second idle wakeup/energy evidence and 10-cycle compositor evidence.
3. Build and validate the normalized P1 target-resource evidence bundle.
4. Characterize variance before introducing any new absolute cross-session resource threshold.
5. If evidence identifies a material regression, implement one isolated optimization with RED -> GREEN and rerun affected physical acceptance; otherwise accept P1 without speculative runtime changes.
6. Only after P1 acceptance proceed to broader active-display/multi-monitor hardening or another product module.

See:

- `docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md`;
- `docs/superpowers/plans/2026-08-18-p1-target-mac-resource-audit.md`.
