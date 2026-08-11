# Project state

Last updated: 2026-08-11
Current version: `0.1.0` (Personal Release published and accepted)
Repository visibility: **Public**
Primary physical target: macOS `26.6` / `Mac16,8`
Protected branch target: `main`

## Current product state

**M6.4 shipping media composition is functionally and security-qualified, and its lazy settled-expanded lifecycle is physically confirmed. The current blocker is absolute compact/background RSS: the media adapter is now absent in compact mode, but the shipping parent still sits around `59–66 MiB`, above the immutable P0 idle/stability ceilings. A shell-only M6.3 comparator is the next required diagnostic before choosing further production optimization. Media UI remains blocked.**

Accepted foundations/integrations:

- M0 Engineering Foundation — accepted;
- R0.1 Personal Release `v0.1.0` — accepted;
- P0 Performance Foundation — accepted and merged as `a056aa74bad5d8e193eb4c76a76e6c910344bd09`;
- P0.1 Public Repository Readiness — accepted;
- M1 interaction/transition slice — accepted and merged as `094b494bd597643244e733baf5787a13b61fb4eb`;
- Universal Media design — `403a557399abb2704f9ae02397b49229ca6cf1f9`;
- M6.1 transport probe — accepted/merged as `7d5210eb0363933d120334d29daf40956b53cb50`, outcome `ACCEPT_TRANSPORT`;
- M6.2 production media state/controller/bridge boundary — accepted/merged as `1ccea500570f9a5ca927739be58d7f7eaadd775a`;
- M6.3 concrete production transport — accepted on frozen candidate `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`;
- M6.4 shipping media composition — **lifecycle/permissions PASS; compact absolute RSS BLOCKED**.

Authoritative evidence:

- M6.3: `docs/testing/PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`;
- M6.4: `docs/testing/SHIPPING_MEDIA_COMPOSITION_ACCEPTANCE.md`;
- M6.4 target procedure: `docs/testing/SHIPPING_MEDIA_COMPOSITION_TARGET_MAC.md`.

## Product

NotchHub is a personal native local-first macOS productivity hub built around the MacBook notch. Planned modules include Shelf, Snippets, Calendar, Translator, Universal Media, and later shell/settings capabilities.

Universal Media follows the system Now Playing source selected by macOS rather than targeting one player. Yandex Music and Yandex Browser are physically verified through the accepted M6.3 production transport. Apple Music, Spotify, and additional independent-player compatibility remain unverified until physically tested.

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

Remaining display/Space hardening stays deferred behind the functional media slice and P1 performance review.

### R0.1 Personal Release

Immutable `v0.1.0` is accepted for personal use. It is ad-hoc signed, sandboxed, Hardened Runtime protected, checksum/provenance verified and intentionally not notarized.

### P0 Performance Foundation

Accepted target-Mac baseline:

- idle CPU median/max `0.0% / 0.7%`, RSS max `33,808 KiB`, threads max `4`;
- hover CPU median/max `5.95% / 22.3%`, RSS max `38,816 KiB`, threads max `7`;
- 10-minute stability CPU median/max `0.0% / 6.8%`, RSS max `34,384 KiB`, RSS drift `-3,712 KiB`, threads max `7`.

Immutable `v0.1.0` artifact baseline:

- executable `220,560 B`;
- app aggregate `223,555 B`;
- DMG `73,955 B`.

Target ceilings remain immutable:

- idle: CPU median <= `0.5%`, CPU max <= `2.0%`, RSS max <= `43008 KiB`, threads max <= `6`;
- stability: CPU median <= `0.5%`, CPU max <= `10.0%`, RSS max <= `45056 KiB`, RSS positive drift <= `8192 KiB`, threads max <= `9`, thread positive drift <= `2`.

Feature-specific shipping growth must be explicit, separately reviewed, and provenance-backed. Runtime ceilings are not silently widened.

## Universal Media

### M6.1 — transport feasibility

Status: **ACCEPTED — `ACCEPT_TRANSPORT`**.

Physically established App Sandbox + Hardened Runtime compatibility, no sensitive permission prompts, authoritative capabilities, Yandex Music/Yandex Browser observation and commands, source switching/disappearance, clean teardown/no orphan, and stable target resource behavior.

### M6.2 — production state/controller/bridge boundary

Status: **ACCEPTED AND MERGED**.

Independent `NotchHubMediaCore` provides normalized media domain types, immutable snapshots, monotonic generation/revision ordering, player-agnostic provider, deterministic `@MainActor MediaSessionController`, injected `SystemMediaTransport`, and isolated `SystemMediaBridge` ownership.

### M6.3 — concrete production system transport

Status: **ACCEPTED**.

Accepted candidate:

- source `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`;
- CI #576 / run `31339015100` — PASS;
- artifact ID `9045247126`;
- digest `sha256:a6323c504021f21e7638b40e47bedd0b2c1a9fcfcf861724c139151ee8faa804`;
- adapter `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- patch SHA-256 `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`.

All `NH-MEDIA-PROD-001...013` gates pass on Mac16,8/macOS 26.6.

### M6.4 — shipping media composition

Status: **TARGET-MAC LIFECYCLE/PERMISSIONS PASS — COMPACT RSS BLOCKED**.

Current frozen shipping candidate:

- source `fdbe987d8f22768b2a75406c8f1e721fa1da2845`;
- CI #693 / run `31472420797` — both jobs PASS;
- artifact `NotchHub-shipping-media-candidate` / ID `9093958828`;
- Actions digest `sha256:f055bc87d1f2c8cafe0d3b57d9cf6cdf82d7a712bf85acf3317232679a9689b9`;
- contained DMG SHA-256 `6371e8695e30f06697d37d2d018e043674e8b27a44022e3d8e846d0e1dad01fd`;
- sizes: executable `313,648 B`, app `615,854 B`, DMG `408,480 B`.

Implemented and confirmed:

- exact pinned production adapter resources ship;
- nested/top-level signatures, Hardened Runtime, sandbox-only entitlement and system-library dependency boundary pass hosted and target preflight;
- candidate-only helpers remain development-only;
- explicit additive M6.4 size gate passes over the unchanged P0 artifact baseline;
- media runtime is scoped to **settled expanded presentation**, not application lifetime;
- compact launch owns zero media adapter processes;
- stale/reversed transition completions cannot trigger media lifecycle changes;
- settled expansion creates the expected owned adapter;
- normal app termination exits parent and active adapter with no orphan;
- Accessibility, Input Monitoring, Automation and Screen Recording prompts are all absent.

Current physical resource evidence:

Compact steady, parent-only, adapter absent:

- CPU median/max `0.0 / 2.4%`;
- RSS median/max `59,792 / 66,160 KiB`;
- threads median/max `3 / 4`.

Compact 10-minute stability, parent-only, adapter absent:

- CPU median/max `0.0 / 3.3%`;
- RSS median/max `59,024 / 60,320 KiB`;
- RSS `56,304 -> 58,976 KiB` (`+2,672 KiB`);
- threads `3 -> 3`, max `4`.

Expanded steady active feature evidence:

- parent RSS median/max `73,168 / 78,624 KiB`;
- adapter RSS median/max `23,456 / 26,208 KiB`;
- conservative combined RSS median/max `96,624 / 104,832 KiB`;
- combined CPU median/max `0.0 / 0.8%`;
- combined thread median/max `5 / 10`;
- clean normal teardown/no orphan.

Ledger:

- `NH-MEDIA-SHIP-001...007` — PASS;
- `NH-MEDIA-SHIP-008` — **BLOCKED**: compact RSS max `66,160 KiB` > P0 idle ceiling `43,008 KiB`; CPU max `2.4%` > `2.0%`;
- `NH-MEDIA-SHIP-009` — **BLOCKED on absolute RSS**: stability shape passes, but RSS max `60,320 KiB` > P0 stability ceiling `45,056 KiB`;
- `NH-MEDIA-SHIP-010` — PASS explicit artifact-size impact.

No runtime budget is widened.

## Current performance investigation

The lazy lifecycle removed approximately `20–24 MiB` of always-on adapter RSS from compact background, but the parent itself remains around `59–66 MiB`.

The next exact comparator is the final M6.3 shell-only shipping DMG where `NotchHubApp` still depends only on `NotchHubCore`:

- source `30de94c0cb6ea17dc21bd366404937db2bc73783`;
- CI #594 / run `31389611697`;
- artifact `NotchHub-dmg` / ID `9063213178`;
- Actions digest `sha256:9ab40b4101a013e11570fa013f49d2a42a3c5198251210a337b2985fc64e2a0d`;
- contained DMG SHA-256 `b1da6681ce49da3c34b3720c39caa32c3fc4508e0abf7d209b63b46f78713fb7`.

A dedicated development-only runner, `scripts/run-shell-only-target-diagnostic.sh`, exact-pins that artifact and applies the same 60-s/10-minute parent-only sampler.

Decision rule:

- shell-only approximately `59–66 MiB` => regression predates M6.4; trace earlier shell/interaction changes before altering media architecture;
- shell-only near P0 range => M6.4 static media linkage is responsible; isolate media code deeper before acceptance.

## Security baseline

`SECURITY.md` remains authoritative. Production subprocess executable remains exactly `/usr/bin/perl`; adapter provenance is pinned; commands remain typed and closed; I/O and teardown remain bounded; no shell/player-specific fallback/networking/telemetry/sensitive-permission expansion was added.

App Sandbox remains the only application entitlement and Hardened Runtime remains mandatory.

## Known limitations / technical debt

- M6.4 absolute compact RSS blocker remains open;
- no compact/expanded media UI, progress rendering or gesture/haptic/seek interaction ships yet;
- Apple Music, Spotify and additional-player compatibility are not physically verified;
- the global `.mouseMoved` fallback remains pending the P1 `NSTrackingArea` / window-local comparison;
- active-display migration, fullscreen/Spaces, screen-configuration handling, notchless mode and click/pin policy remain later work.

## Next optimal step

1. Complete the exact M6.3 shell-only target comparator using `scripts/run-shell-only-target-diagnostic.sh`.
2. Compare its parent-only steady/stability RSS directly with the current M6.4 compact evidence and immutable P0 ceilings.
3. If the regression predates M6.4, bisect/diagnose the shell/interaction evolution before changing media architecture.
4. If M6.4 static linkage causes the regression, design a deeper lazy isolation boundary and implement it under TDD without widening runtime budgets.
5. Re-freeze and repeat target acceptance after any production change.
6. Merge PR #17 only after `NH-MEDIA-SHIP-008/009` pass and the ledger is explicitly `ACCEPTED`.
7. Only then implement compact + expanded media-first UI.
