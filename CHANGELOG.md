# Changelog

All notable changes to NotchHub are documented here. The active version is stored in `VERSION`; published tags/releases are immutable.

## [Unreleased]

Published release remains `v0.1.0`. Everything below is source work not yet published as a new version.

### P1 — target-Mac whole-app resource audit

Status: **MEASUREMENT FOUNDATION MERGED / POST-MERGE CI GREEN / TARGET-MAC EVIDENCE PENDING / NO SHIPPING RUNTIME CHANGE**.

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

Final PR head `8f2e1c51ba8d69a66165a8e0db5f64f029cc3fcd` passed CI #1260 3/3 GREEN. Squash-merged tooling source `5cd9a2a47d87a433155f53b3aa0510000f2fce85` passed post-merge main CI #1261 3/3 GREEN, including the 367-test/81-suite gate, native XCUI, strict traceability, security, DMG, Sandbox/Hardened Runtime, unchanged active size budget and performance smoke.

Initial P1 target collection intentionally measures exact merged M6.6 runtime `bb6df211699c5aef7bac7d50866f3e24b2fe165b` using exact tooling `5cd9a2a47d87a433155f53b3aa0510000f2fce85`. Later documentation commits do not redefine those provenance anchors.

No new wakeup/energy/compositor numerical threshold is claimed from assumptions. P1 remains pending until repeatable target-Mac evidence is collected and reviewed.

### M6.6 — PR #33

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED ON EXACT `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3` / MERGED AS `bb6df211699c5aef7bac7d50866f3e24b2fe165b` / NOT RELEASED**.

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

#### Merge and post-merge verification

Acceptance-record head `c9fbd0605b33a318bb4371ae0f2c928120356adf` passed CI #1243 3/3 GREEN. PR #33 was squash-merged with expected-head protection as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`.

Post-merge main CI #1244 ultimately passed all three canonical jobs on that exact merge source. Its first packaging attempt failed only because runner `hdiutil verify` returned `Resource temporarily unavailable`; the failed job alone was rerun on unchanged source and passed. No application code or policy was changed for that retry.

M6.6 has reached **implemented -> automated-tested -> physically accepted -> merged**. It remains **not released**; immutable published version is still `v0.1.0`.
