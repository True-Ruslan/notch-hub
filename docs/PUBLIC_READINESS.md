# Public repository readiness

Last reviewed: 2026-08-07
Current visibility: **Public**
Hardening merge: `23500e099a0f8b2738f1157c6ae3be71c89df6e1`
Status: **repository-content gates PASS; remaining GitHub Settings gates pending direct verification**

## Goal

Keep the NotchHub source repository safe to expose publicly without broadening application permissions, weakening release integrity, or giving untrusted pull requests access to privileged GitHub Actions capabilities.

## Repository-history audit

The complete pre-public `main` history was short and reviewable:

1. `6e04fa4226e60507e399f1f5b1a3cedce4678182` — initial commit;
2. `eb7bcfda3c6938d5bc3a13a6ccbfa85e062e39cb` — M0 foundation / PR #1;
3. `04487ae9149eb9850d66aae4952e4cfedfcd55da` — release/performance design / PR #2;
4. `8e913dcddfdec7d9aa920df8c37afb23b8c40884` — Personal Release / PR #3;
5. `8fb5a66ffcfefabfa9174ebc42ebeb92a4debafa` — M1 interaction specification / PR #4;
6. `a056aa74bad5d8e193eb4c76a76e6c910344bd09` — P0 Performance Foundation / PR #5.

Before public visibility, the initial commit and complete accessible PR #1–#5 diffs/discussions were reviewed for credential/private-key material and unintended private content. No separate open or closed Issues existed.

Result: **no secret value, API token, password, certificate/private key, or signing credential was found.** Historical workflow text contains only GitHub Secret *names* such as Apple signing/notarization variable names; secret values are not present in repository history.

No repository-history rewrite was required by the reviewed evidence.

## Data intentionally safe to publish

The repository intentionally contains non-secret engineering provenance, including:

- Git commit SHAs and release checksums;
- generic target model identifier `Mac16,8` used for reproducible performance evidence;
- macOS/Xcode/Swift versions;
- aggregate process CPU/RSS/thread measurements;
- executable/app/DMG byte sizes;
- GitHub repository/user name and public product documentation.

The performance harness explicitly excludes usernames, home paths, pointer history, clipboard/snippet content, user files, calendar/media content, and hardware serial numbers from the canonical baseline.

## Public pull-request CI boundary

Untrusted fork code may execute only through ordinary `.github/workflows/ci.yml` pull-request CI.

Executable policy requires that CI:

- uses the ordinary `pull_request` event;
- has explicit `contents: read` permission;
- never uses `pull_request_target` or `workflow_run` as an untrusted-code execution bridge;
- never references repository `secrets.*`;
- never runs untrusted PR code on `self-hosted` runners;
- never grants a `write` permission, `permissions: write-all`, or OIDC `id-token: write` authority;
- keeps `actions/checkout` credentials disabled with `persist-credentials: false`;
- does not hop into a reusable workflow;
- keeps third-party Actions pinned to immutable full commit SHAs;
- has no alternate repository workflow with a `pull_request` trigger.

These invariants are covered by `scripts/test_release_policy.py`, `scripts/release_policy.py`, and `scripts/security-audit.sh`.

### RED → GREEN evidence

The public-CI boundary was introduced test-first. RED CI #123 failed exactly while importing the deliberately missing `validate_public_ci_workflow` helper:

`ImportError: cannot import name 'validate_public_ci_workflow' from 'release_policy'`

Independent review then found two additional bounded trust-boundary gaps before merge: repository-wide privileged trigger enforcement and alternate PR/reusable-workflow execution paths. Tests were added and both gaps were closed before final acceptance.

Exact-head CI #139 on PR #6 passed:

- 16/16 release/public-repository policy tests;
- repository-wide workflow trigger policy;
- public pull-request CI policy;
- 22/22 performance-policy tests;
- complete security audit;
- 11/11 Swift tests;
- signing/Hardened Runtime/exact Sandbox/system-library/DMG checks;
- deterministic artifact-size budget;
- performance harness smoke and artifact upload.

Several earlier jobs during the work failed before checkout/test steps during a GitHub-hosted Actions incident; no test or security gate was weakened in response.

## Release workflow boundary

Publication remains separate from fork PR execution:

- Personal Release is manual `workflow_dispatch`, exact-`main` only, and contains no custom repository/Apple secrets;
- Trusted Release is a dormant future workflow scaffold: it references `environment: release`, but **no GitHub Environment is currently configured and no Apple signing/notarization secrets are provisioned**;
- GitHub documents that an environment must be created before it can be used by a workflow, so Trusted Release is not an operational release tier until that setup is deliberately performed;
- if Trusted Release is adopted later, the `release` environment, protection rules, and Apple credentials must be created and reviewed before the first run;
- neither release path may overwrite an existing tag/release;
- public PR CI cannot invoke either release workflow with write authority.

The absence of a configured `release` environment is intentional for the current Personal Release-only project and is treated as **N/A**, not a failed post-public gate.

## Runtime/security boundary

Changing repository visibility changed source availability, not application authority. The public-readiness change modified no `Sources/` files, entitlements, runtime networking, telemetry, input capture, persistence, subprocess behavior, signing requirements, or performance budgets.

## License

The repository is licensed under the MIT License in root `LICENSE`.

## Post-visibility verification

Programmatically confirmed after the transition:

- GitHub repository metadata reports `visibility=public`;
- public-readiness hardening was squash-merged as `23500e099a0f8b2738f1157c6ae3be71c89df6e1`;
- repository integration settings remain squash-only (`allow_squash_merge=true`, merge/rebase commits disabled);
- `v0.1.0` tag remains addressable and contains `VERSION=0.1.0` plus the versioned Personal Release documentation;
- the first post-public pull-request CI (#141) completed successfully through the normal public `pull_request` path, including public/release policy, security, performance, Swift, signing/Sandbox/DMG, and artifact-size gates;
- no GitHub Environments are currently configured; Trusted Release is intentionally unconfigured and therefore its environment/secrets isolation check is N/A until that tier is adopted.

Still requiring direct GitHub Settings/UI verification because the connected API does not expose these settings/assets:

1. active `main` branch protection/branch ruleset and required CI checks;
2. Actions default workflow token permissions and fork pull-request approval/settings;
3. published `v0.1.0` Release assets (`NotchHub.dmg`, checksum, `build-metadata.json`) remain visible and intact.

GitHub documents that visibility changes can alter ruleset state; therefore these settings are not assumed from the pre-transition configuration.

Public readiness is complete only after these three remaining checks are confirmed.
