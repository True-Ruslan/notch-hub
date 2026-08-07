# Testing

## Goal

Automate every deterministic behavior that can be validated reliably in CI. Manual acceptance is reserved for behavior that depends on physical MacBook notch geometry, real pointer feel, exact macOS permission surfaces, third-party applications, Gatekeeper trust on a downloaded build, or final visual quality.

A green pipeline is necessary but is not treated as proof of physical-device UX. Conversely, manual success does not replace deterministic automated coverage that can reasonably exist.

## Required CI gate

The protected-branch check is `Build, test and package`. It depends on the separate `macOS 26 compatibility` job, so the protected check cannot become successful if the macOS 26 layer fails.

The CI path validates:

1. Swift package structure.
2. project-configured strict Swift formatting.
3. shell and plist syntax.
4. repository security baseline (`scripts/security-audit.sh`).
5. macOS 26 compilation with warnings as errors.
6. macOS 26 full Swift unit-test suite.
7. packaging-runner compilation with warnings as errors.
8. full Swift test suite with coverage instrumentation.
9. release application/DMG packaging.
10. semantic version/build-number stamping.
11. ad-hoc code-signature verification.
12. Hardened Runtime flag verification.
13. effective App Sandbox entitlement verification.
14. linked-library inspection (system libraries only at M0).
15. DMG integrity with `hdiutil verify`.
16. artifact upload.

Do not lower assertions, delete useful tests, weaken security policy, or weaken production behavior merely to make CI green.

## Security test boundary

At M0 the executable security baseline verifies, among other things:

- zero external Swift runtime dependencies;
- no runtime subprocess/shell execution APIs;
- no direct network/WebKit surface;
- no dynamic code loading/private-symbol bridging primitives;
- no global keyboard/button/drag/scroll/modifier monitoring;
- no embedded common credential/private-key formats;
- exactly the expected sandbox entitlement set;
- no dangerous Hardened Runtime exception entitlements;
- no LaunchAgents/LaunchDaemons/privileged-helper surfaces;
- immutable full-SHA GitHub Action references;
- no `pull_request_target` workflows.

Future capabilities that legitimately require a currently forbidden surface must update security policy and tests explicitly in the same reviewed PR.

## Test design

Prefer pure deterministic policies for geometry, parsing, permissions state, module state, transitions, and AppKit/SwiftUI boundary configuration. AppKit/SwiftUI wiring should be thin and delegate decisions to testable code.

Tests should:

- state one behavior in the name;
- assert externally meaningful state/results;
- avoid mocks unless an OS or third-party boundary cannot reasonably be exercised;
- avoid arbitrary sleeps in unit tests;
- include boundary cases for screen geometry and pointer regions;
- reproduce a reported regression before its production fix is written;
- test denied/absent/error states, not only happy paths;
- verify that destructive-looking UI operations do not mutate/delete external data unless explicitly designed to do so;
- prefer deterministic fakes/adapters around OS/third-party boundaries over network/media integration in unit tests.

No arbitrary global coverage percentage is used at this stage. Coverage instrumentation is enabled so untested deterministic logic can be identified as the codebase grows; component-specific thresholds may be introduced after stable module boundaries exist.

## Real-hardware acceptance matrix

Record results in `docs/PROJECT_STATE.md` using these stable IDs.

| ID | Scenario | Expected result | Automation |
| --- | --- | --- | --- |
| `NH-BOOT-001` | Install/open CI-produced DMG | App launches without crashing and panel appears | Packaging automated; launch UX manual |
| `NH-OS26-001` | Run current accepted test build on target macOS 26.6 | App launches, sandboxed runtime remains functional, no unexpected permission prompt/error | macOS 26 CI build/test automated; exact 26.6 hardware/UI manual |
| `NH-NOTCH-001` | Observe compact panel on a MacBook with hardware notch | Panel is centered and compact width matches the physical notch | Exact geometry unit-tested; physical alignment manual |
| `NH-HOVER-001` | Move pointer into compact activation region and hold for at least 3 seconds | Exactly one expansion; no compact/expanded oscillation | Pointer policy unit-tested; actual AppKit event delivery manual |
| `NH-HOVER-002` | Move pointer around inside the expanded panel | Panel remains expanded | Pointer retention unit-tested; event delivery manual |
| `NH-HOVER-003` | Move pointer clearly outside expanded panel/retention margin | Content and actual `NSPanel` frame collapse once to compact geometry and stay compact | Pointer policy + hosting sizing ownership automated; physical animation/window behavior manual |
| `NH-SANDBOX-001` | Run App Sandbox build and exercise normal panel use | No crash, unexpected permission prompt, or loss of required pointer behavior | Entitlement/signing automated; physical runtime manual |
| `NH-GATEKEEPER-001` | Download a stable GitHub Release DMG and open normally | Gatekeeper accepts the Developer ID/notarized build without an unidentified-developer workaround | Release workflow signs/notarizes/staples/assesses; quarantine/download UX manual once per release-pipeline change |
| `NH-SPACE-001` | Switch Spaces / fullscreen app | Panel behavior matches documented policy | Planned M1 |
| `NH-DISPLAY-001` | Connect/move between displays | Panel migrates correctly and uses target display geometry | Planned M1 |

## Acceptance history

### 2026-08-07 — cycle 1, bootstrap build

- `NH-BOOT-001`: PASS enough to run the application.
- `NH-HOVER-001`: FAIL — compact/expanded oscillation.
- RED: `eb4fb4d` produced the expected failing regression.
- GREEN: `eff9bde` replaced raw SwiftUI `onHover` authority with deterministic screen-space pointer policy.

### 2026-08-07 — cycle 2, sandbox/Hardened Runtime build

Target MacBook, macOS 26.6:

- `NH-OS26-001`: PASS.
- `NH-NOTCH-001`: FAIL (minor) — compact panel a few pixels wider than hardware notch.
- `NH-HOVER-001`: PASS.
- `NH-HOVER-002`: PASS.
- `NH-HOVER-003`: FAIL — compact content appeared while the black window shell remained expanded.
- `NH-SANDBOX-001`: prior report was interpreted as PASS by matrix order; the source message duplicated the final label, and that ambiguity is retained in `PROJECT_STATE.md`.

Automated proof:

- RED `c518326`: added `hardwareNotchWidthIsNotInflatedByFallbackMinimum` and `hostingViewDoesNotOwnWindowSizing` before fixes.
- macOS 26 CI failed exactly those two tests: `180` vs expected `176`, and hosting sizing options raw value `7` vs expected empty.
- GREEN `3bb1bbb`: real-notch width uses the detected hardware width and `NSHostingView.sizingOptions = []`.
- CI run #19: **10/10 tests PASS** plus full format/security/signing/Hardened Runtime/App Sandbox/system-library/DMG validation.

### 2026-08-07 — cycle 3, corrected build / M0 final acceptance

Target MacBook, macOS 26.6:

- `NH-NOTCH-001`: **PASS**.
- `NH-HOVER-001`: **PASS**.
- `NH-HOVER-002`: **PASS**.
- `NH-HOVER-003`: **PASS**.

**M0 mandatory physical acceptance: PASS.**

This closes both cycle-2 defects without removing or weakening their regression tests.

## Release validation

PR artifacts are ad-hoc test builds. Stable releases additionally require the gates in `docs/RELEASING.md`: Developer ID signing, Hardened Runtime/App Sandbox verification, Apple notarization, stapling, Gatekeeper assessment, and SHA-256 checksum publication.
