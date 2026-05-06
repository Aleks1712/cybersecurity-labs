# Teori — NSM 2.3 Ivareta en sikker konfigurasjon

## Bakgrunn

Sikker konfigurasjon er et av de mest underrapporterte sikkerhetstiltakene fordi det høres trivielt ut. "Sett opp serveren riktig" er instinktivt klart, men i praksis er det her de fleste reelle kompromisser starter. Misconfigurations konsistent topper Verizon DBIR sine årsrapporter som en av de største årsakene til breach.

NSM 2.3 adresserer dette ved å kreve at virksomheten har en bevisst, dokumentert tilnærming til hvordan systemer konfigureres, ikke bare hva de leveres med fra produsent.

## Det grunnleggende problemet

Operativsystemer og applikasjoner leveres med default-konfigurasjon som er optimalisert for to ting: bred kompatibilitet og enkel oppstart. Ingen av disse er optimalisert for sikkerhet i et truet miljø. Eksempler:

- **Ubuntu 24.04 cloud image:** SSH lytter på `0.0.0.0:22` med `PasswordAuthentication yes`. Det er rasjonelt fra leverandørens side — kunden må kunne logge inn første gang. Men det betyr at en fresh VPS er under aktiv brute-force-angrep innen sekunder etter første boot.
- **Docker default:** Containere kan publishes på `0.0.0.0:port` og bypasser host-firewall. Det forenkler "hello world", men eksponerer applikasjoner ufrivillig.
- **OpenSSH default crypto:** Inkluderer algoritmer som er kjent svake (`diffie-hellman-group1-sha1`, `ssh-rsa` med SHA-1) for kompatibilitet med eldre klienter.

Sikker konfigurasjon handler om å bevisst velge bort default der defaulten ikke matcher trusselbildet.

## Hva NSM 2.3 konkret krever

Paraphrased fra NSM Grunnprinsipper v2.1, prinsipp 2.3:

Virksomheten skal etablere en sikker konfigurasjon for IKT-systemer ved å fjerne unødvendige funksjoner og tjenester, slå på sikkerhetstiltak som er tilgjengelig i plattformen, og dokumentere konfigurasjonen slik at den kan opprettholdes over tid og ved endringer.

Underliggende tiltak (NSM v2.1):

- **2.3.1** — Etabler et sentralt styrt regime for sikkerhetsoppdatering
- **2.3.2** — Konfigurer klienter slik at kun kjent programvare kjører på dem
- **2.3.3** — Deaktiver unødvendig funksjonalitet
- **2.3.4** — Etabler og vedlikehold standard sikkerhetskonfigurasjoner
- **2.3.5** — Verifiser at aktivert sikkerhetskonfigurasjon er i henhold til godkjent baseline
- **2.3.6** — Utfør all konfigurasjon, installasjon og drift på en trygg måte
- **2.3.7** — Endre alle standardpassord
- **2.3.8** — Ikke deaktiver kodebeskyttelsesfunksjoner
- **2.3.9** — Etabler sikker tid
- **2.3.10** — Reduser risiko ved IoT-enheter

## Den kritiske nyansen i 2.3.2 — eksekvering vs. installering (ny i v2.1)

NSM v2.1 har eksplisitt presisering av tiltak 2.3.2: "Husk at programvare ikke må være installert for å kunne kjøre."

Dette er en av de viktigste praktiske observasjonene i hele rammeverket. Tradisjonell software inventory-tilnærming spør "hva er installert?" og fokuserer kontroll på install-tidspunktet. Det er utilstrekkelig fordi:

- En PowerShell-script kan kjøre uten å være installert
- En kompilert binary kan lastes ned, kjøres fra `/tmp` og slettes
- En "living off the land" angriper bruker pre-installerte tools (`certutil`, `bitsadmin`, `wmic`) på måter de ikke var ment for
- Skript-motorer (Python, Bash, JavaScript via Node, makroer i dokumenter) eksekverer kode som aldri "installeres"

Riktig kontroll skjer på eksekverings-tidspunktet, ikke install-tidspunktet. NSM 2.3.2.a anbefaler eksplisitt godkjentlisting av kode som faktisk får kjøre, signert av tiltrodd part.

For Linux-server-skala (våre labs) manifesterer dette seg som:
- AppArmor / SELinux-profiler som begrenser hva en prosess kan kjøre
- `noexec`-mount-flag på `/tmp` og `/var/tmp` (hindrer execution fra writable directories)
- auditd execve-auditing som logger hva som faktisk eksekveres
- I container-context: `read_only: true` på Docker-volumer som har binaries

Lab-en behandler dette under praksis.md som en faktisk implementerbar kontroll, ikke som et abstrakt prinsipp.

## Hva en sikker baseline består av

En baseline er ikke en fil, det er en dokumentert tilstand bestående av:

**Plattformnivå:**
- Hvilke pakker som skal være installert (og hvilke som eksplisitt ikke skal)
- Kjernel-parametere (`sysctl`) som er satt
- Hvilke tjenester (`systemd units`) som er aktivert
- Filsystemets monteringer og rettigheter på kritiske filer

**Tjenestenivå:**
- Konfigurasjonsfiler per tjeneste, med eksplisitt verdier på sikkerhetsrelevante direktiver
- Hvilke porter/endpoints som er aktive og hvilke som er eksplisitt deaktivert
- Hvilke kryptografiske primitiver som er tillatt

**Brukernivå:**
- Hvilke brukerkontoer som finnes og deres roller
- PAM-konfigurasjon
- sudo-policy
- Authorized_keys-policy

**Nettverksnivå:**
- Firewall-regler og deres rasjonale
- Routing-tabeller
- DNS-konfigurasjon

## Forskjellen på "konfigurasjon" og "sikker konfigurasjon"

En vanlig misforståelse er at all konfigurasjon-arbeid er sikkerhets-arbeid. Det er det ikke. Konfigurasjon er hvordan systemet kjører. Sikker konfigurasjon er en delmengde der valg er gjort *eksplisitt for å redusere angrepsflate* eller *eksplisitt for å øke detection-kapasitet*.

Eksempel:
- "Tjenestene skal starte automatisk ved boot" → konfigurasjon
- "Tjenestene som ikke trengs skal være avinstallert, ikke bare disabled" → sikker konfigurasjon
- "Logging skal være aktivert" → konfigurasjon
- "Logging skal være på `LogLevel VERBOSE` for å fange auth-fingerprints, og logger skal sendes til ekstern collector for å overleve host-kompromiss" → sikker konfigurasjon

Det er nyansen NSM 2.3 ber om.

## Konfigurasjon som kode

Moderne tilnærming er å behandle konfigurasjon som kildekode:

1. **Versjonskontrollert.** Hver endring har en commit, en author, en timestamp, og en begrunnelse i commit-meldingen.
2. **Reviewable.** Endringer kan diff-es og gjennomgås før de tar effekt.
3. **Reproduserbar.** Samme baseline kan re-anvendes på en ny host og produsere samme tilstand.
4. **Testbar.** Det finnes automatiserte tester som kan verifisere at konfigurasjonen er korrekt anvendt.

Dette er det som skiller en moderne hardening-praksis fra "loggte inn på server, redigerte fil, husket hva jeg gjorde". For en hjemmelab er git + bash-script tilstrekkelig. For virksomheter med 50+ servere blir det Ansible, Puppet, Salt, eller tilsvarende.

## Drift — det stille problemet

"Configuration drift" er fenomenet der konfigurasjon avviker fra baseline over tid. Det skjer på tre måter:

1. **Manuelle endringer.** Noen logger inn for å feilsøke, endrer en konfig-linje, glemmer å rulle tilbake.
2. **Pakke-oppgraderinger.** En `apt upgrade` kan introdusere nye konfigurasjonsfiler eller endre defaults.
3. **Plattform-endringer.** Cloud-leverandøren oppdaterer en AMI, et nytt cloud-init-skript kjører, og din instilling overskrives.

NSM 2.3.4 ber om at avvik kan detekteres. På virksomhets-skala er dette ansvarsområdet til verktøy som AIDE, OSSEC, Tripwire, eller cloud-native løsninger som AWS Config Rules. På hjemmelab-skala er auditd på kritiske konfig-filer en realistisk approximation: hvis noen rører `/etc/ssh/sshd_config`, lander det i journalen og kan flagges av en Sigma-regel.

## Periodisk verifikasjon

NSM 2.3.5 ber om at konfigurasjonen verifiseres periodisk. Det betyr ikke "se på det av og til" — det betyr at det finnes en gjentatt prosess som måler tilstanden mot baseline og rapporterer avvik.

For våre labs gjøres dette med:
- `ssh-audit` mot SSH-tjenester (eksternt perspektiv)
- `Lynis` mot host-konfig (internt perspektiv)
- `verify-sshd-config.sh` (custom script for kritiske direktiver)
- `99-verify.sh` (post-bootstrap state check)

Periodisiteten kan være ad-hoc i hjemmelab. I virksomhet bør det være automatisert (cron, CI/CD pipeline, scheduled GitHub Action) med output som leses av en faktisk person.

## Hvordan dette kobler til andre prinsipper

Sikker konfigurasjon (2.3) er en forutsetning for flere andre prinsipper:

- **2.4 Beskytt nettverk** — krever at konfigurasjonen av firewall, mesh, og rutere faktisk er som baseline tilsier
- **2.6 Identitet og tilgang** — krever at sshd_config, PAM, og sudoers er i kjent god tilstand
- **3.2 Sikkerhetsovervåkning** — krever at logg-konfigurasjon (LogLevel, syslog, journald) er konsistent
- **2.10 Endringshåndtering** — er prosessen rundt endringer i konfig

Med andre ord: 2.3 er fundament. Hvis du ikke har en kjent baseline, kan du ikke detektere avvik, og uten avviksdeteksjon kan du ikke svare på "har dette systemet blitt rørt?".

## Sources

- NSM Grunnprinsipper v2.1, prinsipp 2.3
  https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ivareta-en-sikker-konfigurasjon/
- Verizon Data Breach Investigations Report (DBIR), årlig publikasjon
- NIST SP 800-128 — Guide for Security-Focused Configuration Management of Information Systems
- CIS Critical Security Controls v8, control 4 (Secure Configuration)
