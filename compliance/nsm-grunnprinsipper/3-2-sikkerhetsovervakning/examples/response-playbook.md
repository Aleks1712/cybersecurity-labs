# Response Playbook — håndtering av bekreftet sikkerhetshendelse

Etter triage har bekreftet en faktisk hendelse, dokumenterer dette playbook-en hvilke steg som skal kjøres. Dette er ikke et fullstendig incident response-program (det er virksomhets-skala), men en praktisk veiledning for hjemmelab/SMB-skala der én eller få personer håndterer hendelser.

## Faser i incident response (NIST SP 800-61)

NIST definerer fire faser:

1. **Preparation** — gjøres før hendelsen. Verktøy, kontakter, playbooks klar.
2. **Detection and Analysis** — alert utløses, triage avgjør at det er ekte.
3. **Containment, Eradication, Recovery** — stopp angrepet, fjern angriperen, gjenopprett tjenester.
4. **Post-Incident Activity** — lærdom, oppdateringer, kommunikasjon.

NSM 4.1-4.4 mapper direkte mot disse fasene.

## Trinn 1 — Vurder og klassifiser hendelse (NSM 4.2)

Før containment: hva slags hendelse er dette egentlig?

**Klassifiser etter type:**

| Type | Eksempler | Dominant teknikk |
|---|---|---|
| Account compromise | SSH key persistence, kompromittert mesh-peer | T1098, T1078 |
| Lateral movement | SSH fra én host til andre | T1021 |
| Privilege escalation | Sudo abuse, container escape | T1548, T1611 |
| Data exfiltration | Unormal egress, store DB-queries | T1041, T1567 |
| Resource abuse | Cryptojacker, botnet member | T1496 |

Klassifisering driver hvilke containment-steg som er relevante. Cryptojacker krever andre steg enn data exfiltration.

**Klassifiser etter severity (NSM 4.2):**

Bruk severity-matrix.md.

## Trinn 2 — Kontroller og håndter (NSM 4.3) — CONTAINMENT

Stopp angriperen fra å gjøre mer skade. Mål: minimer impact, men ikke ødelegg evidens.

### For account compromise

Umiddelbart:
- Disable account: `sudo usermod -L <user>` eller `sudo passwd -l <user>`
- Fjern fra alle relevante grupper: `sudo gpasswd -d <user> sudo wheel docker`
- Roter SSH host keys hvis de potensielt er kompromittert: `ssh-hardening/scripts/rotate-host-keys.sh`
- Hvis Tailscale: gå til admin console, disable enheten

Innen 1 time:
- Audit `/home/<user>/.ssh/authorized_keys` på alle hoster
- Kjør `audit-authorized-keys.sh` script for å finne uventet keys
- Roter alle SSH keys som er på den kompromitterte enheten

### For lateral movement

Umiddelbart:
- Identifiser alle hoster som er nådd. Sjekk `last`, `lastlog`, `journalctl _COMM=sshd` på hver mistenkt host
- Isoler kompromitterte hoster fra mesh: Tailscale `disable device`, eller fjern fra WireGuard peers
- Block source IPs midlertidig: `sudo ufw deny from <ip>`

Innen 1 time:
- Forensisk imaging av disk hvis evidence-bevaring er viktig (sjelden for hjemmelab, ofte for virksomhet)
- Memory dump hvis prosess fortsatt kjører: `gcore <pid>` eller `lime` for kernel memory

### For privilege escalation

Umiddelbart:
- Sjekk om angriperen har persistens: `find / -newer /tmp/marker -type f 2>/dev/null` (etter at du har laget /tmp/marker)
- Sjekk cron-jobs, systemd timers, autostart: `systemctl list-timers --all`, `crontab -l` for hver bruker
- Sjekk SUID/SGID bits: `find / -perm /6000 -type f 2>/dev/null`

Innen 1 time:
- Roter `/etc/sudoers` og `/etc/sudoers.d/*` til kjent god tilstand
- Hvis container escape: stopp og fjern containeren, image kan være kompromittert

### For resource abuse / cryptojacker

Umiddelbart:
- Identifiser prosess: `top` for CPU, eller `ps auxf` for proc tree
- Identifiser nettverkskommunikasjon: `ss -tnp` viser open connections per process
- Drep prosessen: `kill -9 <pid>` (men ikke før du har fanget kontekst)

Innen 1 time:
- Spor opprinnelse: hvilken bruker eier prosessen? Hvilken parent? Hvordan kom det inn?
- Som regel: web exploit → PHP/Node-shell → curl-en ned cryptojacker → run

## Trinn 3 — Eradikering

Fjern angriperens fotavtrykk fra systemet.

**Sjekkliste:**

- [ ] Alle uautoriserte authorized_keys fjernet
- [ ] Alle uautoriserte cron/systemd timer fjernet
- [ ] Alle uautoriserte brukere disabled eller slettet
- [ ] Alle webshells / persistent backdoors fjernet
- [ ] Alle modifiserte konfigurasjonsfiler tilbakestilt fra kjent baseline
- [ ] Alle malicious containers stoppet og fjernet, image deleted
- [ ] Hvis kjernel-nivå compromise mistenkt: re-image hele systemet

**Når kan du IKKE bare eradikere?**

Hvis kompromisset er kjernel-nivå (rootkit, BPF-malware), kan du ikke trygt rense — du må re-image. Indikatorer:
- Prosesser som ikke vises i `ps` men har åpne TCP-forbindelser
- `dmesg` viser uventet kernel module loading
- Inkonsistente svar fra forskjellige verktøy (`ps` vs `/proc/*` vs `top`)
- Filsystem-anomalier ved `find / -mtime -1` som ikke vises i fil-listinger

I disse tilfellene: nuke from orbit. Re-deploy fra git baseline.

## Trinn 4 — Recovery

Bring systemet tilbake til normal drift.

- Verifiser baseline tilstand med `verify-sshd-config.sh` og `99-verify.sh`
- Re-enable SSH access for legitimate users (med roterte keys)
- Re-add hoster til mesh
- Resume normal monitoring
- Hold heightened alert i 30 dager — angripere prøver ofte igjen via samme kanal

## Trinn 5 — Evaluer og lær (NSM 4.4)

24-72 timer etter incident: hold post-mortem.

**Strukturerte spørsmål:**

1. **Hva skjedde?** Faktisk timeline, ikke første hypotese.
2. **Hvordan ble vi kompromittert?** Initial access vector. Var det noe vi ikke detektert?
3. **Hva detekterte vi?** Hvor i kill-chain? Hvor sent eller tidlig?
4. **Hva gikk bra?** Hvilke detection-regler virket? Hvilke runbooks var nyttige?
5. **Hva gikk dårlig?** Hvor sviktet detection? Hvilke runbook-steg manglet?
6. **Hva endrer vi?**
   - Detection-coverage: ny regel som ville fanget initial access
   - Hardening: gap som tillot exploit
   - Process: runbook-oppdatering, kontaktliste, eskaleringssti
   - Tooling: manglet et verktøy for forensics?

**Output:** action items med eier og deadline. Disse skal verifiseres lukket innen 30 dager.

## Hjemmelab vs virksomhet

Dette playbook er skrevet for hjemmelab/SMB-skala der én person håndterer alt. Virksomhet trenger:

- Vakt-rotation og 24/7 dekning
- Eskaleringssti til ledelse
- Juridisk: GDPR breach notification (72h), eventuell varsling til NSM/datatilsynet
- Kommunikasjon: kunder, presse, regulator
- Forsikring: cyber insurance-aktivering
- Eksterne specialists: DFIR-konsulent, jurister

For norsk sektor: NSM NCSC har offentlig kontaktlinje (cert@ncsc.no, 02497 24/7) for alvorlige hendelser.

## Cross-references

- For triage før respons: `triage-playbook.md`
- For severity-vurdering: `severity-matrix.md`
- For threat-modellen som driver detection: `vps-bootstrap/THREAT-MODEL.md`

## Sources

- NIST SP 800-61 — Computer Security Incident Handling Guide
- SANS Incident Handler's Handbook
- NSM Grunnprinsipper v2.1, kategori 4 (Håndtere og gjenopprette)
