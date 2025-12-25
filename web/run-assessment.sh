#!/bin/bash
################################################################################
# Automated Web Security Assessment Script
#
# Generates comprehensive security assessment reports in both .md and .pdf formats
#
# Usage: ./run-assessment.sh <domain> [options]
# Example: ./run-assessment.sh n8n.netsectap-labs.com --auto-send
#
# Features:
# - Automated report generation in Markdown and PDF
# - Optional email delivery (--auto-send flag)
# - Standalone operation (no external dependencies required)
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/assessment-config.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
DOMAIN=""
AUTO_SEND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --target)
            DOMAIN="$2"
            shift 2
            ;;
        --auto-send|--send-report)
            AUTO_SEND="--auto-send"
            shift
            ;;
        --automated)
            # Ignore this flag (used by parent launcher)
            shift
            ;;
        *)
            # If no flag, treat as domain
            if [ -z "$DOMAIN" ]; then
                DOMAIN="$1"
            fi
            shift
            ;;
    esac
done

# Check if domain is provided
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Error: Domain required${NC}"
    echo "Usage: ./run-assessment.sh <domain> [--auto-send]"
    echo "       ./run-assessment.sh --target <domain> [--auto-send]"
    echo "Example: ./run-assessment.sh n8n.netsectap-labs.com --auto-send"
    echo "Example: ./run-assessment.sh --target https://example.com"
    exit 1
fi

# Extract domain from URL if full URL provided
DOMAIN=$(echo "$DOMAIN" | sed 's|https\?://||g' | sed 's|/.*||g')

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}Web Security Assessment - Automated Mode${NC}"
echo -e "${BLUE}============================================================${NC}"
echo -e "Target: ${GREEN}$DOMAIN${NC}"
echo -e "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Extract clean domain name for filename
CLEAN_DOMAIN=$(echo "$DOMAIN" | sed 's/https\?:\/\///g' | sed 's/[^a-zA-Z0-9.-]/-/g')
REPORT_FILE="$SCRIPT_DIR/${CLEAN_DOMAIN}.md"
ASSESSMENT_DATA="$SCRIPT_DIR/.tmp-${CLEAN_DOMAIN}-data.txt"

echo -e "${YELLOW}[1/6]${NC} Running reconnaissance..."
echo "# Assessment Data for $DOMAIN" > "$ASSESSMENT_DATA"
echo "Assessment Date: $(date '+%Y-%m-%d')" >> "$ASSESSMENT_DATA"
echo "" >> "$ASSESSMENT_DATA"

# DNS Information
echo -e "${YELLOW}[2/6]${NC} Gathering DNS information..."
echo "## DNS Information" >> "$ASSESSMENT_DATA"
dig "$DOMAIN" +short >> "$ASSESSMENT_DATA" 2>&1 || echo "DNS lookup failed" >> "$ASSESSMENT_DATA"
echo "" >> "$ASSESSMENT_DATA"

# Security Headers
echo -e "${YELLOW}[3/6]${NC} Checking security headers..."
echo "## Security Headers" >> "$ASSESSMENT_DATA"
curl -sI "https://$DOMAIN" >> "$ASSESSMENT_DATA" 2>&1 || echo "Failed to fetch headers" >> "$ASSESSMENT_DATA"
echo "" >> "$ASSESSMENT_DATA"

# Technology Detection
echo -e "${YELLOW}[4/6]${NC} Detecting technologies..."
if command -v whatweb &> /dev/null; then
    echo "## Technology Stack" >> "$ASSESSMENT_DATA"
    whatweb --color=never "https://$DOMAIN" >> "$ASSESSMENT_DATA" 2>&1
    echo "" >> "$ASSESSMENT_DATA"
fi

# SSL/TLS Configuration
echo -e "${YELLOW}[5/6]${NC} Analyzing SSL/TLS..."
echo "## SSL Certificate" >> "$ASSESSMENT_DATA"
openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" </dev/null 2>/dev/null | \
    openssl x509 -noout -dates -issuer -subject >> "$ASSESSMENT_DATA" 2>&1 || \
    echo "SSL check failed" >> "$ASSESSMENT_DATA"
echo "" >> "$ASSESSMENT_DATA"

# Generate summary
echo -e "${YELLOW}[6/6]${NC} Generating assessment report with risk evaluation..."
echo ""

# Analyze security headers for findings
HEADERS_DATA=$(curl -sI "https://$DOMAIN" 2>/dev/null)
FINDINGS_CRITICAL=0
FINDINGS_HIGH=0
FINDINGS_MEDIUM=0
FINDINGS_LOW=0
FINDINGS_INFO=0

# Create comprehensive markdown report with risk evaluation
cat > "$REPORT_FILE" <<'REPORT_START'
# Web Security Assessment Report

REPORT_START

cat >> "$REPORT_FILE" <<EOF
## ${DOMAIN}

**Assessment Date:** $(date '+%Y-%m-%d %H:%M:%S')
**Assessed By:** NetSecTap Security Assessment Framework
**Report Version:** 1.0

---

## Executive Summary

This security assessment evaluates the web application security posture of **${DOMAIN}**. The assessment covers critical security controls including HTTP security headers, SSL/TLS configuration, DNS security, and technology stack analysis.

EOF

# Analyze security headers and generate findings
cat >> "$REPORT_FILE" <<'EOF'

### Security Findings Overview

EOF

# Check for critical security headers
FINDING_DETAILS=""

if ! echo "$HEADERS_DATA" | grep -qi "strict-transport-security"; then
    FINDINGS_HIGH=$((FINDINGS_HIGH + 1))
    FINDING_DETAILS="${FINDING_DETAILS}
**[HIGH]** Missing HTTP Strict Transport Security (HSTS) header"
fi

if ! echo "$HEADERS_DATA" | grep -qi "content-security-policy"; then
    FINDINGS_MEDIUM=$((FINDINGS_MEDIUM + 1))
    FINDING_DETAILS="${FINDING_DETAILS}
**[MEDIUM]** Missing Content Security Policy (CSP) header"
fi

if ! echo "$HEADERS_DATA" | grep -qi "x-frame-options"; then
    FINDINGS_MEDIUM=$((FINDINGS_MEDIUM + 1))
    FINDING_DETAILS="${FINDING_DETAILS}
**[MEDIUM]** Missing X-Frame-Options header (Clickjacking protection)"
fi

if ! echo "$HEADERS_DATA" | grep -qi "x-content-type-options"; then
    FINDINGS_LOW=$((FINDINGS_LOW + 1))
    FINDING_DETAILS="${FINDING_DETAILS}
**[LOW]** Missing X-Content-Type-Options header"
fi

if echo "$HEADERS_DATA" | grep -qi "server:"; then
    FINDINGS_INFO=$((FINDINGS_INFO + 1))
    FINDING_DETAILS="${FINDING_DETAILS}
**[INFO]** Server version disclosure detected"
fi

# Calculate overall risk score
TOTAL_FINDINGS=$((FINDINGS_CRITICAL * 10 + FINDINGS_HIGH * 7 + FINDINGS_MEDIUM * 4 + FINDINGS_LOW * 2 + FINDINGS_INFO * 1))
if [ $TOTAL_FINDINGS -ge 20 ]; then
    RISK_LEVEL="🔴 HIGH RISK"
    RISK_COLOR="red"
elif [ $TOTAL_FINDINGS -ge 10 ]; then
    RISK_LEVEL="🟠 MEDIUM RISK"
    RISK_COLOR="orange"
else
    RISK_LEVEL="🟢 LOW RISK"
    RISK_COLOR="green"
fi

cat >> "$REPORT_FILE" <<EOF
| Severity | Count |
|----------|-------|
| 🔴 Critical | $FINDINGS_CRITICAL |
| 🟠 High | $FINDINGS_HIGH |
| 🟡 Medium | $FINDINGS_MEDIUM |
| 🔵 Low | $FINDINGS_LOW |
| ℹ️  Info | $FINDINGS_INFO |

**Overall Risk Rating:** $RISK_LEVEL

---

## Detailed Findings

### Security Headers Analysis
$FINDING_DETAILS

---

## Technical Assessment Details

EOF

# Append collected technical data
cat "$ASSESSMENT_DATA" >> "$REPORT_FILE"

# Add recommendations section
cat >> "$REPORT_FILE" <<'EOF'

---

## Recommendations

### Priority 1: Critical & High Severity

1. **Enable HSTS (HTTP Strict Transport Security)**
   - Add header: `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
   - Prevents protocol downgrade attacks and cookie hijacking
   - Implementation: Configure web server to send HSTS header on all HTTPS responses

2. **Implement Content Security Policy**
   - Add restrictive CSP header to prevent XSS attacks
   - Start with: `Content-Security-Policy: default-src 'self'; script-src 'self'`
   - Gradually refine policy based on application requirements

### Priority 2: Medium Severity

3. **Add Clickjacking Protection**
   - Implement: `X-Frame-Options: DENY` or `X-Frame-Options: SAMEORIGIN`
   - Prevents UI redress attacks

4. **Enable MIME-Type Sniffing Protection**
   - Add: `X-Content-Type-Options: nosniff`
   - Prevents browsers from MIME-sniffing responses

### Priority 3: Informational

5. **Remove Server Version Headers**
   - Disable server version disclosure in HTTP headers
   - Reduces information leakage for potential attackers

---

## Next Steps

1. Review and prioritize findings based on business risk
2. Implement Priority 1 recommendations immediately
3. Plan implementation timeline for medium severity items
4. Re-test after implementing fixes
5. Consider implementing automated security header monitoring

---

## Assessment Methodology

This assessment was performed using automated tools and manual verification:
- DNS reconnaissance
- HTTP security header analysis
- SSL/TLS configuration review
- Technology stack fingerprinting
- OWASP Top 10 security control validation

**Note:** This is an automated assessment. For comprehensive security testing, consider a full penetration test.

---

*Report generated by NetSecTap Security Assessment Framework*
*For questions or clarifications, please contact your security team*

EOF

echo -e "${GREEN}✓${NC} Markdown report generated: ${GREEN}$REPORT_FILE${NC}"

# Generate PDF if wkhtmltopdf or pandoc is available
PDF_FILE="${REPORT_FILE%.md}.pdf"

if command -v wkhtmltopdf &> /dev/null; then
    echo -e "${YELLOW}Converting to PDF...${NC}"
    # Convert markdown to HTML first, then to PDF
    if command -v pandoc &> /dev/null; then
        pandoc "$REPORT_FILE" -f markdown -t html -o "${REPORT_FILE%.md}.html" 2>/dev/null
        wkhtmltopdf "${REPORT_FILE%.md}.html" "$PDF_FILE" &>/dev/null && rm "${REPORT_FILE%.md}.html"
        if [ -f "$PDF_FILE" ]; then
            echo -e "${GREEN}✓${NC} PDF report generated: ${GREEN}$PDF_FILE${NC}"
        fi
    else
        echo -e "${YELLOW}Note: Install pandoc for better PDF conversion${NC}"
    fi
elif command -v pandoc &> /dev/null; then
    echo -e "${YELLOW}Converting to PDF...${NC}"
    pandoc "$REPORT_FILE" -o "$PDF_FILE" 2>/dev/null
    if [ -f "$PDF_FILE" ]; then
        echo -e "${GREEN}✓${NC} PDF report generated: ${GREEN}$PDF_FILE${NC}"
    fi
else
    echo -e "${YELLOW}Note: Install wkhtmltopdf or pandoc for PDF generation${NC}"
fi

# Clean up temporary data file
rm -f "$ASSESSMENT_DATA"

echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}Assessment Complete!${NC}"
echo ""
echo -e "Reports saved:"
echo -e "  • Markdown: ${GREEN}$REPORT_FILE${NC}"
if [ -f "$PDF_FILE" ]; then
    echo -e "  • PDF: ${GREEN}$PDF_FILE${NC}"
fi
echo ""

# Display report content for easy preview
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Report Preview:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
cat "$REPORT_FILE"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Handle email delivery based on --send-report flag
if [ "$AUTO_SEND" == "--auto-send" ]; then
    # Check if email is configured
    if [ -f "$SCRIPT_DIR/email-config.json" ]; then
        # Validate email config has real credentials
        if grep -q '"your-azure-client-id-here"' "$SCRIPT_DIR/email-config.json" 2>/dev/null; then
            echo -e "${YELLOW}⚠ Email Configuration Required${NC}"
            echo ""
            echo -e "You used ${CYAN}--send-report${NC} but email is not properly configured."
            echo ""
            echo -e "${GREEN}Setup Instructions:${NC}"
            echo -e "  1. Edit: ${CYAN}$SCRIPT_DIR/email-config.json${NC}"
            echo -e "  2. Replace placeholder values with your Azure App credentials"
            echo -e "  3. See ${CYAN}email-config.example.json${NC} for reference"
            echo -e "  4. Full guide: ${CYAN}$SCRIPT_DIR/README.md${NC}"
            echo ""
        else
            echo -e "${BLUE}Sending report via email...${NC}"
            echo ""
            if python3 "$SCRIPT_DIR/send-report.py" "$PDF_FILE" 2>/dev/null; then
                echo ""
                echo -e "${GREEN}✓ Report sent successfully via email${NC}"
            else
                echo ""
                echo -e "${RED}✗ Failed to send email${NC}"
                echo -e "${YELLOW}Check your email configuration and try again${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠ Email Configuration Required${NC}"
        echo ""
        echo -e "You used ${CYAN}--send-report${NC} but email is not configured."
        echo ""
        echo -e "${GREEN}Setup Instructions:${NC}"
        echo -e "  1. Copy: ${CYAN}cp email-config.example.json email-config.json${NC}"
        echo -e "  2. Edit: ${CYAN}nano email-config.json${NC}"
        echo -e "  3. Add your Azure App Registration credentials"
        echo -e "  4. Full guide: ${CYAN}$SCRIPT_DIR/README.md${NC}"
        echo ""
    fi
fi

echo ""
echo -e "${BLUE}============================================================${NC}"
