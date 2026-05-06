# Praksis — slik implementerer eksisterende labs NSM 2.4

Hvor teorien om zero-trust møter konkrete iptables-regler og Docker-nettverk. NSM 2.4 har 4 tiltak — alle behandlet i rekkefølge under, med implementasjonsdetaljer for hvert.

Det er verdt å merke seg at NSM 2.4-tiltakene er stramme om "hva", men lar virksomheten velge "hvordan". Alle disse implementasjonsdetaljene er én vei til å oppfylle kravene; en faktisk virksomhet kan velge andre verktøy med samme resultat.

## 2.4.1 — Etabler tilgangskontroll på flest mulige nettverksporter

NSM ber om at trafikk kun tillates på godkjentlistede porter, kun forvaltede enheter får adgang, og ikke-forvaltede enheter holdes på gjeste-nett. **NSM v2.1 presiserer eksplisitt at "porter" omfatter fysiske, trådløse og virtuelle porter.**

Den presiseringen er kritisk fordi VPS-skala-arbeid handler nesten utelukkende om virtuelle porter. Det er virtuelle porter som er angrepsflaten, og det er der tilgangskontrollen må finne sted.

### Hvordan vi gjør det

**Lag 1 — Public Internet → VPS-host:**
UFW konfigurert med `default deny incoming` på alle interfaces. Eneste tillatte ingress er på mesh-interfacet (Tailscale eller WireGuard). Fra `vps-bootstrap/scripts/00-bootstrap.sh`:

```bash
ufw default deny incoming
ufw default allow outgoing
ufw default deny forward

# Allow only mesh ingress
ufw allow in on tailscale0
# OR for WireGuard:
# ufw allow 51820/udp comment 'WireGuard listener'
# ufw allow in on wg0
```

Dette implementerer "kun tillatte porter" på virtuelt-port-nivå. Public-side-portene er ikke åpne for noen.

**Lag 2 — Mesh-nettverk → VPS-tjenester:**
Tailscale ACLs styrer hvilke peers (identifisert via tags) som kan nå hvilke ports på hvilke hoster. Eksempel fra `vps-bootstrap/tailscale/acl-example.json`:

```jsonc
"acls": [
  // Bare laptops kan SSH til VPS
  { "action": "accept", "src": ["tag:laptop"], "dst": ["tag:vps:22"] },
  // Bare prod-klienter kan nå prod-app
  { "action": "accept", "src": ["tag:laptop"], "dst": ["tag:prod:80,443"] }
  // Default deny er implisitt
]
```

Dette er identitet-basert tilgangskontroll på virtuelle porter — ikke IP-basert. En kompromittert peer mister tilgang umiddelbart når den fjernes fra meshen.

**Lag 3 — Host → Container (via Docker network):**
Docker-segmentering. Fra `vps-bootstrap/app-deploy/docker-compose.yml.example`:

```yaml
networks:
  frontend: { driver: bridge }
  backend: { driver: bridge, internal: true }

services:
  caddy:
    networks: [frontend]                  # bare frontend
  app:
    networks: [frontend, backend]         # bro mellom soner
  db:
    networks: [backend]                   # bare backend, INGEN internett
```

Caddy kan ikke nå db direkte fordi de ikke deler nettverk. Det er virtuell-port-tilgangskontroll på applikasjonsnivå.

**Kritisk konfigurasjon for å holde Docker fra å bypass UFW:**
```json
// /etc/docker/daemon.json
{ "iptables": false }
```

Uten dette vil `ports: ["100.64.x.y:80:80"]` i compose-filen faktisk eksponere på `0.0.0.0:80` regardless of UFW-policy. `iptables: false` gjør UFW til source-of-truth.

### Hva som mangler

For full v2.1-compliance på fysisk og trådløst nivå:
- 802.1X port-based authentication på fysisk infrastruktur — krever managed switch, ikke i VPS-scope
- WPA3-Enterprise med EAP-TLS for trådløst — krever WiFi-deployment, ikke i VPS-scope

Det er en bevisst scope-avgrensning. En homelab-nettverkssikkerhets-lab ville dekket disse.

## 2.4.2 — Krypter alle trådløse og kablede forbindelser

NSM ber om kryptering for trådløse forbindelser (WPA2/WPA3 enterprise) og for kablede forbindelser som ikke er fysisk kontrollert.

### Hvordan vi gjør det

For VPS-trafikk er all relevant kryptering:

| Trafikk-type | Krypterings-mekanisme | Implementasjon |
|---|---|---|
| Admin SSH til VPS | SSH protokoll med Curve25519 + AEAD | `ssh-hardening/server-config/sshd_config.d/10-crypto.conf` |
| Mesh-VPN | WireGuard (Noise Protocol Framework) | Tailscale (bruker WG underliggende) eller `vps-bootstrap/wireguard/server.conf` |
| Web-trafikk inn til VPS | TLS 1.3 | Caddy reverse proxy med automatisk Let's Encrypt |
| Inter-container | Default plaintext (Docker bridge) — ikke kryptert | Akseptabelt fordi backend-nettverk er `internal: true` og ikke nådbart utenfra |
| Docker socket access | UNIX socket med fil-permisjoner — ikke kryptert | Akseptabelt fordi det er host-lokalt; auditd watcher hvis prosess utenfor docker-gruppen rører den |

**Verifikasjon:**
```bash
# Test at SSH ikke aksepterer ikke-AEAD ciphers
nmap --script ssh2-enum-algos -p 22 <mesh-ip>

# Test at Caddy bruker TLS 1.3
curl -v --tls-max 1.2 https://<mesh-ip> 2>&1 | grep "TLSv1.3"
```

### Hva som mangler

Inter-container kryptering (mTLS mellom Caddy og app, mellom app og db) er ikke implementert. Det ville vært nivå 4 — service mesh som Linkerd eller Istio. For VPS-skala er host-isolering tilstrekkelig.

## 2.4.3 — Kartlegg fysisk tilgjengelighet for svitsjer og kabler

NSM ber om kartlegging av fysisk kabel-beliggenhet, spesielt hvis ikke alle forbindelser autentiseres og krypteres.

### Hvordan vi forholder oss til dette

For VPS-skala er dette ikke vårt ansvar — det er datasenter-leverandørens. Vi har null fysisk tilgang til underliggende infrastruktur.

Det vi *gjør* er å verifisere at leverandøren har relevante sertifiseringer:

| Aspekt | Hva en virksomhet sjekker |
|---|---|
| Datasenter-sertifisering | ISO/IEC 27001, SOC 2 Type II, ISO 22301 (continuity), Tier-rating |
| Kontraktuell garanti | Right-to-audit-clause i kontrakten, fysisk tilgang logget |
| Compliance-dokumenter | Trust Service Criteria report, ISAE 3402 |
| Geografisk plassering | Datasenter-lokasjon (NSM råder ofte til Norge/EØS for sensitive data) |

For norsk sektor: Sjekk om leverandøren er på listene som NSM/Datatilsynet aksepterer, eller om eierforhold (Cloud Act-eksponering for amerikansk-eide tjenester) er en bekymring.

### Hvorfor dette er viktig å ha med i tiltaksmappingen

Selv om vi ikke implementerer 2.4.3 selv, må vi vite at *noen* gjør det og hvordan vi verifiserer det. En hiring manager som leser dette ser at jeg forstår delegering av ansvar via leverandørkjede — som er et viktig konsept for cloud-rolle.

## 2.4.4 — Aktiver brannmur på alle klienter og servere

NSM ber om at brannmur er aktivert på alle hosts (både klienter og servere) — enten innebygde host-brannmurer eller eksterne, og at logging fra brannmur integreres med sentral overvåkning.

### Hvordan vi gjør det

**UFW på VPS-host:**
Konfigurert via `vps-bootstrap/scripts/00-bootstrap.sh` som beskrevet i 2.4.1.

**Logging:**
UFW-events skrives til journald og kan shippes til central log via Vector eller Promtail (ref. `nsm-grunnprinsipper/3-2-sikkerhetsovervakning/parsers/`).

```toml
# Ekstrakt fra vector.toml
[sources.journald_main]
type = "journald"
include_units = [
    "ssh.service",
    "ufw.service",      # ← UFW-events
    "fail2ban.service",
    "docker.service"
]
```

**Per-port granularity i app-deploy:**
For applikasjoner som trenger å eksponere flere ports kan UFW gi finere kontroll:
```bash
ufw allow in on tailscale0 to any port 80,443 proto tcp comment 'web-public'
ufw allow in on tailscale0 to any port 22 proto tcp comment 'admin-only-from-mesh'
ufw allow in on docker0 to any port 5432 proto tcp comment 'db-from-app-only'
```

### Hva som mangler

UFW-logger er på lag, men ingen Sigma-regel i `3-2-sikkerhetsovervakning/sigma-rules/` plukker opp UFW-events ennå. Realistisk neste steg: regel som detekterer `ufw_block` events for outbound trafikk fra containere — det signaliserer ofte at en kompromittert app prøver å callback til C2.

```yaml
# Forslag til ny Sigma-regel:
# title: Container Outbound Connection Blocked by UFW
# tags: attack.command-and-control, attack.t1071, nsm.2-4, nsm.3-2
```

Det legger jeg til i fremtidig iterasjon — for å unngå å blåse opp scope nå.

## Hva en hiring manager bør ta med

Tre punkter:

1. **NSM v2.1's port-presisering er moderne praksis.** Det å forstå at "tilgangskontroll på porter" gjelder Tailscale ACLs og Docker network policy like mye som fysiske RJ45-porter er det som skiller en kandidat som har lest dokumentet fra en som bare har sett tittelen.

2. **2.4 er ikke alene tilstrekkelig.** Lab-en demonstrerer at 2.4 fungerer sammen med 2.6 (identitet) og 3.2 (overvåkning). Et nettverk som er korrekt segmentert men ikke overvåket er halvferdig.

3. **Cloud-delegering er en del av rammeverket.** 2.4.3 er ikke "ikke gjort" — det er "verifisert delegert til leverandør". Det er en moden måte å håndtere shared responsibility model på.

## Sources

- NSM Grunnprinsipper v2.1, prinsipp 2.4 (med v2.1-presisering om porter)
- vps-bootstrap lab i denne repoet
- ssh-hardening lab i denne repoet
- NIST SP 800-207 Zero Trust Architecture
- "Container Security" — Liz Rice, O'Reilly 2020 (for Docker network isolation patterns)
