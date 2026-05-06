# NSM Grunnprinsipper-mapping for vps-bootstrap

Hvilke NSM-tiltak (per [Grunnprinsipper for IKT-sikkerhet v2.1](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/), mai 2024) som denne lab-en demonstrerer, og hvor i lab-en bevisene finnes.

For full kontekst og cross-walks mot NIST/ISO/MITRE, se hovedmappingen i
[`compliance/nsm-grunnprinsipper/`](../../../compliance/nsm-grunnprinsipper/).

VPS-bootstrap-laben er bredere enn ssh-hardening - den dekker host-konfig, nettverk, container-isolasjon, supply-chain, og logging. Tiltakene under er gruppert per NSM-kategori for å gjøre det lett å scanne.

## Kategori 2: Beskytte og opprettholde

### 2.1 - Ivareta sikkerhet i anskaffelses- og utviklingsprosesser

Spesielt 2.1.5 (sikker programvareutvikling) og 2.1.8 (vedlikehold programvarekode).

**Hvor i lab-en:**
- [`app-deploy/verify-supply-chain.sh`](app-deploy/verify-supply-chain.sh) - kjører Trivy (image-scanning), Syft (SBOM-generering), pnpm/npm audit, og cosign signature verification
- [`app-deploy/docker-compose.yml.example`](app-deploy/docker-compose.yml.example) - eksplisitt versjonspinning av container-images, ikke `:latest`

### 2.2 - Etabler en sikker IKT-arkitektur

Spesielt 2.2.3 (oppdeling i soner) og 2.2.7 (robust og motstandsdyktig arkitektur).

**Hvor i lab-en:**
- [`THREAT-MODEL.md`](THREAT-MODEL.md) - fire eksplisitte trust-grenser: Public → Mesh → Host → Container → Backend
- [`app-deploy/docker-compose.yml.example`](app-deploy/docker-compose.yml.example) - segmenterte Docker-nettverk (frontend/backend), `internal: true` på backend

### 2.3 - Ivareta en sikker konfigurasjon

NSM 2.3 har 10 tiltak. Lab-en treffer:

| Tiltak | Hvor |
|---|---|
| **2.3.1 sentralt regime for oppdatering** | [`unattended-upgrades/50unattended-upgrades`](unattended-upgrades/50unattended-upgrades) - automatisk security-patching med reboot-window |
| **2.3.2 kun kjent programvare kjører** (v2.1-presisering: eksekvering, ikke bare installering) | [`scripts/00-bootstrap.sh`](scripts/00-bootstrap.sh) setter `noexec` på `/tmp` og `/var/tmp`; Docker `read_only: true` på containers |
| **2.3.3 deaktiver unødvendig funksjonalitet** | [`scripts/00-bootstrap.sh`](scripts/00-bootstrap.sh) avinstallerer ubrukte default-pakker |
| **2.3.4 standard sikkerhetskonfigurasjoner** | All konfig er kode i git, inkludert [`docker/daemon.json`](docker/daemon.json), [`fail2ban/jail.local`](fail2ban/jail.local) |
| **2.3.5 verifiser konfigurasjon** | [`scripts/99-verify.sh`](scripts/99-verify.sh) sjekker UFW status, listening ports, fail2ban, Docker config, auditd rules, unattended-upgrades |
| **2.3.6 trygg drift** | Mesh-only admin-aksess, ingen public exposure av admin-interfaces |
| **2.3.7 endre standardpassord** | Bootstrap-scriptet kjører ikke om SSH ennå er passord-basert |
| **2.3.8 ikke deaktiver kodebeskyttelse** | Default Linux kernel-flags (ASLR, NX, SMEP, SMAP) verifisert i `99-verify.sh` |
| **2.3.9 sikker tid** | chrony konfigurert mot pool.ntp.org og ntp.uio.no for tillit |
| **2.3.10 IoT-enheter** | Ikke relevant for VPS-skala |

### 2.4 - Beskytt virksomhetens nettverk

NSM 2.4 har 4 tiltak (med v2.1-presisering om at "porter" omfatter fysiske, trådløse og virtuelle):

| Tiltak | Hvor |
|---|---|
| **2.4.1 tilgangskontroll på porter** | [`scripts/00-bootstrap.sh`](scripts/00-bootstrap.sh) konfigurerer UFW per-interface; [`tailscale/acl-example.json`](tailscale/acl-example.json) demonstrerer identitets-basert ACL på virtuelle porter |
| **2.4.2 krypter alle forbindelser** | Mesh-VPN (Tailscale eller WireGuard via [`wireguard/`](wireguard/)) for all admin-trafikk |
| **2.4.3 fysisk kabel-kartlegging** | Ikke relevant - delegert til datasenter-leverandør |
| **2.4.4 brannmur på alle hosts** | UFW default deny + per-interface allow; logger shipped via journald |

### 2.5 - Kontroller dataflyt

Spesielt 2.5.1 (styr dataflyt mellom nettverks-soner) og 2.5.4 (isoler utstyr som er sårbart).

**Hvor i lab-en:**
- [`docker/daemon.json`](docker/daemon.json) - `iptables: false` så UFW er source-of-truth
- [`app-deploy/docker-compose.yml.example`](app-deploy/docker-compose.yml.example) - frontend/backend network segmentation, `internal: true`
- [`ufw/README.md`](ufw/README.md) - dokumenterte regler for east-west trafikk

### 2.6 - Ha kontroll på identiteter og tilganger

Spesielt 2.6.4 (minimer rettigheter til sluttbrukere) og 2.6.5 (minimer rettigheter på drifts-kontoer).

**Hvor i lab-en:**
- [`scripts/00-bootstrap.sh`](scripts/00-bootstrap.sh) setter opp non-root operatør-bruker med `sudo` med begrensede privilegier
- Docker konfigureres med `userns-remap` så containers ikke kjører som host-root

### 2.10 - Integrer sikkerhet i prosess for endringshåndtering

**Hvor i lab-en:**
- [`scripts/00-bootstrap.sh`](scripts/00-bootstrap.sh) er idempotent - kan kjøres flere ganger uten å bryte system
- All konfig er git-versjonskontrollert med commit-meldinger

## Kategori 3: Oppdage

### 3.1 - Oppdag og fjern kjente sårbarheter og trusler

**Hvor i lab-en:**
- [`unattended-upgrades/50unattended-upgrades`](unattended-upgrades/50unattended-upgrades) - automatisk patching av kjente sårbarheter
- [`app-deploy/verify-supply-chain.sh`](app-deploy/verify-supply-chain.sh) - Trivy-scanning av container-images for CVEs
- [`fail2ban/jail.local`](fail2ban/jail.local) - blokkerer kjent skadelig oppførsel (brute force-mønstre)

### 3.2 - Etabler sikkerhetsovervåkning

**Hvor i lab-en:**
- [`scripts/00-bootstrap.sh`](scripts/00-bootstrap.sh) - auditd-regler watcher sshd_config, sudoers, authorized_keys, docker.sock
- [`docker/daemon.json`](docker/daemon.json) - `"log-driver": "journald"` for sentralisert log-collection
- UFW-events shipped via journald

**Detection-pipeline (Sigma/KQL/SPL) finnes i:** [`compliance/nsm-grunnprinsipper/3-2-sikkerhetsovervakning/`](../../../compliance/nsm-grunnprinsipper/3-2-sikkerhetsovervakning/)

## Kategori 4: Håndtere og gjenopprette

### 4.3 - Kontroller og håndter hendelser

**Hvor i lab-en:**
- [`fail2ban/jail.local`](fail2ban/jail.local) - automatisk innkapsling av angripere via UFW ban-action
- [`scripts/99-verify.sh`](scripts/99-verify.sh) - kan brukes som post-incident healthcheck

## Sammendrag av dekning

VPS-bootstrap-laben treffer **17 av NSMs 21 prinsipper** (på prinsipp-nivå, varierende dekningsgrad på tiltak-nivå):

```
Kategori 1 (Identifisere):   ░░░░░░░░░░  delvis (1.2 enheter via 99-verify)
Kategori 2 (Beskytte):       █████████░  9/10 prinsipper (mangler 2.7 data-i-ro, 2.8 e-post, 2.9 backup)
Kategori 3 (Oppdage):        ████░░░░░░  2/4 prinsipper (3.1 sårbarheter, 3.2 overvåkning)
Kategori 4 (Håndtere):       ██░░░░░░░░  1/4 prinsipp (4.3 håndtering via fail2ban)
```

For full ærlig dekningsanalyse med modenhetsvurdering, se [`compliance/nsm-grunnprinsipper/master-mapping/`](../../../compliance/nsm-grunnprinsipper/master-mapping/).

## Hva NSM-tiltak denne lab-en IKKE dekker

- **2.7 data i ro og i transitt** - Bootstrap setter ikke opp LUKS for at-rest encryption. Krever oppsett ved første install.
- **2.8 e-post og nettleser** - VPS-skala har ikke endpoint-konsepter
- **2.9 gjenoppretting av data** - Backup-strategi er en separat lab (planlagt: `cybersec/backup-and-recovery/`)
- **3.4 inntrengningstester** - Lab-en kan testes, men er ikke en pen-test-lab
- **4.1, 4.2, 4.4 incident response og læring** - Krever organisatorisk struktur

## Cross-references til relaterte arbeider

- **Full NSM v2.1 mapping:** [`compliance/nsm-grunnprinsipper/`](../../../compliance/nsm-grunnprinsipper/)
- **Komplementær SSH-konfigurasjon:** [`networking/zero-trust-designs/ssh-hardening/`](../ssh-hardening/)
- **Detection som bruker bootstrap-telemetri:** [`compliance/nsm-grunnprinsipper/3-2-sikkerhetsovervakning/sigma-rules/`](../../../compliance/nsm-grunnprinsipper/3-2-sikkerhetsovervakning/sigma-rules/)
- **Threat model som driver designvalg:** [`THREAT-MODEL.md`](THREAT-MODEL.md)
