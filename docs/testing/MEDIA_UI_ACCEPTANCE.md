# M6.5 Media-first UI Acceptance

Status: **ACCEPTED AND MERGED / NOT RELEASED**
Acceptance date: 2026-08-12
Primary target: `Mac16,8` / macOS 26.6
PR: #19 — `M6.5 Media-first UI`
Merge: `5305dbb87d7a2d0d1c7e4bc1eba156cfcafd4e86`
Design: `docs/superpowers/specs/2026-08-11-media-first-ui-design.md`
Implementation plan: `docs/superpowers/plans/2026-08-11-media-first-ui.md`

## Accepted scope

M6.5 adds the first shipping-source Universal Media presentation on top of the accepted M6.1–M6.4 transport/composition foundation without weakening the M6.4 presentation-scoped lifecycle.

Accepted behavior:

- cold/no-media compact remains the exact physical-notch presentation;
- compact state owns zero media adapter processes;
- settled expansion starts the accepted shipping media runtime;
- authoritative Now Playing state maps to an App-owned presentation model;
- expanded active media renders supplied artwork/metadata/source plus capability-driven previous/play-pause/next controls;
- missing metadata is omitted rather than fabricated;
- unsupported/unknown previous/next capabilities stay disabled;
- trustworthy progress may render from authoritative timing without a periodic polling worker;
- media disappearance while expanded returns to Home without collapsing the panel;
- normal collapse stops/releases the media runtime but retains the last authoritative visual context;
- retained-media compact uses symmetric 36 pt wings around the unchanged physical notch, artwork left and playback status right, with the camera/notch center clear;
- a fresh expanded runtime replaces retained compact context from new authoritative events without comparing raw sequence values across runtime lifetimes;
- gestures, haptics, draggable seek and animated/live compact progress remain outside M6.5.

## Accepted architecture and security invariants

- `NotchHubCore` remains independent of `NotchHubMediaCore`;
- `NotchHubApp` is the media/UI composition root;
- `NotchPanelTransitionCoordinator` remains the sole panel presentation/geometry transition authority;
- the App-level media UI does not mutate `NSPanel` frames directly;
- the production subprocess executable remains fixed to `/usr/bin/perl` behind the accepted transport boundary;
- App Sandbox remains the only application entitlement;
- Hardened Runtime remains enabled;
- no Accessibility, Input Monitoring, Automation/Apple Events, Screen Recording, synthetic media-key, networking, telemetry or player-specific fallback authority was added;
- no repeating `Timer`, timer publisher, `DispatchSourceTimer`, display link, sleep loop, media polling loop or global scroll monitor was added;
- media metadata/artwork/listening history is not persisted or emitted into ordinary production logs.

## TDD evidence

The implementation was developed through explicit RED -> GREEN cycles:

1. Core content composition seam — RED CI #736 -> GREEN #738.
2. Media presentation projection — RED #740 -> GREEN #741.
3. Runtime presentation lifecycle and typed click commands — RED #742 -> GREEN #743.
4. App/media UI composition — RED #745 -> GREEN build/test path.
5. M6.5 feature-size envelope — RED #760 -> GREEN #762.

The first complete UI candidate measured `412,992 / 715,198 / 465,177 B` executable/app/DMG. Review found duplicate Home/Foundation SwiftUI composition. Reusing the existing `NotchRootView` reduced the accepted implementation to approximately `397 KiB / 700 KiB / 462 KiB` without changing product behavior.

The immutable `v0.1.0` P0 baseline and historical M6.4 feature budget remain unchanged. M6.5 uses the separately reviewed cumulative envelope in `performance/m6-5-media-first-ui-size-budget.json`. No runtime CPU/RSS/thread budget was widened.

## Frozen physical candidate

Exact source tested physically:

- source `431d9fbaf1ff5ba98f2ceec09732acafe5f65794`;
- CI #763 / run `31539442148` — **both required jobs PASS** after retrying one external runner TLS failure on the exact same source;
- 194 Swift tests — PASS;
- shipping artifact `NotchHub-shipping-media-candidate`;
- artifact ID `9120231721`;
- Actions digest `sha256:0d18a0c9ce5305b90808f0937531211094b85947ce96b2afd0a2c4020e4e7007`;
- contained DMG SHA-256 `3993330bf57ac86ead949215ba5370a0a33ec6b8f6a17f1d65baa30c41f5f6ad`;
- executable `397,408 B`;
- app physical payload `699,614 B`;
- DMG `461,740 B`.

The first #763 attempt passed warnings-as-errors compilation and all 194 Swift tests, then failed only while cloning the pinned external adapter because the GitHub-hosted runner reported `SSL certificate problem: self signed certificate`. TLS verification and security policy were not weakened. Retrying failed/dependent jobs on the exact same source passed the previously failing probe build plus the complete package/security/performance pipeline.

Automated gates on the frozen source:

- macOS 26 warnings-as-errors build — PASS;
- complete Swift tests — PASS;
- release/security/performance/media policy suites — PASS;
- source performance audit — PASS;
- strict Swift/plist/shell validation — PASS;
- `scripts/security-audit.sh` — PASS;
- shipping provenance/preflight — PASS;
- App Sandbox-only entitlement — PASS;
- Hardened Runtime and nested/top-level signature verification — PASS;
- system-library-only application executable boundary — PASS;
- M6.5 feature-size budget — PASS;
- shared-runner performance harness compatibility/schema smoke — PASS.

Shared-runner CPU/RSS/thread values remain compatibility evidence only, not target-Mac performance acceptance.

## Acceptance ledger

The user physically tested the exact frozen candidate on the primary target and reported all requested checks PASS.

- `NH-MEDIA-UI-001` — cold exact-notch compact and zero adapter: **PASS**.
- `NH-MEDIA-UI-002` — expanded authoritative session -> Media-first UI: **PASS**.
- `NH-MEDIA-UI-003` — playing/paused presentation mapping: **PASS**.
- `NH-MEDIA-UI-004` — partial metadata/artwork fallback without fabrication: **PASS**.
- `NH-MEDIA-UI-005` — capability-driven previous/next and real click command behavior: **PASS**.
- `NH-MEDIA-UI-006` — trustworthy static/event-driven progress and no periodic worker: **PASS**.
- `NH-MEDIA-UI-007` — media disappearance while expanded -> Home without collapse: **PASS**.
- `NH-MEDIA-UI-008` — retained compact context, visible symmetric wings and zero adapter after collapse: **PASS**.
- `NH-MEDIA-UI-009` — fresh re-expansion replaces retained state: **PASS**.
- `NH-MEDIA-UI-010` — typed command/transition/security boundary and no new authority/polling surface: **PASS**.
- `NH-MEDIA-UI-011` — exact target-Mac visual/functional acceptance with Yandex Music + Yandex Browser, permission surface and teardown: **PASS**.

Physical acceptance additionally confirmed:

- play/pause and available previous/next controls behave correctly;
- media disappearance does not collapse expanded NotchHub;
- retained compact wings render correctly around the physical camera housing;
- no media adapter remains while compact;
- fresh player state replaces retained state after re-expansion;
- no Accessibility, Input Monitoring, Automation/Apple Events or Screen Recording prompts appear;
- normal Quit leaves no orphan media adapter.

## Integration evidence

The physical candidate remained frozen at `431d9fbaf1ff5ba98f2ceec09732acafe5f65794`. The remaining PR #19 commits through final head `db243614d9b50cc857150bef30027d5478f23d11` changed source-of-truth documentation only.

Integration gates:

- final PR-head CI #771 — both required jobs PASS;
- final review — no P0/P1 blockers; one bounded P2 transition edge tracked separately as issue #20;
- PR #19 squash merge — `5305dbb87d7a2d0d1c7e4bc1eba156cfcafd4e86`;
- post-merge `main` CI #772 / run `31543163536` — both required jobs PASS.

Issue #20 is not part of the accepted M6.5 matrix: if media context clears during the short in-flight collapse after its compact target has captured retained-media wings, the future layout state changes but the already-running transition target is not currently retargeted. It is a bounded recoverable visual/geometry edge with no security/process authority expansion. It is scheduled as the first TDD hardening task in M6.6 before adding more transition-sensitive gestures.

## Exit decision

**M6.5 is ACCEPTED AND MERGED. It is not released.**

The next product slice is M6.6 local media gestures, haptics and draggable seek, beginning with issue #20 hardening. P1 whole-app performance/local-tracking review remains the following optimization stage.