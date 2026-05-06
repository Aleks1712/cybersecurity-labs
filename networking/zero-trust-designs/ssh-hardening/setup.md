# Reproducible Setup Guide

Step-by-step for å replikere denne lab-en fra scratch.

## Prerequisites

**Klient (macOS, jeg har testet på 14.5):**
- OpenSSH 9.0+ (kommer med macOS Sonoma+)
- (Valgfri) YubiKey 5 series eller nyere for FIDO2-nøkler
- (Valgfri) `secretive` for Secure Enclave-baserte nøkler

```bash
# Verifiser klient-versjon
ssh -V
# Skal være OpenSSH_9.x eller nyere
```

**Server (Ubuntu 24.04, Debian 12, eller Proxmox VE 8):**
- OpenSSH server 9.0+
- Root eller sudo-tilgang
- Konsoll-tilgang som backup (helt nødvendig under hardening)

```bash
# Verifiser server-versjon
sshd -V
ssh -V
```

For AWS EC2 / Azure VMs / GCP Compute brukes samme prosedyre på instansen, men med ekstra hensyn til at man ikke har fysisk konsoll. Bruk vendorens "serial console" eller "boot diagnostics" som fallback.

## Klient-side oppsett

### 1. Lag mappestruktur

```bash
mkdir -p ~/.ssh/keys ~/.ssh/known_hosts.d ~/.ssh/sockets
chmod 700 ~/.ssh ~/.ssh/keys ~/.ssh/known_hosts.d ~/.ssh/sockets
```

### 2. Generer per-host nøkler

For homelab bastion (FIDO2 hvis du har YubiKey, ellers vanlig ed25519):

```bash
# Med YubiKey
ssh-keygen -t ed25519-sk -O resident -O verify-required \
    -C "sasha-homelab-bastion-$(date +%Y%m%d)" \
    -f ~/.ssh/keys/homelab_bastion_ed25519_sk

# Uten YubiKey
ssh-keygen -t ed25519 \
    -C "sasha-homelab-bastion-$(date +%Y%m%d)" \
    -f ~/.ssh/keys/homelab_bastion_ed25519_sk
```

Gjenta for `homelab_internal_ed25519_sk`, `aws_lab_ed25519_sk`, `azure_lab_ed25519_sk`, `github_portfolio_ed25519`.

### 3. Installer ssh_config

```bash
cp client-config/ssh_config ~/.ssh/config
chmod 600 ~/.ssh/config
```

Tilpass `HostName`, `User`, og IP-prefiks per ditt miljø før første bruk.

### 4. Pinn host keys

For hver server, første gang:

```bash
# Hent host key
ssh-keyscan -t ed25519 <hostname> 2>/dev/null

# Verifiser fingerprint OUT OF BAND (vendor console, fysisk konsoll, vendor docs)
# Når verifisert:
ssh-keyscan -t ed25519 <hostname> >> ~/.ssh/known_hosts.d/<env>
```

For GitHub spesifikt, fingerprint matche referansen i `client-config/README.md`.

### 5. Test

```bash
# Tørrtest konfigen — skal vise effektiv config uten å koble til
ssh -G homelab-bastion | head -30

# Faktisk connect
ssh homelab-bastion
```

## Server-side oppsett

### 1. Backup eksisterende konfig

```bash
sudo cp -r /etc/ssh /etc/ssh.bak.$(date +%F)
```

### 2. Installer hardened sshd_config

```bash
sudo cp server-config/sshd_config /etc/ssh/sshd_config
sudo chmod 600 /etc/ssh/sshd_config

sudo mkdir -p /etc/ssh/sshd_config.d
sudo cp server-config/sshd_config.d/*.conf /etc/ssh/sshd_config.d/
sudo chmod 600 /etc/ssh/sshd_config.d/*.conf
```

### 3. Lag ssh-users gruppe

```bash
sudo groupadd -f ssh-users
sudo usermod -aG ssh-users <din-bruker>
```

### 4. Legg din public key på serveren

Fra klienten:

```bash
ssh-copy-id -i ~/.ssh/keys/homelab_bastion_ed25519_sk.pub <bruker>@<host>
```

Dette krever at password auth eller eksisterende key auth virker. Kjør dette FØR du installerer hardened config, eller via fysisk konsoll.

På serveren, sett tighte permissions:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### 5. Generer hardened banner

```bash
sudo tee /etc/ssh/banner > /dev/null <<'EOF'
*****************************************************************
This is a private system. Authorized access only.
All connections are logged. Disconnect immediately if you are not
an authorized user.
*****************************************************************
EOF
```

### 6. Validate konfig FØR reload

```bash
# Lokal verifisering
sudo bash scripts/verify-sshd-config.sh

# Hvis OK:
sudo sshd -t

# Effektiv config-dump for din bruker
sudo sshd -T -C user=<din-bruker>,host=$(hostname -f),addr=$(hostname -I | awk '{print $1}')
```

### 7. Reload (IKKE restart) — med en annen sesjon åpen

I terminal 1: hold eksisterende SSH-sesjon åpen.

I terminal 2: åpne en ny sesjon. Verifiser at den fungerer.

I terminal 3 (eller terminal 1): `sudo systemctl reload ssh`.

I terminal 4: åpne en NY sesjon. Hvis dette fungerer, er du trygg.

Hvis terminal 4 feiler, har du fortsatt terminal 1 og 2 til å fikse fra. Fiks raskt — eksisterende sesjoner overlever bare så lenge ingen kicker dem.

### 8. Aktiver auditd-regler

```bash
sudo tee /etc/audit/rules.d/sshd.rules > /dev/null <<'EOF'
-w /etc/ssh/sshd_config -p wa -k sshd_config_change
-w /etc/ssh/sshd_config.d/ -p wa -k sshd_config_change
-w /etc/ssh/ssh_host_ed25519_key -p wa -k sshd_hostkey_change
-w /root/.ssh/authorized_keys -p wa -k root_authkeys_change
-w /home -p wa -k home_authkeys_change
EOF

sudo augenrules --load
sudo systemctl restart auditd
```

### 9. Verifiser eksternt

Fra klienten:

```bash
# ssh-audit
docker run --rm -it positiveuser/ssh-audit <hostname>

# Skal score A+. Spar output i tests/ssh-audit-hardened.txt for å vise før/etter.
```

## Tilfelle: Cloud VM-spesifikt

### AWS EC2

- I AMI-en: SSH er som regel allerede konfigurert til pubkey-only fra cloud-init. Verifiser at default `~/.ssh/authorized_keys` for `ec2-user` (Amazon Linux) eller `ubuntu` (Ubuntu AMI) inneholder kun nøkkelen du la inn ved instance launch.
- Sikkerhetsgrupper: kun port 22 fra ditt VPN-subnet eller bastion.
- Etter hardening: hvis du fjerner `cloud-init`-baserte nøkler (i `/etc/ssh/sshd_config.d/50-cloud-init.conf`), husk at reboot kan reintroduce dem. Sjekk `/etc/cloud/cloud.cfg`.

### Azure VM

- Azure injects keys via WALinuxAgent. Default `azureuser`-konto har authorized_keys fra ARM template.
- NSG: tilsvarende AWS Security Groups, kun fra bekjente kilder.
- Just-In-Time access (JIT) gjennom Defender for Cloud kan brukes som ekstra lag — det åpner port 22 i NSG-en kun for et tidsvindu og en spesifikk IP.

### GCP Compute

- OS Login (anbefalt): nøkler administreres via IAM, ikke `~/.ssh/authorized_keys`. Hvis aktivert, ignoreres `authorized_keys` på instansen.
- Hvis OS Login ikke brukes, oppfører det seg som AWS/Azure.

## Vedlikehold

| Oppgave | Frekvens | Hvordan |
|---|---|---|
| Re-run `audit-authorized-keys.sh` | Ukentlig | Cron-jobb, ship output til log-aggregator |
| Roter automation-nøkler (CI, backup) | 90 dager | Scriptet, `expiry-time` i authorized_keys |
| Roter personlige nøkler | 12 måneder | Manuelt |
| Roter host keys | Ved kompromiss eller stor oppgradering | `rotate-host-keys.sh` |
| Re-run ssh-audit / Lynis | Månedlig | CI-jobb mot referansebaseline |
| Patch OpenSSH | Innen 7 dager etter CVE | `unattended-upgrades` på alle hosts |
| Threat model review | Årlig eller ved miljøendring | Edit `THREAT-MODEL.md` |
