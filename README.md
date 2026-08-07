# NotchHub

Native, local-first macOS productivity hub built around the MacBook notch.

NotchHub turns the area around the camera housing into a compact panel for everyday tools. Planned modules are Shelf, Snippets, Calendar, Translator, and media controls with **Yandex Music** as the primary player.

## Status

Current version: **0.1.0 — Personal build**.

**M0 engineering foundation is accepted and merged**, including real-hardware acceptance on the primary MacBook/macOS 26.6 target. Immutable Personal Release `v0.1.0` has been published from accepted protected `main` without requiring paid Apple Developer membership. It keeps App Sandbox, Hardened Runtime, strict CI/security gates, checksum/provenance, and explicit not-notarized labeling. The remaining R0.1 gate is downloaded-release acceptance `NH-PERSONAL-RELEASE-001` on the target MacBook.

After downloaded `v0.1.0` acceptance, the next milestone is **Performance Foundation**: reproducible target-Mac CPU/RAM/thread/background-work baseline and evidence-based resource budgets before feature-heavy M1.

Source-of-truth documents:

- [`docs/PROJECT_STATE.md`](docs/PROJECT_STATE.md) — exact current state and next step
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — milestones and exit criteria
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — architecture and distribution tiers
- [`docs/TESTING.md`](docs/TESTING.md) — automated/manual acceptance contracts and history
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) — TDD, commits, versioning, documentation policy
- [`SECURITY.md`](SECURITY.md) — threat model/security invariants/release trust boundary
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

The approved next Performance Foundation milestone will:

- prohibit unreviewed polling/repeating timers/busy loops in runtime sources;
- create a development-only metric harness (never shipped as telemetry);
- measure idle/active/stability CPU, RSS, thread counts, and artifact sizes on the real macOS 26.6 target;
- derive numerical budgets from measurements rather than arbitrary targets;
- keep noisy shared-runner CPU/RAM values out of tight CI thresholds;
- investigate replacing global `.mouseMoved` with reliable local tracking only after behavior/resource measurements exist.

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
