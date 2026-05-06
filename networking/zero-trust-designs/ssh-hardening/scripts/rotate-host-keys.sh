#!/usr/bin/env bash
# ============================================================================
# rotate-host-keys.sh — Rotate SSH host keys
# ============================================================================
#
# When to rotate:
#   - Suspected compromise of the host
#   - Major OS upgrade where keys may have been touched
#   - Periodic rotation per policy (NOT recommended without reason — rotation
#     creates a MITM window and known_hosts churn)
#
# What this does:
#   1. Backs up existing host keys
#   2. Generates new ed25519 (and optionally rsa) host keys
#   3. Prints new fingerprints for distribution
#   4. Does NOT reload sshd — that's a manual step after fingerprints are
#      distributed and clients are prepared
#
# Clients will see "REMOTE HOST IDENTIFICATION HAS CHANGED" until they
# update their known_hosts. Plan accordingly.
# ============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Must run as root" >&2
    exit 1
fi

BACKUP_DIR="/etc/ssh/keys-backup-$(date -u +%Y%m%dT%H%M%SZ)"
echo "[*] Backing up existing host keys to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
cp -p /etc/ssh/ssh_host_*key* "$BACKUP_DIR/"

echo "[*] Generating new ed25519 host key"
rm -f /etc/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key.pub
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N "" -C "$(hostname)-$(date -u +%Y%m%d)"

echo "[*] Generating new RSA-4096 host key (legacy compat)"
rm -f /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key.pub
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N "" -C "$(hostname)-$(date -u +%Y%m%d)"

# Remove ECDSA host key if present — we don't want clients negotiating it
if [[ -f /etc/ssh/ssh_host_ecdsa_key ]]; then
    echo "[*] Removing ECDSA host key (not used in our policy)"
    rm -f /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_ecdsa_key.pub
fi

# DSA is removed in modern OpenSSH but check anyway
if [[ -f /etc/ssh/ssh_host_dsa_key ]]; then
    echo "[*] Removing DSA host key (broken algorithm)"
    rm -f /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_dsa_key.pub
fi

# Set permissions
chmod 600 /etc/ssh/ssh_host_*_key
chmod 644 /etc/ssh/ssh_host_*_key.pub

echo
echo "============================================================"
echo " New host key fingerprints — DISTRIBUTE BEFORE RELOAD"
echo "============================================================"
for key in /etc/ssh/ssh_host_*_key.pub; do
    echo
    echo "Algorithm: $(basename "$key" .pub | sed 's/ssh_host_//;s/_key//')"
    ssh-keygen -lf "$key"
done

echo
echo "============================================================"
echo " Next steps:"
echo "   1. Distribute fingerprints to clients out-of-band"
echo "   2. Clients update their known_hosts:"
echo "        ssh-keygen -R <hostname>"
echo "        ssh-keyscan -t ed25519 <hostname> >> ~/.ssh/known_hosts.d/<env>"
echo "   3. ON THE SERVER: sudo systemctl reload ssh"
echo "   4. Verify a fresh connection works before closing this session"
echo "============================================================"
