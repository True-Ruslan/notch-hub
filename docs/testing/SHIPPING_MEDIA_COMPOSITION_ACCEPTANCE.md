# Shipping Media Composition — Acceptance Evidence

Status: **CI-QUALIFIED — TARGET-MAC GATE PENDING**

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

Status: **PASS — HOSTED PREFLIGHT**

Nested framework and top-level app signatures verify. Hardened Runtime is present and effective app entitlements remain exactly App Sandbox only.

### `NH-MEDIA-SHIP-004` — executable dependency boundary

Status: **PASS — HOSTED PREFLIGHT**

`NotchHub` has no unexpected non-system dynamic-library dependency.

### `NH-MEDIA-SHIP-005` — fail-closed bundle boundary

Status: **PASS — DETERMINISTIC**

Shipping bundle path/provenance validation is exact and fails closed when resources/provenance are missing or invalid. No fallback path expands permissions or runtime authority.

### `NH-MEDIA-SHIP-006` — target owned-adapter lifecycle

Status: **PENDING TARGET-MAC**

Required physical evidence:

- exact frozen DMG launches on `Mac16,8` / macOS 26.6;
- running shipping app owns exactly one expected adapter child;
- normal AppKit termination exits the app and the owned adapter;
- `orphanProcessDetected = false`.

### `NH-MEDIA-SHIP-007` — no sensitive permission prompts

Status: **PENDING HUMAN OBSERVATION**

During the complete physical run confirm:

- Accessibility — NONE;
- Input Monitoring — NONE;
- Automation — NONE;
- Screen Recording — NONE.

### `NH-MEDIA-SHIP-008` — 60-second target resource evidence

Status: **PENDING TARGET-MAC**

The target runner must produce exactly 60 steady parent+adapter samples after warmup. Acceptance is evidence-based against the existing whole-app baseline and the observed composition cost; hosted-runner magnitudes are not substituted.

### `NH-MEDIA-SHIP-009` — approximately 10-minute target stability

Status: **PENDING TARGET-MAC**

The target runner must produce exactly 120 five-second stability samples after warmup, with no sustained CPU signal, RSS accumulation, thread accumulation, premature exit, or orphan adapter.

### `NH-MEDIA-SHIP-010` — explicit artifact-size impact

Status: **PASS — DETERMINISTIC**

Shipping size impact is explicitly measured and enforced by a separate M6.4 additive feature budget over the unchanged immutable P0 baseline. The candidate passes that gate in CI #675.

## Current decision

**DO NOT MERGE M6.4 YET.**

M6.4 is deterministically qualified and has an immutable exact shipping candidate, but physical acceptance remains incomplete until `NH-MEDIA-SHIP-006...009` pass on the primary target. PR #17 must remain Draft until those target results are recorded here and the final decision is explicit.

Media UI, progress rendering, gestures/haptics/seek interaction, and new player compatibility claims remain outside M6.4.
