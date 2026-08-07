# Testing

## Goal

Automate every deterministic behavior that can be validated reliably in CI. Manual acceptance is reserved for behavior that depends on physical MacBook notch geometry, real pointer feel, macOS permission surfaces, third-party applications, or final visual quality.

A green pipeline is necessary but is not treated as proof of physical-device UX.

## Required CI gate

The protected-branch check is `Build, test and package`. It validates:

1. Swift package structure.
2. Swift formatting.
3. shell and plist syntax.
4. debug compilation.
5. the full Swift test suite with coverage instrumentation.
6. release application/DMG packaging.
7. bundle version stamping.
8. ad-hoc code-signature verification.
9. DMG integrity with `hdiutil verify`.
10. artifact upload.

Do not lower assertions, delete useful tests, or weaken production behavior merely to make CI green.

## Test design

Prefer pure deterministic policies for geometry and state transitions. AppKit/SwiftUI wiring should be thin and delegate decisions to testable code.

Tests should:

- state one behavior in the name;
- assert externally meaningful state/results;
- avoid mocks unless an OS or third-party boundary cannot reasonably be exercised;
- avoid arbitrary sleeps in unit tests;
- include boundary cases for screen geometry and pointer regions;
- reproduce a reported regression before its production fix is written.

No arbitrary global coverage percentage is used at this stage. A high number can reward meaningless tests. Coverage instrumentation is enabled so untested deterministic logic can be identified as the codebase grows; thresholds may be introduced later per stable core component.

## Real-hardware acceptance matrix

Record results in `docs/PROJECT_STATE.md` using these stable IDs.

| ID | Scenario | Expected result | Automation |
| --- | --- | --- | --- |
| `NH-BOOT-001` | Install/open CI-produced DMG | App launches without crashing and panel appears | Packaging automated; launch UX manual |
| `NH-NOTCH-001` | Observe compact panel on a MacBook with hardware notch | Panel is centered/aligned with the physical notch and does not cover unexpected menu-bar areas | Geometry unit-tested; physical alignment manual |
| `NH-HOVER-001` | Move pointer into compact activation region and hold it for at least 3 seconds | Exactly one expansion; no compact/expanded oscillation | Pointer policy unit-tested; actual AppKit events manual |
| `NH-HOVER-002` | Move pointer around inside the expanded panel, including outside the original compact width | Panel remains expanded | Pointer retention unit-tested; event delivery manual |
| `NH-HOVER-003` | Move pointer clearly outside expanded panel/retention margin | Panel collapses once and stays compact | Pointer policy unit-tested; animation feel manual |
| `NH-SPACE-001` | Switch Spaces / fullscreen app | Panel behavior matches documented policy | Planned M1 |
| `NH-DISPLAY-001` | Connect/move between displays | Panel migrates correctly and uses target display geometry | Planned M1 |

## Known acceptance history

### 2026-08-07 — bootstrap build

- `NH-BOOT-001`: PASS enough to reach the running panel in the supplied screen recording.
- `NH-HOVER-001`: FAIL. The panel repeatedly oscillated between compact and expanded states during hover.
- Root cause: raw SwiftUI `onHover` events were treated as authoritative while the same state transition animated/resized the hosting `NSPanel`, allowing transient hover exits to feed back into presentation state.
- Regression coverage: `NotchPointerPolicyTests.expandedPointerInsideExpandedRetentionRegionStaysExpanded` was added RED first and failed with `.compact` instead of `.expanded`.
- Automated fix validation: PASS in CI after replacing raw view-hover authority with screen-space pointer-region policy.
- Real-hardware retest of the fixed DMG: PENDING.
