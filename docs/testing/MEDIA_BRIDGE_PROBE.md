# Universal Media Bridge Probe — Target-Mac Acceptance

Status: **EXACT CI CANDIDATE READY — PHYSICAL ACCEPTANCE IN PROGRESS**

Primary target: MacBook with hardware notch, macOS 26.6.

Physical evidence ledger: `docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md`.

This procedure validates only the development-only Universal Media transport probe. It does **not** accept a production `SystemMediaBridge`, does not change NotchHub runtime entitlements, and does not authorize shipping MediaRemote/private compatibility code.

## Safety boundary

The accepted candidate must preserve all of these conditions:

- App Sandbox enabled with exactly `com.apple.security.app-sandbox = true`;
- Hardened Runtime enabled;
- no Accessibility, Input Monitoring, Screen Recording, Automation/Apple Events, synthetic input, SIP weakening, injection, or Gatekeeper weakening;
- one fixed `/usr/bin/perl` adapter process owned by the probe;
- no shell execution from Swift;
- adapter source pinned to `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- the authoritative-capability extension is the repo-owned patch whose SHA-256 is recorded below and embedded into the candidate `Info.plist`;
- observation uses `stream --no-diff --micros`, never repeated `get` polling;
- only typed toggle/next/previous/seek commands are allowed;
- capability probing is a one-shot bounded operation that reports only `next`, `previous`, and `seek` as `supported`, `unsupported`, or `unknown`;
- observation schema v2 adds only privacy-safe session-disappearance and source-switch aggregates;
- no title, artist, album, artwork bytes, raw payload, or listening history is written into durable probe evidence;
- probe and adapter assets remain absent from shipping `NotchHub.app`.

A failure is recorded rather than bypassed. Never rerun an acceptance candidate with Sandbox/Hardened Runtime disabled merely to obtain PASS.

## Exact CI candidate — preferred acceptance path

The current exact deterministic candidate was produced from PR #13 code head:

- source SHA: `cda05bb4ff367d2c4a5d9d438c3f555f3788d186`;
- CI run: **#443**, Actions run ID `31304052700`;
- artifact: `MediaBridgeProbe-candidate`;
- artifact ID: `9035397233`;
- artifact digest: `sha256:5cd10a0c6e9b61d8f060ca29ab8a84a7b1a1ba2408f2769b88ea86bf908be5c0`;
- pinned adapter SHA: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- repo-owned adapter capability patch SHA-256: `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`;
- observation schema: `2`.

CI #443 passed both jobs completely. The macOS 26 job ran **93/93 Swift tests**, applied the repo-owned capability patch to the exact pinned adapter, built the Objective-C framework, packaged the sandboxed/Hardened Runtime probe, executed and validated the real `capabilities` path, executed a real one-second `observe` path, validated the schema-v2 privacy-safe observation surface, performed a signature-preserving ZIP round-trip, re-verified signature/entitlements/source/adapter/patch provenance after extraction, and uploaded the candidate. The normal NotchHub shipping job simultaneously passed release/performance/media policy tests, security audit, coverage tests, shipping DMG verification, Sandbox/Hardened Runtime checks, artifact-size budget, performance harness smoke, and shipping-bundle probe isolation.

With no active Now Playing source on the hosted runner, CI returned:

```json
{"next":"unknown","previous":"unknown","seek":"unknown"}
```

and a schema-v2 observation with `observedSession=false`, `observedSessionDisappearance=false`, and `sourceSwitchCount=0`.

Prefer this exact CI artifact for physical acceptance rather than rebuilding locally.

```bash
rm -rf build/ci-media-probe-candidate
mkdir -p build/ci-media-probe-candidate

gh run download 31304052700 \
  -n MediaBridgeProbe-candidate \
  -D build/ci-media-probe-candidate

mkdir -p build/ci-media-probe-candidate/unpacked
ditto -x -k \
  build/ci-media-probe-candidate/MediaBridgeProbe.zip \
  build/ci-media-probe-candidate/unpacked

APP="build/ci-media-probe-candidate/unpacked/MediaBridgeProbe.app"
PROBE="$APP/Contents/MacOS/MediaBridgeProbe"
SOURCE_SHA="cda05bb4ff367d2c4a5d9d438c3f555f3788d186"
PATCH_SHA256="f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974"

test "$(plutil -extract ProbeSourceCommit raw "$APP/Contents/Info.plist")" = "$SOURCE_SHA"
test "$(plutil -extract ProbeAdapterCommit raw "$APP/Contents/Info.plist")" = \
  "3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
test "$(plutil -extract ProbeAdapterPatchSHA256 raw "$APP/Contents/Info.plist")" = \
  "$PATCH_SHA256"
codesign --verify --deep --strict "$APP"
codesign -dv --verbose=4 "$APP" 2>&1 | grep -Eq 'flags=.*runtime'
codesign --display --entitlements - --xml "$APP" > build/media-probe-entitlements.plist
python3 - <<'PY'
import plistlib
from pathlib import Path

with Path('build/media-probe-entitlements.plist').open('rb') as handle:
    entitlements = plistlib.load(handle)
expected = {'com.apple.security.app-sandbox': True}
if entitlements != expected:
    raise SystemExit(f'Unexpected probe entitlements: {entitlements!r}')
PY
```

Do not substitute a newer branch head or locally rebuilt app during the same acceptance cycle. Documentation-only commits after this code SHA do not invalidate the candidate. If probe code, packaging, security policy, pinned adapter revision, or capability patch changes, obtain a new exact-head CI candidate and restart affected physical evidence.

## Core transport commands

Adapter self-test:

```bash
"$PROBE" self-test
```

Authoritative capability snapshot:

```bash
"$PROBE" capabilities
```

The fixed surface is:

```json
{"next":"supported|unsupported|unknown","previous":"supported|unsupported|unknown","seek":"supported|unsupported|unknown"}
```

Semantics:

- `supported` — an active system Now Playing source exists and MediaRemote advertises the enabled command;
- `unsupported` — an active source exists, an authoritative supported-command array was obtained, and the command is not enabled/present;
- `unknown` — there is no active source, or the authoritative capability API/result could not be established safely.

Do not infer capability from command success.

Bounded event-driven observation:

```bash
"$PROBE" observe --seconds 60 > build/media-bridge-observe.json
```

Schema v2 retains only privacy-safe evidence. Two transition fields are especially useful:

- `observedSessionDisappearance=true` proves that a real session was observed and a later no-session event arrived while the stream stayed active;
- `sourceSwitchCount>0` proves that distinct system Now Playing source bundle identifiers were observed without restarting the probe.

Typed commands:

```bash
"$PROBE" send toggle
"$PROBE" send next
"$PROBE" send previous
"$PROBE" seek 42000000
```

Actual media behavior must be observed for the command gates; process exit success alone is insufficient.

## Stable acceptance matrix

| ID | Scenario | PASS criterion |
| --- | --- | --- |
| `NH-MEDIA-BRIDGE-001` | Sandboxed probe starts | Probe launches with Hardened Runtime and exact sandbox-only entitlement |
| `NH-MEDIA-BRIDGE-002` | Event-driven observation | Current system Now Playing arrives through `stream --no-diff --micros`; no periodic `get` polling |
| `NH-MEDIA-BRIDGE-003` | Yandex Music | System Now Playing source is observed when Yandex Music is active |
| `NH-MEDIA-BRIDGE-004` | Apple Music | System Now Playing source is observed when Apple Music is active |
| `NH-MEDIA-BRIDGE-005` | Spotify | System Now Playing source is observed when Spotify is active |
| `NH-MEDIA-BRIDGE-006` | Browser media | Safari or Chromium YouTube system session is observed |
| `NH-MEDIA-BRIDGE-007` | Additional player | One additional independent player that publishes Now Playing is observed |
| `NH-MEDIA-BRIDGE-008` | Active-source switch | `sourceSwitchCount > 0` while one observation process remains active |
| `NH-MEDIA-BRIDGE-009` | Artwork | Artwork presence is observed for sources that actually publish artwork |
| `NH-MEDIA-BRIDGE-010` | Toggle play/pause | Typed toggle changes playback state when the source accepts it |
| `NH-MEDIA-BRIDGE-011` | Previous/next | Typed previous/next actually change tracks when the source accepts them |
| `NH-MEDIA-BRIDGE-012` | Seek | Typed seek changes timeline position for a source that supports seek |
| `NH-MEDIA-BRIDGE-013` | Source disappearance | `observedSessionDisappearance=true` after the active source is stopped/closed |
| `NH-MEDIA-BRIDGE-014` | Clean teardown | Probe termination removes owned perl/helper processes; no orphan remains |
| `NH-MEDIA-BRIDGE-015` | Failure lifecycle | Adapter crash/nonzero exit fails closed and does not restart-loop |
| `NH-MEDIA-BRIDGE-016` | Capability surface | No-session returns `unknown`; active sources expose authoritative previous/next/seek states without guessing |
| `NH-MEDIA-BRIDGE-017` | Permission surface | No Accessibility/Input Monitoring/Automation permission prompt appears |
| `NH-MEDIA-BRIDGE-018` | Shipping isolation | `NotchHub.app` remains probe-free and retains its accepted runtime boundary |

`NOT_SUPPORTED` is legitimate for a source-specific action the source does not expose. If authoritative capability information cannot be established, record `NEEDS_REDESIGN` rather than manufacturing a heuristic.

## High-signal physical sequence

### 1. No active source

Close or stop every app/browser tab that owns macOS Now Playing, then run:

```bash
"$PROBE" capabilities
```

Expected when there is truly no active system session:

```json
{"next":"unknown","previous":"unknown","seek":"unknown"}
```

### 2. Yandex Music command check

Start an ordinary seekable track in Yandex Music:

```bash
"$PROBE" capabilities
"$PROBE" send toggle
"$PROBE" send toggle
"$PROBE" send next
"$PROBE" send previous
"$PROBE" seek 42000000
"$PROBE" observe --seconds 30 > build/media-bridge-observe-yandex-v2.json
```

Record whether toggle paused/resumed, next/previous changed tracks, and seek moved playback near 42 seconds. Inspect only the privacy-safe JSON report, not raw adapter payload.

### 3. Session disappearance

Start Yandex Music, then begin:

```bash
"$PROBE" observe --seconds 60 > build/media-bridge-disappearance.json
```

During that minute, quit/stop Yandex Music and leave all other media sources inactive. PASS evidence is `observedSession=true` and `observedSessionDisappearance=true`.

### 4. Source switch

Start Yandex Music, then begin:

```bash
"$PROBE" observe --seconds 90 > build/media-bridge-source-switch.json
```

While it remains running, move the active macOS Now Playing source from Yandex Music to Apple Music. PASS evidence is `sourceSwitchCount > 0`; the final `sourceBundleIdentifier` should correspond to the final active source.

### 5. Remaining sources

For Apple Music, Spotify, Safari/Chromium YouTube, and one additional independent Now Playing player, capture a capability snapshot and a bounded observation report. Record `NOT_SUPPORTED` only for a source-specific command that the authoritative capability surface says is unsupported.

### 6. Permission surface

Record whether macOS displayed any Accessibility, Input Monitoring, Automation/Apple Events, or Screen Recording permission prompt. Any such prompt is a failure of the intended boundary.

## Resource measurements

Transport resource evidence is diagnostic M6.1 evidence. It does not replace the accepted P0 baseline or the later P1 whole-app performance review.

With a stable active media source and a long-running observation process, identify the parent probe and owned perl PID, then use the existing privacy-safe sampler for 60-second and 10-minute runs. Review CPU median/max, RSS median/max, thread max, RSS start/end, and thread start/end for runaway work or growth. After stopping the probe, both processes must be gone.

## Decision gate

After the physical matrix and resource evidence are reviewed, M6.1 ends in exactly one outcome:

- `ACCEPT_TRANSPORT` — current Sandbox/Hardened Runtime boundary works, lifecycle is bounded, capability information is sufficient, and resource behavior is acceptable;
- `NEEDS_TRANSPORT_REDESIGN` — the mechanism is promising but capability/lifecycle/security/resource contract is insufficient for production as designed;
- `REJECT_TRANSPORT` — the mechanism requires disproportionate security weakening or otherwise fails the product boundary.

Only `ACCEPT_TRANSPORT` permits a later production `SystemMediaBridge` implementation plan. The probe itself never becomes production code by implication.
