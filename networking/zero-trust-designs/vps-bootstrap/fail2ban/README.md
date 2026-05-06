# Fail2ban — Defense in Depth

## Viktig framing først

Når SSH er pubkey-only (ingen password auth), er det ingenting å brute-force. Fail2ban-mot-SSH i den situasjonen catcher 0% av reelle angrep, fordi det ingen er.

Likevel installerer vi fail2ban. Hvorfor?

1. **Forsikring mot konfigurasjonsfeil.** Hvis noen (du, eller en pakke-oppdatering) ved et uhell setter `PasswordAuthentication yes` igjen, slår fail2ban inn umiddelbart i stedet for å la brute-force kjøre fritt.

2. **Klar for andre tjenester.** Når du senere eksponerer en webapp med login, et mailserver, eller noe annet med passord, har du allerede framework-en på plass.

3. **Audit trail.** Selv banale failed login-forsøk havner i fail2ban-loggen, som er enklere å parse enn rå auth.log.

Det skal **ikke** brukes som primærforsvar. Hvis du baserer deg på "fail2ban vil banne dem", har du allerede tapt — du har en exposed service med svak auth.

## Hva jail.local konfigurerer

- **`bantime.increment`** — repeat offenders får økende ban-tider. 1. forsøk: 10 min. 2.: 20 min. 3.: 40 min. Opp til 1 uke.
- **`nftables`-backend** istedet for legacy `iptables`. Modern Ubuntu/Debian.
- **`ignoreip`** — mesh-subnets whitelistet. Aldri ban en mesh-peer ved et uhell.
- **`backend = systemd`** for sshd-jail — leser fra journald istedet for `/var/log/auth.log` (som mange moderne installasjoner ikke har).
- **`recidive` jail** — den som faktisk gjør jobb. IP-er som blir banned i flere jails over tid får en uke-lang allports-ban.

## Verifisering

```bash
# Status
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Test at jail-en kan parse logs
sudo fail2ban-client get sshd findtime
sudo fail2ban-client get sshd bantime

# Manuelt ban (test)
sudo fail2ban-client set sshd banip 192.0.2.99

# Manuelt unban
sudo fail2ban-client set sshd unbanip 192.0.2.99

# Se nåværende banlist
sudo fail2ban-client status sshd | grep "Banned IP"
```

## Når fail2ban faktisk er nyttig

- **Mailserver:** SMTP-AUTH brute-force er virkelig og fail2ban hjelper
- **WordPress (hvis du må):** xmlrpc.php-bombing av login er kontinuerlig
- **Generic HTTP-basic-auth:** for små private områder uten ordentlig auth
- **VPN-endepunkt på offentlig IP:** WireGuard er stille, men OpenVPN logger handshake-forsøk

For pure mesh-bound SSH: fail2ban er hygiene, ikke security.

## Hva jeg ikke har konfigurert

- **DDoS-mitigering.** Fail2ban er ikke en DDoS-løsning. For volumetrisk angrep, trenger du Cloudflare eller leverandørens DDoS-shield.
- **App-spesifikke jails (nginx, postfix, dovecot).** Aktiver per host som faktisk kjører de tjenestene. Tomme logger fører til feil og støy.
- **Geo-IP banning.** Bryter for ofte legitim bruk og angripere bruker uansett kompromitterte hosts i ditt eget land.

## Sources

- Fail2ban offisiell dokumentasjon: https://github.com/fail2ban/fail2ban/wiki
- Ubuntu Server Guide — Security section
