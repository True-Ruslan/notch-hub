# Security Policy

NotchHub is a personal native macOS utility that may run continuously near system UI. Security, privacy, correctness, and resource efficiency are product requirements rather than release-afterthoughts.

## Protected assets and trust boundaries

Protected assets include the user's Mac, local files, clipboard/snippet content, calendar data, media metadata, credentials stored elsewhere on the machine, and release integrity.

Treat as untrusted or potentially attacker-controlled:

- dropped file URLs/metadata;
- clipboard/calendar text;
- third-party media metadata/artwork;
- future network responses;
- public pull-request code;
- dependency/update proposals.

Important trust boundaries are App Sandbox/entitlements, macOS permissions, external media applications/system Now Playing, the reviewed Universal Media external compatibility process, user-selected files, public GitHub PR CI, release workflows, and—only for a future Trusted Release—Apple signing/notarization credentials.

## Runtime security invariants

These properties hold unless an explicit reviewed security decision changes them:

1. **Local-first and no telemetry.** No analytics, telemetry, advertising, licensing backend, remote-control channel, or direct application network requests in the current product.
2. **Sandbox by default.** App Sandbox remains enabled. New entitlements require concrete least-privilege justification, tests and documentation in the same PR.
3. **Hardened Runtime without dangerous exceptions.** Distributed/test shipping artifacts do not enable JIT, unsigned executable memory, DYLD environment exceptions, disabled library validation, or `get-task-allow`.
4. **No general shell/arbitrary subprocess execution.** The sole reviewed production exception is `Sources/NotchHubMediaCore/MediaRemoteProcessClient.swift`: exactly one Foundation `Process` boundary with executable fixed to `/usr/bin/perl`, trusted packaged adapter/framework paths, and a closed command surface for event stream, capabilities, toggle, previous, next and bounded seek. `scripts/security-audit.sh` fail-closes if unrestricted process authority appears elsewhere in `Sources/**`.
5. **No dynamic private-code loading inside the NotchHub process.** No `dlopen`, `dlsym`, `CFBundleGetFunctionPointerForName`, direct `MRMediaRemote*` resolution, downloaded executable code, unsigned plugin, JIT or self-modifying code. The pinned adapter loads its framework only inside the separately owned external compatibility process.
6. **No broad global input capture.** Current global observation is restricted to `.mouseMoved` for notch interaction. Keyboard, modifiers, buttons, drag and scroll remain prohibited unless a later reviewed feature explicitly changes policy.
7. **No input-history persistence.** Pointer events/coordinates/history are not persisted or used as telemetry.
8. **User-selected file access only.** M2 Shelf uses read-only security-scoped bookmarks for files/folders explicitly selected or locally dropped by the user. Shipping file authority is exactly `com.apple.security.files.user-selected.read-only`; no read-write, Downloads or broad filesystem entitlement is permitted. Removing a Shelf reference never deletes, moves or renames its source file.
9. **No bundled secrets.** API keys, passwords, certificates, private keys, tokens and signing credentials do not enter the repository/app bundle.
10. **Immutable CI dependencies.** External GitHub Actions are pinned to full commit SHAs; privileged PR triggers such as `pull_request_target` are prohibited.
11. **Third-party runtime assets require explicit review.** The MediaRemote adapter/framework is the one accepted pinned external runtime asset and is not a Swift package dependency. Any additional third-party runtime dependency requires security/supply-chain/license review.
12. **No silent privilege escalation.** Accessibility, Screen Recording, Automation/Apple Events, camera, microphone, Full Disk Access, Input Monitoring or similar authority requires a feature-specific decision and degraded mode where feasible.
13. **Private APIs stay isolated and fail closed.** Universal Media permits one MediaRemote-compatible mechanism behind the system-media transport/bridge boundary. Private-framework knowledge must not spread into product UI/gesture state or the NotchHub process. Media failures remain media-only failures and may not weaken Sandbox/Hardened Runtime/library validation or invent capability support.
14. **No hidden updater.** GitHub Releases remain the deliberate update source until an authenticated updater is separately designed.
15. **Performance measurement is development tooling, not runtime telemetry.** Performance scripts/reports must never be bundled or invoked as a shipped background monitoring channel.
16. **Untrusted public PRs are unprivileged.** Ordinary PR CI remains read-only, secret-free, GitHub-hosted, without OIDC/write authority or persisted checkout credentials.
17. **Security-scoped access is explicit, bounded and balanced.** Bookmark resolution happens only for explicit Shelf operations. Open/Show in Finder use short-lived scope immediately balanced after the operation. M2.2 Quick Look may hold exactly one read-only scope for the lifetime of an explicitly active native preview; panel close, replacement, controller close and application termination release it. M2.3 Share may likewise hold exactly one read-only scope for an explicitly active native sharing operation; picker cancellation, sharing success/failure, replacement, controller close and application termination release it. No security scope is intentionally held while Shelf/Quick Look/Share is idle.

## M2.1 Shelf file-access boundary

Shelf is the first feature that intentionally expands the shipping App Sandbox entitlement set. The change is narrowly scoped and machine-enforced.

Shipping NotchHub entitlements are exactly:

- `com.apple.security.app-sandbox = true`;
- `com.apple.security.files.user-selected.read-only = true`.

The development MediaBridgeProbe uses `Resources/MediaBridgeProbe.entitlements` and remains exactly sandbox-only. The Production Media Transport Candidate retains its separate reviewed entitlement file. This prevents a shipping file-access capability from accidentally widening development helper binaries.

Shelf stores only UUID, read-only security-scoped bookmark bytes, display name and file/folder presentation metadata. It does not persist an additional raw path field for browsing or indexing. Persistence is local, atomic and actor-backed under the sandbox Application Support container.

Explicit M2.1 Shelf actions are intentionally limited to:

- Add via native user selection;
- local file/folder drop onto the visible Shelf surface;
- Open;
- Show in Finder;
- Remove reference.

There is no source-file delete/move/rename/copy authority, no background filesystem crawler, no global drag monitor, and no Shelf network path.

Automated security acceptance checks the exact shipping entitlement dictionary, absence of read-write/network/Automation/broad-file authority, balanced security-scope source contract, package effective entitlements, security audit, and release workflow entitlement assertions.

## M2.2 Shelf Quick Look security boundary

M2.2 adds native Quick Look without expanding the entitlement set or persistence model.

The security boundary is split deliberately:

- `ShelfPreviewAccessSession` owns one testable security-scope lifecycle and balances every successful start with one stop;
- `ShelfQuickLookController` owns the native `QLPreviewPanel` lifecycle on the main actor;
- the Quick Look data source holds only the single active preview URL and is cleared on close/replacement;
- `AppDelegate` owns the controller for application lifetime and closes it during normal termination.

A preview request first resolves the existing read-only bookmark. If scope acquisition fails, no new panel content is installed. If a preview is already active, M2.2 closes/clears that preview **before** trying to acquire the replacement scope; this prevents a failed replacement from leaving stale Quick Look content visible after the previous file scope has been released.

M2.2 adds no:

- entitlement;
- source-file write/delete/move/rename/copy authority;
- network client or network entitlement;
- Automation/Apple Events;
- Accessibility/Input Monitoring/Screen Recording;
- global input monitor;
- polling/timer/filesystem scan;
- persistence field for raw file paths;
- third-party runtime dependency.

Detailed automated evidence is recorded in `docs/testing/M2_2_SHELF_QUICK_LOOK_ACCEPTANCE.md`.

## M2.3 Shelf Share / AirDrop security boundary

M2.3 adds an explicit single-item native Share action without widening the shipping entitlement set or Shelf persistence schema.

The security boundary is deliberately split:

- `ShelfShareAccessSession` owns exactly one testable read-only security-scope lifecycle and balances every successful start with one stop;
- `ShelfShareController` owns the active `NSSharingServicePicker` and scope session on the main actor;
- `ShelfSharePickerDelegate` is a narrow non-actor proxy for the Objective-C picker delegate boundary and forwards cancellation to main-actor cleanup;
- `ShelfShareServiceDelegate` forwards native success/failure callbacks to the same main-actor cleanup path;
- `AppDelegate` owns the controller for application lifetime and closes it during normal termination.

A Share request first resolves the existing read-only bookmark. The controller discovers the visible NotchHub panel anchor before acquiring file authority. If no anchor exists or security-scope acquisition fails, no picker is installed and the operation fails closed. If another sharing operation is already active, its picker and scope are closed **before** acquiring the replacement scope.

NotchHub passes the file URL to the native macOS sharing picker and lets the operating system provide applicable sharing services, including AirDrop where available. M2.3 does not implement AirDrop discovery, peer enumeration, transport, network fallback, or any custom sharing protocol.

M2.3 adds no:

- entitlement or broader filesystem authority;
- application network client or network entitlement;
- source-file write/delete/move/rename/copy authority;
- Automation/Apple Events;
- Accessibility/Input Monitoring/Screen Recording;
- global input monitor;
- timer/polling/filesystem scan/background worker loop;
- persistence field or sharing history;
- third-party runtime dependency;
- concurrency-check suppression such as `@preconcurrency` for the picker delegate boundary.

The system picker may consume the file asynchronously, so the read-only scope intentionally remains active until cancellation, sharing success/failure, replacement, controller close, or application termination. This is the minimum authority lifetime required by the explicit native sharing operation; no share scope is retained in idle.

Canonical CI compiles the real AppKit integration, behaviorally tests scope balance/replacement/fail-closed semantics, verifies the delegate-isolation policy, runs external-application regression smoke, and rechecks packaging/effective entitlements/size/performance. CI intentionally does not choose a real external sharing target or AirDrop recipient because that would create nondeterministic system/device side effects.

Detailed automated evidence is recorded in `docs/testing/M2_3_SHELF_SHARE_ACCEPTANCE.md`.

## Universal Media production boundary

Universal Media is now a shipping-source capability, not merely a development probe.

Accepted progression:

- **M6.1** physically accepted the pinned external `/usr/bin/perl` + `ungive/mediaremote-adapter` mechanism under App Sandbox + Hardened Runtime (`ACCEPT_TRANSPORT`).
- **M6.2** established normalized player-agnostic media state, controller, provider and injected bridge/transport boundaries.
- **M6.3** implemented and physically accepted the concrete production transport.
- **M6.4** composed that transport into `NotchHubApp` with exact packaged resources and a presentation-scoped lifecycle: zero adapter while compact, one expected adapter while expanded, clean teardown.
- **M6.5** adds only presentation/UI behavior on top of that accepted authority. It does not widen process, entitlement, permission, network or global-input surface.

The production media mechanism must retain all of these properties:

- executable fixed to `/usr/bin/perl`;
- pinned/repo-verified adapter/framework/license/provenance assets;
- event-driven `stream --no-diff --micros`, not periodic `get` polling;
- fixed typed toggle/previous/next/bounded-seek allowlist;
- strict `supported | unsupported | unknown` capability schema;
- bounded stdout/stderr/JSON/text/artwork/timing inputs;
- explicit process ownership, termination, wait, stale-callback rejection and timeouts;
- no shell command construction or arbitrary executable/argument surface;
- no direct private-framework resolution in `Sources/**`;
- metadata/artwork treated as untrusted;
- listening history not persisted or logged;
- no Accessibility, Input Monitoring, Automation/Apple Events, Screen Recording, synthetic input or network authority;
- controller restart bounded to one controlled retry before fail-closed terminal unavailability.

If these requirements cannot be maintained, the media capability must be rejected/redesigned rather than made to pass by weakening the security baseline.

## M6.5 Media-first UI security result

M6.5 is accepted on the primary `Mac16,8` / macOS 26.6 target. The frozen physical candidate is source `431d9fbaf1ff5ba98f2ceec09732acafe5f65794`; all `NH-MEDIA-UI-001...011` gates pass.

Security-relevant acceptance confirms:

- cold/settled compact owns zero adapter processes;
- normal Quit leaves no orphan adapter;
- UI commands pass only through the existing typed transport surface;
- unsupported/unknown capabilities are not presented as supported;
- media disappearance degrades to ordinary Home rather than widening authority;
- no Accessibility prompt;
- no Input Monitoring prompt;
- no Automation/Apple Events prompt;
- no Screen Recording prompt;
- no networking/telemetry/listening-history persistence was added;
- no global scroll monitor was added;
- no new entitlement was added by M6.5 itself.

Detailed evidence: `docs/testing/MEDIA_UI_ACCEPTANCE.md`.

## Public repository / fork CI boundary

Public source visibility means arbitrary contributors may propose code through forks. Such code is untrusted even when a change appears small.

Ordinary PR CI must retain:

- `pull_request` triggering;
- explicit `permissions: contents: read`;
- no repository secret use;
- no self-hosted runner;
- no write permission or `write-all`;
- no OIDC `id-token: write`;
- checkout with `persist-credentials: false`;
- no `pull_request_target` / `workflow_run` privilege bridge.

`scripts/release_policy.py`, its tests, and `scripts/security-audit.sh` enforce this boundary.

Release workflows are separate manual exact-`main` paths. The current Personal Release uses no Apple/repository signing secrets. The optional Trusted Release remains deliberately dormant until a future reviewed GitHub environment and Apple credentials are configured.

## Distribution trust tiers

### CI artifact

PR/main CI produces an ad-hoc signed DMG with App Sandbox and Hardened Runtime. It is a development artifact and is not a versioned release.

### Personal Release — current supported tier

`.github/workflows/personal-release.yml` publishes a versioned GitHub Release from protected `main`.

Required properties:

- ad-hoc application signature;
- App Sandbox with the exact reviewed shipping entitlement set;
- Hardened Runtime;
- complete correctness/security CI baseline;
- system-library-only application executable linkage;
- DMG integrity;
- SHA-256 checksum;
- machine-readable provenance/build metadata;
- explicit `Personal build — not notarized` labeling;
- immutable tag/release; no replacement/clobber;
- manual `workflow_dispatch` only.

Accepted limitation: Personal Release does not provide Apple Developer identity/notarization. First launch may require Finder **Open** or **System Settings -> Privacy & Security -> Open Anyway**. The project must not recommend disabling Gatekeeper or weakening system trust controls.

### Trusted Release — optional future tier

The repository retains a separate Developer ID/notarization/stapling/Gatekeeper path, but it is intentionally unconfigured. Future activation requires an explicit GitHub `release` environment, protected environment rules and environment-scoped Apple credentials. It must publish only a new version and may not overwrite an existing Personal Release.

## Release supply-chain invariants

- release workflows must not use `--clobber`;
- ambiguous legacy release workflows must not exist;
- external Actions stay full-SHA pinned;
- versioned Personal Release notes must lead with trust status and contain no Gatekeeper-bypass instructions;
- tags/releases are immutable by project policy;
- untrusted PR CI cannot acquire publication authority;
- published artifacts carry source/build provenance and checksums.

## Performance/security boundary

Performance work cannot justify wider security authority.

- runtime source audit rejects unreviewed periodic work;
- development samplers may query `/bin/ps` outside the shipping app;
- shipping process authority remains limited to the exact Universal Media exception above;
- performance tooling is absent from the packaged app;
- feature-size growth is handled by reviewed provenance-backed budgets rather than silently rewriting immutable baselines;
- Shelf remains explicit-event driven and may not add an idle filesystem sampler or timer.

## Reportable security findings

Treat as security findings, among others:

- arbitrary command/code execution;
- `Process()` outside the one allowlisted production file;
- arbitrary media executable/argument paths;
- broad or undocumented file access;
- read-write Shelf authority without explicit redesign;
- source-file mutation from Shelf actions;
- credential/secret leakage;
- hidden network/telemetry/listening-history persistence;
- sensitive input collection;
- Sandbox/Hardened Runtime weakening;
- direct private-framework loading/resolution inside NotchHub;
- unbounded/unsanitized media payloads;
- orphan/restart-storm helper processes;
- capability spoofing;
- stale source/artwork/preview/share leakage after authority is released;
- release workflow privilege compromise;
- mutable action references;
- false Apple notarization/trust claims.

Repository-local checks are defense-in-depth and do not prove absence of vulnerabilities. Material new capability, permission, dependency, private API use, CI authority or release-chain change requires focused review in addition to tests.

## Known accepted risks / deferred hardening

- Personal/CI artifacts are ad-hoc signed and lack Apple Developer identity/notarization trust.
- The current global `NSEvent` monitor observes only `.mouseMoved`; P1 will compare it with a reliable window-local/`NSTrackingArea` design and replace it only if correctness and resource evidence are equal-or-better.
- The external MediaRemote compatibility process relies on a pinned third-party adapter/private framework interface; it remains tightly isolated, provenance-verified and fail-closed but is still an accepted private-API compatibility risk.
- Older media slices include historical physical-acceptance evidence; from M2.1 onward the product owner has explicitly chosen automation-first acceptance for personal-use development unless a later feature says otherwise.

## Validation

Every PR runs deterministic release policy, public-CI boundary, performance policy/audit, media policy, `scripts/security-audit.sh`, compile/test/package, entitlement/signature, provenance, feature-size and macOS 26 compatibility checks. M2 adds real external-app Shelf routing/reset XCUITests, exact read-only file-entitlement policy tests, balanced security-scope tests, M2.2 Quick Look lifecycle/regression policy tests, and M2.3 native Share lifecycle/delegate-isolation/forbidden-authority policy tests. Personal Release repeats the release/security baseline before publication. Trusted Release, if deliberately configured in the future, additionally requires Developer ID/notarization/stapling/Gatekeeper gates.
