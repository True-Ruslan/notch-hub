# Roadmap

Primary target: macOS 26.6 / Mac16,8. Published Personal Release: `v0.1.0`.

States are explicit: **implemented -> automated-tested -> physically accepted -> merged -> released**. Green CI does not substitute for target-Mac acceptance when physical UI, permissions, third-party behavior or resources are part of the contract.

## Completed foundations

- **M0 Engineering Foundation — ACCEPTED / MERGED**.
- **R0.1 Personal Release — ACCEPTED / RELEASED**: immutable `v0.1.0`.
- **P0 Performance Foundation — ACCEPTED / MERGED**.
- **P0.1 Public repository readiness — ACCEPTED**.
- **M1 primary interaction foundation — ACCEPTED / MERGED**; active-display/fullscreen/Spaces/notchless/multi-monitor hardening remains deferred.

## M6 — Universal Media / System Now Playing

- **M6.1 transport feasibility — ACCEPTED**.
- **M6.2 production media boundary — ACCEPTED / MERGED**.
- **M6.3 concrete system transport — ACCEPTED / MERGED**.
- **M6.4 shipping composition — ACCEPTED / MERGED**.
- **M6.5 Media-first UI — ACCEPTED / MERGED**.

### M6.6 — gestures, haptics, interactive notch, seek and Hover Peek

Status: **IMPLEMENTED / AUTOMATED REPAIR GREEN / PHYSICAL RETEST PENDING / NOT MERGED / NOT RELEASED**.

Draft PR #33 contains stable `compact`, `peek`, `expanded` presentation ownership, 120 ms media-only Hover Peek, 140 ms Peek grace, explicit click/DOWN expansion, local media gestures/haptics, interactive panel motion, bounded compact/Peek media work, expanded-only persistent runtime, source icon, seek/cursor isolation and event-driven continuity.

Hover Peek deterministic size policy remains active through `performance/m6-6-hover-peek-size-budget.json`; immutable P0 and older feature budgets remain unchanged.

#### Current acceptance blocker

Exact candidate `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951 was rejected on target hardware even though automation was green.

Physical failures:

- stable hover/haptic/Peek did not fire in the observed broken session;
- moving the pointer out of expanded did not auto-collapse, regressing the accepted M1 contract;
- physical UP could leave a partially collapsed intermediate frame when shrinking geometry moved away from the pointer before local scroll delivered a terminal phase.

The latter two failures have a focused repair. Clean RED `0a42a701fcf4fa2f59972a68d2a3b9243203a202` / CI #959 failed exactly five new regression tests among 333 tests / 69 suites. Production GREEN `64d3e6c2beadacaeda69c8ac06f173ac26aace3e` restored expanded pointer-exit collapse and added local synchronous settlement based on actual panel geometry. Format-only `de5624b7d344e15772fdf0759fbe4b5027a5b1d4` / CI #961 passed both required jobs with all 333 tests and release/security/performance/media/signing/preflight/size/performance-smoke gates green.

The repair introduces no global scroll monitor, event tap, watchdog timer, polling or new sensitive input authority.

The hover/haptic symptom remains an explicit retest condition. If it reproduces from clean stable compact after the transition repair, it becomes a separate TDD defect instead of being guessed into this fix.

Acceptance ledgers:

- `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`;
- `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`;
- `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`.

No P1 work, merge or release is allowed before applicable physical gates pass on one exact candidate.

## P1 — whole-app performance/resource review

Status: **AFTER M6.6 ACCEPTANCE / MERGE**.

Planned: target-Mac CPU/RSS/threads/wakeups/energy/compositor review, global `.mouseMoved` fallback comparison, repeated-run variance characterization.

## Product modules after media/performance foundation

- **M2 Shelf**.
- **M3 Snippets**.
- **M4 Calendar**.
- **M5 Translator**.
- **M7 Product shell**.
- **M8 Trusted distribution — optional**.

## Current priority

1. Pass both required CI jobs on this final docs-synchronized pointer-exit/lost-terminal repair head.
2. Freeze exact source/artifact provenance in PR #33 without another repository commit.
3. Retest clean stable hover/haptic/Peek, expanded pointer-exit auto-collapse, and UP/DOWN pointer/panel-separation settlement first.
4. Any independent repeatable hover or transition failure gets its own RED -> GREEN cycle and new exact candidate.
5. Only after the focused block passes continue remaining Peek/gesture/seek/source-icon/lifecycle/permission gates.
6. Only after full physical PASS: mark PR #33 ready, merge, verify post-merge `main` CI, then begin P1.
