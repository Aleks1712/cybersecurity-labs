# 🤖 ETH2100 – Kunstig intelligens og sikkerhet

> **Karakter:** A | ETH2100 Kontinuasjonseksamen – Oppgave 1  
> **Emne:** Sikkerhetsutfordringer ved generativ og agentisk AI

---

## Innledning

Kunstig intelligens har på kort tid gått fra å være et spesialisert forskningsfelt til å bli en integrert del av arbeidslivet. Store språkmodeller (LLM) som ChatGPT har gjort generativ AI allment tilgjengelig, mens utviklingen nå går mot agentiske systemer som kan utføre handlinger gjennom verktøy, API og integrasjoner. AI kan dermed ikke lenger betraktes utelukkende som et produktivitetsverktøy – det må forstås som en selvstendig angrepsflate.

---

## Sikkerhetsutfordringer ved generativ AI

Generativ AI bygger på probabilistisk mønstergjenkjenning. NIST fremhever at AI-systemer har en særskilt risikoprofil fordi de er dataavhengige, probabilistiske og kan opptre uforutsigbart i grensesituasjoner.

### Tre sentrale trusselkategorier

#### 1. Sosial manipulering og deepfakes
LLM muliggjør produksjon av språklig presise og kontekstsensitive phishing-meldinger på tvers av språk. ENISA fremhever at teknologien reduserer kompetansekrav for målrettede kampanjer. CEO-fraud med syntetiske stemmer er et dokumentert eksempel.

**CIA-perspektiv:** Truer konfidensialitet gjennom svindel og datatyveri.

#### 2. Prompt injection
Angriperen manipulerer modellen til å prioritere ondsinnede instruksjoner fremfor systemets tiltenkte funksjon. OWASP vurderer dette som en av de mest kritiske risikoene i LLM-applikasjoner.

I tradisjonelle applikasjoner kan kontroll og data separeres syntaktisk – LLM-er tolker input semantisk, og det finnes ingen tydelig grense mellom instruksjon og innhold.

**CIA-perspektiv:** Kompromitterer alle tre egenskapene simultant:
- Konfidensialitet → dataeksfiltrering
- Integritet → manipulerte beslutninger
- Tilgjengelighet → uforutsigbar systemoppførsel

#### 3. Dataforgiftning
Målrettet manipulering av treningsdata, finetuning-datasett eller RAG-kilder for å påvirke modellens respons. Skiller seg fra hallusinasjoner ved å være intensjonell. Generativ AI som kodeassistent kan forsterke denne risikoen ved å reprodusere usikre mønstre.

### CIA-rammeverket og AI

Det tradisjonelle CIA-rammeverket forutsetter at kontroll og data kan separeres. AI-systemer utfordrer denne forutsetningen – språk fungerer simultant som input, instruksjon og kontrollmekanisme. CIA-modellen er fortsatt relevant som analytisk rammeverk, men må suppleres med vurdering av semantiske angrepsvektorer.

---

## Sikkerhetsutfordringer ved agentisk AI

Der generativ AI primært produserer informasjon, representerer agentisk AI et kvalitativt skifte: modellen kan utføre handlinger gjennom verktøy og systemintegrasjoner. Risikoen transformeres fra **epistemisk** til **operasjonell**.

### Autonominivåer (Harang & Sablotny, 2025)

| Nivå | Beskrivelse |
|------|-------------|
| 0 | Enkel prompt-respons |
| 1 | Verktøybruk |
| 2 | Multi-step agentiske arbeidsflyter |
| 3 | Fullt autonome agenter med løkker og selvrefleksjon |

### Agency vs. Autonomy

**AWS Agentic AI Security Scoping Matrix** skiller mellom:
- **Agency** – hvilke verktøy agenten kan bruke
- **Autonomy** – graden av selvstendig beslutningstaking

Disse er uavhengige dimensjoner. Sikkerhetskontroller må adressere begge.

### Rogue Actions

Dersom agenten kan sende e-post, endre filer, kjøre kode eller samhandle med interne API-er, kan et vellykket prompt injection-angrep gi angriperen indirekte kontroll over organisasjonens privilegier (OWASP AI Testing Guide kaller dette «Rogue Actions»).

---

## Sikkerhetstiltak – fra filtre til arkitektur

AI-sikkerhet kan ikke baseres på prompt-filtrering alene, men må forankres i arkitektur, dataflyt og tilgangsstyring.

| Tiltak | Beskrivelse |
|--------|-------------|
| Minste privilegium | Agenten gis kun tilgang til nødvendige verktøy |
| Menneskelig godkjenning | For irreversible handlinger |
| Output-validering | Schema-validering, allow-lists, policykontroller |
| Taint tracing | Ubetrodd input behandles som kompromitterbart data |
| Supply chain | Treningsdata, RAG-kilder, plugins og API-integrasjoner må vurderes |

Sikkerhetstiltakene innebærer en reell avveining: menneskelig godkjenning reduserer risiko, men introduserer latens. Kontrollnivået må kalibreres mot brukskontekst og risikoaksept.

---

## Konklusjon

Generative og agentiske AI representerer ulike, men overlappende risikoprofiler. For sikkerhetsprofesjonelle innebærer dette at AI-systemer må behandles som aktive angrepsflater, ikke passive verktøy. Agentiske systemer krever vurdering av verktøytilgang, dataflyt, autonominivå og robusthet mot indirekte prompt injection.

---

## Referanser

| Kilde | Detalj |
|-------|--------|
| Brown & Saner (2025) | The Agentic AI Security Scoping Matrix. AWS Security Blog |
| ENISA (2025) | ENISA Threat Landscape 2025 |
| Harang & Sablotny (2025) | Agentic autonomy levels and security. NVIDIA Technical Blog |
| Meucci & Morana (2025) | OWASP AI Testing Guide (v1). OWASP Foundation |
| NIST (2023) | AI RMF 1.0 (NIST AI 100-1) |
| OWASP Foundation (2025) | OWASP Top 10 for LLM Applications |
| Østby, B. (2025) | Forelesning 10 (uke 39). Høyskolen Kristiania |
