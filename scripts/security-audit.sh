#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
    echo "SECURITY BASELINE FAILED: $*" >&2
    exit 1
}

# 1. Runtime dependencies remain intentionally free of third-party Swift packages.
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
# The only production Process exception is checked separately below and remains fixed
# to the reviewed Universal Media process boundary.
forbidden_source_patterns=(
    'NSTask'
    'posix_spawn'
    'execve[[:space:]]*\('
    'popen[[:space:]]*\('
    'dlopen[[:space:]]*\('
    'dlsym[[:space:]]*\('
    'CFBundleGetFunctionPointerForName'
    'MRMediaRemote'
    'MediaRemote\.framework'
    '/bin/(ba|z|k|c|tc)?sh'
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

# 2a. M6.1/M6.3 accepted one external compatibility-process architecture. Production
# Process use is allowed in exactly one reviewed file and nowhere else. Shipping M6.4
# composes this boundary but does not add another subprocess capability.
PRODUCTION_MEDIA_PROCESS_SOURCE="Sources/NotchHubMediaCore/MediaRemoteProcessClient.swift"
[[ -f "$PRODUCTION_MEDIA_PROCESS_SOURCE" ]] || \
    fail "missing reviewed production media process boundary"

PROCESS_MATCHES="$(grep -RIlE --include='*.swift' 'Process[[:space:]]*\(' Sources || true)"
if [[ "$PROCESS_MATCHES" != "$PRODUCTION_MEDIA_PROCESS_SOURCE" ]]; then
    printf '%s\n' "$PROCESS_MATCHES" >&2
    fail "Process() is permitted only in $PRODUCTION_MEDIA_PROCESS_SOURCE"
fi

PROCESS_COUNT="$(grep -Ec 'Process[[:space:]]*\(' "$PRODUCTION_MEDIA_PROCESS_SOURCE" || true)"
[[ "$PROCESS_COUNT" == "1" ]] || \
    fail "reviewed production media boundary must contain exactly one Process() construction"

grep -Fq 'URL(fileURLWithPath: "/usr/bin/perl")' "$PRODUCTION_MEDIA_PROCESS_SOURCE" || \
    fail "production media process executable is not fixed to /usr/bin/perl"
for required_token in '"stream"' '"--no-diff"' '"--micros"' '"capabilities"' '"send"' '"seek"' '"2"' '"4"' '"5"'; do
    grep -Fq "$required_token" "$PRODUCTION_MEDIA_PROCESS_SOURCE" || \
        fail "production media process allowlist is missing $required_token"
done

if grep -Eq '"get"|"get[[:space:]]' "$PRODUCTION_MEDIA_PROCESS_SOURCE"; then
    fail "production media process boundary must not use periodic get polling"
fi

# 3. No embedded private keys or common long-lived token formats in tracked files.
if git grep -nEI -- \
    '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{24,}' \
    -- ':!CHANGELOG.md' ':!docs/*' ':!SECURITY.md'; then
    fail "possible credential or private key material found in tracked files"
fi

# 4. Sandbox/entitlement contract is intentionally minimal.
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

# 6. No persistence helpers or privileged install surfaces.
for forbidden_path in LaunchAgents LaunchDaemons PrivilegedHelperTools; do
    if find . -path "*/$forbidden_path/*" -print -quit | grep -q .; then
        fail "unexpected persistence/privileged path found: $forbidden_path"
    fi
done

# 7. Workflow supply-chain and public-fork policy.
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

# 8. Release-tier security policy.
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

# 9. Performance tooling is development/release-only.
python3 scripts/performance_policy.py audit Sources || \
    fail "runtime performance policy violated"

if grep -RInE --include='*.swift' 'perf-baseline|performance_policy|test_performance_policy' Sources Resources 2>/dev/null; then
    fail "development performance tooling referenced by runtime/resources"
fi

if grep -InE 'perf-baseline|performance_policy|test_performance_policy' scripts/build-app.sh scripts/build-dmg.sh; then
    fail "application packaging must not copy or invoke development performance tooling"
fi

# 10. Universal Media probe remains development-only. The accepted production
# transport may now ship, but only through the exact M6.4 allowlisted composition.
PROBE_DIR="Tools/MediaBridgeProbe"
BOOTSTRAP="scripts/bootstrap-media-bridge-probe.sh"
PROBE_BUILD="scripts/build-media-bridge-probe-app.sh"
PROBE_VERIFY="scripts/verify-media-bridge-probe.sh"
PROBE_COMMIT="3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
PROBE_REPO="https://github.com/ungive/mediaremote-adapter.git"
SHIPPING_MEDIA_BUILD="scripts/build-app.sh"
SHIPPING_ADAPTER_COMMIT="3ac3d4bdf862c7b5399b4fba4df5689f5c38609a"
SHIPPING_RUNTIME_SOURCE="Sources/NotchHubMediaCore/ShippingMediaRuntime.swift"
SHIPPING_APP_DELEGATE="Sources/NotchHubApp/AppDelegate.swift"

for required in \
    "$PROBE_DIR/Core/ProbeProcess.swift" \
    "$BOOTSTRAP" \
    "$PROBE_BUILD" \
    "$PROBE_VERIFY" \
    "$SHIPPING_MEDIA_BUILD" \
    "$SHIPPING_RUNTIME_SOURCE" \
    "$SHIPPING_APP_DELEGATE"; do
    [[ -e "$required" ]] || fail "missing reviewed media boundary file: $required"
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

# 10a. Shipping may invoke the same reviewed bootstrap at build time and package only
# the pinned production script/framework/license/provenance. Development executables
# remain forbidden from the shipping composition.
grep -Fq "MEDIA_ADAPTER_COMMIT=\"$SHIPPING_ADAPTER_COMMIT\"" "$SHIPPING_MEDIA_BUILD" || \
    fail "shipping adapter revision is not pinned"
grep -Fq 'bootstrap-media-bridge-probe.sh' "$SHIPPING_MEDIA_BUILD" || \
    fail "shipping media build does not reuse reviewed pinned bootstrap"
grep -Fq 'mediaremote-adapter-capabilities.patch' "$SHIPPING_MEDIA_BUILD" || \
    fail "shipping media build does not bind the reviewed capability patch"
for required_asset in \
    'mediaremote-adapter.pl' \
    'MediaRemoteAdapter.framework' \
    'MediaRemoteAdapter-LICENSE.txt' \
    'media-transport-provenance.json'; do
    grep -Fq "$required_asset" "$SHIPPING_MEDIA_BUILD" || \
        fail "shipping media build is missing allowlisted asset: $required_asset"
done
for required_provenance in 'NHSourceCommit' 'NHAdapterCommit' 'NHAdapterPatchSHA256'; do
    grep -Fq "$required_provenance" "$SHIPPING_MEDIA_BUILD" || \
        fail "shipping media build is missing provenance key: $required_provenance"
done

grep -Fq 'ShippingMediaRuntime' "$SHIPPING_APP_DELEGATE" || \
    fail "shipping app does not own the media runtime lifecycle"
grep -Fq 'MediaRemoteAdapter.framework' "$SHIPPING_RUNTIME_SOURCE" || \
    fail "shipping runtime does not resolve the allowlisted framework"
grep -Fq 'mediaremote-adapter.pl' "$SHIPPING_RUNTIME_SOURCE" || \
    fail "shipping runtime does not resolve the allowlisted script"

if grep -Eq 'MediaTransportCandidate|ProductionMediaTransportCandidate|MediaRemoteAdapterTestClient|MediaBridgeProbe\.app' "$SHIPPING_MEDIA_BUILD"; then
    fail "shipping packaging references development-only media executables"
fi
if grep -Eq 'MediaTransportCandidate|ProductionMediaTransportCandidate|MediaRemoteAdapterTestClient|MediaBridgeProbe\.app' scripts/build-dmg.sh; then
    fail "DMG packaging references development-only media executables"
fi

# Runtime source must not invoke probe/test-client tooling or expand the process surface.
if grep -RInE --include='*.swift' 'MediaRemoteAdapterTestClient|MediaTransportCandidate|MediaBridgeProbe' Sources; then
    fail "shipping runtime references development-only media tooling"
fi

if grep -RInE \
    'com\.apple\.security\.cs\.(disable-library-validation|allow-unsigned-executable-memory|allow-dyld-environment-variables|allow-jit|get-task-allow)' \
    "$PROBE_DIR" "$PROBE_BUILD" "$PROBE_VERIFY" "$SHIPPING_MEDIA_BUILD" 2>/dev/null; then
    fail "media composition attempted to weaken Hardened Runtime"
fi

echo "Security baseline checks passed."
