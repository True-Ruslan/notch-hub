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
- no title, artist, album, artwork bytes, raw payload, or listening history is written into durable probe evidence;
- probe and adapter assets remain absent from shipping `NotchHub.app`.

A failure is recorded rather than bypassed. Never rerun an acceptance candidate with Sandbox/Hardened Runtime disabled merely to obtain PASS.

## Exact CI candidate — preferred acceptance path

The current exact deterministic candidate was produced from PR #13 code head:

- source SHA: `231ada7baf83a3a1e9d2e38e35fc80a3f6d53758`;
- CI run: **#432**, Actions run ID `31302447286`;
- artifact: `MediaBridgeProbe-candidate`;
- artifact ID: `9034919275`;
- artifact digest: `sha256:e4d52833982212ff533f034789516811da1177c80f63b07baa572dfc7652b13b`;
- pinned adapter SHA: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- repo-owned adapter capability patch SHA-256: `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`.

CI #432 passed both jobs completely. The macOS 26 job compiled the linked `MediaBridgeProbe` executable product with warnings as errors, ran **91/91 Swift tests**, applied the repo-owned patch to the exact pinned upstream tree, built the patched adapter, packaged the sandboxed/Hardened Runtime probe, verified the bundle, executed the real one-shot `capabilities` path, validated its exact tri-state JSON schema, performed a signature-preserving ZIP round-trip, re-verified signature/entitlements/source/adapter/patch provenance after extraction, and uploaded the candidate. With no active Now Playing source on the hosted runner, the capability probe correctly returned:

```json
{"next":"unknown","previous":"unknown","seek":"unknown"}
```

The normal NotchHub shipping job simultaneously passed release/performance/media policy tests, security audit, coverage tests, shipping DMG verification, Sandbox/Hardened Runtime checks, artifact-size budget, performance harness smoke, and shipping-bundle probe isolation.

Prefer this exact CI artifact for physical acceptance rather than rebuilding locally.

Using GitHub CLI from a checkout of the repository:

```bash
rm -rf build/ci-media-probe-candidate
mkdir -p build/ci-media-probe-candidate

gh run download 31302447286 \
  -n MediaBridgeProbe-candidate \
  -D build/ci-media-probe-candidate

mkdir -p build/ci-media-probe-candidate/unpacked
ditto -x -k \
  build/ci-media-probe-candidate/MediaBridgeProbe.zip \
  build/ci-media-probe-candidate/unpacked

APP="build/ci-media-probe-candidate/unpacked/MediaBridgeProbe.app"
SOURCE_SHA="231ada7baf83a3a1e9d2e38e35fc80a3f6d53758"
PATCH_SHA256="f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974"

test "$(plutil -extract ProbeSourceCommit raw "$APP/Contents/Info.plist")" = "$SOURCE_SHA"
test "$(plutil -extract ProbeAdapterCommit raw "$APP/Contents/Info.plist")" = \
  "3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
test "$(plutil -extract ProbeAdapterPatchSHA256 raw "$APP/Contents/Info.plist")" = \
  "$PATCH_SHA256"
codesign --verify --deep --strict "$APP"
codesign -dv --verbose=4 "$APP" 2>&1 | grep -Eq 'flags=.*runtime'
```

For the commands below, set:

```bash
PROBE_APP="build/ci-media-probe-candidate/unpacked/MediaBridgeProbe.app"
PROBE="$PROBE_APP/Contents/MacOS/MediaBridgeProbe"
```

Do not substitute a newer branch head or locally rebuilt app during the same acceptance cycle. Documentation-only commits after this code SHA do not invalidate the recorded artifact. If probe code, packaging, security policy, pinned adapter revision, or capability patch changes, obtain a new exact-head CI candidate and restart the affected acceptance evidence.

## Local candidate build — fallback only

When CI artifact access is unavailable, a local candidate may be built from the exact code commit being tested:

```bash
git checkout 231ada7baf83a3a1e9d2e38e35fc80a3f6d53758
SOURCE_SHA="$(git rev-parse HEAD)"

bash scripts/bootstrap-media-bridge-probe.sh
SOURCE_COMMIT="$SOURCE_SHA" bash scripts/build-media-bridge-probe-app.sh
bash scripts/verify-media-bridge-probe.sh
```

The resulting fallback candidate is:

```text
build/MediaBridgeProbe.app
```

For the commands below set:

```bash
PROBE_APP="build/MediaBridgeProbe.app"
PROBE="$PROBE_APP/Contents/MacOS/MediaBridgeProbe"
```

The probe is not a normal NotchHub release artifact.

## Basic transport commands

Adapter self-test:

```bash
"$PROBE" self-test
```

Authoritative capability snapshot:

```bash
"$PROBE" capabilities
```

The output surface is deliberately fixed to:

```json
{"next":"supported|unsupported|unknown","previous":"supported|unsupported|unknown","seek":"supported|unsupported|unknown"}
```

Semantics:

- `supported` — an active system Now Playing source exists and MediaRemote advertises the enabled command;
- `unsupported` — an active system Now Playing source exists, an authoritative supported-command array was obtained, and that command is not enabled/present;
- `unknown` — there is no active Now Playing source, or the capability API/result could not be established safely within the bounded probe.

Do not reinterpret `unknown` as `unsupported` and do not infer capability from whether a later command happens to succeed.

Observe for a bounded interval and write privacy-safe JSON through shell redirection outside the sandboxed process:

```bash
"$PROBE" observe --seconds 60 \
  > build/media-bridge-observe.json
```

Typed command examples:

```bash
"$PROBE" send toggle
"$PROBE" send next
"$PROBE" send previous
"$PROBE" seek 42000000
```

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
| `NH-MEDIA-BRIDGE-016` | Capability surface | No-session/indeterminate state returns `unknown`; active sources expose authoritative `supported`/`unsupported` previous/next/seek states without guessing |
| `NH-MEDIA-BRIDGE-017` | Permission surface | No Accessibility/Input Monitoring/Automation permission prompt appears |
| `NH-MEDIA-BRIDGE-018` | Shipping isolation | `NotchHub.app` remains probe-free and retains its accepted runtime boundary |

`NOT_SUPPORTED` is legitimate for a source-specific action the source does not expose. `NH-MEDIA-BRIDGE-016` is different: if the target Mac cannot obtain authoritative capability information from active sources, record `NEEDS_REDESIGN` rather than manufacturing a capability heuristic.

### Capability-specific physical checks

Before opening a media source:

```bash
"$PROBE" capabilities
```

Expected: `unknown` for all three fields when macOS has no active system Now Playing source.

For each active test source, run the same command again while the source is the current macOS Now Playing source:

```bash
"$PROBE" capabilities
```

Record the returned states before sending next/previous/seek. The capability result itself is the evidence used by future UI policy; command success/failure is a separate behavioral check and must not overwrite the recorded capability state.

## Record results

The recorder accepts only known scenario IDs and the fixed status set `PASS|FAIL|NOT_SUPPORTED|NEEDS_REDESIGN`.

For the exact CI #432 candidate:

```bash
SOURCE_SHA="231ada7baf83a3a1e9d2e38e35fc80a3f6d53758"

python3 scripts/media-bridge-probe-acceptance.py \
  --source-commit "$SOURCE_SHA" \
  --macos "26.6" \
  --hardware-model "Mac16,8" \
  --result NH-MEDIA-BRIDGE-001=PASS \
  --result NH-MEDIA-BRIDGE-002=PASS \
  --result NH-MEDIA-BRIDGE-016=PASS \
  --output build/media-bridge-probe-acceptance.json
```

The example statuses above are illustrative only. Do not pre-mark `NH-MEDIA-BRIDGE-016` or any other physical scenario before executing it on the target Mac.

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
