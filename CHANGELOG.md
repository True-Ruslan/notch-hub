# Changelog

All notable changes to NotchHub are documented here. The active version is stored in `VERSION`; published tags/releases are immutable.

## [Unreleased]

Published release remains `v0.1.0`. Everything below is source work not yet published as a new version.

### P1 — target-Mac whole-app resource audit

Status: **MEASUREMENT FOUNDATION MERGED / CORRECTED MERGED RUNTIME RE-FROZEN / TARGET-MAC EVIDENCE PENDING**.

PR #36 established and merged the post-M6.6 performance/resource measurement foundation as exact tooling source `5cd9a2a47d87a433155f53b3aa0510000f2fce85`:

- added a fail-closed target-Mac evidence bundler for existing idle/hover/stability CPU/RSS/thread reports;
- requires one exact measured-app source SHA, one measurement-tool SHA and exact `Mac16,8 / macOS 26.6` platform;
- freezes canonical 10 s warmup + 60/60/600 s measurement windows and 1/1/5 s sample intervals;
- normalizes only aggregate process metrics and required stability evidence;
- adds a closed privacy-safe manual evidence surface for 60-second idle wakeups, 60-second energy observation and 10-cycle compositor review;
- rejects arbitrary free-form fields, raw trace payloads, non-finite metrics, unsupported methods, malformed manual types and provenance/configuration mismatches;
- intentionally does not auto-run privileged `sudo powermetrics`/`timerfires` and adds no app entitlement or runtime telemetry;
- runs the Python evidence contract inside canonical `swift test` through `P1TargetResourceEvidencePolicyTests`;
- added the exact two-worktree target collection procedure and active P1 plan;
- changed development tooling/tests/docs only, with zero `Sources/` changes.

TDD RED evidence:

- CI #1245 at `6b7e90ff17803ef2678ff518b84fe82c8a39e06f`: exactly the new P1 gate failed because the implementation module did not exist;
- CI #1258 at `98cd0974da8e1a71b6322d168e9f28834fe72a0c`: exactly the malformed manual-type regression failed because an uncontrolled `TypeError` escaped instead of fail-closed `EvidenceError`.

Final PR head `8f2e1c51ba8d69a66165a8e0db5f64f029cc3fcd` passed CI #1260 3/3 GREEN. Squash-merged tooling source `5cd9a2a47d87a433155f53b3aa0510000f2fce85` passed post-merge main CI #1261 3/3 GREEN, including the 367-test/81-suite gate, native XCUI, strict traceability, security, DMG, Sandbox/Hardened Runtime, active size budget and performance smoke.

Before target collection began, the old P1 runtime `bb6df211699c5aef7bac7d50866f3e24b2fe165b` was superseded for measurement because the later real multi-monitor check found the hardware-notch screen-selection regression described below. Canonical P1 target collection now measures corrected merged runtime `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251` using unchanged exact tooling `5cd9a2a47d87a433155f53b3aa0510000f2fce85`.

Physical, CI and merge provenance remain distinct: the corrected runtime behavior physically passed on exact source `46f069e57997eab060c79c3d9e279da944d6e263`; no shipping `Sources/` changed after that point; final PR #40 head `b19801be1201a43572f5ea6574d32edfc9174dc5` passed CI #1274 3/3 GREEN; the squash merge `e8d77968...` shares Git tree `f1884e9727d3d5794fb0122e86d9d0b85c3d9d21` with that final head.

No new wakeup/energy/compositor numerical threshold is claimed from assumptions. P1 remains pending until repeatable target-Mac evidence is collected and reviewed.

### M6.6 — PR #33 + corrective PR #40

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED / MERGED / NOT RELEASED**.

Original M6.6 full physical acceptance remains pinned to exact `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3`; PR #33 squash-merged as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`.

Added and hardened:

- local App-owned media gesture session with bounded horizontal visuals and public AppKit arm haptic;
- stable `compact`, `peek`, `expanded` presentation states under the existing Core transition authority;
- exactly 120 ms Hover Peek activation plus 140 ms pointer-exit grace;
- generic no-media Peek with one hover-haptic request after valid dwell;
- click and physical DOWN as explicit expansion paths, with stable outer SwiftUI tap ownership;
- persistent nonactivating AppKit host first-mouse acceptance without mouse-button authority;
- bounded one-shot media probing/commands in compact and Peek while persistent runtime remains expanded-only;
- bounded Peek cancellation that is nonblocking for the UI actor while subprocess ownership remains bounded by finite graceful/forced deadlines;
- stop-race hardening that prevents queued capability work or stale callbacks from escaping a stopped transport;
- exact-top-edge inclusive pointer retention for interactive DOWN;
- physical horizontal normalization independent of macOS scroll-direction preference: LEFT -> `next`, RIGHT -> `previous`;
- horizontal presentation that follows the physical finger direction;
- source-app identity badge through public `NSWorkspace` with bounded in-memory cache;
- capability-gated draggable seek in Peek and expanded, identity-locked across track/source changes;
- balanced seek cursor ownership without pointer warp/lock;
- strict native regression/UI automation and provenance-backed cumulative size budgets.

No global scroll/button/keyboard monitor, mouse-button event authority, event tap, polling loop, repeating timer, display link, UI-test retry/sleep masking, network/telemetry authority or new sensitive permission was added.

#### 2026-08-18 — full M6.6 physical acceptance

Frozen runtime source `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3` passed canonical CI #1241 / run `32075976405` 3/3 GREEN with 366 Swift tests / 80 suites and external exact-app XCUI 11/11.

The complete requested Mac16,8/macOS 26.6 matrix then passed on that exact source, including horizontal direction/follow-finger/haptic behavior, Hover Peek, click, vertical transitions, seek/source/cursor handling, source icon/fallback, no sensitive permissions and clean helper teardown after Quit.

#### Original merge and post-merge verification

Acceptance-record head `c9fbd0605b33a318bb4371ae0f2c928120356adf` passed CI #1243 3/3 GREEN. PR #33 was squash-merged with expected-head protection as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`.

Post-merge main CI #1244 ultimately passed all three canonical jobs on that exact merge source. Its first packaging attempt failed only because runner `hdiutil verify` returned `Resource temporarily unavailable`; the failed job alone was rerun on unchanged source and passed. No application code or policy was changed for that retry.

#### 2026-08-19 — hardware-notch screen-selection correction

A real Mac16,8/macOS 26.6 launch with an external monitor attached exposed that `NSScreen.main` was not a valid product invariant: NotchHub could bind to the external display even though the built-in hardware-notch display was available.

PR #40 added deterministic hardware-notch-first screen selection using existing public AppKit geometry signals, preserving `NSScreen.main` then first-screen fallback when no hardware notch exists. No polling, private display API, telemetry, new permission, entitlement or persistent display state was added.

Exact runtime `46f069e57997eab060c79c3d9e279da944d6e263` was built with matching `NHSourceCommit` and physically re-checked with the external monitor attached — hardware-notch binding PASS. Subsequent commits changed only size-policy/CI/test metadata. Final head `b19801be1201a43572f5ea6574d32edfc9174dc5` passed CI #1274 3/3 GREEN, including the provenance-locked hardware-notch repair size envelope. PR #40 squash-merged as corrected merged runtime `e8d77968abd9ba7a5aaed6c63d108a67b8d8a251`.

M6.6 has reached **implemented -> automated-tested -> physically accepted -> merged**. It remains **not released**; immutable published version is still `v0.1.0`.
