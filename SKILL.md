---
name: juicefs-skill
description: Work with JuiceFS, a high-performance POSIX file system for cloud-native environments. Use when dealing with distributed file systems, object storage backends (S3, Azure, GCS), metadata engines (Redis, MySQL, TiKV), or when users mention JuiceFS, cloud storage, big data, or ML training storage.
license: Apache-2.0
compatibility: Requires JuiceFS client, metadata engine (Redis/MySQL/TiKV/SQLite), and object storage access
metadata:
  author: yuhr123
  version: "1.0"
  based_on: JuiceFS Community Edition
---

# JuiceFS Skill

## Overview

JuiceFS is a high-performance POSIX file system designed for cloud-native environments. It separates data and metadata storage:
- **Data**: Stored in object storage (S3, GCS, Azure Blob, local disk, etc.)
- **Metadata**: Stored in databases (Redis, MySQL, PostgreSQL, TiKV, SQLite, etcd)
- **Client**: Mounts the file system and coordinates data/metadata

## When to Use This Skill

Use this skill when:
- Setting up or managing JuiceFS file systems
- Integrating JuiceFS with Kubernetes, Hadoop, or Docker
- Optimizing JuiceFS performance for specific workloads
- Troubleshooting JuiceFS issues
- Migrating data to/from JuiceFS
- Configuring JuiceFS for big data, ML training, or shared storage

## Core Concepts

### Architecture
```
┌─────────────┐
│ JuiceFS     │
│ Client      │
└──────┬──────┘
       │
    ┌──┴───────────┐
    │              │
┌───▼────┐    ┌───▼────────┐
│Metadata│    │Object      │
│Engine  │    │Storage     │
│(Redis) │    │(S3, etc.)  │
└────────┘    └────────────┘
```

### Data Organization
- **Files** → **Chunks** (max 64 MiB) → **Slices** (variable) → **Blocks** (4 MiB) → Object Storage

### Metadata Engines
- **Redis**: Best for production, fast, supports Sentinel/Cluster for HA
- **MySQL/PostgreSQL**: Good for production with existing infrastructure
- **TiKV**: Excellent for large-scale distributed deployments
- **SQLite**: Simple, single-node, good for testing/development
- **etcd**: Small to medium scale

## Essential Commands

### 1. Format a File System

Create a new JuiceFS file system:

```bash
# Basic format with Redis and S3
juicefs format \
    --storage s3 \
    --bucket https://mybucket.s3.amazonaws.com \
    redis://localhost:6379/1 \
    my-juicefs

# With compression
juicefs format \
    --storage s3 \
    --bucket https://mybucket.s3.amazonaws.com \
    --compress lz4 \
    redis://localhost:6379/1 \
    my-juicefs

# Local development with SQLite
juicefs format \
    --storage file \
    --bucket /data/storage \
    sqlite3://myjfs.db \
    dev-fs
```

### 2. Mount a File System

```bash
# Basic mount
juicefs mount redis://localhost:6379/1 /mnt/jfs

# Production mount with cache optimization
juicefs mount \
    --cache-dir /ssd/cache \
    --cache-size 204800 \
    --writeback \
    -d \
    redis://localhost:6379/1 \
    /mnt/jfs

# Mount with prefetch for read-heavy workloads
juicefs mount \
    --cache-dir /nvme/cache \
    --cache-size 409600 \
    --prefetch 3 \
    redis://localhost:6379/1 \
    /mnt/jfs
```

**Key Mount Options**:
- `--cache-dir`: Cache directory (default: `~/.juicefs/cache`)
- `--cache-size`: Cache size in MiB (default: 102400 = 100GB)
- `--writeback`: Enable write-back cache for better write performance
- `--prefetch N`: Enable read prefetch with N threads
- `--buffer-size`: Read buffer size in MiB (default: 300)
- `-d`: Run in background (daemon mode)

### 3. Unmount

```bash
# Graceful unmount
juicefs umount /mnt/jfs

# Force unmount
juicefs umount -f /mnt/jfs
```

### 4. Sync Data

```bash
# Sync local to JuiceFS
juicefs sync /local/path/ jfs://redis://localhost:6379/1/remote/path/

# Sync between JuiceFS file systems
juicefs sync jfs://redis://localhost:6379/1/src/ jfs://redis://localhost:6379/2/dst/

# Sync from S3 to JuiceFS
juicefs sync s3://bucket/path/ /mnt/jfs/path/

# Dry run
juicefs sync --dry-run /source/ /dest/
```

### 5. Status and Monitoring

```bash
# Show file system status
juicefs status redis://localhost:6379/1

# Real-time statistics
juicefs stats /mnt/jfs

# Profile operations
juicefs profile /mnt/jfs

# Benchmark
juicefs bench /mnt/jfs
```

### 6. Configuration

```bash
# View configuration
juicefs config redis://localhost:6379/1

# Set trash retention
juicefs config redis://localhost:6379/1 --trash-days 7

# Set capacity quota
juicefs config redis://localhost:6379/1 --capacity 1048576
```

### 7. Maintenance

```bash
# Garbage collection (dry run first)
juicefs gc redis://localhost:6379/1 --dry

# Actual garbage collection
juicefs gc redis://localhost:6379/1

# Dump metadata for backup
juicefs dump redis://localhost:6379/1 backup.json

# Load metadata from backup
juicefs load redis://localhost:6379/1 backup.json
```

### 8. S3 Gateway

```bash
# Start S3-compatible gateway
export MINIO_ROOT_USER=admin
export MINIO_ROOT_PASSWORD=12345678
juicefs gateway redis://localhost:6379/1 localhost:9000
```

## Configuration by Workload

### Big Data Processing (Hadoop/Spark)

```bash
juicefs mount \
    --cache-dir /ssd/cache \
    --cache-size 204800 \
    --writeback \
    redis://redis:6379/1 \
    /mnt/jfs
```

### Machine Learning Training

```bash
juicefs mount \
    --cache-dir /nvme/cache \
    --cache-size 409600 \
    --prefetch 3 \
    --buffer-size 600 \
    redis://redis:6379/1 \
    /mnt/ml-data
```

### Shared Development Environment

```bash
juicefs mount \
    --cache-size 102400 \
    redis://redis:6379/1 \
    /mnt/shared
```

### Backup/Archive (Write-heavy)

```bash
juicefs mount \
    --writeback \
    --buffer-size 600 \
    redis://redis:6379/1 \
    /mnt/backup
```

## Kubernetes Integration

### Basic PersistentVolume

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: juicefs-pv
spec:
  capacity:
    storage: 10Pi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  csi:
    driver: csi.juicefs.com
    volumeHandle: juicefs-volume
    fsType: juicefs
    nodePublishSecretRef:
      name: juicefs-secret
      namespace: default
```

## Troubleshooting

### Mount Fails

1. **Check metadata engine**: 
   ```bash
   # For Redis
   redis-cli -h localhost -p 6379 ping
   ```

2. **Check credentials**: Verify access keys for object storage

3. **Check logs**:
   ```bash
   tail -f /var/log/juicefs.log
   ```

### Slow Performance

1. **Check cache hit rate**:
   ```bash
   juicefs stats /mnt/jfs
   ```

2. **Increase cache**:
   ```bash
   juicefs umount /mnt/jfs
   juicefs mount --cache-size 204800 redis://localhost:6379/1 /mnt/jfs
   ```

3. **Enable prefetch for sequential reads**:
   ```bash
   juicefs mount --prefetch 3 redis://localhost:6379/1 /mnt/jfs
   ```

### No Space Left on Device

1. **Clean cache**:
   ```bash
   rm -rf ~/.juicefs/cache/*
   ```

2. **Increase free-space-ratio**:
   ```bash
   juicefs mount --free-space-ratio 0.2 redis://localhost:6379/1 /mnt/jfs
   ```

## Common Patterns

### Production Setup with HA

```bash
# Format with Redis Sentinel
juicefs format \
    --storage s3 \
    --bucket https://prod-bucket.s3.amazonaws.com \
    redis://sentinel1:26379,sentinel2:26379,sentinel3:26379/mymaster/1 \
    prod-fs

# Mount with optimized settings
juicefs mount \
    --cache-dir /ssd/cache \
    --cache-size 204800 \
    --writeback \
    -d \
    redis://sentinel1:26379,sentinel2:26379,sentinel3:26379/mymaster/1 \
    /mnt/jfs
```

### Development Setup

```bash
# Format with SQLite (local)
juicefs format \
    --storage file \
    --bucket /tmp/jfs-storage \
    sqlite3:///tmp/jfs.db \
    dev-fs

# Mount
juicefs mount sqlite3:///tmp/jfs.db /mnt/jfs-dev
```

### Data Migration

```bash
# Step 1: Mount source and destination
juicefs mount redis://source:6379/1 /mnt/source
juicefs mount redis://dest:6379/1 /mnt/dest

# Step 2: Sync data
juicefs sync /mnt/source/ /mnt/dest/

# Or use juicefs sync directly
juicefs sync jfs://redis://source:6379/1/ jfs://redis://dest:6379/1/
```

## Performance Tuning Quick Guide

| Workload | Cache Size | Cache Dir | Extra Options |
|----------|-----------|-----------|---------------|
| Read-heavy | 200-400GB | SSD/NVMe | `--prefetch 3` |
| Write-heavy | 100-200GB | SSD | `--writeback --buffer-size 600` |
| ML Training | 400GB+ | NVMe | `--prefetch 3 --cache-size 409600` |
| Mixed | 100-200GB | SSD | Default |
| Small files | 100GB | SSD | `--prefetch 1` |

## Security Best Practices

1. **Enable encryption**:
   ```bash
   juicefs format --encrypt-secret redis://localhost:6379/1 secure-fs
   ```

2. **Use TLS for metadata engine**: Connect via `rediss://` instead of `redis://`

3. **Use HTTPS for object storage**: Always use HTTPS endpoints

4. **IAM roles**: Use IAM roles instead of access keys when possible

5. **Network isolation**: Use VPC/private networks for production

## Environment Variables

```bash
# AWS credentials
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret

# Redis password
export REDIS_PASSWORD=your-password

# Custom cache
export JUICEFS_CACHE_DIR=/ssd/cache

# Debug logging
export JUICEFS_LOGLEVEL=debug
```

## Quick Decision Trees

### Choosing a Metadata Engine

- **Redis**: Fast, production-ready, supports HA (Sentinel/Cluster)
- **MySQL/PostgreSQL**: Already have infrastructure, need SQL features
- **TiKV**: Large scale, need horizontal scalability
- **SQLite**: Development, testing, single node
- **etcd**: Small to medium scale, already using etcd

### Choosing Cache Size

- **Working set < 100GB**: 100GB cache (102400 MiB)
- **Working set 100-500GB**: 200-400GB cache
- **Working set > 500GB**: 400GB+ cache
- **Rule of thumb**: 10-20% of working set size

## References

For detailed information, see the references:

- [Comprehensive Reference](references/COMPREHENSIVE_REFERENCE.md) - Complete JuiceFS documentation
- [Quick Start Guide](references/QUICKSTART.md) - Task patterns and troubleshooting flowcharts
- [Table of Contents](references/TABLE_OF_CONTENTS.md) - Index of all topics

## Resources

- **Official Documentation**: https://juicefs.com/docs/community/introduction
- **GitHub Repository**: https://github.com/juicedata/juicefs
- **Quick Start**: https://juicefs.com/docs/community/quick_start_guide
- **Command Reference**: https://juicefs.com/docs/community/command_reference
- **Community**: https://github.com/juicedata/juicefs/discussions

## Installation

```bash
# Linux AMD64
curl -sSL https://d.juicefs.com/install | sh -

# macOS (Homebrew)
brew install juicefs

# Docker
docker pull juicedata/juicefs
```

## Tips for AI Agents

1. Always check metadata engine connectivity first
2. Cache is critical - allocate sufficient space on fast storage
3. Use `--writeback` for write-heavy, `--prefetch` for read-heavy workloads
4. Monitor with `juicefs stats` regularly
5. Test with `juicefs bench` before production
6. Plan for metadata engine HA in production
7. Use compression (`--compress lz4`) to reduce costs
8. Enable trash (`--trash-days 7`) for safety
9. Run `juicefs gc` regularly
10. Keep JuiceFS client updated
