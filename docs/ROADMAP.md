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

Status: **ACCEPTED**
Target: `v0.1.0 — Personal build`

Purpose: publish versioned personal-use builds through GitHub Releases without paid Apple Developer membership while preserving security, provenance, and immutable history.

Completed:

- deterministic release-policy tests are green;
- `Personal Release` workflow is manual-only and accepts only exact protected `main`;
- App Sandbox/Hardened Runtime/ad-hoc signature/system-library/DMG gates are repeated before publication;
- no Apple signing/notary secrets or trusted-distribution claims exist in Personal Release;
- SHA-256 and `build-metadata.json` are published beside the DMG;
- existing tags/releases cannot be overwritten (`--clobber`/release upload prohibited);
- future `Trusted Release` workflow is separately named and cannot overwrite Personal versions;
- release docs clearly explain standard Finder / Privacy & Security → Open Anyway path without weakening Gatekeeper;
- protected implementation PR was squash-merged;
- manual `Personal Release` workflow published immutable `v0.1.0` from accepted `main`;
- `NH-PERSONAL-RELEASE-001` passed on the target MacBook/macOS 26.6 using the downloaded GitHub Release DMG.

Apple Developer Program membership is **not** a blocker. Developer ID/notarization is intentionally deferred to an optional future Trusted Release tier.

## P0 — Performance Foundation

Status: **ACCEPTED EVIDENCE; PR #5 FINAL REVIEW/MERGE GATE**

Purpose: make CPU, RAM, threads, wakeups/background work, artifact size, and lifecycle efficiency measurable release requirements before feature-heavy M1 work.

Completed evidence:

- root `PERFORMANCE.md` contract;
- deterministic CI audit against unreviewed polling/timers/sleeps/display links/busy loops;
- standard-library process-metric parser/aggregation and budget-comparison tests;
- development-only target-Mac baseline harness with explicit source/tool provenance;
- Darwin-compatible thread measurement through `ps -M` and stability start/end/quartile evidence;
- reproducible macOS 26.6 scenario contracts for idle, hover/active, stability, artifact size, and deterministic state stress;
- 100,000-transition pure Swift state/pointer stress coverage with no wall-clock threshold;
- CI runner compatibility/schema smoke without CPU/RAM magnitude gating;
- security/package checks proving performance tooling is not bundled as runtime telemetry;
- accepted macOS 26.6 runtime baseline against immutable Personal Release `v0.1.0`;
- exact immutable `v0.1.0` release sizes from published `build-metadata.json`;
- complete machine-readable `performance/baseline-v0.1.0.json`;
- conservative evidence-based CPU/RSS/thread target-Mac ceilings;
- RED→GREEN fail-closed release-size checker covering relative allowance, absolute ceiling, schema mismatch, and missing metrics;
- deterministic shared-CI artifact-size gate with 15% relative allowance plus independent absolute ceilings.

Accepted runtime evidence:

- `NH-PERF-IDLE-001`: CPU median/max `0.0% / 0.7%`, RSS max `33,808 KiB`, threads max `4`;
- `NH-PERF-HOVER-001`: CPU median/max `5.95% / 22.3%`, RSS max `38,816 KiB`, threads max `7`;
- `NH-PERF-STABILITY-001`: CPU median/max `0.0% / 6.8%`, RSS max `34,384 KiB`, threads max `7`;
- 10-minute stability RSS `34,256 -> 30,544 KiB`, delta `-3,712 KiB`, so no sustained RSS accumulation was observed.

Accepted size evidence:

- executable: `220,560 B`;
- app aggregate: `223,555 B`;
- DMG: `73,955 B`;
- release source commit: `8e913dcddfdec7d9aa920df8c37afb23b8c40884`;
- published DMG SHA-256: `cf53be6081b1836551fcbbb91b85fed800de4c089451961f3c6a21f6b77768bc`.

P0 keeps runtime CPU/RSS/thread thresholds on the target Mac and enforces only deterministic/reproducible artifact-size budgets in shared CI.

Exit gate remaining: final CI on exact PR head, independent read-only review, then squash-merge PR #5 if clean. No additional target-Mac measurements are required for P0.

Detailed approved plan: `docs/superpowers/plans/2026-08-07-performance-foundation.md`.
Authoritative runtime policy and accepted values: root `PERFORMANCE.md`.
Machine-readable baseline: `performance/baseline-v0.1.0.json`.

## M1 — Notch Core hardening and interaction

Status: **NEXT AFTER P0 MERGE**

Interaction contract: `docs/specs/M1_NOTCH_INTERACTION.md`.

- measure and investigate replacing global `.mouseMoved` observation with reliable `NSTrackingArea`/window-local tracking, using the accepted P0 hover resource baseline as the comparison point;
- accept replacement only if notch/hover correctness stays PASS and measured resource/input-observation profile is equal or better;
- add a short, cancellable **hover dwell delay** before compact → expanded activation so normal pointer transit through the notch (including movement toward another display) does not immediately open the panel;
- initial dwell candidate: **120 ms**, to be tuned from real MacBook evidence within roughly 100–150 ms rather than hardcoded blindly;
- implement dwell as event-driven single pending work item: no polling, no repeating timer, deterministic cancellation/race tests;
- provide **one trackpad haptic event on a successful user-initiated compact → expanded transition** through public `NSHapticFeedbackManager.defaultPerformer`;
- no haptic on cancelled/quick transit, duplicate pointer events, expanded retention, collapse, programmatic/layout transitions, or stale callbacks;
- haptic must respect macOS/current-device/user settings and must not introduce private APIs, synthetic input, Accessibility, custom drivers, or retry loops;
- click/pin interaction policy;
- tuned expansion/collapse animation and reduced-motion behavior;
- gesture model (hover/click/scroll/swipe) designed independently while benchmarking public NotchNook behavior;
- multiple displays and active-screen migration;
- fullscreen/Space behavior;
- screen-configuration change handling;
- notchless-screen mode decision/prototype;
- expanded automated + real-hardware acceptance matrix, including `NH-HOVER-DELAY-001/002` and `NH-HAPTIC-001/002`.

No `CGEventTap`, Accessibility, Input Monitoring, or broader capture merely for hover convenience or haptic feedback.

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
