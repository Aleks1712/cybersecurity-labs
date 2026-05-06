# Teori — NSM 2.4 Beskytt virksomhetens nettverk

## Det store skiftet i nettverkssikkerhet

I rundt 20 år bygget vi nettverkssikkerhet på en geografisk metafor: det fantes et "innenfor" og et "utenfor", separert av en perimeter. Firewall var portvakt, VPN var nøkkelen som lot eksterne brukere komme "innenfor". En gang du var innenfor, kunne du nå mange ting fritt fordi den interne trafikken var "trygg".

Den modellen er død, og har vært det en stund. Tre ting drepte den:

1. **Cloud computing.** Når dine viktigste systemer kjører hos AWS, Azure, og GCP, er det ikke lenger meningsfullt å snakke om "innenfor virksomheten". Perimeteret er løst opp.

2. **Hjemmekontor og BYOD.** Etter 2020 er enheter som connecter til virksomhetens systemer geografisk og topologisk fordelt. En ansatt på hjemmenettet sitt med en jobbdatamaskin, eller en kontraktor som logger inn fra et coffee shop, passer ikke i "innenfor"-modellen.

3. **Lateral movement.** Reelle kompromisser de siste fem årene har vist at angripere som har én fot innenfor perimeteret bruker SSH agent forwarding, kompromitterte service accounts, eller stjålne credentials til å hoppe lateralt mellom systemer. Den interne trafikken er ikke trygg.

Svaret er zero-trust: hver request autentiseres uavhengig, ingen trafikk er privilegert basert på kilde alone, og segmentering betyr at en kompromittering på ett sted ikke automatisk betyr kompromittering andre steder.

## Hva NSM 2.4 konkret krever

Paraphrased fra NSM Grunnprinsipper v2.1, prinsipp 2.4:

Virksomheten skal beskytte sitt nettverk og kommunikasjonen mot uautorisert tilgang, og sikre at trafikk kun flyter dit den faktisk skal. Dette inkluderer å segmentere nettverket basert på risiko og funksjon, å kontrollere fjerntilgang, og å overvåke trafikk for å oppdage uønskede strømmer.

Underliggende tiltak (NSM v2.1):

- **2.4.1** — Etabler tilgangskontroll på flest mulige nettverksporter (NSM v2.1-presisering: porter kan være fysiske, trådløse eller virtuelle)
- **2.4.2** — Krypter alle trådløse og kablede forbindelser
- **2.4.3** — Kartlegg fysisk tilgjengelighet for svitsjer og kabler
- **2.4.4** — Aktiver brannmur på alle klienter og servere

## Det moderne perspektivet på 2.4

NSM 2.4 leser eldre enn det er. Den nyeste versjonen er ikke fra 2024, men det engelske språket i prinsippet ("perimeter", "gateway", "soner") viser opphavet. Likevel kan tiltakene leses gjennom et zero-trust-filter:

| NSM-tiltak | Tradisjonell tolkning | Zero-trust-tolkning |
|---|---|---|
| 2.4.1 tilgangskontroll på porter | Fysisk port-security på switch | Identitets-basert ACL (mesh-tags), virtuelle porter som primær flate |
| 2.4.2 kryptering | TLS på applikasjon, kanskje IPSec på edge | Encryption-everywhere, mTLS for service-to-service, mesh som default-kryptert lag |
| 2.4.3 fysisk kabel-kartlegging | Kabelkanaler, bygnings-tilgang | I cloud: delegert til leverandør med kontraktuelle krav |
| 2.4.4 brannmur på alle | Edge-firewall + host-firewall | Mikrosegmentering med per-workload policy, eBPF-basert (Cilium, Tetragon) |

Denne lab-en implementerer i hovedsak zero-trust-tolkningen, men viser at tiltakene kan oppfylles på begge måter — noe som er viktig fordi mange norske virksomheter er midt i overgangen.

## Sentrale konsepter

### 1. Trust grenser (trust boundaries)

En trust grense er et punkt hvor du må autentisere på nytt eller kontrollere autorisasjon. I tradisjonell perimeter-modell var det én grense: utenfor-vs-innenfor.

I zero-trust er det mange grenser. For vps-bootstrap-laben er det fire:

1. **Public Internet → VPN Mesh:** Mesh-autentisering kreves
2. **Mesh → Host:** UFW-policy, kun fra mesh-interface tillatt
3. **Host → Container:** Docker security context (no-new-privileges, cap_drop, seccomp)
4. **Frontend container → Backend container:** Egne Docker-nettverk, frontend kan ikke nå DB direkte

Hver grense er en *uavhengig kompromiss-mulighet* for en angriper. Det betyr at en sårbarhet som lar en angriper komme gjennom grense 3 (escape fra container til host) krever et separat angrep for å så krysse grense 2 (escalate fra host til mesh) eller grense 4 (jump til DB-container).

### 2. Mikrosegmentering

Tradisjonell segmentering er basert på subnets — én subnet for "DMZ", én for "interne servers", én for "klienter". Mikrosegmentering går lenger: hver applikasjon, hver tjeneste, kan ha sin egen segmentering, og kommunikasjon mellom dem må eksplisitt tillates.

I praksis i lab-en: Docker-nettverk per funksjon. `frontend`-nettverket har caddy + app, `backend`-nettverket har app + db. Caddy *kan ikke* nå db direkte fordi de ikke deler nettverk. Det er mikrosegmentering på applikasjonsnivå.

### 3. Identitets-basert tilgang

Zero-trust erstatter "kilde-IP"-basert autentisering med "verified identity". Mesh-VPN som Tailscale håndterer dette: hver peer i meshen har en kryptografisk identitet som er knyttet til en bruker eller rolle. ACLs i Tailscale-konsollen er ikke "10.0.0.5 kan nå 10.0.0.8" — de er "tag:laptop kan SSH-e til tag:vps".

Det betyr at en host som mister sin private key, eller en bruker som logger ut, mister tilgang umiddelbart. Det er en mye sterkere garanti enn IP-basert ACL.

### 4. Egress-filtrering

Like viktig som å kontrollere hva som kommer inn, er å kontrollere hva som går ut. Hvis en applikasjon er kompromittert (B5 i threat model: web exploit), vil angriperen prøve å:

- Eksfiltrere data til en C2-server
- Laste ned tools (ofte fra GitHub raw, pastebin, eller transient hosting)
- Joine et botnet

Egress-filtrering kan blokkere disse callbacks før de fullføres. I lab-en gjøres dette via:
- `internal: true` på Docker backend-nettverket — DB har ikke utgående internett
- Mesh VPN gir mulighet til å route all utgående trafikk gjennom en exit-node med sentralisert filtrering (ikke implementert i hjemmelab, men dokumentert som mulighet)

### 5. Observability over enforcement

I zero-trust er det like viktig å se trafikk som å blokkere den. Hvis du *bare* blokkerer ukjent trafikk uten å logge den, vet du ikke om det er angrep eller misconfig. Hvis du logger den uten å blokkere, har du intel men ingen forsvar.

NSM 2.4 og 3.2 (sikkerhetsovervåkning) er designet for å fungere sammen.

## Hva 2.4 IKKE løser

Realisme: zero-trust mesh og mikrosegmentering forsvarer mot lateral movement og perimeter-bypass. Det forsvarer ikke mot:

- **Application layer attacks.** Hvis caddy + app har en SQL injection, betyr ikke segmenteringen at det er irrelevant — angriperen kan eksfiltrere data fra app-en uten å hoppe noen grense.
- **Insider threats med legitim tilgang.** En kompromittert mesh-peer er en legitim peer. Mesh stopper kun illegitime peers.
- **DNS hijacking.** Hvis DNS-en din peker mot en angripers server, bygger mesh-en en sikker tunnel til feil destinasjon.
- **Hardware-nivå compromise.** Hvis skyleverandørens hypervisor er kompromittert, hjelper ikke nettverkssegmentering.

Dette er ikke svakheter i 2.4 — det er definisjonen av scope. 2.4 handler om nettverk. Andre prinsipper (2.5 dataflyt, 2.7 data i ro/transitt, 3.x Oppdage) dekker det.

## Sources

- NSM Grunnprinsipper v2.1, prinsipp 2.4
  https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/beskytt-virksomhetens-nettverk/
- NIST SP 800-207 — Zero Trust Architecture
  https://csrc.nist.gov/publications/detail/sp/800-207/final
- "BeyondCorp: A New Approach to Enterprise Security" — Ward & Beyer, ;login: 39(6), Dec 2014
- Forrester ZTX framework
- "Zero Trust Networks" — Gilman & Barth, O'Reilly 2017
