# For recruiters and hiring managers

You probably have 90 seconds. Here's the version of this repo that matters
for that.

## Who I am

Aleksandar "Sasha" Vucenovic. Final-year BSc Cybersecurity at Kristiania
in Oslo, graduating July 2026. Norwegian work permit, fluent in Norwegian
and English, comfortable working in either professionally.

Bachelor thesis on backdoor attacks against fine-tuned LLMs and
lightweight defenses - directly relevant to current concerns about
LLM supply-chain compromise (Trivy, Checkmarx KICS, LiteLLM incidents
in early 2026).

## What I'm looking for

A first full-time role in Oslo or hybrid-Oslo, starting August 2026,
in one of:

- **Junior cloud security / SOC analyst** - defensive side, blue team
  detection engineering, incident response. Companies like mnemonic,
  NORMA Cyber, Watchcom, Defendable, sector CERTs, in-house teams at
  DNB, Storebrand, Telenor, Equinor.
- **Junior platform / cloud engineer with security focus** - building
  secure infrastructure rather than reacting to attacks. Bouvet, Sopra
  Steria Norge, Capgemini Norge, in-house at scale-ups.
- **Solution / pre-sales engineer** - technical side of vendor work,
  particularly around cloud and security. Less common entry path but
  matches communication and breadth strengths.

I am not looking for: pure offensive (pentest) roles, pure SOC tier-1
ticket-shoveling without growth path, or roles requiring active security
clearance day one (would need time to obtain).

## What this portfolio shows

Three things, deliberately:

**1. I can build secure infrastructure end-to-end.** The SSH-hardening
and VPS-bootstrap labs are not toy examples. They are threat-modeled,
versioned, tested, and produce measurable hardening (ssh-audit grade
A+, 99.97% reduction in attack surface noise). They demonstrate the
skills a junior platform engineer needs day one.

**2. I can write detections, not just configure firewalls.** The NSM 3.2
lab includes 5 Sigma rules with MITRE ATT&CK tagging, dual implementation
in KQL (Sentinel) and SPL (Splunk), and triage/response playbooks. This
is what a junior SOC analyst is asked to do in week three.

**3. I speak Norwegian compliance.** The NSM Grunnprinsipper mapping is
the differentiator. Most BSc portfolios map work to NIST or MITRE because
that's what English YouTube teaches. NSM is what Norwegian public sector
and regulated private sector actually use. Hiring managers at mnemonic,
NORMA Cyber, Bouvet, NSM itself, and any in-house security team in
regulated industry - they speak this language. I do too.

## Where to look first

If you have **5 minutes**, read:
- [`networking/zero-trust-designs/ssh-hardening/THREAT-MODEL.md`](./networking/zero-trust-designs/ssh-hardening/THREAT-MODEL.md)
  to see how I think about adversaries
- [`compliance/nsm-grunnprinsipper/README.md`](./compliance/nsm-grunnprinsipper/README.md)
  to see how I bridge Norwegian and international frameworks

If you have **15 minutes**, also read:
- [`networking/zero-trust-designs/vps-bootstrap/scripts/00-bootstrap.sh`](./networking/zero-trust-designs/vps-bootstrap/scripts/00-bootstrap.sh)
  to see how I write production scripts (idempotent, commented, with
  rollback paths)
- [`compliance/nsm-grunnprinsipper/3-2-sikkerhetsovervakning/sigma-rules/`](./compliance/nsm-grunnprinsipper/3-2-sikkerhetsovervakning/sigma-rules/)
  to see how I write detections

If you have **an hour and want a real signal**:
- [`compliance/nsm-grunnprinsipper/2-3-sikker-konfigurasjon/`](./compliance/nsm-grunnprinsipper/2-3-sikker-konfigurasjon/)
  is the deepest piece. Read teori → praksis → tiltaksmapping →
  verifisering. That's the full pipeline of how I work: theory anchored
  in a real framework, practice with concrete code, mapping that
  recruiters can audit, and verification with measurable outcomes.

## Honest about what's missing

I have no production work experience yet. The labs are real, the threat
models are real, and the measurements are real - but they're at homelab
scale, not at the scale of a 5,000-employee bank.

What that means in practice:
- I have not run an incident on a real production SOC.
- I have not made architectural decisions that affected millions in
  revenue.
- I have not negotiated a security exception with a board-level CISO.
- I have not led a project with budget and people.

I will need to learn these things in the role. The portfolio shows that
the foundations are solid enough that the learning curve is steep but
not vertical.

## Honest about strengths

- **Threat modeling.** Every lab has explicit actor classes with
  capabilities and constraints. This is the skill that distinguishes a
  security engineer from a sysadmin who's read a hardening guide.
- **Cross-framework fluency.** NSM, NIST CSF 2.0, ISO 27002, MITRE
  ATT&CK, OWASP - I can move between them and explain how a single
  control maps across all of them. This is what enables an engineer to
  work with both Norwegian public sector clients and international
  cloud-native shops.
- **Honest documentation.** "What didn't work" sections in every lab.
  Calibrated language ("reduced ASR by 83% in our test setup", not
  "solved backdoor attacks"). I would rather underclaim and let the
  measurements do the work.
- **Norwegian + English.** Comfortable presenting and writing in both.
  Lab content is split: Norwegian for events and Norwegian frameworks,
  English for code and international content.

## What I'm not selling

I am not a senior. I will not pretend to be one. The portfolio is
calibrated to where I actually am: a final-year BSc with a strong thesis,
solid fundamentals, and a clear trajectory toward where I want to be in
3-5 years.

If you need a senior engineer who can lead an incident response team
day one - that's not me yet. If you need a junior who learns fast,
documents thoroughly, and won't bullshit you about what they don't know
- let's talk.

## How to reach me

- **LinkedIn:** linked from [GitHub profile](https://github.com/Aleks1712)
- **GitHub Issues:** open one on this repo for technical questions
- **Email:** in GitHub profile

If you're reaching out about a specific role, mention which lab or
section caught your attention. It tells me you actually read the
portfolio and helps me calibrate the conversation.

---

*Last updated: 2026-05. This page is updated whenever the portfolio
changes substantively. The featured labs and "where to look first"
sections will change as new work lands.*
