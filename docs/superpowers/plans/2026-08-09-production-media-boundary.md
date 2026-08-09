# Production Universal Media Boundary Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the production, player-agnostic media state/controller boundary authorized by the accepted M6.1 `ACCEPT_TRANSPORT` decision, without adding media UI or the concrete private MediaRemote transport yet.

**Architecture:** Add immutable normalized media domain types, a narrow `MediaProvider` protocol, an `@MainActor MediaSessionController`, and an isolated `SystemMediaBridge` adapter boundary over an injected transport. The controller owns ordering, deduplication, capability gating, one controlled restart, and fail-closed media-only state. This slice intentionally does not copy the development probe into shipping code, add subprocess/private API code, broaden entitlements, or wire media into the panel UI; the concrete MediaRemote transport is the next reviewed sub-slice behind the boundary established here.

**Tech Stack:** Swift 6, Swift Package Manager, Swift Testing, Foundation, Combine/ObservableObject only where needed by the controller.

## Global Constraints

- Minimum deployment target remains macOS 14; primary physical target remains macOS 26.6.
- App Sandbox + Hardened Runtime remain mandatory and unchanged.
- No Accessibility, Input Monitoring, Automation, Screen Recording, synthetic input, network access, telemetry, persistence of listening history, or production metadata logging.
- Runtime remains event-driven: no polling loops, repeating timers, display links, or sleep-driven refresh.
- No app-specific player adapters or source-priority rules; follow the macOS system Now Playing source.
- Unsupported or unknown commands are never fabricated or emulated.
- Media failure is fail-closed and must not mutate Notch Core presentation state.
- At most one controlled restart is allowed after unexpected provider failure; a second failure remains unavailable until the next application launch/controller lifecycle.
- The accepted M6.1 probe remains development-only. No probe script/framework/test client is copied into `Sources/**` by this plan.
- This plan does not implement media UI, gestures, haptics, progress animation, or concrete MediaRemote process/dynamic-loading transport.

---

### Task 1: Add immutable media domain and ordering types

**Files:**
- Create: `Sources/NotchHubCore/Media/MediaSessionTypes.swift`
- Test: `Tests/NotchHubCoreTests/MediaSessionTypesTests.swift`

**Interfaces:**
- Produces `MediaSequence`, `MediaCapabilityState`, `MediaCommandCapabilities`, `MediaPlaybackState`, `MediaSourceIdentity`, `MediaSessionSnapshot`, `MediaCommand`, `MediaSubsystemState`.
- `MediaSequence` is lexicographically comparable by `generation` then `revision` and is the single ordering primitive used by later tasks.

- [ ] **Step 1: Write RED tests for ordering and immutable capability/state semantics**

```swift
import Foundation
import Testing
@testable import NotchHubCore

struct MediaSessionTypesTests {
    @Test
    func sequenceOrdersByGenerationThenRevision() {
        #expect(MediaSequence(generation: 1, revision: 2) < MediaSequence(generation: 2, revision: 0))
        #expect(MediaSequence(generation: 2, revision: 1) > MediaSequence(generation: 2, revision: 0))
    }

    @Test
    func snapshotKeepsMissingMetadataAbsent() {
        let snapshot = MediaSessionSnapshot(
            sequence: MediaSequence(generation: 1, revision: 1),
            source: MediaSourceIdentity(bundleIdentifier: "ru.yandex.desktop.music", displayName: nil),
            title: nil,
            artist: nil,
            album: nil,
            artworkData: nil,
            playbackState: .paused,
            durationSeconds: nil,
            positionSeconds: nil,
            referenceDate: nil,
            playbackRate: nil,
            capabilities: .init(previous: .unknown, next: .unknown, seek: .unknown)
        )
        #expect(snapshot.title == nil)
        #expect(snapshot.durationSeconds == nil)
        #expect(snapshot.capabilities.seek == .unknown)
    }
}
```

- [ ] **Step 2: Run CI/test target and verify RED**

Run: `swift test --filter MediaSessionTypesTests`
Expected: compile failure because the media domain types do not exist.

- [ ] **Step 3: Implement minimal immutable `Sendable`/`Equatable` domain types**

Use exact cases:

```swift
public enum MediaCapabilityState: Sendable, Equatable { case supported, unsupported, unknown }
public enum MediaPlaybackState: Sendable, Equatable { case paused, playing }
public enum MediaCommand: Sendable, Equatable { case togglePlayPause, previous, next, seek(seconds: Double) }
public enum MediaSubsystemState: Sendable, Equatable { case unavailable, idle, paused, playing }
```

`MediaSessionSnapshot` stores only normalized optional values and `Data?` artwork; it performs no logging/persistence and fabricates no defaults.

- [ ] **Step 4: Run focused and full Swift tests**

Run: `swift test --filter MediaSessionTypesTests && swift test --parallel`
Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/NotchHubCore/Media/MediaSessionTypes.swift Tests/NotchHubCoreTests/MediaSessionTypesTests.swift
git commit -m "feat: add normalized media session domain"
```

---

### Task 2: Define the player-agnostic provider contract

**Files:**
- Create: `Sources/NotchHubCore/Media/MediaProvider.swift`
- Test: `Tests/NotchHubCoreTests/MediaProviderContractTests.swift`

**Interfaces:**
- Produces `MediaProviderEvent`, `MediaProviderFailure`, `MediaCommandResult`, and `@MainActor MediaProvider`.
- Consumes the Task 1 domain types.
- Provider event surface is callback-driven and event-based, not polling-based.

Required contract:

```swift
public enum MediaProviderEvent: Sendable, Equatable {
    case ready
    case session(MediaSessionSnapshot)
    case noSession(MediaSequence)
    case failed(MediaProviderFailure)
    case stopped
}

@MainActor
public protocol MediaProvider: AnyObject {
    var eventHandler: (@MainActor (MediaProviderEvent) -> Void)? { get set }
    func start()
    func stop()
    func send(_ command: MediaCommand) async -> MediaCommandResult
}
```

- [ ] **Step 1: Write RED compile/behavior contract tests with a test fake**
- [ ] **Step 2: Run `swift test --filter MediaProviderContractTests` and verify RED**
- [ ] **Step 3: Add minimal protocol/event/result/failure definitions; no production implementation yet**
- [ ] **Step 4: Run focused + full tests and verify GREEN**
- [ ] **Step 5: Commit `feat: define media provider contract`**

---

### Task 3: Implement deterministic `MediaSessionController`

**Files:**
- Create: `Sources/NotchHubCore/Media/MediaSessionController.swift`
- Create: `Tests/NotchHubCoreTests/MediaSessionControllerTests.swift`

**Interfaces:**
- Consumes `MediaProvider` and Task 1 domain types.
- Produces `@MainActor public final class MediaSessionController: ObservableObject`.
- Exposes read-only `state: MediaSubsystemState` and `snapshot: MediaSessionSnapshot?`.
- Public lifecycle: `start()`, `stop()`, semantic command methods or `send(_:) async`.

Controller invariants:

1. `start()` installs exactly one provider handler and starts once.
2. `.ready` with no session -> `.idle`.
3. accepted snapshot -> `.playing` or `.paused` from authoritative playback state.
4. `.noSession` with a newer sequence clears only media state -> `.idle`.
5. strictly older sequence events are ignored.
6. exact duplicate snapshots are ignored without extra published state mutation.
7. a newer generation always supersedes an older source generation.
8. previous/next/seek are sent only when the corresponding capability is `.supported`; `.unknown` and `.unsupported` fail closed locally.
9. command failure never mutates the authoritative snapshot.
10. first unexpected `.failed` clears media state and performs exactly one controlled provider stop/start restart.
11. second `.failed` transitions to `.unavailable`, stops the provider, and never restarts again in that controller lifecycle.
12. explicit `stop()` disables restart and leaves media `.unavailable` without touching Notch Core state.

- [ ] **Step 1: Write RED tests for state transitions, stale/out-of-order rejection, dedupe, capability gating, command failure, and one-restart policy**
- [ ] **Step 2: Run `swift test --filter MediaSessionControllerTests`; verify failures are due to missing controller**
- [ ] **Step 3: Implement the minimal controller with one explicit event handler and no timers/tasks for observation**
- [ ] **Step 4: Run focused tests, then `swift test --parallel`; expect GREEN**
- [ ] **Step 5: Commit `feat: add media session controller`**

---

### Task 4: Add isolated production `SystemMediaBridge` boundary

**Files:**
- Create: `Sources/NotchHubCore/Media/SystemMediaBridge.swift`
- Test: `Tests/NotchHubCoreTests/SystemMediaBridgeTests.swift`

**Interfaces:**
- Produces internal `SystemMediaTransport` and `SystemMediaTransportEvent` plus public/internal `SystemMediaBridge: MediaProvider` as appropriate for app composition.
- The transport is injected. This task deliberately does not implement MediaRemote/private API/process loading.
- The bridge translates transport lifecycle/session/command results into the provider contract and owns transport callback installation/removal.

Required boundary behavior:

- one start owns one transport callback;
- repeated start is idempotent;
- stop clears callback before transport teardown;
- transport session/no-session events pass through unchanged after normalized domain construction;
- malformed/invalid data is not represented because the concrete transport must construct validated domain values before crossing this boundary;
- fixed typed `MediaCommand` only; no string/command-ID passthrough exists;
- bridge never logs metadata and never persists snapshots;
- bridge does not know about UI, gestures, panel state, or source-specific policy.

- [ ] **Step 1: Write RED tests with a fake transport for start/stop ownership, event forwarding, typed command forwarding, and idempotency**
- [ ] **Step 2: Run `swift test --filter SystemMediaBridgeTests`; verify RED**
- [ ] **Step 3: Implement minimal injected bridge boundary**
- [ ] **Step 4: Run focused + full Swift tests and deterministic repository policy checks**
- [ ] **Step 5: Commit `feat: isolate system media bridge boundary`**

---

### Task 5: Lock security/performance boundary before concrete transport work

**Files:**
- Modify: `scripts/security-audit.sh`
- Modify: `scripts/performance_policy.py` only if required to recognize the new event-driven media files without weakening existing bans
- Test: existing security/performance policy tests; add focused regression tests only when a policy rule changes.

**Interfaces:**
- Ensures the current slice does not accidentally introduce `Process`/`NSTask`, `dlopen`/`dlsym`, MediaRemote/private symbols, polling/repeating timers, networking, or entitlement changes.
- Explicitly allows the *type name* `SystemMediaBridge` while continuing to reject actual private/runtime transport mechanisms outside a later narrowly reviewed change.

- [ ] **Step 1: Add/adjust policy regression test only if the new file names trigger an ambiguous existing rule**
- [ ] **Step 2: Run policy tests and security audit; verify any RED is a real policy mismatch, not bypassed**
- [ ] **Step 3: Make the minimum policy change needed; never broaden prohibited runtime primitives**
- [ ] **Step 4: Run `python3 scripts/test_performance_policy.py`, release policy tests, and `scripts/security-audit.sh`**
- [ ] **Step 5: Commit only if a policy file actually needed modification**

---

### Task 6: Synchronize architecture and project state

**Files:**
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/PROJECT_STATE.md`
- Modify: `docs/ROADMAP.md`
- Modify: `CHANGELOG.md`

Record precisely:

- M6.1 transport remains accepted and merged as `7d5210eb0363933d120334d29daf40956b53cb50`;
- this M6.2 slice establishes production domain/provider/controller/bridge boundaries only;
- concrete MediaRemote transport packaging/integration remains the next reviewed sub-slice;
- no media UI/gesture code is included yet;
- deferred Apple Music/Spotify/independent-player compatibility claims remain deferred;
- security/performance baseline is unchanged.

- [ ] **Step 1: Update docs from actual implemented behavior only**
- [ ] **Step 2: Scan for stale statements claiming production media is still wholly blocked on M6.1**
- [ ] **Step 3: Run documentation/policy tests and full Swift suite**
- [ ] **Step 4: Commit `docs: record production media boundary`**

---

### Task 7: Final verification and PR gate

**Files:** no new runtime files unless verification exposes a defect.

- [ ] **Step 1: Run complete Swift suite with warnings-as-errors build**

```bash
swift build -Xswiftc -warnings-as-errors
swift test --parallel
```

- [ ] **Step 2: Run release/performance/security/media policy suites and package verification through CI**
- [ ] **Step 3: Confirm no new entitlement, network, subprocess, dynamic-loading, polling/timer, or probe-bundling surface**
- [ ] **Step 4: Compare branch to `main`; review every changed file against this plan**
- [ ] **Step 5: Open/refresh PR with exact scope, TDD evidence, CI evidence, and explicitly deferred concrete transport/UI work**
- [ ] **Step 6: Merge only after exact-head CI is green and PR is mergeable**

## Plan self-review

- Spec coverage: domain normalization, provider abstraction, controller ordering/dedup/capabilities/failure semantics, one-restart lifecycle, isolated bridge boundary, security/performance invariants, and docs are all mapped to explicit tasks.
- Scope: concrete private MediaRemote transport, packaging, media UI, gestures/haptics, progress animation, and P1 optimization are intentionally excluded so this plan remains one independently reviewable architecture slice.
- Placeholder scan: no TBD/TODO requirements remain in the plan.
- Type consistency: ordering uses `MediaSequence`; provider, controller, and bridge share the same domain command/event types; no parallel source-specific model is introduced.
