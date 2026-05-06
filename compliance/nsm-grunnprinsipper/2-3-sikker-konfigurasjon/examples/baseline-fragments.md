# Baseline export — eksempel på dokumentert sikker konfigurasjon

Dette er et utdrag av baseline-konfigurasjonen som ssh-hardening og vps-bootstrap implementerer. Brukes som referanse-eksempel for hvordan en baseline ser ut når den er fullt dokumentert.

## SSH-tjeneste-baseline (key fragments)

```
# /etc/ssh/sshd_config.d/10-crypto.conf
# Source: ssh-hardening/server-config/sshd_config.d/10-crypto.conf
# Justification: Mozilla OpenSSH Modern profile, NSM 2.3, NSM 2.7

# Host keys — Ed25519 only. RSA host keys disabled even at 4096 bits.
HostKey /etc/ssh/ssh_host_ed25519_key

# Key Exchange — post-quantum hybrid first, then Curve25519
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org

# Ciphers — AEAD only
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com

# MACs — ETM (Encrypt-Then-MAC) only
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com

# Public key types accepted from clients
PubkeyAcceptedAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com
```

```
# /etc/ssh/sshd_config.d/20-auth.conf
# Source: ssh-hardening/server-config/sshd_config.d/20-auth.conf
# Justification: NSM 2.6, defense against A2/A4 actors

PasswordAuthentication no
PermitRootLogin no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no

PubkeyAuthentication yes

# Restrict to operators group only
AllowGroups ops

# Require fresh authentication, even if multiple methods configured
AuthenticationMethods publickey

# Limit attack window
LoginGraceTime 30s
MaxAuthTries 3
MaxSessions 4
```

```
# /etc/ssh/sshd_config.d/40-audit.conf
# Source: ssh-hardening/server-config/sshd_config.d/40-audit.conf
# Justification: NSM 3.2 — required telemetry for detection

LogLevel VERBOSE   # logs key fingerprints used for authentication
SyslogFacility AUTHPRIV
```

## Docker daemon baseline

```json
// /etc/docker/daemon.json
// Source: vps-bootstrap/docker/daemon.json
// Justification: NSM 2.3, container hardening, defense against B5

{
  "userns-remap": "default",
  "no-new-privileges": true,
  "iptables": false,
  "log-driver": "journald",
  "log-opts": {
    "tag": "{{.Name}}/{{.ID}}"
  },
  "live-restore": true,
  "default-runtime": "runc",
  "default-shm-size": "64M"
}
```

## UFW baseline

```bash
# vps-bootstrap/ufw/before.rules and bootstrap-applied policy
# Justification: NSM 2.4

ufw default deny incoming
ufw default allow outgoing
ufw default deny forward
ufw default deny routed

# Allow only mesh-interface ingress
ufw allow in on tailscale0
# OR for WireGuard:
# ufw allow 51820/udp comment 'WireGuard listener'
# ufw allow in on wg0

ufw enable
```

## fail2ban baseline

```ini
# /etc/fail2ban/jail.local
# Source: vps-bootstrap/fail2ban/jail.local
# Note: fail2ban is defense-in-depth. With password auth disabled, its primary
# value is reducing log noise from scanners, not blocking compromise.

[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
banaction = ufw

[sshd]
enabled = true
mode    = aggressive    # catches more pre-auth scanner patterns

[recidive]
enabled  = true
bantime  = 1w
findtime = 1d
maxretry = 5
```

## auditd baseline (subset)

```
# /etc/audit/rules.d/vps-bootstrap.rules
# Source: vps-bootstrap/scripts/00-bootstrap.sh
# Justification: NSM 3.2.1 — telemetry sources for detection

# SSH config tampering
-w /etc/ssh/sshd_config -p wa -k sshd_config_change
-w /etc/ssh/sshd_config.d/ -p wa -k sshd_config_change
-w /etc/ssh/ssh_host_ed25519_key -p wa -k sshd_hostkey_change

# sudo policy tampering
-w /etc/sudoers -p wa -k sudo_change
-w /etc/sudoers.d/ -p wa -k sudo_change

# authorized_keys tampering (per-user catch-all)
-w /home -p wa -k authkeys_change
-w /root/.ssh -p wa -k root_authkeys_change

# Docker socket access (container escape detection)
-w /var/run/docker.sock -p rwxa -k docker_socket

# Make rules immutable until reboot (prevents `auditctl -D` mid-attack)
-e 2
```

## Hva eksempelet demonstrerer

For en hiring manager eller revisor som leser dette:

1. **Hver linje har et formål.** Det er ikke kopiert fra en blogg. Hver direktiv har en `Justification:`-kommentar som peker til hvorfor.

2. **Kilder er navngitt.** Mozilla, NSM, CIS, threat-actors. En revisor kan validere at vi følger anerkjente standarder, ikke folkemening.

3. **Trade-offs er eksplisitte.** Eksempel: fail2ban-noten erkjenner at fail2ban er defense-in-depth, ikke primært forsvar. Det signaliserer modenhet — en junior ville claim fail2ban er "secure". En modne security-engineer vet at det er marginalt verdi når password auth er av.

4. **Rules er immutable etter loading.** `-e 2` på auditd er det som hindrer en angriper med root å bare disable auditd uten reboot. Det er en detalj som krever at man har lest auditd-dokumentasjonen, ikke bare kopiert et eksempel.

## Sources

- ssh-hardening lab i denne repoet
- vps-bootstrap lab i denne repoet
- Mozilla OpenSSH guidelines
- NSM Grunnprinsipper v2.1
