#!/bin/bash
#
# KubeAgentiX Debug - Security Validation Script
# Run this after building to verify security posture
#

set -e

IMAGE="${1:-kubeagentix-debug:test}"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        KubeAgentiX Debug - Security Validation               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Validating image: $IMAGE"
echo ""

PASS=0
FAIL=0

check() {
    local name="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$actual" == *"$expected"* ]]; then
        echo "✅ PASS: $name"
        ((PASS++))
    else
        echo "❌ FAIL: $name (expected: $expected, got: $actual)"
        ((FAIL++))
    fi
}

# Test 1: Non-root user
echo ""
echo "━━━ 1. User Validation ━━━"
USER_ID=$(docker run --rm "$IMAGE" id -u)
check "Running as non-root (UID 65532)" "65532" "$USER_ID"

# Test 2: No SUID/SGID binaries
echo ""
echo "━━━ 2. SUID/SGID Check ━━━"
SUID_COUNT=$(docker run --rm "$IMAGE" sh -c "find / -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | wc -l")
check "No SUID/SGID binaries" "0" "$SUID_COUNT"

# Test 3: Bash available
echo ""
echo "━━━ 3. Shell Verification ━━━"
BASH_VERSION=$(docker run --rm "$IMAGE" bash --version 2>&1 | head -1)
check "Bash shell available" "bash" "$BASH_VERSION"

# Test 4: Essential tools present
echo ""
echo "━━━ 4. Tool Availability ━━━"
for tool in curl dig ping ip ss nc mtr jq yq openssl htop ps; do
    TOOL_PATH=$(docker run --rm "$IMAGE" which "$tool" 2>/dev/null || echo "NOT_FOUND")
    check "Tool: $tool" "/" "$TOOL_PATH"
done

# Test 5: No listening ports
echo ""
echo "━━━ 5. Network Security ━━━"
LISTEN_PORTS=$(docker run --rm "$IMAGE" ss -tlnp 2>/dev/null | wc -l)
check "No listening ports" "1" "$LISTEN_PORTS"  # 1 = header only

# Test 6: Labels present
echo ""
echo "━━━ 6. Image Labels ━━━"
LABELS=$(docker inspect "$IMAGE" --format '{{json .Config.Labels}}' 2>/dev/null)
check "Security label: nonroot" "io.kubeagentix.security.nonroot" "$LABELS"
check "Security label: PSS profile" "io.kubeagentix.security.pss-profile" "$LABELS"

# Summary
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                     VALIDATION SUMMARY                       ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Passed: $PASS                                               "
echo "║  Failed: $FAIL                                               "
echo "╚══════════════════════════════════════════════════════════════╝"

if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "⚠️  Some checks failed. Review the output above."
    exit 1
else
    echo ""
    echo "✅ All security validations passed!"
    exit 0
fi
