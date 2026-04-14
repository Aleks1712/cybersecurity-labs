# Section 7: Azure Storage Services

## Storage Account Types

**GPv2 (Standard):** Four data types: containers (blobs), files, queues, tables. Can hold 5 PB. Pay for what you use. Cheapest at ~2 cents per GB/month. Not recommended for high-demand workloads. Can be configured as a Data Lake for big data analytics.

**Premium options:** Premium blob storage (block blobs or page blobs), premium file storage (SSD, lower latency), premium SSD/SSD v2/Ultra Disk for VMs.

## Storage Types

**Blob Storage (Containers):** Binary Large Objects — any file type (TXT, PDF, ZIP, CSV, JPG, AVI). Stored in containers. Public or private. Unstructured data. Most popular storage type. Organized into folders. In AWS this is called S3.

**Disk Storage:** Block-level storage for VM hard disks.

**Azure Files:** True hierarchical folder structure. Mount as a drive letter (S: drive) on Windows, Linux, macOS. Supports SMB and NFS. Use cases: replace on-prem file storage, lift-and-shift migration, adds redundancy and failover.

**Azure File Sync:** Cloud tiering, backup, hybrid option, distributed access in sync with on-prem servers.

## Location and Redundancy

Create storage accounts in any region. Keep data close to consumers for speed. Prices vary by region.

**Redundancy:** Azure keeps 3 copies by default (LRS or ZRS). Global redundancy keeps 6 copies (3 local + 3 in another region).

| Option | Copies | Scope |
|--------|--------|-------|
| LRS | 3 | One datacenter |
| ZRS | 3 | Across availability zones |
| GRS | 6 | Local + paired region |
| GZRS | 6 | Zones + paired region |

## Access Tiers

| Tier | Best for | Storage cost | Access cost |
|------|----------|-------------|-------------|
| Hot | Frequently accessed (default) | Highest | Lowest |
| Cool | Infrequently accessed, min 30 days | 50% cheaper | More expensive |
| Cold | Rarely accessed, min 90 days | Even cheaper | Even more expensive |
| Archive | Very rarely accessed, min 180 days | Cheapest | Most expensive, offline |

Archive data must be rehydrated before access (can take hours).

## Migration Tools

**AzCopy:** CLI tool for large-volume data transfer. Works locally and in Cloud Shell. Uses SAS tokens for authentication.

**Azure Storage Explorer:** GUI tool for managing containers, blobs, and files.

**Azure File Sync:** Sync on-prem Windows file servers with Azure file shares.

**Azure Migrate:** Guided experience to discover, assess, and migrate servers, databases, and VMs to Azure.

**Azure Data Box:** Physical device for transferring massive data. Data Box (100 TB), Data Box Disk (8 TB), Data Box Heavy (1 PB). Encrypted and wiped clean after use.

## Security

- Storage accounts are HTTPS only by default
- Anonymous access turned off by default
- Key access turned on by default
- Entra ID authorization recommended
- All data encrypted at rest (Microsoft-managed or customer-managed keys via Key Vault)
- Infrastructure encryption available as additional layer
- Immutable storage for security logs (cannot be changed or deleted)

---

## CLI Examples

```bash
# Create a storage account
az storage account create --name mystorageacct --resource-group myRG \
  --location norwayeast --sku Standard_LRS

# Upload a file to blob storage
az storage blob upload --account-name mystorageacct \
  --container-name logs --name server.log --file ./server.log

# List blobs
az storage blob list --account-name mystorageacct \
  --container-name logs -o table

# Copy between storage accounts with AzCopy
azcopy copy 'https://source.blob.core.windows.net/data/*' \
  'https://dest.blob.core.windows.net/backup/' --recursive
```
-e 
---
[⬅️ Back to AZ-900 Index](../)
