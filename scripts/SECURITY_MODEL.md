# Security Model Documentation

## Security Model Overview

This SKILL provides secure access guidance for AI Agents working with JuiceFS. The security model is designed to maximize isolation between AI agents and sensitive credentials.

## Core Design Principle

**Root User Initialization with Non-Root Agent Execution**

The security model is based on a clear separation of responsibilities:
- **Root/Administrator**: Initializes the system, compiles secure binaries with embedded credentials
- **AI Agent (Non-Root User)**: Executes binaries, but cannot access embedded credentials

This enforces true OS-level isolation where the AI agent can execute operations but cannot read sensitive information.

## Security Model: Multi-User Mode

**Setup Process:**
1. Run initialization script as `root` (using `sudo`)
2. Specify the AI agent username during setup
3. Script compiles wrapper with embedded credentials using shc (Shell Script Compiler)
4. Binary is created with:
   - Owner: `root`
   - Group: AI agent user's primary group
   - Permissions: `750` (owner: read+execute, group: execute, others: none)

**Security Properties:**
- ✅ AI agent user can execute the binary (via group execute permission)
- ✅ AI agent user CANNOT read the embedded credentials (compiled binary, not plaintext)
- ✅ True isolation enforced by the operating system
- ✅ Even if AI agent tries to read files, OS denies access to sensitive data
- ✅ Root owns the binary, AI agent user cannot change permissions
- ✅ Credentials are obfuscated in compiled binary format

**Example:**
```bash
# Admin runs:
sudo ./scripts/juicefs-init.sh
# AI agent user: aiagent
# Filesystem name: prod-data

# Generated binary:
-rwxr-x--- 1 root aiagent 12345 Feb 4 juicefs-scripts/prod-data

# AI agent user executes:
$ whoami
aiagent
$ ./juicefs-scripts/prod-data mount /mnt/jfs
✓ Mounted successfully

# AI agent cannot access credentials (binary format, not readable as plaintext)
$ strings ./juicefs-scripts/prod-data | grep -i password
# Binary is obfuscated by shc - credentials not easily readable
```

## Implementation Details

### Binary Compilation with shc

The security model uses shc (Shell Script Compiler) to compile shell scripts into binary format:

```bash
# Wrapper script with embedded credentials is compiled
shc -r -f wrapper-script.sh

# Produces:
# - wrapper-script.sh.x (compiled binary)
# - wrapper-script.sh.x.c (C source code, deleted after compilation)

# Binary is renamed and permissions set
mv wrapper-script.sh.x juicefs-scripts/<filesystem-name>
chmod 750 juicefs-scripts/<filesystem-name>
chown root:<ai-agent-group> juicefs-scripts/<filesystem-name>
```

### Permission Model

**Binary Permissions:**
- Owner: root (rwx)
- Group: AI agent user's group (r-x)
- Others: none (---)
- Numeric: 750

**Key Benefits:**
- AI agent can execute via group membership
- Cannot read source (compiled binary)
- Cannot modify permissions (not owner)
- Credentials embedded in binary format (obfuscated)

## Usage Recommendations

### Production Deployments

**Setup Process:**
```bash
# 1. Create dedicated user for AI agent
sudo useradd -m -s /bin/bash aiagent

# 2. Initialize as root
sudo ./scripts/juicefs-init.sh
# AI agent user: aiagent
# Follow prompts to configure filesystem

# 3. Run AI agent as that user
sudo -u aiagent /path/to/ai-agent
```

**Why This Approach:**
- ✓ True credential isolation enforced by OS
- ✓ AI agent cannot access sensitive information
- ✓ Follows principle of least privilege
- ✓ Industry standard security practice

## Security Analysis

### Attack Scenarios

**Scenario 1: AI agent tries to read credentials**

Multi-user mode with compiled binary:
```bash
$ cat prod-data
# Binary format - not human readable
$ strings prod-data | grep -i password
# Obfuscated by shc - credentials not easily accessible
✓ PROTECTED (credentials in compiled format)
```

**Scenario 2: AI agent uses debugger/tracer**

All binary-based approaches:
```bash
$ strace -s 9999 ./prod-data mount /mnt/jfs 2>&1 | grep -E 'SECRET|PASSWORD'
# Can potentially see credentials in system calls ⚠️ LIMITATION
```

Note: No file permission system can fully protect against runtime debugging. For complete isolation, consider:
- SELinux/AppArmor policies to restrict debugging
- Containers with limited capabilities
- Separate execution contexts with restricted ptrace
- Hardware security modules (HSM) for credential storage

## Limitations

### Current Implementation

1. **Execution Tracing**: Anyone who can execute can potentially trace execution and see credentials in system calls (requires ptrace capability)
2. **Process Memory**: Running processes have credentials in memory
3. **Binary Decompilation**: Determined attackers might attempt to decompile shc binaries (though obfuscated)
4. **Root Access**: Root can always access any file or process memory

### Mitigation Strategies

To address these limitations:

1. **Restrict ptrace**: Use SELinux/AppArmor to prevent tracing
   ```bash
   # Example AppArmor profile snippet
   deny ptrace,
   ```

2. **Limit Capabilities**: Run AI agent in containers with minimal capabilities
   ```bash
   docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE ...
   ```

3. **Process Isolation**: Use separate security contexts
4. **Audit Logging**: Monitor for suspicious behavior

## Advanced Security Recommendations

For production environments requiring maximum security:

### 1. Secret Management Services

Use dedicated secret management instead of embedded credentials:

**AWS Secrets Manager / Parameter Store:**
```bash
# Binary calls AWS CLI to fetch secrets at runtime
AWS_SECRET=$(aws secretsmanager get-secret-value --secret-id juicefs/prod-creds)
```

**HashiCorp Vault:**
```bash
# Binary authenticates to Vault and retrieves credentials
CREDS=$(vault kv get secret/juicefs/prod)
```

**Benefits:**
- Credentials never stored in binaries
- Centralized rotation and auditing
- Time-limited access tokens
- Role-based access control

### 2. IAM Roles and Instance Profiles

Use cloud provider IAM instead of static credentials:

**AWS:**
- Assign IAM role to EC2 instance
- JuiceFS automatically uses instance profile
- No credentials needed in configuration

**Azure:**
- Use Managed Identity
- Automatic credential handling

**GCP:**
- Use Workload Identity
- Service account impersonation

### 3. Configuration File Encryption

Encrypt configuration files with tools like:

**age (modern encryption):**
```bash
# Encrypt config
age -e -o config.encrypted config.yaml

# Decrypt at runtime (requires key)
age -d config.encrypted
```

**SOPS (Secrets OPerationS):**
```bash
# Encrypt values in YAML
sops -e config.yaml > config.encrypted.yaml

# Decrypt at runtime
sops -d config.encrypted.yaml
```

**Benefits:**
- Config files can be version controlled
- Encryption keys managed separately
- Support for key rotation

### 4. Certificate-Based Authentication

Use client certificates instead of passwords:

**Redis with TLS client certs:**
```bash
juicefs mount \
  --redis-cert /path/to/client.crt \
  --redis-key /path/to/client.key \
  rediss://redis:6379/1 /mnt/jfs
```

**Benefits:**
- No passwords to protect
- Automatic validation
- Can be revoked independently

## Best Practices

1. **Use Root Initialization**
   - Always run initialization script with sudo
   - Ensures proper isolation between root and AI agent user

2. **Minimal Credentials**
   - Use IAM roles when possible (AWS, Azure, GCP)
   - Rotate credentials regularly
   - Limit credential scope and permissions

3. **Defense in Depth**
   - File permissions (this solution)
   - Network isolation (VPC, private networks)
   - Principle of least privilege
   - Regular security audits

4. **Monitor and Audit**
   - Check file permissions regularly: `ls -la juicefs-scripts/`
   - Review access logs
   - Monitor for unauthorized access attempts
   - Use cloud provider audit trails (CloudTrail, etc.)

5. **Consider Advanced Options**
   - For maximum security, use secret management services
   - Implement IAM-based authentication
   - Use certificate-based authentication where possible

## SKILL Responsibility Boundary

### What This SKILL Provides

**Security Guidance for AI Agent Environments:**
- Method to prevent AI agents from accessing sensitive credentials
- Secure initialization process with binary compilation
- Clear separation between admin setup and agent usage
- Best practices for credential isolation

### What This SKILL Does NOT Handle

**Out of Scope:**
- How AI agents are deployed
- How AI agents are run or managed
- Host system security configuration
- Network security setup
- General system administration

### Collaboration Model

**Admin/User Responsibilities:**
- Install JuiceFS client
- Run initialization script with root privileges
- Manage system users and permissions
- Configure network and firewall rules
- Choose and configure metadata engines and object storage

**AI Agent Responsibilities:**
- Execute provided binaries to mount/unmount filesystems
- Work with mounted filesystems
- Report status and issues
- Never attempt to access credentials

**SKILL's Role:**
- Provide guidance on secure setup
- Ensure maximum isolation between agent and credentials
- Document security model and best practices
- Offer advanced security recommendations

## Conclusion

The security model provides true credential isolation through:
- **Root-based initialization** ensuring proper separation
- **Binary compilation with shc** obfuscating sensitive data
- **OS-level permissions** preventing unauthorized access
- **Clear responsibility boundaries** between admin and agent

This addresses credential protection requirements by:
1. Enforcing execution-only access for AI agents
2. Preventing credential exposure in plaintext
3. Providing OS-level security guarantees
4. Offering advanced security options for enhanced protection
