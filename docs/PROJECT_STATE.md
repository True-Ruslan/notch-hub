# Project state

Last updated: 2026-08-11
Current version: `0.1.0` (Personal Release published and accepted)
Repository visibility: **Public**
Primary physical target: macOS `26.6` / `Mac16,8`
Protected branch target: `main`

## Current product state

**M6.4 shipping media composition is implemented and CI-qualified, and its lazy settled-expanded lifecycle is physically validated. M6.4 itself is no longer the leading explanation for the compact RSS blocker: the final M6.3 shell-only shipping app, which does not link `NotchHubMediaCore`, reproduces essentially the same elevated compact RSS. Root-cause work has therefore moved backward to the P0→M1 shell evolution / measurement-environment boundary. PR #17 remains Draft until that performance discrepancy is explained and resolved without silently widening budgets.**

Accepted foundations/integrations:

- M0 Engineering Foundation — accepted;
- R0.1 Personal Release `v0.1.0` — accepted;
- P0 Performance Foundation — accepted and merged as `a056aa74bad5d8e193eb4c76a76e6c910344bd09`;
- P0.1 Public Repository Readiness — accepted;
- M1 interaction/transition slice — accepted and merged as `094b494bd597643244e733baf5787a13b61fb4eb`;
- Universal Media design — `403a557399abb2704f9ae02397b49229ca6cf1f9`;
- M6.1 transport probe — accepted/merged as `7d5210eb0363933d120334d29daf40956b53cb50`, final outcome `ACCEPT_TRANSPORT`;
- M6.2 production media state/controller/bridge boundary — accepted/merged as `1ccea500570f9a5ca927739be58d7f7eaadd775a`;
- M6.3 concrete production transport — accepted on frozen candidate `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`;
- M6.4 shipping media composition — **lifecycle/security physically PASS; compact absolute RSS root-cause investigation continues outside the media-runtime boundary**.

Authoritative evidence:

- M6.3: `docs/testing/PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`;
- M6.4: `docs/testing/SHIPPING_MEDIA_COMPOSITION_ACCEPTANCE.md`;
- M6.4 target procedure: `docs/testing/SHIPPING_MEDIA_COMPOSITION_TARGET_MAC.md`.

## Product

NotchHub is a personal native local-first macOS productivity hub built around the MacBook notch. Planned modules include Shelf, Snippets, Calendar, Translator, Universal Media, and later shell/settings capabilities.

Universal Media follows the system Now Playing source selected by macOS rather than targeting one player. Yandex Music and Yandex Browser are physically verified through the accepted M6.3 production transport. Apple Music, Spotify, and additional independent-player compatibility remain explicitly unverified until physically tested.

NotchNook and Boring Notch are independent product/engineering references only. NotchHub remains an independent MIT implementation; GPL-covered implementation code is not copied.

## Accepted engineering baseline

### M0 / M1 interaction foundation

Accepted behavior includes:

- Swift 6 native shell;
- public notch geometry and AppKit-owned panel sizing;
- one cancellable `120 ms` hover dwell;
- compact activation geometry 4 pt left/right/bottom and 0 pt top with inclusive boundaries;
- one public `.levelChange` haptic for eligible deliberate expansion;
- `NotchPanelTransitionCoordinator` as sole compact/expanded transition authority;
- `0.20 s` AppKit/Core Animation transition with Reduce Motion = zero duration;
- one local + one narrow global `.mouseMoved` fallback with explicit lifecycle ownership;
- no per-event `Task` allocation in the live pointer hot path;
- no display link, polling loop, repeating timer, synthetic input, Accessibility or Input Monitoring requirement for notch interaction.

Remaining M1 display/Space hardening stays deferred behind the functional media slice and P1 performance review.

### R0.1 Personal Release

Immutable `v0.1.0` is accepted for personal use. It is ad-hoc signed, sandboxed, Hardened Runtime protected, checksum/provenance verified and intentionally not notarized. Paid Apple Developer Program membership is not required for the current personal-use tier.

### P0 Performance Foundation

Accepted target-Mac baseline:

- idle CPU median/max `0.0% / 0.7%`, RSS max `33,808 KiB`, threads max `4`;
- hover CPU median/max `5.95% / 22.3%`, RSS max `38,816 KiB`, threads max `7`;
- 10-minute stability CPU median/max `0.0% / 6.8%`, RSS max `34,384 KiB`, RSS drift `-3,712 KiB`, threads max `7`.

Immutable `v0.1.0` artifact baseline:

- executable `220,560 B`;
- app aggregate `223,555 B`;
- DMG `73,955 B`.

The P0 baseline remains immutable. Feature-specific shipping growth must be explicit, separately reviewed, and provenance-backed.

## Universal Media

### M6.1 — transport feasibility

Status: **ACCEPTED — `ACCEPT_TRANSPORT`**.

The compatibility probe physically established App Sandbox + Hardened Runtime compatibility, no sensitive permission prompts, authoritative capabilities, Yandex Music/Yandex Browser observation and commands, source switching/disappearance, clean teardown/no orphan, and stable target resource behavior.

### M6.2 — production state/controller/bridge boundary

Status: **ACCEPTED AND MERGED**.

Independent `NotchHubMediaCore` provides normalized media domain types, immutable snapshots, monotonic generation/revision ordering, a player-agnostic provider, deterministic `@MainActor MediaSessionController`, injected `SystemMediaTransport`, and `SystemMediaBridge` callback/teardown/typed-command ownership.

### M6.3 — concrete production system transport

Status: **ACCEPTED**.

Accepted exact candidate:

- source `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`;
- CI #576 / run `31339015100` — PASS;
- artifact ID `9045247126`;
- digest `sha256:a6323c504021f21e7638b40e47bedd0b2c1a9fcfcf861724c139151ee8faa804`;
- adapter `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- patch SHA-256 `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`.

All `NH-MEDIA-PROD-001...013` gates pass on Mac16,8/macOS 26.6, including actual toggle/next/previous/seek behavior, no sensitive permission prompts, clean teardown/no orphan, 60-second steady evidence, and corrected 10-minute stability evidence.

### M6.4 — shipping media composition

Status: **TARGET LIFECYCLE/SECURITY PASS — COMPACT ABSOLUTE RSS BLOCKED; ROOT CAUSE PREDATES M6.4**.

Current frozen shipping candidate:

- source `fdbe987d8f22768b2a75406c8f1e721fa1da2845`;
- CI #693 / run `31472420797` — both jobs PASS;
- artifact `NotchHub-shipping-media-candidate`;
- artifact ID `9093958828`;
- Actions digest `sha256:f055bc87d1f2c8cafe0d3b57d9cf6cdf82d7a712bf85acf3317232679a9689b9`;
- contained DMG SHA-256 `6371e8695e30f06697d37d2d018e043674e8b27a44022e3d8e846d0e1dad01fd`;
- exact sizes: executable `313,648 B`, physical app payload `615,854 B`, DMG `408,480 B`.

Implemented and deterministic/hosted-qualified:

- `NotchHubApp` links `NotchHubMediaCore` and ships exact pinned production adapter resources;
- nested framework/top-level signatures, Hardened Runtime, sandbox-only entitlement and system-library dependency boundary remain intact;
- candidate-only helpers remain development-only;
- immutable P0 artifact baseline remains unchanged and explicit M6.4 additive size gate passes;
- media runtime starts only after a matching transition successfully settles `.expanded` and stops/releases after matching `.compact` settlement;
- stale/reversed transition completions cannot trigger media lifecycle changes;
- compact target collector samples parent only and fails if an owned media adapter appears;
- expanded collector requires exactly one owned adapter and clean normal teardown.

Current-candidate physical evidence on `Mac16,8` / macOS 26.6:

- compact adapter absent throughout 60-second steady and 10-minute stability — PASS;
- expanded state owns expected adapter — PASS;
- normal termination exits parent/adapter with no orphan — PASS;
- Accessibility / Input Monitoring / Automation / Screen Recording — NONE;
- compact steady CPU median/max `0.0/2.4%`, RSS median/max `59,792/66,160 KiB`, threads max `4`;
- compact stability CPU median/max `0.0/3.3%`, RSS median/max `59,024/60,320 KiB`, RSS `56,304 -> 58,976 KiB`, threads `3 -> 3`;
- expanded active combined CPU median/max `0.0/0.8%`, RSS median/max `96,624/104,832 KiB`, threads median/max `5/10`, clean teardown.

The compact RSS is above P0 absolute ceilings, so `NH-MEDIA-SHIP-008/009` remain blocked. However a historical comparator disproves M6.4 as the primary cause:

Final M6.3 shell-only shipping app:

- source `30de94c0cb6ea17dc21bd366404937db2bc73783`;
- CI #594 / run `31389611697`;
- artifact `NotchHub-dmg` / ID `9063213178`;
- does **not** link `NotchHubMediaCore` and contains no M6.4 media shipping resources;
- steady CPU median/max `0.0/3.2%`, RSS median/max `58,656/62,624 KiB`, threads max `5`;
- 10-minute stability CPU median/max `0.0/1.6%`, RSS median/max `56,384/60,400 KiB`, RSS `58,736 -> 54,640 KiB`, threads `3 -> 3`;
- adapter absent and parent normal termination PASS.

Therefore the ~56–62 MiB shell footprint predates M6.4. No M6.4 runtime or size budget is widened.

Current M6.4 ledger:

- `NH-MEDIA-SHIP-001...007` — PASS;
- `NH-MEDIA-SHIP-008` — BLOCKED on compact absolute RSS / small idle CPU-max miss, with root cause now known to predate M6.4;
- `NH-MEDIA-SHIP-009` — BLOCKED on compact absolute RSS; drift/thread behavior passes and root cause predates M6.4;
- `NH-MEDIA-SHIP-010` — PASS.

## Security baseline

`SECURITY.md` remains authoritative.

The shipping app intentionally contains accepted M6.3 media transport through the narrow M6.4 composition boundary. Production subprocess executable remains exactly `/usr/bin/perl`; adapter provenance is pinned; command surface remains typed and closed; I/O and teardown remain bounded; no shell/player-specific fallback/networking/telemetry/sensitive-permission expansion was added.

App Sandbox remains the only application entitlement and Hardened Runtime remains mandatory. Lazy presentation-scoped media lifecycle changes when the accepted subprocess exists, not what authority it has.

## Known limitations / technical debt

- absolute compact RSS is above the P0 ceilings on both M6.4 and the earlier M6.3 shell-only app; root cause is under historical/performance investigation;
- no compact/expanded media UI, progress rendering or gesture/haptic/seek interaction ships yet;
- Apple Music, Spotify and additional-player compatibility are not physically verified;
- global `.mouseMoved` fallback remains pending P1 `NSTrackingArea` / window-local comparison;
- active-display migration, fullscreen/Spaces, screen-configuration handling, notchless mode and click/pin policy remain later work.

## Next optimal step

1. Re-run immutable `v0.1.0` (source `8e913dc...`) today on the same Mac16,8/macOS 26.6 using the current parent-only collector and compare it in the same session with accepted M1 candidate `f6de06f...` from CI #319.
2. Use `scripts/run-shell-rss-bisect.sh` so both candidates get identical 10-second warmup + 60-second steady sampling and normal termination.
3. If current `v0.1.0` also measures ~56–62 MiB, treat the discrepancy as environment/baseline-context drift and investigate what changed in runtime conditions before changing production code or budgets.
4. If `v0.1.0` remains near its original ~34 MiB while M1 is high, the regression is code-level inside M1; physically bisect M1 artifacts around transition/Reduce-Motion lifecycle changes and prove the exact mechanism before fixing.
5. Keep PR #17 Draft and do not widen runtime budgets until that fork is resolved.
6. Only after the performance discrepancy is resolved may M6.4 be marked `ACCEPTED` and Media UI proceed.
