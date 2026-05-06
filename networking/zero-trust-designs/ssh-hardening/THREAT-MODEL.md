# Threat Model — SSH Administrative Access

**Scope:** SSH brukt for administrasjon av Linux-hosts, både homelab (Proxmox VE, k3s noder, baremetal) og cloud (AWS EC2, Azure VMs, GCP Compute). Ikke SSH som transport for git, scp, eller automatiserte CI/CD pipelines — de har sine egne threat models.

**Assumptions:**
- Operatøren (meg) bruker en macOS klient med Secure Enclave tilgjengelig
- Servere kjører OpenSSH 9.0 eller nyere (alt under er enten patched eller i ferd med å bli erstattet)
- Det finnes en VPN-løsning (WireGuard) tilgjengelig for å eksponere SSH bak, ikke direkte på offentlig internett der det er mulig
- Operatøren har tilgang til hardware security key (YubiKey) for kritiske miljøer

## Aktører og deres kapabiliteter

### A1 — Opportunistisk masseangripere
- **Hva de gjør:** Scanner offentlig internett etter port 22, prøver password lister, kjente kompromitterte SSH keys
- **Kapabiliteter:** Lave. Botnet, ingen targeted intel
- **Mitigert av:** Ingen password auth, ingen offentlig eksponering der det er mulig, sterke nøkler
- **MITRE:** T1110.001 (Password Guessing), T1110.003 (Password Spraying)

### A2 — Targeted opportunist
- **Hva de gjør:** Identifiserer meg som mål (LinkedIn, GitHub, kanskje gjennom et tidligere lekket dataset), scanner mine kjente hosts, prøver credential reuse fra breach data
- **Kapabiliteter:** Moderate. Bruker offentlig OSINT, har tid til reconnaissance
- **Mitigert av:** Hardware-backed keys (kan ikke gjenbrukes fra et breach), per-host nøkler ikke én master-nøkkel, host nøkkel-pinning for å oppdage MITM
- **MITRE:** T1589 (Gather Victim Identity Information), T1110.004 (Credential Stuffing)

### A3 — Supply chain kompromiss
- **Hva de gjør:** Kompromitterer en pakke jeg installerer (npm, PyPI, brew formula), eller en CI-credential, og bruker det til å ekfiltrere SSH-nøkler eller installere keylogger på klienten min
- **Kapabiliteter:** Høye. Dette er threat-modellen hele bachelor-thesisen min handler om
- **Mitigert av:** Hardware-backed keys (privatnøkkelen forlater aldri Secure Enclave/YubiKey), egne SSH-nøkler ikke i `~/.ssh/id_*` der enhver pakke som lekker kan finne dem, separate nøkler for separate trust-domener
- **MITRE:** T1195.002 (Compromise Software Supply Chain), T1552.004 (Unsecured Credentials: Private Keys)

### A4 — Lateral movement etter initial kompromiss
- **Hva de gjør:** Har allerede en host i miljøet mitt (kanskje en sårbar container på k3s), prøver å hoppe til andre hosts via SSH agent forwarding, kompromitterte authorized_keys, eller stjålne nøkler fra `/home`
- **Kapabiliteter:** Høye, gitt at de allerede er innenfor
- **Mitigert av:** `AllowAgentForwarding no` på alle servere, `from=` restriksjon på authorized_keys, separate nøkler per trust-domene, segmenterte VPN-tunneller
- **MITRE:** T1021.004 (Remote Services: SSH), T1563.001 (Remote Service Session Hijacking: SSH Hijacking)

### A5 — Statlig aktør med "store now, decrypt later" kapasitet
- **Hva de gjør:** Logger SSH-trafikk i dag, planlegger å dekryptere når kvante-kapable angrep blir tilgjengelig
- **Kapabiliteter:** Svært høye, men interessen i meg spesifikt er lav
- **Mitigert av:** Post-quantum KEX (`sntrup761x25519-sha512@openssh.com`) der OpenSSH støtter det
- **Realistisk:** Ikke en sannsynlig trussel for meg personlig, men det er gratis å forsvare seg så hvorfor ikke

## Hva denne konfigurasjonen IKKE forsvarer mot

Ærlighet er viktig. Disse er ikke dekket og kan ikke dekkes av SSH-konfig alene:

- **Kompromittert klient med live session.** Hvis maskinen min er ownet og angriperen har en aktiv terminal, er SSH-konfig irrelevant. Endpoint security er en separat lag (FileVault, EDR, Yara-rules på `~/Library/LaunchAgents/`).
- **Insider på leverandørsiden.** Hvis Apple eller min sky-leverandør er kompromittert, er Secure Enclave / EC2 instance metadata tilgjengelig for angriperen. Forsvares delvis av at jeg ikke lagrer alle nøkler samme sted, men dette er en restriksjonsmulighet, ikke en mitigation.
- **Social engineering for å installere bakdør.** Hvis noen overbeviser meg om å kjøre `curl ... | sudo bash`, er ingenting trygt. Forsvares av personlig hygiene, ikke av sshd_config.
- **0-day i OpenSSH selv.** Patches raskt når CVE er publisert (`unattended-upgrades` på alle hosts). Mellom CVE og patch er det ingenting konfigurasjon kan gjøre.
- **Side-channel mot Secure Enclave / YubiKey.** Akademisk interessant, ikke realistisk for min trussel.

## Kontroller mappet til aktører

| Kontroll | A1 | A2 | A3 | A4 | A5 |
|---|---|---|---|---|---|
| Disable password auth | Y | Y | - | - | - |
| Hardware-backed keys (`sk-ed25519`) | - | Y | Y | Y | - |
| `AllowAgentForwarding no` | - | - | - | Y | - |
| `from=` på authorized_keys | - | Y | - | Y | - |
| Post-quantum KEX | - | - | - | - | Y |
| Host key pinning | - | Y | - | - | - |
| WireGuard foran SSH | Y | Y | - | partial | - |
| Separate keys per trust-domene | - | - | Y | Y | - |
| Auditd på sshd_config endringer | - | - | partial | Y | - |

## Når denne modellen må revideres

- **Hvis OpenSSH 10.x lander.** Sannsynligvis nye KEX-defaults og kanskje nye attack surfaces.
- **Hvis jeg får produksjonsansvar.** Da blir A4 (lateral movement) den dominante trusselen og dette er ikke nok.
- **Hvis jeg ser CVE-er som påvirker `sk-*` key types.** Hardware-backed keys er ikke magiske.
- **Årlig uansett.** Dato på forrige revisjon: 2026-05-05.

## Sources

- NIST SP 800-207 (Zero Trust Architecture) — for trust boundary thinking
- MITRE ATT&CK Enterprise Matrix v15 — for technique IDs
- "OpenSSH Threat Model" diskusjoner i openssh-unix-dev mailing list
