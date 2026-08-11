# Shipping Media Composition — Implementation Plan

Status: **COMPLETED — M6.4 ACCEPTED; FINAL PR INTEGRATION PENDING**
Date: 2026-08-10
Base: `main` at `e967393ea4deb574883f0234465313cfc5cdd71a`

## Goal

Compose the already accepted M6.3 production system-media transport into the real shipping `NotchHub.app` without adding Media UI and without weakening the accepted security/performance boundaries.

The slice makes the shipping app own the production media lifecycle, packages the exact pinned MediaRemote adapter resources, and provides shipping evidence for code signing, entitlements, bundle provenance, artifact size, process lifecycle, and target-Mac resources.

## Fixed inputs

- accepted M6.3 transport candidate source: `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`;
- pinned adapter commit: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- capability patch SHA-256: `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`;
- production subprocess executable remains exactly `/usr/bin/perl`;
- App Sandbox remains the only application entitlement;
- Hardened Runtime remains mandatory;
- no Accessibility, Input Monitoring, Automation, Screen Recording, network, shell, AppleScript, synthetic-input, player-specific fallback, or private-framework loading inside the NotchHub process;
- no media title/artist/album/artwork/listening-history telemetry or persistence;
- immutable P0 baseline data is never rewritten merely because later target measurements differ.

## Explicitly out of scope

- compact/expanded Media UI;
- progress rendering;
- gestures/haptics for media controls;
- volume control;
- Apple Music/Spotify compatibility claims;
- broader permissions or entitlements;
- changing the accepted M6.3 wire/process/transport semantics unless a shipping-composition defect proves that change necessary.

## Accepted architecture

`NotchHubApp` is the application composition root for the media subsystem.

- `NotchHubApp` depends on `NotchHubCore` and `NotchHubMediaCore`.
- A narrow public `ShippingMediaRuntime` facade owns the internal `MediaRemoteSystemTransport -> SystemMediaBridge -> MediaSessionController` chain.
- The original app-lifetime start was rejected after target-Mac evidence showed an unnecessary always-on adapter/background cost.
- Accepted production lifecycle is presentation-scoped: application launch remains compact and creates no media runtime; a matching successfully settled `.expanded` transition creates/starts one runtime; a matching settled `.compact` transition stops/releases it.
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

The nested framework is explicitly signed before the top-level application. The final app passes strict deep signature verification, Hardened Runtime verification, exact sandbox-only entitlement verification, DMG verification, and app-executable dynamic-library allowlisting.

## Completed TDD / verification sequence

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
11. Final M6.3 shell-only comparator reproduced the same current compact RSS class without M6.4 media linkage, disproving M6.4 static linkage as the source of the historical absolute-RSS discrepancy.
12. Exact same-session immutable `v0.1.0` vs M1 #319 comparator measured RSS medians `60,144 KiB` vs `59,552 KiB`, disproving a persistent P0→M1 memory regression.
13. Exact direct same-session immutable `v0.1.0` vs frozen M6.4 comparator measured baseline RSS median/max `61,504/67,104 KiB` and candidate `62,256/65,232 KiB`; candidate delta `+752 KiB` median and `-1,872 KiB` max, CPU candidate `0.0/0.0%` vs baseline `0.0/6.7%`, threads identical `3/4`.
14. The exact baseline's own repeated same-day median varied by `1,360 KiB`, larger than the candidate median delta. There is no material directionally consistent M6.4 steady-memory regression.
15. Independent 10-minute M6.4 compact stability passes with RSS drift `+2,672 KiB` inside the retained `+8,192 KiB` growth gate and threads `3 -> 3`.
16. `PERFORMANCE.md` was corrected from evidence: immutable historical P0 numbers remain preserved, while cross-session absolute `ps rss` and isolated CPU maxima are no longer standalone gates; same-session immutable-baseline steady comparison plus long-run growth remain the acceptance mechanism.
17. `NH-MEDIA-SHIP-008/009` resolved PASS without rewriting `performance/baseline-v0.1.0.json` or silently raising a numeric runtime budget.
18. Acceptance/state/roadmap/changelog synchronized; final exact-head CI/change review and PR integration remain.

Comparator tooling evidence:

- shell-only comparator: RED #705 -> GREEN #709;
- P0 vs M1 comparator: RED #712 -> GREEN policy #714, exact-head #718 PASS;
- direct P0 vs M6.4 comparator: RED #720 -> GREEN #721 PASS.

## Accepted frozen M6.4 candidate

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
- `NH-MEDIA-SHIP-008` — 60-second target resource evidence — **PASS** under exact same-session immutable-baseline comparison.
- `NH-MEDIA-SHIP-009` — approximately 10-minute target stability — **PASS**; RSS/thread growth bounded and no compact adapter/orphan.
- `NH-MEDIA-SHIP-010` — artifact-size impact measured explicitly with no silent budget widening — **PASS**.

## Merge boundary

All M6.4 acceptance gates pass. PR #17 may leave Draft only after the final documentation/policy head passes required CI and independent change review. Then merge via squash into protected `main`, verify the merge/main CI, and proceed to Media UI as a separate slice.
