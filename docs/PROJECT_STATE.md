# Project state

Last updated: 2026-08-15
Current published version: `0.1.0` (Personal Release)
Repository visibility: **Public**
Default branch: `main`
Primary physical target: macOS `26.6` / `Mac16,8`

## Current state

The currently published release remains immutable `v0.1.0`. It predates the accepted M1/P0.1/M6 source work; the regression/UI automation foundation and all current M6.6 work remain unreleased.

`main` remains at `172805f8cd63dab664d0dbc6747576fb51b13e7a` (`M6.6: add vertical gesture visual tracking`). M6.1 through M6.5 and the already merged M6.6 prerequisites remain accepted/merged as recorded in the acceptance ledgers and Git history.

Two draft PRs remain intentionally separated:

- **PR #33 — M6.6 consolidated interaction + Hover Peek:** implemented and automated-tested, but **physical acceptance is still pending**. Its frozen target-Mac candidate remains `423bc5d72a3676d01793f898ed2e8e79845bc8cd`; CI #962 / run `31685581542` passed the required automation. The PR stays draft, unmerged and unreleased until it is rebased/resumed after the testing foundation merge, passes fresh regression CI, then passes the focused repair retest and remaining M6.6 physical matrix on `Mac16,8` / macOS 26.6.
- **PR #34 — Regression and UI Automation Foundation:** Plan 1 and the Legacy Regression Baseline Backfill are implemented and automated-verified. The pre-documentation exact candidate `1e9ec7ac322ab4580f4f867e39457db915cfcb77` passed CI #1051 / run `31847082833` with all three required jobs green and then passed two additional independent `macOS UI regression` executions on the same exact source. PR #34 remains draft/unmerged/unreleased until this documentation-synchronized head receives fresh exact-head CI and final review.

PR #34 does not intentionally repair or tune M6.6 product behavior. PR #33 remained untouched while the accepted baseline was backfilled.

## Regression and UI automation foundation

The foundation establishes a native macOS regression layer without replacing SwiftPM as the production build system:

- a checked-in Xcode project containing only a non-production UI-test host and `NotchHubUITests`;
- XCUI tests launch the exact SwiftPM-built `NotchHub.app` by URL rather than linking production source into the UI-test target;
- deterministic media and haptic fixtures compile only under `NOTCHHUB_UI_TESTING`;
- normal Personal/Release builds are verified to contain none of the fixture markers;
- stable accessibility identifiers expose externally meaningful notch/media state to XCUIAutomation;
- UI synchronization uses XCTest predicates/state waits rather than arbitrary sleeps or automatic retries;
- failure evidence includes screenshot, accessibility hierarchy, `.xcresult`, and exact `NHSourceCommit` provenance;
- deterministic UI journeys exercise real XCUI hover, pointer exit and typed media-control interaction;
- canonical CI contains the third required job `macOS UI regression` on `macos-26` while preserving package/security/performance gates.

No new network authority, telemetry, sensitive permission, global scroll monitor, event tap, polling loop, repeating watchdog, display link or synthetic media-key path is introduced by the testing foundation.

## Acceptance traceability — Plan 2 complete on the PR branch

Authoritative plan: `docs/superpowers/plans/2026-08-14-legacy-regression-baseline-backfill.md`.

`Tests/Acceptance/coverage.yml` plus `scripts/test_acceptance_coverage.py` now provide complete fail-closed traceability across the discovered stable acceptance inventory:

- exact CI output on `1e9ec7ac322ab4580f4f867e39457db915cfcb77`: `discovered=90 mapped=90 unmapped=0 missingAutomation=30`;
- every discovered stable ID has a manifest entry with ledger-derived status;
- accepted deterministic behavior points to concrete unit/integration/UI/policy/shipping evidence;
- genuinely physical properties retain explicit `physicalOnlyReason` evidence instead of being falsely treated as automated;
- pending/deferred M6.6 and deferred M1 contracts remain pending/deferred rather than being promoted to accepted;
- canonical CI now runs `python3 scripts/test_acceptance_coverage.py --mode strict` in both `macOS UI regression` and `Build, test and package`.

The `missingAutomation=30` report is not unmapped debt: it includes contracts whose current status or genuinely physical evidence does not require an automated layer. Strict mapping debt is zero.

A validator regression found during Task 9 was closed under RED -> GREEN: ordinary behavioral prose such as a lowercase `failed` capability can no longer silently turn a pending acceptance ID into `rejected`; per-ID `PASS`/`FAIL`/`DEFERRED` remains recognized only as explicit acceptance tokens, while document-level `Status:` parsing remains authoritative.

## Exact pre-documentation verification

Source `1e9ec7ac322ab4580f4f867e39457db915cfcb77`, CI #1051 / run `31847082833`:

- `macOS 26 compatibility` — PASS;
- `macOS UI regression` — PASS;
- `Build, test and package` — PASS;
- strict acceptance coverage — `90 / 90` mapped, zero unmapped;
- Swift suite — **250 tests PASS**;
- source/security policy, Sandbox-only entitlement, Hardened Runtime/signing, shipping preflight, system-library boundary, feature-size budget and performance smoke — PASS;
- exact shipping candidate sizes — executable `446,656 B`, app `748,863 B`, DMG `483,835 B`, within the regression-foundation envelope;
- the same exact source completed **three independent `macOS UI regression` executions successfully**; no failed run was retried merely to obtain a green result.

A fresh documentation-synchronized exact-head CI is still required before PR #34 may be considered merge-ready.

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
- Regression/UI Automation Foundation + Legacy Backfill in PR #34 — **implemented / automated-verified / strict PASS on pre-doc candidate / final docs-head CI and review pending / not merged / not released**.
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

- PR #34 still requires fresh CI on this documentation-synchronized exact head, final diff review, merge and post-merge `main` CI before the foundation is accepted as merged.
- PR #33 still requires rebase/resume after #34, fresh automated regression evidence, target-Mac physical retest and the remaining M6.6 gesture/Peek/seek/source-icon/lifecycle/permission matrix.
- Apple Music, Spotify and additional-player compatibility remain unverified rather than assumed.
- active-display migration, multi-monitor hardening, fullscreen/Spaces, screen-configuration changes, notchless mode and click/pin policy remain deferred M1 work;
- the global `.mouseMoved` fallback remains pending the P1 local-tracking comparison;
- portable absolute memory-footprint measurement and repeated-run variance characterization remain P1 research.

## Next optimal step

1. Run canonical CI on this documentation-synchronized PR #34 exact head and require all three jobs, including strict traceability and real XCUI, to pass.
2. Review the final PR #34 diff for unsupported acceptance claims, accidental product behavior changes, security/trust-boundary widening or performance-policy weakening.
3. If clean, mark PR #34 ready, merge it through normal protected-branch rules, and require post-merge `main` CI to pass.
4. Only then rebase/resume PR #33 onto the merged regression foundation, obtain a fresh exact-head candidate and run the new regression suite before target-Mac physical acceptance.
5. Only after M6.6 is physically accepted and merged may P1 resource/performance work or later product milestones advance.
