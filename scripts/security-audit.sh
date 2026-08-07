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
    Resources .github Sources Tests 2>/dev/null; then
    fail "dangerous code-signing/runtime exception found"
fi

# 6. No persistence helpers or privileged install surfaces at M0.
for forbidden_path in LaunchAgents LaunchDaemons PrivilegedHelperTools; do
    if find . -path "*/$forbidden_path/*" -print -quit | grep -q .; then
        fail "unexpected persistence/privileged path found: $forbidden_path"
    fi
done

# 7. Workflow supply-chain policy: external actions must be immutable full SHAs,
# and pull_request_target is prohibited for this repository.
python3 <<'PY'
from pathlib import Path
import re

workflow_dir = Path('.github/workflows')
errors = []
for path in sorted(workflow_dir.glob('*.y*ml')):
    text = path.read_text(encoding='utf-8')
    if 'pull_request_target:' in text:
        errors.append(f'{path}: pull_request_target is prohibited')
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

echo "Security baseline checks passed."
