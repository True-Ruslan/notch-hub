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

Status: **IN PROGRESS in PR #5**.

Performance is a first-class product requirement alongside security. P0 executes before feature-heavy M1.

Implemented/in review in PR #5:

- root `PERFORMANCE.md` event-driven/resource-efficiency contract;
- RED→GREEN deterministic performance-policy tests;
- runtime source scanner for unreviewed busy loops, timers, sleeps, and display links;
- strict `/bin/ps` CPU/RSS/thread parser and median/max aggregation;
- deterministic budget-comparison helpers with malformed/non-finite input rejection;
- development-only `scripts/perf-baseline.py` with explicit measured-app/tooling provenance separation;
- deterministic `NH-PERF-STATE-001` 100,000-transition Swift stress coverage without wall-clock assertions;
- CI integration for policy tests/audit, deterministic artifact sizes, development-tool isolation, and a short harness compatibility/schema smoke;
- security audit enforcement proving performance tooling is not referenced/copied into runtime packaging;
- stable `NH-PERF-IDLE-001`, `NH-PERF-HOVER-001`, `NH-PERF-STABILITY-001`, `NH-PERF-SIZE-001`, and `NH-PERF-STATE-001` contracts.

Still required before P0 acceptance:

1. final PR #5 automated CI/review on the completed tooling changes;
2. canonical macOS 26.6 idle/hover/stability measurements against accepted Personal Release `v0.1.0`;
3. exact accepted-release executable/app/DMG sizes;
4. review measurement stability/noise;
5. create `performance/baseline-v0.1.0.json` with summarized non-sensitive values;
6. derive evidence-based budgets only from those measurements;
7. add only reproducible budget gates to CI, then complete final review/merge.

Authoritative policy: `PERFORMANCE.md`.
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

- P0 canonical target-Mac performance baseline/budgets are not yet accepted;
- current global `.mouseMoved` observer is security-narrow but its resource cost is not yet baselined;
- current M0 hover activation remains immediate; M1 will add the approved cancellable dwell;
- current M0 build has no expansion haptic; M1 will add public AppKit haptic feedback after successful deliberate hover;
- active-display migration, final Spaces/fullscreen policy, animation tuning, and final product UI belong to M1;
- feature modules including Yandex Music are not implemented yet;
- ad-hoc Personal Release lacks Apple Developer identity/notarization by deliberate product choice.

## Next optimal step

1. Finish automated verification of PR #5 P0 tooling.
2. Run the documented `NH-PERF-IDLE-001`, `NH-PERF-HOVER-001`, `NH-PERF-STABILITY-001`, and `NH-PERF-SIZE-001` measurements on the target MacBook/macOS 26.6 against accepted `v0.1.0`.
3. Review the measurements, commit summarized baseline values, and derive honest budgets.
4. Complete P0 review/merge only when correctness/security/performance gates are green.
5. Start M1 with measured investigation of local tracking versus the current global `mouseMoved`, followed by delayed hover + haptic work under `docs/specs/M1_NOTCH_INTERACTION.md`.
