#!/usr/bin/env bash
# Fail fast on errors and undefined variables.
set -euo pipefail

# Script version.
VERSION="1.0.0"
echo $VERSION

# Show usage information.
usage() {
    cat <<EOF
netscan - Network Security Scanner

Usage: netscan.sh [OPTIONS]

Options:
    --help              Show this help message
    --version           Show version information
    --target DOMAIN     Target domain to scan (required for scans)
    --scan TYPE         Scan type: ports, ssl, headers, dns, or all (default: all)

Scan Types:
    ports       Scan top 20 common ports using nmap
    ssl         Check SSL/TLS certificate expiry
    headers     Inspect HTTP security headers
    dns         Look up DNS records (A, MX, NS)
    all         Run all scans

Examples:
    netscan.sh --target example.com --scan all
    netscan.sh --target example.com --scan ssl
EOF
}

# Show the current script version.
show_version() {
    echo "netscan version ${VERSION}"
}

# Scan the top 20 ports on the target host.
scan_ports() {
    local target="$1"
    echo "=== Port Scan (Top 20) ==="
    echo "Target: ${target}"
    echo ""
    nmap -Pn --top-ports 20 "$target" 2>/dev/null || echo "Error: nmap scan failed"
    echo ""
}

# Check SSL/TLS certificate expiry.
scan_ssl() {
    local target="$1"
    echo "=== SSL/TLS Certificate Check ==="
    echo "Target: ${target}:443"
    echo ""

    local expiry_str
    expiry_str=$(openssl s_client -connect "${target}:443" -servername "$target" \
        </dev/null 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null \
        | cut -d= -f2)

    if [[ -z "$expiry_str" ]]; then
        echo "Error: Could not retrieve SSL certificate"
        echo ""
        return 1
    fi

    local expiry_epoch now_epoch days_left
    expiry_epoch=$(date -d "$expiry_str" +%s)
    now_epoch=$(date +%s)
    days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

    echo "Certificate expires: ${expiry_str}"
    echo "Days remaining: ${days_left}"

    if [[ $days_left -lt 0 ]]; then
        echo "Status: EXPIRED"
    elif [[ $days_left -lt 30 ]]; then
        echo "Status: WARNING (expires within 30 days)"
    else
        echo "Status: OK"
    fi
    echo ""
}

# Inspect common HTTP security headers.
scan_headers() {
    local target="$1"
    echo "=== HTTP Security Headers ==="
    echo "Target: https://${target}"
    echo ""

    local headers
    headers=$(curl -sI -m 10 "https://${target}" 2>/dev/null) || {
        echo "Error: Could not connect to https://${target}"
        echo ""
        return 1
    }

    local -a check_headers=("Strict-Transport-Security" "X-Frame-Options" "X-Content-Type-Options" "Content-Security-Policy")

    for header in "${check_headers[@]}"; do
        if echo "$headers" | grep -qi "^${header}:"; then
            local value
            value=$(echo "$headers" | grep -i "^${header}:" | head -1 | cut -d: -f2- | xargs)
            echo "[PASS] ${header}: ${value}"
        else
            echo "[MISSING] ${header}"
        fi
    done
    echo ""
}

# Look up key DNS record types.
scan_dns() {
    local target="$1"
    echo "=== DNS Records ==="
    echo "Target: ${target}"
    echo ""

    echo "-- A Records --"
    host -t A "$target" 2>/dev/null || echo "No A records found"
    echo ""

    echo "-- MX Records --"
    host -t MX "$target" 2>/dev/null || echo "No MX records found"
    echo ""

    echo "-- NS Records --"
    host -t NS "$target" 2>/dev/null || echo "No NS records found"
    echo ""
}

# Parse arguments and run the requested scan.
main() {
    local target=""
    local scan_type="all"

    # Read supported command-line options.
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help)
                usage
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            --target)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --target requires a domain argument" >&2
                    exit 1
                fi
                target="$2"
                shift 2
                ;;
            --scan)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --scan requires a type argument" >&2
                    exit 1
                fi
                scan_type="$2"
                shift 2
                ;;
            *)
                echo "Error: Unknown option '$1'" >&2
                echo "Run 'netscan.sh --help' for usage information." >&2
                exit 1
                ;;
        esac
    done

    # Require a target whenever a scan is requested.
    if [[ -z "$target" && "$scan_type" != "" ]]; then
        if [[ "${scan_type}" == "all" || -n "${scan_type}" ]]; then
            echo "Error: --target is required for scanning" >&2
            echo "Run 'netscan.sh --help' for usage information." >&2
            exit 1
        fi
    fi

    # Print the report header.
    echo "========================================"
    echo " Network Security Report"
    echo " Target: ${target}"
    echo " Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
    echo ""

    # Run the selected scan type.
    case "${scan_type}" in
        ports)   scan_ports "$target" ;;
        ssl)     scan_ssl "$target" ;;
        headers) scan_headers "$target" ;;
        dns)     scan_dns "$target" ;;
        all)
            scan_ports "$target"
            scan_ssl "$target"
            scan_headers "$target"
            scan_dns "$target"
            ;;
        *)
            echo "Error: Unknown scan type '${scan_type}'" >&2
            echo "Valid types: ports, ssl, headers, dns, all" >&2
            exit 1
            ;;
    esac
}

main "$@"