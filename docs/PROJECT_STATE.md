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

PR #33 `M6.6: app media gesture session TDD` is **implemented / automated-tested / physical acceptance pending / draft / not merged / not released**.

The current consolidated user-visible slice now uses three stable presentation states under the existing single transition authority:

`compact <-> peek <-> expanded`

Hover previews media in Peek after the frozen 120 ms dwell; click or physical DOWN explicitly expands. Peek has a 140 ms pointer-exit grace. Compact and settled Peek own zero persistent media observer; only settled expanded owns the presentation-scoped shipping runtime.

The branch includes:

- local App-owned `MediaGestureSession` with RIGHT -> previous, LEFT -> next, DOWN -> expand and expanded UP -> compact semantics independent of macOS scroll-direction preference;
- one public AppKit arm haptic per horizontal armed transition;
- interactive follow-finger panel motion through the existing Core transition authority;
- bounded compact/Peek one-shot media capability and command work without persistent observation;
- public `NSWorkspace` source-app icon resolution with an 8-entry in-memory cache;
- capability-gated draggable seek in Peek and expanded presentation;
- seek transaction identity locking across track/source changes;
- cursor hide/restore only while a valid seek owns interaction, with no pointer warp/lock;
- bounded event-driven media/Home and horizontal-release continuity without polling, repeating timers or display links.

### Physical repair and Hover Peek progression

First complete physical candidate `d008f698b323963f084eedce601620ee957ef442` / CI #872 passed automation but failed target acceptance on hover/gesture arbitration, physical vertical direction, stale seek across source/track change and visual continuity. It is superseded.

Those defects were repaired under independent RED -> GREEN cycles and the physical-repair size envelope became green at `6403dae0e33281f6dcd5bcbd79ec5147b6580c0a` / CI #883.

The subsequent Hover Peek follow-up changed the acceptance surface and intentionally required a new cumulative size envelope rather than modifying historical budgets:

- CI #939 on `7daffde9b7c2a734e2ddfa234b1ee744b0d96d9e` established functional/security/package evidence and exact sizes `562,368 / 864,574 / 555,272 B` executable/app/DMG; only the previous repair envelope failed;
- commit `4bc15c4757727922817b4aaac35c7991c852019a` added the focused Hover Peek budget policy and CI #940 provided a clean RED: 327 Swift tests / 68 suites with exactly the missing budget failing;
- `performance/m6-6-hover-peek-size-budget.json` is bound to CI #939 evidence; prior repair/seek/icon/gesture budgets remain immutable historical evidence;
- `745baa55b7a53519b3832f21305fa9c357ce05fa` / CI #944 passed both required jobs with the Hover Peek envelope active, including policy/security checks, 327 Swift tests, Sandbox/Hardened Runtime, signing, shipping preflight, deterministic size enforcement and performance smoke.

This documentation sync follows that pre-docs green head. The exact docs-synchronized acceptance candidate and artifacts are recorded in PR #33 after its own CI completes.

## Security/resource invariants

- App Sandbox-only entitlement and Hardened Runtime remain mandatory.
- No Accessibility, Input Monitoring, Automation, Screen Recording, network, telemetry, history persistence or arbitrary command authority was added.
- Universal Media retains the fixed reviewed `/usr/bin/perl` + pinned adapter/framework boundary.
- Settled compact and Peek own zero persistent adapter; settled expanded owns the expected presentation-scoped runtime; normal Quit must leave no orphan.
- Source icon lookup is public local `NSWorkspace` with bounded in-memory cache.
- Gesture/Peek hot paths add no polling, timer/display-link, broad global scroll capture, per-event process creation or logging.

## Performance state

`performance/baseline-v0.1.0.json` remains immutable. All prior M6 feature budgets remain immutable provenance records.

The active cumulative deterministic artifact-size envelope is now `performance/m6-6-hover-peek-size-budget.json`, sourced from CI #939 evidence. This is an explicit reviewed feature-growth envelope over immutable P0, not a baseline rewrite. CI #944 proves the branch passes the new active gate.

Target-Mac CPU/RSS/threads/wakeups/energy acceptance remains separate from shared-runner CI. P1 whole-app resource review does not begin before M6.6 is physically accepted and merged.

## Not yet accepted

- `NH-MEDIA-PEEK-001...013` require target-Mac physical acceptance on one exact docs-synchronized CI candidate.
- Applicable `NH-MEDIA-GESTURE-*`, `NH-NOTCH-INTERACTIVE-*` and `NH-MEDIA-SOURCE-ICON-*` gates must be rechecked on the same candidate.
- Process ownership must be explicitly verified for settled compact, settled Peek, settled expanded and normal Quit.
- No Accessibility, Input Monitoring, Automation or Screen Recording prompt may appear.
- P1 whole-app performance/resource review remains blocked until M6.6 is accepted/merged.
- Active-display migration, fullscreen/Spaces, screen configuration, notchless mode and broader multi-monitor hardening remain later M1 work.
- Apple Music/Spotify/additional players remain unverified unless available on the target Mac.

## Next optimal step

Run CI on this docs-synchronized head, freeze that exact successful candidate and artifacts, then run the focused M6.6 target-Mac acceptance matrix on Mac16,8/macOS 26.6. Only after full physical PASS may PR #33 leave draft, merge, and receive post-merge `main` verification. P1 remains blocked until then.
