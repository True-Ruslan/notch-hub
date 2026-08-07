# Project state

Last updated: 2026-08-07
Current version: `0.1.0` (Personal Release published and accepted)
Primary physical target: macOS `26.6`
Protected branch: `main`
P0 completion PR: #5 `Performance Foundation`
Next milestone after P0 merge: M1 `Notch Core hardening and interaction`

## P0 Performance Foundation

Status: **ACCEPTED EVIDENCE; final exact-head CI/review/merge gate pending**.

Canonical sources:

- `PERFORMANCE.md` — performance/resource policy and human-readable baseline;
- `performance/baseline-v0.1.0.json` — machine-readable canonical baseline;
- `docs/TESTING.md` — acceptance IDs and RED→GREEN evidence;
- `docs/ROADMAP.md` — milestone state and next work.

Accepted runtime baseline on macOS 26.6 / `Mac16,8` against Personal Release `v0.1.0`:

- idle CPU median/max `0.0% / 0.7%`, RSS max `33,808 KiB`, threads max `4`;
- hover CPU median/max `5.95% / 22.3%`, RSS max `38,816 KiB`, threads max `7`;
- stability CPU median/max `0.0% / 6.8%`, RSS max `34,384 KiB`, threads max `7`;
- stability RSS `34,256 -> 30,544 KiB` (`-3,712 KiB`), no sustained memory growth observed.

Accepted immutable `v0.1.0` release sizes:

- executable `220,560 B`;
- app aggregate `223,555 B`;
- DMG `73,955 B`;
- source `8e913dcddfdec7d9aa920df8c37afb23b8c40884`;
- DMG SHA-256 `cf53be6081b1836551fcbbb91b85fed800de4c089451961f3c6a21f6b77768bc`.

Runtime CPU/RSS/thread thresholds remain target-Mac acceptance gates. Shared CI enforces deterministic source/state/security rules plus artifact sizes: 15% relative allowance and independent absolute ceilings.

RED CI #91 failed exactly on the absent size-comparison API. GREEN CI #94 passed 22 performance-policy tests, all security/build/package gates, the deterministic size gate, harness smoke, and artifact upload. CI #94 candidate sizes (`214,016 / 217,012 / 73,378 B`) were inside budget.

P0 introduces no runtime entitlement, telemetry, network, subprocess, private-API, privileged-helper, or broader input-capture surface.

## Next optimal step

1. Final exact-head CI and independent read-only PR #5 review.
2. Squash-merge PR #5 only if both are green.
3. Start M1: measured local AppKit tracking investigation, then delayed hover + public AppKit haptic under `docs/specs/M1_NOTCH_INTERACTION.md`.
