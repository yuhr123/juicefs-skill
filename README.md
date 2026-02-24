# JuiceFS Secure Initialization and Wrapper Tool

A standalone utility for securely setting up JuiceFS for general users, administrators, and automated environments.

## Overview

This tool helps you securely set up JuiceFS by compiling credentials into a binary wrapper using shc (Shell Script Compiler) that can be executed but not easily read. It is useful in any environment where you want to prevent sensitive credentials (access keys, passwords) from being stored in plaintext.

## Scripts

### `juicefs-init.sh`

Interactive initialization script that:
- Prompts for JuiceFS configuration (metadata engine, object storage, credentials)
- Formats the filesystem if needed
- Compiles wrapper script with embedded credentials into a binary using shc
- Sets appropriate permissions (binary owned by root, executable by the configured user)

### `test-init.sh`

Test script that validates the initialization script:
- Checks script structure and syntax
- Verifies security features are present
- Validates script generation logic
- Tests metadata engine and storage support

## Usage

### 1. Run the Initialization Script

**IMPORTANT: This script MUST be run with root/administrator privileges (sudo)**

```bash
sudo ./juicefs-init.sh
```

**Why root is required:**
- To install shc (Shell Script Compiler) if not present
- To compile scripts into secure binaries
- To set proper ownership (root) and permissions
- To ensure the configured user can execute but not read the binary

**JuiceFS Installation:**
- The script checks if JuiceFS is in your PATH
- If not found, it offers to install it automatically
- Installation uses the standard JuiceFS installation script

Follow the interactive prompts to configure:
- Username of the user who will execute the wrapper binary
- Filesystem name
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
- If binary already exists for the same filesystem name, you'll be prompted to confirm overwrite
- The script checks if the filesystem is already formatted and skips formatting if it exists
- For existing filesystems, storage credential prompts are skipped automatically
- You can safely re-run the script to regenerate the binary with updated configuration

### 2. Generated Binary

The initialization script creates a `juicefs-scripts/` directory with:

- **`<filesystem-name>`** - Compiled binary wrapper (e.g., `prod-data`)
  - Permissions: 750 (owner rwx, group r-x, others none)
  - Owner: root
  - Group: configured user's primary group
  - Contains: Embedded credentials (compiled, not readable as plaintext)
  - Accepts any JuiceFS command and parameters
  - **Configured user can execute but credentials are obfuscated in binary format**

**Note:** No separate mount/unmount/status scripts. The single binary accepts all JuiceFS commands.

### 3. Using the Generated Binary

```bash
# Switch to the configured user first
su - myuser

# Show available commands (help)
./juicefs-scripts/prod-data

# Mount the filesystem
./juicefs-scripts/prod-data mount /mnt/jfs

# Mount with custom options
./juicefs-scripts/prod-data mount --cache-size 204800 /mnt/jfs

# Check status
./juicefs-scripts/prod-data status

# Unmount the filesystem
./juicefs-scripts/prod-data umount /mnt/jfs
```

**Any JuiceFS command works:**
- The binary wraps JuiceFS with embedded metadata connection
- All standard JuiceFS commands and options are supported
- Credentials are compiled into the binary, not stored as plaintext

## Security Features

### Binary Compilation with shc

**Security Model:**
- Run init script as root with `sudo`
- Script compiles wrapper with embedded credentials using shc (Shell Script Compiler)
- Binary owned by root, executable by configured user
- Configured user can execute but credentials are obfuscated in binary format
- True credential isolation enforced by OS

**How it works:**
1. Root runs initialization script
2. Script creates wrapper with embedded credentials
3. shc compiles wrapper into binary format
4. Binary set with permissions 750 (root:user-group)
5. User can execute but cannot easily read credentials

### Permission Model

- Binary owned by root
- Group ownership set to configured user's primary group
- Permissions: 750 (owner read+write+execute, group read+execute, others none)
- Configured user executes via group permission
- Credentials embedded in compiled binary format (obfuscated by shc)

### When Security is Required

Use this secure approach when using:
- ✅ Object storage with access keys (S3, OSS, Azure, GCS)
- ✅ Databases with passwords (Redis, MySQL, PostgreSQL)
- ✅ Any configuration with sensitive information

Not required for:
- ❌ Local storage + SQLite3 (no credentials)
- ❌ Unauthenticated metadata engines

## Example Workflow

### Scenario: Setting up JuiceFS with S3 and Redis

**Step 1: Initialize** (admin runs as root)
```bash
sudo ./juicefs-init.sh

# Prompts and responses:
# User: myuser
# Filesystem name: prod-data
# Metadata Engine: 1 (Redis with password)
# Redis host: localhost
# Redis password: ****
# Storage: 1 (Amazon S3)
# S3 bucket: https://mybucket.s3.amazonaws.com
# AWS Access Key: AKIA...
# AWS Secret Key: ****
# ...additional options...

# Binary created: juicefs-scripts/prod-data
# Owned by root, executable by myuser
```

**Step 2: Use the Binary** (configured user runs)
```bash
# Switch to configured user
su - myuser

# Mount the filesystem
./juicefs-scripts/prod-data mount /mnt/jfs
# ✓ Filesystem mounted at /mnt/jfs

# Check status
./juicefs-scripts/prod-data status
# Shows filesystem information

# Work with mounted filesystem
ls /mnt/jfs
cp data.csv /mnt/jfs/

# Unmount when done
./juicefs-scripts/prod-data umount /mnt/jfs
# ✓ Filesystem unmounted
```

## For Users and Automated Environments

When an automated process or restricted user needs to work with JuiceFS:

1. **If credentials are needed**, the administrator should run:
   ```
   Please run the initialization script yourself (requires root):
     sudo ./juicefs-init.sh
   
   After setup, use the generated binary safely.
   ```

2. **Use generated binary** without accessing credentials:
   ```bash
   # The binary accepts any JuiceFS command
   ./juicefs-scripts/<filesystem-name> mount <mountpoint>
   ./juicefs-scripts/<filesystem-name> status
   ./juicefs-scripts/<filesystem-name> umount <mountpoint>
   ```

3. **For local development** (no credentials), direct commands are safe:
   ```bash
   juicefs format --storage file --bucket /tmp/storage sqlite3:///tmp/jfs.db dev-fs
   juicefs mount sqlite3:///tmp/jfs.db /mnt/jfs
   ```

## Testing

Run the test script to validate the initialization script:

```bash
./test-init.sh
```

This performs tests to ensure:
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
   sudo ./juicefs-init.sh
   ```

2. Use the same filesystem name as before

3. The script will:
   - Detect existing binary and ask for confirmation to overwrite
   - Check if filesystem already exists (skip formatting)
   - Regenerate binary with new configuration

### Handling Existing Filesystems

The script automatically detects:
- ✓ If JuiceFS command is installed
- ✓ If filesystem is already formatted
- ✓ If binary already exists for the filesystem name

**Safe re-run behavior:**
- Won't format an already-formatted filesystem
- Prompts before overwriting existing binary
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
sudo ./juicefs-init.sh
# Filesystem: prod-data
# Cache size: 100GB

# Later, want to increase cache
sudo ./juicefs-init.sh
# Filesystem: prod-data (same name)
# Metadata: redis://localhost:6379/1
# ✓ Filesystem already exists (shows info)
# Step 4: Object Storage Configuration
# ✓ Skipped (filesystem already exists, credentials already stored)
# ⚠️  WARNING: Existing binary found...
# Continue? y
# Cache size: 200GB (new value)

# Result: Binary updated with new cache size
# No need to re-enter S3 credentials!
# Filesystem not reformatted (already exists)
```

### Example: Existing Filesystem on New Machine

```bash
# You have a JuiceFS filesystem already formatted
# Moving to a new machine or re-configuring

sudo ./juicefs-init.sh
# Filesystem: prod-data
# Metadata: redis://prod-redis:6379/1

# ✓ Filesystem 'prod-data' already exists
# 
# ℹ️  Since the filesystem already exists:
#    - Storage credentials are already saved in metadata
#    - Format step will be skipped
#    - Only binary will be generated
#    - You do NOT need to re-enter object storage credentials

# Configure mount options (cache, prefetch, etc.)
# Binary created without asking for S3 AK/SK!
```

## Troubleshooting

### "juicefs command not found"

Install JuiceFS first:
```bash
curl -sSL https://d.juicefs.com/install | sh -
```

### Cannot read binary source

This is by design! The binary contains compiled credentials that are obfuscated. You can:
- Execute the binary: `./juicefs-scripts/prod-data mount /mnt/jfs`
- Cannot easily read credentials from binary format

To update configuration, re-run the initialization script with sudo.

### Need to modify configuration

Re-run the initialization script:
```bash
sudo ./juicefs-init.sh
```

It will detect if the filesystem already exists and skip formatting.

## Best Practices

1. **Always use sudo** - Root privileges required for proper security isolation
2. **Use IAM roles** when possible instead of static access keys
3. **Use TLS** for metadata engines (rediss:// instead of redis://)
4. **Regular updates** - Keep JuiceFS client updated
5. **Monitor access** - Check filesystem status regularly

## Advanced Security Options

For enhanced security in production environments, consider:

1. **Secret Management Services**: AWS Secrets Manager, HashiCorp Vault
2. **IAM Roles**: Use cloud provider IAM instead of static credentials
3. **Certificate-Based Auth**: Use TLS client certificates
4. **Configuration Encryption**: Tools like age or SOPS

See [SECURITY_MODEL.md](SECURITY_MODEL.md) for detailed advanced security recommendations.

## Additional Resources

- [JuiceFS Documentation](https://juicefs.com/docs/community/introduction)
- [Security Model](SECURITY_MODEL.md) - Detailed security documentation

## License

This tool is provided as a reference for JuiceFS Community Edition (Apache License 2.0).
