# JuiceFS Secure Initialization Scripts

This directory contains scripts to help you securely set up JuiceFS in AI agent environments.

## Overview

When working with JuiceFS and AI agents, it's important to prevent sensitive credentials (access keys, passwords) from being exposed to the AI model. These scripts help you create mount/unmount scripts with embedded credentials that are protected by execute-only permissions.

## Scripts

### `juicefs-init.sh`

Interactive initialization script that:
- Prompts for JuiceFS configuration (metadata engine, object storage, credentials)
- Formats the filesystem if needed
- Generates mount, unmount, and status scripts
- Sets appropriate permissions (execute-only for scripts with credentials)

### `test-init.sh`

Test script that validates the initialization script:
- Checks script structure and syntax
- Verifies security features are present
- Validates script generation logic
- Tests metadata engine and storage support

## Usage

### 1. Run the Initialization Script

```bash
./scripts/juicefs-init.sh
```

**JuiceFS Installation:**
- The script checks if JuiceFS is in your PATH
- If not found, it offers to install it automatically
- Installation uses the standard JuiceFS installation script

Follow the interactive prompts to configure:
- Filesystem name
- Mount point
- Metadata engine (Redis, MySQL, PostgreSQL, TiKV, SQLite)
- Object storage (S3, local, etc.)
- Cache settings
- Performance options

**Smart credential handling:**
- If the filesystem already exists, the script detects it early
- You do NOT need to re-enter object storage credentials (AK/SK)
- Storage credentials are already saved in the metadata engine
- Only mount options need to be configured

**Re-running the script:**
- If scripts already exist for the same filesystem name, you'll be prompted to confirm overwrite
- The script checks if the filesystem is already formatted and skips formatting if it exists
- For existing filesystems, storage credential prompts are skipped automatically
- You can safely re-run the script to regenerate mount/unmount scripts with updated configuration

### 2. Generated Scripts

The initialization script creates a `juicefs-scripts/` directory with:

- **`format-<name>.sh`** - Formats the filesystem (only created if needed)
  - Permissions: 500 (execute-only)
  - Contains: Storage credentials and metadata connection
  - Not created if filesystem already exists
  
- **`mount-<name>.sh`** - Mounts the filesystem
  - Permissions: 500 (execute-only)
  - Contains: All credentials and mount options
  - Checks if already mounted before attempting mount
  
- **`unmount-<name>.sh`** - Unmounts the filesystem
  - Permissions: 500 (execute-only)
  - Contains: Mount point information
  - Checks if mounted before attempting unmount
  
- **`status-<name>.sh`** - Checks filesystem status
  - Permissions: 755 (readable)
  - Safe for AI agents - no credentials

### 3. Using Generated Scripts

```bash
# Mount the filesystem (user or AI agent can run this)
./juicefs-scripts/mount-myfs.sh

# Check status (AI agent can safely read and run this)
./juicefs-scripts/status-myfs.sh

# Unmount the filesystem
./juicefs-scripts/unmount-myfs.sh
```

**Idempotent operations:**
- Mount script checks if already mounted and skips if so
- Unmount script checks if mounted and skips if not
- Safe to run multiple times

## Security Features

### Two Security Modes

**Multi-user mode (RECOMMENDED):**
- Run init script as root with `sudo`
- Scripts owned by root, executable by AI agent user
- AI agent user can execute but CANNOT read scripts
- True credential isolation enforced by OS
- Example: `sudo ./scripts/juicefs-init.sh` → select option 1

**Single-user mode (LIMITED):**
- Run init script as same user running AI agent
- Scripts owned by you, chmod 500 (execute-only)
- Owner can still change permissions to read if needed
- Protects from accidental exposure, not intentional access
- Example: `./scripts/juicefs-init.sh` → select option 2

### Permission Model

**Multi-user mode:**
- Scripts owned by root
- Group ownership set to AI agent user's primary group
- Permissions: 550 (owner read+execute, group execute-only)
- AI agent user inherits group execute permission
- AI agent CANNOT read script contents (no read permission)

**Single-user mode:**
- Scripts owned by you
- Permissions: 500 (owner execute-only)
- Note: Owner can always `chmod 600` to read if needed
- This is a limitation of single-user approach

### When Security is Required

Use this secure approach when using:
- ✅ Object storage with access keys (S3, OSS, Azure, GCS)
- ✅ Databases with passwords (Redis, MySQL, PostgreSQL)
- ✅ Any configuration with sensitive information

Not required for:
- ❌ Local storage + SQLite3 (no credentials)
- ❌ Unauthenticated metadata engines

## Example Workflow

### Scenario: Setting up JuiceFS with S3 and Redis (Multi-User Mode)

**Step 1: Initialize** (admin runs as root)
```bash
sudo ./scripts/juicefs-init.sh

# Prompts and responses:
# Security mode: 1 (Multi-user mode)
# AI agent user: aiagent
# Filesystem name: prod-data
# Mount point: /mnt/jfs
# Metadata Engine: 1 (Redis with password)
# Redis host: localhost
# Redis password: ****
# Storage: 1 (Amazon S3)
# S3 bucket: https://mybucket.s3.amazonaws.com
# AWS Access Key: AKIA...
# AWS Secret Key: ****
# ...additional options...

# Scripts created, owned by root, executable by aiagent
```

**Step 2: Mount** (AI agent user or system runs)
```bash
# Switch to AI agent user
su - aiagent

# Mount the filesystem (can execute, cannot read)
./juicefs-scripts/mount-prod-data.sh
# ✓ Filesystem mounted at /mnt/jfs

# Try to read the script (should fail)
cat ./juicefs-scripts/mount-prod-data.sh
# cat: Permission denied ✓
```

**Step 3: Use** (AI agent works with mounted filesystem)
```bash
# AI agent can now use /mnt/jfs for file operations
ls /mnt/jfs
cp data.csv /mnt/jfs/
```

**Step 4: Monitor** (AI agent can safely check status)
```bash
./juicefs-scripts/status-prod-data.sh
# Shows mount status and statistics
```

**Step 5: Unmount** (when done)
```bash
./juicefs-scripts/unmount-prod-data.sh
# ✓ Filesystem unmounted
```

## For AI Agents

When an AI agent needs to work with JuiceFS:

1. **If credentials are needed**, the agent should instruct the user:
   ```
   ⚠️  This operation requires sensitive credentials.
   
   Please run the initialization script yourself:
     ./scripts/juicefs-init.sh
   
   After setup, I can use the generated scripts safely.
   ```

2. **Use generated scripts** without accessing credentials:
   ```bash
   # Mount (execute only, no credential access)
   ./juicefs-scripts/mount-<name>.sh
   
   # Check status (safe to read)
   ./juicefs-scripts/status-<name>.sh
   
   # Unmount (execute only)
   ./juicefs-scripts/unmount-<name>.sh
   ```

3. **For local development** (no credentials), direct commands are safe:
   ```bash
   juicefs format --storage file --bucket /tmp/storage sqlite3:///tmp/jfs.db dev-fs
   juicefs mount sqlite3:///tmp/jfs.db /mnt/jfs
   ```

## Testing

Run the test script to validate the initialization script:

```bash
./scripts/test-init.sh
```

This performs 12 tests to ensure:
- Script exists and is executable
- Proper bash syntax
- All security features present
- All metadata engines supported
- Storage options available
- Credential handling correct
- Existing scripts detection
- Filesystem status checks

## Re-running and Updates

### Updating Configuration

If you need to change mount options or credentials:

1. Re-run the initialization script:
   ```bash
   ./scripts/juicefs-init.sh
   ```

2. Use the same filesystem name as before

3. The script will:
   - Detect existing scripts and ask for confirmation to overwrite
   - Check if filesystem already exists (skip formatting)
   - Regenerate mount/unmount scripts with new configuration

### Handling Existing Filesystems

The script automatically detects:
- ✓ If JuiceFS command is installed
- ✓ If filesystem is already formatted
- ✓ If scripts already exist for the filesystem name

**Safe re-run behavior:**
- Won't format an already-formatted filesystem
- Prompts before overwriting existing scripts
- Shows existing filesystem status and details
- **Skips storage credential prompts for existing filesystems** (credentials already in metadata)

**Key benefit:** When working with an existing filesystem, you only need to provide:
- Filesystem name
- Metadata engine URL
- Mount options (cache, prefetch, etc.)

You do NOT need to re-enter:
- Object storage credentials (AK/SK)
- Bucket URLs
- Storage configuration

This is because JuiceFS stores storage credentials in the metadata engine during formatting, and they're retrieved automatically during mount.

### Example: Changing Mount Options

```bash
# Initial setup
./scripts/juicefs-init.sh
# Filesystem: prod-data
# Cache size: 100GB

# Later, want to increase cache
./scripts/juicefs-init.sh
# Filesystem: prod-data (same name)
# Metadata: redis://localhost:6379/1
# ✓ Filesystem already exists (shows info)
# Step 4: Object Storage Configuration
# ✓ Skipped (filesystem already exists, credentials already stored)
# ⚠️  WARNING: Existing scripts found...
# Continue? y
# Cache size: 200GB (new value)

# Result: Mount script updated with new cache size
# No need to re-enter S3 credentials!
# Filesystem not reformatted (already exists)
```

### Example: Existing Filesystem on New Machine

```bash
# You have a JuiceFS filesystem already formatted
# Moving to a new machine or re-configuring

./scripts/juicefs-init.sh
# Filesystem: prod-data
# Metadata: redis://prod-redis:6379/1

# ✓ Filesystem 'prod-data' already exists
# 
# ℹ️  Since the filesystem already exists:
#    - Storage credentials are already saved in metadata
#    - Format step will be skipped
#    - Only mount/unmount scripts will be generated
#    - You do NOT need to re-enter object storage credentials

# Configure mount options (cache, prefetch, etc.)
# Scripts created without asking for S3 AK/SK!
```

## Troubleshooting

### "juicefs command not found"

Install JuiceFS first:
```bash
curl -sSL https://d.juicefs.com/install | sh -
```

### Cannot read script content

This is by design! Scripts with credentials are execute-only (chmod 500). You can:
- Run the script: `./juicefs-scripts/mount-myfs.sh`
- Cannot read: `cat ./juicefs-scripts/mount-myfs.sh` (Permission denied)

To recreate scripts, run the initialization script again.

### Need to modify configuration

Re-run the initialization script:
```bash
./scripts/juicefs-init.sh
```

It will detect if the filesystem already exists and skip formatting.

## Best Practices

1. **Backup your credentials** - Since scripts are execute-only, keep credentials in a secure location
2. **Use IAM roles** when possible instead of access keys
3. **Use TLS** for metadata engines (rediss:// instead of redis://)
4. **Regular updates** - Keep JuiceFS client updated
5. **Monitor access** - Use the status script to monitor filesystem health

## Additional Resources

- [JuiceFS Documentation](https://juicefs.com/docs/community/introduction)
- [SKILL.md](../SKILL.md) - Complete JuiceFS skill documentation
- [Security Section](../SKILL.md#-security-protecting-sensitive-credentials) - Detailed security guidance

## License

This skill is provided as a reference for JuiceFS Community Edition (Apache License 2.0).
