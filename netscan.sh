#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"

# Display usage information and available options
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

# Print the current version
show_version() {
    echo "netscan version ${VERSION}"
}

# Scan the top 20 most common ports using nmap
scan_ports() {
    local target="$1"
    echo "=== Port Scan (Top 20) ==="
    echo "Target: ${target}"
    echo ""
    nmap -Pn --top-ports 20 "$target" 2>/dev/null || echo "Error: nmap scan failed"
    echo ""
}

# Entry point: parse arguments and dispatch to scan functions
main() {
    local target=""
    local scan_type="all"

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

    if [[ -z "$target" && "$scan_type" != "" ]]; then
        if [[ "${scan_type}" == "all" || -n "${scan_type}" ]]; then
            echo "Error: --target is required for scanning" >&2
            echo "Run 'netscan.sh --help' for usage information." >&2
            exit 1
        fi
    fi

    echo "========================================"
    echo " Network Security Report"
    echo " Target: ${target}"
    echo " Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
    echo ""

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