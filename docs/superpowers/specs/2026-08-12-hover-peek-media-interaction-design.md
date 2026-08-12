# Hover Peek Media Interaction Design

Status: APPROVED PRODUCT DESIGN / WRITTEN SPEC PENDING REVIEW
Date: 2026-08-12
Target: NotchHub Personal Release on macOS 26.6 / Mac16,8
Scope: M6.6 physical-acceptance follow-up for hover ergonomics, media continuity, and seek cursor treatment

## 1. Purpose

The current M6.6 exact candidate proves the core local gesture model on target hardware, but physical acceptance exposed an ergonomics conflict: compact media gestures are reliable only when the pointer stays on the side wings, while entering the physical notch can trigger full hover expansion. Fast pointer movement can therefore expand the full interface when the user only intended to swipe and leave.

NotchHub will replace direct hover-to-expanded behavior with a three-state interaction model:

```text
compact <-> peek <-> expanded
```

`peek` is a lightweight media-only preview attached to the physical notch. Hover reveals media context without opening the full interface. Full expansion requires an intentional click or downward gesture.

This design also closes two physical-acceptance continuity defects: visible interface blinking during expanded track switches and during compact-to-expanded downward gestures. It adds a bounded cursor-visibility policy for timeline seek without pointer locking.

This document supersedes the hover-expands-directly assumptions in `2026-08-12-interactive-notch-media-ux-design.md` and earlier M1 hover behavior where they conflict. Existing accepted gesture directions, semantic thresholds, lifecycle ownership, security boundaries, and M6.6 media-command behavior remain unchanged unless explicitly revised here.

## 2. Product outcome

The intended interaction is:

- `compact`: minimal media surface around the hardware notch, optimized for fast horizontal previous/next gestures;
- `peek`: small one-line media preview shown only when media context exists;
- `expanded`: the existing full NotchHub interface.

The governing product rule is:

> Hover previews. Click or downward gesture explicitly expands.

A quick pointer pass through the hardware notch must therefore never open the full expanded interface by hover alone.

## 3. State semantics

### 3.1 Compact

Compact preserves the current M6.6 media wings and gesture semantics:

- physical LEFT -> next;
- physical RIGHT -> previous;
- physical DOWN -> interactive direct expansion to `expanded`;
- short/reversed horizontal gestures do not commit, haptic, or stick;
- settled compact owns zero persistent media observation.

When no usable media context exists, hovering the notch does nothing. A click on the notch or a qualifying downward gesture may still open the full NotchHub interface.

### 3.2 Peek

Peek exists only when NotchHub has a retained or freshly confirmed media context.

Peek is intentionally smaller than the full expanded surface and contains only:

- small artwork at leading edge;
- one-line title;
- one-line artist treatment within the same compact metadata area, truncating with ellipsis as needed;
- interactive timeline spanning most of the available width;
- lightweight play/pause state indicator;
- no previous/next buttons;
- no dedicated play/pause button;
- no source-application icon;
- no Home content or generic non-media placeholder.

Peek supports:

- physical LEFT/RIGHT media gestures with the same semantics as compact/expanded;
- timeline seek;
- click on free, non-control surface -> `expanded`;
- physical DOWN -> `expanded`.

Timeline interaction never implicitly expands the panel.

### 3.3 Expanded

Expanded preserves the existing full NotchHub interface and media runtime behavior.

- physical UP -> interactive collapse directly to `compact`;
- pointer exit does not collapse expanded state;
- track/source updates occur inside the existing state rather than transiently showing Home.

Expanded does not collapse to Peek on upward gesture. The stable endpoint is compact.

## 4. Transition contract

The stable transitions are:

```text
compact + hover dwell + usable media -> peek
compact + click                    -> expanded
compact + DOWN                     -> expanded

peek + click free surface          -> expanded
peek + DOWN                        -> expanded
peek + pointer exit                -> grace -> compact

expanded + UP                      -> compact
```

There is no required `compact -> peek -> expanded` stop during a downward gesture. A compact downward gesture continues to use the existing interactive compact-to-expanded geometry path.

No hover event may transition directly from compact or peek to expanded.

## 5. Single transition authority

`peek` becomes a real third state in the existing panel transition/state authority. It is not implemented as:

- a second `NSPanel`;
- an independent SwiftUI overlay with separate geometry ownership;
- a parallel hover-only state machine.

`NotchPanelTransitionCoordinator` and `NotchPanelController` remain the only authoritative owners of panel geometry and stable presentation state.

Conceptually the stable states become:

```text
compact
peek
expanded
```

with bounded transition phases between them. The coordinator must continue rejecting stale transition completions by generation.

The existing interactive compact<->expanded path remains authoritative for vertical follow-finger gestures. Peek transitions use bounded endpoint animations and do not create a second interactive geometry model unless a later approved design explicitly requires one.

## 6. Hover activation and collapse

### 6.1 Activation

Hover uses the existing short dwell concept, but its destination changes from full expansion to Peek.

Activation rules:

- media context is required;
- a quick pass through the hover region before dwell completion remains compact;
- beginning an owned swipe/seek cancels pending hover activation;
- hover activation must not steal an already-started compact gesture;
- activation produces no full-interface state transition.

### 6.2 Peek collapse grace

Pointer exit from Peek does not collapse immediately.

The exact grace contract is **140 ms**.

- pointer exits Peek -> schedule one 140 ms collapse opportunity;
- pointer re-enters before 140 ms -> cancel collapse;
- active swipe or seek -> collapse is prohibited until the interaction ends;
- click/down transition to expanded -> pending collapse is cancelled;
- after the grace expires with no conflicting ownership -> animate Peek to compact.

This grace mechanism is bounded and one-shot. It is not a repeating timer or polling loop.

## 7. Input priority

While Peek is visible, input arbitration is ordered:

1. active seek owns input exclusively;
2. horizontal media gesture;
3. vertical downward expansion gesture;
4. click on free surface;
5. hover-exit collapse.

Consequences:

- seek suppresses horizontal/vertical notch gestures;
- horizontal capture prevents downward expansion for that physical gesture;
- hover-exit cannot interrupt an active seek or swipe;
- click on the timeline belongs to seek and must not expand;
- click on free Peek surface expands exactly once.

Momentum remains unable to arm or commit media/panel gestures under the existing M6.6 contract.

## 8. Media freshness and runtime ownership

Peek must feel immediate without introducing compact polling.

### 8.1 Cached-first presentation

When hover dwell completes and an in-memory media presentation exists:

1. show Peek immediately from the last in-memory snapshot;
2. start exactly one bounded freshness acquisition through the existing media boundary;
3. if fresh media confirms the session, update Peek in place;
4. if media is no longer available, collapse Peek to compact without showing Home.

No media state is persisted to disk for Peek.

### 8.2 No persistent compact observation

Settled compact continues to own zero persistent `mediaremote-adapter.pl` observation.

Peek may own only the minimum bounded lifecycle required to refresh and support its active interaction contract. The implementation must not introduce:

- polling;
- repeating timers;
- display-link media observation;
- sleep loops;
- background history collection;
- speculative long-lived observation after returning to compact.

Any persistent runtime required by the existing expanded UI still starts/stops according to authoritative expanded lifecycle settlement.

## 9. Continuity and no-blink contract

The target-Mac retest reported visible blinking during expanded track switching and compact downward expansion. These are acceptance defects, not cosmetic future work.

The implementation must preserve visual continuity across authoritative media updates:

- track change updates content in the current panel state;
- source change updates content in the current panel state unless the media session truly disappears;
- transient model replacement must not render Home between two valid media presentations;
- compact DOWN must not produce a visible intermediate Home frame;
- Peek freshness confirmation must not recreate the entire panel branch;
- transitions may use short bounded opacity/geometry animation, but animation must not mask an avoidable state-machine discontinuity.

A genuine loss of media is allowed to remove media UI according to the state contract; a temporary internal update boundary is not.

## 10. Seek cursor policy

Timeline seek keeps the existing session-identity isolation and adds cursor visibility ownership.

### 10.1 Behavior

- cursor hides only after a valid seek begins;
- the pointer is not warped, repositioned, locked, recentered, or converted to relative mouse mode;
- normal local pointer/drag events continue to drive the timeline preview;
- cursor becomes visible immediately after seek completion or cancellation.

### 10.2 Fail-safe restoration

Every seek teardown path must restore cursor visibility, including:

- normal commit;
- explicit cancel;
- track change;
- source change;
- capability loss;
- Peek collapse;
- transition to expanded where the seek is cancelled;
- application resign/invalidation path;
- media runtime teardown;
- normal application Quit.

Cursor visibility ownership must be centralized so nested begin/end paths cannot leave AppKit cursor hide-count unbalanced.

The design does not request Accessibility, Input Monitoring, Automation, Screen Recording, event taps, synthetic input, or global mouse ownership.

## 11. Haptic policy

Existing approved M6.6 haptics remain unchanged:

- horizontal previous/next: one `.levelChange` when entering armed;
- commit/cancel: no additional haptic;
- unsupported gesture: no haptic;
- vertical expansion/collapse: no new haptic.

Peek does not add hover or seek haptics in this slice. Cursor hiding during seek is visual feedback only.

## 12. Error handling

Fail closed:

- no media at hover time -> remain compact;
- cached media later disproved -> collapse Peek to compact;
- refresh failure without authoritative evidence of session loss -> do not fabricate new media state; preserve only bounded current Peek presentation until normal exit/teardown policy resolves it;
- source identity changes during seek -> cancel seek, restore cursor, do not apply the old target to the new source;
- panel/layout authority invalidation -> cancel active interaction, restore cursor, resolve to the current authoritative stable state;
- stale async completion -> ignored by generation/session identity.

No error path may strand Peek, persistent adapter ownership, or hidden cursor state.

## 13. Performance and security constraints

Per-event gesture/seek work remains limited to scalar state updates and UI presentation changes.

Prohibited in hot paths:

- per-scroll-event `Task {}` allocation;
- subprocess creation on every event;
- image decoding or source-icon lookup on every event;
- file I/O;
- network calls;
- metadata logging;
- repeating timers or display links.

The design preserves:

- App Sandbox-only entitlement;
- Hardened Runtime;
- fixed `/usr/bin/perl` media boundary with pinned resources;
- no global `.scrollWheel` monitor;
- no `CGEventTap`;
- no synthetic media keys;
- no new sensitive permissions;
- no telemetry/network/listening-history persistence.

## 14. Deterministic automated tests

Before production changes, TDD must freeze at minimum:

### State machine

- compact + media hover dwell -> Peek;
- compact + no media hover dwell -> compact;
- compact click -> expanded;
- compact DOWN -> expanded directly;
- Peek free-surface click -> expanded;
- Peek DOWN -> expanded;
- expanded UP -> compact;
- expanded pointer exit -> remains expanded.

### Grace and ownership

- Peek pointer exit does not collapse before 140 ms;
- exactly-at/after 140 ms with no return collapses;
- re-entry before deadline cancels collapse;
- active swipe prevents collapse;
- active seek prevents collapse;
- transition to expanded cancels pending collapse.

### Input arbitration

- seek outranks all Peek notch gestures;
- horizontal capture outranks downward gesture;
- timeline click does not expand;
- free-surface click expands exactly once;
- momentum cannot commit.

### Media lifecycle

- cached snapshot can render immediate Peek;
- one freshness request updates Peek in place;
- media disappearance collapses Peek without Home flash;
- settled compact has zero persistent adapter ownership;
- cancelled compact expansion starts no persistent adapter;
- Peek collapse releases any bounded Peek ownership;
- no polling/repeating media worker is introduced.

### Continuity

- track/source revision updates do not pass through Home while media remains valid;
- compact DOWN does not render Home between compact and expanded media states;
- Peek freshness update preserves stable panel identity/transition authority.

### Cursor

- successful seek begin acquires cursor-hide ownership once;
- commit restores once;
- cancel restores once;
- track/source change restores once;
- panel invalidation/teardown/Quit restores once;
- failed seek begin never hides;
- no pointer warp/lock API is introduced.

### Existing regression contract

Existing automated coverage must remain green for:

- LEFT -> next, RIGHT -> previous;
- short/reversed swipe cancellation;
- horizontal one-arm haptic semantics;
- seek transaction identity isolation;
- lifecycle teardown;
- source icon behavior in expanded;
- security/permission policy;
- release/signing/preflight policy.

## 15. Physical acceptance ledger

Add a separate stable `NH-MEDIA-PEEK-*` ledger rather than renumbering frozen M6.6 IDs.

| ID | Gate | Required result |
|---|---|---|
| `NH-MEDIA-PEEK-001` | Hover destination | With media available, hover dwell opens Peek only; full expanded UI never opens from hover alone. |
| `NH-MEDIA-PEEK-002` | No-media hover | With no media context, hover leaves the panel compact. |
| `NH-MEDIA-PEEK-003` | Fast pointer pass | Rapid pointer passage through the notch does not expand full UI or leave Peek stuck. |
| `NH-MEDIA-PEEK-004` | Grace | Leaving Peek and returning within 140 ms keeps Peek stable; staying outside beyond the grace returns to compact. |
| `NH-MEDIA-PEEK-005` | Explicit expansion | Click on free Peek surface and physical DOWN each open expanded exactly once. |
| `NH-MEDIA-PEEK-006` | Peek horizontal gestures | LEFT -> next and RIGHT -> previous remain reliable without hover stealing the gesture. |
| `NH-MEDIA-PEEK-007` | Peek seek | Timeline seek works without expanding and suppresses notch gestures while active. |
| `NH-MEDIA-PEEK-008` | Seek cursor | Cursor hides for active timeline drag and is visible again after commit/cancel/session change/teardown. |
| `NH-MEDIA-PEEK-009` | Track continuity | Track/source changes update media content without an obvious Home/interface blink while media remains valid. |
| `NH-MEDIA-PEEK-010` | Downward continuity | Compact DOWN follows existing interactive expansion and reaches expanded without visible intermediate Home blink. |
| `NH-MEDIA-PEEK-011` | Expanded collapse | Expanded physical UP returns directly to compact; pointer exit alone does not close expanded. |
| `NH-MEDIA-PEEK-012` | Lifecycle | Settled compact and normal Quit leave no unexpected persistent `mediaremote-adapter.pl` process. |
| `NH-MEDIA-PEEK-013` | Permissions | No Accessibility, Input Monitoring, Automation, or Screen Recording prompts are introduced. |

The previously physically passed M6.6 semantic gates remain valid unless production code affecting them changes. Any modified behavior must be rerun where relevant on the exact candidate.

## 16. Implementation sequencing

After written-spec approval, implementation planning should use small RED -> GREEN slices:

1. freeze three-state panel semantics and hover destination;
2. add Peek geometry/presentation under existing transition authority;
3. add 140 ms grace and input ownership;
4. wire cached-first media freshness without persistent compact observation;
5. preserve swipe/seek behavior inside Peek;
6. add balanced seek cursor-visibility ownership;
7. remove track/downward transition blink at its state-source boundary;
8. update acceptance ledgers, performance size evidence if required, and exact-candidate documentation;
9. require full CI and focused target-Mac physical acceptance before PR #33 can leave draft.

No merge occurs merely because automated tests pass.