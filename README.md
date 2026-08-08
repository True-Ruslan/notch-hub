# NotchHub

Native, local-first macOS productivity hub built around the MacBook notch.

NotchHub turns the area around the camera housing into a compact panel for everyday tools. Planned modules are Shelf, Snippets, Calendar, Translator, and **universal system media controls** that follow the macOS Now Playing source rather than targeting one music application. Yandex Music remains one of the primary real-world acceptance sources alongside Apple Music, Spotify, browser media, and an independent player.

## Status

Current version: **0.1.0 — Personal build**.

**M0 engineering foundation, R0.1 Personal Release, P0 Performance Foundation, and P0.1 Public Repository Readiness are accepted.** P0 was squash-merged into `main` as `a056aa74bad5d8e193eb4c76a76e6c910344bd09`; public-readiness hardening was squash-merged as `23500e099a0f8b2738f1157c6ae3be71c89df6e1` and completed with successful post-public Settings/UI verification. The accepted M1 interaction/transition slice was squash-merged as `094b494bd597643244e733baf5787a13b61fb4eb`.

The source repository is **public**. Public pull-request CI is intentionally unprivileged and cannot use repository secrets or write authority. The next active product slice is the **Universal Media Bridge compatibility/security probe**; remaining M1 pointer-observation optimization is deferred to the P1 whole-app performance review after the functional media slice exists.

Source-of-truth documents:

- [`docs/PROJECT_STATE.md`](docs/PROJECT_STATE.md) — exact current state and next step
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — milestones and exit criteria
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — architecture and distribution tiers
- [`docs/TESTING.md`](docs/TESTING.md) — automated/manual acceptance contracts and history
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) — TDD, commits, versioning, documentation policy
- [`SECURITY.md`](SECURITY.md) — threat model/security invariants/release trust boundary
- [`PERFORMANCE.md`](PERFORMANCE.md) — resource-efficiency invariants, accepted target-Mac baseline values, budgets, and regression policy
- [`performance/baseline-v0.1.0.json`](performance/baseline-v0.1.0.json) — canonical machine-readable performance/resource baseline
- [`docs/PUBLIC_READINESS.md`](docs/PUBLIC_READINESS.md) — public-repository audit scope, findings, and post-transition acceptance
- [`docs/RELEASING.md`](docs/RELEASING.md) — Personal Release and optional future Trusted Release
- [`docs/PRODUCT_REFERENCES.md`](docs/PRODUCT_REFERENCES.md) — independent product/UI research
- [`docs/specs/M1_NOTCH_INTERACTION.md`](docs/specs/M1_NOTCH_INTERACTION.md) — approved delayed-hover and haptic interaction contract
- [`docs/superpowers/specs/2026-08-09-universal-media-gestures-haptics-design.md`](docs/superpowers/specs/2026-08-09-universal-media-gestures-haptics-design.md) — approved Universal Media, gesture, haptic, security, and P1 design
- [`docs/superpowers/plans/2026-08-09-universal-media-bridge-probe.md`](docs/superpowers/plans/2026-08-09-universal-media-bridge-probe.md) — first TDD implementation plan: compatibility/security probe before production media code
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

The approved Universal Media design permits one future, replaceable private MediaRemote compatibility boundary only behind `SystemMediaBridge`. That exception is **not implemented yet** and does not currently change the runtime security baseline. The first step is a development-only sandbox/Hardened Runtime compatibility probe; a failed probe is redesigned or rejected rather than made to pass by weakening the app.

Public/fork pull requests execute only the ordinary `pull_request` CI path with explicit `contents: read`, no repository secrets, no self-hosted runners, no OIDC/write permission, and checkout credentials disabled. `pull_request_target` and `workflow_run` privilege bridges are prohibited repository-wide; alternate PR workflows and reusable-workflow hops from public PR CI are also rejected by executable policy. Release publication is isolated in manual trusted-main workflows.

CI enforces these baselines. Future capabilities that require broader permissions/attack surface must change `SECURITY.md`, executable policy, tests, and relevant docs in the same reviewed PR.

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
- a measured reason to revisit global `.mouseMoved`: hover CPU is materially higher than untouched idle, but the `NSTrackingArea` / window-local experiment is intentionally evaluated during P1 after media integration so optimization is based on the real application rather than an isolated speculative slice.

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

A separately isolated `Trusted Release` workflow preserves Developer ID + Apple notarization/stapling/Gatekeeper checks for a future new version if Apple Developer Program membership becomes worthwhile. It is intentionally unconfigured today: no GitHub Environment or Apple signing/notarization secrets are provisioned, and the workflow cannot become operational until that future setup is deliberately completed. It cannot replace an already published Personal version.

## Architecture

SwiftUI handles composition; AppKit handles window/panel integration. Geometry, pointer decisions, and sizing authority are isolated/testable instead of hidden in UI callbacks.

Universal media will use a player-agnostic `MediaProvider`/`MediaSessionSnapshot` boundary. The only approved private-API exception is an isolated, optional `SystemMediaBridge` compatibility layer for system-wide macOS Now Playing; it must fail closed, remain replaceable, avoid global scroll capture and periodic track polling, and pass focused security/compatibility/performance acceptance before production adoption.

## Privacy

The baseline app is local-only and makes no direct network requests. Future modules must document any added permission, external process, private API, network use, persistence, cache, or resource-monitoring behavior before implementation.

## License

NotchHub source code is available under the [MIT License](LICENSE).