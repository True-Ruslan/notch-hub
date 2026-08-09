# Universal Media Bridge Probe — Physical Acceptance Evidence

Status: **ACCEPTED — `ACCEPT_TRANSPORT`**

Authoritative physical procedure: `docs/testing/MEDIA_BRIDGE_PROBE.md`.

## Current acceptance candidate

- source SHA: `cda05bb4ff367d2c4a5d9d438c3f555f3788d186`;
- CI run: `#443` / `31304052700`;
- artifact: `MediaBridgeProbe-candidate` / ID `9035397233`;
- artifact digest: `sha256:5cd10a0c6e9b61d8f060ca29ab8a84a7b1a1ba2408f2769b88ea86bf908be5c0`;
- adapter SHA: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- capability patch SHA-256: `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`;
- observation report schema: `2`;
- Swift tests at candidate creation: **93/93 PASS**.

Documentation-only commits after `cda05bb4...` do not change the physical candidate. Any later probe-code, packaging, security-policy, pinned-adapter, or capability-patch change requires a new exact candidate.

## Target environment

Physical evidence collected on 2026-08-09:

- hardware model: `Mac16,8`;
- macOS: `26.6` / build `25G72`;
- source recorded by probe reports: `cda05bb4ff367d2c4a5d9d438c3f555f3788d186`;
- effective entitlements: exactly `com.apple.security.app-sandbox = true`;
- local code-signing output: `flags=0x10002(adhoc,runtime)` and explicit `HARDENED_RUNTIME=PASS`;
- no Accessibility, Input Monitoring, Automation, or Screen Recording prompt appeared during the physical command/observation cycle.

Accordingly `NH-MEDIA-BRIDGE-001` and `NH-MEDIA-BRIDGE-017` are **PASS**.

## Capability surface

No active Now Playing source:

```json
{"next":"unknown","previous":"unknown","seek":"unknown"}
```

Yandex Music active:

```json
{"next":"supported","previous":"supported","seek":"supported"}
```

Browser media active:

```json
{"next":"supported","previous":"supported","seek":"supported"}
```

An earlier mixed snapshot (`next=supported`, `previous=unsupported`, `seek=supported`) is retained only as diagnostic evidence that the tri-state decoder can represent `unsupported`; the source identity for that exact instant was not separately recorded.

`NH-MEDIA-BRIDGE-016`: **PASS** — no-session fails closed to `unknown`; active real sources expose authoritative previous/next/seek states without inferring support from later command behavior.

## Yandex Music physical evidence

Stable schema-v2 observation:

- source bundle: `ru.yandex.desktop.music`;
- event count: `3`;
- session observed: `true`;
- playing state observed: `true`;
- artwork observed: `true`;
- clean teardown: `true`;
- orphan process detected: `false`;
- `observedSessionDisappearance=false`;
- `sourceSwitchCount=0`.

A separate transition run on the same candidate recorded:

- event count: `9`;
- final source bundle: `ru.yandex.desktop.music`;
- session/artwork/playing state observed: `true`;
- `observedSessionDisappearance=true`;
- `sourceSwitchCount=2`;
- clean teardown: `true`;
- orphan process detected: `false`.

The stable run shows that schema-v2 transition counters do not invent transitions. The transition run directly proves event-driven source switching and disappearance because `sourceSwitchCount` increments only between distinct non-null bundle identifiers and `observedSessionDisappearance` is set only after an observed real session later becomes no-session.

Physical command behavior was explicitly confirmed on the target Mac:

- toggle paused playback: PASS;
- second toggle resumed playback: PASS;
- next changed track: PASS;
- previous changed track: PASS;
- seek to `42000000` microseconds moved playback to approximately 42 seconds: PASS.

Therefore `NH-MEDIA-BRIDGE-002`, `003`, `008`, `009`, `010`, `011`, `012`, `013`, and `014` are **PASS** from current-candidate target-Mac evidence.

## Browser physical evidence

Yandex Browser media was tested on the same exact candidate.

Capability snapshot:

```json
{"next":"supported","previous":"supported","seek":"supported"}
```

Schema-v2 report:

- source bundle: `ru.yandex.desktop.yandex-browser`;
- event count: `2`;
- session observed: `true`;
- playing state observed: `true`;
- artwork observed: `true`;
- clean teardown: `true`;
- orphan process detected: `false`;
- `observedSessionDisappearance=false`;
- `sourceSwitchCount=0`;
- source commit: `cda05bb4ff367d2c4a5d9d438c3f555f3788d186`.

`NH-MEDIA-BRIDGE-006`: **PASS** — browser media publishes a system Now Playing session and is observed through the same event-driven transport.

## Failure lifecycle

`NH-MEDIA-BRIDGE-015`: **PASS (deterministic exact-candidate coverage)**.

A target-Mac crash injection is intentionally not required because the exact candidate's process boundary is deterministic and its failure properties are stronger when asserted without timing or manual intervention:

- a non-zero owned adapter exit transitions to `.failed(exitCode:)`;
- launch count remains exactly one, proving no automatic restart loop;
- an oversized/protocol-invalid stream fails closed to `.protocolFailure`, terminates the owned process, and waits for it;
- explicit stop clears handlers, terminates only the owned running process, waits for exit, and becomes `.stopped`;
- one-shot timeout terminates, performs the final wait, clears handlers, and throws `timedOut`;
- the concrete exact-candidate implementation contains no automatic observation restart path.

These tests are part of the 93/93 exact-candidate Swift test suite executed by CI #443. Physical evidence separately proves ordinary clean teardown/no orphan behavior on the target Mac.

## Source-coverage policy for this Personal Release

The original compatibility matrix also listed Apple Music, Spotify, and one additional independent player. These are useful breadth checks, but they are not architectural proof of the MediaRemote transport itself.

On the actual personal target Mac:

- `NH-MEDIA-BRIDGE-004` — Apple Music: **NOT TESTED / DEFERRED** — no Apple Music subscription/source available for the acceptance cycle;
- `NH-MEDIA-BRIDGE-005` — Spotify: **NOT TESTED / DEFERRED** — Spotify is not installed/available on the target Mac;
- `NH-MEDIA-BRIDGE-007` — additional independent player: **NOT TESTED / DEFERRED** — no such player is installed/used on the target Mac.

These are explicitly **not FAIL**. We will not install or subscribe to otherwise-unused media products solely to satisfy a synthetic compatibility matrix for a personal application. The consequence is equally explicit: this M6.1 acceptance justifies the transport for the user's actual Personal Release environment, but it does not claim verified compatibility with Apple Music, Spotify, or arbitrary third-party players until those sources are tested in the future.

The transport is demonstrated across two distinct real system Now Playing publishers on the same target Mac: Yandex Music (`ru.yandex.desktop.music`) and Yandex Browser (`ru.yandex.desktop.yandex-browser`), plus continuous source-switch/disappearance evidence.

## Resource evidence

The target-Mac resource cycle used the exact current candidate with Yandex Music active. The existing privacy-safe sampler attached independently to the parent probe and its owned `/usr/bin/perl` adapter.

### 60-second steady-state measurements

Both processes were sampled for exactly 60 one-second samples after a 10-second warmup:

- parent probe: CPU median/max `0.0% / 0.0%`, RSS median/max `5,680 / 5,680 KiB`, threads median/max `2 / 2`;
- owned adapter: CPU median/max `0.0% / 0.0%`, RSS median/max `20,288 / 20,288 KiB`, threads median/max `2 / 2`;
- combined steady-state RSS from the two synchronized summaries: `25,968 KiB` (~25.4 MiB), 4 threads, sampled CPU `0.0%`.

The first attempted 10-minute resource measurement was invalid because the manually configured 700-second observer reached its natural end before the later stability samplers completed. That orchestration mistake is retained as **INVALID / RETRIED**, not as a transport failure; the valid 60-second evidence remained accepted.

### 10-minute stability measurements

The corrected stability-only run used `observe --seconds 640`, then started both resource samplers immediately. Each sampler produced exactly 120 samples at 5-second intervals over ~600 seconds.

Parent probe:

- CPU median/max: `0.0% / 0.0%`;
- RSS median/max: `5,664 / 7,328 KiB`;
- RSS start/first-quartile/end: `5,680 / 5,664 / 5,552 KiB`;
- RSS end-minus-start: `-128 KiB`;
- threads median/max: `2 / 2`;
- thread start/end: `2 / 2`.

Owned adapter:

- CPU median/max: `0.0% / 0.1%`;
- RSS median/max: `20,368 / 24,480 KiB`;
- RSS start/first-quartile/end: `20,288 / 20,256 / 20,256 KiB`;
- RSS end-minus-start: `-32 KiB`;
- threads median/max: `2 / 6`;
- thread start/end: `2 / 2`.

Combined end-minus-start RSS drift is `-160 KiB`; combined ending thread count is unchanged at 4. Individual RSS maxima provide a conservative simultaneous upper bound of `31,808 KiB` (~31.1 MiB), still below the accepted whole-app P0 stability RSS ceiling of `45,056 KiB`; this comparison is contextual only because M6.1 measures the development transport probe rather than shipping NotchHub.

The same 640-second observer run recorded 21 events, a real Yandex Music session/artwork/playing state, `observedSessionDisappearance=true`, `sourceSwitchCount=6`, `cleanTeardown=true`, and `orphanProcessDetected=false`. Shell lifecycle verification after natural completion independently returned `PROBE_TEARDOWN=PASS` and `PERL_TEARDOWN=PASS`.

There is no sustained CPU, RSS, or thread growth in the accepted target-Mac evidence.

## Final gate ledger

PASS:

- `NH-MEDIA-BRIDGE-001` — sandboxed + Hardened Runtime target-Mac launch;
- `NH-MEDIA-BRIDGE-002` — event-driven system Now Playing observation;
- `NH-MEDIA-BRIDGE-003` — Yandex Music;
- `NH-MEDIA-BRIDGE-006` — browser media;
- `NH-MEDIA-BRIDGE-008` — active-source switching;
- `NH-MEDIA-BRIDGE-009` — artwork presence;
- `NH-MEDIA-BRIDGE-010` — play/pause toggle;
- `NH-MEDIA-BRIDGE-011` — previous/next;
- `NH-MEDIA-BRIDGE-012` — seek;
- `NH-MEDIA-BRIDGE-013` — source disappearance;
- `NH-MEDIA-BRIDGE-014` — clean teardown/no orphan;
- `NH-MEDIA-BRIDGE-015` — bounded failure lifecycle/no restart loop, deterministic CI-backed;
- `NH-MEDIA-BRIDGE-016` — authoritative capability surface;
- `NH-MEDIA-BRIDGE-017` — no sensitive permission prompt;
- `NH-MEDIA-BRIDGE-018` — shipping isolation, CI-backed by exact-candidate CI;
- target-Mac 60-second resource evidence — PASS;
- target-Mac 10-minute stability evidence — PASS.

DEFERRED / NOT TESTED because source is unavailable and not part of the user's current personal environment:

- `NH-MEDIA-BRIDGE-004` — Apple Music;
- `NH-MEDIA-BRIDGE-005` — Spotify;
- `NH-MEDIA-BRIDGE-007` — additional independent player.

No required gate for the actual Personal Release environment remains pending.

## Transport decision

**`ACCEPT_TRANSPORT`**

Rationale:

1. the transport works under the required App Sandbox + Hardened Runtime boundary without sensitive permissions or OS-security weakening;
2. observation is event-driven and the shipping app remains free of probe/private compatibility code;
3. authoritative command capabilities fail closed to `unknown` and expose real supported states on active sources;
4. real Yandex Music and browser system Now Playing publishers are observed on the target Mac;
5. actual play/pause, previous/next, and seek behavior works on the physically tested source;
6. source switching, source disappearance, clean teardown, bounded failures, and no-restart-loop behavior are proven;
7. 60-second and 10-minute target-Mac measurements show negligible sampled CPU, bounded RSS/threads, negative RSS drift, and no sustained resource accumulation.

This decision authorizes planning and implementation of the production `MediaProvider` / `MediaSessionSnapshot` / `MediaSessionController` / isolated `SystemMediaBridge` architecture defined by the approved Universal Media design. It does **not** authorize copying the development probe wholesale into shipping code, broadening permissions, adding polling, or claiming verified Apple Music/Spotify/arbitrary-player compatibility before those sources are actually tested.

No title, artist, album, artwork bytes, raw MediaRemote payload, or listening history is retained in this ledger.
