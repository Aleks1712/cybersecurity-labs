# Application Deployment

Etter at VPS-en er bootstrapped (steg 1-9 i `scripts/00-bootstrap.sh`), er det først nå du legger applikasjoner på den. Rekkefølgen er ikke tilfeldig — du legger ikke verdifulle ting på maskiner som fortsatt er åpne.

## Pre-deploy: verifiser supply chain

```bash
cd /path/to/your/app
bash /path/to/vps-bootstrap/app-deploy/verify-supply-chain.sh
```

Scriptet kjører:

1. **Trivy** mot alle Docker-images i `docker-compose.yml` for kjente CVEs
2. **`pnpm audit` / `npm audit` / `pip-audit`** mot dependencies
3. **Lockfile diff** — har noen rørt lockfilen siden siste commit?
4. **Postinstall-script-deteksjon** — npm-pakker med install-scripts er ikke automatisk farlige, men er en stor attack surface for supply-chain-angrep (thesis-relevant). Verdi i å vite hvor mange du har.
5. **SBOM** generert med syft (SPDX-format)
6. **Cosign** verifikasjon for image signatures (om de finnes)

Output i `supply-chain-reports/<timestamp>/`. Commit ikke disse — `.gitignore` dem.

## Deploy

```bash
# Kopier templaten og tilpass
cp docker-compose.yml.example docker-compose.yml

# Sett opp .env (chmod 600 — inneholder secrets)
cat > .env <<EOF
DB_USER=appuser
DB_PASSWORD=$(openssl rand -hex 32)
DB_NAME=app
APP_IMAGE=ghcr.io/yourname/yourapp:v1.2.3
EOF
chmod 600 .env

# Replace 100.64.x.y med din faktiske tailscale/wg IP
# Sjekk: tailscale ip -4   eller   wg show wg0

# Validate compose
docker compose config

# Start
docker compose up -d

# Verifiser
docker compose ps
docker compose logs -f
```

## Hva templaten har bakt inn

- **Read-only rotfilesystem** for app-containeren. tmpfs for /tmp.
- **Non-root user** (`user: "1000:1000"`) — viktig at image-en er bygget for å støtte dette
- **`cap_drop: [ALL]`** og kun det DB faktisk trenger
- **`security_opt: [no-new-privileges:true]`** — ingen setuid-eskaleringsvei
- **Resource limits** så en runaway container ikke OOM-killer hosten
- **Healthchecks** så `restart: unless-stopped` faktisk vet hva "broken" betyr
- **Separat `frontend` og `backend` nettverk** — caddy kan ikke nå DB direkte (defense-in-depth: caddy compromise → ikke automatisk DB compromise)
- **`internal: true`** på backend-nettverket — ingen utgående internett fra DB-laget
- **Mesh-bound publish** (`100.64.x.y:80:80` istedet for `0.0.0.0:80:80`) så portene ikke leaker offentlig hvis daemon.json `iptables: false` skulle bli reset

## Hva templaten IKKE har

- **Specific app image.** Du må bygge eller velge din egen.
- **TLS-konfig.** Caddy gjør ACME automatisk, men du må peke DNS til mesh-IP-en din eller en exit-node.
- **Backup-strategi.** Egen lab.
- **Monitoring/observability.** Egen lab — Prometheus/Grafana eller Loki via Docker.

## Vanlige fallgruver

1. **`user: "1000:1000"` bryter image-en din.** Hvis Dockerfile-en din har `USER root` eller forventer å skrive til `/var/log` eller lignende, må du enten endre image-en (anbefalt) eller fjerne `user`-direktivet (mindre sikkert).

2. **`read_only: true` bryter image-en din.** Hvis app-en skriver til `/run`, `/var/cache`, `/etc/something`, må du legge til tmpfs eller volumes for de stiene. Logg som tipper kan diagnostisere: `docker compose logs app | grep -i "permission denied\|read-only"`.

3. **`internal: true` bryter ACME**. Hvis backend-tjenester trenger å kalle ut (f.eks. for CRL/OCSP, OAuth callbacks), kan ikke `internal: true` være på. Vurder `egress`-policy via en explicit gateway istedet.

4. **`cap_drop: [ALL]` med Postgres bryter det.** Postgres trenger SETUID/SETGID for sin internal user-dropping. Templaten har dette bakt inn for db-tjenesten — ikke fjern det.

## Cross-references

- SSH-hardening: `networking/zero-trust-designs/ssh-hardening/`
- Docker daemon hardening: `../docker/`
- UFW configuration: `../ufw/`
- Threat model: `../THREAT-MODEL.md`

## Sources

- Docker Compose security best practices: https://docs.docker.com/compose/production/
- OWASP Docker Security Cheat Sheet
- Aqua Security: docker-bench-security audit checklist
- Sigstore documentation (cosign): https://docs.sigstore.dev/
