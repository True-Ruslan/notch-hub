# Changelog

All notable changes to NotchHub are documented here. The active version is stored in `VERSION`; published tags/releases are immutable.

## [Unreleased]

Published release remains `v0.1.0`. Everything below is source work not yet published as a new version.

### P1 — target-Mac whole-app resource audit

Status: **ACCEPTED — COMPLETE TARGET-MAC EVIDENCE / DIRECT GATES PASS / NOT RELEASED**.

P1 began with PR #36, which established the fail-closed target-Mac measurement/evidence foundation as historical tooling source `5cd9a2a47d87a433155f53b3aa0510000f2fce85`. The evidence contract separates measured runtime provenance from tooling provenance, freezes Idle/Hover/Stability timing and sample counts, stores only aggregate process evidence, uses a closed privacy-safe manual evidence surface and intentionally avoids privileged automatic collectors or new app permissions.

#### Tooling hardening

PR #44 corrected the platform validator after the physical target advanced to macOS `26.6.1`. Exact model remains `Mac16,8`; only canonical `26.6` / `26.6.x` versions are accepted; the exact patch is preserved and must agree across Idle/Hover/Stability/manual evidence. It squash-merged as `99a75dbe0664120a572bd8229d4fe461790ee07b`.

The first physical collection attempt then exposed locale-dependent `/bin/ps` output. PR #47 made sampling deterministic by applying `LC_ALL=C` only to the sampler subprocesses while preserving the parent/measured-app environment and strict parser. RED head `63af71dc9a614837fa2fe67f31d0cd0b5e3c0aa9` failed the intended locale regression; GREEN head `5e1d870f67972d5799c34e77acc1a8c1f4de9f7b` passed CI #1288 3/3 GREEN; squash merge `28965561f81c71ea58a352301fbe08554c644044` became the locale-stable sampler provenance.

PR #49 then extended the closed evidence contract with the accepted qualitative `manual-visual-compositor` fallback while retaining `instruments-core-animation` as preferred when available. It merged as final accepted P1 tooling/evidence checkout `fc7562b0799faa4dd80e8c47263354a8bd16bd6a`. `perf-baseline.py` itself remained unchanged from the locale-stable sampler ancestry.

#### Runtime defects found by physical P1 acceptance

P1 target-Mac testing found real behavior defects rather than merely resource numbers, and each candidate was rejected until physically corrected.

1. The earlier hardware-notch launch regression had already been repaired by PR #40, merged as `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`.
2. Manual compositor acceptance on that runtime exposed an expanded-size panel displaying compact content and remaining stuck. PR #51 added exact current-generation frame/corner reconciliation before logical settlement. RED `7e06d24d0b89f4c413c180882ec9d628384e9bce`; physically accepted GREEN head `329b867595b6ffe127fa3552f51bef8412865f37`; squash merge `1f56c3e5da8a46509a3472a52da12a1abfb16a8c`. Accepted head and merge share Git tree `8aebcc6db915b77e30c51b1d4fc45e4c3b895bb1`.
3. Activity Monitor then showed that the existing persistent global `.mouseMoved` monitor amplified unrelated external-monitor pointer motion from about `3` to `111` Idle Wake Ups while the app was otherwise inactive. PR #53 replaced persistent global observation with a bounded escape monitor tied to an actual local/tracking interaction.

The first PR #53 candidate that removed global observation entirely was rejected because rapid pointer exit could leave a large black Peek panel stuck. A second one-shot candidate was also rejected because it removed the global fallback on the first inside global sample before the true outside escape arrived. Final head `bddd0503d972c652752a0e1463f3495685accc83` retained the bounded monitor while samples remained inside the current interactive region and removed it only after the actual outside sample was delivered to the existing interaction state machine.

Final PR #53 physical acceptance on Mac16,8/macOS 26.6.2:

- rapid exit 30/30 PASS, including immediate exits and migration to the external monitor;
- normal compositor cycles 10/10 PASS;
- reversal recovery PASS;
- freeze/stuck panel NOT OBSERVED;
- frame/corner/flicker anomalies NONE;
- hardware-notch binding PASS;
- same-candidate Activity Monitor A/B: Idle Wake Ups `2` stationary and `2` during unrelated pointer motion on the external monitor, eliminating the prior `3 -> 111` amplification.

PR #53 squash-merged as final measured runtime `11dad43364a969f4d5f8c1a92e1281b5b41c8a74`. The physically accepted head and squash merge share exact Git tree `8f0a7fee0b02599520a5776133f51c1215da7d98`.

#### 2026-08-21 — final coherent P1 acceptance

The complete final bundle was recollected after the runtime fixes on one exact platform/tooling provenance:

- measured runtime `11dad43364a969f4d5f8c1a92e1281b5b41c8a74`;
- tooling `fc7562b0799faa4dd80e8c47263354a8bd16bd6a`;
- exact target `Mac16,8 / macOS 26.6.2`;
- hardware-notch binding PASS;
- exactly one measured NotchHub process from the built app with embedded source SHA matching the runtime.

Reviewed machine evidence:

- **Idle** — CPU median/max `0.0/0.0%`; RSS median/max `58,432/58,496 KiB`; thread median/max `3/6`. Direct Idle thread gate `<=6` PASS.
- **Hover** — CPU median/max `6.8/32.3%`; RSS median/max `75,936/76,784 KiB`; thread median/max `6/6`. CPU median steady-state target `<=8.0%` PASS and thread gate `<=9` PASS. The one-second CPU max remains diagnostic under the accepted policy and is not a standalone portable cross-session gate.
- **Stability** — CPU median/max `0.0/0.0%`; RSS start/end `58,816 -> 54,848 KiB`, delta `-3,968 KiB`; thread start/end `3 -> 3`, max `5`, delta `0`. RSS growth, thread max and thread-delta direct gates PASS.

Reviewed manual evidence:

- Activity Monitor Idle Wake Ups, 60 s: `0.0/s`, explicitly reviewed with no anomaly;
- Activity Monitor Energy fallback, 60 s: `no-anomaly-observed`; Energy Impact `0.0`, App Nap `No`, Preventing Sleep `No`; displayed 12-hour value `0.29` retained only as diagnostic historical context;
- manual visual compositor: exactly 10 cycles, `no-anomaly-observed`; reversal recovery PASS; no freeze/stuck panel or frame/corner/flicker anomaly.

The closed-schema manual evidence and normalized `p1-target-resource-evidence.json` validated successfully with `reviewRequired=false`. Final direct-gate review returned PASS for Idle threads, Hover CPU median/threads, Stability RSS growth/threads/thread delta and manual review status.

Issue #38 was closed completed after review. Earlier 26.6.1, pre-settlement and pre-pointer-fix evidence remains immutable diagnostic history and is not mixed into this accepted bundle.

No speculative runtime optimization is justified by the accepted evidence. P1 acceptance is not a release event; published release remains `v0.1.0`.

### M1 — event-driven active-display / multi-monitor migration

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / NOT RELEASED**.

PR #56 adds event-driven display-topology migration: observes `NSApplication.didChangeScreenParametersNotification`, resolves `NSScreen.screens` fresh on topology change while preserving hardware-notch-first selection and the accepted `NSScreen.main`/first-screen fallback, migrates stable Compact/Peek/Expanded endpoints to the newly resolved display through one shared `NotchPanelLayoutModel`, retargets in-flight programmatic and interactive transitions by generation so stale animation completions cannot move the new screen endpoint, cancels interrupted interactive transitions back to their origin presentation, reconciles the physical settled frame/corner synchronously across migration, and resets the bounded pointer-escape monitor. No new dependency, permission, entitlement, networking, telemetry, timer, display link or persistent global input monitoring was added.

Automated verification: exact candidate `dd945dc3ca009f8d9429ad044d50a01a2ea1bb62`; CI #1344 / run `32527603794` 3/3 GREEN across `macOS 26 compatibility`, `macOS UI regression` (including external-app XCUI smoke) and `Build, test and package`; full coverage-instrumented Swift suite passed 392 tests; formatting, acceptance-traceability, source performance policy, security baseline, warnings-as-errors builds, shipping-media preflight, codesign, Hardened Runtime, exact sandbox-only entitlement, system-library/provenance checks, DMG verification and the active `performance/m1-active-display-migration-size-budget.json` size gate all passed.

Physical acceptance on exact `Mac16,8 / macOS 26.6.2`, built-in hardware-notch display plus an external monitor (2560x1440) connected — **11/11 PASS**: Compact/Peek/Expanded connect-disconnect-reconfigure (including media continuity in Expanded); interruption of programmatic Compact->Expanded and Expanded->Compact transitions with no frozen intermediate state; interruption of partial interactive expansion and collapse gestures, cancelling cleanly without unintended haptic/commit; no-notch first-screen fallback; 5-10x repeated migration cycles with no jitter, duplicate observers or accumulating lag; post-migration pointer/hover scoped only to the current hardware-notch screen with correct rapid-exit Peek collapse; and no new macOS permission prompts across the run. Post-Quit `pgrep -lf 'mediaremote-adapter\.pl' || true` empty.

PR #56 squash-merged as `c7d2bdb9cae744d439d240f22acd14140bacedd3`; issue #55 closed completed. Design/invariants: `docs/superpowers/specs/2026-08-21-active-display-multi-monitor-migration-design.md`. Published release remains `v0.1.0`.

### M6.7 — live media timeline and live Compact display

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / NOT RELEASED**.

PR #58 deliberately reverses two prior accepted invariants, both explicitly decided by the product owner and recorded before implementation in `docs/superpowers/specs/2026-08-22-live-media-timeline-and-compact-design.md`:

1. **Always-on shipping media runtime.** `ShippingMediaRuntime.start()` now runs once at launch and `stop()` once at Quit, instead of being scoped to settled `.expanded`. Compact's existing artwork/play-pause icon becomes live for free — already reactively bound to the presentation model — reflecting a track change, pause or play/pause toggle performed outside NotchHub without needing to re-expand.
2. **One narrowly-scoped, reviewed, bounded-lifecycle timer.** `MediaTimelineTicker` extrapolates the displayed playback position between authoritative system events at ~300ms, armed only while the settled panel presentation is Peek or Expanded and playback is active, torn down on collapse, pause, session loss or quit; never runs in Compact or Idle. `scripts/performance_policy.py`'s runtime audit previously had no exception mechanism at all for its blanket Timer/polling scan; this PR adds a fail-closed, schema-validated reviewed-exception manifest (`performance/reviewed-runtime-timers.json`) scoped to exactly this one `(file, rule)` pair, covered by its own unit tests, rather than working around the audit with a different API.

A real pre-existing hazard was found and fixed along the way: `MediaPeekSession.handleSettledPeek()` started its bounded one-shot probe unconditionally, which was safe before M6.7 (Compact/Peek never had a live authoritative presentation to protect) but could clobber the runtime's already-good data with the probe's `.noSession` result once the runtime became always-active — reproduced by a hover-then-click sequence erasing title/artist/artwork moments before Expanded rendered. Fixed by skipping the probe entirely when a live presentation already exists.

Automated verification: canonical CI (`macOS 26 compatibility`, `macOS UI regression`, `Build, test and package`) 3/3 GREEN on exact candidate `3cee40c9650d50254f25e633a3e0e5163124df07`; `MediaTimelineTickerTests` (fully clock/timer-injected, no real `Timer`/run loop) cover bounded arm/disarm conditions, extrapolation and duration clamping, re-anchoring without drift, and optimistic seek re-anchoring; `scripts/performance_policy.py`'s reviewed-exception mechanism has its own fail-closed unit tests; the active `performance/m6-7-live-media-timeline-and-compact-size-budget.json` size gate passed.

Physical acceptance on exact `Mac16,8 / macOS 26.6.2` — **7/7 PASS**: live-ticking timeline in Peek and in Expanded while playing; exact freeze on pause with no drift and correct resume; Compact reflecting a track change/pause/play-pause toggle performed outside NotchHub without re-expanding; `ps` CPU sampling across 5 samples while settled Compact showed `0.0%` (ticker correctly torn down); post-Quit `pgrep -lf 'mediaremote-adapter\.pl'` empty under a normal quit; and a fresh P1-style Idle/Hover/Stability resource bundle, required because Idle no longer has a zero-adapter baseline —

| Scenario | CPU median/max | RSS median/max (KiB) | Thread median/max |
|---|---|---|---|
| Idle | 0.0% / 2.4% | 73,648 / 73,776 | 4 / 5 |
| Hover | 0.0% / 18.0% | 71,832 / 72,128 | 3 / 5 |
| Stability | 0.0% / 0.0% | 64,160 / 71,648 | 3 / 7 |

with Stability RSS `71,648 -> 59,904` KiB (delta `-11,744`, a decrease) and threads `3 -> 3` (delta `0`). All direct gates PASS against the previously accepted thresholds (Idle threadMax `<=6`; Hover CPU median `<=8.0%`, threadMax `<=9`; Stability RSS delta `<=+8192`, threadMax `<=9`, thread delta `<=+2`) despite the adapter now running continuously. This bundle supersedes the prior "zero-adapter compact" Idle baseline in `docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md`, which remains immutable historical evidence for the source it measured.

Physical acceptance also confirmed Force Quit (Activity Monitor) leaves an orphaned `mediaremote-adapter.pl` process — expected for any app with a child process under SIGKILL, not a regression — and surfaced a separate, non-blocking follow-up: NotchHub has no user-discoverable normal-quit path today (no Dock icon, no Quit menu item, Cmd+Q is a no-op).

PR #58 squash-merged as `bd48037baff85d8eb3354fbf3792c5db016ff4a1`. Full evidence: `docs/testing/M6_7_LIVE_MEDIA_TIMELINE_AND_COMPACT_ACCEPTANCE.md`. Published release remains `v0.1.0`.

### M6.8 — compact live equalizer

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / NOT RELEASED**.

Competitive review of `TheBoredTeam/boring.notch` (open source, same `MediaRemoteAdapter`) and NotchNook found one concrete, low-risk UX improvement worth borrowing: both replace a static play/pause glyph in Compact with a small animated equalizer/spectrum that visibly pulses while something is playing. PR #60 adds `MediaCompactEqualizerView`, replacing `MediaNotchRootView.compactMediaContent`'s static SF Symbol with 3 bars driven by SwiftUI's `PhaseAnimator`, armed only while `playbackState == .playing`, settling to a flat static pose on pause. No timer primitive, no new `performance/reviewed-runtime-timers.json` entry needed — confirmed by `scripts/performance_policy.py audit Sources` staying green.

Physical acceptance on exact `Mac16,8 / macOS 26.6.2` — all items PASS: bars visibly animate out of phase while playing; settle flat on pause and restart correctly on resume; `ps` CPU sampling across 5 samples while settled Compact with media playing showed `0.0%`; no jank introduced to existing hover-for-Peek/click-for-Expanded interaction; clean post-Quit process teardown under a normal quit.

A real bug was found and fixed during acceptance: the initial implementation drove the bars with `.animation(...repeatForever...)`, which froze mid-animation after the horizontal next/previous swipe gesture — the swipe's own `withAnimation` transaction interrupted the bars' implicit repeating loop, a documented SwiftUI gotcha, only recovering after expand+collapse force-recreated the view. Fixed by switching to `PhaseAnimator`, which owns its own animation timeline and is not vulnerable to an ancestor's unrelated explicit animation transaction — the documented reason Apple introduced it as the modern replacement for perpetual `repeatForever` loops. Re-verified: repeated next/previous swipes no longer freeze the equalizer.

PR #60 squash-merged as `4cbb01d7d5f57f26c40162c8149faf27691c2e06`. Full evidence: `docs/testing/M6_8_COMPACT_LIVE_EQUALIZER_ACCEPTANCE.md`. Published release remains `v0.1.0`. Other competitive-review ideas surfaced but explicitly deferred: album-art color tinting, `matchedGeometryEffect` cross-state artwork morphing, marquee text for overflowing titles.

### M6.6 — PR #33 + corrective runtime work

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / NOT RELEASED**.

Original M6.6 full physical acceptance remains pinned to exact `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3`; PR #33 squash-merged as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`.

Accepted M6.6 behavior includes:

- local App-owned media gesture session with bounded horizontal visuals and public AppKit arm haptic;
- stable `compact`, `peek`, `expanded` presentation states under the existing Core transition authority;
- exactly 120 ms Hover Peek activation plus 140 ms pointer-exit grace;
- generic no-media Peek with one hover-haptic request after valid dwell;
- click and physical DOWN as explicit expansion paths;
- bounded one-shot media probing/commands in compact and Peek while persistent runtime remains expanded-only;
- bounded Peek cancellation and transport teardown;
- physical LEFT -> `next`, RIGHT -> `previous`, independent of macOS scroll-direction preference;
- draggable seek/source identity/cursor isolation;
- hardware-notch-first initial screen selection with `NSScreen.main`/first-screen fallback;
- exact current-generation physical endpoint settlement before logical presentation settlement;
- bounded pointer escape monitoring only during an actual interaction rather than persistent global mouse observation.

No global scroll/button/keyboard monitor, mouse-button event authority, event tap, polling loop, repeating timer, display link, UI-test retry/sleep masking, networking/telemetry authority or new sensitive permission was added.

Published release remains `v0.1.0`.
