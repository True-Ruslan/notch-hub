# Project state

P0 Performance Foundation evidence is complete in PR #5. Final exact-head CI and independent review are the only remaining merge gates.

Canonical evidence: `PERFORMANCE.md`, `performance/baseline-v0.1.0.json`, `docs/TESTING.md`, and `docs/ROADMAP.md`.

Accepted target baseline: Personal Release `v0.1.0`, macOS 26.6 / `Mac16,8`. Idle CPU median/max `0.0% / 0.7%`; hover `5.95% / 22.3%`; stability `0.0% / 6.8%`. The 10-minute stability run showed no sustained RSS growth.

Accepted immutable release sizes: executable `220,560 B`, app `223,555 B`, DMG `73,955 B`. Shared CI enforces deterministic size budgets; CPU/RSS/thread limits remain target-Mac acceptance gates.

GREEN CI #94 passed 22 performance-policy tests, all security/build/package checks, canonical size budget enforcement, harness smoke, and artifact upload. P0 adds no runtime entitlement, telemetry, network, subprocess, private API, privileged helper, or broader input capture.

Next after P0 merge: M1 local AppKit tracking investigation, delayed hover, and public AppKit haptic under `docs/specs/M1_NOTCH_INTERACTION.md`.
