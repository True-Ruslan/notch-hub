#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
    echo "SECURITY BASELINE FAILED: $*" >&2
    exit 1
}

# 1. Runtime dependencies are intentionally zero at M0. New third-party code must be
# reviewed explicitly before this invariant is changed.
DEPS_JSON="$(mktemp)"
trap 'rm -f "$DEPS_JSON"' EXIT
swift package show-dependencies --format json > "$DEPS_JSON"
python3 - "$DEPS_JSON" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

dependencies = data.get("dependencies", [])
if dependencies:
    names = ", ".join(dep.get("name") or dep.get("identity") or "unknown" for dep in dependencies)
    raise SystemExit(f"Unexpected external Swift dependencies: {names}")
PY

# 2. Reject source-level capabilities that materially expand the attack surface.
# If one becomes necessary later, it must be introduced with a reviewed policy update,
# dedicated tests, and a narrow replacement for this blanket prohibition.
forbidden_source_patterns=(
    'Process[[:space:]]*\('
    'NSTask'
    'posix_spawn'
    'execve[[:space:]]*\('
    'popen[[:space:]]*\('
    'dlopen[[:space:]]*\('
    'dlsym[[:space:]]*\('
    'URLSession'
    'NWConnection'
    'import[[:space:]]+Network'
    'import[[:space:]]+WebKit'
    'WKWebView'
    '@_silgen_name'
    'https?://'
    '\.keyDown'
    '\.keyUp'
    '\.flagsChanged'
    '\.leftMouseDown'
    '\.leftMouseUp'
    '\.rightMouseDown'
    '\.rightMouseUp'
    '\.otherMouseDown'
    '\.otherMouseUp'
    '\.leftMouseDragged'
    '\.rightMouseDragged'
    '\.otherMouseDragged'
    '\.scrollWheel'
)

for pattern in "${forbidden_source_patterns[@]}"; do
    if grep -RInE --include='*.swift' "$pattern" Sources; then
        fail "forbidden source capability matched pattern: $pattern"
    fi
done

# 3. No embedded private keys or common long-lived token formats in tracked files.
if git grep -nEI -- \
    '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{24,}' \
    -- ':!CHANGELOG.md' ':!docs/*' ':!SECURITY.md'; then
    fail "possible credential or private key material found in tracked files"
fi

# 4. M0 sandbox/entitlement contract is intentionally minimal.
ENTITLEMENTS_JSON="$(mktemp)"
trap 'rm -f "$DEPS_JSON" "$ENTITLEMENTS_JSON"' EXIT
plutil -convert json -o "$ENTITLEMENTS_JSON" Resources/NotchHub.entitlements
python3 - "$ENTITLEMENTS_JSON" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    actual = json.load(handle)

expected = {"com.apple.security.app-sandbox": True}
if actual != expected:
    raise SystemExit(f"Unexpected entitlements. Expected {expected!r}, got {actual!r}")
PY

# 5. High-risk Hardened Runtime exceptions must never be silently introduced.
if grep -RInE \
    'com\.apple\.security\.cs\.(disable-library-validation|allow-unsigned-executable-memory|allow-dyld-environment-variables|allow-jit|get-task-allow)' \
    Resources .github Sources Tools Tests 2>/dev/null; then
    fail "dangerous code-signing/runtime exception found"
fi

# 6. No persistence helpers or privileged install surfaces at M0.
for forbidden_path in LaunchAgents LaunchDaemons PrivilegedHelperTools; do
    if find . -path "*/$forbidden_path/*" -print -quit | grep -q .; then
        fail "unexpected persistence/privileged path found: $forbidden_path"
    fi
done

# 7. Workflow supply-chain and public-fork policy. External actions must be immutable
# full SHAs, privileged PR/workflow_run bridges are prohibited repository-wide, and
# ordinary PR CI must stay read-only without repository secrets or self-hosted runners.
python3 <<'PY'
from pathlib import Path
import re

workflow_dir = Path('.github/workflows')
errors = []
for path in sorted(workflow_dir.glob('*.y*ml')):
    text = path.read_text(encoding='utf-8')
    for line_no, line in enumerate(text.splitlines(), 1):
        match = re.search(r'\buses:\s*([^\s#]+)', line)
        if not match:
            continue
        reference = match.group(1)
        if reference.startswith('./'):
            continue
        if '@' not in reference:
            errors.append(f'{path}:{line_no}: action reference has no immutable revision: {reference}')
            continue
        revision = reference.rsplit('@', 1)[1]
        if not re.fullmatch(r'[0-9a-fA-F]{40}', revision):
            errors.append(f'{path}:{line_no}: action is not pinned to a full commit SHA: {reference}')

if errors:
    raise SystemExit('\n'.join(errors))
PY

python3 scripts/release_policy.py validate-public-workflows --directory .github/workflows || \
    fail "repository workflow triggers violated the public-repository trust boundary"

CI_WORKFLOW=".github/workflows/ci.yml"
[[ -f "$CI_WORKFLOW" ]] || fail "missing CI workflow"
python3 scripts/release_policy.py validate-public-ci --workflow "$CI_WORKFLOW" || \
    fail "ordinary pull-request CI violated the public-repository trust boundary"

# 8. Release-tier security policy. Personal distribution intentionally has no Apple
# credentials/notarization authority and must never be silently upgraded, weakened,
# or made mutable. The future trusted tier is separate and cannot overwrite versions.
PERSONAL_WORKFLOW=".github/workflows/personal-release.yml"
TRUSTED_WORKFLOW=".github/workflows/trusted-release.yml"
[[ -f "$PERSONAL_WORKFLOW" ]] || fail "missing Personal Release workflow"
[[ -f "$TRUSTED_WORKFLOW" ]] || fail "missing Trusted Release workflow"
[[ ! -e .github/workflows/release.yml ]] || fail "ambiguous legacy release.yml must not exist"

python3 scripts/release_policy.py validate-workflow --workflow "$PERSONAL_WORKFLOW" || \
    fail "Personal Release workflow violated its trust boundary"

VERSION="$(tr -d '[:space:]' < VERSION)"
NOTES="docs/releases/v$VERSION.md"
python3 scripts/release_policy.py validate-notes --version "$VERSION" --notes "$NOTES" || \
    fail "Personal Release notes violated trust-labeling policy"

if grep -RIn --include='*release.yml' -- '--clobber' .github/workflows; then
    fail "release workflows must never replace existing release assets"
fi

if ! grep -q 'environment: release' "$TRUSTED_WORKFLOW"; then
    fail "Trusted Release must remain behind the release environment"
fi
if ! grep -q 'notarytool' "$TRUSTED_WORKFLOW"; then
    fail "Trusted Release must retain Apple notarization"
fi
if ! grep -q 'Developer ID Application' "$TRUSTED_WORKFLOW"; then
    fail "Trusted Release must retain Developer ID verification"
fi

# 9. Performance tooling is development/release-only. The runtime remains event-driven,
# and the sampler/policy scripts must never become an in-app telemetry or subprocess surface.
python3 scripts/performance_policy.py audit Sources || \
    fail "runtime performance policy violated"

if grep -RInE --include='*.swift' 'perf-baseline|performance_policy|test_performance_policy' Sources Resources 2>/dev/null; then
    fail "development performance tooling referenced by runtime/resources"
fi

if grep -InE 'perf-baseline|performance_policy|test_performance_policy' scripts/build-app.sh scripts/build-dmg.sh; then
    fail "application packaging must not copy or invoke development performance tooling"
fi

# 10. Universal Media probe is a development-only compatibility boundary. It may use
# Process only inside Tools, but its transport, input scope, upstream revision, and
# shipping isolation are fixed and executable policy. A successful probe does not
# relax the production Sources/** restrictions above.
PROBE_DIR="Tools/MediaBridgeProbe"
BOOTSTRAP="scripts/bootstrap-media-bridge-probe.sh"
PROBE_BUILD="scripts/build-media-bridge-probe-app.sh"
PROBE_VERIFY="scripts/verify-media-bridge-probe.sh"
PROBE_COMMIT="3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
PROBE_REPO="https://github.com/ungive/mediaremote-adapter.git"

for required in "$PROBE_DIR/Core/ProbeProcess.swift" "$BOOTSTRAP" "$PROBE_BUILD" "$PROBE_VERIFY"; do
    [[ -e "$required" ]] || fail "missing media bridge probe boundary file: $required"
done

grep -Fq "readonly ADAPTER_REPO=\"$PROBE_REPO\"" "$BOOTSTRAP" || \
    fail "media bridge probe upstream repository is not fixed"
grep -Fq "readonly ADAPTER_COMMIT=\"$PROBE_COMMIT\"" "$BOOTSTRAP" || \
    fail "media bridge probe upstream revision is not pinned"
grep -Fq 'URL(fileURLWithPath: "/usr/bin/perl")' "$PROBE_DIR/Core/ProbeProcess.swift" || \
    fail "media bridge probe process executable is not fixed to /usr/bin/perl"
for required_arg in '"stream"' '"--no-diff"' '"--micros"'; do
    grep -Fq "$required_arg" "$PROBE_DIR/Core/ProbeProcess.swift" || \
        fail "media bridge probe stream contract is missing $required_arg"
done

probe_forbidden_patterns=(
    'NSTask'
    'posix_spawn'
    'execve[[:space:]]*\('
    'popen[[:space:]]*\('
    'dlopen[[:space:]]*\('
    'dlsym[[:space:]]*\('
    'URLSession'
    'NWConnection'
    'import[[:space:]]+Network'
    'import[[:space:]]+WebKit'
    'WKWebView'
    '@_silgen_name'
    '/bin/(ba|z|k|c|tc)?sh'
    '\.keyDown'
    '\.keyUp'
    '\.flagsChanged'
    '\.leftMouseDown'
    '\.leftMouseUp'
    '\.rightMouseDown'
    '\.rightMouseUp'
    '\.otherMouseDown'
    '\.otherMouseUp'
    '\.leftMouseDragged'
    '\.rightMouseDragged'
    '\.otherMouseDragged'
    '\.scrollWheel'
)
for pattern in "${probe_forbidden_patterns[@]}"; do
    if grep -RInE --include='*.swift' "$pattern" "$PROBE_DIR"; then
        fail "forbidden media probe capability matched pattern: $pattern"
    fi
done

if grep -RInE --include='*.swift' '"get"|"get[[:space:]]' "$PROBE_DIR"; then
    fail "media bridge probe must not use periodic get polling"
fi

for packaging_script in scripts/build-app.sh scripts/build-dmg.sh; do
    if grep -Eq 'MediaBridgeProbe|mediaremote-adapter|MediaRemoteAdapter' "$packaging_script"; then
        fail "shipping packaging references development media probe assets: $packaging_script"
    fi
done

if grep -RInE \
    'com\.apple\.security\.cs\.(disable-library-validation|allow-unsigned-executable-memory|allow-dyld-environment-variables|allow-jit|get-task-allow)' \
    "$PROBE_DIR" "$PROBE_BUILD" "$PROBE_VERIFY" 2>/dev/null; then
    fail "media bridge probe attempted to weaken Hardened Runtime"
fi

echo "Security baseline checks passed."
