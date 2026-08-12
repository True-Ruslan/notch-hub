# Interactive Notch Media UX Design

Status: APPROVED IN PRODUCT DIRECTION / WRITTEN SPEC PENDING REVIEW
Date: 2026-08-12
Target: NotchHub Personal Release on macOS 26.6 / Mac16,8
Scope: M6.6 user-visible interaction layer after merged Tasks 0–4

## 1. Purpose

NotchHub should feel physically connected to the MacBook notch rather than behaving like a conventional popover that merely appears below it. The next M6.6 user-visible slice therefore adds an interactive compact-to-expanded morph, local media swipe tracking, semantic media haptics, and source-application identity as an icon rather than persistent source text.

The product direction is inspired by the interaction qualities the user likes in notch utilities such as NotchHook and by the source-app icon treatment seen in TheBoringNotch. These products are references for interaction goals only. NotchHub must use an independent implementation, its existing architecture, and its own visual language. No external implementation is copied.

This design supersedes the old M6.6 Task 5+ interaction assumptions where they conflict. M6.6 Tasks 0–4 remain accepted foundations and are not reopened; later tasks may consume their public seams without weakening their accepted behavior.

## 2. Product outcome

The user should perceive one continuous surface attached to the physical notch:

- compact NotchHub remains visually anchored to the hardware notch;
- a local downward trackpad gesture progressively pulls the notch surface open rather than waiting until release and then playing a fixed endpoint animation;
- a local upward gesture from expanded progressively pushes the panel back into the physical notch;
- cancelling or reversing before commit returns smoothly to the starting endpoint;
- releasing after the existing 70 pt vertical commit threshold settles to the destination using the existing animation policy;
- horizontal media gestures visibly track the finger and commit previous/next only on physical release;
- horizontal media arm transitions keep the already-frozen one-haptic semantics;
- the source application is represented primarily by its application icon, not a persistent textual label in the visual player chrome;
- draggable seek remains capability-driven and isolated from track/panel gestures.

Hover remains a first-class alternate expansion input. Existing hover behavior is not replaced by the vertical gesture.

## 3. Non-goals

This slice does not add:

- click-to-pin or click-to-toggle policy;
- global scroll capture;
- synthetic media keys;
- application-specific media integrations;
- a source selector;
- volume gestures;
- automatic opening based on media events;
- artwork-driven continuous color extraction;
- a second panel/geometry owner;
- continuous media observation while settled compact;
- a new vertical-gesture haptic contract;
- any new Accessibility, Input Monitoring, Automation, Screen Recording, network, telemetry, file, Contacts, Calendar, or clipboard authority.

Those remain separate future decisions.

## 4. Existing accepted foundations

This design depends on and preserves the following merged M6.6 foundations:

1. Task 0: in-flight compact layout changes safely retarget collapse through `NotchPanelTransitionCoordinator`.
2. Task 1: every media one-shot process is lifecycle-owned and teardown-safe.
3. Task 2: `MediaGestureCoordinator` is the pure deterministic gesture state machine for threshold, hysteresis, momentum, diagonal arbitration, capability gating, vertical intents, and seek isolation.
4. Task 3: local scroll delivery exists only on NotchHub's owned hosting view, and programmatic expansion/collapse route through the transition coordinator.
5. Task 4: settled-compact previous/next capability checks and commands use a bounded one-shot dispatcher with no persistent observation.

The implementation must build on these seams rather than bypassing them.

## 5. Interactive panel transition architecture

### 5.1 Single authority

`NotchPanelTransitionCoordinator` remains the only owner of compact/expanded panel transition state, frame targets, corner-radius targets, cancellation generation, and stale-completion rejection.

Neither `AppDelegate`, SwiftUI views, nor the gesture session may call `NSPanel.setFrame` or animate panel geometry directly.

### 5.2 New interactive transition state

The transition coordinator gains an interactive transition mode distinct from its existing endpoint animation phases.

Conceptual state:

```text
compact
  -> interactiveExpanding(progress)
  -> expanding
  -> expanded

expanded
  -> interactiveCollapsing(progress)
  -> collapsing
  -> compact
```

Interactive state is driven synchronously by local physical gesture samples. It does not allocate one Swift concurrency task per scroll event.

The coordinator owns:

- transition origin (`compact` or `expanded`);
- normalized interactive progress `0...1`;
- current interpolated frame and corner radius;
- commit/cancel handoff to the existing endpoint settle path;
- generation invalidation when another authoritative transition wins.

The existing `NotchPanelController` remains the AppKit panel owner and injects the narrow immediate-presentation callback used by the coordinator. The controller may update its owned panel only when invoked by the coordinator; application composition code does not gain direct panel-frame authority.

### 5.3 Geometry interpolation

Interactive geometry uses the current authoritative `NotchLayout` endpoints.

For normalized progress `p` in `0...1`:

```text
frame.origin.x = lerp(compact.origin.x, expanded.origin.x, p)
frame.origin.y = lerp(compact.origin.y, expanded.origin.y, p)
frame.width    = lerp(compact.width,    expanded.width,    p)
frame.height   = lerp(compact.height,   expanded.height,   p)
cornerRadius   = lerp(compactRadius,    expandedRadius,    p)
```

The interpolation must use the same top-edge/screen-space conventions as the accepted endpoint transition. Interactive motion may not create a second geometry model.

### 5.4 Progress mapping

The semantic vertical commit threshold remains the already-frozen `70 pt` in `MediaGestureCoordinator`.

Visual progress is intentionally more responsive than commit semantics:

```text
visualProgress = clamp(abs(cumulativeVerticalDelta) / interactiveTravel, 0...1)
interactiveTravel = max(140 pt, min(expandedHeight - compactHeight, 220 pt))
```

The gesture can therefore visually follow the finger before the semantic commit threshold is reached, while `MediaGestureCoordinator` remains authoritative for whether release requests expansion/collapse.

Target-Mac physical acceptance may tune `interactiveTravel` once if the motion feels too stiff or too eager. Any accepted value is then frozen into deterministic tests. The `70 pt` semantic threshold is not silently changed by visual tuning.

### 5.5 Commit and cancellation

On physical gesture end:

- if `MediaGestureCoordinator` emitted `requestExpansion`, interactive expansion settles to `.expanded` through the normal transition coordinator path;
- if it emitted `requestCollapse`, interactive collapse settles to `.compact` through the normal transition coordinator path;
- if no semantic transition intent was emitted, the panel settles back to its origin endpoint;
- `.cancelled` always returns to the origin endpoint;
- momentum cannot begin, arm, commit, or continue an interactive panel transition.

The settle animation begins from the current presentation state and uses the existing Reduce Motion policy. Reduce Motion still resolves to the exact destination without an extra animation.

### 5.6 Arbitration with hover and other transitions

Interactive gesture ownership is fail-closed:

- a vertical interactive gesture may begin only while the corresponding stable endpoint is authoritative;
- an already-running endpoint transition is not converted into a new interactive gesture mid-flight;
- horizontal capture prevents vertical interactive panel progress for that physical gesture;
- seek capture prevents panel interaction;
- if hover or another authoritative transition changes the desired presentation before the gesture owns a valid interactive session, the gesture is ignored;
- invalidation or screen/layout authority changes cancel the interactive session and resolve through the current authoritative layout.

No stale interactive completion may restore an older frame after a newer transition generation.

## 6. Media gesture visual tracking

`MediaGestureCoordinator` remains the semantic recognizer. A new App-owned `MediaGestureSession` adapts local `NSEvent` scroll samples to the pure coordinator and maps emitted effects to platform actions.

For horizontal gestures:

- compact artwork/status may translate subtly with the finger;
- expanded Media artwork/card may translate more visibly;
- visual translation is clamped and damped; it does not represent a fabricated next track;
- entering horizontal `armed` produces exactly one public AppKit `.levelChange` haptic per armed transition;
- leaving `armed` through hysteresis resets the armed treatment without an extra haptic;
- physical release while armed sends exactly one previous/next command;
- commit does not emit a second haptic;
- the view returns to authoritative media state after command completion/event update;
- stale async capability/command results are ignored by existing generation/lifecycle rules.

Vertical panel morph uses visual tracking only. It does not add a new haptic signal. Hover expansion keeps its already-accepted haptic behavior, and horizontal gesture haptics must not double-fire with it.

The App-owned session does not know about MediaRemote details. It calls only the accepted `ShippingMediaRuntime`, `ShippingMediaCompactCommandDispatcher`, and panel-controller seams.

## 7. Source application icon

### 7.1 Presentation data

`ShippingMediaPresentation` gains a separate optional `sourceBundleIdentifier` in addition to the normalized source display name retained for accessibility/help semantics and deterministic tests.

The bundle identifier is normalized from authoritative `MediaSessionSnapshot.source.bundleIdentifier`. It is not inferred from title/artist text.

### 7.2 App-layer resolver

Application icon lookup belongs in `NotchHubApp`, not `NotchHubMediaCore`, because `NSWorkspace` is an AppKit platform concern.

Introduce a small `SourceApplicationIconResolver` with these rules:

- input: normalized bundle identifier;
- resolve via public `NSWorkspace.urlForApplication(withBundleIdentifier:)`;
- obtain the icon via public workspace/application APIs;
- in-memory cache capacity: at most 8 bundle identifiers for the application lifetime;
- no filesystem crawling;
- no persistence;
- no polling;
- no network;
- failure returns `nil` rather than inventing an application identity.

The resolver is invoked on source identity change, not on every SwiftUI render.

### 7.3 Visual treatment

Expanded Media removes the persistent source text row from normal visual chrome.

Instead:

- show a `24 pt` source application icon badge at the lower trailing corner of the album artwork;
- use a lightweight dark backing/border only as needed to keep the badge legible over bright artwork;
- when icon resolution fails, show a neutral system application glyph badge rather than textual source chrome;
- expose the normalized source display name through accessibility/help metadata so source identity remains understandable without relying exclusively on the icon;
- compact Media does not gain an additional source icon in this slice; it remains artwork-left/status-right to preserve the accepted 36 pt wings.

This pattern is independently implemented. TheBoringNotch is a visual/product reference only. The inspected repository revision is GPL-3.0, so no source text or implementation is copied into NotchHub.

## 8. Media runtime lifecycle during interactive motion

The accepted M6.4/M6.5 lifecycle remains unchanged.

### Compact -> interactive expansion

- settled compact starts with zero persistent adapter processes;
- beginning interactive expansion does **not** start `ShippingMediaRuntime`;
- retained media visuals may move/morph using already-retained presentation only;
- persistent runtime starts only after the panel reaches matching settled `.expanded`;
- if the gesture cancels back to compact, no persistent runtime was started.

### Expanded -> interactive collapse

- the existing expanded runtime remains alive while the panel is interactively collapsing;
- it continues to be the authoritative expanded media source until matching settled `.compact`;
- after settled compact, runtime stops/releases exactly as today;
- compact again owns zero persistent adapter processes.

This asymmetric lifecycle is intentional: it prevents speculative process startup during a cancelled expansion while avoiding media authority loss during an in-progress collapse.

## 9. Seek interaction

Draggable seek remains part of M6.6 after gesture/haptic wiring.

Requirements:

- seek is interactive only when `canSeek == true` and trustworthy position/duration exist;
- beginning seek captures the interaction and suppresses horizontal/vertical notch gestures;
- local preview follows the drag without polling the track;
- commit occurs once at drag completion through a typed `seek(to:)` runtime entry point;
- cancellation returns to authoritative progress;
- command failure returns to authoritative progress;
- seek unavailable/unknown is visually non-draggable and produces no misleading haptic.

## 10. Haptic policy

Use `NSHapticFeedbackManager.defaultPerformer` only through an injectable App-owned haptic seam.

Haptic events:

- horizontal previous/next: one `.levelChange` when entering armed;
- staying horizontally armed: none;
- horizontal commit: none;
- horizontal cancellation: none;
- unsupported media action: none;
- vertical interactive expansion/collapse: no new M6.6 haptic;
- hover expansion keeps its existing accepted haptic policy.

Tests assert semantic haptic requests, not physical vibration.

## 11. Performance policy

Interactive motion is a hot path and must remain lightweight.

Prohibited in per-event handling:

- `Task {}` allocation for every scroll sample;
- subprocess creation except the already-bounded compact capability/command requests at semantic boundaries;
- image decoding;
- source-icon resolution;
- file I/O;
- timers/display links/sleep loops;
- metadata logging;
- network calls.

Per-event work should be limited to scalar state-machine updates, interpolation, and Core/AppKit presentation updates.

If shipping artifact size exceeds the current Task-4 feature envelope, a new provenance-backed feature budget requires its own RED -> GREEN policy cycle. Historical budgets and `performance/baseline-v0.1.0.json` remain immutable.

Target-Mac acceptance must also check qualitative animation smoothness and resource ownership; shared-runner CPU/RSS magnitudes remain compatibility evidence rather than target acceptance.

## 12. Security and privacy policy

This design does not widen the trust boundary.

It explicitly preserves:

- App Sandbox-only entitlement;
- Hardened Runtime;
- fixed `/usr/bin/perl` media boundary with pinned resources;
- no global `.scrollWheel` monitor;
- no `CGEventTap`;
- no Accessibility/Input Monitoring/Automation/Screen Recording authority;
- no synthetic media keys;
- no arbitrary executable/path/argument surface;
- no telemetry/networking/listening-history persistence;
- no direct private-framework loading in the NotchHub process.

`NSWorkspace` source-icon lookup is local public AppKit functionality and receives only the authoritative source bundle identifier already present in normalized media state.

## 13. Testing strategy

### 13.1 Interactive transition deterministic tests

Add Core tests for:

- zero progress equals exact origin endpoint;
- one progress equals exact destination endpoint;
- intermediate interpolation is deterministic;
- progress clamps to `0...1`;
- interactive expansion/collapse begin only from matching stable endpoints;
- cancellation settles to origin;
- committed end settles to destination;
- Reduce Motion settles exactly;
- stale generation cannot restore old interactive geometry;
- retarget/layout change uses current authoritative endpoints;
- no expansion haptic originates from interactive transition plumbing.

### 13.2 App gesture-session tests

Test with injected fakes:

- local event phase/delta conversion;
- horizontal visual offset routing;
- compact capability request generation;
- compact command path uses dispatcher only;
- expanded command path uses runtime only;
- vertical visual progress routes only through panel interactive API;
- horizontal arm effect maps to exactly one haptic call;
- no second haptic on horizontal commit;
- vertical interaction produces no new haptic;
- momentum ignored;
- seek-active suppresses notch gestures;
- invalidation resets visual state and stops compact dispatcher ownership.

### 13.3 Source-icon tests

Test:

- bundle ID propagated independently of display name;
- resolver success returns icon;
- resolver failure returns nil/fallback path;
- cache never exceeds 8 source bundle identifiers;
- repeated same-source rendering does not repeatedly resolve through workspace;
- source switch updates resolved presentation identity;
- visual source text is absent from normal expanded chrome;
- accessibility/help identity remains available.

### 13.4 Source-level policy tests

Keep fail-closed tests that reject:

- global/local event-monitor registration for `.scrollWheel`;
- direct App `NSPanel.setFrame` ownership;
- synthetic media keys;
- direct private-framework loading;
- new sensitive entitlements;
- polling/repeating-timer additions in the gesture path.

## 14. Acceptance ledger extension

The frozen `NH-MEDIA-GESTURE-001...018` IDs remain unchanged. This design adds a separate ledger so already-frozen semantics are not renumbered or rewritten.

Create `docs/testing/INTERACTIVE_NOTCH_ACCEPTANCE.md` with these stable IDs:

| ID | Gate | Required result |
|---|---|---|
| `NH-NOTCH-INTERACTIVE-001` | Compact downward tracking | Physical local downward gesture visibly interpolates from the exact current compact layout without waiting for release. |
| `NH-NOTCH-INTERACTIVE-002` | Compact cancellation | Short/reversed/cancelled downward gesture returns to the exact compact endpoint and never starts persistent media observation. |
| `NH-NOTCH-INTERACTIVE-003` | Compact commit | Qualifying downward gesture settles through transition authority to exact expanded endpoint. |
| `NH-NOTCH-INTERACTIVE-004` | Expanded upward tracking | Physical local upward gesture visibly interpolates from expanded toward compact while expanded runtime remains authoritative until settlement. |
| `NH-NOTCH-INTERACTIVE-005` | Expanded cancel/commit | Cancel returns to exact expanded; qualifying release settles to exact compact and then releases runtime. |
| `NH-NOTCH-INTERACTIVE-006` | Arbitration + stale safety | Horizontal/seek capture cannot move panel; momentum cannot drive interactive progress; stale generations/layout updates cannot restore an obsolete frame. |
| `NH-NOTCH-INTERACTIVE-007` | Hover parity | Existing 120 ms hover expansion remains correct and its accepted haptic does not duplicate because interactive input exists. |
| `NH-NOTCH-INTERACTIVE-008` | Reduce Motion | Interactive gesture may track physical input, but settle obeys Reduce Motion and lands exactly at the authoritative endpoint. |
| `NH-NOTCH-INTERACTIVE-009` | Resource lifecycle | Settled compact owns zero persistent adapter, cancelled compact expansion starts none, settled expanded owns the expected adapter, Quit leaves no orphan. |
| `NH-MEDIA-SOURCE-ICON-001` | Authoritative identity | Expanded source badge derives only from authoritative source bundle identifier, never track metadata heuristics. |
| `NH-MEDIA-SOURCE-ICON-002` | Correct/fallback rendering | Resolvable source shows its application icon; unresolved source shows neutral app glyph without fabricated identity. |
| `NH-MEDIA-SOURCE-ICON-003` | Text removal + accessibility | Persistent visual source text is absent from expanded chrome while source name remains available to accessibility/help semantics. |
| `NH-MEDIA-SOURCE-ICON-004` | Local bounded lookup | Icon lookup uses public `NSWorkspace`, no network/persistence/crawling, and in-memory cache is capped at 8 bundle identifiers. |

## 15. Physical acceptance

The first candidate containing interactive panel motion, gesture haptics, source icon, and seek requires target acceptance on macOS 26.6 / Mac16,8 before merge/release status is claimed.

Minimum physical matrix combines applicable existing `NH-MEDIA-GESTURE-*` gates with all new `NH-NOTCH-INTERACTIVE-*` and `NH-MEDIA-SOURCE-ICON-*` gates. In particular verify:

1. Cold no-media hover expansion/collapse remains correct.
2. Compact swipe-down visually follows fingers and commits at the existing semantic threshold.
3. Short/reversed swipe-down returns smoothly to compact with no persistent adapter startup.
4. Expanded swipe-up follows fingers and commits to compact.
5. Short/reversed swipe-up returns smoothly to expanded.
6. Momentum after finger release does not create a second transition.
7. Horizontal compact next/previous works with one arm haptic and one command.
8. Horizontal expanded next/previous visibly tracks and commits once.
9. Unsupported previous/next cannot arm and produces no haptic.
10. Vertical morph introduces no new haptic beyond existing hover behavior.
11. Source app is represented by the correct application icon for Yandex Music and Yandex Browser/Chromium when resolvable.
12. Source icon fallback is non-misleading when application resolution fails.
13. Seek drags only when capability is supported and commits once.
14. No Accessibility/Input Monitoring/Automation/Screen Recording prompt appears.
15. Settled compact owns zero persistent adapter process.
16. Settled expanded owns the expected persistent adapter.
17. Cancelled compact expansion never starts a persistent adapter.
18. Normal Quit leaves no NotchHub/media child orphan.
19. Motion feels continuous with no obvious frame jump at handoff from interactive progress to endpoint settle animation.

One explicit tuning pass is allowed for visual interactive travel/damping based on target-Mac feel. Any tuned constants must be frozen in tests before acceptance.

## 16. Implementation order

After this written spec is reviewed, implementation proceeds under strict TDD in this order:

1. create/freeze the new interactive/source-icon acceptance ledger;
2. interactive transition model/API in `NotchHubCore`;
3. App-owned `MediaGestureSession` and horizontal haptic routing;
4. interactive horizontal/vertical visual wiring;
5. source bundle identity propagation and `SourceApplicationIconResolver`;
6. source icon UI replacing persistent source text;
7. capability-gated draggable seek;
8. source-level security/performance policy checks and any justified size-budget cycle;
9. exact-head CI;
10. one consolidated target-Mac physical acceptance candidate;
11. documentation sync, merge, post-merge CI, then P1 performance/resource review.

## 17. Reference policy

External notch utilities are used only to identify desirable product qualities and interaction patterns. NotchHub implementation remains independent.

The inspected TheBoringNotch revision resolves application identity/icon through public `NSWorkspace` APIs and overlays an app icon on album artwork. Its repository license is GPL-3.0. NotchHub adopts only the general product idea and implements its own types, bounded cache, layout, tests, lifecycle, and accessibility behavior. No GPL implementation text is copied into NotchHub source.
