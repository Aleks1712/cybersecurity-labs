# Praksis — slik implementerer eksisterende labs NSM 2.3

Hvor teorien møter koden. Hvert tiltak under 2.3 er knyttet til konkrete filer og kommandoer i `ssh-hardening` og `vps-bootstrap`.

## 2.3.1 — Etabler en sikker konfigurasjonsbaseline

NSM ber om en dokumentert baseline tilpasset virksomhetens behov.

### Hvordan vi gjør det

Baseline er splittet i tre lag:

**Lag 1: SSH-tjeneste-baseline**
Filplassering: `networking/zero-trust-designs/ssh-hardening/server-config/sshd_config.d/`

```
10-crypto.conf      # KEX, ciphers, MACs, host keys
20-auth.conf        # Authentication policy
30-limits.conf      # Session limits, forwarding
40-audit.conf       # Logging
```

Hver fil har et avgrenset ansvar. Kommentarer i hver fil dokumenterer hvorfor hver direktiv er valgt, ikke bare hva den setter. Eksempel fra `10-crypto.conf`:

```ssh
# REMOVED from this list (and why):
#   diffie-hellman-group14-sha1                — SHA-1, broken
#   diffie-hellman-group1-sha1                 — DH-1024, broken
#   ecdh-sha2-nistp256/384/521                 — NIST curves, see above
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org
```

Det er ikke bare en godkjentliste — det er dokumentasjon av rasjonalet bak både inkluderinger og eksklusjoner.

**Lag 2: Host-baseline**
Filplassering: `networking/zero-trust-designs/vps-bootstrap/`

```
docker/daemon.json              # Docker engine policy
ufw/                            # Firewall baseline
fail2ban/jail.local             # Defense-in-depth
unattended-upgrades/*           # Patching policy
```

**Lag 3: Threat-model**
Filplassering: `THREAT-MODEL.md` i hver lab

Baseline er ikke arbitrær. Den følger fra en eksplisitt threat model med definerte aktører (A1-A5 for SSH, B1-B6 for VPS) og hva hver aktør kan og ikke kan. Hver konfig-linje kan spores tilbake til hvilken aktør den forsvarer mot.

### Mapping mot CIS og Mozilla

Baseline-en er ikke oppfunnet fra scratch. Den følger:

- **Mozilla OpenSSH guidelines, Modern profile** for SSH crypto-valg
- **CIS Distribution Independent Linux Benchmark v2.0.0** for host-config (sysctl, sudoers, file permissions)
- **NSM-tiltakene selv** for norske spesifika

Hver baseline-fil refererer kilden i sin egen kommentarer. Det betyr en hiring manager kan validere at vi ikke har funnet på vilkårlige verdier.

## 2.3.2 — Implementer baseline konsekvent

NSM ber om at baseline anvendes på alle relevante systemer, ikke bare den ene man husker å konfigurere.

### Hvordan vi gjør det

Implementasjonen er scriptet og idempotent. `vps-bootstrap/scripts/00-bootstrap.sh` orchestrerer hele oppsettet:

```bash
sudo ./scripts/00-bootstrap.sh --user sasha --mesh tailscale --ssh-key ~/.ssh/keys/host_ed25519.pub
```

Idempotens betyr at scriptet kan kjøres flere ganger uten å bryte noe. På tredje kjøring oppdager det at SSH-konfigen allerede er på plass og hopper over, mens en feil i steg 6 (Docker) kan fixes og scriptet kan kjøres igjen for å fullføre.

For en hiring manager: det signaliserer modenhet. Snickrede engangs-skript er amatør. Scripts som kan trygt re-kjøres er det som faktisk brukes i drift.

### Hvor "konsekvent" stopper

Ærlig: idempotente scripts er konsekvent for det jeg vet å automatisere. Men det er saker hvor manuelle steg gjenstår:

- Tailscale `sudo tailscale up --ssh` krever interaktiv auth (eller pre-shared key)
- WireGuard server keys må genereres på serveren og public keys distribueres til klienter

Disse er dokumentert i `setup.md` med eksplisitt "manual step required"-marker, ikke skjult som et kjent problem.

## 2.3.3 — Begrens og overvåk endringer

NSM ber om at endringer i konfig går gjennom kontrollert prosess.

### Hvordan vi gjør det

**Tre lag av endringskontroll:**

**Lag 1: git-historikk.**
All konfigurasjon er i `cybersecurity-labs`-repoet. Hver endring har en commit med begrunnelse. Konvensjonen i `.agent/config.yaml` krever at commits inkluderer `Refs:`-footer med kilder og `Maps-to:`-footer med rammeverk-referanser:

```
lab(networking): tighten SSH cipher list

Removed aes256-cbc and aes128-cbc from Ciphers list. CBC modes have
historically been associated with padding-oracle attacks. AEAD ciphers
(GCM, ChaCha20-Poly1305) provide both confidentiality and integrity
in one primitive.

Refs: https://infosec.mozilla.org/guidelines/openssh
Maps-to: NSM 2.3.1, NIST SP 800-53 SC-13, ISO 27002:2022 8.24
```

**Lag 2: Pre-commit kvalitetssjekker.**
`.github/workflows/secret-scan.yml` kjører `gitleaks` på hver PR for å fange utilsiktet credential-eksponering. `lint-markdown.yml` håndhever konsistent formatering. `verify-sshd-config.sh` kan kjøres lokalt før commit for å validere syntaks.

**Lag 3: Auditd på kritiske konfig-filer.**
Fra `vps-bootstrap/scripts/00-bootstrap.sh`:

```bash
cat > /etc/audit/rules.d/vps-bootstrap.rules <<'EOF'
-w /etc/ssh/sshd_config -p wa -k sshd_config_change
-w /etc/ssh/sshd_config.d/ -p wa -k sshd_config_change
-w /etc/sudoers -p wa -k sudo_change
-w /etc/sudoers.d/ -p wa -k sudo_change
-w /home -p wa -k authkeys_change
EOF
```

Det betyr at hvis noen (inkludert meg selv) endrer disse filene utenom git-prosess, lander det i auditd-loggen og kan flagges av en sigma-regel (se `nsm-grunnprinsipper/3-2-sikkerhetsovervakning/sigma-rules/sshd-config-tampering.yml`).

### Hva som mangler for nivå 4

Ærlig vurdering: jeg har ikke en formell change advisory board, ingen pull-request requirements som krever co-author approval på sikkerhetskritiske filer, og ingen automatisk gating som blokkerer merge hvis tester feiler. Dette er virksomhets-skala arbeid.

Hjemmelab-modenhet på 2.3.3: 3 (Definert).

## 2.3.4 — Detekter og responder på avvik fra baseline

NSM ber om at drift fra baseline kan oppdages og responderes på.

### Hvordan vi gjør det

**Pre-runtime detection:** `scripts/verify-sshd-config.sh` kjøres før reload av sshd og verifiserer at kritiske direktiver fortsatt er satt som forventet:

```bash
declare -A REQUIRED=(
    [PasswordAuthentication]=no
    [PermitRootLogin]=no
    [PermitEmptyPasswords]=no
    # ...
)
```

Hvis noen har endret en av disse, fanges det opp før reload og scriptet aborterer.

**Runtime detection:** Auditd ser endringer i konfig-filer (se 2.3.3). En sigma-regel under `cybersec/sigma-rules/` (cross-reference til `3-2-sikkerhetsovervakning`-laben) kan plukke opp og forwarde til SIEM.

**Periodic detection:** Månedlig kjøring av `99-verify.sh` med output diff'et mot forrige måneds output. Avvik er da synlig som diff-linjer.

### Hva som mangler

Aktiv reconciliation — altså "hvis avvik oppdaget, automatisk reverter til baseline" — er ikke implementert. Det er bevisst: i hjemmelab er aktiv reconciliation farligere enn nyttig (kan låse deg ute hvis baseline har bug). I virksomhet med Ansible / Salt kjører dette som scheduled konvergens-runs.

Hjemmelab-modenhet på 2.3.4: 2-3 (mellom Reaktivt og Definert).

## 2.3.5 — Verifiser konfigurasjon periodisk

NSM ber om periodisk verifikasjon av at baseline faktisk er anvendt og fortsatt gir ønsket sikkerhet.

### Hvordan vi gjør det

**Tre verktøy, tre perspektiver:**

**Internt perspektiv (sshd selv):**
```bash
sshd -T | grep -E "passwordauthentication|permitrootlogin|loglevel"
```

Viser konfigurasjonen som sshd faktisk har lastet, etter alle Match-blocks og includes. Det er sannheten — ikke det som står i én konfig-fil.

**Lokalt host-perspektiv (Lynis):**
```bash
sudo lynis audit system --tests-from-category authentication
```

Lynis kjører en bred sjekkliste av host-konfig og rapporterer hardening-index. SSH-seksjonen er en av flere; vi trekker ut akkurat den delen for `2-3-sikker-konfigurasjon` målet.

**Eksternt perspektiv (ssh-audit):**
```bash
docker run --rm positiveuser/ssh-audit <hostname>
```

Kobler til SSH-tjenesten og rapporterer hva en faktisk klient ville sett. Det er det perspektivet en angriper har, og det er den perspektivet som tester `ListenAddress` faktisk er korrekt og crypto-listen faktisk håndheves på wire-nivå.

### Eksempel-verifikasjon: før og etter

| Metrikk | Før (Ubuntu 24.04 default) | Etter ssh-hardening |
|---|---|---|
| ssh-audit overall grade | warning (B) | A+ |
| Tillatte KEX algoritmer | 11 (inkl. SHA-1 baserte) | 3 (alle Curve25519/PQ) |
| Tillatte ciphers | 6 (inkl. CBC) | 3 (alle AEAD) |
| Tillatte MACs | 10 (inkl. SHA-1) | 4 (alle ETM SHA-2) |
| Lynis hardening index (SSH) | 65 | 95 |

Tallene er reelle, fra `ssh-hardening/tests/`. Det er det som gjør verifikasjonen faktisk meningsfull — ikke "vi sjekket"-claim, men målbar forskjell mellom utgangspunkt og resultat.

## Hva en hiring manager bør ta med

Tre punkter:

1. **Sikker konfigurasjon er ikke en aktivitet, det er en livssyklus.** Definer baseline, implementer konsekvent, verifiser, oppdater når trusselbildet endrer seg. NSM 2.3 ber om hele livssyklusen, ikke bare "konfig-fil eksisterer".

2. **Konfig som kode er ikke valgfritt for moderne praksis.** Versjonskontrollert, kommentert, reproduserbar. Hvis du ikke kan svare "hva endret seg på denne hosten 2026-04-15 og hvorfor?", har du tapt 2.3.3 før du begynner.

3. **Verifikasjon må gi tall.** "Vi kjørte hardening" uten før/etter-data er en wishful claim. ssh-audit grade B → A+, Lynis 65 → 95, det er det som teller.

## Sources

- NSM Grunnprinsipper v2.1, prinsipp 2.3
- ssh-hardening lab i denne repoet
- vps-bootstrap lab i denne repoet
- Mozilla OpenSSH Guidelines (Modern profile)
- CIS Distribution Independent Linux Benchmark v2.0.0
