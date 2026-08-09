# Universal Media Bridge Probe — Physical Acceptance Evidence

Status: **PARTIAL TARGET-MAC EVIDENCE — CURRENT CANDIDATE RERUN PENDING**

Authoritative physical procedure: `docs/testing/MEDIA_BRIDGE_PROBE.md`.

## Current acceptance candidate

- source SHA: `cda05bb4ff367d2c4a5d9d438c3f555f3788d186`;
- CI run: `#443` / `31304052700`;
- artifact: `MediaBridgeProbe-candidate` / ID `9035397233`;
- artifact digest: `sha256:5cd10a0c6e9b61d8f060ca29ab8a84a7b1a1ba2408f2769b88ea86bf908be5c0`;
- adapter SHA: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- capability patch SHA-256: `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`;
- observation report schema: `2`;
- Swift tests: **93/93 PASS**.

CI #443 passed both jobs completely and executed both real `capabilities` and one-second `observe` operations from the packaged Sandbox/Hardened Runtime candidate. The schema-v2 observation gate validates the privacy-safe `observedSessionDisappearance` and `sourceSwitchCount` fields. The MediaRemote adapter revision, capability patch, typed command surface, runtime entitlements, and shipping NotchHub boundary are unchanged from the first physical transport run.

Documentation-only commits after `cda05bb4...` do not change the candidate. Any later probe-code, packaging, security-policy, pinned-adapter, or capability-patch change requires a new exact candidate.

## Historical first Yandex evidence — superseded candidate

The first target-Mac run used source `231ada7baf83a3a1e9d2e38e35fc80a3f6d53758`, CI #432 / run `31302447286`, artifact ID `9034919275`.

Reported target hardware evidence on 2026-08-09:

- hardware model `Mac16,8`;
- macOS `26.6` / build `25G72`;
- active source `ru.yandex.desktop.music`;
- 60-second observation, event count `5`;
- session observed `true`;
- playing state observed `true`;
- artwork observed `true`;
- clean teardown `true`;
- orphan process detected `false`;
- authoritative active-source capabilities: `next=supported`, `previous=supported`, `seek=supported`.

This is strong historical evidence that the underlying transport and capability extension work on the target Mac. It demonstrated the transport behavior corresponding to `NH-MEDIA-BRIDGE-002`, `003`, `009`, `014`, and the active-source half of `016`. It is not silently promoted to final PASS for the current candidate because probe report code changed afterward.

No title, artist, album, artwork bytes, raw MediaRemote payload, or listening history is recorded here.

## Why schema v2 was added

The first report could not directly prove two required event-driven behaviors without manual interpretation:

- `NH-MEDIA-BRIDGE-008` — active source changes while the stream remains running;
- `NH-MEDIA-BRIDGE-013` — disappearance of an already observed session.

Schema v2 adds only two privacy-safe aggregates:

- `sourceSwitchCount`: count of observed changes between distinct non-null source bundle identifiers;
- `observedSessionDisappearance`: true only after a real session was observed and a later no-session payload arrived.

## Current candidate physical status

No physical gate is yet marked final PASS for source `cda05bb4ff367d2c4a5d9d438c3f555f3788d186`. The short current-candidate rerun should establish:

1. exact Sandbox/Hardened Runtime integrity;
2. no-session capabilities = `unknown/unknown/unknown`;
3. Yandex active capabilities;
4. actual toggle/next/previous/seek behavior;
5. schema-v2 Yandex observation;
6. source disappearance and source switching through the new aggregates;
7. no sensitive permission prompt.

The remaining multi-source matrix includes Apple Music, Spotify, browser media, and one additional independent Now Playing source, followed by target-Mac resource measurements.

`NH-MEDIA-BRIDGE-018` remains automatically covered by CI #443: probe assets are excluded from `NotchHub.app`, and shipping Sandbox/Hardened Runtime/security/performance gates pass.

## Transport decision

No final transport outcome is recorded yet. `ACCEPT_TRANSPORT`, `NEEDS_TRANSPORT_REDESIGN`, and `REJECT_TRANSPORT` remain pending until the current exact candidate's required physical matrix and resource evidence are reviewed.
