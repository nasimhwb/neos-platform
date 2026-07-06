# Neos Platform Shared Infrastructure - Scaling Strategies

This document provides a scaling playbook for transition from a single KVM VPS node to a highly-available, multi-node platform.

---

## 1. Vertical Scaling (Single Node Limits)

Before scaling horizontally, optimize VPS system resources:
- **Hostinger Upgrade**: Upgrading from KVM2 (4GB RAM) to KVM4 (16GB RAM) or KVM8 (32GB RAM) is the fastest, lowest-complexity option.
- **PostgreSQL Buffers**: Adjust `configs/postgres/postgresql.conf` values:
  - RAM = 16GB -> `shared_buffers = 4GB` (25%), `effective_cache_size = 12GB` (75%).
- **Redis Limits**: Increase `REDIS_MAXMEMORY` to match available memory.

---

## 2. Horizontal Database Scaling (PostgreSQL & Redis)

When read/write contention slows down database operations, split the database layer:

### PostgreSQL Replication
Move PostgreSQL to dedicated nodes using a Primary-Replica architecture:
1. **Primary Node**: Handles all write transactions (`INSERT`, `UPDATE`, `DELETE`).
2. **Replica Nodes**: Synchronize via WAL streaming replication to serve read transactions (`SELECT`).
3. **Connection Pooling**: Deploy **PgBouncer** in front of PostgreSQL to manage connection limits and route requests.

### Redis Cluster
Reconfigure Redis from a standalone node to a **Redis Cluster**:
- Shards key spaces across multiple Redis instances.
- Sets up primary-secondary replication for cache high-availability.

---

## 3. Storage Scaling (MinIO Distributed Mode)

To secure files against disk hardware failure and increase read/write I/O, migrate MinIO to **Distributed Mode**:

- **Erasure Coding**: Distribute object data blocks and parity blocks across a minimum of 4 distinct server nodes.
- **High Availability**: If a drive or node goes offline, MinIO continues serving requests using the remaining block structures.
- **Topology Example**:
  ```
  [MinIO Server 1] ---> Disk Mount (/data1)
  [MinIO Server 2] ---> Disk Mount (/data2)
  [MinIO Server 3] ---> Disk Mount (/data3)
  [MinIO Server 4] ---> Disk Mount (/data4)
  ```

---

## 4. Ingress and App Load Balancing

To handle high user loads and prevent single-node VPS failures from causing downtime:

1. **Load Balancer Layer**: Deploy two **HAProxy** or **Keepalived** nodes in active-passive mode (or leverage Cloudflare Load Balancers) to manage a Virtual IP (VIP).
2. **Application Worker Nodes**: Spin up multiple VPS nodes hosting Docker Compose worker containers.
3. **Shared Ingress**: Route public HTTPS traffic across Nginx nodes, which proxy connections to the backend application hosts.
