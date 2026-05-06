# Journald log shipping — design notes

## Hvorfor journald som primærkilde

På Ubuntu 24.04 (basis for `vps-bootstrap`) er journald defaultet for log-collection. Tradisjonelt har Linux-system brukt syslog → `/var/log/auth.log`, men journald har fordeler:

- **Strukturerte felt.** Hver event har key-value-par, ikke bare en streng.
- **Indeksert.** `journalctl --grep`, filtere på `_PID`, `_UID`, `SYSLOG_IDENTIFIER` er native.
- **Forwarder-vennlig.** `systemd-journal-upload` kan pushe direkte til en sentral collector.
- **Tamper-resistant (delvis).** Med `Seal=yes` og forward secure sealing (FSS) signeres journal-blokker, så manipulering kan oppdages.

Vps-bootstrap skriver fortsatt syslog parallelt for kompatibilitet, men journald er sannhetskilden for de fleste sikkerhetsrelevante events.

## Tre arkitektur-alternativer

### Alternativ A: systemd-journal-upload → systemd-journal-remote

Native systemd-løsning. Crypto-vennlig (TLS native).

```
┌──────────────┐     HTTPS/TLS      ┌───────────────────────────┐
│ vps-host     │  ─────────────►    │ central log collector     │
│ journald     │                    │ systemd-journal-remote    │
│ + journal-   │                    │ + journalctl over network │
│   upload     │                    │ + downstream forwarders   │
└──────────────┘                    └───────────────────────────┘
```

**Pluss:** ingen ekstra agent, krypto innebygget, samme format hele veien
**Minus:** ingen transformasjon, krever sentral journald-host som ikke er native på Sentinel/Splunk/Loki

### Alternativ B: Vector som universal agent

Mer fleksibel. Kan transformere og pushe til hvilken som helst collector.

```
┌──────────────┐                    ┌────────────┐
│ vps-host     │  ─►  vector  ─►    │  Loki      │
│ journald +   │                    └────────────┘
│ /var/log/    │            └─►     ┌────────────┐
│ audit/       │                    │  Splunk    │
└──────────────┘                    └────────────┘
                            └─►     ┌────────────┐
                                    │  Sentinel  │
                                    └────────────┘
```

Konfigurert i `vector.toml` i denne mappen.

**Pluss:** ett verktøy uansett SIEM, rich transformations, mature
**Minus:** ekstra agent, ressursforbruk på små VPS

### Alternativ C: Promtail (Loki-spesifikk)

```
┌──────────────┐                    ┌────────────┐
│ vps-host     │ ─►  promtail  ─►   │  Loki      │
└──────────────┘                    └────────────┘
```

Konfigurert i `promtail.yaml`.

**Pluss:** veldig lett, native Loki labels
**Minus:** kun Loki-output

## Anbefaling for hjemmelab-skala

For 1-3 VPS:
- Alternativ C (Promtail) hvis du allerede kjører Grafana stack
- Alternativ A (systemd-journal-upload) hvis du vil ha minst mulig tooling
- Alternativ B (Vector) hvis du eksperimenterer med flere SIEM-er parallelt

For ekte virksomhet:
- Alternativ B (Vector) eller en cloud-leverandørs native agent (AMA for Sentinel, Splunk Universal Forwarder)

## Hva som mangler for full implementasjon

Dette er konfig-eksempler, ikke et ferdig deployment. For å faktisk shippe logger trenger du:

1. **Endpoint.** En kjørende Loki/Splunk/Sentinel som kan motta. Ikke i scope for denne lab-en — den dekker source-side.
2. **Auth-credentials.** Vector og Promtail har eksempel-stubber, men du må generere og deploye dine egne.
3. **TLS-configurasjon.** Hvis logger går over public internet (ikke gjennom mesh) må det være TLS med sertifikat-pinning.
4. **Retention-policy.** Hvor lenge skal logger lagres? GDPR-implikasjoner hvis du lagrer source IPs lenger enn nødvendig.

Disse er virksomhets-skala beslutninger som ikke har én riktig svar.
