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

## How NotchHub may use the reference

NotchNook is a useful benchmark for interaction quality, product breadth, and visual ergonomics. We may study public screenshots/demos and the official feature list to answer questions such as:

- how much information fits around the notch without obscuring work;
- when hover, click, scroll, and swipe interactions feel natural;
- how modules scale horizontally;
- how a file shelf communicates temporary ownership;
- how multi-monitor and notchless behavior is presented;
- how settings expose module ordering and interaction preferences.

NotchHub remains an independent implementation. Do not copy proprietary code, assets, icons, wording, layouts pixel-for-pixel, or reverse-engineered private implementation details.

## NotchHub product direction

Useful differentiators for the personal build:

- **security/local-first:** no licensing backend, analytics, telemetry, ads, or direct network surface by default;
- **Yandex Music first:** media support is validated against the user's actual player rather than treating Spotify/Apple Music as the primary target;
- **Snippets + Translator:** first-class text productivity modules;
- **developer-oriented modules later:** GitHub/CI, timers, clipboard and system/dev status only when they can be added with a narrow security boundary;
- **testable interaction core:** deterministic pointer/geometry policies and explicit real-hardware acceptance IDs;
- **GitHub Releases:** signed/notarized personal distribution with reproducible release history.

## UI principles derived from references, not copied from them

1. The compact state should visually merge with the hardware notch and stay quiet.
2. Expansion should be stable: one deliberate expansion, no oscillation, accidental collapse, or pointer chasing.
3. The most important module state should be readable before secondary controls.
4. Gestures should supplement obvious click/hover interaction, not be the only discoverable path.
5. A shelf must make it impossible to confuse “remove from shelf” with “delete source file”.
6. Privacy-sensitive values such as snippets must support a future screen-sharing/privacy mode.
7. Multi-monitor and notchless behavior must be designed, not treated as undefined fallback behavior.
8. Animation must respect Reduced Motion and should never be required to understand state.
