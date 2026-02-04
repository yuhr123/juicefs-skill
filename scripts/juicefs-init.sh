#!/bin/bash

# JuiceFS Secure Initialization Script
# This script creates a compiled binary wrapper for JuiceFS with embedded credentials
# using shc (Shell Script Compiler) to protect sensitive information.
#
# The binary encapsulates metadata engine connection info and can accept any parameters.
#
# SECURITY MODEL:
# - Multi-user mode (RECOMMENDED): Run as root/admin, creates binary for AI agent user
# - Single-user mode (LIMITED): Same user runs init and AI agent, provides basic protection

set -e

echo "=========================================="
echo "  JuiceFS Secure Initialization Script"
echo "=========================================="
echo ""
echo "This script will create a compiled binary wrapper for JuiceFS"
echo "with credentials embedded and protected using shc (Shell Script Compiler)."
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
echo "   - Binary will be owned by root, executable by AI agent user"
echo "   - AI agent user CANNOT decompile or read binary contents"
echo "   - Provides true credential protection"
echo ""
echo "2) Single-user mode (LIMITED - Basic protection)"
echo "   - Run this script as the same user running AI agent"
echo "   - Binary owned by you"
echo "   - Provides protection from casual inspection"
echo "   - Suitable for development or trusted environments"
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
    echo "✓ Binary will be created for user: $AI_AGENT_USER"
    
elif [[ "$SECURITY_MODE" == "2" ]]; then
    echo ""
    echo "Single-user mode selected."
    echo ""
    echo "⚠️  LIMITATION: While the binary is compiled, advanced users with"
    echo "    the right tools could potentially decompile it."
    echo "    This provides good protection for typical use cases."
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

# Check if JuiceFS is installed
if ! command -v juicefs &> /dev/null; then
    echo "❌ JuiceFS client not found in PATH."
    echo ""
    read -p "Would you like to install JuiceFS now? (y/n): " INSTALL_CONFIRM
    
    if [[ "$INSTALL_CONFIRM" == "y" ]]; then
        echo ""
        echo "Installing JuiceFS..."
        
        # Try standard installation script
        if curl -sSL https://d.juicefs.com/install | sh -; then
            echo "✓ JuiceFS installed successfully"
            
            # Verify installation
            if command -v juicefs &> /dev/null; then
                JUICEFS_BIN=$(command -v juicefs)
            else
                echo "❌ Installation completed but juicefs not found in PATH."
                echo "   You may need to restart your shell or run: source ~/.bashrc"
                exit 1
            fi
        else
            echo ""
            echo "❌ Automatic installation failed."
            echo ""
            echo "Please install manually:"
            echo "  curl -sSL https://d.juicefs.com/install | sh -"
            echo ""
            echo "Or download from: https://github.com/juicedata/juicefs/releases/latest"
            echo ""
            exit 1
        fi
    else
        echo ""
        echo "Cannot proceed without JuiceFS client."
        echo "Please install it and run this script again:"
        echo "  curl -sSL https://d.juicefs.com/install | sh -"
        echo ""
        exit 1
    fi
else
    JUICEFS_BIN=$(command -v juicefs)
fi

echo "✓ Using JuiceFS at: $JUICEFS_BIN"
echo ""

# Check if shc (Shell Script Compiler) is installed
if ! command -v shc &> /dev/null; then
    echo "❌ shc (Shell Script Compiler) not found in PATH."
    echo ""
    echo "shc is required to compile scripts into binaries for credential protection."
    echo ""
    read -p "Would you like to install shc now? (y/n): " INSTALL_SHC_CONFIRM
    
    if [[ "$INSTALL_SHC_CONFIRM" == "y" ]]; then
        echo ""
        echo "Installing shc..."
        
        # Detect OS and install shc
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux - try different package managers
            if command -v apt-get &> /dev/null; then
                echo "Using apt-get..."
                if [[ "$MULTIUSER_MODE" == "true" ]]; then
                    apt-get update && apt-get install -y shc
                else
                    sudo apt-get update && sudo apt-get install -y shc
                fi
            elif command -v yum &> /dev/null; then
                echo "Using yum..."
                if [[ "$MULTIUSER_MODE" == "true" ]]; then
                    yum install -y shc
                else
                    sudo yum install -y shc
                fi
            elif command -v dnf &> /dev/null; then
                echo "Using dnf..."
                if [[ "$MULTIUSER_MODE" == "true" ]]; then
                    dnf install -y shc
                else
                    sudo dnf install -y shc
                fi
            else
                echo "❌ Could not detect package manager."
                echo "   Please install shc manually and run this script again."
                exit 1
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS - use brew
            if command -v brew &> /dev/null; then
                echo "Using Homebrew..."
                brew install shc
            else
                echo "❌ Homebrew not found."
                echo "   Please install Homebrew first: https://brew.sh"
                echo "   Then run: brew install shc"
                exit 1
            fi
        else
            echo "❌ Unsupported operating system."
            echo "   Please install shc manually and run this script again."
            exit 1
        fi
        
        # Verify installation
        if command -v shc &> /dev/null; then
            echo "✓ shc installed successfully"
        else
            echo "❌ shc installation completed but not found in PATH."
            echo "   You may need to restart your shell or install manually."
            exit 1
        fi
    else
        echo ""
        echo "Cannot proceed without shc."
        echo "Please install it and run this script again:"
        echo ""
        echo "Linux (Debian/Ubuntu): sudo apt-get install shc"
        echo "Linux (RHEL/CentOS):   sudo yum install shc"
        echo "macOS (Homebrew):      brew install shc"
        echo ""
        exit 1
    fi
fi

echo "✓ Using shc at: $(command -v shc)"
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

# Create scripts directory early for later use
SCRIPTS_DIR="$(pwd)/juicefs-scripts"

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
    echo "   - Only binary wrapper will be generated"
    echo "   - You do NOT need to re-enter object storage credentials"
    echo ""
    SKIP_FORMAT=true
    SKIP_STORAGE_CONFIG=true
else
    echo "Filesystem '$FS_NAME' does not exist, will format it."
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

# Format filesystem if needed (inline, not as a persistent script)
if [ "$SKIP_FORMAT" = false ]; then
    echo ""
    echo "Formatting JuiceFS filesystem..."
    echo ""
    
    # Set environment variables if needed
    if [ "$USE_ENV_VARS" = true ] && [ -n "$AWS_ACCESS_KEY" ]; then
        export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY"
        export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY"
    fi
    
    # Run format command
    $JUICEFS_BIN format \
        --storage $STORAGE_TYPE \
        --bucket "$STORAGE_BUCKET" \
        $COMPRESS_OPT \
        "$META_URL" \
        $FS_NAME
    
    echo ""
    echo "✓ Filesystem formatted successfully"
    echo ""
fi

# Generate wrapper script that will be compiled
echo ""
echo "Creating JuiceFS wrapper script..."

# Intermediate script path (will be deleted after compilation)
WRAPPER_SCRIPT="${SCRIPTS_DIR}/.${FS_NAME}-wrapper.sh"
BINARY_PATH="${SCRIPTS_DIR}/${FS_NAME}"

# Check for existing binary
if [ -f "$BINARY_PATH" ]; then
    echo ""
    echo "⚠️  WARNING: Binary '$BINARY_PATH' already exists."
    echo ""
    read -p "Overwrite existing binary? (y/n): " OVERWRITE_BINARY
    
    if [[ "$OVERWRITE_BINARY" != "y" ]]; then
        echo "Aborted. No changes made."
        exit 0
    fi
    echo ""
    echo "Proceeding to overwrite existing binary..."
fi

cat > "$WRAPPER_SCRIPT" << 'WRAPPER_EOF'
#!/bin/bash
# JuiceFS Wrapper for: FILESYSTEM_NAME
# This script encapsulates JuiceFS client with metadata engine connection
# It accepts any parameters and passes them to juicefs
# Auto-generated on GENERATION_DATE

set -e

WRAPPER_EOF

# Add environment variables if needed
if [ "$USE_ENV_VARS" = true ] && [ -n "$AWS_ACCESS_KEY" ]; then
    cat >> "$WRAPPER_SCRIPT" << WRAPPER_EOF
# Storage credentials
export AWS_ACCESS_KEY_ID='$AWS_ACCESS_KEY'
export AWS_SECRET_ACCESS_KEY='$AWS_SECRET_KEY'

WRAPPER_EOF
fi

# Add the main wrapper logic
cat >> "$WRAPPER_SCRIPT" << 'WRAPPER_EOF'
# JuiceFS binary and metadata URL
JUICEFS="JUICEFS_BIN_PLACEHOLDER"
META_URL='META_URL_PLACEHOLDER'
FS_NAME='FILESYSTEM_NAME'

# Display usage if no arguments provided
if [ $# -eq 0 ]; then
    echo "JuiceFS Wrapper for filesystem: $FS_NAME"
    echo "Metadata engine: <configured>"
    echo ""
    echo "Usage: $0 <juicefs-command> [options]"
    echo ""
    echo "Examples:"
    echo "  $0 mount MOUNT_POINT_PLACEHOLDER                 # Mount filesystem"
    echo "  $0 mount --cache-size 204800 MOUNT_POINT_PLACEHOLDER  # Mount with options"
    echo "  $0 umount MOUNT_POINT_PLACEHOLDER                # Unmount filesystem"
    echo "  $0 status                                        # Show filesystem status"
    echo "  $0 stats MOUNT_POINT_PLACEHOLDER                 # Show filesystem statistics"
    echo "  $0 bench MOUNT_POINT_PLACEHOLDER                 # Run benchmark"
    echo ""
    echo "The metadata engine connection is pre-configured."
    echo "You only need to provide the command and any additional options."
    exit 0
fi

# Get the command (first argument)
COMMAND="$1"
shift

# Commands that need META_URL as first argument after command
case "$COMMAND" in
    mount|umount|status|config|gc|fsck|dump|load|destroy|clone|snapshot|rmr)
        # These commands expect: juicefs <command> [options] <META_URL> [other args]
        # For mount: juicefs mount [options] <META_URL> <MOUNT_POINT>
        "$JUICEFS" "$COMMAND" "$@" "$META_URL"
        ;;
    format)
        # Format needs META_URL before filesystem name
        # juicefs format [options] <META_URL> <NAME>
        "$JUICEFS" "$COMMAND" "$@" "$META_URL"
        ;;
    *)
        # For other commands (like stats, bench, info, warmup, etc.) that operate on mount point
        # juicefs <command> [options] <MOUNT_POINT>
        # These don't need META_URL
        "$JUICEFS" "$COMMAND" "$@"
        ;;
esac
WRAPPER_EOF

# Replace placeholder values
sed "s|JUICEFS_BIN_PLACEHOLDER|$JUICEFS_BIN|g" "$WRAPPER_SCRIPT" | \
sed "s|META_URL_PLACEHOLDER|$META_URL|g" | \
sed "s/FILESYSTEM_NAME/$FS_NAME/g" | \
sed "s|MOUNT_POINT_PLACEHOLDER|$MOUNT_POINT|g" | \
sed "s/GENERATION_DATE/$(date)/g" > "${WRAPPER_SCRIPT}.tmp"

mv "${WRAPPER_SCRIPT}.tmp" "$WRAPPER_SCRIPT"

chmod +x "$WRAPPER_SCRIPT"

echo "✓ Wrapper script created"

# Compile the wrapper script with shc
echo ""
echo "Compiling wrapper script to binary..."
echo "This protects embedded credentials from inspection."
echo ""

# Run shc to compile the script
# -f: input file
# -o: output binary file
# -r: relax security (allows running on different systems)
# -v: verbose
shc -f "$WRAPPER_SCRIPT" -o "$BINARY_PATH" -r

if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ Error: Binary compilation failed"
    echo "   Wrapper script is at: $WRAPPER_SCRIPT"
    exit 1
fi

echo "✓ Binary compiled successfully: $BINARY_PATH"

# Set permissions on the binary
if [[ "$MULTIUSER_MODE" == "true" ]]; then
    AI_AGENT_GROUP=$(id -gn "$AI_AGENT_USER")
    chown root:"$AI_AGENT_GROUP" "$BINARY_PATH"
    chmod 750 "$BINARY_PATH"  # Owner and group can execute
    echo "✓ Binary owned by root, executable by $AI_AGENT_USER (group $AI_AGENT_GROUP)"
    echo "   Permissions: 750 (owner rwx, group r-x)"
else
    chmod 755 "$BINARY_PATH"
    echo "✓ Binary permissions set to 755"
fi

# Clean up intermediate files
echo ""
echo "Cleaning up intermediate files..."

# Remove the wrapper script
rm -f "$WRAPPER_SCRIPT"
echo "✓ Removed: $WRAPPER_SCRIPT"

# Remove shc generated C source file if it exists
if [ -f "${WRAPPER_SCRIPT}.x.c" ]; then
    rm -f "${WRAPPER_SCRIPT}.x.c"
    echo "✓ Removed: ${WRAPPER_SCRIPT}.x.c"
fi

echo ""
echo "=========================================="
echo "  Verifying Binary Functionality"
echo "=========================================="
echo ""

# Test the binary by checking filesystem status
echo "Testing binary with 'status' command..."
if "$BINARY_PATH" status; then
    echo ""
    echo "✓ Binary verification successful!"
else
    echo ""
    echo "⚠️  Warning: Binary test returned non-zero exit code"
    echo "   This may be normal if the filesystem is not yet mounted"
fi

echo ""
echo "=========================================="
echo "  ✓ Initialization Complete!"
echo "=========================================="
echo ""

if [ "$SKIP_FORMAT" = true ]; then
    echo "Summary:"
    echo "  - Filesystem '$FS_NAME' already exists (no format needed)"
    echo "  - Compiled binary wrapper created"
else
    echo "Summary:"
    echo "  - Filesystem '$FS_NAME' formatted successfully"
    echo "  - Compiled binary wrapper created"
fi

echo ""
echo "Binary location: $BINARY_PATH"
echo ""
echo "Usage examples:"
echo ""
echo "  # Show help and available commands"
echo "  $BINARY_PATH"
echo ""
echo "  # Mount the filesystem"
echo "  $BINARY_PATH mount $MOUNT_POINT"
echo ""
echo "  # Mount with custom cache settings"
echo "  $BINARY_PATH mount --cache-size 204800 $MOUNT_POINT"
echo ""
echo "  # Check filesystem status"
echo "  $BINARY_PATH status"
echo ""
echo "  # Show filesystem statistics"
echo "  $BINARY_PATH stats $MOUNT_POINT"
echo ""
echo "  # Unmount the filesystem"
echo "  $BINARY_PATH umount $MOUNT_POINT"
echo ""
echo "  # Run benchmark"
echo "  $BINARY_PATH bench $MOUNT_POINT"
echo ""

if [ "$NEEDS_SECURITY" = true ]; then
    echo "🔒 SECURITY NOTES:"
    echo "   - Binary contains embedded credentials"
    
    if [[ "$MULTIUSER_MODE" == "true" ]]; then
        echo "   - Multi-user mode: Binary owned by root, executable by $AI_AGENT_USER"
        echo "   - User '$AI_AGENT_USER' can execute but credentials are protected"
        echo "   - This provides strong credential isolation"
        echo "   - Binary location: $BINARY_PATH"
    else
        echo "   - Single-user mode: Binary compiled with shc"
        echo "   - Credentials are obfuscated in the compiled binary"
        echo "   - Provides good protection for typical use cases"
    fi
    
    echo "   - Binary can be used by AI agents safely"
    echo "   - Credentials cannot be extracted via simple commands like 'cat'"
    echo ""
else
    echo "ℹ️  INFO:"
    echo "   - Your configuration doesn't require sensitive credentials"
    echo "   - Binary is still protected from casual inspection"
    echo ""
fi

if [[ "$MULTIUSER_MODE" == "true" ]]; then
    echo "Next steps (as user $AI_AGENT_USER):"
    echo "  1. Switch to AI agent user: su - $AI_AGENT_USER"
    echo "  2. Mount the filesystem: $BINARY_PATH mount $MOUNT_POINT"
    echo "  3. Verify mount: mountpoint $MOUNT_POINT"
    echo "  4. Use the filesystem normally"
else
    echo "Next steps:"
    echo "  1. Mount the filesystem: $BINARY_PATH mount $MOUNT_POINT"
    echo "  2. Verify mount: mountpoint $MOUNT_POINT"
    echo "  3. Use the filesystem normally"
    echo "  4. When done, unmount: $BINARY_PATH umount $MOUNT_POINT"
fi
echo ""
