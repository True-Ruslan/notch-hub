# Production System Media Transport Implementation Plan

Status: **APPROVED FOR IMPLEMENTATION BY CONTINUATION AUTHORITY**
Date: 2026-08-09
Base: protected `main` after M6.2 (`e68fc524fa0c08439ad1bac91dc76a79f01f270f`)

## Goal

Implement the concrete production `SystemMediaTransport` behind the accepted M6.2 `SystemMediaBridge` without yet adding Media UI or starting the transport from the shipping `NotchHubApp`.

The implementation must reuse the already accepted M6.1 compatibility mechanism, not invent a second private integration:

- pinned upstream `ungive/mediaremote-adapter` revision `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- repo-owned authoritative-capability patch;
- fixed `/usr/bin/perl` process boundary;
- event-driven `stream --no-diff --micros` observation;
- fixed typed toggle/previous/next/seek command allowlist;
- bounded untrusted JSON/artwork handling;
- exact `supported | unsupported | unknown` previous/next/seek capability semantics;
- App Sandbox + Hardened Runtime with no new entitlement;
- one controlled restart remains owned by `MediaSessionController`.

This is a production-code transport slice, but shipping composition is intentionally deferred until this concrete transport has deterministic proof and a target-Mac candidate. `NotchHubMediaCore` therefore remains outside the current `NotchHubApp` dependency graph during this plan. This avoids running or packaging a private transport before its production implementation has been reviewed and physically accepted.

## External reference findings

`TheBoredTeam/boring.notch` was reviewed at `main` commit `71e50d8a5edc1010ceffa34f34348157183b76e4` and is recorded in `docs/PRODUCT_REFERENCES.md`.

Useful evidence:

- Boring Notch independently uses `ungive/mediaremote-adapter` and a fixed `/usr/bin/perl` real-time stream for modern system Now Playing observation.
- Its production implementation also resolves private MediaRemote functions directly in the app process and uses AppleScript/app-specific controllers for additional features.
- Its main app requests broader Automation/Apple Events, camera, calendar, file and network entitlements.
- Mature issue history highlights stale artwork, multi-player/source-switch fallback and display/fullscreen edge cases that NotchHub should defend against explicitly.

NotchHub adopts the external-process/event-stream lesson only. Direct private-framework dynamic loading in the app process, AppleScript fallbacks, per-player controllers and broader entitlements remain rejected for this milestone.

Boring Notch is GPL-3.0. Its source is a behavioral/architectural reference only; no GPL-covered implementation code may be copied into MIT NotchHub. The independently reviewed upstream MediaRemote Adapter remains BSD-3-Clause and is governed by its own license.

## Security decision

M6.1 produced `ACCEPT_TRANSPORT`, so `SECURITY.md` invariant 4 may now receive one narrowly scoped reviewed exception:

> Production `Process` use is permitted only inside the concrete MediaRemote transport process boundary, with executable fixed to `/usr/bin/perl`, repository-pinned adapter assets, closed argument construction, bounded stdout/stderr, explicit process ownership/teardown, and no shell or arbitrary executable/argument surface.

The exception does **not** permit `Process` elsewhere in `Sources/**` and does not relax the dynamic-loading ban inside the NotchHub process. The private framework is loaded only by the external `/usr/bin/perl` compatibility process when the transport is eventually packaged and composed.

No entitlement changes are authorized.

## Architecture

### `MediaRemoteWirePayload`

Internal validated representation of one `stream --no-diff --micros` event.

It retains only data needed to build `MediaSessionSnapshot` and an internal capability-refresh fingerprint:

- source bundle identifier;
- optional title / artist / album;
- playing;
- optional duration / elapsed time / reference timestamp / playback rate;
- optional bounded artwork bytes;
- optional stable content/unique identifier used only to suppress redundant capability queries.

Missing artwork is represented as `nil` and must clear previous artwork. No stale-field merge exists because production uses `--no-diff`.

Bounds initially match the physically accepted probe:

- maximum JSON line: 8 MiB;
- maximum artwork after base64 decode: 4 MiB;
- maximum UTF-8 text field: 16 KiB;
- maximum duration/position: 30 days;
- maximum absolute playback rate: 16.

### `MediaRemoteCapabilityPayload`

Strict decoder for exactly:

- `previous`;
- `next`;
- `seek`;

with values only `supported`, `unsupported`, or `unknown`. Unknown keys or values are rejected rather than ignored.

### `MediaRemoteProcessClient`

Internal typed process boundary used by the transport.

It exposes only:

- `startStream()` / `stopStream()`;
- one stream-line callback and one failure callback;
- `capabilities()`;
- `send(MediaCommand)`.

The concrete Foundation implementation owns all `Process`, `Pipe`, `FileHandle` and `/usr/bin/perl` details. `MediaRemoteSystemTransport` never constructs arbitrary command strings.

The concrete process client accepts validated resource URLs at construction but fixes:

- executable: `/usr/bin/perl`;
- stream command: `<script> <framework> stream --no-diff --micros`;
- capabilities command: `<script> <framework> capabilities`;
- toggle: `send 2`;
- next: `send 4`;
- previous: `send 5`;
- seek: `seek <positive bounded microseconds>`.

No test client is required by the production runtime path. The adapter test client remains development/probe-only.

### `MediaRemoteSystemTransport`

Concrete `SystemMediaTransport` implementation.

Responsibilities:

- idempotent start/stop;
- forward `ready` after the observation process is successfully owned;
- decode every stream line fail-closed;
- normalize valid active payloads to immutable snapshots;
- produce a strictly increasing `MediaSequence`;
- clear snapshot/artwork on no-session/source changes rather than carrying stale data;
- query authoritative capabilities only when the active media fingerprint changes;
- publish an immediate snapshot with capabilities `unknown/unknown/unknown`, then a newer snapshot if an authoritative capability query completes for the same still-current fingerprint;
- logically invalidate stale capability completions when a newer media fingerprint/session arrives;
- treat capability-query failure as capability `unknown`, not as fabricated support and not as loss of otherwise valid metadata;
- surface observation process launch/protocol/termination failures through `.failed` so the already-tested controller owns the one-restart policy;
- send only typed commands through the process client;
- never log/persist title, artist, album, artwork or listening history.

Capability refresh is deliberately keyed to media fingerprint rather than every play/pause/timestamp event. This avoids spawning a one-shot process for ordinary state-only updates while still refreshing on source/track changes. Target-Mac acceptance will measure this real production behavior before shipping composition.

## Sequence policy

- every transport `start()` creates a fresh stream generation;
- first active session after start begins media generation 1 / revision 1;
- source change or no-session -> new active session increments generation;
- updates within the same active source/session increment revision;
- authoritative capability completion for the still-current fingerprint increments revision;
- no-session always emits a sequence newer than the last session snapshot;
- stale stream/capability callbacks from an earlier start/session generation are ignored.

The controller remains the final stale/out-of-order guard; the transport also rejects its own stale asynchronous completions so bad ordering is not intentionally emitted upstream.

## TDD tasks

### Task 1 — bounded production wire decoder

Files:

- create `Sources/NotchHubMediaCore/MediaRemoteWire.swift`;
- create `Tests/NotchHubMediaCoreTests/MediaRemoteWireTests.swift`.

RED coverage first:

- full no-diff payload decodes normalized values;
- missing artwork remains nil;
- empty payload means no active session;
- diff payload is rejected;
- oversized line is rejected before JSON decode;
- oversized text is rejected;
- oversized/base64-invalid artwork is rejected;
- non-finite/negative/out-of-range duration, position and playback rate are rejected;
- capability decoder accepts exact tri-state schema;
- capability decoder rejects missing/extra/unknown fields.

### Task 2 — fixed production process boundary

Files:

- create `Sources/NotchHubMediaCore/MediaRemoteProcessClient.swift`;
- create `Tests/NotchHubMediaCoreTests/MediaRemoteProcessClientTests.swift`.

RED coverage first with injected fake launcher/handle:

- stream executable is exactly `/usr/bin/perl`;
- stream arguments are exact and contain no test client, shell or arbitrary argument surface;
- repeated start creates one process;
- stop clears handlers, terminates and waits exactly once;
- nonzero observation exit becomes failure;
- oversized/protocol-invalid stdout fails closed and tears down;
- stderr is bounded and not surfaced as metadata;
- one-shot commands use exact allowlist arguments;
- invalid seek is rejected before process launch;
- one-shot timeout terminates/waits and fails closed;
- capabilities stdout is bounded and decoded strictly.

### Task 3 — transport normalization/state/capabilities

Files:

- create `Sources/NotchHubMediaCore/MediaRemoteSystemTransport.swift`;
- create `Tests/NotchHubMediaCoreTests/MediaRemoteSystemTransportTests.swift`.

RED coverage first:

- start owns one process and emits ready;
- active payload produces playing/paused snapshot with normalized source/metadata/timing;
- empty payload emits newer no-session;
- missing artwork on a new payload clears artwork instead of reusing previous content;
- source switch cannot retain prior metadata/artwork;
- same-source state update increments revision without changing generation;
- new source/session increments generation;
- capability query runs once per changed media fingerprint, not play/pause-only update;
- first snapshot fails closed with unknown capabilities;
- matching authoritative capability result publishes a newer snapshot;
- stale capability result after source/track change is ignored;
- capability query failure leaves unknown capabilities without failing the metadata stream;
- malformed stream input fails transport;
- observation termination fails transport;
- repeated stop is idempotent and emits no stale callbacks;
- typed commands forward exactly through the process client.

Include explicit Boring-Notch-derived regression cases for stale artwork and rapid source switching.

### Task 4 — narrow security/performance policy exception

Files:

- modify `scripts/security-audit.sh`;
- modify policy tests as needed;
- modify `SECURITY.md`.

Rules:

- blanket `Process(` prohibition remains for all `Sources/**` except the exact reviewed production media process file;
- that file must contain `/usr/bin/perl` and exact stream/capability/command tokens;
- shell paths, `NSTask`, spawn/exec/popen, direct `dlopen`/`dlsym`, direct MediaRemote symbols, networking and broad input APIs remain prohibited;
- no entitlement changes;
- production metadata strings must not be written to logs;
- no periodic `get` command or timer/polling primitive may be added.

### Task 5 — production candidate harness without shipping composition

Reuse production `NotchHubMediaCore` code in a development-only executable target that packages the same adapter assets under Sandbox + Hardened Runtime. The candidate must exercise the **production transport implementation**, not the older probe process implementation, so target-Mac acceptance tests the code intended for shipping.

The harness may emit privacy-safe lifecycle/capability/source/result aggregates only. It must not persist title/artist/album/artwork/listening history.

The existing M6.1 probe remains historical evidence and is not deleted.

### Task 6 — target-Mac acceptance gate

Before shipping composition, run the production transport candidate on `Mac16,8` / macOS 26.6 and confirm at minimum:

- sandbox-only entitlement + Hardened Runtime;
- Yandex Music session/artwork/playback state;
- Yandex Browser session;
- no-session -> active -> source switch -> disappearance;
- authoritative capabilities;
- actual toggle/previous/next/seek through production transport;
- stale artwork regression: a payload/source without artwork does not display previous artwork;
- clean stop/no orphan;
- one-failure/one-restart controller path remains bounded;
- no Accessibility/Input Monitoring/Automation/Screen Recording prompts;
- 60-second and 10-minute parent+adapter resource evidence with no sustained growth.

Only after this passes may `NotchHubMediaCore` become a `NotchHubApp` dependency and production adapter assets enter `NotchHub.app` packaging.

## Deferred from this plan

- shipping app composition and asset packaging;
- media UI;
- progress rendering;
- gestures/haptics;
- volume/shuffle/repeat/favorite controls;
- AppleScript/player-specific fallback controllers;
- Apple Music/Spotify/additional-player compatibility claims not physically tested;
- direct private MediaRemote calls from NotchHub process;
- multi-display/fullscreen shell work except adding learned regression notes to the roadmap.

## Completion gate

This plan is implementation-complete only when deterministic production transport tests and repository security/package checks pass and a production-transport candidate is available for target-Mac acceptance. It is **not** shipping-complete until the separate physical acceptance gate passes.
