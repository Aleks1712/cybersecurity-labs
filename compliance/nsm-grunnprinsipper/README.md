# NSM Grunnprinsipper for IKT-sikkerhet — Praktisk anvendelse

**Dato:** 2026-05-05
**Pillar:** cybersec / compliance (cross-cuts cloud, networking, kubernetes)
**Basert på:** NSM Grunnprinsipper for IKT-sikkerhet versjon 2.1 (publisert 31. mai 2024)
**Kilde:** https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/

## Hva er nytt i v2.1 (relevant for denne lab-serien)

NSM Grunnprinsipper v2.1 er hovedsakelig en oppdatering av v2.0 (april 2020), ikke en strukturell omskriving. De viktigste endringene som påvirker lab-serien:

- **"Hvitelisting" → "godkjentlisting"** som offisielt norsk begrep. Engelske ekvivalenter (`allowlist`, `allowlisting`) brukes fortsatt i kode og kommentarer fordi det er det internasjonale tekniske begrepet.
- **Tiltak 2.3.2 — presisering om eksekvering vs. installering.** En kritisk nyanse: programvare trenger ikke være installert for å kjøre. Lab-en (2-3-sikker-konfigurasjon) reflekterer dette i hvordan applikasjons-godkjentlisting er beskrevet.
- **Tiltak 2.4.1 — presisering om nettverksporter.** v2.1 spesifiserer at "porter" omfatter fysiske, trådløse og virtuelle. Lab-en (2-4-beskytt-nettverk) tar opp alle tre i tiltaksmapping.

Disse endringene er små men presise — de viser at NSM oppdaterer rammeverket basert på reelle hendelser og endret trusselbilde. For en hiring manager: det at jeg vet hva som er nytt i v2.1 og hva det betyr i praksis, signaliserer at jeg leser kildedokumentet, ikke bare oppsummerer det.

## Hvorfor denne lab-serien finnes

NSM grunnprinsipper er det rammeverket norske offentlige virksomheter, kritisk infrastruktur, og store private selskaper faktisk bruker når de risikovurderer IKT-systemer. Datatilsynet refererer til det. Forsvaret bruker det. Helse-Norge, Statnett, kommunene, og leverandørene som driver dem mapper internt mot disse prinsippene fordi NSM er fagorgan for forebyggende sikkerhet.

Det meste som finnes på engelsk YouTube om "cloud security" eller "Linux hardening" mapper mot NIST eller MITRE. Det er nyttig, men det er ikke det språket som faktisk brukes i risikovurderinger som havner på et styrebord i Oslo. Denne lab-serien bygger bro: vi tar ekte teknisk arbeid (SSH-hardening, VPS-bootstrap, sikkerhetsovervåkning) og oversetter til NSM-rammeverket samtidig som vi kart-walk-er mot internasjonale rammeverk for de som trenger begge språk.

## Struktur

NSM v2.1 har 4 kategorier, 21 prinsipper, og 118 underliggende tiltak. Denne lab-serien dekker ikke alle 118. Den dekker tre prinsipper i dybden, pluss en master mapping-tabell som viser hvor andre labs i dette repoet treffer de øvrige prinsippene.

```
nsm-grunnprinsipper/
├── README.md                              # Du er her
├── master-mapping/                        # Oversikt: hvilke prinsipper dekker hvilke labs
│   ├── README.md
│   ├── mapping-tabell.md
│   ├── modenhetsvurdering.md
│   └── diagrams/
│       ├── kategorier-overview.svg
│       └── lab-til-prinsipp-mapping.svg
├── 2-3-sikker-konfigurasjon/              # Dybde-lab: NSM 2.3
│   ├── README.md
│   ├── teori.md
│   ├── praksis.md
│   ├── tiltaksmapping.md
│   ├── verifisering.md
│   ├── diagrams/
│   └── examples/
├── 2-4-beskytt-nettverk/                  # Dybde-lab: NSM 2.4
│   ├── README.md
│   ├── teori.md
│   ├── praksis.md
│   ├── tiltaksmapping.md
│   ├── diagrams/
│   └── examples/
└── 3-2-sikkerhetsovervakning/             # Dybde-lab: NSM 3.2
    ├── README.md
    ├── teori.md
    ├── praksis.md
    ├── tiltaksmapping.md
    ├── diagrams/
    ├── examples/
    ├── sigma-rules/
    ├── kql-queries/
    └── parsers/
```

## Hvorfor disse tre prinsippene først

**2.3 Ivareta en sikker konfigurasjon** — fordi jeg allerede har bygget arbeidet (`ssh-hardening` og `vps-bootstrap`-labene) som demonstrerer akkurat dette. Lab-en kobler eksisterende kode til NSM-tiltakene og viser hvordan moderne hardening-praksis faktisk implementerer det NSM ber om.

**2.4 Beskytt virksomhetens nettverk** — fordi VPN-mesh-arbeidet i `vps-bootstrap` er en konkret manifestering av zero-trust-prinsippet som NSM 2.4 forutsetter. Det viser at jeg forstår overgangen fra perimeter-basert til identitets-basert nettverkssikkerhet, som er der norsk offentlig sektor er på vei nå.

**3.2 Etabler sikkerhetsovervåkning** — fordi det fyller cybersec-pillaren samtidig, og fordi alle tre labs på "Beskytte"-siden uten en motsvarighet på "Oppdage"-siden er ufullstendig. En hiring manager som ser bare blue-team-deteksjon eller bare hardening tenker at kandidaten er enøyd. Begge sider, koblet sammen via samme rammeverk, viser systemtenking.

## Hva NSM-rammeverket faktisk er, og hva det ikke er

**Det er:**
- Et anbefalingssett, ikke en compliance-standard. NSM eksplisitt sier at virksomheter velger ut tiltak basert på egen risikovurdering.
- Bygget for norske forhold — peker mot sikkerhetsloven, digitalsikkerhetsloven, og sektorspesifikke krav (kraftberedskapsforskriften, finansforetaksloven).
- Praksisorientert — hvert prinsipp har konkrete tiltak, ikke bare prinsipp-prosa.

**Det er ikke:**
- Tilstrekkelig for sikkerhetslov-pliktige virksomheter. Sikkerhetsloven har strengere krav som ikke dekkes her.
- ISO 27001/27002. Det er beslektet, men ISO er prosess-standard mens NSM er teknisk anbefalingssett.
- Et erstatning for NIST CSF — de overlapper ~70%, og en SINTEF-analyse fra 2021 fant at NSM grunnprinsipper er 81% relevant for OT-systemer i petroleum, men at NIST CSF dekker ting NSM ikke gjør (særlig formell risk management).

## Modenhetsmodell — ærlig vurdering

For å være tro mot rammeverket må jeg være ærlig om hvor jeg står. NSM-tiltak kan vurderes på en skala (de bruker ikke en formell modenhetsmodell, men det implisitte er):

| Status | Hva det betyr |
|---|---|
| Implementert og verifisert | Tiltaket er på plass, dokumentert, og testet med målbart resultat |
| Implementert men ikke verifisert | På plass i konfig, men ingen test har bekreftet at det faktisk fungerer som forventet |
| Delvis implementert | Noe av tiltaket dekket, andre deler mangler eller er kompenserende |
| Ikke relevant | Tiltaket gjelder en sammenheng som ikke gjelder for min lab (f.eks. tiltak rettet mot store organisasjoner) |
| Ikke implementert | Bevisst eller ubevisst gap. Dokumenteres ærlig. |

Denne tabellen er fylt ut for hver dybde-lab i `tiltaksmapping.md`-filen.

## Ærlighet om scope

Disse labs er bygget for **personlig homelab og småskala VPS-deployment**. Skalaen som NSM-rammeverket egentlig er bygget for er virksomhets-IKT med tusenvis av brukere, formelle styringsstrukturer, og 24/7-drift. Når jeg mapper en homelab-tiltak til NSM 2.3.4 ("Ha en formell konfigurasjonsstandard"), er det demonstrerende, ikke ekvivalent. En reell virksomhet som "implementerer 2.3.4" har en ITIL-prosess, ikke et bash-script.

Det er greit. Lab-ens jobb er å vise at jeg forstår hva tiltaket forsøker å oppnå, og hvordan det manifesterer seg på teknisk nivå. Skalaspranget til virksomhets-IKT er en rolle-skala-spranget, ikke et forståelses-sprang.

## Sources

- NSM Grunnprinsipper for IKT-sikkerhet v2.1 (juni 2024)
  https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/
- NSM Grunnprinsipper PDF (2 MB)
  https://nsm.no/getfile.php/1313975-1717589722/NSM/Filer/Dokumenter/Veiledere/NSMs%20Grunnprinsipper%20for%20IKT-sikkerhet%20v2.1.pdf
- English version: NSM ICT Security Principles
  https://nsm.no/advice-and-guidance/publications/nsm-ict-security-principles
- SINTEF-rapport: Grunnprinsipper for IKT-sikkerhet i industrielle IKT-systemer (2021)
  https://www.havtil.no/globalassets/fagstoff/prosjektrapporter/ikt-sikkerhet/id4-grunnprinsipper-for-ikt-sikkerhet_sintef-rapportnr-2021-00055-feb---signert.pdf
- JustisCERT: NSM Grunnprinsipper-oversikt
  https://www.justiscert.no/aktuelt/nsm-grunnprinsipper-for-ikt-sikkerhet
