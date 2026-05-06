# Sources

Alle eksterne kilder denne lab-en bygger på. Per repo-konvensjonen ingen verbatim-paragrafer; alt er paraphrased og krediteres her.

## OpenSSH offisiell dokumentasjon
- `ssh(1)`, `sshd(8)`, `ssh_config(5)`, `sshd_config(5)` man pages, OpenSSH 9.6
- https://www.openssh.com/manual.html
- https://www.openssh.com/releasenotes.html

## Hardening-guider
- Mozilla OpenSSH guidelines, Modern profile
  https://infosec.mozilla.org/guidelines/openssh
- ssh-audit project — algorithm policies and rationale
  https://github.com/jtesta/ssh-audit
- Stribika SSH guide (historisk referanse, dated men nyttig for KEX-rasjonale)
  https://stribika.github.io/2015/01/04/secure-secure-shell.html

## Standards og frameworks
- NIST SP 800-53 Rev. 5, controls AC-17, IA-2, SC-12, AU-12
  https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final
- NIST SP 800-207 Zero Trust Architecture
  https://csrc.nist.gov/publications/detail/sp/800-207/final
- ISO/IEC 27002:2022, clauses 8.5, 8.20, 8.21
- CIS Distribution Independent Linux Benchmark v2.0.0, section 5.2
  https://www.cisecurity.org/benchmark/distribution_independent_linux

## Adversary frameworks
- MITRE ATT&CK Enterprise v15 — techniques T1021.004, T1098.004, T1110, T1556, T1195.002, T1552.004, T1563.001
  https://attack.mitre.org/
- MITRE D3FEND — defensive techniques mapping
  https://d3fend.mitre.org/

## Post-quantum SSH
- IETF draft-ietf-sshm-ssh-pq (work in progress)
  https://datatracker.ietf.org/wg/sshm/about/
- OpenSSH release notes for 9.0 (sntrup761x25519 introduction) and 9.5+ updates
  https://www.openssh.com/txt/release-9.0

## FIDO2 / hardware-backed SSH
- OpenSSH FIDO/U2F documentation
  https://www.openssh.com/agent-restrict.html
- YubiKey SSH guide
  https://developers.yubico.com/SSH/

## Norwegian context
- NSM grunnprinsipper for IKT-sikkerhet
  https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/grunnprinsipper-for-ikt-sikkerhet-2-0/
