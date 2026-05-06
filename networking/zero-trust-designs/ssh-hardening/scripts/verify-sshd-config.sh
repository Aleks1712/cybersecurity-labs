#!/usr/bin/env bash
# ============================================================================
# verify-sshd-config.sh — Pre-flight check before reloading sshd
# ============================================================================
#
# Usage: sudo ./verify-sshd-config.sh
#
# Runs sshd -t against the prospective config, checks that critical
# directives have expected values, and warns on common mistakes.
# Returns 0 if safe to reload, non-zero otherwise.
# ============================================================================

set -euo pipefail

SSHD_CONFIG="${SSHD_CONFIG:-/etc/ssh/sshd_config}"
EXIT=0

red() { printf '\033[31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }

# 1. Syntax check
echo "[*] Running sshd -t against $SSHD_CONFIG"
if ! sshd -t -f "$SSHD_CONFIG"; then
    red "[!] sshd -t failed. Refusing to proceed."
    exit 1
fi
green "[+] Syntax OK"

# 2. Critical directives — these MUST be set as expected
declare -A REQUIRED=(
    [PasswordAuthentication]=no
    [PermitRootLogin]=no
    [PermitEmptyPasswords]=no
    [KbdInteractiveAuthentication]=no
    [ChallengeResponseAuthentication]=no
    [HostbasedAuthentication]=no
    [PubkeyAuthentication]=yes
    [UsePAM]=yes
    [StrictModes]=yes
    [PermitUserEnvironment]=no
    [AllowAgentForwarding]=no
    [X11Forwarding]=no
    [LogLevel]=VERBOSE
)

# Get effective config (resolves Match blocks for default user)
EFFECTIVE=$(sshd -T -f "$SSHD_CONFIG" 2>/dev/null)

for key in "${!REQUIRED[@]}"; do
    expected="${REQUIRED[$key]}"
    actual=$(echo "$EFFECTIVE" | awk -v k="${key,,}" '$1 == k { print $2; exit }')
    if [[ -z "$actual" ]]; then
        yellow "[?] $key not set in effective config (expected: $expected)"
        EXIT=1
    elif [[ "${actual,,}" != "${expected,,}" ]]; then
        red "[!] $key=$actual (expected: $expected)"
        EXIT=1
    else
        green "[+] $key=$actual"
    fi
done

# 3. Crypto check — ensure no weak algorithms remain
echo
echo "[*] Checking for weak crypto..."
WEAK_PATTERNS=(
    "diffie-hellman-group1-sha1"
    "diffie-hellman-group14-sha1"
    "ssh-rsa[^-]"      # plain ssh-rsa (SHA-1), but allow rsa-sha2-*
    "hmac-md5"
    "hmac-sha1[^-]"
    "3des-cbc"
    "aes.*-cbc"
    "ecdsa-sha2-nistp"
)

for pattern in "${WEAK_PATTERNS[@]}"; do
    if echo "$EFFECTIVE" | grep -E "$pattern" >/dev/null 2>&1; then
        red "[!] Weak crypto detected: $pattern"
        EXIT=1
    fi
done

if [[ $EXIT -eq 0 ]]; then
    green "[+] No weak crypto found in effective config"
fi

# 4. Authorized_keys permission audit
echo
echo "[*] Auditing authorized_keys permissions..."
while IFS=: read -r user _ uid _ _ home _; do
    [[ $uid -lt 1000 ]] && continue
    [[ "$user" == "nobody" ]] && continue
    authkeys="$home/.ssh/authorized_keys"
    [[ ! -f "$authkeys" ]] && continue
    perms=$(stat -c %a "$authkeys")
    if [[ "$perms" != "600" ]]; then
        yellow "[?] $authkeys has permissions $perms (should be 600)"
        EXIT=1
    fi
done < /etc/passwd

if [[ $EXIT -eq 0 ]]; then
    green "[+] All authorized_keys files have correct permissions"
fi

# 5. Active session sanity check
echo
echo "[*] Active SSH sessions (you'll keep these on reload, lose them on restart):"
who | grep -E '(pts|tty)' || echo "    (none)"

echo
if [[ $EXIT -eq 0 ]]; then
    green "===================================="
    green " Safe to reload sshd"
    green " Run: sudo systemctl reload ssh"
    green "===================================="
else
    red "===================================="
    red " DO NOT reload until issues fixed"
    red "===================================="
fi

exit $EXIT
