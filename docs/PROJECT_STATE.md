# Project state

Last updated: 2026-08-18
Published version: `0.1.0` Personal Release
Primary physical target: macOS 26.6 / Mac16,8
Protected branch: `main`
Current main source: `bb6df211699c5aef7bac7d50866f3e24b2fe165b`
Active development: P1 target-Mac whole-app resource review, Draft PR #36

## Product state

NotchHub is a native, local-first macOS productivity hub built around the physical MacBook notch. Security, privacy, performance, energy use and deterministic interaction behavior remain first-class constraints. Runtime work remains event-driven unless measured evidence justifies otherwise.

Published state remains immutable `v0.1.0`. M6.6 is now accepted and merged source work but remains unreleased. P1 is the active gate before broad multi-monitor hardening or another product module.

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

Acceptance-record head `c9fbd0605b33a318bb4371ae0f2c928120356adf` changed documentation/coverage only and passed CI #1243 3/3 GREEN. It did not redefine the physical runtime candidate.

PR #33 was then marked Ready and squash-merged with expected-head protection. Merge/main SHA:

`bb6df211699c5aef7bac7d50866f3e24b2fe165b`

Post-merge main CI #1244 passed all three canonical jobs on that exact source. Its first `Build, test and package` attempt failed after successful build/tests/signing because runner `hdiutil verify` returned `Resource temporarily unavailable`; the failed job alone was rerun on the unchanged source and passed every packaging/security/performance step. This is retained as a runner/disk-image transient, not an application regression.

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

No global scroll/button/keyboard monitor, mouse-button event authority, event tap, polling loop, repeating timer, display link, UI-test retry/sleep masking, new process executable boundary, network authority, telemetry or sensitive permission was introduced by M6.6.

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

Draft PR #36 starts P1 with a development/release-only evidence foundation:

- existing `perf-baseline.py` remains the non-privileged CPU/RSS/thread collector;
- `p1_target_resource_evidence.py` validates one exact runtime source, one tool SHA, target platform and fixed scenario configuration;
- manual evidence records idle wakeups, energy and compositor findings through explicit Apple observation tools;
- arbitrary free-form fields/raw traces are rejected from the normalized evidence bundle;
- privileged `sudo powermetrics` / `timerfires` are not part of the canonical automated path;
- the new evidence contract runs inside canonical `swift test`.

TDD RED evidence for PR #36: CI #1245 on head `6b7e90ff17803ef2678ff518b84fe82c8a39e06f` ran 367 tests / 81 suites and failed with exactly one issue: `ModuleNotFoundError: p1_target_resource_evidence` from the new P1 policy test. Existing suites remained green. The implementation then added the missing development-only bundler; shipping runtime remains unchanged.

See:

- `docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md`;
- `docs/superpowers/plans/2026-08-18-p1-target-mac-resource-audit.md`.

## Next optimal step

1. Finish PR #36 automated evidence foundation and require all three canonical CI jobs GREEN.
2. Freeze the accepted P1 measurement-tool commit while measured runtime stays exact merged M6.6 `bb6df211699c5aef7bac7d50866f3e24b2fe165b`.
3. Collect target-Mac idle/hover/stability CPU/RSS/thread reports plus 60-second idle wakeup/energy and 10-cycle compositor evidence.
4. Characterize variance before introducing any new absolute cross-session resource threshold.
5. If evidence identifies a material regression, implement one isolated optimization with RED -> GREEN and rerun affected physical acceptance; otherwise accept P1 without speculative runtime changes.
6. Only after P1 acceptance proceed to broader active-display/multi-monitor hardening or another product module.
