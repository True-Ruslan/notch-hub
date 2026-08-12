# Project state

Last updated: 2026-08-13
Published version: `0.1.0` Personal Release
Primary physical target: macOS 26.6 / Mac16,8
Protected branch: `main`

## Current state

NotchHub is a native, local-first macOS productivity hub built around the physical MacBook notch. Security, privacy, performance and energy use are first-class constraints; runtime behavior is event-driven unless a separate measured decision proves otherwise.

Published state remains immutable `v0.1.0`. M1/P0.1/M6 source work is not released yet.

### Merged foundations

- M0 Engineering Foundation — accepted/merged.
- R0.1 Personal Release `v0.1.0` — accepted/released.
- P0 Performance Foundation — accepted/merged; immutable baseline preserved.
- P0.1 Public repository readiness — accepted.
- M1 primary interaction/transition foundation — accepted/merged; multi-display/fullscreen/Spaces hardening remains deferred.
- M6.1 transport feasibility — accepted (`ACCEPT_TRANSPORT`).
- M6.2 normalized media boundary — accepted/merged.
- M6.3 production system transport — accepted/merged.
- M6.4 shipping media composition/lazy lifecycle — accepted/merged.
- M6.5 Media-first UI — accepted/merged.
- M6.6 Tasks 0-4 prerequisites, including deterministic gesture engine, local input seam, compact dispatcher, interactive transition authority and vertical visual tracking — merged into `main`.

Current `main` head before PR #33 remains `172805f8cd63dab664d0dbc6747576fb51b13e7a`; post-merge main CI #836 passed.

## Active work — M6.6 PR #33

PR #33 `M6.6: app media gesture session TDD` remains **implemented / automated-tested / physical acceptance pending / draft / not merged / not released**.

The consolidated user-visible slice uses stable `compact <-> peek <-> expanded` presentation states under one transition authority. Hover previews Peek after 120 ms; click or physical DOWN explicitly expands; Peek exit grace is 140 ms. Compact and settled Peek own zero persistent media observer; only settled expanded owns the presentation-scoped shipping runtime.

### Hover Peek physical result

The docs-synchronized candidate `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945 was **physically rejected** on Mac16,8/macOS 26.6.

Observed during the first test block:

- an unexpected full expanded Home/foundation surface appeared and looked stuck during the initial interaction sequence;
- after restarting while the pointer was already stationary on the physical notch, compact did not enter Peek despite the pointer remaining in the hover region.

The restart/stationary symptom has a proven code cause: `NotchPanelController.show()` passed the current `NSEvent.mouseLocation` into the interaction coordinator with `allowActivation: false`. With a stationary pointer, no subsequent `mouseMoved` existed to schedule the normal 120 ms dwell.

The unexpected full-expanded observation is not assigned that root cause. The hover success path routes only to Peek; full expansion is owned by explicit click/DOWN. The next target retest must therefore explicitly prove that hover alone never expands. A repeat without click/DOWN is a separate defect requiring its own RED -> GREEN cycle.

### Stationary startup repair TDD

- RED `553cf973722dfb214f0fcb741ddb6c9b0b44ff02` / CI #947: 328 tests / 68 suites, exactly the new `showKeepsStationaryPointerEligibleForHoverDwell` regression test failed; warnings-as-errors build passed;
- GREEN `d17bd27be72c8c3bd022fb2c3613050c398c622e`: removed only the startup activation suppression from `show()`;
- CI #948 / run `31645020620`: both required jobs PASS with 328 Swift tests, policy/security checks, Sandbox/Hardened Runtime/signing, shipping preflight, active Hover Peek size enforcement and performance smoke;
- CI #948 artifact sizes remain inside the active envelope: `562,368 / 864,574 / 555,281 B` executable/app/DMG;
- shipping artifact `9160475207`, digest `sha256:77b8d08df15f698068ecf45ca13e1b811ff3c3db5b82f74e183ac46299dfcab0`;
- standalone DMG artifact `9160479006`, digest `sha256:d36f5f1cd4d9ed71328900338d069838f6fbe3905c182136df3372395467e667`;
- contained DMG SHA-256 `51b6b7b947153edd722ba92cc87080e02afc57cb553b96c07cb28423060ff587`.

CI #948 is pre-docs repair evidence. This documentation sync must itself pass both required jobs; that exact docs-synchronized head/artifact becomes the next physical candidate.

## Security/resource invariants

- App Sandbox-only entitlement and Hardened Runtime remain mandatory.
- No Accessibility, Input Monitoring, Automation, Screen Recording, network, telemetry, history persistence or arbitrary command authority was added.
- Universal Media retains the fixed reviewed `/usr/bin/perl` + pinned adapter/framework boundary.
- Settled compact and Peek own zero persistent adapter; settled expanded owns the expected presentation-scoped runtime; normal Quit must leave no orphan.
- Source icon lookup is public local `NSWorkspace` with bounded in-memory cache.
- Gesture/Peek hot paths add no polling, timer/display-link, broad global scroll capture, per-event process creation or logging.
- The stationary-startup fix adds no monitor or periodic work; it only allows the existing one-shot dwell policy to evaluate the already-known cursor location on `show()`.

## Performance state

`performance/baseline-v0.1.0.json` remains immutable. All prior M6 feature budgets remain immutable provenance records.

The active cumulative deterministic artifact-size envelope remains `performance/m6-6-hover-peek-size-budget.json`. CI #948 proves the repair remains within it. Target-Mac CPU/RSS/threads/wakeups/energy acceptance remains separate from shared-runner CI.

## Not yet accepted

- `NH-MEDIA-PEEK-001` failed on `bbba...` and requires retest on the new exact docs-synchronized candidate, including restart while the cursor is already stationary on the notch.
- Hover alone must be shown not to open full expanded UI; a repeat without click/DOWN is a separate blocker.
- `NH-MEDIA-PEEK-002...013` and affected `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, `NH-MEDIA-SOURCE-ICON-*` remain physically pending.
- Process ownership and sensitive-permission checks remain pending.
- P1 whole-app performance/resource review remains blocked until M6.6 is physically accepted and merged.
- Active-display migration, fullscreen/Spaces, screen configuration, notchless mode and broader multi-monitor hardening remain later M1 work.

## Next optimal step

Pass both required CI jobs on this docs-synchronized repair head, freeze its exact DMG/provenance, then retest the narrow startup/hover regression first on Mac16,8/macOS 26.6. Only if that passes should the remaining M6.6 physical matrix continue. PR #33 remains draft; P1 remains blocked.
