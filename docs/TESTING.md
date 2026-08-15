# Testing

## Policy

Automate every deterministic behavior that can be validated reliably. Manual acceptance is reserved for physical notch geometry, real pointer/trackpad feel, compositor continuity, haptic feel, macOS permission/trust surfaces, third-party integration and target-hardware resources.

A green pipeline is necessary but never substitutes for target-Mac acceptance. Manual success never substitutes for reproducible automated coverage.

## Required CI

Canonical protected-branch jobs:

- `macOS 26 compatibility`;
- `macOS UI regression`;
- `Build, test and package`.

CI covers warnings-as-errors builds, Swift tests, exact external-app XCUI, acceptance-traceability policy, release/security/performance/media policy, strict formatting/plist/shell checks, Sandbox/Hardened Runtime/signing/system-library verification, shipping media preflight, deterministic artifact sizes, active provenance-backed feature budget, performance-harness schema smoke and artifacts.

Do not weaken tests, security rules, production behavior or historical baselines merely to obtain green CI.

## Regression/UI automation foundation

PR #34 merged the native regression foundation as `bd9566f690d314ed40fd6f3723a319291ceb4a58`; post-merge main CI #1053 passed all three jobs.

The foundation includes:

- checked-in XCTest/XCUIAutomation project that launches the exact SwiftPM-built `NotchHub.app` by URL;
- source provenance validation through `NHSourceCommit`;
- compile-time-only `NOTCHHUB_UI_TESTING` deterministic media/haptic fixtures;
- shipping binary marker scans proving fixture isolation;
- stable accessibility IDs for `notch.surface.compact`, `notch.surface.peek`, `notch.surface.expanded` and relevant media controls;
- predicate/state-driven synchronization and `.xcresult`/screenshot/accessibility-tree diagnostics;
- machine-readable acceptance coverage in `Tests/Acceptance/coverage.yml` plus current overlay/supersession ledgers;
- fail-closed `scripts/test_acceptance_coverage.py --mode strict` in both UI and package jobs.

Current PR #33 inventory is **116 discovered / 116 mapped / 0 unmapped**. Approved supersessions preserve historical accepted evidence while making intentional product replacement explicit; they do not convert replacement M6.6 contracts into physical acceptance.

## TDD rule

For production behavior:

1. add a focused regression test;
2. preserve a RED run proving the intended missing behavior;
3. implement the minimum GREEN change;
4. run full CI/security/performance verification;
5. only then advance to another independent defect.

Race, stale-callback, boundary and teardown behavior must be tested deterministically without arbitrary sleeps where practical.

## Accepted physical foundations

M1 notch/hover/haptic/animation and M6.1-M6.5 media contracts are physically accepted on the primary target as recorded in their ledgers. M6.6 remains physically unaccepted. In particular, expanded pointer-exit auto-collapse is an accepted M1 invariant and must not be weakened by M6.6.

## M6.6 current automated evidence

Stable contracts:

- `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`;
- `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`;
- `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`.

Current tests/policy cover gesture semantics, compact/Peek bounded one-shot lifecycle, local scroll composition, physical-axis normalization, stable presentation ownership, 120 ms Hover Peek, 140 ms Peek grace, explicit expansion, transition authority, source icon, seek/cursor isolation, event-driven continuity, zero persistent compact/Peek adapter ownership and existing Sandbox/Hardened Runtime/security boundaries.

Pre-documentation implementation baseline `f49f94d5ab51dcec5dccb97b6c0997ec631b1261` passed PR #33 CI #1100 / run `31870867724`:

- all three canonical jobs SUCCESS;
- **347 tests / 72 suites PASS**;
- strict acceptance **116/116 PASS**;
- **9/9 native external-app XCUI PASS**;
- exact UI-test app build and shipping-fixture exclusion PASS;
- production transport candidate/archive verification PASS;
- release DMG, security, Sandbox-only entitlement, Hardened Runtime, signing, shipping preflight, combined size gate and performance smoke PASS.

The protocol-runtime testability refactor itself followed a separate RED `3b79448697d614b7f022009653eca655a31bad4f` / CI #1096 -> GREEN `f49f94d5ab51dcec5dccb97b6c0997ec631b1261` / CI #1099. `MediaGestureSession` now accepts `MediaRuntimeSession`; shipping composition remains the only concrete `ShippingMediaRuntime` creator, while deterministic UI runtime can traverse the same expanded command/seek seam under test compilation.

This docs sync changes the source SHA; physical testing must use the new docs-synchronized head only after its fresh CI passes.

## Physical rejection and repair cycles

### Stationary startup hover

Candidate `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945 passed automation but failed target acceptance when relaunching with a stationary pointer already on the physical notch. Root cause was deterministic startup activation suppression in `show()`.

- RED `553cf973722dfb214f0fcb741ddb6c9b0b44ff02` / CI #947 reproduced it;
- GREEN `d17bd27be72c8c3bd022fb2c3613050c398c622e` / CI #948 removed only that suppression.

### Expanded pointer exit / interactive lost terminal

Candidate `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951 passed automation but failed target testing:

- expanded remained open after the pointer left;
- physical UP could leave an intermediate clipped frame if shrinking geometry moved away from the pointer before local scroll delivered `.ended`/`.cancelled`;
- hover/haptic/Peek was also absent in the observed broken session and remains an independent retest condition.

Focused RED `0a42a701fcf4fa2f59972a68d2a3b9243203a202` / CI #959 proved exactly five new regression failures while the previous suite passed. GREEN `64d3e6c2beadacaeda69c8ac06f173ac26aace3e` restored pointer-exit semantics and synchronous actual-frame settlement. Current native XCUI and strict regression coverage preserve the repaired deterministic paths.

The repair uses existing local precise-scroll events and existing mouse-move observation. It adds no global scroll monitor, event tap, repeating watchdog, polling loop, display link or sensitive input authority.

## Required target retest

Use one exact docs-synchronized CI-produced candidate. Do not mix binaries or source SHAs between checks.

Run the focused blocker block first:

1. from stable compact with usable media, deliberate hover opens Peek after 120 ms and produces the expected Peek haptic; hover alone never opens full expanded Home;
2. stationary relaunch on the notch behaves the same without requiring extra mouse movement;
3. DOWN -> expanded, then plain pointer exit from expanded retention returns non-haptically to exact compact;
4. expanded UP while shrinking geometry moves away from a stationary pointer still settles to exact compact, never an intermediate frame;
5. expanded UP with deliberate pointer movement outside during the owned gesture also settles exact compact;
6. compact DOWN with early pointer/panel separation fails safe to compact rather than remaining partially expanded;
7. repeat the block several times to catch stale ownership.

Only after this focused block passes continue the remaining M6.6 matrix: 140 ms Peek grace, LEFT/RIGHT/haptic semantics, seek/cursor/source-change cancellation, media continuity/source icon, sensitive permission prompts and process lifecycle.

For lifecycle checks:

```bash
pgrep -lf 'mediaremote-adapter\.pl' || true
```

Expected: settled compact and settled Peek are empty; settled expanded may own exactly the expected adapter; normal Quit returns to empty.

## Performance boundary

`performance/baseline-v0.1.0.json` is immutable historical evidence. Historical M6 and regression-foundation budgets are also immutable provenance records.

The active cumulative integration envelope is `performance/m6-6-regression-foundation-integration-size-budget.json`, derived from exact shipping candidate source `452f78b0e42c5302702393e9c45c563849661ca4`, CI #1089 / run `31869841148`, artifact `9243156724`:

- measured app `882687 B`, DMG `552272 B`, executable `580480 B`;
- allowances over the immutable baseline: app `614400 B`, DMG `462848 B`, executable `315392 B`;
- allowances are page-rounded and fail-closed; older feature envelopes are not active CI budgets.

Shared-runner CPU/RSS magnitudes are compatibility evidence, not target-Mac acceptance. P1 target resource review begins only after M6.6 physical acceptance and merge.
