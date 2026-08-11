# M6.5 Media-first UI Design

Status: APPROVED IMPLEMENTATION SLICE
Date: 2026-08-11
Base: `main` at `ec41bfe55a007328df27aba60f51d84f9f658a0e`
Primary target: `Mac16,8` / macOS 26.6

## Purpose

Implement the first real Universal Media presentation on top of the accepted M6.1–M6.4 transport/composition foundation. This slice is UI-only in product scope: it renders normalized system Now Playing state and forwards click controls through the existing typed media command boundary. Gesture/haptic/seek interaction remains a later slice.

The approved `2026-08-09-universal-media-gestures-haptics-design.md` remains authoritative except where the newer physically accepted M6.4 lifecycle is more restrictive.

## M6.4 lifecycle constraint

M6.4 proved that an always-on media adapter creates unnecessary compact/background cost and accepted a stricter invariant:

- cold compact launch owns no `ShippingMediaRuntime` and no adapter process;
- media runtime starts only after the matching panel transition settles `.expanded`;
- media runtime stops/releases after the matching transition settles `.compact`;
- stale/reversed transition completions cannot start media;
- compact steady/stability must keep the adapter absent.

M6.5 does not weaken that accepted invariant merely to obtain live compact Now Playing updates.

Therefore compact media presentation in this slice is explicitly **retained last-authoritative context**, not live background observation. A cold launch stays on ordinary compact content until at least one expanded session has produced an authoritative media snapshot. When the panel later collapses, the last accepted media presentation may remain visible while the adapter is absent. If the media session disappears or the bridge becomes unavailable while expanded, that retained context is cleared before collapse.

This is an intentional intermediate product contract. Live compact observation or compact media gestures may revisit lifecycle only in a separately measured/accepted later slice.

## Dependency direction

`NotchHubCore` must not import `NotchHubMediaCore`.

The App target remains the composition layer:

```text
NotchHubCore                       NotchHubMediaCore
  NotchPanelController               ShippingMediaRuntime
  NotchPanelModel                    ShippingMediaPresentationModel
  generic hosting/content seam       MediaSessionController/transport
             \                         /
              \                       /
                   NotchHubApp
                    MediaNotchRootView
```

`NotchPanelController` receives a narrow content-view factory. Its existing default initializer continues to build the current foundation preview, so Core behavior/tests remain independently usable. `NotchHubApp` injects the media-aware SwiftUI root without giving Core any media transport/domain dependency.

## Presentation model

`NotchHubMediaCore` exposes a presentation-only, immutable `ShippingMediaPresentation` derived from the authoritative `MediaSubsystemState + MediaSessionSnapshot`.

It contains only UI-safe normalized values:

- playback state (`playing` / `paused`);
- optional title, artist and album;
- optional artwork bytes;
- source display label from authoritative source identity;
- previous/next/seek support booleans;
- optional trustworthy position/duration values.

Empty/whitespace-only metadata is treated as absent. No title/artist/album placeholder text is fabricated. Progress exists only when duration is finite and positive and position is finite/non-negative; position is clamped to duration for display safety. There is no timer or periodic progress polling in this slice.

`ShippingMediaPresentationModel` is App-owned and survives individual runtime instances. Runtime change callbacks update it while expanded. Runtime teardown detaches its callback before stopping the controller so a normal collapse does not erase the last authoritative presentation. Unexpected/no-session state while still expanded does clear it.

`MediaSessionController` remains the **sole sequence/freshness authority**. The presentation model intentionally does not compare `MediaSequence` across runtime lifetimes: a later expanded runtime is a new controller/transport lifecycle and may restart its local generation numbering. Stale callbacks from an old runtime are prevented by the accepted controller/bridge handler-generation invalidation and by detaching the runtime presentation callback before teardown. A fresh authoritative snapshot from a later expansion must therefore be allowed to replace retained compact context regardless of its raw sequence value relative to the previous runtime.

## Compact geometry and UI

The accepted ordinary compact state remains the exact physical-notch frame. That invariant is retained for cold launch and any compact state without retained media context.

A hardware constraint discovered before M6.5 production UI implementation changes the retained-media compact geometry: content placed inside the exact physical-notch width would be clipped by the hosting view and physically occluded by the camera housing. M6.5 therefore adds **36 pt symmetric media wings** around the unchanged physical notch only while retained media context exists.

For a hardware notch of width `W`, retained-media compact width is `W + 72 pt`, centered on the same notch center and with the same compact height/top edge. `hardwareNotchWidth` remains the actual detected hardware width. The expanded frame is unchanged.

The geometry remains owned by `NotchPanelTransitionCoordinator`: App/media code may only set a generic compact horizontal-extension input on `NotchPanelController`. It may not call `NSPanel.setFrame` or become a second transition authority. The extension is updated from event-driven presentation-model changes while expanded so the next collapse targets either exact-notch compact (`0 pt` extension) or retained-media compact (`36 pt` per side). The pointer/activation layout uses the same current compact frame, making the visible wings valid hover targets.

With retained media context:

- a 24–28 pt artwork image (or lightweight SF Symbol placeholder) fits in the left 36 pt wing;
- a small playing/paused status symbol fits in the right 36 pt wing;
- the physical notch center remains visually empty/black;
- no persistent title/artist text or transport controls are shown;
- no continuously animated progress is shown;
- compact remains non-activating and does not start the adapter.

## Expanded UI

When an authoritative media presentation exists while expanded, Media is the first content surface.

Show:

- artwork or lightweight placeholder;
- title only when present;
- artist only when present;
- album only when present;
- source label;
- previous/play-pause/next controls;
- previous/next disabled unless their authoritative capability is supported;
- static event-driven progress only when trustworthy position/duration exist;
- no draggable seek control in this slice.

If media disappears while the panel is expanded, replace Media with the ordinary Home/foundation content without requesting panel collapse. The compact extension is simultaneously reset to zero so a later collapse returns to exact-notch ordinary compact.

Buttons send only the existing typed semantic commands. No AppleScript, media-key synthesis, Accessibility, Input Monitoring, player-specific fallback, arbitrary process arguments, or new entitlement is introduced.

## Event-driven/resource policy

M6.5 introduces no repeating `Timer`, timer publisher, `DispatchSourceTimer`, sleep loop, display link, polling loop, global scroll monitor, or metadata persistence/logging.

SwiftUI and compact-geometry updates occur only from panel presentation changes and media controller callbacks. Artwork decoding is view-local and bounded by the already bounded transport payload; invalid artwork falls back to the system placeholder.

## Acceptance IDs

- `NH-MEDIA-UI-001` — cold compact launch with no retained media context keeps exact-notch ordinary compact content and zero adapter process.
- `NH-MEDIA-UI-002` — expanded active session renders Media-first content from authoritative state.
- `NH-MEDIA-UI-003` — playing/paused updates change the status and play/pause symbol without fabricated state.
- `NH-MEDIA-UI-004` — partial/empty metadata omits missing rows; invalid artwork uses the lightweight placeholder.
- `NH-MEDIA-UI-005` — previous/next controls are actionable only when capability is `supported`; unsupported/unknown never fabricate support.
- `NH-MEDIA-UI-006` — progress is shown only for trustworthy position+duration and is event-driven/static in this slice; no periodic progress worker exists.
- `NH-MEDIA-UI-007` — session disappearance/unavailable while expanded switches to Home content, resets future compact geometry to exact-notch and does not collapse the panel.
- `NH-MEDIA-UI-008` — normal expanded->compact settlement stops/releases runtime while retaining the last authoritative context, targets exactly 36 pt visible wings per side and keeps the adapter absent.
- `NH-MEDIA-UI-009` — later expansion rebases retained context from its fresh controller lifecycle; old-runtime callbacks cannot surface after teardown and raw sequence values are never compared across runtime lifetimes.
- `NH-MEDIA-UI-010` — media button commands and media compact geometry remain inside existing typed/transition boundaries; no new sensitive permission, entitlement, networking, arbitrary subprocess, global input or direct panel-frame surface is introduced.
- `NH-MEDIA-UI-011` — target-Mac visual/functional acceptance passes with Yandex Music and Yandex Browser, including visible left/right media wings around the physical notch, metadata/artwork as available, play/pause, capability-driven previous/next, media disappearance -> expanded Home, compact retained context, exact-notch fallback and zero compact adapter.

## Explicitly deferred

- horizontal next/previous swipes;
- swipe down/up expand/collapse;
- gesture haptics;
- draggable seek interaction;
- continuously animated progress;
- live compact Now Playing observation while collapsed;
- Apple Music/Spotify/additional-player compatibility claims;
- P1 tracking-area/global-pointer optimization;
- broader M1 display/Spaces/notchless policy.

## Exit gate

M6.5 may be marked accepted only when deterministic CI is green and `NH-MEDIA-UI-001...011` are recorded. CI can prove mapping, dependency/security/event-driven/geometry policy and package integrity; `NH-MEDIA-UI-011` requires physical target-Mac acceptance. Until that physical gate passes, the PR remains implemented/tested but not accepted/merged/released.
