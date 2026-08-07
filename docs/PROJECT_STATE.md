# Project state

Last updated: 2026-08-07
Current version: `0.1.0` (Personal Release candidate; tag not published yet)
Primary physical target: macOS `26.6`
Protected branch: `main`
Current implementation PR: #3 `Personal Release v0.1.0`

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
- strict CI, macOS 26 compatibility, warnings-as-errors, security audit, 10/10 Swift regression tests, release DMG packaging/integrity checks;
- RED→GREEN evidence for both real-hardware defect cycles.

M0 integration PR #1 was squash-merged. Approved Personal Release + Performance Foundation design/plans were subsequently merged through docs PR #2.

## Current milestone — R0.1 Personal Release

Status: **implementation/verification in PR #3**.

The Apple Developer Program dependency is intentionally deferred because NotchHub is currently personal-use software. This is a deliberate product decision, not an accidental missing credential.

Current supported versioned distribution will therefore be **Personal Release**:

- manual GitHub Actions publication from exact protected `main`;
- ad-hoc app signature;
- App Sandbox and Hardened Runtime remain mandatory;
- complete correctness/security CI rerun before publication;
- SHA-256 + machine-readable provenance metadata;
- explicit `Personal build — not notarized` warning;
- normal macOS Finder / Privacy & Security → Open Anyway approval may be needed once for a downloaded build;
- no Gatekeeper disabling/quarantine-bypass/custom-root instructions;
- immutable tag/release; no `--clobber`/asset replacement.

A separate `Trusted Release` workflow retains Developer ID/notarization for a future new version if paid Apple membership becomes worthwhile. It cannot replace an existing Personal version.

## PR #3 TDD / automated evidence so far

Release infrastructure is being developed through deterministic RED→GREEN tests:

1. RED: release-policy tests failed because `release_policy.py` did not exist.
2. GREEN candidate exposed a real policy bug: safe text `Do not disable Gatekeeper` was falsely classified as a bypass instruction; the rule was corrected rather than weakening tests.
3. RED: current-version notes test failed because `docs/releases/v0.1.0.md` was absent; GREEN after versioned notes were added.
4. RED: Personal Release workflow contract failed because `personal-release.yml` was absent; GREEN after fail-closed manual workflow implementation.
5. RED: tier-separation contract failed because `trusted-release.yml` was absent; GREEN after trusted workflow was separated and legacy `release.yml` removed.
6. RED: trust-boundary tests failed because executable `validate_personal_release_workflow` did not exist; GREEN after the validator and security-audit integration were added.

Latest targeted checks on the current code before this documentation state update:

- macOS 26 compatibility: PASS;
- release-policy tests: PASS;
- executable security baseline including release-tier boundaries: PASS;
- existing M0 Swift/security behavior remains unchanged by PR #3 (no `Sources/` changes).

Final full CI on the documentation-complete PR head is still required before merge.

## Personal Release assets and guarantees

Planned `v0.1.0` GitHub Release assets:

- `NotchHub.dmg`;
- `NotchHub.dmg.sha256`;
- `build-metadata.json` containing source commit, build number, runner/toolchain versions, artifact sizes/checksum, `distributionTier=personal`, `appleTrusted=false`, `notarized=false`.

Versioned release notes: `docs/releases/v0.1.0.md`.

The release does **not** claim Apple identity/notarization trust.

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
- sensitive new permissions/capabilities require explicit security review and tests.

## Performance/resource-efficiency requirement

Performance is now a first-class product requirement alongside security. The approved Performance Foundation plan will execute immediately after Personal `v0.1.0` publication and before feature-heavy M1.

It will establish:

- `PERFORMANCE.md`;
- deterministic no-unreviewed-polling/timer/busy-loop policy;
- development-only target-Mac metric harness;
- canonical macOS 26.6 idle/hover/stability/artifact-size baseline;
- evidence-based CPU/RAM/thread/size budgets rather than invented thresholds;
- CI gates only for deterministic/reproducible performance invariants;
- proof that measurement tooling is never shipped as runtime telemetry.

Approved plan: `docs/superpowers/plans/2026-08-07-performance-foundation.md`.

## Known limitations

- `v0.1.0` Personal Release is not yet published;
- ad-hoc Personal Release will lack Apple Developer identity/notarization and may require standard macOS first-launch approval;
- performance baseline/budgets have not yet been measured;
- current global `.mouseMoved` observer is security-narrow but its resource cost is not yet baselined;
- active-display migration, final Spaces/fullscreen policy, animation tuning, and final product UI belong to M1;
- feature modules including Yandex Music are not implemented yet.

## Next optimal step

1. Complete PR #3 documentation and final CI.
2. Review PR #3 diff/security boundaries; mark Ready and squash-merge into protected `main` only when all checks are green.
3. Run **Personal Release** workflow manually on `main`; it must publish immutable `v0.1.0 — Personal build` with DMG/checksum/provenance.
4. Run `NH-PERSONAL-RELEASE-001` on the target MacBook/macOS 26.6. Do not replace `v0.1.0` if acceptance fails; fix and increment the version.
5. Begin Performance Foundation (P0), establish real target-Mac resource baseline and evidence-based budgets.
6. Only then start feature-heavy M1, beginning with measured investigation of local tracking vs the current global `mouseMoved` monitor.
