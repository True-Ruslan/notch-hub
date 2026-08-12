# Project state

Last updated: 2026-08-12
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

PR #33 `M6.6: app media gesture session TDD` is **draft / not merged / not released**. It contains the user-visible App gesture session, source-app icon and draggable seek plus the physical-acceptance repair pass.

First physical candidate `d008f698b323963f084eedce601620ee957ef442` / CI #872 passed automation but failed target acceptance on compact hover arbitration, physical vertical direction, seek source/track cancellation and visual continuity. It is superseded and must not be merged.

The repair pass was implemented under independent RED -> GREEN cycles. Exact pre-docs repair head `6403dae0e33281f6dcd5bcbd79ec5147b6580c0a` passed CI #883 in both required jobs, including Swift tests, warnings-as-errors builds, policy/security checks, Sandbox/Hardened Runtime, signing, shipping preflight, the new provenance-backed repair size budget and performance smoke.

### Repair behavior

- axis-aware physical gesture normalization keeps RIGHT -> previous, LEFT -> next and corrects DOWN -> expand / UP -> collapse across system scroll-direction preference;
- compact media wings no longer broaden hover activation; precise local gesture preflight cancels pending hover dwell without adding a new event monitor;
- seek transactions capture authoritative media generation + source bundle identity and cannot apply a stale drag to a new track/source;
- seek capture blocks scroll gestures until completion/cancellation;
- transient media/session changes and horizontal release use bounded event-driven visual continuity without polling/timer/display-link;
- all historical feature-size budgets and immutable P0 remain unchanged; active repair growth has its own provenance-backed envelope.

## Security/resource invariants

- App Sandbox-only entitlement and Hardened Runtime remain mandatory.
- No Accessibility, Input Monitoring, Automation, Screen Recording, network, telemetry, history persistence or arbitrary command authority was added.
- Universal Media retains the fixed reviewed `/usr/bin/perl` + pinned adapter/framework boundary.
- Settled compact owns zero persistent adapter; expanded owns the expected presentation-scoped runtime; normal Quit must leave no orphan.
- Source icon lookup is public local `NSWorkspace` with bounded in-memory cache.
- Gesture hot path has no per-event process creation, image lookup, file I/O, timer/display link or logging.

## Performance state

`performance/baseline-v0.1.0.json` remains immutable. Historical M6.4/M6.5/M6.6 feature budgets remain preserved for provenance.

CI #881 established the repair size evidence before budget creation: executable/app/DMG `523,200 / 825,406 / 527,113 B`, with every functional/security/signing/preflight check passing and only the prior seek envelope failing. CI #882 then provided a clean missing-budget RED. `performance/m6-6-physical-acceptance-repair-size-budget.json` is bound to that evidence; CI #883 passed the new active gate.

## Not yet accepted

- The repaired M6.6 user-visible slice still requires one exact docs-sync CI candidate and target-Mac retest.
- `NH-MEDIA-GESTURE-012` and `016` require explicit process checks on target hardware.
- The new `NH-NOTCH-INTERACTIVE-*` ledger requires physical acceptance.
- P1 whole-app performance/resource review must not start before M6.6 is accepted/merged.
- Active-display migration, fullscreen/Spaces, screen configuration, notchless mode and click/pin remain later M1 work.
- Apple Music/Spotify/additional players remain unverified unless available on the target Mac.
- Retained compact media may intentionally be stale until expansion because compact persistent observation is prohibited.
- Live continuously advancing progress, seek-start haptic and enlarged seek interaction treatment are separate future UX decisions; they are not silently folded into this acceptance repair.

## Next optimal step

Freeze one docs-synchronized exact CI candidate from PR #33, run the focused M6.6 physical retest on Mac16,8/macOS 26.6, and only after full PASS mark acceptance, prepare PR #33 for merge and verify post-merge `main` CI.
