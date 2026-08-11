# Shipping Media Composition — Acceptance Evidence

Status: **TARGET LIFECYCLE/PERMISSIONS PASS — FINAL SAME-SESSION M6.4 RSS COMPARATOR PENDING**

Authoritative implementation plan: `docs/superpowers/plans/2026-08-10-shipping-media-composition.md`.
Accepted transport dependency: `docs/testing/PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`.
Target procedure: `docs/testing/SHIPPING_MEDIA_COMPOSITION_TARGET_MAC.md`.

## Current frozen shipping candidate

Current candidate:

- source SHA: `fdbe987d8f22768b2a75406c8f1e721fa1da2845`;
- GitHub Actions: CI `#693` / run `31472420797` — both jobs PASS;
- artifact: `NotchHub-shipping-media-candidate`;
- artifact ID: `9093958828`;
- Actions artifact digest: `sha256:f055bc87d1f2c8cafe0d3b57d9cf6cdf82d7a712bf85acf3317232679a9689b9`;
- contained DMG SHA-256: `6371e8695e30f06697d37d2d018e043674e8b27a44022e3d8e846d0e1dad01fd`;
- pinned adapter SHA: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- capability patch SHA-256: `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`.

Exact candidate sizes:

- executable: `313648 B`;
- physical app payload: `615854 B`;
- DMG: `408480 B`.

The immutable P0 baseline remains unchanged. The explicit M6.4 additive feature-size budget passes. No runtime or size budget is widened from target findings.

Later tests/collectors/runner/documentation commits do not replace this physical candidate. Any later shipping production/package/signing/entitlement/adapter/resource change requires another frozen candidate and fresh target evidence.

## Superseded first physical candidate and target finding

Superseded source `c19ce13c5321fce72464ddf0a5d9b1467f770db0` / CI #675 started the media runtime unconditionally at application launch.

Its target run on `Mac16,8` / macOS 26.6 proved signatures/security/lifecycle/stability, but compact/background combined RSS was approximately `80–86 MiB`.

A no-Now-Playing A/B measurement was essentially unchanged:

- active source combined RSS median/max: `80608/86320 KiB`;
- no-session combined RSS median/max: `80096/85552 KiB`;
- active source parent RSS median/max: `59592/62592 KiB`;
- no-session parent RSS median/max: `59808/61648 KiB`;
- no-session adapter RSS median/max: `20288/23904 KiB`.

This ruled out active track/artwork retention. The always-on observer + adapter was unnecessary compact-idle cost.

## Root-cause fix for always-on media cost

The production fix was implemented under RED -> GREEN coverage without changing accepted M6.3 process/wire/transport semantics.

New lifecycle:

- application launch remains compact and does not create `ShippingMediaRuntime`;
- settled-presentation callback is published only after matching transition completion;
- stale/reversed completions cannot publish a settled state;
- settled `.expanded` creates/starts one media runtime;
- settled `.compact` stops/releases the runtime;
- app termination still stops/releases any active runtime before panel teardown.

TDD evidence:

- CI #690 — RED: settled-presentation callback contract missing;
- CI #693 — GREEN: production lifecycle implementation PASS;
- CI #697 — compact parent-only collector contract PASS;
- CI #699 — RED for superseded target-runner contract;
- CI #700 — GREEN compact-vs-expanded runner contract PASS.

## Current-candidate target evidence — 2026-08-11

Platform: `Mac16,8` / macOS `26.6`.

Preflight:

- exact source/adapter/patch provenance — PASS;
- resources — PASS;
- strict top-level + nested codesign — PASS;
- Hardened Runtime — PASS;
- exact sandbox-only entitlement — PASS;
- system-only app executable libraries — PASS;
- development tools absent — PASS.

Human permission observation:

- Accessibility — NONE;
- Input Monitoring — NONE;
- Automation — NONE;
- Screen Recording — NONE.

### Compact 60-second steady

Adapter remained absent for the complete warmup + measurement window.

Parent:

- CPU median/max `0.0/2.4%`;
- RSS median/max `59792/66160 KiB`;
- threads median/max `3/4`;
- `60` one-second samples after `10s` warmup.

### Compact 10-minute stability

Adapter remained absent for the complete warmup + measurement window.

Parent:

- CPU median/max `0.0/3.3%`;
- RSS median/max `59024/60320 KiB`;
- RSS start/end `56304 -> 58976 KiB` (`+2672 KiB`);
- threads median/max `3/4`;
- threads start/end `3 -> 3`;
- `120` five-second samples after `10s` warmup.

The stability shape is good: no sustained CPU signal, RSS drift is within the stored `+8192 KiB` drift allowance, and thread drift is zero. Absolute RSS is above the original single-run P0 idle/stability ceilings, which triggered the historical comparability investigation below.

### Expanded 60-second active evidence

Settled expanded state owned the expected adapter.

Parent:

- CPU median/max `0.0/0.1%`;
- RSS median/max `73168/78624 KiB`;
- threads median/max `3/5`.

Adapter:

- CPU median/max `0.0/0.7%`;
- RSS median/max `23456/26208 KiB`;
- threads median/max `2/5`.

Conservative combined upper bounds:

- CPU median/max `0.0/0.8%`;
- RSS median/max `96624/104832 KiB`;
- threads median/max `5/10`.

Normal application termination reports parent exited, adapter exited, and `orphanProcessDetected = false`.

## Historical shell-only comparator — M6.4 static linkage disproven

To distinguish M6.4 static media linkage from an older shell/runtime change, the final exact-head M6.3 shipping app was measured with the same current compact parent-only collector.

Comparator:

- source `30de94c0cb6ea17dc21bd366404937db2bc73783`;
- CI #594 / run `31389611697`;
- artifact `NotchHub-dmg` / ID `9063213178`;
- artifact digest `sha256:9ab40b4101a013e11570fa013f49d2a42a3c5198251210a337b2985fc64e2a0d`;
- contained DMG SHA-256 `b1da6681ce49da3c34b3720c39caa32c3fc4508e0abf7d209b63b46f78713fb7`;
- `NotchHubApp` depends only on `NotchHubCore`;
- no M6.4 media shipping resources;
- no media adapter process.

60-second steady:

- CPU median/max `0.0/3.2%`;
- RSS median/max `58656/62624 KiB`;
- threads median/max `3/5`.

10-minute stability:

- CPU median/max `0.0/1.6%`;
- RSS median/max `56384/60400 KiB`;
- RSS start/end `58736 -> 54640 KiB` (`-4096 KiB`);
- threads median/max `3/5`;
- threads start/end `3 -> 3`.

Parent exited normally and adapter remained absent.

This is essentially the same compact shell RSS class as M6.4 and therefore disproves M6.4 static media linkage as the primary cause of the remaining absolute-RSS discrepancy.

## Same-session immutable-baseline A/B — P0 -> M1 persistent regression disproven

The P0 measurement harness at measurement-tool commit `dfd4f87f8e5be04b467172d720d22bfc054c06d0` and the current compact collector both sample Darwin `/bin/ps -p PID -o %cpu= -o rss=` and count `ps -M` thread rows. The metric definition therefore did not change between harnesses.

To distinguish code evolution from runtime/measurement-context portability, the exact immutable `v0.1.0` release and accepted M1 candidate #319 were measured back-to-back on the same `Mac16,8` / macOS 26.6 using one literal shared measurement path: `10 s` warmup, `60 s` parent-only steady sampling, `1 s` interval, normal AppKit termination.

Exact baseline `v0.1.0`:

- source `8e913dcddfdec7d9aa920df8c37afb23b8c40884`;
- release asset ID `505235050`;
- DMG SHA-256 `cf53be6081b1836551fcbbb91b85fed800de4c089451961f3c6a21f6b77768bc`;
- CPU median/max `0.0/0.0%`;
- RSS median/max `60144/63376 KiB`;
- threads median/max `3/5`.

Accepted M1 candidate #319:

- source `f6de06f5d045fc9375b3b31b0a7feb97a13cebe4`;
- workflow run `31257399497`;
- artifact ID `9021802122`;
- DMG SHA-256 `3a6ead1a716e6cf813d2125a7cdecf18a41a3ac2179bf5ca08f5cd4474856945`;
- CPU median/max `0.0/3.4%`;
- RSS median/max `59552/69680 KiB`;
- threads median/max `3/4`.

A/B RSS delta M1 minus immutable baseline:

- median: `-592 KiB`;
- max: `+6304 KiB`.

The exact immutable baseline binary itself therefore no longer reproduces its historical `~34 MiB` RSS observation in the current runtime context. A persistent P0 -> M1 memory regression is disproven. The old single-run absolute RSS ceilings remain immutable historical evidence but are not demonstrated to be portable across target-Mac sessions.

This is a measurement-context/metric-classification finding, not permission to silently widen production budgets. The final M6.4 decision still requires a direct same-session immutable-baseline comparison against the frozen M6.4 candidate.

## Final direct M6.4 RSS comparator

Development-only `scripts/run-m6-4-rss-ab.sh` exact-pins:

- immutable `v0.1.0`: source `8e913dcddfdec7d9aa920df8c37afb23b8c40884`, release asset ID `505235050`, DMG SHA-256 `cf53be6081b1836551fcbbb91b85fed800de4c089451961f3c6a21f6b77768bc`;
- frozen M6.4: source `fdbe987d8f22768b2a75406c8f1e721fa1da2845`, run `31472420797`, artifact ID `9093958828`, DMG SHA-256 `6371e8695e30f06697d37d2d018e043674e8b27a44022e3d8e846d0e1dad01fd`.

Both candidates use one literal shared 10-second warmup + 60-second parent-only steady measurement path and normal AppKit termination.

Interpretation:

- materially worse M6.4 same-session steady behavior => keep `008/009` blocked and continue root-cause work;
- equal-or-better M6.4 median/steady behavior, together with the already-good 10-minute drift/thread evidence => correct the cross-session RSS gate methodology rather than changing production code or silently widening the historical numeric budget.

CI #721 / run `31522174412` validates the new exact comparator contract and passes the full macOS compatibility/build/test/security/package/size pipeline.

## Acceptance ledger

### `NH-MEDIA-SHIP-001` — shipping linkage and lifecycle ownership

Status: **PASS**

Shipping app links media core; runtime ownership is correctly scoped to settled expanded presentation.

### `NH-MEDIA-SHIP-002` — exact production resources and provenance

Status: **PASS**

Exact pinned production resources ship and development tools remain absent.

### `NH-MEDIA-SHIP-003` — signatures, Hardened Runtime, sandbox-only entitlement

Status: **PASS — HOSTED + TARGET**

### `NH-MEDIA-SHIP-004` — executable dependency boundary

Status: **PASS — HOSTED + TARGET**

### `NH-MEDIA-SHIP-005` — fail-closed bundle boundary

Status: **PASS — DETERMINISTIC**

### `NH-MEDIA-SHIP-006` — target owned-adapter lifecycle

Status: **PASS — TARGET-MAC**

Compact owns zero adapters; settled expansion owns the expected adapter; normal termination exits parent/adapter and leaves no orphan.

### `NH-MEDIA-SHIP-007` — no sensitive permission prompts

Status: **PASS — TARGET-MAC HUMAN OBSERVATION**

All four monitored sensitive permission categories were NONE.

### `NH-MEDIA-SHIP-008` — 60-second target resource evidence

Status: **PENDING — FINAL SAME-SESSION IMMUTABLE-BASELINE A/B**

Compact CPU median and thread count are good. Historical absolute RSS ceilings are not reproducible even with the exact immutable baseline binary under the current runtime context. M6.4 static linkage and P0 -> M1 persistent RSS regression are both disproven. Final decision requires the direct `v0.1.0` versus frozen M6.4 same-session comparator.

### `NH-MEDIA-SHIP-009` — approximately 10-minute target stability

Status: **STABILITY BEHAVIOR PASS; FINAL RSS CLASSIFICATION PENDING DIRECT A/B**

CPU median `0.0%`, RSS drift `+2672 KiB`, thread drift `0`, adapter absent. M6.3 shell-only has the same RSS class with negative drift. Final acceptance waits only for direct immutable-baseline versus M6.4 steady comparison and the resulting RSS methodology decision.

### `NH-MEDIA-SHIP-010` — explicit artifact-size impact

Status: **PASS — DETERMINISTIC**

Current candidate remains inside the explicit M6.4 additive feature-size budget over the unchanged immutable P0 baseline.

## Current decision

**DO NOT MERGE M6.4 YET.**

M6.4 production lifecycle/security behavior is physically sound. M6.4 static media linkage and a persistent P0 -> M1 memory regression are both disproven as explanations for the current absolute-RSS discrepancy. The exact immutable baseline binary itself now measures in the same ~60 MiB RSS class.

One final short target comparison remains: exact immutable `v0.1.0` versus frozen M6.4 in the same session. No performance budget is widened and no production fix is attempted before that direct evidence is evaluated.

Media UI, progress rendering, gesture/haptic/seek interaction, and additional-player compatibility remain outside M6.4.
