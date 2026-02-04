# JuiceFS Community Edition Skill

## Overview

JuiceFS is a high-performance POSIX file system designed for cloud-native environments. It separates data and metadata storage, persisting data in object storage (like Amazon S3) and metadata in various database engines (Redis, MySQL, TiKV, etc.).

**Key Characteristics:**
- **License**: Apache License 2.0
- **Architecture**: Client-Server model with separated data and metadata storage
- **Use Cases**: Big data, machine learning, AI platforms, cloud storage
- **Compatibility**: Fully POSIX-compatible, Hadoop-compatible, S3-compatible

## Architecture Components

### 1. JuiceFS Client
- Coordinates object storage and metadata engine
- Implements file system interfaces (POSIX, Hadoop, Kubernetes, S3 gateway)
- Handles file operations and caching

### 2. Data Storage
- Stores actual file data
- Supports multiple storage backends:
  - Local disk
  - Cloud object storage (S3, GCS, Azure Blob, Alibaba OSS, Tencent COS, etc.)
  - HDFS
  - MinIO, Ceph RGW

### 3. Metadata Engine
- Stores file metadata (name, size, permissions, timestamps, directory structure)
- Supported engines:
  - **Redis**: Fast, in-memory, ideal for metadata
  - **MySQL/PostgreSQL**: Relational databases
  - **SQLite**: Lightweight, single-file database
  - **TiKV**: Distributed key-value store
  - **etcd**: Distributed key-value store
  - **Redis Cluster**: Distributed Redis (v1.0.0-beta3+)

## Data Organization

JuiceFS splits files into a hierarchical structure:

1. **File** → Multiple **Chunks** (default: max 64 MiB each)
2. **Chunk** → One or more **Slices** (variable length based on write patterns)
3. **Slice** → Multiple **Blocks** (default: 4 MiB each)
4. **Blocks** → Stored in object storage

## Installation

### Download and Install

```bash
# Linux AMD64
curl -sSL https://d.juicefs.com/install | sh -

# macOS (using Homebrew)
brew install juicefs

# From source
git clone https://github.com/juicedata/juicefs.git
cd juicefs
make
```

### Docker
```bash
docker pull juicedata/juicefs
```

## Common Commands and Usage

### 1. Format a File System

Create a new JuiceFS file system:

```bash
# With Redis metadata engine
juicefs format \
    --storage s3 \
    --bucket https://mybucket.s3.amazonaws.com \
    --access-key <ACCESS_KEY> \
    --secret-key <SECRET_KEY> \
    redis://localhost:6379/1 \
    my-juicefs

# With MySQL metadata engine
juicefs format \
    --storage s3 \
    --bucket https://mybucket.s3.amazonaws.com \
    "mysql://user:password@(localhost:3306)/juicefs" \
    my-juicefs

# With SQLite (local metadata)
juicefs format \
    --storage file \
    --bucket /data/storage \
    sqlite3://myjfs.db \
    my-juicefs
```

### 2. Mount a File System

```bash
# Basic mount
juicefs mount redis://localhost:6379/1 /mnt/jfs

# Mount with options
juicefs mount \
    -d \
    --cache-dir /var/cache/jfs \
    --cache-size 102400 \
    redis://localhost:6379/1 \
    /mnt/jfs

# Mount in foreground (for debugging)
juicefs mount redis://localhost:6379/1 /mnt/jfs

# Mount with specific cache settings
juicefs mount \
    --cache-dir /mycache \
    --cache-size 204800 \
    --buffer-size 600 \
    redis://localhost:6379/1 \
    /mnt/jfs
```

### 3. Unmount

```bash
# Unmount gracefully
juicefs umount /mnt/jfs

# Force unmount
juicefs umount -f /mnt/jfs
```

### 4. File System Status

```bash
# Show file system information
juicefs status redis://localhost:6379/1

# Show detailed statistics
juicefs info /mnt/jfs
```

### 5. Benchmarking

```bash
# Run built-in benchmark
juicefs bench /mnt/jfs

# Custom benchmark with fio
fio --name=sequential-read --directory=/mnt/jfs --rw=read --refill_buffers --bs=4M --size=4G
```

### 6. Data Synchronization

```bash
# Sync between local and JuiceFS
juicefs sync /local/path/ jfs://redis://localhost:6379/1/remote/path/

# Sync between two JuiceFS file systems
juicefs sync jfs://redis://localhost:6379/1/src/ jfs://redis://localhost:6379/2/dst/

# Sync from object storage
juicefs sync s3://mybucket/path/ /mnt/jfs/path/
```

### 7. Gateway Mode (S3-compatible API)

```bash
# Start S3 gateway
juicefs gateway redis://localhost:6379/1 localhost:9000

# With authentication
export MINIO_ROOT_USER=admin
export MINIO_ROOT_PASSWORD=12345678
juicefs gateway redis://localhost:6379/1 localhost:9000
```

### 8. Dump and Load Metadata

```bash
# Dump metadata to JSON
juicefs dump redis://localhost:6379/1 dump.json

# Load metadata from JSON
juicefs load redis://localhost:6379/1 dump.json
```

### 9. Garbage Collection

```bash
# Check for leaked objects
juicefs gc redis://localhost:6379/1 --dry

# Perform garbage collection
juicefs gc redis://localhost:6379/1

# Compact metadata
juicefs gc redis://localhost:6379/1 --compact
```

### 10. Configuration Management

```bash
# Show configuration
juicefs config redis://localhost:6379/1

# Modify configuration
juicefs config redis://localhost:6379/1 --trash-days 7
juicefs config redis://localhost:6379/1 --capacity 1048576
```

## Kubernetes Integration

### Using CSI Driver

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

### As a PersistentVolumeClaim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: juicefs-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: juicefs-sc
  resources:
    requests:
      storage: 10Gi
```

## Hadoop Integration

### Configure Hadoop

Add to `core-site.xml`:

```xml
<configuration>
  <property>
    <name>fs.jfs.impl</name>
    <value>io.juicefs.JuiceFileSystem</value>
  </property>
  <property>
    <name>fs.AbstractFileSystem.jfs.impl</name>
    <value>io.juicefs.JuiceFS</value>
  </property>
  <property>
    <name>juicefs.meta</name>
    <value>redis://localhost:6379/1</value>
  </property>
</configuration>
```

### Access JuiceFS in Hadoop

```bash
# List files
hadoop fs -ls jfs://my-juicefs/

# Copy files
hadoop fs -put local-file jfs://my-juicefs/path/
hadoop fs -get jfs://my-juicefs/path/file local-file
```

## Docker Integration

### Mount JuiceFS in Docker

```bash
# Create a volume
docker volume create \
    --driver local \
    --opt type=none \
    --opt device=/mnt/jfs \
    --opt o=bind \
    juicefs-vol

# Use the volume
docker run -it \
    --volume juicefs-vol:/data \
    ubuntu:latest \
    /bin/bash
```

### Using Docker Compose

```yaml
version: '3'
services:
  app:
    image: myapp:latest
    volumes:
      - type: bind
        source: /mnt/jfs
        target: /data
```

## Performance Optimization

### Cache Configuration

```bash
# Mount with optimized cache
juicefs mount \
    --cache-dir /ssd/cache \
    --cache-size 204800 \
    --free-space-ratio 0.1 \
    --cache-partial-only=false \
    redis://localhost:6379/1 \
    /mnt/jfs
```

### Tuning Options

- **--cache-size**: Set cache size in MiB (default: 102400)
- **--cache-dir**: Cache directory path (default: `$HOME/.juicefs/cache`)
- **--free-space-ratio**: Minimum free space ratio (default: 0.1)
- **--buffer-size**: Read buffer size in MiB (default: 300)
- **--prefetch**: Number of prefetch threads (default: 1)
- **--writeback**: Enable write-back cache
- **--upload-limit**: Upload bandwidth limit in Mbps
- **--download-limit**: Download bandwidth limit in Mbps

### Metadata Optimization

For Redis:
```bash
# Redis persistence configuration
# In redis.conf:
save 900 1
save 300 10
save 60 10000

# Enable AOF for better durability
appendonly yes
appendfsync everysec
```

## Monitoring and Troubleshooting

### Real-time Monitoring

```bash
# Show real-time statistics
juicefs stats /mnt/jfs

# Show access log
juicefs profile /mnt/jfs

# Monitor specific process
juicefs profile /mnt/jfs --interval 1
```

### Checking Logs

```bash
# View mount log
tail -f /var/log/juicefs.log

# View with specific log level
juicefs mount --debug redis://localhost:6379/1 /mnt/jfs
```

### Common Issues and Solutions

#### 1. Mount fails with "connection refused"
- **Cause**: Cannot connect to metadata engine
- **Solution**: 
  - Check metadata engine is running
  - Verify connection string
  - Check network connectivity

#### 2. Slow performance
- **Cause**: Insufficient cache, network latency, or metadata engine bottleneck
- **Solution**:
  - Increase cache size: `--cache-size`
  - Use SSD for cache: `--cache-dir /ssd/cache`
  - Optimize metadata engine (Redis tuning)
  - Enable prefetch: `--prefetch 3`

#### 3. High memory usage
- **Cause**: Large cache or many open files
- **Solution**:
  - Reduce cache size
  - Limit buffer size: `--buffer-size 300`
  - Close unused files

#### 4. "No space left on device"
- **Cause**: Cache directory full
- **Solution**:
  - Clean cache: `rm -rf ~/.juicefs/cache/*`
  - Increase free-space-ratio: `--free-space-ratio 0.2`
  - Use larger cache directory

#### 5. Metadata engine connection lost
- **Cause**: Network issue or metadata engine crash
- **Solution**:
  - Check metadata engine status
  - Verify network connectivity
  - Consider using highly available setup (Redis Sentinel, Redis Cluster)

## Security Best Practices

### 1. Data Encryption

```bash
# Enable encryption at rest
juicefs format \
    --encrypt-secret \
    --storage s3 \
    redis://localhost:6379/1 \
    my-secure-jfs

# Data in transit is encrypted by default via HTTPS/TLS
```

### 2. Access Control

```bash
# Mount with specific permissions
juicefs mount \
    --uid 1000 \
    --gid 1000 \
    redis://localhost:6379/1 \
    /mnt/jfs

# Use extended attributes for fine-grained control
setfacl -m u:user:rwx /mnt/jfs/directory
```

### 3. Network Security

- Use TLS for metadata engine connections
- Use HTTPS for object storage
- Configure firewall rules
- Use VPC/private networks

### 4. Secrets Management

```bash
# Use environment variables for credentials
export AWS_ACCESS_KEY_ID=<your-access-key>
export AWS_SECRET_ACCESS_KEY=<your-secret-key>

# Or use IAM roles (recommended for cloud environments)
juicefs mount --storage s3 redis://localhost:6379/1 /mnt/jfs
```

## Advanced Features

### 1. Trash Management

```bash
# Enable trash (deleted files kept for 1 day by default)
juicefs config redis://localhost:6379/1 --trash-days 7

# Disable trash
juicefs config redis://localhost:6379/1 --trash-days 0
```

### 2. Quota Management

```bash
# Set capacity quota
juicefs config redis://localhost:6379/1 --capacity 1048576  # 1 PiB

# Set inode quota
juicefs config redis://localhost:6379/1 --inodes 10000000
```

### 3. Snapshot (Planned Feature)

Currently in roadmap, will allow:
- Point-in-time file system snapshots
- Quick backup and restore
- Testing and development environments

### 4. Compression

```bash
# Format with compression (LZ4 or Zstandard)
juicefs format \
    --compress lz4 \
    redis://localhost:6379/1 \
    my-jfs

# Or use zstd for better compression ratio
juicefs format \
    --compress zstd \
    redis://localhost:6379/1 \
    my-jfs
```

### 5. Multi-Region Replication

```bash
# Configure multiple object storage endpoints
# This is done at the object storage level, not JuiceFS
# JuiceFS automatically uses the configured object storage replication
```

## Use Cases and Patterns

### 1. Big Data Processing

```bash
# Mount JuiceFS for Hadoop/Spark workloads
juicefs mount \
    --cache-dir /ssd/cache \
    --cache-size 204800 \
    --writeback \
    redis://localhost:6379/1 \
    /mnt/jfs

# Access via Hadoop
hadoop fs -ls jfs://my-juicefs/data/
spark-submit --master yarn my-job.py jfs://my-juicefs/input/
```

### 2. Machine Learning Training

```bash
# Mount with optimized settings for ML workloads
juicefs mount \
    --prefetch 3 \
    --cache-size 409600 \
    --cache-dir /nvme/cache \
    redis://localhost:6379/1 \
    /mnt/ml-data

# Training data can now be accessed like local files
python train.py --data-dir /mnt/ml-data/datasets/
```

### 3. Shared Development Environment

```bash
# Multiple developers can mount the same file system
# Developer 1:
juicefs mount redis://redis.company.com:6379/1 /mnt/shared

# Developer 2:
juicefs mount redis://redis.company.com:6379/1 /mnt/shared

# Changes are immediately visible to all users (strong consistency)
```

### 4. Backup and Archival

```bash
# Sync local data to JuiceFS for backup
juicefs sync /important/data/ jfs://redis://localhost:6379/1/backups/

# Restore from backup
juicefs sync jfs://redis://localhost:6379/1/backups/ /restored/data/
```

### 5. Container Persistent Storage

```yaml
# Kubernetes StatefulSet with JuiceFS
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 3
  template:
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        volumeMounts:
        - name: mysql-data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: mysql-data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: juicefs-sc
      resources:
        requests:
          storage: 10Gi
```

## Comparison with Alternatives

### JuiceFS vs Alluxio
- **JuiceFS**: Simpler architecture, POSIX-compliant, better for cloud-native
- **Alluxio**: More features for data orchestration, better for hybrid cloud

### JuiceFS vs CephFS
- **JuiceFS**: Easier to deploy, better cloud integration, uses object storage
- **CephFS**: Better for on-premise, integrated with Ceph ecosystem

### JuiceFS vs NFS
- **JuiceFS**: Scalable, cloud-native, better performance with object storage
- **NFS**: Traditional, simple setup for small scale

### JuiceFS vs EFS (AWS)
- **JuiceFS**: Portable across clouds, customizable, potentially lower cost
- **EFS**: Fully managed, integrated with AWS services

## Metadata Engines Comparison

| Engine | Performance | Scalability | HA Support | Use Case |
|--------|-------------|-------------|------------|----------|
| Redis | Excellent | Good | Yes (Sentinel/Cluster) | Production (most common) |
| MySQL | Good | Good | Yes (Replication) | Production |
| PostgreSQL | Good | Good | Yes (Replication) | Production |
| TiKV | Good | Excellent | Yes (Built-in) | Large scale |
| SQLite | Good | Limited | No | Single node, testing |
| etcd | Good | Good | Yes (Built-in) | Small scale |

## Quick Reference Commands

```bash
# Format
juicefs format [OPTIONS] META-URL NAME

# Mount
juicefs mount [OPTIONS] META-URL MOUNTPOINT

# Unmount
juicefs umount [OPTIONS] MOUNTPOINT

# Status
juicefs status META-URL

# Info
juicefs info PATH

# Sync
juicefs sync [OPTIONS] SRC DST

# Gateway
juicefs gateway [OPTIONS] META-URL ADDRESS

# Bench
juicefs bench [OPTIONS] PATH

# GC
juicefs gc [OPTIONS] META-URL

# Config
juicefs config META-URL [OPTIONS]

# Dump
juicefs dump [OPTIONS] META-URL FILE

# Load
juicefs load [OPTIONS] META-URL FILE

# Stats
juicefs stats PATH

# Profile
juicefs profile PATH
```

## Environment Variables

```bash
# AWS credentials
export AWS_ACCESS_KEY_ID=<key>
export AWS_SECRET_ACCESS_KEY=<secret>

# Redis password
export REDIS_PASSWORD=<password>

# Cache directory
export JUICEFS_CACHE_DIR=/ssd/cache

# Log level
export JUICEFS_LOGLEVEL=debug

# No usage reporting
export JUICEFS_NO_USAGE_REPORT=1
```

## Resources and Documentation

- **Official Documentation**: https://juicefs.com/docs/community/introduction
- **GitHub Repository**: https://github.com/juicedata/juicefs
- **Quick Start Guide**: https://juicefs.com/docs/community/quick_start_guide
- **Command Reference**: https://juicefs.com/docs/community/command_reference
- **Community Forum**: https://github.com/juicedata/juicefs/discussions
- **Slack Channel**: https://go.juicefs.com/slack

## Common Workflows for AI Agents

### Workflow 1: Setting Up a New JuiceFS File System

1. Choose and set up metadata engine (Redis recommended)
2. Choose and configure object storage
3. Format the file system with `juicefs format`
4. Mount the file system with `juicefs mount`
5. Verify with basic operations (create, read, write, delete)
6. Configure caching and performance options
7. Set up monitoring

### Workflow 2: Migrating Data to JuiceFS

1. Mount JuiceFS file system
2. Use `juicefs sync` to transfer data
3. Verify data integrity
4. Update application configurations
5. Monitor performance and adjust cache settings

### Workflow 3: Troubleshooting Performance Issues

1. Check `juicefs stats` for real-time metrics
2. Review mount options (cache size, buffer size)
3. Check metadata engine performance
4. Verify network connectivity and bandwidth
5. Review object storage performance
6. Adjust mount options and remount if needed

### Workflow 4: Setting Up High Availability

1. Configure HA for metadata engine (Redis Sentinel/Cluster)
2. Use replicated object storage
3. Deploy multiple JuiceFS clients
4. Configure automatic failover
5. Test failover scenarios
6. Set up monitoring and alerts

## Tips for AI Agents

1. **Always check metadata engine connectivity first** before troubleshooting other issues
2. **Cache is critical for performance** - allocate sufficient cache space on fast storage (SSD/NVMe)
3. **Use appropriate mount options** for the workload (e.g., `--writeback` for write-heavy, `--prefetch` for read-heavy)
4. **Monitor regularly** using `juicefs stats` and `juicefs profile`
5. **Test before production** - use `juicefs bench` to validate performance
6. **Plan for metadata engine HA** in production environments
7. **Use compression** (`--compress lz4`) to reduce storage costs
8. **Enable trash** for accidental deletion protection
9. **Regular garbage collection** to reclaim leaked storage
10. **Keep JuiceFS client updated** for bug fixes and performance improvements

## Version Compatibility

- JuiceFS storage format is stable and forward-compatible
- Metadata format is compatible across versions
- Always use matching client versions for best compatibility
- Check release notes when upgrading for breaking changes

## License and Support

- **License**: Apache License 2.0
- **Community Support**: GitHub Issues, Discussions, Slack
- **Enterprise Support**: Available from JuiceData Inc.
- **Contributing**: See contributing guide at https://juicefs.com/docs/community/development/contributing_guide
