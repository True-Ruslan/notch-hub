# Testing

## Policy

Automate every deterministic behavior that can be validated reliably. Manual acceptance is reserved for physical notch geometry, real pointer/trackpad feel, compositor continuity, haptic feel, macOS permission/trust surfaces, third-party integration and target-hardware resources.

A green pipeline is necessary but never substitutes for target-Mac acceptance. Manual success never substitutes for reproducible automated coverage.

## Required CI

Protected-branch checks:

- `macOS 26 compatibility`;
- `Build, test and package`.

CI covers warnings-as-errors builds, Swift tests, release/security/performance/media policy, strict formatting/plist/shell checks, Sandbox/Hardened Runtime/signing/system-library verification, shipping media preflight, deterministic artifact sizes, active provenance-backed feature budget, performance-harness schema smoke and artifacts.

Do not weaken tests, security rules, production behavior or historical baselines merely to obtain green CI.

## TDD rule

For production behavior:

1. add a focused regression test;
2. preserve a RED run proving the intended missing behavior;
3. implement the minimum GREEN change;
4. run full CI/security/performance verification;
5. only then advance to another independent defect.

Race, stale-callback, boundary and teardown behavior must be tested deterministically without arbitrary sleeps where practical.

## Accepted physical foundations

M1 notch/hover/haptic/animation and M6.1-M6.5 media contracts are physically accepted on the primary target as recorded in their ledgers. M6.6 remains physically unaccepted.

## M6.6 current automated coverage

Stable contracts:

- `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`;
- `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`;
- `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`.

Current tests/policy cover gesture semantics, compact/Peek bounded one-shot lifecycle, local scroll composition, physical-axis normalization, stable `compact`/`peek`/`expanded` ownership, 120 ms dwell, 140 ms grace, explicit expansion, transition authority, source icon, seek/cursor isolation, event-driven continuity, zero persistent compact/Peek adapter ownership and existing Sandbox/Hardened Runtime/security boundaries.

## Physical rejection and stationary-startup repair

Candidate `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945 passed automation but was rejected during target-Mac Hover Peek acceptance.

Confirmed defect: after relaunch while the cursor was already stationary on the physical notch, Peek could fail to open indefinitely. Root cause was deterministic: `NotchPanelController.show()` explicitly passed `allowActivation: false` when synchronizing `NSEvent.mouseLocation`; without a subsequent `mouseMoved`, the 120 ms dwell was never scheduled.

The repair followed the required TDD sequence:

- test-only RED `553cf973722dfb214f0fcb741ddb6c9b0b44ff02` / CI #947: warnings-as-errors build PASS; 328 tests / 68 suites; exactly `showKeepsStationaryPointerEligibleForHoverDwell` failed;
- minimum GREEN `d17bd27be72c8c3bd022fb2c3613050c398c622e`: removed only the startup activation suppression;
- CI #948 / run `31645020620`: both required jobs PASS; 328 tests PASS; release/security/performance/media policy, Sandbox/Hardened Runtime/signing, shipping preflight, active size enforcement and performance smoke all PASS;
- CI #948 sizes `562,368 / 864,574 / 555,281 B`, still within `performance/m6-6-hover-peek-size-budget.json`.

No new polling, repeating timer, event monitor, process boundary or sensitive input authority was introduced by the repair.

A full-expanded Home/foundation surface was also observed during the rejected physical sequence. This is recorded as an unresolved observation, not silently attributed to the stationary-startup bug. Positive hover resolution in current source requests Peek only. The next target retest must explicitly verify that hover alone never reaches expanded; if it does without click/DOWN, capture the exact sequence and start a separate RED -> GREEN cycle.

## Required target retest

Use one exact docs-synchronized CI-produced candidate.

First run the focused blocker check:

1. normal media hover opens Peek after dwell, not expanded;
2. quit/relaunch while the pointer is already stationary inside the physical notch; after the same dwell Peek opens without extra movement;
3. repeat normal/restart hover several times; hover alone never shows full expanded Home;
4. fast transit and pointer exit do not leave a stuck presentation.

Only after this focused block passes continue the remaining M6.6 matrix: 140 ms grace, LEFT/RIGHT/haptic, click/DOWN/UP, seek/cursor/source-change cancellation, media continuity/source icon, no sensitive permission prompts, and lifecycle ownership.

For lifecycle checks:

```bash
pgrep -lf 'mediaremote-adapter\.pl' || true
```

Expected: settled compact and settled Peek are empty; settled expanded may own exactly the expected adapter; normal Quit returns to empty.

## Performance boundary

`performance/baseline-v0.1.0.json` is immutable historical evidence. Current active feature envelope remains `performance/m6-6-hover-peek-size-budget.json`. Shared-runner CPU/RSS magnitudes are compatibility evidence, not target-Mac acceptance.

P1 target resource review begins only after M6.6 physical acceptance and merge.
