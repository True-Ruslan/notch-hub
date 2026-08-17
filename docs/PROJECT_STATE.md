# Project state

Last updated: 2026-08-18
Published version: `0.1.0` Personal Release
Primary physical target: macOS 26.6 / Mac16,8
Protected branch: `main`

## Product state

NotchHub is a native, local-first macOS productivity hub built around the physical MacBook notch. Security, privacy, performance, energy use and deterministic interaction behavior remain first-class constraints. Runtime work is event-driven unless measured evidence justifies otherwise.

Published state remains immutable `v0.1.0`. M6.6 below is unreleased source work.

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

Current PR #33 base is `main` at `bd9566f690d314ed40fd6f3723a319291ceb4a58`.

## Active work — M6.6 PR #33

PR #33 `M6.6: app media gesture session TDD` is **implemented / regression-integrated / source candidate `f2e81d993...` 3/3 automated-green / final horizontal physical contract PASS / full one-SHA M6.6 physical matrix still pending / draft / not merged / not released**.

Current interaction contract:

- stable `compact <-> peek <-> expanded` under one transition authority;
- hover dwell exactly 120 ms; Peek exit grace exactly 140 ms;
- generic Peek works without usable media; optional media enrichment begins only after authoritative Peek settlement;
- settled compact and Peek own zero persistent media observer; only settled expanded owns the presentation-scoped shipping runtime;
- explicit click remains one stable SwiftUI tap path; persistent AppKit hosting accepts first mouse but owns no mouse-button semantics;
- physical DOWN expands; physical UP collapses; exact top-screen/panel `maxY` remains inside the interaction region;
- expanded pointer exit returns non-haptically to exact compact;
- interactive transitions settle to exact endpoints even if moving geometry loses terminal local scroll delivery;
- physical horizontal direction is LEFT -> `next`, RIGHT -> `previous`, independent of macOS scroll-direction preference;
- horizontal visuals follow the physical finger direction rather than the media semantic direction;
- seek, source identity and cursor isolation remain bounded/event-driven;
- bounded Peek cancellation is nonblocking for the UI actor, with transport stop races and late callbacks fail-closed;
- persistent expanded-runtime and application-Quit teardown retain synchronous fail-closed lifecycle verification.

No global scroll/button/keyboard monitor, mouse-button event authority, event tap, polling loop, repeating timer, display link, UI-test retry/sleep masking, new process executable boundary, network authority, telemetry or sensitive permission has been introduced.

## Final horizontal physical evidence

Exact source `f2e81d993db37af9548799682ad8f03c7d64ae27` / CI #1238 / run `32072408370` is 3/3 GREEN:

- macOS 26 compatibility — SUCCESS;
- Build, test and package — SUCCESS;
- macOS UI regression — SUCCESS, external exact-app XCUI 11/11;
- Swift gate — 365 tests / 79 suites;
- strict acceptance traceability, production MediaRemote transport/archive, Sandbox, Hardened Runtime, shipping preflight, current cumulative size budget, coverage and performance smoke — GREEN.

On 2026-08-18 Mac16,8/macOS 26.6 physically confirmed on exact `f2e81d993...`:

- RIGHT -> Previous/back and animation RIGHT with the fingers;
- LEFT -> Next and animation LEFT with the fingers;
- below-threshold horizontal smoke -> no switch;
- momentum -> no extra switch;
- DOWN/UP smoke remained correct;
- supported horizontal arm haptic was felt exactly once.

This closes the final horizontal direction/follow-finger defect. It does not by itself promote unrelated Peek, seek, source-icon, lifecycle, permission or full interactive gates that were not re-exercised on the same exact candidate.

## Horizontal repair history

Historical automated-green candidate `6c2109195042759b951217f489a201a82dd044cd` was physically rejected because LEFT/RIGHT media commands were reversed.

A later candidate corrected visual follow-finger motion but exposed that the command semantic axis still depended on a compensating sign inversion. The final repair makes normalized X represent the physical finger direction directly:

- RIGHT -> positive X;
- LEFT -> negative X;
- `.visualOffset(cumulativeX)` follows that sign;
- negative/LEFT -> `.next`;
- positive/RIGHT -> `.previous`;
- vertical Y normalization remains unchanged.

The existing normalizer and coordinator regressions are now supplemented by `MediaGesturePhysicalPipelineTests`, which exercises raw AppKit horizontal delta -> normalizer -> visual offset -> typed command across both macOS scroll-direction preference states. This is a test-only characterization addition after the physical PASS; it changes no production behavior.

## Hover Peek / lifecycle repair retained

The final minimal architecture keeps:

- generic Peek after valid dwell;
- media enrichment only after authoritative `.peek` settlement;
- `stopNonBlocking()` for bounded Peek release after callback detachment;
- immediate cancellation of in-flight one-shot work without `waitUntilExit` on the UI actor;
- bounded graceful/forced subprocess termination;
- synchronous `stop()` for persistent expanded runtime and explicit Quit verification;
- no `NSEvent.pressedMouseButtons` correctness dependency and no primary-press production seam.

`MediaRemoteSystemTransportStopRaceTests` and `ShippingMediaPeekProbeTransportIntegrationTests` cover late queued capability launch, stale post-stop activity, first-usable-snapshot completion and bounded transport release.

## Security and resource invariants

- App Sandbox-only entitlement and Hardened Runtime remain mandatory.
- No Accessibility, Input Monitoring, Automation, Screen Recording, networking, telemetry, history persistence or arbitrary command authority is added.
- Universal Media retains the reviewed fixed `/usr/bin/perl` + pinned adapter/framework boundary.
- Settled compact and Peek own zero persistent adapter; settled expanded owns the expected presentation-scoped runtime; normal Quit must leave no orphan.
- Gesture/Peek/transition hot paths add no polling, repeating timer, display link, global monitor, event tap, per-event subprocess creation or production logging.
- UI fixtures and diagnostics remain compile-time test-only; shipping composition still creates the concrete production runtime.

## Performance state

`performance/baseline-v0.1.0.json` and all historical feature budgets remain immutable provenance records.

The active cumulative envelope remains `performance/m6-6-physical-acceptance-20260816-first-click-size-budget.json`. CI #1238 passed the same envelope without expansion.

Shared-runner performance remains compatibility evidence only. Target-Mac CPU/RSS/threads/wakeups/energy acceptance remains P1 and starts only after M6.6 physical acceptance and merge.

## Still not accepted on one final exact candidate

- complete no-media and media Hover Peek physical matrix, including stationary-pointer relaunch and physical hover haptic;
- compact click while Hover Peek/media enrichment overlaps;
- exact-top-edge DOWN and full interactive pointer/panel separation matrix;
- complete UP/pointer-exit settlement matrix;
- full seek/cursor/source-continuity matrix;
- source-icon matrix;
- lifecycle cleanup after real Quit with explicit empty `pgrep` evidence;
- full permission matrix;
- all remaining pending `NH-MEDIA-PEEK-*`, `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, and `NH-MEDIA-SOURCE-ICON-*` gates;
- PR #33 remains draft/unmerged;
- no new release claim is made;
- P1 and multi-display hardening remain blocked by M6.6 acceptance.

## Next optimal step

1. Land the test/documentation synchronization as one atomic PR-head commit with no production-code change.
2. Require all three canonical CI jobs GREEN on that exact head. The expected regression suite includes the new raw-input -> visual -> command horizontal pipeline test.
3. Freeze that exact SHA and CI-produced artifact provenance without another repository commit.
4. Perform one final target-Mac one-SHA M6.6 physical matrix on the frozen head, including a quick LEFT/RIGHT reconfirmation plus the remaining Peek, interactive, seek, source, lifecycle and permission gates.
5. After real Quit run `pgrep -lf 'mediaremote-adapter\.pl' || true` and require empty output.
6. Only after full one-SHA physical evidence is green may PR #33 become ready, merge, receive post-merge main verification and unblock P1/multi-display hardening.
