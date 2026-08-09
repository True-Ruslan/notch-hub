# Universal Media Bridge Probe — Physical Acceptance Evidence

Status: **TARGET-MAC CORE TRANSPORT ACCEPTED SO FAR — RESOURCE GATE PENDING**

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

Physical command behavior was also explicitly confirmed by the user on the target Mac:

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

These tests are part of the 93/93 exact-candidate Swift test suite executed by CI #443. Physical evidence already separately proves ordinary clean teardown/no orphan behavior on the target Mac. Artificially killing the adapter on the personal machine would therefore add lower-quality, timing-dependent evidence without exercising a different production branch.

## Source-coverage policy for this Personal Release

The original compatibility matrix also listed Apple Music, Spotify, and one additional independent player. These are useful breadth checks, but they are not architectural proof of the MediaRemote transport itself.

On the actual personal target Mac:

- `NH-MEDIA-BRIDGE-004` — Apple Music: **NOT TESTED / DEFERRED** — no Apple Music subscription/source available for the acceptance cycle;
- `NH-MEDIA-BRIDGE-005` — Spotify: **NOT TESTED / DEFERRED** — Spotify is not installed/available on the target Mac;
- `NH-MEDIA-BRIDGE-007` — additional independent player: **NOT TESTED / DEFERRED** — no such player is installed/used on the target Mac.

These are explicitly **not FAIL**. We will not install or subscribe to otherwise-unused media products solely to satisfy a synthetic compatibility matrix for a personal application. The consequence is equally explicit: this M6.1 acceptance may justify the transport for the user's actual Personal Release environment, but it must not claim verified compatibility with Apple Music, Spotify, or arbitrary third-party players until those sources are tested in the future.

The transport itself is already demonstrated across two distinct real system Now Playing publishers on the same target Mac: Yandex Music (`ru.yandex.desktop.music`) and Yandex Browser (`ru.yandex.desktop.yandex-browser`), plus a continuous source-switch/disappearance run.

## Current gate ledger

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
- `NH-MEDIA-BRIDGE-018` — shipping isolation, CI-backed by exact-candidate CI.

DEFERRED / NOT TESTED because source is unavailable and not part of the user's current personal environment:

- `NH-MEDIA-BRIDGE-004` — Apple Music;
- `NH-MEDIA-BRIDGE-005` — Spotify;
- `NH-MEDIA-BRIDGE-007` — additional independent player.

Pending:

- target-Mac parent + owned-adapter resource measurements and planned stability run.

## Historical first Yandex evidence — superseded candidate

The first target-Mac run used source `231ada7baf83a3a1e9d2e38e35fc80a3f6d53758`, CI #432 / run `31302447286`, artifact ID `9034919275`. It remains useful historical transport evidence, but all final PASS statuses above are tied to the current `cda05bb4...` candidate.

## Remaining acceptance work

1. Collect target-Mac parent/owned-perl CPU, RSS, and thread measurements, including the planned stability run.
2. Review all evidence and record exactly one final outcome: `ACCEPT_TRANSPORT`, `NEEDS_TRANSPORT_REDESIGN`, or `REJECT_TRANSPORT`.

No title, artist, album, artwork bytes, raw MediaRemote payload, or listening history is retained in this ledger.

## Transport decision

No final transport outcome is recorded yet. The current evidence strongly supports the transport for the actual Personal Release environment; only target-Mac resource/stability evidence remains before the decision.