# Project state

Last updated: 2026-08-13
Published version: `0.1.0` Personal Release
Primary physical target: macOS 26.6 / Mac16,8
Protected branch: `main`

## Current state

NotchHub is a native, local-first macOS productivity hub built around the physical MacBook notch. Security, privacy, performance and energy use are first-class constraints; runtime behavior is event-driven unless a separate measured decision proves otherwise.

Published state remains immutable `v0.1.0`. M1/P0.1/M6 source work below is unreleased.

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
- M6.6 prerequisite tasks through vertical visual tracking — merged into `main`.

Current `main` head before PR #33 remains `172805f8cd63dab664d0dbc6747576fb51b13e7a`; main CI #836 passed.

## Active work — M6.6 PR #33

PR #33 `M6.6: app media gesture session TDD` is **implemented / automated repair tested / physical acceptance failed and retest pending / draft / not merged / not released**.

The branch owns stable `compact <-> peek <-> expanded`, media-only 120 ms Hover Peek with 140 ms grace, explicit click/DOWN expansion, local previous/next gestures and haptics, follow-finger transitions, bounded compact/Peek media work, expanded-only persistent runtime, source icon, seek/cursor isolation and event-driven continuity.

## Physical acceptance history

### Stationary-startup hover failure

Candidate `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945 was rejected. Relaunch with the pointer already stationary on the notch could never arm the normal dwell because `show()` passed the initial mouse location with hover activation disabled.

RED `553cf973722dfb214f0fcb741ddb6c9b0b44ff02` / CI #947 reproduced it; GREEN `d17bd27be72c8c3bd022fb2c3613050c398c622e` / CI #948 removed only that startup suppression.

### Expanded pointer-exit / interactive lost-terminal failure

The next exact candidate `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951 also passed automation but was rejected on Mac16,8/macOS 26.6.

Target observations:

- clean hover/haptic/Peek did not fire in the observed broken session;
- DOWN expanded successfully, but moving the pointer away left expanded open;
- UP collapse could leave a clipped intermediate panel if the shrinking window moved out from under the pointer before local scroll delivered its terminal phase.

The pointer-exit failure was a regression of accepted M1 behavior: PR #33 had changed expanded pointer policy to retain `.expanded` outside the retention region. The stuck intermediate frame came from relying on local `.ended`/`.cancelled` to finish an interactive transition even when shrinking geometry could stop further local delivery.

Focused repair:

- clean RED `0a42a701fcf4fa2f59972a68d2a3b9243203a202` / CI #959: 333 tests / 69 suites; exactly five new regression tests failed while the previous suite passed;
- production GREEN `64d3e6c2beadacaeda69c8ac06f173ac26aace3e`: restored accepted expanded pointer-exit collapse, allowed only pointer-exit collapse to retarget an owned interactive transition, and routed current local pointer position through interactive updates so actual `panel.frame` can settle immediately when geometry leaves the pointer;
- format-only `de5624b7d344e15772fdf0759fbe4b5027a5b1d4` / CI #961: both required jobs PASS, 333 tests / 69 suites PASS, strict formatting/security/performance/media/signing/preflight/size/performance-smoke PASS.

The hover/haptic symptom is not silently assigned to the transition repair. It must be retested from a clean stable compact state on the next exact candidate; if it persists independently, it becomes a separate focused RED -> GREEN defect.

## Security/resource invariants

- App Sandbox-only entitlement and Hardened Runtime remain mandatory.
- No Accessibility, Input Monitoring, Automation, Screen Recording, network, telemetry, history persistence or arbitrary command authority was added.
- Universal Media retains the reviewed fixed `/usr/bin/perl` + pinned adapter/framework boundary.
- Settled compact and Peek own zero persistent adapter; settled expanded owns the expected presentation-scoped runtime; normal Quit must leave no orphan.
- Gesture/Peek/transition hot paths add no polling, repeating timer, display link, global scroll monitor, event tap, per-event process creation or logging.
- The lost-terminal repair reuses existing local scroll delivery and existing mouse-move observation; it adds no new input authority.

## Performance state

`performance/baseline-v0.1.0.json` and prior feature budgets remain immutable provenance records. The active cumulative deterministic size envelope remains `performance/m6-6-hover-peek-size-budget.json`. CI #961 proves the repair still satisfies the active policy and performance smoke.

Target-Mac CPU/RSS/threads/wakeups/energy acceptance remains separate. P1 does not begin before M6.6 is physically accepted and merged.

## Not yet accepted

- stable compact hover/haptic/Peek must be retested, including stationary relaunch;
- expanded pointer exit must return non-haptically to exact compact;
- UP/DOWN interactive transitions must never remain at an intermediate frame when pointer/panel separation occurs before terminal local scroll delivery;
- remaining `NH-MEDIA-PEEK-*`, affected `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*`, `NH-MEDIA-SOURCE-ICON-*`, process ownership and permission checks remain physically pending;
- PR #33 stays draft and unmerged;
- P1 and later multi-display hardening remain blocked by the current M6.6 acceptance stage.

## Next optimal step

Run both required CI jobs on this docs-synchronized repair head. If green, freeze that exact source and DMG provenance in PR #33 without another repository commit, then perform the focused target-Mac retest for hover, expanded pointer exit and lost-terminal interactive settlement. Only after that block passes should the rest of M6.6 acceptance continue.
