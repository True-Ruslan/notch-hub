# Production System Media Transport — Acceptance Evidence

Status: **ACCEPTED — TARGET-MAC GATE COMPLETE**

Authoritative implementation plan: `docs/superpowers/plans/2026-08-09-production-system-media-transport.md`.
Historical transport decision: `docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md` (`ACCEPT_TRANSPORT`).
Target procedure: `docs/testing/PRODUCTION_MEDIA_TRANSPORT_TARGET_MAC.md`.

## Accepted exact production-transport candidate

M6.3 is accepted on this immutable physical candidate:

- source SHA: `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`;
- CI run: `#576` / `31339015100` — both jobs PASS;
- artifact: `ProductionMediaTransportCandidate-candidate`;
- artifact ID: `9045247126`;
- artifact size: `199242` bytes;
- artifact digest: `sha256:a6323c504021f21e7638b40e47bedd0b2c1a9fcfcf861724c139151ee8faa804`;
- adapter SHA: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- capability patch SHA-256: `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`;
- evidence schema: `1`.

CI #576 proves warnings-as-errors builds, the full Swift suite, the real production candidate, archive round-trip verification, security/release/performance policy, App Sandbox + Hardened Runtime, shipping isolation, artifact-size budget and performance-harness smoke.

Later acceptance-documentation and collector-only fixes do not replace this physical code candidate. Any later change to `Sources/NotchHubMediaCore/**`, `Tools/ProductionMediaTransportCandidate/**`, candidate packaging/signing, pinned adapter/patch, security/runtime policy or candidate entitlements requires a new candidate and fresh target evidence.

## Accepted transport contract

The accepted implementation provides:

- event-driven `stream --no-diff --micros` observation with strict bounded wire decoding;
- full-snapshot replacement semantics and stale-artwork clearing;
- authoritative `supported / unsupported / unknown` command capabilities;
- monotonic source/session generation and revision ordering;
- no-session invalidation and source-switch isolation;
- stale capability-completion rejection;
- exactly one reviewed Foundation `Process()` boundary, fixed to `/usr/bin/perl`;
- closed adapter arguments and typed toggle/previous/next/seek only;
- no shell, arbitrary executable, arbitrary MediaRemote command-ID, player-specific fallback or networking surface;
- bounded owned-process teardown without polling/repeating timers;
- controller-owned one-restart/no-loop behavior;
- privacy-safe acceptance evidence with no listening-history retention;
- exact shipping isolation: `NotchHub.app` still does not link `NotchHubMediaCore` and contains no adapter/candidate assets.

## Target-discovered lifecycle defect and fix

The superseded CI #558 candidate exposed a real production defect: teardown could remain in unbounded `Process.waitUntilExit()` after long observation.

The accepted candidate fixes this under RED -> GREEN coverage:

- graceful termination receives a fixed `1s` process-exit-event wait;
- failure to confirm graceful exit escalates the owned adapter to `SIGKILL`;
- forced termination receives a second fixed `1s` process-exit-event wait;
- no polling or repeating timer is used;
- unconfirmed exit becomes `.teardownFailure` with `lastTeardownClean = false`;
- candidate `cleanTeardown` is derived from the actual process result;
- protocol-failure and one-shot timeout cleanup use the same bounded policy.

Two target-acceptance collector defects were also corrected without changing the frozen production candidate:

- resource sampling now uses numeric CPU/RSS/thread `ProcessSample` values (`ba7d5722...` RED -> `44bb5b4...` GREEN, CI #582 PASS);
- long-run completion uses an absolute observer deadline plus bounded `60s` completion grace instead of the superseded fixed 20-second watchdog (`375fac05...` RED -> `d5d6927e...` GREEN, CI #584 PASS).

## Target-Mac environment

Final physical acceptance was performed on:

- hardware: `Mac16,8`;
- macOS: `26.6` / build `25G72`;
- candidate source: `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`.

## Physical acceptance ledger

### `NH-MEDIA-PROD-001` — target Sandbox + Hardened Runtime

Status: **PASS**

Exact preflight proves source/adapter/patch provenance, strict code-sign verification, App Sandbox-only effective entitlements and Hardened Runtime.

### `NH-MEDIA-PROD-002` — no-session fail-closed state

Status: **PASS**

With all Now Playing sources stopped/closed, target preflight reports exactly `previous/next/seek = unknown/unknown/unknown`.

### `NH-MEDIA-PROD-003` — Yandex Music production observation

Status: **PASS**

The production transport observes `ru.yandex.desktop.music`, artwork and playing state.

### `NH-MEDIA-PROD-004` — browser production observation

Status: **PASS**

The same production transport observes `ru.yandex.desktop.yandex-browser` as the authoritative system Now Playing source without a browser-specific fallback.

### `NH-MEDIA-PROD-005` — source switching and disappearance

Status: **PASS**

The physical source-cycle records `sourceSwitchCount = 1`, reaches Yandex Browser as the resulting source, observes later session disappearance and reports `cleanTeardown = true`.

### `NH-MEDIA-PROD-006` — authoritative capabilities

Status: **PASS**

Observed capability states are:

- no session: `unknown/unknown/unknown`;
- active Yandex Music: `supported/supported/supported`;
- Yandex Browser: `previous/next/seek = unsupported/supported/supported`.

No capability support is fabricated.

### `NH-MEDIA-PROD-007` — actual command behavior

Status: **PASS**

With Yandex Music active and supported capabilities reported, the candidate returned `sent=true` and the user physically confirmed:

- toggle pause — PASS;
- toggle resume — PASS;
- next — PASS;
- previous — PASS;
- seek 42 seconds — PASS.

### `NH-MEDIA-PROD-008` — stale artwork regression

Status: **PASS DETERMINISTIC / PHYSICAL OPTIONAL**

Full-snapshot and rapid-switch tests prevent stale artwork/capability inheritance. The available physical source sequence did not naturally produce an artwork-bearing -> no-artwork switch; this optional condition was not manufactured.

### `NH-MEDIA-PROD-009` — clean stop / no orphan

Status: **PASS**

Source-cycle, 60-second steady and corrected 10-minute stability evidence all report clean teardown. Resource runs report `orphanProcessDetected = false`.

### `NH-MEDIA-PROD-010` — bounded failure lifecycle

Status: **PASS**

Deterministic tests prove bounded graceful/forced child termination, fail-closed unconfirmed teardown, one controller restart only, stale callback rejection and no restart loop. The target 10-minute regression run completes normally with clean teardown and no orphan child.

### `NH-MEDIA-PROD-011` — no sensitive permission prompts

Status: **PASS**

During the complete target source/command cycle the user confirmed:

- Accessibility — NONE;
- Input Monitoring — NONE;
- Automation — NONE;
- Screen Recording — NONE.

### `NH-MEDIA-PROD-012` — 60-second resource evidence

Status: **PASS**

Current-candidate steady evidence:

- 60 samples at `1s` intervals after `10s` warmup;
- parent CPU median/max: `0.0/0.0%`;
- adapter CPU median/max: `0.0/0.1%`;
- combined RSS median/max upper bounds: `26416/32192 KiB`;
- combined thread median/max upper bounds: `4/9`;
- source: `ru.yandex.desktop.music`;
- `cleanTeardown = true`;
- `orphanProcessDetected = false`.

### `NH-MEDIA-PROD-013` — 10-minute stability evidence

Status: **PASS**

Corrected target stability evidence:

- requested duration: `600s`;
- sample interval: `5s`;
- sample count: `120`;
- parent CPU median/max: `0.0/2.2%`;
- adapter CPU median/max: `0.0/5.3%`;
- combined CPU median/max upper bounds: `0.0/7.5%`;
- combined RSS median/max upper bounds: `26456/35168 KiB`;
- combined RSS start/end: `35168 -> 26160 KiB`;
- combined RSS drift: `-9008 KiB`;
- combined thread start/end: `11 -> 4`;
- `observerReport.cleanTeardown = true`;
- `orphanProcessDetected = false`.

There is no sustained CPU signal, RSS accumulation or thread accumulation in the measured run.

## Final decision

**M6.3 ACCEPTED.**

The concrete production `SystemMediaTransport` passes deterministic/CI qualification and the complete current-candidate target-Mac gate. The accepted result is the isolated transport implementation only.

The following remain explicitly outside M6.3 and must be implemented as separate reviewed slices:

- linking `NotchHubMediaCore` into `NotchHubApp`;
- packaging pinned adapter/framework assets into shipping `NotchHub.app`;
- fresh shipping package/security/artifact-size/runtime acceptance;
- compact/expanded Media UI;
- gesture/haptic/seek interaction state machines;
- Apple Music, Spotify and additional-player compatibility claims not physically tested on the Personal Release target.

No title, artist, album, artwork bytes, raw MediaRemote payload or listening history is retained in this ledger.
