# WireGuard — Self-Hosted VPN Mesh

Vanilla WireGuard som alternativ til Tailscale. Mer kontroll, mer arbeid. Velg dette hvis:

- Du vil ikke stole på en tredjepart for kontrollplanet
- Du har static IP-er som ikke endrer seg ofte
- Du har færre enn ~10 peers (lengre listene blir vanskeligere å vedlikeholde manuelt)
- Du har lyst til å forstå hva en VPN faktisk gjør

Velg Tailscale hvis:
- Du har dynamic IP-er (hjemme-router, mobile peers)
- Mange peers på tvers av forskjellige nettverk
- Du vil ha NAT traversal automatisk
- Du vil ha SSH-policy via mesh-identitet

## Topologi-valg

WireGuard er ikke automatisk mesh — du må velge topologi:

**Hub-and-spoke (enklest):**
- Én sentral host (typisk en VPS) er server
- Alle andre peers connecter til den
- Peer-til-peer går gjennom hub
- Ulempe: hub er single point of failure

**Full mesh (hver peer-til-peer):**
- Hver peer kjenner alle andre peers
- Direkte connections mellom peers
- Mer config å vedlikeholde, men ingen SPOF

For 2-5 peers, hub-and-spoke er fint. For større, vurder Tailscale eller Headscale.

## Genererings og oppsett

På VPS (server-side):

```bash
cd /etc/wireguard
umask 077

# Server keys
wg genkey | tee server_private.key | wg pubkey > server_public.key

# Vis public key som skal inn i hver client config
cat server_public.key
```

På laptop/phone/peer (client-side):

```bash
# Generate client keys
wg genkey | tee client_private.key | wg pubkey > client_public.key

# Vis client public key — skal inn i server's wg0.conf som [Peer]
cat client_public.key
```

## Aktivering

Etter at `wg0.conf` er på plass på begge sider:

```bash
# Server
sudo systemctl enable --now wg-quick@wg0

# Client (Linux)
sudo systemctl enable --now wg-quick@wg0

# Client (macOS / iOS / Android — bruk WireGuard-appen)
# Importer config-filen, klikk activate
```

## Verifisering

```bash
# Server
sudo wg show
# Forventet output: interface wg0, listening port, listet peers og deres
# latest handshake

# Connectivity test fra client til server
ping 10.50.0.1
```

Hvis ping feiler:
1. Sjekk `wg show` på begge sider — er det handshake?
2. Sjekk `sudo iptables -L -n` — er trafikk blokkert?
3. Sjekk at UFW tillater UDP/51820 inn på public interface
4. Sjekk at endpoint i client config matcher VPS public IP
5. Sjekk at AllowedIPs på server-side er `10.50.0.x/32` for client (ikke /24 — det blir conflict)

## Operativ håndtering

**Legge til ny peer (live, uten å restart):**
```bash
sudo wg set wg0 peer <new-peer-pubkey> allowed-ips 10.50.0.X/32
# Persist endringen i wg0.conf også, ellers er den borte ved reboot
```

**Fjerne peer:**
```bash
sudo wg set wg0 peer <peer-pubkey> remove
# Persist endringen i wg0.conf også
```

**Rotere keys:**

Roter på client-side (generer nye, oppdater på server, oppdater client config). På server-side: kompliceredte fordi alle clients må oppdatere server-pubkey samtidig. Plan downtime.

## Forskjell mot Tailscale spesifikt

| | Tailscale | WireGuard |
|---|---|---|
| NAT traversal | automatisk | du må manuelt sette opp port forwarding eller endpoint |
| Identitet | OAuth (Google/Microsoft/etc.) | shared keys |
| Key rotation | automatic | manuelt |
| ACL | sentralt admin console | iptables/ufw + AllowedIPs |
| MagicDNS | ja | nei (bruk /etc/hosts eller egen DNS) |
| SSH integration | innebygd | bruk vanlig SSH over tunnelen |
| Cost | free for personal, betalt for større | free |
| Trust model | Tailscale Inc. har kontrollplan | du har alt |

## Sources

- WireGuard documentation: https://www.wireguard.com/
- WireGuard whitepaper (kryptografi-rasjonalet): https://www.wireguard.com/papers/wireguard.pdf
- "WireGuard Quick Start": https://www.wireguard.com/quickstart/
