# Roadmap

Primary target: macOS 26.6 / Mac16,8. Published Personal Release: `v0.1.0`.

States are explicit: **implemented -> automated-tested -> physically accepted -> merged -> released**. Green CI does not substitute for target-Mac acceptance when physical UI, permissions, third-party behavior or resources are part of the contract.

## Completed foundations

- **M0 Engineering Foundation — ACCEPTED / MERGED**.
- **R0.1 Personal Release — ACCEPTED / RELEASED**: immutable `v0.1.0`.
- **P0 Performance Foundation — ACCEPTED / MERGED**.
- **P0.1 Public repository readiness — ACCEPTED**.
- **M1 primary interaction foundation — ACCEPTED / MERGED**; active-display/fullscreen/Spaces/notchless/multi-monitor hardening remains deferred.
- **Regression/UI Automation Foundation — IMPLEMENTED / TESTED / MERGED** via PR #34 as `bd9566f690d314ed40fd6f3723a319291ceb4a58`; post-merge main CI #1053 passed all three canonical jobs.

## M6 — Universal Media / System Now Playing

- **M6.1 transport feasibility — ACCEPTED**.
- **M6.2 production media boundary — ACCEPTED / MERGED**.
- **M6.3 concrete system transport — ACCEPTED / MERGED**.
- **M6.4 shipping composition — ACCEPTED / MERGED**.
- **M6.5 Media-first UI — ACCEPTED / MERGED**.

### M6.6 — gestures, haptics, interactive notch, seek and Hover Peek

Status: **IMPLEMENTED / INTEGRATED WITH REGRESSION FOUNDATION / AUTOMATED GREEN / PHYSICAL RETEST PENDING / NOT MERGED / NOT RELEASED**.

Draft PR #33 contains stable `compact`, `peek`, `expanded` presentation ownership, 120 ms media-only Hover Peek, 140 ms Peek grace, explicit click/DOWN expansion, local media gestures/haptics, interactive panel motion, bounded compact/Peek media work, expanded-only persistent runtime, source icon, seek/cursor isolation and event-driven continuity.

Pre-documentation implementation baseline `f49f94d5ab51dcec5dccb97b6c0997ec631b1261` passed PR #33 CI #1100 / run `31870867724` with all three canonical jobs green, **347 tests / 72 suites**, strict acceptance **116/116**, native external-app XCUI **9/9**, production media transport, release/security/signing/Sandbox/Hardened Runtime, combined size gate and performance smoke all PASS.

This docs sync creates the next exact source candidate and therefore requires its own fresh three-job CI before physical artifact provenance is frozen.

The active cumulative deterministic size policy is `performance/m6-6-regression-foundation-integration-size-budget.json`. Immutable P0 and all historical M6 feature budgets remain unchanged provenance records.

#### Regression-foundation integration status

Temporary draft PR #35 was used as an integration workspace after PR #34 changed the base beneath frozen PR #33. It must not be merged to `main`.

The integration now provides:

- fail-closed strict traceability for all **116 discovered / 116 mapped** stable acceptance IDs;
- explicit approved supersession records for historical M1 behavior intentionally replaced by the Hover Peek design, without promoting new M6.6 gates to accepted;
- native exact-app XCUI with stable compact/Peek/expanded accessibility surfaces and shipping fixture-leak detection;
- compile-time-only deterministic media/haptic fixtures;
- protocol-based expanded media gesture/seek runtime injection while concrete `ShippingMediaRuntime` construction remains shipping-composition authority;
- a provenance-backed cumulative M6.6 + regression-foundation size envelope.

First full combined baseline `e5cdc58776f80f1fc6f57e22959a07704d895fbe` / CI #1095 passed all canonical jobs. A separate testability refactor followed RED `3b79448697d614b7f022009653eca655a31bad4f` / CI #1096 -> GREEN `f49f94d5ab51dcec5dccb97b6c0997ec631b1261` / CI #1099 and was independently reverified after non-force fast-forward into real PR #33 by CI #1100.

#### Physical acceptance blocker

Candidate `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951 was rejected on target hardware even though automation was green:

- stable hover/haptic/Peek did not fire in the observed broken session;
- moving the pointer out of expanded did not auto-collapse, regressing accepted M1 behavior;
- physical UP could leave a partially collapsed intermediate frame when shrinking geometry moved away from the pointer before local scroll delivered a terminal phase.

The latter two failures have focused deterministic repairs and regression coverage. The hover/haptic symptom remains an explicit physical retest condition; it is not considered accepted by automation.

Acceptance ledgers:

- `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`;
- `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`;
- `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`.

No P1 work, merge or release is allowed before applicable physical gates pass on one exact candidate.

## P1 — whole-app performance/resource review

Status: **BLOCKED UNTIL M6.6 PHYSICAL ACCEPTANCE + MERGE**.

Planned: target-Mac CPU/RSS/threads/wakeups/energy/compositor review, global `.mouseMoved` fallback comparison, repeated-run variance characterization.

## Product modules after media/performance foundation

- **M2 Shelf**.
- **M3 Snippets**.
- **M4 Calendar**.
- **M5 Translator**.
- **M7 Product shell**.
- **M8 Trusted distribution — optional**.

## Current priority

1. Pass all three canonical CI jobs on this docs-synchronized PR #33 head.
2. Freeze that exact source SHA and CI-produced shipping artifact/DMG provenance without another source commit.
3. Retest clean stable hover/haptic/Peek and stationary relaunch first.
4. Retest DOWN -> expanded -> plain pointer exit and UP/DOWN pointer/panel-separation settlement; require exact stable endpoint every time.
5. Any independent repeatable failure gets its own RED -> GREEN cycle and a new exact candidate.
6. Only after the focused block passes continue remaining Peek/gesture/seek/source-icon/lifecycle/permission gates on the same candidate.
7. Only after full physical PASS: mark PR #33 ready, merge, verify post-merge `main` CI, close the M6.6 milestone and begin P1.
