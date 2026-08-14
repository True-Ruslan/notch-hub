# Project state

Last updated: 2026-08-14
Current published version: `0.1.0` (Personal Release)
Repository visibility: **Public**
Default branch: `main`
Primary physical target: macOS `26.6` / `Mac16,8`

## Current state

The currently published release remains immutable `v0.1.0`. It predates the accepted M1/P0.1/M6 source work; nothing in the current regression-foundation branch is released.

`main` remains at `172805f8cd63dab664d0dbc6747576fb51b13e7a` (`M6.6: add vertical gesture visual tracking`). M6.1 through M6.5 and the already merged M6.6 prerequisites remain accepted/merged as recorded in the acceptance ledgers and Git history.

Two draft PRs are intentionally separated:

- **PR #33 — M6.6 consolidated interaction + Hover Peek:** implemented and automated-tested, but **physical acceptance is still pending**. Its frozen target-Mac candidate is `423bc5d72a3676d01793f898ed2e8e79845bc8cd`; CI #962 / run `31685581542` passed the required automation. The PR stays draft, unmerged and unreleased until the focused repair retest and remaining M6.6 physical matrix pass on `Mac16,8` / macOS 26.6.
- **PR #34 — Regression and UI Automation Foundation:** separate testing-foundation work from stable `main`. **Foundation Plan 1 is complete and automated-tested.** Task-9 exact verification source `5e9341b4d957a967ec82166e18e009455119fd0b` passed canonical CI #1007 / run `31817097807` in all three jobs: `macOS 26 compatibility`, `macOS UI regression`, and `Build, test and package`. The active work is now Plan 2 — Legacy Regression Baseline Backfill.

PR #34 does not intentionally repair or tune M6.6 product behavior. PR #33 remains untouched while the regression baseline is backfilled.

## Regression and UI automation foundation — Plan 1

Plan 1 establishes a native macOS regression layer without replacing SwiftPM as the production build system:

- a checked-in Xcode project containing only a non-production UI-test host and `NotchHubUITests`;
- XCUI tests launch the exact SwiftPM-built `NotchHub.app` by URL rather than linking production source into the UI-test target;
- deterministic media and haptic fixtures are compiled only under `NOTCHHUB_UI_TESTING`;
- normal Personal/Release builds are verified to contain none of the fixture markers;
- stable accessibility identifiers expose externally meaningful notch/media state to XCUIAutomation;
- UI synchronization uses XCTest predicates/state waits rather than arbitrary sleeps or automatic retries;
- failure evidence includes screenshot, accessibility hierarchy, `.xcresult`, and exact `NHSourceCommit` provenance;
- deterministic media UI journeys exercise real XCUI hover and click input, including hover expansion plus Next / Previous / Play-Pause behavior;
- acceptance coverage is machine-audited from stable `NH-*` IDs in `docs/testing/*.md`;
- canonical CI contains the third job `macOS UI regression` on `macos-26` while preserving package/security/performance gates.

Production-diff review found no accidental product-feature or shipping trust-boundary change: shipping composition still creates `ShippingMediaRuntime`, AppDelegate retains runtime lifecycle ownership, shipping haptics remain direct `AppKitNotchHapticPerformer`, and all deterministic substitutions are compile-time test-only. No new network authority, telemetry, sensitive permission, global scroll monitor, event tap, polling loop, repeating watchdog, display link or synthetic media-key path was added.

## Acceptance traceability — Plan 2 active

Authoritative plan: `docs/superpowers/plans/2026-08-14-legacy-regression-baseline-backfill.md`.

`Tests/Acceptance/coverage.yml` plus `scripts/test_acceptance_coverage.py` implement:

- `audit` — validates manifest correctness while reporting legacy unmapped IDs;
- `strict` — fails closed until the accepted deterministic baseline is completely mapped and physical-only exceptions are explicitly justified.

Current audit discovers **70 stable acceptance IDs**. The seed manifest contains **1 verified mapping** and therefore reports **69 legacy backfill gaps**. This is traceability debt, not a reversal of historical physical acceptance.

Plan 2 must complete the inventory for all stable accepted IDs, reuse existing valid tests where possible, add missing deterministic unit/integration/XCUI coverage, and reserve `physicalOnlyReason` only for genuinely physical properties. Feature work remains frozen until strict validation passes.

## Status ladder

- M0 Engineering Foundation — **accepted / merged**.
- R0.1 Personal Release `v0.1.0` — **accepted / released**.
- P0 Performance Foundation — **accepted / merged**; immutable baseline preserved.
- P0.1 Public Repository Readiness — **accepted**.
- M1 primary notch interaction/transition slice — **physically accepted / merged**.
- M6.1 transport feasibility — **physically accepted**.
- M6.2 production media boundary — **accepted / merged**.
- M6.3 production system transport — **physically accepted / merged**.
- M6.4 shipping composition — **physically accepted / merged**.
- M6.5 Media-first UI — **physically accepted / merged**.
- M6.6 merged prerequisites on `main` — **implemented / automated-tested / merged**.
- M6.6 consolidated PR #33 — **implemented / automated-tested / physical retest pending / not merged / not released**.
- Regression foundation PR #34 Plan 1 — **implemented / automated-tested / complete / not merged / not released**.
- Legacy regression baseline backfill Plan 2 — **active blocking testing stage / strict not yet passing**.
- P1 whole-app performance/resource review — **blocked until M6.6 acceptance and merge**.

## Security and privacy baseline

`SECURITY.md` remains authoritative. Important invariants are unchanged:

- local-first and no telemetry;
- App Sandbox-only application entitlement;
- Hardened Runtime without dangerous exceptions;
- no direct application networking;
- no bundled secrets;
- no broad global input capture beyond the existing narrow `.mouseMoved` fallback;
- exactly one reviewed production media subprocess boundary fixed to `/usr/bin/perl` with pinned resources and a closed typed command surface;
- no direct private-framework loading in the NotchHub process;
- no media listening-history persistence/logging;
- no Accessibility, Input Monitoring, Automation/Apple Events or Screen Recording expansion for the testing foundation.

UI fixtures substitute only nondeterministic external boundaries under a compile-time testing condition and are explicitly rejected from shipping artifacts.

## Performance baseline

`performance/baseline-v0.1.0.json` remains immutable historical evidence:

- executable `220,560 B`;
- app `223,555 B`;
- DMG `73,955 B`.

Historical M6 feature budgets remain immutable. The foundation uses the separate provenance-backed `performance/regression-ui-automation-foundation-size-budget.json`; canonical CI enforces that envelope instead of rewriting earlier budgets. Shared-runner CPU/RSS/thread magnitudes remain compatibility evidence only; target-Mac performance acceptance still follows `PERFORMANCE.md`.

## Known limitations / technical debt

- PR #34 acceptance traceability is still in `audit` mode: 69 legacy stable-ID mappings remain to be backfilled before strict mode can become mandatory.
- PR #33 still requires target-Mac physical retest and the remaining M6.6 gesture/Peek/seek/source-icon/lifecycle/permission matrix.
- Apple Music, Spotify and additional-player compatibility remain unverified rather than assumed.
- active-display migration, multi-monitor hardening, fullscreen/Spaces, screen-configuration changes, notchless mode and click/pin policy remain deferred M1 work;
- the global `.mouseMoved` fallback remains pending the P1 local-tracking comparison;
- portable absolute memory-footprint measurement and repeated-run variance characterization remain P1 research.

## Next optimal step

1. Execute Plan 2 Task 1: produce the complete machine-readable acceptance inventory/report from all stable ledgers, classifying every ID as deterministic, integration, UI/E2E or genuinely physical-only without changing accepted semantics.
2. Backfill M1 and M6.1-M6.5 executable mappings in plan order, reusing existing valid tests before adding new ones.
3. Complete the manifest for every stable accepted ID; every deterministic accepted behavior must point to executable evidence while physical-only gates carry a narrow explicit reason.
4. Switch canonical CI from acceptance `audit` to `strict` and require strict PASS before considering PR #34 ready to merge. After merge, require post-merge `main` CI.
5. Only then rebase/resume PR #33, obtain a fresh exact-head CI candidate and complete target-Mac M6.6 physical acceptance.
6. Only after M6.6 is accepted and merged may P1 resource/performance work or later product milestones advance.
