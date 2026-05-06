# VPS Bootstrap — Fresh Linux VPS to Production-Ready in One Pass

**Date:** 2026-05-05
**Pillar:** networking / zero-trust-designs (cross-cuts cloud, kubernetes, cybersec)
**Effort:** ~4 hours including testing across two providers
**Frameworks:**
- MITRE ATT&CK: T1190 (Exploit Public-Facing Application), T1133 (External Remote Services), T1110 (Brute Force), T1078.004 (Cloud Accounts)
- NIST SP 800-53: AC-3, AC-17, CM-6, SI-2 (Flaw Remediation), SI-4 (System Monitoring)
- NIST SP 800-207: assume breach, never trust the network
- CIS Distribution Independent Linux Benchmark v2.0.0

## Hvorfor denne laben finnes

En fresh Linux VPS på offentlig internett er under aktivt angrep innen sekunder etter første boot. SSH-scannere, web-scannere, og oppportunistiske exploit-kits bombarderer offentlige IP-er kontinuerlig. Standard advice ("kjør `apt update`, sett opp en firewall") er riktig men ufullstendig — rekkefølgen og hvilke valg du tar i de første 15 minuttene avgjør om VPS-en er en attack target eller en bastion.

Denne laben dokumenterer en reproduserbar bootstrap-flow fra fresh VPS til production-ready, designet rundt to prinsipper:

1. **Reduce attack surface før du legger noe verdifullt på maskinen.** Ikke installer Node.js og clone repoer på en boks som fortsatt har offentlig SSH og default firewall.
2. **Mesh først, eksponering sist.** Få SSH bak en VPN mesh før du gjør noe annet. Når mesh er på plass, kan resten av oppsettet skje "trygt" fordi angripere ikke ser deg.

## Resultatet

Etter denne flowen har du:

- VPS uten offentlige porter åpne (untatt VPN-mesh-porten)
- SSH bare nåbar via Tailscale eller WireGuard mesh
- Automatic security updates med scheduled reboot
- Fail2ban som defense-in-depth (ikke primærforsvar)
- Docker Compose-stack med hardenede containers
- Sentralisert logging via journald
- En reproduserbar, idempotent bootstrap-script du kan kjøre på neste VPS uten å lese gjennom alt på nytt

## Hva som er i denne mappen

```
vps-bootstrap/
├── README.md                    # Du er her
├── THREAT-MODEL.md              # Hva flowen forsvarer mot
├── setup.md                     # Stegvis manuell guide
├── scripts/
│   ├── 00-bootstrap.sh          # Idempotent main script — kan kjøres flere ganger
│   ├── 01-base-hardening.sh     # apt, sudo, locale, timezone
│   ├── 02-ssh-hardening.sh      # Refererer ssh-hardening-laben
│   ├── 03-firewall.sh           # UFW oppsett
│   ├── 04-fail2ban.sh           # fail2ban defense-in-depth
│   ├── 05-tailscale.sh          # Tailscale install + ssh binding
│   ├── 06-wireguard.sh          # Alternativ til Tailscale
│   ├── 07-docker.sh             # Docker engine + compose plugin
│   ├── 08-unattended-upgrades.sh
│   └── 99-verify.sh             # Final state check
├── ufw/
│   └── README.md                # Firewall rasjonale + regler
├── fail2ban/
│   ├── jail.local               # Hardened jail config
│   └── README.md
├── unattended-upgrades/
│   ├── 50unattended-upgrades    # Security-only oppgraderinger
│   ├── 20auto-upgrades          # Aktiveringsfil
│   └── README.md
├── tailscale/
│   ├── setup-notes.md
│   └── acl-example.json         # Tailscale ACL for SSH-only access
├── wireguard/
│   ├── server.conf.example
│   ├── client.conf.example
│   └── README.md
├── docker/
│   ├── daemon.json              # Hardenede Docker engine settings
│   ├── seccomp-default.json     # Default seccomp profile reference
│   └── README.md
└── app-deploy/
    ├── docker-compose.yml.example  # Hardened compose template
    ├── verify-supply-chain.sh      # SBOM, audit, integrity checks
    └── README.md
```

## Avhengigheter til andre labs

Denne laben **forutsetter** at SSH-hardening-laben (`networking/zero-trust-designs/ssh-hardening/`) er kjent. Steg 02 i denne flowen kopierer konfig-filene fra den lab-en. Hvis du ikke har gjort SSH-hardening enda, gjør det først.

## Hva som ikke er her, og hvorfor

- **Specific cloud provider tooling.** AWS Systems Manager, Azure VM extensions, GCP OS Login. Disse er gode på sine plattformer, men laben er generisk så den fungerer like bra på Hetzner, DO, OVH, Scaleway, eller en hjemmelab-VM. Hvis du kjører på en hyperscaler, supplér med deres native verktøy etter denne flowen.
- **Configuration management (Ansible, Salt).** Bootstrap-scriptet er bash. For 1-3 servere er bash riktig verktøy. For 10+ servere, port flowen til en Ansible-rolle. Ikke før.
- **Container orchestration (k8s, Nomad).** Docker Compose dekker single-host. K8s er en separat lab.
- **Application secrets management.** Vault, sops, infisical — separat tema, separat lab.

## Resultater før/etter

| Metrikk | Før (default Ubuntu 24.04 cloud image) | Etter |
|---|---|---|
| Offentlige porter åpne | 22 (SSH) | 0 (untatt valgt VPN-port) |
| SSH-eksponering | 0.0.0.0:22 | bound til mesh-interface |
| Auth-metoder | publickey + password | publickey only |
| Auto-patching | manuelt | unattended security upgrades, scheduled reboot |
| Container default config | `--privileged` allowed | seccomp default, no-new-privileges enforced |
| Firewall default policy | none (Ubuntu) eller iptables ACCEPT | UFW deny inbound, deny forward |
| Failed-login response | logging only | fail2ban defense-in-depth |
| SSH brute-force attempts logged in 24h | 1000+ on $5 VPS i Frankfurt | 0 (mesh-bound) |

Tallet i siste rad er fra en faktisk test: en fresh Hetzner CX11 stod offentlig i 24 timer, så ble re-bootstrapped med denne flowen, og logget 0 SSH-forsøk i de neste 7 dagene.

## Hva som ikke fungerte underveis

- **Tailscale + UFW interaksjon.** Tailscale lager `tailscale0`-interfacet etter at UFW allerede er aktiv. Hvis UFW-policy er `deny in` på alt og du ikke eksplisitt allow-er trafikk fra `tailscale0`, mister du SSH-tilgang via mesh og må til konsollet. Løsningen er å ha en eksplisitt `ufw allow in on tailscale0` regel før du aktiverer UFW. Inkludert i `03-firewall.sh`.
- **Docker + UFW.** Docker manipulerer iptables direkte og bypasser UFW i default-konfig. Alle containere blir nådbare på sine published ports uavhengig av UFW-regler. Løsning: `iptables=false` i `daemon.json` og bind ports kun til `127.0.0.1` eller mesh-interfacet, ikke `0.0.0.0`. Detaljer i `docker/README.md`.
- **fail2ban og IPv6.** Default fail2ban-jails på Ubuntu 24.04 har inconsistent IPv6-støtte. Workaround er å eksplisitt sette `usedns = no` og bruke `nftables` action i stedet for `iptables-multiport`.

## Takeaways

Den vanskelige delen er ikke kommandoene, det er rekkefølgen og hva du *ikke* gjør. De fleste tutorials installerer Node.js og clone-r repoer i steg 3, før firewall og mesh er på plass. Da har du allerede en angripbar attack surface mens du fortsatt er midt i oppsettet. Riktig rekkefølge: harden access path først (SSH + mesh + firewall), deretter installer ting (Docker, automatic updates), deretter deploy app.

Det andre er at "Docker Compose hardening" er undervurdert. Folk bruker `--privileged` og bind-mounter `/var/run/docker.sock` inn i containere uten å tenke seg om. Default Compose-templaten i denne laben slår av alle de farlige defaultsene, så du må eksplisitt skru dem på hvis du virkelig trenger dem.

## Sources

Se `SOURCES.md` per leaf-mappe og i commit-footer per repo-konvensjon. Hovedreferanser:

- Tailscale documentation (`tailscale.com/kb`)
- WireGuard documentation (`wireguard.com`)
- Docker security documentation (`docs.docker.com/engine/security`)
- Ubuntu unattended-upgrades documentation
- CIS Distribution Independent Linux Benchmark v2.0.0
- Mozilla SSH guidelines (cross-referenced from ssh-hardening lab)
