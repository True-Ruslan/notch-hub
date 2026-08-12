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

M1 notch/hover/haptic/animation and M6.1-M6.5 media contracts are physically accepted on the primary target as recorded in their ledgers. M6.6 Task 0 was also physically accepted; pure/lifecycle prerequisites that added no user-facing behavior were automated-accepted before merge.

## M6.6 current automated coverage

Stable contracts:

- `docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`;
- `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`;
- `docs/testing/MEDIA_PEEK_ACCEPTANCE.md`.

Current tests/policy prove:

- pure threshold/hysteresis/momentum/diagonal/captured-axis semantics;
- compact one-shot capability generation/freshness and lifecycle ownership;
- local-only scroll composition, with no global/local scroll event-monitor registration or event tap;
- physical input normalization independent of macOS scroll-direction preference;
- physical RIGHT -> previous / LEFT -> next and DOWN -> expand / expanded UP -> compact semantics;
- stable `compact`, `peek`, `expanded` presentation ownership;
- 120 ms hover dwell to media-only Peek and 140 ms Peek exit grace;
- no-media and fast-transit hover fail closed to compact;
- click/physical DOWN explicit expansion without hover opening full expanded UI;
- media wings do not expand the hover activation region;
- precise local gesture preflight cancels pending hover dwell;
- Core remains the sole panel transition/frame authority;
- interactive geometry interpolation, cancel/commit, retarget and stale-generation safety;
- source bundle identity propagation and bounded public `NSWorkspace` icon lookup;
- bounded one-shot Peek media probing and commands without persistent observation;
- capability-gated seek in Peek and expanded plus invalid-number fail-closed behavior;
- seek transaction identity locking across track/source changes;
- seek-active suppression of track/panel gestures;
- cursor visibility ownership is balanced and adds no pointer warp/lock/global authority;
- bounded visual continuity with no polling/timer/display-link;
- compact and settled Peek own zero persistent adapter by policy; expanded remains the only persistent runtime state;
- App Sandbox-only, Hardened Runtime, fixed media process trust boundary and no new sensitive authority.

## Physical repair and Hover Peek policy history

First complete candidate `d008f698b323963f084eedce601620ee957ef442` / CI #872 was not accepted. Target testing exposed hover/compact gesture arbitration, vertical physical direction, stale seek across track/source change and visual continuity issues.

Those defects were repaired under focused RED -> GREEN cycles; repair size policy became green in CI #883.

Hover Peek then added intentional shipping growth and a broader acceptance matrix. The size-policy cycle is independently proven:

- evidence head `7daffde9b7c2a734e2ddfa234b1ee744b0d96d9e` / CI #939 passed functional/security/signing/preflight checks and measured executable/app/DMG `562,368 / 864,574 / 555,272 B`; only the previous repair envelope failed;
- `4bc15c4757727922817b4aaac35c7991c852019a` / CI #940 is the required RED: 327 tests / 68 suites and exactly the missing Hover Peek budget failed;
- `performance/m6-6-hover-peek-size-budget.json` is provenance-bound to CI #939 evidence; all older feature budgets remain immutable historical records;
- `745baa55b7a53519b3832f21305fa9c357ce05fa` / CI #944 is the pre-docs GREEN: both required jobs passed, including 327 Swift tests, policy/security/signing/preflight, active size enforcement and performance smoke.

## Required target retest

Use one exact docs-synchronized CI-produced candidate for all applicable gates.

At minimum verify:

- 120 ms hover opens Peek only when usable media exists; no-media hover stays compact and fast transit leaves no stuck Peek;
- 140 ms Peek exit/re-entry grace;
- short/reversed horizontal gesture: no command/haptic/stuck visual state;
- compact/Peek/expanded RIGHT previous and LEFT next where applicable without hover stealing input;
- click and physical DOWN explicitly expand; compact/Peek DOWN and expanded UP preserve follow-finger continuity;
- diagonal/momentum/re-arm behavior;
- seek only when supported, including Peek seek;
- seek drag cancelled by track/source/capability change; release must not seek the new track;
- cursor restored after seek commit/cancel/source change/app resign/invalidation/Quit;
- media/track continuity without obvious Home/interface blink while media remains valid;
- source icon for Yandex Music and Yandex Browser/Chromium plus truthful fallback when encountered;
- no Accessibility/Input Monitoring/Automation/Screen Recording prompt;
- process ownership for settled compact, settled Peek, settled expanded, cancelled expansion and normal Quit.

For lifecycle checks:

```bash
pgrep -lf 'mediaremote-adapter\.pl' || true
```

Expected: settled compact and settled Peek are empty; settled expanded may own exactly the expected adapter; normal Quit returns to empty.

## Performance boundary

`performance/baseline-v0.1.0.json` is immutable historical evidence. Intentional shipping growth gets a separate provenance-backed cumulative envelope; previous budget files are not rewritten. Shared-runner CPU/RSS magnitudes are compatibility evidence, not target-Mac acceptance.

Current active feature envelope: `performance/m6-6-hover-peek-size-budget.json`.

P1 target resource review begins only after M6.6 physical acceptance and merge.
