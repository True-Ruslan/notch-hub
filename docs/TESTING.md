# Testing

## Goal

Automate every deterministic behavior that can be validated reliably. Manual acceptance is reserved for physical notch geometry, real pointer feel, exact macOS trust/permission surfaces, third-party app integration, target-hardware resource measurements, and other behavior CI cannot honestly reproduce.

A green pipeline is necessary but is not proof of real-device UX or target-Mac efficiency. Conversely, manual success never replaces deterministic automated coverage that can reasonably exist.

## Required CI gate

Protected-branch check: `Build, test and package`, dependent on `macOS 26 compatibility`.

Current CI validates:

1. Swift package structure.
2. deterministic Personal/Trusted release-policy unit/static tests.
3. deterministic performance-policy/parser/aggregation tests.
4. project-configured strict Swift formatting.
5. shell/plist syntax.
6. executable repository security baseline (`scripts/security-audit.sh`).
7. deterministic runtime performance-policy audit (`scripts/performance_policy.py audit Sources`).
8. macOS 26 compilation with warnings as errors.
9. macOS 26 complete Swift test suite.
10. packaging-runner compilation with warnings as errors.
11. complete Swift tests with coverage instrumentation, including deterministic state-stress coverage.
12. release app/DMG packaging.
13. semantic version/build-number stamping.
14. ad-hoc code-signature verification.
15. Hardened Runtime verification.
16. exact effective App Sandbox entitlement verification.
17. linked-library inspection (system libraries only at the current milestone).
18. DMG integrity with `hdiutil verify`.
19. short development-harness compatibility/schema smoke on a shared runner, with no CPU/RAM magnitude gate.
20. artifact upload.

Do not lower assertions, delete useful tests, weaken security/release/performance policy, or weaken production behavior merely to make CI green.

## Release-policy test boundary

`scripts/test_release_policy.py` and `scripts/release_policy.py` cover deterministic distribution rules:

- strict release SemVer/tag derivation;
- versioned Personal Release notes exist and lead with the mandatory not-notarized warning;
- unsafe Gatekeeper-bypass instructions are rejected;
- provenance/build metadata has an exact schema and validated source/checksum/size inputs;
- Personal Release requires manual `main` publication, ad-hoc signature verification, Sandbox/Hardened Runtime, checksum/provenance, and immutable `gh release create` semantics;
- Personal Release rejects Apple signing/notary secrets, `environment: release`, `--clobber`, release uploads, or Gatekeeper-bypass commands;
- Trusted Release remains a separate Developer ID/notarization tier;
- ambiguous legacy `release.yml` is prohibited.

The same Personal Release boundary is rechecked by `scripts/security-audit.sh` so a workflow cannot bypass unit tests simply by being omitted from the normal test command.

## Security test boundary

The executable security baseline verifies, among other things:

- zero external Swift runtime dependencies;
- no runtime subprocess/shell execution APIs;
- no direct network/WebKit surface;
- no dynamic code loading/private-symbol bridging primitives;
- no global keyboard/button/drag/scroll/modifier monitoring;
- no embedded common credential/private-key formats;
- exactly the expected sandbox entitlement set;
- no dangerous Hardened Runtime exception entitlements;
- no LaunchAgents/LaunchDaemons/privileged-helper surfaces;
- immutable full-SHA GitHub Action references;
- no `pull_request_target` workflows;
- explicit Personal/Trusted release-tier boundaries and immutable release assets;
- performance measurement tooling remains development-only and is not copied/referenced into the application bundle.

Future capabilities that legitimately require a currently forbidden surface must update policy and tests explicitly in the same reviewed PR.

## Performance test boundary

`PERFORMANCE.md` is authoritative for runtime resource policy, accepted target-Mac values, budgets, and methodology.

`scripts/test_performance_policy.py` and `scripts/performance_policy.py` deterministically cover:

- forbidden unreviewed polling/timer/sleep/display-link primitives in runtime Swift sources;
- strict `/bin/ps` CPU/RSS/thread sample parsing;
- Darwin `ps -M` thread-row parsing;
- median/max aggregation without inventing empty measurements;
- stability start/end/quartile evidence;
- baseline-harness configuration validation;
- deterministic budget comparison and malformed/non-finite input rejection.

`scripts/perf-baseline.py` is development/release tooling only. CI runs only a short compatibility/schema smoke and must not enforce runner CPU/RSS/thread values. Canonical runtime values come from the target MacBook/macOS 26.6 under the stable scenarios below.

## Test design

Prefer pure deterministic policies for geometry, parsing, permissions, state, transitions, release rules, resource-policy rules, time-dependent interaction decisions, and AppKit/SwiftUI boundary configuration. AppKit/SwiftUI/GitHub orchestration should be thin around tested policies.

Tests should:

- state one behavior in the name;
- assert externally meaningful results;
- avoid mocks unless an OS/third-party boundary cannot reasonably be exercised;
- avoid arbitrary sleeps in unit tests;
- include boundary/error/denied cases;
- reproduce reported deterministic regressions before fixes where practical;
- never fabricate a RED phase if a behavior is already correctly testable;
- prefer deterministic fake adapters around external boundaries over live services;
- inject a monotonic clock/scheduler for dwell/debounce behavior instead of waiting in real time;
- inject a haptic output abstraction so tests assert request count/reason without requiring physical trackpad vibration;
- never use noisy shared-runner timing values as tight performance gates.

No arbitrary global code-coverage percentage is used. Coverage instrumentation is enabled to find untested deterministic logic; component-specific thresholds may be introduced only where they remain meaningful.

## P0 performance contracts

| ID | Scenario | Expected result | Automation |
| --- | --- | --- | --- |
| `NH-PERF-IDLE-001` | Accepted Personal Release, 10 s warmup then untouched compact mode for 60 s sampled every 1 s | Stable idle CPU/RSS/thread summary; no app-initiated periodic work discovered by policy/review | Sampling automated on target Mac; interaction/manual environment control |
| `NH-PERF-HOVER-001` | 60 s sampler while repeating documented 5-second expand/retain/collapse cycle | Active summary captured without synthesized input; accepted hover behavior remains intact | Sampling automated; interaction manual |
| `NH-PERF-STABILITY-001` | 10 min untouched run sampled every 5 s | No unexplained sustained RSS/thread growth | Sampling automated on target Mac; interpretation reviewed |
| `NH-PERF-SIZE-001` | Accepted release executable/app/DMG | Exact byte sizes recorded in canonical baseline | Deterministic local/release metadata |
| `NH-PERF-STATE-001` | Exactly 100,000 pure pointer/presentation decisions | Correct final/count invariants with no retained history/state growth API; no wall-clock assertion | Fully automated Swift test |

Runtime baseline values and initial target-Mac ceilings are now documented in `PERFORMANCE.md`. Shared runner CPU/RAM/thread values are never substituted for this acceptance. The canonical `performance/baseline-v0.1.0.json` remains intentionally absent until exact immutable-release size metadata is incorporated.

## M1 delayed-hover and haptic contract

Authoritative interaction specification: `docs/specs/M1_NOTCH_INTERACTION.md`.

Before implementation, RED-first tests must prove at minimum:

- pointer transit shorter than the dwell threshold does not expand and emits zero haptic requests;
- deliberate hover expands only when the threshold completes;
- one successful user-initiated `compact -> expanded` transition emits exactly one haptic request;
- repeated `mouseMoved` events do not create duplicate pending work or duplicate haptics;
- a cancelled dwell cannot fire later from a stale callback;
- re-entry starts a fresh dwell instead of reusing elapsed time;
- expanded retention does not retrigger haptic feedback;
- collapse followed by a new deliberate hover may produce one new haptic;
- controller teardown/state invalidation cancels pending dwell work.

The implementation must remain event-driven: no polling, no repeating timer, and at most one pending activation task/timer. Physical haptic feel remains a real-device acceptance concern because macOS may legitimately suppress trackpad feedback depending on current hardware, touch state, accessibility, and user preferences.

## Real-hardware / distribution acceptance matrix

Record results in `docs/PROJECT_STATE.md`.

| ID | Scenario | Expected result | Automation |
| --- | --- | --- | --- |
| `NH-BOOT-001` | Install/open CI-produced DMG | App launches and panel appears | Packaging automated; launch UX manual |
| `NH-OS26-001` | Run accepted test build on target macOS 26.6 | App launches, sandboxed runtime works, no unexpected permission prompt | macOS 26 CI automated; exact 26.6 hardware manual |
| `NH-NOTCH-001` | Observe compact panel on hardware-notch MacBook | Center/width match physical notch | Geometry unit-tested; physical alignment manual |
| `NH-HOVER-001` | Enter compact activation region and hold >=3 s | One expansion; no oscillation | Pointer policy unit-tested; AppKit delivery manual |
| `NH-HOVER-002` | Move within expanded panel | Remains expanded | Retention unit-tested; AppKit delivery manual |
| `NH-HOVER-003` | Move outside retention region | Content and actual panel frame collapse once and remain compact | Policy/sizing ownership automated; physical window behavior manual |
| `NH-SANDBOX-001` | Exercise normal panel in Sandbox build | No crash/unexpected permission/loss of behavior | Entitlement/signing automated; runtime manual |
| `NH-PERSONAL-RELEASE-001` | Download versioned Personal Release from GitHub | Published SHA-256 matches; installation uses only standard Finder / Privacy & Security approval; app opens on macOS 26.6; accepted notch/hover scenarios remain PASS | Release policy/checksum/provenance automated; downloaded quarantine/trust path + hardware behavior manual once for first personal pipeline/version |
| `NH-HOVER-DELAY-001` | Move pointer through notch toward another display without intentionally stopping | Transit completes before dwell threshold; panel stays compact; zero haptic feedback | Deterministic injected-clock cancellation test; real cross-display pointer feel manual |
| `NH-HOVER-DELAY-002` | Deliberately hover over compact notch | Panel expands once after a short perceptible-but-fast dwell, with no flicker/oscillation | State/time policy automated; final dwell tuning manual |
| `NH-HAPTIC-001` | Deliberately hover using a compatible Force Touch trackpad while touching it | Exactly one short tactile event accompanies the successful expansion | Haptic request count/reason automated through fake performer; physical tactile result manual |
| `NH-HAPTIC-002` | Quick/cancelled hover, retention movement, and collapse | No haptic feedback | Deterministic policy/output tests automated; physical negative check manual |
| `NH-GATEKEEPER-TRUSTED-001` | Future: download Trusted Release | Gatekeeper identifies `Notarized Developer ID` without personal-build approval workaround | Trusted workflow automated; normal downloaded path manual when tier is first adopted |
| `NH-SPACE-001` | Switch Spaces/fullscreen | Behavior matches M1 policy | Planned M1 |
| `NH-DISPLAY-001` | Connect/move between displays | Correct target-display geometry/migration | Planned M1 |

## Acceptance history

### 2026-08-07 — cycle 1

- `NH-BOOT-001`: PASS enough to run application.
- `NH-HOVER-001`: FAIL — compact/expanded oscillation.
- RED `eb4fb4d`: expected failing retention regression.
- GREEN `eff9bde`: raw SwiftUI hover authority replaced by deterministic screen-space policy.

### 2026-08-07 — cycle 2

Target MacBook/macOS 26.6:

- `NH-OS26-001`: PASS.
- `NH-NOTCH-001`: FAIL — compact panel a few pixels too wide.
- `NH-HOVER-001`: PASS.
- `NH-HOVER-002`: PASS.
- `NH-HOVER-003`: FAIL — compact content while expanded black panel frame remained.
- `NH-SANDBOX-001`: earlier report was inferred as PASS by matrix order because the source message repeated the last label; that ambiguity remains documented rather than rewritten.

RED `c518326` produced exactly the two intended CI failures (`180` vs `176`; hosting sizing options `7` vs empty). GREEN `3bb1bbb` fixed both. CI then reached **10/10 PASS** plus full security/package gates.

### 2026-08-07 — cycle 3 / M0 final acceptance

Target MacBook/macOS 26.6:

- `NH-NOTCH-001`: **PASS**.
- `NH-HOVER-001`: **PASS**.
- `NH-HOVER-002`: **PASS**.
- `NH-HOVER-003`: **PASS**.

**M0 mandatory physical acceptance: PASS.**

### 2026-08-07 — cycle 4 / Personal Release acceptance

Downloaded immutable GitHub Personal Release `v0.1.0` on the target MacBook/macOS 26.6:

- `NH-PERSONAL-RELEASE-001`: **PASS**.
- published checksum/install/standard macOS first-launch path: **PASS**;
- application launch: **PASS**;
- accepted `NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, `NH-HOVER-003` behavior on the downloaded release: **PASS**.

**R0.1 Personal Release acceptance: PASS.**

### 2026-08-07 — cycle 5 / P0 runtime baseline

Accepted Personal Release `v0.1.0` (`8e913dcddfdec7d9aa920df8c37afb23b8c40884`) on target macOS 26.6 / `Mac16,8`, measured using P0 tooling commit `dfd4f87f8e5be04b467172d720d22bfc054c06d0`:

- `NH-PERF-IDLE-001`: **BASELINE ACCEPTED** — 60 samples / `60.017 s`; CPU median/max `0.0% / 0.7%`; RSS median/max `33,648 / 33,808 KiB`; threads `4 / 4`;
- `NH-PERF-HOVER-001`: **BASELINE ACCEPTED** — 60 samples / `60.018 s`; CPU median/max `5.95% / 22.3%`; RSS median/max `38,456 / 38,816 KiB`; threads `6 / 7`;
- `NH-PERF-STABILITY-001`: **BASELINE ACCEPTED** — 120 samples / `600.013 s`; CPU median/max `0.0% / 6.8%`; RSS median/max `30,992 / 34,384 KiB`; threads `3 / 7`;
- stability RSS `34,256 -> 30,544 KiB`, delta `-3,712 KiB`: **no sustained RSS growth detected**;
- stability threads `4 -> 5`, max `7`: bounded transient behavior; no runaway thread accumulation detected.

Initial target-Mac CPU/RSS/thread ceilings are recorded in `PERFORMANCE.md` with conservative headroom and are not used as shared-runner CI thresholds.

`NH-PERF-SIZE-001` remains pending exact immutable-release `build-metadata.json` values before the canonical baseline JSON and deterministic size gate can be finalized.

## Personal Release TDD evidence

PR #3 records release-policy RED/GREEN evidence independently from app runtime:

- initial release policy tests failed because `release_policy.py` was absent;
- first implementation exposed and fixed a false-positive Gatekeeper rule (`Do not disable Gatekeeper` must be allowed while actual bypass instructions are forbidden);
- versioned release-note integration test failed until `docs/releases/v0.1.0.md` existed;
- Personal Release workflow contract failed until `.github/workflows/personal-release.yml` existed;
- tier-separation test failed until `trusted-release.yml` existed and legacy `release.yml` was removed;
- trust-boundary tests failed until the executable workflow validator existed;
- final Trusted pre-publish recheck received an additional RED-first fail-closed regression test before its fix.

`v0.1.0` Personal Release was published from accepted `main` and subsequently passed `NH-PERSONAL-RELEASE-001` on the target MacBook/macOS 26.6.
