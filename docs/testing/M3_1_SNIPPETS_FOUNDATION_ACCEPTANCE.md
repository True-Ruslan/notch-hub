# M3.1 Snippets Foundation — Automated Acceptance

Status: **IMPLEMENTED / FINAL EXACT-HEAD CI PENDING / NOT MERGED / NOT RELEASED**

Date: 2026-09-10  
PR: #93  
Feature branch: `feat/m3-1-snippets-foundation`  
Stacked base: `feat/m2-3-shelf-share`

## Acceptance policy

NotchHub uses automation-first acceptance for bounded personal-use product slices unless a feature specification explicitly elevates a physical check to a required gate.

M3.1 therefore uses the project state sequence:

**implemented → automated-accepted → merged → released**

Current state while this document is being added:

- Implemented: **YES**
- Production behavior verified by canonical CI: **YES, except for the intentionally superseded size envelope**
- Final documented-head automated acceptance: **PENDING**
- Merged: **NO**
- Released: **NO**

No physical Snippets check is required for merge under the current personal-use acceptance policy. Any deterministic defect discovered later should first be reproduced by automation.

## Accepted implementation scope

M3.1 adds a bounded sandbox-local text Snippets module:

- first-class Expanded Home → Snippets routing;
- Snippets access while media is active in Expanded;
- destination reset to Home outside Expanded;
- versioned local `SnippetItem` persistence;
- Add, Edit and Delete with explicit user action;
- explicit Copy through a narrow write-only clipboard boundary;
- one in-surface SwiftUI editor rather than a new window;
- process-isolated UI-test persistence;
- external application XCUITest coverage for Home/media routing and collapse reset.

Explicitly deferred from this slice:

- clipboard reading, history, monitoring, observation or auto-capture;
- direct paste into another application;
- Accessibility, Automation/Apple Events, Input Monitoring or Screen Recording;
- global keyboard shortcuts;
- search, tags, favorites, folders, drag reordering, import/export or sync;
- rich text, images, files or attachments;
- URL fetching/WebKit/metadata lookup;
- new network authority or third-party runtime dependency.

## Data and persistence boundary

`SnippetItem` stores only UUID, exact user-entered text, `createdAt` and `updatedAt`.

`SnippetPersistenceRepository` is actor-backed and writes schema-v1 JSON atomically to the app's sandbox-local Application Support directory:

```text
Application Support/NotchHub/Snippets/snippets.json
```

Behavior is fail-closed and bounded:

- missing file → empty state without an error;
- malformed JSON → empty state plus a load-error flag;
- unsupported schema → empty state plus a load-error flag;
- failed save → keep already-mutated in-memory state and set the bounded persistence error flag;
- successful later save clears that flag;
- no periodic retry, file watcher or filesystem scan.

Snippet text is treated as sensitive local user content. Production Snippets code does not print or log snippet text and does not place it into telemetry, diagnostics or build artifacts.

## Clipboard boundary

Core exposes only `SnippetClipboardWriting.write(_:)`.

The shipping `SystemSnippetClipboardWriter` owns the sole Snippets AppKit clipboard access and is intentionally write-only:

1. `NSPasteboard.general`;
2. `clearContents()`;
3. `setString(text, forType: .string)`.

Source-policy tests reject clipboard read/history/observation primitives including `string(forType:)`, `data(forType:)`, `propertyList(forType:)`, `pasteboardItems`, `readObjects(...)` and `changeCount`, as well as timer/polling/global-monitor/network/Accessibility escape paths.

External XCUITest does not click Copy, so the canonical runner validates routing and composition without modifying the machine's real clipboard.

## Routing and composition

M3.1 generalizes the previous Shelf-only wrapper into one `ProductRoutingRootView` composition seam.

`NotchDestinationModel` remains the bounded first-party destination authority for `.home`, `.shelf` and `.snippets`. Panel geometry and transitions remain owned by `NotchPanelController` / `NotchPanelTransitionCoordinator`.

`AppDelegate` owns one `SnippetStore` and one `SystemSnippetClipboardWriter` for application lifetime and supplies concrete `ShelfView`, `SnippetsView` and existing media/Home content to the generic router.

The obsolete `ShelfRoutingRootView` production path is removed so two routing authorities cannot drift independently. Media rendering internals remain independent from `SnippetStore` and `NotchDestinationModel`.

UI-test builds use:

```text
FileManager.default.temporaryDirectory/
  NotchHub-UITests-<pid>/
    Snippets/
      snippets.json
```

so XCUITest cannot read or mutate the real user's Snippets database.

## TDD and canonical evidence

M3.1 was developed through explicit RED → GREEN stages for persistence, store semantics, routing, clipboard/UI policy and final App composition.

The final composition RED required `AppDelegate` to own the process-isolated `SnippetStore`, inject one clipboard writer and route concrete `SnippetsView` content. Production composition commit `42018bdbfcac4623db38cb57aa1e910c382df93e` satisfied that contract. A later canonical package failure exposed only strict Swift-format warnings in two M3.1 tests; formatter-only commits corrected those warnings without changing behavior.

Canonical CI #1501 / run `34372146755` on exact head `be46025ccfc4b4b9d6f33e78d294c6d186a9202c` established the production behavior and package/security result:

- `macOS 26 compatibility` — **SUCCESS**;
- `macOS UI regression` — **SUCCESS**, including external application XCUITest smoke;
- `Build, test and package` — all correctness/security/package steps before size enforcement **SUCCESS**;
- complete Swift suite — **532 tests PASS**;
- release DMG build — **SUCCESS**;
- Hardened Runtime / App Sandbox / exact effective entitlements — **SUCCESS**;
- shipping provenance and deterministic artifact-size collection — **SUCCESS**.

The only failing gate was the pre-M3.1 M2.1 feature-size envelope, which correctly rejected intentional Snippets shipping growth.

## Provenance-backed M3.1 size envelope

Exact deterministic evidence from CI #1501:

```json
{
  "appSizeBytes": 1318340,
  "dmgSizeBytes": 807169,
  "executableSizeBytes": 1016032,
  "schemaVersion": 1,
  "sourceCommit": "be46025ccfc4b4b9d6f33e78d294c6d186a9202c"
}
```

Evidence provenance:

- workflow run: `34372146755`;
- artifact: `10112663094` (`NotchHub-shipping-media-candidate`);
- immutable baseline: `performance/baseline-v0.1.0.json`.

`performance/m3-1-snippets-foundation-size-budget.json` adds only a feature-specific allowance to that immutable baseline. The resulting headroom is deliberately narrow:

- app: 46,996 bytes;
- DMG: 47,943 bytes;
- executable: 45,208 bytes.

The historical M2.1 and M7 envelopes remain unchanged and are self-validated separately. CI now uses the M3.1 envelope as the active release-size gate.

## Security result

M3.1 does not widen the shipping entitlement set. It remains exactly:

- `com.apple.security.app-sandbox = true`;
- `com.apple.security.files.user-selected.read-only = true`.

The read-only user-selected-file entitlement exists for Shelf; Snippets persistence is inside the app's own sandbox container and requires no new file entitlement.

M3.1 adds no application network authority, WebKit path, subprocess, dynamic code, telemetry, snippet-content logging, clipboard reader/history/observer, timer/polling/filesystem watcher, global input monitor, direct paste path, Accessibility/Automation/Input Monitoring/Screen Recording permission, or third-party runtime dependency.

## Performance and energy result

M3.1 adds **zero recurring idle work** by design.

Work occurs only on explicit navigation, the one-shot first Snippets load, explicit Add/Edit/Delete persistence, and explicit Copy. No timer, clipboard observer, file watcher, polling loop or background retry is introduced.

The deterministic size increase is separately budgeted from exact canonical evidence rather than by modifying the historical baseline.

## External UI acceptance

The external application suite covers these no-side-effect scenarios:

1. Expanded Home → Snippets → Home;
2. Expanded media → Snippets → Home/media restored;
3. Snippets destination resets after collapse/re-expand.

The suite asserts stable Snippets accessibility surfaces and deliberately does not click Copy or enter sensitive snippet content.

## Dependency and release ordering

At the time this document is added, the latest published Personal Release is still `v0.5.0`; protected `main` contains the prepared `v0.6.0` M2.1 release commit but `v0.6.0` publication is still pending.

Therefore PR #93 remains stacked and must not merge ahead of:

1. publication of prepared `v0.6.0`;
2. merge and protected-main verification of PR #91 (M2.2 Quick Look);
3. retarget/reverification/merge of PR #92 (M2.3 Share).

After those dependencies are integrated, PR #93 must be retargeted to the resulting `main` and reverified if the effective merge base changes. M3.1 must not be described as released until a versioned GitHub Release actually contains it.

## Final documented-head gate

This file intentionally does not predeclare automated acceptance. The branch becomes **AUTOMATED-ACCEPTED** only after all three required canonical jobs succeed on the exact final head containing this acceptance record, matching security/architecture/roadmap documentation, the M3.1 size budget and its active CI gate.
