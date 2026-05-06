# Modenhetsvurdering

Som dokumentert i master-mapping-en, er dekningen av NSM-prinsippene ikke jevn på tvers av kategorier. Dette dokumentet forklarer hvorfor og hva som driver prioriteringen.

## Dekningsgrad per kategori

```
Kategori 1 (Identifisere):   ░░░░░░░░░░ 20%   — virksomhets-skala konsepter
Kategori 2 (Beskytte):       ████████░░ 80%   — der teknisk arbeid skjer
Kategori 3 (Oppdage):        ████░░░░░░ 50%   — påbegynt, må bygges ut
Kategori 4 (Håndtere):       ██░░░░░░░░ 25%   — krever organisasjon, ikke kode
```

## Hvorfor denne fordelingen

NSM-rammeverket er bygget for hele organisasjoner — toppledelse, sikkerhetsledere, IT-drift, applikasjonsutviklere. Et hjemmelab-portfolio kan demonstrere godt den tekniske kjernen (Beskytte, Oppdage), men mye av Identifisere og Håndtere forutsetter ting som ikke gir mening solo:

- **Styringsstrukturer** (1.1) er ledelsesnivå
- **Formelt CMDB** (1.2) er virksomhets-skala
- **Incident response team og øvelser** (4.1, 4.4) krever flere mennesker

Dette er ikke en svakhet i portfolio-en — det er en realisme om hva en BSc-kandidat realistisk kan demonstrere. En hiring manager som leser dette tenker:

> "Kandidaten forstår at NSM-rammeverket er bredere enn det tekniske, og forstår hvor egne ferdigheter passer inn. Det er en mer voksen vurdering enn å fake-claime full dekning."

## Modenhetsmodell brukt her

NSM bruker ikke en formell modenhetsmodell (CMMI-style 1-5), men det implisitte kan beskrives slik:

### Nivå 1 — Ad-hoc
Tiltaket er ikke implementert, eller implementert sporadisk uten dokumentasjon. Risikoen er ikke vurdert.

### Nivå 2 — Reaktivt
Tiltaket er implementert som respons på hendelser. Det er ingen plan eller dokumentasjon, bare reaksjon.

### Nivå 3 — Definert
Tiltaket er dokumentert, implementert konsekvent, og har målbare kriterier for "fungerer det". Dette er nivået disse labs sikter mot for prinsipper de dekker.

### Nivå 4 — Styrt
Tiltaket har metrikker som spores over tid, og avvik utløser respons. Krever virksomhets-skala observability.

### Nivå 5 — Kontinuerlig forbedring
Tiltaket er underlagt kontinuerlig forbedring basert på trender, post-mortems, og threat landscape-endringer.

## Hvor labs ligger på modenhetsskalaen

| Prinsipp | Modenhet i mine labs | Hva som mangler for nivå 4 |
|---|---|---|
| 2.3 Sikker konfigurasjon | 3 (Definert) | Drift av konfigurasjon over tid (config drift detection) |
| 2.4 Beskytt nettverk | 3 (Definert) | East-west traffic analysis, DPI |
| 2.6 Identitet og tilgang | 3 (Definert) | IDP-integrasjon, regelmessig access review |
| 3.2 Sikkerhetsovervåkning | 2-3 (mellom Reaktivt og Definert) | SIEM med korrelasjon, threat hunting-program |
| 4.3 Kontroller hendelser | 2 (Reaktivt) | Incident response runbook, øvelser |

## Hva dette betyr i praksis

For en hiring manager: kandidaten dokumenterer ærlig at hjemmelab-arbeid topper ut på nivå 3 ("Definert") — som er der norske SMB faktisk er. Nivå 4-5 krever organisasjon, prosess, og budsjett som BSc-kandidat ikke kan demonstrere alene.

For meg: når jeg fyller ut roller-spesifikke jobbsøknader, kan jeg vise konkret hvilke prinsipper jeg har erfaring med på nivå 3, og hva jeg vil måtte lære i en virksomhetsrolle for å nå nivå 4.

## Sources

- NSM Grunnprinsipper v2.1, kapittel om "Forholdet mellom kategori, prinsipp og tiltak"
- CMMI for Services v1.3 (for inspirert maturity-thinking)
- ISO/IEC 21827 (SSE-CMM) — Systems Security Engineering Capability Maturity Model
