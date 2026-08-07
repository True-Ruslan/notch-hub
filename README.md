# NotchHub

Native, local-first macOS productivity hub built around the MacBook notch.

NotchHub turns the area around the camera housing into a compact panel for everyday tools. Planned modules are Shelf, Snippets, Calendar, Translator, and media controls with **Yandex Music** as the primary player.

## Status

Current version: **0.1.0 — Personal build**.

**M0 engineering foundation and R0.1 Personal Release are accepted and merged. P0 Performance Foundation has accepted evidence and is at its final PR review/merge gate.** Immutable `v0.1.0` was published from protected `main` without paid Apple Developer membership and subsequently passed downloaded-release acceptance on the primary MacBook/macOS 26.6 target, including checksum/install/launch and accepted notch/hover behavior.

P0 now has a complete canonical `v0.1.0` performance baseline: target-Mac idle/hover/10-minute stability measurements, exact immutable-release executable/app/DMG sizes, target-Mac CPU/RSS/thread acceptance ceilings, and a deterministic release-size regression gate in CI. After PR #5 passes final exact-head CI/read-only review and is merged, the next development milestone is **M1 Notch Core hardening and interaction**.

Source-of-truth documents:

- [`docs/PROJECT_STATE.md`](docs/PROJECT_STATE.md) — exact current state and next step
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — milestones and exit criteria
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — architecture and distribution tiers
- [`docs/TESTING.md`](docs/TESTING.md) — automated/manual acceptance contracts and history
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) — TDD, commits, versioning, documentation policy
- [`SECURITY.md`](SECURITY.md) — threat model/security invariants/release trust boundary
- [`PERFORMANCE.md`](PERFORMANCE.md) — resource-efficiency invariants, accepted target-Mac baseline values, budgets, and regression policy
- [`performance/baseline-v0.1.0.json`](performance/baseline-v0.1.0.json) — canonical machine-readable performance/resource baseline
- [`docs/RELEASING.md`](docs/RELEASING.md) — Personal Release and optional future Trusted Release
- [`docs/PRODUCT_REFERENCES.md`](docs/PRODUCT_REFERENCES.md) — independent product/UI research
- [`docs/specs/M1_NOTCH_INTERACTION.md`](docs/specs/M1_NOTCH_INTERACTION.md) — approved delayed-hover and haptic interaction contract
- [`docs/superpowers/plans/2026-08-07-performance-foundation.md`](docs/superpowers/plans/2026-08-07-performance-foundation.md) — approved performance plan
- [`CHANGELOG.md`](CHANGELOG.md) — notable changes

## Requirements

- macOS 14+ deployment target
- primary current real-hardware target: macOS 26.6
- Xcode / Swift 6 only for development

Installed users need only the `.dmg`/`.app`, not development tools.

## Development

```bash
swift build
swift test --parallel
(cd scripts && python3 -m unittest -v test_release_policy.py)
(cd scripts && python3 -m unittest -v test_performance_policy.py)
python3 scripts/performance_policy.py audit Sources
./scripts/security-audit.sh
```

Behavior changes and defects use RED → GREEN → REFACTOR where a truthful deterministic RED is possible. Do not manufacture a failing test merely to imitate TDD. See `docs/DEVELOPMENT.md`.

Build a local ad-hoc app/DMG:

```bash
./scripts/build-app.sh
./scripts/build-dmg.sh
```

Test/Personal builds still enable App Sandbox + Hardened Runtime.

## Security

Current runtime intentionally has:

- App Sandbox enabled;
- Hardened Runtime enabled without dangerous exceptions;
- zero third-party Swift runtime dependencies;
- no telemetry/analytics/advertising/licensing backend;
- no direct runtime network/WebKit surface;
- no runtime subprocess/shell execution;
- no dynamic code/plugin loading;
- no global keyboard/button/drag/scroll/modifier monitoring;
- global observation currently limited to `mouseMoved`, without persisted pointer history.

CI enforces this baseline. Future capabilities that require broader permissions/attack surface must change `SECURITY.md`, executable policy, tests, and relevant docs in the same reviewed PR.

## Performance/resource efficiency

NotchHub is intended to stay available continuously, so low resource consumption is a product requirement rather than a later optimization pass.

P0 provides:

- deterministic prohibition of unreviewed polling/repeating timers/busy loops in runtime sources;
- development-only metric tooling that is never shipped as telemetry;
- accepted macOS 26.6 runtime baselines for idle, active hover, and 10-minute stability;
- conservative target-Mac CPU/RSS/thread ceilings derived from those measurements;
- exact immutable-release `v0.1.0` artifact-size baseline: executable `220,560 B`, app `223,555 B`, DMG `73,955 B`;
- a fail-closed shared-CI artifact-size gate with a 15% relative regression allowance plus independent absolute ceilings;
- shared-runner CPU/RAM values kept out of tight gates because they are not honest target-hardware evidence;
- a measured reason to investigate replacing global `.mouseMoved` in M1: hover CPU is materially higher than untouched idle while idle/stability remain near-zero median CPU.

See `PERFORMANCE.md` and `performance/baseline-v0.1.0.json` for exact methodology, measurements, and budgets.

## Distribution

### Personal Release — current

Versioned builds are published through **Actions → Personal Release** from protected `main`.

They are:

- ad-hoc signed;
- App Sandbox + Hardened Runtime verified;
- checksum/provenance verified;
- explicitly labeled **Personal build — not notarized**;
- immutable: an existing tag/release is never overwritten.

Assets: `NotchHub.dmg`, `NotchHub.dmg.sha256`, `build-metadata.json`.

Because no paid Developer ID/notarization is used, macOS may require Finder **Open** or **System Settings → Privacy & Security → Open Anyway** on first launch of a downloaded version. Do not disable Gatekeeper. See `docs/RELEASING.md`.

### Trusted Release — optional future

A separately isolated `Trusted Release` workflow preserves Developer ID + Apple notarization/stapling/Gatekeeper checks for a future new version if Apple Developer Program membership becomes worthwhile. It cannot replace an already published Personal version.

## Architecture

SwiftUI handles composition; AppKit handles window/panel integration. Geometry, pointer decisions, and sizing authority are isolated/testable instead of hidden in UI callbacks.

Yandex Music integration will use a provider boundary. A MediaRemote/private fallback is allowed only after focused security, compatibility, and performance review and may not weaken Sandbox/Hardened Runtime/library validation.

## Privacy

The baseline app is local-only and makes no direct network requests. Future modules must document any added permission, external process, private API, network use, persistence, cache, or resource-monitoring behavior before implementation.
