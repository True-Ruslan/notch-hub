# Changelog

All notable changes to NotchHub are documented here.

The project follows [Semantic Versioning](https://semver.org/). The active version is stored in repository-root [`VERSION`](VERSION).

## [Unreleased]

### Added

- M6.4 shipping composition linking the accepted `NotchHubMediaCore` into `NotchHubApp`, packaging exact pinned adapter/framework/license/provenance resources, and retaining the reviewed signing/security boundary.
- Presentation-scoped media lifecycle: compact launch owns no media runtime; settled expansion starts media; settled compact stops/releases it.
- Development-only candidate isolation, privacy-safe shipping acceptance collectors, exact-DMG target runners, compact parent-only sampling, and active parent+adapter evidence.
- Explicit M6.4 additive artifact-size policy over the unchanged immutable P0 baseline.
- Historical performance diagnostics for exact M6.3 shell-only comparison and exact same-session `v0.1.0` versus M1 #319 RSS comparison.
- M6.3 concrete production system-media transport and target-Mac acceptance tooling.
- M6.2 normalized production media state/controller/bridge boundary.
- M6.1 Universal Media compatibility/security probe and acceptance ledger.
- P0 performance policy, immutable baseline, target-Mac sampling and deterministic release-size enforcement.
- M1 delayed-hover, haptic, pointer-monitor, transition, animation and Reduce Motion hardening with deterministic and physical acceptance.
- MIT license and public-repository safety policy.

### Changed

- **M6.4 remains Draft and is not yet accepted.** Current frozen production source `fdbe987d8f22768b2a75406c8f1e721fa1da2845` passes security, provenance, adapter lifecycle, permission posture and stability-shape gates, but compact absolute RSS exceeds the stored P0 ceilings.
- Current M6.4 compact target evidence: steady CPU median/max `0.0/2.4%`, RSS median/max `59,792/66,160 KiB`, threads max `4`; 10-minute stability CPU median/max `0.0/3.3%`, RSS median/max `59,024/60,320 KiB`, RSS `56,304 -> 58,976 KiB`, threads `3 -> 3`.
- The first M6.4 always-on media candidate was rejected after target testing showed roughly `80–86 MiB` combined compact RSS. The runtime budget was not widened; media runtime ownership was moved to settled expanded presentation under RED→GREEN coverage.
- A no-Now-Playing A/B on the superseded candidate was essentially unchanged, ruling out active track/artwork retention as the cause of the first extra resource cost.
- **M6.4 static media linkage is disproven as the primary cause of the remaining compact RSS discrepancy.** Final M6.3 shell-only app `30de94c0cb6ea17dc21bd366404937db2bc73783`, where `NotchHubApp` links only `NotchHubCore` and contains no M6.4 shipping media assets, reproduced steady RSS `58,656/62,624 KiB` and stability RSS `56,384/60,400 KiB`.
- Root-cause investigation therefore moves backward to P0 measurement context versus M1 shell evolution. The next falsifiable test re-runs immutable `v0.1.0` and accepted M1 candidate #319 in the same session using the same current 60-second parent-only collector.
- The P0 baseline remains immutable while comparability is investigated; it is not rewritten from new evidence.
- M6.3 remains accepted with Yandex Music/Yandex Browser observation and actual toggle/previous/next/seek behavior.
- Apple Music, Spotify and additional-player compatibility remain explicitly unverified/deferred for the Personal Release cycle.

### Fixed

- M6.4 app launch no longer creates or starts `ShippingMediaRuntime`; compact idle owns zero media adapter processes.
- Stale or reversed panel-transition completions cannot start media runtime.
- Candidate-only media helpers no longer inflate the shipping link graph.
- M6.4 feature-size checking accepts the exact real artifact-size envelope while remaining fail-closed for unexpected fields.
- M6.3 process teardown is bounded rather than relying on unbounded `Process.waitUntilExit()`.
- M1 hardware-notch rendering, transition ownership, stale-completion handling, collapse staging, animation reversal, Reduce Motion retargeting, pointer hot-path allocation and exact top-edge activation were corrected under RED→GREEN coverage.

### Testing

- Current M6.4 frozen candidate `fdbe987d8f22768b2a75406c8f1e721fa1da2845` passed CI #693 / run `31472420797`; artifact ID `9093958828`, Actions digest `sha256:f055bc87d1f2c8cafe0d3b57d9cf6cdf82d7a712bf85acf3317232679a9689b9`, contained DMG SHA-256 `6371e8695e30f06697d37d2d018e043674e8b27a44022e3d8e846d0e1dad01fd`.
- Physical current-candidate testing proved zero adapter throughout compact steady/stability, one owned adapter after settled expansion, clean normal teardown/no orphan, and no Accessibility/Input Monitoring/Automation/Screen Recording prompts.
- Final M6.3 shell-only comparator source `30de94c0cb6ea17dc21bd366404937db2bc73783`, CI #594 / run `31389611697`, artifact ID `9063213178`, DMG SHA-256 `b1da6681ce49da3c34b3720c39caa32c3fc4508e0abf7d209b63b46f78713fb7` reproduced the elevated compact shell RSS without M6.4 linkage.
- Shell-only comparator tooling was developed RED #705 -> GREEN #709.
- Same-session P0→M1 RSS bisect tooling was developed RED #712 and uses one shared current collector path for both exact historical candidates.
- The A/B runner pins immutable `v0.1.0` source `8e913dcddfdec7d9aa920df8c37afb23b8c40884`, release DMG SHA-256 `cf53be6081b1836551fcbbb91b85fed800de4c089451961f3c6a21f6b77768bc`, and M1 #319 source `f6de06f5d045fc9375b3b31b0a7feb97a13cebe4`, artifact ID `9021802122`, DMG SHA-256 `3a6ead1a716e6cf813d2125a7cdecf18a41a3ac2179bf5ca08f5cd4474856945`.
- The P0 harness at measurement-tool commit `dfd4f87f8e5be04b467172d720d22bfc054c06d0` and the current compact collector both sample Darwin `ps rss` in KiB, so there is no identified metric-definition change explaining the discrepancy.

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

- App Sandbox and Hardened Runtime remain mandatory for the Personal Release.
- No telemetry, runtime networking, subprocess execution, dynamic code loading, sensitive global input monitoring or bundled credentials.
- Personal Release is ad-hoc signed and intentionally not notarized; standard macOS first-launch trust flows are documented without weakening Gatekeeper.
