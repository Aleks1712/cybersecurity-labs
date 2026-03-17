# MITRE ATT&CK – Dybdeanalyse

> Basert på praktiske analyser: BOTSv1, malware-analyse og ICS-angrep

## Hva er MITRE ATT&CK?

MITRE ATT&CK er et globalt kunnskapsbibliotek som dokumenterer hvordan angripere opererer.
```
TAKTIKK  → Hva angriperen vil oppnå (f.eks. Initial Access)
  └─ TEKNIKK    → Hvordan (f.eks. Spearphishing)
       └─ SUBTEKNIKK → Spesifikk variant (T1566.001)
```

## BOTSv1 – Full ATT&CK-mapping

### T1595.002 – Active Scanning
```splunk
index="botsv1" earliest=0 attack="Acunetix.Web.Vulnerability.Scanner"
```
Acunetix setter unik User-Agent og kjører mange forespørsler raskt.
Deteksjon: `stats count by src_ip` og se etter statistisk avvik.

### T1190 – Exploit Public-Facing Application
Microsoft-IIS/8.5 er end-of-life med kjente XSS-sårbarheter.
XSS kan brukes til å stjele session cookies eller laste inn BeEF hook.

### T1110 – Brute Force
Mønsteret (s-start og kun tall) indikerer dictionary attack.
Deteksjon: Mer enn 10 POST til samme endepunkt innen 60 sekunder.

### T1021.002 – SMB Lateral Movement
```
Remote Registry  → Leser Windows-registeret for persistens-mekanismer
SAM              → Hashede passord for lokale brukere
LSA              → Cached credentials og LSA secrets
```
Tilgang til SAM/LSA er typisk forløperen til credential dumping.

### T1071.004 – DNS Tunneling
Normal DNS: korte domenenavn som `google.com`
Mistenkelig: lange base32-kodede strenger i queries
Verktøy: iodine, dnscat2, Cobalt Strike DNS beacon

## VBA Macro – T1566 kjeden
```
T1566.001  Spearphishing Attachment  → passordbeskyttet .docm
T1027      Obfuscated Files          → passord hindrer skanning
T1204.002  User Execution            → Document_Open() auto-kjøring
T1105      Ingress Tool Transfer     → URLDownloadToFileA → invoice.exe
T1059      Command Interpreter       → ShellExecuteA kjører payload
T1070      Indicator Removal         → dokument slettes, falsk feil
```

## FrostyGoop – MITRE ATT&CK for ICS
```
T0819  Exploit Public-Facing App  → sårbar ruter kompromittert
T0812  Default Credentials        → IT til OT bevegelse
T1003  Credential Dumping         → SAM-data hentet ut
T0869  Standard App Layer Proto   → Modbus TCP (port 502)
T0831  Manipulation of Control    → ENCO-kontrollere manipulert
```

Modbus har ingen autentisering, ingen kryptering – designet 1979.

## Volt Typhoon – Living off the Land
```
T1595   Rekognosering av Fortinet, Cisco, Ivanti
T1190   CVE-2024-39717 i VPN-gatewayer
T1059   WMIC, PowerShell, ntdsutil, netsh
T1003   ntdsutil → NTDS.dit → offline passordknekking
T1550   Pass-the-Hash lateral movement
T1090   KV-botnett via SOHO-routere maskerer C2
T0831   Pre-positioning mot OT-systemer
```

Dwell time: opptil 5 år uoppdaget.

## Deteksjon – Splunk
```splunk
// ntdsutil credential dumping
index=* EventCode=1 Image="*ntdsutil.exe"
| table _time, ComputerName, CommandLine

// PowerShell obfuskering
index=* EventCode=1 Image="*powershell.exe"
    (CommandLine="*-enc*" OR CommandLine="*-EncodedCommand*")
| table _time, ComputerName, CommandLine

// WMIC remote execution
index=* EventCode=1 Image="*wmic.exe" CommandLine="*/node:*"
| table _time, ComputerName, CommandLine
```

## Alle observerte teknikker

| ID | Teknikk | Lab |
|----|---------|-----|
| T1595.002 | Active Scanning | BOTSv1 |
| T1190 | Exploit Public-Facing App | BOTSv1, FrostyGoop |
| T1566.001 | Spearphishing Attachment | YARA |
| T1027 | Obfuscated Files | YARA |
| T1204.002 | User Execution | YARA |
| T1105 | Ingress Tool Transfer | YARA |
| T1110 | Brute Force | BOTSv1 |
| T1078 | Valid Accounts | BOTSv1 |
| T1003 | Credential Dumping | BOTSv1, FrostyGoop |
| T1021.002 | SMB Lateral Movement | BOTSv1 |
| T1071.004 | DNS Tunneling | BOTSv1 |
| T1070 | Indicator Removal | YARA |
| T1090.002 | External Proxy (KV-botnett) | Volt Typhoon |
| T1550.002 | Pass the Hash | Volt Typhoon |
| T0831 | Manipulation of Control (ICS) | FrostyGoop |
