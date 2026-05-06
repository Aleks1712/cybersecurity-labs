#!/usr/bin/env bash
# ============================================================================
# audit-authorized-keys.sh — Find stale and risky authorized_keys
# ============================================================================
#
# Usage: sudo ./audit-authorized-keys.sh [--json]
#
# Iterates all home directories, parses each authorized_keys file, and reports:
#   - Keys without source restrictions (no from=)
#   - Keys without expiry (no expiry-time=)
#   - Keys using deprecated algorithms (ssh-rsa with SHA-1, ssh-dss)
#   - Keys with overly permissive options (no restriction)
#   - Files with wrong permissions
#
# This is a hygiene tool — run it weekly, fix what it flags.
# ============================================================================

set -euo pipefail

JSON=false
[[ "${1:-}" == "--json" ]] && JSON=true

if [[ $EUID -ne 0 ]]; then
    echo "Must run as root to read all home directories" >&2
    exit 1
fi

declare -a FINDINGS

check_authkeys() {
    local user="$1"
    local file="$2"

    # Permission check
    local perms
    perms=$(stat -c %a "$file")
    if [[ "$perms" != "600" ]]; then
        FINDINGS+=("$user|$file|PERMS|File mode is $perms, should be 600")
    fi

    # Read each non-comment, non-empty line
    local lineno=0
    while IFS= read -r line; do
        lineno=$((lineno + 1))
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Detect deprecated algorithms
        if [[ "$line" =~ ^ssh-rsa[[:space:]] ]] || [[ "$line" =~ [[:space:]]ssh-rsa[[:space:]] ]]; then
            FINDINGS+=("$user|$file:$lineno|ALGO|Plain ssh-rsa key (SHA-1 signatures), should rotate to ed25519")
        fi
        if [[ "$line" =~ [[:space:]]?ssh-dss[[:space:]] ]]; then
            FINDINGS+=("$user|$file:$lineno|ALGO|ssh-dss (DSA) key, broken algorithm, REMOVE")
        fi

        # Detect missing from= restriction
        if ! [[ "$line" =~ from= ]]; then
            FINDINGS+=("$user|$file:$lineno|SCOPE|No from= source restriction")
        fi

        # Detect missing restrict / no-* options
        if ! [[ "$line" =~ (restrict|no-port-forwarding) ]]; then
            FINDINGS+=("$user|$file:$lineno|OPTS|No 'restrict' or 'no-*' options — full forwarding allowed")
        fi

        # Detect missing expiry on automation-style keys (heuristic: if key has command=, expect expiry)
        if [[ "$line" =~ command= ]] && ! [[ "$line" =~ expiry-time= ]]; then
            FINDINGS+=("$user|$file:$lineno|EXPIRY|Forced-command key without expiry-time=")
        fi

        # Extract fingerprint for reporting
        local tmpfile
        tmpfile=$(mktemp)
        echo "$line" > "$tmpfile"
        local fp
        fp=$(ssh-keygen -lf "$tmpfile" 2>/dev/null | awk '{print $2}') || fp="(unparseable)"
        rm -f "$tmpfile"
        FINDINGS+=("$user|$file:$lineno|FP|$fp")
    done < "$file"
}

# Iterate home directories
while IFS=: read -r user _ uid _ _ home _; do
    [[ $uid -lt 1000 ]] && [[ $uid -ne 0 ]] && continue
    [[ "$user" == "nobody" ]] && continue
    [[ ! -d "$home/.ssh" ]] && continue

    for f in "$home/.ssh/authorized_keys" "$home/.ssh/authorized_keys2"; do
        [[ -f "$f" ]] && check_authkeys "$user" "$f"
    done
done < /etc/passwd

# Also check root explicitly
[[ -f /root/.ssh/authorized_keys ]] && check_authkeys "root" "/root/.ssh/authorized_keys"

# Report
if $JSON; then
    printf '['
    first=true
    for finding in "${FINDINGS[@]}"; do
        IFS='|' read -r u f c m <<< "$finding"
        $first || printf ','
        first=false
        printf '{"user":"%s","location":"%s","category":"%s","message":"%s"}' "$u" "$f" "$c" "$m"
    done
    printf ']\n'
else
    if [[ ${#FINDINGS[@]} -eq 0 ]]; then
        echo "[+] No findings. Authorized_keys hygiene looks clean."
        exit 0
    fi
    echo
    echo "============================================================"
    echo " authorized_keys audit findings"
    echo "============================================================"
    printf '%-12s %-50s %-8s %s\n' "USER" "LOCATION" "CATEGORY" "MESSAGE"
    echo "------------------------------------------------------------"
    for finding in "${FINDINGS[@]}"; do
        IFS='|' read -r u f c m <<< "$finding"
        printf '%-12s %-50s %-8s %s\n' "$u" "$f" "$c" "$m"
    done
    echo
fi
