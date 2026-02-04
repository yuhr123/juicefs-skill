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

## Quick Start

The main skill instructions are in [`SKILL.md`](SKILL.md), which contains:

- **YAML frontmatter**: Skill metadata (name, description, license)
- **Essential commands**: Format, mount, sync, status, configuration
- **Configuration patterns**: Optimized settings for different workloads
- **Troubleshooting**: Common issues and solutions
- **Quick reference**: Decision trees and performance tuning

For comprehensive details, see the [references directory](references/).

## Skill Coverage

### Core Functionality
- Architecture and components (client, data storage, metadata engine)
- Installation and setup procedures
- All JuiceFS commands with examples
- Kubernetes, Hadoop, and Docker integration

### Performance & Optimization
- Cache configuration strategies
- Mount options by workload (ML training, big data, shared dev)
- Performance tuning guidelines
- Metadata engine selection

### Operations
- Monitoring and troubleshooting
- Security best practices (encryption, access control)
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
- Full `SKILL.md` loaded when activated (~11KB, 385 lines)
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