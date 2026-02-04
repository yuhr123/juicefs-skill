# JuiceFS Quick Start Guide for AI Agents

This guide provides a quick reference for AI agents to get started with JuiceFS operations.

## Prerequisites Check

Before working with JuiceFS, verify:
1. Metadata engine is available (Redis, MySQL, etc.)
2. Object storage is configured (S3, local, etc.)
3. JuiceFS client is installed

## Common Task Patterns

### Task 1: Create and Mount a New File System

```bash
# Step 1: Format the file system
juicefs format \
    --storage s3 \
    --bucket https://mybucket.s3.amazonaws.com \
    redis://localhost:6379/1 \
    my-fs

# Step 2: Mount the file system
juicefs mount redis://localhost:6379/1 /mnt/jfs

# Step 3: Verify
df -h /mnt/jfs
ls -la /mnt/jfs
```

### Task 2: Quick Performance Test

```bash
# Run benchmark
juicefs bench /mnt/jfs

# Check stats
juicefs stats /mnt/jfs
```

### Task 3: Sync Data

```bash
# From local to JuiceFS
juicefs sync /source/path/ jfs://redis://localhost:6379/1/dest/path/

# From JuiceFS to local
juicefs sync jfs://redis://localhost:6379/1/source/path/ /dest/path/
```

### Task 4: Troubleshooting

```bash
# Check status
juicefs status redis://localhost:6379/1

# View real-time stats
juicefs stats /mnt/jfs

# Check logs
tail -f /var/log/juicefs.log

# Unmount if stuck
juicefs umount -f /mnt/jfs
```

## Decision Tree for Common Questions

### "How do I choose a metadata engine?"

- **Small scale, testing**: SQLite
- **Production, single node**: Redis
- **Production, HA needed**: Redis Sentinel or Redis Cluster
- **Large scale distributed**: TiKV
- **Existing infrastructure**: MySQL/PostgreSQL

### "What cache size should I use?"

- **General purpose**: 100GB (102400 MiB)
- **Read-heavy workload**: 200-400GB
- **Write-heavy workload**: 100-200GB with --writeback
- **ML training**: 400GB+ on NVMe
- **Rule of thumb**: 10-20% of working set size

### "Which mount options for my workload?"

**Read-heavy (data analytics)**:
```bash
juicefs mount --prefetch 3 --cache-size 204800 redis://localhost:6379/1 /mnt/jfs
```

**Write-heavy (logging, backups)**:
```bash
juicefs mount --writeback --buffer-size 600 redis://localhost:6379/1 /mnt/jfs
```

**ML training (mixed)**:
```bash
juicefs mount --prefetch 3 --cache-size 409600 --cache-dir /nvme/cache redis://localhost:6379/1 /mnt/jfs
```

**Shared development**:
```bash
juicefs mount --cache-size 102400 redis://localhost:6379/1 /mnt/jfs
```

## Troubleshooting Flowchart

### Issue: Mount fails

1. **Check metadata engine**
   ```bash
   # For Redis
   redis-cli -h localhost -p 6379 ping
   ```

2. **Check credentials**
   - Verify access keys for object storage
   - Check Redis/MySQL password

3. **Check network**
   ```bash
   telnet localhost 6379  # For Redis
   curl -I https://mybucket.s3.amazonaws.com  # For S3
   ```

### Issue: Slow performance

1. **Check cache**
   ```bash
   juicefs stats /mnt/jfs  # Look at cache hit rate
   ```

2. **Increase cache if needed**
   ```bash
   juicefs umount /mnt/jfs
   juicefs mount --cache-size 204800 redis://localhost:6379/1 /mnt/jfs
   ```

3. **Check metadata engine performance**
   ```bash
   # For Redis
   redis-cli --latency -h localhost -p 6379
   ```

4. **Enable prefetch for sequential reads**
   ```bash
   juicefs mount --prefetch 3 redis://localhost:6379/1 /mnt/jfs
   ```

### Issue: No space left on device

1. **Clean cache**
   ```bash
   rm -rf ~/.juicefs/cache/*
   ```

2. **Increase free space ratio**
   ```bash
   juicefs mount --free-space-ratio 0.2 redis://localhost:6379/1 /mnt/jfs
   ```

## Command Templates

### Format Command Template

```bash
juicefs format \
    --storage <STORAGE_TYPE> \
    --bucket <BUCKET_URL> \
    [--access-key <KEY>] \
    [--secret-key <SECRET>] \
    [--compress <lz4|zstd>] \
    <META_URL> \
    <NAME>
```

### Mount Command Template

```bash
juicefs mount \
    [--cache-dir <DIR>] \
    [--cache-size <SIZE_MiB>] \
    [--prefetch <N>] \
    [--writeback] \
    [--buffer-size <SIZE_MiB>] \
    [-d] \
    <META_URL> \
    <MOUNTPOINT>
```

### Sync Command Template

```bash
juicefs sync \
    [--threads <N>] \
    [--update] \
    [--delete-src] \
    [--delete-dst] \
    [--dry-run] \
    <SRC> \
    <DST>
```

## Example Configurations

### Example 1: Production Setup with Redis Sentinel

```bash
# Format
juicefs format \
    --storage s3 \
    --bucket https://prod-bucket.s3.amazonaws.com \
    redis://sentinel1:26379,sentinel2:26379,sentinel3:26379/mymaster/1 \
    prod-fs

# Mount with HA
juicefs mount \
    --cache-dir /ssd/cache \
    --cache-size 204800 \
    --writeback \
    redis://sentinel1:26379,sentinel2:26379,sentinel3:26379/mymaster/1 \
    /mnt/jfs
```

### Example 2: Development Setup with SQLite

```bash
# Format
juicefs format \
    --storage file \
    --bucket /tmp/jfs-storage \
    sqlite3:///tmp/jfs.db \
    dev-fs

# Mount
juicefs mount sqlite3:///tmp/jfs.db /mnt/jfs-dev
```

### Example 3: ML Training Setup

```bash
# Format with compression
juicefs format \
    --storage s3 \
    --bucket https://ml-data.s3.amazonaws.com \
    --compress lz4 \
    redis://redis-cluster:6379/1 \
    ml-fs

# Mount with optimized settings
juicefs mount \
    --cache-dir /nvme/jfs-cache \
    --cache-size 409600 \
    --prefetch 3 \
    --buffer-size 600 \
    redis://redis-cluster:6379/1 \
    /mnt/ml-data
```

## Kubernetes Quick Deploy

```yaml
# 1. Create secret
apiVersion: v1
kind: Secret
metadata:
  name: juicefs-secret
type: Opaque
stringData:
  name: "my-juicefs"
  metaurl: "redis://redis-service:6379/1"
  storage: "s3"
  bucket: "https://mybucket.s3.amazonaws.com"
  access-key: "your-access-key"
  secret-key: "your-secret-key"

---
# 2. Create PVC
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

---
# 3. Use in Pod
apiVersion: v1
kind: Pod
metadata:
  name: juicefs-app
spec:
  containers:
  - name: app
    image: centos
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo $(date) >> /data/out.txt; sleep 5; done"]
    volumeMounts:
    - name: juicefs-volume
      mountPath: /data
  volumes:
  - name: juicefs-volume
    persistentVolumeClaim:
      claimName: juicefs-pvc
```

## Monitoring Commands

```bash
# Real-time stats (refresh every 1 second)
juicefs stats /mnt/jfs

# Profile operations
juicefs profile /mnt/jfs

# Check info for a specific file
juicefs info /mnt/jfs/myfile

# View configuration
juicefs config redis://localhost:6379/1

# Check status
juicefs status redis://localhost:6379/1
```

## Maintenance Tasks

### Daily
- Monitor cache hit rate: `juicefs stats /mnt/jfs`
- Check metadata engine health

### Weekly
- Review logs for errors: `grep ERROR /var/log/juicefs.log`
- Check disk space for cache directory
- Monitor performance metrics

### Monthly
- Run garbage collection: `juicefs gc redis://localhost:6379/1`
- Review and clean old trash: `juicefs config redis://localhost:6379/1 --trash-days 1`
- Update JuiceFS client if new version available
- Backup metadata: `juicefs dump redis://localhost:6379/1 backup.json`

## Quick Reference URLs

- Command reference: https://juicefs.com/docs/community/command_reference
- Performance tuning: https://juicefs.com/docs/community/cache
- Troubleshooting: https://juicefs.com/docs/community/fault_diagnosis_and_analysis
- Kubernetes guide: https://juicefs.com/docs/community/how_to_use_on_kubernetes

## Environment Variables Reference

```bash
# AWS credentials
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret

# Redis password
export REDIS_PASSWORD=your-password

# Custom cache directory
export JUICEFS_CACHE_DIR=/ssd/cache

# Debug logging
export JUICEFS_LOGLEVEL=debug

# Disable usage reporting
export JUICEFS_NO_USAGE_REPORT=1
```

## Best Practices Checklist

- [ ] Use Redis or distributed metadata engine for production
- [ ] Enable trash for accidental deletion protection (--trash-days 7)
- [ ] Configure appropriate cache size (at least 100GB)
- [ ] Use SSD/NVMe for cache directory
- [ ] Enable compression to reduce storage costs (--compress lz4)
- [ ] Set up monitoring with `juicefs stats`
- [ ] Regular garbage collection (weekly/monthly)
- [ ] Backup metadata regularly with `juicefs dump`
- [ ] Use HA setup for metadata engine (Sentinel/Cluster)
- [ ] Test failover procedures
- [ ] Document your JuiceFS configuration
- [ ] Keep JuiceFS client updated
