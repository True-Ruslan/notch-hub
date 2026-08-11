# Testing

## Goal

Automate every deterministic behavior that can be validated reliably. Manual acceptance is reserved for physical notch geometry, real pointer feel, compositor/window-animation continuity, physical haptic feel, exact macOS trust/permission surfaces, third-party app integration, and target-hardware resource measurements.

A green pipeline is necessary but is not proof of real-device UX or target-Mac efficiency. Manual success likewise never replaces deterministic automated coverage that can reasonably exist.

## Required CI gate

Protected-branch checks:

- `macOS 26 compatibility`;
- `Build, test and package` (dependent on the macOS 26 job).

Current CI validates:

1. Swift package structure.
2. Personal/Trusted release-policy tests.
3. Performance-policy/parser/budget tests, including explicit M6.5 feature-size policy.
4. Media bridge/probe policy tests.
5. Strict Swift formatting.
6. shell/plist syntax.
7. executable repository security baseline.
8. deterministic runtime performance source audit.
9. macOS 26 compilation with warnings as errors.
10. complete Swift test suite on macOS 26.
11. production media probe/candidate build and verification.
12. package-runner warnings-as-errors compilation.
13. complete Swift tests with coverage instrumentation.
14. release app/DMG packaging.
15. semantic version/build-number and source/media provenance stamping.
16. nested/top-level code-signature verification.
17. Hardened Runtime verification.
18. exact effective App Sandbox entitlement verification.
19. system-library-only application executable dependency inspection.
20. shipping media preflight/provenance verification.
21. deterministic executable/app/DMG size capture.
22. fail-closed feature-size comparison against immutable P0 baseline plus the active reviewed feature envelope.
23. short shared-runner performance harness compatibility/schema smoke with no CPU/RSS/thread magnitude gate.
24. artifact upload.

Do not lower assertions, delete useful tests, weaken security/release/performance policy, widen accepted budgets, or weaken production behavior merely to make CI green.

## Test design

Tests should:

- state one behavior in the name;
- assert externally meaningful results;
- avoid arbitrary sleeps;
- include boundary/error/denied/stale-callback cases;
- reproduce deterministic regressions before fixes where practical;
- test exact physical-coordinate boundaries when hardware behavior depends on inclusive/exclusive edges;
- never substitute a nearby interior point for a named physical-edge scenario;
- never fabricate RED when behavior is already correctly testable;
- use injected schedulers/output closures around OS boundaries;
- intentionally invoke cancelled/stale callbacks when race safety is part of the contract;
- keep shared-runner runtime magnitudes out of tight target-hardware gates.

No arbitrary global coverage percentage is used.

## Security/release testing boundary

Deterministic checks cover:

- strict SemVer/tag derivation and immutable release semantics;
- mandatory Personal Release trust warning and Gatekeeper-bypass rejection;
- unprivileged public/fork PR CI;
- App Sandbox + Hardened Runtime;
- exact production process allowlist;
- no arbitrary shell/executable/private-loading surface;
- system-only application executable linkage;
- pinned media resource provenance;
- no unexpected entitlement/permission expansion;
- release workflow isolation from untrusted PR execution.

`SECURITY.md` is authoritative.

## Performance testing boundary

`PERFORMANCE.md` and `performance/baseline-v0.1.0.json` are authoritative.

The immutable `v0.1.0` artifact baseline remains:

- executable `220,560 B`;
- app `223,555 B`;
- DMG `73,955 B`.

Intentional feature growth is handled by separately reviewed provenance-backed envelopes. M6.4 and M6.5 budgets do not rewrite the P0 baseline.

Shared GitHub runners validate deterministic performance policy/schema/package behavior only. CPU/RSS/thread target acceptance is based on real-hardware evidence and same-session/within-run methodology where required.

## M1 interaction/transition contract

Authoritative specification: `docs/specs/M1_NOTCH_INTERACTION.md`.

Deterministic coverage proves:

- quick transit shorter than 120 ms does not expand or haptic;
- deliberate hover emits one eligible expansion intent at threshold;
- duplicate pointer events keep one pending activation;
- cancellation/stale callback cannot later win;
- re-entry receives a fresh dwell;
- expanded retention/collapse is deterministic;
- compact activation uses inclusive 4 pt left/right/bottom and 0 pt top boundaries;
- `NotchPanelTransitionCoordinator` is the sole transition authority;
- stale/reversed completions cannot win;
- Reduce Motion retarget creates no duplicate haptic;
- 10,000 reversal stress retains only latest-generation authority;
- AppKit owns outer clipping/chrome and exact compact/expanded geometry;
- pointer monitor owns one local + one global `.mouseMoved` monitor and removes them idempotently;
- no per-mouse-event Swift concurrency task is allocated;
- no polling/repeating timer/display-link/sleep loop is introduced.

Accepted physical M1 matrix:

| ID | Scenario | Status |
| --- | --- | --- |
| `NH-NOTCH-001` | Physical-notch compact geometry | **PASS** |
| `NH-HOVER-001` | Deliberate hover opens once | **PASS** |
| `NH-HOVER-002` | Expanded retention | **PASS** |
| `NH-HOVER-003` | Exit collapses once | **PASS** |
| `NH-HOVER-DELAY-001` | Quick transit / second-display transit | **PASS** |
| `NH-HOVER-DELAY-002` | 120 ms deliberate hover | **PASS** |
| `NH-HOVER-TOP-001` | Exact top screen-edge activation | **PASS** |
| `NH-HAPTIC-001` | Eligible deliberate expansion | **PASS** |
| `NH-HAPTIC-002` | Cancel/retain/collapse | **PASS** |
| `NH-VISUAL-001...003` | Physical chrome and repeated cycles | **PASS** |
| `NH-ANIM-001...004` | Normal/reversed/rapid transitions | **PASS** |
| `NH-MOTION-001...002` | Reduce Motion behavior | **PASS** |
| Startup pointer overlap | No startup-only expansion/haptic | **PASS** |
| `NH-SPACE-001` | Spaces/fullscreen policy | Planned later M1 |
| `NH-DISPLAY-001` | Active-display migration | Planned later M1 |

Historical exact artifacts and RED/GREEN details remain in Git history and `CHANGELOG.md`.

## Universal Media acceptance hierarchy

Detailed acceptance ledgers:

- M6.1: `docs/testing/MEDIA_BRIDGE_PROBE_ACCEPTANCE.md`;
- M6.3: `docs/testing/PRODUCTION_MEDIA_TRANSPORT_ACCEPTANCE.md`;
- M6.4: `docs/testing/SHIPPING_MEDIA_COMPOSITION_ACCEPTANCE.md`;
- M6.5: `docs/testing/MEDIA_UI_ACCEPTANCE.md`.

### M6.1

Status: **ACCEPTED**.

Target testing established system Now Playing feasibility under Sandbox + Hardened Runtime, authoritative capability states, real commands, source switch/disappearance behavior, no sensitive permission prompts, clean teardown and bounded resource behavior.

### M6.2

Status: **ACCEPTED AND MERGED**.

Deterministic tests cover normalized media state, ordering, provider/controller/bridge lifecycle, typed commands, stale callbacks and bounded restart/fail-closed behavior.

### M6.3

Status: **ACCEPTED AND MERGED**.

All `NH-MEDIA-PROD-001...013` gates pass, including Yandex Music/Yandex Browser observation, real toggle/previous/next/seek, no sensitive permission prompts, bounded teardown and target resource evidence.

### M6.4

Status: **ACCEPTED AND MERGED**.

All `NH-MEDIA-SHIP-001...010` gates pass. Physical evidence confirms zero adapter throughout compact steady/stability, one expected adapter after settled expansion, clean normal teardown and no sensitive permission prompts.

### M6.5 — Media-first UI

Status: **ACCEPTED ON TARGET MAC — ALL `NH-MEDIA-UI-001...011` PASS**.

Frozen physical candidate:

- source `431d9fbaf1ff5ba98f2ceec09732acafe5f65794`;
- CI #763 / run `31539442148` — both required jobs PASS on exact source after retrying one external runner TLS failure;
- 194 Swift tests — PASS;
- shipping artifact ID `9120231721`;
- Actions digest `sha256:0d18a0c9ce5305b90808f0937531211094b85947ce96b2afd0a2c4020e4e7007`;
- DMG SHA-256 `3993330bf57ac86ead949215ba5370a0a33ec6b8f6a17f1d65baa30c41f5f6ad`.

Deterministic/policy coverage proves:

- Core composition seam does not introduce a media dependency into `NotchHubCore`;
- media presentation maps authoritative state without metadata/capability fabrication;
- fresh runtime events may replace retained presentation without cross-runtime raw-sequence comparison;
- runtime attaches/detaches presentation callbacks in lifecycle-safe order;
- UI exposes only typed click commands in M6.5;
- compact wings are geometry inputs to the existing transition authority;
- no polling/timer/display-link/global scroll monitor is introduced;
- M6.5 size envelope is explicit, provenanced and fail-closed.

Physical target acceptance confirmed:

| ID | Scenario | Status |
| --- | --- | --- |
| `NH-MEDIA-UI-001` | Cold exact-notch compact / zero adapter | **PASS** |
| `NH-MEDIA-UI-002` | Expanded active session -> Media-first UI | **PASS** |
| `NH-MEDIA-UI-003` | Playing/paused presentation | **PASS** |
| `NH-MEDIA-UI-004` | Partial metadata/artwork fallback | **PASS** |
| `NH-MEDIA-UI-005` | Capability-driven previous/next + real clicks | **PASS** |
| `NH-MEDIA-UI-006` | Trustworthy static progress / no periodic worker | **PASS** |
| `NH-MEDIA-UI-007` | Media disappears while expanded -> Home, no collapse | **PASS** |
| `NH-MEDIA-UI-008` | Retained 36 pt compact wings / adapter absent | **PASS** |
| `NH-MEDIA-UI-009` | Fresh re-expansion replaces retained state | **PASS** |
| `NH-MEDIA-UI-010` | Typed command/security/transition boundary | **PASS** |
| `NH-MEDIA-UI-011` | Full Mac16,8/macOS 26.6 Yandex Music + Yandex Browser acceptance | **PASS** |

Physical acceptance also confirmed no Accessibility, Input Monitoring, Automation/Apple Events or Screen Recording prompts and no orphan adapter after normal Quit.

Documentation-only commits after frozen source `431d9fbaf1ff5ba98f2ceec09732acafe5f65794` require fresh exact-head CI but do **not** require another physical run because they do not alter the tested application artifact.

## Next testing contract

The next Universal Media slice must establish `NH-MEDIA-GESTURE-*` IDs before production changes. Coverage must include:

- local-only gesture state machine;
- no global scroll monitor;
- gesture cancellation/reversal boundaries;
- haptic eligibility and no duplicate feedback;
- seek only when authoritative capability is supported;
- bounded typed seek values;
- no periodic progress worker;
- target-Mac gesture feel, haptic feel, actual seek correctness and regression checks.

The invariant remains unchanged: hardware success does not replace deterministic tests, and green CI does not claim physical behavior it cannot observe.