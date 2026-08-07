# Roadmap

## M0 — Engineering foundation

Status: in progress
Target release: `v0.1.0`

- Swift 6 package structure
- native macOS app bootstrap
- deterministic notch geometry model
- compact/expanded panel state
- stable pointer activation/retention policy
- automated unit/regression tests
- TDD and commit/documentation policy
- CI build/test/package/integrity pipeline
- ad-hoc `.app` and `.dmg` packaging
- Semantic Versioning and `CHANGELOG.md`
- project architecture/state/testing documentation

Exit criteria:

- protected required check `Build, test and package` is green;
- CI produces and verifies an installable DMG;
- `NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, and `NH-HOVER-003` pass on a real MacBook with hardware notch;
- any acceptance regressions have RED-first automated coverage where deterministic;
- `PROJECT_STATE`, `TESTING`, and `CHANGELOG` match the accepted build;
- only then merge the bootstrap PR and tag `v0.1.0`.

## M1 — Notch Core

- tuned expansion/collapse animation and interaction feel
- click/pin interaction policy
- multiple displays and active-screen migration
- fullscreen/Space behavior
- screen-configuration change handling
- reduced-motion behavior
- expand the real-hardware acceptance matrix for display/Space scenarios

## M2 — Shelf

- accept files via drag and drop
- drag files back into other apps
- preserve source files; removing from Shelf never deletes the source
- stale-reference handling
- optional automatic cleanup

## M3 — Snippets

- local snippet store
- groups and search
- copy to clipboard
- optional direct paste behind explicit Accessibility permission
- privacy mode for screen sharing

## M4 — Calendar

- EventKit integration
- next-event view
- permission states and graceful denial handling
- upcoming-event compact indicator

## M5 — Translator

- Apple Translation framework integration where available
- automatic source-language handling
- copy result and swap languages
- optional clipboard translation

## M6 — Media / Yandex Music

- provider abstraction and fake provider tests
- Yandex Music desktop compatibility probe
- track metadata and artwork
- play/pause, previous, next
- timeline/progress where available
- isolated MediaRemote fallback for personal builds if required
- compatibility tests across macOS updates

## M7 — Product shell

- settings
- global shortcuts
- launch at login
- module ordering and enable/disable controls
- accessibility behavior

## M8 — Release hardening

- Developer ID signing
- Apple notarization
- release notes automation from maintained project history
- stable distribution workflow
