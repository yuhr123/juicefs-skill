# Quick Reference for AI Agents: JuiceFS Security

## When User Mentions JuiceFS Setup

### Step 1: Detect if Credentials Are Needed

**Ask these questions:**
- What metadata engine? (Redis, MySQL, PostgreSQL, etc.)
- Does it require a password? 
- What object storage? (S3, OSS, Azure, GCS, etc.)
- Does it require access keys?

### Step 2: Determine Approach

#### If Credentials ARE Needed (S3, Redis with password, etc.)

**DO NOT** directly run format/mount commands!

**Instead, guide the user:**

```
⚠️  SECURITY WARNING: This setup requires sensitive credentials.

To prevent credential exposure to me (the AI agent), please:

1. Run the initialization script yourself:
   cd /path/to/juicefs-skill
   ./scripts/juicefs-init.sh

2. Follow the prompts to configure your filesystem

3. After setup, tell me, and I can use the generated scripts:
   - Mount: ./juicefs-scripts/mount-<name>.sh
   - Status: ./juicefs-scripts/status-<name>.sh
   - Unmount: ./juicefs-scripts/unmount-<name>.sh

This keeps your AK/SK and passwords secure from me.
```

#### If Credentials NOT Needed (local + sqlite3)

**This is SAFE** - you can directly help:

```bash
juicefs format \
    --storage file \
    --bucket /tmp/jfs-storage \
    sqlite3:///tmp/jfs.db \
    dev-fs

juicefs mount sqlite3:///tmp/jfs.db /mnt/jfs-dev
```

### Step 3: After User Initializes

Once user has run the initialization script, you can safely:

```bash
# Mount the filesystem (execute without reading)
./juicefs-scripts/mount-<name>.sh

# Check status (safe to read - no credentials)
./juicefs-scripts/status-<name>.sh

# Work with mounted filesystem
ls /mnt/jfs
cp data.csv /mnt/jfs/
python train.py --data /mnt/jfs/

# Unmount when done
./juicefs-scripts/unmount-<name>.sh
```

## Detection Logic

### Requires Security:
- ✅ S3, OSS, Azure Blob, GCS (has AK/SK)
- ✅ Redis with password
- ✅ MySQL/PostgreSQL with password
- ✅ Any URL containing passwords or keys

### Does NOT Require Security:
- ❌ Local storage (`--storage file`)
- ❌ SQLite3 without password
- ❌ Redis without password (rare, development only)
- ❌ TiKV without auth (if configured)

## Example Conversations

### Example 1: User Wants S3 + Redis (NEEDS SECURITY)

**User:** "Help me set up JuiceFS with S3 and Redis"

**You (AI):** 
```
I can help! However, this setup requires sensitive credentials 
(AWS access keys and Redis password).

To keep these secure from me, please run the initialization 
script yourself:

  ./scripts/juicefs-init.sh

It will guide you through:
- Configuring Redis connection with password
- Setting up S3 with your AWS credentials
- Generating secure mount/unmount scripts

After you've run it, let me know and I can help you use 
the generated scripts safely.

Would you like me to explain what the script does?
```

### Example 2: User Wants Local + SQLite (SAFE)

**User:** "Help me set up JuiceFS for local development"

**You (AI):** 
```
Great! For local development with no credentials, I can help 
directly. Here's how to set it up:

# Format filesystem
juicefs format \
    --storage file \
    --bucket /tmp/jfs-storage \
    sqlite3:///tmp/jfs.db \
    dev-fs

# Mount it
juicefs mount sqlite3:///tmp/jfs.db /mnt/jfs-dev

# Verify
mountpoint /mnt/jfs-dev

This is safe because there are no credentials involved.
```

### Example 3: User Already Initialized (USE SCRIPTS)

**User:** "I've run the initialization script. Now what?"

**You (AI):**
```
Perfect! Now I can safely work with JuiceFS. Let me mount it:

# Check what scripts are available
ls juicefs-scripts/

# Mount the filesystem
./juicefs-scripts/mount-<name>.sh

# Verify it's mounted
./juicefs-scripts/status-<name>.sh

What would you like to do with the mounted filesystem?
```

## Commands You CAN Run Safely

### After Initialization:

```bash
# Execute mount script (no credential access)
./juicefs-scripts/mount-<name>.sh

# Execute unmount script
./juicefs-scripts/unmount-<name>.sh

# Read and execute status script
./juicefs-scripts/status-<name>.sh

# Work with mounted filesystem
ls /mnt/jfs
cp file.txt /mnt/jfs/
cat /mnt/jfs/data.csv
```

### With Local Setup (No Credentials):

```bash
# All juicefs commands are safe
juicefs format ...
juicefs mount ...
juicefs umount ...
juicefs status ...
juicefs sync ...
```

## Commands You CANNOT Run

### Do NOT run these with sensitive credentials:

```bash
# ❌ Direct mount with Redis password
juicefs mount redis://:password@host:6379/1 /mnt/jfs

# ❌ Format with S3 requiring AK/SK
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
juicefs format --storage s3 ...

# ❌ Any command exposing credentials to you
```

## Red Flags (Indicate Need for Security)

Watch for these keywords from users:
- "AWS credentials"
- "access key" / "secret key"
- "Redis password"
- "database password"
- "S3", "OSS", "Azure Blob", "GCS"
- "MySQL", "PostgreSQL" with auth
- Any password or secret mention

When you see these → Guide to initialization script!

## Remember

1. **Your role**: Help users work with JuiceFS **without accessing credentials**
2. **User's role**: Run initialization script **with credentials** outside your context
3. **Result**: Secure collaboration where you can execute scripts but never see secrets

## Testing Your Understanding

**Quiz:**

1. User says: "Mount JuiceFS with S3 and MySQL"
   → Answer: Guide to initialization script (credentials needed)

2. User says: "Mount JuiceFS with local storage and SQLite"
   → Answer: Direct help is safe (no credentials)

3. User says: "I ran the init script, what's next?"
   → Answer: Execute the generated mount script

4. User says: "What's my Redis password?"
   → Answer: Cannot access it - it's in execute-only scripts

5. User says: "Can you update the mount options?"
   → Answer: Re-run initialization script to regenerate
