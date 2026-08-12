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
- `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`.

Current tests/policy prove:

- pure threshold/hysteresis/momentum/diagonal/captured-axis semantics;
- compact one-shot capability generation/freshness and lifecycle ownership;
- local-only scroll composition, with no global/local event-monitor registration or event tap;
- physical input normalization independent of macOS scroll-direction preference;
- physical RIGHT -> previous / LEFT -> next and DOWN -> expand / UP -> collapse semantics;
- media wings do not expand the hover activation region;
- precise local gesture preflight cancels pending hover dwell;
- Core remains the sole panel transition/frame authority;
- interactive geometry interpolation, cancel/commit, retarget and stale-generation safety;
- source bundle identity propagation and bounded public `NSWorkspace` icon lookup;
- capability-gated seek and invalid-number fail-closed behavior;
- seek transaction identity locking across track/source changes;
- seek-active suppression of track/panel gestures;
- bounded visual continuity with no polling/timer/display-link;
- historical size budgets remain immutable/provenanced and active repair growth uses its own envelope;
- App Sandbox-only, Hardened Runtime, fixed media process trust boundary and no new sensitive authority.

## Physical repair history

First complete candidate `d008f698b323963f084eedce601620ee957ef442` / CI #872 was not accepted. Target testing exposed hover/compact gesture arbitration, vertical physical direction, stale seek across track/source change and visual continuity issues.

Repair TDD evidence is recorded in `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`. Pre-docs repair head `6403dae0e33281f6dcd5bcbd79ec5147b6580c0a` passed CI #883 in both jobs after clean functional and size-policy RED cycles.

## Required target retest

On the exact final candidate:

- short/reversed horizontal gesture: no command/haptic/stuck visual state;
- compact RIGHT previous and LEFT next before hover can steal input;
- expanded RIGHT previous and LEFT next with smooth visual reset;
- compact physical DOWN expands, expanded physical UP collapses;
- diagonal/momentum/re-arm behavior;
- seek only when supported;
- seek drag cancelled by track/source/capability change; release must not seek the new track;
- hover regression;
- source icon for Yandex Music and Yandex Browser/Chromium plus truthful fallback when encountered;
- no Accessibility/Input Monitoring/Automation/Screen Recording prompt;
- settled compact/cancelled compact expansion/normal Quit process ownership.

For lifecycle checks:

```bash
pgrep -lf 'mediaremote-adapter\.pl' || true
```

Expected after compact work and after Quit: empty output.

## Performance boundary

`performance/baseline-v0.1.0.json` is immutable historical evidence. Intentional shipping growth gets a separate provenance-backed cumulative envelope; previous budget files are not rewritten. Shared-runner CPU/RSS magnitudes are compatibility evidence, not target-Mac acceptance.

Current active feature envelope: `performance/m6-6-physical-acceptance-repair-size-budget.json`.

P1 target resource review begins only after M6.6 acceptance/merge.
