# Tiltaksmapping — NSM 3.2 til konkret implementasjon

For hvert tiltak under prinsipp 3.2 (per NSM v2.1, mai 2024). NSM 3.2 har 7 underliggende tiltak.

## 3.2.1 — Fastsett virksomhetens strategi og retningslinjer for sikkerhetsovervåkning

NSM-tekst: strategien skal beskrive formål, hvilke data som samles, sikker oppbevaring, kapasitetsplanlegging, tilgangsstyring, sammenstilling av logger, sletting, revisjonsintervall.

| Aspekt | Implementasjon |
|---|---|
| Hvor | `nsm-grunnprinsipper/3-2-sikkerhetsovervakning/teori.md` (filosofi), `praksis.md` (operative valg), `examples/triage-playbook.md` (prosess) |
| Status | Implementert (på dokumentnivå) |
| Bevis | Strategi og retningslinjer dokumentert med eksplisitte valg om kilder, retention, tilgangsstyring |
| Mapping NIST | SP 800-53 AU-1 (Audit and Accountability Policy and Procedures), PM-14 |
| Mapping ISO | ISO/IEC 27002:2022 8.15 (Logging) |
| Gap | I virksomhet ville dette vært en formell policy signed av ledelsen, ikke bare README. Hjemmelab-modenhet topp ut der. |

## 3.2.2 — Følg lover, reguleringer og virksomhetens retningslinjer for sikkerhetsovervåkning

NSM-tekst: undersøk hvilke lover/regler som gjelder, vurder retention-tid, informer ansatte om hva som samles inn.

| Aspekt | Implementasjon |
|---|---|
| Hvor | `parsers/journald-to-loki.md` (har eksplisitte GDPR-betraktninger) |
| Status | Delvis implementert |
| Bevis | Dokumentasjon av at IP-adresser er PII per GDPR; retention-policy må veies mot personvern; hva-vi-ikke-logger-bevisst (HTTP body, secrets) |
| Mapping NIST | SP 800-53 AU-1 |
| Mapping ISO | 8.15, 5.31 (Legal, statutory, regulatory and contractual requirements) |
| Norsk lovverk | Personopplysningsloven (GDPR), e-komloven (lagring av trafikkdata), arbeidsmiljøloven (overvåking av ansatte krever drøfting) |
| Gap | For en virksomhet med ansatte må ansatt-overvåkning drøftes med tillitsvalgte og dokumenteres skriftlig per arbeidsmiljøloven § 9-2. Ikke relevant for hjemmelab. |

## 3.2.3 — Avgjør hvilke deler av IKT-systemet som skal overvåkes

NSM-tekst: kritiske deler, OS, interne nøkkelpunkt, internt-eksternt nøkkelpunkt, sikkerhetsprodukter, backup-systemer.

| Aspekt | Implementasjon |
|---|---|
| Hvor | `praksis.md` har full kilde-tabell mot threat-model |
| Status | Implementert |
| Bevis | 8 distinkte log-kilder mappet mot konkrete actor classes (A1-A5 fra ssh-hardening, B1-B6 fra vps-bootstrap) |
| Mapping NIST | SP 800-53 AU-2 (Audit Events) |
| Mapping NIST CSF | DE.CM-1, DE.CM-3, DE.CM-7 |
| Mapping ISO | 8.15, 8.16 (Monitoring activities) |
| Gap | Backup-systemovervåkning er ikke i scope (backup-lab eksisterer ikke ennå). Application-level logging også planlagt for senere. |

## 3.2.4 — Beslutt hvilke data som er sikkerhetsrelevant og bør samles inn

NSM-tekst: tilgangskontroll-data, admin/sikkerhets-logger, og for klienter spesielt: forsøk på kjøring av ukjent programvare, forsøk på privilege escalation.

| Aspekt | Implementasjon |
|---|---|
| Hvor | `ssh-hardening/server-config/sshd_config.d/40-audit.conf` (LogLevel VERBOSE), `vps-bootstrap/scripts/00-bootstrap.sh` (auditd watches) |
| Status | Implementert (på relevante deler) |
| Bevis | sshd VERBOSE logger key fingerprints; auditd watcher sshd_config, sudoers, authorized_keys, docker.sock |
| Mapping NIST | SP 800-53 AU-2, AU-3 (Content of Audit Records), AU-12 (Audit Generation) |
| Mapping ISO | 8.15 |
| Gap | Forsøk på kjøring av ukjent programvare (NSM nevner spesifikt for klienter) er kun delvis dekket på server via auditd execve — bør utvides for faktisk klient-overvåkning hvis lab utvides. |

## 3.2.5 — Verifiser at innsamling fungerer etter hensikt

NSM-tekst: kontroll av loginnstillinger, tilstrekkelig lagringsplass, standardisert format for tredjeparts logganalyseverktøy.

| Aspekt | Implementasjon |
|---|---|
| Hvor | `praksis.md` har coverage-test-prosedyre (kjør benign signal, verifiser at det havner i pipeline), `parsers/vector.toml` strukturerer JSON-output |
| Status | Implementert (prosedyrelt) |
| Bevis | Coverage-test gir end-to-end-verifikasjon av detection-pipeline |
| Mapping NIST | SP 800-53 AU-12, CA-7 (Continuous Monitoring) |
| Mapping ISO | 8.15, 8.16 |
| Gap | Ingen automatisert healthcheck (cron-job som verifiserer at logging-pipeline kjører). I virksomhet ville Prometheus + alertmanager dekke dette. |

## 3.2.6 — Påse at innsamlet data ikke kan manipuleres

NSM-tekst: signering av logger, tilgangsstyring, deteksjon av manipulering/sletting, tidssynkronisering, sentral konsolidering.

| Aspekt | Implementasjon |
|---|---|
| Hvor | auditd-rules watcher `/var/log/audit/audit.log` selv (`-w /var/log/audit/audit.log -p wa -k log_tampering`); ekstern shipping for redundans; chrony for tidssynkronisering |
| Status | Implementert |
| Bevis | auditd er konfigurert med `-e 2` (immutable rules until reboot); journald sealing kan aktiveres med Seal=yes; Vector buffer for nettverksavbrudd |
| Mapping NIST | SP 800-53 AU-9 (Protection of Audit Information), AU-9(2) (Store on Separate Physical Systems), AU-8 (Time Stamps) |
| Mapping ISO | 8.15, 5.28 (Information transfer) |
| Gap | Ingen WORM-storage på collector-siden i lab-en (avhengig av faktisk SIEM-deployment). Journald sealing (FSS) er ikke aktivert som default. |

## 3.2.7 — Gjennomgå og konfigurer innhenting av sikkerhetsrelevant data jevnlig

NSM-tekst: periodisk gjennomgang for å sikre at det innhentes relevante data, og for å fjerne data som ikke lenger har relevans.

| Aspekt | Implementasjon |
|---|---|
| Hvor | `examples/triage-playbook.md` dokumenterer kvartalsvis review-prosess; sjekkpunkter for regel-helse, FP-rate, storage |
| Status | Delvis implementert |
| Bevis | Prosess dokumentert; kriterier definert |
| Mapping NIST | SP 800-53 CA-7 (Continuous Monitoring), AU-6 (Audit Review) |
| Mapping ISO | 8.16 |
| Gap | Ingen automatisert dashboard for regel-helse over tid. I virksomhet ville Grafana eller Sentinel workbook dekket dette. Ingen scheduled "log volume vs. baseline"-alert. |

## Sammendrag

| Tiltak | Status | Modenhet (1-5) |
|---|---|---|
| 3.2.1 Strategi og retningslinjer | Implementert (dok-nivå) | 3 |
| 3.2.2 Lover og regler | Delvis (dokumentert, ikke ratifisert) | 2-3 |
| 3.2.3 Hvilke deler å overvåke | Implementert | 3 |
| 3.2.4 Hvilke data å samle | Implementert (relevant) | 3 |
| 3.2.5 Verifisering av innsamling | Implementert (prosedyrelt) | 2-3 |
| 3.2.6 Beskyttelse av data | Implementert | 3 |
| 3.2.7 Periodisk gjennomgang | Delvis | 2 |

**Gjennomsnittlig modenhet:** 2-3 (mellom Reaktivt og Definert).

## Detection-engineering layer (over og utover 3.2)

NSM 3.2 ber om at logger samles og beskyttes, men sier mindre om *hvordan* detection-regler skrives. Dette er prinsipp 3.3 (Analyser data fra sikkerhetsovervåkning). Lab-en dekker også 3.3 indirekte via:

- 5 Sigma-regler i `sigma-rules/`
- KQL-implementasjoner for Sentinel
- SPL-implementasjoner for Splunk
- MITRE ATT&CK-mapping per regel

Detaljer i `praksis.md` og MITRE ATT&CK coverage-tabell i `examples/MITRE-mapping.csv`.

## Cross-walks

| NSM | NIST CSF 2.0 | NIST SP 800-53 | ISO 27002:2022 | MITRE D3FEND |
|---|---|---|---|---|
| 3.2.1 | DE.DP-1 | AU-1, PM-14 | 8.15 | (n/a) |
| 3.2.2 | DE.DP-2 | AU-1 | 8.15, 5.31 | (n/a) |
| 3.2.3 | DE.CM-1, DE.CM-3 | AU-2 | 8.15 | D3-LM (Log Management) |
| 3.2.4 | DE.CM-1 | AU-2, AU-3, AU-12 | 8.15 | D3-LFA (Log File Analysis) |
| 3.2.5 | DE.DP-3 | AU-12, CA-7 | 8.15, 8.16 | D3-OAM (Operating Activity Monitoring) |
| 3.2.6 | PR.PT-1 | AU-9, AU-9(2), AU-8 | 8.15, 5.28 | D3-LIA (Log Integrity Analysis) |
| 3.2.7 | DE.DP-5 | CA-7, AU-6 | 8.16 | (n/a) |
