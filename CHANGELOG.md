# Changelog

All notable changes to NotchHub are documented here. The active version is stored in `VERSION`; published tags/releases are immutable.

## [Unreleased]

Published release remains `v0.1.0`. Everything below is source work not yet published as a new version.

### M6.6 — PR #33

Status: **IMPLEMENTED / AUTOMATED-TESTED / PHYSICALLY ACCEPTED ON EXACT `8744b9e6239fa28a6d1094f6f4e7669e4ada25b3` / DRAFT / NOT MERGED / NOT RELEASED**.

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

The physically accepted runtime SHA remains `8744b9e...`. This acceptance-record synchronization changes documentation and machine-readable coverage only; it does not create a new physical-runtime claim.

#### Horizontal repair history retained

Earlier automated-green candidates exposed that command semantics and presentation sign could compensate for each other and still be physically wrong. `MediaGesturePhysicalPipelineTests` now binds raw AppKit horizontal delta -> scroll-preference normalization -> visual offset -> typed media command across both macOS scroll-direction preference states. Historical rejected candidates remain evidence and are not rewritten as passing.

#### Acceptance state

M6.6 has reached **physically accepted**, but not **merged** or **released**. PR #33 remains Draft pending explicit merge authorization. After merge, post-merge `main` CI must pass before P1 target-Mac performance/resource review begins.
