# Docker Engine Hardening

`daemon.json` er minimal med vilje. Hver setting har en grunn — her er den.

## Per-setting rasjonale

### `"iptables": false`

Docker manipulerer som default `iptables`-kjeder direkte når en container publishes en port (`-p 8080:80`). Effekten er at containere blir nådbare på `0.0.0.0:8080` uavhengig av UFW-policy. Det er den vanligste fallgruven for folk som tror UFW beskytter dem.

Med `iptables: false` lar Docker firewall-en være, og du må eksplisitt åpne porter via UFW. Du må også manuelt skrive routing-regler hvis du vil at containere skal kunne snakke med hverandre via brigde-nettverk (Docker normalt gjør dette automatisk via iptables NAT).

**Konsekvens:** Bind alltid containere til `127.0.0.1:port` eller mesh-interfacet:

```yaml
# docker-compose.yml
services:
  app:
    ports:
      - "127.0.0.1:8080:8080"   # kun lokalt
      # eller
      - "100.64.x.y:8080:8080"  # tailscale IP
```

Reverse proxy på samme host (Caddy, Nginx) kan så binde til mesh-interfacet og route innover til localhost-porten.

### `"ip-forward": false`

Tilsvarende prinsipp. Docker default skrur på `net.ipv4.ip_forward=1` på hosten. Hvis du ikke trenger det (single host, ingen container-til-container routing utover bridge), la det stå av.

### `"userns-remap": "default"`

User namespace remapping. Container-root mappes til en non-root UID på hosten (typisk i 100000-range). Hvis en container escapes via en kernel-bug, har angriperen UID 100000 på hosten, ikke 0.

**Krav:** `/etc/subuid` og `/etc/subgid` må ha entries for `dockremap`-brukeren. Docker setter dette opp automatisk ved første start med `userns-remap` aktivert.

**Trade-offs:** Volumes mounted fra host får annen ownership-mapping (en fil eid av root på hosten ser ut som UID 100000+root i containeren). Dette bryter noen images som forventer å kunne chown til arbitrary IDs. Hvis en spesifikk container må kjøre uten remapping, override per-container med `--userns=host`.

### `"no-new-privileges": true`

Setter `no_new_privs` flag på alle containere. Effekt: ingen setuid-binær inne i containeren kan eskalere privilegier. Det blokkerer en hel kategori container-escape-teknikker.

**Trade-offs:** Noen containere (sshd, nogle init-systemer i container, sudo-baserte mønstre) kan brekke. Override per-container med `security_opt: [no-new-privileges:false]` hvis du må — men forklar i kommentaren hvorfor.

### `"log-driver": "journald"`

Default `json-file` driver lagrer logs i `/var/lib/docker/containers/<id>/<id>-json.log`. Den filen vokser ubegrenset om du ikke setter `max-size`/`max-file`. Disken fyller seg, kernel OOM-killer dreper random prosesser, og du våkner til en død server.

`journald` ship logs til systemd-journal som har innebygd rotasjon, kompresjon, og persistens-policy. Det integrerer også med `journalctl` — du kan filtrere på container-navn:

```bash
journalctl CONTAINER_NAME=myapp -f
```

### `"live-restore": true`

Containere fortsetter å kjøre når `docker.service` restartes. Kritisk for sikkerhetsoppdateringer av Docker selv — du kan oppgradere uten å ta ned alle containere samtidig.

### `"metrics-addr": "127.0.0.1:9323"`

Hvis du noen gang vil scrape Prometheus-metrics fra Docker engine, lytter den på 127.0.0.1:9323 (loopback only). Default i mange tutorials er 0.0.0.0:9323 — det eksponerer container-metadata til alle som kan nå porten.

## Compose-best practices for hardening

`app-deploy/docker-compose.yml.example` viser mønsteret. Hovedpoeng:

1. **`read_only: true`** på containerens rotfilesystem
2. **`tmpfs:`** for /tmp og andre writable områder
3. **`security_opt:`** med `no-new-privileges:true` og `seccomp=` profil
4. **`cap_drop: [ALL]`** og deretter `cap_add: [<bare det du trenger>]`
5. **`user: "1000:1000"`** istedet for default root-i-container
6. **`networks:`** med eksplisitte definerte nettverk, ikke default bridge

## Rootless Docker — vurdert og forkastet (for nå)

Rootless Docker (kjør Docker daemon som non-root) er mer sikkert i prinsippet. I praksis i 2026:

- Krever cgroups v2 (OK på Ubuntu 24.04)
- Krever `slirp4netns` for nettverksvirtualisering — slower than vanilla
- Bryter noen volume-mounts og host-binding scenarios
- Compose v2 fungerer, men noen plugins (Buildkit features) er begrensede

For denne lab-konteksten (single-VPS hobby/portfolio), er `userns-remap` + cap_drop + read_only en god balanse. For større prod, vurder rootless Docker eller en annen runtime helt (containerd direkte, eller en sandbox som gVisor/Kata Containers).

## Sources

- Docker security documentation: https://docs.docker.com/engine/security/
- Docker daemon.json reference: https://docs.docker.com/reference/cli/dockerd/
- "Containers in Production" by Ian Lewis (Google) — for rootless tradeoffs
- Aqua Security: trivy + docker-bench-security for scanning images and engine
