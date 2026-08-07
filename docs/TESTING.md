# Testing

## Goal

Automate every deterministic behavior that can be validated reliably in CI. Manual acceptance is reserved for behavior that depends on physical MacBook notch geometry, real pointer feel, exact macOS permission surfaces, third-party applications, Gatekeeper trust on a real downloaded build, or final visual quality.

A green pipeline is necessary but is not treated as proof of physical-device UX. Conversely, manual success does not replace deterministic automated coverage that can reasonably exist.

## Required CI gate

The protected-branch check is `Build, test and package`. It is intentionally dependent on the separate `macOS 26 compatibility` job, so the protected check cannot become successful when the macOS 26 build/test layer fails.

The CI path validates:

1. Swift package structure.
2. project-configured strict Swift formatting.
3. shell and plist syntax.
4. repository security baseline (`scripts/security-audit.sh`).
5. macOS 26 compilation with warnings as errors.
6. macOS 26 full Swift unit-test suite.
7. packaging-runner debug compilation with warnings as errors.
8. full Swift test suite with coverage instrumentation.
9. release application/DMG packaging.
10. semantic version/build-number stamping.
11. ad-hoc code-signature verification.
12. Hardened Runtime flag verification.
13. effective App Sandbox entitlement verification.
14. linked-library inspection (only system libraries allowed at M0).
15. DMG integrity with `hdiutil verify`.
16. artifact upload.

Do not lower assertions, delete useful tests, weaken security policy, or weaken production behavior merely to make CI green.

## Security test boundary

The repository security baseline is executable and fails closed when an unreviewed high-risk capability is introduced. At M0 it verifies, among other things:

- zero external Swift runtime dependencies;
- no runtime subprocess/shell execution APIs;
- no direct network/WebKit surface;
- no dynamic code loading/private-symbol bridging primitives;
- no global keyboard event monitoring;
- no embedded common credential/private-key formats;
- exactly the expected sandbox entitlement set;
- no dangerous Hardened Runtime exception entitlements;
- no LaunchAgents/LaunchDaemons/privileged-helper surfaces;
- immutable full-SHA GitHub Action references;
- no `pull_request_target` workflows.

These checks are intentionally conservative. When a future feature legitimately needs a currently forbidden capability, change the security policy and audit rule explicitly in the same reviewed PR rather than bypassing the check.

## Test design

Prefer pure deterministic policies for geometry, parsing, permissions state, module state, transitions, and AppKit/SwiftUI boundary configuration. AppKit/SwiftUI wiring should be thin and delegate decisions to testable code.

Tests should:

- state one behavior in the name;
- assert externally meaningful state/results;
- avoid mocks unless an OS or third-party boundary cannot reasonably be exercised;
- avoid arbitrary sleeps in unit tests;
- include boundary cases for screen geometry and pointer regions;
- reproduce a reported regression before its production fix is written;
- test failures and denied/absent permission states, not only happy paths;
- verify that destructive-looking UI operations do not mutate/delete external data unless explicitly designed to do so;
- prefer deterministic fakes/adapters around OS/third-party boundaries over network/media integration in unit tests.

No arbitrary global coverage percentage is used at this stage. A high number can reward meaningless tests. Coverage instrumentation is enabled so untested deterministic logic can be identified as the codebase grows; component-specific thresholds may be introduced after stable module boundaries exist.

## Real-hardware acceptance matrix

Record results in `docs/PROJECT_STATE.md` using these stable IDs.

| ID | Scenario | Expected result | Automation |
| --- | --- | --- | --- |
| `NH-BOOT-001` | Install/open CI-produced DMG | App launches without crashing and panel appears | Packaging automated; launch UX manual |
| `NH-OS26-001` | Run current accepted test build on target macOS 26.6 | App launches, sandboxed runtime remains functional, no unexpected permission prompt/error | macOS 26 CI build/test automated; exact 26.6 hardware/UI manual |
| `NH-NOTCH-001` | Observe compact panel on a MacBook with hardware notch | Panel is centered and its compact width matches the physical notch rather than a fallback width | Exact detected geometry unit-tested; physical alignment manual |
| `NH-HOVER-001` | Move pointer into compact activation region and hold it for at least 3 seconds | Exactly one expansion; no compact/expanded oscillation | Pointer policy unit-tested; actual AppKit events manual |
| `NH-HOVER-002` | Move pointer around inside the expanded panel, including outside the original compact width | Panel remains expanded | Pointer retention unit-tested; event delivery manual |
| `NH-HOVER-003` | Move pointer clearly outside expanded panel/retention margin | Panel content and actual `NSPanel` frame both collapse once to compact geometry and stay compact | Pointer policy + hosting sizing ownership automated; physical AppKit/window animation manual |
| `NH-SANDBOX-001` | Run the App Sandbox build and exercise hover/normal panel use | No crash; no unexpected security/permission prompt; no loss of required pointer behavior | Entitlement/signing automated; physical runtime manual |
| `NH-GATEKEEPER-001` | Download a stable GitHub Release DMG and open normally | Gatekeeper identifies/notarizes the Developer ID build without “unidentified developer” workaround | Release workflow signs/notarizes/staples/assesses; quarantine/download UX manual once per release pipeline change |
| `NH-SPACE-001` | Switch Spaces / fullscreen app | Panel behavior matches documented policy | Planned M1 |
| `NH-DISPLAY-001` | Connect/move between displays | Panel migrates correctly and uses target display geometry | Planned M1 |

## Known acceptance history

### 2026-08-07 — cycle 1, bootstrap build

- `NH-BOOT-001`: PASS enough to reach the running panel in the supplied screen recording.
- `NH-HOVER-001`: FAIL. The panel repeatedly oscillated between compact and expanded states during hover.
- Root cause: raw SwiftUI `onHover` events were treated as authoritative while the same state transition animated/resized the hosting `NSPanel`, allowing transient hover exits to feed back into presentation state.
- Regression coverage: `NotchPointerPolicyTests.expandedPointerInsideExpandedRetentionRegionStaysExpanded` was added RED first and failed with `.compact` instead of `.expanded`.
- Automated fix validation: PASS after replacing raw view-hover authority with screen-space pointer-region policy.

### 2026-08-07 — cycle 2, sandbox/Hardened Runtime build

Target MacBook, macOS 26.6:

- `NH-OS26-001`: PASS.
- `NH-NOTCH-001`: FAIL (minor) — compact panel appeared a few pixels wider than the hardware notch.
- `NH-HOVER-001`: PASS.
- `NH-HOVER-002`: PASS.
- `NH-HOVER-003`: FAIL — the view switched to its compact dot, but the black window shell remained expanded after pointer exit.
- `NH-SANDBOX-001`: reported as PASS by matrix order; the final user line repeated the `NH-HOVER-003` label, so this interpretation is explicitly documented rather than hidden.

Automated regression proof:

- RED commit `c518326` added `hardwareNotchWidthIsNotInflatedByFallbackMinimum` and `hostingViewDoesNotOwnWindowSizing` before the fixes.
- macOS 26 CI compiled successfully, then failed exactly those two tests: compact width `180` vs expected `176`, and hosting sizing options `rawValue 7` vs expected empty.
- GREEN commit `3bb1bbb` changed real-notch compact width to the detected hardware width and disabled `NSHostingView` sizing ownership with `sizingOptions = []`.
- CI run #19: **10/10 tests PASS**, plus format/security/warnings/signing/Hardened Runtime/App Sandbox/system-dylib/DMG gates PASS.
- Corrected-DMG hardware retest: PENDING for `NH-NOTCH-001`, `NH-HOVER-001`, `NH-HOVER-002`, and `NH-HOVER-003`.

## Release validation

PR artifacts are ad-hoc test builds. Stable releases additionally require the release workflow gates described in `docs/RELEASING.md`: Developer ID signing, Hardened Runtime/App Sandbox verification, Apple notarization, stapling, Gatekeeper assessment, and SHA-256 checksum publication.
