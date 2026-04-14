# Section 5: S3 (Simple Storage Service)

## S3 Overview

Object storage — not block storage, not file storage. Stores objects (files) in buckets. Bucket names are globally unique. Objects can be 0 bytes to 5 TB. Unlimited total storage. Key-value store: the key is the object name (path), the value is the data.

## Storage Classes

| Class | Durability | Availability | Min Duration | Use Case |
|-------|-----------|-------------|-------------|----------|
| Standard | 11 nines | 99.99% | None | Frequently accessed |
| Standard-IA | 11 nines | 99.9% | 30 days | Infrequent, rapid access needed |
| One Zone-IA | 11 nines | 99.5% | 30 days | Non-critical, recreatable |
| Glacier Instant | 11 nines | 99.9% | 90 days | Archive, millisecond retrieval |
| Glacier Flexible | 11 nines | 99.99% | 90 days | Archive, minutes to hours |
| Glacier Deep Archive | 11 nines | 99.99% | 180 days | Long-term archive, 12h retrieval |
| Intelligent-Tiering | 11 nines | 99.9% | None | Unknown access patterns |

> [!TIP]
> All S3 classes have 11 nines (99.999999999%) durability. The difference is availability, retrieval time, and cost.

## Security

**Bucket policies:** JSON resource-based policies controlling access at the bucket level. **ACLs:** Legacy method, avoid for new designs. **Block Public Access:** Account-level setting to prevent accidental public exposure. **Encryption:** SSE-S3 (AWS-managed keys, default), SSE-KMS (customer-managed via KMS), SSE-C (customer-provided keys), client-side encryption.

## CLI Examples

```bash
# Create a bucket
aws s3 mb s3://my-security-logs-2026 --region eu-north-1

# Upload a file
aws s3 cp ./report.pdf s3://my-security-logs-2026/reports/

# Sync a directory
aws s3 sync ./logs/ s3://my-security-logs-2026/logs/ --delete

# List objects
aws s3 ls s3://my-security-logs-2026/ --recursive --human-readable
```

## Key Features

**Versioning:** Keep multiple versions of an object. Protect against accidental deletion. Delete markers hide objects but don't remove them. MFA Delete requires MFA to permanently delete versions.

**Lifecycle Policies:** Automatically transition objects between storage classes or expire them. Example: move to Standard-IA after 30 days, Glacier after 90, delete after 365.

**Cross-Region Replication (CRR):** Replicate objects to a bucket in another region. Requires versioning enabled on both buckets. Use for disaster recovery, compliance, or latency reduction.

---

[⬅️ Back to AWS SAA-C03 Index](../)
