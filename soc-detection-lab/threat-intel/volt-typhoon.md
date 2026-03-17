# Volt Typhoon – Kinesisk pre-positioning

**Aktiv siden:** 2021 | **Dwell time:** Opptil 5 år

## Kill Chain
```
T1595  Rekognosering av Fortinet, Cisco, Ivanti
T1190  CVE-2024-39717 i VPN-gatewayer
T1059  Living off the Land: WMIC, ntdsutil, netsh, PowerShell
T1003  ntdsutil → NTDS.dit → offline passordknekking
T1550  Pass-the-Hash lateral movement
T1090  KV-botnett via SOHO-routere maskerer C2-trafikk
```

## Deteksjon
```splunk
index=* EventCode=1 Image="*ntdsutil.exe"
| table _time, ComputerName, CommandLine

index=* EventCode=1 Image="*powershell.exe"
    (CommandLine="*-enc*" OR CommandLine="*-EncodedCommand*")
| table _time, ComputerName, CommandLine
```

## Norges sårbarhet
- Legacy SCADA uten IT/OT-segmentering
- VPN-grensesnitt eksponert mot internett
- NATO-medlem og energileverandør til Europa → attraktivt mål

**Kilde:** CISA AA23-144A, AA24-038A
