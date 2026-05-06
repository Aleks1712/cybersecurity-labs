# Sources

Eksterne kilder for hele vps-bootstrap-laben. Per repo-konvensjonen ingen verbatim-paragrafer, alt paraphrased.

## OS og pakkesystemer

- Ubuntu Server Guide — Security and Networking sections
  https://ubuntu.com/server/docs
- Debian Administrator's Handbook
  https://debian-handbook.info/
- `unattended-upgrades` documentation
  https://wiki.debian.org/UnattendedUpgrades

## Firewall og nettverk

- UFW manual page (`man ufw`)
- nftables documentation
  https://wiki.nftables.org/
- Linux netfilter project
  https://www.netfilter.org/

## VPN mesh

- Tailscale documentation
  https://tailscale.com/kb/
- Tailscale + UFW integration
  https://tailscale.com/kb/1077/secure-server-ubuntu
- WireGuard documentation
  https://www.wireguard.com/
- WireGuard whitepaper (kryptografi-rasjonale)
  https://www.wireguard.com/papers/wireguard.pdf
- Headscale (selvhostet Tailscale-kontrollplan)
  https://github.com/juanfont/headscale

## Container security

- Docker security best practices
  https://docs.docker.com/engine/security/
- Docker daemon.json reference
  https://docs.docker.com/reference/cli/dockerd/
- Aqua Security: docker-bench-security
  https://github.com/docker/docker-bench-security
- Trivy (container scanner)
  https://github.com/aquasecurity/trivy
- Sigstore / cosign
  https://docs.sigstore.dev/

## Standards og frameworks

- NIST SP 800-53 Rev. 5
  https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final
- NIST SP 800-207 Zero Trust Architecture
  https://csrc.nist.gov/publications/detail/sp/800-207/final
- NIST SP 800-190 Application Container Security Guide
  https://csrc.nist.gov/publications/detail/sp/800-190/final
- CIS Distribution Independent Linux Benchmark v2.0.0
  https://www.cisecurity.org/benchmark/distribution_independent_linux
- ISO/IEC 27002:2022

## Adversary frameworks

- MITRE ATT&CK Enterprise — techniques referenced:
  T1190 (Exploit Public-Facing Application)
  T1133 (External Remote Services)
  T1110 (Brute Force)
  T1078.004 (Cloud Accounts)
  T1496 (Resource Hijacking)
  T1552.005 (Cloud Instance Metadata API)
  T1195.002 (Compromise Software Supply Chain)
  T1199 (Trusted Relationship)
  T1595 (Active Scanning)
  https://attack.mitre.org/

- MITRE D3FEND — defensive techniques mapping
  https://d3fend.mitre.org/

## Cross-references til andre labs i repoet

- `networking/zero-trust-designs/ssh-hardening/` — SSH-spesifikk hardening
- `cybersec/sigma-rules/` — detection rules som matcher denne stack-en (planlagt)
- `kubernetes/runtime-security/` — runtime-detection for container-eskalering (planlagt)
