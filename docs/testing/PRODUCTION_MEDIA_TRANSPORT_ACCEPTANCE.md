# Production System Media Transport — Acceptance Evidence

Status: **CI-QUALIFIED — TARGET-MAC ACCEPTANCE PARTIAL**

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

Any later change to `Sources/NotchHubMediaCore/**`, `Tools/ProductionMediaTransportCandidate/**`, candidate packaging/signing, the pinned adapter, the capability patch, security/runtime policy or candidate entitlements requires a new exact candidate and artifact digest. Documentation-only acceptance updates and collector-only tooling fixes do not replace the candidate above.

## Superseded candidate and target-discovered lifecycle defect

The previous candidate `3932426bcf063162ee7de1378ed301c9ce664746` from CI #558 / artifact `9039199985` is **SUPERSEDED** and must not be used for final M6.3 acceptance.

Target-Mac evidence on `Mac16,8` / macOS 26.6 established useful diagnostics before supersession:

- exact source/adapter/patch provenance, code-sign verification, App Sandbox-only entitlements and Hardened Runtime passed;
- active Yandex Music reported authoritative `previous/next/seek = supported/supported/supported`;
- a 60-second steady run completed with very low CPU, healthy RSS/thread counts, `cleanTeardown = true`, and no orphan process;
- a source-cycle run observed a real Yandex Music session, artwork, playing state and session disappearance with `cleanTeardown = true`; however `sourceSwitchCount = 0`, so browser/source-switch acceptance was not established.

The approximately 10-minute stability run then exposed a real lifecycle defect. Sampling reached the long-running observer, but candidate finalization did not finish within the collector watchdog after the 600-second sample window. Investigation found unbounded `Process.waitUntilExit()` calls in production observation/protocol/timeout teardown paths. This was a candidate defect, not a resource-budget failure and not a user-command error.

The current exact candidate fixes that defect by:

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

## Acceptance-tooling defects found on the current candidate

Two collector defects were found by the target-Mac runs and fixed without changing the frozen production candidate.

### Resource sampling boundary

The first current-candidate `steady` and `stability` attempts were **INVALID / RETRY REQUIRED**, not transport/performance FAIL. The collector passed `%cpu,rss,command` output into a parser that requires numeric `CPU RSS threads`, and then accumulated dictionaries even though the shared summary functions require `ProcessSample` values.

- RED: `ba7d5722d3a528356847a982beab90dd06429ef2`;
- GREEN: `44bb5b4b3b92b56a23b7601472fda0db0bf4cfd2`;
- verification: CI `#582` / `31371779783`, both jobs PASS.

The collector now reuses the already-proven Darwin sampling boundary from `perf-baseline.py`: separate `%cpu`/`rss`, `ps -M` thread counting, then exact numeric `ProcessSample` values.

### Long-run completion watchdog

After the sampling fix, the current candidate passed the 60-second steady run, but the approximately 10-minute run again produced no JSON because the collector still allowed only a fixed `20s` for a `610s` observer to finish after sampling. The successful steady run showed that actual wall time can already exceed the internal observer duration by several seconds, making the fixed post-sampling watchdog too brittle for the long acceptance case.

This attempt is **INVALID / RETRY REQUIRED**, not transport/performance FAIL. Production teardown code did not regress.

- RED: `375fac050fb698e1bd6126530b3b7bbb9340e5bf`;
- GREEN: `d5d6927e46f56737873786938643ed9a483ced58`;
- verification: CI `#584` / `31377101223`, both jobs PASS.

The collector now computes an absolute observer deadline from process start and allows a bounded `60s` completion grace after the requested observer lifetime. If that absolute deadline is exceeded, the run still fails closed. No production timeout or media transport behavior was relaxed.

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

The final physical gate uses the **current exact candidate** above on:

- hardware: `Mac16,8`;
- macOS: `26.6` / build `25G72`;
- candidate source: `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`.

## Current-candidate physical evidence received

Current target evidence already proves:

- exact candidate source/adapter/patch provenance;
- strict code-sign verification;
- effective entitlement set is App Sandbox only;
- Hardened Runtime is present;
- active-session capability query reports `previous/next/seek = supported/supported/supported`;
- Yandex Music session `ru.yandex.desktop.music` is observed through the production transport;
- artwork and playing state are observed;
- a real session disappearance is observed;
- the completed current-candidate 120-second observation reports `cleanTeardown = true`;
- the completed current-candidate 60-second resource run reports healthy CPU/RSS/thread behavior, `cleanTeardown = true`, and no orphan adapter process.

The received source-cycle has `sourceSwitchCount = 0`, so browser/source-switch acceptance is not yet established. The received preflight was executed with an active media session, so no-session fail-closed state is also still pending.

## Physical acceptance ledger

### `NH-MEDIA-PROD-001` — target Sandbox + Hardened Runtime

Status: **PASS CURRENT CANDIDATE**

Current-candidate preflight on `Mac16,8` / macOS 26.6 proves exact provenance, strict code-sign verification, App Sandbox-only effective entitlements, Hardened Runtime and successful launch.

### `NH-MEDIA-PROD-002` — no-session fail-closed state

Status: **PENDING TARGET / PASS HOSTED**

The received current-candidate preflight was executed with an active source and therefore returned `supported/supported/supported`. Re-run preflight once with all media sources stopped/closed. Normal no-session result is expected to remain `unknown/unknown/unknown`; support must never be fabricated.

### `NH-MEDIA-PROD-003` — Yandex Music production observation

Status: **PASS CURRENT CANDIDATE**

The current candidate observed `ru.yandex.desktop.music`, artwork and playing state through the production transport.

### `NH-MEDIA-PROD-004` — browser production observation

Status: **PENDING**

Yandex Browser / YouTube must be observed as the authoritative system Now Playing source through the same production transport, without a browser-specific fallback controller.

### `NH-MEDIA-PROD-005` — source switching and disappearance

Status: **PARTIAL — DISAPPEARANCE PASS / SOURCE SWITCH PENDING**

The current candidate observed real session disappearance and clean teardown. The received source-cycle has `sourceSwitchCount = 0`, so a real authoritative Yandex Music -> browser switch remains to be demonstrated.

### `NH-MEDIA-PROD-006` — authoritative capabilities

Status: **PARTIAL — ACTIVE SOURCE PASS / NO-SESSION PENDING**

The current candidate reports `previous/next/seek = supported/supported/supported` with the active Yandex Music session. Final evidence still needs the separate no-session fail-closed preflight. Command support is not inferred from later command behavior.

### `NH-MEDIA-PROD-007` — actual command behavior

Status: **PENDING**

Physically confirm toggle pause, toggle resume, next, previous and seek 42 seconds when the active session reports the corresponding capability as supported.

### `NH-MEDIA-PROD-008` — stale artwork regression

Status: **PASS DETERMINISTIC / PHYSICAL OPTIONAL**

Full-snapshot and rapid-switch deterministic tests prevent stale artwork/capability inheritance. Physical `observedArtworkClearOnSourceSwitch = true` is useful only if the available real source sequence naturally creates that condition; it is not required to manufacture it.

### `NH-MEDIA-PROD-009` — clean stop / no orphan

Status: **PASS CURRENT SHORT/STEADY RUNS / LONG-RUN CONFIRMATION PENDING**

The current-candidate source-cycle reports `cleanTeardown = true`. The current-candidate 60-second resource run also reports `cleanTeardown = true` and `orphanProcessDetected = false`. The 10-minute regression run remains the final long-run confirmation.

### `NH-MEDIA-PROD-010` — bounded failure lifecycle

Status: **PASS DETERMINISTIC + PASS HOSTED CURRENT CANDIDATE**

The current candidate proves bounded graceful/forced child termination, fail-closed unconfirmed teardown, one controller restart only, stale callback rejection, and no restart loop. Destructive target fault injection is not required unless real target behavior contradicts these semantics.

### `NH-MEDIA-PROD-011` — no sensitive permission prompts

Status: **PENDING**

No Accessibility, Input Monitoring, Automation or Screen Recording permission prompt may appear during the target cycle.

### `NH-MEDIA-PROD-012` — 60-second resource evidence

Status: **PASS CURRENT CANDIDATE**

Current-candidate steady evidence on `Mac16,8` / macOS 26.6:

- sample count: `60` at `1s` intervals after `10s` warmup;
- parent CPU median/max: `0.0/0.0%`;
- adapter CPU median/max: `0.0/0.1%`;
- parent RSS median/max: `6160/8304 KiB`;
- adapter RSS median/max: `20256/23888 KiB`;
- combined RSS median/max upper bounds: `26416/32192 KiB`;
- parent thread median/max: `2/4`;
- adapter thread median/max: `2/5`;
- combined thread median/max upper bounds: `4/9`;
- observer source: `ru.yandex.desktop.music`;
- observer capabilities: `supported/supported/supported`;
- `cleanTeardown = true`;
- `orphanProcessDetected = false`.

There is no sustained background CPU signal in this run and no orphan process at teardown.

### `NH-MEDIA-PROD-013` — 10-minute stability evidence

Status: **PENDING RETRY — LATEST ATTEMPT INVALID DUE TO FIXED COLLECTOR WATCHDOG**

The latest current-candidate attempt reached the corrected resource sampling path but the collector terminated the `observe --seconds 610.0` process after the superseded fixed 20-second post-sampling watchdog. No `resources-10min.json` was produced, so this attempt is neither PASS nor FAIL for transport/resource stability.

Collector-only fix `d5d6927e46f56737873786938643ed9a483ced58` replaces that brittle watchdog with an absolute observer deadline plus bounded 60-second completion grace. CI #584 is fully green. Re-run only the 10-minute stability command; the current-candidate preflight, source-cycle and 60-second resource evidence remain valid.

The successful retry must complete, record CPU/RSS/thread summaries and drift, report clean teardown, and leave no owned adapter process. Sustained CPU/RSS/thread growth or unconfirmed teardown fails the gate.

## Current decision

**DO NOT COMPOSE INTO SHIPPING APP YET.**

M6.3 code is CI-qualified and the current physical evidence now passes Sandbox/Hardened Runtime, Yandex Music observation, active-source capabilities, disappearance, short/steady teardown and the 60-second resource gate. Remaining target work is limited to no-session preflight, browser/source switching, actual command behavior + permission prompts, and the corrected 10-minute stability retry.

PR #16 remains Draft until those gates are complete and the final decision is recorded here.

If the target gate passes, the next separate implementation slice may add `NotchHubMediaCore` and pinned adapter assets to `NotchHub.app` under the same reviewed Sandbox/security/performance boundary. Media UI remains a later slice.

No title, artist, album, artwork bytes, raw MediaRemote payload or listening history is retained in this ledger.
