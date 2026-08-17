# Changelog

All notable changes to NotchHub are documented here. The active version is stored in `VERSION`; published tags/releases are immutable.

## [Unreleased]

Published release remains `v0.1.0`. Everything below is source work not yet published as a new version.

### M6.6 — current draft PR #33

Status: **IMPLEMENTED / REGRESSION-INTEGRATED / CI #1238 3/3 GREEN / FINAL HORIZONTAL PHYSICAL CONTRACT PASS ON `f2e81d993...` / FULL ONE-SHA PHYSICAL MATRIX PENDING / NOT MERGED / NOT RELEASED**.

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

#### 2026-08-18 — final horizontal physical contract

Final source `f2e81d993db37af9548799682ad8f03c7d64ae27` / CI #1238 / run `32072408370` passed all three canonical jobs, 365 Swift tests / 79 suites, external exact-app XCUI 11/11, production transport/archive, security/source policy, Sandbox/Hardened Runtime/signing/preflight, unchanged size budget and performance smoke.

Physical testing on Mac16,8/macOS 26.6 confirmed on that exact source:

- RIGHT -> Previous/back and visual motion follows the fingers RIGHT;
- LEFT -> Next and visual motion follows the fingers LEFT;
- below-threshold horizontal smoke -> no switch;
- momentum -> no extra switch;
- DOWN/UP smoke remains correct;
- supported horizontal arm haptic is felt exactly once.

The final root cause was a compensating-sign design across horizontal AppKit normalization, presentation displacement and media direction. The repair makes normalized X equal the physical finger direction; presentation consumes that same X and semantic command mapping remains negative/LEFT -> Next, positive/RIGHT -> Previous. Vertical normalization is unchanged.

A new `MediaGesturePhysicalPipelineTests` characterization binds raw AppKit delta -> scroll-preference normalization -> visual offset -> typed media command across both macOS scroll-direction preference states. This test is intentionally added after physical closure to prevent the specific class of compensating-sign regression that escaped narrower unit tests. It adds no production behavior.

#### Physical acceptance history

- `d008f698b323963f084eedce601620ee957ef442` / CI #872 — rejected; later cycles repaired hover arbitration, vertical direction, stale seek identity and visual continuity.
- `bbba286030b3a9d193fd2c8c913691af5c8fa200` / CI #945 — rejected on stationary-startup Hover Peek; startup regression subsequently repaired.
- `c9b4174e9cb1c841171418ade06ade833712be21` / CI #951 — rejected for expanded pointer-exit and interactive lost-terminal behavior.
- `0a7a7c46342eb9424b55ce9e89734d9c73a437f6` / CI #1101 — rejected for no-media Hover Peek/haptic and exact-top-edge DOWN self-collapse.
- `6c2109195042759b951217f489a201a82dd044cd` / CI #1156 — automated-green but physically rejected because LEFT/RIGHT track commands were reversed.
- `e39f501a6388c8a0d53c1360f8b44e1bb72454cd` — physical animation followed the fingers, but media command direction remained reversed relative to the final contract.
- `f2e81d993db37af9548799682ad8f03c7d64ae27` / CI #1238 — final horizontal direction + follow-finger + haptic smoke PASS.

Historical failures remain evidence for their exact candidates and are not erased by later GREEN runs.

#### Hover Peek / lifecycle hardening retained

The final architecture keeps generic Peek before optional enrichment, inclusive exact-top-edge containment, stable outer SwiftUI click authority and local `NSTrackingArea` hover. Bounded Peek teardown uses nonblocking cancellation on the UI actor; persistent expanded runtime and explicit Quit retain synchronous fail-closed teardown verification.

`MediaRemoteSystemTransportStopRaceTests` and `ShippingMediaPeekProbeTransportIntegrationTests` cover queued capability stop races, stale callbacks, first-usable-snapshot completion and bounded release. The speculative `NSEvent.pressedMouseButtons` timing guard and primary-press production seam were removed after they failed to provide deterministic correctness.

#### Acceptance status after this synchronization

The horizontal physical contract is proven on `f2e81d993...`, but M6.6 as a whole remains pending because the final one-SHA matrix still requires media/no-media Peek + haptic, stationary restart, click-during-enrichment, exact-edge DOWN, pointer-exit/UP settlement, seek/cursor/source continuity, source icon, permission surface and post-Quit helper cleanup on one frozen documentation/test head.

The new test/documentation commit changes no production code. Its exact head must independently pass all three canonical CI jobs before it can be frozen for that final target-Mac matrix.
