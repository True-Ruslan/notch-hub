# Project state

Last updated: 2026-08-07
Current version: `0.1.0` (Personal Release published and accepted)
Primary physical target: macOS `26.6`
Protected branch: `main`
P0 completion PR: #5 `Performance Foundation`
Next milestone after P0 merge: M1 `Notch Core hardening and interaction`

## P0 Performance Foundation

Status: **ACCEPTED EVIDENCE; final exact-head CI/review/merge gate pending**.

Canonical sources: `PERFORMANCE.md`, `performance/baseline-v0.1.0.json`, `docs/TESTING.md`, `docs/ROADMAP.md`.

Accepted runtime baseline against Personal Release `v0.1.0` on macOS 26.6 / `Mac16,8`:
- idle CPU median/max `0.0% / 0.7%`, RSS max `33,808 KiB`, threads max `4`;
- hover CPU median/max `5.95% / 22.3%`, RSS max `38,816 KiB`, threads max `7`;
- stability CPU median/max `0.0% / 6.8%`, RSS max `34,384 KiB`, threads max `7`, RSS drift `-3,712 KiB`.

Accepted immutable `v0.1.0` sizes: executable `220,560 B`, app `223,555 B`, DMG `73,955 B`, source `8e913dcddfdec7d9aa920df8c37afb23b8c40884`, DMG SHA-256 `cf53be6081b1836551fcbbb91b85fed800de4c089451961f3c6a21f6b77768bc`.

Runtime CPU/RSS/thread limits remain target-Mac acceptance gates. Shared CI enforces deterministic policy/security/state plus size budgets with a 15% relative allowance and independent absolute ceilings.

RED CI #91 failed exactly because the size comparison API was absent. GREEN CI #94 passed 22 performance-policy tests, security/build/package gates, deterministic size gate, harness smoke, and artifact upload.

P0 adds no runtime entitlement, telemetry, network, subprocess, private API, privileged helper, or broader input capture.

## Next optimal step
1. Final exact-head CI and independent PR #5 review.
2. Squash-merge PR #5 if clean.
3. Start M1 with measured local AppKit tracking investigation, then delayed hover + public AppKit haptic under `docs/specs/M1_NOTCH_INTERACTION.md`.
