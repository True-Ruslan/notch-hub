# Production System Media Transport — Acceptance Evidence

Status: **CI-QUALIFIED — TARGET-MAC ACCEPTANCE ALMOST COMPLETE**

Authoritative implementation plan: `docs/superpowers/plans/2026-08-09-production-system-media-transport.md`.
Historical transport decision: `docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md` (`ACCEPT_TRANSPORT`).
Target procedure: `docs/testing/PRODUCTION_MEDIA_TRANSPORT_TARGET_MAC.md`.

## Current exact production-transport candidate

The physical candidate remains frozen at:

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

Later acceptance-documentation and collector-only fixes do not replace this frozen physical code candidate. Any later change to `Sources/NotchHubMediaCore/**`, `Tools/ProductionMediaTransportCandidate/**`, candidate packaging/signing, the pinned adapter, the capability patch, security/runtime policy or candidate entitlements requires a new exact candidate and artifact digest.

## Superseded candidate and target-discovered lifecycle defect

The previous candidate `3932426bcf063162ee7de1378ed301c9ce664746` from CI #558 / artifact `9039199985` is **SUPERSEDED** and must not be used for final M6.3 acceptance.

Its target-Mac stability run exposed an unbounded production teardown path after the sampling window. The frozen current candidate fixes that defect with bounded process-exit-event waits, graceful termination, owned-child `SIGKILL` escalation, a second bounded forced-exit wait, truthful `cleanTeardown`, `.teardownFailure` on unconfirmed exit, and no polling/repeating timer.

Deterministic RED→GREEN tests cover graceful-to-forced escalation, failed forced teardown, one-shot timeout cleanup and truthful candidate evidence. CI #576 proves the resulting real production candidate still builds, runs, verifies and archives successfully under macOS 26.

## Acceptance-tooling corrections

Two collector defects were found by physical testing and corrected without changing the frozen production candidate.

### Resource sampling boundary

The collector initially mixed command text into a parser that expects numeric CPU/RSS/thread values.

- RED: `ba7d5722d3a528356847a982beab90dd06429ef2`;
- GREEN: `44bb5b4b3b92b56a23b7601472fda0db0bf4cfd2`;
- verification: CI `#582` / `31371779783`, both jobs PASS.

The collector now reuses the proven Darwin process-sampling boundary: separate `%cpu` / `rss`, `ps -M` thread counting, then exact numeric `ProcessSample` values.

### Long-run completion watchdog

The first corrected 10-minute attempt reached valid sampling but the collector still imposed a brittle fixed 20-second completion watchdog after the sample loop.

- RED: `375fac050fb698e1bd6126530b3b7bbb9340e5bf`;
- GREEN: `d5d6927e46f56737873786938643ed9a483ced58`;
- verification: CI `#584` / `31377101223`, both jobs PASS.

The collector now uses an absolute observer lifetime deadline plus bounded `60s` completion grace. A genuine runaway still fails closed. This correction changed acceptance tooling only, not production transport behavior.

## CI-qualified transport properties

The frozen candidate retains these reviewed properties:

- strict bounded `stream --no-diff --micros` wire decoding;
- full-snapshot semantics with no stale-field merge;
- fixed `/usr/bin/perl` executable and closed adapter argument construction;
- no shell, arbitrary executable, arbitrary command-ID, player-specific fallback or network surface;
- authoritative tri-state capabilities;
- monotonic source/session generations and revisions;
- no-session invalidation;
- stale artwork clearing on source change;
- rapid source-switch stale-capability rejection;
- typed toggle/previous/next/seek forwarding;
- controller-owned one-restart/no-loop lifecycle;
- privacy-safe exact report schema;
- exact shipping isolation: `NotchHub.app` still contains no production media candidate or adapter assets.

## Target-Mac acceptance environment

Final physical evidence is for:

- hardware: `Mac16,8`;
- macOS: `26.6` / build `25G72`;
- candidate source: `c63f39c40b90d647e48271b9dc1d5ffd6e612c0b`.

## Current-candidate physical evidence received — 2026-08-10

### No-session preflight

The exact candidate now has a clean no-session target preflight:

- source provenance: exact frozen candidate;
- adapter and patch provenance: exact expected values;
- `codesignVerified = true`;
- `hardenedRuntime = true`;
- `sandboxOnly = true`;
- capabilities: `previous/next/seek = unknown/unknown/unknown`.

This closes the previously missing no-session fail-closed evidence.

### Yandex Music -> Yandex Browser source cycle

The exact candidate completed a 120-second source-cycle with:

- `observedSession = true`;
- `observedPlayingState = true`;
- `observedArtwork = true`;
- final authoritative source `ru.yandex.desktop.yandex-browser`;
- browser capabilities `previous/next/seek = unsupported/supported/supported`;
- `sourceSwitchCount = 1`;
- `observedSessionDisappearance = true`;
- `cleanTeardown = true`.

This proves the production transport follows a real system Now Playing switch to Yandex Browser without a browser-specific fallback and later observes session disappearance.

`observedArtworkClearOnSourceSwitch = false` is not a failure: physical artwork-clear evidence is optional unless the naturally available source sequence actually switches from an artwork-bearing item to a distinct no-artwork source. Deterministic stale-artwork coverage remains authoritative for that regression.

### Command dispatch evidence

With Yandex Music active, the candidate reported `previous/next/seek = supported/supported/supported`. The supplied terminal log shows successful transport responses for:

- toggle #1: `{"sent":true}`;
- toggle #2: `{"sent":true}`;
- next: `{"sent":true}`;
- previous: `{"sent":true}`;
- seek `42`: `{"sent":true}`.

This proves the production candidate accepted and dispatched the typed command surface without returning a transport error. It does **not** by itself prove that the real player visibly paused/resumed/switched/seeking correctly; that human-observed effect remains a required physical assertion for `NH-MEDIA-PROD-007`.

### 60-second steady resources

Already accepted current-candidate steady evidence:

- sample count: `60` at `1s` intervals after `10s` warmup;
- parent CPU median/max: `0.0/0.0%`;
- adapter CPU median/max: `0.0/0.1%`;
- parent RSS median/max: `6160/8304 KiB`;
- adapter RSS median/max: `20256/23888 KiB`;
- combined RSS median/max upper bounds: `26416/32192 KiB`;
- parent thread median/max: `2/4`;
- adapter thread median/max: `2/5`;
- combined thread median/max upper bounds: `4/9`;
- source: `ru.yandex.desktop.music`;
- capabilities: `supported/supported/supported`;
- `cleanTeardown = true`;
- `orphanProcessDetected = false`.

### Corrected 10-minute stability retry

The corrected stability run now completes normally and produces final JSON:

- requested duration: `600s`;
- sample interval: `5s`;
- sample count: `120`;
- source: `ru.yandex.desktop.music`;
- observer capabilities: `supported/supported/supported`;
- parent CPU median/max: `0.0/2.2%`;
- adapter CPU median/max: `0.0/5.3%`;
- combined CPU median/max upper bounds: `0.0/7.5%`;
- combined RSS median/max upper bounds: `26456/35168 KiB`;
- combined RSS start/end: `35168 -> 26160 KiB`;
- combined RSS drift: `-9008 KiB`;
- combined thread median/max upper bounds: `4/11`;
- combined thread start/end: `11 -> 4`;
- `observerReport.cleanTeardown = true`;
- `orphanProcessDetected = false`.

The run shows no sustained CPU signal, no RSS accumulation, no thread accumulation, a large negative RSS drift over the measured window, clean bounded teardown and no owned adapter left behind. This closes the target regression gate for the teardown defect discovered on the superseded candidate.

## Physical acceptance ledger

### `NH-MEDIA-PROD-001` — target Sandbox + Hardened Runtime

Status: **PASS CURRENT CANDIDATE**

Exact target preflight proves source/adapter/patch provenance, strict code-sign verification, App Sandbox-only effective entitlements, Hardened Runtime and successful launch.

### `NH-MEDIA-PROD-002` — no-session fail-closed state

Status: **PASS CURRENT CANDIDATE**

No-session target preflight reports exactly `previous/next/seek = unknown/unknown/unknown`; support is not fabricated in the absence of a system session.

### `NH-MEDIA-PROD-003` — Yandex Music production observation

Status: **PASS CURRENT CANDIDATE**

The current candidate observes `ru.yandex.desktop.music`, artwork and playing state through the production transport.

### `NH-MEDIA-PROD-004` — browser production observation

Status: **PASS CURRENT CANDIDATE**

The source-cycle ends with authoritative system source `ru.yandex.desktop.yandex-browser` and valid browser capability state through the same production transport.

### `NH-MEDIA-PROD-005` — source switching and disappearance

Status: **PASS CURRENT CANDIDATE**

The current source-cycle records `sourceSwitchCount = 1`, Yandex Browser as the resulting system source, later session disappearance and `cleanTeardown = true`.

### `NH-MEDIA-PROD-006` — authoritative capabilities

Status: **PASS CURRENT CANDIDATE**

No-session capabilities are `unknown/unknown/unknown`; active Yandex Music reports `supported/supported/supported`; Yandex Browser reports `unsupported/supported/supported` for previous/next/seek. The candidate preserves tri-state authority rather than manufacturing support.

### `NH-MEDIA-PROD-007` — actual command behavior

Status: **PARTIAL — TYPED DISPATCH PASS / REAL PLAYER EFFECT PENDING**

The candidate returned `sent=true` for toggle pause/resume, next, previous and seek 42 seconds while the active Yandex Music session reported all three queried capabilities as supported.

Final physical acceptance still requires the human-observed result that the real player actually paused, resumed, advanced, went back and moved to approximately `00:42`. A successful transport acknowledgement alone is intentionally not treated as proof of player behavior.

### `NH-MEDIA-PROD-008` — stale artwork regression

Status: **PASS DETERMINISTIC / PHYSICAL OPTIONAL**

Full-snapshot and rapid-switch deterministic tests prevent stale artwork/capability inheritance. The real source-cycle did not naturally produce an artwork-bearing -> no-artwork switch, so `observedArtworkClearOnSourceSwitch = false` is not treated as failure.

### `NH-MEDIA-PROD-009` — clean stop / no orphan

Status: **PASS CURRENT CANDIDATE**

Short source-cycle, 60-second steady and corrected 10-minute stability evidence all report clean teardown. Both resource runs report `orphanProcessDetected = false`.

### `NH-MEDIA-PROD-010` — bounded failure lifecycle

Status: **PASS DETERMINISTIC + PASS HOSTED CURRENT CANDIDATE + TARGET REGRESSION CONFIRMED**

Deterministic tests prove bounded graceful/forced child termination, fail-closed unconfirmed teardown, one controller restart only, stale callback rejection and no restart loop. The corrected 10-minute target run completes normally with `cleanTeardown = true` and no orphan child, confirming the target-discovered teardown regression is fixed on the frozen candidate.

### `NH-MEDIA-PROD-011` — no sensitive permission prompts

Status: **PENDING HUMAN OBSERVATION**

No Accessibility, Input Monitoring, Automation or Screen Recording permission prompt may appear during the target command/source cycle. The supplied machine evidence and terminal transcript do not state whether such prompts were shown, so this gate is intentionally not inferred.

### `NH-MEDIA-PROD-012` — 60-second resource evidence

Status: **PASS CURRENT CANDIDATE**

The accepted steady run has `0.0%` combined median CPU upper bound, low steady RSS/thread counts, `cleanTeardown = true` and no orphan process.

### `NH-MEDIA-PROD-013` — 10-minute stability evidence

Status: **PASS CURRENT CANDIDATE**

The corrected 600-second / 120-sample target run completed normally. Combined RSS changed `35168 -> 26160 KiB` (`-9008 KiB`), combined threads changed `11 -> 4`, combined median CPU upper bound remained `0.0%`, `observerReport.cleanTeardown = true`, and `orphanProcessDetected = false`.

## Current decision

**DO NOT COMPOSE INTO SHIPPING APP YET.**

M6.3 production transport is CI-qualified and all machine-verifiable target gates are now complete. The exact frozen candidate passes no-session fail-closed behavior, Yandex Music observation, Yandex Browser observation, authoritative source switching/disappearance, capability semantics, short/steady/long teardown and both resource gates.

Two human-observed assertions remain before PR #16 may become Ready or merge:

1. confirm that toggle pause/resume, next, previous and seek 42 seconds visibly affected the real player as intended;
2. confirm that no Accessibility, Input Monitoring, Automation or Screen Recording permission prompt appeared during the complete target cycle.

Once those two observations are recorded as PASS/NONE, update this ledger to **ACCEPTED**, synchronize `PROJECT_STATE.md`, `ROADMAP.md`, `CHANGELOG.md` and PR metadata, run fresh exact-head CI/review, mark PR #16 Ready and squash-merge through protected `main`.

Only after accepted M6.3 is merged may the next separate shipping-composition slice add `NotchHubMediaCore` and pinned adapter assets to `NotchHub.app` under fresh package/security/size/runtime evidence. Media UI remains later.

No title, artist, album, artwork bytes, raw MediaRemote payload or listening history is retained in this ledger.
