# Security Policy

NotchHub is a personal native macOS utility that may run continuously near system UI. Security, privacy, correctness, and resource efficiency are product requirements rather than release-afterthoughts.

## Protected assets and trust boundaries

Protected assets include the user's Mac, local files, clipboard/snippet content, calendar data, media metadata, credentials stored elsewhere on the machine, and release integrity.

Treat as untrusted or potentially attacker-controlled: dropped file URLs/metadata, clipboard text, calendar strings, third-party media metadata/artwork, future network responses, GitHub pull-request content, forked repository code, and dependency/update proposals.

Important trust boundaries are App Sandbox/entitlements, macOS permissions, other applications such as Yandex Music, user-selected files, public GitHub pull-request CI, release workflows/environments, and—only for the optional trusted distribution tier—Apple signing/notarization credentials.

## Runtime security invariants

These properties hold unless an explicit reviewed security decision changes them:

1. **Local-first and no telemetry.** No analytics, telemetry, advertising, licensing backend, remote-control channel, or direct network requests in the baseline app.
2. **Sandbox by default.** App Sandbox remains enabled. New entitlements require a concrete feature, least-privilege justification, tests, and documentation in the same PR.
3. **Hardened Runtime without dangerous exceptions.** Do not enable JIT, unsigned executable memory, DYLD environment variables, disabled library validation, or `get-task-allow` in distributed builds.
4. **No runtime shell/subprocess execution.** Runtime sources do not invoke `Process`, `NSTask`, shells, package managers, scripts, or arbitrary executables without a dedicated architecture/security review.
5. **No dynamic code loading.** No `dlopen`, `dlsym`, downloaded executable content, unsigned plug-ins, JIT, or self-modifying code.
6. **No broad global input capture.** The current M0 implementation observes only global `mouseMoved` to resolve notch hover. Keyboard, modifier, button, drag, and scroll event classes remain prohibited unless a later reviewed feature changes the policy.
7. **Minimize observed input.** Pointer events/coordinates/history are not persisted or used as telemetry.
8. **User-selected file access only.** Future Shelf work uses sandbox-compatible user-selected/security-scoped access rather than broad filesystem authority. Removing from Shelf must not delete the source file.
9. **No bundled secrets.** API keys, passwords, certificates, private keys, tokens, and signing material never enter the repository/app bundle.
10. **Immutable CI dependencies.** External GitHub Actions are pinned to full 40-character commit SHAs. `pull_request_target` is prohibited.
11. **Third-party runtime dependencies require review.** M0 has zero external Swift runtime dependencies. Adding one requires security/supply-chain/license review and an explicit baseline change.
12. **No silent privilege escalation.** Accessibility, Screen Recording, Automation/Apple Events, camera, microphone, Full Disk Access, Input Monitoring, or similarly sensitive permissions require a feature-specific security decision and degraded mode where feasible.
13. **Private APIs are isolated and optional.** A future Yandex Music MediaRemote fallback must stay behind a provider boundary and may not disable Sandbox/Hardened Runtime/library validation or add general input capture.
14. **Updates require authenticated provenance.** No self-updater/background updater exists. GitHub Releases are the deliberate manual update source until an authenticated updater is separately designed.
15. **Performance measurement is not runtime telemetry.** `scripts/perf-baseline.py`, `scripts/performance_policy.py`, raw measurements, and related policy tooling are development/release assets only. They must never be copied into the app bundle, invoked from `Sources`, or used to create a shipped background monitoring channel.
16. **Untrusted public PRs are unprivileged.** Ordinary pull-request CI must remain `contents: read`, secret-free, GitHub-hosted, without OIDC/write permissions, without persisted checkout credentials, and without a privileged trigger such as `pull_request_target` or `workflow_run`.

## Public repository / fork CI boundary

Public source visibility means arbitrary contributors may propose code through forks. Such code is untrusted even when the change appears small.

`.github/workflows/ci.yml` is the only workflow intended to execute ordinary pull-request code. Its executable policy requires:

- ordinary `pull_request` triggering;
- explicit `permissions: contents: read`;
- no repository `secrets.*` references;
- no self-hosted runner;
- no `write` permission or `permissions: write-all`;
- no OIDC `id-token: write` authority;
- `actions/checkout` with `persist-credentials: false`;
- no `pull_request_target` or `workflow_run` privilege bridge.

`scripts/release_policy.py validate-public-ci`, its unit tests, and `scripts/security-audit.sh` enforce this boundary. A change that needs additional CI authority must be reviewed as a security architecture change rather than silently widening PR permissions.

Release workflows are not part of untrusted PR execution. They remain manual, exact-`main` publication paths. Trusted Release secrets stay behind the `release` environment and are never made available to ordinary PR CI.

## Distribution trust tiers

### CI test artifact

PR/main CI produces an ad-hoc signed DMG with App Sandbox and Hardened Runtime enabled. It is a development artifact, may trigger normal Gatekeeper trust warnings, and is not a versioned release.

### Personal Release — current supported tier

The current personal-use distribution is a versioned GitHub Release produced by `.github/workflows/personal-release.yml` from the exact protected `main` commit.

Mandatory properties:

- ad-hoc application signature;
- App Sandbox enabled with the reviewed entitlement set;
- Hardened Runtime enabled;
- complete correctness/security CI baseline;
- system-library-only linkage at the current milestone;
- DMG integrity check;
- SHA-256 checksum;
- machine-readable provenance/build metadata;
- explicit `Personal build — not notarized` release labeling;
- immutable tag/release: existing versions/assets are never overwritten;
- manual `workflow_dispatch` only.

Accepted limitation: this tier does **not** provide an Apple-verified developer identity or Apple notarization. macOS may require Finder **Open** or **System Settings → Privacy & Security → Open Anyway** on first launch. The project must never recommend globally disabling Gatekeeper, stripping quarantine recursively, or installing a custom trusted root merely to suppress that warning.

Personal Release contains no Apple Developer secrets and must not reference `notarytool`, Developer ID, or the GitHub `release` environment.

### Trusted Release — optional future tier

`.github/workflows/trusted-release.yml` retains the stronger future path for low-friction distribution if Apple Developer Program membership later becomes worthwhile:

- Developer ID Application signing;
- Hardened Runtime + App Sandbox verification;
- Apple notarization;
- stapling;
- Gatekeeper assessment;
- checksum publication.

Trusted Release is a separate tier and may not overwrite an already published Personal Release version/tag. A new trusted artifact therefore requires a new version if that version was already released personally.

## Release supply-chain invariants

`scripts/release_policy.py`, its unit tests, and `scripts/security-audit.sh` enforce release boundaries. In particular:

- Personal Release contains no custom GitHub secrets/Apple credentials;
- neither release workflow may use `--clobber`;
- the ambiguous legacy `.github/workflows/release.yml` must not exist;
- versioned personal release notes must lead with the trust warning and must not include Gatekeeper-bypass instructions;
- release workflows must remain full-SHA pinned for external actions;
- published tags/releases are immutable;
- untrusted fork PR CI cannot acquire release publication authority.

## Performance/security boundary

P0 adds development measurement tooling without changing runtime authority:

- the runtime source audit rejects unreviewed polling/timer/sleep/display-link primitives;
- the sampler may use development-side subprocesses to query `/bin/ps`, but runtime Swift sources remain prohibited from spawning processes;
- the sampler records process CPU/RSS/thread aggregates plus non-sensitive source/platform provenance only;
- it does not record usernames, file/content data, clipboard/snippets, window titles, pointer history, serial numbers, or network telemetry identifiers;
- CI verifies the performance tooling is absent from `NotchHub.app` packaging.

A future need for shipped resource monitoring would be a separate security/privacy architecture decision, not an extension of P0 tooling.

## Public-readiness audit

`docs/PUBLIC_READINESS.md` records the pre-publication history/workflow audit and mandatory post-visibility checks. Repository visibility must not be treated as safely changed until those post-transition settings checks pass.

## Reportable security findings

Treat as security findings, among others: arbitrary command/code execution; broad/undocumented file access; credential leakage; hidden network/telemetry; keystroke collection; Sandbox/Hardened Runtime weakening; untrusted dylib/plugin loading; release-workflow compromise; mutable action references; false claims of Apple trust; insecure temporary-file handling with realistic impact; or permissions materially broader than a feature requires.

Security checks are defense-in-depth and do not prove absence of vulnerabilities. Material new capability, permission, dependency, private-API use, CI authority, or release-chain change requires focused review in addition to tests.

## Known accepted risks

- Personal/CI artifacts are ad-hoc signed and therefore lack Apple Developer identity/notarization trust.
- The current global `NSEvent` monitor observes only `mouseMoved`. P0 establishes its canonical resource baseline; M1 will investigate reliable window-local tracking only if correctness and measured resource evidence support replacement without expanding permissions.
- Yandex Music integration is not yet implemented; no MediaRemote/private dependency exists.
- Repository-local security gates intentionally do not depend on paid GitHub security products; public visibility does not make those external products a correctness prerequisite.

## Validation

Every PR runs deterministic release-policy tests, public-CI boundary tests, performance-policy tests/audit, `scripts/security-audit.sh`, compile/test/package checks, entitlement/signature verification, performance-tool bundle-isolation checks, and macOS 26 compatibility. CI performance smoke validates harness compatibility/schema only and never treats noisy runner CPU/RSS/thread values as a tight security/performance gate. Personal Release repeats the complete release/security baseline before publication and adds checksum/provenance validation. Trusted Release, when eventually used, additionally requires Developer ID/notarization/stapling/Gatekeeper gates.
