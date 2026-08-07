# Security Policy

NotchHub is a personal native macOS utility that runs continuously near the system UI. Security and privacy are product requirements, not release-afterthoughts.

## System and scope

Covered runtime surfaces:

- the NotchHub application bundle and Swift sources;
- AppKit/SwiftUI panel and pointer interaction;
- local application storage;
- future Shelf file references, snippets/clipboard, EventKit calendar, Translation, and Yandex Music/media integration;
- build, signing, notarization, and GitHub Release workflows.

The primary protected assets are the user's Mac, local files, clipboard/snippet content, calendar data, media metadata, credentials stored elsewhere on the machine, and the integrity of released binaries.

## Threat model and trust boundaries

Treat the following as untrusted or potentially attacker-controlled:

- file URLs and metadata dropped into Shelf;
- clipboard contents and pasted text;
- calendar/event strings;
- media metadata/artwork supplied by third-party applications;
- filenames and document contents selected by the user;
- future external/network responses if a module ever needs network access;
- GitHub pull-request content and dependency/update proposals;
- build inputs other than immutable trusted toolchain components.

Important trust boundaries include macOS permissions/entitlements, App Sandbox, the process boundary of other applications such as Yandex Music, files explicitly selected by the user, GitHub Actions, Apple Developer signing credentials, and Apple notarization.

## Security invariants

These properties must hold unless an explicit reviewed security decision changes them:

1. **Local-first and no telemetry.** The baseline application makes no direct network requests, contains no analytics/telemetry SDK, licensing client, advertising code, or remote-control channel.
2. **Sandbox by default.** Stable builds use App Sandbox. New entitlements must be the minimum required for a concrete feature and documented in the same PR.
3. **Hardened Runtime without dangerous exceptions.** Do not enable JIT, unsigned executable memory, DYLD environment variables, disabled library validation, or `get-task-allow` in distributed builds.
4. **No subprocess or shell execution.** Runtime code must not invoke `Process`, `NSTask`, shells, package managers, scripts, or arbitrary executables without an explicit architecture/security review.
5. **No dynamic code loading or plug-in execution.** Runtime code must not use `dlopen`, `dlsym`, downloaded executable content, unsigned plug-ins, or self-modifying/JIT code.
6. **No global keyboard/button/scroll monitoring.** The M0 pointer interaction observes only the `mouseMoved` event class needed to determine notch hover state. Keystrokes, modifier keys, button events, drag events, and scrolling must not be globally captured unless a later feature explicitly changes this reviewed policy.
7. **Minimize observed input.** Pointer monitors must not persist event contents, coordinates, histories, or behavioral telemetry. The current implementation reads only current pointer location to resolve UI state.
8. **User-selected file access only.** Shelf should use App Sandbox user-selected access/security-scoped mechanisms rather than broad filesystem entitlements. Removing an item from Shelf must never delete the source file unless a future explicit delete feature is separately designed and confirmed.
9. **No bundled secrets.** API keys, Developer ID certificates, App Store Connect keys, passwords, tokens, or private keys must never be committed or embedded in the app. Release credentials live only in GitHub encrypted secrets/environment secrets.
10. **Immutable CI dependencies.** GitHub Actions used by workflows are pinned to full commit SHAs. `pull_request_target` is prohibited.
11. **Third-party runtime dependencies require review.** M0 intentionally has zero external Swift package dependencies. Adding one requires a security/supply-chain review, documented rationale, license check, and explicit baseline update.
12. **Signed and notarized stable releases.** User-facing GitHub Releases must be Developer ID signed, Hardened Runtime enabled, notarized by Apple, stapled, and accompanied by a SHA-256 checksum. Ad-hoc signed PR artifacts are test builds only and must not be presented as trusted stable releases.
13. **No silent privilege escalation.** Accessibility, Screen Recording, Automation/Apple Events, camera, microphone, Full Disk Access, Input Monitoring, or other sensitive permissions may be requested only for a feature that cannot reasonably work without them, after documenting why and providing a degraded mode where possible.
14. **Private APIs are isolated and optional.** If Yandex Music support ultimately needs MediaRemote/private APIs, that code must be isolated behind a provider boundary, must not disable Hardened Runtime/library validation, must not execute external code, and must have a documented fallback/failure mode.
15. **Updates must be authenticated.** Do not implement self-update until the update channel verifies cryptographic provenance/signatures. Until then, GitHub Releases are the distribution source.

## Reportable findings and severity context

Treat as security findings, among others:

- arbitrary command/code execution;
- unsafe deserialization/parsing that reaches privileged operations;
- broad or undocumented file access;
- credential/token leakage;
- hidden telemetry/network calls;
- keystroke collection;
- sandbox or Hardened Runtime bypass/disablement;
- untrusted dylib/plugin loading;
- release-workflow compromise or mutable action references;
- signing/notarization bypasses that allow an untrusted artifact to be published as stable;
- insecure temporary-file handling with meaningful local impact;
- permission requests materially broader than the feature needs.

Severity is based on realistic reachability and impact to the user's Mac/data. A local utility with persistent presence near system UI has a high bar for code execution, input capture, persistence, and release-chain issues.

## Known limitations and accepted risk

- M0 test artifacts are ad-hoc signed and therefore do not receive normal Gatekeeper trust. They are explicitly non-release artifacts.
- The app currently uses a global `NSEvent` monitor for the `mouseMoved` event class only. Apple documents global event monitors as observational; key-related monitoring has additional Accessibility requirements. Keyboard, mouse-button, drag, and scroll event classes are prohibited by repository policy and CI baseline at M0. This movement-only monitor remains subject to real-device privacy/behavior validation.
- Yandex Music integration is not implemented. No private MediaRemote dependency is currently present.
- CodeQL and GitHub Dependency Review availability depends on GitHub repository/product entitlement. For this private user-owned repository, repository-local security gates must not assume those paid/public-repository features are available.

## Security validation

Every PR runs `scripts/security-audit.sh` plus compile/test/package checks. Stable releases additionally verify Developer ID signing, Hardened Runtime, App Sandbox entitlements, Apple notarization/stapling, Gatekeeper assessment, and DMG checksum generation.

Security checks are defense-in-depth; they do not prove absence of vulnerabilities. Material new capability or permission changes require a focused manual security review in addition to tests.
