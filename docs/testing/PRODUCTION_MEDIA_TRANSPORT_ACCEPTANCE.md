# Production System Media Transport — Acceptance Evidence

Status: **CI-QUALIFIED — TARGET-MAC ACCEPTANCE PENDING**

Authoritative implementation plan: `docs/superpowers/plans/2026-08-09-production-system-media-transport.md`.
Historical transport decision: `docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md` (`ACCEPT_TRANSPORT`).

## Exact production-transport candidate

The code candidate is frozen at:

- source SHA: `3932426bcf063162ee7de1378ed301c9ce664746`;
- CI run: `#558` / `31317528628`;
- artifact: `ProductionMediaTransportCandidate-candidate`;
- artifact ID: `9039199985`;
- artifact size: `198164` bytes;
- artifact digest: `sha256:4e2f40fe124cc9919bbe1b17fc5759308513309c49e7fcc75bf0a9c6dac1b46d`;
- adapter SHA: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`;
- capability patch SHA-256: `f251ca3eb8bcd417eed526fc3e5efad29c2aa375d7aad7a2cb3a206857d51974`;
- production candidate evidence schema: `1`;
- exact-candidate Swift suite: **162/162 PASS in 31 suites**.

Documentation-only commits after `3932426b...` do not change this physical candidate. Any later change to `Sources/NotchHubMediaCore/**`, `Tools/ProductionMediaTransportCandidate/**`, candidate packaging/signing, the pinned adapter, the capability patch, security/runtime policy, or candidate entitlements requires a new exact candidate and a new artifact digest.

## CI-qualified evidence

CI #558 is fully green on the exact code candidate. Both jobs completed successfully.

### macOS 26 candidate execution

Hosted environment:

- macOS `26.5.2` / build `25F84`;
- Xcode `26.6`;
- Swift `6.3.3`;
- hosted hardware reports as `VirtualMac2,1` through the historical probe.

The production candidate was built from the real `NotchHubMediaCore` production transport, not from the older probe implementation.

Candidate verification proved:

- exact candidate source provenance;
- pinned adapter provenance and repo-owned capability patch provenance;
- App Sandbox entitlement is exactly `com.apple.security.app-sandbox = true`;
- Hardened Runtime is present;
- ad-hoc code signature verifies recursively and strictly;
- production runtime does not package `MediaRemoteAdapterTestClient`;
- candidate executable links only system libraries;
- archive round-trip preserves signature/runtime/entitlement/provenance requirements;
- rebuilding `NotchHub.app` after candidate verification proves candidate executable, adapter script, adapter framework and adapter test client remain absent from the shipping app.

Hosted no-active-session capability result:

```json
{"next":"unknown","previous":"unknown","seek":"unknown"}
```

Hosted one-second production observation:

```json
{"adapterCommit":"3ac3d4bdf862c7b5399b4fba4df5689f5c38609a","capabilities":{"next":"unknown","previous":"unknown","seek":"unknown"},"cleanTeardown":true,"eventCount":1,"observedArtwork":false,"observedArtworkClearOnSourceSwitch":false,"observedPlayingState":false,"observedSession":false,"observedSessionDisappearance":false,"schemaVersion":1,"sourceBundleIdentifier":null,"sourceCommit":"3932426bcf063162ee7de1378ed301c9ce664746","sourceSwitchCount":0}
```

This proves that the real production candidate starts under the required sandbox/runtime boundary, reaches the MediaRemote compatibility process, fails closed to `unknown` when no system Now Playing session exists, emits the exact privacy-safe report schema, and tears down cleanly in hosted CI.

### Deterministic transport evidence

The 162-test exact-candidate suite includes deterministic coverage for:

- strict bounded `--no-diff --micros` wire decoding;
- oversized/malformed JSON, text, artwork, timing and capability rejection;
- full-snapshot semantics with no stale-field merge;
- fixed `/usr/bin/perl` executable and exact closed argument construction;
- no shell/arbitrary executable/arbitrary command-ID surface;
- bounded stdout/stderr and one-shot timeout teardown;
- idempotent observation start/stop and owned-process teardown;
- source/session generation and revision monotonicity;
- no-session invalidation;
- stale artwork clearing on source change;
- rapid source switch with stale capability completion rejection;
- authoritative capability refresh only on media fingerprint change;
- capability-query failure remaining `unknown` without destroying valid metadata;
- typed toggle/previous/next/seek forwarding with no per-player fallback;
- first unexpected controller failure restarting exactly once;
- second unexpected failure becoming unavailable without a restart loop;
- stale callbacks rejected after stop/restart;
- candidate report privacy and stable exact schema;
- candidate bundle path resolution through `Bundle.main` rather than launch-path assumptions;
- operational-only failure classification without raw stderr or metadata exposure.

### Repository policy evidence

The exact candidate also passes:

- release policy tests;
- performance policy tests and source audit;
- production-candidate packaging policy tests;
- strict Swift formatting;
- plist and shell syntax validation;
- `security-audit.sh` with the single exact-file `Process()` allowlist;
- warnings-as-errors builds;
- coverage-instrumented Swift tests;
- shipping DMG build and verification;
- shipping App Sandbox + Hardened Runtime verification;
- shipping artifact size budget;
- shipping performance-harness compatibility smoke.

No production media asset has entered `NotchHub.app`; shipping composition remains intentionally deferred.

## Target-Mac acceptance environment

The physical gate must use the exact artifact above on the personal target:

- hardware: `Mac16,8`;
- macOS: `26.6` / build `25G72`;
- candidate source recorded by the artifact: `3932426bcf063162ee7de1378ed301c9ce664746`.

The production candidate is development-only. Passing this gate authorizes a later, separate shipping-composition change; it does not itself add `NotchHubMediaCore` or adapter assets to `NotchHub.app`.

## Physical acceptance ledger

### `NH-MEDIA-PROD-001` — target Sandbox + Hardened Runtime

Status: **PENDING**

Required target evidence:

- `codesign --verify --deep --strict` succeeds;
- effective entitlements are exactly `{ "com.apple.security.app-sandbox": true }`;
- code-signing flags contain `runtime`;
- candidate launches successfully on macOS 26.6.

### `NH-MEDIA-PROD-002` — no-session fail-closed state

Status: **PENDING TARGET / PASS HOSTED**

With no active Now Playing source, `capabilities` must return exact previous/next/seek tri-state values and must not fabricate support. Expected normal no-session result is `unknown/unknown/unknown`.

### `NH-MEDIA-PROD-003` — Yandex Music production observation

Status: **PENDING**

Required target evidence:

- system session observed through the production transport;
- source bundle is `ru.yandex.desktop.music`;
- playback state observed;
- artwork observed when the active track publishes artwork;
- report retains no title/artist/album/artwork bytes/raw payload.

### `NH-MEDIA-PROD-004` — browser production observation

Status: **PENDING**

Required target evidence: Yandex Browser / browser YouTube is observed as the system Now Playing source through the same production transport, without a browser-specific fallback controller.

### `NH-MEDIA-PROD-005` — source switching and disappearance

Status: **PENDING**

Required target evidence from a continuous production observation:

- no-session -> active transition is accepted;
- at least one real source switch is reflected by `sourceSwitchCount > 0` when two distinct source bundle identifiers become authoritative;
- disappearance after a real session sets `observedSessionDisappearance = true`;
- no synthetic or app-specific source-selection policy is used.

### `NH-MEDIA-PROD-006` — authoritative capabilities

Status: **PENDING**

Required target evidence:

- no-session fails closed;
- active Yandex Music and/or browser sessions expose exact `supported | unsupported | unknown` states;
- command support is not inferred from later command success.

### `NH-MEDIA-PROD-007` — actual command behavior

Status: **PENDING**

Required physical behavior confirmation on an active source:

- toggle actually pauses;
- second toggle actually resumes;
- next actually changes to the next item when supported;
- previous actually changes to the previous item when supported;
- seek to a known position actually changes playback position when supported.

A candidate JSON result or zero process exit alone is insufficient evidence for this gate.

### `NH-MEDIA-PROD-008` — stale artwork regression

Status: **PENDING PHYSICAL / PASS DETERMINISTIC**

Deterministic exact-candidate tests already prove that a new full payload/source without artwork cannot inherit prior artwork and that rapid source switching rejects stale asynchronous capability completions.

Physical evidence should additionally set `observedArtworkClearOnSourceSwitch = true` if the available real source sequence naturally provides an artwork-bearing source followed by a distinct source without artwork. This condition must not be manufactured by weakening the transport or installing otherwise-unused software solely for the test.

### `NH-MEDIA-PROD-009` — clean stop / no orphan

Status: **PENDING TARGET / PASS HOSTED**

Required target evidence: after natural observation completion or explicit stop, the candidate exits and no owned `/usr/bin/perl ... mediaremote-adapter.pl` process remains.

### `NH-MEDIA-PROD-010` — bounded failure lifecycle

Status: **PASS DETERMINISTIC**

The exact-candidate test suite proves:

- first unexpected failure causes exactly one controller-owned restart;
- stale callbacks from the failed generation are rejected;
- second unexpected failure locks the subsystem unavailable;
- no automatic restart loop occurs;
- process/protocol/timeout failures tear down the owned process fail-closed.

A target-Mac fault injection is not required unless a later real failure contradicts these deterministic semantics.

### `NH-MEDIA-PROD-011` — no sensitive permission prompts

Status: **PENDING**

During the complete target cycle, no Accessibility, Input Monitoring, Automation, or Screen Recording permission prompt may appear.

### `NH-MEDIA-PROD-012` — 60-second resource evidence

Status: **PENDING**

With a real active source, measure the candidate parent and its owned adapter process for 60 one-second samples after warmup. Record CPU median/max, RSS median/max and thread median/max separately and combined. No sustained work or resource accumulation is acceptable.

### `NH-MEDIA-PROD-013` — 10-minute stability evidence

Status: **PENDING**

With a real active source, run a sufficiently long production observation and collect approximately 10 minutes of parent+owned-adapter evidence. Record CPU, RSS start/first-quartile/end/max, RSS drift, threads start/end/max and lifecycle teardown. Sustained CPU, RSS or thread growth fails this gate.

## Exact-candidate retrieval

From a local clone with GitHub CLI authenticated:

```bash
gh run download 31317528628 \
  --repo True-Ruslan/notch-hub \
  --name ProductionMediaTransportCandidate-candidate \
  --dir build/m6-3-candidate

mkdir -p build/m6-3-candidate/extracted
ditto -x -k \
  build/m6-3-candidate/ProductionMediaTransportCandidate.zip \
  build/m6-3-candidate/extracted

APP="$PWD/build/m6-3-candidate/extracted/ProductionMediaTransportCandidate.app"
CANDIDATE="$APP/Contents/MacOS/MediaTransportCandidate"
```

Before using the candidate, verify the downloaded Actions artifact digest shown by GitHub for run #558 / artifact ID `9039199985` is:

```text
sha256:4e2f40fe124cc9919bbe1b17fc5759308513309c49e7fcc75bf0a9c6dac1b46d
```

The GitHub Actions artifact digest refers to the uploaded Actions artifact envelope, not necessarily to the nested `ProductionMediaTransportCandidate.zip` file produced inside it; do not compare that digest to the nested zip unless a separate nested-file digest is recorded.

## Current decision

**DO NOT COMPOSE INTO SHIPPING APP YET.**

M6.3 implementation is deterministic and CI-qualified, but the plan's target-Mac gate remains intentionally open. PR #16 must remain Draft until the physical acceptance ledger is complete and the resulting decision is recorded.

If the target gate passes, the next separate implementation slice may add `NotchHubMediaCore` to `NotchHubApp` and package the pinned adapter assets into `NotchHub.app` under the same reviewed sandbox/security/performance boundary. Media UI remains a later slice.

No title, artist, album, artwork bytes, raw MediaRemote payload, or listening history is retained in this ledger.
