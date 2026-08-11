# Shipping Media Composition — Acceptance Evidence

Status: **TARGET-MAC PERF INVESTIGATION — LIFECYCLE/STABILITY PASS**

Authoritative implementation plan: `docs/superpowers/plans/2026-08-10-shipping-media-composition.md`.
Accepted transport dependency: `docs/testing/PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`.
Target procedure: `docs/testing/SHIPPING_MEDIA_COMPOSITION_TARGET_MAC.md`.

## Frozen shipping candidate

M6.4 deterministic/package qualification is frozen on this exact shipping artifact:

- source SHA: `c19ce13c5321fce72464ddf0a5d9b1467f770db0`;
- GitHub Actions: CI `#675` / run `31408757149` — both jobs PASS;
- artifact: `NotchHub-shipping-media-candidate`;
- artifact ID: `9070996306`;
- Actions artifact size: `393164` bytes;
- Actions artifact digest: `sha256:c3b279153b8abf75ab77fa2f478888ae1fe9bad6bfdbf64665567bf713b8035d`;
- contained DMG SHA-256: `ccf8a503515d382c206c6211606ca6401ba33114863a30721e134c1a45af04b9`;
- pinned adapter SHA: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- capability patch SHA-256: `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`.

Later target-acceptance tooling/tests/documentation commits do not replace this physical shipping candidate. Any later change to shipping production code, `Package.swift` shipping linkage, packaging/signing, app/framework entitlements, security policy affecting the runtime boundary, pinned adapter/patch, or shipped resources requires a new frozen candidate and fresh target evidence.

## Deterministic artifact evidence

The exact published candidate records:

- executable: `312816 B`;
- physical app payload: `615022 B`;
- DMG: `406618 B`.

The immutable P0 `v0.1.0` baseline remains unchanged. M6.4 uses a separate reviewed additive feature-size budget:

- executable allowance: `65536 B`;
- app allowance: `360448 B`;
- DMG allowance: `327680 B`.

CI #675 passes the additive feature-size gate. The budget is explicit and feature-scoped; no baseline value was rewritten.

## Hosted preflight evidence

CI #675 runs the real `scripts/shipping_media_acceptance.py preflight` against the built shipping `NotchHub.app` and records:

- exact source/adapter/patch provenance;
- shipping resources present;
- strict deep top-level code-sign verification;
- nested `MediaRemoteAdapter.framework` signature verification;
- Hardened Runtime present;
- effective entitlements exactly `{ com.apple.security.app-sandbox = true }`;
- shipping executable linked only to system libraries;
- development media tools absent from the shipping app;
- required adapter capability symbol present.

Hosted runner resource magnitudes are not target-Mac acceptance and are not used as CPU/RSS/thread ceilings.

## First target-Mac shipping run — 2026-08-11

The frozen candidate was run on the primary target `Mac16,8` / macOS `26.6` through the exact-DMG target runner.

Preflight passed source/adapter/patch provenance, resources, strict signatures, nested signature, Hardened Runtime, exact sandbox-only entitlement, system-only executable libraries, development-tool exclusion, and adapter capability symbol verification.

Steady evidence:

- warmup `10s`;
- `60` samples at `1s` intervals;
- parent CPU median/max: `0.0/3.2%`;
- adapter CPU median/max: `0.0/1.0%`;
- combined CPU median/max upper bounds: `0.0/4.2%`;
- parent RSS median/max: `59592/62592 KiB`;
- adapter RSS median/max: `21016/23728 KiB`;
- combined RSS median/max upper bounds: `80608/86320 KiB`;
- combined thread median/max upper bounds: `5/11`.

Stability evidence:

- warmup `10s`;
- `120` samples at `5s` intervals over `600s`;
- parent CPU median/max: `0.0/3.1%`;
- adapter CPU median/max: `0.0/0.0%`;
- combined CPU median/max upper bounds: `0.0/3.1%`;
- parent RSS median/max: `58192/60528 KiB`;
- adapter RSS median/max: `20224/23712 KiB`;
- combined RSS median/max upper bounds: `78416/84240 KiB`;
- parent RSS start/end: `59024 -> 52192 KiB` (`-6832 KiB`);
- adapter RSS start/end: `20320 -> 20064 KiB` (`-256 KiB`);
- combined RSS start/end: `79344 -> 72256 KiB` (`-7088 KiB`);
- parent thread start/end: `3 -> 3`;
- adapter thread start/end: `2 -> 2`;
- combined thread start/end: `5 -> 5`;
- combined transient thread max upper bound: `13`.

Normal termination evidence reports `parentExited = true`, `adapterExited = true`, and `orphanProcessDetected = false`.

Human permission observation for the complete physical run:

- Accessibility — NONE;
- Input Monitoring — NONE;
- Automation — NONE;
- Screen Recording — NONE.

The run therefore shows excellent CPU behavior, clean lifecycle, and no sustained RSS/thread accumulation. It also reveals a material absolute steady-state footprint increase relative to the accepted P0 whole-app ceilings. That increase is treated as a performance finding to investigate, not as justification to silently widen runtime budgets.

## Accepted composition contract

The CI-qualified implementation provides:

- `NotchHubApp -> NotchHubMediaCore` shipping linkage;
- app-owned `ShippingMediaRuntime` start/stop lifecycle;
- exact pinned production adapter script/framework/license/provenance inside `NotchHub.app`;
- candidate/probe helpers isolated in development-only targets and absent from shipping payload;
- one previously reviewed production `/usr/bin/perl` process boundary with typed media commands only;
- no new Accessibility, Input Monitoring, Automation, Screen Recording, network, shell, AppleScript, synthetic-input, or player-specific fallback surface;
- App Sandbox-only entitlement and Hardened Runtime retained;
- event-driven production behavior retained;
- privacy-safe acceptance evidence with no title/artist/album/artwork/listening-history retention.

## Acceptance ledger

### `NH-MEDIA-SHIP-001` — shipping linkage and lifecycle ownership

Status: **PASS — DETERMINISTIC**

`NotchHubApp` links `NotchHubMediaCore`; the application composition root owns one `ShippingMediaRuntime`, starts it after app launch, and stops/releases it before app termination.

### `NH-MEDIA-SHIP-002` — exact production resources and provenance

Status: **PASS — DETERMINISTIC / HOSTED PREFLIGHT**

The exact pinned adapter script/framework/license/provenance are packaged. `MediaBridgeProbe`, `MediaTransportCandidate`, `ProductionMediaTransportCandidate.app`, and `MediaRemoteAdapterTestClient` remain absent from shipping output.

### `NH-MEDIA-SHIP-003` — signatures, Hardened Runtime, sandbox-only entitlement

Status: **PASS — HOSTED + TARGET PREFLIGHT**

Nested framework and top-level app signatures verify. Hardened Runtime is present and effective app entitlements remain exactly App Sandbox only.

### `NH-MEDIA-SHIP-004` — executable dependency boundary

Status: **PASS — HOSTED + TARGET PREFLIGHT**

`NotchHub` has no unexpected non-system dynamic-library dependency.

### `NH-MEDIA-SHIP-005` — fail-closed bundle boundary

Status: **PASS — DETERMINISTIC**

Shipping bundle path/provenance validation is exact and fails closed when resources/provenance are missing or invalid. No fallback path expands permissions or runtime authority.

### `NH-MEDIA-SHIP-006` — target owned-adapter lifecycle

Status: **PASS — TARGET-MAC**

The exact frozen DMG launches on `Mac16,8` / macOS 26.6, the shipping app owns the expected adapter child, normal AppKit termination exits both parent and adapter, and `orphanProcessDetected = false`.

### `NH-MEDIA-SHIP-007` — no sensitive permission prompts

Status: **PASS — TARGET-MAC HUMAN OBSERVATION**

During the complete physical run:

- Accessibility — NONE;
- Input Monitoring — NONE;
- Automation — NONE;
- Screen Recording — NONE.

### `NH-MEDIA-SHIP-008` — 60-second target resource evidence

Status: **BLOCKED — PERFORMANCE INVESTIGATION**

The exact 60-s evidence is valid and CPU behavior is excellent, but the absolute footprint materially exceeds the existing P0 whole-app target ceilings:

- combined RSS max: `86320 KiB` versus P0 idle/stability whole-app ceilings `43008/45056 KiB`;
- parent RSS max alone: `62592 KiB`;
- combined transient threads max: `11` versus P0 idle/stability ceilings `6/9`.

These P0 ceilings predate the accepted external media transport and are not automatically transferable as an additive transport budget. Crossing them nevertheless requires investigation before M6.4 acceptance. No runtime budget is widened from this single run.

Next diagnostic question: distinguish the steady cost of the always-on observer/process infrastructure from the incremental cost of an active media-session payload/artwork path using the same frozen candidate and a short no-session target measurement.

### `NH-MEDIA-SHIP-009` — approximately 10-minute target stability

Status: **PASS — STABILITY BEHAVIOR / M6.4 STILL BLOCKED BY `NH-MEDIA-SHIP-008`**

The target runner produced exactly 120 five-second stability samples after warmup. CPU median remained `0.0%`; combined RSS decreased by `7088 KiB`; combined thread start/end remained `5 -> 5`; normal app/adapter termination passed and no orphan was detected. There is no sustained CPU signal, RSS accumulation, or thread accumulation in this measured run.

### `NH-MEDIA-SHIP-010` — explicit artifact-size impact

Status: **PASS — DETERMINISTIC**

Shipping size impact is explicitly measured and enforced by a separate M6.4 additive feature budget over the unchanged immutable P0 baseline. The candidate passes that gate in CI #675.

## Current decision

**DO NOT MERGE M6.4 YET.**

Physical lifecycle, permissions, and long-run stability pass. The only remaining acceptance blocker is the absolute target-Mac resource footprint exposed by `NH-MEDIA-SHIP-008`. Investigate and optimize before accepting a new runtime budget. If production code changes, freeze a new shipping candidate and repeat the relevant target gates.

Media UI, progress rendering, gestures/haptics/seek interaction, and new player compatibility claims remain outside M6.4.
