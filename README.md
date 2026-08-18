# NotchHub

Native, local-first macOS productivity hub built around the MacBook notch.

NotchHub turns the area around the camera housing into a compact, event-driven panel for focused tools. Planned product modules include Shelf, Snippets, Calendar, Translator, Universal Media, and later settings/shortcuts capabilities.

## Status

Current published version: **`0.1.0` — Personal build**.

Current development state:

- M0 Engineering Foundation — accepted/merged;
- R0.1 Personal Release `v0.1.0` — accepted/released;
- P0 Performance Foundation — accepted/merged;
- P0.1 Public Repository Readiness — accepted;
- M1 interaction/transition slice — accepted/merged;
- M6.1 Universal Media transport feasibility — accepted;
- M6.2 production media state/controller/bridge boundary — accepted/merged;
- M6.3 concrete system-media transport — accepted/merged;
- M6.4 shipping media composition — accepted/merged;
- M6.5 compact + expanded Media-first UI — accepted/merged;
- **M6.6 gestures, haptics, interactive notch, seek and Hover Peek — implemented, automated-tested, physically accepted and merged via PR #33 as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`; not released.**
- **P1 whole-app target-Mac performance/resource review — measurement foundation merged via PR #36 as `5cd9a2a47d87a433155f53b3aa0510000f2fce85`; target-Mac evidence pending.**

The published `v0.1.0` release predates the M1/P0.1/M6 work currently present in source. A new version is required before those changes can be published because existing tags/releases are immutable.

The current priority is P1 target collection: measure exact merged M6.6 runtime `bb6df211...` on Mac16,8/macOS 26.6 using frozen measurement tooling `5cd9a2a4...`, characterize CPU/RSS/threads/wakeups/energy/compositor behavior, and optimize only where evidence demonstrates a material issue. Broader multi-monitor hardening and new product modules remain after this resource gate.

## Universal Media

NotchHub follows the macOS system Now Playing source rather than targeting one music application.

Accepted source behavior now includes:

- stable `compact`, `peek`, `expanded` ownership under one transition authority;
- media and generic no-media Hover Peek with exact dwell/grace behavior;
- explicit click and physical DOWN expansion plus physical UP/pointer-exit collapse;
- horizontal LEFT -> Next and RIGHT -> Previous with presentation following the fingers;
- public AppKit haptic feedback for supported qualifying gesture arms;
- capability-driven previous/play-pause/next and draggable seek;
- source-app badge/fallback and identity-locked seek cancellation;
- presentation-scoped system-media runtime: zero persistent adapter while settled compact/Peek, runtime only in settled expanded;
- trustworthy event-driven static progress without a one-second polling loop;
- typed, bounded system-media command/process boundary;
- no listening-history persistence or production metadata logging.

Yandex Music and Yandex Browser/Chromium system Now Playing are physically verified on the primary target. Apple Music, Spotify and additional independent-player compatibility remain explicitly unverified rather than assumed.

The physically accepted M6.6 runtime is pinned to exact source `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3`; documentation/coverage descendants do not rewrite that hardware evidence. The feature is now merged into `main` through `bb6df211699c5aef7bac7d50866f3e24b2fe165b`.

## Requirements

- deployment target: macOS 14+;
- primary real-hardware acceptance target: macOS 26.6 / `Mac16,8`;
- Swift 6 / Xcode for development;
- installed Personal builds require only the `.dmg` / `.app`.

## Development

```bash
swift build -Xswiftc -warnings-as-errors
swift test --parallel
(cd scripts && python3 -m unittest -v test_release_policy.py)
(cd scripts && python3 -m unittest -v test_performance_policy.py test_feature_size_budget.py)
python3 scripts/performance_policy.py audit Sources
./scripts/security-audit.sh
```

Behavior changes and deterministic defects use RED -> GREEN -> REFACTOR where a truthful RED is possible. Physical acceptance is reserved for behavior CI cannot honestly prove, such as real notch geometry, actual player integration, permission surfaces, haptic feel and target-Mac resource behavior.

Build a local ad-hoc app/DMG:

```bash
./scripts/build-app.sh
./scripts/build-dmg.sh
```

Test/Personal builds retain App Sandbox + Hardened Runtime.

## Architecture

SwiftUI owns view composition; AppKit owns `NSPanel`, screen geometry and presentation transitions.

The current high-level dependency direction is:

```text
NotchHubApp
  -> NotchHubCore
  -> NotchHubMediaCore

NotchHubCore
  -X-> NotchHubMediaCore
```

`NotchHubApp` is the composition root. `NotchHubCore` stays media-independent, and `NotchPanelTransitionCoordinator` remains the sole panel transition/geometry authority. Universal Media projects normalized system-media state into an App-owned presentation model; UI does not learn private MediaRemote command IDs or process details.

The accepted private compatibility exception remains isolated behind the system-media transport boundary. The NotchHub process itself does not directly `dlopen`/resolve private framework symbols.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Security and privacy

Current runtime policy includes:

- App Sandbox as the only application entitlement;
- Hardened Runtime without dangerous exception entitlements;
- no telemetry, analytics, advertising or licensing backend;
- no direct application networking/WebKit surface;
- no bundled secrets;
- no Accessibility, Input Monitoring, Automation/Apple Events or Screen Recording requirement;
- global input observation limited to the existing narrow `.mouseMoved` fallback under P1 review;
- exactly one reviewed production subprocess boundary for Universal Media, fixed to `/usr/bin/perl` with pinned resources and a closed typed command surface;
- no arbitrary shell/executable/argument surface;
- no dynamic private-framework loading inside the NotchHub process;
- no production persistence/logging of media metadata or listening history.

Public/fork pull requests execute only unprivileged `pull_request` CI with read-only repository authority and no secrets. Release publication remains isolated from untrusted PR execution.

See [`SECURITY.md`](SECURITY.md).

## Performance/resource efficiency

NotchHub is designed to stay available continuously, so resource use is a product requirement.

Key invariants:

- runtime work is event-driven by default;
- no unreviewed polling/repeating timer/display-link/busy-loop surface;
- settled compact and Peek own zero persistent media observer;
- shared CI validates deterministic source/lifecycle/package/size policy, not noisy runner CPU/RSS magnitudes;
- target-Mac runtime evidence is required for resource acceptance;
- immutable `v0.1.0` baseline remains historical evidence and is never silently rewritten;
- P1 combines exact CPU/RSS/thread reports with privacy-safe target-Mac wakeup/energy/compositor evidence before any optimization decision;
- the accepted P1 tooling source is pinned to `5cd9a2a47d87a433155f53b3aa0510000f2fce85`; later documentation commits do not redefine measurement provenance;
- performance work cannot broaden permissions, input capture, networking or telemetry authority.

See [`PERFORMANCE.md`](PERFORMANCE.md), [`docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md`](docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md) and `performance/`.

## Distribution

### Personal Release — current

Versioned builds are published through **Actions -> Personal Release** from protected `main`.

They are:

- ad-hoc signed;
- App Sandbox + Hardened Runtime verified;
- checksum/provenance verified;
- explicitly labeled **Personal build — not notarized**;
- immutable: an existing tag/release is never overwritten.

Because no paid Developer ID/notarization is used, macOS may require Finder **Open** or **System Settings -> Privacy & Security -> Open Anyway** on first launch. Do not disable Gatekeeper.

### Trusted Release — optional future

The repository retains an isolated Developer ID + notarization path for a future version if Apple Developer Program membership becomes worthwhile. It is intentionally unconfigured today and cannot become operational until the required GitHub environment and Apple credentials are deliberately provisioned/reviewed.

See [`docs/RELEASING.md`](docs/RELEASING.md).

## Source of truth

- [`docs/PROJECT_STATE.md`](docs/PROJECT_STATE.md) — exact current project state and next step
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — milestone order and exit criteria
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — runtime/package ownership
- [`docs/TESTING.md`](docs/TESTING.md) — CI and physical acceptance policy
- [`docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md`](docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md) — active P1 target-Mac resource runbook
- [`docs/testing/MEDIA_GESTURE_ACCEPTANCE.md`](docs/testing/MEDIA_GESTURE_ACCEPTANCE.md) — M6.6 gesture evidence
- [`docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md`](docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md) — M6.6 interaction evidence
- [`docs/testing/MEDIA_PEEK_ACCEPTANCE.md`](docs/testing/MEDIA_PEEK_ACCEPTANCE.md) — M6.6 Peek evidence
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) — TDD/Git/documentation policy
- [`SECURITY.md`](SECURITY.md) — security/privacy boundary
- [`PERFORMANCE.md`](PERFORMANCE.md) — performance/resource policy and baseline interpretation
- [`CHANGELOG.md`](CHANGELOG.md) — notable changes
- [`docs/superpowers/plans/2026-08-18-p1-target-mac-resource-audit.md`](docs/superpowers/plans/2026-08-18-p1-target-mac-resource-audit.md) — active P1 implementation plan

## License

NotchHub source code is available under the [MIT License](LICENSE).
