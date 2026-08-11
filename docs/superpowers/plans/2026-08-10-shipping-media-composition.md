# Shipping Media Composition — Implementation Plan

Status: **IN PROGRESS — TARGET PERFORMANCE INVESTIGATION**
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
- no media title/artist/album/artwork/listening-history telemetry or persistence;
- immutable P0 runtime ceilings are not widened merely because a new feature exceeds them.

## Explicitly out of scope

- compact/expanded Media UI;
- progress rendering;
- gestures/haptics for media controls;
- volume control;
- Apple Music/Spotify compatibility claims;
- broader permissions or entitlements;
- changing the accepted M6.3 wire/process/transport semantics unless a shipping-composition defect proves that change necessary.

## Current architecture

`NotchHubApp` is the application composition root for the media subsystem.

- `NotchHubApp` depends on `NotchHubCore` and `NotchHubMediaCore`.
- A narrow public `ShippingMediaRuntime` facade owns the internal `MediaRemoteSystemTransport -> SystemMediaBridge -> MediaSessionController` chain.
- The original app-lifetime start was rejected after target-Mac evidence showed an unnecessary always-on adapter/background cost.
- Current production lifecycle is presentation-scoped: application launch remains compact and creates no media runtime; a matching successfully settled `.expanded` transition creates/starts one runtime; a matching settled `.compact` transition stops/releases it.
- Stale/reversed transition completions cannot start media.
- App termination stops/releases any active runtime before panel teardown.
- Resource resolution remains restricted to the real `NotchHub.app/Contents/Resources` boundary and fails closed.

## Shipping resource contract

`NotchHub.app/Contents/Resources` contains only the production assets required by the accepted transport:

- `mediaremote-adapter.pl`;
- `MediaRemoteAdapter.framework`;
- `MediaRemoteAdapter-LICENSE.txt`;
- privacy-safe media transport provenance containing source commit, pinned adapter commit, and capability patch SHA-256.

Development-only `MediaBridgeProbe`, `MediaTransportCandidate`, `ProductionMediaTransportCandidate.app`, and `MediaRemoteAdapterTestClient` remain absent.

The nested framework is explicitly signed before the top-level application. The final app must continue to pass strict deep signature verification, Hardened Runtime verification, exact sandbox-only entitlement verification, DMG verification, and app-executable dynamic-library allowlisting.

## TDD / verification sequence

Completed sequence:

1. RED/GREEN shipping bundle path/provenance resolver coverage.
2. RED/GREEN shipping linkage/package/security/lifecycle policy.
3. Exact feature-size measurement; candidate-only helpers isolated from shipping after measurable binary inflation.
4. Explicit additive M6.4 artifact-size allowance over the unchanged P0 artifact baseline.
5. Shipping preflight/resource/teardown collector and exact-DMG target runner.
6. First physical candidate exposed approximately `80–86 MiB` combined compact/background RSS.
7. No-session A/B produced essentially the same footprint, ruling out active metadata/artwork retention.
8. RED/GREEN production lifecycle fix moved media runtime from application lifetime to matching settled expanded presentation.
9. Compact parent-only collector added; any owned adapter during compact measurement fails closed.
10. Current candidate physically confirmed zero adapter while compact, one adapter while expanded, clean normal teardown/no orphan, and no sensitive permission prompts.

Current investigation:

11. Current compact parent still measures approximately `59–66 MiB`, exceeding P0 idle/stability RSS ceilings even with the adapter absent.
12. Run the exact final M6.3 shell-only shipping comparator (`30de94c0...`, CI #594, artifact ID `9063213178`) through the same parent-only 60-s/10-minute sampler.
13. If shell-only is also approximately `59–66 MiB`, trace a pre-M6.4 shell/interaction regression before changing media architecture.
14. If shell-only returns near P0 while M6.4 remains approximately `59–66 MiB`, design a deeper lazy media-isolation boundary and implement it under TDD.
15. Re-freeze and repeat relevant target gates after any production change.
16. Only after all stable M6.4 gates pass: update final docs/CHANGELOG, run exact-head CI and change review, mark PR #17 Ready and merge.

## Current frozen M6.4 candidate

- source `fdbe987d8f22768b2a75406c8f1e721fa1da2845`;
- CI #693 / run `31472420797` — PASS;
- artifact ID `9093958828`;
- artifact digest `sha256:f055bc87d1f2c8cafe0d3b57d9cf6cdf82d7a712bf85acf3317232679a9689b9`;
- DMG SHA-256 `6371e8695e30f06697d37d2d018e043674e8b27a44022e3d8e846d0e1dad01fd`.

## Acceptance IDs

- `NH-MEDIA-SHIP-001` — `NotchHubApp` links `NotchHubMediaCore` and owns media lifecycle — **PASS**.
- `NH-MEDIA-SHIP-002` — exact pinned production resources/provenance present; development assets absent — **PASS**.
- `NH-MEDIA-SHIP-003` — nested/top-level signatures, Hardened Runtime and sandbox-only entitlement — **PASS**.
- `NH-MEDIA-SHIP-004` — no unexpected non-system dynamic-library dependency — **PASS**.
- `NH-MEDIA-SHIP-005` — missing/invalid resources/provenance fail closed — **PASS**.
- `NH-MEDIA-SHIP-006` — target compact/expanded adapter lifecycle and clean teardown — **PASS**.
- `NH-MEDIA-SHIP-007` — no Accessibility/Input Monitoring/Automation/Screen Recording prompts — **PASS**.
- `NH-MEDIA-SHIP-008` — 60-second target resource evidence — **BLOCKED on compact absolute RSS; small idle CPU-max miss also recorded**.
- `NH-MEDIA-SHIP-009` — approximately 10-minute target stability — **BLOCKED on absolute RSS; drift/thread stability otherwise passes**.
- `NH-MEDIA-SHIP-010` — artifact-size impact measured explicitly with no silent budget widening — **PASS**.

## Merge boundary

PR #17 remains Draft. M6.4 must not merge while `NH-MEDIA-SHIP-008` or `NH-MEDIA-SHIP-009` is blocked.
