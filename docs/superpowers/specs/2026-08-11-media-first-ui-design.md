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

## Compact UI

With no retained media context, preserve the accepted ordinary compact indicator.

With retained media context:

- artwork (or a lightweight SF Symbol placeholder) appears on the left side of the compact surface;
- a small playing/paused status symbol appears on the right;
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

If media disappears while the panel is expanded, replace Media with the ordinary Home/foundation content without requesting panel collapse.

Buttons send only the existing typed semantic commands. No AppleScript, media-key synthesis, Accessibility, Input Monitoring, player-specific fallback, arbitrary process arguments, or new entitlement is introduced.

## Event-driven/resource policy

M6.5 introduces no repeating `Timer`, timer publisher, `DispatchSourceTimer`, sleep loop, display link, polling loop, global scroll monitor, or metadata persistence/logging.

SwiftUI updates occur only from panel presentation changes and media controller callbacks. Artwork decoding is view-local and bounded by the already bounded transport payload; invalid artwork falls back to the system placeholder.

## Acceptance IDs

- `NH-MEDIA-UI-001` — cold compact launch with no retained media context keeps ordinary compact content and zero adapter process.
- `NH-MEDIA-UI-002` — expanded active session renders Media-first content from authoritative state.
- `NH-MEDIA-UI-003` — playing/paused updates change the status and play/pause symbol without fabricated state.
- `NH-MEDIA-UI-004` — partial/empty metadata omits missing rows; invalid artwork uses the lightweight placeholder.
- `NH-MEDIA-UI-005` — previous/next controls are actionable only when capability is `supported`; unsupported/unknown never fabricate support.
- `NH-MEDIA-UI-006` — progress is shown only for trustworthy position+duration and is event-driven/static in this slice; no periodic progress worker exists.
- `NH-MEDIA-UI-007` — session disappearance/unavailable while expanded switches to Home content and does not collapse the panel.
- `NH-MEDIA-UI-008` — normal expanded->compact settlement stops/releases runtime while retaining the last authoritative compact context and keeping the adapter absent.
- `NH-MEDIA-UI-009` — later expansion rebases retained context from fresh authoritative transport events; no stale presentation overrides a newer snapshot.
- `NH-MEDIA-UI-010` — media button commands remain inside the existing typed transport boundary; no new sensitive permission, entitlement, networking, arbitrary subprocess or global input surface.
- `NH-MEDIA-UI-011` — target-Mac visual/functional acceptance passes with Yandex Music and Yandex Browser, including metadata/artwork as available, play/pause, capability-driven previous/next, media disappearance -> expanded Home, compact retained context, and zero compact adapter.

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

M6.5 may be marked accepted only when deterministic CI is green and `NH-MEDIA-UI-001...011` are recorded. CI can prove mapping, dependency/security/event-driven policy and package integrity; `NH-MEDIA-UI-011` requires physical target-Mac acceptance. Until that physical gate passes, the PR remains implemented/tested but not accepted/merged/released.
