# JuiceFS Skill - Table of Contents

This document provides an index to all the JuiceFS skill resources for AI agents.

## Skill Files

### 1. [COMPREHENSIVE_REFERENCE.md](COMPREHENSIVE_REFERENCE.md)
**Main comprehensive skill document**

The primary reference containing detailed information about:
- JuiceFS architecture and components
- Installation and setup procedures
- All commands with examples
- Integration guides (Kubernetes, Hadoop, Docker)
- Performance optimization techniques
- Security best practices
- Troubleshooting guides
- Advanced features and use cases
- Comparison with alternatives

**Best for**: Comprehensive reference, in-depth understanding, detailed configurations

**Sections**: 20+ major sections covering all aspects of JuiceFS

**Note**: This is the reference material. The main skill entry point is `../SKILL.md` in the parent directory.

### 2. [QUICKSTART.md](QUICKSTART.md)
**Quick reference guide for common tasks**

A practical guide focused on:
- Common task patterns
- Decision trees for choosing configurations
- Troubleshooting flowcharts
- Command templates
- Example configurations
- Kubernetes quick deploy
- Monitoring and maintenance

**Best for**: Quick answers, task execution, troubleshooting, daily operations

**Sections**: Task-oriented guides with ready-to-use commands

### 3. [README.md](README.md)
**Overview and navigation**

Introduction to the skill repository:
- What this skill is about
- How AI agents use it
- Coverage overview
- Usage examples

**Best for**: Understanding the skill structure, getting started

## How to Use This Skill

### For AI Agents

1. **Answering questions**: Reference `juicefs-skill.md` for detailed explanations
2. **Executing tasks**: Use `QUICKSTART.md` for command templates and patterns
3. **Troubleshooting**: Check both files - QUICKSTART for common issues, main skill for deep dives
4. **Configuration decisions**: Use decision trees in QUICKSTART, validate with detailed info in main skill

### Quick Access by Topic

#### Architecture & Concepts
- **File**: juicefs-skill.md
- **Sections**: Overview, Architecture Components, Data Organization

#### Getting Started
- **File**: QUICKSTART.md or juicefs-skill.md (Installation section)
- **Key content**: Prerequisites, installation methods, first mount

#### Common Operations
- **File**: QUICKSTART.md (for quick patterns) or juicefs-skill.md (for all options)
- **Topics**: Format, mount, sync, benchmark, status

#### Integrations
- **File**: juicefs-skill.md (detailed) + QUICKSTART.md (Kubernetes quick deploy)
- **Topics**: Kubernetes, Hadoop, Docker

#### Performance
- **File**: juicefs-skill.md (Performance Optimization section) + QUICKSTART.md (decision trees)
- **Topics**: Cache configuration, tuning options, mount options by workload

#### Troubleshooting
- **File**: QUICKSTART.md (flowcharts) + juicefs-skill.md (detailed solutions)
- **Topics**: Common issues, monitoring, debugging

#### Security
- **File**: juicefs-skill.md (Security Best Practices section)
- **Topics**: Encryption, access control, network security, secrets management

#### Advanced Topics
- **File**: juicefs-skill.md
- **Topics**: Trash management, quota, compression, HA setup

## Search by Use Case

### "I need to set up JuiceFS for the first time"
1. Read: README.md (What is a Skill?)
2. Follow: QUICKSTART.md → Task 1: Create and Mount a New File System
3. Reference: juicefs-skill.md → Installation, Common Commands

### "I need to optimize performance for ML training"
1. Check: QUICKSTART.md → Decision Tree for mount options
2. Read: QUICKSTART.md → Example 3: ML Training Setup
3. Deep dive: juicefs-skill.md → Performance Optimization, Use Cases (ML Training)

### "I need to deploy JuiceFS on Kubernetes"
1. Quick start: QUICKSTART.md → Kubernetes Quick Deploy
2. Detailed guide: juicefs-skill.md → Kubernetes Integration
3. Reference: Official docs link in Resources section

### "I'm experiencing slow performance"
1. Diagnose: QUICKSTART.md → Troubleshooting Flowchart (Slow performance)
2. Solutions: juicefs-skill.md → Monitoring and Troubleshooting
3. Optimize: juicefs-skill.md → Performance Optimization

### "I need to choose a metadata engine"
1. Decision tree: QUICKSTART.md → "How do I choose a metadata engine?"
2. Comparison: juicefs-skill.md → Metadata Engines Comparison
3. Details: juicefs-skill.md → Architecture Components (Metadata Engine)

### "I want to compare JuiceFS with alternatives"
1. Read: juicefs-skill.md → Comparison with Alternatives
2. Use cases: juicefs-skill.md → Use Cases and Patterns

## Topic Index

### A
- Architecture → juicefs-skill.md (Architecture Components)
- Access Control → juicefs-skill.md (Security Best Practices)
- Advanced Features → juicefs-skill.md (Advanced Features)

### B
- Backup → juicefs-skill.md (Use Cases - Backup and Archival)
- Benchmarking → juicefs-skill.md (Common Commands #5), QUICKSTART.md (Task 2)
- Best Practices → juicefs-skill.md (Tips for AI Agents), QUICKSTART.md (Best Practices Checklist)

### C
- Cache Configuration → juicefs-skill.md (Performance Optimization), QUICKSTART.md (Decision Tree)
- Commands Reference → juicefs-skill.md (Quick Reference Commands), QUICKSTART.md (Command Templates)
- Compression → juicefs-skill.md (Advanced Features #4)
- Configuration → juicefs-skill.md (Common Commands #10)
- Containers → juicefs-skill.md (Docker Integration), QUICKSTART.md (Kubernetes Quick Deploy)

### D
- Data Organization → juicefs-skill.md (Data Organization)
- Docker → juicefs-skill.md (Docker Integration)

### E
- Encryption → juicefs-skill.md (Security Best Practices #1)
- Environment Variables → juicefs-skill.md (Environment Variables), QUICKSTART.md (Environment Variables Reference)

### F
- Format → juicefs-skill.md (Common Commands #1), QUICKSTART.md (Task 1)

### G
- Garbage Collection → juicefs-skill.md (Common Commands #9)
- Gateway Mode → juicefs-skill.md (Common Commands #7)

### H
- Hadoop → juicefs-skill.md (Hadoop Integration)
- High Availability → juicefs-skill.md (Common Workflows #4), QUICKSTART.md (Example 1)

### I
- Installation → juicefs-skill.md (Installation)
- Integration → juicefs-skill.md (Kubernetes, Hadoop, Docker Integration)

### K
- Kubernetes → juicefs-skill.md (Kubernetes Integration), QUICKSTART.md (Kubernetes Quick Deploy)

### M
- Machine Learning → juicefs-skill.md (Use Cases #2), QUICKSTART.md (Example 3)
- Metadata Engines → juicefs-skill.md (Architecture, Metadata Engines Comparison)
- Monitoring → juicefs-skill.md (Monitoring and Troubleshooting), QUICKSTART.md (Monitoring Commands)
- Mount → juicefs-skill.md (Common Commands #2), QUICKSTART.md (Task 1, Mount options by workload)

### O
- Object Storage → juicefs-skill.md (Architecture, Supported Object Storage)
- Optimization → juicefs-skill.md (Performance Optimization), QUICKSTART.md (Decision Trees)

### P
- Performance → juicefs-skill.md (Performance Optimization), QUICKSTART.md (Troubleshooting)
- POSIX Compatibility → juicefs-skill.md (Overview)

### Q
- Quota Management → juicefs-skill.md (Advanced Features #2)
- Quick Start → QUICKSTART.md

### R
- Redis → juicefs-skill.md (Architecture, Metadata Engines)

### S
- Security → juicefs-skill.md (Security Best Practices)
- Sync → juicefs-skill.md (Common Commands #6), QUICKSTART.md (Task 3)

### T
- Trash Management → juicefs-skill.md (Advanced Features #1)
- Troubleshooting → juicefs-skill.md (Monitoring and Troubleshooting), QUICKSTART.md (Troubleshooting Flowchart)

### U
- Unmount → juicefs-skill.md (Common Commands #3), QUICKSTART.md (Task 4)
- Use Cases → juicefs-skill.md (Use Cases and Patterns)

### W
- Workflows → juicefs-skill.md (Common Workflows for AI Agents), QUICKSTART.md (Common Task Patterns)

## Version Information

- **Skill Version**: 1.0
- **Based on JuiceFS**: Community Edition (latest as of 2024)
- **Last Updated**: February 2026

## External Resources

All external resource links are included in:
- juicefs-skill.md → Resources and Documentation section
- QUICKSTART.md → Quick Reference URLs section

## Contribution Guidelines

To contribute to this skill:
1. Fork the repository
2. Update the relevant file(s)
3. Ensure consistency across all documents
4. Update this table of contents if adding new sections
5. Submit a pull request

## License

This skill documentation is based on JuiceFS Community Edition (Apache License 2.0).

---

**For AI Agents**: This table of contents helps you quickly locate information. Use it as your first reference point when answering questions about JuiceFS.
