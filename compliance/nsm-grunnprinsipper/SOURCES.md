# Sources — NSM Grunnprinsipper-laben

Komplett kildeliste for hele lab-serien. Organisert per dokument-type. All sitering er paraphrased — ingen verbatim-quotes lengre enn de NSM gir under fair-use-grenser.

## Primary — NSM-dokumentasjon

- **NSM Grunnprinsipper for IKT-sikkerhet versjon 2.1** (juni 2024)
  Web: https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/
  PDF: https://nsm.no/getfile.php/1313975-1717589722/NSM/Filer/Dokumenter/Veiledere/NSMs%20Grunnprinsipper%20for%20IKT-sikkerhet%20v2.1.pdf
  Kategori-spesifikke sider:
  - 1. Identifisere og kartlegge: https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/identifisere-og-kartlegge/
  - 2. Beskytte og opprettholde: https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/
  - 3. Oppdage: https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/oppdage/
  - 4. Håndtere og gjenopprette: https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/handtere-og-gjenopprette/

- **NSM ICT Security Principles (English)**
  https://nsm.no/advice-and-guidance/publications/nsm-ict-security-principles

- **JustisCERT — NSM Grunnprinsipper-oversikt**
  https://www.justiscert.no/aktuelt/nsm-grunnprinsipper-for-ikt-sikkerhet

- **SINTEF-rapport: Grunnprinsipper for IKT-sikkerhet i industrielle IKT-systemer** (2021)
  https://www.havtil.no/globalassets/fagstoff/prosjektrapporter/ikt-sikkerhet/id4-grunnprinsipper-for-ikt-sikkerhet_sintef-rapportnr-2021-00055-feb---signert.pdf
  Brukt for OT-relevans-analyse og NIST CSF cross-walk.

## Internasjonale rammeverk

- **NIST Cybersecurity Framework 2.0** (februar 2024)
  https://www.nist.gov/cyberframework

- **NIST SP 800-53 Rev. 5** — Security and Privacy Controls
  https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final

- **NIST SP 800-128** — Guide for Security-Focused Configuration Management
  https://csrc.nist.gov/publications/detail/sp/800-128/final

- **NIST SP 800-207** — Zero Trust Architecture
  https://csrc.nist.gov/publications/detail/sp/800-207/final

- **NIST SP 800-61 Rev. 2** — Computer Security Incident Handling Guide
  https://csrc.nist.gov/publications/detail/sp/800-61/rev-2/final

- **ISO/IEC 27002:2022** — Information security controls
  https://www.iso.org/standard/75652.html
  (Paywalled; used for cross-walk reference based on summary tables.)

- **CIS Distribution Independent Linux Benchmark v2.0.0**
  https://www.cisecurity.org/benchmark/distribution_independent_linux

- **CIS Critical Security Controls v8**
  https://www.cisecurity.org/controls/v8

## Detection-engineering ressurser

- **Sigma rule format** — https://github.com/SigmaHQ/sigma
- **MITRE ATT&CK Enterprise** — https://attack.mitre.org/
- **MITRE D3FEND** — https://d3fend.mitre.org/
- **David Bianco — "Pyramid of Pain"** — http://detect-respond.blogspot.com/2013/03/the-pyramid-of-pain.html

## Hardening-veiledere

- **Mozilla OpenSSH Guidelines** — https://infosec.mozilla.org/guidelines/openssh
- **OpenSSH `sshd(8)` manpage**
- **Docker security documentation** — https://docs.docker.com/engine/security/

## Bøker

- "Zero Trust Networks" — Evan Gilman & Doug Barth, O'Reilly 2017
- "Practical Threat Intelligence and Data-Driven Threat Hunting" — Valentina Costa-Gazcón
- "Container Security" — Liz Rice, O'Reilly 2020

## Industri-rapporter (årlige)

- Mandiant M-Trends
- IBM Security Cost of a Data Breach Report
- Verizon Data Breach Investigations Report (DBIR)

## Norsk kontekst

- **Sikkerhetsloven** (LOV-2018-06-01-24)
- **Digitalsikkerhetsloven** (LOV-2024-...)
- **Datatilsynets veiledere** — https://www.datatilsynet.no/

## Citation-filosofi

Hvert dokument i lab-serien har en `## Sources`-seksjon i bunnen. Ved konkrete claims (f.eks. "ssh-audit grade A+", "118 tiltak i NSM v2.1") er kilden navngitt direkte. Tall som er reproduserbare via verktøy (ssh-audit, Lynis, nmap) er rapportert som lab-observasjoner uten ekstern citation, fordi de er empiriske.

NSM-rammeverket selv siteres med URL og versjon (v2.1), ikke med side-tall, fordi dokumentet finnes både som PDF og som strukturert nettside.
