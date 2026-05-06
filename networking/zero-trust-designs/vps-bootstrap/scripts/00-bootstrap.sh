#!/usr/bin/env bash
# ============================================================================
# 00-bootstrap.sh — Idempotent VPS bootstrap orchestrator
# ============================================================================
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<you>/<repo>/main/networking/zero-trust-designs/vps-bootstrap/scripts/00-bootstrap.sh | sudo bash -s -- --user <username> --mesh tailscale
#
#   ^ Yes, the irony: this script is exactly the kind of "curl | bash" pattern
#     I tell people to be skeptical of. For a bootstrap-from-scratch flow on a
#     box you control, it's acceptable. For anything else, clone the repo,
#     read it, then run it.
#
# Or, more carefully (recommended):
#   git clone <repo>
#   cd <repo>/networking/zero-trust-designs/vps-bootstrap
#   sudo ./scripts/00-bootstrap.sh --user sasha --mesh tailscale
#
# Flags:
#   --user <name>          Required. Username to create with sudo + ssh-users
#   --mesh tailscale|wg    Required. VPN mesh implementation
#   --ssh-key <path>       Required. Path to public key to install for --user
#   --hostname <name>      Optional. Set system hostname
#   --skip-reboot          Optional. Don't reboot after kernel updates
#   --dry-run              Print what would run, don't execute
# ============================================================================

set -euo pipefail

# ------------------------- Argument parsing -------------------------
USERNAME=""
MESH=""
SSH_KEY=""
HOSTNAME=""
SKIP_REBOOT=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --user) USERNAME="$2"; shift 2 ;;
        --mesh) MESH="$2"; shift 2 ;;
        --ssh-key) SSH_KEY="$2"; shift 2 ;;
        --hostname) HOSTNAME="$2"; shift 2 ;;
        --skip-reboot) SKIP_REBOOT=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        *) echo "Unknown arg: $1" >&2; exit 2 ;;
    esac
done

# ------------------------- Validation -------------------------
[[ $EUID -eq 0 ]] || { echo "Must run as root (use sudo)" >&2; exit 1; }
[[ -n "$USERNAME" ]] || { echo "--user required" >&2; exit 2; }
[[ "$MESH" =~ ^(tailscale|wg)$ ]] || { echo "--mesh must be 'tailscale' or 'wg'" >&2; exit 2; }
[[ -n "$SSH_KEY" && -f "$SSH_KEY" ]] || { echo "--ssh-key required and must exist" >&2; exit 2; }

# Logging
LOG_DIR=/var/log/vps-bootstrap
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date -u +%Y%m%dT%H%M%SZ).log"
exec > >(tee -a "$LOG_FILE") 2>&1

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
blue()   { printf '\033[34m%s\033[0m\n' "$*"; }

run() {
    if $DRY_RUN; then
        echo "[DRY-RUN] $*"
    else
        eval "$@"
    fi
}

step() {
    echo
    blue "============================================================"
    blue " $*"
    blue "============================================================"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ------------------------- 1. Base hardening -------------------------
step "Step 1/9: Base system hardening"

run "apt-get update -qq"
run "DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq"
run "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    sudo curl ca-certificates gnupg ufw fail2ban \
    unattended-upgrades apt-listchanges \
    auditd net-tools dnsutils \
    lsb-release apt-transport-https"

# Hostname
if [[ -n "$HOSTNAME" ]]; then
    run "hostnamectl set-hostname '$HOSTNAME'"
fi

# Timezone (UTC for servers — local time creates surprises in logs)
run "timedatectl set-timezone UTC"

# Create user if not exists
if ! id "$USERNAME" >/dev/null 2>&1; then
    run "adduser --disabled-password --gecos '' '$USERNAME'"
fi
run "groupadd -f ssh-users"
run "usermod -aG sudo,ssh-users '$USERNAME'"

# Sudo: no password for this user (since SSH is pubkey-only and we trust the key)
# Comment this out if you prefer password sudo
SUDO_FILE="/etc/sudoers.d/90-$USERNAME"
if ! $DRY_RUN; then
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "$SUDO_FILE"
    chmod 440 "$SUDO_FILE"
    visudo -cf "$SUDO_FILE" || { red "sudoers syntax error"; exit 1; }
fi

# Install user's SSH key
USER_SSH_DIR="/home/$USERNAME/.ssh"
run "mkdir -p '$USER_SSH_DIR'"
run "cat '$SSH_KEY' >> '$USER_SSH_DIR/authorized_keys'"
# Dedupe authorized_keys (idempotency)
if ! $DRY_RUN; then
    sort -u "$USER_SSH_DIR/authorized_keys" -o "$USER_SSH_DIR/authorized_keys"
fi
run "chmod 700 '$USER_SSH_DIR'"
run "chmod 600 '$USER_SSH_DIR/authorized_keys'"
run "chown -R '$USERNAME:$USERNAME' '$USER_SSH_DIR'"

green "[+] Base hardening complete"

# ------------------------- 2. SSH hardening -------------------------
step "Step 2/9: SSH hardening (referencing ssh-hardening lab)"

SSH_LAB="$LAB_ROOT/../ssh-hardening"
if [[ ! -d "$SSH_LAB" ]]; then
    yellow "[!] ssh-hardening lab not found at $SSH_LAB"
    yellow "    Falling back to inline minimal config. For full hardening,"
    yellow "    clone the ssh-hardening lab and re-run this script."
    INLINE_SSH=true
else
    INLINE_SSH=false
fi

run "cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.\$(date +%F)"

if ! $INLINE_SSH; then
    run "cp '$SSH_LAB/server-config/sshd_config' /etc/ssh/sshd_config"
    run "mkdir -p /etc/ssh/sshd_config.d"
    run "cp '$SSH_LAB'/server-config/sshd_config.d/*.conf /etc/ssh/sshd_config.d/"
    run "chmod 600 /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf"
else
    # Inline minimal hardening if ssh-hardening lab is unavailable
    if ! $DRY_RUN; then
        cat > /etc/ssh/sshd_config.d/99-vps-bootstrap.conf <<'EOF'
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
AllowGroups ssh-users
MaxAuthTries 3
LoginGraceTime 30s
LogLevel VERBOSE
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
UseDNS no
EOF
        chmod 600 /etc/ssh/sshd_config.d/99-vps-bootstrap.conf
    fi
fi

# Validate before reload
if ! $DRY_RUN; then
    if ! sshd -t; then
        red "[!] sshd config validation FAILED. Aborting before reload."
        red "[!] Restoring backup."
        cp /etc/ssh/sshd_config.bak.* /etc/ssh/sshd_config
        exit 1
    fi
fi
run "systemctl reload ssh"

green "[+] SSH hardened. Reloaded with backup at /etc/ssh/sshd_config.bak.*"

# ------------------------- 3. Firewall (UFW) -------------------------
step "Step 3/9: UFW firewall"

run "ufw --force reset"
run "ufw default deny incoming"
run "ufw default allow outgoing"
run "ufw default deny forward"

# Mesh-specific ingress rules
case "$MESH" in
    tailscale)
        # Tailscale uses NAT traversal — no inbound port needed in most cases
        # but we allow tailscale0 interface
        run "ufw allow in on tailscale0"
        ;;
    wg)
        # WireGuard listens on UDP 51820 by default
        run "ufw allow 51820/udp comment 'WireGuard'"
        run "ufw allow in on wg0"
        ;;
esac

# DO NOT open SSH publicly — SSH is reachable via mesh only
# If for some reason you need a break-glass public SSH (cloud console isn't
# always available), uncomment below and accept the risk:
# run "ufw allow 22/tcp comment 'SSH break-glass'"

run "ufw --force enable"
run "ufw status verbose"

green "[+] UFW active with default-deny inbound, mesh-only ingress"

# ------------------------- 4. Fail2ban -------------------------
step "Step 4/9: Fail2ban (defense-in-depth)"

if [[ -f "$LAB_ROOT/fail2ban/jail.local" ]]; then
    run "cp '$LAB_ROOT/fail2ban/jail.local' /etc/fail2ban/jail.local"
fi
run "systemctl enable --now fail2ban"
run "fail2ban-client status"

green "[+] Fail2ban active (note: this is hygiene, not primary defense)"

# ------------------------- 5. VPN mesh -------------------------
step "Step 5/9: VPN mesh ($MESH)"

case "$MESH" in
    tailscale)
        # Install tailscale per official instructions
        if ! command -v tailscale >/dev/null 2>&1; then
            run "curl -fsSL https://tailscale.com/install.sh | sh"
        fi
        # Verify the install script's signature/hash if available — left to operator
        run "systemctl enable --now tailscaled"

        yellow "[?] Manual step required:"
        yellow "    Run 'sudo tailscale up --ssh --advertise-tags=tag:vps'"
        yellow "    (or your tag of choice). Pre-authkey can be passed via --authkey."
        yellow "    See tailscale/setup-notes.md for ACL examples."
        ;;
    wg)
        run "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq wireguard wireguard-tools"
        yellow "[?] Manual step required:"
        yellow "    Configure /etc/wireguard/wg0.conf using wireguard/server.conf.example"
        yellow "    Then: systemctl enable --now wg-quick@wg0"
        ;;
esac

green "[+] Mesh installed (manual config step pending)"

# ------------------------- 6. Docker -------------------------
step "Step 6/9: Docker engine + compose plugin"

if ! command -v docker >/dev/null 2>&1; then
    # Official Docker repo (not snap, not docker.io from Ubuntu — those are stale or wrong)
    run "install -m 0755 -d /etc/apt/keyrings"
    run "curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc"
    run "chmod a+r /etc/apt/keyrings/docker.asc"
    run "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" > /etc/apt/sources.list.d/docker.list"
    run "apt-get update -qq"
    run "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
fi

# Hardened daemon.json
if [[ -f "$LAB_ROOT/docker/daemon.json" ]]; then
    run "mkdir -p /etc/docker"
    run "cp '$LAB_ROOT/docker/daemon.json' /etc/docker/daemon.json"
    run "systemctl restart docker"
fi

run "usermod -aG docker '$USERNAME'"

green "[+] Docker installed with hardened daemon config"

# ------------------------- 7. Unattended upgrades -------------------------
step "Step 7/9: Automatic security updates"

if [[ -f "$LAB_ROOT/unattended-upgrades/50unattended-upgrades" ]]; then
    run "cp '$LAB_ROOT/unattended-upgrades/50unattended-upgrades' /etc/apt/apt.conf.d/"
fi
if [[ -f "$LAB_ROOT/unattended-upgrades/20auto-upgrades" ]]; then
    run "cp '$LAB_ROOT/unattended-upgrades/20auto-upgrades' /etc/apt/apt.conf.d/"
fi
run "systemctl enable --now unattended-upgrades.service"

green "[+] Unattended security upgrades active"

# ------------------------- 8. Auditd rules -------------------------
step "Step 8/9: Auditd rules"

if ! $DRY_RUN; then
    cat > /etc/audit/rules.d/vps-bootstrap.rules <<'EOF'
# SSH config tampering
-w /etc/ssh/sshd_config -p wa -k sshd_config_change
-w /etc/ssh/sshd_config.d/ -p wa -k sshd_config_change
-w /etc/ssh/ssh_host_ed25519_key -p wa -k sshd_hostkey_change

# Sudo / privilege escalation
-w /etc/sudoers -p wa -k sudo_change
-w /etc/sudoers.d/ -p wa -k sudo_change

# User/group changes
-w /etc/passwd -p wa -k user_change
-w /etc/shadow -p wa -k user_change
-w /etc/group -p wa -k user_change

# Authorized keys tampering
-w /home -p wa -k authkeys_change
-w /root/.ssh/ -p wa -k authkeys_change

# Docker socket — anyone hitting this gets root-equivalent
-w /var/run/docker.sock -p wa -k docker_socket
EOF
fi

run "augenrules --load"
run "systemctl restart auditd || true"

green "[+] Auditd rules loaded"

# ------------------------- 9. Verify -------------------------
step "Step 9/9: Verification"

if [[ -f "$SCRIPT_DIR/99-verify.sh" ]]; then
    run "bash '$SCRIPT_DIR/99-verify.sh'"
else
    yellow "[?] 99-verify.sh not found. Run manual checks per README."
fi

# Final reboot if kernel updated
if ! $SKIP_REBOOT && [[ -f /var/run/reboot-required ]]; then
    yellow "[?] Kernel update pending. Rebooting in 30 seconds (Ctrl-C to cancel)..."
    if ! $DRY_RUN; then
        sleep 30
        systemctl reboot
    fi
fi

green
green "============================================================"
green " Bootstrap complete. Log: $LOG_FILE"
green "============================================================"
green
green " Next steps:"
green "   1. Complete mesh authentication (tailscale up, or wg0.conf)"
green "   2. Verify mesh-only access:"
green "      - From mesh: ssh $USERNAME@<mesh-ip>"
green "      - From public internet: ssh should fail / time out"
green "   3. Deploy app via docker compose (see app-deploy/)"
green "   4. Document this server in your inventory"
green
