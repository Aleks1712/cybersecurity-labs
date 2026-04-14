# Section 4: Cloud Service Types

## IaaS — Infrastructure as a Service

You rent infrastructure: VMs, storage, networking. You manage OS, middleware, runtime, applications, and data. Cloud replacement of real-world datacenter things.

**Azure examples:** Virtual Machines, Azure Storage, Virtual Networks

**Use cases:** Lift-and-shift migration, test/dev environments, storage and backup, apps requiring full infrastructure control.

## PaaS — Platform as a Service

Provider handles infrastructure, OS, middleware, runtime. You focus on application code and data. PaaS adds a service layer on top of IaaS.

**Azure examples:** App Service, Azure SQL Database, Azure Functions

**Use cases:** Web app development, analytics and BI, rapid development without infrastructure management.

## SaaS — Software as a Service

Ready-to-use software delivered over the internet. No administration of infrastructure or platform.

**Azure/Microsoft examples:** Microsoft 365, Outlook, Teams, Dynamics 365

## Serverless

You do not manage the server. You only handle writing and running code. Consumption-based pricing — no charges when idle.

**Azure serverless services:** Functions, Container Apps, Kubernetes, SQL Database (serverless tier), Cosmos DB

Serverless SQL auto-scales between 0.5 and 80 vCores. First 1 million executions per month are free. Ideal for event-driven or intermittent workloads. Challenge: costs may vary month-to-month, cold starts may cause slight delays.

| Aspect | VM (IaaS) | App Service (PaaS) | Functions (Serverless) |
|--------|-----------|-------------------|----------------------|
| Pay for | Always on | Always on | Only execution time |
| Scaling | Manual / Scale Sets | Built-in | Automatic |
| Admin | OS + everything | App + config | Only code |
| Cost at zero use | Still paying | Still paying | Free |
