# Shipping Media Composition — Acceptance Evidence

Status: **TARGET-MAC LIFECYCLE/PERMISSIONS PASS — COMPACT RSS BLOCKED — SHELL-ONLY COMPARATOR PENDING**

Authoritative implementation plan: `docs/superpowers/plans/2026-08-10-shipping-media-composition.md`.
Accepted transport dependency: `docs/testing/PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`.
Target procedure: `docs/testing/SHIPPING_MEDIA_COMPOSITION_TARGET_MAC.md`.

## Current frozen shipping candidate

The current physical candidate is:

- source SHA: `fdbe987d8f22768b2a75406c8f1e721fa1da2845`;
- GitHub Actions: CI `#693` / run `31472420797` — both jobs PASS;
- artifact: `NotchHub-shipping-media-candidate`;
- artifact ID: `9093958828`;
- Actions artifact digest: `sha256:f055bc87d1f2c8cafe0d3b57d9cf6cdf82d7a712bf85acf3317232679a9689b9`;
- contained DMG SHA-256: `6371e8695e30f06697d37d2d018e043674e8b27a44022e3d8e846d0e1dad01fd`;
- pinned adapter SHA: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- capability patch SHA-256: `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`;
- executable: `313648 B`;
- physical app payload: `615854 B`;
- DMG: `408480 B`.

The immutable P0 runtime and artifact baselines remain unchanged. No runtime budget has been widened from target findings.

Later acceptance tooling/tests/documentation commits do not replace this physical candidate. Any later production/package/signing/entitlement/adapter/resource change requires a new frozen candidate and fresh target evidence.

## Superseded always-on candidate finding

The first candidate `c19ce13c5321fce72464ddf0a5d9b1467f770db0` started `ShippingMediaRuntime` unconditionally at application launch and kept the media adapter alive while compact.

Target evidence showed approximately `80–86 MiB` combined RSS whether Now Playing was active or absent. The no-session A/B result therefore ruled out active track/artwork retention and identified the always-on media lifecycle as a real background cost.

The production fix moved media ownership to settled presentation state:

- compact launch creates no `ShippingMediaRuntime`;
- matching settled `.expanded` starts one runtime;
- matching settled `.compact` stops/releases it;
- stale/reversed transition completions cannot start media;
- app termination still stops any active runtime before panel teardown.

TDD/CI evidence:

- CI #690 — RED for missing settled-presentation callback;
- CI #693 — GREEN production lifecycle fix;
- CI #697 — compact parent-only collector contract PASS;
- CI #699 — RED for superseded target-runner contract;
- CI #700 — GREEN compact-vs-expanded target runner;
- CI #703 — docs/tooling head remained fully GREEN.

## Current target-Mac evidence — 2026-08-11

Platform: `Mac16,8` / macOS `26.6`.

### Preflight

Current candidate target preflight PASS:

- source/adapter/patch provenance verified;
- resources verified;
- top-level and nested signatures verified;
- Hardened Runtime present;
- effective entitlement remains App Sandbox only;
- executable links only expected system libraries;
- development tools absent;
- adapter capability symbol verified.

### Compact steady — parent only

The panel remained untouched and the adapter stayed absent for the complete warmup and 60-s measurement.

- sample count: `60` at `1s`;
- adapter absent: `true`;
- CPU median/max: `0.0 / 2.4%`;
- RSS median/max: `59792 / 66160 KiB`;
- threads median/max: `3 / 4`.

P0 idle ceilings are:

- CPU median <= `0.5%` — PASS;
- CPU max <= `2.0%` — **FAIL (`2.4%`)**;
- RSS max <= `43008 KiB` — **FAIL (`66160 KiB`)**;
- threads max <= `6` — PASS.

The CPU-max miss is small and transient; the material blocker is the approximately `23 MiB` RSS excess over the existing idle ceiling.

### Compact stability — parent only

The adapter stayed absent for the complete warmup and 10-minute measurement.

- sample count: `120` at `5s`;
- adapter absent: `true`;
- CPU median/max: `0.0 / 3.3%`;
- RSS median/max: `59024 / 60320 KiB`;
- RSS start/end: `56304 -> 58976 KiB` (`+2672 KiB`);
- threads median/max: `3 / 4`;
- threads start/end: `3 -> 3`.

P0 stability ceilings are:

- CPU median <= `0.5%` — PASS;
- CPU max <= `10.0%` — PASS;
- RSS max <= `45056 KiB` — **FAIL (`60320 KiB`)**;
- RSS positive drift <= `8192 KiB` — PASS (`+2672 KiB`);
- threads max <= `9` — PASS;
- thread positive drift <= `+2` — PASS (`0`).

There is no sustained CPU or thread growth and RSS drift remains bounded. Acceptance is still blocked by the absolute compact RSS footprint.

### Expanded steady — active feature cost

After a real user hover settled the panel expanded, the collector found the expected owned adapter and recorded 60 samples.

Parent:

- CPU median/max: `0.0 / 0.1%`;
- RSS median/max: `73168 / 78624 KiB`;
- threads median/max: `3 / 5`.

Adapter:

- CPU median/max: `0.0 / 0.7%`;
- RSS median/max: `23456 / 26208 KiB`;
- threads median/max: `2 / 5`.

Conservative combined upper bounds:

- CPU median/max: `0.0 / 0.8%`;
- RSS median/max: `96624 / 104832 KiB`;
- threads median/max: `5 / 10`.

This is active-feature evidence, not a replacement for compact idle budgets. No new expanded runtime ceiling is invented from a single run.

### Lifecycle and permissions

Compact run:

- adapter remained absent throughout;
- parent exited normally.

Expanded run:

- exactly one owned adapter was discovered by the existing fail-closed collector;
- `parentExited = true`;
- `adapterExited = true`;
- `orphanProcessDetected = false`.

Human permission observation:

- Accessibility — NONE;
- Input Monitoring — NONE;
- Automation — NONE;
- Screen Recording — NONE.

## Acceptance ledger

### `NH-MEDIA-SHIP-001` — shipping linkage and lifecycle ownership

Status: **PASS — DETERMINISTIC / TARGET-CONFIRMED**

`NotchHubApp` links `NotchHubMediaCore`; runtime ownership is scoped to settled expanded presentation rather than application lifetime.

### `NH-MEDIA-SHIP-002` — exact production resources and provenance

Status: **PASS — DETERMINISTIC / HOSTED + TARGET PREFLIGHT**

Exact pinned production resources ship and development probe/candidate tools remain absent.

### `NH-MEDIA-SHIP-003` — signatures, Hardened Runtime, sandbox-only entitlement

Status: **PASS — HOSTED + TARGET PREFLIGHT**

Nested/top-level signatures verify; Hardened Runtime is present and App Sandbox remains the only app entitlement.

### `NH-MEDIA-SHIP-004` — executable dependency boundary

Status: **PASS — HOSTED + TARGET PREFLIGHT**

The shipping executable links only expected system libraries.

### `NH-MEDIA-SHIP-005` — fail-closed bundle boundary

Status: **PASS — DETERMINISTIC**

Missing/invalid shipping resources/provenance fail closed without expanding runtime authority.

### `NH-MEDIA-SHIP-006` — target owned-adapter lifecycle

Status: **PASS — TARGET-MAC**

Compact owns zero adapter processes; settled expansion produces the expected owned adapter; normal termination exits parent and active adapter with no orphan.

### `NH-MEDIA-SHIP-007` — no sensitive permission prompts

Status: **PASS — TARGET-MAC HUMAN OBSERVATION**

Accessibility, Input Monitoring, Automation and Screen Recording prompts were all absent.

### `NH-MEDIA-SHIP-008` — 60-second target resource evidence

Status: **BLOCKED — COMPACT ABSOLUTE RESOURCE FOOTPRINT**

Adapter absence is confirmed and CPU median/thread behavior are good, but compact parent RSS max is `66160 KiB` versus the accepted P0 idle ceiling `43008 KiB`. CPU max also transiently reaches `2.4%` versus the `2.0%` idle ceiling. No runtime budget is widened.

### `NH-MEDIA-SHIP-009` — approximately 10-minute target stability

Status: **BLOCKED — ABSOLUTE RSS; STABILITY SHAPE PASSES**

No adapter, CPU median `0.0%`, RSS drift only `+2672 KiB`, and threads `3 -> 3` show no sustained growth. Absolute RSS max `60320 KiB` still exceeds the P0 stability ceiling `45056 KiB`.

### `NH-MEDIA-SHIP-010` — explicit artifact-size impact

Status: **PASS — DETERMINISTIC**

The candidate remains inside the separately reviewed M6.4 additive feature-size budget over the unchanged immutable P0 baseline.

## Next diagnostic — shell-only comparator

The remaining question is whether the approximately `59–66 MiB` compact parent footprint is caused by M6.4 static media composition or predates M6.4.

Use the final M6.3 exact-head shipping artifact where `NotchHubApp` still depends only on `NotchHubCore`:

- source `30de94c0cb6ea17dc21bd366404937db2bc73783`;
- CI #594 / run `31389611697`;
- artifact `NotchHub-dmg` / ID `9063213178`;
- Actions digest `sha256:9ab40b4101a013e11570fa013f49d2a42a3c5198251210a337b2985fc64e2a0d`;
- contained DMG SHA-256 `b1da6681ce49da3c34b3720c39caa32c3fc4508e0abf7d209b63b46f78713fb7`.

The development-only `scripts/run-shell-only-target-diagnostic.sh` exact-pins that DMG and applies the same parent-only 60-s/10-minute collector.

Interpretation:

- if shell-only RSS is also approximately `59–66 MiB`, the regression predates M6.4 and must be traced to earlier shell/interaction work before changing media architecture;
- if shell-only returns near the accepted P0 range while M6.4 stays near `59–66 MiB`, static shipping media composition is the cause and requires deeper lazy isolation before M6.4 can be accepted.

## Current decision

**DO NOT MERGE M6.4 YET.**

Security, signatures, permissions, process lifecycle and long-run growth behavior pass. The remaining blocker is absolute compact RSS. Complete the exact M6.3 shell-only comparator before choosing the next production optimization.

Media UI, progress rendering, gesture/haptic/seek interaction and additional-player compatibility remain outside M6.4.
