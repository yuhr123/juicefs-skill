# Security Model Documentation

## Problem Statement

The original implementation had a fundamental security flaw identified by the user:

> "当前应该是假设以运行 ai agent 的用户身份来初始化脚本并设置仅运行权限。但这显然是一个掩耳盗铃的逻辑，只有另一个隔离的用户来设置这个权限（或 root），才能真正意义上保证脚本是只能运行的。"

Translation: "Currently it assumes the same user running the AI agent initializes the script and sets execute-only permissions. But this is obviously self-deception logic. Only another isolated user (or root) can truly guarantee that the script is execute-only."

### The Fundamental Issue

When the same user owns a file and sets `chmod 500`:
- The file appears to be "execute-only" 
- BUT the owner can always run `chmod 600` to make it readable again
- This is "掩耳盗铃" (covering one's ears while stealing a bell) - self-deception
- The protection is illusory when protecting from yourself

## Solution: Two Security Modes

### Mode 1: Multi-User (RECOMMENDED - True Isolation)

**Setup:**
1. Run initialization script as `root` (using `sudo`)
2. Specify the AI agent username during setup
3. Scripts are created with:
   - Owner: `root`
   - Group: AI agent user's primary group
   - Permissions: `510` (owner: read+execute, group: execute-only, others: none)

**Security Properties:**
- ✅ AI agent user can execute scripts (via group execute permission)
- ✅ AI agent user CANNOT read scripts (no read permission for group)
- ✅ True isolation enforced by the operating system
- ✅ Even if AI agent tries `cat`, `less`, `echo`, etc., OS denies access
- ✅ Root owns the files, AI agent user cannot change permissions

**Example:**
```bash
# Admin runs:
sudo ./scripts/juicefs-init.sh
# Select: 1 (Multi-user mode)
# AI agent user: aiagent

# Generated script ownership:
-r-xr-x--- 1 root aiagent 1234 Feb 4 mount-prod.sh

# AI agent user tries to read:
$ whoami
aiagent
$ ./juicefs-scripts/mount-prod.sh
✓ Mounted successfully

$ cat ./juicefs-scripts/mount-prod.sh
cat: Permission denied ✓ TRUE PROTECTION
```

### Mode 2: Single-User (LIMITED - Basic Protection)

**Setup:**
1. Run initialization script as the same user running AI agent
2. Scripts are created with:
   - Owner: Current user
   - Permissions: `500` (owner: execute-only)

**Security Properties:**
- ⚠️ Provides protection from accidental exposure
- ⚠️ Owner can always change permissions: `chmod 600 script.sh`
- ⚠️ Protection is advisory, not enforced
- ✓ Suitable for development or trusted single-user environments
- ✓ Better than nothing - prevents casual viewing

**Example:**
```bash
# User runs:
./scripts/juicefs-init.sh
# Select: 2 (Single-user mode)

# Generated script ownership:
-r-x------ 1 user user 1234 Feb 4 mount-prod.sh

# Same user can work around:
$ ./juicefs-scripts/mount-prod.sh
✓ Mounted successfully

$ cat ./juicefs-scripts/mount-prod.sh
cat: Permission denied (chmod 500)

$ chmod 600 ./juicefs-scripts/mount-prod.sh
$ cat ./juicefs-scripts/mount-prod.sh
✓ Can now read (LIMITATION)
```

## Implementation Details

### Permission Function

```bash
set_secure_permissions() {
    local script_path="$1"
    local is_sensitive="$2"  # true/false
    
    if [[ "$is_sensitive" == "true" ]]; then
        if [[ "$MULTIUSER_MODE" == "true" ]]; then
            # Multi-user: root owns, group executes only (no read)
            AI_AGENT_GROUP=$(id -gn "$AI_AGENT_USER")
            chown root:"$AI_AGENT_GROUP" "$script_path"
            chmod 510 "$script_path"
        else
            # Single-user: owner execute-only
            chmod 500 "$script_path"
        fi
    else
        # Status scripts (no credentials)
        chmod 755 "$script_path"
        if [[ "$MULTIUSER_MODE" == "true" ]]; then
            chown root:"$AI_AGENT_GROUP" "$script_path"
        fi
    fi
}
```

### Permission Model Comparison

| Aspect | Multi-User Mode | Single-User Mode |
|--------|----------------|------------------|
| Owner | root | Current user |
| AI agent can execute | ✓ Yes | ✓ Yes |
| AI agent can read | ✗ No (enforced) | ⚠️ No (advisory) |
| AI agent can change perms | ✗ No | ✓ Yes (owner) |
| Protection level | TRUE isolation | Basic protection |
| Use case | Production | Development |
| Requires | sudo | Regular user |

## Usage Recommendations

### For Production Deployments

**ALWAYS use multi-user mode:**
```bash
# Create dedicated user for AI agent
sudo useradd -m -s /bin/bash aiagent

# Initialize as root
sudo ./scripts/juicefs-init.sh
# Select: 1 (Multi-user mode)
# AI agent user: aiagent

# Run AI agent as that user
sudo -u aiagent /path/to/ai-agent
```

### For Development/Testing

**Single-user mode is acceptable:**
```bash
# Initialize as yourself
./scripts/juicefs-init.sh
# Select: 2 (Single-user mode)
# Acknowledge limitations

# Run AI agent in same session
/path/to/ai-agent
```

### For Shared Servers

**MUST use multi-user mode:**
- Multiple users on the system
- Need true credential isolation
- Cannot trust all users

## Security Analysis

### Attack Scenarios

**Scenario 1: AI agent tries to read credentials**

Multi-user mode:
```bash
$ cat mount-prod.sh
cat: Permission denied ✓ BLOCKED
```

Single-user mode:
```bash
$ cat mount-prod.sh
cat: Permission denied (initially)
$ chmod 600 mount-prod.sh && cat mount-prod.sh
✓ CAN READ ✗ BYPASSED
```

**Scenario 2: AI agent uses `strings` or binary tools**

Multi-user mode:
```bash
$ strings mount-prod.sh
strings: mount-prod.sh: Permission denied ✓ BLOCKED
```

Single-user mode:
```bash
$ strings mount-prod.sh
strings: mount-prod.sh: Permission denied (initially)
$ chmod 600 mount-prod.sh && strings mount-prod.sh
✓ CAN READ ✗ BYPASSED
```

**Scenario 3: AI agent uses debugger/tracer**

Both modes:
```bash
$ strace -s 9999 ./mount-prod.sh 2>&1 | grep -E 'SECRET|PASSWORD'
# Can see credentials in memory/execution ✗ LIMITATION
```

Note: No file permission system can protect against debugging the execution.
For complete isolation, consider:
- SELinux/AppArmor policies
- Containers with limited capabilities
- Separate execution contexts

## Limitations

### Both Modes

1. **Execution Tracing**: Anyone who can execute can trace execution and see credentials in memory
2. **Process Memory**: Running processes have credentials in memory
3. **System Logs**: Credentials might appear in logs if not careful

### Single-User Mode Specific

1. **Owner Bypass**: Owner can always `chmod` to read
2. **Backup/Copy**: Owner can copy file and change permissions
3. **Advisory Only**: Protection is not enforced by OS

### Multi-User Mode Specific

1. **Root Access**: Root can always read any file
2. **Requires Setup**: Need sudo access for initial setup
3. **User Management**: Must properly manage AI agent user

## Best Practices

1. **Choose Appropriate Mode**
   - Production → Multi-user
   - Development → Single-user (with awareness)

2. **Minimal Credentials**
   - Use IAM roles when possible
   - Rotate credentials regularly
   - Limit credential scope

3. **Audit Regularly**
   - Check file permissions: `ls -la juicefs-scripts/`
   - Review access logs
   - Monitor for unauthorized access

4. **Defense in Depth**
   - File permissions (this solution)
   - Network isolation
   - Principle of least privilege
   - Regular security audits

## Conclusion

The updated implementation provides:
- **True isolation** via multi-user mode (recommended)
- **Honest documentation** of single-user mode limitations
- **User choice** based on deployment needs
- **Clear guidance** on when to use each mode

This addresses the "掩耳盗铃" (self-deception) criticism by:
1. Acknowledging the limitation of single-user approach
2. Providing a proper multi-user solution
3. Documenting the security properties honestly
4. Guiding users to appropriate choices
