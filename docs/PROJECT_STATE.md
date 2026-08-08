# Project state

Last updated: 2026-08-08
Current version: `0.1.0` (Personal Release published and accepted)
Repository visibility: **Public**
Primary physical target: macOS `26.6`
Protected branch target: `main`
P0 merge commit: `a056aa74bad5d8e193eb4c76a76e6c910344bd09`
Public-readiness hardening merge: `23500e099a0f8b2738f1157c6ae3be71c89df6e1`
Current product milestone: M1 `Notch Core hardening and interaction` — **IN PROGRESS**
Active implementation PR: #10 `M1 delayed hover and haptic interaction core`

## Product

NotchHub is a personal, native, local-first macOS productivity hub built around the MacBook notch. Planned modules are Shelf, Snippets, Calendar, Translator, and media controls with Yandex Music as the primary player.

NotchNook is a public product/UI research reference only; NotchHub remains an independent implementation.

## Accepted foundation

**M0 — Engineering foundation: ACCEPTED and merged.**

Real-hardware final acceptance on the target MacBook/macOS 26.6:

- `NH-OS26-001`: PASS from the earlier sandbox/Hardened Runtime cycle;
- `NH-NOTCH-001`: PASS;
- `NH-HOVER-001`: PASS;
- `NH-HOVER-002`: PASS;
- `NH-HOVER-003`: PASS.

M0 includes the Swift 6 native shell, public notch geometry, deterministic pointer policy, AppKit-owned panel sizing, App Sandbox + Hardened Runtime, zero third-party Swift runtime dependencies, strict CI/security/package gates, and accepted real-hardware regression fixes.

## R0.1 Personal Release

Status: **ACCEPTED**.

`v0.1.0` was published from accepted commit `8e913dcddfdec7d9aa920df8c37afb23b8c40884` as an immutable Personal Release and passed downloaded-release acceptance on the target MacBook/macOS 26.6. Personal Release remains ad-hoc signed, sandboxed, Hardened Runtime protected, checksum/provenance verified, and intentionally not notarized. Trusted Release remains an optional future tier.

## P0 Performance Foundation

Status: **ACCEPTED AND MERGED**.

PR #5 was exact-head CI green, reviewed with no P0/P1/P2 blocker, and squash-merged to `main` as `a056aa74bad5d8e193eb4c76a76e6c910344bd09`.

Canonical sources:

- `PERFORMANCE.md` — policy, accepted measurements, budgets, and regression rules;
- `performance/baseline-v0.1.0.json` — machine-readable canonical baseline;
- `docs/TESTING.md` — acceptance matrix and RED→GREEN evidence;
- `docs/ROADMAP.md` — milestone sequencing.

Implemented P0 foundation:

- event-driven runtime policy and source audit against unreviewed busy loops/timers/sleeps/display links;
- strict CPU/RSS/thread sampling/aggregation and Darwin `ps -M` thread measurement;
- development-only target-Mac sampler with explicit app/tool provenance;
- exactly 100,000 deterministic pointer/presentation decisions in CI without wall-clock threshold;
- exact immutable release artifact-size baseline;
- target-Mac CPU/RSS/thread acceptance ceilings;
- fail-closed artifact-size checker with 15% relative allowance plus independent absolute ceilings;
- shared-CI size regression gate;
- executable security proof that measurement tooling is not bundled into runtime packaging.

### Accepted target-Mac runtime baseline

Measured against accepted `v0.1.0` on macOS 26.6 / `Mac16,8`, using tooling commit `dfd4f87f8e5be04b467172d720d22bfc054c06d0`:

- `NH-PERF-IDLE-001`: CPU median/max `0.0% / 0.7%`, RSS median/max `33,648 / 33,808 KiB`, threads median/max `4 / 4`;
- `NH-PERF-HOVER-001`: CPU median/max `5.95% / 22.3%`, RSS median/max `38,456 / 38,816 KiB`, threads median/max `6 / 7`;
- `NH-PERF-STABILITY-001`: CPU median/max `0.0% / 6.8%`, RSS median/max `30,992 / 34,384 KiB`, threads median/max `3 / 7`;
- stability RSS `34,256 -> 30,544 KiB` (`-3,712 KiB`): no sustained memory growth observed;
- stability threads `4 -> 5`, max `7`: no runaway accumulation.

Measurement windows matched the stable contracts: idle `60.017 s / 60 samples`, hover `60.018 s / 60 samples`, stability `600.013 s / 120 samples`.

### Accepted immutable-release size baseline

Published `v0.1.0` metadata:

- executable `220,560 B`;
- app aggregate `223,555 B`;
- DMG `73,955 B`;
- build number `1`;
- release source `8e913dcddfdec7d9aa920df8c37afb23b8c40884`;
- DMG SHA-256 `cf53be6081b1836551fcbbb91b85fed800de4c089451961f3c6a21f6b77768bc`;
- Xcode 26.6 / Swift 6.3.3 provenance.

Runtime CPU/RSS/thread limits remain target-Mac acceptance gates. Shared GitHub runners never substitute for physical resource evidence. Artifact byte sizes are deterministic and are enforced in CI.

## P0.1 Public repository readiness

Status: **ACCEPTED**.

PR #6 completed the public-source audit/hardening with exact-head CI #139 fully green and no final review blocker, then squash-merged to `main` as `23500e099a0f8b2738f1157c6ae3be71c89df6e1`.

GitHub repository metadata reports `visibility=public`. Public-source preparation introduced no runtime or entitlement changes. The first post-public PR CI (#141) also completed successfully through the ordinary public `pull_request` path with the full security/performance/Swift/package gate set.

Accepted evidence:

- complete short pre-public `main` history and accessible PR #1–#5 diffs/discussions reviewed with no secret value/private-key material found;
- no separate open/closed Issues existed at transition time;
- root MIT `LICENSE` present;
- deterministic public-CI policy keeps untrusted PR execution on the single ordinary `ci.yml` path;
- public PR CI requires `contents: read`, no secrets, no self-hosted runner, no OIDC/write authority, and no persisted checkout credentials;
- repository-wide policy rejects alternate `pull_request` workflows plus `pull_request_target`/`workflow_run` bridges and reusable-workflow hops from public PR CI;
- Personal Release publication remains isolated from untrusted PR execution;
- Trusted Release is intentionally unconfigured: no GitHub Environments exist and no Apple signing/notarization secrets are provisioned; its `release` environment requirement becomes applicable only if that optional tier is deliberately adopted;
- `v0.1.0` tag remains addressable and its versioned release documentation remains intact;
- repository metadata retains squash-only integration (`allow_squash_merge=true`, merge/rebase commits disabled);
- direct post-public verification confirmed the active `main` protection/ruleset and required CI checks;
- direct post-public verification confirmed Actions default workflow token permissions and fork-PR settings;
- direct post-public verification confirmed the published `v0.1.0` Release assets, checksum, and provenance remain intact.

The `release` environment verification item is **N/A**: the current supported tier is Personal Release, no GitHub Environments exist, and Trusted Release is explicitly dormant until future Apple Developer adoption.

P0.1 is complete. Any future change to repository visibility, Actions authority, branch/ruleset protection, release workflow trust, or credential handling requires a fresh focused review.

## M1 interaction core

Status: **IMPLEMENTED IN PR #10; TARGET-MAC ACCEPTANCE PENDING**.

Authoritative requirements: `docs/specs/M1_NOTCH_INTERACTION.md`.
Implementation plan: `docs/superpowers/plans/2026-08-08-m1-pointer-dwell-haptics.md`.

Implemented deterministically:

- a dedicated `NotchInteractionCoordinator` separates pointer delivery, time, haptic output, and presentation state;
- compact → expanded activation uses one cancellable one-shot dwell with named initial candidate `120 ms`;
- duplicate pointer movement does not create duplicate pending activation;
- leaving before the threshold cancels immediately;
- generation validation makes stale callbacks harmless even if a cancelled callback is invoked later;
- re-entry starts a fresh full dwell;
- expanded retention/collapse stays independent from the activation dwell;
- one successful pointer-initiated `compact -> expanded` transition requests exactly one haptic;
- quick/cancelled transit, duplicate movement, retention, collapse, programmatic expansion, setup-time pointer synchronization, and stale callbacks request no haptic;
- initial `show()` pointer synchronization is explicitly non-activating, so launching while the cursor already overlaps the notch cannot schedule dwell/haptic without a subsequent user mouse-move event;
- production haptic uses public `NSHapticFeedbackManager.defaultPerformer` with `.generic` / `.now`;
- the dwell scheduler is one `DispatchWorkItem` via `DispatchQueue.main.asyncAfter`, not polling or a repeating timer;
- pointer-monitor ownership is explicit: one local and one global `.mouseMoved` monitor are registered once and removed idempotently on invalidation;
- application termination invalidates the controller and pending work;
- no entitlement, runtime dependency, networking, subprocess, Accessibility, Input Monitoring, `CGEventTap`, private API, or broader event mask was added.

### TDD / CI evidence

- RED CI #147 first failed because the interaction coordinator/scheduler/haptic types deliberately did not exist; an independent missing `Foundation` test-harness import was then corrected without adding production code.
- RED CI #148 failed cleanly on the still-missing production interaction types.
- RED CI #150 additionally covered the missing pointer-monitor lifecycle abstraction and failed for both intended production seams.
- GREEN CI #157 passed macOS 26 compatibility, 24/24 Swift tests, release/performance policy, runtime performance audit, security baseline, build/package/signature/Sandbox/Hardened Runtime/DMG gates, but correctly failed the unchanged artifact-size budget: executable `254,000 B` exceeded the 15% relative limit `253,644 B` by `356 B`.
- The budget was **not widened**. Runtime metadata/structure was reduced without changing tested behavior.
- GREEN CI #158 on implementation head `6b0173b79e457a8749c6f8675681efb8850e4e9e` passed all gates. Candidate sizes: executable `251,856 B`, app `254,853 B`, DMG `83,072 B`.
- Independent change review then found one P2 setup-path risk: `show()` could feed the current mouse location through the normal activation path and request a haptic after launch without a fresh user movement.
- RED CI #165 on `0b777f8009c6bd76026fb70585a1d9d8debc034f` failed exactly because the new `allowActivation` regression seam did not yet exist.
- GREEN CI #167 on reviewed implementation head `693ca834043b4b690f05e419aae5061af68163c2` passed the complete pipeline with **25/25 Swift tests**, all release/security/performance policy gates, package/signature/Sandbox/Hardened Runtime/DMG checks, and unchanged artifact-size budgets. Candidate sizes: executable `251,872 B`, app `254,869 B`, DMG `83,036 B`.

The shared-runner 5-second performance harness in CI remains schema/compatibility evidence only; its CPU/RSS/thread values are not target-Mac acceptance data.

### Still pending before delayed-hover/haptic acceptance

The following exact hardware scenarios have **not** yet been claimed as PASS on the target MacBook/macOS 26.6:

- `NH-HOVER-DELAY-001` — normal cross-display transit remains compact with zero haptic;
- `NH-HOVER-DELAY-002` — deliberate hover expands once after a fast but perceptible dwell; final dwell tuning is accepted;
- `NH-HAPTIC-001` — one physical Force Touch haptic accompanies successful deliberate expansion when hardware/settings permit it;
- `NH-HAPTIC-002` — quick/cancelled hover, retention, and collapse produce no physical haptic;
- regression retest of `NH-NOTCH-001` and `NH-HOVER-001/002/003` on the exact PR candidate.

The `120 ms` value therefore remains the **candidate**, not a final hardware-tuned value.

## Security baseline

`SECURITY.md` remains authoritative. M1 interaction work adds no runtime entitlement, telemetry, analytics, networking, subprocess/shell, dynamic loading, private API, privileged helper, Accessibility/Input Monitoring permission, or broader global input capture. Global observation remains exactly `.mouseMoved` and pointer coordinates/history are not persisted.

## Known limitations / technical debt

- initial target-Mac runtime ceilings are based on one canonical run per scenario and intentionally include conservative headroom;
- the narrow global `.mouseMoved` fallback remains in the M1 candidate; it now has explicit lifecycle ownership but is not yet replaced;
- the current AppKit event backend still uses a main-actor task hop for delivered `.mouseMoved` events; this is retained until the measured pointer-tracking optimization step rather than changed speculatively;
- a window-local `NSTrackingArea`/AppKit replacement may be accepted only after target-Mac correctness, cross-display behavior, and resource evidence are equal or better than the P0 baseline;
- final dwell timing is pending physical UX acceptance;
- active-display migration, Spaces/fullscreen policy, screen-configuration handling, notchless mode, click/pin policy, animation/reduced-motion tuning, gestures, product modules, and optional trusted distribution remain later work.

## Next optimal step

1. Complete final exact-head PR CI after this evidence/documentation synchronization.
2. Exercise the exact PR candidate on the target MacBook/macOS 26.6 and record `NH-NOTCH-001`, `NH-HOVER-001/002/003`, `NH-HOVER-DELAY-001/002`, and `NH-HAPTIC-001/002` honestly.
3. Tune the named dwell value only from that physical evidence; if changed, preserve deterministic coverage and rerun exact-head CI/hardware acceptance.
4. Run the separate M1 local-tracking experiment against the accepted P0 `NH-PERF-HOVER-001` baseline. Remove global `.mouseMoved` only if local tracking remains reliable during notch/multi-display transit and resource/input-observation evidence is equal or better.
5. Continue M1 with active-display migration, Spaces/fullscreen, screen-configuration handling, animation/reduced-motion, click/pin, and gesture hardening after the core interaction path is accepted.
