# Product references

## NotchNook

Official product page: https://lo.cafe/notchnook

Observed on 2026-08-07:

- official version shown: `v1.6.2`;
- minimum macOS: `14.6`;
- positions the notch as a utility center with widgets/live activities and a temporary file shelf;
- explicitly highlights scroll/swipe interaction;
- supports notchless screens with a handler-style surface;
- states support for multiple monitors.

The repository https://github.com/notchnook-tool/notchnook contains only a small README/history rather than reusable product source code, and some claims there conflict with the official site (for example pricing). Treat it as an informational page only, not as an authoritative implementation or product specification.

## Boring Notch

Official product page: https://theboring.name/

Open-source repository: https://github.com/TheBoredTeam/boring.notch

Reference snapshot reviewed on 2026-08-09: repository `main` at `71e50d8a5edc1010ceffa34f34348157183b76e4`.

Boring Notch is a particularly important reference because it is a mature open-source implementation of substantially the same product category: a native macOS utility that turns the hardware notch / top-screen area into a compact live-activity and productivity surface.

Publicly exposed product features include:

- system/Now Playing media presentation and playback controls;
- calendar and reminders;
- camera mirror;
- battery/charging status;
- file Shelf with AirDrop-oriented sharing;
- replacement volume/brightness/keyboard-backlight HUDs;
- configurable gesture control;
- notch sizing/display customization;
- configurable media-control slots;
- visual artwork effects and player tinting;
- support for non-notch Macs and multiple-display-oriented settings.

The repository is licensed under **GPL-3.0**. NotchHub may study its behavior, architecture, issue history, public UI and engineering tradeoffs, but **must not copy GPL-covered source code into the MIT-licensed NotchHub codebase** unless the project deliberately changes its licensing strategy. Reimplement ideas independently from requirements and observable behavior. Third-party components used by Boring Notch must be reviewed under their own licenses rather than assuming Boring Notch's GPL license applies to the upstream component itself.

### Media architecture findings

Boring Notch independently validates several assumptions already made by NotchHub:

- it explicitly credits `ungive/mediaremote-adapter` for macOS system Now Playing support on modern macOS;
- its current `NowPlayingController` launches the adapter through fixed `/usr/bin/perl` and consumes a real-time JSON stream rather than periodically polling track metadata;
- it also directly resolves functions from the private `MediaRemote.framework` for commands and seek;
- it maintains separate Apple Music / Spotify / YouTube Music controller fallbacks and uses AppleScript for some app-specific features such as volume/favorite operations;
- its main app requests substantially broader entitlements than NotchHub, including Automation/Apple Events, camera, calendar, network client/server, file access and temporary Apple Events exceptions.

NotchHub adopts only the first two high-level lessons: system Now Playing is the correct universal source, and the external adapter transport is a viable event-driven compatibility mechanism. NotchHub **rejects** direct private-framework dynamic loading inside the app process, AppleScript/app-specific fallback controllers, and broad permissions for the Universal Media milestone.

The accepted NotchHub M6.1 transport remains the stronger reference for exact production constraints: pinned adapter revision, fixed executable/arguments, bounded untrusted JSON, authoritative capability states, one controlled restart, no metadata logging/history, Sandbox + Hardened Runtime, and measured target-Mac resource behavior.

### Useful UX/architecture ideas to retain

The following Boring Notch ideas are useful design input, not copy targets:

- media-first expanded layout with artwork, metadata, progress and a compact control toolbar;
- optional/configurable media-control slots rather than permanently filling the surface with every possible action;
- source-application icon as a lightweight fallback/secondary identity when artwork is unavailable;
- modules such as media, calendar and camera should be independently hideable/reorderable rather than forcing one permanently wide composition;
- expanded width should eventually respond to enabled modules rather than assuming every module is visible;
- gestures should be scoped to the application's own window and distinguish physical scroll phase from momentum;
- non-notch mode, multi-display behavior and fullscreen behavior need explicit product policies rather than incidental geometry fallbacks;
- Shelf, battery live activity and system HUD replacement are validated future feature categories worth evaluating after the current roadmap priorities.

NotchHub deliberately keeps dynamic artwork color extraction/blur-heavy theming deferred until P1 performance evidence; visual inspiration is not sufficient reason to add continuous image processing.

### Failure modes learned from the mature reference

Open Boring Notch issue history is useful as a regression-design source. In particular, NotchHub should explicitly defend against:

- stale artwork surviving when a new source/session provides no artwork;
- incorrect fallback when multiple media players are active and the system Now Playing owner changes;
- browser/private-session artwork edge cases;
- media controls or global hooks interfering with native hardware media behavior;
- notch/window migration glitches across displays;
- fullscreen-media visibility policy drifting from the actual active display/session;
- a single fixed expanded layout becoming unnecessarily wide when optional modules are disabled.

These are not assumed defects in NotchHub; they are scenarios to convert into deterministic tests or target-Mac acceptance cases before equivalent functionality ships.

## How NotchHub may use the references

NotchNook and Boring Notch are useful benchmarks for interaction quality, product breadth, visual ergonomics and already-discovered edge cases. We may study public screenshots/demos, documented behavior, open-source architecture and issue history to answer questions such as:

- how much information fits around the notch without obscuring work;
- when hover, click, scroll, and swipe interactions feel natural;
- how modules scale horizontally;
- how a file shelf communicates temporary ownership;
- how multi-monitor and notchless behavior is presented;
- how settings expose module ordering and interaction preferences;
- which mature-product edge cases deserve first-class regression tests;
- which private/system integration mechanisms work in practice and which permissions or coupling costs they introduce.

NotchHub remains an independent implementation. Do not copy proprietary assets, icons, wording, layouts pixel-for-pixel, or GPL-covered Boring Notch source into the MIT NotchHub codebase. Prefer independently specified behavior, public/system APIs where possible, and NotchHub's stricter security/performance boundaries.

## NotchHub product direction

Useful differentiators for the personal build:

- **security/local-first:** no licensing backend, analytics, telemetry, ads, or direct network surface by default;
- **Yandex Music first:** media support is validated against the user's actual player rather than treating Spotify/Apple Music as the primary target;
- **Snippets + Translator:** first-class text productivity modules;
- **developer-oriented modules later:** GitHub/CI, timers, clipboard and system/dev status only when they can be added with a narrow security boundary;
- **testable interaction core:** deterministic pointer/geometry policies and explicit real-hardware acceptance IDs;
- **GitHub Releases:** immutable Personal Releases are ad-hoc signed, Sandbox/Hardened Runtime verified, checksum/provenance backed, and explicitly not notarized; Developer ID/notarized Trusted Release remains an optional future tier.

## UI principles derived from references, not copied from them

1. The compact state should visually merge with the hardware notch and stay quiet.
2. Expansion should be stable: one deliberate expansion, no oscillation, accidental collapse, or pointer chasing.
3. The most important module state should be readable before secondary controls.
4. Gestures should supplement obvious click/hover interaction, not be the only discoverable path.
5. A shelf must make it impossible to confuse “remove from shelf” with “delete source file”.
6. Privacy-sensitive values such as snippets must support a future screen-sharing/privacy mode.
7. Multi-monitor and notchless behavior must be designed, not treated as undefined fallback behavior.
8. Animation must respect Reduced Motion and should never be required to understand state.
9. Missing media metadata/artwork must clear or fall back explicitly; never reuse stale content from a previous source.
10. System Now Playing source ownership remains authoritative; NotchHub does not invent per-player priority rules.
11. Optional modules should eventually compose without forcing permanently oversized expanded geometry.
