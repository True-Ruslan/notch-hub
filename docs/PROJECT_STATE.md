# Project state

Last updated: 2026-08-18
Published version: `0.1.0` Personal Release
Primary physical target: macOS 26.6 / Mac16,8
Protected branch: `main`

## Product state

NotchHub is a native, local-first macOS productivity hub built around the physical MacBook notch. Security, privacy, performance, energy use and deterministic interaction behavior remain first-class constraints. Runtime work remains event-driven unless measured evidence justifies otherwise.

Published state remains immutable `v0.1.0`. M6.6 below is accepted source work but is still unreleased and unmerged.

### Merged foundations

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
- M6.6 prerequisite tasks through vertical visual tracking — merged.
- Regression/UI Automation Foundation — merged via PR #34 as `bd9566f690d314ed40fd6f3723a319291ceb4a58`; post-merge main CI #1053 passed all canonical jobs.

Current PR #33 base remains `main` at `bd9566f690d314ed40fd6f3723a319291ceb4a58`.

## M6.6 PR #33 — physically accepted source candidate

PR #33 `M6.6: app media gesture session TDD` is **implemented -> automated-tested -> physically accepted on exact source `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3` -> still draft / not merged / not released**.

Exact source candidate evidence:

- source SHA: `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3`;
- canonical CI #1241 / run `32075976405` — 3/3 GREEN;
- Swift gate — 366 tests / 80 suites GREEN;
- external exact-app native XCUI — 11/11 GREEN;
- strict acceptance traceability, production MediaRemote transport/archive, Sandbox, Hardened Runtime, shipping preflight, current cumulative size budget, coverage and shared-runner performance smoke — GREEN.

On 2026-08-18 the complete requested target-Mac matrix passed on Mac16,8/macOS 26.6 using that exact candidate:

- RIGHT -> Previous/back, animation follows RIGHT, one supported arm haptic;
- LEFT -> Next, animation follows LEFT, one supported arm haptic;
- media-on hover -> Peek + physical haptic, never accidental expansion;
- stationary-pointer relaunch -> Peek + physical haptic;
- media-off hover -> generic Peek + physical haptic;
- compact click while hover/media enrichment can overlap -> one prompt Expanded transition;
- exact-top-edge DOWN and center DOWN -> stable follow-finger expansion without twitch/self-collapse;
- expanded pointer exit -> exact Compact;
- expanded UP, including UP while leaving retention -> exact Compact;
- seek preview / commit / cancel -> correct; cursor restores; track/source identity change cancels the transaction;
- source-app icon and fallback rendering -> correct;
- Accessibility / Input Monitoring / Automation / Screen Recording -> NONE;
- after real Quit, `pgrep -lf 'mediaremote-adapter\.pl' || true` -> empty.

Deterministic subcontracts not requiring hardware perception remain covered by the automated suite: threshold/hysteresis, short/reverted gestures, momentum rejection, diagonal arbitration, capability fail-closed behavior, 120 ms dwell, 140 ms Peek grace, Reduce Motion endpoint policy, stale generation protection, bounded source lookup and transport stop races.

## Accepted interaction contract

- stable `compact <-> peek <-> expanded` under one transition authority;
- hover dwell exactly 120 ms; Peek exit grace exactly 140 ms;
- generic Peek works without usable media; optional media enrichment begins only after authoritative Peek settlement;
- settled compact and Peek own zero persistent media observer; only settled expanded owns the presentation-scoped shipping runtime;
- explicit click remains one stable SwiftUI tap path; persistent AppKit hosting accepts first mouse but owns no mouse-button semantics;
- physical DOWN expands; physical UP collapses; exact top-screen/panel `maxY` remains inside the interaction region;
- expanded pointer exit returns non-haptically to exact compact;
- interactive transitions settle to exact endpoints even if moving geometry loses terminal local scroll delivery;
- physical horizontal direction is LEFT -> `next`, RIGHT -> `previous`, independent of macOS scroll-direction preference;
- horizontal visuals follow the physical finger direction;
- seek, source identity and cursor isolation remain bounded/event-driven;
- bounded Peek cancellation is nonblocking for the UI actor, with transport stop races and late callbacks fail-closed;
- persistent expanded-runtime and application-Quit teardown retain synchronous fail-closed lifecycle verification.

No global scroll/button/keyboard monitor, mouse-button event authority, event tap, polling loop, repeating timer, display link, UI-test retry/sleep masking, new process executable boundary, network authority, telemetry or sensitive permission was introduced.

## Regression coverage

The final horizontal defect is guarded by `MediaGesturePhysicalPipelineTests`, which exercises raw AppKit horizontal delta -> normalization -> follow-finger visual offset -> typed media command across both macOS scroll-direction preference states. Existing coordinator, Peek, interactive-transition, seek, cursor, source-icon, lifecycle and policy suites cover the remaining deterministic contracts.

The acceptance ledgers are authoritative for stable IDs:

- `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`;
- `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`;
- `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`.

Machine-readable traceability remains in `Tests/Acceptance/coverage.yml` plus `coverage-current.json`.

## Security and resource invariants

- App Sandbox-only entitlement and Hardened Runtime remain mandatory.
- No Accessibility, Input Monitoring, Automation, Screen Recording, networking, telemetry, history persistence or arbitrary command authority is added.
- Universal Media retains the reviewed fixed `/usr/bin/perl` + pinned adapter/framework boundary.
- Settled compact and Peek own zero persistent adapter; settled expanded owns the expected presentation-scoped runtime; normal Quit leaves no orphan.
- Gesture/Peek/transition hot paths add no polling, repeating timer, display link, global monitor, event tap, per-event subprocess creation or production logging.
- UI fixtures and diagnostics remain compile-time test-only; shipping composition still creates the concrete production runtime.

## Performance state

`performance/baseline-v0.1.0.json` and all historical feature budgets remain immutable provenance records.

The active cumulative envelope remains `performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json`; exact candidate CI #1241 passed without widening it.

Shared-runner performance remains compatibility evidence only. Target-Mac CPU/RSS/threads/wakeups/energy acceptance remains P1 and starts only after PR #33 is merged and post-merge `main` is verified.

## Acceptance-record rule

The physical source acceptance is frozen on exact `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3`. The follow-up acceptance-record commit changes documentation and machine-readable coverage only; it does not redefine the physically accepted runtime SHA. That record must pass all canonical CI gates before PR #33 can advance.

PR #33 intentionally remains Draft until separate merge authorization. No release claim is made.

## Next optimal step

1. Validate this acceptance-record commit through all three canonical CI jobs without production changes or policy weakening.
2. Update PR #33 metadata to point at accepted source `8744b9e...` and the acceptance-record CI evidence while keeping it Draft.
3. On explicit merge authorization, mark PR #33 ready, merge with expected-head protection and verify post-merge `main` CI.
4. Only after the merge/post-merge gate, close M6.6 as merged and begin P1 target-Mac whole-app performance/resource review before multi-monitor hardening.
