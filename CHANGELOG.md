# Changelog

All notable changes to NotchHub are documented here. The active version is stored in `VERSION`; published tags/releases are immutable.

## [Unreleased]

## [0.4.0] - 2026-09-03

Published as `v0.4.0` — Personal build. See `docs/releases/v0.4.0.md` for the full release notes. Everything below was implemented, automated-tested, physically accepted and merged since `v0.3.0`.

### Artwork morphing — `matchedGeometryEffect` cross-state morph

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.4.0`**.

The last of the three ideas the M6.8 competitive review deferred (the compact live equalizer shipped as M6.8, marquee text as M6.9, album-art color tinting as M6.11 in `v0.3.0`). `MediaNotchRootView` gained a shared `@Namespace` applied via `.matchedGeometryEffect(id: "media.artwork", in:)` at the single `artwork(_:size:)` definition site, so SwiftUI treats the artwork image as the same view across Compact/Peek/Expanded and interpolates its frame/position instead of cross-fading a size "pop". The morph is driven by an explicit `.animation(value: panelModel.contentPresentation)` kept in sync with the panel's own AppKit resize duration — `notchStandardAnimationDuration`/`notchAnimationDuration(reduceMotion:)` (`Sources/NotchHubCore/Notch/NotchAnimationDurationProvider.swift`) became `public` for this cross-module reuse — and is disabled entirely under Reduce Motion, matching the AppKit side's existing zero-duration behavior there. No new pure/testable calculator module was needed; coverage is a RED-first source-scanning policy test (`ArtworkMorphingPolicyTests`) locking the shared namespace, the single `matchedGeometryEffect` call site, the explicit animation wiring, and the absence of any new timer primitive. Design/invariants: `docs/superpowers/specs/2026-09-03-artwork-morphing-design.md`.

Physical acceptance on exact `Mac16,8`/macOS `26.6.x` — all 8 checklist items PASS: smooth cross-state morphing via explicit tap; correct interactive drag expand/collapse including a cancelled mid-drag; no jitter across rapid repeated transitions; the morph doesn't fight the physical LEFT/RIGHT swipe gesture-visual offset; track-change tinting/cross-fade unaffected; Reduce Motion pops exactly as before; no hover/gesture jank; clean post-Quit teardown. Full evidence: `docs/testing/ARTWORK_MORPHING_ACCEPTANCE.md`. PR #75 squash-merged as `8ac7a44cc0565893d363e917807a6dcbac38c3cb`.

### Fullscreen / Spaces hardening

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.4.0`**.

Closes the last item M1's active-display/multi-monitor migration (`v0.2.0`) deliberately deferred: fullscreen-app and Spaces-switch behavior. `NotchPanelController.configurePanel()` already implemented Apple's documented recipe for a utility panel that survives both (`.canJoinAllSpaces`, `.fullScreenAuxiliary`, `.stationary`, `.level = .statusBar`, `styleMask [.borderless, .nonactivatingPanel]`) unchanged since M1's original panel foundation, but nothing asserted it and neither scenario had ever been physically exercised — a real coverage gap where a future refactor could silently regress fullscreen/Spaces support with every existing test still green. New `NotchPanelSpacesFullscreenPolicyTests` constructs the real `NotchPanelController` and asserts `collectionBehavior`/`level`/`hidesOnDeactivate`/`styleMask` on the actual `NSPanel` object — a real unit test rather than source-scanning, since `NotchHubCore` (unlike the SwiftUI-only `NotchHubApp`) is fully unit-tested. `panel` changed from `private` to internal module visibility so `@testable import` can read it, matching this codebase's existing `@testable` convention; no new public API surface. Design/invariants: `docs/superpowers/specs/2026-09-03-fullscreen-spaces-notchless-hardening-design.md`.

No production behavior changed and physical testing found no real defect — the existing recipe already held. Physical acceptance on exact `Mac16,8`/macOS `26.6.x` — all 7 checklist items PASS: Compact stayed visible and hover-to-Peek/click-to-Expanded kept working with another app fullscreen on the notch display; Space switches across Compact/Peek/Expanded and mid-interaction never lost, duplicated, or mispositioned the panel; no new permission prompt; no jank; clean post-Quit teardown. Full evidence: `docs/testing/FULLSCREEN_SPACES_HARDENING_ACCEPTANCE.md`. PR #77 squash-merged as `273126e54f93cd806eaf2be9fa5191f47092d416`.

## [0.3.0] - 2026-09-02

Published as `v0.3.0` — Personal build. See `docs/releases/v0.3.0.md` for the full release notes. Everything below was implemented, automated-tested, physically accepted and merged since `v0.2.0`.

### M6.11 — album-art color tinting

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.3.0`**.

Deferred since M6.8's competitive review (`TheBoredTeam/boring.notch`, NotchNook): the panel background was flat `Color.black` in every presentation state. A new pure `MediaArtworkTintCalculator` (`Sources/NotchHubMediaCore/MediaArtworkTintCalculator.swift`) clamps a raw sampled artwork color into a subtle, legible tint (saturation capped at `0.55`, brightness kept within `0.05...0.34`, defensive against non-finite input); a new `MediaArtworkTintSampler` (`Sources/NotchHubMediaCore/MediaArtworkTintSampler.swift`) decodes artwork `Data` via `CoreGraphics`/`ImageIO` only (no `AppKit`), drawing it into a 1x1-pixel context for a fast average-color sample, then converts to HSB with a pure RGB->HSB conversion. Both live in `NotchHubMediaCore` rather than `NotchHubApp` specifically so they get real behavioral unit tests (`Tests/NotchHubMediaCoreTests/MediaArtworkTintCalculatorTests.swift`, `MediaArtworkTintSamplerTests.swift`, the latter synthesizing solid-color PNGs in memory) rather than the source-scanning-only coverage every `NotchHubApp`-only SwiftUI file is limited to (`NotchHubApp` has no test target at all).

`MediaNotchRootView.mediaContent(_:)`'s shared `.background(Color.black)` (covering Compact, Peek and Expanded alike) becomes `.background(artworkTintColor)`, recomputed via `.onChange(of: presentation.artworkData, initial: true)` and crossfaded with a declarative `.animation(.easeInOut(duration: 0.4), value:)` — no new `Timer`/`CADisplayLink`/polling primitive, so no `performance/reviewed-runtime-timers.json` entry is needed. No artwork (or a fully transparent/undecodable image) falls back to `MediaArtworkTintCalculator.fallback`, which converts to exactly `Color(hue: 0, saturation: 0, brightness: 0)` — identical to the pre-slice flat black background.

Design/invariants: `docs/superpowers/specs/2026-08-24-album-art-color-tinting-design.md`.

Verified locally before any CI push: `swift build`, `swift build -Xswiftc -warnings-as-errors`, `swift format lint --recursive --strict`, `scripts/performance_policy.py audit Sources`, `scripts/security-audit.sh`, `plutil -lint`, and `bash -n scripts/*.sh` all pass on this authoring machine's real Swift 6.3.3/Xcode 26.6 toolchain (macOS 26.6.2) — the first slice in this project's history authored with local toolchain access. The sampler/calculator logic itself was also exercised directly against real decoded solid-color PNGs via a temporary scratch executable (not committed) before the permanent tests were written, confirming e.g. pure red/green/blue artwork samples to the expected hue and that saturation/brightness clamp correctly. The `Testing` framework itself is unavailable in this authoring environment (Command Line Tools only, no full Xcode.app), so `swift test` could not be run locally; canonical CI remains the first real execution of the new test files, matching this project's established precedent (e.g. M6.10's `AppQuitMenuPolicyTests`).

Canonical CI passed 3/3 GREEN on candidate `984c31fcf8387f12f50bab15711a967975d015d2` (run `32696922857`), including the first real execution of `MediaArtworkTintCalculatorTests`/`MediaArtworkTintSamplerTests`. Real measured artifact sizes from that run (`appSizeBytes=949791`, `dmgSizeBytes=612975`, `executableSizeBytes=647584`) became the evidence for a new `performance/m6-11-album-art-tint-size-budget.json`, which replaced `m6-10-discoverable-quit-menu-size-budget.json` as the active release size-budget reference in `ci.yml` and in the four/five hardcoded Swift and Python policy-test assertions of the active budget filename, matching the M6.9/M6.10 precedent of deriving the allowance from a real interim candidate's measured sizes rather than the eventual squash-merge SHA.

Physical acceptance on exact `Mac16,8`/macOS `26.6.x` — album-art tint checklist PASS across multiple tracks/artwork colors, crossfade smooth, no-artwork fallback unchanged, no jank; the two acceptance-found defects below fixed and re-verified in the same PR. PR #69 squash-merged as `ad572cea5787ac8487308855f517395c8a3a23b2`.

### Physical acceptance found two real, pre-existing defects (unrelated to the tint itself)

Physical acceptance of the tint checklist passed, but surfaced two real, pre-existing UI defects — neither caused by the tinting change — fixed in this same PR before merge:

1. **Peek title/artist text partially hidden behind the physical hardware notch.** `peekMediaContent` used a hardcoded `.padding(.top, 28)` regardless of real notch geometry, while `expandedMediaContent` already correctly derives its top inset from `layoutModel.currentLayout.expandedContentTopInset`. On the real target Mac16,8, the physical notch height (`safeAreaTop`, ~37pt) exceeds that hardcoded 28pt, and Peek content is horizontally centered on the notch the same way Compact is, so the top slice of the title/artist row rendered under the physically opaque notch area — genuinely unrenderable pixels, not just a cosmetic overlap. Fixed by adding `NotchLayout.peekContentTopInset` (`hasHardwareNotch ? compactFrame.height + 4 : 28`, mirroring `expandedContentTopInset`'s reasoning with a tighter buffer for Peek's more compact layout) and using it in place of the hardcoded constant. New tests: `peekContentTopInsetAlwaysClearsThePhysicallyOpaqueNotchHeight` plus updated assertions in the existing hardware/no-notch `NotchGeometryTests`.

2. **Seek-to-tap visibly reset the position to (near) zero before animating to the clicked spot.** `MediaTimelineTicker.apply(presentation:)` unconditionally re-anchored extrapolation from whatever authoritative snapshot it was given. `MediaGestureSession.commitSeek` dispatches the transport seek command asynchronously; a system Now Playing snapshot captured *before* that command took effect can arrive concurrently and race the confirmation, clobbering the `applyOptimisticSeek(to:)` anchor with a stale pre-seek (or transiently near-zero) position — SwiftUI's `ProgressView` then visibly interpolates from that stale value back up to the real position once the genuine post-seek update lands, reproducing exactly the reported "resets to zero, then animates to the clicked position." Fixed by giving `MediaTimelineTicker` a bounded pending-seek guard: after `applyOptimisticSeek(to:)`, `apply(presentation:)` ignores snapshots whose position isn't within `1.0s` of the pending target, until either a confirming snapshot arrives or a `2.0s` timeout safety net elapses (so a seek whose confirmation never precisely lands doesn't suppress authoritative updates forever); a track/session change (`apply(presentation: nil)`) clears the pending seek immediately. New tests: `staleSnapshotArrivingRightAfterAnOptimisticSeekDoesNotRevertTheAnchor`, `confirmingSnapshotNearTheSeekTargetReanchorsNormallyAgain`, `pendingSeekSuppressionExpiresAfterTimeoutSoUpdatesAreNotStuckForever`, `sessionLossWhileASeekIsPendingClearsThePendingSeekToo`.

Both fixes were also exercised directly against real Swift execution via temporary, uncommitted scratch executables on this authoring machine's local toolchain before the permanent tests were written (`swift test` itself remains unavailable locally; canonical CI is the first real execution of the new/updated test files).

### Panel positioning — cold-launch Peek could render mispositioned until the next transition

Status: **IMPLEMENTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.3.0`**.

Real defect found during ad-hoc physical testing on a cold launch: the very first time Peek appeared, the panel rendered visibly shifted right of the physical hardware notch, with an odd opening slide; any later transition (a normal hover/collapse cycle) silently self-corrected it, which made it look like "interaction fixes it" — a coincidence, not a cause.

Root cause, found via targeted temporary instrumentation (`FileHandle.standardError` frame dumps at each panel-frame call site, removed before commit) rather than guesswork: `NotchPanelController` constructs its `NSPanel` at the un-extended `compactFrame` (e.g. width `220`, origin `x=790`). As soon as a media session is detected, `AppDelegate` calls `setCompactHorizontalExtension(36)`, which correctly updates `NotchPanelLayoutModel`'s `compactFrame` to a *symmetrically* widened, recentered rect (`width=292`, `origin x=754`) — but `NotchPanelTransitionCoordinator.animationPolicyDidChange(layout:)`'s settled-phase branch (`.compact`/`.peek`/`.expanded`) was a bare `break`: it never re-applied the panel's actual on-screen frame to match. Confirmed live via `NSWindow.didResizeNotification`: AppKit itself was independently resizing the panel's *width* to `292` (matching SwiftUI's new media content) while leaving its *origin* at the stale `790` — an asymmetric, off-center resize the settled-phase no-op then never corrected. The very next real transition (hover to Peek) computed its endpoint from the correctly-updated *model* layout, so it looked centered — but animated from the AppKit-corrupted stale `panel.frame` as its start point, producing the reported wrong-position-then-slide.

Fix: `animationPolicyDidChange`'s settled-phase cases now reconcile the panel to the current layout's exact endpoint via the existing `applySettledPresentation` primitive (instant, no animation, no spurious settlement callback) instead of trusting the frame is already correct. This is a general correctness fix, not specific to any one root cause of staleness — it also covers the panel's `NotchPanelController.init()`-time base layout being briefly wrong on a cold launch before `NSScreen`'s notch-detection auxiliary rects settle (a second, narrower defensive fix also added: a single one-shot `DispatchQueue.main.async` re-check right after construction, reusing the same tested display-migration path — not a repeating timer/poll).

New tests: `NotchPanelTransitionPolicyChangeTests.policyChangeWhileSettledReconcilesFrameWithoutAnimatingOrPublishingSettlement`; `NotchDisplayMigrationTests.controllerRechecksTopologyOnceOnColdLaunchInsteadOfTrustingFirstScreenRead`.

Physical acceptance on exact `Mac16,8`/macOS `26.6.x`: reproduced the mispositioned cold-launch Peek on two separate cold-launch attempts before the fix (confirmed not browser-specific — a cold launch with Yandex Music reproduced identically); confirmed the corrected build renders Peek in the exact correct position on the very first hover after a cold launch — verified live by the product owner. PR #71 squash-merged as `634fc5629218209a99649d8c1fc22981954fa4d4`.

### Media transport — Now Playing sessions without title metadata were silently dropped

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.3.0`**.

Real-world defect found during ad-hoc physical testing (unrelated to any single milestone in flight): playing a movie in a browser tab that never sets `navigator.mediaSession.metadata` (title/artist/album) made NotchHub show nothing at all — Compact stayed flat black, no Peek — even though the OS's own Control Center Now Playing widget correctly showed the session with playback controls and just the app's name as a fallback label.

Root cause was in the vendored, patched `MediaRemoteAdapter` (`Tools/MediaBridgeProbe/patches/mediaremote-adapter-capabilities.patch`, applied over pinned upstream commit `3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`), not in NotchHub's Swift code: `src/adapter/stream.m`'s `directHandle()` gates *all* payload emission on `allMandatoryPayloadKeysSet(liveData)`, and upstream's `keys.m` lists `kMRATitle` as mandatory alongside the process identifier and playing state. When a session has an active PID and a real playing state but an empty title, the adapter silently emitted `{"type":"data","diff":false,"payload":{}}` — indistinguishable from genuinely nothing playing — discarding the `bundleIdentifier`/`playing` state it had already successfully collected. Confirmed directly by invoking the built `mediaremote-adapter.pl`/`MediaRemoteAdapter.framework` standalone against the live session before and after the fix. The Swift pipeline (`MediaRemoteWire.swift`, `ShippingMediaPresentationModel.swift`) was already architecturally ready for a title-less-but-active session — `normalizedText` already converts an empty/whitespace title to `nil` and `sourceDisplayName` already falls back to the bundle identifier (covered by the pre-existing `whitespaceMetadataIsOmittedWithoutFabrication` test) — it simply never received one, because the adapter withheld it.

Fix: extended the patch with a `src/adapter/keys.m` hunk dropping `kMRATitle` from `mandatoryPayloadKeys()`, so a session is surfaced as soon as its process identifier and playing state are known, matching the more permissive fallback the system's own Now Playing widget already uses. New test: `MediaRemoteWireTests.activeSessionWithoutTitleStillDecodes`, confirming the wire decoder itself already tolerated this shape (an empty, not omitted, title/artist/album) before the adapter ever started sending it.

Changing the patch changes its SHA-256, which `ShippingMediaBundlePaths.pinnedAdapterPatchSHA256` deliberately pins as a supply-chain integrity check — `ShippingMediaRuntime` refuses to start the adapter at all if the built framework's patch hash doesn't match, which is exactly what happened on the first rebuild after the patch changed (correct, intended fail-closed behavior, not a new bug) until the pinned constant was updated to match, in lockstep, in all four places that hardcode it: `Sources/NotchHubMediaCore/ShippingMediaRuntime.swift`, `Tests/NotchHubMediaCoreTests/ShippingMediaBundlePathsTests.swift`, `scripts/shipping_media_acceptance.py`, `scripts/production_media_transport_acceptance.py`.

Physical acceptance on exact `Mac16,8`/macOS `26.6.x`: confirmed the adapter emitted only `payload: {}` for an actively playing browser video session before the fix (matching the OS's own Control Center widget, which showed the session correctly); confirmed the same live session decoded correctly (`bundleIdentifier`, `playing`, `elapsedTimeMicros`, `durationMicros`) after patching; confirmed the rebuilt app was refused from starting the media runtime at all until the pinned hash was corrected (`resolveValidated` throwing `invalidProvenance`, silently swallowed by its `try?` call site — no child adapter process, no crash, no log output, by design given this project's no-production-logging policy); confirmed the rebuilt app with the corrected hash spawns the adapter and the notch now shows the browser session — verified live by the product owner. PR #70 squash-merged as `ed215290100becc1a54e46fec0b209682b539d32`.

## [0.2.0] - 2026-08-23

Published as `v0.2.0` — Personal build. See `docs/releases/v0.2.0.md` for the full release notes. Everything below was implemented, automated-tested, physically accepted (or explicitly waived by the product owner, noted individually) and merged since `v0.1.0`.

### M6.10 — discoverable normal-quit path

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.2.0`**.

M6.7's physical acceptance found that Force Quit was the only way to quit NotchHub (`LSUIElement`/`.accessory` means no Dock icon, no app menu bar, Cmd+Q is a no-op), and Force Quit's SIGKILL bypasses `applicationWillTerminate`'s existing, already-tested media-runtime cleanup — leaving an orphaned `mediaremote-adapter.pl` process. `AppDelegate` now installs a minimal `NSStatusItem` (stock SF Symbol icon, no custom asset) with a static menu: a disabled "NotchHub" title and a "Quit NotchHub" action wired to `#selector(NSApplication.terminate(_:))`, routing through the existing cleanup path rather than adding new termination logic. No new entitlement, permission, or timer — `Resources/NotchHub.entitlements` is unchanged (still exactly `com.apple.security.app-sandbox`), activation policy stays `.accessory`.

Design/invariants: `docs/superpowers/specs/2026-08-23-discoverable-quit-menu-design.md`.

PR #64 squash-merged as `b911746077092bfffd60d93cd8072c268cb1df94` after canonical CI GREEN 3/3 (`swift test` confirmed the new `AppQuitMenuPolicyTests` GREEN; the authoring environment has no local Xcode/`swift-testing` toolchain, so this was the first real execution) and the release size gate against real evidence in `performance/m6-10-discoverable-quit-menu-size-budget.json`. Physical acceptance on the product owner's own Mac — all 7 checklist items PASS: status item appears, Quit menu works, post-quit `pgrep -lf 'mediaremote-adapter\.pl'` empty (the actual defect fixed), no Dock icon, no new permission prompt, notch panel unaffected. Full evidence: `docs/testing/M6_10_DISCOVERABLE_QUIT_ACCEPTANCE.md`.

### P1 — target-Mac whole-app resource audit

Status: **ACCEPTED — COMPLETE TARGET-MAC EVIDENCE / DIRECT GATES PASS / RELEASED — `v0.2.0`**.

P1 began with PR #36, which established the fail-closed target-Mac measurement/evidence foundation as historical tooling source `5cd9a2a47d87a433155f53b3aa0510000f2fce85`. The evidence contract separates measured runtime provenance from tooling provenance, freezes Idle/Hover/Stability timing and sample counts, stores only aggregate process evidence, uses a closed privacy-safe manual evidence surface and intentionally avoids privileged automatic collectors or new app permissions.

#### Tooling hardening

PR #44 corrected the platform validator after the physical target advanced to macOS `26.6.1`. Exact model remains `Mac16,8`; only canonical `26.6` / `26.6.x` versions are accepted; the exact patch is preserved and must agree across Idle/Hover/Stability/manual evidence. It squash-merged as `99a75dbe0664120a572bd8229d4fe461790ee07b`.

The first physical collection attempt then exposed locale-dependent `/bin/ps` output. PR #47 made sampling deterministic by applying `LC_ALL=C` only to the sampler subprocesses while preserving the parent/measured-app environment and strict parser. RED head `63af71dc9a614837fa2fe67f31d0cd0b5e3c0aa9` failed the intended locale regression; GREEN head `5e1d870f67972d5799c34e77acc1a8c1f4de9f7b` passed CI #1288 3/3 GREEN; squash merge `28965561f81c71ea58a352301fbe08554c644044` became the locale-stable sampler provenance.

PR #49 then extended the closed evidence contract with the accepted qualitative `manual-visual-compositor` fallback while retaining `instruments-core-animation` as preferred when available. It merged as final accepted P1 tooling/evidence checkout `fc7562b0799faa4dd80e8c47263354a8bd16bd6a`. `perf-baseline.py` itself remained unchanged from the locale-stable sampler ancestry.

#### Runtime defects found by physical P1 acceptance

P1 target-Mac testing found real behavior defects rather than merely resource numbers, and each candidate was rejected until physically corrected.

1. The earlier hardware-notch launch regression had already been repaired by PR #40, merged as `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`.
2. Manual compositor acceptance on that runtime exposed an expanded-size panel displaying compact content and remaining stuck. PR #51 added exact current-generation frame/corner reconciliation before logical settlement. RED `7e06d24d0b89f4c413c180882ec9d628384e9bce`; physically accepted GREEN head `329b867595b6ffe127fa3552f51bef8412865f37`; squash merge `1f56c3e5da8a46509a3472a52da12a1abfb16a8c`. Accepted head and merge share Git tree `8aebcc6db915b77e30c51b1d4fc45e4c3b895bb1`.
3. Activity Monitor then showed that the existing persistent global `.mouseMoved` monitor amplified unrelated external-monitor pointer motion from about `3` to `111` Idle Wake Ups while the app was otherwise inactive. PR #53 replaced persistent global observation with a bounded escape monitor tied to an actual local/tracking interaction.

The first PR #53 candidate that removed global observation entirely was rejected because rapid pointer exit could leave a large black Peek panel stuck. A second one-shot candidate was also rejected because it removed the global fallback on the first inside global sample before the true outside escape arrived. Final head `bddd0503d972c652752a0e1463f3495685accc83` retained the bounded monitor while samples remained inside the current interactive region and removed it only after the actual outside sample was delivered to the existing interaction state machine.

Final PR #53 physical acceptance on Mac16,8/macOS 26.6.2:

- rapid exit 30/30 PASS, including immediate exits and migration to the external monitor;
- normal compositor cycles 10/10 PASS;
- reversal recovery PASS;
- freeze/stuck panel NOT OBSERVED;
- frame/corner/flicker anomalies NONE;
- hardware-notch binding PASS;
- same-candidate Activity Monitor A/B: Idle Wake Ups `2` stationary and `2` during unrelated pointer motion on the external monitor, eliminating the prior `3 -> 111` amplification.

PR #53 squash-merged as final measured runtime `11dad43364a969f4d5f8c1a92e1281b5b41c8a74`. The physically accepted head and squash merge share exact Git tree `8f0a7fee0b02599520a5776133f51c1215da7d98`.

#### 2026-08-21 — final coherent P1 acceptance

The complete final bundle was recollected after the runtime fixes on one exact platform/tooling provenance:

- measured runtime `11dad43364a969f4d5f8c1a92e1281b5b41c8a74`;
- tooling `fc7562b0799faa4dd80e8c47263354a8bd16bd6a`;
- exact target `Mac16,8 / macOS 26.6.2`;
- hardware-notch binding PASS;
- exactly one measured NotchHub process from the built app with embedded source SHA matching the runtime.

Reviewed machine evidence:

- **Idle** — CPU median/max `0.0/0.0%`; RSS median/max `58,432/58,496 KiB`; thread median/max `3/6`. Direct Idle thread gate `<=6` PASS.
- **Hover** — CPU median/max `6.8/32.3%`; RSS median/max `75,936/76,784 KiB`; thread median/max `6/6`. CPU median steady-state target `<=8.0%` PASS and thread gate `<=9` PASS. The one-second CPU max remains diagnostic under the accepted policy and is not a standalone portable cross-session gate.
- **Stability** — CPU median/max `0.0/0.0%`; RSS start/end `58,816 -> 54,848 KiB`, delta `-3,968 KiB`; thread start/end `3 -> 3`, max `5`, delta `0`. RSS growth, thread max and thread-delta direct gates PASS.

Reviewed manual evidence:

- Activity Monitor Idle Wake Ups, 60 s: `0.0/s`, explicitly reviewed with no anomaly;
- Activity Monitor Energy fallback, 60 s: `no-anomaly-observed`; Energy Impact `0.0`, App Nap `No`, Preventing Sleep `No`; displayed 12-hour value `0.29` retained only as diagnostic historical context;
- manual visual compositor: exactly 10 cycles, `no-anomaly-observed`; reversal recovery PASS; no freeze/stuck panel or frame/corner/flicker anomaly.

The closed-schema manual evidence and normalized `p1-target-resource-evidence.json` validated successfully with `reviewRequired=false`. Final direct-gate review returned PASS for Idle threads, Hover CPU median/threads, Stability RSS growth/threads/thread delta and manual review status.

Issue #38 was closed completed after review. Earlier 26.6.1, pre-settlement and pre-pointer-fix evidence remains immutable diagnostic history and is not mixed into this accepted bundle.

No speculative runtime optimization is justified by the accepted evidence. P1 acceptance is not a release event; published release remains `v0.1.0`.

### M1 — event-driven active-display / multi-monitor migration

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.2.0`**.

PR #56 adds event-driven display-topology migration: observes `NSApplication.didChangeScreenParametersNotification`, resolves `NSScreen.screens` fresh on topology change while preserving hardware-notch-first selection and the accepted `NSScreen.main`/first-screen fallback, migrates stable Compact/Peek/Expanded endpoints to the newly resolved display through one shared `NotchPanelLayoutModel`, retargets in-flight programmatic and interactive transitions by generation so stale animation completions cannot move the new screen endpoint, cancels interrupted interactive transitions back to their origin presentation, reconciles the physical settled frame/corner synchronously across migration, and resets the bounded pointer-escape monitor. No new dependency, permission, entitlement, networking, telemetry, timer, display link or persistent global input monitoring was added.

Automated verification: exact candidate `dd945dc3ca009f8d9429ad044d50a01a2ea1bb62`; CI #1344 / run `32527603794` 3/3 GREEN across `macOS 26 compatibility`, `macOS UI regression` (including external-app XCUI smoke) and `Build, test and package`; full coverage-instrumented Swift suite passed 392 tests; formatting, acceptance-traceability, source performance policy, security baseline, warnings-as-errors builds, shipping-media preflight, codesign, Hardened Runtime, exact sandbox-only entitlement, system-library/provenance checks, DMG verification and the active `performance/m1-active-display-migration-size-budget.json` size gate all passed.

Physical acceptance on exact `Mac16,8 / macOS 26.6.2`, built-in hardware-notch display plus an external monitor (2560x1440) connected — **11/11 PASS**: Compact/Peek/Expanded connect-disconnect-reconfigure (including media continuity in Expanded); interruption of programmatic Compact->Expanded and Expanded->Compact transitions with no frozen intermediate state; interruption of partial interactive expansion and collapse gestures, cancelling cleanly without unintended haptic/commit; no-notch first-screen fallback; 5-10x repeated migration cycles with no jitter, duplicate observers or accumulating lag; post-migration pointer/hover scoped only to the current hardware-notch screen with correct rapid-exit Peek collapse; and no new macOS permission prompts across the run. Post-Quit `pgrep -lf 'mediaremote-adapter\.pl' || true` empty.

PR #56 squash-merged as `c7d2bdb9cae744d439d240f22acd14140bacedd3`; issue #55 closed completed. Design/invariants: `docs/superpowers/specs/2026-08-21-active-display-multi-monitor-migration-design.md`. Included in `v0.2.0`.

### M6.7 — live media timeline and live Compact display

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.2.0`**.

PR #58 deliberately reverses two prior accepted invariants, both explicitly decided by the product owner and recorded before implementation in `docs/superpowers/specs/2026-08-22-live-media-timeline-and-compact-design.md`:

1. **Always-on shipping media runtime.** `ShippingMediaRuntime.start()` now runs once at launch and `stop()` once at Quit, instead of being scoped to settled `.expanded`. Compact's existing artwork/play-pause icon becomes live for free — already reactively bound to the presentation model — reflecting a track change, pause or play/pause toggle performed outside NotchHub without needing to re-expand.
2. **One narrowly-scoped, reviewed, bounded-lifecycle timer.** `MediaTimelineTicker` extrapolates the displayed playback position between authoritative system events at ~300ms, armed only while the settled panel presentation is Peek or Expanded and playback is active, torn down on collapse, pause, session loss or quit; never runs in Compact or Idle. `scripts/performance_policy.py`'s runtime audit previously had no exception mechanism at all for its blanket Timer/polling scan; this PR adds a fail-closed, schema-validated reviewed-exception manifest (`performance/reviewed-runtime-timers.json`) scoped to exactly this one `(file, rule)` pair, covered by its own unit tests, rather than working around the audit with a different API.

A real pre-existing hazard was found and fixed along the way: `MediaPeekSession.handleSettledPeek()` started its bounded one-shot probe unconditionally, which was safe before M6.7 (Compact/Peek never had a live authoritative presentation to protect) but could clobber the runtime's already-good data with the probe's `.noSession` result once the runtime became always-active — reproduced by a hover-then-click sequence erasing title/artist/artwork moments before Expanded rendered. Fixed by skipping the probe entirely when a live presentation already exists.

Automated verification: canonical CI (`macOS 26 compatibility`, `macOS UI regression`, `Build, test and package`) 3/3 GREEN on exact candidate `3cee40c9650d50254f25e633a3e0e5163124df07`; `MediaTimelineTickerTests` (fully clock/timer-injected, no real `Timer`/run loop) cover bounded arm/disarm conditions, extrapolation and duration clamping, re-anchoring without drift, and optimistic seek re-anchoring; `scripts/performance_policy.py`'s reviewed-exception mechanism has its own fail-closed unit tests; the active `performance/m6-7-live-media-timeline-and-compact-size-budget.json` size gate passed.

Physical acceptance on exact `Mac16,8 / macOS 26.6.2` — **7/7 PASS**: live-ticking timeline in Peek and in Expanded while playing; exact freeze on pause with no drift and correct resume; Compact reflecting a track change/pause/play-pause toggle performed outside NotchHub without re-expanding; `ps` CPU sampling across 5 samples while settled Compact showed `0.0%` (ticker correctly torn down); post-Quit `pgrep -lf 'mediaremote-adapter\.pl'` empty under a normal quit; and a fresh P1-style Idle/Hover/Stability resource bundle, required because Idle no longer has a zero-adapter baseline —

| Scenario | CPU median/max | RSS median/max (KiB) | Thread median/max |
|---|---|---|---|
| Idle | 0.0% / 2.4% | 73,648 / 73,776 | 4 / 5 |
| Hover | 0.0% / 18.0% | 71,832 / 72,128 | 3 / 5 |
| Stability | 0.0% / 0.0% | 64,160 / 71,648 | 3 / 7 |

with Stability RSS `71,648 -> 59,904` KiB (delta `-11,744`, a decrease) and threads `3 -> 3` (delta `0`). All direct gates PASS against the previously accepted thresholds (Idle threadMax `<=6`; Hover CPU median `<=8.0%`, threadMax `<=9`; Stability RSS delta `<=+8192`, threadMax `<=9`, thread delta `<=+2`) despite the adapter now running continuously. This bundle supersedes the prior "zero-adapter compact" Idle baseline in `docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md`, which remains immutable historical evidence for the source it measured.

Physical acceptance also confirmed Force Quit (Activity Monitor) leaves an orphaned `mediaremote-adapter.pl` process — expected for any app with a child process under SIGKILL, not a regression — and surfaced a separate, non-blocking follow-up: NotchHub has no user-discoverable normal-quit path today (no Dock icon, no Quit menu item, Cmd+Q is a no-op).

PR #58 squash-merged as `bd48037baff85d8eb3354fbf3792c5db016ff4a1`. Full evidence: `docs/testing/M6_7_LIVE_MEDIA_TIMELINE_AND_COMPACT_ACCEPTANCE.md`. Included in `v0.2.0`.

### M6.8 — compact live equalizer

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.2.0`**.

Competitive review of `TheBoredTeam/boring.notch` (open source, same `MediaRemoteAdapter`) and NotchNook found one concrete, low-risk UX improvement worth borrowing: both replace a static play/pause glyph in Compact with a small animated equalizer/spectrum that visibly pulses while something is playing. PR #60 adds `MediaCompactEqualizerView`, replacing `MediaNotchRootView.compactMediaContent`'s static SF Symbol with 3 bars driven by SwiftUI's `PhaseAnimator`, armed only while `playbackState == .playing`, settling to a flat static pose on pause. No timer primitive, no new `performance/reviewed-runtime-timers.json` entry needed — confirmed by `scripts/performance_policy.py audit Sources` staying green.

Physical acceptance on exact `Mac16,8 / macOS 26.6.2` — all items PASS: bars visibly animate out of phase while playing; settle flat on pause and restart correctly on resume; `ps` CPU sampling across 5 samples while settled Compact with media playing showed `0.0%`; no jank introduced to existing hover-for-Peek/click-for-Expanded interaction; clean post-Quit process teardown under a normal quit.

A real bug was found and fixed during acceptance: the initial implementation drove the bars with `.animation(...repeatForever...)`, which froze mid-animation after the horizontal next/previous swipe gesture — the swipe's own `withAnimation` transaction interrupted the bars' implicit repeating loop, a documented SwiftUI gotcha, only recovering after expand+collapse force-recreated the view. Fixed by switching to `PhaseAnimator`, which owns its own animation timeline and is not vulnerable to an ancestor's unrelated explicit animation transaction — the documented reason Apple introduced it as the modern replacement for perpetual `repeatForever` loops. Re-verified: repeated next/previous swipes no longer freeze the equalizer.

PR #60 squash-merged as `4cbb01d7d5f57f26c40162c8149faf27691c2e06`. Full evidence: `docs/testing/M6_8_COMPACT_LIVE_EQUALIZER_ACCEPTANCE.md`. Included in `v0.2.0`. Other competitive-review ideas surfaced but explicitly deferred: album-art color tinting, `matchedGeometryEffect` cross-state artwork morphing, marquee text for overflowing titles.

### M6.9 — media marquee text for overflowing titles

Status: **IMPLEMENTED / AUTOMATED-TESTED / CANONICAL CI GREEN / MERGED / PHYSICAL ACCEPTANCE EXPLICITLY WAIVED / RELEASED — `v0.2.0`**.

Deferred from M6.8's competitive review: Peek and Expanded title/artist/album previously hard-truncated with `.lineLimit(1)` + `.truncationMode(.tail)`, silently hiding overflow. A new pure `MediaMarqueeCalculator` (`Sources/NotchHubMediaCore/MediaMarqueeCalculator.swift`) decides whether content overflows its available width and how long one scroll cycle takes at a fixed speed; a new `MediaMarqueeText` view (`Sources/NotchHubApp/MediaMarqueeText.swift`) renders exactly today's static truncated text when content fits (or measurement hasn't completed), and otherwise scrolls two duplicated copies of the content in a continuous conveyor loop driven by SwiftUI's `PhaseAnimator` — the same self-contained, ancestor-transaction-immune mechanism `MediaCompactEqualizerView` uses, not a `Timer`/`CADisplayLink`/`TimelineView`. `accessibilityReduceMotion` gates straight to the static fallback. All 5 title/artist/album call sites in `MediaNotchRootView.peekMediaContent`/`expandedMediaContent` were swapped; Compact is unaffected (it never renders title/artist text). No new `performance/reviewed-runtime-timers.json` entry needed — confirmed by `scripts/performance_policy.py audit Sources`.

Design/invariants: `docs/superpowers/specs/2026-08-22-media-marquee-text-design.md`.

PR #62 squash-merged as `704bfbcdb1bd81774e8fc2d6a7d9f60a6672d703` after canonical CI GREEN 3/3 (`Build, test and package`, `macOS 26 compatibility`, `macOS UI regression`), including the full Swift test suite (`MediaMarqueeCalculatorTests`, pure/deterministic, and `MediaMarqueeTextPolicyTests`, source-scanning) and the release size gate against real evidence in `performance/m6-9-media-marquee-text-size-budget.json` (measured on candidate `f968cd6ea479bf5f04582f572472d27947490b62`: app `944,735` / DMG `604,187` / executable `642,528` bytes). `.github/workflows/ci.yml`'s size-gate reference now points at the M6.9 budget.

Two real CI-only defects were found and fixed during this PR, neither reproducible in the authoring environment (no local Xcode/`swift-testing` toolchain): `MediaMarqueeText`'s own doc comment literally spelled out the banned substring `TimelineView`, tripping its own source-scanning policy test; and four pre-existing Swift policy tests (`M66HoverPeekSizeBudgetPolicyTests`, `RegressionUIFoundationSizeBudgetPolicyTests`, `M66PhysicalAcceptance20260815RepairSizeBudgetPolicyTests`, `M66FirstClickAcceptanceSizeBudgetPolicyTests`) hardcode an assertion that `ci.yml`'s active feature-budget reference matches the current slice, updated from `m6-8` to `m6-9`.

Unlike every prior milestone, the product owner was directly asked whether to physically test first, merge with the gate waived, or leave the PR open, and explicitly chose to waive physical acceptance and merge immediately. This is recorded honestly in `docs/testing/M6_9_MEDIA_MARQUEE_ACCEPTANCE.md`, including the specific residual risk: this exact class of custom `PhaseAnimator`/`GeometryReader` SwiftUI code has a direct precedent (M6.8) for hiding bugs only physical testing caught.

### M6.6 — PR #33 + corrective runtime work

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.2.0`**.

Original M6.6 full physical acceptance remains pinned to exact `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3`; PR #33 squash-merged as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`.

Accepted M6.6 behavior includes:

- local App-owned media gesture session with bounded horizontal visuals and public AppKit arm haptic;
- stable `compact`, `peek`, `expanded` presentation states under the existing Core transition authority;
- exactly 120 ms Hover Peek activation plus 140 ms pointer-exit grace;
- generic no-media Peek with one hover-haptic request after valid dwell;
- click and physical DOWN as explicit expansion paths;
- bounded one-shot media probing/commands in compact and Peek while persistent runtime remains expanded-only;
- bounded Peek cancellation and transport teardown;
- physical LEFT -> `next`, RIGHT -> `previous`, independent of macOS scroll-direction preference;
- draggable seek/source identity/cursor isolation;
- hardware-notch-first initial screen selection with `NSScreen.main`/first-screen fallback;
- exact current-generation physical endpoint settlement before logical presentation settlement;
- bounded pointer escape monitoring only during an actual interaction rather than persistent global mouse observation.

No global scroll/button/keyboard monitor, mouse-button event authority, event tap, polling loop, repeating timer, display link, UI-test retry/sleep masking, networking/telemetry authority or new sensitive permission was added.

Included in `v0.2.0`.
