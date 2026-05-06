# Tiltaksmapping — NSM 2.4 til konkret implementasjon

For hvert tiltak under prinsipp 2.4 (per NSM v2.1, mai 2024). NSM 2.4 har 4 underliggende tiltak.

## 2.4.1 — Etabler tilgangskontroll på flest mulige nettverksporter

NSM-tekst med v2.1-presisering: "Vær oppmerksom på at porter kan være fysiske, trådløse eller virtuelle." Tiltak omhandler godkjentlisting av nettverkstrafikk, kun forvaltede enheter får adgang, ikke-forvaltede enheter på gjeste-nett.

**Hvorfor v2.1-presiseringen om porter er viktig:**

Tradisjonell forståelse av "nettverksport" er fysisk RJ45-jack i en svitsj. Men i moderne miljø er det tre kategorier som alle krever tilgangskontroll:

| Port-type | Eksempler i lab-en | Kontroll-mekanisme |
|---|---|---|
| **Fysisk** | RJ45 på switch/ruter, USB | 802.1X port-based auth (ikke i lab-scope), fysisk tilgangskontroll |
| **Trådløs** | WiFi SSID, Bluetooth | WPA2/WPA3 enterprise, MAC-allowlisting, SSID-segmentering |
| **Virtuell** | Tailscale-forbindelse, Docker-container-IP, VLAN-tag, cloud security group | Mesh-ACLs, UFW-regler per interface, Docker network policy, cloud SG-regler |

I VPS-laben er det de **virtuelle portene** som er primær angrepsflate. Tailscale ACL er port-tilgangskontroll selv om ingenting fysisk skjer.

| Aspekt | Implementasjon |
|---|---|
| Hvor | `vps-bootstrap/scripts/00-bootstrap.sh` (UFW per-interface), `vps-bootstrap/tailscale/acl-example.json`, `vps-bootstrap/docker/daemon.json` (`iptables: false` så UFW er source-of-truth) |
| Status | Implementert (virtuelle porter); ikke relevant (fysiske/trådløse for VPS) |
| Bevis | UFW `allow in on tailscale0`, `default deny incoming`; Tailscale ACL deler tag:vps fra tag:laptop og restricter SSH-tilgang |
| Mapping NIST | SP 800-53 AC-3, SC-7 (Boundary Protection), SC-7(5) (Deny by Default) |
| Mapping NIST CSF | PR.AC-3, PR.AC-5 |
| Mapping ISO | 8.20 (Network security), 8.21 (Security of network services) |
| Gap | Ingen 802.1X (krever managed switch — out of scope for VPS). Ingen MAC-allowlisting på trådløst (out of scope). Cloud security groups (AWS/Azure) ikke i scope, men prinsippet det samme. |

## 2.4.2 — Krypter alle trådløse og kablede forbindelser

NSM-tekst: WPA2/WPA3 enterprise-modus for trådløst, kryptering for kablede forbindelser som ikke er fysisk kontrollert.

| Aspekt | Implementasjon |
|---|---|
| Hvor | Mesh-VPN-kryptering for all admin-trafikk (Tailscale bruker WireGuard underliggende; WireGuard direkte alternativ); SSH MAC + AEAD ciphers; TLS i applikasjonslag (Caddy) |
| Status | Implementert (innenfor VPS-scope) |
| Bevis | All trafikk inn til VPS går gjennom kryptert mesh; ingen plaintext exposure |
| Mapping NIST | SP 800-53 SC-8 (Transmission Confidentiality), SC-13 (Cryptographic Protection) |
| Mapping ISO | 8.20, 8.24 (Use of cryptography) |
| Gap | Trådløst er out-of-scope. For en faktisk Norge-deployment ville WPA3-Enterprise med EAP-TLS vært riktig. |

## 2.4.3 — Kartlegg fysisk tilgjengelighet for svitsjer og kabler

NSM-tekst: kartlegging av kabel-beliggenhet, særlig hvis ikke alle forbindelser autentiseres og krypteres.

| Aspekt | Implementasjon |
|---|---|
| Status | Ikke relevant for VPS-scope |
| Begrunnelse | VPS kjører i datasenter under leverandørens fysiske kontroll. Som VPS-kunde har vi ingen tilgang til underliggende fysisk infrastruktur. Tiltaket gjelder for selv-driftet datasenter eller kontornettverk. |
| Mapping NIST | SP 800-53 PE-3 (Physical Access Control), PE-4 (Access Control for Transmission) |
| Hva en virksomhet ville sjekket | Datasenter-leverandørens sertifiseringer (ISO 27001, SOC 2 Type II, Tier-rating); kontraktuell garanti for at fysisk tilgang er logget og restricted; segregert kunde-utstyr (caged/locked rack) |

For VPS-bruk er dette delegert til leverandøren via SLA og sertifiseringer.

## 2.4.4 — Aktiver brannmur på alle klienter og servere

NSM-tekst: bruk innebygde brannmurer for trafikkstyring og logging, integrer med sentral logging.

| Aspekt | Implementasjon |
|---|---|
| Hvor | `vps-bootstrap/scripts/00-bootstrap.sh` (UFW konfigurert default deny), `vps-bootstrap/ufw/before.rules`, UFW logging integrert med journald (ref. 3-2-laben) |
| Status | Implementert og verifisert |
| Bevis | UFW status active i 99-verify.sh; ufw.log shipped til central log via Vector/Promtail; eksempel-regler for app-deploy med per-port granularity |
| Mapping NIST | SP 800-53 SC-7 (Boundary Protection), AU-2 (Audit Events for firewall logs) |
| Mapping NIST CSF | PR.AC-5, DE.CM-1 |
| Mapping ISO | 8.20, 8.16 (Monitoring activities) |
| Gap | UFW-logger ikke aktivt brukt for detection (ingen Sigma-regler på UFW-events i 3.2-laben). Realistisk neste steg: Sigma-regel på "blocked outbound" som kan signal cryptojacker/data-exfil. |

## Sammendrag

| Tiltak | Status | Modenhet |
|---|---|---|
| 2.4.1 Tilgangskontroll på porter | Implementert (virtuell), n/a (fysisk/trådløs) | 3 |
| 2.4.2 Kryptering | Implementert | 3 |
| 2.4.3 Fysisk kabel-kartlegging | Ikke relevant (delegert til leverandør) | n/a |
| 2.4.4 Brannmur på klienter/servere | Implementert | 3 |

**Gjennomsnittlig modenhet på 2.4:** 3 (Definert) for relevante tiltak.

For nivå 4 ville vi trengt:
- Active network detection and response (NDR) — øst-vest visibility
- 802.1X på fysisk infrastruktur (krever managed switches)
- WPA3-Enterprise med EAP-TLS for trådløst (krever RADIUS-server)
- Egress-filtrering med DNS-allowlisting (krever pi-hole / NextDNS / cloud egress proxy)

## Cross-walks

| NSM | NIST CSF 2.0 | NIST SP 800-53 | ISO 27002:2022 |
|---|---|---|---|
| 2.4.1 | PR.AC-3, PR.AC-5 | AC-3, SC-7, SC-7(5) | 8.20, 8.21 |
| 2.4.2 | PR.DS-2 | SC-8, SC-13 | 8.20, 8.24 |
| 2.4.3 | PR.AC-2 | PE-3, PE-4 | 7.1, 7.2 (Physical security) |
| 2.4.4 | PR.AC-5, DE.CM-1 | SC-7, AU-2 | 8.20, 8.16 |

## Zero-trust-spesifikt cross-walk (NIST SP 800-207)

Denne lab-en demonstrerer zero-trust ut over hva NSM 2.4 alene krever, fordi norsk offentlig sektor er midt i overgangen og hiring managers ser etter ZT-kompetanse. Mapping mot NIST SP 800-207 grunnprinsipper:

| ZT-prinsipp | Hvordan denne lab-en demonstrerer det |
|---|---|
| Alle datakilder og compute-tjenester regnes som ressurser | Hver container er en ressurs som krever auth |
| All kommunikasjon sikres uavhengig av nettverkslokasjon | Mesh + TLS + SSH crypto = encrypted everywhere |
| Tilgang til ressurser gis per-session | SSH session er per-connection, mesh er per-peer |
| Tilgang bestemmes av dynamisk policy | Tailscale ACLs, UFW per-interface rules, Docker network membership |
| Virksomheten overvåker integritet og sikkerhetsposisjon på alle eide og tilknyttede assets | Cross-reference til 3.2-laben (sikkerhetsovervåkning) |
| All ressurs-autentisering og -autorisering er dynamisk og strengt håndhevet før tilgang | SSH pubkey + Tailscale identity, ikke IP-basert |
| Virksomheten samler maksimal informasjon om gjeldende tilstand til assets, nettverksinfrastruktur og kommunikasjon | LogLevel VERBOSE, auditd, journald-shipping |
