#!/bin/bash

# Test script for juicefs-init.sh
# This validates the script structure and logic without requiring JuiceFS installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
INIT_SCRIPT="$REPO_DIR/scripts/juicefs-init.sh"

echo "=========================================="
echo "  Testing juicefs-init.sh"
echo "=========================================="
echo ""

# Test 1: Check if script exists and is executable
echo "Test 1: Checking script existence and permissions..."
if [ ! -f "$INIT_SCRIPT" ]; then
    echo "❌ FAIL: Script does not exist at $INIT_SCRIPT"
    exit 1
fi

if [ ! -x "$INIT_SCRIPT" ]; then
    echo "❌ FAIL: Script is not executable"
    exit 1
fi
echo "✓ PASS: Script exists and is executable"
echo ""

# Test 2: Check script has proper shebang
echo "Test 2: Checking shebang..."
FIRST_LINE=$(head -n 1 "$INIT_SCRIPT")
if [[ "$FIRST_LINE" != "#!/bin/bash" ]]; then
    echo "❌ FAIL: Script does not have proper shebang"
    exit 1
fi
echo "✓ PASS: Script has proper shebang"
echo ""

# Test 3: Check for required sections
echo "Test 3: Checking for required sections..."
REQUIRED_SECTIONS=(
    "Metadata Engine"
    "Object Storage"
    "Mount Options"
    "Summary of Configuration"
    "shc"
)

for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -q "$section" "$INIT_SCRIPT"; then
        echo "❌ FAIL: Missing required section: $section"
        exit 1
    fi
done
echo "✓ PASS: All required sections present"
echo ""

# Test 4: Check security features
echo "Test 4: Checking security features..."
SECURITY_FEATURES=(
    "shc"
    "NEEDS_SECURITY"
    "binary"
    "compile"
)

for feature in "${SECURITY_FEATURES[@]}"; do
    if ! grep -q "$feature" "$INIT_SCRIPT"; then
        echo "❌ FAIL: Missing security feature: $feature"
        exit 1
    fi
done
echo "✓ PASS: Security features present"
echo ""

# Test 5: Check for binary generation
echo "Test 5: Checking for binary generation logic..."
BINARY_FEATURES=(
    "WRAPPER_SCRIPT"
    "BINARY_PATH"
    "shc -f"
)

for feature in "${BINARY_FEATURES[@]}"; do
    if ! grep -q "$feature" "$INIT_SCRIPT"; then
        echo "❌ FAIL: Missing binary generation feature: $feature"
        exit 1
    fi
done

# Check that format is done inline, not as a script
if grep -q "Creating format script" "$INIT_SCRIPT"; then
    echo "❌ FAIL: Format script should not be generated (format should be inline)"
    exit 1
fi

# Check that wrapper can accept parameters
if ! grep -q '\$@' "$INIT_SCRIPT"; then
    echo "❌ FAIL: Wrapper should accept parameters (\$@)"
    exit 1
fi

echo "✓ PASS: Binary generation logic present"
echo ""

# Test 6: Check for metadata engine options
echo "Test 6: Checking metadata engine support..."
METADATA_ENGINES=(
    "Redis"
    "MySQL"
    "PostgreSQL"
    "TiKV"
    "SQLite"
)

for engine in "${METADATA_ENGINES[@]}"; do
    if ! grep -q "$engine" "$INIT_SCRIPT"; then
        echo "❌ FAIL: Missing metadata engine: $engine"
        exit 1
    fi
done
echo "✓ PASS: All metadata engines supported"
echo ""

# Test 7: Check for storage options
echo "Test 7: Checking storage options..."
STORAGE_OPTIONS=(
    "Amazon S3"
    "Local filesystem"
)

for storage in "${STORAGE_OPTIONS[@]}"; do
    if ! grep -q "$storage" "$INIT_SCRIPT"; then
        echo "❌ FAIL: Missing storage option: $storage"
        exit 1
    fi
done
echo "✓ PASS: Storage options present"
echo ""

# Test 8: Check for multi-user mode support
echo "Test 8: Checking multi-user mode support..."
MULTIUSER_FEATURES=(
    "Multi-user mode"
    "Single-user mode"
    "MULTIUSER_MODE"
    "AI_AGENT_USER"
    "chown root"
)

for feature in "${MULTIUSER_FEATURES[@]}"; do
    if ! grep -q "$feature" "$INIT_SCRIPT"; then
        echo "❌ FAIL: Missing multi-user feature: $feature"
        exit 1
    fi
done
echo "✓ PASS: Multi-user mode support present"
echo ""

# Test 9: Check for credential handling
echo "Test 9: Checking credential handling..."
CREDENTIAL_VARS=(
    "AWS_ACCESS_KEY"
    "AWS_SECRET_KEY"
    "REDIS_PASSWORD"
)

for var in "${CREDENTIAL_VARS[@]}"; do
    if ! grep -q "$var" "$INIT_SCRIPT"; then
        echo "❌ FAIL: Missing credential variable: $var"
        exit 1
    fi
done
echo "✓ PASS: Credential handling present"
echo ""

# Test 10: Check for binary verification
echo "Test 10: Checking binary verification..."
VERIFICATION_CHECKS=(
    "Verifying Binary"
    "Testing binary"
    "status"
)

for check in "${VERIFICATION_CHECKS[@]}"; do
    if ! grep -q "$check" "$INIT_SCRIPT"; then
        echo "❌ FAIL: Missing verification check: $check"
        exit 1
    fi
done
echo "✓ PASS: Binary verification present"
echo ""

# Test 11: Check for filesystem status check improvements
echo "Test 11: Checking filesystem status improvements..."
if ! grep -q "Filesystem.*already exists" "$INIT_SCRIPT"; then
    echo "❌ FAIL: Missing filesystem exists message"
    exit 1
fi
if ! grep -q "SKIP_FORMAT" "$INIT_SCRIPT"; then
    echo "❌ FAIL: Missing SKIP_FORMAT logic"
    exit 1
fi
echo "✓ PASS: Filesystem status checks present"
echo ""

# Test 12: Check for cleanup logic
echo "Test 12: Checking cleanup logic..."
CLEANUP_CHECKS=(
    "Cleaning up"
    "rm -f"
    ".x.c"
)

for check in "${CLEANUP_CHECKS[@]}"; do
    if ! grep -q "$check" "$INIT_SCRIPT"; then
        echo "❌ FAIL: Missing cleanup check: $check"
        exit 1
    fi
done
echo "✓ PASS: Cleanup logic present"
echo ""

# Test 13: Validate bash syntax
echo "Test 13: Validating bash syntax..."
if ! bash -n "$INIT_SCRIPT"; then
    echo "❌ FAIL: Script has syntax errors"
    exit 1
fi
echo "✓ PASS: Script syntax is valid"
echo ""

echo "=========================================="
echo "  ✓ All tests passed!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - Script exists and is executable"
echo "  - All required sections present"
echo "  - Security features implemented (shc compilation)"
echo "  - Binary generation logic correct"
echo "  - Metadata engines supported"
echo "  - Storage options available"
echo "  - Multi-user mode support implemented"
echo "  - Credential handling present"
echo "  - Binary verification implemented"
echo "  - Filesystem status checks improved"
echo "  - Cleanup logic present"
echo "  - Bash syntax valid"
echo ""
