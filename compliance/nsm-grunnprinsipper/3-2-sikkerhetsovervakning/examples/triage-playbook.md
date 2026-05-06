# Triage Playbook — slik vurderes alerts før de eskaleres

Dokumentet er en SOC-style triage-prosedyre. Det dekker hva en operatør gjør i de første 5-15 minuttene etter at en alert utløses, før hen bestemmer om det er en faktisk hendelse som skal eskaleres til full incident response.

## Filosofien bak triage

Hver alert er en hypotese. Triage tester hypotesen med så lite arbeid som mulig — hvis den er feil (false positive), lukk den. Hvis den er riktig, eskaler. Hvis den er usikker, samle mer kontekst.

Tre utfall mulig:

- **Closed — false positive.** Notert i dashboard. Hvis FP-rate på regelen blir høy, regelen må tunes.
- **Open — confirmed incident.** Eskalerer til response-playbook.
- **Open — under investigation.** Mer kontekst trengs. Time-out etter 30 min hvis ingen progress.

## Trinn 1 — Initial vurdering (under 2 minutter)

Når en alert kommer inn, sjekk *fire kritiske faktorer*:

### 1. Severity og asset criticality

Sigma-regelen rapporterer en `level:`. Sammenstill med assetens kritikalitet:

| Sigma-level | Asset crit | Effective severity |
|---|---|---|
| critical | high | P1 — handle nå |
| critical | low | P2 — denne timen |
| high | high | P1 — handle nå |
| high | low | P2 — innen dagen |
| medium | high | P3 — denne uken |
| medium | low | P4 — backlog |

Asset criticality er kontekst som SIEM-en ikke vet alene. En alert om docker-socket-access på prod-DB er P1. Samme alert på dev-sandbox er P3.

### 2. Volum

Er det én alert eller mange? Hundre alerts på samme regel innen 5 minutter er enten:
- En faktisk pågående angrep (storm av attempts)
- En ødelagt regel som genererer FP
- En endring i miljøet (f.eks. ny monitoring-agent som ser legitimt ut som anomali)

Ikke spend 30 min på den første alert hvis det er 99 til som venter.

### 3. Kjent kontekst

Sjekk change-management. Er det en planlagt endring som matcher tidsstempelet?

- Kjørte en `apt upgrade` som rørte sshd_config?
- Ble en ny Ansible-playbook applied?
- Logget noen seg på for vedlikehold?

Hvis ja, dokumenter koblingen og lukk som FP. Hvis nei, fortsett.

### 4. Identitet bak handlingen

Hvem er `audit_uid` eller `sudo_user`? Match mot:
- Operatør-roster
- Service accounts godkjentliste
- Vendor support-kontoer

En kjent operatør er ikke automatisk legitim, men gir lavere mistanke enn en ukjent eller "midlertidig" account.

## Trinn 2 — Samle kontekst (3-10 minutter)

Hvis trinn 1 ikke ga en clear FP-konklusjon, hent mer data:

### For SSH brute force-alerts

```kql
// Sjekk om source IP har lykkes på samme host eller andre hoster
Syslog
| where TimeGenerated > ago(24h)
| where SyslogMessage contains "Accepted publickey"
| where SyslogMessage contains "<source-ip>"
| project TimeGenerated, Computer, SyslogMessage
```

Hvis source IP har lykket suksess senere, det er ikke lenger "brute force-attempt" — det er "compromise via brute force followed by access". Eskalering.

### For config tampering

```kql
// Sjekk hvilken commit / endring matcher tidsstempelet
// Korreler med git log fra deployment server hvis tilgjengelig
Syslog
| where Computer == "<host>"
| where TimeGenerated between (datetime(<event_time>)-5m .. datetime(<event_time>)+5m)
| where ProcessName !in ("sshd")
| project TimeGenerated, ProcessName, SyslogMessage
```

Letter etter parent process, andre samtidige aktiviteter.

### For docker socket access

Critical i de fleste tilfeller. Sjekk:
- Hvilken container-image kjører den prosessen som rørte socket?
- Eller var det en non-container prosess på host?
- Match `ProcessName` mot kjente legitime tools (Portainer, k3s-agent, etc.)

### For sudo anomaly

```kql
// Hva gjorde brukeren før og etter sudo-eventet?
Syslog
| where Computer == "<host>"
| where TimeGenerated between (datetime(<event_time>)-15m .. datetime(<event_time>)+15m)
| where Facility == "auth" or SyslogMessage contains "<sudo_user>"
| project TimeGenerated, ProcessName, SyslogMessage
| order by TimeGenerated asc
```

Etablerer narrative: ble brukeren autentisert legitimt? Hva førte fram til sudo-eventet?

## Trinn 3 — Avgjørelse

Etter trinn 1-2:

**Lukk som FP** hvis:
- Alle "is this expected?"-sjekker er ja
- Match mot change record finnes
- Operatør bekrefter at hen utførte handlingen

Notér i alert-management:
- Regel-ID
- Hvorfor lukket (kort: "matchet ansible run cron 2026-05-04 03:15")
- Tidsforbruk på triage

**Eskaler til incident response** hvis:
- Identitet eller handling kan ikke forklares legitimt
- Korrelasjon viser at dette er ett av flere tegn (kill-chain assembly)
- Asset er kritisk og signal er high/critical
- Du er usikker — eskalering er ikke dyrt, missed compromise er

Fyll ut incident ticket med:
- Alert-data
- Triage-notater
- Hva som er gjort (containment-steps tatt, eller eksplisitt "ingen — venter på response team")
- Initial hypotese om hva som skjer

**Hold som "under investigation"** hvis:
- Du trenger mer data og det krever spesialisert tooling (forensic image, memory dump)
- Du venter på at en ekspert leser inn

Time-out er 30 minutter — etter det må alert enten lukkes eller eskaleres. Ingen alerts skal hvile i "under investigation" over natten uten at noen vet.

## Anti-patterns — hva en god triage IKKE gjør

- **Closer alerts uten å lese dem.** "Det er bare X-regel, alltid FP" kan være sant 99 ganger og fatalt den 100. gangen.
- **Eskaler alt for trygghets skyld.** Det overbelaster response-teamet og gjør at de slutter å lese eskaleringer.
- **Bruker mer enn 15 min på en triage.** Hvis du ikke kan avgjøre etter 15 min, eskaler. Tiden din er mer verdifull enn alert-volumet.
- **Glemmer å dokumentere.** Hver triage-beslutning bør være rekonstruerbar 6 måneder senere.

## Cross-references

- For vurdering av severity: `severity-matrix.md`
- For respons etter eskalering: `response-playbook.md`
- For MITRE-kontekst: `MITRE-mapping.csv`

## Sources

- "Practical Threat Intelligence and Data-Driven Threat Hunting" — Valentina Costa-Gazcón
- SANS DFIR posters
- erfaringer fra `cybsec-events`-sporet (markedsobservasjon Oslo/NCSC)
