# Verifisering — slik testes NSM 2.3-tiltakene

NSM 2.3.5 ber om periodisk verifikasjon. Dette dokumentet beskriver hvordan tiltakene faktisk testes, med konkrete kommandoer og forventede utfall.

## Verifikasjons-prinsipper

1. **Tre uavhengige perspektiver.** Internt (sshd selv), lokalt (host-tools), eksternt (over wire). Hvis alle tre er enig, er konfigen sannsynligvis riktig.
2. **Målbar utgangspunkt.** Hver test produserer et tall eller en grade som kan sammenlignes over tid.
3. **Reproduserbar.** Anyone kan kjøre samme test og få samme svar.

## Test 1 — sshd internal verification

```bash
# Hva sshd faktisk har lastet (etter alle Match-blocks og includes)
sudo sshd -T | grep -E "^(passwordauthentication|permitrootlogin|loglevel|kexalgorithms|ciphers|macs)"
```

**Forventet output:**
```
passwordauthentication no
permitrootlogin no
loglevel VERBOSE
kexalgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org
ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
macs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com
```

Hvis output avviker fra forventet, det betyr enten konfig-fil ble redigert utenfor git-prosess, eller at en Match-block overstyrer global config (og vi har en uventet sub-config aktivt).

## Test 2 — verify-sshd-config.sh (custom)

```bash
sudo /usr/local/bin/verify-sshd-config.sh
```

Skriptet (i `ssh-hardening/scripts/`) sjekker at kritiske direktiver er satt som forventet, og aborterer hvis ikke. Brukes som pre-flight-check før `systemctl reload sshd`.

**Forventet output ved suksess:**
```
[+] PasswordAuthentication=no ... OK
[+] PermitRootLogin=no ... OK
[+] PermitEmptyPasswords=no ... OK
[+] PubkeyAuthentication=yes ... OK
[+] LogLevel=VERBOSE ... OK
[+] All critical directives verified
```

## Test 3 — Lynis hardening assessment

```bash
sudo apt install lynis
sudo lynis audit system --quiet --no-colors
```

**Relevante seksjoner i output:**
- "SSH" → hardening index for SSH
- "Authentication" → PAM, login policies
- "File integrity" → AIDE / auditd configuration
- "Logging and auditing" → log retention, log rotation

**Forventet hardening index:**
- Pre-hardening (Ubuntu default): 65
- Post ssh-hardening + vps-bootstrap: 90+ overall, 95+ SSH-spesifikk

Hvis tallet faller, det indikerer at noe i baseline har glidd ut av sync.

## Test 4 — ssh-audit (eksternt)

```bash
# Fra en non-VPS host
docker run --rm positiveuser/ssh-audit <hostname-or-mesh-ip>
```

**Forventet utfall:** Grade A+ med ingen warnings.

Eksempel-output snippet:
```
(gen) banner: SSH-2.0-OpenSSH_9.6
(gen) software: OpenSSH 9.6
(gen) compatibility: OpenSSH 7.6+ (server)
(gen) compression: enabled (zlib@openssh.com)

(kex) sntrup761x25519-sha512@openssh.com -- [info] available since OpenSSH 8.5
                                          `- [info] hybrid key exchange (post-quantum + curve25519)
(kex) curve25519-sha256                   -- [info] available since OpenSSH 7.4
(kex) curve25519-sha256@libssh.org        -- [info] available since OpenSSH 6.5

(key) rsa-sha2-512                        -- [info] available since OpenSSH 7.2
(key) ssh-ed25519                         -- [info] available since OpenSSH 6.5

(enc) chacha20-poly1305@openssh.com       -- [info] available since OpenSSH 6.5

(mac) hmac-sha2-256-etm@openssh.com       -- [info] available since OpenSSH 6.2
(mac) hmac-sha2-512-etm@openssh.com       -- [info] available since OpenSSH 6.2

# algorithm recommendations (for OpenSSH 9.6)
(rec) ssh-rsa                             -- key algorithm to remove

# additional info
(nfo) For hardening guides on common OSes, please refer to <URL>

# overall score
(gen) banner: SSH-2.0-OpenSSH_9.6
                                                                Grade: A+
```

## Test 5 — vps-bootstrap 99-verify.sh

```bash
sudo /usr/local/bin/99-verify.sh
```

Scriptet (fra `vps-bootstrap/scripts/`) sjekker:

- UFW status og regelsett
- Tjenester som lytter på public-vs-mesh interfaces
- fail2ban status
- Docker daemon konfig
- auditd regler
- Unattended upgrades konfig

**Forventet output:**
```
[+] UFW: active, default deny incoming, allow outgoing
[+] No services listening on public IP (only mesh interface)
[+] fail2ban: active, jails: sshd, recidive
[+] Docker: userns-remap=default, no-new-privileges=true, iptables=false
[+] auditd: active, X rules loaded
[+] Unattended-Upgrades: enabled, auto-reboot after security updates
```

Hvis noen sjekk feiler, den linjen blir `[!]` med detalj om hva som er galt.

## Test 6 — Manuell wire-test

For å bekrefte at perimeter er korrekt implementert:

```bash
# Fra en non-mesh host (f.eks. mobilt internett, ikke ditt vanlige nettverk)
nmap -Pn -p 1-65535 <public-ip>
```

**Forventet utfall:**
- Tailscale-only: 0 åpne porter (NAT traversal, ingen public ingress)
- WireGuard-only: 1 åpen port (UDP 51820)
- IKKE forventet: SSH (port 22) åpen, eller noen TCP-port over 1024

Hvis SSH er åpen mot public IP, betyr det at UFW-policy ikke fungerer som tenkt eller at en service har bypasset firewall.

## Test 7 — Coverage-test for detection

For 3.2-laben (cross-reference):

```bash
# Generer en kjent benign signal
ssh fakeuser@<host>  # vil feile, men logges som "Failed password for invalid user fakeuser"
```

Sjekk at:
- `/var/log/auth.log` inneholder `Invalid user fakeuser from <ip>`
- Sigma-regelen `ssh-brute-force.yml` ville ha matchet (hvis flere forsøk innen 5m)
- KQL/SPL-query ville returnert eventet

Dette tester at hele detection-pipelinen fungerer end-to-end, ikke bare at reglene er syntaktisk korrekte.

## Periodisitet

Anbefaling for hjemmelab:

| Test | Frekvens |
|---|---|
| sshd -T | Etter hver konfig-endring |
| verify-sshd-config.sh | Pre-reload (hver gang) |
| Lynis | Månedlig |
| ssh-audit | Månedlig |
| 99-verify.sh | Etter hver bootstrap-kjøring |
| nmap fra ekstern | Kvartalsvis |
| Detection coverage-test | Kvartalsvis |

Resultatene logges i en enkel changelog (CHANGELOG.md eller dedikert tracking-fil) så jeg kan se trender over tid.

## Hva en hiring manager bør se

Denne filen demonstrerer at jeg ikke bare skriver konfig — jeg tester at konfigen faktisk virker, fra flere uavhengige perspektiver, med målbare utfall. Det er forskjellen mellom "claim hardening" og "demonstrert hardening".

## Sources

- ssh-audit dokumentasjon
- Lynis manual
- OpenSSH `sshd(8)` manpage, `-T` flag
