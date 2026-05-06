# Client-side SSH configuration

## Designprinsipper

1. **Per-host nøkler.** En kompromittert nøkkel skal ikke gi tilgang til alle miljøer. Homelab, AWS, Azure, og GitHub har separate nøkler. Kostnaden er litt mer oppsett, gevinsten er at blast radius av en lekket privatnøkkel er begrenset til ett trust-domene.

2. **Hardware-backed der det er mulig.** `sk-ed25519`-nøkler bruker en hardware token (YubiKey eller macOS Secure Enclave via `secretive`). Den private nøkkelen forlater aldri hardware. En kompromittert klient kan misbruke nøkkelen mens hen er aktiv (touch på YubiKey, enable på Secure Enclave), men kan ikke kopiere den ut.

3. **Host key pinning.** `~/.ssh/known_hosts.d/<env>` per miljø. Endringer i host keys er da ekstremt synlige — `ssh` nekter å koble til, og jeg må bevisst verifisere at det er en planlagt rotasjon før jeg fjerner gammel oppføring. Dette forsvarer mot MITM og mot at en angriper svinger om en host record.

4. **`IdentitiesOnly yes`.** Uten denne vil ssh-agent prøve hver eneste nøkkel den har for hver host. Det rate-limiter deg ut av GitHub i tillegg til å lekke alle public keys du eier til hver host du connecter mot. Med `IdentitiesOnly yes` brukes kun nøkkelen som er eksplisitt konfigurert for den hosten.

5. **Ingen agent forwarding.** `ForwardAgent no` overalt. Agent forwarding er en lateral movement-kanal: hvis du SSH-er fra A til B med agent forwarding, og B er kompromittert, kan B bruke agenten din til å autentisere som deg mot enhver C du har nøkkel til. ProxyJump løser de fleste behov uten denne risikoen.

6. **Connection multiplexing.** `ControlMaster` for hosts jeg connecter mye til. Reduserer auth-overhead, og betyr færre TCP-handshakes som logges på server-siden — som faktisk hjelper SOC-en med å se reelle anomalier.

## Filsystemoppsett

```
~/.ssh/
├── config                   # Den filen
├── keys/                    # 0700, hver fil 0600
│   ├── homelab_bastion_ed25519_sk
│   ├── homelab_bastion_ed25519_sk.pub
│   ├── homelab_internal_ed25519_sk
│   ├── aws_lab_ed25519_sk
│   ├── azure_lab_ed25519_sk
│   └── github_portfolio_ed25519
├── known_hosts.d/           # En fil per trust-domene
│   ├── homelab
│   ├── aws
│   ├── azure
│   └── github
└── sockets/                 # ControlMaster sockets, 0700
```

Permissions:
```bash
chmod 700 ~/.ssh ~/.ssh/keys ~/.ssh/known_hosts.d ~/.ssh/sockets
chmod 600 ~/.ssh/config ~/.ssh/keys/* ~/.ssh/known_hosts.d/*
chmod 644 ~/.ssh/keys/*.pub
```

`ssh` vil nekte å bruke nøkler med for åpne permissions — det er bra, men det er vår jobb å sette dem riktig fra start.

## Hvordan generere nøklene

```bash
# Standard ed25519 (klient skal autentisere mot et legacy system uten FIDO2-støtte)
ssh-keygen -t ed25519 -C "sasha-aws-lab-$(date +%Y%m%d)" -f ~/.ssh/keys/aws_lab_ed25519_sk

# FIDO2-backed ed25519 (krever YubiKey eller annen FIDO2-token)
# -O resident gjør at nøkkelen kan importeres fra YubiKey på en ny maskin
# -O verify-required krever PIN på YubiKey i tillegg til touch
ssh-keygen -t ed25519-sk -O resident -O verify-required \
    -C "sasha-homelab-bastion-$(date +%Y%m%d)" \
    -f ~/.ssh/keys/homelab_bastion_ed25519_sk
```

For Secure Enclave på macOS bruk `secretive` (https://github.com/maxgoedjen/secretive) — den eksponerer en SSH agent som signerer med Secure Enclave-nøkler.

## Pinning av known_hosts

Første gang du connecter mot en ny host:

```bash
# Bekreft fingerprint OUT OF BAND først (cloud console, vendor docs, fysisk konsoll)
# Deretter:
ssh-keyscan -t ed25519 <hostname> >> ~/.ssh/known_hosts.d/<env>
```

For GitHub spesifikt, fingerprint skal matche:
```
github.com ssh-ed25519 SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU
```

Verifisert mot https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints

## Rotasjon

- **Personlige nøkler:** roter hvert 12. måned eller umiddelbart ved mistanke om kompromiss
- **Agent-nøkler (CI, automation):** roter hvert 90. dag, scriptet
- **Host keys på server:** roter ved kompromiss eller stor versjonsoppgradering, ellers la dem stå (rotasjon uten grunn skaper kun forvirring og potensiell MITM-vindu)
