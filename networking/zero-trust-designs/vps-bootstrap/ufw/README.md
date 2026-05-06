# UFW Firewall Configuration

UFW (Uncomplicated Firewall) er Ubuntu/Debian sin frontend til `nftables`/`iptables`. På denne stack-en har den én jobb: blokkere alt inbound på offentlige interfacer, og kun slippe gjennom mesh-trafikk.

## Designprinsipper

1. **Default deny inbound, default allow outbound.** Det vanlige homelab-mønsteret. Egress filtering er en separat lab — det er mer komplisert enn det høres ut, og det er lett å lock-e seg selv ute fra `apt update`.

2. **Default deny forward.** Hvis denne hosten ikke er en router, skal den ikke route. Default `forward = drop` er et "ja, jeg har tenkt på dette"-signal. Hvis du senere setter opp Docker (som bruker forwarding), aktiverer Docker dette automatisk i sine egne kjeder.

3. **Mesh-interface allow.** Tailscale-interfacet (`tailscale0`) eller WireGuard (`wg0`) får eksplisitt allow. All trafikk inn på mesh er allerede authenticated av mesh-en selv, så vi stoler på den.

4. **Ingen offentlig SSH.** Bevisst valg. Kostnaden er at hvis mesh-en feiler, må du bruke leverandørens web-konsoll. Gevinsten er at SSH-scannere ikke ser deg, og brute-force-statistikken blir 0 i stedet for 1000+/dag.

## Standard regelsett

```
Default policies:
  Inbound:   deny
  Outbound:  allow
  Forward:   deny

Allowed:
  in on tailscale0 (eller wg0)  — mesh trafikk
  51820/udp                      — kun hvis WireGuard valgt; Tailscale trenger ikke åpen port
```

Det er det. Ingen andre porter.

## Når trenger du å åpne mer?

**Hvis hosten serverer offentlig HTTP/HTTPS:**

```bash
sudo ufw allow 80/tcp comment 'HTTP redirect to HTTPS'
sudo ufw allow 443/tcp comment 'HTTPS'
```

Men før du gjør dette, vurder: kan du sette en Cloudflare Tunnel eller en reverse proxy på en annen mesh-host i stedet? Da slipper du å eksponere VPS-en direkte.

**Hvis hosten kjører en SMTP-relay:**

Ikke gjør det med mindre du må. Egress-port-25-policy fra alle store VPS-leverandører er restriktiv, og IP-reputasjonen til generic VPS-er er dårlig nok til at email du sender går rett i spam.

**Hvis hosten er en game server eller IRC eller noe annet eksotisk:**

Eksplisitt allow med `comment` så du i fremtiden husker hvorfor regelen er der.

## IPv6

UFW har IPv6-støtte aktivert som default i `/etc/default/ufw` (`IPV6=yes`). Vi lar den stå på.

Forrige tutorial du så som sa "disable IPv6" var sannsynligvis fra rundt 2014. I 2026 er IPv6 like veletablert som IPv4, og mange cloud-provider gir deg en gratis /64 som er nyttig for mesh-routing.

## Når Docker er installert

Docker manipulerer iptables direkte og bypasser UFW i default-konfig. Det er en kjent fallgruve. Løsning: sett `"iptables": false` i `/etc/docker/daemon.json` (gjøres i `docker/daemon.json`), bind containere til `127.0.0.1:port` eller mesh-interfacet, og la UFW være i kontroll.

Detaljer i `docker/README.md`.

## Verifisering

```bash
# Status og regler
sudo ufw status verbose

# Hva ufw faktisk vil si til iptables/nftables
sudo ufw show added

# Lytte-porter
sudo ss -lntp

# Test fra utsiden (fra en non-mesh kilde)
nmap -Pn -p- <vps-public-ip>
# Forventet: alle filtered/closed, kanskje 51820/udp open hvis WireGuard
```

## Sources

- UFW manual page (`man ufw`)
- Ubuntu Server Guide — Firewall section
- Tailscale documentation: "Use Tailscale with UFW" (https://tailscale.com/kb/1077/secure-server-ubuntu)
