# Threat Model — Public-Facing VPS

**Scope:** Linux VPS instances rented from generic providers (Hetzner, DigitalOcean, Linode, OVH, Scaleway, AWS Lightsail, Azure B-series, etc.) hosting personal projects, demos, side-projects, and small production services.

**Out of scope:** Enterprise infrastructure, regulated workloads (PCI/HIPAA/finanstilsyn-overvåkede), multi-tenant systems, or anything where the answer to "is this compliance-relevant?" is yes.

## Cross-reference

This threat model extends `networking/zero-trust-designs/ssh-hardening/THREAT-MODEL.md`. The SSH-specific actor classes (A1–A5) still apply. This document adds VPS-specific concerns.

## Additional actors and capabilities

### B1 — Mass-scanning botnet
- **Activity:** Scans entire IPv4 ranges hourly, fingerprints services, attempts known exploits against any open port. The current generation targets primarily SSH (22), HTTP/S (80, 443), Redis (6379), Docker API (2375/2376), Postgres (5432), and various VPN endpoints. New ports get added within hours of a CVE landing.
- **Capability:** Low per-host but enormous in aggregate. Operates in seconds, not days.
- **Mitigated by:** No public ports, period. VPN mesh ingress only.
- **MITRE:** T1595 (Active Scanning), T1190 (Exploit Public-Facing Application)

### B2 — Cryptojacker post-exploitation kit
- **Activity:** When a vulnerable service is exploited, the kit installs cryptominers, persists via cron/systemd, and joins a botnet C2. Often the second stage after a successful B1 scan finds a misconfigured Redis or Docker socket.
- **Capability:** Automated, no human in the loop. Kits are commodity.
- **Mitigated by:** No exposed services that lead to exploitation. Container hardening prevents escape if a containerized service IS exploited. Egress filtering catches C2 callbacks.
- **MITRE:** T1496 (Resource Hijacking), T1071.001 (Application Layer Protocol)

### B3 — Cloud credential harvester
- **Activity:** Specifically targets cloud VMs. Once on the host, queries instance metadata service (169.254.169.254) for IAM role credentials, then pivots into the cloud account itself. AWS-specific tools are mature (e.g., scanning for `~/.aws/credentials`, hitting IMDSv1).
- **Capability:** Targeted post-exploitation, often manual.
- **Mitigated by:** IMDSv2 only (token-required) on AWS, no role attached unless needed, host-level egress control to metadata IP.
- **MITRE:** T1552.005 (Cloud Instance Metadata API), T1078.004 (Cloud Accounts)

### B4 — Supply-chain attack on app dependencies
- **Activity:** A package the application installs (npm, PyPI, container base image) is compromised. Code runs at install time (npm postinstall, Python setup.py) or at runtime, exfiltrates secrets, opens reverse shell.
- **Capability:** Can be zero-day quality. Sometimes detected within hours, sometimes within months.
- **Mitigated by:** Lockfile verification, SBOM generation, `npm audit`/`pnpm audit`, running containers as non-root, read-only filesystems, restricted egress.
- **MITRE:** T1195.002 (Compromise Software Supply Chain)
- **Cross-ref:** Bachelor thesis context — this is the same attack class.

### B5 — Drive-by web exploit
- **Activity:** If the VPS hosts a web app, attacks the app itself. SQL injection, RCE, SSRF, deserialization. A successful hit gives shell as the app user.
- **Capability:** Wide-spectrum, automated for known CVEs, manual for novel apps.
- **Mitigated by:** Web app security (out of scope here), defense-in-depth via container isolation, restricted file system writes, egress filtering.
- **MITRE:** T1190

### B6 — Provider control plane compromise
- **Activity:** Hyperscaler or VPS provider's own systems compromised. Customer instances, snapshots, or credentials accessed.
- **Capability:** Rare but high-impact when it happens.
- **Mitigated by:** Encrypted disks, secrets in HSM-backed services not on disk, separate trust domains for cloud accounts vs. local infrastructure.
- **Realistic:** Low probability for me personally. Documented for completeness.
- **MITRE:** T1199 (Trusted Relationship)

## Trust boundaries

The bootstrap establishes the following trust boundaries:

```
[ Public Internet ]                                          (untrusted)
        ↓
        ↓ only one port open: VPN listener (Tailscale/WireGuard)
        ↓
[ VPN Mesh Network ]                                         (trusted client identity)
        ↓
        ↓ only authenticated mesh peers can reach
        ↓
[ VPS Host ]                                                  (boundary 1)
        ↓
        ↓ Docker Engine (rootless or rootful with hardening)
        ↓
[ Container ]                                                 (boundary 2)
        ↓
        ↓ Application as non-root, read-only FS, restricted syscalls
        ↓
[ Application Process ]                                       (boundary 3)
```

Each boundary is a separate compromise that an attacker has to cross. B1 (mass scanner) is stopped at the public-internet boundary. B5 (web exploit) compromises only boundary 3, doesn't automatically reach the host. B4 (supply chain) lands inside boundary 3 and has to escape through container hardening to reach the host.

## What this bootstrap does NOT defend against

Be honest:

- **Compromised provider hardware.** If the VPS host's hypervisor is compromised, encrypted disks help but don't fully solve it.
- **DNS hijacking of dependencies.** If the npm/PyPI mirror is compromised at DNS level on the way to the VPS, lockfile integrity catches it but only if you actually verify hashes.
- **Long-running mesh-peer compromise.** If your laptop is compromised and mesh-authenticated, the VPS sees a legitimate connection. Detection requires endpoint security on the laptop, which is a separate concern.
- **Application-layer attacks.** Web app vulnerabilities are not addressed here. The bootstrap creates a hardened platform for the app; it does not make the app secure.
- **Insider attacks at provider.** A rogue employee at the VPS provider with access to host or storage. Mitigated only by encryption + ephemeral workloads.

## Acceptance criteria

The bootstrap is "done" when, on a fresh VPS:

1. `nmap -Pn <vps-public-ip>` from a non-mesh source returns either nothing (mesh-only) or only the VPN listener port
2. `ssh <vps-public-ip>` from a non-mesh source returns "Connection refused" or times out
3. `ssh <vps-mesh-ip>` from a mesh peer succeeds with publickey only
4. `docker run --rm alpine ps -ef` shows the container running as expected, but `docker run --privileged ...` is blocked by policy
5. `unattended-upgrades --dry-run --debug` shows pending security updates being processed
6. `systemctl status fail2ban` shows it active, and `fail2ban-client status sshd` shows it tracking
7. `journalctl -u ssh -n 50` shows ed25519 fingerprints in successful auth lines (LogLevel VERBOSE inherited from SSH lab)

If any of these fail, the bootstrap is not complete.

## Review schedule

- After each VPS provider change (new image, new region, new instance type)
- After major OS version upgrade (Ubuntu 24.04 → 26.04)
- After mesh-tool change (Tailscale version with breaking changes, or migrating to Headscale)
- Annually regardless: 2026-05-05 → 2027-05-05
