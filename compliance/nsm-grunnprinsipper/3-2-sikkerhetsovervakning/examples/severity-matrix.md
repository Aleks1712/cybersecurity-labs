# Severity Matrix — vurdering av alert-alvor

NSM 4.2 ber om at hendelser vurderes og klassifiseres. Denne matrisen kombinerer Sigma-rule severity med asset criticality og kontekstuelle faktorer for å gi en aksjon-prioritet (P1-P4).

## Aksjon-prioriteter

| Prioritet | Respons-tid | Hva det betyr |
|---|---|---|
| **P1** | Umiddelbart (under 1 time) | Aktiv kompromittering eller imminent. Avbryt annen aktivitet. |
| **P2** | Innen 4 timer | Sannsynlig kompromittering eller targeted attempt. Prioriter denne arbeidsdagen. |
| **P3** | Innen 24 timer | Mistenksom aktivitet som krever oppfølging, men ikke akutt. |
| **P4** | Innen 7 dager | Lavt-volum signal, eller noise-cleanup. Backlog. |

## Asset criticality klassifisering

| Klasse | Eksempler i lab-en | Beskrivelse |
|---|---|---|
| **High** | DB-container med persistente data, mesh-koordinator, prod-serverer | Kompromiss = høy impact (data, drift, identitet) |
| **Medium** | App-container, monitoring-stack, dev-/staging-server | Kompromiss = forstyrrelse, men ikke katastrofalt |
| **Low** | Sandbox, pure compute uten data, throwaway test-environment | Kompromiss = liten direkte impact |

For lab-en: det meste er Medium-Low. Database-container med persistent data er High.

## Severity matrix — Sigma-level mot asset criticality

|  Sigma-level → | **Critical** | **High** | **Medium** | **Low** | **Informational** |
|---|---|---|---|---|---|
| **High asset** | P1 | P1 | P2 | P3 | P4 |
| **Medium asset** | P1 | P2 | P3 | P3 | P4 |
| **Low asset** | P2 | P3 | P3 | P4 | P4 |

Eksempel: `docker-socket-access` (Sigma critical) på prod-DB (High asset) → P1, umiddelbar respons.
Samme alert på sandbox-container (Low asset) → P2, innen 4 timer.

## Kontekstuelle modifiers

Etter initial scoring kan disse heve eller senke prioriteten:

### Hever prioritet (+1 nivå)

- **Korrelasjon:** Alert er én av flere relaterte alerts på samme tidsvindu. Suggests campaign.
- **Pågående suksess:** SSH brute force-alerts fulgt av en `Accepted publickey` fra samme IP innen kort tid.
- **Asset er nylig kompromittert:** Hvis samme system har hatt alvorlig hendelse forrige 30 dager.
- **Off-hours:** Alert utenfor normal arbeidstid kan være tegn på angriper som unngår oppdagelse.
- **Geografi:** Source-IP fra land hvor du ikke har legitime brukere.

### Senker prioritet (−1 nivå)

- **Kjent maintenance window:** Match mot scheduled change.
- **Identifisert legitim aktør:** Operator eller service-account bekreftet å ha kjørt handlingen.
- **Kjent regel-FP:** Regelen har høy historisk FP-rate og ingen ny kontekst.

Modifiers kan ikke hopp over flere nivåer. P3 kan bli P2 eller P4, men ikke P1 fra én modifier alone.

## Eskaleringssti

Etter at prioritet er satt:

- **P1:** Til operatør umiddelbart (push notification, SMS, telefon). I virksomhet: SOC vakt-team.
- **P2:** Til operatør (e-post + chat). Skal håndteres samme arbeidsdag.
- **P3:** Til ticket-kø. Skal pickes opp i daglig stand-up eller første ledige sjekk.
- **P4:** Til ukentlig review.

For hjemmelab er "operatør" deg selv. For virksomhet finnes en formell on-call rotation.

## Rapportering oppover

P1-hendelser i virksomhet utløser typisk varsling oppover:

- Sikkerhetsleder (CISO) varslet umiddelbart
- Ledelse innen 4 timer hvis bekreftet
- Eksterne hvis nødvendig:
  - **NSM NCSC** for alvorlige hendelser i samfunnskritisk infrastruktur (per sikkerhetsloven § 6-3)
  - **Datatilsynet** ved personopplysningsbrudd (innen 72 timer per GDPR Art. 33)
  - **Politiet/Kripos** ved straffbare forhold
  - **Egen forsikring** ved cyber insurance-policy

For hjemmelab er ingen av disse aktuelle, men kunnskapen om når de skal varsles er en del av incident response-modenhet.

## Hva matrisen IKKE løser

Severity-vurdering er ikke en algoritme. Modifiers og kontekst krever menneskelig vurdering. To operatører kan komme til ulik prioritet for samme alert — det er normalt og hvorfor doble vurderinger og post-mortems eksisterer.

Matrisen er en starting point for konsistens, ikke en erstatning for vurdering.

## Cross-references

- For hva som triages før severity settes: `triage-playbook.md`
- For håndtering etter severity er satt: `response-playbook.md`
- For threat models som driver "hvor kritisk er dette assetet?": `vps-bootstrap/THREAT-MODEL.md`

## Sources

- NIST SP 800-61, kapittel 3.2.6 (Incident Prioritization)
- NSM Grunnprinsipper v2.1, prinsipp 4.2 (Vurder og klassifiser hendelser)
- SANS Incident Handler's Handbook
- ENISA Reference Incident Classification Taxonomy
