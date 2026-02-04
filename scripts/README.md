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

Follow the interactive prompts to configure:
- Filesystem name
- Mount point
- Metadata engine (Redis, MySQL, PostgreSQL, TiKV, SQLite)
- Object storage (S3, local, etc.)
- Cache settings
- Performance options

### 2. Generated Scripts

The initialization script creates a `juicefs-scripts/` directory with:

- **`format-<name>.sh`** - Formats the filesystem (if needed)
  - Permissions: 500 (execute-only)
  - Contains: Storage credentials and metadata connection
  
- **`mount-<name>.sh`** - Mounts the filesystem
  - Permissions: 500 (execute-only)
  - Contains: All credentials and mount options
  
- **`unmount-<name>.sh`** - Unmounts the filesystem
  - Permissions: 500 (execute-only)
  - Contains: Mount point information
  
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

## Security Features

### Execute-Only Permissions

Scripts containing credentials are set to chmod 500:
- **Owner can execute** - You can run the script
- **Owner cannot read** - Even you cannot cat/view the script content
- **Others have no access** - Complete protection from other users

This prevents AI agents from reading credentials while still allowing them to execute the scripts.

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

**Step 1: Initialize** (user runs this, outside AI agent)
```bash
./scripts/juicefs-init.sh

# Prompts and responses:
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
```

**Step 2: Mount** (AI agent or user can run)
```bash
./juicefs-scripts/mount-prod-data.sh
# ✓ Filesystem mounted at /mnt/jfs
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

This performs 9 tests to ensure:
- Script exists and is executable
- Proper bash syntax
- All security features present
- All metadata engines supported
- Storage options available
- Credential handling correct

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
