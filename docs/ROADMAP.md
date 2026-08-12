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

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICAL RETEST PENDING / NOT MERGED / NOT RELEASED**.

Draft PR #33 contains stable `compact`, `peek`, `expanded` presentation ownership, 120 ms media-only hover Peek, 140 ms exit grace, explicit click/DOWN expansion, local media gestures/haptics, interactive panel motion, bounded compact/Peek one-shot media work, expanded-only persistent runtime, source icon, seek/cursor isolation and event-driven continuity.

Hover Peek deterministic size policy is active through `performance/m6-6-hover-peek-size-budget.json`; immutable P0 and older feature budgets remain unchanged.

#### Current acceptance blocker

The first docs-synchronized Hover Peek physical candidate `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945 was rejected on target hardware.

A reproducible restart/stationary-pointer defect was identified: `show()` synchronized the current mouse location with hover activation disabled, so relaunching while the pointer was already on the notch could never arm the 120 ms dwell without a further `mouseMoved` event.

Focused TDD repair:

- RED `553cf973722dfb214f0fcb741ddb6c9b0b44ff02` / CI #947: exactly the new stationary-startup regression test failed among 328 tests;
- GREEN `d17bd27be72c8c3bd022fb2c3613050c398c622e` / CI #948: both required jobs PASS, 328 tests PASS, security/signing/preflight/size/performance gates PASS;
- production change is limited to allowing the existing hover policy to evaluate `NSEvent.mouseLocation` normally during `show()`; no new polling, monitor or authority.

An unexpected full-expanded Home surface was also observed during the rejected physical run. Code inspection does not prove it shares the restart root cause because hover resolution routes only to Peek. The next physical candidate must explicitly prove that hover alone never expands; a repeat without click/DOWN becomes a separate TDD defect.

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

1. Pass CI on the docs-synchronized stationary-hover repair head and freeze its exact source/artifacts.
2. Retest `NH-MEDIA-PEEK-001` first: normal hover, restart with pointer already stationary on the notch, and proof that hover alone never opens full expanded UI.
3. If that focused retest passes, continue `NH-MEDIA-PEEK-002...013` plus affected gesture/interactive/source-icon gates.
4. Any repeatable failure gets an independent RED -> GREEN cycle and a new exact candidate.
5. Only after full physical PASS: record evidence, mark PR #33 ready, merge and verify post-merge `main` CI.
6. Then start P1.
