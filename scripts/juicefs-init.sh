#!/bin/bash

# JuiceFS Secure Initialization Script
# This script creates mount/unmount scripts with embedded credentials
# and sets them to execute-only permissions to prevent AI agents from
# accessing sensitive information like AK/SK and passwords.
#
# SECURITY MODEL:
# - Multi-user mode (RECOMMENDED): Run as root/admin, creates scripts for AI agent user
# - Single-user mode (LIMITED): Same user runs init and AI agent, provides basic protection

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

# Determine deployment mode
echo "=========================================="
echo "  Security Mode Selection"
echo "=========================================="
echo ""
echo "Choose your deployment mode:"
echo ""
echo "1) Multi-user mode (RECOMMENDED - Proper isolation)"
echo "   - Run this script as root or admin user"
echo "   - Scripts will be owned by root, executable by AI agent user"
echo "   - AI agent user CANNOT read script contents"
echo "   - Provides true credential protection"
echo ""
echo "2) Single-user mode (LIMITED - Basic protection)"
echo "   - Run this script as the same user running AI agent"
echo "   - Scripts owned by you, chmod 500 (execute-only)"
echo "   - You CAN still read your own files if needed"
echo "   - Provides protection from accidental exposure, not from yourself"
echo ""
read -p "Select mode (1 or 2): " SECURITY_MODE

if [[ "$SECURITY_MODE" == "1" ]]; then
    echo ""
    echo "Multi-user mode selected."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo ""
        echo "⚠️  WARNING: Multi-user mode requires root privileges."
        echo "    Please run this script with sudo:"
        echo ""
        echo "    sudo ./scripts/juicefs-init.sh"
        echo ""
        exit 1
    fi
    
    # Ask for the AI agent user
    echo ""
    read -p "Enter the username that will run the AI agent: " AI_AGENT_USER
    
    # Validate user exists
    if ! id "$AI_AGENT_USER" &>/dev/null; then
        echo "❌ Error: User '$AI_AGENT_USER' does not exist"
        echo "   Please create the user first: useradd -m $AI_AGENT_USER"
        exit 1
    fi
    
    MULTIUSER_MODE=true
    echo "✓ Scripts will be created for user: $AI_AGENT_USER"
    
elif [[ "$SECURITY_MODE" == "2" ]]; then
    echo ""
    echo "Single-user mode selected."
    echo ""
    echo "⚠️  LIMITATION: Since you are both creating and running scripts,"
    echo "    you can always read the script contents if needed (you own them)."
    echo "    This provides protection from accidental exposure, but not from"
    echo "    intentional access. For true isolation, use multi-user mode."
    echo ""
    read -p "Continue with single-user mode? (y/n): " CONTINUE_SINGLE
    
    if [[ "$CONTINUE_SINGLE" != "y" ]]; then
        echo "Aborted."
        exit 0
    fi
    
    MULTIUSER_MODE=false
    AI_AGENT_USER=$(whoami)
    
else
    echo "❌ Invalid selection"
    exit 1
fi

echo ""

# Function to set secure permissions on generated scripts
set_secure_permissions() {
    local script_path="$1"
    local is_sensitive="$2"  # true for scripts with credentials, false for status scripts
    
    if [[ "$is_sensitive" == "true" ]]; then
        # Scripts with credentials - execute-only
        chmod 500 "$script_path"
        
        if [[ "$MULTIUSER_MODE" == "true" ]]; then
            # Multi-user mode: change ownership to root, set group to AI agent user's group
            # AI agent user can execute via group permissions
            AI_AGENT_GROUP=$(id -gn "$AI_AGENT_USER")
            chown root:"$AI_AGENT_GROUP" "$script_path"
            chmod 550 "$script_path"  # Owner (root) read+execute, group (AI agent) execute-only
            echo "✓ Script owned by root, executable by $AI_AGENT_USER (group $AI_AGENT_GROUP)"
        else
            # Single-user mode: owner only
            echo "✓ Script set to execute-only (chmod 500)"
            echo "   Note: You (the owner) can still change permissions if needed"
        fi
    else
        # Status script without credentials - readable
        chmod 755 "$script_path"
        
        if [[ "$MULTIUSER_MODE" == "true" ]]; then
            AI_AGENT_GROUP=$(id -gn "$AI_AGENT_USER")
            chown root:"$AI_AGENT_GROUP" "$script_path"
            echo "✓ Status script readable by all users"
        else
            echo "✓ Status script readable (chmod 755)"
        fi
    fi
}

# Function to find JuiceFS binary
find_juicefs() {
    # Check common installation paths
    local juicefs_paths=(
        "/usr/local/bin/juicefs"
        "/usr/bin/juicefs"
        "$HOME/.juicefs/bin/juicefs"
        "/opt/juicefs/juicefs"
    )
    
    # First try command in PATH
    if command -v juicefs &> /dev/null; then
        command -v juicefs
        return 0
    fi
    
    # Try common paths
    for path in "${juicefs_paths[@]}"; do
        if [ -x "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# Function to copy juicefs binary to system path
copy_to_system_path() {
    local source_path="$1"
    local target_path="/usr/local/bin/juicefs"
    
    echo ""
    echo "JuiceFS found at: $source_path"
    echo "This location may not be accessible when switching users (e.g., su root)."
    echo ""
    read -p "Copy to $target_path for system-wide access? (y/n): " COPY_CONFIRM
    
    if [[ "$COPY_CONFIRM" == "y" ]]; then
        if [ -w "/usr/local/bin" ]; then
            cp "$source_path" "$target_path" && chmod +x "$target_path"
            if [ $? -eq 0 ]; then
                echo "✓ Successfully copied to $target_path"
                echo "$target_path"
                return 0
            else
                echo "❌ Failed to copy. You may need to run with sudo."
                return 1
            fi
        else
            # Try with sudo
            echo "Copying requires elevated privileges..."
            sudo cp "$source_path" "$target_path" && sudo chmod +x "$target_path"
            if [ $? -eq 0 ]; then
                echo "✓ Successfully copied to $target_path"
                echo "$target_path"
                return 0
            else
                echo "❌ Failed to copy with sudo."
                return 1
            fi
        fi
    else
        echo "$source_path"
        return 0
    fi
}

# Function to offer installation
offer_installation() {
    echo "❌ JuiceFS client not found."
    echo ""
    read -p "Would you like to install JuiceFS now? (y/n): " INSTALL_CONFIRM
    
    if [[ "$INSTALL_CONFIRM" != "y" ]]; then
        echo "Installation skipped."
        return 1
    fi
    
    echo ""
    echo "Installing JuiceFS..."
    
    # Try standard installation script
    if curl -sSL https://d.juicefs.com/install | sh -; then
        echo "✓ JuiceFS installed successfully"
        # Try to find it again
        if command -v juicefs &> /dev/null; then
            command -v juicefs
            return 0
        elif [ -x "/usr/local/bin/juicefs" ]; then
            echo "/usr/local/bin/juicefs"
            return 0
        fi
    fi
    
    echo ""
    echo "❌ Automatic installation failed."
    echo ""
    echo "Possible reasons:"
    echo "  - Network connectivity issues"
    echo "  - Unsupported system architecture"
    echo "  - Insufficient permissions"
    echo ""
    echo "Please install manually:"
    echo "  1. Download from: https://github.com/juicedata/juicefs/releases/latest"
    echo "  2. Choose the correct binary for your system (linux-amd64, linux-arm64, etc.)"
    echo "  3. Extract and install:"
    echo "     tar -zxf juicefs-*.tar.gz"
    echo "     sudo install juicefs /usr/local/bin/"
    echo ""
    return 1
}

# Check if JuiceFS is installed
JUICEFS_BIN=$(find_juicefs)

if [ $? -ne 0 ]; then
    # Not found in common paths, offer installation
    JUICEFS_BIN=$(offer_installation)
    if [ $? -ne 0 ]; then
        echo "Cannot proceed without JuiceFS client."
        exit 1
    fi
else
    # Found, but check if it needs to be copied to system path
    if [[ "$JUICEFS_BIN" != "/usr/local/bin/juicefs" ]] && [[ "$JUICEFS_BIN" != "/usr/bin/juicefs" ]]; then
        # Binary is in user-specific location, suggest copying
        NEW_PATH=$(copy_to_system_path "$JUICEFS_BIN")
        if [ $? -eq 0 ] && [ -n "$NEW_PATH" ]; then
            JUICEFS_BIN="$NEW_PATH"
        fi
    fi
fi

echo "✓ Using JuiceFS at: $JUICEFS_BIN"
echo ""

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

# Create scripts directory early to check for existing scripts
SCRIPTS_DIR="$(pwd)/juicefs-scripts"

# Check for existing scripts for this filesystem
MOUNT_SCRIPT="${SCRIPTS_DIR}/mount-${FS_NAME}.sh"
UNMOUNT_SCRIPT="${SCRIPTS_DIR}/unmount-${FS_NAME}.sh"
STATUS_SCRIPT="${SCRIPTS_DIR}/status-${FS_NAME}.sh"
FORMAT_SCRIPT="${SCRIPTS_DIR}/format-${FS_NAME}.sh"

EXISTING_SCRIPTS=()
if [ -f "$MOUNT_SCRIPT" ]; then
    EXISTING_SCRIPTS+=("mount-${FS_NAME}.sh")
fi
if [ -f "$UNMOUNT_SCRIPT" ]; then
    EXISTING_SCRIPTS+=("unmount-${FS_NAME}.sh")
fi
if [ -f "$STATUS_SCRIPT" ]; then
    EXISTING_SCRIPTS+=("status-${FS_NAME}.sh")
fi
if [ -f "$FORMAT_SCRIPT" ]; then
    EXISTING_SCRIPTS+=("format-${FS_NAME}.sh")
fi

if [ ${#EXISTING_SCRIPTS[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  WARNING: Existing scripts found for filesystem '$FS_NAME':"
    for script in "${EXISTING_SCRIPTS[@]}"; do
        echo "   - $SCRIPTS_DIR/$script"
    done
    echo ""
    echo "These scripts will be overwritten with new configuration."
    echo ""
    read -p "Continue and overwrite existing scripts? (y/n): " OVERWRITE_CONFIRM
    
    if [[ "$OVERWRITE_CONFIRM" != "y" ]]; then
        echo "Aborted. No changes made."
        exit 0
    fi
    echo ""
    echo "Proceeding to overwrite existing scripts..."
fi

echo ""
echo "Step 3: Checking if filesystem exists..."
echo "-----------------------------------------"

# Check if filesystem already exists
if $JUICEFS_BIN status "$META_URL" &>/dev/null; then
    echo "✓ Filesystem '$FS_NAME' already exists"
    echo ""
    echo "Existing filesystem information:"
    $JUICEFS_BIN status "$META_URL" 2>/dev/null | head -20 || echo "  (Unable to retrieve details)"
    echo ""
    echo "ℹ️  Since the filesystem already exists:"
    echo "   - Storage credentials are already saved in metadata"
    echo "   - Format step will be skipped"
    echo "   - Only mount/unmount scripts will be generated"
    echo "   - You do NOT need to re-enter object storage credentials"
    echo ""
    SKIP_FORMAT=true
    SKIP_STORAGE_CONFIG=true
else
    echo "Filesystem '$FS_NAME' does not exist, will create format script."
    echo ""
    SKIP_FORMAT=false
    SKIP_STORAGE_CONFIG=false
fi

# Only ask for storage configuration if filesystem doesn't exist
if [ "$SKIP_STORAGE_CONFIG" = false ]; then
    echo ""
    echo "Step 4: Object Storage Configuration"
    echo "-------------------------------------"
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
else
    echo ""
    echo "Step 4: Object Storage Configuration"
    echo "-------------------------------------"
    echo "✓ Skipped (filesystem already exists, credentials already stored)"
fi

echo ""
echo "Step 5: Mount Options"
echo "---------------------"
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

if [ "$SKIP_STORAGE_CONFIG" = false ]; then
    echo "Storage Type: $STORAGE_TYPE"
    echo "Storage Bucket: $STORAGE_BUCKET"
else
    echo "Storage: (Using existing filesystem configuration)"
fi

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
mkdir -p "$SCRIPTS_DIR"

# Generate format script if needed
if [ "$SKIP_FORMAT" = false ]; then
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
# JuiceFS binary path
JUICEFS="$JUICEFS_BIN"

\$JUICEFS format \\
    --storage $STORAGE_TYPE \\
    --bucket '$STORAGE_BUCKET' \\
    $COMPRESS_OPT \\
    '$META_URL' \\
    $FS_NAME

echo "✓ Filesystem formatted successfully"
EOF

    set_secure_permissions "$FORMAT_SCRIPT" "true"
    
    echo ""
    echo "Running format script..."
    
    if [[ "$MULTIUSER_MODE" == "true" ]]; then
        # In multi-user mode, run as the AI agent user
        sudo -u "$AI_AGENT_USER" "$FORMAT_SCRIPT"
    else
        "$FORMAT_SCRIPT"
    fi
fi

# Generate mount script
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
# JuiceFS binary path
JUICEFS="$JUICEFS_BIN"

# Check if already mounted
if mountpoint -q '$MOUNT_POINT' 2>/dev/null; then
    echo "✓ $MOUNT_POINT is already mounted"
    exit 0
fi

# Create mount point if it doesn't exist
mkdir -p '$MOUNT_POINT'

# Mount the filesystem
\$JUICEFS mount \\
    --cache-dir '$CACHE_DIR' \\
    --cache-size $CACHE_SIZE \\
    $WRITEBACK_OPT \\
    $PREFETCH_OPT \\
    -d \\
    '$META_URL' \\
    '$MOUNT_POINT'

echo "✓ Filesystem mounted at $MOUNT_POINT"
EOF

set_secure_permissions "$MOUNT_SCRIPT" "true"

# Generate unmount script
echo ""
echo "Creating unmount script: $UNMOUNT_SCRIPT"

cat > "$UNMOUNT_SCRIPT" << EOF
#!/bin/bash
# JuiceFS Unmount Script for: $FS_NAME
# Auto-generated on $(date)
# DO NOT EDIT MANUALLY

set -e

# JuiceFS binary path
JUICEFS="$JUICEFS_BIN"

# Check if mounted
if ! mountpoint -q '$MOUNT_POINT' 2>/dev/null; then
    echo "✓ $MOUNT_POINT is not mounted"
    exit 0
fi

# Unmount the filesystem
\$JUICEFS umount '$MOUNT_POINT'

echo "✓ Filesystem unmounted from $MOUNT_POINT"
EOF

set_secure_permissions "$UNMOUNT_SCRIPT" "true"

# Generate status script (no sensitive info)
echo ""
echo "Creating status script: $STATUS_SCRIPT"

cat > "$STATUS_SCRIPT" << EOF
#!/bin/bash
# JuiceFS Status Script for: $FS_NAME
# This script can be safely read by AI agents

# JuiceFS binary path
JUICEFS="$JUICEFS_BIN"

echo "Filesystem: $FS_NAME"
echo "Mount point: $MOUNT_POINT"
echo ""

if mountpoint -q '$MOUNT_POINT' 2>/dev/null; then
    echo "Status: MOUNTED ✓"
    echo ""
    echo "Running statistics..."
    \$JUICEFS stats '$MOUNT_POINT' --interval 1 --verbosity 1 2>/dev/null || true
else
    echo "Status: NOT MOUNTED"
    echo ""
    echo "To mount, run: $MOUNT_SCRIPT"
fi
EOF

set_secure_permissions "$STATUS_SCRIPT" "false"

echo ""
echo "=========================================="
echo "  ✓ Initialization Complete!"
echo "=========================================="
echo ""

if [ "$SKIP_FORMAT" = true ]; then
    echo "Summary:"
    echo "  - Filesystem '$FS_NAME' already exists (no format needed)"
    echo "  - Mount/unmount/status scripts created/updated"
else
    echo "Summary:"
    echo "  - Filesystem '$FS_NAME' formatted successfully"
    echo "  - Mount/unmount/status scripts created"
fi

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
    
    if [[ "$MULTIUSER_MODE" == "true" ]]; then
        echo "   - Multi-user mode: Scripts owned by root, executable by $AI_AGENT_USER"
        echo "   - User '$AI_AGENT_USER' can execute but CANNOT read script contents"
        echo "   - This provides TRUE credential isolation"
        echo "   - Scripts location: $SCRIPTS_DIR"
    else
        echo "   - Single-user mode: Scripts owned by you, chmod 500"
        echo "   - You (owner) CAN still read scripts if you change permissions"
        echo "   - This provides protection from accidental exposure only"
        echo "   - For true isolation, consider running in multi-user mode with sudo"
    fi
    
    echo "   - Status script is safe to share with AI agents"
    echo ""
else
    echo "ℹ️  INFO:"
    echo "   - Your configuration doesn't require sensitive credentials"
    echo "   - Scripts can be safely viewed if needed"
    echo ""
fi

if [[ "$MULTIUSER_MODE" == "true" ]]; then
    echo "Next steps (as user $AI_AGENT_USER):"
    echo "  1. Switch to AI agent user: su - $AI_AGENT_USER"
    echo "  2. Run the mount script: $MOUNT_SCRIPT"
    echo "  3. Verify mount: mountpoint $MOUNT_POINT"
else
    echo "Next steps:"
    echo "  1. Run the mount script to mount your filesystem"
    echo "  2. Verify mount with: mountpoint $MOUNT_POINT"
    echo "  3. Use the status script to monitor your filesystem"
fi
echo ""
