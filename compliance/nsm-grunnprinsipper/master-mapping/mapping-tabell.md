# Mapping-tabell — NSM v2.1 prinsipper og labs

Tabellen dekker alle 21 prinsipper. For hver oppgis dekningsgrad, hvilke labs som demonstrerer det, og NIST-mapping for cross-walk.

## Kategori 1: Identifisere og kartlegge

### 1.1 Kartlegg styringsstrukturer, leveranser og understøttende systemer

- **Hovedlab:** ingen. Dette er virksomhets-skala, ikke hjemmelab.
- **Andre labs:** master-mapping-en selv er en form for tjeneste-/lab-register
- **Status:** Ikke relevant for hjemmelab-skala
- **Begrunnelse:** Tiltakene under 1.1 (formelle styringsstrukturer, virksomhetsleveranser, IKT-kart) forutsetter en organisasjon med roller, ledelseslag, og forretningsprosesser. Hjemmelab-tilsvarende er en repo-README med "her er det jeg har".
- **NIST CSF:** GV.OC, GV.RM, ID.BE
- **NIST SP 800-53:** PM-1 til PM-9

### 1.2 Kartlegg enheter og programvare

- **Hovedlab:** ingen dedikert lab. Demonstreres delvis via `vps-bootstrap/scripts/99-verify.sh`
- **Status:** Delvis implementert
- **Begrunnelse:** Verify-scriptet kartlegger hva som faktisk er installert og lytter på en VPS. En reell virksomhet ville hatt et CMDB med alle enheter og pakkversjoner — det er virksomhets-skala.
- **NIST CSF:** ID.AM-1, ID.AM-2
- **NIST SP 800-53:** CM-8, PM-5

### 1.3 Kartlegg brukere og behov for tilgang

- **Hovedlab:** ingen dedikert. Demonstreres i `ssh-hardening/server-config/sshd_config.d/20-auth.conf` med `AllowGroups` og `AllowUsers`
- **Status:** Implementert på teknisk nivå, ikke organisatorisk
- **NIST CSF:** ID.AM-3, PR.AC-1
- **NIST SP 800-53:** AC-2

## Kategori 2: Beskytte og opprettholde

### 2.1 Ivareta sikkerhet i anskaffelses- og utviklingsprosesser

- **Hovedlab:** `vps-bootstrap/app-deploy/verify-supply-chain.sh`
- **Andre labs:** AI-security/model-supply-chain (planlagt — bygger på bachelor thesis)
- **Status:** Delvis implementert — supply chain verification eksisterer
- **Begrunnelse:** SBOM, npm/pnpm audit, Trivy image scanning, cosign signature verification dekker tekniske tiltak. Anskaffelsesprosess som virksomhets-praksis er ikke i scope.
- **NIST CSF:** PR.IP-2, PR.SC
- **NIST SP 800-53:** SA-3, SA-12

### 2.2 Etabler en sikker IKT-arkitektur

- **Hovedlab:** `vps-bootstrap` (zero-trust mesh-arkitektur, segmenterte Docker-nettverk)
- **Andre labs:** `ssh-hardening` (SSH-arkitektur), `2-4-beskytt-nettverk` (denne mappen)
- **Status:** Implementert og verifisert
- **NIST CSF:** PR.AC-5, PR.PT-4
- **NIST SP 800-207:** Zero Trust Architecture
- **NIST SP 800-53:** SC-7, SC-32

### 2.3 Ivareta en sikker konfigurasjon ★

- **Hovedlab:** `2-3-sikker-konfigurasjon` (denne mappen)
- **Andre labs:** `ssh-hardening` (SSH config baseline), `vps-bootstrap` (Docker, fail2ban, UFW)
- **Status:** Implementert og verifisert (ssh-audit grade A+, Lynis 95)
- **NIST CSF:** PR.IP-1, PR.IP-3
- **NIST SP 800-53:** CM-2, CM-6
- **CIS:** Distribution Independent Linux Benchmark v2.0.0
- **MITRE D3FEND:** Configuration Inventory, Baseline Configuration

### 2.4 Beskytt virksomhetens nettverk ★

- **Hovedlab:** `2-4-beskytt-nettverk` (denne mappen)
- **Andre labs:** `vps-bootstrap` (UFW, mesh VPN)
- **Status:** Implementert og verifisert (0 SSH-forsøk i 7 dager etter mesh-binding)
- **NIST CSF:** PR.AC-5, PR.PT-4, DE.CM-1
- **NIST SP 800-207:** ZT primer
- **NIST SP 800-53:** SC-7, SC-8

### 2.5 Kontroller dataflyt

- **Hovedlab:** ingen dedikert. Demonstreres via Docker-nettverkssegmentering i `vps-bootstrap/app-deploy/docker-compose.yml.example`
- **Status:** Delvis implementert
- **Begrunnelse:** Docker `internal: true` på backend-nettverket, eksplisitt frontend/backend-segmentering, men ingen DPI/east-west-overvåkning
- **NIST CSF:** PR.DS-5, PR.PT-4
- **NIST SP 800-53:** SC-7(8), AC-4

### 2.6 Ha kontroll på identiteter og tilganger

- **Hovedlab:** `ssh-hardening` (pubkey-only, AllowGroups, fra-restriksjoner i authorized_keys)
- **Status:** Implementert og verifisert på SSH-nivå
- **Begrunnelse:** Hjemmelab har ikke IDP, SSO, eller PAM-integrasjon. SSH som adgangsvei er solid implementert.
- **NIST CSF:** PR.AC-1, PR.AC-4, PR.AC-7
- **NIST SP 800-53:** AC-2, AC-6, IA-2, IA-5

### 2.7 Beskytt data i ro og i transitt

- **Hovedlab:** ingen dedikert. Demonstreres via SSH-kryptering (transitt) og Docker volume-encryption (delvis)
- **Status:** Delvis implementert
- **Begrunnelse:** TLS via Caddy reverse proxy, SSH transitt-kryptering, men ingen formell at-rest encryption (LUKS) på VPS-nivå. Det krever oppsett ved første install.
- **NIST CSF:** PR.DS-1, PR.DS-2
- **NIST SP 800-53:** SC-13, SC-28

### 2.8 Beskytt e-post og nettleser

- **Status:** Ikke relevant for VPS-skala lab
- **Begrunnelse:** Disse tiltakene gjelder endepunkter (klient-PCer) og mailservere. Out of scope for serverlab.

### 2.9 Etabler evne til gjenoppretting av data

- **Status:** Planlagt
- **Begrunnelse:** Backup-strategi for VPS og homelab er en separat lab som jeg vil bygge i `cybersec/backup-and-recovery/`. Ærlig: denne mangler akkurat nå.
- **NIST CSF:** PR.IP-4, RC.RP-1
- **NIST SP 800-53:** CP-9, CP-10

### 2.10 Integrer sikkerhet i prosess for endringshåndtering

- **Hovedlab:** ingen dedikert. Demonstreres via git-arbeidsflyt, PR-templates i hovedrepoet, `pre-commit`-hooks (gitleaks, markdownlint per `.agent/config.yaml`)
- **Status:** Delvis implementert
- **NIST CSF:** PR.IP-3
- **NIST SP 800-53:** CM-3, CM-4

## Kategori 3: Oppdage

### 3.1 Oppdag og fjern kjente sårbarheter og trusler

- **Hovedlab:** ingen dedikert ennå. Demonstreres via `vps-bootstrap/unattended-upgrades` (auto-patching) og `verify-supply-chain.sh` (Trivy)
- **Status:** Delvis implementert (auto-patching virker; aktiv vulnerability scanning er begrenset)
- **NIST CSF:** ID.RA-1, DE.CM-8
- **NIST SP 800-53:** RA-5, SI-2

### 3.2 Etabler sikkerhetsovervåkning ★

- **Hovedlab:** `3-2-sikkerhetsovervakning` (denne mappen)
- **Andre labs:** auditd-regler i `vps-bootstrap/scripts/00-bootstrap.sh`, LogLevel VERBOSE i `ssh-hardening`
- **Status:** Implementert (sigma-rules, KQL queries, journald-shipping demo)
- **NIST CSF:** DE.CM-1, DE.CM-3, DE.CM-7
- **NIST SP 800-53:** AU-2, AU-6, AU-12, SI-4

### 3.3 Analyser data fra sikkerhetsovervåkning

- **Hovedlab:** dekkes som del av `3-2-sikkerhetsovervakning`
- **Status:** Implementert (Sigma → SIEM-mapping)
- **NIST CSF:** DE.AE-2, DE.AE-3
- **NIST SP 800-53:** AU-6, IR-4

### 3.4 Gjennomfør inntrengningstester

- **Status:** Planlagt — `offensive/htb-writeups/` og fremtidige internal pen test labs
- **Begrunnelse:** Som BSc-student har jeg ikke kjørt formell pen-test mot egne system. HTB og THM dekker offensive teknikker mot kontrollerte mål.
- **NIST CSF:** ID.RA-1, PR.IP-7
- **NIST SP 800-53:** CA-8, RA-5

## Kategori 4: Håndtere og gjenopprette

### 4.1 Forbered virksomheten på håndtering av hendelser

- **Status:** Delvis dekket via `3-2-sikkerhetsovervakning` (alerting → playbook trigger demo)
- **Begrunnelse:** Formell incident response plan med roller og ansvar er virksomhets-skala
- **NIST CSF:** PR.IP-9, PR.IP-10
- **NIST SP 800-53:** IR-1, IR-2, IR-8

### 4.2 Vurder og klassifiser hendelser

- **Status:** Berørt i `3-2-sikkerhetsovervakning` via Sigma-regler med `level:` (low, medium, high, critical)
- **NIST CSF:** RS.AN-2

### 4.3 Kontroller og håndter hendelser

- **Status:** Demonstrert via `fail2ban` automatic ban-actions og dokumentert manuell prosedyre
- **NIST CSF:** RS.MI-1, RS.MI-2
- **NIST SP 800-53:** IR-4

### 4.4 Evaluer og lær av hendelser

- **Hovedlab:** ingen dedikert. Demonstreres via `events-and-market/` (planlagt) — incident write-ups med "hva som ikke fungerte"
- **Status:** Planlagt
- **NIST CSF:** RS.IM-1, RS.IM-2
- **NIST SP 800-53:** IR-4(1), PM-15

## Sammendrag av dekning

| Kategori | Antall prinsipper | Implementert | Delvis | Ikke relevant | Planlagt |
|---|---|---|---|---|---|
| 1. Identifisere | 3 | 0 | 2 | 1 | 0 |
| 2. Beskytte | 10 | 5 | 3 | 1 | 1 |
| 3. Oppdage | 4 | 1 | 1 | 0 | 2 |
| 4. Håndtere | 4 | 0 | 3 | 0 | 1 |
| **Totalt** | **21** | **6** | **9** | **2** | **4** |

Dekning av "implementert eller delvis" = 15/21 = 71% på prinsippnivå. På tiltaksnivå (118 underliggende tiltak) er dekningen lavere — anslagsvis 40-50%, fordi mange tiltak forutsetter virksomhets-skala prosesser.

Det er et ærlig tall. En BSc-portfolio som claimer "fullstendig NSM-dekning" er utroverdig — denne tabellen viser hvor jeg er, hva som mangler, og hvorfor.
