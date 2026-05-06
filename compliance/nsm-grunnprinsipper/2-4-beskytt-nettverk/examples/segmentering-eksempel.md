# Network segmentering — Tailscale ACL og verifikasjons-eksempler

## Tailscale ACL — eksempel for lab-en

Tailscale ACLs er identitets-basert segmentering. I stedet for "10.0.0.5 kan SSH til 10.0.0.8" er reglene "tag:laptop kan SSH-e til tag:vps". Identiteter persisterer på tvers av IP-endringer.

```jsonc
// vps-bootstrap/tailscale/acl-example.json
{
  "tagOwners": {
    "tag:vps":     ["autogroup:admin"],
    "tag:laptop":  ["autogroup:admin"],
    "tag:dev":     ["autogroup:admin"],
    "tag:prod":    ["autogroup:admin"]
  },

  "acls": [
    // Operator laptops can SSH to all VPS hosts
    {
      "action": "accept",
      "src":    ["tag:laptop"],
      "dst":    ["tag:vps:22"]
    },

    // Dev hosts can talk to dev hosts only — not prod
    {
      "action": "accept",
      "src":    ["tag:dev"],
      "dst":    ["tag:dev:*"]
    },

    // Prod hosts are isolated; only laptops with explicit access can reach
    {
      "action": "accept",
      "src":    ["tag:laptop"],
      "dst":    ["tag:prod:22,80,443"]
    },

    // Default deny is implicit — anything not matched above is blocked
  ],

  "ssh": [
    // Tailscale SSH (replaces sshd entirely on VPS, optional)
    {
      "action": "check",        // requires re-auth periodically
      "src":    ["autogroup:admin"],
      "dst":    ["tag:vps"],
      "users":  ["root", "ubuntu", "sasha"]
    }
  ]
}
```

Kommentar: ACL-en er minimal. Et virksomhets-deployment ville hatt:
- Per-bruker tags med fine-grained access
- Separate ACLs per app/service
- Conditional access basert på device posture (jamf, intune)
- Auto-revoke ved manglende device-check-in

## Wire-test før og etter mesh-binding

### Før: SSH eksponert mot public internet

Setup: Standard Ubuntu 24.04 VPS, port 22 åpen.

```bash
$ nmap -Pn -p 22 <public-ip>
PORT   STATE SERVICE
22/tcp open  ssh
```

Auth.log etter 24 timer:
```bash
$ wc -l /var/log/auth.log
46812 /var/log/auth.log
```

Ekstrakt:
```
... Failed password for invalid user admin from 185.247.xxx.xxx port 60182 ...
... Failed password for invalid user oracle from 218.92.xxx.xxx port 14523 ...
... Failed password for invalid user test from 124.165.xxx.xxx port 41235 ...
[ ~ 10000 lignende per døgn ]
```

Det er bakgrunnsstøy — mass scanners (B1) som prøver default credentials. Volumet betyr ingenting alene, men det demonstrerer attack-overflate.

### Etter: SSH bundet til mesh-interface

Setup: ssh-hardening + vps-bootstrap applied. SSH `ListenAddress` satt til mesh-interface IP. UFW deny on public.

```bash
$ nmap -Pn -p 22 <public-ip>
PORT   STATE    SERVICE
22/tcp filtered ssh   # eller "closed" — UFW dropper pakker
```

Auth.log etter 7 dager:
```bash
$ wc -l /var/log/auth.log
142 /var/log/auth.log
```

Innholdet er kun legitime authentications fra meg via mesh, pluss noen `systemd-logind` entries.

**Tall:** 46.812 forsøk på 24 timer → 142 events på 7 dager.
That's a 99.97% reduksjon i SSH-aktivitet og en 100% reduksjon i public attack-overflate.

## Hva eksemplet demonstrerer

For en hiring manager:

1. **Tall, ikke claims.** "Vi reduserte angrepsoverflate" er handwaving. "46.812 forsøk → 142 events" er målbart.

2. **Threat-aware design.** Beslutningen om mesh-binding er drevet av observerte angrep (B1 mass scanners), ikke generisk "best practice".

3. **Identitets-basert ACL.** Tailscale-eksempelet viser overgangen fra IP-basert til identitet-basert tilgang, som er fundamentet for zero-trust.

## Cross-references

- ssh-hardening (server-side config): `networking/zero-trust-designs/ssh-hardening/`
- vps-bootstrap (mesh setup, UFW): `networking/zero-trust-designs/vps-bootstrap/`
- Threat model B1: `vps-bootstrap/THREAT-MODEL.md`

## Sources

- Tailscale ACL documentation
- vps-bootstrap setup-prosess (faktiske observasjoner)
