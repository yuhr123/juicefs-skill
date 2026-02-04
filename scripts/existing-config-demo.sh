#!/bin/bash

# Demo: Handling Existing JuiceFS Configurations
# This demonstrates the improved behavior when re-running the init script

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║         Demo: Handling Existing JuiceFS Configurations                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

cat << 'EOF'

## The Problem (Original Implementation)

When re-running the initialization script:
❌ No check for existing scripts
❌ Would overwrite scripts without warning
❌ Would try to format already-formatted filesystem
❌ No clear feedback about what's being updated

User experience:
  $ ./scripts/juicefs-init.sh
  # ... goes through all prompts again
  # Silently overwrites existing scripts
  # May fail trying to format existing filesystem


## The Solution (Improved Implementation)

### Feature 1: Check for Existing Scripts

Before creating scripts, check if they already exist:

┌─────────────────────────────────────────────────────────────┐
│ $ ./scripts/juicefs-init.sh                                 │
│ # After providing filesystem name: "prod-data"              │
│                                                             │
│ ⚠️  WARNING: Existing scripts found for filesystem 'prod-data': │
│    - ./juicefs-scripts/mount-prod-data.sh                  │
│    - ./juicefs-scripts/unmount-prod-data.sh                │
│    - ./juicefs-scripts/status-prod-data.sh                 │
│                                                             │
│ These scripts will be overwritten with new configuration.   │
│                                                             │
│ Continue and overwrite existing scripts? (y/n):            │
└─────────────────────────────────────────────────────────────┘

**Benefits:**
✓ User is aware of existing scripts
✓ Can abort if unintentional
✓ Clear about what will be overwritten
✓ Safe confirmation before proceeding


### Feature 2: Detect Existing Filesystem

Check if filesystem is already formatted:

┌─────────────────────────────────────────────────────────────┐
│ Step 5: Checking if filesystem exists...                    │
│ ---------------------------------------------------------   │
│ ✓ Filesystem 'prod-data' already exists                    │
│                                                             │
│ Existing filesystem information:                           │
│   Name: prod-data                                          │
│   UUID: abcd-1234-efgh-5678                               │
│   Storage: s3                                              │
│   Bucket: mybucket.s3.amazonaws.com                       │
│   ...                                                      │
│                                                             │
│ ℹ️  Format step will be skipped.                            │
│    Mount/unmount scripts will be regenerated.              │
└─────────────────────────────────────────────────────────────┘

**Benefits:**
✓ Shows existing filesystem details
✓ Skips unnecessary format operation
✓ Clear about what will happen
✓ Safe - won't re-format existing data


### Feature 3: Improved Summary

After completion, clear summary of what happened:

┌─────────────────────────────────────────────────────────────┐
│ ========================================                    │
│   ✓ Initialization Complete!                               │
│ ========================================                    │
│                                                             │
│ Summary:                                                   │
│   - Filesystem 'prod-data' already exists (no format needed)│
│   - Mount/unmount/status scripts created/updated          │
│                                                             │
│ Scripts created in: ./juicefs-scripts                      │
│                                                             │
│ To mount the filesystem:                                   │
│   ./juicefs-scripts/mount-prod-data.sh                    │
│ ...                                                        │
└─────────────────────────────────────────────────────────────┘

**Benefits:**
✓ Clear about format skipped vs created
✓ User knows what changed
✓ Confidence in re-running script


## Use Cases

### Use Case 1: Update Mount Options

Scenario: Change cache size from 100GB to 200GB

```bash
# Initial setup (cache: 100GB)
$ ./scripts/juicefs-init.sh
Filesystem: prod-data
Cache size: 100GB
# Scripts created

# Later, want to increase cache
$ ./scripts/juicefs-init.sh
Filesystem: prod-data

⚠️  WARNING: Existing scripts found...
Continue? y

✓ Filesystem already exists
# Shows existing filesystem info
Format step skipped

Cache size: 200GB (new value)

Summary:
  - Filesystem 'prod-data' already exists (no format needed)
  - Mount/unmount/status scripts created/updated
```

**Result:**
- Scripts regenerated with new cache size
- Filesystem not touched
- Safe and clear process


### Use Case 2: Fix Typo in Mount Point

Scenario: Typo in mount point path, need to fix

```bash
# Initial setup (typo: /mtn/jfs instead of /mnt/jfs)
$ ./scripts/juicefs-init.sh
Mount point: /mtn/jfs  # Typo!
# Scripts created with wrong path

# Realize mistake, re-run
$ ./scripts/juicefs-init.sh

⚠️  WARNING: Existing scripts found...
Continue? y

Mount point: /mnt/jfs  # Correct path

✓ Filesystem already exists
Format step skipped

Scripts regenerated with correct mount point
```


### Use Case 3: Accidental Re-run

Scenario: Accidentally run script again

```bash
$ ./scripts/juicefs-init.sh

⚠️  WARNING: Existing scripts found for filesystem 'prod-data':
   - ./juicefs-scripts/mount-prod-data.sh
   - ./juicefs-scripts/unmount-prod-data.sh
   - ./juicefs-scripts/status-prod-data.sh

Continue and overwrite existing scripts? (y/n): n

Aborted. No changes made.
```

**Result:**
- User can abort safely
- No accidental overwrite
- Existing scripts preserved


## Comparison Table

┌──────────────────────┬────────────────────┬─────────────────────┐
│ Scenario             │ Original Behavior  │ Improved Behavior   │
├──────────────────────┼────────────────────┼─────────────────────┤
│ Existing scripts     │ Silent overwrite   │ Warn & confirm      │
│ Existing filesystem  │ Try to format      │ Skip format, show   │
│                      │ (may fail)         │ info                │
│ Re-run accidentally  │ Overwrites scripts │ Can abort safely    │
│ Update config        │ Not clear what     │ Clear what changed  │
│                      │ changed            │                     │
│ User feedback        │ Minimal            │ Comprehensive       │
└──────────────────────┴────────────────────┴─────────────────────┘


## Technical Implementation

### Check for Existing Scripts
```bash
EXISTING_SCRIPTS=()
if [ -f "$MOUNT_SCRIPT" ]; then
    EXISTING_SCRIPTS+=("mount-${FS_NAME}.sh")
fi
# ... check others ...

if [ ${#EXISTING_SCRIPTS[@]} -gt 0 ]; then
    echo "⚠️  WARNING: Existing scripts found..."
    read -p "Continue? (y/n): " CONFIRM
    if [[ "$CONFIRM" != "y" ]]; then
        exit 0
    fi
fi
```

### Check for Existing Filesystem
```bash
if juicefs status "$META_URL" &>/dev/null; then
    echo "✓ Filesystem already exists"
    juicefs status "$META_URL" | head -20
    echo "Format step will be skipped"
    SKIP_FORMAT=true
else
    SKIP_FORMAT=false
fi
```

### Improved Summary
```bash
if [ "$SKIP_FORMAT" = true ]; then
    echo "Summary:"
    echo "  - Filesystem already exists (no format needed)"
    echo "  - Scripts created/updated"
else
    echo "Summary:"
    echo "  - Filesystem formatted successfully"
    echo "  - Scripts created"
fi
```


## Benefits

✓ **Safe re-running**: Can update configuration without risk
✓ **Clear feedback**: User knows exactly what's happening
✓ **No data loss**: Won't re-format existing filesystem
✓ **Idempotent**: Safe to run multiple times
✓ **User control**: Can abort before overwriting
✓ **Informative**: Shows existing filesystem details


## Testing

Added comprehensive tests:
- Test 10: Check existing scripts detection
- Test 11: Check filesystem status improvements
- Test 12: Validate bash syntax

All 12 tests passing ✓

EOF

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Implementation Complete ✓                                   ║"
echo "║                                                              ║"
echo "║  The initialization script now properly handles:            ║"
echo "║  - Existing scripts (with confirmation)                     ║"
echo "║  - Existing filesystems (skip format)                       ║"
echo "║  - Safe re-running (idempotent)                            ║"
echo "║  - Clear feedback (what changed)                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
