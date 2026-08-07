# Development

## Engineering principles

NotchHub is developed as a small native macOS product, not as a demo. Prefer simple, observable behavior and explicit state over UI magic.

### Test-driven development

For behavior changes and bug fixes, use RED → GREEN → REFACTOR:

1. Add the smallest behavioral test that expresses the requirement.
2. Run it and verify it fails for the expected reason.
3. Implement the smallest production change that makes it pass.
4. Run the full required CI-equivalent checks.
5. Refactor only while the suite remains green.

A regression test must fail against the broken behavior before the fix is considered covered. Do not write tests whose only purpose is to satisfy a coverage number.

### Commits

Use small, intention-revealing commits. Preferred Conventional Commit prefixes:

- `feat:` user-visible capability
- `fix:` defect correction
- `test:` tests or reproducible regression coverage
- `refactor:` behavior-preserving internal change
- `docs:` documentation only
- `chore:` tooling, CI, packaging, maintenance

Do not mix unrelated refactors with a bug fix. A useful bug-fix history normally shows the regression test separately from the production fix.

### Pull requests

`main` is protected. Development happens on branches and lands through pull requests with the required `Build, test and package` check green. Use squash merge for the final integration commit while preserving the branch commit history in the PR discussion.

Before marking a PR ready:

- required automated checks are green;
- `CHANGELOG.md` is updated for notable behavior changes;
- `docs/PROJECT_STATE.md` reflects the actual state and remaining manual work;
- unavoidable manual acceptance is explicitly listed rather than silently assumed.

## Versioning

NotchHub uses Semantic Versioning (`MAJOR.MINOR.PATCH`). The current target version lives in the repository-root `VERSION` file and is stamped into `CFBundleShortVersionString` by the packaging script.

- PATCH: compatible bug fixes and hardening.
- MINOR: backward-compatible product capabilities/modules.
- MAJOR: incompatible product or storage/API changes once a stable contract exists.

`CFBundleVersion` is a monotonically increasing build number supplied by CI (`github.run_number`) and defaults to `1` for local packaging.

Release tags use `v<version>`, for example `v0.1.0`. The release workflow rejects a tag that does not match `VERSION`.

## Documentation contract

The repository is the hand-off source of truth for a new development session:

- `README.md` — product and build entry point.
- `docs/ARCHITECTURE.md` — architectural boundaries and decisions.
- `docs/ROADMAP.md` — milestones and exit criteria.
- `docs/PROJECT_STATE.md` — exact current state, accepted/manual-tested items, known limitations, and next step.
- `docs/TESTING.md` — automated gates and manual acceptance scenario IDs.
- `CHANGELOG.md` — notable changes by release.

Update the relevant files in the same PR when a decision, limitation, acceptance result, or roadmap status changes.
