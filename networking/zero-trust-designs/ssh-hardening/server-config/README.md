# Server-side SSH configuration

## Designprinsipper

1. **Modulær konfig.** Hovedfilen `sshd_config` includer kun `sshd_config.d/*.conf`. Pakke-oppgraderinger overskriver ikke policy, hver fil dekker én concern, og diff-er er lett å lese i code review.

2. **Allowlist over denylist.** `AllowGroups ssh-users` betyr at *kun* medlemmer av den gruppen kan logge inn over SSH. Nye brukere som opprettes på systemet er som default ikke tillatt — det er sikrere enn å vedlikeholde en evig voksende `DenyUsers`-liste.

3. **Crypto removal, ikke deprioritization.** Hvis `aes256-cbc` står i listen din i det hele tatt, kan en MITM-angriper i teorien forhandle det fram. Listen i `10-crypto.conf` inneholder kun moderne AEAD-ciphers, ETM-MACs, og Curve25519/post-quantum KEX. Det er ingen fallback-utvei.

4. **Verbose logging er obligatorisk.** Standard `LogLevel INFO` logger ikke key fingerprints. Med `VERBOSE` kan SOC-en eller jeg selv svare "hvilken nøkkel logget inn på denne hosten 2026-04-22 kl 03:14?" — det er kritisk for incident response.

5. **Forwarding av som default.** Agent forwarding, X11 forwarding, og TCP forwarding er alle av. Det aktiveres per host i `Match`-blocks der det faktisk trengs (sjelden).

## Installasjonsrekkefølge

```bash
# 1. Backup eksisterende konfig
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%F)

# 2. Sørg for at sshd_config.d/ eksisterer og er inkludert
sudo mkdir -p /etc/ssh/sshd_config.d

# 3. Drop in nye filer
sudo cp 10-crypto.conf /etc/ssh/sshd_config.d/
sudo cp 20-auth.conf /etc/ssh/sshd_config.d/
sudo cp 30-limits.conf /etc/ssh/sshd_config.d/
sudo cp 40-audit.conf /etc/ssh/sshd_config.d/
sudo chmod 600 /etc/ssh/sshd_config.d/*.conf

# 4. Erstatt main sshd_config
sudo cp sshd_config /etc/ssh/sshd_config
sudo chmod 600 /etc/ssh/sshd_config

# 5. Lag ssh-users gruppe og legg til operatør
sudo groupadd -f ssh-users
sudo usermod -aG ssh-users sasha

# 6. Validate
sudo sshd -t
echo "Exit code: $?"

# 7. Test fra en NY ssh-sesjon FØR du discarder den eksisterende
#    Hvis dette feiler, har du fortsatt en åpen sesjon å fikse fra
sudo systemctl reload ssh
```

**Aldri** restart sshd uten en åpen, fungerende sesjon i bakhånd. Reload er trygt; restart kobler ned eksisterende sesjoner og hvis konfig-en din er broken, har du locked deg ut.

## Banner

`/etc/ssh/banner` skal inneholde en juridisk advarsel. Eksempel:

```
*****************************************************************
This is a private system. Authorized access only.
All connections are logged. Disconnect immediately if you are not
an authorized user. Unauthorized access may result in legal action
under applicable computer misuse laws.
*****************************************************************
```

For norske systemer kan banneren også være på norsk. Det viktige er at det er en bevisst advarsel — i visse jurisdiksjoner svekker fravær av en banner muligheten til å forfølge angripere juridisk.

## Match-blocks for spesialtilfeller

Standard policy passer ikke alle. Eksempler på legitime `Match`-blocks i `sshd_config.d/50-match.conf`:

```
# Backup user trenger sftp men ikke shell
Match User backup
    ChrootDirectory /srv/backup/%u
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
    PermitTunnel no

# CI-bruker fra spesifikk subnet, kun til deploy-script
Match User ci-deploy Address 10.20.0.0/16
    ForceCommand /usr/local/bin/ci-deploy.sh
    PermitTTY no
    AllowTcpForwarding no

# Admin-tilgang fra bastion ONLY, krever 2 publickey
Match Group ssh-admins Address 10.100.0.5
    AuthenticationMethods publickey,publickey
    AllowAgentForwarding no
```

`Match` parses i rekkefølge, og endringer i en match-block gjelder kun under den match-en, ikke globalt. Test alltid med `sshd -T -C user=...,host=...,addr=...` for å se den effektive konfig-en for en bruker.

## Ting jeg ikke har inkludert (med vilje)

- **`Port 2222`.** Sikkerhetsmessig nytteløst, gjør automatisering vanskeligere, bryter `iptables`-regler folk har for `tcp/22`. Hvis du vil redusere logg-støy fra brute-forcers, eksponer aldri SSH offentlig — bruk WireGuard eller Tailscale i stedet.
- **fail2ban-konfig.** Hvis du har `PasswordAuthentication no`, er fail2ban-mot-SSH stort sett security theater. Det blokkerer 0.01% av forsøk som hadde feilet uansett. Inkluder hvis det får compliance-folk fornøyde, men ikke regn med det.
- **Port-knocking.** Se §1 i hoved-README.
- **TCP wrappers (`/etc/hosts.allow`).** Deprecated i nyere OpenSSH-builds som ikke lenger linker mot libwrap. Bruk firewall-regler (nftables, ufw) i stedet.

## Verifisering

```bash
# 1. Syntax check
sshd -t

# 2. Effektiv konfig for en gitt bruker
sshd -T -C user=sasha,host=$(hostname),addr=10.100.0.10

# 3. Eksternt: ssh-audit
docker run --rm -it positiveuser/ssh-audit <hostname>

# 4. Lynis (kjøres lokalt på hosten)
sudo lynis audit system --tests-from-category authentication
```

Output fra (3) og (4) er lagret i `tests/`.
