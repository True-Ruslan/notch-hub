# Project state

Last updated: 2026-08-07
Current version: `0.1.0` (Personal Release published and accepted)
Primary physical target: macOS `26.6`
Protected branch: `main`
Current implementation PR: #5 `Performance Foundation`

## Product

NotchHub is a personal, native, local-first macOS productivity hub built around the MacBook notch. Planned modules are Shelf, Snippets, Calendar, Translator, and media controls with Yandex Music as the primary player.

NotchNook is a public product/UI research reference only; NotchHub remains an independent implementation.

## Accepted foundation

**M0 — Engineering foundation: ACCEPTED and merged.**

Real-hardware final acceptance on the target MacBook/macOS 26.6:

- `NH-OS26-001`: PASS from the earlier sandbox/Hardened Runtime cycle;
- `NH-NOTCH-001`: PASS;
- `NH-HOVER-001`: PASS;
- `NH-HOVER-002`: PASS;
- `NH-HOVER-003`: PASS.

M0 includes:

- Swift 6 / SwiftUI + AppKit native app shell;
- public-API hardware-notch geometry and exact physical width;
- explicit compact/expanded panel state;
- deterministic pointer activation/retention policy;
- AppKit-owned panel geometry (`NSHostingView.sizingOptions = []`);
- App Sandbox + Hardened Runtime;
- zero third-party Swift runtime dependencies;
- no direct runtime network/WebKit, subprocess/shell, dynamic loading, telemetry, or broad global input monitoring;
- global observation restricted to `mouseMoved` only;
- strict CI, macOS 26 compatibility, warnings-as-errors, security audit, Swift regression tests, release DMG packaging/integrity checks;
- RED→GREEN evidence for both real-hardware defect cycles.

M0 integration PR #1 was squash-merged. Approved Personal Release + Performance Foundation design/plans were subsequently merged through docs PR #2.

## R0.1 Personal Release

Status: **ACCEPTED**.

The Apple Developer Program dependency is intentionally deferred because NotchHub is currently personal-use software. This is a deliberate product decision, not an accidental missing credential.

Current supported versioned distribution is **Personal Release**:

- manual GitHub Actions publication from exact protected `main`;
- ad-hoc app signature;
- App Sandbox and Hardened Runtime mandatory;
- complete correctness/security CI rerun before publication;
- SHA-256 + machine-readable provenance metadata;
- explicit `Personal build — not notarized` warning;
- normal macOS Finder / Privacy & Security → Open Anyway approval may be needed once for a downloaded build;
- no Gatekeeper disabling/quarantine-bypass/custom-root instructions;
- immutable tag/release; no `--clobber`/asset replacement.

`v0.1.0` was published from accepted merge commit `8e913dcddfdec7d9aa920df8c37afb23b8c40884` and remains immutable.

Downloaded-release acceptance on the target MacBook/macOS 26.6 is complete:

- `NH-PERSONAL-RELEASE-001`: **PASS**;
- checksum/install/standard macOS first-launch path: PASS;
- application launch: PASS;
- accepted `NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, `NH-HOVER-003` behavior on the downloaded release: PASS.

A separate `Trusted Release` workflow retains Developer ID/notarization for a future new version if paid Apple membership becomes worthwhile. It cannot replace an existing Personal version.

## Personal Release automated evidence

Release infrastructure was developed through deterministic RED→GREEN tests:

1. RED: release-policy tests failed because `release_policy.py` did not exist.
2. GREEN candidate exposed a real policy bug: safe text `Do not disable Gatekeeper` was falsely classified as a bypass instruction; the rule was corrected rather than weakening tests.
3. RED: current-version notes test failed because `docs/releases/v0.1.0.md` was absent; GREEN after versioned notes were added.
4. RED: Personal Release workflow contract failed because `personal-release.yml` was absent; GREEN after fail-closed manual workflow implementation.
5. RED: tier-separation contract failed because `trusted-release.yml` was absent; GREEN after trusted workflow was separated and legacy `release.yml` removed.
6. RED: trust-boundary tests failed because executable `validate_personal_release_workflow` did not exist; GREEN after the validator and security-audit integration were added.
7. Security review found a fail-closed weakness in the future Trusted pre-publish recheck; a RED test was added before the final remote tag/release error-classification fix.

Pre-merge PR #3 verification passed macOS 26 compatibility, release-policy tests, executable security baseline, warnings-as-errors, Swift tests, DMG packaging, signature/Hardened Runtime/App Sandbox/system-library/integrity checks, and artifact upload.

## Current milestone — P0 Performance Foundation

Status: **IN PROGRESS in PR #5; runtime target-Mac baseline accepted, exact release sizes pending**.

Performance is a first-class product requirement alongside security. P0 executes before feature-heavy M1.

Implemented/in review in PR #5:

- root `PERFORMANCE.md` event-driven/resource-efficiency contract;
- RED→GREEN deterministic performance-policy tests;
- runtime source scanner for unreviewed busy loops, timers, sleeps, and display links;
- strict `/bin/ps` CPU/RSS/thread parser and median/max aggregation;
- deterministic budget-comparison helpers with malformed/non-finite input rejection;
- development-only `scripts/perf-baseline.py` with explicit measured-app/tooling provenance separation;
- Darwin-compatible thread measurement using `ps -M` after CI exposed unsupported `thcount`;
- exact full-window sampling and stability start/end/quartile evidence;
- deterministic `NH-PERF-STATE-001` 100,000-transition Swift stress coverage without wall-clock assertions;
- CI integration for policy tests/audit, deterministic artifact sizes, development-tool isolation, and a short harness compatibility/schema smoke;
- security audit enforcement proving performance tooling is not referenced/copied into runtime packaging;
- stable `NH-PERF-IDLE-001`, `NH-PERF-HOVER-001`, `NH-PERF-STABILITY-001`, `NH-PERF-SIZE-001`, and `NH-PERF-STATE-001` contracts.

### Accepted target-Mac runtime measurements

Measured against accepted Personal Release `v0.1.0` source commit `8e913dcddfdec7d9aa920df8c37afb23b8c40884` on macOS 26.6 / `Mac16,8`, using tooling commit `dfd4f87f8e5be04b467172d720d22bfc054c06d0`:

- `NH-PERF-IDLE-001`: **BASELINE ACCEPTED** — CPU median/max `0.0% / 0.7%`, RSS median/max `33,648 / 33,808 KiB`, threads median/max `4 / 4`;
- `NH-PERF-HOVER-001`: **BASELINE ACCEPTED** — CPU median/max `5.95% / 22.3%`, RSS median/max `38,456 / 38,816 KiB`, threads median/max `6 / 7`;
- `NH-PERF-STABILITY-001`: **BASELINE ACCEPTED** — CPU median/max `0.0% / 6.8%`, RSS median/max `30,992 / 34,384 KiB`, threads median/max `3 / 7`;
- stability RSS start/end: `34,256 -> 30,544 KiB` (`-3,712 KiB`, no sustained memory growth);
- stability thread start/end: `4 -> 5`, max `7`.

Measurement windows and sample counts matched the contracts: idle `60.017 s / 60 samples`, hover `60.018 s / 60 samples`, stability `600.013 s / 120 samples`.

Initial CPU/RSS/thread budgets are documented in `PERFORMANCE.md` as conservative **target-Mac acceptance ceilings**, not shared-runner CI thresholds. The main M1 optimization comparison target is hover CPU/resource behavior because the current global `.mouseMoved` observer is active there.

Still required before P0 acceptance:

1. obtain exact immutable `v0.1.0` `build-metadata.json` values for `NH-PERF-SIZE-001`;
2. create complete `performance/baseline-v0.1.0.json` containing runtime summaries, exact release sizes, and budgets;
3. derive and add only reproducible artifact-size budget gates to CI;
4. run final PR #5 automated CI and independent change review;
5. merge only after all correctness/security/performance gates are green.

Authoritative policy and accepted runtime values: `PERFORMANCE.md`.
Approved plan: `docs/superpowers/plans/2026-08-07-performance-foundation.md`.

## Security baseline

`SECURITY.md` is authoritative. Current key invariants:

- Sandbox by default;
- Hardened Runtime without dangerous exceptions;
- zero external Swift runtime dependencies;
- no bundled secrets;
- no runtime shell/subprocess/dynamic code loading;
- no telemetry/analytics/remote-control channel;
- no broad global input capture;
- immutable full-SHA GitHub Actions;
- Personal Release contains no Apple secrets/notary path and cannot overwrite existing versions;
- development performance tooling remains outside runtime/app packaging;
- sensitive new permissions/capabilities require explicit security review and tests.

## Approved M1 interaction requirements

Two additional UX requirements are part of the M1 contract and must be implemented test-first after P0:

1. **Delayed hover activation**
   - compact → expanded must not happen immediately on first pointer entry;
   - use a short cancellable dwell/debounce, initial candidate `120 ms`, tuned from real-hardware evidence around `100–150 ms`;
   - quick pointer transit through the notch, especially while moving to another display, must cancel activation and leave the panel compact;
   - event-driven only: no polling/repeating timer, at most one pending activation task, deterministic cancellation/race tests.

2. **Trackpad haptic feedback on successful expansion**
   - use public AppKit `NSHapticFeedbackManager.defaultPerformer`;
   - emit exactly one haptic request only for a completed user-initiated `compact -> expanded` transition;
   - no feedback for quick/cancelled hover, duplicate movement, expanded retention, collapse, layout/programmatic transitions, or stale callbacks;
   - respect macOS/current-device/accessibility/user settings; no private APIs, synthetic input, custom drivers, Accessibility hacks, audio imitation, or retry loop.

Authoritative spec: `docs/specs/M1_NOTCH_INTERACTION.md`.

Planned acceptance IDs: `NH-HOVER-DELAY-001`, `NH-HOVER-DELAY-002`, `NH-HAPTIC-001`, `NH-HAPTIC-002`.

## Known limitations

- P0 exact accepted-release size baseline and deterministic size budget gate are still pending;
- initial target-Mac runtime budgets come from one canonical run per scenario and intentionally include conservative headroom; future accepted repeated measurements may tighten them;
- current global `.mouseMoved` observer is security-narrow but hover baseline shows materially higher active CPU than idle, making M1 tracking investigation worthwhile;
- current M0 hover activation remains immediate; M1 will add the approved cancellable dwell;
- current M0 build has no expansion haptic; M1 will add public AppKit haptic feedback after successful deliberate hover;
- active-display migration, final Spaces/fullscreen policy, animation tuning, and final product UI belong to M1;
- feature modules including Yandex Music are not implemented yet;
- ad-hoc Personal Release lacks Apple Developer identity/notarization by deliberate product choice.

## Next optimal step

1. Complete `NH-PERF-SIZE-001` from immutable Personal Release `v0.1.0` build metadata.
2. Commit the complete canonical `performance/baseline-v0.1.0.json` and deterministic artifact-size budget gate.
3. Run final PR #5 CI and independent change review, then merge P0 if clean.
4. Start M1 with measured investigation of local tracking versus the current global `mouseMoved`, followed by delayed hover + haptic work under `docs/specs/M1_NOTCH_INTERACTION.md`.
