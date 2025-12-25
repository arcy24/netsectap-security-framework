#!/bin/bash
#
# network-scan.sh - Automated network scanning wrapper
# Wraps nmap, masscan, and other tools for comprehensive network assessment
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SCAN_DIR="$PROJECT_ROOT/scans"
REPORTS_DIR="$PROJECT_ROOT/reports"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SCAN_TYPE="quick"
OUTPUT_FORMAT="all"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ENABLE_CVE=false

usage() {
    cat << EOF
Usage: $0 [OPTIONS] TARGET

Automated network scanning tool for security assessments

ARGUMENTS:
    TARGET              Target IP address, CIDR range, or hostname

OPTIONS:
    -t, --type TYPE     Scan type: quick, full, vuln, service, discovery
                        Default: quick
    -o, --output DIR    Output directory (default: $SCAN_DIR/nmap)
    -f, --format FMT    Output format: nmap, xml, gnmap, all
                        Default: all
    -p, --ports PORTS   Port specification (e.g., 80,443 or 1-1000)
    -n, --name NAME     Scan name/label for output files
    --cve               Enable automatic CVE vulnerability lookup after scan
    -h, --help          Show this help message

SCAN TYPES:
    quick      Fast scan of common 1000 ports (-T4)
    full       Full TCP port scan (1-65535)
    vuln       Vulnerability scan with NSE scripts
    service    Service/version detection (-sV)
    discovery  Host discovery only (ping scan)

EXAMPLES:
    # Quick scan of a single host
    $0 192.168.1.1

    # Full scan with custom name
    $0 --type full --name gateway 192.168.1.1

    # Vulnerability scan of subnet
    $0 --type vuln 192.168.1.0/24

    # Service detection on specific ports
    $0 --type service --ports 80,443,8080 example.com

REQUIREMENTS:
    - nmap (with NSE scripts for vuln scanning)
    - Root/sudo for some scan types

EOF
    exit 0
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_requirements() {
    if ! command -v nmap &> /dev/null; then
        log_error "nmap is not installed. Install with: sudo apt install nmap"
        exit 1
    fi
}

run_quick_scan() {
    local target="$1"
    local output_base="$2"

    log_info "Running quick scan on $target..."

    nmap -T4 -F \
        -oN "${output_base}.nmap" \
        -oX "${output_base}.xml" \
        -oG "${output_base}.gnmap" \
        "$target"
}

run_full_scan() {
    local target="$1"
    local output_base="$2"

    log_info "Running full port scan on $target (this may take a while)..."

    nmap -p- -T4 \
        -oN "${output_base}.nmap" \
        -oX "${output_base}.xml" \
        -oG "${output_base}.gnmap" \
        "$target"
}

run_vuln_scan() {
    local target="$1"
    local output_base="$2"

    log_info "Running vulnerability scan on $target..."
    log_warning "This requires NSE scripts and may take significant time"

    nmap -sV --script vuln \
        -oN "${output_base}.nmap" \
        -oX "${output_base}.xml" \
        -oG "${output_base}.gnmap" \
        "$target"
}

run_service_scan() {
    local target="$1"
    local output_base="$2"
    local ports="$3"

    log_info "Running service detection scan on $target..."

    if [ -n "$ports" ]; then
        nmap -sV -p "$ports" \
            -oN "${output_base}.nmap" \
            -oX "${output_base}.xml" \
            -oG "${output_base}.gnmap" \
            "$target"
    else
        nmap -sV \
            -oN "${output_base}.nmap" \
            -oX "${output_base}.xml" \
            -oG "${output_base}.gnmap" \
            "$target"
    fi
}

run_discovery_scan() {
    local target="$1"
    local output_base="$2"

    log_info "Running host discovery on $target..."

    nmap -sn \
        -oN "${output_base}.nmap" \
        -oX "${output_base}.xml" \
        -oG "${output_base}.gnmap" \
        "$target"
}

# Parse command line arguments
TARGET=""
SCAN_NAME=""
PORTS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            SCAN_TYPE="$2"
            shift 2
            ;;
        -o|--output)
            SCAN_DIR="$2"
            shift 2
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -p|--ports)
            PORTS="$2"
            shift 2
            ;;
        -n|--name)
            SCAN_NAME="$2"
            shift 2
            ;;
        --cve)
            ENABLE_CVE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            TARGET="$1"
            shift
            ;;
    esac
done

# Validate target
if [ -z "$TARGET" ]; then
    log_error "No target specified"
    usage
fi

# Check requirements
check_requirements

# Create output directory
mkdir -p "$SCAN_DIR/nmap"

# Generate output filename
if [ -z "$SCAN_NAME" ]; then
    CLEAN_TARGET=$(echo "$TARGET" | tr '/' '_' | tr ':' '_')
    OUTPUT_BASE="$SCAN_DIR/nmap/${CLEAN_TARGET}_${SCAN_TYPE}_${TIMESTAMP}"
else
    OUTPUT_BASE="$SCAN_DIR/nmap/${SCAN_NAME}_${SCAN_TYPE}_${TIMESTAMP}"
fi

log_info "Scan configuration:"
log_info "  Target: $TARGET"
log_info "  Type: $SCAN_TYPE"
log_info "  Output: $OUTPUT_BASE.*"

# Run the appropriate scan
case $SCAN_TYPE in
    quick)
        run_quick_scan "$TARGET" "$OUTPUT_BASE"
        ;;
    full)
        run_full_scan "$TARGET" "$OUTPUT_BASE"
        ;;
    vuln)
        run_vuln_scan "$TARGET" "$OUTPUT_BASE"
        ;;
    service)
        run_service_scan "$TARGET" "$OUTPUT_BASE" "$PORTS"
        ;;
    discovery)
        run_discovery_scan "$TARGET" "$OUTPUT_BASE"
        ;;
    *)
        log_error "Unknown scan type: $SCAN_TYPE"
        usage
        ;;
esac

log_success "Scan completed!"
log_info "Results saved to:"
log_info "  - ${OUTPUT_BASE}.nmap (human-readable)"
log_info "  - ${OUTPUT_BASE}.xml (XML format)"
log_info "  - ${OUTPUT_BASE}.gnmap (greppable format)"

# CVE lookup integration (if enabled)
if [ "$ENABLE_CVE" = true ]; then
    log_info "Running CVE vulnerability lookup..."

    if [ -f "${OUTPUT_BASE}.xml" ]; then
        "$SCRIPT_DIR/cve-lookup.sh" --xml "${OUTPUT_BASE}.xml" \
            --output "${OUTPUT_BASE}_cve.json" \
            --format json

        if [ $? -eq 0 ]; then
            log_success "CVE data saved to: ${OUTPUT_BASE}_cve.json"
        else
            log_warning "CVE lookup encountered errors (see above)"
        fi
    else
        log_warning "XML file not found, skipping CVE lookup"
    fi
fi

# Generate quick summary
if [ -f "${OUTPUT_BASE}.nmap" ]; then
    echo ""
    log_info "Quick summary:"
    echo "----------------------------------------"
    grep -E "Nmap scan report|open|filtered" "${OUTPUT_BASE}.nmap" | head -20
    echo "----------------------------------------"
fi

log_info "To generate a full report, run:"
log_info "  ./scripts/generate-report.sh ${OUTPUT_BASE}.xml"
