# Production System Media Transport — Acceptance Evidence

Status: **CI-QUALIFIED — NEW TARGET-MAC REVALIDATION PENDING**

Authoritative implementation plan: `docs/superpowers/plans/2026-08-09-production-system-media-transport.md`.
Historical transport decision: `docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md` (`ACCEPT_TRANSPORT`).
Target procedure: `docs/testing/PRODUCTION_MEDIA_TRANSPORT_TARGET_MAC.md`.

## Current exact production-transport candidate

The current physical candidate is frozen at:

- source SHA: `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`;
- CI run: `#576` / `31339015100`;
- artifact: `ProductionMediaTransportCandidate-candidate`;
- artifact ID: `9045247126`;
- artifact size: `199242` bytes;
- artifact digest: `sha256:a6323c504021f21e7638b40e47bedd0b2c1a9fcfcf861724c139151ee8faa804`;
- adapter SHA: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- capability patch SHA-256: `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`;
- production candidate evidence schema: `1`.

CI #576 is fully green on this code candidate. Both jobs pass, including warnings-as-errors, the full Swift suite, real production-candidate execution, archive round-trip verification, release/performance/security policy, Sandbox + Hardened Runtime, shipping artifact-size budget and performance-harness smoke.

Any later change to `Sources/NotchHubMediaCore/**`, `Tools/ProductionMediaTransportCandidate/**`, candidate packaging/signing, the pinned adapter, the capability patch, security/runtime policy or candidate entitlements requires a new exact candidate and artifact digest. Documentation-only acceptance updates do not replace the candidate above.

## Superseded candidate and target-discovered defect

The previous candidate `3932426bcf063162ee7de1378ed301c9ce664746` from CI #558 / artifact `9039199985` is **SUPERSEDED** and must not be used for final M6.3 acceptance.

Target-Mac evidence on `Mac16,8` / macOS 26.6 established useful diagnostics before supersession:

- exact source/adapter/patch provenance, code-sign verification, App Sandbox-only entitlements and Hardened Runtime passed;
- active Yandex Music reported authoritative `previous/next/seek = supported/supported/supported`;
- a 60-second steady run completed with parent CPU median/max `0.0/0.0%`, adapter CPU median/max `0.0/0.0%`, combined RSS median upper bound `29808 KiB`, combined RSS max upper bound `34752 KiB`, combined thread median/max upper bounds `5/5`, `cleanTeardown = true`, and no orphan process;
- a source-cycle run observed a real Yandex Music session, artwork, playing state and session disappearance with `cleanTeardown = true`; however `sourceSwitchCount = 0`, so browser/source-switch acceptance was not established.

The approximately 10-minute stability run then exposed a real lifecycle defect. Sampling reached the long-running observer, but candidate finalization did not finish within the collector's 20-second watchdog after the 600-second sample window. Investigation found unbounded `Process.waitUntilExit()` calls in production observation/protocol/timeout teardown paths. This is a candidate defect, not a resource-budget failure and not a user-command error.

The new exact candidate fixes that defect by:

- replacing production teardown with a bounded termination policy;
- attempting graceful termination and waiting at most `1s` for the process-exit event;
- escalating the owned adapter process to `SIGKILL` if graceful termination is not confirmed;
- waiting at most another `1s` for forced termination confirmation;
- avoiding polling/repeating timers by using the process termination event as the wait signal;
- recording `lastTeardownClean = false` and `.teardownFailure` when exit still cannot be confirmed;
- making the candidate report derive `cleanTeardown` from the actual process-client result rather than hard-coding `true`;
- classifying teardown failure as privacy-safe operational code `processTeardown`;
- applying the same bounded termination policy to protocol-failure and one-shot-timeout cleanup.

Deterministic RED→GREEN tests cover graceful-to-forced escalation, failed forced teardown, and truthful candidate evidence. CI #576 additionally proves the real production candidate still builds, runs, verifies and archives successfully under macOS 26.

## CI-qualified transport evidence

The current exact candidate retains the previously accepted transport properties:

- strict bounded `--no-diff --micros` wire decoding;
- full-snapshot semantics with no stale-field merge;
- fixed `/usr/bin/perl` executable and closed adapter argument construction;
- no shell, arbitrary executable, arbitrary command-ID, player-specific or network surface;
- authoritative tri-state capabilities;
- monotonic source/session generations and revisions;
- no-session invalidation;
- stale artwork clearing on source change;
- rapid source-switch stale-capability rejection;
- typed toggle/previous/next/seek forwarding;
- controller-owned one-restart/no-loop lifecycle;
- privacy-safe exact report schema;
- candidate bundle resolution through `Bundle.main`;
- exact shipping isolation: `NotchHub.app` still contains no production media candidate or adapter assets.

Hosted CI continues to validate no-session fail-closed capabilities, candidate startup, privacy-safe observation, clean teardown and archive round-trip behavior.

## Target-Mac acceptance environment

The final physical gate must use the **current exact candidate** above on:

- hardware: `Mac16,8`;
- macOS: `26.6` / build `25G72`;
- candidate source: `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`.

The superseded #558 evidence remains diagnostic only. Because the production process lifecycle changed, final acceptance is intentionally re-run on the new candidate instead of mixing source revisions.

## Physical acceptance ledger

### `NH-MEDIA-PROD-001` — target Sandbox + Hardened Runtime

Status: **PENDING CURRENT CANDIDATE / PASS SUPERSEDED DIAGNOSTIC**

Required on the current candidate: strict code-sign verification, exact App Sandbox-only effective entitlements, Hardened Runtime and successful launch.

### `NH-MEDIA-PROD-002` — no-session fail-closed state

Status: **PENDING TARGET / PASS HOSTED**

With all media sources stopped/closed, target `capabilities` must not fabricate support. Normal no-session result is expected to remain `unknown/unknown/unknown`.

### `NH-MEDIA-PROD-003` — Yandex Music production observation

Status: **PENDING CURRENT CANDIDATE / PASS SUPERSEDED DIAGNOSTIC**

The old candidate observed `ru.yandex.desktop.music`, artwork and playing state. Re-run on the current candidate so lifecycle/teardown and source evidence belong to one exact revision.

### `NH-MEDIA-PROD-004` — browser production observation

Status: **PENDING**

Yandex Browser / YouTube must be observed as the authoritative system Now Playing source through the same production transport, without a browser-specific fallback controller.

### `NH-MEDIA-PROD-005` — source switching and disappearance

Status: **PENDING**

The superseded run proved real disappearance but had `sourceSwitchCount = 0`. The current-candidate source-cycle must exercise Yandex Music -> browser and produce `sourceSwitchCount > 0` when macOS authoritatively switches between the two bundle identifiers, then prove session disappearance.

### `NH-MEDIA-PROD-006` — authoritative capabilities

Status: **PENDING CURRENT CANDIDATE / ACTIVE-SOURCE PASS SUPERSEDED DIAGNOSTIC**

The old active-session preflight reported supported previous/next/seek. Final evidence must include current-candidate no-session fail-closed state and active-session exact tri-state values without inference from command success.

### `NH-MEDIA-PROD-007` — actual command behavior

Status: **PENDING**

Physically confirm toggle pause, toggle resume, next, previous and seek 42 seconds when the active session reports the corresponding capability as supported.

### `NH-MEDIA-PROD-008` — stale artwork regression

Status: **PASS DETERMINISTIC / PHYSICAL OPTIONAL**

Full-snapshot and rapid-switch deterministic tests prevent stale artwork/capability inheritance. Physical `observedArtworkClearOnSourceSwitch = true` is useful only if the available real source sequence naturally creates that condition; it is not required to manufacture it.

### `NH-MEDIA-PROD-009` — clean stop / no orphan

Status: **PENDING CURRENT CANDIDATE / SHORT-RUN PASS SUPERSEDED DIAGNOSTIC**

This is the gate materially affected by the target-discovered defect. Current-candidate observation and resource runs must report truthful `cleanTeardown = true` and no owned adapter process after exit.

### `NH-MEDIA-PROD-010` — bounded failure lifecycle

Status: **PASS DETERMINISTIC + PASS HOSTED CURRENT CANDIDATE**

The current candidate proves bounded graceful/forced child termination, fail-closed unconfirmed teardown, one controller restart only, stale callback rejection, and no restart loop. Destructive target fault injection is not required unless real target behavior contradicts these semantics.

### `NH-MEDIA-PROD-011` — no sensitive permission prompts

Status: **PENDING**

No Accessibility, Input Monitoring, Automation or Screen Recording permission prompt may appear during the target cycle.

### `NH-MEDIA-PROD-012` — 60-second resource evidence

Status: **PENDING CURRENT CANDIDATE / PASS SUPERSEDED DIAGNOSTIC**

The old 60-second run was healthy but is not final evidence after lifecycle code changed. Re-run the fixed 60-second collector on the current candidate.

### `NH-MEDIA-PROD-013` — 10-minute stability evidence

Status: **PENDING CURRENT CANDIDATE; PREVIOUS ATTEMPT EXPOSED FIXED DEFECT**

Run the approximately 10-minute current-candidate collector. It must complete, record CPU/RSS/thread summaries and drift, report clean teardown, and leave no owned adapter process. Sustained CPU/RSS/thread growth or unconfirmed teardown fails this gate.

## Current decision

**DO NOT COMPOSE INTO SHIPPING APP YET.**

M6.3 code is CI-qualified after the target-discovered lifecycle fix, but target acceptance must now be completed against exact candidate `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`. PR #16 remains Draft until that ledger is complete.

If the target gate passes, the next separate implementation slice may add `NotchHubMediaCore` and pinned adapter assets to `NotchHub.app` under the same reviewed Sandbox/security/performance boundary. Media UI remains a later slice.

No title, artist, album, artwork bytes, raw MediaRemote payload or listening history is retained in this ledger.
