# Universal Media Bridge Probe — Physical Acceptance Evidence

Status: **PARTIAL TARGET-MAC ACCEPTANCE — TRANSPORT DECISION PENDING**

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

## Current target-Mac evidence

Target hardware reported on 2026-08-09:

- hardware model: `Mac16,8`;
- macOS: `26.6` / build `25G72`;
- exact current candidate source recorded by the probe: `cda05bb4ff367d2c4a5d9d438c3f555f3788d186`;
- effective entitlements: exactly `com.apple.security.app-sandbox = true` and no additional entitlement key.

### Capability surface

With no active system Now Playing source, the target Mac returned:

```json
{"next":"unknown","previous":"unknown","seek":"unknown"}
```

With Yandex Music active, the target Mac returned:

```json
{"next":"supported","previous":"supported","seek":"supported"}
```

An earlier snapshot in the same physical session also returned a mixed authoritative state (`next=supported`, `previous=unsupported`, `seek=supported`) before the explicit no-source test. This is retained as diagnostic evidence that the probe can represent `unsupported` independently, but it is not attributed to Yandex because the active source identity for that instant was not separately recorded.

This completes both halves of `NH-MEDIA-BRIDGE-016` on the current candidate: no-session/indeterminate state fails closed to `unknown`, while an active real source exposes authoritative command states without inferring them from later command behavior.

### Stable Yandex observation

The uploaded schema-v2 Yandex report records:

- source bundle: `ru.yandex.desktop.music`;
- event count: `3`;
- session observed: `true`;
- playing state observed: `true`;
- artwork observed: `true`;
- clean teardown: `true`;
- orphan process detected: `false`;
- `observedSessionDisappearance=false`;
- `sourceSwitchCount=0`.

The zero transition aggregates are expected for this later stable Yandex-only run and demonstrate that schema v2 does not manufacture source changes or disappearance events during a stable source.

### Transition-observation run

A separate schema-v2 run on the same exact current candidate recorded:

- event count: `9`;
- final source bundle: `ru.yandex.desktop.music`;
- session/artwork/playing state observed: `true`;
- `observedSessionDisappearance=true`;
- `sourceSwitchCount=2`;
- clean teardown: `true`;
- orphan process detected: `false`.

`ProbeObservationEvidence` increments `sourceSwitchCount` only when two consecutive non-null observed bundle identifiers differ, and sets `observedSessionDisappearance` only after a real session has already been observed and a later no-session payload arrives. Therefore this run is accepted as direct event-stream evidence for active-source switching and source disappearance without relying on track metadata or manual visual interpretation.

No title, artist, album, artwork bytes, raw MediaRemote payload, or listening history is recorded here.

## Current-candidate acceptance status

Accepted from the current exact candidate:

- `NH-MEDIA-BRIDGE-002`: **PASS** — target Mac receives system Now Playing through the event-driven stream; implementation/CI policy independently locks it to `stream --no-diff --micros` with no periodic `get` polling.
- `NH-MEDIA-BRIDGE-003`: **PASS** — Yandex Music is observed as `ru.yandex.desktop.music`.
- `NH-MEDIA-BRIDGE-008`: **PASS** — one continuous schema-v2 observation recorded two changes between distinct non-null source bundle identifiers without restart/polling.
- `NH-MEDIA-BRIDGE-009`: **PASS** — artwork presence is observed for Yandex Music.
- `NH-MEDIA-BRIDGE-013`: **PASS** — after a real media session was observed, the event stream later produced a no-session state without probe failure.
- `NH-MEDIA-BRIDGE-014`: **PASS** — both supplied schema-v2 reports record clean teardown and no orphan process.
- `NH-MEDIA-BRIDGE-016`: **PASS** — target-Mac no-session returns `unknown/unknown/unknown`; active Yandex returns authoritative `supported/supported/supported`; no command-success heuristic is used.
- `NH-MEDIA-BRIDGE-018`: **PASS (CI-backed)** — exact candidate CI excludes all probe assets from shipping `NotchHub.app` and preserves the shipping Sandbox/Hardened Runtime/security/performance boundary.

Strong but not yet final physical acceptance:

- `NH-MEDIA-BRIDGE-001`: effective target-Mac entitlement surface is exact sandbox-only and the candidate launches successfully; one explicit local Hardened Runtime success marker is still requested before recording final PASS for this physical gate.

Still pending because the supplied evidence does not directly prove the required behavior:

- `NH-MEDIA-BRIDGE-004` — Apple Music;
- `NH-MEDIA-BRIDGE-005` — Spotify;
- `NH-MEDIA-BRIDGE-006` — browser media;
- `NH-MEDIA-BRIDGE-007` — additional independent player;
- `NH-MEDIA-BRIDGE-010` — actual toggle play/pause behavior;
- `NH-MEDIA-BRIDGE-011` — actual previous/next behavior;
- `NH-MEDIA-BRIDGE-012` — actual seek behavior;
- `NH-MEDIA-BRIDGE-015` — target-Mac failure lifecycle if still required after deterministic failure-path review;
- `NH-MEDIA-BRIDGE-017` — explicit confirmation that no Accessibility/Input Monitoring/Automation/Screen Recording prompt appeared.

Command processes exited without reported CLI errors, but command exit status is intentionally not used as proof of media behavior.

## Historical first Yandex evidence — superseded candidate

The first target-Mac run used source `231ada7baf83a3a1e9d2e38e35fc80a3f6d53758`, CI #432 / run `31302447286`, artifact ID `9034919275`.

It observed Yandex Music with artwork/playing state, clean teardown/no orphan process, and active capabilities `next=supported`, `previous=supported`, `seek=supported`. This remains useful historical evidence that the underlying transport/capability extension worked before schema v2, but final physical PASS statuses above are tied to the current `cda05bb4...` candidate.

## Remaining acceptance work

1. Confirm actual Yandex behavior for toggle, next, previous, and seek rather than inferring it from successful command process exit.
2. Record one explicit local Hardened Runtime success marker and confirm that no sensitive permission prompt appeared.
3. Exercise Apple Music, Spotify, browser media, and one additional independent Now Playing source.
4. Collect target-Mac parent/owned-perl resource evidence, including the planned stability run.
5. Review the failure-lifecycle requirement against the already deterministic fail-closed tests and perform a target-Mac fault injection only if it adds evidence without weakening the security boundary.

## Transport decision

No final transport outcome is recorded yet. `ACCEPT_TRANSPORT`, `NEEDS_TRANSPORT_REDESIGN`, and `REJECT_TRANSPORT` remain pending until the remaining required physical matrix and resource evidence are reviewed.
