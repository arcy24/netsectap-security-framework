#!/bin/bash
#
# generate-report.sh - Generate markdown reports from scan results
# Parses nmap XML output and creates formatted reports
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="$PROJECT_ROOT/reports"
TEMPLATES_DIR="$PROJECT_ROOT/templates"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $0 [OPTIONS] SCAN_FILE

Generate markdown reports from nmap scan results

ARGUMENTS:
    SCAN_FILE          Path to nmap XML file (.xml)

OPTIONS:
    -o, --output FILE  Output markdown file (auto-generated if not specified)
    -t, --template     Use custom template
    -f, --format FMT   Report format: markdown, html, json
                       Default: markdown
    -h, --help         Show this help message

EXAMPLES:
    # Generate report from XML scan
    $0 scans/nmap/192.168.1.1_quick_20250101_120000.xml

    # Specify output file
    $0 -o reports/gateway-scan.md scans/nmap/gateway.xml

REQUIREMENTS:
    - xsltproc (for XML parsing)
    - Optional: pandoc (for HTML conversion)

EOF
    exit 0
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_requirements() {
    if ! command -v xmllint &> /dev/null && ! command -v xsltproc &> /dev/null; then
        log_error "xmllint or xsltproc is required. Install with: sudo apt install libxml2-utils xsltproc"
        exit 1
    fi
}

generate_cve_section() {
    local xml_file="$1"
    local output_file="$2"
    local cve_file="${xml_file%.xml}_cve.json"

    echo "" >> "$output_file"
    echo "---" >> "$output_file"
    echo "" >> "$output_file"
    echo "## CVE Vulnerability Analysis" >> "$output_file"
    echo "" >> "$output_file"

    # Check if CVE data exists
    if [ ! -f "$cve_file" ]; then
        echo "_CVE analysis not available. Run scan with \`--cve\` flag or use \`cve-lookup.sh\` to generate CVE data._" >> "$output_file"
        echo "" >> "$output_file"
        echo '```bash' >> "$output_file"
        echo "# To generate CVE data for this scan:" >> "$output_file"
        echo "./scripts/cve-lookup.sh --xml $xml_file" >> "$output_file"
        echo '```' >> "$output_file"
        echo "" >> "$output_file"
        return 0
    fi

    # Count vulnerabilities by severity
    local critical_count=$(grep -c '"severity":"CRITICAL"' "$cve_file" 2>/dev/null || echo 0)
    local high_count=$(grep -c '"severity":"HIGH"' "$cve_file" 2>/dev/null || echo 0)
    local medium_count=$(grep -c '"severity":"MEDIUM"' "$cve_file" 2>/dev/null || echo 0)
    local low_count=$(grep -c '"severity":"LOW"' "$cve_file" 2>/dev/null || echo 0)
    local total_count=$((critical_count + high_count + medium_count + low_count))

    # Summary table
    echo "### Vulnerability Summary" >> "$output_file"
    echo "" >> "$output_file"
    echo "| Severity | Count |" >> "$output_file"
    echo "|----------|-------|" >> "$output_file"
    echo "| 🔴 Critical | $critical_count |" >> "$output_file"
    echo "| 🟠 High | $high_count |" >> "$output_file"
    echo "| 🟡 Medium | $medium_count |" >> "$output_file"
    echo "| 🟢 Low | $low_count |" >> "$output_file"
    echo "| **Total** | **$total_count** |" >> "$output_file"
    echo "" >> "$output_file"

    # Risk assessment
    echo "### Risk Assessment" >> "$output_file"
    echo "" >> "$output_file"

    if [ $critical_count -gt 0 ]; then
        echo "🚨 **IMMEDIATE ACTION REQUIRED**: $critical_count critical vulnerabilit(ies) detected that could lead to system compromise." >> "$output_file"
        echo "" >> "$output_file"
        echo "**Recommendation:** Prioritize patching or mitigation for all CRITICAL CVEs immediately." >> "$output_file"
    elif [ $high_count -gt 0 ]; then
        echo "⚠️ **HIGH PRIORITY**: $high_count high severity vulnerabilit(ies) require attention and patching." >> "$output_file"
        echo "" >> "$output_file"
        echo "**Recommendation:** Plan patching activities within the next 7-14 days." >> "$output_file"
    elif [ $medium_count -gt 0 ]; then
        echo "⚡ **MODERATE RISK**: $medium_count medium severity vulnerabilit(ies) identified." >> "$output_file"
        echo "" >> "$output_file"
        echo "**Recommendation:** Consider updating affected services during next maintenance window." >> "$output_file"
    elif [ $low_count -gt 0 ]; then
        echo "ℹ️ **LOW RISK**: $low_count low severity vulnerabilit(ies) detected." >> "$output_file"
        echo "" >> "$output_file"
        echo "**Recommendation:** Track and address during regular update cycles." >> "$output_file"
    else
        echo "✅ **EXCELLENT**: No CVE vulnerabilities detected in scanned services." >> "$output_file"
        echo "" >> "$output_file"
        echo "**Note:** Continue regular scanning to maintain security posture." >> "$output_file"
    fi

    echo "" >> "$output_file"

    # Detailed findings (if critical or high severity)
    if [ $critical_count -gt 0 ] || [ $high_count -gt 0 ]; then
        echo "### Detailed CVE Findings" >> "$output_file"
        echo "" >> "$output_file"
        echo "_For complete CVE details, CVSS scores, and descriptions, see: \`$(basename "$cve_file")\`_" >> "$output_file"
        echo "" >> "$output_file"

        # Parse services with CVEs from JSON
        if command -v grep &>/dev/null; then
            echo "**Services with vulnerabilities:**" >> "$output_file"
            echo "" >> "$output_file"

            # Extract service information (basic parsing)
            local service_count=$(grep -c '"product":' "$cve_file" 2>/dev/null || echo 0)
            if [ $service_count -gt 0 ]; then
                echo "- $service_count service(s) analyzed" >> "$output_file"
                echo "- CVE data sourced from NIST National Vulnerability Database" >> "$output_file"
                echo "- Last updated: $(date)" >> "$output_file"
            fi
            echo "" >> "$output_file"
        fi
    fi

    return 0
}

parse_xml_basic() {
    local xml_file="$1"
    local output_file="$2"

    log_info "Parsing scan results..."

    # Start markdown report
    cat > "$output_file" << 'EOF'
# Network Scan Report

**Generated:** $(date)
**Scan File:** $(basename "$xml_file")

---

## Executive Summary

EOF

    # Extract basic info using grep/sed (fallback if no XML tools)
    echo "### Scan Information" >> "$output_file"
    echo "" >> "$output_file"

    if command -v xmllint &> /dev/null; then
        # Extract scan arguments
        local scan_args=$(xmllint --xpath 'string(//nmaprun/@args)' "$xml_file" 2>/dev/null || echo "N/A")
        local scan_time=$(xmllint --xpath 'string(//nmaprun/@startstr)' "$xml_file" 2>/dev/null || echo "N/A")
        local nmap_version=$(xmllint --xpath 'string(//nmaprun/@version)' "$xml_file" 2>/dev/null || echo "N/A")

        echo "- **Nmap Version:** $nmap_version" >> "$output_file"
        echo "- **Scan Command:** \`$scan_args\`" >> "$output_file"
        echo "- **Scan Time:** $scan_time" >> "$output_file"
        echo "" >> "$output_file"

        # Count hosts
        local total_hosts=$(xmllint --xpath 'count(//host)' "$xml_file" 2>/dev/null || echo "0")
        local up_hosts=$(xmllint --xpath 'count(//host[status[@state="up"]])' "$xml_file" 2>/dev/null || echo "0")

        echo "### Host Summary" >> "$output_file"
        echo "" >> "$output_file"
        echo "- **Total Hosts Scanned:** $total_hosts" >> "$output_file"
        echo "- **Hosts Up:** $up_hosts" >> "$output_file"
        echo "" >> "$output_file"
    fi

    # Extract hosts and ports (basic parsing)
    echo "## Detailed Findings" >> "$output_file"
    echo "" >> "$output_file"

    # Parse the original .nmap file if available
    local nmap_file="${xml_file%.xml}.nmap"
    if [ -f "$nmap_file" ]; then
        echo '```' >> "$output_file"
        cat "$nmap_file" >> "$output_file"
        echo '```' >> "$output_file"
    else
        log_warning "Original .nmap file not found, using XML only"
        # Basic XML text extraction
        if command -v xmllint &> /dev/null; then
            xmllint --format "$xml_file" >> "$output_file" 2>/dev/null || cat "$xml_file" >> "$output_file"
        fi
    fi

    # Add CVE vulnerability section
    generate_cve_section "$xml_file" "$output_file"

    # Add recommendations section
    cat >> "$output_file" << 'EOF'

---

## Security Recommendations

### High Priority
- [ ] Review all open ports and disable unnecessary services
- [ ] Ensure all services are running latest patched versions
- [ ] Verify firewall rules are properly configured

### Medium Priority
- [ ] Review service banners for information disclosure
- [ ] Implement network segmentation where applicable
- [ ] Schedule regular vulnerability scans

### Low Priority
- [ ] Document all legitimate services and ports
- [ ] Implement IDS/IPS monitoring
- [ ] Review and update security baselines

---

## Appendix

### Scanning Methodology
This scan was performed using nmap with the following approach:
1. Host discovery to identify active systems
2. Port scanning to enumerate open services
3. Service version detection for vulnerability assessment
4. OS fingerprinting where applicable

### References
- NIST SP 800-115: Technical Guide to Information Security Testing
- OWASP Testing Guide
- CIS Benchmarks

---

*Report generated by Network Hygiene Assessment Tool*
*For questions or issues, visit: https://github.com/[your-username]/network-hygiene*

EOF
}

# Parse arguments
INPUT_FILE=""
OUTPUT_FILE=""
REPORT_FORMAT="markdown"

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -t|--template)
            TEMPLATE_FILE="$2"
            shift 2
            ;;
        -f|--format)
            REPORT_FORMAT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            INPUT_FILE="$1"
            shift
            ;;
    esac
done

# Validate input
if [ -z "$INPUT_FILE" ]; then
    log_error "No scan file specified"
    usage
fi

if [ ! -f "$INPUT_FILE" ]; then
    log_error "Scan file not found: $INPUT_FILE"
    exit 1
fi

# Generate output filename if not specified
if [ -z "$OUTPUT_FILE" ]; then
    BASENAME=$(basename "$INPUT_FILE" .xml)
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    mkdir -p "$REPORTS_DIR"
    OUTPUT_FILE="$REPORTS_DIR/${BASENAME}_report_${TIMESTAMP}.md"
fi

# Check requirements
check_requirements

# Generate report
log_info "Generating report from $INPUT_FILE"
log_info "Output: $OUTPUT_FILE"

parse_xml_basic "$INPUT_FILE" "$OUTPUT_FILE"

log_success "Report generated: $OUTPUT_FILE"

# Optionally convert to HTML
if [ "$REPORT_FORMAT" = "html" ] && command -v pandoc &> /dev/null; then
    HTML_FILE="${OUTPUT_FILE%.md}.html"
    log_info "Converting to HTML..."
    pandoc "$OUTPUT_FILE" -o "$HTML_FILE" --standalone --toc
    log_success "HTML report: $HTML_FILE"
fi

log_info "View report with: cat $OUTPUT_FILE"
log_info "Or open with: xdg-open $OUTPUT_FILE"
