# Section 6: EC2 (Elastic Compute Cloud)

## EC2 Overview

Virtual servers in the cloud. IaaS — you manage OS, patching, applications. Choice of instance types optimized for different workloads.

## Instance Types

| Family | Optimized For | Example Use |
|--------|--------------|-------------|
| T (burstable) | General purpose, variable workloads | Web servers, dev environments |
| M | General purpose, balanced | Application servers |
| C | Compute | Batch processing, ML inference, gaming |
| R | Memory | In-memory databases, real-time analytics |
| I/D | Storage | Data warehousing, distributed file systems |
| G/P | GPU | ML training, video rendering |

Naming: **m5.xlarge** = family(m) generation(5) . size(xlarge)

## Key Concepts

**AMI (Amazon Machine Image):** Template for launching instances. Contains OS, pre-installed software, configuration. Can create custom AMIs from existing instances.

**EBS (Elastic Block Store):** Network-attached block storage for EC2. Persists independently from the instance. Snapshots for backup (stored in S3). Types: gp3 (general SSD), io2 (high-performance SSD), st1 (throughput HDD), sc1 (cold HDD).

**Instance Store:** Physically attached storage. Highest performance but ephemeral — data lost when instance stops or terminates.

**User Data:** Script that runs on first boot. Use for automated setup (install packages, configure services, pull code).

**Security Groups:** Instance-level firewall. Stateful — if inbound is allowed, outbound response is automatic.

## Purchase Options

| Option | Commitment | Savings | Use Case |
|--------|-----------|---------|----------|
| On-Demand | None | 0% | Unpredictable workloads, testing |
| Reserved (1-3yr) | 1 or 3 years | Up to 72% | Steady-state production |
| Spot | None, can be interrupted | Up to 90% | Fault-tolerant batch jobs |
| Dedicated Hosts | Per-host billing | Varies | Licensing, compliance |

## CLI Examples

```bash
# Launch an instance
aws ec2 run-instances --image-id ami-0123456789 \
  --instance-type t3.micro --key-name mykey \
  --security-group-ids sg-123 --subnet-id subnet-456

# List running instances
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].[InstanceId,InstanceType,PublicIpAddress]" \
  --output table

# Stop an instance (stop billing for compute, EBS still charged)
aws ec2 stop-instances --instance-ids i-0123456789
```

---

[⬅️ Back to AWS SAA-C03 Index](../)
