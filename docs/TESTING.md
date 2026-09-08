# Testing

## Policy

NotchHub is a personal-use native macOS application. The primary product target is **macOS 26.6**.

From 2026-09-08 onward, deterministic automated acceptance is the default merge and release gate. Physical/manual checks remain useful for diagnostics and subjective quality, but they are not blockers unless a future feature specification explicitly elevates one to a mandatory gate.

Use project states precisely:

**implemented → automated-accepted → merged → released**

A green PR is not merged until its exact head passed the required checks. Merged code is not released until a versioned release points at accepted merged code and the release workflow/provenance checks pass.

## Required CI

Canonical protected-branch jobs:

- `macOS 26 compatibility`;
- `macOS UI regression`;
- `Build, test and package`.

For product changes, the exact candidate SHA must pass all applicable checks:

- Swift build with warnings as errors;
- Swift unit, integration and policy tests;
- strict acceptance traceability;
- external-application XCUITest for deterministic user-facing flows;
- source/security policy audit;
- exact effective shipping-entitlement verification;
- isolated probe/candidate entitlement verification where applicable;
- release bundle, code-signing, Hardened Runtime, provenance and DMG verification;
- deterministic artifact-size budget;
- performance-policy audit and compatibility smoke;
- no unresolved review defects.

A failed mandatory gate means the candidate is not `automated-accepted`.

## Test-driven development

Feature and defect work follows RED → GREEN whenever the behavior can be validated deterministically:

1. add or tighten the smallest test/policy check that expresses the required behavior;
2. observe the intended failure on the pre-fix candidate;
3. implement the minimum production change;
4. run the focused check;
5. run the complete CI matrix before integration.

Tests must not mutate real user data.

## UI automation

User-visible notch flows are exercised through the external-app XCUITest project. UI fixtures must remain isolated from the shipping application, and the shipping build is checked for fixture/test markers.

For App Sandbox/TCC features, UI tests should validate routing and safe state transitions without fabricating broad permissions. Persistence semantics, negative security cases and file-operation safety belong in deterministic core/policy tests.

## Security testing

The shipping entitlement set is fail-closed and exact. As of M2.1:

- `com.apple.security.app-sandbox = true`;
- `com.apple.security.files.user-selected.read-only = true`.

Tests/scripts reject unexpected read-write file access, network entitlements, Automation/Apple Events, global input monitoring, dynamic-code exceptions or other permissions not explicitly reviewed by a feature specification.

Security-scoped resource access must be short-lived, balanced and fail closed when scope acquisition fails.

## Performance testing

Prefer event-driven behavior over timers or polling. The performance policy rejects unreviewed runtime timers and related mechanisms.

Shipping candidates are checked against the immutable baseline plus the currently reviewed provenance-backed feature-size budget. Historical feature budgets remain evidence; only the latest reviewed budget is the active CI envelope.

When a feature needs CPU/RSS/thread evidence, use the repository performance harness and retain source-commit provenance.

## Physical/manual checks

Physical checks on the owner's Mac may still be run for visual quality, hardware-specific behavior, third-party integration or diagnosis. They are **non-blocking by default** from 2026-09-08.

Historical records under `docs/testing/` remain valid evidence for older releases; this policy does not rewrite their historical status.

`NH-PERSONAL-RELEASE-001` is retained as the historical/manual personal-release spot-check identifier. For new releases it is optional diagnostic evidence, not a release gate.

## M2.1 reference evidence

M2.1 Shelf Foundation reached automated acceptance on PR #88 head `7f2a17cd39f15ec395560866c8d61e0c4cf9d5bf` with CI run `34267057068` (#1460): macOS 26 compatibility, external-app UI regression and build/test/package all succeeded. It was squash-merged as `b0c1cf2f1054e754174099c31b1684f1742a11b2`.

Detailed evidence: `docs/testing/M2_1_SHELF_FOUNDATION_ACCEPTANCE.md`.
