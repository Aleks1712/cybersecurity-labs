# 🔍 soc-detection-lab

> Praktiske SOC-analyser med full MITRE ATT&CK-mapping
> CYB2100 Cyberforsvar – Høyskolen Kristiania

## Struktur

| Mappe | Innhold |
|-------|---------|
| [splunk-botsv1](./splunk-botsv1) | BOTSv1 SOC-analyse med SPL-spørringer og bilder |
| [yara-rules](./yara-rules) | YARA-regler for phishing-makro og polymorf skadevare |
| [threat-intel](./threat-intel) | FrostyGoop og Volt Typhoon writeups |
| [mitre-attack](./mitre-attack) | Full ATT&CK-dybdeanalyse |

## MITRE ATT&CK – Observerte teknikker

| ID | Teknikk | Lab | Taktikk |
|----|---------|-----|---------|
| T1595.002 | Active Scanning | BOTSv1 | Reconnaissance |
| T1190 | Exploit Public-Facing App | BOTSv1, FrostyGoop | Initial Access |
| T1566.001 | Spearphishing Attachment | YARA | Initial Access |
| T1110 | Brute Force | BOTSv1 | Credential Access |
| T1003 | Credential Dumping | BOTSv1, FrostyGoop | Credential Access |
| T1021.002 | SMB Lateral Movement | BOTSv1 | Lateral Movement |
| T1071.004 | DNS Tunneling | BOTSv1 | Exfiltration |
| T1090.002 | External Proxy (KV-botnett) | Volt Typhoon | C2 |
| T0831 | Manipulation of Control (ICS) | FrostyGoop | Impact |
