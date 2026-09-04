# Roadmap

Primary target: Mac16,8 / macOS 26.6.x. Current physical environment: macOS 26.6.2. Published Personal Release: `v0.4.0` (`v0.1.0`, `v0.2.0` and `v0.3.0` remain published/immutable as historical evidence).

States are explicit: **implemented -> automated-tested -> physically accepted -> merged -> released**. Green CI does not substitute for target-Mac acceptance when physical UI, permissions, third-party behavior or resources are part of the contract.

## Completed foundations

- **M0 Engineering Foundation — ACCEPTED / MERGED**.
- **R0.1 Personal Release — ACCEPTED / RELEASED**: immutable `v0.1.0`.
- **P0 Performance Foundation — ACCEPTED / MERGED**.
- **P0.1 Public repository readiness — ACCEPTED**.
- **M1 primary interaction foundation — ACCEPTED / MERGED**; active-display/multi-monitor migration (PR #56) and fullscreen/Spaces panel-configuration hardening (PR #77) are both accepted/merged; notchless-display fallback verified as part of M1's matrix.
- **Regression/UI Automation Foundation — IMPLEMENTED / TESTED / MERGED** via PR #34 as `bd9566f690d314ed40fd6f3723a319291ceb4a58`.

## M6 — Universal Media / System Now Playing

- **M6.1 transport feasibility — ACCEPTED**.
- **M6.2 production media boundary — ACCEPTED / MERGED**.
- **M6.3 concrete system transport — ACCEPTED / MERGED**.
- **M6.4 shipping composition — ACCEPTED / MERGED**.
- **M6.5 Media-first UI — ACCEPTED / MERGED**.

### M6.6 — gestures, haptics, interactive notch, seek and Hover Peek

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.2.0`**.

Original full physical source acceptance remains permanently pinned to exact runtime `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3`. PR #33 squash-merged as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`; released as part of `v0.2.0`.

Later real target-Mac checks found and repaired three independent runtime defects while preserving the accepted interaction/security boundary:

- hardware-notch launch screen selection — PR #40, merged `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`;
- exact compositor endpoint settlement — PR #51, physically accepted head `329b867595b6ffe127fa3552f51bef8412865f37`, merged `1f56c3e5da8a46509a3472a52da12a1abfb16a8c`;
- broad global pointer wakeups plus rapid-exit loss — PR #53, physically accepted head `bddd0503d972c652752a0e1463f3495685accc83`, merged `11dad43364a969f4d5f8c1a92e1281b5b41c8a74`.

Final PR #53 physical acceptance on Mac16,8/macOS 26.6.2 covered rapid exit 30/30, compositor 10/10, reversal recovery, hardware-notch binding and same-candidate wakeup A/B. The accepted head and squash merge share Git tree `8f0a7fee0b02599520a5776133f51c1215da7d98`.

## P1 — whole-app performance/resource review

Status: **ACCEPTED — COMPLETE TARGET-MAC EVIDENCE / DIRECT GATES PASS / NO SPECULATIVE OPTIMIZATION REQUIRED**.

Accepted provenance:

- measured runtime: `11dad43364a969f4d5f8c1a92e1281b5b41c8a74`;
- measurement/evidence tooling: `fc7562b0799faa4dd80e8c47263354a8bd16bd6a`;
- exact target: `Mac16,8 / macOS 26.6.2`;
- closed issue #38 contains the live collection and final acceptance trail.

Final evidence:

- Idle — CPU median/max `0.0/0.0%`; RSS median/max `58,432/58,496 KiB`; threads median/max `3/6`; Idle thread gate PASS.
- Hover — CPU median/max `6.8/32.3%`; RSS median/max `75,936/76,784 KiB`; threads median/max `6/6`; CPU median target and thread gate PASS. One-second CPU max remains diagnostic under the accepted policy.
- Stability — CPU median/max `0.0/0.0%`; RSS `58,816 -> 54,848 KiB` (`-3,968 KiB`); threads `3 -> 3`, max `5`; all direct growth/thread gates PASS.
- Activity Monitor Idle Wake Ups, 60 s — `0.0/s`, explicitly reviewed with no anomaly.
- Activity Monitor Energy fallback, 60 s — `no-anomaly-observed`; Energy Impact `0.0`, App Nap `No`, Preventing Sleep `No`.
- Manual visual compositor — exactly 10 cycles PASS; reversal recovery PASS; no freeze/stuck panel or frame/corner/flicker anomaly.
- Normalized evidence bundle — validation PASS, `reviewRequired=false`, final direct-gate review PASS.

Earlier 26.6.1 and pre-fix measurements remain historical diagnostic evidence and are not mixed with the accepted 26.6.2 bundle.

P1 lifecycle is complete as an acceptance gate and is released as part of `v0.2.0`.

## M1 — active-display / multi-monitor migration

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.2.0`**.

Event-driven display-topology migration: observes `NSApplication.didChangeScreenParametersNotification`, resolves `NSScreen.screens` fresh on topology change while preserving hardware-notch-first selection and the accepted `NSScreen.main`/first-screen fallback, migrates Compact/Peek/Expanded through one shared `NotchPanelLayoutModel`, retargets in-flight programmatic and interactive transitions by generation, and resets the bounded pointer-escape monitor across migration. No private display APIs, repeating timers, display links, telemetry or new permissions were added.

Automated candidate `dd945dc3ca009f8d9429ad044d50a01a2ea1bb62`; CI #1344 3/3 GREEN; full Swift suite 392 tests GREEN.

Physical acceptance on `Mac16,8 / macOS 26.6.2` with an external monitor connected — 11/11 PASS, covering connect/disconnect/reconfigure across Compact/Peek/Expanded, interruption of programmatic and interactive transitions, no-notch fallback, repeated migration cycles, post-migration pointer/hover scoping and no new permission prompts. Full checklist recorded in PR #56.

PR #56 squash-merged as `c7d2bdb9cae744d439d240f22acd14140bacedd3`; issue #55 closed. Released as part of `v0.2.0`.

## M6.7 — live media timeline and live Compact display

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.2.0`**.

Deliberately reverses two prior accepted invariants: the shipping media runtime now runs for the app's whole lifetime instead of only while settled Expanded, so Compact reflects live Now Playing state; and one narrowly-scoped, reviewed bounded-lifecycle `Timer` (`MediaTimelineTicker`) extrapolates a real-time-ticking progress position while settled Peek/Expanded and playing. `scripts/performance_policy.py`'s runtime audit gained a fail-closed, schema-validated reviewed-exception manifest for exactly this one timer. A real pre-existing hazard was also found and fixed: the one-shot peek probe could clobber an already-live authoritative presentation on hover.

Physical acceptance on `Mac16,8 / macOS 26.6.2` — 7/7 PASS, including live-ticking timeline in Peek/Expanded, correct pause/resume freezing, live Compact reflecting external track/pause changes, verified `0.0%` CPU from the ticker while settled Compact, clean post-Quit teardown under a normal quit, and a fresh P1-style Idle/Hover/Stability resource bundle with all direct gates passing despite the adapter now running continuously. Full checklist and evidence: `docs/testing/M6_7_LIVE_MEDIA_TIMELINE_AND_COMPACT_ACCEPTANCE.md`.

PR #58 squash-merged as `bd48037baff85d8eb3354fbf3792c5db016ff4a1`. Released as part of `v0.2.0`. Physical acceptance also surfaced a non-blocking follow-up: NotchHub has no user-discoverable normal-quit path (no Dock icon, no Quit menu item, Cmd+Q is a no-op) — Force Quit is the only option today and skips process cleanup.

## M6.8 — compact live equalizer

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.2.0`**.

Competitive-review-driven: replaces Compact's static play/pause glyph with a small animated equalizer, borrowing a UX detail found in both `TheBoredTeam/boring.notch` (open source, same MediaRemoteAdapter) and NotchNook's compact-mode presentation. `MediaCompactEqualizerView` animates 3 bars via SwiftUI's `PhaseAnimator`, armed only while playing, settling flat on pause. No timer primitive; no new reviewed-exception entry needed.

Physical acceptance on `Mac16,8 / macOS 26.6.2` — all items PASS. Acceptance found and fixed a real bug: the initial `.repeatForever`-based animation froze after the horizontal next/previous swipe gesture (an ancestor `withAnimation` transaction interrupting the implicit loop); fixed by switching to `PhaseAnimator`, immune to that class of interference. Full evidence: `docs/testing/M6_8_COMPACT_LIVE_EQUALIZER_ACCEPTANCE.md`.

PR #60 squash-merged as `4cbb01d7d5f57f26c40162c8149faf27691c2e06`. Released as part of `v0.2.0`. Other competitive-review ideas (album-art color tinting, `matchedGeometryEffect` cross-state artwork morphing) remain explicitly deferred to future slices; marquee text is now underway as M6.9 below.

## M6.9 — media marquee text for overflowing titles

Status: **IMPLEMENTED / AUTOMATED-TESTED / CANONICAL CI GREEN / MERGED / PHYSICAL ACCEPTANCE EXPLICITLY WAIVED / RELEASED — `v0.2.0`**.

Deferred from M6.8: Peek and Expanded title/artist/album previously hard-truncated overflowing text. `MediaMarqueeCalculator` (pure, unit-tested) decides overflow/timing; `MediaMarqueeText` renders static truncated text when content fits and otherwise scrolls a continuous conveyor loop via SwiftUI's `PhaseAnimator`, gated off entirely by `accessibilityReduceMotion`. Compact is unaffected (no title/artist text there). No new timer-policy exception needed. Design/invariants: `docs/superpowers/specs/2026-08-22-media-marquee-text-design.md`.

PR #62 squash-merged as `704bfbcdb1bd81774e8fc2d6a7d9f60a6672d703` after canonical CI GREEN 3/3. Unlike every prior milestone, physical acceptance on `Mac16,8`/macOS `26.6.x` was explicitly waived by the product owner rather than performed — recorded honestly, including the residual risk this creates, in `docs/testing/M6_9_MEDIA_MARQUEE_ACCEPTANCE.md`.

## M6.10 — discoverable normal-quit path

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.2.0`**.

M6.7's physical acceptance found Force Quit was the only way to quit NotchHub, bypassing `applicationWillTerminate`'s existing, already-tested media-runtime cleanup and leaving an orphaned `mediaremote-adapter.pl` process. `AppDelegate` now installs a minimal `NSStatusItem` (stock SF Symbol, no custom asset) with a static "Quit NotchHub" menu action wired to `#selector(NSApplication.terminate(_:))`, routing through the existing cleanup path. No new entitlement, permission, or timer. Design/invariants: `docs/superpowers/specs/2026-08-23-discoverable-quit-menu-design.md`.

PR #64 squash-merged as `b911746077092bfffd60d93cd8072c268cb1df94` after canonical CI GREEN 3/3. Physical acceptance on the product owner's own Mac — all 7 checklist items PASS, including confirming `pgrep -lf 'mediaremote-adapter\.pl'` is empty after quitting via the menu (the actual defect fixed). Full evidence: `docs/testing/M6_10_DISCOVERABLE_QUIT_ACCEPTANCE.md`.

## M6.11 — album-art color tinting

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.3.0`**.

The last of the three ideas the M6.8 competitive review deferred (marquee text shipped as M6.9; `matchedGeometryEffect` artwork morphing remains deferred). Replaces the panel's flat `Color.black` background with a subtle tint sampled from the current track's artwork, crossfading on track change. `MediaArtworkTintCalculator`/`MediaArtworkTintSampler` live in `NotchHubMediaCore` (real unit tests, not source-scanning) rather than `NotchHubApp`. Design/invariants: `docs/superpowers/specs/2026-08-24-album-art-color-tinting-design.md`.

Physical acceptance found and fixed two real, pre-existing UI defects in the same PR before merge: Peek title/artist text partially hidden under the physical hardware notch (missing notch-geometry-derived top inset), and seek-to-tap visibly resetting the timeline to near-zero before animating to the clicked spot (a stale pre-seek snapshot race). PR #69 squash-merged as `ad572cea5787ac8487308855f517395c8a3a23b2`.

Two further real, unrelated defects were found and fixed during the same round of physical testing, neither tied to this or any other milestone: title-less Now Playing sessions (e.g. browser video without `navigator.mediaSession.metadata`) being silently dropped by the vendored `MediaRemoteAdapter`'s title-mandatory gate (PR #70, `ed215290100becc1a54e46fec0b209682b539d32`), and cold-launch Peek rendering mispositioned until the next transition due to a settled-phase no-op never reconciling the panel frame (PR #71, `634fc5629218209a99649d8c1fc22981954fa4d4`). Full detail in `CHANGELOG.md` and `docs/PROJECT_STATE.md`. Released as part of `v0.3.0`, published 2026-09-02 via PR #73 and the `Personal Release` workflow (run `33652040573`) on source `7de4a41de0947f09bedf26fa3385cab566038475`; see `docs/releases/v0.3.0.md`.

## Artwork morphing — `matchedGeometryEffect` cross-state morph

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.4.0`**.

The last of the three ideas the M6.8 competitive review deferred (equalizer/M6.8, marquee text/M6.9, album-art tinting/M6.11). A shared `@Namespace` + `matchedGeometryEffect(id: "media.artwork")` on the single `artwork(_:size:)` definition site lets SwiftUI interpolate the artwork's frame/position across Compact/Peek/Expanded instead of cross-fading a size "pop", driven by an explicit `.animation(value: panelModel.contentPresentation)` synced to the AppKit panel's own resize duration (`notchAnimationDuration`, now `public` in `NotchHubCore`) and disabled under Reduce Motion. Design/invariants: `docs/superpowers/specs/2026-09-03-artwork-morphing-design.md`.

Canonical CI GREEN 3/3; full Swift suite 450/450 tests GREEN. Physical acceptance on the product owner's own Mac — all 8 checklist items PASS. Full evidence: `docs/testing/ARTWORK_MORPHING_ACCEPTANCE.md`.

PR #75 squash-merged as `8ac7a44cc0565893d363e917807a6dcbac38c3cb`.

## Fullscreen / Spaces hardening

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / RELEASED — `v0.4.0`**.

Closes the last item M1 deliberately deferred: fullscreen-app and Spaces-switch behavior. `NotchPanelController.configurePanel()` already implemented Apple's documented recipe for a utility panel that survives both (`.canJoinAllSpaces`, `.fullScreenAuxiliary`, `.stationary`, `.level = .statusBar`) unchanged since M1, but no test asserted it and neither scenario had been physically exercised. `NotchPanelSpacesFullscreenPolicyTests` constructs the real `NotchPanelController` and asserts these invariants on the actual `NSPanel`. Design/invariants: `docs/superpowers/specs/2026-09-03-fullscreen-spaces-notchless-hardening-design.md`.

No production behavior changed and no real defect was found. Canonical CI GREEN 3/3; full Swift suite 453/453 tests GREEN. Physical acceptance on the product owner's own Mac — all 7 checklist items PASS. Full evidence: `docs/testing/FULLSCREEN_SPACES_HARDENING_ACCEPTANCE.md`.

PR #77 squash-merged as `273126e54f93cd806eaf2be9fa5191f47092d416`.

## M7 — Product shell (first bounded Settings slice)

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED — not yet released**.

First scoped version of M7, with no prior spec before this slice. Four controls per product-owner scoping: Launch at Login (`SMAppService.mainApp`), Reduce Motion override (System/Always On/Always Off, via a new pure `effectiveReduceMotion(systemValue:override:)`), manual display override (a stable `displayUUID`-keyed `NotchScreenSelection` overload, falling back to the existing M1 automatic policy if the pinned display disconnects), and About (version + release link). Entry point: a new "Settings…" menu-bar item opening one ordinary `NSWindow`. First persisted state in the app (`NotchHubSettings`/`NotchHubSettingsStore`, one `UserDefaults.standard` key). No new entitlement. Design/invariants: `docs/superpowers/specs/2026-09-04-m7-settings-shell-design.md`.

First change to `NotchPanelController`'s core paths since its last physical acceptance (M1/M6.6/M6.11) — wires the new settings through the *existing* transition/migration mechanisms, no new one. Canonical CI GREEN 3/3, including a fresh `performance/m7-settings-shell-size-budget.json` derived from this PR's own measured candidate (the prior `m6-11-album-art-tint-size-budget.json` ceiling was too tight for the added feature). Full Swift suite 469/469 tests GREEN. Physical acceptance on the product owner's own Mac — all 8 checklist items PASS; no real defect found. Full evidence: `docs/testing/M7_SETTINGS_SHELL_ACCEPTANCE.md`.

PR #81 squash-merged as `165cd9e925ae14b41e01a3adef3390116437ce47`.

## Repository governance

Issue #42 remains open because `main` is intended to be protected but GitHub currently reports it unprotected. Restoring branch governance remains a repository-quality priority and should be completed when repository capabilities permit. Do not treat the current unprotected state as accepted architecture.

## Product modules after media/performance foundation

- **M2 Shelf**.
- **M3 Snippets**.
- **M4 Calendar**.
- **M5 Translator**.
- **M7 Product shell**.
- **M8 Trusted distribution — optional**.

## Current priority

1. Keep issue #42 visible for branch-protection restoration.
2. M7's first bounded Settings slice (PR #81: Launch at Login, Reduce Motion override, manual display override, About) is merged and physically accepted, not yet released. Unreleased work has accumulated on top of `v0.4.0`; a new Personal Release is a strong candidate before starting the next slice.
3. Require target-Mac physical acceptance before any shipping behavior change that CI cannot honestly prove.
4. Keep published releases (`v0.1.0`, `v0.2.0`, `v0.3.0`, `v0.4.0`) immutable; ship any future defect or feature as a new version.
