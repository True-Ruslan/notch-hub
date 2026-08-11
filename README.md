# NotchHub

Native, local-first macOS productivity hub built around the MacBook notch.

NotchHub turns the area around the camera housing into a compact, event-driven panel for focused tools. Planned product modules include Shelf, Snippets, Calendar, Translator, Universal Media, and later settings/shortcuts capabilities.

## Status

Current published version: **`0.1.0` — Personal build**.

Current development state:

- M0 Engineering Foundation — accepted;
- R0.1 Personal Release `v0.1.0` — accepted and published;
- P0 Performance Foundation — accepted;
- P0.1 Public Repository Readiness — accepted;
- M1 interaction/transition slice — accepted;
- M6.1 Universal Media transport feasibility — accepted;
- M6.2 production media state/controller/bridge boundary — accepted;
- M6.3 concrete system-media transport — accepted;
- M6.4 shipping media composition — accepted and merged;
- **M6.5 compact + expanded Media-first UI — accepted on `Mac16,8` / macOS 26.6 in PR #19.**

The published `v0.1.0` release predates the M1/P0.1/M6 work currently present in source. A new version is required before those changes can be published because existing tags/releases are immutable.

The next product slice is the separately scoped local media gesture/haptic/draggable-seek work. P1 whole-app performance and the deferred local pointer-tracking experiment follow after that functional slice.

## Universal Media

NotchHub follows the macOS system Now Playing source rather than targeting one music application.

Accepted behavior now includes:

- presentation-scoped system-media runtime: zero adapter while compact, runtime only after settled expansion;
- compact retained media context with symmetric visible wings around the physical notch;
- expanded Media-first artwork/metadata/source presentation;
- capability-driven previous/play-pause/next controls;
- trustworthy event-driven static progress without a one-second polling loop;
- media disappearance while expanded -> Home without collapsing the panel;
- fresh authoritative state replacing retained compact context after re-expansion;
- typed, bounded system-media command/process boundary;
- no listening-history persistence or production metadata logging.

Yandex Music and Yandex Browser/Chromium system Now Playing are physically verified on the primary target. Apple Music, Spotify and additional independent-player compatibility remain explicitly unverified rather than assumed.

Gestures, haptic interaction for media controls, draggable seek and animated/live compact progress are not part of M6.5.

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
- global input observation limited to the existing narrow `.mouseMoved` fallback;
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
- compact media state owns zero adapter processes;
- shared CI validates deterministic source/lifecycle/package/size policy, not noisy runner CPU/RSS magnitudes;
- target-Mac runtime evidence is required for resource acceptance;
- immutable `v0.1.0` baseline remains historical evidence and is never silently rewritten;
- intentional feature size growth uses separately reviewed provenance-backed budgets (`M6.4`, `M6.5`) rather than widening the historical baseline.

See [`PERFORMANCE.md`](PERFORMANCE.md) and `performance/`.

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
- [`docs/testing/MEDIA_UI_ACCEPTANCE.md`](docs/testing/MEDIA_UI_ACCEPTANCE.md) — M6.5 acceptance evidence
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) — TDD/Git/documentation policy
- [`SECURITY.md`](SECURITY.md) — security/privacy boundary
- [`PERFORMANCE.md`](PERFORMANCE.md) — performance/resource policy and baseline interpretation
- [`CHANGELOG.md`](CHANGELOG.md) — notable changes
- [`docs/superpowers/specs/2026-08-09-universal-media-gestures-haptics-design.md`](docs/superpowers/specs/2026-08-09-universal-media-gestures-haptics-design.md) — approved Universal Media product design
- [`docs/superpowers/specs/2026-08-11-media-first-ui-design.md`](docs/superpowers/specs/2026-08-11-media-first-ui-design.md) — M6.5 Media-first UI design

## License

NotchHub source code is available under the [MIT License](LICENSE).