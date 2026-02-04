# JuiceFS Skill for AI Agents

This repository contains an Agent Skill for JuiceFS Community Edition, following the [Agent Skills specification](https://agentskills.io/specification).

## About JuiceFS

JuiceFS is a high-performance POSIX file system designed for cloud-native environments. It separates data and metadata storage, making it ideal for big data, machine learning, and artificial intelligence workloads.

## Skill Structure

This skill follows the [Agent Skills format](https://agentskills.io/what-are-skills):

```
juicefs-skill/
├── SKILL.md                           # Main skill file (required)
├── README.md                          # This file
└── references/                        # Detailed reference material
    ├── COMPREHENSIVE_REFERENCE.md     # Complete JuiceFS documentation
    ├── QUICKSTART.md                  # Task patterns and troubleshooting
    ├── TABLE_OF_CONTENTS.md          # Topic index
    └── SUMMARY.md                     # Package summary
```

## Installation

### For AI Agent Developers

To integrate this skill into your AI agent:

#### 1. Clone or Download the Skill

```bash
# Clone this repository
git clone https://github.com/yuhr123/juicefs-skill.git

# Or download and extract to your skills directory
cd /path/to/your/skills/directory
git clone https://github.com/yuhr123/juicefs-skill.git
```

#### 2. Configure Your Agent

Add the skill directory to your agent's skill discovery path. The exact method depends on your agent implementation:

**For filesystem-based agents** (e.g., Claude, agents with bash/unix environment):

Add the skill path to your agent's system prompt:

```xml
<available_skills>
  <skill>
    <name>juicefs-skill</name>
    <description>Work with JuiceFS, a high-performance POSIX file system for cloud-native environments. Use when dealing with distributed file systems, object storage backends (S3, Azure, GCS), metadata engines (Redis, MySQL, TiKV), or when users mention JuiceFS, cloud storage, big data, or ML training storage.</description>
    <location>/path/to/juicefs-skill/SKILL.md</location>
  </skill>
</available_skills>
```

**For tool-based agents**:

Implement a skill activation tool that can:
1. Parse the YAML frontmatter from `SKILL.md`
2. Load the full skill content when needed
3. Access reference files in the `references/` directory

#### 3. Verify Installation

Test that your agent can discover and load the skill:

```bash
# Using skills-ref validation tool
skills-ref validate ./juicefs-skill

# Generate prompt XML for your agent
skills-ref to-prompt ./juicefs-skill
```

### For End Users

If you're using an AI agent that already supports Agent Skills:

1. **Find your agent's skills directory**
   - Check your agent's documentation for the skills location
   - Common paths: `~/.config/agent/skills/`, `~/agent-skills/`, or specified in config

2. **Install the skill**
   ```bash
   cd /path/to/agent/skills
   git clone https://github.com/yuhr123/juicefs-skill.git
   ```

3. **Restart your agent** (if required)
   - Some agents auto-discover skills on startup
   - Others may require a manual reload or restart

4. **Verify the skill is loaded**
   - Ask your agent: "What skills do you have?"
   - Test with: "How do I mount a JuiceFS file system?"

### Using skills-ref Library

Install the reference library for validation and prompt generation:

```bash
pip install skills-ref
```

Then validate and use:

```bash
# Validate the skill
skills-ref validate ./juicefs-skill

# Generate XML for agent prompts
skills-ref to-prompt ./juicefs-skill
```

## Quick Start

The main skill instructions are in [`SKILL.md`](SKILL.md), which contains:

- **YAML frontmatter**: Skill metadata (name, description, license, compatibility, metadata)
- **Essential commands**: Format, mount, sync, status, configuration
- **Security guidance**: Protecting credentials in AI agent environments
- **Configuration patterns**: Optimized settings for different workloads
- **Troubleshooting**: Common issues and solutions
- **Quick reference**: Decision trees and performance tuning

For comprehensive details, see the [references directory](references/).

## 🔒 Security: Protecting Credentials

When using JuiceFS with AI agents, sensitive credentials (AK/SK, passwords) should NOT be exposed to the AI model. This skill includes a secure initialization script:

### Using the Initialization Script

```bash
# Run the interactive initialization script
./scripts/juicefs-init.sh
```

This script will:
1. ✅ Prompt for all configuration (metadata, storage, credentials)
2. ✅ Format the filesystem if needed
3. ✅ Generate mount/unmount scripts with embedded credentials
4. ✅ Set scripts to execute-only permissions (chmod 500)
5. ✅ AI agents can run scripts but cannot read credentials

### When to Use Secure Initialization

**Required for:**
- Object storage with access keys (S3, OSS, Azure, GCS)
- Databases with passwords (Redis, MySQL, PostgreSQL)
- Any configuration with sensitive information

**Not required for:**
- Local storage + SQLite3 (no credentials)

### Generated Scripts

After initialization, you'll have:
- `juicefs-scripts/mount-<name>.sh` - Mount filesystem (execute-only)
- `juicefs-scripts/unmount-<name>.sh` - Unmount filesystem (execute-only)
- `juicefs-scripts/status-<name>.sh` - Check status (readable, safe)

AI agents can safely execute these scripts without accessing your credentials.

See [SKILL.md](SKILL.md) for detailed security documentation.

## Skill Coverage

### Core Functionality
- Architecture and components (client, data storage, metadata engine)
- Installation and setup procedures
- All JuiceFS commands with examples
- Kubernetes, Hadoop, and Docker integration
- **🔒 Secure credential handling for AI agents**

### Performance & Optimization
- Cache configuration strategies
- Mount options by workload (ML training, big data, shared dev)
- Performance tuning guidelines
- Metadata engine selection

### Operations
- Monitoring and troubleshooting
- **Security best practices (credential protection, encryption, access control)**
- Maintenance tasks (garbage collection, backups)
- Data migration patterns

### Reference Material (in `references/`)
- **COMPREHENSIVE_REFERENCE.md**: 780+ lines of detailed documentation
- **QUICKSTART.md**: Task-oriented patterns and flowcharts
- **TABLE_OF_CONTENTS.md**: A-Z topic index
- **SUMMARY.md**: Package overview and metrics

## How AI Agents Use This Skill

AI agents load this skill when users need to:

1. **Set up JuiceFS**: Format file systems, configure metadata engines
2. **Mount and access**: Mount with appropriate settings for workloads
3. **Integrate**: Deploy with Kubernetes, Hadoop, Docker
4. **Optimize**: Tune cache, prefetch, and performance settings
5. **Troubleshoot**: Diagnose and resolve issues
6. **Maintain**: Run garbage collection, backup metadata

The skill uses **progressive disclosure**:
- Light metadata (`name`, `description`) loaded at startup
- Full `SKILL.md` loaded when activated (~11KB, 466 lines)
- Reference files loaded on demand for deep dives

## Usage Examples

An AI agent with this skill can help with:

- "How do I mount JuiceFS with Redis and S3?"
- "What cache size should I use for ML training?"
- "Show me how to set up JuiceFS in Kubernetes"
- "JuiceFS is slow - how do I troubleshoot?"
- "What's the best metadata engine for production?"

## Validation

Validate this skill using the [skills-ref](https://github.com/agentskills/agentskills/tree/main/skills-ref) library:

```bash
skills-ref validate ./juicefs-skill
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Make changes following the [Agent Skills specification](https://agentskills.io/specification)
3. Validate with `skills-ref validate`
4. Submit a pull request

## Resources

- **Skill Specification**: https://agentskills.io/specification
- **JuiceFS Documentation**: https://juicefs.com/docs/community/introduction
- **JuiceFS GitHub**: https://github.com/juicedata/juicefs
- **JuiceFS Community**: https://github.com/juicedata/juicefs/discussions

## License

This skill is provided as a reference for JuiceFS Community Edition (Apache License 2.0).

## Metadata

- **Skill Name**: juicefs-skill
- **Version**: 1.0
- **Author**: yuhr123
- **Based on**: JuiceFS Community Edition documentation
- **Format**: [Agent Skills specification](https://agentskills.io)