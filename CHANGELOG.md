# Changelog

All notable changes to NotchHub are documented here.

The project follows [Semantic Versioning](https://semver.org/). The active version is stored in repository-root [`VERSION`](VERSION).

## [Unreleased]

The current published release remains `v0.1.0`; everything below is source work that has not yet been published as a new version.

### Added

- **M6.6 one-shot lifecycle ownership**: `MediaRemoteProcessClient` now owns every in-flight one-shot capability/command process so normal teardown can cancel them deterministically before compact gestures increase one-shot usage.
- Tight provenance-backed Task-1 artifact envelope in `performance/m6-6-one-shot-lifecycle-size-budget.json`; immutable P0 and historical M6.4/M6.5 budgets remain unchanged.
- **M6.6 gesture/haptic/seek acceptance contract** with stable `NH-MEDIA-GESTURE-001...018` gates and a TDD implementation plan.
- M6.6 compact-command design delta: bounded current-system one-shot capability validation before compact arming, preserving zero persistent observation while compact.
- **M6.5 Media-first UI**: compact retained media context and expanded Media-first presentation driven by authoritative macOS Now Playing state.
- App-owned `ShippingMediaPresentationModel` that projects normalized media state into UI-only data without leaking transport/private-command details into SwiftUI.
- Expanded artwork/title/artist/album/source presentation with capability-driven previous/play-pause/next controls and trustworthy static progress.
- Retained compact media wings: symmetric 36 pt visible extensions around the unchanged physical notch, artwork left and playback status right.
- Generic Notch content-composition seam that keeps `NotchHubCore` independent from `NotchHubMediaCore` while leaving panel transition/geometry ownership in Core/AppKit.
- Explicit M6.5 cumulative feature-size policy in `performance/m6-5-media-first-ui-size-budget.json` over the unchanged immutable P0 baseline.
- M6.5 deterministic acceptance IDs `NH-MEDIA-UI-001...011` and target-Mac acceptance ledger.
- M6.4 shipping composition linking the accepted `NotchHubMediaCore` into `NotchHubApp`, packaging pinned adapter/framework/license/provenance resources and retaining the reviewed signing/security boundary.
- Presentation-scoped media lifecycle: compact owns no media runtime; settled expansion starts media; settled compact stops/releases it.
- Development-only media candidate/probe isolation and privacy-safe shipping acceptance tooling.
- M6.3 concrete production system-media transport and target-Mac acceptance tooling.
- M6.2 normalized production media state/controller/bridge boundary.
- M6.1 Universal Media compatibility/security probe and acceptance ledger.
- P0 performance policy, immutable baseline, target-Mac sampling and deterministic release-size enforcement.
- M1 delayed-hover, haptic, pointer-monitor, transition, animation and Reduce Motion hardening with deterministic and physical acceptance.
- MIT license and public-repository safety policy.

### Changed

- **M6.6 Task 1 is automated-accepted and merged.** Final exact PR head `5a141dd30196bd8bd050a217c8bf9a6fed6ad02c` passed CI #786 / run `31576327027`; PR #24 was squash-merged as `957e2f085ebf1fae1b3f741a7f79dd6a45b599b6`; post-merge `main` CI #787 / run `31577048395` passed both required jobs. No separate physical gate was required because this prerequisite changes process lifecycle only and adds no user-facing behavior.
- Normal media teardown now cancels active one-shot timeout tokens, fails pending one-shot continuations closed, ignores stale callbacks, and retains an unconfirmed forced teardown for a later retry.
- Current CI feature-size envelope now points to the Task-1-specific M6.6 budget. Relative to M6.5 allowance, executable grows by only 16 KiB and app by 20 KiB; DMG allowance is unchanged.
- **M6.6 Task 0 is accepted and merged.** Issue #20 was fixed on exact physically accepted source `0d40391721ae934653a9c75fc981dd683121cf46` and squash-merged via PR #22 as `f017addd2efc9aed5b60b1556205bdb8eab23e0e`.
- The frozen compact gesture contract does not keep `ShippingMediaRuntime` alive in compact mode and does not add global scroll observation; compact capability/command operations are bounded uses of the existing fixed media process boundary only.
- **M6.5 is accepted on `Mac16,8` / macOS 26.6.** All `NH-MEDIA-UI-001...011` gates pass on frozen physical source `431d9fbaf1ff5ba98f2ceec09732acafe5f65794`.
- Cold/no-media compact remains exact-notch and zero-adapter. After a real expanded media session, normal collapse retains the last authoritative visual context in 36 pt side wings while the media runtime is stopped/released.
- Media disappearance while expanded now returns to the existing Home surface without collapsing the panel.
- Fresh expanded runtime events replace retained compact context without comparing raw media sequence numbers across runtime lifetimes; ordering remains `MediaSessionController` responsibility.
- Previous/next availability is strictly capability-driven; missing metadata/capability state is not fabricated.
- Progress remains event-driven/static in M6.5; draggable seek, gesture handling and media haptics remain M6.6 work.
- The first complete M6.5 UI candidate measured `412,992 / 715,198 / 465,177 B` executable/app/DMG. Reusing the existing Home/Foundation view instead of duplicating it reduced the accepted implementation to `397,408 / 699,614 / 461,740 B` on the frozen physical candidate.
- The immutable P0 artifact baseline and historical M6.4 budget remain unchanged. M6.5 growth is represented by a separate provenance-backed feature envelope; no runtime CPU/RSS/thread budget was widened.
- **M6.4 shipping media composition remains accepted.** All `NH-MEDIA-SHIP-001...010` gates passed on frozen source `fdbe987d8f22768b2a75406c8f1e721fa1da2845` and PR #17 was merged as `4ba603e1c3564d6cdf58169a7936f1954dee2ffd`.
- M6.4 direct same-session immutable `v0.1.0` comparison found no material steady compact-memory regression; the independent 10-minute RSS/thread growth gate also passed.
- `PERFORMANCE.md` preserves original P0 measurements as immutable historical calibration while classifying cross-session absolute `ps rss` and isolated CPU maxima as non-portable standalone gates.
- M6.3 remains accepted with Yandex Music/Yandex Browser observation and actual toggle/previous/next/seek behavior.
- Apple Music, Spotify and additional-player compatibility remain explicitly unverified/deferred rather than assumed.

### Fixed

- M6.6 Task 1 prevents in-flight media one-shot capability/command operations from escaping normal client teardown; pending operations no longer depend solely on their later timeout/termination callback to finish.
- M6.6 Task 0 retargets an in-flight collapse when compact extension changes, so media disappearance during collapse settles at the exact ordinary hardware-notch frame instead of stale empty media wings; stale completion cannot win and no second haptic is emitted.
- Media UI no longer attempts to place compact artwork/status inside the physically occluded camera-housing width; retained media uses side wings while ordinary compact remains exact-notch.
- M6.5 no longer duplicates the existing Home/Foundation SwiftUI hierarchy inside the media root, reducing the shipping payload without changing behavior.
- Media presentation teardown detaches the UI callback before controller stop so ordinary compact teardown preserves retained visual context without keeping the adapter alive.
- Invalid/missing shipping media resources clear expanded presentation and fail closed rather than exposing a partial UI state.
- M6.4 app launch does not create/start `ShippingMediaRuntime`; compact idle owns zero media adapter processes.
- Stale or reversed panel-transition completions cannot start media runtime.
- Candidate-only media helpers remain outside the shipping link graph.
- M6.3 process teardown is bounded rather than relying on unbounded waiting.
- M1 hardware-notch rendering, transition ownership, stale-completion handling, collapse staging, animation reversal, Reduce Motion retargeting, pointer hot-path allocation and exact top-edge activation were corrected under RED -> GREEN coverage.

### Testing

- M6.6 Task 1 lifecycle RED: source `440b830e01d843491027ced174ffcf504707570b`, CI #780 / run `31574477720`, with the new tests failing only because `stop()` did not own one-shots.
- M6.6 Task 1 behavioral GREEN / old-size-policy RED: source `55d08e58ce755a4e5d32a1128bd1a1262fe1ff42`, CI #783 / run `31575348332`, 198 Swift tests PASS; only the historical M6.5 size envelope failed.
- M6.6 Task 1 size-policy RED: source `ccf569d7d2f6f1ae5dce3738176f2be3fc97c683`, CI #784 / run `31575902157`, failing exactly because the Task-1 budget did not yet exist and CI still referenced M6.5.
- M6.6 Task 1 final GREEN: source `5a141dd30196bd8bd050a217c8bf9a6fed6ad02c`, CI #786 / run `31576327027`, both required jobs PASS, 198 Swift tests PASS, exact sizes `415,200 / 717,406 / 465,179 B`; post-merge main CI #787 / run `31577048395` PASS.
- M6.6 Task 0 TDD: RED source `785c48d8cc6831f4196cfa7c78843b826acb9a07`, CI #775 / run `31567022553`; GREEN/physical source `0d40391721ae934653a9c75fc981dd683121cf46`, CI #776 / run `31567162859`, 196 Swift tests / 39 suites PASS; target-Mac focused matrix PASS; PR #22 merge `f017addd2efc9aed5b60b1556205bdb8eab23e0e`; post-merge main CI #777 / run `31572634042` PASS in both required jobs.
- M6.5 TDD cycles: Core content seam RED #736 -> GREEN #738; media presentation RED #740 -> GREEN #741; runtime presentation/typed commands RED #742 -> GREEN #743; App/UI composition RED #745 -> GREEN; feature-size policy RED #760 -> GREEN #762.
- Frozen M6.5 physical candidate `431d9fbaf1ff5ba98f2ceec09732acafe5f65794`: CI #763 / run `31539442148`, 194 Swift tests PASS, shipping artifact ID `9120231721`, Actions digest `sha256:0d18a0c9ce5305b90808f0937531211094b85947ce96b2afd0a2c4020e4e7007`, contained DMG SHA-256 `3993330bf57ac86ead949215ba5370a0a33ec6b8f6a17f1d65baa30c41f5f6ad`.
- The first #763 attempt failed only while cloning the pinned external adapter because the GitHub-hosted runner reported a self-signed-certificate TLS error; warnings-as-errors build and all Swift tests had already passed. Retrying failed/dependent jobs on the exact same source passed the complete pipeline without weakening TLS/security policy.
- Physical M6.5 acceptance confirmed Yandex Music and Yandex Browser Media-first UI, real click controls, media disappearance -> expanded Home, retained compact wings, fresh re-expansion, zero adapter while compact, no sensitive permission prompts and clean Quit/no orphan.
- Accepted M6.4 frozen candidate `fdbe987d8f22768b2a75406c8f1e721fa1da2845`: CI #693 / run `31472420797`, artifact ID `9093958828`, Actions digest `sha256:f055bc87d1f2c8cafe0d3b57d9cf6cdf82d7a712bf85acf3317232679a9689b9`, contained DMG SHA-256 `6371e8695e30f06697d37d2d018e043674e8b27a44022e3d8e846d0e1dad01fd`.
- M6.4 physical evidence proved zero adapter throughout compact steady/stability, one owned adapter after settled expansion, clean teardown/no orphan and no Accessibility/Input Monitoring/Automation/Screen Recording prompts.
- Same-session P0 -> M1 and direct `v0.1.0` -> M6.4 comparison tooling/evidence remains recorded in `PERFORMANCE.md` and the M6.4 acceptance ledger.

### Security

- M6.6 Task 1 changes ownership/cancellation only; it does not widen the fixed `/usr/bin/perl` executable/path/argument boundary, one-shot timeouts, permissions, entitlements, networking or global input surface.
- M6.6 Task 0 changed transition routing only and did not widen runtime authority.
- The frozen M6.6 gesture design explicitly prohibits global scroll capture, synthetic keys and new sensitive permissions; compact one-shot validation/commands must use the same fixed pinned `/usr/bin/perl` boundary and return to zero process ownership.
- M6.5 adds UI/presentation behavior only and does not widen runtime authority.
- App Sandbox remains the only application entitlement and Hardened Runtime remains mandatory.
- The sole production process exception remains the fixed `/usr/bin/perl` Universal Media boundary with pinned resources and a closed typed command surface.
- No Accessibility, Input Monitoring, Automation/Apple Events, Screen Recording, networking, telemetry, arbitrary shell/executable surface, direct private-framework loading in the NotchHub process, or listening-history persistence was added.

## [0.1.0] - 2026-08-07

### Added

- Initial native macOS NotchHub application foundation using Swift 6, SwiftUI and AppKit.
- Hardware-notch geometry from public `NSScreen` APIs with compact/expanded states and AppKit-owned sizing.
- Deterministic screen-space pointer/retention policy and exact physical-notch compact width.
- App Sandbox and Hardened Runtime with minimal reviewed entitlements.
- Strict CI/security/release policy, DMG integrity verification and real-hardware acceptance.

### Fixed

- Prevented compact/expanded hover resize oscillation through deterministic screen-space policy.
- Real hardware notch widths no longer inherit the fallback minimum.
- Disabled `NSHostingView` window-sizing ownership so SwiftUI content cannot leave the actual `NSPanel` frame expanded.
- Corrected Personal Release note validation while keeping Gatekeeper/quarantine bypass instructions prohibited.

### Testing

- Corrected-build hardware retest on macOS 26.6: `NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, and `NH-HOVER-003` PASS.
- Immutable Personal Release `v0.1.0` was published from accepted protected `main` and passed downloaded-release acceptance `NH-PERSONAL-RELEASE-001`.

### Security

- App Sandbox and Hardened Runtime are mandatory for the Personal Release.
- No telemetry, runtime networking, sensitive input monitoring or bundled credentials.
- Personal Release is ad-hoc signed and intentionally not notarized; standard macOS first-launch trust flows are documented without weakening Gatekeeper.
