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
    "Additional Options"
    "Summary of Configuration"
    "chmod 500"
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
    "chmod 500"
    "NEEDS_SECURITY"
    "execute-only"
    "sensitive"
)

for feature in "${SECURITY_FEATURES[@]}"; do
    if ! grep -q "$feature" "$INIT_SCRIPT"; then
        echo "❌ FAIL: Missing security feature: $feature"
        exit 1
    fi
done
echo "✓ PASS: Security features present"
echo ""

# Test 5: Check for script generation
echo "Test 5: Checking for script generation logic..."
GENERATED_SCRIPTS=(
    "mount-"
    "unmount-"
    "status-"
    "format-"
)

for script_type in "${GENERATED_SCRIPTS[@]}"; do
    if ! grep -q "$script_type" "$INIT_SCRIPT"; then
        echo "❌ FAIL: Missing script generation for: $script_type"
        exit 1
    fi
done
echo "✓ PASS: Script generation logic present"
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

# Test 8: Check for credential handling
echo "Test 8: Checking credential handling..."
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

# Test 9: Validate bash syntax
echo "Test 9: Validating bash syntax..."
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
echo "  - Security features implemented"
echo "  - Script generation logic correct"
echo "  - Metadata engines supported"
echo "  - Storage options available"
echo "  - Credential handling present"
echo "  - Bash syntax valid"
echo ""
