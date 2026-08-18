# Changelog

All notable changes to NotchHub are documented here. The active version is stored in `VERSION`; published tags/releases are immutable.

## [Unreleased]

Published release remains `v0.1.0`. Everything below is source work not yet published as a new version.

### P1 — target-Mac whole-app resource audit

Status: **ACTIVE / DRAFT PR #36 / MEASUREMENT FOUNDATION IN PROGRESS / NO SHIPPING RUNTIME CHANGE**.

Started the post-M6.6 performance/resource gate:

- added a fail-closed target-Mac evidence bundler for existing idle/hover/stability CPU/RSS/thread reports;
- requires one exact measured-app source SHA, one measurement-tool SHA and exact `Mac16,8 / macOS 26.6` platform;
- freezes canonical 10 s warmup + 60/60/600 s measurement windows and 1/1/5 s sample intervals;
- normalizes only aggregate process metrics and required stability evidence;
- adds a closed privacy-safe manual evidence surface for 60-second idle wakeups, 60-second energy observation and 10-cycle compositor review;
- rejects arbitrary free-form fields, raw trace payloads, non-finite metrics, unsupported methods and provenance/configuration mismatches;
- intentionally does not auto-run privileged `sudo powermetrics`/`timerfires` and adds no app entitlement or runtime telemetry;
- runs the Python evidence contract inside canonical `swift test` through `P1TargetResourceEvidencePolicyTests`;
- added `docs/testing/P1_TARGET_RESOURCE_ACCEPTANCE.md` and the active P1 implementation plan.

TDD RED was captured by CI #1245 at head `6b7e90ff17803ef2678ff518b84fe82c8a39e06f`: 367 tests / 81 suites ran and exactly the new P1 gate failed because `p1_target_resource_evidence` had not yet been implemented. Existing suites remained green.

No new wakeup/energy/compositor numerical threshold is claimed from assumptions. P1 must first collect repeatable target-Mac evidence and characterize variance.

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

Frozen runtime source `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3` passed canonical CI #1241 / run `32075976405`:

- macOS 26 compatibility — GREEN;
- Build, test and package — GREEN;
- macOS UI regression — GREEN;
- 366 Swift tests / 80 suites — GREEN;
- external exact-app XCUI 11/11 — GREEN;
- strict acceptance traceability, production MediaRemote transport/archive, Sandbox/Hardened Runtime/signing/preflight, unchanged active cumulative size budget and shared-runner performance smoke — GREEN.

The complete requested Mac16,8/macOS 26.6 matrix then passed on that exact source:

- RIGHT -> Previous/back; presentation follows the fingers RIGHT; one supported arm haptic;
- LEFT -> Next; presentation follows the fingers LEFT; one supported arm haptic;
- media-on hover -> Peek + physical haptic without hover-only expansion;
- stationary-pointer relaunch -> Peek + physical haptic;
- media-off hover -> generic Peek + physical haptic;
- explicit compact click remains prompt and single while Hover Peek/media enrichment can overlap;
- exact-top-edge and center DOWN follow the finger and settle Expanded without twitch/self-collapse;
- expanded pointer exit and physical UP, including UP while leaving retention, settle exact Compact;
- seek preview / commit / cancel work; cursor restores; track/source identity change cancels the transaction;
- source-app icon and neutral fallback render correctly;
- Accessibility, Input Monitoring, Automation and Screen Recording remain NONE;
- after real Quit, `pgrep -lf 'mediaremote-adapter\.pl' || true` is empty.

The physically accepted runtime SHA remains `8744b9e...`. Acceptance-record commits changed documentation/coverage only and did not create a replacement physical-runtime claim.

#### Merge and post-merge verification

Acceptance-record head `c9fbd0605b33a318bb4371ae0f2c928120356adf` passed CI #1243 3/3 GREEN. PR #33 was then marked Ready and squash-merged with expected-head protection as `bb6df211699c5aef7bac7d50866f3e24b2fe165b`.

Post-merge main CI #1244 ultimately passed all three canonical jobs on that exact merge source. Its first packaging attempt failed only because runner `hdiutil verify` returned `Resource temporarily unavailable` after build/tests/signing had succeeded. The failed job alone was rerun on unchanged source and passed every packaging/security/performance step. No application code or policy was changed for that retry.

#### Acceptance state

M6.6 has reached **implemented -> automated-tested -> physically accepted -> merged**. It remains **not released**; immutable published version is still `v0.1.0`.
