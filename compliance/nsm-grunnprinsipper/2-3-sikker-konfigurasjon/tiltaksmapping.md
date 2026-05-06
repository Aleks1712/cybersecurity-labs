# Tiltaksmapping — NSM 2.3 til konkret implementasjon

For hvert tiltak under prinsipp 2.3 (per NSM v2.1, mai 2024), dokumenterer denne tabellen hvor implementasjonen finnes, hvilken modenhetsstatus den har, og hvilke gap som er uakseptert risiko.

NSM 2.3 har 10 underliggende tiltak. Dette er en presis mapping mot dokumentet, ikke en omformulering.

## 2.3.1 — Etabler et sentralt styrt regime for sikkerhetsoppdatering

NSM-tekst: prioritetsliste for oppdateringer, klar rutine med ansvarsforhold, automatisering der mulig, isolering av enheter som er vanskelige å holde oppdatert.

| Aspekt | Implementasjon |
|---|---|
| Hvor | `vps-bootstrap/unattended-upgrades/` (auto-patching), `vps-bootstrap/scripts/00-bootstrap.sh` (apt-policy konfigurert ved bootstrap) |
| Status | Delvis implementert |
| Bevis | unattended-upgrades aktivert med auto-reboot-window for security-patches; kjente versjoner dokumentert i setup.md |
| Mapping NIST | SP 800-53 SI-2 (Flaw Remediation), CM-3 |
| Mapping ISO | ISO/IEC 27002:2022 8.8 (Management of technical vulnerabilities) |
| Gap | Ingen sentralisert patch-management (Ansible/Salt) for cross-host. Ingen formell prioriteringsliste skrevet ned. Auto-patching dekker OS, men ikke alle Docker-containers automatisk. |

## 2.3.2 — Konfigurer klienter slik at kun kjent programvare kjører på dem

NSM-tekst inkluderer presisering ny i v2.1: "Husk at programvare ikke må være installert for å kunne kjøre." Tiltak omhandler godkjentlisting av programkode, signering, applikasjonsbutikker, blokkering av makroer i dokumenter.

| Aspekt | Implementasjon |
|---|---|
| Hvor | Mer relevant for klient-skala enn server-skala. På server-siden: Docker `read_only: true` på containers, `noexec` mount-flag på `/tmp` (i bootstrap), AppArmor-profiler for utvalgte tjenester |
| Status | Delvis implementert (server-context); ikke relevant i klassisk forstand for VPS-skala |
| Bevis | Docker-compose example viser read-only filesystem; bootstrap-scriptet setter noexec på /tmp og /var/tmp |
| Mapping NIST | SP 800-53 CM-7 (Least Functionality), CM-7(5) (Authorized Software / Allowlisting) |
| Mapping ISO | 8.19 (Installation of software on operational systems) |
| Mapping CIS | Critical Security Controls v8, Control 2 (Inventory and Control of Software Assets) |
| Gap | Ingen full execve-auditing (kun auditd på spesifikke baner). Ingen signaturbasert applikasjonskontroll på Linux-server (krever Wazuh, IPE, eller dm-verity). For klient-skala er dette ikke i scope for VPS-laben. |

**Hvorfor v2.1-presiseringen om eksekvering vs. installering er viktig:**
Tradisjonell software inventory spør "hva er installert?". NSM 2.3.2 v2.1 spør "hva får faktisk kjøre?". Forskjellen er kritisk for å fange:
- Living-off-the-land-angrep med pre-installerte tools
- Skript-motorer som eksekverer kode uten formell installasjon
- Makroer i dokumenter
- Binaries som kjøres fra `/tmp` og slettes (fileless malware)

Lab-en demonstrerer dette på server-skala via `noexec` og container-isolering. Full klient-godkjentlisting er ut av scope.

## 2.3.3 — Deaktiver unødvendig funksjonalitet

NSM-tekst: innebygget funksjonalitet som ikke trengs bør deaktiveres — eldre protokoller, innebygd støtte for personlige sky-tjenester, andre innebygde tjenester.

| Aspekt | Implementasjon |
|---|---|
| Hvor | `ssh-hardening/server-config/sshd_config.d/30-limits.conf` (X11Forwarding off, AgentForwarding off, GatewayPorts off, AllowTcpForwarding no), `ssh-hardening/server-config/sshd_config.d/10-crypto.conf` (eldre KEX/Cipher/MAC removed), `vps-bootstrap/scripts/00-bootstrap.sh` (avinstallerer ubrukte default-pakker) |
| Status | Implementert og verifisert |
| Bevis | ssh-audit grade A+ (eldre algoritmer fjernet); SSH har minimal feature-set; Docker daemon med kun nødvendig funksjonalitet |
| Mapping NIST | SP 800-53 CM-7 (Least Functionality) |
| Mapping ISO | 8.9 |
| Gap | Bredere host-attack-surface-reduction (fjerning av compiler tools, statisk linkede tools) er ikke implementert. Akseptabelt for hjemmelab. |

## 2.3.4 — Etabler og vedlikehold standard sikkerhetskonfigurasjoner

NSM-tekst: én standard per type enhet, sentralisert drift, gjennomgang og oppdatering, kun autorisert driftspersonale kan endre.

| Aspekt | Implementasjon |
|---|---|
| Hvor | `ssh-hardening/server-config/sshd_config.d/` (modular per-tema config), `vps-bootstrap/docker/daemon.json`, `vps-bootstrap/ufw/`, `vps-bootstrap/fail2ban/jail.local`, alt versjonskontrollert i git |
| Status | Implementert |
| Bevis | Konfig som kode, kommentert med rasjonale per direktiv, kilder navngitt (Mozilla, CIS) |
| Mapping NIST | SP 800-53 CM-2 (Baseline Configuration), CM-6 (Configuration Settings) |
| Mapping ISO | 8.9 (Configuration management) |
| Mapping CIS | Critical Security Controls v8, Control 4 |
| Gap | Baseline er per-host, ikke per-rolle. Reell virksomhet har rolle-spesifikke baselines (web server, DB server, jump host). |

## 2.3.5 — Verifiser at aktivert sikkerhetskonfigurasjon er i henhold til godkjent baseline

NSM-tekst: regelmessig sammenligning av aktiv konfig mot godkjent, varsling ved avvik, integritets-beskyttelse av baseline, automatiser så mye som mulig.

| Aspekt | Implementasjon |
|---|---|
| Hvor | `ssh-hardening/scripts/verify-sshd-config.sh` (pre-runtime), auditd watches på sshd_config (runtime — ref. 3-2-laben), Sigma-rule `sshd-config-tampering.yml` |
| Status | Implementert |
| Bevis | verify-sshd-config.sh aborterer reload ved avvik; auditd-events fanges av detection-pipeline |
| Mapping NIST | SP 800-53 CM-3(5), SI-7 (Software, Firmware, and Information Integrity) |
| Mapping ISO | 8.9, 8.16 |
| Gap | Ingen aktiv reconciliation (auto-revert). I hjemmelab er det farligere enn nyttig. I virksomhet håndteres dette av Ansible/Salt-Stack pull-mode. |

## 2.3.6 — Utfør all konfigurasjon, installasjon og drift på en trygg måte

NSM-tekst: drift over tiltrodde kanaler, dedikerte drifts-klienter, redusert interaktiv pålogging, integritetsbeskyttede admin-grensesnitt.

| Aspekt | Implementasjon |
|---|---|
| Hvor | `ssh-hardening/client-config/ssh_config` (per-host nøkler, ingen agent-forwarding), mesh-VPN for admin-aksess, ingen public exposure av admin-interfaces |
| Status | Implementert |
| Bevis | Admin SSH går kun via mesh-interface; per-host nøkler hindrer credential reuse |
| Mapping NIST | SP 800-53 AC-17 (Remote Access), SC-8 (Transmission Confidentiality and Integrity) |
| Mapping ISO | 8.20, 8.21 |
| Gap | Ingen Privileged Access Management (PAM-tooling) som CyberArk/Hashicorp Boundary. For hjemmelab er det out-of-scope. |

## 2.3.7 — Endre alle standardpassord på IKT-produktene før produksjonssetting

NSM-tekst: gjelder applikasjoner, OS, rutere, brannmurer, skrivere, aksesspunkter. Foretrekk sertifikatbasert autentisering der støttet.

| Aspekt | Implementasjon |
|---|---|
| Hvor | `vps-bootstrap/scripts/00-bootstrap.sh` (sjekker for default-passord; SSH er pubkey-only fra start) |
| Status | Implementert (på SSH-nivå); ikke applicable for noen tjenester |
| Bevis | Ingen passordbasert SSH; Docker daemon ikke eksponert med default-credentials |
| Mapping NIST | SP 800-53 IA-5 (Authenticator Management) |
| Mapping ISO | 8.5 (Secure authentication) |
| Gap | Hvis applikasjonen som deployes har egne default-credentials (DB-passord, admin-konsoller), må de håndteres per app. Bootstrap-scriptet kan ikke gjette hva apps trenger. |

## 2.3.8 — Ikke deaktiver kodebeskyttelsesfunksjoner

NSM-tekst: DEP, SEHOP, ASLR — disse skal være aktivert. Lag unntaksregler for eldre apps fremfor å deaktivere globalt.

| Aspekt | Implementasjon |
|---|---|
| Hvor | Default Linux kernel-konfigurasjon på Ubuntu 24.04 (ASLR, NX-bit, SMEP, SMAP — alle on). Bootstrap verifiserer disse. |
| Status | Implementert (default i moderne kernel) |
| Bevis | `cat /proc/sys/kernel/randomize_va_space` returnerer `2` (full ASLR); kernel-flagger for security-features verifiserbar |
| Mapping NIST | SP 800-53 SI-16 (Memory Protection) |
| Gap | Ingen kjente. Det viktigste er å ikke deaktivere disse — vi har ikke gjort det. |

## 2.3.9 — Etabler sikker tid

NSM-tekst: tidskilder med høyere tillit, alle enheter benytter tid med ønsket kvalitet.

| Aspekt | Implementasjon |
|---|---|
| Hvor | `vps-bootstrap/scripts/00-bootstrap.sh` (chrony konfigurert mot pool.ntp.org og ntp.uio.no — sistnevnte for tillitsnivå) |
| Status | Implementert |
| Bevis | chrony aktiv; tidssynk verifisert via `chronyc tracking` i 99-verify.sh |
| Mapping NIST | SP 800-53 AU-8 (Time Stamps) |
| Mapping ISO | 8.17 (Clock synchronization) |
| Gap | Ingen autentisert NTP (NTS) implementert. Akseptabelt for hjemmelab — for kritiske systemer ville NTS-protokollen vært riktig steg. |

## 2.3.10 — Reduser risiko ved IoT-enheter

| Aspekt | Implementasjon |
|---|---|
| Status | Ikke relevant for VPS-skala lab |
| Begrunnelse | VPS-en har ingen IoT-enheter. Tiltaket gjelder primært homelab/kontornettverk. Kunne dekkes i en separat lab. |

## Sammendrag

| Tiltak | Status | Modenhet (1-5) |
|---|---|---|
| 2.3.1 Sikkerhetsoppdatering | Delvis | 2-3 |
| 2.3.2 Eksekverings-kontroll | Delvis (server-context) | 2-3 |
| 2.3.3 Deaktiver unødvendig | Implementert | 3 |
| 2.3.4 Standard baseline | Implementert | 3 |
| 2.3.5 Verifisering | Implementert | 3 |
| 2.3.6 Trygg drift | Implementert | 3 |
| 2.3.7 Standardpassord | Implementert | 3 |
| 2.3.8 Kodebeskyttelse | Implementert | 3 |
| 2.3.9 Sikker tid | Implementert | 3 |
| 2.3.10 IoT | Ikke relevant | n/a |

**Gjennomsnittlig modenhet på 2.3:** ~3 (Definert) for relevante tiltak.

For å nå nivå 4 (Styrt) ville jeg trengt:
- Ansible / Salt-Stack for cross-host konsistens
- Centralized patch-management dashboard
- Full execve-auditing med korrelasjon (Wazuh, Falco)
- Formell change advisory board

Disse er virksomhets-skala krav, ikke realistiske for hjemmelab.

## Cross-walks fra NSM 2.3 til andre rammeverk

| NSM | NIST CSF 2.0 | NIST SP 800-53 | ISO 27002:2022 | CIS Controls v8 |
|---|---|---|---|---|
| 2.3.1 | ID.RA-1, RS.MI-3 | SI-2, CM-3 | 8.8 | 7.4, 7.7 |
| 2.3.2 | PR.PT-3 | CM-7, CM-7(5) | 8.19 | 2.1, 2.6 |
| 2.3.3 | PR.PT-3 | CM-7 | 8.9 | 4.8 |
| 2.3.4 | PR.IP-1 | CM-2, CM-6 | 8.9 | 4.1, 4.2 |
| 2.3.5 | DE.CM-7 | CM-3(5), SI-7 | 8.9, 8.16 | 4.5 |
| 2.3.6 | PR.AC-3 | AC-17, SC-8 | 8.20, 8.21 | 12.7 |
| 2.3.7 | PR.AC-1 | IA-5 | 8.5 | 5.2 |
| 2.3.8 | PR.PT-3 | SI-16 | 8.7 | 10.5 |
| 2.3.9 | (n/a) | AU-8 | 8.17 | 8.4 |
| 2.3.10 | PR.AC-5 | SC-7 | 8.20 | 12.6 |
