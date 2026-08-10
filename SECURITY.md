# Security Policy

NotchHub is a personal native macOS utility that may run continuously near system UI. Security, privacy, correctness, and resource efficiency are product requirements rather than release-afterthoughts.

## Protected assets and trust boundaries

Protected assets include the user's Mac, local files, clipboard/snippet content, calendar data, media metadata, credentials stored elsewhere on the machine, and release integrity.

Treat as untrusted or potentially attacker-controlled: dropped file URLs/metadata, clipboard text, calendar strings, third-party media metadata/artwork, future network responses, GitHub pull-request content, forked repository code, and dependency/update proposals.

Important trust boundaries are App Sandbox/entitlements, macOS permissions, external media applications and the system Now Playing surface, the reviewed Universal Media compatibility process, user-selected files, public GitHub pull-request CI, release workflows/environments, and—only for the optional trusted distribution tier—Apple signing/notarization credentials.

## Runtime security invariants

These properties hold unless an explicit reviewed security decision changes them:

1. **Local-first and no telemetry.** No analytics, telemetry, advertising, licensing backend, remote-control channel, or direct network requests in the baseline app.
2. **Sandbox by default.** App Sandbox remains enabled. New entitlements require a concrete feature, least-privilege justification, tests, and documentation in the same PR.
3. **Hardened Runtime without dangerous exceptions.** Do not enable JIT, unsigned executable memory, DYLD environment variables, disabled library validation, or `get-task-allow` in distributed builds.
4. **No general runtime shell/subprocess execution.** Runtime sources do not invoke shells, package managers, arbitrary executables, `NSTask`, spawn/exec/popen surfaces, or unrestricted `Process`. The sole reviewed production exception is `Sources/NotchHubMediaCore/MediaRemoteProcessClient.swift`: it may construct exactly one Foundation `Process` boundary whose executable is fixed to `/usr/bin/perl`, whose adapter/framework resource paths are supplied by trusted application composition, and whose arguments are closed to the reviewed `stream --no-diff --micros`, `capabilities`, toggle/previous/next, and bounded-seek media operations. `scripts/security-audit.sh` fail-closes if `Process()` appears anywhere else in `Sources/**` or if this boundary loses its fixed executable/command contract.
5. **No dynamic code loading in the NotchHub process.** No `dlopen`, `dlsym`, `CFBundleGetFunctionPointerForName`, direct `MRMediaRemote*` resolution, downloaded executable content, unsigned plug-ins, JIT, or self-modifying code. The accepted MediaRemote adapter loads its private framework only inside the separately owned external compatibility process when that transport is eventually packaged/composed.
6. **No broad global input capture.** The current M0 implementation observes only global `mouseMoved` to resolve notch hover. Keyboard, modifier, button, drag, and scroll event classes remain prohibited unless a later reviewed feature changes the policy.
7. **Minimize observed input.** Pointer events/coordinates/history are not persisted or used as telemetry.
8. **User-selected file access only.** Future Shelf work uses sandbox-compatible user-selected/security-scoped access rather than broad filesystem authority. Removing from Shelf must not delete the source file.
9. **No bundled secrets.** API keys, passwords, certificates, private keys, tokens, and signing material never enter the repository/app bundle.
10. **Immutable CI dependencies.** External GitHub Actions are pinned to full 40-character commit SHAs. `pull_request_target` is prohibited.
11. **Third-party runtime dependencies require review.** M0 has zero external Swift runtime dependencies. Adding one requires security/supply-chain/license review and an explicit baseline change. The MediaRemote adapter is an explicitly pinned external runtime asset only after the separate production-transport packaging/composition gate; it is not a Swift package dependency.
12. **No silent privilege escalation.** Accessibility, Screen Recording, Automation/Apple Events, camera, microphone, Full Disk Access, Input Monitoring, or similarly sensitive permissions require a feature-specific security decision and degraded mode where feasible.
13. **Private APIs are isolated, optional, and fail closed.** Universal Media permits one MediaRemote compatibility mechanism behind `SystemMediaBridge`. M6.1 physically accepted the external adapter mechanism under App Sandbox + Hardened Runtime. M6.2 established the player-agnostic state/controller/bridge boundary. M6.3 may implement the concrete process transport only behind that boundary; private-framework knowledge must not spread into UI/gesture/product state or the NotchHub process. Media failures remain media-only failures and may not weaken Sandbox/Hardened Runtime/library validation, add broad permissions, or invent capability support.
14. **Updates require authenticated provenance.** No self-updater/background updater exists. GitHub Releases are the deliberate manual update source until an authenticated updater is separately designed.
15. **Performance measurement is not runtime telemetry.** `scripts/perf-baseline.py`, `scripts/performance_policy.py`, raw measurements, and related policy tooling are development/release assets only. They must never be copied into the app bundle, invoked from `Sources`, or used to create a shipped background monitoring channel.
16. **Untrusted public PRs are unprivileged.** Ordinary pull-request CI must remain `contents: read`, secret-free, GitHub-hosted, without OIDC/write permissions, without persisted checkout credentials, and without a privileged trigger such as `pull_request_target` or `workflow_run`.

## Universal Media compatibility boundary — accepted transport, production integration gated

The Universal Media compatibility mechanism was first isolated as the development-only probe described by `docs/superpowers/plans/2026-08-09-universal-media-bridge-probe.md`. Target-Mac M6.1 evidence produced final decision **`ACCEPT_TRANSPORT`** for the pinned `/usr/bin/perl` + `ungive/mediaremote-adapter` architecture under the required App Sandbox + Hardened Runtime posture.

The accepted evidence proved event-driven system Now Playing observation, authoritative capability states, fixed typed commands, bounded process lifecycle, privacy-safe evidence, no sensitive permission prompts, and stable target-Mac resource behavior on the available real sources. That decision authorizes one production implementation of the same narrow mechanism; it does not authorize arbitrary subprocess execution or direct private-framework calls inside NotchHub.

M6.3 production transport therefore follows these mandatory properties:

- executable fixed to `/usr/bin/perl`;
- pinned/repo-verified MediaRemote adapter assets;
- event-driven `stream --no-diff --micros`, never periodic `get` polling;
- fixed typed toggle/previous/next/bounded-seek command allowlist;
- strict `supported | unsupported | unknown` capability schema;
- bounded stdout/stderr/JSON/text/artwork/timing inputs;
- explicit process ownership, termination, wait, stale-callback rejection, and timeout handling;
- no shell command construction or arbitrary executable/argument surface;
- no direct `dlopen`/`dlsym`/`CFBundleGetFunctionPointerForName`/`MRMediaRemote*` use in `Sources/**`;
- metadata/artwork remain untrusted and listening history is not persisted or logged;
- no Accessibility, Input Monitoring, Automation/Apple Events, Screen Recording, synthetic input, network authority, or new entitlement;
- controller-owned restart remains bounded to one controlled retry, then fail closed.

`NotchHubMediaCore` is still intentionally outside the shipping `NotchHubApp` dependency graph while M6.3 is being implemented. The production process code and adapter assets do not enter the distributed app merely because unit/CI tests pass. A production-transport candidate must first pass target-Mac sandbox/Hardened Runtime, functional, lifecycle, privacy, command, stale-artwork/source-switch, and resource acceptance. Shipping composition and asset packaging are a subsequent reviewed gate.

If those requirements cannot be maintained, the transport is rejected or redesigned. Media functionality is not sufficient justification to weaken the application's accepted security foundation.

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

Release workflows are not part of untrusted PR execution. They remain manual, exact-`main` publication paths. The current Personal Release path uses no custom repository/Apple secrets. The optional Trusted Release workflow is deliberately dormant: it references `environment: release`, but no GitHub Environment or Apple signing/notarization secrets are currently configured. If that tier is adopted later, the environment, protection rules, and secrets must be provisioned and reviewed before first use.

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

`.github/workflows/trusted-release.yml` retains the stronger future path for low-friction distribution if Apple Developer Program membership later becomes worthwhile. It is **not currently operational** because no GitHub `release` environment or Apple signing/notarization secrets are configured.

Future activation requires an explicit setup/review step before the first run:

- create the GitHub `release` environment;
- configure appropriate environment protection rules;
- provision Developer ID and notarization credentials only as environment-scoped secrets;
- verify the workflow still fails closed before publishing any artifact.

Once activated, the tier requires:

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

P0 adds development measurement tooling without changing general runtime authority:

- the runtime source audit rejects unreviewed polling/timer/sleep/display-link primitives;
- the sampler may use development-side subprocesses to query `/bin/ps`;
- ordinary runtime Swift sources remain prohibited from spawning processes; only the exact M6.3 media compatibility boundary described above is allowlisted;
- the sampler records process CPU/RSS/thread aggregates plus non-sensitive source/platform provenance only;
- it does not record usernames, file/content data, clipboard/snippets, window titles, pointer history, serial numbers, or network telemetry identifiers;
- CI verifies the performance tooling is absent from `NotchHub.app` packaging.

The historical M6.1 probe remains development evidence. M6.3 may reuse the accepted mechanism only through the separately audited production implementation. Probe helper/framework/script code is never silently copied into the shipping app.

A future need for shipped resource monitoring would be a separate security/privacy architecture decision, not an extension of P0 tooling.

## Public-readiness audit

`docs/PUBLIC_READINESS.md` records the pre-publication history/workflow audit and mandatory post-visibility checks. Repository visibility must not be treated as safely changed until those post-transition settings checks pass.

## Reportable security findings

Treat as security findings, among others: arbitrary command/code execution; broad/undocumented file access; credential leakage; hidden network/telemetry; keystroke collection; Sandbox/Hardened Runtime weakening; untrusted dylib/plugin loading; release-workflow compromise; mutable action references; false claims of Apple trust; insecure temporary-file handling with realistic impact; or permissions materially broader than a feature requires.

For Universal Media, also treat as reportable findings: `Process()` outside the one allowlisted production file, arbitrary bridge/process arguments or executable paths, shell execution, direct private-framework function resolution in the NotchHub process, unbounded/unsanitized media metadata/artwork, orphan/restart-storm helper processes, hidden listening-history persistence, capability spoofing that causes unsupported actions to be presented as available, stale source/artwork leakage, or a private compatibility path that silently bypasses the approved fail-closed boundary.

Security checks are defense-in-depth and do not prove absence of vulnerabilities. Material new capability, permission, dependency, private-API use, CI authority, or release-chain change requires focused review in addition to tests.

## Known accepted risks

- Personal/CI artifacts are ad-hoc signed and therefore lack Apple Developer identity/notarization trust.
- The current global `NSEvent` monitor observes only `mouseMoved`. P0 establishes its canonical resource baseline; the window-local replacement experiment is deferred to P1 and is adopted only if correctness and measured resource evidence support replacement without expanding permissions.
- M6.1 accepted the MediaRemote external-process transport mechanism and M6.2 merged the player-agnostic production boundary. M6.3 production transport implementation is under review and is not yet composed into the shipping `NotchHubApp`; current distributed builds therefore still contain no production MediaRemote adapter/process asset.
- Repository-local security gates intentionally do not depend on paid GitHub security products; public visibility does not make those external products a correctness prerequisite.

## Validation

Every PR runs deterministic release-policy tests, public-CI boundary tests, performance-policy tests/audit, `scripts/security-audit.sh`, compile/test/package checks, entitlement/signature verification, performance-tool bundle-isolation checks, and macOS 26 compatibility. CI performance smoke validates harness compatibility/schema only and never treats noisy runner CPU/RSS/thread values as a tight security/performance gate. Personal Release repeats the complete release/security baseline before publication and adds checksum/provenance validation. Trusted Release, if deliberately configured in the future, additionally requires Developer ID/notarization/stapling/Gatekeeper gates.
