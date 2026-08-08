# Testing

## Goal

Automate every deterministic behavior that can be validated reliably. Manual acceptance is reserved for physical notch geometry, real pointer feel, exact macOS trust/permission surfaces, third-party app integration, target-hardware resource measurements, and other behavior CI cannot honestly reproduce.

A green pipeline is necessary but is not proof of real-device UX or target-Mac efficiency. Conversely, manual success never replaces deterministic automated coverage that can reasonably exist.

## Required CI gate

Protected-branch check: `Build, test and package`, dependent on `macOS 26 compatibility`.

Current CI validates:

1. Swift package structure.
2. deterministic Personal/Trusted release-policy unit/static tests.
3. deterministic performance-policy/parser/aggregation/budget tests.
4. project-configured strict Swift formatting.
5. shell/plist syntax.
6. executable repository security baseline (`scripts/security-audit.sh`).
7. deterministic runtime performance-policy audit (`scripts/performance_policy.py audit Sources`).
8. macOS 26 compilation with warnings as errors.
9. macOS 26 complete Swift test suite.
10. packaging-runner compilation with warnings as errors.
11. complete Swift tests with coverage instrumentation, including deterministic state-stress coverage.
12. release app/DMG packaging.
13. semantic version/build-number stamping.
14. ad-hoc code-signature verification.
15. Hardened Runtime verification.
16. exact effective App Sandbox entitlement verification.
17. linked-library inspection (system libraries only at the current milestone).
18. DMG integrity with `hdiutil verify`.
19. deterministic executable/app/DMG byte-size capture.
20. fail-closed comparison of candidate artifact sizes against `performance/baseline-v0.1.0.json`.
21. short development-harness compatibility/schema smoke on a shared runner, with no CPU/RAM magnitude gate.
22. artifact upload.

Do not lower assertions, delete useful tests, weaken security/release/performance policy, or weaken production behavior merely to make CI green.

## Release-policy test boundary

`scripts/test_release_policy.py` and `scripts/release_policy.py` cover deterministic distribution rules:

- strict release SemVer/tag derivation;
- versioned Personal Release notes exist and lead with the mandatory not-notarized warning;
- unsafe Gatekeeper-bypass instructions are rejected;
- provenance/build metadata has an exact schema and validated source/checksum/size inputs;
- Personal Release requires manual `main` publication, ad-hoc signature verification, Sandbox/Hardened Runtime, checksum/provenance, and immutable `gh release create` semantics;
- Personal Release rejects Apple signing/notary secrets, `environment: release`, `--clobber`, release uploads, or Gatekeeper-bypass commands;
- Trusted Release remains a separate Developer ID/notarization tier;
- ambiguous legacy `release.yml` is prohibited.

The same Personal Release boundary is rechecked by `scripts/security-audit.sh` so a workflow cannot bypass unit tests simply by being omitted from the normal test command.

## Security test boundary

The executable security baseline verifies, among other things:

- zero external Swift runtime dependencies;
- no runtime subprocess/shell execution APIs;
- no direct network/WebKit surface;
- no dynamic code loading/private-symbol bridging primitives;
- no global keyboard/button/drag/scroll/modifier monitoring;
- no embedded common credential/private-key formats;
- exactly the expected sandbox entitlement set;
- no dangerous Hardened Runtime exception entitlements;
- no LaunchAgents/LaunchDaemons/privileged-helper surfaces;
- immutable full-SHA GitHub Action references;
- no `pull_request_target` workflows;
- explicit Personal/Trusted release-tier boundaries and immutable release assets;
- performance measurement tooling remains development-only and is not copied/referenced into the application bundle.

Future capabilities that legitimately require a currently forbidden surface must update policy and tests explicitly in the same reviewed PR.

## Performance test boundary

`PERFORMANCE.md` is authoritative for runtime resource policy, accepted target-Mac values, budgets, and methodology. `performance/baseline-v0.1.0.json` is the canonical machine-readable baseline.

`scripts/test_performance_policy.py` and `scripts/performance_policy.py` deterministically cover:

- forbidden unreviewed polling/timer/sleep/display-link primitives in runtime Swift sources;
- strict `/bin/ps` CPU/RSS/thread sample parsing;
- Darwin `ps -M` thread-row parsing;
- median/max aggregation without inventing empty measurements;
- stability start/end/quartile evidence;
- baseline-harness configuration validation;
- deterministic flat runtime-budget comparison and malformed/non-finite input rejection;
- release-size budget success below both limits;
- named absolute-ceiling failure;
- named relative-regression failure;
- fail-closed baseline schema/version and required-metric validation;
- fail-closed `check-size-budget` CLI behavior.

`scripts/perf-baseline.py` is development/release tooling only. CI runs only a short compatibility/schema smoke and must not enforce runner CPU/RSS/thread values. Canonical runtime values come from the target MacBook/macOS 26.6 under the stable scenarios below. Artifact sizes are deterministic enough to be enforced in shared CI.

## Test design

Prefer pure deterministic policies for geometry, parsing, permissions, state, transitions, release rules, resource-policy rules, time-dependent interaction decisions, and AppKit/SwiftUI boundary configuration. AppKit/SwiftUI/GitHub orchestration should be thin around tested policies.

Tests should:

- state one behavior in the name;
- assert externally meaningful results;
- avoid mocks unless an OS/third-party boundary cannot reasonably be exercised;
- avoid arbitrary sleeps in unit tests;
- include boundary/error/denied cases;
- reproduce reported deterministic regressions before fixes where practical;
- never fabricate a RED phase if a behavior is already correctly testable;
- prefer deterministic fake adapters around external boundaries over live services;
- inject a monotonic clock/scheduler for dwell/debounce behavior instead of waiting in real time;
- inject a haptic output abstraction so tests assert request count/reason without requiring physical trackpad vibration;
- never use noisy shared-runner timing values as tight performance gates.

No arbitrary global code-coverage percentage is used. Coverage instrumentation is enabled to find untested deterministic logic; component-specific thresholds may be introduced only where they remain meaningful.

## P0 performance contracts

| ID | Scenario | Expected result | Automation |
| --- | --- | --- | --- |
| `NH-PERF-IDLE-001` | Accepted Personal Release, 10 s warmup then untouched compact mode for 60 s sampled every 1 s | Stable idle CPU/RSS/thread summary; no app-initiated periodic work discovered by policy/review | Sampling automated on target Mac; interaction/manual environment control |
| `NH-PERF-HOVER-001` | 60 s sampler while repeating documented 5-second expand/retain/collapse cycle | Active summary captured without synthesized input; accepted hover behavior remains intact | Sampling automated; interaction manual |
| `NH-PERF-STABILITY-001` | 10 min untouched run sampled every 5 s | No unexplained sustained RSS/thread growth | Sampling automated on target Mac; interpretation reviewed |
| `NH-PERF-SIZE-001` | Accepted release executable/app/DMG | Exact byte sizes recorded in canonical baseline and later candidates kept within reviewed budget | Release metadata + shared-CI deterministic gate |
| `NH-PERF-STATE-001` | Exactly 100,000 pure pointer/presentation decisions | Correct final/count invariants with no retained history/state growth API; no wall-clock assertion | Fully automated Swift test |

All P0 baseline inputs are accepted. Shared runner CPU/RAM/thread values are never substituted for target-Mac acceptance. Canonical values and budgets are stored in `performance/baseline-v0.1.0.json` and explained in `PERFORMANCE.md`.

## M1 delayed-hover, haptic, and notch-visual contract

Authoritative interaction specification: `docs/specs/M1_NOTCH_INTERACTION.md`.

The current PR #10 deterministic suite proves:

- pointer transit shorter than the dwell threshold does not expand and emits zero haptic requests;
- setup-time/current-pointer synchronization does not schedule activation or haptic without a subsequent user mouse-move event;
- deliberate hover expands only when the threshold completes;
- one successful user-initiated `compact -> expanded` transition emits exactly one haptic request;
- repeated `mouseMoved` events do not create duplicate pending work or duplicate haptics;
- a cancelled dwell cannot fire later from a stale callback;
- re-entry starts a fresh dwell instead of reusing elapsed time;
- expanded retention does not retrigger haptic feedback;
- collapse followed by a new deliberate hover may produce one new haptic;
- programmatic expansion does not emit haptic feedback;
- controller/state invalidation cancels pending dwell work;
- pointer-monitor start is idempotent and owns exactly one local plus one global `.mouseMoved` monitor;
- pointer-monitor invalidation removes both monitor tokens exactly once;
- the revised compact activation policy rejects a pointer only 2 pt inside the physical compact edge and accepts the 4 pt depth candidate;
- hardware-notch layout resolves a transparent compact app surface so the real notch defines its visible rounded silhouette;
- hardware-notch expanded content begins at `compactFrame.height + 12 pt`, while no-notch fallback keeps the normal 20 pt inset;
- non-notch compact fallback remains opaque;
- panel-frame presentation changes no longer run an independent AppKit animation that can visibly diverge from presentation state;
- the hosting view tracks panel bounds in both width and height while retaining `sizingOptions == []`;
- outer panel clipping has one owner at the AppKit boundary: the hosting view is layer-backed, `masksToBounds == true`, and uses a continuous `12 pt` compact / `22 pt` expanded radius;
- the AppKit mask/radius invariant survives **32 repeated expanded -> compact cycles** in deterministic regression coverage.

The implementation remains event-driven: no polling, no repeating timer, and at most one pending activation work item. Production haptic output is public AppKit. The revised tactile candidate is one `.levelChange` request per successful expansion; AppKit exposes patterns rather than an arbitrary strength scalar, so stronger feedback is not simulated by duplicate haptic requests.

The `120 ms` dwell, `4 pt` activation inset, and `.levelChange` pattern are target-Mac candidates until the revised physical acceptance cycle. Deterministic tests validate policy and backing-layer invariants but cannot declare the physical rendering or tactile feel accepted.

## Real-hardware / distribution acceptance matrix

Record results in `docs/PROJECT_STATE.md`.

| ID | Scenario | Expected result | Automation |
| --- | --- | --- | --- |
| `NH-BOOT-001` | Install/open CI-produced DMG | App launches and panel appears | Packaging automated; launch UX manual |
| `NH-OS26-001` | Run accepted test build on target macOS 26.6 | App launches, sandboxed runtime works, no unexpected permission prompt | macOS 26 CI automated; exact 26.6 hardware manual |
| `NH-NOTCH-001` | Observe compact panel on hardware-notch MacBook | Center/width match physical notch | Geometry unit-tested; physical alignment manual |
| `NH-HOVER-001` | Enter compact activation region and hold >=3 s | One expansion; no oscillation | Pointer policy unit-tested; AppKit delivery manual |
| `NH-HOVER-002` | Move within expanded panel | Remains expanded | Retention unit-tested; AppKit delivery manual |
| `NH-HOVER-003` | Move outside retention region | Content and actual panel frame collapse once and remain compact | Policy/sizing ownership automated; physical window behavior manual |
| `NH-SANDBOX-001` | Exercise normal panel in Sandbox build | No crash/unexpected permission/loss of behavior | Entitlement/signing automated; runtime manual |
| `NH-PERSONAL-RELEASE-001` | Download versioned Personal Release from GitHub | Published SHA-256 matches; installation uses only standard Finder / Privacy & Security approval; app opens on macOS 26.6; accepted notch/hover scenarios remain PASS | Release policy/checksum/provenance automated; downloaded quarantine/trust path + hardware behavior manual once for first personal pipeline/version |
| `NH-HOVER-DELAY-001` | Move pointer through/near notch toward another display without intentionally stopping | Transit completes before dwell/depth threshold; panel stays compact; zero haptic feedback | Deterministic scheduler + edge-depth policy tests; real cross-display pointer feel manual |
| `NH-HOVER-DELAY-002` | Deliberately move at least slightly inside and hover over compact notch | Panel expands once after a short perceptible-but-fast dwell, with no flicker/oscillation | State/time/depth policy automated; final dwell/depth tuning manual |
| `NH-HAPTIC-001` | Deliberately hover using a compatible Force Touch trackpad while touching it | Exactly one appropriately noticeable tactile event accompanies successful expansion | Haptic request count automated through fake performer; physical tactile result manual |
| `NH-HAPTIC-002` | Quick/cancelled hover, retention movement, and collapse | No haptic feedback | Deterministic policy/output tests automated; physical negative check manual |
| `NH-VISUAL-001` | Observe compact NotchHub on the physical-notch display | Native physical notch keeps its rounded silhouette; no app-painted black corner pixels make it look square | Hardware/no-notch background policy automated; exact silhouette manual |
| `NH-VISUAL-002` | Deliberately hold pointer in the expanded panel | Primary controls are visible below the physical notch during active hover, not only after exit/collapse begins | Expanded content inset + frame-state behavior deterministic; physical occlusion/visibility manual |
| `NH-VISUAL-003` | Open and collapse the expanded panel repeatedly, at least 20 cycles on the target Mac | Rounded panel chrome remains rounded after every cycle; no transition to square bottom corners | AppKit layer mask/radius + 32-cycle deterministic regression automated; exact physical rendering manual |
| `NH-GATEKEEPER-TRUSTED-001` | Future: download Trusted Release | Gatekeeper identifies `Notarized Developer ID` without personal-build approval workaround | Trusted workflow automated; normal downloaded path manual when tier is first adopted |
| `NH-SPACE-001` | Switch Spaces/fullscreen | Behavior matches M1 policy | Planned M1 |
| `NH-DISPLAY-001` | Connect/move between displays | Correct target-display geometry/migration | Planned M1 |

## Acceptance history

### 2026-08-07 — cycle 1

- `NH-BOOT-001`: PASS enough to run application.
- `NH-HOVER-001`: FAIL — compact/expanded oscillation.
- RED `eb4fb4d`: expected failing retention regression.
- GREEN `eff9bde`: raw SwiftUI hover authority replaced by deterministic screen-space policy.

### 2026-08-07 — cycle 2

Target MacBook/macOS 26.6:

- `NH-OS26-001`: PASS.
- `NH-NOTCH-001`: FAIL — compact panel a few pixels too wide.
- `NH-HOVER-001`: PASS.
- `NH-HOVER-002`: PASS.
- `NH-HOVER-003`: FAIL — compact content while expanded black panel frame remained.
- `NH-SANDBOX-001`: earlier report was inferred as PASS by matrix order because the source message repeated the last label; that ambiguity remains documented rather than rewritten.

RED `c518326` produced exactly the two intended CI failures (`180` vs `176`; hosting sizing options `7` vs empty). GREEN `3bb1bbb` fixed both. CI then reached **10/10 PASS** plus full security/package gates.

### 2026-08-07 — cycle 3 / M0 final acceptance

Target MacBook/macOS 26.6:

- `NH-NOTCH-001`: **PASS**.
- `NH-HOVER-001`: **PASS**.
- `NH-HOVER-002`: **PASS**.
- `NH-HOVER-003`: **PASS**.

**M0 mandatory physical acceptance: PASS.**

### 2026-08-07 — cycle 4 / Personal Release acceptance

Downloaded immutable GitHub Personal Release `v0.1.0` on the target MacBook/macOS 26.6:

- `NH-PERSONAL-RELEASE-001`: **PASS**.
- published checksum/install/standard macOS first-launch path: **PASS**;
- application launch: **PASS**;
- accepted `NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, `NH-HOVER-003` behavior on the downloaded release: **PASS**.

**R0.1 Personal Release acceptance: PASS.**

### 2026-08-07 — cycle 5 / P0 runtime baseline

Accepted Personal Release `v0.1.0` (`8e913dcddfdec7d9aa920df8c37afb23b8c40884`) on target macOS 26.6 / `Mac16,8`, measured using P0 tooling commit `dfd4f87f8e5be04b467172d720d22bfc054c06d0`:

- `NH-PERF-IDLE-001`: **BASELINE ACCEPTED** — 60 samples / `60.017 s`; CPU median/max `0.0% / 0.7%`; RSS median/max `33,648 / 33,808 KiB`; threads `4 / 4`;
- `NH-PERF-HOVER-001`: **BASELINE ACCEPTED** — 60 samples / `60.018 s`; CPU median/max `5.95% / 22.3%`; RSS median/max `38,456 / 38,816 KiB`; threads `6 / 7`;
- `NH-PERF-STABILITY-001`: **BASELINE ACCEPTED** — 120 samples / `600.013 s`; CPU median/max `0.0% / 6.8%`; RSS median/max `30,992 / 34,384 KiB`; threads `3 / 7`;
- stability RSS `34,256 -> 30,544 KiB`, delta `-3,712 KiB`: **no sustained RSS growth detected**;
- stability threads `4 -> 5`, max `7`: bounded transient behavior; no runaway thread accumulation detected.

Initial target-Mac CPU/RSS/thread ceilings are recorded in `PERFORMANCE.md` with conservative headroom and are not used as shared-runner CI thresholds.

### 2026-08-07 — cycle 6 / P0 size baseline and budget gate

Immutable `v0.1.0` release metadata supplied the exact `NH-PERF-SIZE-001` baseline:

- executable: `220,560 B`;
- app aggregate: `223,555 B`;
- DMG: `73,955 B`;
- source commit: `8e913dcddfdec7d9aa920df8c37afb23b8c40884`;
- DMG SHA-256: `cf53be6081b1836551fcbbb91b85fed800de4c089451961f3c6a21f6b77768bc`.

RED CI #91 failed exactly because the new release-size comparison API did not yet exist. GREEN CI #94 then passed **22/22 Python performance-policy tests**, security/policy audits, **11/11 Swift tests**, packaging/signature/Sandbox/Hardened Runtime/DMG checks, deterministic size capture, the new release-size budget gate, harness smoke, and artifact upload.

CI #94 candidate sizes were executable `214,016 B`, app `217,012 B`, DMG `73,378 B`; all passed the canonical 15% relative allowance and absolute ceilings.

**P0 Performance Foundation acceptance: PASS.**

### 2026-08-08 — cycle 7 / M1 delayed hover + haptic deterministic core

PR #10 uses explicit RED → GREEN evidence:

- RED commit `079e82bcc93dd9d664a5b4200806dd2ee858bd72` added interaction tests before production coordinator/scheduler/haptic APIs existed;
- RED CI #147 failed on those missing production APIs and also exposed an independent missing `Foundation` import in the test harness;
- test-only commit `c972198fc8d6e33b588e34fb58d4732f1f4b0808` corrected the import without adding production behavior;
- RED CI #148 then failed cleanly only on the still-missing interaction production types;
- pointer-monitor lifecycle tests were added before their production abstraction; RED CI #150 failed on both intended seams;
- GREEN implementation introduced one-shot dwell scheduling, generation/stale-callback validation, public AppKit haptic output, and explicit monitor lifecycle;
- CI #157 passed **24/24 Swift tests**, release/performance policy, runtime performance audit, security, warnings-as-errors, packaging/signature/Sandbox/Hardened Runtime/DMG checks, but failed the unchanged P0 size gate because executable `254,000 B` exceeded the 15% threshold `253,644 B` by `356 B`;
- the P0 budget was not weakened; internal runtime metadata was reduced while all behavioral tests stayed unchanged;
- CI #158 on implementation head `6b0173b79e457a8749c6f8675681efb8850e4e9e` passed all gates with executable `251,856 B`, app `254,853 B`, and DMG `83,072 B`;
- independent change review found that `show()` could otherwise interpret setup-time current mouse location as a normal activation event and request an unintended launch haptic;
- RED commit `0b777f8009c6bd76026fb70585a1d9d8debc034f` added `setupPointerSynchronizationInsideCompactDoesNotActivateOrHaptic`; CI #165 failed exactly on the absent `allowActivation` seam;
- GREEN implementation separated setup pointer synchronization from user movement; CI #167 passed **25/25 Swift tests** and every release/security/performance/package gate with executable `251,872 B`, app `254,869 B`, and DMG `83,036 B`.

This established deterministic readiness for the first physical M1 cycle, not M1 acceptance.

### 2026-08-08 — cycle 8 / first M1 target-Mac hardware feedback

Target MacBook/macOS 26.6:

- the requested delayed-hover/haptic interaction checks were reported **PASS**;
- expanded visual state: **FAIL** — the panel became a large black surface while primary controls were not visible during the active hover; controls appeared only as pointer exit/collapse began and were positioned under the physical notch;
- compact physical-notch silhouette: **FAIL** — app-painted black corner pixels protruded into the physical notch's rounded-corner cutouts, making the notch appear square;
- haptic: functional, but user requested a slightly more noticeable feel;
- activation geometry: functional, but user requested that the cursor move slightly deeper inside the physical notch rather than triggering at its edge;
- no separate dwell complaint was reported, so `120 ms` remained the candidate.

Because two real visual defects remained, the first M1 hardware candidate was **NOT ACCEPTED**, despite the original interaction checks otherwise passing.

### 2026-08-08 — cycle 9 / revised visual + activation/haptic candidate

TDD and budget evidence for the revised candidate:

- RED CI #172 proved the hardware-notch visual contract did not yet exist;
- successive correctness/security-green visual implementations were rejected by the unchanged P0 artifact budget in CI #177, #181, and #187;
- no budget was widened and no assertion was weakened; the visual architecture was simplified instead;
- CI #188 passed the complete pipeline after compact hardware-notch rendering became transparent, expanded content received safe notch spacing, and AppKit frame state stopped animating independently: executable `251,856 B`, app `254,853 B`, DMG `83,143 B`;
- RED commit `488dd14a89ce3ae0d5b784f9b6fa69d6836b6a94` / CI #189 proved a point only 2 pt inside the physical compact boundary still activated under the old policy;
- GREEN compact activation now uses an inward `4 pt` candidate and leaves expanded retention unchanged;
- production haptic remains one public AppKit request but uses `.levelChange` instead of `.generic` as the revised tactile candidate;
- GREEN CI #191 on `ab782262c16163742bb115671f7908255fc08e4a` passed **27/27 Swift tests**, all release/security/performance policy gates, packaging/signature/Sandbox/Hardened Runtime/DMG verification, unchanged artifact-size budgets, harness smoke, and artifact upload;
- CI #191 sizes: executable `251,856 B`, app `254,853 B`, DMG `83,117 B`.

Revised hardware acceptance was still pending for `NH-NOTCH-001`, `NH-HOVER-001/002/003`, `NH-HOVER-DELAY-001/002`, `NH-HAPTIC-001/002`, and `NH-VISUAL-001/002`.

### 2026-08-08 — cycle 10 / repeated panel-chrome hardware regression

Target MacBook/macOS 26.6 screenshots and repeated interaction clarified the rendering boundary:

- the compact screenshot can show the 4 pt indicator over wallpaper because a physical camera notch is hardware and is not captured in the framebuffer; the hardware-notch compact app surface is intentionally transparent, so this screenshot is **not** evidence of an opaque black compact panel;
- expanded panel corners were initially rounded but became square after several open/collapse cycles;
- `NH-VISUAL-003`: **FAIL on the previous candidate**.

Root cause review found split ownership of the same outer chrome invariant: SwiftUI `clipShape` owned visual clipping while AppKit `NSPanel.setFrame` independently resized the window on every presentation transition. The previous automated suite had no AppKit-level requirement that the backing surface remain clipped through repeated resizing.

TDD correction:

- RED commit `8088df8df655183d3fbe1a0cff54d23dfc936034` added the desired AppKit presentation-mask API and repeated-cycle regression before production support existed;
- RED CI #196 failed exactly because `NotchHostingViewFactory.applyPresentation` did not exist;
- GREEN implementation moved outer clipping ownership to the existing AppKit hosting-view boundary, enabled layer backing and `masksToBounds`, uses continuous `12 pt` compact / `22 pt` expanded radii, reasserts them on every state transition, and makes the hosting view autoresize with both width and height;
- SwiftUI outer `clipShape` was removed so there is no competing owner;
- GREEN source head `446a976591a43a856a2683337cb4df1ada10cc8a` / CI #199 passed **29/29 Swift tests**, including **32 repeated expanded -> compact mask cycles**, plus release/security/performance policies, warnings-as-errors, packaging/signature/Sandbox/Hardened Runtime/DMG checks, harness smoke, and the unchanged P0 size budget;
- CI #199 sizes improved to executable `248,768 B`, app `251,765 B`, DMG `82,069 B`.

Physical acceptance remains **PENDING**. The revised target-Mac pass must include `NH-VISUAL-003` with at least 20 real open/collapse cycles; deterministic AppKit invariants do not substitute for observing the actual pixels on the target display.

## Personal Release TDD evidence

PR #3 records release-policy RED/GREEN evidence independently from app runtime:

- initial release policy tests failed because `release_policy.py` was absent;
- first implementation exposed and fixed a false-positive Gatekeeper rule (`Do not disable Gatekeeper` must be allowed while actual bypass instructions are forbidden);
- versioned release-note integration test failed until `docs/releases/v0.1.0.md` existed;
- Personal Release workflow contract failed until `.github/workflows/personal-release.yml` existed;
- tier-separation test failed until `trusted-release.yml` existed and legacy `release.yml` was removed;
- trust-boundary tests failed until the executable workflow validator existed;
- final Trusted pre-publish recheck received an additional RED-first fail-closed regression test before its fix.

`v0.1.0` Personal Release was published from accepted `main` and subsequently passed `NH-PERSONAL-RELEASE-001` on the target MacBook/macOS 26.6.
