# Tests

Hvordan kjøre testene som validerer at hardening-en faktisk fungerer.

## ssh-audit

Eksternt verktøy som kobler til SSH-serveren og rapporterer på algoritmer, host keys, og kjente svakheter.

```bash
# Via Docker (anbefalt — alltid siste versjon)
docker run --rm -it positiveuser/ssh-audit <hostname>

# Via pip
pip install --user ssh-audit
ssh-audit <hostname>
```

Forventet output etter hardening: **overall grade A+**, ingen `[fail]` eller `[warn]`.

Lagre output:
```bash
ssh-audit <hostname> > tests/ssh-audit-hardened.txt
```

For sammenligning, kjør samme verktøy mot en upatchede default-installasjon og lagre som `ssh-audit-baseline.txt`.

## Lynis

Lokal system audit — kjøres på serveren, ikke fra klienten.

```bash
# Installer
sudo apt install lynis    # Debian/Ubuntu
sudo dnf install lynis    # RHEL/Fedora

# Kjør med fokus på authentication og SSH
sudo lynis audit system --tests-from-category authentication > tests/lynis-ssh-section.txt

# Hardening index for SSH spesifikt:
sudo lynis show details SSH-7408
```

Forventet: hardening index 90+ for SSH-seksjonen.

## Manual checks

### Verifiser at password auth virkelig er av

```bash
# Fra klienten, prøv eksplisitt password auth
ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password user@host
# Forventet: "Permission denied (publickey)."
```

### Verifiser at root login er av

```bash
ssh root@host
# Forventet: "Permission denied (publickey)." selv hvis du har en gyldig nøkkel
```

### Verifiser at agent forwarding faktisk er av

```bash
ssh -A user@host
# På serveren:
echo $SSH_AUTH_SOCK
# Forventet: tom — agent forwarding ble nektet selv om klient ba om det
```

### Verifiser at gamle algoritmer faktisk avvises

```bash
# Prøv å forhandle ssh-rsa (SHA-1)
ssh -o HostKeyAlgorithms=ssh-rsa -o PubkeyAcceptedAlgorithms=ssh-rsa user@host
# Forventet: "no matching host key type found" eller tilsvarende

# Prøv en svak cipher
ssh -c aes256-cbc user@host
# Forventet: "no matching cipher found"
```

## Logging-verifisering

Etter en innlogging, sjekk at fingerprint er logget:

```bash
sudo journalctl -u ssh -n 50 | grep -i "accepted publickey"
```

Forventet linje:
```
Accepted publickey for sasha from 10.100.0.10 port 51234 ssh2: ED25519 SHA256:abcd...
```

`SHA256:abcd...` er fingerprint av nøkkelen som ble brukt — det er det `LogLevel VERBOSE` gir deg.

## Continuous validation

Anbefalt: en ukentlig cron-jobb som kjører `ssh-audit` mot alle dine hosts og varsler hvis grade faller under A+. Eksempel i `scripts/` (TODO — ikke skrevet ennå, lab-iterasjon 2).
