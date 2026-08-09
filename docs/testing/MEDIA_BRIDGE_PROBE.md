# Universal Media Bridge Probe — Target-Mac Acceptance

Status: **ACCEPTED — `ACCEPT_TRANSPORT`**

Primary target: MacBook with hardware notch, macOS 26.6.

Physical evidence ledger: `docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md`.

This procedure validates only the development-only Universal Media transport probe. It does **not** make the probe itself production code and does not authorize weakening NotchHub runtime entitlements or shipping an unreviewed private compatibility boundary.

## Safety boundary

The accepted candidate preserves all of these conditions:

- App Sandbox enabled with exactly `com.apple.security.app-sandbox = true`;
- Hardened Runtime enabled;
- no Accessibility, Input Monitoring, Screen Recording, Automation/Apple Events, synthetic input, SIP weakening, injection, or Gatekeeper weakening;
- one fixed `/usr/bin/perl` adapter process owned by the probe;
- no shell execution from Swift;
- adapter source pinned to `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- authoritative-capability extension is the repo-owned patch whose SHA-256 is recorded below and embedded into the candidate `Info.plist`;
- observation uses `stream --no-diff --micros`, never repeated `get` polling;
- only typed toggle/next/previous/seek commands are allowed;
- capability probing is a one-shot bounded operation reporting only `next`, `previous`, and `seek` as `supported`, `unsupported`, or `unknown`;
- observation schema v2 adds only privacy-safe session-disappearance and source-switch aggregates;
- no title, artist, album, artwork bytes, raw payload, or listening history is written into durable probe evidence;
- probe and adapter assets remain absent from shipping `NotchHub.app`.

A failure is recorded rather than bypassed. Never rerun an acceptance candidate with Sandbox/Hardened Runtime disabled merely to obtain PASS.

## Exact accepted candidate

The accepted deterministic candidate was produced from PR #13 code head:

- source SHA: `cda05bb4ff367d2c4a5d9d438c3f555f3788d186`;
- CI run: **#443**, Actions run ID `31304052700`;
- artifact: `MediaBridgeProbe-candidate`;
- artifact ID: `9035397233`;
- artifact digest: `sha256:5cd10a0c6e9b61d8f060ca29ab8a84a7b1a1ba2408f2769b88ea86bf908be5c0`;
- pinned adapter SHA: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- repo-owned adapter capability patch SHA-256: `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`;
- observation schema: `2`.

CI #443 passed both jobs completely. The macOS 26 job ran **93/93 Swift tests**, applied the exact pinned adapter patch, built the Objective-C framework, packaged the sandboxed/Hardened Runtime probe, executed and validated the real `capabilities` path, executed a real one-second `observe` path, validated the schema-v2 privacy-safe observation surface, performed a signature-preserving ZIP round-trip, re-verified signature/entitlements/source/adapter/patch provenance after extraction, and uploaded the candidate. The normal NotchHub shipping job simultaneously passed release/performance/media policy tests, security audit, coverage tests, shipping DMG verification, Sandbox/Hardened Runtime checks, artifact-size budget, performance harness smoke, and shipping-bundle probe isolation.

Documentation-only commits after this code SHA do not invalidate the candidate. Any probe-code, packaging, security-policy, pinned-adapter, or capability-patch change requires a new exact candidate and affected physical evidence.

## Core transport commands

Adapter self-test:

```bash
"$PROBE" self-test
```

Authoritative capability snapshot:

```bash
"$PROBE" capabilities
```

Fixed surface:

```json
{"next":"supported|unsupported|unknown","previous":"supported|unsupported|unknown","seek":"supported|unsupported|unknown"}
```

Semantics:

- `supported` — an active system Now Playing source exists and MediaRemote advertises the enabled command;
- `unsupported` — an active source exists, an authoritative supported-command array was obtained, and the command is not enabled/present;
- `unknown` — there is no active source, or the authoritative capability API/result could not be established safely.

Capability is never inferred from command success.

Bounded event-driven observation:

```bash
"$PROBE" observe --seconds 60 > build/media-bridge-observe.json
```

Schema v2 retains only privacy-safe evidence:

- `observedSessionDisappearance=true` proves that a real session was observed and a later no-session event arrived while the stream stayed active;
- `sourceSwitchCount>0` proves that distinct system Now Playing source bundle identifiers were observed without restarting the probe.

Typed commands:

```bash
"$PROBE" send toggle
"$PROBE" send next
"$PROBE" send previous
"$PROBE" seek 42000000
```

Actual media behavior is required for command acceptance; process exit success alone is insufficient.

## Stable acceptance matrix

| ID | Scenario | Final status |
| --- | --- | --- |
| `NH-MEDIA-BRIDGE-001` | Sandboxed probe starts | **PASS** |
| `NH-MEDIA-BRIDGE-002` | Event-driven observation | **PASS** |
| `NH-MEDIA-BRIDGE-003` | Yandex Music | **PASS** |
| `NH-MEDIA-BRIDGE-004` | Apple Music | **NOT TESTED / DEFERRED** — source unavailable on Personal Release target |
| `NH-MEDIA-BRIDGE-005` | Spotify | **NOT TESTED / DEFERRED** — source unavailable on Personal Release target |
| `NH-MEDIA-BRIDGE-006` | Browser media | **PASS** — Yandex Browser |
| `NH-MEDIA-BRIDGE-007` | Additional player | **NOT TESTED / DEFERRED** — no independent player used on target |
| `NH-MEDIA-BRIDGE-008` | Active-source switch | **PASS** |
| `NH-MEDIA-BRIDGE-009` | Artwork | **PASS** |
| `NH-MEDIA-BRIDGE-010` | Toggle play/pause | **PASS** |
| `NH-MEDIA-BRIDGE-011` | Previous/next | **PASS** |
| `NH-MEDIA-BRIDGE-012` | Seek | **PASS** |
| `NH-MEDIA-BRIDGE-013` | Source disappearance | **PASS** |
| `NH-MEDIA-BRIDGE-014` | Clean teardown | **PASS** |
| `NH-MEDIA-BRIDGE-015` | Failure lifecycle | **PASS** — deterministic exact-candidate coverage |
| `NH-MEDIA-BRIDGE-016` | Capability surface | **PASS** |
| `NH-MEDIA-BRIDGE-017` | Permission surface | **PASS** |
| `NH-MEDIA-BRIDGE-018` | Shipping isolation | **PASS** — CI-backed |

Deferred source rows are not failures and do not imply verified compatibility. The accepted transport is scoped to the actual Personal Release environment and the architecture it proves.

## Accepted physical evidence summary

Target: `Mac16,8`, macOS `26.6` build `25G72`.

Accepted functional/security evidence includes:

- exact sandbox-only entitlement;
- local `adhoc,runtime` Hardened Runtime signature;
- no Accessibility/Input Monitoring/Automation/Screen Recording prompts;
- no-session capabilities `unknown/unknown/unknown`;
- active Yandex Music and Yandex Browser capabilities `supported/supported/supported`;
- Yandex Music and Yandex Browser system Now Playing observation with artwork/playing-state evidence;
- real Yandex toggle pause/resume, next, previous, and seek-to-42s behavior;
- source switching and source disappearance through one continuous event-driven stream;
- repeated clean teardown/no orphan evidence;
- deterministic nonzero-exit, protocol-failure, explicit-stop, timeout, and no-restart-loop lifecycle coverage.

## Accepted resource measurements

Resource evidence is diagnostic M6.1 evidence and does not replace the accepted P0 whole-app baseline or the later P1 whole-app performance review.

### 60-second steady state

Both parent probe and owned adapter were sampled for exactly 60 one-second samples after a 10-second warmup:

- parent probe: CPU median/max `0.0% / 0.0%`, RSS median/max `5,680 / 5,680 KiB`, threads median/max `2 / 2`;
- owned adapter: CPU median/max `0.0% / 0.0%`, RSS median/max `20,288 / 20,288 KiB`, threads median/max `2 / 2`;
- combined steady RSS `25,968 KiB` (~25.4 MiB), 4 threads.

### Corrected 10-minute stability

A fresh `observe --seconds 640` process was started immediately before both samplers. Each sampler produced 120 samples at 5-second intervals over ~600 seconds.

Parent probe:

- CPU median/max `0.0% / 0.0%`;
- RSS median/max `5,664 / 7,328 KiB`;
- RSS start/end `5,680 -> 5,552 KiB`, delta `-128 KiB`;
- threads start/end/max `2 / 2 / 2`.

Owned adapter:

- CPU median/max `0.0% / 0.1%`;
- RSS median/max `20,368 / 24,480 KiB`;
- RSS start/end `20,288 -> 20,256 KiB`, delta `-32 KiB`;
- threads start/end/max `2 / 2 / 6`.

Combined RSS drift was `-160 KiB`; ending combined thread count remained 4. The observer completed naturally with `cleanTeardown=true`, no orphan process, and explicit shell checks `PROBE_TEARDOWN=PASS` / `PERL_TEARDOWN=PASS`.

The earlier attempt that started a 700-second observer too early relative to the later 600-second sampler is classified **INVALID / RETRIED**, not FAIL; the corrected stability run supersedes it.

## Decision gate

M6.1 ended with exactly:

**`ACCEPT_TRANSPORT`**

The accepted Sandbox/Hardened Runtime boundary works, lifecycle is bounded and fail-closed, capability information is sufficient, real available system Now Playing publishers function correctly, and target-Mac resource behavior shows no sustained CPU/RSS/thread accumulation.

This permits the next separately reviewed production `SystemMediaBridge` implementation plan. It does not make the development probe production code by implication, does not authorize permission/security broadening, and does not eliminate the later P1 whole-app performance review.
