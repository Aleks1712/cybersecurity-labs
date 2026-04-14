# Section 12: Tools for Managing and Deploying Azure Resources

## Azure Portal

Web-based GUI for managing Azure. Good for learning and exploration. Not ideal for repetitive tasks — use CLI/PowerShell for automation.

## Azure Cloud Shell

Browser-based shell directly in Azure Portal. Two environments:
- **Azure CLI:** Bash-based commands (`az vm list`, `az keyvault list`). Cross-platform.
- **Azure PowerShell:** PowerShell cmdlets (`Get-AzVM`). 

Output in JSON format by default. Saves needing to install software locally.

## Azure Arc

Extends Azure management to resources outside Azure. Consistent management for servers across your environment. VM extensions allow Azure tools (monitoring, security, updates) to work on non-Azure machines. Works with Kubernetes clusters, SQL databases, and on-prem servers.

**What you can do with Arc:** Collect log data for Log Analytics and Monitor. Use VM Insights to analyze performance. Download and execute scripts on hybrid connected machines. Refresh certifications using Key Vault. Attach and manage Kubernetes clusters.

Supports: on-premises, Azure, and other cloud providers (AWS, GCP).

## Infrastructure as Code (IaC)

Define your desired infrastructure in a configuration file. Deploy the file. Re-deploy it again and again. Recreate it in another region. Benefits: consistency, repeatability, version control.

**Desired State Configuration (DSC):** Ensures your configuration doesn't drift from the original setup over time. More robust than manual management.

## IaC Options in Azure

**ARM Templates:** JSON files defining infrastructure. Azure Resource Manager is the deployment and management layer — ALL requests (Portal, CLI, PowerShell, SDK) go through ARM. Declarative: describe what you want, not how. Idempotent.

**Bicep:** Simpler syntax than JSON, compiles to ARM templates.

**Other options:** Terraform, Chef/Puppet, PowerShell scripts, Python or other code (track changes in GitHub).

```json
{
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "name": "mystorageaccount"
    },
    {
      "type": "Microsoft.Storage/storageAccounts/blobServices/containers",
      "name": "mycontainer"
    }
  ]
}
```

---

## Bicep Example

```bicep
// Deploy a storage account with Bicep (Infrastructure as Code)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'mystorageaccount'
  location: 'norwayeast'
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}
```

## CLI Examples

```bash
# Deploy a Bicep template
az deployment group create --resource-group myRG --template-file main.bicep

# Apply a resource lock
az lock create --name DoNotDelete --resource-group ProductionRG \
  --lock-type CanNotDelete

# Tag resources for cost tracking
az group update --name myRG --tags Environment=Production Team=Security
```
