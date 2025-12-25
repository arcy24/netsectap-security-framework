#!/bin/bash

################################################################################
# Security Assessment Launcher
# Part of the NetSecTap Security Assessment Framework
#
# This script provides a unified interface for running both web and network
# security assessments.
################################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_DIR="${SCRIPT_DIR}/web"
NETWORK_DIR="${SCRIPT_DIR}/network"

################################################################################
# Check Email Configuration
################################################################################
check_email_configured() {
    local email_config="${WEB_DIR}/email-config.json"

    # Check if config file exists
    [[ ! -f "$email_config" ]] && return 1

    # Check if config has placeholder values (not configured)
    grep -q '"your-azure-client-id-here"' "$email_config" 2>/dev/null && return 1

    # Simple check: if file exists and doesn't have placeholders, consider it configured
    # The actual validation happens when sending email
    return 0
}

################################################################################
# Display Banner
################################################################################
show_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║        NetSecTap Security Assessment Framework                ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Show email delivery status
    if check_email_configured; then
        echo -e "${GREEN}✓${NC} Email delivery: ${GREEN}Enabled${NC}"
    else
        echo -e "${YELLOW}○${NC} Email delivery: ${YELLOW}Not configured${NC}"
    fi
    echo ""
}

################################################################################
# Display Usage
################################################################################
show_usage() {
    cat << EOF
${GREEN}USAGE:${NC}
    $0 [COMMAND] [OPTIONS]

${GREEN}COMMANDS:${NC}
    ${CYAN}web${NC}              Run web application security assessment
    ${CYAN}network${NC}          Run network infrastructure security assessment
    ${CYAN}both${NC}             Run both web and network assessments
    ${CYAN}help${NC}             Display this help message

${GREEN}WEB ASSESSMENT OPTIONS:${NC}
    --target <url>        Target URL for web assessment
    --automated           Use automated workflow
    --report-only         Generate report from existing assessment
    --send-report         Send report via email after assessment

${GREEN}NETWORK ASSESSMENT OPTIONS:${NC}
    --target <ip/range>   Target IP or IP range for network scan
    --type <scan_type>    Scan type: quick, full, vuln, service, discovery
    --cve                 Include CVE vulnerability lookup
    --hygiene-check       Run security hygiene check after scan
    --report              Generate report after scan

${GREEN}EXAMPLES:${NC}
    # Web assessment with automated workflow
    $0 web --target https://example.com --automated

    # Network vulnerability scan with CVE lookup
    $0 network --target 192.168.1.0/24 --type vuln --cve --report

    # Quick network scan with hygiene check
    $0 network --target 192.168.1.10 --type quick --hygiene-check

    # Run both assessments (interactive mode)
    $0 both

    # Web assessment with report delivery
    $0 web --target https://example.com --send-report

${GREEN}INTERACTIVE MODE:${NC}
    Run without arguments for interactive menu:
    $0

EOF
}

################################################################################
# Prompt for Email Delivery
################################################################################
prompt_email_delivery() {
    local report_file="$1"

    if [[ ! -f "$report_file" ]]; then
        echo -e "${YELLOW}Warning: Report file not found: $report_file${NC}"
        return 1
    fi

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   Report Generated Successfully!       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""

    if check_email_configured; then
        echo -e "${GREEN}✓ Email delivery is configured${NC}"
        echo ""
        read -p "Would you like to send this report via email? (y/n): " send_email

        if [[ "$send_email" =~ ^[Yy]$ ]]; then
            read -p "Recipient email address [press Enter for default]: " recipient

            echo ""
            echo -e "${BLUE}Sending report via email...${NC}"

            cd "$WEB_DIR"
            if [[ -n "$recipient" ]]; then
                python3 send-report.py "$report_file" "$recipient"
            else
                python3 send-report.py "$report_file"
            fi

            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}✓ Report sent successfully!${NC}"
            else
                echo -e "${RED}✗ Failed to send report${NC}"
            fi
            cd "$SCRIPT_DIR"
        else
            echo -e "${CYAN}Report saved locally: $report_file${NC}"
        fi
    else
        echo -e "${YELLOW}✗ Email delivery not configured${NC}"
        echo -e "${CYAN}Report saved locally: $report_file${NC}"
        echo ""
        echo -e "${CYAN}To configure email delivery:${NC}"
        echo -e "  1. Copy ${WEB_DIR}/email-config.example.json"
        echo -e "  2. Rename to email-config.json"
        echo -e "  3. Configure with your Azure App credentials"
        echo -e "  4. See ${WEB_DIR}/README.md for setup instructions"
    fi
}

################################################################################
# Interactive Menu
################################################################################
show_menu() {
    echo -e "${GREEN}Select Assessment Type:${NC}"
    echo -e "  ${CYAN}1)${NC} Web Application Security Assessment"
    echo -e "  ${CYAN}2)${NC} Network Infrastructure Security Assessment"
    echo -e "  ${CYAN}3)${NC} Both (Web + Network)"
    echo -e "  ${CYAN}4)${NC} Help"
    echo -e "  ${CYAN}5)${NC} Exit"
    echo ""
    read -p "Enter choice [1-5]: " choice
}

################################################################################
# Run Web Assessment
################################################################################
run_web_assessment() {
    echo -e "${BLUE}=== Starting Web Security Assessment ===${NC}"

    if [[ ! -d "$WEB_DIR" ]]; then
        echo -e "${RED}Error: Web assessment directory not found: $WEB_DIR${NC}"
        exit 1
    fi

    cd "$WEB_DIR"

    # Check if automated workflow script exists
    if [[ -f "run-assessment.sh" ]]; then
        echo -e "${GREEN}Using automated web assessment workflow...${NC}"

        # Run the assessment (handles report display and email internally)
        bash run-assessment.sh "$@"
    else
        echo -e "${YELLOW}Automated workflow script not found.${NC}"
        echo -e "${CYAN}Please run assessments manually from: $WEB_DIR${NC}"
        echo -e "${CYAN}See README.md for instructions.${NC}"
    fi

    cd "$SCRIPT_DIR"
}

################################################################################
# Run Network Assessment
################################################################################
run_network_assessment() {
    echo -e "${BLUE}=== Starting Network Security Assessment ===${NC}"

    if [[ ! -d "$NETWORK_DIR" ]]; then
        echo -e "${RED}Error: Network assessment directory not found: $NETWORK_DIR${NC}"
        exit 1
    fi

    cd "$NETWORK_DIR"

    # Check if network scan script exists
    if [[ -f "scripts/network-scan.sh" ]]; then
        echo -e "${GREEN}Using network scanning toolkit...${NC}"
        bash scripts/network-scan.sh "$@"
    else
        echo -e "${YELLOW}Network scan script not found.${NC}"
        echo -e "${CYAN}Please run assessments manually from: $NETWORK_DIR${NC}"
        echo -e "${CYAN}See README.md for instructions.${NC}"
    fi

    cd "$SCRIPT_DIR"
}

################################################################################
# Run Both Assessments
################################################################################
run_both_assessments() {
    echo -e "${BLUE}=== Running Comprehensive Security Assessment ===${NC}"
    echo ""

    # Collect targets
    read -p "Enter web target URL (or press Enter to skip): " web_target
    read -p "Enter network target IP/range (or press Enter to skip): " network_target

    if [[ -n "$web_target" ]]; then
        echo ""
        echo -e "${CYAN}[1/2] Running Web Assessment...${NC}"
        run_web_assessment --target "$web_target"
        echo ""
    fi

    if [[ -n "$network_target" ]]; then
        echo ""
        echo -e "${CYAN}[2/2] Running Network Assessment...${NC}"
        run_network_assessment --target "$network_target" --type quick --cve
        echo ""
    fi

    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Comprehensive Assessment Complete!    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
}

################################################################################
# Main Logic
################################################################################
main() {
    show_banner

    # No arguments - show interactive menu
    if [[ $# -eq 0 ]]; then
        show_menu
        case $choice in
            1)
                read -p "Enter target URL: " target
                run_web_assessment --target "$target"
                ;;
            2)
                read -p "Enter target IP/range: " target
                read -p "Scan type (quick/full/vuln/service/discovery) [quick]: " scan_type
                scan_type=${scan_type:-quick}
                run_network_assessment --target "$target" --type "$scan_type"
                ;;
            3)
                run_both_assessments
                ;;
            4)
                show_usage
                ;;
            5)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                exit 1
                ;;
        esac
        exit 0
    fi

    # Parse command line arguments
    COMMAND="$1"
    shift

    case "$COMMAND" in
        web)
            run_web_assessment "$@"
            ;;
        network)
            run_network_assessment "$@"
            ;;
        both)
            run_both_assessments
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            echo -e "${RED}Error: Unknown command '$COMMAND'${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
