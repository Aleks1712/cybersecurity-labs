# Teori — NSM 3.2 Etabler sikkerhetsovervåkning

## Hvorfor sikkerhetsovervåkning er den dyreste sikkerhetsinvesteringen man kan utelate

Sikkerhetsbransjen har et velkjent fenomen: virksomheter bruker store budsjetter på preventive tiltak (firewall, EDR, hardening) men sparer på detection og response. Resultatet er at de fleste reelle kompromisser går uoppdaget i lange perioder. Mandiant M-Trends og IBM Cost of a Data Breach rapporterer år etter år at median dwell time (tid fra kompromiss til oppdagelse) er målt i uker, ikke timer.

NSM 3.2 adresserer dette. Hardening (kategori 2) reduserer angrepsflate. Detection (kategori 3) krymper dwell time. Begge må til. Et system uten hardening er enkelt å kompromittere. Et system uten detection er enkelt å holde kompromittert.

## Hva NSM 3.2 konkret krever

Paraphrased fra NSM Grunnprinsipper v2.1, prinsipp 3.2:

Virksomheten skal etablere sikkerhetsovervåkning av sine IKT-systemer for å oppdage avvik fra normaltilstand og potensielle sikkerhetshendelser. Overvåkningen må omfatte både teknisk telemetri fra systemer og applikasjoner, og bruksmønstre fra brukere. Logger skal beskyttes mot uautorisert endring eller sletting, og lagres lenge nok til å støtte etterforskning.

Underliggende tiltak (NSM v2.1):

- **3.2.1** — Fastsett virksomhetens strategi og retningslinjer for sikkerhetsovervåkning
- **3.2.2** — Følg lover, reguleringer og virksomhetens retningslinjer
- **3.2.3** — Avgjør hvilke deler av IKT-systemet som skal overvåkes
- **3.2.4** — Beslutt hvilke data som er sikkerhetsrelevant og bør samles inn
- **3.2.5** — Verifiser at innsamling fungerer etter hensikt
- **3.2.6** — Påse at innsamlet data ikke kan manipuleres
- **3.2.7** — Gjennomgå og konfigurer innhenting jevnlig

## Pyramide av telemetri

David Bianco's "Pyramid of Pain" beskriver hvor smertefullt det er for en angriper når en detection treffer på ulike nivåer av indikatorer:

```
                    /\
                   /  \    TTPs (taktikker, teknikker, prosedyrer)
                  /    \   ← VELDIG vondt for angriper
                 /------\
                /        \  Tools
               /          \ ← vondt
              /------------\
             /              \  Network/Host artifacts
            /                \ ← noe vondt
           /------------------\
          /                    \  Domain names
         /                      \ ← lett å bytte
        /------------------------\
       /                          \  IP addresses
      /                            \ ← veldig lett å bytte
     /------------------------------\
    /                                \  Hash values
   /__________________________________\ ← trivielt å bytte
```

Detection som hviler på IP/hash-blacklists (bunn) er rask å implementere men trivielt å omgå. Detection som hviler på TTPs (topp) er vanskelig å skrive men nesten umulig å omgå uten å bytte attack methodology.

NSM 3.2 ber implisitt om at virksomheten beveger seg oppover pyramiden over tid. Tidlig: bare logge alt. Senere: skrive deteksjonsregler basert på taktikker, ikke bare IP-adresser.

## Detection-engineering som disiplin

"Detection engineering" er det relativt nye fagfeltet rundt å systematisk utvikle, vedlikeholde og evaluere deteksjoner. Hovedaksiomer:

### 1. En detection er en hypotese

Hver detection-regel uttrykker en hypotese: "hvis denne mønsteret observeres, er det sannsynlig at noe ondskapsfullt skjer." Hypotesen kan være feil (false positive) eller savne (false negative). Begge må måles.

### 2. False positives er ikke fri

Hver false positive koster operatør-tid. En detection som genererer 100 alerts per dag hvor 99 er FP, er en detection som ikke vil bli sjekket — operatøren har sluttet å lese den. Den er da effektivt en false negative for de tilfeller den faktisk ville fanget.

### 3. False negatives er konfidens-skadelige

Hvis en detection går glipp av en kompromittering som senere oppdages på annen måte, taper du tillit til hele detection-stacken. Postmortem må svare "hvorfor fanget vi ikke dette?".

### 4. Detection-as-code

Detections skal være versjonskontrollert, reviewable, testbar — på samme måte som applikasjonskode. Sigma-formatet eksisterer for å gjøre dette mulig på tvers av SIEM-leverandører.

## Sigma — det rammeverks-uavhengige formatet

Sigma er for detection hva yara er for malware-signaturer: et åpent format som kan oversettes til SIEM-spesifikke språk. Når jeg skriver en detection som Sigma:

```yaml
detection:
  selection:
    EventType: 'authentication_failure'
  condition: selection
```

...kan den konverteres til:
- KQL (Microsoft Sentinel)
- SPL (Splunk)
- LogQL (Loki / Grafana)
- Elastic ES|QL
- Wazuh rules
- og 20+ andre

Verdien er to-fold:
1. **Portabilitet.** Hvis virksomheten bytter SIEM, følger reglene med.
2. **Community-deling.** SigmaHQ-prosjektet har 3000+ regler tilgjengelig som starting points.

Lab-en bruker Sigma som primær-format og leverer KQL og SPL som derived implementations.

## MITRE ATT&CK som taksonomi

Hver detection bør tagges med MITRE ATT&CK-teknikker den oppdager. Dette gir tre fordeler:

1. **Coverage tracking.** Hvilke teknikker har vi detection for, hvilke har vi ikke?
2. **Threat-informed defense.** Hvis trusselbildet skifter (f.eks. APT29 bruker oftere T1078.004), kan virksomheten prioritere coverage av de teknikkene de mangler.
3. **Felles språk.** En SOC-analytiker som ser "T1098.004 utløst" vet umiddelbart at det handler om SSH authorized_keys persistence.

Hver Sigma-regel i `sigma-rules/` har `tags:`-blokk med ATT&CK-mapping.

## Logger som bevis vs. logger som telemetri

To distinkte bruksområder:

**Telemetri:** Real-time/near-real-time signaler for detection og operasjonell overvåkning. Kan miste enkelte events uten katastrofe. Optimaliseres for query speed.

**Bevis (forensic):** Komplett historikk for etterforskning etter en hendelse. Må ikke miste events. Må være tukle-resistant. Optimaliseres for integrity og retention.

Disse trenger ofte ulike storage-strategier. Telemetri går til SIEM med 30-90 dagers retention. Bevis går til immutable cold storage med 1-7 års retention, ofte WORM (write-once-read-many).

NSM 3.2.6 ("påse at innsamlet data ikke kan manipuleres") er primært en bevis-kvalitets-krav.

## Hva 3.2 forutsetter at allerede er på plass

Detection krever at telemetrien finnes. Hvis sshd kjører med `LogLevel ERROR`, kan ingen detection finne ut hvilken nøkkel som ble brukt for autentisering — det er aldri logget. Detection-engineering avhenger av at hardening (kategori 2) har slått på riktig logging.

Sjekkpunkt: før jeg skriver en detection-regel, må jeg verifisere at log-kilden faktisk inneholder feltet jeg query-er på.

For lab-en betyr dette:
- `LogLevel VERBOSE` i sshd_config.d/40-audit.conf (i ssh-hardening) → muliggjør key fingerprint logging
- auditd watches på sshd_config og authorized_keys (i vps-bootstrap) → muliggjør tampering detection
- Docker daemon med `"log-driver": "journald"` → muliggjør container-event correlation

Uten disse hardening-valgene har vi ingen telemetri å detektere på.

## Hva 3.2 IKKE løser alene

Detection er nødvendig men ikke tilstrekkelig. Det må kobles til:

- **3.3 Analyser data fra sikkerhetsovervåkning** — noen må faktisk se på alertene
- **4.1-4.3 Hendelseshåndtering** — alert er ikke en handling, det må føre til respons
- **2.10 Endringshåndtering** — for å skille legitim aktivitet fra mistenkelig

Et alert som ingen ser, ingen reagerer på, og som ikke kan korreleres med change tickets, er bare støy.

## Sources

- NSM Grunnprinsipper v2.1, prinsipp 3.2
  https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/oppdage/etabler-sikkerhetsovervakning/
- Mandiant M-Trends rapport (årlig)
- IBM Security Cost of a Data Breach Report (årlig)
- David Bianco — "Pyramid of Pain" (2013, fortsatt referansemodell)
- SigmaHQ — https://sigmahq.io
- MITRE ATT&CK Enterprise — https://attack.mitre.org/
