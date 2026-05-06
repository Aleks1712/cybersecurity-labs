# Manual Setup Guide

Hvis du ikke vil kjøre `00-bootstrap.sh` blindt (smart), er dette det samme i steg-for-steg form. Bra for å forstå hva som skjer, og for å feilsøke når noe går galt i scripted-versjonen.

## Forutsetninger

- Fresh Linux VPS (Ubuntu 24.04, Debian 12, eller tilsvarende). Andre distro fungerer med små justeringer.
- Root-tilgang via leverandørens default mekanisme (root-passord eller pre-installert SSH-nøkkel)
- Konsoll-tilgang som backup (leverandørens web-konsoll)
- Din SSH public key tilgjengelig

## Steg 1: First contact

Logg inn som root med leverandørens default-mekanisme.

```bash
ssh root@<vps-public-ip>
```

**Det første du gjør, før noe annet:**

```bash
# Update package lists
apt update

# Apply ALL pending security updates (including kernel)
DEBIAN_FRONTEND=noninteractive apt upgrade -y

# Reboot if kernel was updated
[[ -f /var/run/reboot-required ]] && reboot
```

Hvorfor først? Du sitter på en boks med kjente sårbarheter til disse kommandoene fullføres. Alt annet kan vente.

## Steg 2: Bruker, sudo, SSH-nøkkel

Aldri bruk root for daglig drift. Lag en bruker, gi hen sudo, deaktiver root-login.

```bash
# Erstatt 'sasha' med ditt navn
adduser --disabled-password --gecos '' sasha
usermod -aG sudo sasha
groupadd -f ssh-users
usermod -aG ssh-users sasha

# Installer SSH-nøkkelen din for den brukeren
mkdir -p /home/sasha/.ssh
echo "ssh-ed25519 AAAA... din public key her" > /home/sasha/.ssh/authorized_keys
chmod 700 /home/sasha/.ssh
chmod 600 /home/sasha/.ssh/authorized_keys
chown -R sasha:sasha /home/sasha/.ssh

# Test innlogging FRA EN ANNEN TERMINAL før du går videre
# ssh sasha@<vps-public-ip>
# Hvis den fungerer, fortsett. Hvis ikke, fix nå mens root fortsatt er åpent.
```

NOPASSWD sudo (valgfritt — gir litt mer komfort men litt mindre sikkerhet):

```bash
echo "sasha ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-sasha
chmod 440 /etc/sudoers.d/90-sasha
visudo -cf /etc/sudoers.d/90-sasha   # syntax check
```

## Steg 3: SSH hardening

**Nå** kjører vi SSH-hardening. Detaljer i `networking/zero-trust-designs/ssh-hardening/`.

Kort versjon, hvis du ikke har den lab-en tilgjengelig:

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo tee /etc/ssh/sshd_config.d/99-bootstrap.conf > /dev/null <<'EOF'
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
AllowGroups ssh-users
MaxAuthTries 3
LoginGraceTime 30s
LogLevel VERBOSE
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
UseDNS no
EOF
sudo chmod 600 /etc/ssh/sshd_config.d/99-bootstrap.conf

# Validate FØR reload
sudo sshd -t

# Reload (med en ny sesjon åpen i en annen terminal som backup)
sudo systemctl reload ssh
```

Test ny sesjon i tredje terminal. Hvis fungerer, alle gode.

## Steg 4: Firewall

```bash
# UFW kommer pre-installert på Ubuntu, må enables på Debian
sudo apt install -y ufw

# Reset til kjent baseline
sudo ufw --force reset

# Default-policy
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default deny forward

# IKKE åpne 22 — vi gir SSH gjennom mesh-en når den kommer.
# Hvis du IKKE har konsoll-tilgang som backup, åpne SSH midlertidig:
# sudo ufw allow 22/tcp comment 'temporary, remove after mesh up'

# Aktiver
sudo ufw --force enable
sudo ufw status verbose
```

## Steg 5: VPN mesh

Velg én. **Tailscale anbefales for de fleste use cases.**

### Tailscale

```bash
# Installer
curl -fsSL https://tailscale.com/install.sh | sh

# Auth (åpner URL i terminal som du logger inn på)
sudo tailscale up --ssh --advertise-tags=tag:vps

# Verifiser
tailscale ip -4
tailscale status
```

Tilpass UFW for å tillate trafikk fra mesh:

```bash
sudo ufw allow in on tailscale0
sudo ufw status verbose
```

### WireGuard (alternativ)

```bash
sudo apt install -y wireguard wireguard-tools

# Generer server keys
cd /etc/wireguard
sudo wg genkey | sudo tee server_private.key | sudo wg pubkey | sudo tee server_public.key

# Lag wg0.conf — se wireguard/server.conf.example for templaten
sudo nano /etc/wireguard/wg0.conf

# Aktiver
sudo systemctl enable --now wg-quick@wg0

# Tillat trafikk inn på mesh-interface
sudo ufw allow 51820/udp
sudo ufw allow in on wg0
```

## Steg 6: Verifiser at SSH er mesh-only

På klienten din:

```bash
# Skal fungere (mesh)
ssh sasha@<tailscale-ip>

# Skal IKKE fungere (offentlig)
ssh sasha@<public-ip>
# Forventet: Connection timed out (UFW dropper)
```

Hvis (2) faktisk fungerer, betyr det at SSH fortsatt lytter på offentlig IP. Sjekk `ss -lntp | grep ssh` — bind-adressen skal være tailscale-IP eller mesh-subnet, ikke `0.0.0.0`.

For å fikse det, legg til i `/etc/ssh/sshd_config.d/00-listen.conf`:

```
ListenAddress 100.64.x.y    # din tailscale IP
# eller
ListenAddress 10.50.0.1     # din wireguard IP
```

Reload og test igjen.

## Steg 7: Fail2ban

```bash
sudo apt install -y fail2ban

# Kopier hardened jail.local fra denne lab-en
sudo cp fail2ban/jail.local /etc/fail2ban/jail.local

sudo systemctl enable --now fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

## Steg 8: Automatic security updates

```bash
sudo apt install -y unattended-upgrades apt-listchanges

sudo cp unattended-upgrades/50unattended-upgrades /etc/apt/apt.conf.d/
sudo cp unattended-upgrades/20auto-upgrades /etc/apt/apt.conf.d/

sudo systemctl enable --now unattended-upgrades.service

# Tørrtest
sudo unattended-upgrade --dry-run --debug
```

## Steg 9: Docker

```bash
# Offisiell Docker-repo (ikke snap, ikke docker.io fra Ubuntu)
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Hardened daemon.json
sudo mkdir -p /etc/docker
sudo cp docker/daemon.json /etc/docker/daemon.json
sudo systemctl restart docker

# Legg deg selv til docker-gruppen (krever ny innlogging for å ta effekt)
sudo usermod -aG docker sasha
```

## Steg 10: Auditd-regler

```bash
sudo apt install -y auditd

sudo tee /etc/audit/rules.d/vps-bootstrap.rules > /dev/null <<'EOF'
-w /etc/ssh/sshd_config -p wa -k sshd_config_change
-w /etc/ssh/sshd_config.d/ -p wa -k sshd_config_change
-w /etc/sudoers -p wa -k sudo_change
-w /etc/sudoers.d/ -p wa -k sudo_change
-w /etc/passwd -p wa -k user_change
-w /etc/shadow -p wa -k user_change
-w /home -p wa -k authkeys_change
-w /var/run/docker.sock -p wa -k docker_socket
EOF

sudo augenrules --load
sudo systemctl restart auditd
```

## Steg 11: Endelig verifikasjon

```bash
sudo bash scripts/99-verify.sh
```

Skal vise alle grønne (PASS), eller maks gule (WARN) for ting du eksplisitt har valgt å ikke aktivere.

## Steg 12: App deploy

Først nå legger du applikasjoner på maskinen. Se `app-deploy/README.md`.

## Total tid

- Erfaren operatør, scripted: 5-10 minutter
- Erfaren operatør, manuelt: 30-45 minutter
- Første gang du gjør det, manuelt med å lese dokumentasjon: 2-3 timer
- Inkludert å feilsøke når noe ikke fungerer: legg til 1 time

## Hva du har etter dette

- En VPS uten offentlige porter (utover mesh)
- SSH kun nådbar via mesh, med pubkey-only og verbose audit logging
- Fail2ban som defense-in-depth
- Automatic security updates aktivert
- Docker installert med hardenede defaults
- Auditd-regler som logger tampering med kritiske filer
- Klar til å deploye apps via Docker Compose

## Hva du IKKE har enda

- Sentralt logging (ship til Loki/Sentinel/Splunk) — egen lab
- Backup-strategi — egen lab
- Monitoring/alerting — egen lab
- Disk encryption (LUKS) — krever oppsett ved første install, ikke retroaktivt på en kjørende VPS
- DDoS-mitigering — i praksis Cloudflare eller leverandørens egne verktøy

Disse blir egne labs i `cloud/` eller `cybersec/`-pillarene når jeg kommer dit i rotasjonen.
