# Section 8: Databases

## Choosing the Right Database

| Need | Service | Type |
|------|---------|------|
| Relational, managed | RDS | MySQL, PostgreSQL, MariaDB, Oracle, SQL Server |
| Relational, cloud-native | Aurora | MySQL/PostgreSQL compatible, 5x faster |
| Key-value, millisecond latency | DynamoDB | NoSQL, serverless, auto-scaling |
| In-memory cache | ElastiCache | Redis or Memcached |
| Data warehouse | Redshift | Columnar, petabyte-scale analytics |
| Document | DocumentDB | MongoDB compatible |
| Graph | Neptune | Relationships, fraud detection |
| Time series | Timestream | IoT, DevOps metrics |

## RDS (Relational Database Service)

Managed relational database. AWS handles: provisioning, patching, backups, failover. You handle: schema, queries, application code, performance tuning.

**Multi-AZ:** Synchronous standby in another AZ. Automatic failover. For HA, not for read scaling.

**Read Replicas:** Asynchronous copies for read-heavy workloads. Can be cross-region. For performance, not for HA.

> [!IMPORTANT]
> Multi-AZ = high availability (automatic failover). Read Replicas = performance (offload reads). Know the difference for the exam.

## Aurora

MySQL and PostgreSQL compatible. Storage auto-scales in 10 GB increments up to 128 TB. 6 copies of data across 3 AZs. Continuous backup to S3. Instant crash recovery. Aurora Serverless scales compute automatically.

## DynamoDB

Fully managed NoSQL. Single-digit millisecond performance at any scale. Serverless — no infrastructure to manage. On-demand or provisioned capacity. DynamoDB Accelerator (DAX) adds microsecond caching layer. Global Tables for multi-region replication.

---

[⬅️ Back to AWS SAA-C03 Index](../)
