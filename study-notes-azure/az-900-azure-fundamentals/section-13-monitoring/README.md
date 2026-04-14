# Section 13: Monitoring Tools

## Azure Advisor

Personalized recommendations based on your deployed resources. Five categories:

1. **Operational Excellence:** Workflow and process improvements
2. **Reliability:** Improve availability
3. **Security:** Identify threats and vulnerabilities
4. **Performance:** Improve speed and responsiveness
5. **Cost:** Reduce spending (e.g., "this VM is underutilized, consider a smaller size")

## Azure Service Health

Track the health of Azure services relevant to you.

**Azure Status:** Global overview of all Azure service health.
**Service Health:** Focused view of the services and regions YOU use. Alerts for active service issues, planned maintenance, and health advisories.
**Resource Health:** Health of YOUR specific individual resources.

## Azure Monitor

Centralized dashboard for collecting, analyzing, and acting on telemetry from Azure and on-premises environments.

**Log Analytics:** Write and run log queries using KQL (Kusto Query Language). Pre-built queries available. Analyze data from many sources.

**Application Insights:** Monitor live web applications. Track request rates, response times, failure rates, dependency calls, user behavior, and page views.

**Monitor Metrics:** Real-time performance data. Create dashboards, run queries, set up alerts.

**Alerts:** Automatic notifications based on threshold values or conditions. Can trigger email, SMS, Azure Functions, Logic Apps, and other actions.

---

## CLI Examples

```bash
# Query Log Analytics with KQL
az monitor log-analytics query --workspace myWorkspace \
  --analytics-query "AzureActivity | where OperationNameValue contains 'delete' | top 10 by TimeGenerated"

# List security recommendations from Advisor
az advisor recommendation list --category security -o table

# Check current month spending
az consumption usage list \
  --query "[].{Service:consumedService, Cost:pretaxCost}" -o table
```
-e 
---
[⬅️ Back to AZ-900 Index](../)
