#!/usr/bin/env bash
# ============================================================================
# 99-verify.sh — Post-bootstrap state verification
# ============================================================================
#
# Runs after 00-bootstrap.sh to confirm the system is in the expected state.
# Returns 0 if all checks pass, non-zero with summary if not.
# ============================================================================

set -uo pipefail

PASS=0
FAIL=0
WARN=0

green()  { printf '\033[32m[+] %s\033[0m\n' "$*"; PASS=$((PASS+1)); }
red()    { printf '\033[31m[!] %s\033[0m\n' "$*"; FAIL=$((FAIL+1)); }
yellow() { printf '\033[33m[?] %s\033[0m\n' "$*"; WARN=$((WARN+1)); }

echo "============================================================"
echo " VPS bootstrap verification"
echo "============================================================"

# ---- SSH ----
echo
echo "[*] SSH"
if sshd -t 2>/dev/null; then
    green "sshd config syntax valid"
else
    red "sshd config syntax INVALID"
fi

if sshd -T 2>/dev/null | grep -qE '^passwordauthentication no'; then
    green "PasswordAuthentication=no"
else
    red "PasswordAuthentication is not 'no'"
fi

if sshd -T 2>/dev/null | grep -qE '^permitrootlogin no'; then
    green "PermitRootLogin=no"
else
    red "PermitRootLogin is not 'no'"
fi

if sshd -T 2>/dev/null | grep -qE '^loglevel verbose'; then
    green "LogLevel=VERBOSE"
else
    yellow "LogLevel is not VERBOSE (key fingerprints won't be logged)"
fi

# ---- Firewall ----
echo
echo "[*] Firewall (UFW)"
if ufw status | grep -q "Status: active"; then
    green "UFW active"
else
    red "UFW not active"
fi

if ufw status verbose | grep -q "Default: deny (incoming)"; then
    green "Default policy: deny incoming"
else
    red "UFW default incoming is not 'deny'"
fi

# ---- Mesh ----
echo
echo "[*] VPN mesh"
if command -v tailscale >/dev/null 2>&1; then
    if tailscale status >/dev/null 2>&1; then
        green "Tailscale running and authenticated"
        TS_IP=$(tailscale ip -4 2>/dev/null | head -1)
        echo "    Tailscale IPv4: $TS_IP"
    else
        yellow "Tailscale installed but not authenticated (run: tailscale up)"
    fi
elif command -v wg >/dev/null 2>&1; then
    if wg show 2>/dev/null | grep -q interface; then
        green "WireGuard interface configured"
    else
        yellow "WireGuard installed but no interface up"
    fi
else
    red "No VPN mesh tool found"
fi

# ---- Docker ----
echo
echo "[*] Docker"
if command -v docker >/dev/null 2>&1; then
    if systemctl is-active --quiet docker; then
        green "Docker engine running"
        DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo unknown)
        echo "    Version: $DOCKER_VERSION"
    else
        red "Docker installed but not running"
    fi

    # Check that iptables is disabled in daemon.json (so UFW is in control)
    if [[ -f /etc/docker/daemon.json ]] && grep -q '"iptables": false' /etc/docker/daemon.json 2>/dev/null; then
        green "Docker daemon: iptables=false (UFW remains in control)"
    else
        yellow "Docker daemon may be bypassing UFW (iptables=true). See docker/README.md"
    fi
else
    red "Docker not installed"
fi

# ---- Unattended upgrades ----
echo
echo "[*] Auto-updates"
if systemctl is-enabled --quiet unattended-upgrades; then
    green "unattended-upgrades enabled"
else
    red "unattended-upgrades not enabled"
fi

if [[ -f /etc/apt/apt.conf.d/20auto-upgrades ]] && grep -q '"1"' /etc/apt/apt.conf.d/20auto-upgrades; then
    green "Auto-upgrade activation file present"
else
    yellow "20auto-upgrades not configured"
fi

# ---- Fail2ban ----
echo
echo "[*] Fail2ban"
if systemctl is-active --quiet fail2ban; then
    green "fail2ban active"
    fail2ban-client status 2>/dev/null | head -10 || true
else
    yellow "fail2ban not active (acceptable if mesh-only and no public services)"
fi

# ---- Auditd ----
echo
echo "[*] Auditd"
if systemctl is-active --quiet auditd; then
    green "auditd active"
else
    yellow "auditd not active"
fi

# ---- Public exposure check ----
echo
echo "[*] Public exposure"
PUBLIC_PORTS=$(ss -lntp 2>/dev/null | awk 'NR>1 && $4 !~ /^(127\.|::1|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.)/ { print $4 }' | sort -u)
if [[ -z "$PUBLIC_PORTS" ]]; then
    green "No services listening on public IPs"
else
    yellow "Services listening on public IPs:"
    echo "$PUBLIC_PORTS" | sed 's/^/        /'
fi

# ---- Summary ----
echo
echo "============================================================"
echo " Summary: $PASS passed, $WARN warnings, $FAIL failures"
echo "============================================================"

if [[ $FAIL -gt 0 ]]; then
    exit 1
elif [[ $WARN -gt 0 ]]; then
    exit 2
else
    exit 0
fi
