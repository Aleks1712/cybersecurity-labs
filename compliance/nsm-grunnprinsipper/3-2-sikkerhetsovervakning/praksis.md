# Praksis — slik implementerer eksisterende labs NSM 3.2

Pipeline fra event-source til respons, med konkrete filer og verktøy per fase.

## 3.2.1 — Definer hvilke kilder skal overvåkes basert på risiko

NSM ber om at log-kilder velges basert på risikovurdering, ikke "alt" eller "tilfeldig".

### Hvordan vi gjør det

Lab-ens log-kilder er valgt basert på threat models i `ssh-hardening/THREAT-MODEL.md` (A1-A5 actor classes) og `vps-bootstrap/THREAT-MODEL.md` (B1-B6). Hver kilde dekker et bestemt sett av aktører:

| Kilde | Konfig-fil | Dekker aktør | Hvilken evne |
|---|---|---|---|
| `sshd` (LogLevel VERBOSE) | `ssh-hardening/server-config/sshd_config.d/40-audit.conf` | A2 (interactive auth attacks), A4 (key compromise) | Failed/successful auth, key fingerprints |
| `auditd` på sshd_config | `vps-bootstrap/scripts/00-bootstrap.sh` | A4, B6 (provider compromise) | Tampering med SSH-konfig |
| `auditd` på authorized_keys | `vps-bootstrap/scripts/00-bootstrap.sh` | A4 (persistence via key) | Backdoor key insertion |
| `auditd` på sudoers | `vps-bootstrap/scripts/00-bootstrap.sh` | post-compromise privesc | Sudo-policy tampering |
| `auditd` på docker.sock | `vps-bootstrap/scripts/00-bootstrap.sh` | B5 (web exploit → container escape) | Container escape attempts |
| `ufw.log` | `vps-bootstrap/ufw/` | B1 (mass scanners) | Blocked traffic patterns |
| `fail2ban` | `vps-bootstrap/fail2ban/jail.local` | A2, B1 | Successful bans (= attempted brute force) |
| Docker daemon (journald driver) | `vps-bootstrap/docker/daemon.json` | B5 | Container lifecycle events |

Kritisk: kilde-valget er drevet av "hvilke angrep vil vi se?", ikke "hva er enkelt å logge?". Sistnevnte gir bias mot lette kilder og blindspots på de viktige.

### Hva som ikke logges (bevisst)

For å unngå log-volume-eksplosjon og GDPR-problemer, logges *ikke*:

- **Application body content.** HTTP request body kan inneholde PII. Vi logger headers og status, ikke body.
- **Password attempts (cleartext).** sshd logger aldri passord, men noen apps gjør det. Strip ut.
- **Full TLS handshake content.** Vi vet at TLS skjer, ikke hva som var inne.

Dette er en bevisst trade-off mellom detection-kapasitet og privacy/storage.

## 3.2.2 — Sentraliser logger fra IKT-systemene

NSM ber om at logger samles til ett sted som kan analyseres helhetlig.

### Hvordan vi gjør det

Tre arkitektur-alternativer er dokumentert i `parsers/journald-to-loki.md`. Sammendrag:

1. **systemd-journal-upload → systemd-journal-remote.** Native, krypto-vennlig.
2. **Vector som universal agent.** Konfig i `parsers/vector.toml`. Pusher til Loki/Splunk/Sentinel.
3. **Promtail.** Loki-spesifikk, lett-vekts. Konfig i `parsers/promtail.yaml`.

For lab-skala anbefales Vector (alternativ 2) hvis du eksperimenterer med flere SIEM-er. For drift anbefales den native agenten til SIEM-en (Azure Monitor Agent for Sentinel, Universal Forwarder for Splunk).

### Network design for log shipping

Critical: log shipping fra mange noder til én collector er en angrepsvektor i seg selv. Hvis collector kompromitteres, har angriperen alle logger fra alle noder pluss mulighet til å forfalske eller slette dem fremover.

Mitigering:
- Log shipping over mesh-VPN (ikke public internet)
- TLS med sertifikat-pinning hvis offentlig
- Append-only retention på collector-siden
- Secondary collector som mirror for redundans

## 3.2.3 — Etabler regler og indikatorer for å detektere avvik

NSM ber om at det finnes konkrete deteksjonsregler, ikke bare "noen ser på loggene av og til".

### Hvordan vi gjør det

5 Sigma-regler i `sigma-rules/`, hver tagged med MITRE ATT&CK og NSM-prinsipper:

| Regel | MITRE | Severity | Hva den fanger |
|---|---|---|---|
| `ssh-brute-force.yml` | T1110.001, T1110.003 | medium | Repeated auth failures fra én IP |
| `sshd-config-tampering.yml` | T1098.004, T1556 | high | Endring i sshd_config |
| `authorized-keys-tampering.yml` | T1098.004, T1021.004 | high (critical for root) | Key persistence |
| `docker-socket-access.yml` | T1611, T1610 | critical | Container escape attempts |
| `sudo-anomaly.yml` | T1548.003, T1078.003 | high–critical | Privilege escalation |

Hver regel er også implementert som KQL (`kql-queries/`) for Sentinel og SPL (`spl-queries/`) for Splunk, slik at en hiring manager kan se at jeg jobber multi-platform.

### Coverage-rasjonale

Jeg har bevisst valgt regler som:

1. **Dekker hele kill-chain-en for vps-scope.** Reconnaissance (SSH brute force) → initial access (key/config tampering) → persistence (authorized_keys) → privilege escalation (sudo) → impact (container escape).
2. **Bygger på telemetri vi faktisk har.** Ingen regel krever logger som ikke produseres av lab-konfig.
3. **Har lavere FP-rate gjennom kontekst.** Eksempel: `docker-socket-access` ekskluderer kjente Docker-prosesser. `sudo-anomaly` ekskluderer kjente sudoers.

### Hva som mangler for nivå 4

På nivå 4 ville jeg hatt:
- **Anomaly-baserte regler** (statistical baselining over flere uker)
- **UEBA** (user behavior analytics) — score brukere over tid
- **Threat intel-enrichment** — automatisk match mot AbuseIPDB / ThreatFox
- **Korrelerings-regler** som fanger sekvenser av events ("brute force fulgt av suksess fra samme IP innen 1 time")

Hjemmelab-modenhet på 3.2.3: 3 (Definert) for de regler som finnes, men ufullstendig coverage.

## 3.2.4 — Gjennomgå sikkerhetsovervåkningen periodisk

NSM ber om at det er en periodisk gjennomgang av at overvåkningen faktisk virker som tenkt.

### Hvordan vi gjør det

Demonstrert via `examples/triage-playbook.md` og kvartalsvis review-prosess dokumentert. Sjekkpunkter:

- **Coverage-test:** Kjør en kjent benign attack (failed SSH login fra ekstern IP). Genererer den alert? Hvis nei, regelen er ødelagt.
- **False-positive-rate:** Per regel, hvor mange alerts genereres per uke? Hvor mange er ekte? Hvis FP-rate > 80%, regelen må tunes.
- **Storage-helse:** Logger lagres faktisk? Retention-policy holder?
- **Pipeline-helse:** Vector/Promtail kjører? Buffer-er ikke fulle?

### Hva som mangler

Ingen automatisert dashboard som viser regel-helse over tid. Det er virksomhets-skala arbeid som krever et vedlikeholdt SIEM med use-case management.

## 3.2.5 — Beskytt logger mot uautorisert endring eller sletting

NSM ber om at logger ikke kan endres eller slettes av en angriper som har host-tilgang.

### Hvordan vi gjør det

Lagdelt forsvar:

**Lag 1 — Lokal beskyttelse:**
- auditd selv har rule som watcher andre log-filer:
  ```
  -w /var/log/auth.log -p wa -k log_tampering
  -w /var/log/audit/audit.log -p wa -k log_tampering
  ```
- journald sealing (FSS) hvis aktivert: signerer journal-blokker så manipulasjon detekteres

**Lag 2 — Ekstern shipping:**
- Logger sendes umiddelbart til ekstern collector. Selv om angriperen sletter lokal kopi, er ekstern kopi sikret.
- Vector buffrer events lokalt, så midlertidige nettverksavbrudd ikke gir log-tap.

**Lag 3 — Append-only collector:**
- Collector-siden bør være konfigurert append-only. Loki har dette gjennom WORM-flag på chunks. Splunk har frozen-buckets. Sentinel har immutable-flag.

### Realismetjekk

Forutsetning: angriperen har lokal host-kompromiss og prøver å skjule sporene. Bestens lokale forsvar er auditd-sealing + ekstern shipping. Hvis angriperen er root og kan stoppe auditd og vector før de skriver, kan de eliminere både lokal og ekstern logging — men da har de en annen rød flagg på collector-siden ("agent har sluttet å rapportere"), som er sin egen alert.

## Hva en hiring manager bør ta med

Tre punkter:

1. **Detection er detection-engineering.** Det er ikke "klikk i SIEM-en og slå på alle regler". Hver regel har en hypotese, en signal-source, en false-positive-policy, en MITRE-mapping.

2. **Sigma som format gjør deg portabel.** En kandidat som skriver Sigma kan jobbe med hvilket som helst SIEM. En kandidat som kun kan SPL er låst til Splunk.

3. **Coverage er en lang reise.** Å ha 5 solide regler med dokumentert FP-rate er bedre enn 200 importerte SigmaHQ-regler hvor du ikke vet hvilke som virker. Kvalitet over kvantitet.

## Sources

- NSM Grunnprinsipper v2.1, prinsipp 3.2
- SigmaHQ — https://sigmahq.io
- MITRE ATT&CK Enterprise — https://attack.mitre.org/
- ssh-hardening og vps-bootstrap labs i denne repoet (telemetri-source)
