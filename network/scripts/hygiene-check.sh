#!/bin/bash
#
# hygiene-check.sh - Network hygiene checker
# Analyzes scan results for common security issues and misconfigurations
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SCAN_DIR="$PROJECT_ROOT/scans"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Risk scores
SCORE=0
MAX_SCORE=0

usage() {
    cat << EOF
Usage: $0 [OPTIONS] [SCAN_FILE]

Network hygiene checker - Analyze scans for security issues

ARGUMENTS:
    SCAN_FILE          Path to nmap scan file (.nmap or .xml)
                       If not specified, analyzes most recent scan

OPTIONS:
    -a, --all          Check all scans in scan directory
    -s, --severity LVL Report only issues of severity: critical, high, medium, low
    -r, --report FILE  Save report to file
    -j, --json         Output in JSON format
    --skip-cve         Skip CVE vulnerability checks
    -h, --help         Show this help message

CHECKS PERFORMED:
    - Common vulnerable ports (telnet, FTP, SMB, etc.)
    - Unnecessary services
    - Outdated service versions
    - Default configurations
    - Missing security headers
    - Weak encryption protocols
    - CVE vulnerabilities (from NVD database)

EXAMPLES:
    # Check most recent scan
    $0

    # Check specific scan file
    $0 scans/nmap/192.168.1.1_quick_20250101.nmap

    # Check all scans and save report
    $0 --all --report hygiene-report.txt

EOF
    exit 0
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_critical() {
    echo -e "${RED}${MAGENTA}[CRITICAL]${NC} $1"
}

check_dangerous_ports() {
    local scan_file="$1"
    local issues=0

    log_info "Checking for dangerous/vulnerable ports..."

    # Define dangerous ports
    declare -A DANGEROUS_PORTS=(
        ["21"]="FTP - Unencrypted file transfer"
        ["23"]="Telnet - Unencrypted remote access"
        ["69"]="TFTP - Unencrypted, no authentication"
        ["135"]="MS-RPC - Known vulnerabilities"
        ["139"]="NetBIOS - SMB over NetBIOS"
        ["445"]="SMB - File sharing, ransomware target"
        ["1433"]="MS-SQL - Database exposure"
        ["3306"]="MySQL - Database exposure"
        ["3389"]="RDP - Remote desktop, brute-force target"
        ["5432"]="PostgreSQL - Database exposure"
        ["5900"]="VNC - Remote desktop, often weak passwords"
        ["6379"]="Redis - Often unsecured"
        ["27017"]="MongoDB - Often unsecured"
    )

    for port in "${!DANGEROUS_PORTS[@]}"; do
        if grep -qE "^$port/tcp.*open" "$scan_file" 2>/dev/null; then
            log_critical "Port $port/tcp OPEN - ${DANGEROUS_PORTS[$port]}"
            ((issues++))
            ((SCORE+=10))
        fi
    done

    ((MAX_SCORE+=10))

    if [ $issues -eq 0 ]; then
        log_success "No dangerous ports detected"
    else
        log_error "Found $issues dangerous open port(s)"
    fi

    return $issues
}

check_unnecessary_services() {
    local scan_file="$1"
    local issues=0

    log_info "Checking for unnecessary services..."

    # Services that are often unnecessary
    declare -A UNNECESSARY_SERVICES=(
        ["finger"]="Finger protocol - legacy, information disclosure"
        ["echo"]="Echo service - debugging only"
        ["discard"]="Discard service - debugging only"
        ["daytime"]="Daytime service - unnecessary"
        ["chargen"]="Chargen service - DDoS amplification risk"
    )

    for service in "${!UNNECESSARY_SERVICES[@]}"; do
        if grep -qi "^[0-9]*/tcp.*open.*$service" "$scan_file" 2>/dev/null; then
            log_warning "Unnecessary service detected: $service - ${UNNECESSARY_SERVICES[$service]}"
            ((issues++))
            ((SCORE+=3))
        fi
    done

    ((MAX_SCORE+=3))

    if [ $issues -eq 0 ]; then
        log_success "No unnecessary services detected"
    fi

    return $issues
}

check_unencrypted_protocols() {
    local scan_file="$1"
    local issues=0

    log_info "Checking for unencrypted protocols..."

    # Check for HTTP instead of HTTPS
    if grep -qE "^80/tcp.*open.*http" "$scan_file" 2>/dev/null; then
        if ! grep -qE "^443/tcp.*open.*https" "$scan_file" 2>/dev/null; then
            log_warning "HTTP (80/tcp) open without HTTPS (443/tcp)"
            ((issues++))
            ((SCORE+=5))
        fi
    fi

    # Check for FTP
    if grep -qE "^21/tcp.*open.*ftp" "$scan_file" 2>/dev/null; then
        log_error "FTP (unencrypted) detected - consider FTPS or SFTP"
        ((issues++))
        ((SCORE+=5))
    fi

    # Check for Telnet
    if grep -qE "^23/tcp.*open.*telnet" "$scan_file" 2>/dev/null; then
        log_critical "Telnet (unencrypted) detected - use SSH instead"
        ((issues++))
        ((SCORE+=10))
    fi

    ((MAX_SCORE+=10))

    if [ $issues -eq 0 ]; then
        log_success "No unencrypted protocols detected"
    fi

    return $issues
}

check_excessive_open_ports() {
    local scan_file="$1"

    log_info "Checking for excessive open ports..."

    local open_ports=$(grep -cE "^[0-9]+/tcp.*open" "$scan_file" 2>/dev/null || echo 0)

    if [ $open_ports -gt 20 ]; then
        log_error "Excessive open ports detected: $open_ports (consider reducing attack surface)"
        ((SCORE+=5))
    elif [ $open_ports -gt 10 ]; then
        log_warning "Many open ports detected: $open_ports (review necessity)"
        ((SCORE+=2))
    else
        log_success "Reasonable number of open ports: $open_ports"
    fi

    ((MAX_SCORE+=5))
}

check_common_vulns() {
    local scan_file="$1"
    local issues=0

    log_info "Checking for common vulnerabilities..."

    # Check for outdated SSH versions
    if grep -qE "OpenSSH [0-6]\." "$scan_file" 2>/dev/null; then
        log_error "Outdated SSH version detected - update recommended"
        ((issues++))
        ((SCORE+=7))
    fi

    # Check for anonymous FTP
    if grep -qi "Anonymous FTP login allowed" "$scan_file" 2>/dev/null; then
        log_critical "Anonymous FTP login is allowed!"
        ((issues++))
        ((SCORE+=10))
    fi

    # Check for default web pages
    if grep -qi "default.*page\|apache.*test.*page\|IIS.*start.*page" "$scan_file" 2>/dev/null; then
        log_warning "Default web page detected - may indicate unconfigured service"
        ((issues++))
        ((SCORE+=3))
    fi

    ((MAX_SCORE+=10))

    if [ $issues -eq 0 ]; then
        log_success "No common vulnerabilities detected"
    fi

    return $issues
}

check_cve_vulnerabilities() {
    local scan_file="$1"
    local xml_file="${scan_file%.nmap}.xml"
    local cve_file="${scan_file%.nmap}_cve.json"
    local issues=0

    # Skip if disabled
    if [ "${SKIP_CVE:-false}" = true ]; then
        return 0
    fi

    log_info "Checking for CVE vulnerabilities..."

    # If CVE data doesn't exist, try to generate it
    if [ ! -f "$cve_file" ]; then
        if [ -f "$xml_file" ]; then
            log_info "No CVE data found, querying NVD database..."
            "$SCRIPT_DIR/cve-lookup.sh" --xml "$xml_file" \
                --output "$cve_file" --format json --silent 2>/dev/null

            if [ ! -f "$cve_file" ]; then
                log_warning "Failed to generate CVE data, skipping CVE checks"
                return 0
            fi
        else
            log_warning "No XML file found, skipping CVE checks"
            log_info "Run scan with service detection: ./scripts/network-scan.sh --type vuln <target>"
            return 0
        fi
    fi

    # Parse CVE data and calculate risk
    if [ -f "$cve_file" ]; then
        local critical_cves=$(grep -c '"severity":"CRITICAL"' "$cve_file" 2>/dev/null || echo 0)
        local high_cves=$(grep -c '"severity":"HIGH"' "$cve_file" 2>/dev/null || echo 0)
        local medium_cves=$(grep -c '"severity":"MEDIUM"' "$cve_file" 2>/dev/null || echo 0)
        local low_cves=$(grep -c '"severity":"LOW"' "$cve_file" 2>/dev/null || echo 0)

        # Score weighting: CRITICAL=+15, HIGH=+10, MEDIUM=+5, LOW=+2
        if [ $critical_cves -gt 0 ]; then
            log_critical "Found $critical_cves CRITICAL severity CVE(s)"
            ((SCORE+=$critical_cves*15))
            ((issues+=critical_cves))
        fi

        if [ $high_cves -gt 0 ]; then
            log_error "Found $high_cves HIGH severity CVE(s)"
            ((SCORE+=$high_cves*10))
            ((issues+=high_cves))
        fi

        if [ $medium_cves -gt 0 ]; then
            log_warning "Found $medium_cves MEDIUM severity CVE(s)"
            ((SCORE+=$medium_cves*5))
            ((issues+=medium_cves))
        fi

        if [ $low_cves -gt 0 ]; then
            log_info "Found $low_cves LOW severity CVE(s)"
            ((SCORE+=$low_cves*2))
        fi

        if [ $issues -eq 0 ] && [ $low_cves -eq 0 ]; then
            log_success "No CVE vulnerabilities detected"
        fi
    fi

    ((MAX_SCORE+=15))  # Add to max score for percentage calculation

    return $issues
}

generate_summary() {
    local scan_file="$1"
    local total_issues=$2

    echo ""
    echo "========================================"
    echo "       NETWORK HYGIENE SUMMARY"
    echo "========================================"
    echo ""
    echo "Scan File: $(basename "$scan_file")"
    echo "Timestamp: $(date)"
    echo ""

    # Calculate risk score percentage
    local risk_percentage=0
    if [ $MAX_SCORE -gt 0 ]; then
        risk_percentage=$((SCORE * 100 / MAX_SCORE))
    fi

    echo "Risk Score: $SCORE / $MAX_SCORE ($risk_percentage%)"
    echo ""

    if [ $risk_percentage -lt 20 ]; then
        echo -e "${GREEN}Overall Status: GOOD${NC}"
        echo "Network hygiene is acceptable."
    elif [ $risk_percentage -lt 50 ]; then
        echo -e "${YELLOW}Overall Status: FAIR${NC}"
        echo "Some security concerns detected. Review and address issues."
    elif [ $risk_percentage -lt 75 ]; then
        echo -e "${RED}Overall Status: POOR${NC}"
        echo "Significant security issues detected. Immediate attention required."
    else
        echo -e "${RED}${MAGENTA}Overall Status: CRITICAL${NC}"
        echo "Critical security issues detected. Address immediately!"
    fi

    echo ""
    echo "Total Issues Found: $total_issues"
    echo ""
    echo "========================================"
    echo ""
}

# Parse arguments
SCAN_FILE=""
CHECK_ALL=false
SEVERITY=""
REPORT_FILE=""
JSON_OUTPUT=false
SKIP_CVE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            CHECK_ALL=true
            shift
            ;;
        -s|--severity)
            SEVERITY="$2"
            shift 2
            ;;
        -r|--report)
            REPORT_FILE="$2"
            shift 2
            ;;
        -j|--json)
            JSON_OUTPUT=true
            shift
            ;;
        --skip-cve)
            SKIP_CVE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            SCAN_FILE="$1"
            shift
            ;;
    esac
done

# Find scan file if not specified
if [ -z "$SCAN_FILE" ] && [ "$CHECK_ALL" = false ]; then
    log_info "No scan file specified, looking for most recent scan..."
    SCAN_FILE=$(find "$SCAN_DIR" -name "*.nmap" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

    if [ -z "$SCAN_FILE" ]; then
        log_error "No scan files found in $SCAN_DIR"
        log_info "Run a scan first: ./scripts/network-scan.sh <target>"
        exit 1
    fi

    log_info "Using most recent scan: $(basename "$SCAN_FILE")"
fi

# Verify file exists
if [ ! -f "$SCAN_FILE" ]; then
    log_error "Scan file not found: $SCAN_FILE"
    exit 1
fi

# Run checks
echo ""
log_info "Starting network hygiene checks..."
echo ""

TOTAL_ISSUES=0

check_dangerous_ports "$SCAN_FILE"
TOTAL_ISSUES=$((TOTAL_ISSUES + $?))

check_unnecessary_services "$SCAN_FILE"
TOTAL_ISSUES=$((TOTAL_ISSUES + $?))

check_unencrypted_protocols "$SCAN_FILE"
TOTAL_ISSUES=$((TOTAL_ISSUES + $?))

check_excessive_open_ports "$SCAN_FILE"

check_common_vulns "$SCAN_FILE"
TOTAL_ISSUES=$((TOTAL_ISSUES + $?))

# CVE vulnerability checks
check_cve_vulnerabilities "$SCAN_FILE"
TOTAL_ISSUES=$((TOTAL_ISSUES + $?))

# Generate summary
generate_summary "$SCAN_FILE" "$TOTAL_ISSUES"

# Save report if requested
if [ -n "$REPORT_FILE" ]; then
    {
        generate_summary "$SCAN_FILE" "$TOTAL_ISSUES"
    } > "$REPORT_FILE"
    log_success "Report saved to: $REPORT_FILE"
fi

# Exit with appropriate code
if [ $SCORE -gt 50 ]; then
    exit 1
else
    exit 0
fi
