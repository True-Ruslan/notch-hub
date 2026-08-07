# Personal Release and Performance Baseline Design

Date: 2026-08-07
Status: proposed and user-approved at design level; implementation pending written-spec review
Target repository: `True-Ruslan/notch-hub`

## Context

M0 engineering foundation is accepted on the target MacBook running macOS 26.6. The project already enforces App Sandbox, Hardened Runtime, zero third-party Swift runtime dependencies, strict CI, deterministic regression tests, and a fail-closed security baseline.

The original release design assumed an Apple Developer Program membership so every stable GitHub Release could be Developer ID signed and notarized. That yearly paid dependency is intentionally deferred because NotchHub is currently a personal-use application and is not intended for public distribution.

The project also elevates runtime efficiency to a first-class product requirement. NotchHub is expected to run continuously near the system UI, so security, correctness, performance, memory usage, wakeups, CPU use, and background activity must be treated as merge/release concerns rather than later optimization work.

## Decisions

### D1 — Personal release is the current supported distribution tier

`v0.1.0` will be published through GitHub Releases as a **personal ad-hoc signed build**.

The personal release will still require:

- accepted protected `main` as the exact source;
- the complete normal CI quality gate;
- App Sandbox;
- Hardened Runtime with no dangerous exceptions;
- zero unexpected entitlements;
- system-library-only linkage at the current milestone;
- DMG integrity verification;
- SHA-256 checksum publication;
- explicit build metadata containing source commit, version, build number, runner/macOS version, Xcode/Swift version, and artifact checksum;
- immutable release/tag semantics.

The personal release will **not** claim Apple trust, Developer ID signing, or notarization. Release notes and documentation must state that macOS may require Finder `Open` / Privacy & Security `Open Anyway` on first launch of a downloaded build.

The project must never recommend disabling Gatekeeper, globally weakening macOS security, removing quarantine recursively, or installing a custom trusted root solely to suppress the warning.

### D2 — Trusted distribution remains a future optional tier

The existing Developer ID + notarization flow is retained as a future **Trusted Release** path, but it is no longer a blocker for personal versioning or continued development.

The two tiers are intentionally distinct:

1. **Personal Release** — current, ad-hoc signed, local/personal use, checksum/provenance verified by the project.
2. **Trusted Release** — future, Developer ID signed + notarized + stapled + Gatekeeper-assessed if Apple Developer Program membership becomes worthwhile.

A personal artifact must never be presented as a trusted/notarized artifact.

### D3 — Release artifacts are immutable

A published version/tag is immutable. If a release is wrong, the project fixes the defect and increments the version; it does not silently replace a previously published DMG under the same version.

The personal release workflow therefore fails if the derived `v<version>` tag or GitHub Release already exists.

### D4 — No automatic updater yet

NotchHub will not implement background self-update or an update daemon. Updates remain a deliberate manual action through GitHub Releases until an authenticated update design is separately reviewed.

This keeps persistence, networking, signing, and supply-chain attack surface minimal.

## Personal Release workflow design

A dedicated workflow should publish the accepted application from protected `main` without Apple secrets.

Proposed flow:

```text
manual workflow_dispatch on main
    -> validate source == current protected main
    -> validate VERSION / SemVer / CHANGELOG state
    -> run format + security audit + warnings-as-errors build + full tests
    -> build release app + DMG using ad-hoc signature
    -> verify bundle ID/version/build number
    -> verify codesign integrity
    -> verify Hardened Runtime
    -> inspect effective App Sandbox entitlements
    -> verify linked libraries
    -> hdiutil verify
    -> generate SHA-256
    -> generate machine-readable build metadata
    -> assert tag/release do not already exist
    -> create immutable v<version> tag
    -> publish GitHub Release
       - NotchHub.dmg
       - NotchHub.dmg.sha256
       - build-metadata.json
```

Release notes must prominently state:

- personal-use build;
- ad-hoc signed, not Developer ID/notarized;
- expected macOS first-launch trust warning;
- safe opening instructions only;
- exact source commit and checksum.

The current trusted release workflow should be renamed or documented so it cannot be confused with the personal path.

## Performance and resource-efficiency contract

Performance is a permanent project invariant alongside `SECURITY.md`.

### Runtime principles

1. **Event-driven by default.** Do not poll when an OS event/notification can be used.
2. **No permanent busy loops.** `while true`, spin loops, and similar constructs are prohibited in runtime code without an explicitly reviewed bounded design.
3. **No periodic timers without justification.** `Timer`, `DispatchSourceTimer`, repeating sleeps/tasks, display links, or periodic refresh loops require an explicit performance rationale and lifecycle tests.
4. **Zero unnecessary background work while idle.** A compact, untouched NotchHub should do no application-level work other than unavoidable OS event delivery.
5. **Observers must have bounded lifetimes.** Event monitors, notifications, tasks, subscriptions, security-scoped resources, and future media/calendar observers must be explicitly cancelled/released.
6. **Caches must be bounded.** Artwork, snippets, file metadata, and other future caches require size/count limits and eviction rules.
7. **No hidden network/background sync.** Existing security policy remains authoritative; performance design does not justify adding network traffic.
8. **Avoid broad input observation.** Prefer window-local AppKit tracking over systemwide event observation when behavior can be implemented reliably without extra permissions.
9. **Native APIs first.** Avoid heavyweight embedded runtimes, web views, daemon helpers, and unnecessary third-party frameworks.
10. **Measure before setting tight numerical budgets.** Absolute CPU/RAM limits must come from a reproducible baseline on the real target Mac rather than arbitrary guesses.

## M1 pointer-monitor optimization

The existing global `NSEvent` `.mouseMoved` monitor is intentionally narrow from a security perspective, but it still receives mouse movement systemwide and therefore is a candidate for unnecessary wakeups/CPU work.

M1 should investigate replacing it with an AppKit-local tracking boundary such as `NSTrackingArea` / view-level enter/exit/move handling while preserving the already accepted deterministic screen-space retention policy.

Preferred order:

1. window-local tracking with no global event monitor;
2. if reliable behavior cannot be achieved, a narrowly scoped fallback with documented measured cost;
3. do not adopt `CGEventTap`, Input Monitoring, Accessibility, or broader capture merely for hover convenience.

The replacement must be developed RED -> GREEN where deterministic and must pass the existing real-hardware notch/hover matrix before the global monitor is removed.

## Performance baseline methodology

Before implementing feature-heavy M1 work, establish a reproducible M0/M0.1 resource baseline on the target MacBook/macOS 26.6.

### Metrics

At minimum record:

- idle CPU percentage over a sustained window;
- active/hover CPU percentage during a defined interaction window;
- resident memory (RSS) median and maximum;
- thread count median and maximum;
- process lifetime stability / memory growth across repeated expand-collapse cycles;
- binary/app/DMG size;
- whether the application creates periodic work while completely idle.

Energy-impact/wakeup data should be added when it can be gathered reproducibly without requiring unsafe privileges or unstable CI assumptions.

### Measurement scenarios

Use stable IDs:

- `NH-PERF-IDLE-001` — launch, warm up, then remain compact/untouched for a fixed measurement window.
- `NH-PERF-HOVER-001` — repeated normal expand/retain/collapse interaction using a fixed procedure.
- `NH-PERF-STRESS-001` — large deterministic state-transition stress run to detect leaks/unbounded allocations in testable code.
- `NH-PERF-SIZE-001` — record executable/app/DMG sizes for each release candidate.

The exact sampling duration and command implementation belong in the implementation plan, but must be fixed and documented before results are compared.

## Performance gates

### Deterministic CI gates

CI should fail on objectively testable regressions such as:

- forbidden unbounded loops or new polling/timer primitives without explicit allowlist review;
- leaked/lifecycle-broken testable observers or tasks where deterministic tests can prove ownership;
- unbounded collections/caches introduced in core services without explicit policy;
- significant artifact-size growth beyond a documented project threshold once a baseline is established;
- performance-sensitive pure algorithms exceeding broad, non-flaky complexity/iteration invariants where wall-clock timing is unnecessary.

### Real-hardware performance gate

CPU/RAM/energy numbers from shared GitHub runners must **not** be used as tight required thresholds because runner load/hardware noise makes that dishonest.

Instead:

- CI verifies deterministic performance invariants and produces comparable metadata;
- the target MacBook establishes the canonical runtime baseline;
- future release candidates are compared against the same measurement procedure;
- a material regression requires investigation before acceptance.

Numerical budgets are added only after the first baseline is measured. They should include both an absolute ceiling and a regression allowance large enough to account for measurement noise.

## Security/performance interaction

Performance optimization must not weaken security. In particular:

- no sandbox escape or entitlement broadening for speed;
- no unsigned/dynamic native code loading;
- no custom daemon/helper merely to reduce UI latency;
- no privileged performance collector shipped with the app;
- no global input capture expansion;
- no silent telemetry for performance monitoring.

Measurements are development/release activities, not runtime telemetry.

## Documentation changes required during implementation

The implementation PR should update:

- `SECURITY.md` — distinguish personal vs trusted release guarantees and accepted Gatekeeper limitation;
- `docs/ARCHITECTURE.md` — add event-driven/resource-efficiency architecture and release tiers;
- `docs/RELEASING.md` — document Personal Release as current default and Trusted Release as optional future path;
- `docs/TESTING.md` — add performance scenario IDs and deterministic/manual boundary;
- `docs/ROADMAP.md` — remove paid Apple membership as a blocker and place performance baseline before feature-heavy M1 work;
- `docs/PROJECT_STATE.md` — record the deliberate Apple-program deferral and current next step;
- `CHANGELOG.md` — record release/performance infrastructure changes;
- a new `PERFORMANCE.md` — authoritative performance/resource contract, baselining method, budgets, and regression policy.

## TDD and implementation sequencing

Implementation should be split into small, reviewable commits/PR work with RED evidence where behavior is testable:

1. release-policy/documentation contract;
2. Personal Release workflow tests/static validation before workflow implementation where feasible;
3. performance-policy/audit regression tests;
4. baseline measurement harness with self-tests for parsing/aggregation;
5. collect the first target-Mac baseline and commit only summarized non-sensitive metrics;
6. establish numerical budgets from the baseline;
7. begin M1 pointer-monitor optimization using RED -> GREEN regression coverage;
8. rerun real-hardware hover and performance acceptance.

## Acceptance criteria

This design is complete when implementation proves all of the following:

- `v0.1.0` can be published from protected `main` without Apple paid credentials;
- the release is clearly identified as personal/ad-hoc and cannot be confused with a notarized build;
- the release includes checksum and provenance/build metadata;
- published release versions are immutable;
- no macOS security setting must be globally disabled to run the app;
- trusted Developer ID/notarization support remains available for the future but does not block development;
- `PERFORMANCE.md` exists and is enforced by executable CI policy where deterministic;
- a reproducible target-Mac performance baseline exists before substantial M1 feature work;
- numerical CPU/RAM/resource budgets are evidence-based rather than invented;
- performance work does not broaden permissions or security attack surface;
- existing M0 correctness/security tests remain green.

## Non-goals

This work does not yet implement Shelf, Snippets, Calendar, Translator, Yandex Music, self-update, public distribution, Developer ID purchase, or final visual redesign. Those remain later milestones after distribution and runtime-efficiency foundations are explicit and measurable.
