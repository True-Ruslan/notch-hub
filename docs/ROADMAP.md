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

Status: **IMPLEMENTED / REGRESSION-INTEGRATED / DIRECTION REPAIR AUTOMATED-GREEN BEFORE FINAL DOCS SYNC / PHYSICAL RETEST PENDING / NOT MERGED / NOT RELEASED**.

Draft PR #33 currently provides:

- stable `compact`, `peek`, `expanded` ownership under one transition authority;
- exactly 120 ms hover dwell and 140 ms Peek exit grace;
- generic Hover Peek even when no usable media session exists, with one hover-haptic request;
- bounded one-shot media enrichment in compact/Peek and persistent runtime only in expanded;
- explicit click/DOWN expansion with tap ownership above generic/media and compact/Peek branch replacement;
- exact-top-edge inclusive interactive pointer retention;
- local previous/next gestures with physical LEFT -> `next` and RIGHT -> `previous`, independent of macOS scroll-direction preference;
- interactive panel follow-finger motion and exact endpoint settlement;
- source icon, seek/cursor isolation and event-driven continuity.

No new global input authority, polling, repeating timer, display link, retry/sleep masking or sensitive permission was added.

#### 2026-08-15 physical rejection and direction repair

Exact candidate `6c2109195042759b951217f489a201a82dd044cd` / CI #1156 passed all canonical automation but was physically rejected on Mac16,8/macOS 26.6 after a real media playback test showed horizontal track gestures reversed relative to the frozen contract.

The defect was isolated to physical X normalization, not semantic command mapping. Vertical Y semantics were already correct.

Focused TDD:

- RED `f5cb5e3d1f13c7dc5564ce24068e83007f97bb1b` / CI #1157 / run `31897906228`: 354 tests / 75 suites, with only two new physical-direction assertions failing; LEFT had positive X instead of negative X, RIGHT negative instead of positive, while Y remained correct.
- GREEN `50b82dae49f3ce6c6e194b1ab9775bd5cd5dd430` / CI #1158 / run `31898052051`: one production-line change, `x: -scrollingDeltaX * preferenceScale`; Y, coordinator, haptic, lifecycle and transport code unchanged.
- #1158 passed all three canonical jobs, all 354 Swift tests, strict traceability, exact external-app XCUI, security/source policy, production transport/archive, Sandbox/Hardened Runtime/signing/preflight, unchanged size budget and performance smoke.

The current docs-synchronized descendant must pass fresh three-job CI. Only then can its exact source and CI-produced shipping/DMG artifacts be frozen for physical direction retesting.

#### Earlier 2026-08-15 repair history

Candidate `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101 was physically rejected for no-media Hover Peek/haptic and exact-top-edge DOWN self-collapse. Subsequent repair introduced generic no-media Peek, inclusive exact-edge retention and preserved pointer-exit/settlement behavior.

Docs head `a91e196d0ed51fb73a49b680eac1321100cdadb5` / CI #1152 was automatically rejected because first-launch explicit clicks could be lost during generic/media root replacement. Focused RED #1153 -> GREEN `16feb0433f7fdfb18d5eacfcce66707959e6211a` / CI #1155 moved tap authority to the stable outer root without retries/sleeps or new input authority.

The active cumulative deterministic size policy remains `performance/m6-6-physical-acceptance-20260815-repair-size-budget.json`. Immutable P0 and all historical M6 budgets remain unchanged provenance records; #1158 passed the same active envelope unchanged.

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

1. Pass all three canonical CI jobs on the final direction-repair documentation-synchronized PR #33 head.
2. Freeze exact source SHA + shipping/DMG artifact provenance without another source commit.
3. With real media playing, retest LEFT -> next and RIGHT -> previous repeatedly in compact and expanded, then Peek; verify one arm haptic per supported armed transition.
4. Any independent repeatable failure gets its own focused RED -> GREEN cycle and a new exact candidate.
5. After direction passes, continue remaining Hover Peek, seek, source-icon, interactive, lifecycle/process and permission gates on the same candidate.
6. Only after full physical PASS: mark PR #33 ready, merge, verify post-merge `main` CI, close M6.6 and begin P1.
