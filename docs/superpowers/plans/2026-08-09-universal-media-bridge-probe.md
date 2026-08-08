# Universal Media Bridge Compatibility and Security Probe Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prove or reject a system-wide, event-driven MediaRemote transport for NotchHub on the target macOS 26.6 configuration without changing the shipped NotchHub runtime or weakening its accepted Sandbox/Hardened Runtime baseline.

**Architecture:** Build a development-only Swift probe outside `Sources/` that launches a single allowlisted `/usr/bin/perl` MediaRemote adapter stream, validates bounded JSON events, sends only allowlisted media commands, and is packaged into a temporary ad-hoc signed Hardened Runtime + App Sandbox probe bundle. The probe uses a pinned upstream MediaRemote Adapter revision only under ignored `build/` paths; no third-party Swift package or probe asset is added to the shipping NotchHub bundle. Hardware evidence decides whether this transport is eligible for a later production `SystemMediaBridge` plan.

**Tech Stack:** Swift 6, Foundation `Process` in development-only `Tools/`, Swift Testing, Swift Package Manager, App Sandbox, Hardened Runtime, shell/Python standard-library development tooling, pinned `ungive/mediaremote-adapter` revision `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a` (BSD-3-Clause) for the probe only.

## Global Constraints

- Authoritative design: `docs/superpowers/specs/2026-08-09-universal-media-gestures-haptics-design.md`.
- Deployment floor stays macOS 14; primary physical acceptance target is macOS 26.6.
- This plan is a **transport probe**, not production media integration and not Media UI/gesture implementation.
- `Sources/**` must not gain `Process`, `NSTask`, `dlopen`, `dlsym`, MediaRemote imports, private symbols, polling, timers, networking, or new permissions in this slice.
- Shipping `NotchHub.app` keeps exactly `com.apple.security.app-sandbox = true`; no entitlement changes are permitted by this plan.
- Hardened Runtime remains enabled; no `disable-library-validation`, JIT, unsigned executable memory, DYLD environment entitlement, or `get-task-allow` exception.
- No Accessibility, Input Monitoring, Screen Recording, Automation/Apple Events, synthetic input, SIP changes, code injection, or Gatekeeper weakening.
- The Swift probe never invokes a shell. Its production probe launcher fixes `executableURL` to `/usr/bin/perl` and builds an allowlisted argument vector.
- The adapter source is fetched only by an explicit development bootstrap command, pinned to exact commit `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`, built into ignored `build/`, and never committed as a runtime dependency.
- The adapter's BSD-3-Clause license must accompany any temporary probe bundle containing its binary/script assets.
- Observation uses adapter `stream --no-diff --micros`; periodic `get` polling is prohibited.
- Probe reports must not persist title, artist, album, artwork bytes, listening history, or raw Now Playing payloads. Durable evidence contains source bundle identifier, capability/result booleans, lifecycle/result codes, counts, timestamps/latencies, and resource aggregates only.
- A missing or insufficient capability surface is an explicit probe result, not permission to guess support in UI.
- The valid final outcomes are `ACCEPT_TRANSPORT`, `REJECT_TRANSPORT`, or `NEEDS_TRANSPORT_REDESIGN`. Security weakening is not a valid way to turn a failed probe green.

---

## File Structure Locked by This Plan

### Development-only probe code

- Create `Tools/MediaBridgeProbe/Core/ProbeMediaPayload.swift` — bounded decoding/normalization for adapter stream lines; no AppKit/UI.
- Create `Tools/MediaBridgeProbe/Core/ProbeMediaCommand.swift` — strict media command allowlist and command-line mapping.
- Create `Tools/MediaBridgeProbe/Core/ProbeProcess.swift` — lifecycle abstraction and concrete fixed `/usr/bin/perl` launcher; owns stream termination.
- Create `Tools/MediaBridgeProbe/Core/ProbeReport.swift` — privacy-preserving evidence schema; never stores track metadata/artwork.
- Create `Tools/MediaBridgeProbe/CLI/main.swift` — development CLI for `observe`, `send`, `seek`, and `self-test`.
- Create `Tests/MediaBridgeProbeCoreTests/ProbeMediaPayloadTests.swift`.
- Create `Tests/MediaBridgeProbeCoreTests/ProbeMediaCommandTests.swift`.
- Create `Tests/MediaBridgeProbeCoreTests/ProbeProcessTests.swift`.
- Create `Tests/MediaBridgeProbeCoreTests/ProbeReportTests.swift`.

### Probe build/acceptance tooling

- Modify `Package.swift` — add `MediaBridgeProbeCore`, `MediaBridgeProbe`, and `MediaBridgeProbeCoreTests` only; no external package dependencies.
- Create `scripts/bootstrap-media-bridge-probe.sh` — fetch/build exact pinned upstream adapter into `build/media-bridge-probe/vendor/`.
- Create `scripts/build-media-bridge-probe-app.sh` — package/sign temporary `build/MediaBridgeProbe.app` with the same sandbox entitlement file as NotchHub.
- Create `scripts/verify-media-bridge-probe.sh` — deterministic signature/entitlement/bundle/isolation checks.
- Create `scripts/media-bridge-probe-acceptance.py` — normalize user-entered scenario results into metadata-safe JSON.
- Create `docs/testing/MEDIA_BRIDGE_PROBE.md` — exact target-Mac manual acceptance procedure and scenario IDs.

### Policy/documentation touched only when the probe implementation exists

- Modify `scripts/test_release_policy.py` — assert shipping packaging never references `MediaBridgeProbe`, `mediaremote-adapter.pl`, or `MediaRemoteAdapter.framework`.
- Modify `docs/TESTING.md` — distinguish deterministic probe tests from unavoidable real-media hardware acceptance.
- Modify `docs/PROJECT_STATE.md` and `docs/ROADMAP.md` only after the probe result is known; do not claim the bridge accepted before physical evidence exists.
- Modify `SECURITY.md` only if a later production bridge is accepted; this probe plan does **not** yet relax runtime `Sources/**` subprocess/dynamic-loading prohibitions.

---

### Task 1: Add Development-Only Probe Targets and Bounded Media Payload Decoding

**Files:**
- Modify: `Package.swift`
- Create: `Tools/MediaBridgeProbe/Core/ProbeMediaPayload.swift`
- Create: `Tests/MediaBridgeProbeCoreTests/ProbeMediaPayloadTests.swift`

**Interfaces:**
- Consumes: newline-delimited UTF-8 JSON emitted by upstream `stream --no-diff --micros`.
- Produces:
  - `struct ProbeMediaPayload: Equatable, Sendable`
  - `enum ProbePayloadDecoderError: Error, Equatable`
  - `struct ProbePayloadDecoder { static func decode(line: Data) throws -> ProbeMediaPayload? }`

- [ ] **Step 1: Add the probe targets to `Package.swift` without external package dependencies**

Use this target shape:

```swift
.target(
    name: "MediaBridgeProbeCore",
    path: "Tools/MediaBridgeProbe/Core"
),
.executableTarget(
    name: "MediaBridgeProbe",
    dependencies: ["MediaBridgeProbeCore"],
    path: "Tools/MediaBridgeProbe/CLI"
),
.testTarget(
    name: "MediaBridgeProbeCoreTests",
    dependencies: ["MediaBridgeProbeCore"],
    path: "Tests/MediaBridgeProbeCoreTests"
)
```

Do not add anything to `Package.dependencies`.

- [ ] **Step 2: Write RED decoding tests**

Use Swift Testing and cover at least:

```swift
import Foundation
import Testing
@testable import MediaBridgeProbeCore

struct ProbeMediaPayloadTests {
    @Test
    func decodesNoDiffMicrosPayloadWithoutPersistingRawJSON() throws {
        let line = Data(#"{"type":"data","diff":false,"payload":{"bundleIdentifier":"ru.yandex.desktop.music","playing":true,"title":"Track","artist":"Artist","album":"Album","durationMicros":180000000,"elapsedTimeMicros":42000000,"timestampEpochMicros":1786233600000000,"playbackRate":1,"artworkMimeType":"image/jpeg","artworkData":"AQID","prohibitsSkip":false}}"#.utf8)

        let decoded = try #require(ProbePayloadDecoder.decode(line: line))
        #expect(decoded.bundleIdentifier == "ru.yandex.desktop.music")
        #expect(decoded.playing)
        #expect(decoded.durationMicros == 180_000_000)
        #expect(decoded.elapsedTimeMicros == 42_000_000)
        #expect(decoded.artworkByteCount == 3)
        #expect(decoded.title == "Track")
    }

    @Test
    func emptyPayloadMeansNoActiveSession() throws {
        let line = Data(#"{"type":"data","diff":false,"payload":{}}"#.utf8)
        #expect(try ProbePayloadDecoder.decode(line: line) == nil)
    }

    @Test
    func rejectsDiffPayloadForProbeSimplicity() {
        let line = Data(#"{"type":"data","diff":true,"payload":{"title":"stale"}}"#.utf8)
        #expect(throws: ProbePayloadDecoderError.diffPayloadNotAllowed) {
            try ProbePayloadDecoder.decode(line: line)
        }
    }

    @Test
    func rejectsOversizedLineBeforeJSONDecoding() {
        let line = Data(repeating: 0x61, count: ProbePayloadDecoder.maximumLineBytes + 1)
        #expect(throws: ProbePayloadDecoderError.lineTooLarge) {
            try ProbePayloadDecoder.decode(line: line)
        }
    }

    @Test
    func rejectsOversizedArtworkAfterBase64Decode() {
        let oversized = Data(repeating: 0x41, count: ProbePayloadDecoder.maximumArtworkBytes + 1)
            .base64EncodedString()
        let line = Data(#"{"type":"data","diff":false,"payload":{"bundleIdentifier":"test.player","playing":true,"title":"Track","artworkData":"\#(oversized)"}}"#.utf8)

        #expect(throws: ProbePayloadDecoderError.artworkTooLarge) {
            try ProbePayloadDecoder.decode(line: line)
        }
    }
}
```

Initial deterministic bounds for the probe:

```swift
static let maximumLineBytes = 8 * 1024 * 1024
static let maximumArtworkBytes = 4 * 1024 * 1024
static let maximumTextUTF8Bytes = 16 * 1024
static let maximumDurationMicros: UInt64 = 30 * 24 * 60 * 60 * 1_000_000
static let maximumPlaybackRate = 16.0
```

Missing optional fields remain `nil`; do not manufacture placeholders.

- [ ] **Step 3: Run the focused test and verify RED**

Run:

```bash
swift test --filter ProbeMediaPayloadTests
```

Expected: compile/test failure because `ProbePayloadDecoder` and related types do not exist.

- [ ] **Step 4: Implement the minimum bounded decoder**

Implementation shape:

```swift
public struct ProbeMediaPayload: Equatable, Sendable {
    public let bundleIdentifier: String
    public let playing: Bool
    public let title: String
    public let artist: String?
    public let album: String?
    public let durationMicros: UInt64?
    public let elapsedTimeMicros: UInt64?
    public let timestampEpochMicros: UInt64?
    public let playbackRate: Double?
    public let artworkMimeType: String?
    public let artworkByteCount: Int
    public let prohibitsSkip: Bool?
}
```

Decode through private `Decodable` wire structs. Validate line size before `JSONDecoder`, text UTF-8 byte lengths before normalization, finite/non-negative timing, `abs(playbackRate) <= 16`, and decoded artwork size. Do not retain the base64 string or artwork bytes after counting them in this probe model.

- [ ] **Step 5: Run focused and complete tests**

```bash
swift test --filter ProbeMediaPayloadTests
swift test --parallel
```

Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
git add Package.swift Tools/MediaBridgeProbe/Core/ProbeMediaPayload.swift Tests/MediaBridgeProbeCoreTests/ProbeMediaPayloadTests.swift
git commit -m "test: define bounded media bridge probe payloads"
```

---

### Task 2: Define a Closed Media Command Allowlist

**Files:**
- Create: `Tools/MediaBridgeProbe/Core/ProbeMediaCommand.swift`
- Create: `Tests/MediaBridgeProbeCoreTests/ProbeMediaCommandTests.swift`

**Interfaces:**
- Produces:
  - `enum ProbeMediaCommand: Equatable, Sendable`
  - `func adapterArguments(scriptURL:frameworkURL:testClientURL:) throws -> [String]`
- Only `togglePlayPause`, `next`, `previous`, and `seek(microseconds:)` are accepted for product-relevant probing.

- [ ] **Step 1: Write RED allowlist tests**

```swift
import Foundation
import Testing
@testable import MediaBridgeProbeCore

struct ProbeMediaCommandTests {
    @Test
    func nextMapsToMediaRemoteCommandFour() throws {
        let args = try ProbeMediaCommand.next.adapterArguments(
            scriptURL: URL(fileURLWithPath: "/bundle/mediaremote-adapter.pl"),
            frameworkURL: URL(fileURLWithPath: "/bundle/MediaRemoteAdapter.framework"),
            testClientURL: URL(fileURLWithPath: "/bundle/MediaRemoteAdapterTestClient")
        )
        #expect(args.suffix(2) == ["send", "4"])
    }

    @Test
    func previousMapsToFive() throws {
        let args = try ProbeMediaCommand.previous.adapterArguments(
            scriptURL: URL(fileURLWithPath: "/bundle/mediaremote-adapter.pl"),
            frameworkURL: URL(fileURLWithPath: "/bundle/MediaRemoteAdapter.framework"),
            testClientURL: URL(fileURLWithPath: "/bundle/MediaRemoteAdapterTestClient")
        )
        #expect(args.suffix(2) == ["send", "5"])
    }

    @Test
    func seekRejectsValuesBeyondThirtyDays() {
        #expect(throws: ProbeMediaCommandError.seekOutOfRange) {
            try ProbeMediaCommand.seek(microseconds: 30 * 24 * 60 * 60 * 1_000_000 + 1)
                .validated()
        }
    }
}
```

- [ ] **Step 2: Verify RED**

```bash
swift test --filter ProbeMediaCommandTests
```

- [ ] **Step 3: Implement the fixed mappings**

Use only:

```swift
public enum ProbeMediaCommand: Equatable, Sendable {
    case togglePlayPause
    case next
    case previous
    case seek(microseconds: UInt64)
}
```

Mappings:

- toggle = `send 2`
- next = `send 4`
- previous = `send 5`
- seek = `seek <positive microseconds>`

No arbitrary command ID/string passthrough is allowed.

- [ ] **Step 4: Run tests and commit**

```bash
swift test --filter ProbeMediaCommandTests
swift test --parallel
git add Tools/MediaBridgeProbe/Core/ProbeMediaCommand.swift Tests/MediaBridgeProbeCoreTests/ProbeMediaCommandTests.swift
git commit -m "test: lock media probe command allowlist"
```

---

### Task 3: Implement Cancellation-Safe Probe Process Ownership

**Files:**
- Create: `Tools/MediaBridgeProbe/Core/ProbeProcess.swift`
- Create: `Tests/MediaBridgeProbeCoreTests/ProbeProcessTests.swift`

**Interfaces:**
- Produces `ProbeProcessController` with exactly one observation process at a time.
- Concrete launcher always uses `/usr/bin/perl`; tests inject a fake process boundary.

- [ ] **Step 1: Write RED lifecycle tests**

Cover:

```swift
@Test func startTwiceCreatesOneStreamProcess()
@Test func stopTerminatesAndWaitsForTheOwnedProcess()
@Test func nonzeroExitTransitionsToFailedWithoutAutomaticLoop()
@Test func oversizedStdoutLineStopsTheStreamAsProtocolFailure()
@Test func stderrIsBoundedAndDoesNotBecomeDurableMetadata()
@Test func commandProcessUsesFixedPerlExecutableAndAllowlistedArguments()
```

The fake launcher must record launch count, executable URL, arguments, terminate count, and synthetic stdout/stderr/exit events. No wall-clock sleeps.

- [ ] **Step 2: Verify RED**

```bash
swift test --filter ProbeProcessTests
```

- [ ] **Step 3: Implement lifecycle ownership**

Production probe process configuration must be equivalent to:

```swift
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
process.arguments = [
    scriptURL.path,
    frameworkURL.path,
    testClientURL.path,
    "stream",
    "--no-diff",
    "--micros",
]
```

Use pipes for stdout/stderr. Parse newline-delimited stdout incrementally with an 8 MiB per-line hard limit. `stop()` must close handlers, call `terminate()` only for a running owned process, and wait for process exit before releasing ownership. The probe itself does not implement restart in this task; a production restart policy belongs to the later production bridge plan.

- [ ] **Step 4: Run tests and commit**

```bash
swift test --filter ProbeProcessTests
swift test --parallel
git add Tools/MediaBridgeProbe/Core/ProbeProcess.swift Tests/MediaBridgeProbeCoreTests/ProbeProcessTests.swift
git commit -m "test: harden media probe process lifecycle"
```

---

### Task 4: Add Privacy-Preserving Probe Evidence

**Files:**
- Create: `Tools/MediaBridgeProbe/Core/ProbeReport.swift`
- Create: `Tests/MediaBridgeProbeCoreTests/ProbeReportTests.swift`

**Interfaces:**
- Produces JSON-safe evidence with no track content.

- [ ] **Step 1: Write RED privacy tests**

The report schema must contain only fields such as:

```swift
public struct ProbeReport: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let sourceCommit: String
    public let macOSVersion: String
    public let hardwareModel: String
    public let adapterCommit: String
    public let sourceBundleIdentifier: String?
    public let observedSession: Bool
    public let observedArtwork: Bool
    public let observedPlayingState: Bool
    public let eventCount: Int
    public let commandResults: [String: Bool]
    public let cleanTeardown: Bool
    public let orphanProcessDetected: Bool
}
```

Test that encoded JSON does not contain sample title/artist/album strings or `artworkData`.

- [ ] **Step 2: Verify RED, implement, run GREEN**

```bash
swift test --filter ProbeReportTests
swift test --parallel
```

- [ ] **Step 3: Commit**

```bash
git add Tools/MediaBridgeProbe/Core/ProbeReport.swift Tests/MediaBridgeProbeCoreTests/ProbeReportTests.swift
git commit -m "test: add privacy-safe media probe evidence"
```

---

### Task 5: Build the Development CLI

**Files:**
- Create: `Tools/MediaBridgeProbe/CLI/main.swift`

**Interfaces:**
- Commands:
  - `MediaBridgeProbe observe --seconds N --report PATH`
  - `MediaBridgeProbe send toggle|next|previous`
  - `MediaBridgeProbe seek MICROSECONDS`
  - `MediaBridgeProbe self-test`

- [ ] **Step 1: Add parser tests before CLI wiring where deterministic behavior belongs in Core**

Move argument parsing into a small `ProbeInvocation` type in Core if necessary so invalid invocations can be unit tested without launching processes.

Required failures:

```text
unknown command -> exit 64
negative/zero observe duration -> exit 64
seek outside validated range -> exit 64
extra arbitrary arguments -> exit 64
missing bundled adapter paths -> exit 66
```

- [ ] **Step 2: Wire CLI to `ProbeProcessController`**

`observe` starts the event stream, records only normalized evidence, and stops after a one-shot bounded deadline. The deadline is development-only probe orchestration; no repeating timer/polling is introduced. `send`/`seek` launch one bounded command process and propagate success/failure.

Do not print title/artist/album/artwork in the normal CLI output. A temporary `--diagnostic-metadata` mode is **not** part of this plan.

- [ ] **Step 3: Verify warnings-as-errors and tests**

```bash
swift build --target MediaBridgeProbe -Xswiftc -warnings-as-errors
swift test --parallel
swift format lint --recursive --strict --configuration .swift-format Tools Tests Package.swift
```

- [ ] **Step 4: Commit**

```bash
git add Tools/MediaBridgeProbe/CLI/main.swift Tools/MediaBridgeProbe/Core
 git commit -m "feat: add bounded media bridge probe cli"
```

---

### Task 6: Pin and Build the Upstream Adapter Outside the Repository Runtime

**Files:**
- Create: `scripts/bootstrap-media-bridge-probe.sh`

**Interfaces:**
- Produces ignored build assets under `build/media-bridge-probe/vendor/` only.
- Upstream: `https://github.com/ungive/mediaremote-adapter.git`
- Exact revision: `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`

- [ ] **Step 1: Write deterministic shell assertions before network/build actions**

The script begins with:

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly ADAPTER_REPO="https://github.com/ungive/mediaremote-adapter.git"
readonly ADAPTER_COMMIT="3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly VENDOR_DIR="$ROOT_DIR/build/media-bridge-probe/vendor"
```

Fetch only the exact commit into `build/`; after checkout require:

```bash
test "$(git -C "$VENDOR_DIR/source" rev-parse HEAD)" = "$ADAPTER_COMMIT"
```

Build with upstream CMake instructions and verify all expected files exist:

```text
MediaRemoteAdapter.framework
MediaRemoteAdapterTestClient
bin/mediaremote-adapter.pl
LICENSE
```

No upstream file is copied into tracked source directories.

- [ ] **Step 2: Add a local no-network reuse path**

If the exact checked-out revision and built assets already exist, the script reuses them rather than refetching.

- [ ] **Step 3: Shell-check and commit**

```bash
bash -n scripts/bootstrap-media-bridge-probe.sh
git add scripts/bootstrap-media-bridge-probe.sh
git commit -m "chore: pin media bridge probe adapter source"
```

---

### Task 7: Package a Sandbox/Hardened Probe Bundle Matching NotchHub's Trust Boundary

**Files:**
- Create: `scripts/build-media-bridge-probe-app.sh`
- Create: `scripts/verify-media-bridge-probe.sh`

**Interfaces:**
- Produces `build/MediaBridgeProbe.app` only.
- Uses existing `Resources/NotchHub.entitlements` unchanged.

- [ ] **Step 1: Package the CLI and adapter assets**

Bundle layout:

```text
build/MediaBridgeProbe.app/
  Contents/
    MacOS/MediaBridgeProbe
    Resources/
      mediaremote-adapter.pl
      MediaRemoteAdapter.framework/
      MediaRemoteAdapterTestClient
      MediaRemoteAdapter-LICENSE.txt
```

Create a minimal generated `Info.plist` with bundle identifier `ru.trueruslan.notchhub.media-bridge-probe`, minimum system version `14.0`, and executable `MediaBridgeProbe`.

- [ ] **Step 2: Sign nested code then the probe bundle**

Ad-hoc development signing order:

```bash
codesign --force --sign - "$APP/Contents/Resources/MediaRemoteAdapter.framework"
codesign --force --sign - "$APP/Contents/Resources/MediaRemoteAdapterTestClient"
codesign --force --options runtime \
  --entitlements "$ROOT_DIR/Resources/NotchHub.entitlements" \
  --sign - "$APP"
```

Do not add special entitlements to make the probe work.

- [ ] **Step 3: Verify exact effective entitlements and Hardened Runtime**

`verify-media-bridge-probe.sh` must enforce:

```bash
codesign --verify --deep --strict build/MediaBridgeProbe.app
codesign -dv --verbose=4 build/MediaBridgeProbe.app 2> build/media-bridge-probe-codesign.txt
grep -Eq 'flags=.*runtime' build/media-bridge-probe-codesign.txt
codesign --display --entitlements - --xml build/MediaBridgeProbe.app > build/media-bridge-probe-entitlements.plist
```

Then parse the plist and require exact equality:

```python
{"com.apple.security.app-sandbox": True}
```

Also fail if the shipping bundle contains probe assets:

```bash
./scripts/build-app.sh release
if find build/NotchHub.app -type f \( \
  -name 'MediaBridgeProbe' -o \
  -name 'mediaremote-adapter.pl' -o \
  -name 'MediaRemoteAdapterTestClient' \
\) -print -quit | grep -q .; then
  exit 1
fi
if find build/NotchHub.app -type d -name 'MediaRemoteAdapter.framework' -print -quit | grep -q .; then
  exit 1
fi
```

- [ ] **Step 4: Run verification and commit**

```bash
bash -n scripts/build-media-bridge-probe-app.sh scripts/verify-media-bridge-probe.sh
./scripts/build-media-bridge-probe-app.sh
./scripts/verify-media-bridge-probe.sh
git add scripts/build-media-bridge-probe-app.sh scripts/verify-media-bridge-probe.sh
git commit -m "chore: package sandboxed media bridge probe"
```

If sandboxed execution cannot launch/use the adapter, record the failure; do **not** rerun with sandbox disabled as the acceptance candidate.

---

### Task 8: Add Shipping-Bundle Isolation Regression Coverage

**Files:**
- Modify: `scripts/test_release_policy.py`

**Interfaces:**
- Proves development probe assets cannot silently become shipping runtime assets.

- [ ] **Step 1: Add RED source-policy tests**

Add a test that reads `scripts/build-app.sh` and `scripts/build-dmg.sh` and asserts they do not reference any of:

```python
forbidden = (
    "MediaBridgeProbe",
    "mediaremote-adapter.pl",
    "MediaRemoteAdapter.framework",
    "MediaRemoteAdapterTestClient",
)
```

Also assert `Package.swift` has no `.package(` external dependencies.

- [ ] **Step 2: Run RED/GREEN appropriately**

If the existing packaging already passes the new invariant, do not fabricate a RED production defect. The test itself is a new policy lock. Run:

```bash
(cd scripts && python3 -m unittest -v test_release_policy.py)
./scripts/security-audit.sh
```

Expected: PASS with unchanged shipping security baseline.

- [ ] **Step 3: Commit**

```bash
git add scripts/test_release_policy.py
git commit -m "test: isolate media probe from shipping bundle"
```

---

### Task 9: Document and Execute the Target-Mac Transport Acceptance Matrix

**Files:**
- Create: `docs/testing/MEDIA_BRIDGE_PROBE.md`
- Create: `scripts/media-bridge-probe-acceptance.py`

**Interfaces:**
- Produces `build/media-bridge-probe-acceptance.json` with no track metadata.

- [ ] **Step 1: Define scenario IDs and exact PASS criteria**

The document must include:

```text
NH-MEDIA-BRIDGE-001  sandboxed probe starts with Hardened Runtime and exact sandbox entitlement
NH-MEDIA-BRIDGE-002  stream observes current system Now Playing without periodic polling
NH-MEDIA-BRIDGE-003  Yandex Music source observed
NH-MEDIA-BRIDGE-004  Apple Music source observed
NH-MEDIA-BRIDGE-005  Spotify source observed
NH-MEDIA-BRIDGE-006  Safari/Chromium YouTube source observed
NH-MEDIA-BRIDGE-007  additional independent Now Playing player observed
NH-MEDIA-BRIDGE-008  macOS active-source switch is reflected by stream events
NH-MEDIA-BRIDGE-009  artwork is observed for at least the sources that publish it
NH-MEDIA-BRIDGE-010  toggle play/pause command works when system source accepts it
NH-MEDIA-BRIDGE-011  next/previous commands work when the source accepts them
NH-MEDIA-BRIDGE-012  seek works for a source that exposes seek behavior
NH-MEDIA-BRIDGE-013  closing the source yields no-session state without probe failure
NH-MEDIA-BRIDGE-014  terminating the probe terminates owned perl/helper processes; no orphan remains
NH-MEDIA-BRIDGE-015  adapter crash/nonzero exit does not restart-loop
NH-MEDIA-BRIDGE-016  capability surface is sufficient to distinguish supported/unsupported/unknown actions
NH-MEDIA-BRIDGE-017  no Accessibility/Input Monitoring/Automation prompt appears
NH-MEDIA-BRIDGE-018  NotchHub shipping bundle remains unchanged and probe-free
```

For `NH-MEDIA-BRIDGE-016`, if the tested adapter cannot expose an authoritative capability signal for previous/next/seek, mark `NEEDS_TRANSPORT_REDESIGN`; do not infer capabilities from button success after the fact.

- [ ] **Step 2: Add a privacy-safe acceptance recorder**

`scripts/media-bridge-probe-acceptance.py` accepts scenario IDs and `PASS|FAIL|NOT_SUPPORTED|NEEDS_REDESIGN`, validates the known ID set, and writes only:

```json
{
  "schemaVersion": 1,
  "sourceCommit": "<40 hex>",
  "adapterCommit": "3ac3d4bdf862c7b5399b4fba4df5689f5c38609a",
  "platform": {"macOS": "26.6", "hardwareModel": "Mac16,8"},
  "results": {"NH-MEDIA-BRIDGE-001": "PASS"}
}
```

No free-form metadata field is allowed.

- [ ] **Step 3: Add unit tests for the Python recorder in the same script module or a dedicated `scripts/test_media_bridge_probe_acceptance.py`**

Test unknown scenario rejection, invalid result rejection, source SHA validation, and absence of arbitrary metadata fields.

- [ ] **Step 4: Commit**

```bash
git add docs/testing/MEDIA_BRIDGE_PROBE.md scripts/media-bridge-probe-acceptance.py scripts/test_media_bridge_probe_acceptance.py
git commit -m "docs: define universal media bridge hardware acceptance"
```

---

### Task 10: Measure Bridge Resource Cost Before Production Adoption

**Files:**
- Modify: `docs/testing/MEDIA_BRIDGE_PROBE.md`
- Reuse: `scripts/perf-baseline.py`

**Interfaces:**
- Development evidence only under `build/`; do not alter P0 baseline budgets in this task.

- [ ] **Step 1: Measure the probe + child process explicitly**

The existing sampler attaches to one PID, so collect two separate raw measurements while a stable media source is playing:

```bash
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

Also run at least 10 minutes with the stream idle except for system-delivered playback progress/track events to detect sustained RSS/thread growth. These values are diagnostic transport evidence, not yet P1 whole-app acceptance.

- [ ] **Step 2: Verify teardown resource recovery**

After stopping the probe, require both:

```bash
! kill -0 "$PROBE_PID" 2>/dev/null
! kill -0 "$PERL_PID" 2>/dev/null
```

Also inspect for the exact child command line and confirm no matching orphan remains.

- [ ] **Step 3: Record only aggregate conclusions in project docs**

Do not commit raw measurements containing local paths/process command lines. If the transport is accepted, record aggregate CPU/RSS/thread observations and lifecycle result in `docs/PROJECT_STATE.md` later.

---

### Task 11: Run Full Deterministic Gates and Make the Transport Decision

**Files:**
- Modify after evidence: `docs/PROJECT_STATE.md`
- Modify after evidence: `docs/ROADMAP.md`
- Modify after evidence: `docs/TESTING.md`
- Modify after evidence: `CHANGELOG.md` only if probe tooling itself is considered a notable unreleased engineering change

**Interfaces:**
- Produces one explicit decision: `ACCEPT_TRANSPORT`, `REJECT_TRANSPORT`, or `NEEDS_TRANSPORT_REDESIGN`.

- [ ] **Step 1: Run CI-equivalent deterministic gates**

```bash
swift package describe
(cd scripts && python3 -m unittest -v test_release_policy.py)
(cd scripts && python3 -m unittest -v test_performance_policy.py)
python3 scripts/performance_policy.py audit Sources
swift format lint --recursive --strict --configuration .swift-format Sources Tests Tools Package.swift
bash -n scripts/*.sh
./scripts/security-audit.sh
swift build -Xswiftc -warnings-as-errors
swift test --parallel
./scripts/build-dmg.sh
```

Expected: ordinary NotchHub shipping app still passes existing security/signature/Sandbox/system-library/size gates. Do not widen the P0 size budget because the probe target exists; `build-app.sh` still packages only `NotchHub`.

- [ ] **Step 2: Apply the physical decision gate**

`ACCEPT_TRANSPORT` requires all of the following:

1. sandbox + Hardened Runtime probe works without extra entitlement/permission;
2. event-driven system Now Playing observation works on macOS 26.6;
3. Yandex Music, Apple Music, Spotify, browser media, and one independent player are observable when macOS exposes them;
4. play/pause and track navigation work where actually supported;
5. seek works for at least one source that supports seek;
6. source switching and disappearance are correct;
7. artwork path is demonstrated where published;
8. capability discovery is sufficient for the capability-driven product contract, or has a concrete authoritative MediaRemote extension path proven by the probe;
9. child lifecycle is bounded with clean termination/no orphan/restart storm;
10. no security prompt/permission widening occurs;
11. diagnostic resource cost does not reveal runaway CPU/RSS/threads/background process behavior.

If item 8 is not satisfied, use `NEEDS_TRANSPORT_REDESIGN` even if metadata/commands otherwise work.

- [ ] **Step 3: Update state documents truthfully**

For `ACCEPT_TRANSPORT`, record that only the transport mechanism is accepted for production design; Media UI/gestures/P1 remain unimplemented. Promote the next plan to production `MediaProvider` + `SystemMediaBridge` boundary.

For `REJECT_TRANSPORT`, record the exact failed security/compatibility reason and keep shipped NotchHub unchanged.

For `NEEDS_TRANSPORT_REDESIGN`, record the missing capability/lifecycle requirement and design the smallest next transport experiment rather than weakening constraints.

- [ ] **Step 4: Final commit**

```bash
git add docs/PROJECT_STATE.md docs/ROADMAP.md docs/TESTING.md CHANGELOG.md
git commit -m "docs: record universal media bridge probe result"
```

---

## Plan Self-Review

### Spec coverage

- Universal system Now Playing scope: covered by hardware matrix.
- Isolated private MediaRemote boundary: probed only in development tooling; no `Sources/**` exposure.
- Event-driven behavior/no periodic track polling: `stream --no-diff --micros` is mandatory.
- Sandbox/Hardened Runtime: exact current entitlement and runtime flags are mandatory probe conditions.
- Fail-closed lifecycle: nonzero exit/no restart-loop/clean teardown are explicit gates.
- Metadata/artwork validation: bounded parser tests cover them without durable track data.
- Fixed command allowlist: explicit mapping and no arbitrary command passthrough.
- Capability-driven requirement: `NH-MEDIA-BRIDGE-016` can block acceptance; unsupported/unknown is never guessed.
- Multi-source target hardware: Yandex Music, Apple Music, Spotify, browser, independent player are mandatory.
- Privacy: persisted reports exclude title/artist/album/artwork/raw payload.
- Performance: diagnostic parent/child measurements and 10-minute stability precede production adoption; full P1 remains after complete media slice.
- Shipping isolation: package/release policy keeps probe and third-party assets out of `NotchHub.app`.

### Placeholder scan

The plan intentionally contains no `TBD`, `TODO`, or implementation placeholders. A failed capability surface has a defined outcome (`NEEDS_TRANSPORT_REDESIGN`) rather than an unspecified follow-up.

### Type consistency

The plan uses one development module name (`MediaBridgeProbeCore`), one executable (`MediaBridgeProbe`), one payload decoder (`ProbePayloadDecoder`), one command type (`ProbeMediaCommand`), one process owner (`ProbeProcessController`), and one evidence model (`ProbeReport`) consistently across tasks.

## Definition of Done for This Plan

This plan is complete only when either:

- the exact sandboxed/hardened target-Mac probe produces sufficient evidence to mark `ACCEPT_TRANSPORT`, **or**
- the transport is explicitly rejected/redesigned with the shipping NotchHub runtime unchanged.

A working metadata demo by itself is not completion. No Media UI or gesture work begins until the transport decision is recorded.