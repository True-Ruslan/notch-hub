# Roadmap

## M0 — Engineering foundation

Status: in progress
Target release: `v0.1.0`
Primary real-hardware target: macOS `26.6`

- Swift 6 package structure
- native macOS app bootstrap
- deterministic notch geometry model
- compact/expanded panel state
- stable pointer activation/retention policy
- automated unit/regression tests
- TDD and commit/documentation policy
- strict formatting + warnings-as-errors gates
- macOS 26 compatibility CI
- executable security baseline and root `SECURITY.md`
- App Sandbox by default with minimal entitlements
- Hardened Runtime with no dangerous exceptions
- zero third-party runtime dependencies at M0
- immutable full-SHA GitHub Action references
- CI build/test/package/signature/entitlement/dylib/DMG-integrity pipeline
- ad-hoc `.app` and `.dmg` packaging for PR testing
- Semantic Versioning and `CHANGELOG.md`
- Developer ID + Apple notarization GitHub Release workflow
- project architecture/state/testing/releasing/product-reference documentation

Exit criteria:

- protected required check `Build, test and package` is green and therefore its required macOS 26 compatibility dependency is green;
- CI produces and verifies an installable sandboxed/Hardened Runtime DMG;
- `NH-OS26-001`, `NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, `NH-HOVER-003`, and `NH-SANDBOX-001` pass on the target MacBook/macOS 26.6;
- any acceptance regression has RED-first automated coverage wherever deterministic;
- `PROJECT_STATE`, `TESTING`, `SECURITY`, and `CHANGELOG` match the accepted build;
- Apple Developer release credentials are configured directly in the GitHub `release` environment;
- only then merge the bootstrap PR and publish signed/notarized `v0.1.0` through GitHub Releases;
- `NH-GATEKEEPER-001` validates the first stable release downloaded through the normal user path.

## M1 — Notch Core

- tuned expansion/collapse animation and interaction feel
- click/pin interaction policy
- gesture model (hover/click/scroll/swipe) designed independently while benchmarking public NotchNook behavior
- multiple displays and active-screen migration
- fullscreen/Space behavior
- screen-configuration change handling
- notchless-screen handler mode decision/prototype
- reduced-motion behavior
- expand the real-hardware acceptance matrix for display/Space/gesture scenarios
- automate AppKit interaction seams further where stable event injection/testing is trustworthy

## M2 — Shelf

- accept files via drag and drop
- drag files back into other apps
- use App Sandbox user-selected/security-scoped access rather than broad filesystem permissions
- preserve source files; removing from Shelf never deletes the source
- stale-reference handling
- optional automatic cleanup
- deterministic tests for ownership, source preservation, malformed/stale references, and cleanup policy

## M3 — Snippets

- local snippet store inside sandbox container
- groups and search
- copy to clipboard
- optional direct paste only after a dedicated Accessibility/security decision; copy-only remains the safe fallback
- privacy mode for screen sharing
- tests for persistence, search, escaping, sensitive-value masking, and denied permission paths

## M4 — Calendar

- EventKit integration
- next-event view
- permission states and graceful denial handling
- upcoming-event compact indicator
- deterministic adapter tests plus minimal real permission acceptance

## M5 — Translator

- Apple Translation framework integration where available
- automatic source-language handling
- copy result and swap languages
- optional clipboard translation
- keep direct app network access disabled; any future network-backed translation requires explicit security review

## M6 — Media / Yandex Music

- provider abstraction and deterministic fake-provider tests
- Yandex Music desktop compatibility probe on macOS 26.6
- track metadata and artwork
- play/pause, previous, next
- timeline/progress where available
- prefer sandbox-compatible/public integration paths
- isolated MediaRemote/private-API fallback only if required, with explicit security review and without disabling Hardened Runtime/library validation
- compatibility tests across macOS updates

## M7 — Product shell

- settings
- global shortcuts only with narrowly scoped permissions and no general keyboard logging
- launch at login using supported macOS APIs rather than LaunchAgents/daemon persistence
- module ordering and enable/disable controls
- accessibility behavior
- privacy/security settings and permission explanations

## M8 — Release hardening and maintenance

- validate Developer ID/notarization pipeline on recurring releases
- reproducible release metadata and checksums
- authenticated update-channel design decision (do not add self-update before signature/provenance verification exists)
- periodic dependency/action/toolchain security review
- focused security review before expanding runtime permissions or network surface
