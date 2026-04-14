# AZ-500: Microsoft Azure Security Technologies — Study Notes

Study notes from *Microsoft Azure Security Technologies Certification and Beyond* by David Okeyode (Packt, 2021, 526 pages). The book is structured around the four AZ-500 exam domains with hands-on exercises for every chapter.

**Exam details:** AZ-500 | Prerequisite: AZ-900 recommended | Tests practical Azure security skills

---

## Book Structure (13 Chapters)

**Section 1: Identity and Access Security (Ch. 1-5)**
**Section 2: Azure Platform Protection (Ch. 6-9)**
**Section 3: Secure Storage, Applications, and Data (Ch. 10-12)**
**Section 4: Security Operations (Ch. 13)**

---

## Exam Domains

| Domain | Weight | Book Chapters |
|--------|--------|---------------|
| Manage identity and access | 25-30% | Ch. 1-5 |
| Secure networking | 20-25% | Ch. 6-7 |
| Secure compute, storage, and databases | 20-25% | Ch. 8-12 |
| Manage security operations | 25-30% | Ch. 13 |

---

## Section 1: Identity and Access Security (Ch. 1-5)

### Ch. 1: Introduction to Azure Security

The shared responsibility model defines which security tasks are handled by Microsoft and which are handled by you. Your security responsibility varies depending on the service model. With IaaS (like VMs) you have the most responsibilities, including OS patching. With PaaS (like App Service) you are not responsible for OS patching but still responsible for configuration and access control. With SaaS you have the fewest responsibilities but still control access to your data.

Key takeaway from the book: wherever you have responsibility in the shared model, if you do not have a strategy to address it, you are leaving yourself exposed to threats.

**CSA Guidance v4.0 connection:** The CSA Security Guidance (152 pages, 14 domains) provides the vendor-neutral framework behind everything in AZ-500. CSA defines the cloud security process model: identify requirements, select provider/service/deployment model, define architecture, assess controls, identify gaps, implement controls, manage changes. CSA also provides the CAIQ for evaluating providers and the CCM for mapping controls to compliance standards.

**Thales 2022 context:** 39% of critical infrastructure orgs breached in the past 12 months. 44% reported increases in attack volume/severity. Only 30% had a formal Zero Trust strategy.

### Ch. 2: Understanding Azure AD (Entra ID)

Azure AD is NOT on-premises Active Directory in the cloud. On-prem AD uses Kerberos and LDAP. Azure AD uses OAuth 2.0, OpenID Connect, and SAML.

**Azure AD Editions:** Free (basic user management, SSO). Premium P1 (Conditional Access, self-service password reset, hybrid identity). Premium P2 (Identity Protection, PIM for just-in-time admin access).

**Key objects:** Users, Groups, Roles (Azure AD roles vs Azure RBAC roles), Service Principals.

### Ch. 3: Azure AD Hybrid Identity

Three authentication methods: **PHS** (sends hashed passwords to cloud, simplest, recommended), **PTA** (validates against on-prem in real time), **Federation/ADFS** (delegates to on-prem server, most complex).

**Real-world case: Maersk and PHS.** Weeks before NotPetya destroyed all 150 domain controllers, 45,000 PCs, and 4,000 servers, Maersk had deployed Azure AD SSO with PHS. Cloud access survived because PHS decouples cloud auth from on-prem. If they had used ADFS, cloud access would have died too. Cost: $300M. The CISO said: recover AD within 24 hours or you cannot recover anything.

### Ch. 4: Azure AD Identity Security

**Conditional Access:** Policy engine evaluating signals (user, location, device, app, risk) to enforce decisions (allow, block, require MFA). Best practices: MFA for admins, block legacy auth, require managed devices.

**Identity Protection:** Detects user risk (compromised credentials) and sign-in risk (suspicious activity). Risk levels: low, medium, high. Policies: force password change or require MFA.

**Thales 2022:** Only 51% of critical infrastructure orgs had MFA deployed. MFA primarily for remote staff (68%) and privileged IT (53%), leaving gaps.

**CSA v4.0 (Domain 12):** Key IAM standards: SAML 2.0 (federated identity), OAuth 2.0 (API authorization), OpenID Connect (authentication on OAuth). Core principle: federate identity, don't create separate cloud accounts.

### Ch. 5: Azure AD Identity Governance

**PIM:** Just-in-time privileged access. Eligible assignments require activation with approval/MFA/justification. Time-bound. Access reviews verify users still need access.

---

## Section 2: Platform Protection (Ch. 6-9)

### Ch. 6: Perimeter Security

**DDoS Protection:** Basic (free, always on) vs Standard (adaptive tuning, analytics, cost protection). **Azure Firewall:** Application rules (FQDN), network rules (IP/port), NAT rules, threat intelligence. **WAF:** OWASP CRS on Application Gateway (regional) or Front Door (global). Detection vs prevention mode.

### Ch. 7: Network Security

**NSGs:** Stateful rules, priority 100-4096. Default: allow intra-VNet, allow outbound, deny inbound internet. **ASGs:** Group VMs by role instead of IP addresses. **Service Endpoints:** Traffic over Azure backbone. **Private Link:** Private IP from your VNet to Azure service, no public exposure.

### Ch. 8: Host Security

VM hardening: endpoint protection, disk encryption (BitLocker/dm-crypt), update management, JIT VM Access. **Azure Bastion:** Managed RDP/SSH through portal, no public IP needed.

### Ch. 9: Container Security

**ACR:** Service firewall, content trust, vulnerability scanning. **AKS:** Private cluster, network policies, pod-managed identities, Azure Policy for pod security.

---

## Section 3: Storage, Apps, and Data (Ch. 10-12)

### Ch. 10: Storage Security

SSE with Microsoft or customer-managed keys. SAS tokens for time-limited access. Azure AD authorization recommended. Defender for Storage detects anomalies.

### Ch. 11: Database Security

Defense in depth for Azure SQL: IP firewall, VNet rules, private endpoints, Azure AD auth. TDE (encryption at rest, default on). Always Encrypted (client-side, DB admins cannot read). Dynamic Data Masking. SQL Auditing. Defender for SQL.

### Ch. 12: Key Vault

Stores secrets, keys (HSM-backed), and certificates. Two access planes: management (RBAC) and data (access policies or RBAC). Soft-delete + purge protection. Auto-replicated to paired region.

**CSA v4.0 (Domain 11):** Four key management options: provider-managed, BYOK, HYOK, full customer control. Cryptographic erasure for cloud data destruction.

**Thales 2022:** 55% use 5+ key management tools. Gap between selecting encryption (62%) and key management (51%).

---

## Section 4: Security Operations (Ch. 13)

**Azure Policy:** Audit, deny, or auto-remediate. Initiatives group related policies. **Blueprints:** Package roles, policies, ARM templates.

**Azure Monitor:** Metrics and logs. Log Analytics with KQL. **Defender for Cloud:** Secure Score, recommendations, compliance dashboards.

### Azure Sentinel (Microsoft Sentinel)

Cloud-native SIEM and SOAR. Full workflow: Data Connectors > Log Analytics > Analytics Rules > Incidents > Investigation Graph + Playbooks (Logic Apps) + Threat Hunting (KQL) + Workbooks.

**Real-world case: Colonial Pipeline.** DarkSide accessed via compromised VPN credential without MFA. Exfiltrated 100GB in 2 hours. In Sentinel: anomalous sign-in, large data transfer, lateral movement, and ransomware file changes would have triggered analytics rules. Automated playbooks could have contained the breach. Cost without detection: $4.4M ransom, 6-day shutdown.

**CSA v4.0 (Domain 9):** Cloud IR differs from traditional. SLAs must define IR responsibilities before incidents. Automate forensic processes. Sentinel playbooks implement this.

**Thales 2022:** Only 45% had a formal ransomware response plan.

---

## How This Maps to Real Security Work

Identity security (Ch. 2-5) covers the most common attack vector (credential compromise). Network security (Ch. 6-7) covers perimeter defense and segmentation. Security operations (Ch. 13) covers the SIEM/SOAR workflow. The Sentinel workflow of collect, detect, investigate, respond is what a SOC analyst does every day.

---

## Sources

| Resource | Type | How it was used |
|----------|------|-----------------|
| David Okeyode, AZ-500 (Packt, 2021) | Book (526 pages) | Primary study material |
| CSA Security Guidance v4.0 (2017) | Framework (152 pages) | Vendor-neutral cloud security principles |
| Thales Data Threat Report 2022 | Industry report | Real-world breach data and stats |

## Study Resources

- [Microsoft Learn AZ-500](https://learn.microsoft.com/en-us/credentials/certifications/azure-security-engineer/)
- [AZ-500 Exam Study Guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-500)

---

**GitHub:** [Aleks1712](https://github.com/Aleks1712)
**Status:** Studying (building on AZ-900 foundation)
