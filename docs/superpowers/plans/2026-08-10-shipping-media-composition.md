# Shipping Media Composition — Implementation Plan

Status: **IN PROGRESS**
Date: 2026-08-10
Base: `main` at `e967393ea4deb574883f0234465313cfc5cdd71a`

## Goal

Compose the already accepted M6.3 production system-media transport into the real shipping `NotchHub.app` without adding Media UI and without weakening the accepted security/performance boundaries.

The slice must make the shipping app own the production media lifecycle, package the exact pinned MediaRemote adapter resources, and produce fresh shipping evidence for code signing, entitlements, bundle provenance, artifact size, process lifecycle, and target-Mac resources.

## Fixed inputs

- accepted M6.3 transport candidate source: `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`;
- pinned adapter commit: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- capability patch SHA-256: `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`;
- production subprocess executable remains exactly `/usr/bin/perl`;
- App Sandbox remains the only application entitlement;
- Hardened Runtime remains mandatory;
- no Accessibility, Input Monitoring, Automation, Screen Recording, network, shell, AppleScript, synthetic-input, player-specific fallback, or private-framework loading inside the NotchHub process;
- no media title/artist/album/artwork/listening-history telemetry or persistence.

## Explicitly out of scope

- compact/expanded Media UI;
- progress rendering;
- gestures/haptics for media controls;
- volume control;
- Apple Music/Spotify compatibility claims;
- broader permissions or entitlements;
- changing the accepted M6.3 wire/process/transport semantics unless a shipping-composition defect proves that change necessary.

## Architecture

`NotchHubApp` becomes the application composition root for the media subsystem.

- `NotchHubApp` depends on `NotchHubCore` and `NotchHubMediaCore`.
- A narrow public shipping runtime facade in `NotchHubMediaCore` owns the existing internal `MediaRemoteSystemTransport -> SystemMediaBridge -> MediaSessionController` chain.
- The app delegate starts that facade at application launch and stops it before application termination.
- The facade resolves only resources under the real `NotchHub.app/Contents/Resources` directory and fails closed when provenance/resources are invalid or absent.
- Existing accepted transport implementation files should remain unchanged unless a concrete failing test requires otherwise.

## Shipping resource contract

`NotchHub.app/Contents/Resources` must contain exactly the production assets required by the accepted transport:

- `mediaremote-adapter.pl`;
- `MediaRemoteAdapter.framework`;
- `MediaRemoteAdapter-LICENSE.txt`;
- privacy-safe media transport provenance containing source commit, pinned adapter commit, and capability patch SHA-256.

Development-only `MediaBridgeProbe`, `MediaTransportCandidate`, and `MediaRemoteAdapterTestClient` must remain absent.

The nested framework must be explicitly signed before the top-level application is signed. The final app must continue to pass strict deep signature verification, Hardened Runtime verification, exact sandbox-only entitlement verification, DMG verification, and app-executable dynamic-library allowlisting.

## TDD / verification sequence

1. RED: add deterministic tests for shipping bundle path/provenance resolution before the shipping resolver exists.
2. GREEN: add the narrow runtime facade and bundle resolver without packaging changes.
3. RED: add executable packaging/security policy tests requiring shipping linkage, exact resources, provenance, nested signing, and lifecycle ownership.
4. GREEN: update `Package.swift`, app composition, packaging, security policy, and CI verification with the smallest required changes.
5. Run the unchanged release size gate first and record the real feature cost. Do not pre-widen the P0 budget.
6. If the unchanged size gate fails, optimize first. Any later budget decision must be based on exact measured shipping artifacts and explicitly documented; no silent allowance change.
7. Produce a shipping candidate artifact from the exact code head for target-Mac acceptance.
8. Target Mac: verify launch, owned adapter lifecycle, no sensitive permission prompts, 60-second steady resources, approximately 10-minute stability, clean app shutdown, and no orphan adapter process.
9. After physical PASS, update acceptance/state/roadmap/changelog, run fresh exact-head CI and final change review, then ship through a separate shipping checkpoint.

## Acceptance IDs

- `NH-MEDIA-SHIP-001` — `NotchHubApp` links `NotchHubMediaCore` and owns media lifecycle.
- `NH-MEDIA-SHIP-002` — exact pinned production resources and provenance are present; development probe/candidate assets are absent.
- `NH-MEDIA-SHIP-003` — nested framework and top-level app signatures verify; Hardened Runtime and sandbox-only entitlement remain exact.
- `NH-MEDIA-SHIP-004` — shipping app executable has no unexpected non-system dynamic-library dependency.
- `NH-MEDIA-SHIP-005` — missing/invalid bundle provenance/resources fail closed without crash/restart loop.
- `NH-MEDIA-SHIP-006` — target app launch owns exactly the expected adapter process boundary and terminates it cleanly.
- `NH-MEDIA-SHIP-007` — no Accessibility/Input Monitoring/Automation/Screen Recording prompts.
- `NH-MEDIA-SHIP-008` — 60-second target resource evidence is acceptable.
- `NH-MEDIA-SHIP-009` — approximately 10-minute target stability shows no sustained CPU/RSS/thread growth and no orphan process.
- `NH-MEDIA-SHIP-010` — artifact-size impact is measured explicitly; no budget is silently widened.
