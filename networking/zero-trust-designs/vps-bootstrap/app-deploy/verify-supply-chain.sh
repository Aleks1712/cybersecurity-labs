#!/usr/bin/env bash
# ============================================================================
# verify-supply-chain.sh — Pre-deploy checks for application dependencies
# ============================================================================
#
# Run this BEFORE 'docker compose up' on a new app or after dependency updates.
# It does NOT block deployment if findings are present — it surfaces them so
# you can review and accept the risk consciously.
#
# Checks performed:
#   1. Docker images: scan with trivy for known CVEs
#   2. Application dependencies: npm/pnpm/pip audit
#   3. Lockfile integrity (no surprises since last commit)
#   4. SBOM generation for the running stack
#   5. Container image signature verification (cosign, if signed)
#
# Usage:
#   ./verify-supply-chain.sh [--strict]
#
# --strict: exit non-zero on any HIGH/CRITICAL findings
# ============================================================================

set -uo pipefail

STRICT=false
[[ "${1:-}" == "--strict" ]] && STRICT=true

PROJECT_DIR="$(pwd)"
REPORT_DIR="${PROJECT_DIR}/supply-chain-reports/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$REPORT_DIR"

EXIT=0
red()    { printf '\033[31m[!] %s\033[0m\n' "$*"; }
yellow() { printf '\033[33m[?] %s\033[0m\n' "$*"; }
green()  { printf '\033[32m[+] %s\033[0m\n' "$*"; }
blue()   { printf '\033[34m[*] %s\033[0m\n' "$*"; }

# ---- 1. Trivy image scan ----
echo
blue "1. Scanning Docker images with Trivy..."

if ! command -v trivy >/dev/null 2>&1; then
    yellow "trivy not installed. Install via: brew install trivy / apt install trivy"
    yellow "Skipping image scan."
else
    # Extract image names from docker-compose.yml
    if [[ -f docker-compose.yml ]]; then
        IMAGES=$(docker compose config --images 2>/dev/null || true)
        if [[ -z "$IMAGES" ]]; then
            yellow "No images found in docker-compose.yml"
        else
            for img in $IMAGES; do
                blue "  Scanning $img..."
                trivy image --severity HIGH,CRITICAL --format table "$img" \
                    > "$REPORT_DIR/trivy-${img//\//_}.txt" 2>&1 || true
                # Count CRITICAL findings
                CRIT=$(grep -c "CRITICAL" "$REPORT_DIR/trivy-${img//\//_}.txt" 2>/dev/null || echo 0)
                if [[ "$CRIT" -gt 0 ]]; then
                    red "  $img: $CRIT CRITICAL findings (see $REPORT_DIR)"
                    $STRICT && EXIT=1
                else
                    green "  $img: no CRITICAL findings"
                fi
            done
        fi
    else
        yellow "No docker-compose.yml in current directory"
    fi
fi

# ---- 2. Application dependency audit ----
echo
blue "2. Application dependency audit..."

if [[ -f package.json ]]; then
    if [[ -f pnpm-lock.yaml ]]; then
        if command -v pnpm >/dev/null 2>&1; then
            blue "  Running 'pnpm audit'..."
            pnpm audit --prod --json > "$REPORT_DIR/pnpm-audit.json" 2>&1 || true
            HIGH=$(grep -c '"severity":"high"' "$REPORT_DIR/pnpm-audit.json" 2>/dev/null || echo 0)
            CRIT=$(grep -c '"severity":"critical"' "$REPORT_DIR/pnpm-audit.json" 2>/dev/null || echo 0)
            if [[ "$CRIT" -gt 0 || "$HIGH" -gt 0 ]]; then
                red "  pnpm audit: $CRIT critical, $HIGH high"
                $STRICT && EXIT=1
            else
                green "  pnpm audit: no high/critical findings"
            fi
        else
            yellow "  pnpm not installed"
        fi
    elif [[ -f package-lock.json ]]; then
        blue "  Running 'npm audit'..."
        npm audit --omit=dev --json > "$REPORT_DIR/npm-audit.json" 2>&1 || true
        # Parse JSON output for vulnerability counts
        if command -v jq >/dev/null 2>&1; then
            HIGH=$(jq '.metadata.vulnerabilities.high // 0' "$REPORT_DIR/npm-audit.json")
            CRIT=$(jq '.metadata.vulnerabilities.critical // 0' "$REPORT_DIR/npm-audit.json")
            if [[ "$CRIT" -gt 0 || "$HIGH" -gt 0 ]]; then
                red "  npm audit: $CRIT critical, $HIGH high"
                $STRICT && EXIT=1
            else
                green "  npm audit: no high/critical findings"
            fi
        fi
    fi
fi

if [[ -f requirements.txt || -f pyproject.toml ]]; then
    if command -v pip-audit >/dev/null 2>&1; then
        blue "  Running 'pip-audit'..."
        pip-audit --format=json > "$REPORT_DIR/pip-audit.json" 2>&1 || true
        green "  pip-audit complete (review $REPORT_DIR/pip-audit.json)"
    else
        yellow "  pip-audit not installed (pip install pip-audit)"
    fi
fi

# ---- 3. Lockfile integrity ----
echo
blue "3. Lockfile integrity check..."

# Check for uncommitted changes to lockfiles — if lockfile changed locally
# without being committed, that's a red flag (someone may have run install
# and we want to know what changed)
for lock in package-lock.json pnpm-lock.yaml yarn.lock requirements.txt poetry.lock Pipfile.lock; do
    if [[ -f "$lock" ]]; then
        if git diff --quiet "$lock" 2>/dev/null; then
            green "  $lock: clean (matches HEAD)"
        else
            yellow "  $lock: uncommitted changes — review before deploying"
            git diff --stat "$lock" 2>/dev/null || true
        fi
    fi
done

# ---- 4. Postinstall script detection (npm/pnpm specifically) ----
echo
blue "4. Scanning for postinstall scripts in npm dependencies..."

if [[ -d node_modules ]]; then
    # Find packages with postinstall, install, or preinstall scripts
    POSTINSTALL=$(find node_modules -maxdepth 3 -name package.json \
        -exec grep -l '"postinstall"\|"preinstall"\|"install"' {} + 2>/dev/null | wc -l)

    if [[ "$POSTINSTALL" -gt 50 ]]; then
        yellow "  Found $POSTINSTALL packages with install scripts (high count — review)"
        find node_modules -maxdepth 3 -name package.json \
            -exec grep -l '"postinstall"\|"preinstall"\|"install"' {} + 2>/dev/null \
            > "$REPORT_DIR/install-scripts.txt"
    elif [[ "$POSTINSTALL" -gt 0 ]]; then
        yellow "  Found $POSTINSTALL packages with install scripts"
    else
        green "  No packages with install scripts"
    fi
fi

# ---- 5. SBOM generation ----
echo
blue "5. SBOM generation..."

if command -v syft >/dev/null 2>&1; then
    blue "  Generating SBOM with syft..."
    syft "dir:$PROJECT_DIR" -o spdx-json > "$REPORT_DIR/sbom.spdx.json" 2>&1 || true
    green "  SBOM written to $REPORT_DIR/sbom.spdx.json"
else
    yellow "  syft not installed (https://github.com/anchore/syft)"
fi

# ---- 6. Cosign image signature check ----
echo
blue "6. Container image signature verification..."

if command -v cosign >/dev/null 2>&1; then
    if [[ -n "${IMAGES:-}" ]]; then
        for img in $IMAGES; do
            if cosign verify "$img" >/dev/null 2>&1; then
                green "  $img: signature verified"
            else
                yellow "  $img: not signed or signature unverifiable"
            fi
        done
    fi
else
    yellow "  cosign not installed (https://docs.sigstore.dev/cosign/installation)"
fi

# ---- Summary ----
echo
echo "============================================================"
echo " Supply chain check complete. Reports: $REPORT_DIR"
echo "============================================================"

if [[ $EXIT -ne 0 ]]; then
    red "Findings present. Review reports before deploying."
    exit 1
fi
