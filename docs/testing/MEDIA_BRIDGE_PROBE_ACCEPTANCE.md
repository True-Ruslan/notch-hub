# Universal Media Bridge Probe — Physical Acceptance Evidence

Status: **PARTIAL TARGET-MAC ACCEPTANCE — TRANSPORT DECISION PENDING**

Candidate under test:

- source SHA: `231ada7baf83a3a1e9d2e38e35fc80a3f6d53758`;
- CI run: `#432` / `31302447286`;
- artifact: `MediaBridgeProbe-candidate` / ID `9034919275`;
- artifact digest: `sha256:e4d52833982212ff533f034789516811da1177c80f63b07baa572dfc7652b13b`;
- adapter SHA: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- capability patch SHA-256: `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`.

Target hardware evidence reported on 2026-08-09:

- hardware model: `Mac16,8`;
- macOS: `26.6` / build `25G72`;
- active source: `ru.yandex.desktop.music`;
- observation duration: 60 seconds;
- event count: `5`;
- session observed: `true`;
- playing state observed: `true`;
- artwork observed: `true`;
- clean teardown: `true`;
- orphan process detected: `false`.

Authoritative capability output with Yandex Music active:

```json
{"next":"supported","previous":"supported","seek":"supported"}
```

No title, artist, album, artwork bytes, raw MediaRemote payload, or listening history is recorded here.

## Accepted from this evidence

- `NH-MEDIA-BRIDGE-002`: **PASS** — target Mac receives bounded event-driven system Now Playing observation; deterministic code/CI policy independently locks observation to `stream --no-diff --micros` with no periodic `get` polling.
- `NH-MEDIA-BRIDGE-003`: **PASS** — Yandex Music is observed as the active system Now Playing source (`ru.yandex.desktop.music`).
- `NH-MEDIA-BRIDGE-009`: **PASS** — artwork presence is observed for Yandex Music.
- `NH-MEDIA-BRIDGE-014`: **PASS** — report records clean teardown and no orphan process.

## Capability gate evidence

`NH-MEDIA-BRIDGE-016` has strong positive active-source evidence but is **not yet final PASS**.

Confirmed on the target Mac:

- active Yandex Music source returns authoritative `supported` for next;
- active Yandex Music source returns authoritative `supported` for previous;
- active Yandex Music source returns authoritative `supported` for seek.

Still required before final `NH-MEDIA-BRIDGE-016=PASS`:

- with no active macOS Now Playing source, the same exact candidate must return `unknown` for next/previous/seek on the target Mac.

The hosted macOS 26 CI runner already returned all three as `unknown` with no active source, but hosted-runner evidence does not replace the target-Mac physical half of this gate.

## Not yet accepted from this run

The following scenarios remain pending because the supplied evidence does not directly prove them:

- `NH-MEDIA-BRIDGE-001` — local entitlement/Hardened Runtime verification output was not recorded with this evidence bundle;
- `NH-MEDIA-BRIDGE-004` — Apple Music;
- `NH-MEDIA-BRIDGE-005` — Spotify;
- `NH-MEDIA-BRIDGE-006` — browser media;
- `NH-MEDIA-BRIDGE-007` — additional independent player;
- `NH-MEDIA-BRIDGE-008` — active-source switching;
- `NH-MEDIA-BRIDGE-010` — actual toggle play/pause command behavior;
- `NH-MEDIA-BRIDGE-011` — actual previous/next command behavior;
- `NH-MEDIA-BRIDGE-012` — actual seek behavior;
- `NH-MEDIA-BRIDGE-013` — source disappearance/no-session transition;
- `NH-MEDIA-BRIDGE-015` — physical failure-lifecycle scenario;
- `NH-MEDIA-BRIDGE-016` — target-Mac no-session half still pending;
- `NH-MEDIA-BRIDGE-017` — no sensitive permission prompt was not explicitly recorded in the supplied evidence.

`NH-MEDIA-BRIDGE-018` remains automatically verified by the exact candidate CI shipping job: probe assets are excluded from `NotchHub.app` and the shipping Sandbox/Hardened Runtime boundary remains unchanged.

## Transport decision

No final transport outcome is recorded yet. `ACCEPT_TRANSPORT`, `NEEDS_TRANSPORT_REDESIGN`, and `REJECT_TRANSPORT` remain pending until the remaining required physical matrix and resource evidence are reviewed.
