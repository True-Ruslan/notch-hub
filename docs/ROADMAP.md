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

Status: **IMPLEMENTED / REGRESSION-INTEGRATED / FOCUSED REPAIR AUTOMATED-GREEN BEFORE FINAL DOCS SYNC / PHYSICAL RETEST PENDING / NOT MERGED / NOT RELEASED**.

Draft PR #33 currently provides:

- stable `compact`, `peek`, `expanded` ownership under one transition authority;
- exactly 120 ms hover dwell and 140 ms Peek exit grace;
- generic Hover Peek even when no usable media session exists, with one hover-haptic request;
- bounded one-shot media enrichment in compact/Peek and persistent runtime only in expanded;
- explicit click/DOWN expansion with tap ownership above both generic/media and compact/Peek branch replacement;
- exact-top-edge inclusive interactive pointer retention;
- local previous/next gestures and haptics;
- interactive panel follow-finger motion and exact endpoint settlement;
- source icon, seek/cursor isolation and event-driven continuity.

No new global input authority, polling, repeating timer, display link, retry/sleep masking or sensitive permission was added.

#### 2026-08-15 physical rejection and repair

Candidate `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101 was rejected on the target Mac:

- with music off, hover produced no Peek/haptic;
- exact-top-edge DOWN twitched then self-collapsed;
- expanded pointer exit remained PASS;
- center-notch DOWN and physical UP were stable.

The repair changed the pending product contract so no-media hover opens generic Peek and requests one hover haptic, replaced half-open interactive containment at the physical boundary, and hardened explicit-click ownership across hover/media presentation changes.

Automated evidence:

- behavior head `63b0f2f96f879123f3883db7311c90a20d3a4328` / CI #1140: 352 Swift tests / 74 suites and 11/11 external XCUI PASS; package failed only on the preceding DMG size ceiling;
- pre-docs head `3e617698a503590dbc18958960a5335753734ccc` / CI #1147: all three canonical jobs PASS with strict traceability, security/source audit, production transport, shipping/signing/Sandbox/Hardened Runtime/preflight, performance smoke and the revised tight size budget;
- docs head `a91e196d0ed51fb73a49b680eac1321100cdadb5` / CI #1152 was automatically rejected because two first-launch explicit-click XCUI journeys could still lose the gesture when the entire generic/media outer branch changed;
- focused RED `ac1f004b9a0d2a0fd54c16cb7c0041933d3523df` / CI #1153: 354 tests / 75 suites with only the new root tap-ownership test failing;
- GREEN `16feb0433f7fdfb18d5eacfcce66707959e6211a` / CI #1155: tap authority moved to the stable outer media-aware root; all three canonical jobs and the external-app XCUI suite PASS with no retries/sleeps.

The active cumulative deterministic size policy remains `performance/m6-6-physical-acceptance-20260815-repair-size-budget.json`. It keeps app/executable allowance unchanged from the preceding cumulative envelope and adds one 4096-byte DMG allowance quantum. Immutable P0 and all historical M6 budgets remain unchanged provenance records. #1155 passed the same envelope unchanged at app `883119 B`, DMG `555204 B`, executable `580912 B`.

The current docs-synchronized head still requires fresh three-job CI. After it passes, its exact source and CI-produced shipping artifact/DMG are frozen without another source commit.

Acceptance ledgers:

- `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`;
- `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`;
- `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`.

No P1 work, merge or release is allowed before all applicable physical gates pass on one exact candidate.

## P1 — whole-app performance/resource review

Status: **BLOCKED UNTIL M6.6 PHYSICAL ACCEPTANCE + MERGE**.

Planned: target-Mac CPU/RSS/threads/wakeups/energy/compositor review, narrow global `.mouseMoved` fallback comparison, repeated-run variance characterization, and real active-display/multi-monitor reality checks.

## Product modules after media/performance foundation

- **M2 Shelf**.
- **M3 Snippets**.
- **M4 Calendar**.
- **M5 Translator**.
- **M7 Product shell**.
- **M8 Trusted distribution — optional**.

## Current priority

1. Pass all three canonical CI jobs on the final documentation-synchronized PR #33 head.
2. Freeze exact source SHA + shipping/DMG artifact provenance without another source commit.
3. Run the focused target-Mac block: no-media Hover Peek/haptic, stationary relaunch, explicit click under hover/media branch changes, exact-top-edge DOWN, expanded pointer exit, UP/DOWN lost-terminal safety.
4. Any independent repeatable failure gets its own focused RED -> GREEN cycle and a new exact candidate.
5. Only after the focused block passes continue remaining Peek/gesture/seek/source-icon/lifecycle/permission gates on the same candidate.
6. Only after full physical PASS: mark PR #33 ready, merge, verify post-merge `main` CI, close M6.6 and begin P1.
