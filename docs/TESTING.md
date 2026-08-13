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

M1 notch/hover/haptic/animation and M6.1-M6.5 media contracts are physically accepted on the primary target as recorded in their ledgers. M6.6 remains physically unaccepted. In particular, expanded pointer-exit auto-collapse is an accepted M1 invariant and must not be weakened by M6.6.

## M6.6 current automated coverage

Stable contracts:

- `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`;
- `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`;
- `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`.

Current tests/policy cover gesture semantics, compact/Peek bounded one-shot lifecycle, local scroll composition, physical-axis normalization, stable presentation ownership, 120 ms Hover Peek, 140 ms Peek grace, explicit expansion, transition authority, source icon, seek/cursor isolation, event-driven continuity, zero persistent compact/Peek adapter ownership and existing Sandbox/Hardened Runtime/security boundaries.

## Physical rejection and repair cycles

### Stationary startup hover

Candidate `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945 passed automation but failed target acceptance when relaunching with a stationary pointer already on the physical notch. Root cause was deterministic startup activation suppression in `show()`.

- RED `553cf973722dfb214f0fcb741ddb6c9b0b44ff02` / CI #947: 328 tests / 68 suites with exactly the new stationary-startup regression failing;
- GREEN `d17bd27be72c8c3bd022fb2c3613050c398c622e` / CI #948: both required jobs PASS with 328 tests and all policy/security/package gates.

### Expanded pointer exit / interactive lost terminal

Exact candidate `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951 passed automation but failed target testing:

- expanded remained open after the pointer left;
- physical UP could leave an intermediate clipped frame if shrinking geometry moved away from the pointer before local scroll delivered `.ended`/`.cancelled`;
- hover/haptic/Peek was also absent in the observed broken session and remains an independent retest condition.

The first failure was a regression in PR #33: expanded pointer policy had been changed from accepted M1 auto-collapse to unconditional expanded retention. The second exposed an ownership gap because interactive settlement depended only on terminal local scroll delivery.

Focused deterministic regression coverage was added for:

1. expanded pointer outside retention -> compact;
2. expanded pointer exit -> non-haptic collapse intent;
3. pointer exit during interactive collapse -> retarget to stable compact;
4. pointer exit during interactive expansion -> return to stable compact;
5. local interactive path -> pass current pointer and settle when actual visible `panel.frame` leaves it without adding global scroll capture.

TDD evidence:

- clean RED `0a42a701fcf4fa2f59972a68d2a3b9243203a202` / CI #959: **333 tests / 69 suites**, exactly the five new regression tests failed; the prior suite passed;
- production GREEN `64d3e6c2beadacaeda69c8ac06f173ac26aace3e`;
- CI #960 proved the functional test suite green but the packaging job stopped on two strict-format warnings in the new test file only;
- format-only `de5624b7d344e15772fdf0759fbe4b5027a5b1d4` / CI #961: **both required jobs PASS; 333 tests / 69 suites PASS**, including all five regression tests, strict source/security/performance/media checks, Sandbox/Hardened Runtime/signing, shipping preflight, active size enforcement and performance smoke.

The repair uses existing local precise-scroll events and existing mouse-move observation. It adds no global scroll monitor, event tap, repeating watchdog, polling loop, display link or sensitive input authority.

## Required target retest

Use one exact docs-synchronized CI-produced candidate.

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

`performance/baseline-v0.1.0.json` is immutable historical evidence. Current active feature envelope remains `performance/m6-6-hover-peek-size-budget.json`. Shared-runner CPU/RSS magnitudes are compatibility evidence, not target-Mac acceptance.

P1 target resource review begins only after M6.6 physical acceptance and merge.
