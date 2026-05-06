# NSM Grunnprinsipper-mapping for ssh-hardening

Hvilke NSM-tiltak (per [Grunnprinsipper for IKT-sikkerhet v2.1](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/), mai 2024) som denne lab-en demonstrerer, og hvor i lab-en bevisene finnes.

For full kontekst og cross-walks mot NIST/ISO/MITRE, se hovedmappingen i
[`compliance/nsm-grunnprinsipper/`](../../../compliance/nsm-grunnprinsipper/).

## Primære tiltak (lab-en er bygget rundt disse)

### 2.3.3 - Deaktiver unødvendig funksjonalitet

NSM ber om at innebygd funksjonalitet som ikke trengs deaktiveres - eldre protokoller, ubrukte tjenester, unødvendige sub-features.

**Hvor i lab-en:**
- [`server-config/sshd_config.d/10-crypto.conf`](server-config/sshd_config.d/10-crypto.conf) - eldre KEX, ciphers, MACs eksplisitt fjernet (SHA-1, CBC modes, NIST curves) med dokumentert rasjonale per linje
- [`server-config/sshd_config.d/30-limits.conf`](server-config/sshd_config.d/30-limits.conf) - X11Forwarding off, AgentForwarding off, GatewayPorts off, AllowTcpForwarding no

**Bevis:** ssh-audit grade B → A+. Tallene er reproduserbare via tests/.

### 2.3.4 - Etabler og vedlikehold standard sikkerhetskonfigurasjoner

NSM ber om én standard per type enhet, sentralisert drift, kun autorisert driftspersonale kan endre.

**Hvor i lab-en:**
- [`server-config/sshd_config.d/`](server-config/sshd_config.d/) - modular config splittet per ansvar (crypto, auth, limits, audit). Hver fil har dokumentert rasjonale.
- [`server-config/sshd_config`](server-config/sshd_config) - hoved-config som inkluderer modulene
- Hele konfigen er ment for git-versjonskontroll med commit-meldinger som dokumenterer endringer

### 2.3.5 - Verifiser at aktivert sikkerhetskonfigurasjon er i henhold til godkjent baseline

NSM ber om regelmessig sammenligning av aktiv konfig mot godkjent, varsling ved avvik, automatisering der mulig.

**Hvor i lab-en:**
- [`scripts/verify-sshd-config.sh`](scripts/verify-sshd-config.sh) - aborterer reload hvis kritiske direktiver er endret
- [`tests/README.md`](tests/README.md) - dokumenterer hvordan ssh-audit, Lynis, og `sshd -T` brukes for tre uavhengige perspektiver på baseline-status

### 2.3.6 - Utfør all konfigurasjon, installasjon og drift på en trygg måte

NSM ber om drift over tiltrodde kanaler, dedikerte drifts-klienter, redusert interaktiv pålogging.

**Hvor i lab-en:**
- [`client-config/ssh_config`](client-config/ssh_config) - per-host nøkler (`IdentityFile ~/.ssh/keys/<env>_ed25519_sk`), `IdentitiesOnly yes`, ingen agent-forwarding
- [`client-config/known_hosts.example`](client-config/known_hosts.example) - host key pinning per environment
- Hardware-backed nøkler (FIDO2 / Secure Enclave) støttet via `sk-ssh-ed25519`

### 2.3.7 - Endre alle standardpassord

NSM ber om at default-passord byttes før produksjonssetting, foretrekk sertifikatbasert autentisering.

**Hvor i lab-en:**
- [`server-config/sshd_config.d/20-auth.conf`](server-config/sshd_config.d/20-auth.conf) - `PasswordAuthentication no` fra start, pubkey-only
- [`scripts/audit-authorized-keys.sh`](scripts/audit-authorized-keys.sh) - kontrollerer at ingen swakke nøkler ligger i authorized_keys

### 2.6 - Ha kontroll på identiteter og tilganger (hele prinsippet)

NSM 2.6 har 7 underliggende tiltak. SSH-laben demonstrerer:
- **2.6.1 retningslinjer for tilgangskontroll** - `AllowGroups`, `AllowUsers` regler dokumentert
- **2.6.4 minimer rettigheter til sluttbrukere** - SSH session begrensninger, ingen interactive root
- **2.6.6 styr tilganger til enheter** - per-host nøkler, host key pinning
- **2.6.7 multi-faktor autentisering** - FIDO2 hardware-key støtte (`sk-ssh-ed25519`)

**Hvor i lab-en:**
- [`server-config/sshd_config.d/20-auth.conf`](server-config/sshd_config.d/20-auth.conf)
- [`server-config/pam.d-sshd`](server-config/pam.d-sshd) - PAM stack for auth-policy

## Sekundære tiltak (lab-en bidrar til disse, men de er ikke hovedfokus)

| Tiltak | Hvordan denne lab-en bidrar |
|---|---|
| 2.3.1 sentralt regime for sikkerhetsoppdatering | OpenSSH versjon-tracking dokumentert i [`SOURCES.md`](SOURCES.md) |
| 2.3.9 sikker tid | LogLevel VERBOSE i [`40-audit.conf`](server-config/sshd_config.d/40-audit.conf) krever korrekt tid for å gi mening i logger |
| 2.4.2 krypter alle forbindelser | SSH er kryptert per definisjon; lab-en sikrer at krypteringen er sterk (AEAD ciphers, post-quantum hybrid KEX) |
| 3.2.4 hvilke data å samle | LogLevel VERBOSE genererer key fingerprints som er essensielle for detection (se [`40-audit.conf`](server-config/sshd_config.d/40-audit.conf)) |

## Hva NSM-tiltak denne lab-en IKKE dekker

For honest dokumentasjon - dette er bevisste scope-grenser:

- **2.3.1 patch-management** - SSH-laben gir versjons-info men automatisk patching håndteres av `vps-bootstrap` (unattended-upgrades)
- **2.4 nettverkstiltak** - SSH-laben gjør ikke firewall-jobb. Det er `vps-bootstrap` sin oppgave (UFW)
- **3.2 sikkerhetsovervåkning** - SSH-laben *genererer* riktig telemetri, men ingestion/analyse skjer i [`compliance/nsm-grunnprinsipper/3-2-sikkerhetsovervakning/`](../../../compliance/nsm-grunnprinsipper/3-2-sikkerhetsovervakning/)

## Cross-references til relaterte arbeider

- **Full NSM v2.1 mapping:** [`compliance/nsm-grunnprinsipper/`](../../../compliance/nsm-grunnprinsipper/)
- **Komplementær lab (host og nettverk):** [`networking/zero-trust-designs/vps-bootstrap/`](../vps-bootstrap/)
- **Detection som bruker SSH-telemetri:** [`compliance/nsm-grunnprinsipper/3-2-sikkerhetsovervakning/sigma-rules/ssh-brute-force.yml`](../../../compliance/nsm-grunnprinsipper/3-2-sikkerhetsovervakning/sigma-rules/ssh-brute-force.yml)
