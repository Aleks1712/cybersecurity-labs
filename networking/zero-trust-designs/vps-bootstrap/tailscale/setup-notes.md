# Tailscale Setup

Tailscale er det letteste alternativet for personlig/småskala mesh: kontrollplan-servere er hosted, derfor null oppsett av koordinasjonsserver, og det fungerer på tvers av NAT/CGNAT uten port forwarding.

Trade-off: du stoler på Tailscale Inc. for kontrollplanet (men ikke for trafikkinnhold — det er end-to-end-kryptert direkte mellom peers, kontrollplanet ser kun nøkkel-utveksling).

Hvis du vil ha selvhostet kontrollplan, bruk Headscale (open-source reimplementasjon). Klienten er den samme.

## Initial setup

```bash
# Etter at 00-bootstrap.sh har installert tailscale:

# Auth interaktivt (åpner URL du må logge inn på)
sudo tailscale up --ssh --advertise-tags=tag:vps

# ELLER auth med pre-generated key (fra tailscale admin console):
sudo tailscale up --authkey tskey-auth-... --ssh --advertise-tags=tag:vps

# Verifiser
tailscale status
tailscale ip -4
```

## Hva flaggene betyr

- **`--ssh`** — Aktiverer Tailscale SSH. Tailscale tar over SSH-handshaken og bruker mesh-identitet i stedet for vanlige SSH-nøkler. Du kan fortsatt bruke vanlig SSH ved siden av; `--ssh` gir bare et ekstra alternativ. Verdt å vurdere for break-glass-scenarier (når dine SSH-nøkler er borte men Tailscale-auth fortsatt fungerer).

- **`--advertise-tags=tag:vps`** — Tagger denne hosten. ACL-er kan så referere til `tag:vps` istedet for spesifikke maskinnavn.

- **`--accept-routes`** — Hvis andre noder annonserer subnet-routes (f.eks. en hjemmelab-router), godta dem. La det være av med mindre du vet du trenger det.

- **`--exit-node=...`** — Bruk en annen node som default-route. Ikke for VPS — VPS-er er typisk *kilder* til exit-node-funksjonalitet, ikke konsumenter.

## ACL — locker SSH til kun deg

I Tailscale admin console, sett opp en ACL som spesifikt tillater SSH til `tag:vps` kun fra ditt eget bruker-account. Eksempel ACL-policy i `acl-example.json`.

Default Tailscale ACL er "allow all between all your devices" — det er greit for personlig bruk, men hvis du har lab-deler som kan kompromitteres separat, vil du segmentere.

## Verifisering

```bash
# Fra VPS-en
tailscale status                    # ser jeg andre noder?
tailscale ping <annet-node-navn>    # round-trip test

# Fra annen node
ssh <vps-name>                      # MagicDNS hostname fungerer
ssh <100.x.y.z>                     # eller direkte tailscale IP
```

## Hva som BØR fungere etter oppsett

- `ssh user@<vps-tailscale-ip>` fra mesh-peer → suksess
- `ssh user@<vps-public-ip>` fra ikke-mesh kilde → connection refused / timeout
- `nmap -Pn <vps-public-ip>` fra ikke-mesh kilde → ingen åpne porter

Hvis (3) viser åpne porter, har firewall-en feilet eller noen tjeneste binder til `0.0.0.0` istedet for tailscale-interfacet.

## Vedlikehold

Tailscale klient oppdaterer seg via apt (har sin egen repo lagt til av install-scriptet). `unattended-upgrades` plukker opp security-oppdateringer av tailscale-pakken automatisk siden den kommer fra "tailscale" suite som matches av "${distro_id}:" pattern hvis du legger den til i 50unattended-upgrades.

Sjekk versjonen:
```bash
tailscale version
```

## Logout / dekommissionering

```bash
sudo tailscale logout
sudo tailscale down
sudo apt remove --purge tailscale
```

Husk også å fjerne maskinen fra Tailscale admin console — `logout` fjerner kun lokal state, ikke registreringen sentralt.

## Sources

- Tailscale documentation: https://tailscale.com/kb
- "Use Tailscale with UFW": https://tailscale.com/kb/1077
- Tailscale ACL syntax: https://tailscale.com/kb/1018/acls
