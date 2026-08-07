# Roadmap

## M0 — Engineering foundation

Status: **ACCEPTED**
Version target: `v0.1.0`
Primary real-hardware target: macOS `26.6`

Completed:

- Swift 6 native application foundation;
- deterministic notch geometry and compact/expanded state;
- stable pointer activation/retention policy;
- exact hardware-notch width and AppKit-owned panel sizing;
- RED → GREEN regression coverage for real-device defects;
- strict formatting + warnings-as-errors + macOS 26 CI;
- App Sandbox and Hardened Runtime;
- zero third-party Swift runtime dependencies;
- executable security baseline;
- immutable full-SHA GitHub Action references;
- DMG packaging/signature/entitlement/system-library/integrity verification;
- SemVer/CHANGELOG/project-state/testing/security documentation;
- macOS 26.6 real-hardware acceptance of required notch/hover behavior.

M0 code is merged into protected `main`.

## R0.1 — Personal Release foundation

Status: **IN PROGRESS** (`PR #3`)
Target: `v0.1.0 — Personal build`

Purpose: publish versioned personal-use builds through GitHub Releases without paid Apple Developer membership while preserving security, provenance, and immutable history.

Exit criteria:

- deterministic release-policy tests are green;
- `Personal Release` workflow is manual-only and accepts only exact protected `main`;
- App Sandbox/Hardened Runtime/ad-hoc signature/system-library/DMG gates are repeated before publication;
- no Apple signing/notary secrets or trusted-distribution claims exist in Personal Release;
- SHA-256 and `build-metadata.json` are published beside the DMG;
- existing tags/releases cannot be overwritten (`--clobber`/release upload prohibited);
- future `Trusted Release` workflow is separately named and cannot overwrite Personal versions;
- release docs clearly explain standard Finder / Privacy & Security → Open Anyway path without weakening Gatekeeper;
- `CHANGELOG.md`, `PROJECT_STATE`, `TESTING`, `SECURITY`, architecture, and release docs match the candidate;
- protected PR CI is green;
- PR is squash-merged;
- manual `Personal Release` workflow successfully publishes `v0.1.0`;
- `NH-PERSONAL-RELEASE-001` passes on the target MacBook/macOS 26.6.

Apple Developer Program membership is **not** a blocker. Developer ID/notarization is intentionally deferred to an optional future Trusted Release tier.

## P0 — Performance Foundation

Status: **NEXT after Personal `v0.1.0` publication**

Purpose: make CPU, RAM, threads, wakeups/background work, artifact size, and lifecycle efficiency measurable release requirements before feature-heavy M1 work.

Planned:

- root `PERFORMANCE.md` contract;
- deterministic CI audit against unreviewed polling/timers/busy loops;
- standard-library process-metric parser/aggregation tests;
- development-only target-Mac baseline harness;
- reproducible macOS 26.6 scenarios for idle, hover/active, stability, and artifact size;
- evidence-based budgets derived from real measurements, never arbitrary guesses;
- CI gates for deterministic/reproducible resource invariants (especially artifact size), while noisy CPU/RAM thresholds remain target-Mac acceptance rather than shared-runner gates;
- prove performance tooling is never bundled as telemetry/runtime monitoring.

Detailed approved plan: `docs/superpowers/plans/2026-08-07-performance-foundation.md`.

## M1 — Notch Core hardening and interaction

Status: after P0 baseline

- measure and investigate replacing global `.mouseMoved` observation with reliable `NSTrackingArea`/window-local tracking;
- accept replacement only if notch/hover correctness stays PASS and measured resource/input-observation profile is equal or better;
- click/pin interaction policy;
- tuned expansion/collapse animation and reduced-motion behavior;
- gesture model (hover/click/scroll/swipe) designed independently while benchmarking public NotchNook behavior;
- multiple displays and active-screen migration;
- fullscreen/Space behavior;
- screen-configuration change handling;
- notchless-screen mode decision/prototype;
- expanded automated + real-hardware acceptance matrix.

No `CGEventTap`, Accessibility, Input Monitoring, or broader capture merely for hover convenience.

## M2 — Shelf

- drag files into/out of Shelf;
- sandbox-compatible user-selected/security-scoped access;
- source file is never deleted when removed from Shelf;
- stale-reference handling and optional cleanup;
- deterministic ownership/source-preservation/error tests.

## M3 — Snippets

- sandbox-local store;
- groups/search/copy;
- privacy mode;
- direct paste only after explicit Accessibility/security decision and with copy-only fallback;
- persistence/search/escaping/masking/denied-state tests.

## M4 — Calendar

- EventKit adapter;
- next-event UI;
- explicit permission denial/availability states;
- deterministic adapter tests + minimal real permission acceptance.

## M5 — Translator

- Apple Translation framework where available;
- language handling/swap/copy;
- optional clipboard translation;
- no direct app network translation without separate security review.

## M6 — Media / Yandex Music

- provider abstraction + deterministic fake-provider tests;
- Yandex Music desktop compatibility probe on macOS 26.6;
- metadata/artwork/play-pause/previous-next/timeline where available;
- prefer public/sandbox-compatible integration;
- isolated MediaRemote fallback only after security, compatibility, and performance review;
- never weaken Hardened Runtime/library validation or add broad input capture.

## M7 — Product shell

- settings;
- narrowly scoped shortcuts;
- launch-at-login through supported macOS APIs rather than custom agents/daemons;
- module ordering/enable-disable;
- accessibility/privacy/security settings.

## M8 — Trusted distribution and maintenance (optional)

- only if Apple Developer Program becomes worthwhile;
- validate Developer ID/notarization/stapling/Gatekeeper path on a new version;
- never replace an existing Personal Release tag;
- authenticated update-channel design before any self-update;
- recurring dependency/action/toolchain/security/performance review.
