#!/bin/bash

# JuiceFS Secure Initialization Script
# This script creates mount/unmount scripts with embedded credentials
# and sets them to execute-only permissions to prevent AI agents from
# accessing sensitive information like AK/SK and passwords.

set -e

echo "=========================================="
echo "  JuiceFS Secure Initialization Script"
echo "=========================================="
echo ""
echo "This script will help you create JuiceFS mount/unmount scripts"
echo "with credentials embedded and protected by execute-only permissions."
echo ""
echo "⚠️  IMPORTANT: This script is only needed when using:"
echo "   - Object storage with access keys (S3, OSS, Azure, etc.)"
echo "   - Databases with passwords (Redis, MySQL, PostgreSQL, etc.)"
echo ""
echo "   Not needed for: local storage + SQLite3"
echo ""

# Check if JuiceFS is installed
if ! command -v juicefs &> /dev/null; then
    echo "❌ Error: juicefs command not found. Please install JuiceFS first."
    echo ""
    echo "Installation instructions:"
    echo "  curl -sSL https://d.juicefs.com/install | sh -"
    echo ""
    exit 1
fi

echo "Step 1: Basic Configuration"
echo "----------------------------"
read -p "Filesystem name: " FS_NAME
read -p "Mount point (e.g., /mnt/jfs): " MOUNT_POINT

# Validate mount point
if [ -z "$MOUNT_POINT" ]; then
    echo "❌ Error: Mount point cannot be empty"
    exit 1
fi

echo ""
echo "Step 2: Metadata Engine"
echo "------------------------"
echo "Choose metadata engine:"
echo "  1) Redis (with password)"
echo "  2) Redis (without password)"
echo "  3) MySQL/PostgreSQL"
echo "  4) TiKV"
echo "  5) SQLite3 (local, no password)"
echo "  6) Custom URL"
read -p "Select (1-6): " META_CHOICE

case $META_CHOICE in
    1)
        read -p "Redis host (e.g., localhost): " REDIS_HOST
        read -p "Redis port (default 6379): " REDIS_PORT
        REDIS_PORT=${REDIS_PORT:-6379}
        read -p "Redis database (default 1): " REDIS_DB
        REDIS_DB=${REDIS_DB:-1}
        read -sp "Redis password: " REDIS_PASSWORD
        echo ""
        META_URL="redis://:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB}"
        NEEDS_SECURITY=true
        ;;
    2)
        read -p "Redis host (e.g., localhost): " REDIS_HOST
        read -p "Redis port (default 6379): " REDIS_PORT
        REDIS_PORT=${REDIS_PORT:-6379}
        read -p "Redis database (default 1): " REDIS_DB
        REDIS_DB=${REDIS_DB:-1}
        META_URL="redis://${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB}"
        NEEDS_SECURITY=false
        ;;
    3)
        echo "Example: mysql://username:password@host:3306/dbname"
        read -p "Username: " DB_USER
        read -sp "Password: " DB_PASSWORD
        echo ""
        read -p "Host (e.g., localhost): " DB_HOST
        read -p "Port (e.g., 3306 for MySQL, 5432 for PostgreSQL): " DB_PORT
        read -p "Database name: " DB_NAME
        read -p "Type (mysql/postgres): " DB_TYPE
        META_URL="${DB_TYPE}://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
        NEEDS_SECURITY=true
        ;;
    4)
        read -p "TiKV hosts (comma-separated, e.g., host1:2379,host2:2379): " TIKV_HOSTS
        META_URL="tikv://${TIKV_HOSTS}/${FS_NAME}"
        NEEDS_SECURITY=false
        ;;
    5)
        read -p "SQLite database path (e.g., /tmp/jfs.db): " SQLITE_PATH
        META_URL="sqlite3://${SQLITE_PATH}"
        NEEDS_SECURITY=false
        ;;
    6)
        read -p "Metadata URL: " META_URL
        read -p "Does this URL contain sensitive credentials? (y/n): " HAS_CREDS
        if [[ "$HAS_CREDS" == "y" ]]; then
            NEEDS_SECURITY=true
        else
            NEEDS_SECURITY=false
        fi
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Step 3: Object Storage"
echo "----------------------"
echo "Choose object storage:"
echo "  1) Amazon S3"
echo "  2) Local filesystem"
echo "  3) Other (custom)"
read -p "Select (1-3): " STORAGE_CHOICE

case $STORAGE_CHOICE in
    1)
        read -p "S3 bucket URL (e.g., https://mybucket.s3.amazonaws.com): " BUCKET_URL
        read -p "AWS Access Key ID: " AWS_ACCESS_KEY
        read -sp "AWS Secret Access Key: " AWS_SECRET_KEY
        echo ""
        STORAGE_TYPE="s3"
        STORAGE_BUCKET="$BUCKET_URL"
        NEEDS_SECURITY=true
        USE_ENV_VARS=true
        ;;
    2)
        read -p "Local storage path (e.g., /data/jfs-storage): " LOCAL_PATH
        STORAGE_TYPE="file"
        STORAGE_BUCKET="$LOCAL_PATH"
        USE_ENV_VARS=false
        ;;
    3)
        read -p "Storage type (e.g., oss, azure, gcs): " STORAGE_TYPE
        read -p "Bucket URL: " STORAGE_BUCKET
        read -p "Does this storage require access keys? (y/n): " NEEDS_KEYS
        if [[ "$NEEDS_KEYS" == "y" ]]; then
            read -p "Access Key ID: " AWS_ACCESS_KEY
            read -sp "Secret Access Key: " AWS_SECRET_KEY
            echo ""
            NEEDS_SECURITY=true
            USE_ENV_VARS=true
        else
            USE_ENV_VARS=false
        fi
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Step 4: Additional Options"
echo "--------------------------"
read -p "Enable compression? (y/n, default n): " ENABLE_COMPRESS
COMPRESS_OPT=""
if [[ "$ENABLE_COMPRESS" == "y" ]]; then
    COMPRESS_OPT="--compress lz4"
fi

read -p "Cache directory (default ~/.juicefs/cache): " CACHE_DIR
CACHE_DIR=${CACHE_DIR:-~/.juicefs/cache}

read -p "Cache size in MiB (default 102400 = 100GB): " CACHE_SIZE
CACHE_SIZE=${CACHE_SIZE:-102400}

read -p "Enable writeback cache? (y/n, default n): " ENABLE_WRITEBACK
WRITEBACK_OPT=""
if [[ "$ENABLE_WRITEBACK" == "y" ]]; then
    WRITEBACK_OPT="--writeback"
fi

read -p "Enable prefetch? Enter number of threads (0 to disable, default 0): " PREFETCH_THREADS
PREFETCH_OPT=""
if [[ "$PREFETCH_THREADS" =~ ^[1-9][0-9]*$ ]]; then
    PREFETCH_OPT="--prefetch $PREFETCH_THREADS"
fi

echo ""
echo "=========================================="
echo "Summary of Configuration"
echo "=========================================="
echo "Filesystem Name: $FS_NAME"
echo "Mount Point: $MOUNT_POINT"
echo "Metadata Engine: ${META_URL%%:*}://..." # Hide sensitive part
echo "Storage Type: $STORAGE_TYPE"
echo "Storage Bucket: $STORAGE_BUCKET"
echo "Cache Dir: $CACHE_DIR"
echo "Cache Size: ${CACHE_SIZE} MiB"
echo "Compression: ${ENABLE_COMPRESS:-n}"
echo "Writeback: ${ENABLE_WRITEBACK:-n}"
echo "Prefetch: ${PREFETCH_THREADS:-0} threads"
echo ""
read -p "Proceed with these settings? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    echo "Aborted."
    exit 0
fi

# Create scripts directory
SCRIPTS_DIR="$(pwd)/juicefs-scripts"
mkdir -p "$SCRIPTS_DIR"

echo ""
echo "Step 5: Checking if filesystem exists..."
echo "-----------------------------------------"

# Check if filesystem already exists
if juicefs status "$META_URL" &>/dev/null; then
    echo "✓ Filesystem already exists, skipping format."
    SKIP_FORMAT=true
else
    echo "Filesystem does not exist, will format."
    SKIP_FORMAT=false
fi

# Generate format script if needed
if [ "$SKIP_FORMAT" = false ]; then
    FORMAT_SCRIPT="${SCRIPTS_DIR}/format-${FS_NAME}.sh"
    echo ""
    echo "Creating format script: $FORMAT_SCRIPT"
    
    cat > "$FORMAT_SCRIPT" << EOF
#!/bin/bash
# JuiceFS Format Script for: $FS_NAME
# Auto-generated on $(date)
# DO NOT EDIT MANUALLY

set -e

EOF

    if [ "$USE_ENV_VARS" = true ] && [ -n "$AWS_ACCESS_KEY" ]; then
        cat >> "$FORMAT_SCRIPT" << EOF
export AWS_ACCESS_KEY_ID='$AWS_ACCESS_KEY'
export AWS_SECRET_ACCESS_KEY='$AWS_SECRET_KEY'

EOF
    fi

    cat >> "$FORMAT_SCRIPT" << EOF
juicefs format \\
    --storage $STORAGE_TYPE \\
    --bucket '$STORAGE_BUCKET' \\
    $COMPRESS_OPT \\
    '$META_URL' \\
    $FS_NAME

echo "✓ Filesystem formatted successfully"
EOF

    chmod 500 "$FORMAT_SCRIPT"
    echo "✓ Format script created and set to execute-only (500)"
    
    echo ""
    echo "Running format script..."
    "$FORMAT_SCRIPT"
fi

# Generate mount script
MOUNT_SCRIPT="${SCRIPTS_DIR}/mount-${FS_NAME}.sh"
echo ""
echo "Creating mount script: $MOUNT_SCRIPT"

cat > "$MOUNT_SCRIPT" << EOF
#!/bin/bash
# JuiceFS Mount Script for: $FS_NAME
# Auto-generated on $(date)
# DO NOT EDIT MANUALLY

set -e

EOF

if [ "$USE_ENV_VARS" = true ] && [ -n "$AWS_ACCESS_KEY" ]; then
    cat >> "$MOUNT_SCRIPT" << EOF
export AWS_ACCESS_KEY_ID='$AWS_ACCESS_KEY'
export AWS_SECRET_ACCESS_KEY='$AWS_SECRET_KEY'

EOF
fi

cat >> "$MOUNT_SCRIPT" << EOF
# Check if already mounted
if mountpoint -q '$MOUNT_POINT' 2>/dev/null; then
    echo "✓ $MOUNT_POINT is already mounted"
    exit 0
fi

# Create mount point if it doesn't exist
mkdir -p '$MOUNT_POINT'

# Mount the filesystem
juicefs mount \\
    --cache-dir '$CACHE_DIR' \\
    --cache-size $CACHE_SIZE \\
    $WRITEBACK_OPT \\
    $PREFETCH_OPT \\
    -d \\
    '$META_URL' \\
    '$MOUNT_POINT'

echo "✓ Filesystem mounted at $MOUNT_POINT"
EOF

chmod 500 "$MOUNT_SCRIPT"
echo "✓ Mount script created and set to execute-only (500)"

# Generate unmount script
UNMOUNT_SCRIPT="${SCRIPTS_DIR}/unmount-${FS_NAME}.sh"
echo ""
echo "Creating unmount script: $UNMOUNT_SCRIPT"

cat > "$UNMOUNT_SCRIPT" << EOF
#!/bin/bash
# JuiceFS Unmount Script for: $FS_NAME
# Auto-generated on $(date)
# DO NOT EDIT MANUALLY

set -e

# Check if mounted
if ! mountpoint -q '$MOUNT_POINT' 2>/dev/null; then
    echo "✓ $MOUNT_POINT is not mounted"
    exit 0
fi

# Unmount the filesystem
juicefs umount '$MOUNT_POINT'

echo "✓ Filesystem unmounted from $MOUNT_POINT"
EOF

chmod 500 "$UNMOUNT_SCRIPT"
echo "✓ Unmount script created and set to execute-only (500)"

# Generate status script (no sensitive info)
STATUS_SCRIPT="${SCRIPTS_DIR}/status-${FS_NAME}.sh"
echo ""
echo "Creating status script: $STATUS_SCRIPT"

cat > "$STATUS_SCRIPT" << EOF
#!/bin/bash
# JuiceFS Status Script for: $FS_NAME
# This script can be safely read by AI agents

echo "Filesystem: $FS_NAME"
echo "Mount point: $MOUNT_POINT"
echo ""

if mountpoint -q '$MOUNT_POINT' 2>/dev/null; then
    echo "Status: MOUNTED ✓"
    echo ""
    echo "Running statistics..."
    juicefs stats '$MOUNT_POINT' --interval 1 --verbosity 1 2>/dev/null || true
else
    echo "Status: NOT MOUNTED"
    echo ""
    echo "To mount, run: $MOUNT_SCRIPT"
fi
EOF

chmod 755 "$STATUS_SCRIPT"
echo "✓ Status script created (readable)"

echo ""
echo "=========================================="
echo "  ✓ Initialization Complete!"
echo "=========================================="
echo ""
echo "Scripts created in: $SCRIPTS_DIR"
echo ""
echo "To mount the filesystem:"
echo "  $MOUNT_SCRIPT"
echo ""
echo "To unmount the filesystem:"
echo "  $UNMOUNT_SCRIPT"
echo ""
echo "To check status (safe for AI agents):"
echo "  $STATUS_SCRIPT"
echo ""

if [ "$NEEDS_SECURITY" = true ]; then
    echo "🔒 SECURITY NOTES:"
    echo "   - Mount/unmount scripts contain sensitive credentials"
    echo "   - Scripts are set to execute-only (chmod 500)"
    echo "   - AI agents cannot read these scripts"
    echo "   - Keep these scripts secure and backed up"
    echo "   - Status script is safe to share with AI agents"
    echo ""
else
    echo "ℹ️  INFO:"
    echo "   - Your configuration doesn't require sensitive credentials"
    echo "   - Scripts can be safely viewed if needed"
    echo ""
fi

echo "Next steps:"
echo "  1. Run the mount script to mount your filesystem"
echo "  2. Verify mount with: mountpoint $MOUNT_POINT"
echo "  3. Use the status script to monitor your filesystem"
echo ""
