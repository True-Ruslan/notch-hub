# Universal Media, Gestures, and Haptics Design

Status: APPROVED IN DESIGN REVIEW
Date: 2026-08-09
Target: NotchHub Personal Release on macOS 26.6

## 1. Purpose

NotchHub must provide system-wide media controls comparable to modern notch utilities without becoming tied to one player. The media layer must follow the macOS system Now Playing source instead of implementing per-application integrations for Yandex Music, Apple Music, Spotify, browsers, and other players.

The supported universe for this milestone is explicit:

> If macOS itself exposes an application as the active system Now Playing session, NotchHub should be able to observe and control that session subject to the capabilities the source actually exposes.

Applications that do not publish a system media session are outside the first milestone. We do not add application-specific adapters merely to manufacture unsupported capabilities.

The design preserves the existing NotchHub priorities: local-first behavior, minimal permissions, App Sandbox + Hardened Runtime, event-driven execution, low idle resource use, deterministic state machines, evidence-based hardware acceptance, and no silent weakening of security or performance guarantees.

## 2. Product behavior

### 2.1 Compact media state

When an active system media session exists, compact NotchHub becomes a minimal Now Playing surface around the physical notch:

- artwork on the left;
- a lightweight playback/status indicator on the right;
- no persistent title, artist text, or full transport controls;
- paused playback preserves media context but uses a quieter visual state;
- when no media session exists, compact NotchHub returns to the normal non-media presentation.

Horizontal media swipes are available directly from compact mode without opening the panel.

### 2.2 Expanded media-first state

When NotchHub expands while an active media session exists, the initial expanded page is Media rather than the ordinary Home page.

The expanded Media page may show:

- large artwork;
- title;
- artist;
- album when present;
- previous, play/pause, and next controls when supported;
- elapsed time and duration when trustworthy;
- progress indicator when timing data is available;
- draggable seek control only when the active source advertises seek capability;
- a secondary indication of the source application.

Media is prioritized only while a system media session exists. Other NotchHub modules remain available. If the media session disappears while NotchHub is already expanded, the panel stays expanded and replaces Media content with the ordinary Home content; disappearance of media must not force a panel collapse.

### 2.3 Multiple media applications

NotchHub does not invent its own source-priority rules in the first milestone. It follows whichever media session macOS currently treats as system Now Playing. If macOS changes the active source, NotchHub follows that change.

A user-facing source selector is explicitly deferred.

## 3. Scope decomposition

The media milestone is intentionally split into five acceptance slices:

1. Universal Media Bridge.
2. Media UI.
3. Gesture + Haptic Engine.
4. Target-Mac hardware acceptance.
5. P1 whole-app performance review and any evidence-driven optimization.

The first implementation work must prove the transport and lifecycle contract before building a visually complete media player.

## 4. Universal Media architecture

### 4.1 Component boundaries

The design uses the following boundaries:

#### `SystemMediaBridge`

The only component allowed to contain the private MediaRemote compatibility mechanism. Its responsibilities are limited to communication with the macOS system media session:

- observe current Now Playing state;
- receive metadata and playback updates;
- receive source capabilities;
- send a fixed allowlist of media commands;
- report bridge lifecycle and command outcomes.

No UI, gesture logic, product state, persistence, or per-player policy belongs here.

#### `MediaProvider`

A private NotchHub protocol that completely hides the bridge implementation from the rest of the application. Production code outside the bridge boundary depends only on this protocol.

A deterministic `FakeMediaProvider` is required for tests.

#### `MediaSessionSnapshot`

An immutable normalized representation of the active system media session. It includes only validated values needed by NotchHub, such as:

- session/source generation;
- source application identity suitable for display;
- title;
- artist;
- album;
- artwork payload or decoded representation;
- playback state;
- duration;
- current position reference;
- reference timestamp;
- playback rate when meaningful;
- supported command capabilities.

Missing values remain absent rather than being replaced with fabricated data.

#### `MediaSessionController`

The MainActor owner of the normalized media state. It:

- owns the current `MediaSessionSnapshot`;
- normalizes and deduplicates provider events;
- rejects stale generations and out-of-order state;
- manages provider lifecycle;
- maps product intents to provider commands;
- handles command failure without corrupting presentation state;
- exposes media availability to the rest of NotchHub.

#### `MediaGestureCoordinator`

A deterministic state machine for user gestures. It never knows which player is active and never talks to MediaRemote directly. It emits semantic intents such as `next`, `previous`, `expand`, `collapse`, and `seek`.

#### Media presentation layer

SwiftUI/AppKit views render normalized media state and issue semantic intents. They do not contain per-player logic or private API integration.

### 4.2 Data flow

Observation flow:

`macOS system Now Playing -> SystemMediaBridge -> MediaProvider -> MediaSessionController -> Media UI`

Command flow:

`click/swipe/seek -> semantic intent -> MediaSessionController -> MediaProvider -> SystemMediaBridge -> system media session`

### 4.3 Universal capability contract

The UI is capability-driven.

- If seek is unavailable, progress may remain visible as an indicator but is not draggable.
- If previous or next is unavailable, the matching button and swipe action are non-actionable.
- If artwork is unavailable, use a lightweight system-appropriate placeholder.
- If duration or position is unknown, do not display fabricated progress.
- Unsupported actions are never emulated through synthetic keys, Accessibility, Input Monitoring, or other broad automation mechanisms.
- Capability changes during a session are applied immediately and safely.

## 5. MediaRemote compatibility boundary

### 5.1 Explicit exception

NotchHub normally prohibits private APIs. For this milestone, one narrow exception is approved: a private MediaRemote-based implementation may exist only behind `SystemMediaBridge` because public macOS APIs do not currently provide a general third-party observer/controller for the system-wide Now Playing session.

This exception does not relax the rule anywhere else in the application.

### 5.2 Probe before acceptance

A MediaRemote mechanism is not accepted merely because it works on a developer machine. The first engineering task is a compatibility/security probe on the target macOS 26.6 Personal Release configuration.

The probe must establish:

- compatibility with App Sandbox + Hardened Runtime or document the exact boundary required;
- no Accessibility permission;
- no Input Monitoring permission;
- no synthetic input;
- real-time/event-driven Now Playing updates rather than periodic track polling;
- metadata and artwork availability;
- play/pause, previous, next, and seek when the source advertises those capabilities;
- clean bridge teardown;
- no orphan helper process;
- bounded restart behavior after failure;
- acceptable resource behavior for the bridge itself;
- no requirement to broadly weaken NotchHub's existing security foundation.

If a compatible bridge requires security weakening that is disproportionate to media functionality, the transport is rejected and redesigned rather than forcing acceptance.

### 5.3 Fail-closed behavior

The core NotchHub application must remain useful if the media bridge is unavailable or breaks after a macOS update.

Bridge lifecycle is modeled explicitly, for example:

`starting -> ready -> unavailable | failed -> stopped`

A bridge failure invalidates media state only. It must not crash, freeze, collapse, or otherwise destabilize the Notch Core.

The first milestone permits at most one controlled automatic restart after an unexpected bridge failure. If the restarted bridge fails again, the media subsystem stays unavailable until the next NotchHub launch. No unbounded restart loop is allowed.

### 5.4 Trust boundary

The bridge is treated as a narrow, untrusted compatibility boundary with respect to the core application.

It must not receive access to unrelated NotchHub data or features. In particular:

- no network access is added for the bridge as part of this feature;
- no user file access is added;
- no clipboard access is added;
- no Contacts or Calendar access is added;
- no arbitrary command execution interface is exposed;
- the command channel accepts only a fixed typed media-command allowlist;
- media metadata is treated as untrusted input;
- listening history is not persisted;
- track metadata is not emitted into normal production logs.

Messages crossing the boundary must validate lengths, numeric ranges, enum values, generation identity, and ordering. Malformed or oversized messages are rejected.

Artwork must be decoded defensively and with bounded resource use. It is data only and never executable content.

## 6. Media subsystem state model

The normalized top-level state is intentionally small:

- `unavailable`: media transport is not usable;
- `idle`: transport is healthy but no active system media session exists;
- `paused`: an active session exists and is not currently playing;
- `playing`: an active session exists and is playing.

The UI is a projection of this state plus snapshot capabilities. There are no separate Spotify, Yandex Music, Apple Music, or browser presentation states.

## 7. Gesture model

### 7.1 Gesture surface

Media gestures are recognized only over NotchHub's own window/interactive surface. There is no global `.scrollWheel` monitor.

The initial gesture contract is:

- compact + horizontal swipe left: prepare/commit next track;
- compact + horizontal swipe right: prepare/commit previous track;
- expanded Media + horizontal swipe left/right: same next/previous behavior with stronger visual card tracking;
- compact + swipe down: expand NotchHub;
- expanded + swipe up: collapse NotchHub;
- drag on an actionable progress control: seek;
- click/tap play/pause: toggle playback.

Gesture-based volume control is explicitly out of scope for the first media milestone.

### 7.2 Horizontal gesture state machine

Horizontal media gestures use an explicit cancellation-safe state machine:

`idle -> tracking -> armed -> committed | cancelled`

Rules:

- only physical gesture movement (`NSEvent.phase`) may arm a media command;
- momentum after finger release may never arm or create a command;
- horizontal recognition requires clear X-axis dominance over Y-axis movement;
- once direction is captured horizontally, the same gesture may not simultaneously expand or collapse the panel;
- no media command is sent during `.changed`;
- the command is sent only on physical gesture end while still armed;
- `.cancelled` always cancels;
- a short or reverted gesture has no side effect.

### 7.3 Initial threshold and hysteresis

The initial engineering threshold is:

`clamp(28% of the interactive width, 70 pt ... 120 pt)`

The initial hysteresis for disarming after crossing the threshold is `20 pt`.

These are engineering defaults, not immutable product constants. Target-Mac hardware acceptance may tune them once based on real trackpad behavior. Accepted values are then frozen into regression tests.

### 7.4 Commit-on-release

Reaching the threshold means `armed`, not immediate execution.

While armed:

- the user receives one haptic confirmation;
- the current card/compact indicator reflects the drag direction;
- returning sufficiently below the threshold disarms the gesture;
- releasing while armed commits exactly one next/previous command;
- releasing while unarmed cancels.

If the gesture is disarmed and deliberately crosses the threshold again, another armed transition and haptic are permitted. Hysteresis prevents threshold chatter.

The media UI does not permanently invent the next track after a command. It waits for the media provider/system state to confirm the actual resulting session. If the command fails or the source does not change, presentation returns to the latest authoritative snapshot.

### 7.5 Seek gesture isolation

Seek is its own interaction session. While the pointer is dragging an actionable progress control:

- horizontal track switching is not recognized;
- local preview position may follow the drag;
- the actual seek command is committed at drag completion;
- cancellation restores the authoritative position;
- command failure also returns the UI to the provider-reported position.

## 8. Haptic contract

Haptics use the public AppKit haptic performer and are driven by semantic gesture transitions rather than raw scroll events.

For horizontal media swipes:

- entering `armed` requests one `.levelChange` feedback;
- staying armed requests no additional feedback;
- cancellation requests no extra feedback;
- commit requests no second feedback because the armed haptic already conveyed the actionable threshold;
- an unsupported command cannot arm and therefore cannot produce a misleading haptic.

Reduced Motion affects visual motion policy but does not suppress valid tactile feedback by itself. System/user haptic availability remains authoritative.

The design explicitly rejects haptic calls on every `.changed` event.

## 9. UI motion and visual policy

### 9.1 Compact

Compact media feedback is deliberately restrained. Horizontal gestures may move or bias the artwork/status treatment enough to communicate direction, but must not turn compact mode into a full card carousel.

### 9.2 Expanded

In expanded Media, the artwork/card follows the physical horizontal gesture more visibly.

- cancel: presentation returns to the current card;
- commit: the current card may complete its directional exit while the next authoritative snapshot arrives;
- stale asynchronous updates may not visually restore an older track after a newer session generation has arrived.

### 9.3 Artwork policy

The first milestone does not perform continuous dominant-color extraction or build a heavy dynamic theme from artwork. Artwork is displayed with the existing NotchHub visual language and system materials/black surfaces.

Dynamic artwork-driven theming may be reconsidered only after P1 performance evidence.

### 9.4 Existing transition authority remains authoritative

Media presentation must not introduce another owner of panel frame, compact/expanded geometry, or transition lifecycle. The existing Notch panel transition architecture remains the single authority for panel geometry and expansion/collapse.

Media content transitions operate within that authority.

## 10. Timeline and progress without periodic polling

The media subsystem must not poll current track/progress every few hundred milliseconds or every second merely to keep the UI alive.

An authoritative timing snapshot should contain a position reference, reference timestamp, and playback rate when available. Expanded Media may derive a display position from that reference while visible and playing. New system events rebase the reference.

Compact mode does not require a continuously animated timeline.

Any mechanism chosen to animate visible progress must stop doing work when the relevant UI is not visible and must be measured during P1.

## 11. Testing strategy

### 11.1 Deterministic controller tests

Using `FakeMediaProvider`, test at minimum:

- no session -> new session;
- playing <-> paused;
- source switch;
- session disappearance;
- partial metadata;
- missing artwork;
- capability changes;
- unsupported commands;
- command failure;
- stale generation rejection;
- out-of-order update rejection;
- duplicate update deduplication;
- bridge unavailable state;
- one allowed restart followed by fail-closed behavior after repeated failure;
- media failure does not corrupt Notch Core state.

### 11.2 Gesture state-machine tests

Test at minimum:

- short horizontal swipe cancels;
- threshold crossing arms once;
- no command occurs during `.changed`;
- armed + `.ended` commits exactly once;
- `.cancelled` never commits;
- return below hysteresis disarms;
- deliberate re-arm is possible;
- haptic occurs exactly once per armed transition;
- momentum cannot arm or commit;
- diagonal motion does not accidentally trigger media switching;
- horizontal capture prevents simultaneous vertical transition;
- unsupported next/previous cannot arm;
- compact and expanded semantics match;
- seek captures the progress interaction independently.

### 11.3 Media UI state tests

Test observable states rather than implementation details:

- ordinary compact -> media compact;
- playing -> paused compact;
- active session + expansion -> expanded Media-first;
- media disappears while expanded -> expanded Home, not collapse;
- capability-driven buttons and seek behavior;
- partial metadata does not create empty/fake UI rows;
- unavailable bridge does not damage ordinary NotchHub UI.

### 11.4 Bridge contract/security tests

Test at minimum:

- malformed message rejection;
- oversized metadata rejection;
- invalid numeric range rejection;
- unknown enum/command rejection;
- stale generation rejection;
- lifecycle termination;
- no restart storm;
- no persistence of track metadata/history;
- no production logging of sensitive media metadata;
- helper/package teardown behavior where automation can prove it;
- no unapproved entitlement or permission expansion.

## 12. Target-Mac compatibility and hardware acceptance

The transport and UX must be tested on the primary target Mac/macOS 26.6 with multiple independent system Now Playing sources.

The minimum source matrix is:

- Yandex Music;
- Apple Music;
- Spotify;
- Safari or a Chromium-based browser with YouTube media playback;
- one additional independent media player that publishes system Now Playing.

For each source, verify whatever capabilities macOS actually exposes:

- source detection;
- title/artist/album as available;
- artwork as available;
- playing/paused;
- play/pause;
- previous/next when supported;
- seek when supported;
- source close/disappearance.

Capability absence is not a failure. Claiming or emulating a capability that the source did not expose is a failure.

Cross-source hardware scenarios must include:

- macOS switching the active Now Playing source;
- compact next/previous swipe;
- compact swipe cancellation;
- expanded interactive next/previous swipe;
- haptic on arming;
- vertical expand/collapse without horizontal conflict;
- seek drag where supported;
- source disappearance while expanded;
- bridge failure while NotchHub remains operational;
- quitting NotchHub and verifying bridge/helper teardown.

## 13. Performance acceptance: P1

Performance optimization is performed after the complete functional media slice is accepted, while performance invariants are still respected throughout implementation.

P1 compares the whole application against the accepted P0 target-Mac baseline rather than measuring only the media module in isolation.

Minimum scenarios:

- no active media session, NotchHub idle;
- media playing while NotchHub is compact;
- expanded Media visible without interaction;
- active horizontal swipe interaction;
- active seek interaction;
- repeated track/artwork changes;
- at least 10 minutes of compact playback;
- bridge crash and bounded restart;
- media source closes and application returns to steady idle.

Collect, where reliable:

- CPU median/max;
- RSS median/max and stability;
- thread count and stability;
- wakeups/background activity;
- executable/app/DMG sizes;
- steady-state recovery after media interaction ends;
- helper lifecycle/resource persistence.

Do not pre-authorize an arbitrary percentage increase in runtime cost. Persistent idle regression requires investigation even when numerically small. Active UI may consume more resources while being used, but that cost must subside after interaction ends.

The previously deferred `NSTrackingArea` / window-local pointer-observation experiment is evaluated during this P1 review so its real value can be compared in the application after media integration rather than optimized speculatively in isolation.

P1 has only three valid outcomes:

- `ACCEPT`: behavior and resource cost are acceptable;
- `OPTIMIZE`: a measurable regression has an actionable optimization path;
- `REJECT/REDESIGN`: transport or UI cost violates the product's security/performance foundation.

## 14. Explicit non-goals for the first media milestone

The following are out of scope unless new evidence forces reconsideration:

- application-specific Yandex Music/Spotify/Apple Music adapters;
- user-selectable media source priority;
- global scroll-wheel capture;
- Accessibility or Input Monitoring permissions;
- synthetic media-key generation;
- gesture-based volume control;
- persistent listening history;
- analytics/telemetry;
- continuous dominant-color artwork analysis;
- frequent polling of media state;
- weakening the existing sandbox/security baseline merely to keep private MediaRemote compatibility alive.

## 15. Acceptance order

Implementation must follow this order:

1. compatibility/security probe for the system-wide bridge;
2. production `MediaProvider` boundary and normalized state model;
3. deterministic controller tests and event-driven media state;
4. compact/expanded Media presentation;
5. gesture + haptic state machine and seek interaction;
6. target-Mac multi-source hardware acceptance;
7. P1 whole-app performance review;
8. evidence-driven optimization if required;
9. accept the media milestone only after all applicable gates pass.

This order prevents building a polished media UI on top of an unproven transport and prevents speculative performance work before the actual product slice exists.