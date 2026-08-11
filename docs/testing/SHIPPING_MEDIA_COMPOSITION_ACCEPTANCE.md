# Shipping Media Composition — Acceptance Evidence

Status: **CI-QUALIFIED — NEW TARGET-MAC GATE PENDING**

Authoritative implementation plan: `docs/superpowers/plans/2026-08-10-shipping-media-composition.md`.
Accepted transport dependency: `docs/testing/PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`.
Target procedure: `docs/testing/SHIPPING_MEDIA_COMPOSITION_TARGET_MAC.md`.

## Current frozen shipping candidate

The first physical shipping candidate exposed a real compact-idle resource regression. Production code was therefore changed and the physical acceptance candidate was re-frozen.

Current candidate:

- source SHA: `fdbe987d8f22768b2a75406c8f1e721fa1da2845`;
- GitHub Actions: CI `#693` / run `31472420797` — both jobs PASS;
- artifact: `NotchHub-shipping-media-candidate`;
- artifact ID: `9093958828`;
- Actions artifact size: `395069` bytes;
- Actions artifact digest: `sha256:f055bc87d1f2c8cafe0d3b57d9cf6cdf82d7a712bf85acf3317232679a9689b9`;
- contained DMG SHA-256: `6371e8695e30f06697d37d2d018e043674e8b27a44022e3d8e846d0e1dad01fd`;
- pinned adapter SHA: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- capability patch SHA-256: `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`.

Exact candidate sizes:

- executable: `313648 B`;
- physical app payload: `615854 B`;
- DMG: `408480 B`.

The immutable P0 baseline remains unchanged. The existing explicit M6.4 additive feature-size budget still passes; no runtime or size budget was widened because of target findings.

Later tests/collectors/runner/documentation commits do not replace this physical candidate. Any later shipping production/package/signing/entitlement/adapter/resource change requires another frozen candidate and fresh target evidence.

## Superseded first physical candidate and target finding

Superseded source `c19ce13c5321fce72464ddf0a5d9b1467f770db0` / CI #675 was structurally correct but started the media runtime unconditionally at application launch.

Its target run on `Mac16,8` / macOS 26.6 proved:

- preflight/signatures/Hardened Runtime/sandbox-only/system-library boundary — PASS;
- normal parent + adapter termination and no orphan — PASS;
- Accessibility / Input Monitoring / Automation / Screen Recording prompts — NONE;
- 10-minute CPU/RSS/thread accumulation — no accumulation;
- but compact/background combined RSS was approximately `80–86 MiB`, materially above the P0 whole-app idle/stability ceilings.

A second no-Now-Playing A/B measurement produced essentially the same footprint:

- active source combined RSS median/max: `80608/86320 KiB`;
- no-session combined RSS median/max: `80096/85552 KiB`;
- active source parent RSS median/max: `59592/62592 KiB`;
- no-session parent RSS median/max: `59808/61648 KiB`;
- no-session adapter RSS median/max: `20288/23904 KiB`.

This ruled out active track/artwork retention as the cause. The root cause was the always-on shipping composition itself: `AppDelegate` created and started `ShippingMediaRuntime` during application launch, so compact idle permanently owned the media observer and adapter process.

## Root-cause fix

The production fix was implemented under RED -> GREEN coverage without changing the accepted M6.3 process/wire/transport semantics.

New lifecycle:

- application launch remains compact and does **not** create `ShippingMediaRuntime`;
- `NotchPanelTransitionCoordinator` publishes a settled-presentation callback only after the matching transition completion;
- stale/reversed animation completions cannot publish a settled state;
- after a successfully settled `.expanded` transition, `AppDelegate` creates and starts one `ShippingMediaRuntime`;
- after a successfully settled `.compact` transition, `AppDelegate` stops and releases the runtime;
- app termination still stops/releases any active runtime before panel teardown.

This keeps process creation/teardown outside the animation path, avoids adapter churn on aborted hover expansions, and removes media observation from background compact idle.

TDD evidence:

- CI #690 — RED: new settled-presentation Swift test failed only because the callback did not exist;
- CI #693 — GREEN: both jobs PASS after the lifecycle implementation;
- CI #697 — compact parent-only collector contract PASS;
- CI #699 — RED for the superseded target-runner contract;
- CI #700 — GREEN for the new compact-vs-expanded target runner; both jobs PASS.

## Current acceptance contract

The shipping bundle still retains the accepted M6.4 security/package boundary:

- `NotchHubApp -> NotchHubMediaCore` linkage;
- exact pinned adapter script/framework/license/provenance in the app;
- candidate/probe tools absent from shipping output;
- one reviewed production `/usr/bin/perl` process boundary with typed commands only;
- App Sandbox as the only app entitlement and Hardened Runtime mandatory;
- no Accessibility, Input Monitoring, Automation, Screen Recording, networking, shell, AppleScript, synthetic-input, or player-specific fallback expansion;
- privacy-safe target evidence only.

The runtime acceptance boundary is now explicitly split:

1. **compact background** — parent-only measurement; the adapter must remain absent for the entire warmup/measurement window and P0 idle/stability ceilings remain directly applicable;
2. **expanded media feature** — exactly one owned adapter is expected only after a settled user expansion; parent+adapter cost is recorded separately as active feature evidence.

## Acceptance ledger

### `NH-MEDIA-SHIP-001` — shipping linkage and lifecycle ownership

Status: **PASS — DETERMINISTIC / FIXED AFTER TARGET FINDING**

`NotchHubApp` links `NotchHubMediaCore` and owns the media lifecycle. Media runtime ownership is now scoped to settled expanded presentation rather than application lifetime.

### `NH-MEDIA-SHIP-002` — exact production resources and provenance

Status: **PASS — DETERMINISTIC / HOSTED PREFLIGHT**

Exact pinned production resources ship; development probe/candidate tools remain absent.

### `NH-MEDIA-SHIP-003` — signatures, Hardened Runtime, sandbox-only entitlement

Status: **PASS — HOSTED PREFLIGHT / FRESH TARGET RECONFIRMATION PENDING**

CI verifies nested/top-level signatures, Hardened Runtime and exact sandbox-only app entitlement on the current candidate.

### `NH-MEDIA-SHIP-004` — executable dependency boundary

Status: **PASS — HOSTED PREFLIGHT / FRESH TARGET RECONFIRMATION PENDING**

The shipping executable links only expected system libraries.

### `NH-MEDIA-SHIP-005` — fail-closed bundle boundary

Status: **PASS — DETERMINISTIC**

Missing/invalid shipping resources/provenance fail closed without expanding authority.

### `NH-MEDIA-SHIP-006` — target owned-adapter lifecycle

Status: **PENDING CURRENT CANDIDATE**

Required fresh evidence:

- compact launch owns zero adapter processes;
- settled user expansion causes exactly one owned adapter to appear;
- normal application termination exits both parent and active adapter with no orphan.

### `NH-MEDIA-SHIP-007` — no sensitive permission prompts

Status: **PENDING CURRENT-CANDIDATE RECONFIRMATION**

The superseded candidate produced no prompts; current-candidate target acceptance must confirm the same posture.

### `NH-MEDIA-SHIP-008` — 60-second target resource evidence

Status: **PENDING CURRENT CANDIDATE**

Primary gate is compact parent-only steady evidence with the adapter absent throughout. Compare directly with the accepted P0 idle ceilings:

- CPU median <= `0.5%`;
- CPU max <= `2.0%`;
- RSS max <= `43008 KiB`;
- threads max <= `6`.

Expanded parent+adapter steady evidence is recorded separately as active feature cost and is not substituted for compact idle.

### `NH-MEDIA-SHIP-009` — approximately 10-minute target stability

Status: **PENDING CURRENT CANDIDATE**

Compact parent-only stability must keep the adapter absent throughout and satisfy the existing P0 stability ceilings:

- CPU median <= `0.5%`;
- CPU max <= `10.0%`;
- RSS max <= `45056 KiB`;
- RSS end-minus-start <= `+8192 KiB`;
- threads max <= `9`;
- thread end-minus-start <= `+2`.

### `NH-MEDIA-SHIP-010` — explicit artifact-size impact

Status: **PASS — DETERMINISTIC**

The current candidate remains inside the separately reviewed M6.4 additive feature-size budget over the unchanged immutable P0 baseline.

## Current decision

**DO NOT MERGE M6.4 YET.**

The target-discovered root cause has been fixed and deterministically qualified. PR #17 remains Draft until the current `fdbe987...` candidate passes compact background resources/stability, expanded adapter lifecycle/steady evidence, permission reconfirmation, and the ledger is explicitly changed to `ACCEPTED`.

Media UI, progress rendering, gesture/haptic/seek interaction, and additional-player compatibility remain outside M6.4.
