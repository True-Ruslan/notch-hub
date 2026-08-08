# Universal Media Bridge Probe — Target-Mac Acceptance

Status: **IMPLEMENTATION CANDIDATE — PHYSICAL ACCEPTANCE PENDING**

Primary target: MacBook with hardware notch, macOS 26.6.

This procedure validates only the development-only Universal Media transport probe. It does **not** accept a production `SystemMediaBridge`, does not change NotchHub runtime entitlements, and does not authorize shipping MediaRemote/private compatibility code.

## Safety boundary

The accepted candidate must preserve all of these conditions:

- App Sandbox enabled with exactly `com.apple.security.app-sandbox = true`;
- Hardened Runtime enabled;
- no Accessibility, Input Monitoring, Screen Recording, Automation/Apple Events, synthetic input, SIP weakening, injection, or Gatekeeper weakening;
- one fixed `/usr/bin/perl` adapter process owned by the probe;
- no shell execution from Swift;
- adapter source pinned to `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- observation uses `stream --no-diff --micros`, never repeated `get` polling;
- only typed toggle/next/previous/seek commands are allowed;
- no title, artist, album, artwork bytes, raw payload, or listening history is written into durable probe evidence;
- probe and adapter assets remain absent from shipping `NotchHub.app`.

A failure is recorded rather than bypassed. Never rerun an acceptance candidate with Sandbox/Hardened Runtime disabled merely to obtain PASS.

## Build candidate

From the exact PR/commit to be tested:

```bash
SOURCE_SHA="$(git rev-parse HEAD)"

bash scripts/bootstrap-media-bridge-probe.sh
SOURCE_COMMIT="$SOURCE_SHA" bash scripts/build-media-bridge-probe-app.sh
bash scripts/verify-media-bridge-probe.sh
```

The resulting candidate is:

```text
build/MediaBridgeProbe.app
```

The probe is not a normal NotchHub release artifact.

## Basic transport commands

Adapter self-test:

```bash
build/MediaBridgeProbe.app/Contents/MacOS/MediaBridgeProbe self-test
```

Observe for a bounded interval and write privacy-safe JSON through shell redirection outside the sandboxed process:

```bash
build/MediaBridgeProbe.app/Contents/MacOS/MediaBridgeProbe \
  observe --seconds 60 \
  > build/media-bridge-observe.json
```

Typed command examples:

```bash
build/MediaBridgeProbe.app/Contents/MacOS/MediaBridgeProbe send toggle
build/MediaBridgeProbe.app/Contents/MacOS/MediaBridgeProbe send next
build/MediaBridgeProbe.app/Contents/MacOS/MediaBridgeProbe send previous
build/MediaBridgeProbe.app/Contents/MacOS/MediaBridgeProbe seek 42000000
```

Do not infer capability merely because a command exits successfully. `NH-MEDIA-BRIDGE-016` separately requires an authoritative capability signal suitable for a future capability-driven UI.

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
| `NH-MEDIA-BRIDGE-008` | Active-source switch | macOS source changes are reflected by stream events without restart/polling |
| `NH-MEDIA-BRIDGE-009` | Artwork | Artwork presence is observed for sources that actually publish artwork |
| `NH-MEDIA-BRIDGE-010` | Toggle play/pause | Typed toggle works when the source accepts it |
| `NH-MEDIA-BRIDGE-011` | Previous/next | Typed previous/next work when the source accepts them |
| `NH-MEDIA-BRIDGE-012` | Seek | Typed seek works for a source that supports seek |
| `NH-MEDIA-BRIDGE-013` | Source disappearance | Closing/stopping the active source yields no-session state without probe failure |
| `NH-MEDIA-BRIDGE-014` | Clean teardown | Probe termination removes owned perl/helper processes; no orphan remains |
| `NH-MEDIA-BRIDGE-015` | Failure lifecycle | Adapter crash/nonzero exit fails closed and does not restart-loop |
| `NH-MEDIA-BRIDGE-016` | Capability surface | Transport can distinguish supported/unsupported/unknown previous/next/seek without guessing |
| `NH-MEDIA-BRIDGE-017` | Permission surface | No Accessibility/Input Monitoring/Automation permission prompt appears |
| `NH-MEDIA-BRIDGE-018` | Shipping isolation | `NotchHub.app` remains probe-free and retains its accepted runtime boundary |

`NOT_SUPPORTED` is legitimate for a source-specific action the source does not expose. `NH-MEDIA-BRIDGE-016` is different: if the transport cannot provide authoritative capability information at all, record `NEEDS_REDESIGN` rather than manufacturing a capability heuristic.

## Record results

The recorder accepts only known scenario IDs and the fixed status set `PASS|FAIL|NOT_SUPPORTED|NEEDS_REDESIGN`.

Example:

```bash
python3 scripts/media-bridge-probe-acceptance.py \
  --source-commit "$SOURCE_SHA" \
  --macos "26.6" \
  --hardware-model "Mac16,8" \
  --result NH-MEDIA-BRIDGE-001=PASS \
  --result NH-MEDIA-BRIDGE-002=PASS \
  --result NH-MEDIA-BRIDGE-016=NEEDS_REDESIGN \
  --output build/media-bridge-probe-acceptance.json
```

The output has no free-form notes or media-content fields.

## Resource measurements

Transport resource evidence is diagnostic M6.1 evidence. It does not change the accepted P0 baseline and does not substitute for the later P1 whole-app performance review.

With a stable active media source, identify both the probe PID and its owned perl PID, then measure them separately using the existing privacy-safe process sampler:

```bash
PROBE_PID="$(pgrep -x MediaBridgeProbe | head -n 1)"
PERL_PID="$(pgrep -P "$PROBE_PID" perl | head -n 1)"

python3 scripts/perf-baseline.py \
  --attach-pid "$PROBE_PID" \
  --source-commit "$SOURCE_SHA" \
  --scenario idle \
  --warmup-seconds 10 \
  --duration-seconds 60 \
  --interval-seconds 1 \
  --output build/perf-media-probe-parent.json

python3 scripts/perf-baseline.py \
  --attach-pid "$PERL_PID" \
  --source-commit "$SOURCE_SHA" \
  --scenario idle \
  --warmup-seconds 10 \
  --duration-seconds 60 \
  --interval-seconds 1 \
  --output build/perf-media-probe-perl.json
```

Also run a 10-minute stability measurement for both processes while the stream remains active and interaction is otherwise idle. Review CPU median/max, RSS median/max, thread max, RSS start/end, and thread start/end for runaway work or growth.

After stopping the probe, both processes must be gone:

```bash
! kill -0 "$PROBE_PID" 2>/dev/null
! kill -0 "$PERL_PID" 2>/dev/null
```

## Decision gate

After the full matrix and resource evidence are reviewed, M6.1 ends in exactly one outcome:

- `ACCEPT_TRANSPORT` — current Sandbox/Hardened Runtime boundary works, lifecycle is bounded, capability information is sufficient, and resource behavior is acceptable;
- `NEEDS_TRANSPORT_REDESIGN` — the mechanism is promising but capability/lifecycle/security/resource contract is insufficient for production as designed;
- `REJECT_TRANSPORT` — the mechanism requires disproportionate security weakening or otherwise fails the product boundary.

Only `ACCEPT_TRANSPORT` permits writing a later production `SystemMediaBridge` implementation plan. This probe itself never becomes production code by implication.
