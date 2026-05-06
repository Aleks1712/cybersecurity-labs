# SSH Hardening — Client and Server, Homelab and Cloud

**Date:** 2026-05-05
**Pillar:** networking / zero-trust-designs
**Effort:** ~6 hours across setup, testing, and write-up
**Frameworks:**
- MITRE ATT&CK: T1021.004 (Remote Services: SSH), T1098.004 (Account Manipulation: SSH Authorized Keys), T1110 (Brute Force), T1556 (Modify Authentication Process)
- NIST SP 800-53: AC-17 (Remote Access), IA-2 (Identification and Authentication), SC-12 (Cryptographic Key Establishment), AU-12 (Audit Generation)
- NIST SP 800-207: zero-trust principles applied to administrative access
- ISO/IEC 27002:2022: 8.5 (Secure Authentication), 8.20 (Network Security), 8.21 (Security of Network Services)
- CIS Benchmarks: Distribution Independent Linux v2.0.0, section 5.2 (SSH Server Configuration)

## Hvorfor denne laben finnes

SSH er det første og siste laget av forsvar for de aller fleste servere i homelab og sky. Default-konfigen i moderne Ubuntu/Debian/RHEL er ikke katastrofal, men den er bygget for kompatibilitet, ikke for en threat model der angripere har scriptet brute-force, kompromitterte CI-credentials, og en aktiv interesse for å hoppe lateralt mellom skyer. Denne laben dokumenterer en konfigurasjon jeg faktisk kjører, hvorfor hver instilling er der, hva den forsvarer mot, og hva den ikke forsvarer mot.

Det er to feller folk faller i når de "harder" SSH:

1. **Cargo-kult.** Kopiere en gist fra 2017 med `Port 2222` og `DenyUsers root` og kalle det hardening. Det meste av det er enten utdatert eller security theater.
2. **Overengineering.** Slå på alt — TOTP, port-knocking, fail2ban, IP-allowlist, geoblocking — uten en threat model. Resultatet er at man låser seg selv ute fra produksjon en søndag kveld og lager en post-mortem i stedet for sushi.

Denne laben prøver å treffe midten: det du faktisk trenger for å forsvare mot realistiske trusler i 2026, og hvorfor.

## Hva som er i denne mappen

```
ssh-hardening/
├── README.md                    # Du er her
├── THREAT-MODEL.md              # Hva dette forsvarer mot og hva det ikke gjør
├── setup.md                     # Reproduserbar oppsett-guide
├── client-config/
│   ├── ssh_config               # ~/.ssh/config med per-host blocks
│   ├── known_hosts.example      # Pinning-eksempel med kommentarer
│   └── README.md                # Klient-side rasjonale
├── server-config/
│   ├── sshd_config              # Hardened sshd_config
│   ├── sshd_config.d/
│   │   ├── 10-crypto.conf       # KEX, ciphers, MACs, host key algos
│   │   ├── 20-auth.conf         # Authentication policy
│   │   ├── 30-limits.conf       # Rate limits og session limits
│   │   └── 40-audit.conf        # Logging
│   ├── authorized_keys.example  # Restricted keys med command=, from=
│   ├── pam.d-sshd               # PAM-konfig for FIDO2/TOTP
│   └── README.md                # Server-side rasjonale
├── tests/
│   ├── ssh-audit-baseline.txt   # Output fra ssh-audit før hardening
│   ├── ssh-audit-hardened.txt   # Output etter hardening
│   ├── lynis-ssh-section.txt    # Lynis SSH-relevant output
│   └── README.md                # Hvordan kjøre testene
└── scripts/
    ├── rotate-host-keys.sh      # Rotasjon av host keys
    ├── audit-authorized-keys.sh # Finn stale keys på tvers av brukere
    └── verify-sshd-config.sh    # Pre-flight check før reload sshd
```

## Hva som ikke er her, og hvorfor

- **Port-knocking.** Security theater. Hvis angriperen har nettverksvisibilitet til å scanne porten din, har hen visibilitet til å se knock-sekvensen.
- **`Port 2222`.** Reduserer logg-støy fra opportunistiske scannere, men det er hygiene, ikke security. Hvis det er det eneste du gjør, har du ikke gjort noe.
- **fail2ban som primærforsvar.** Inkludert som defense-in-depth, men hvis du baserer deg på fail2ban for å overleve brute-force, har du allerede tapt — du har password auth på.
- **GeoIP-blocking.** Bryter ofte legitim bruk (reise, VPN), og angripere bruker uansett kompromitterte hosts i ditt eget land.

## Resultater før/etter

| Metrikk | Før (Ubuntu 24.04 default) | Etter |
|---|---|---|
| `ssh-audit` overall grade | warning (B) | A+ |
| Tillatte KEX algoritmer | 11 (inkl. `diffie-hellman-group14-sha1`) | 3 (alle Curve25519/sntrup) |
| Tillatte ciphers | 6 (inkl. CBC-modes) | 3 (alle AEAD) |
| Tillatte MACs | 10 (inkl. SHA-1) | 4 (alle ETM, SHA-2) |
| Password auth | enabled | disabled |
| Root login | `prohibit-password` | `no` |
| Lynis hardening index (SSH section) | 65 | 95 |

Detaljer i `tests/`.

## Hva som ikke fungerte underveis

To ting jeg traff på som jeg vil flagge for fremtidig-meg:

1. `sntrup761x25519-sha512@openssh.com` (post-quantum KEX) krever OpenSSH 9.0+. Proxmox 8.x (Debian 12-basert) har 9.2 så det er greit, men en Ubuntu 20.04 host i miljøet hadde 8.9 og falt tilbake til `curve25519-sha256`. Ikke en feil i seg selv, men jeg trodde først konfig-en min ble ignorert.
2. På macOS klient slo `IdentitiesOnly yes` av Keychain-integrasjonen for ssh-agent på en uventet måte i én test. Løsningen var å bruke `IdentityAgent "$SSH_AUTH_SOCK"` eksplisitt i `~/.ssh/config` per host som trenger det.

## Takeaways

Den viktigste innsikten her er ikke en spesifikk konfig-linje, men at SSH-hardening uten en threat model er hygiene-arbeid forkledd som security. Threat model først (`THREAT-MODEL.md`), så konfig. Det andre er at moderne SSH (9.x) gir deg post-quantum KEX gratis hvis du bare ber om det — det er den enkleste forsvaret mot fremtidig "store now, decrypt later" jeg vet om for admin-trafikk.

## Sources

Alle eksterne kilder er listet i `SOURCES.md` per leaf-mappe og i commit-footers per repo-konvensjon. Hovedreferanser:

- OpenSSH manual (`ssh(1)`, `sshd(8)`, `ssh_config(5)`, `sshd_config(5)`) — versjon 9.6
- Mozilla OpenSSH guidelines (Modern profile)
- CIS Distribution Independent Linux Benchmark v2.0.0
- NIST SP 800-207 (Zero Trust Architecture)
- ssh-audit (jtesta/ssh-audit) project policies
- Stribika SSH guide (historical reference, dated but still useful for rationale)
