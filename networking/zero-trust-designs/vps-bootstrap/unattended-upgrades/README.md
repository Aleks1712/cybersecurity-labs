# Unattended Security Updates

Den enkleste hardening-tiltaken med høyest payoff: install patches automatisk når de slippes.

## Hva som er konfigurert

- **`50unattended-upgrades`** — hovedfil. Kun security-pocket aktivert, ikke alle oppdateringer. Auto-reboot 03:00 hvis kernel er oppdatert.
- **`20auto-upgrades`** — aktiverer at unattended-upgrades faktisk kjører. Uten denne sitter konfig-en bare og venter.

## Hvorfor kun security-pocket

Du vil ha kernel-CVEs og OpenSSH-CVEs patched automatisk. Du vil **ikke** ha en automatisk pakke-oppdatering som plutselig endrer Postgres-major-versjon kl. 03:14 en tirsdag og bryter applikasjonen din.

Security-pocket inkluderer:
- Kernel patches
- OpenSSH-fikser
- glibc-fikser
- OpenSSL-fikser
- Sårbarhetsfikser i bibliotek og verktøy

Det inkluderer **ikke**:
- Major version bumps
- Feature-oppdateringer
- Pakker som ikke er klassifisert som security

For den andre kategorien, kjør `apt upgrade` manuelt månedlig som del av maintenance-vinduet.

## Auto-reboot

`Automatic-Reboot "true"` med `Automatic-Reboot-Time "03:00"` betyr at hvis en kernel-oppdatering krever reboot, gjøres det automatisk om natten. For en personal VPS er dette riktig avveining — du vil ha kernel-CVE-fikset oftere enn du vil ha 100% uptime.

For en produksjons-stack med flere noder bak en load balancer, vurder å sette `Automatic-Reboot "false"` og scripte rolling reboot via Ansible eller lignende.

## Verifisering

```bash
# Tørrtest — hva ville blitt installert akkurat nå
sudo unattended-upgrade --dry-run --debug

# Sist kjørte oppdatering
ls -la /var/log/unattended-upgrades/
sudo cat /var/log/unattended-upgrades/unattended-upgrades.log

# Status av timer-en
systemctl status apt-daily.timer
systemctl status apt-daily-upgrade.timer
systemctl status unattended-upgrades.service
```

## Hva som kan gå galt

1. **Disk-fyllpunkt.** Hvis `/var` er fylt, feiler oppdateringer stille. Cron-mailen forteller deg, men leser du den? Sett opp en disk-monitor.
2. **Reboot-loop.** Hvis en kernel-oppdatering har en bug på din spesifikke hardware, kan auto-reboot resultere i en host som ikke kommer opp. Pin kernelen til en kjent god versjon mens du undersøker.
3. **Pakke-konflikt.** Av og til krasjer security-fikser med en pinned pakke (PostgreSQL-extension etc.) og oppdateringen feiler. `Verbose "true"` i konfig-en logger dette så du kan diagnose.

## Hva som er bevisst ikke aktivert

- **Email rapport.** Kunne hatt `Unattended-Upgrade::Mail "root"` men vi har ikke MTA-konfigurert. Sjekk loggene istedet, eller ship dem til sentral logging.
- **Snap auto-refresh.** Snap har sin egen update-mekanisme. Ubuntu pre-installerer ofte snap-pakker du kanskje ikke vil ha — vurder å fjerne snap helt i en separat hardening-steg.

## Sources

- Debian Wiki: UnattendedUpgrades
- Ubuntu Server Guide: Automatic Updates
- `man unattended-upgrade`
