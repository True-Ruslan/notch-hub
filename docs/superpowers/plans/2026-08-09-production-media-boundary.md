# Production Universal Media Boundary Implementation Plan

Status: **IMPLEMENTED — FINAL PR VERIFICATION PENDING**

**Goal:** Build the production, player-agnostic media state/controller boundary authorized by the accepted M6.1 `ACCEPT_TRANSPORT` decision, without adding media UI or the concrete private MediaRemote transport yet.

**Final architecture:** production media domain/provider/controller/bridge code lives in independent Swift target `NotchHubMediaCore`. The target is fully built and tested by CI but is deliberately not a dependency of `NotchHubApp` until the concrete system transport/composition slice. This preserves honest shipping-size accounting while keeping the production architecture ready for the next reviewed step.

**Tech Stack:** Swift 6, Swift Package Manager, Swift Testing, Foundation.

## Global constraints — preserved

- [x] Minimum deployment target remains macOS 14; primary physical target remains macOS 26.6.
- [x] App Sandbox + Hardened Runtime remain mandatory and unchanged.
- [x] No Accessibility, Input Monitoring, Automation, Screen Recording, synthetic input, network access, telemetry, listening-history persistence, or production metadata logging.
- [x] Event-driven only: no polling loops, repeating timers, display links, or sleep-driven refresh.
- [x] No app-specific player adapters or source-priority rules.
- [x] Unsupported/unknown commands fail closed and are never fabricated.
- [x] Media failure is isolated from Notch Core presentation state.
- [x] At most one controlled restart after unexpected provider failure; a second failure remains unavailable for the controller lifecycle.
- [x] The accepted M6.1 probe remains development-only and is not copied into production media code.
- [x] No media UI, gestures, haptics, progress animation, or concrete MediaRemote process/dynamic-loading transport in M6.2.

## Task 1 — immutable media domain and ordering

Status: **COMPLETE**.

Final files:

- `Sources/NotchHubMediaCore/MediaSessionTypes.swift`
- `Tests/NotchHubMediaCoreTests/MediaSessionTypesTests.swift`

Completed:

- [x] RED test-first contract for `MediaSequence` and normalized snapshot semantics.
- [x] RED confirmed by CI on missing domain types.
- [x] `MediaSequence` orders lexicographically by generation then revision.
- [x] Capability, playback, source, command, subsystem, and immutable snapshot types implemented.
- [x] Snapshot fabricates no absent metadata/timing/capability values.
- [x] Full snapshot equality intentionally removed after size investigation; freshness/deduplication authority is `MediaSequence`.

## Task 2 — player-agnostic provider contract

Status: **COMPLETE**.

Final files:

- `Sources/NotchHubMediaCore/MediaProvider.swift`
- `Tests/NotchHubMediaCoreTests/MediaProviderContractTests.swift`

Completed:

- [x] RED compile/behavior contract added before provider definitions.
- [x] RED confirmed on missing `MediaProvider`, `MediaProviderEvent`, and command result types.
- [x] One typed event handler, explicit `start()` / `stop()`, and typed async command dispatch implemented.
- [x] No polling, arbitrary command IDs/strings, player-specific policy, or UI dependency.

## Task 3 — deterministic `MediaSessionController`

Status: **COMPLETE**.

Final files:

- `Sources/NotchHubMediaCore/MediaSessionController.swift`
- `Tests/NotchHubMediaCoreTests/MediaSessionControllerTests.swift`

Completed:

- [x] RED tests written before controller implementation.
- [x] RED confirmed specifically on missing `MediaSessionController`.
- [x] Idempotent start and explicit terminal stop.
- [x] Ready/idle, paused/playing, and newer no-session mapping.
- [x] Strict generation/revision ordering; old and same-sequence conflicting events rejected.
- [x] Duplicate publication suppressed by sequence.
- [x] Previous/next/seek require `.supported`; unknown/unsupported fail closed locally.
- [x] Invalid seek fails closed.
- [x] Command failure leaves authoritative snapshot unchanged.
- [x] First unexpected provider failure performs exactly one controlled restart.
- [x] Handler generation invalidates callbacks from the previous provider lifecycle.
- [x] Second unexpected failure locks unavailable with no restart loop.
- [x] No timers, polling, metadata logging/persistence, or Notch presentation ownership.

## Task 4 — isolated `SystemMediaBridge` boundary

Status: **COMPLETE**.

Final files:

- `Sources/NotchHubMediaCore/SystemMediaBridge.swift`
- `Tests/NotchHubMediaCoreTests/SystemMediaBridgeTests.swift`

Completed:

- [x] RED tests created before bridge/transport types.
- [x] CI #499 confirmed RED only on missing `SystemMediaBridge`, `SystemMediaTransport`, and `SystemMediaTransportEvent` after production build passed.
- [x] Injected typed `SystemMediaTransport` protocol implemented without concrete private transport.
- [x] Repeated bridge start is idempotent.
- [x] One start owns one transport callback.
- [x] Stop clears callback before transport teardown.
- [x] Stale transport callbacks cannot surface after stop/restart.
- [x] Normalized transport events forward through the provider contract.
- [x] Typed commands forward only while started.
- [x] No UI, gestures, source-specific policy, logging, persistence, MediaRemote, subprocess, or dynamic-loading implementation.

## Task 5 — security/performance boundary and size investigation

Status: **COMPLETE — NO POLICY WEAKENING REQUIRED**.

Completed:

- [x] Existing release/performance/media-policy/security suites passed without modifying scanners or entitlements.
- [x] No new `Process`/`NSTask`, `dlopen`/`dlsym`, MediaRemote/private symbols, networking, polling, repeating timer, or sensitive permission surface was introduced.
- [x] Initial direct placement in `NotchHubCore` was rejected by the unchanged P0 shipping-size gate.
- [x] Controlled `public -> internal` experiment proved exported API metadata was avoidable for app-internal domain types.
- [x] Full snapshot/provider-event `Equatable` was removed because sequence ordering already owns deduplication and the synthesized equality added unnecessary link cost.
- [x] Controlled synchronous-vs-asynchronous command experiment changed zero shipping bytes; async command dispatch was restored because future transport I/O must not be forced to block `@MainActor`.
- [x] Root cause isolated: dormant media state-machine code should not enter the current shipping link graph before the feature is composed.
- [x] Production media code moved to independent `NotchHubMediaCore` target while retaining full test coverage.
- [x] CI #494 proved the split restored shipping executable/app exactly to `250,320 B / 253,317 B` with the unchanged budget.
- [x] CI #500 on code head `52d6d76b564c603cb21f0ec49bff4fa958c3aac7` passed **117/117 Swift tests**, both jobs, security/performance/release/media-policy gates, Sandbox/Hardened Runtime/package verification, and exact shipping payload `250,320 B / 253,317 B`.

## Task 6 — synchronize architecture and project state

Status: **COMPLETE; EXACT DOCUMENTATION HEAD CI PENDING**.

Updated:

- [x] `docs/ARCHITECTURE.md`
- [x] `docs/PROJECT_STATE.md`
- [x] `docs/ROADMAP.md`
- [x] `CHANGELOG.md`

Recorded explicitly:

- [x] M6.1 remains accepted/merged as `7d5210eb0363933d120334d29daf40956b53cb50` with `ACCEPT_TRANSPORT`.
- [x] M6.2 establishes production normalized domain/provider/controller/injected bridge boundaries only.
- [x] `NotchHubMediaCore` is built/tested but not yet linked into shipping `NotchHubApp`.
- [x] Concrete private system transport/composition is the next reviewed sub-slice.
- [x] No media UI/gesture code is included.
- [x] Apple Music/Spotify/additional-player compatibility remains deferred.
- [x] Security/entitlement/runtime baseline and shipping-size budget are unchanged.

## Task 7 — final verification and PR gate

Status: **IN PROGRESS**.

- [ ] Exact documentation head complete CI success.
- [ ] Confirm no new entitlement/network/subprocess/dynamic-loading/polling/timer/probe-bundling surface on final head.
- [ ] Compare final branch to `main` and review every changed file against this plan.
- [ ] Refresh PR #14 with exact scope, TDD history, CI evidence, size investigation, and deferred concrete transport/UI scope.
- [ ] Mark ready only after exact-head CI is green and PR is mergeable.
- [ ] Squash-merge with expected head SHA.
- [ ] Post-merge verify protected `main` and authoritative docs.

## Final scope review

Concrete MediaRemote/private transport implementation, production composition into `NotchHubApp`, media UI, gestures/haptics, progress animation, physical production-media acceptance, and P1 whole-app optimization are deliberately excluded from M6.2. The next development slice starts with concrete `SystemMediaTransport` behind the accepted injected boundary, not UI.
