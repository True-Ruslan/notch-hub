# Testing

## Goal

Automate every deterministic behavior that can be validated reliably. Manual acceptance is reserved for physical notch geometry, real pointer feel, exact macOS trust/permission surfaces, third-party app integration, and other behavior CI cannot honestly reproduce.

A green pipeline is necessary but is not proof of real-device UX. Conversely, manual success never replaces deterministic automated coverage that can reasonably exist.

## Required CI gate

Protected-branch check: `Build, test and package`, dependent on `macOS 26 compatibility`.

Current CI validates:

1. Swift package structure.
2. deterministic Personal/Trusted release-policy unit/static tests.
3. project-configured strict Swift formatting.
4. shell/plist syntax.
5. executable repository security baseline (`scripts/security-audit.sh`).
6. macOS 26 compilation with warnings as errors.
7. macOS 26 complete Swift test suite.
8. packaging-runner compilation with warnings as errors.
9. complete Swift tests with coverage instrumentation.
10. release app/DMG packaging.
11. semantic version/build-number stamping.
12. ad-hoc code-signature verification.
13. Hardened Runtime verification.
14. exact effective App Sandbox entitlement verification.
15. linked-library inspection (system libraries only at the current milestone).
16. DMG integrity with `hdiutil verify`.
17. artifact upload.

Do not lower assertions, delete useful tests, weaken security/release policy, or weaken production behavior merely to make CI green.

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
- explicit Personal/Trusted release-tier boundaries and immutable release assets.

Future capabilities that legitimately require a currently forbidden surface must update policy and tests explicitly in the same reviewed PR.

## Test design

Prefer pure deterministic policies for geometry, parsing, permissions, state, transitions, release rules, time-dependent interaction decisions, and AppKit/SwiftUI boundary configuration. AppKit/SwiftUI/GitHub orchestration should be thin around tested policies.

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

## Personal Release TDD evidence

PR #3 records release-policy RED/GREEN evidence independently from app runtime:

- initial release policy tests failed because `release_policy.py` was absent;
- first implementation exposed and fixed a false-positive Gatekeeper rule (`Do not disable Gatekeeper` must be allowed while actual bypass instructions are forbidden);
- versioned release-note integration test failed until `docs/releases/v0.1.0.md` existed;
- Personal Release workflow contract failed until `.github/workflows/personal-release.yml` existed;
- tier-separation test failed until `trusted-release.yml` existed and legacy `release.yml` was removed;
- trust-boundary tests failed until the executable workflow validator existed;
- final Trusted pre-publish recheck received an additional RED-first fail-closed regression test before its fix.

`v0.1.0` Personal Release has been published from the accepted `main` commit. `NH-PERSONAL-RELEASE-001` remains pending until the downloaded GitHub Release DMG is accepted on the target MacBook.
