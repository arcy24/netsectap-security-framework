#!/bin/bash

################################################################################
# WiFi Security Assessment Script
# Part of the NetSecTap Security Assessment Framework
#
# This script automates WiFi security assessments including:
# - Interface management and network connection
# - Network reconnaissance and host discovery
# - Encryption analysis with aircrack-ng suite
# - Security scoring and vulnerability assessment
# - Report generation
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
OUTPUT_DIR="${SCRIPT_DIR}/output"
REPORTS_DIR="${SCRIPT_DIR}/reports"

# Default values
INTERFACE="wlan0"
SCAN_TYPE="quick"
MONITOR_MODE=false
GENERATE_REPORT=false
TARGET_SSID=""
SCAN_DURATION=30

################################################################################
# Display Usage
################################################################################
show_usage() {
    cat << EOF
${GREEN}USAGE:${NC}
    $0 [OPTIONS]

${GREEN}OPTIONS:${NC}
    --interface <iface>    Wireless interface to use (default: wlan0)
    --ssid <ssid>          Target SSID to analyze
    --scan-type <type>     Scan type: quick, full, monitor
                           - quick: Basic WiFi scan with nmcli/iw
                           - full: Extended scan with host discovery
                           - monitor: Advanced capture with airodump-ng
    --duration <seconds>   Scan duration for monitor mode (default: 30)
    --report               Generate security assessment report
    --help                 Display this help message

${GREEN}SCAN TYPES:${NC}
    ${CYAN}quick${NC}   - Fast scan using nmcli and iw (no monitor mode)
    ${CYAN}full${NC}    - Comprehensive scan with network reconnaissance
    ${CYAN}monitor${NC} - Deep analysis using monitor mode (requires root)

${GREEN}EXAMPLES:${NC}
    # Quick WiFi scan
    $0 --scan-type quick

    # Full scan of specific network with report
    $0 --scan-type full --ssid "MyNetwork" --report

    # Monitor mode capture and analysis
    sudo $0 --scan-type monitor --ssid "MyNetwork" --duration 60 --report

${GREEN}PREREQUISITES:${NC}
    - nmcli, iw (for quick/full scans)
    - aircrack-ng suite (for monitor mode)
    - nmap (for host discovery in full scans)
    - Root privileges (for monitor mode only)

EOF
}

################################################################################
# Check Prerequisites
################################################################################
check_prerequisites() {
    local missing_tools=()

    # Basic tools (required for all scans)
    command -v nmcli >/dev/null 2>&1 || missing_tools+=("nmcli")
    command -v iw >/dev/null 2>&1 || missing_tools+=("iw")

    # Monitor mode tools (only required for monitor scan)
    if [[ "$SCAN_TYPE" == "monitor" ]]; then
        command -v airmon-ng >/dev/null 2>&1 || missing_tools+=("airmon-ng")
        command -v airodump-ng >/dev/null 2>&1 || missing_tools+=("airodump-ng")

        # Check for root privileges
        if [[ $EUID -ne 0 ]]; then
            echo -e "${RED}Error: Monitor mode requires root privileges${NC}"
            echo -e "${YELLOW}Please run with sudo:${NC} sudo $0 $*"
            exit 1
        fi
    fi

    # Full scan tools
    if [[ "$SCAN_TYPE" == "full" ]]; then
        command -v nmap >/dev/null 2>&1 || missing_tools+=("nmap")
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing required tools: ${missing_tools[*]}${NC}"
        echo ""
        echo -e "${CYAN}Install missing tools:${NC}"
        echo "  sudo apt install network-manager iw aircrack-ng nmap"
        exit 1
    fi
}

################################################################################
# Check Interface Status
################################################################################
check_interface() {
    echo -e "${BLUE}Checking interface ${INTERFACE}...${NC}"

    # Check if interface is already in monitor mode (e.g., wlan0mon exists)
    local mon_interface="${INTERFACE}mon"
    if ip link show "$mon_interface" >/dev/null 2>&1; then
        echo -e "${YELLOW}Interface is currently in monitor mode ($mon_interface)${NC}"

        # If we're doing a monitor scan, we can use the existing monitor interface
        if [[ "$SCAN_TYPE" == "monitor" ]]; then
            echo -e "${GREEN}✓ Using existing monitor mode interface${NC}"
            # Don't need to check further for monitor scans
            return 0
        else
            # For non-monitor scans, disable monitor mode
            echo -e "${YELLOW}Disabling monitor mode to restore normal operation...${NC}"

            # Stop monitor mode
            if command -v airmon-ng >/dev/null 2>&1; then
                sudo airmon-ng stop "$mon_interface" >/dev/null 2>&1
                sleep 2

                # Restart NetworkManager
                sudo systemctl restart NetworkManager >/dev/null 2>&1
                sleep 2
            else
                echo -e "${RED}Error: airmon-ng not found. Cannot disable monitor mode.${NC}"
                echo -e "${CYAN}Manual fix: sudo ip link set $mon_interface down${NC}"
                exit 1
            fi

            # Verify interface is back
            if ! ip link show "$INTERFACE" >/dev/null 2>&1; then
                echo -e "${RED}Error: Failed to restore interface $INTERFACE${NC}"
                exit 1
            fi

            echo -e "${GREEN}✓ Monitor mode disabled, interface restored${NC}"
        fi
    fi

    # Check if interface exists (skip for monitor scans if already in monitor mode)
    if ! ip link show "$INTERFACE" >/dev/null 2>&1; then
        echo -e "${RED}Error: Interface $INTERFACE not found${NC}"
        echo ""
        echo -e "${CYAN}Available wireless interfaces:${NC}"
        iw dev | grep Interface | awk '{print $2}'
        echo ""
        echo -e "${YELLOW}If you see ${INTERFACE}mon, the interface is stuck in monitor mode.${NC}"
        echo -e "${CYAN}To fix manually, run:${NC}"
        echo "  sudo airmon-ng stop ${INTERFACE}mon"
        echo "  sudo systemctl restart NetworkManager"
        exit 1
    fi

    # Check if interface is up
    if ! ip link show "$INTERFACE" | grep -q "state UP"; then
        echo -e "${YELLOW}Interface $INTERFACE is down. Bringing it up...${NC}"
        sudo ip link set "$INTERFACE" up
        sleep 2
    fi

    # Check for RF blocks
    if rfkill list | grep -A 1 "Wireless LAN" | grep -q "blocked: yes"; then
        echo -e "${YELLOW}WiFi is blocked by rfkill. Unblocking...${NC}"
        sudo rfkill unblock wifi
        sleep 1
    fi

    echo -e "${GREEN}✓ Interface $INTERFACE is ready${NC}"
}

################################################################################
# Quick WiFi Scan
################################################################################
quick_scan() {
    echo -e "${CYAN}=== Quick WiFi Scan ===${NC}"
    echo ""

    local scan_file="${OUTPUT_DIR}/wifi-scan-$(date +%Y%m%d-%H%M%S).txt"
    mkdir -p "$OUTPUT_DIR"

    echo -e "${BLUE}Scanning for WiFi networks...${NC}"

    # Trigger rescan
    nmcli device wifi rescan 2>/dev/null || true
    sleep 2

    # Capture nmcli output
    nmcli device wifi list | tee "$scan_file"
    echo ""

    if [[ -n "$TARGET_SSID" ]]; then
        echo -e "${CYAN}=== Detailed scan of '$TARGET_SSID' ===${NC}"

        # Use iw for detailed information
        local detail_file="${OUTPUT_DIR}/wifi-detail-$(date +%Y%m%d-%H%M%S).txt"
        sudo iw dev "$INTERFACE" scan | grep -A 30 "SSID: $TARGET_SSID" | tee "$detail_file"

        echo ""
        echo -e "${GREEN}✓ Scan results saved to:${NC}"
        echo "  - $scan_file"
        echo "  - $detail_file"
    else
        echo -e "${GREEN}✓ Scan results saved to: $scan_file${NC}"
    fi
}

################################################################################
# Full WiFi Scan with Host Discovery
################################################################################
full_scan() {
    echo -e "${CYAN}=== Full WiFi Security Scan ===${NC}"
    echo ""

    # First do a quick scan
    quick_scan
    echo ""

    # Check if connected to a network
    if ! nmcli connection show --active | grep -q "wifi"; then
        echo -e "${YELLOW}Not connected to any WiFi network${NC}"

        if [[ -n "$TARGET_SSID" ]]; then
            read -p "Connect to '$TARGET_SSID' for host discovery? (y/n): " connect_choice
            if [[ "$connect_choice" =~ ^[Yy]$ ]]; then
                read -sp "Enter password for '$TARGET_SSID': " wifi_password
                echo ""
                nmcli device wifi connect "$TARGET_SSID" password "$wifi_password"
                sleep 3
            else
                echo -e "${YELLOW}Skipping host discovery (requires network connection)${NC}"
                return
            fi
        else
            echo -e "${YELLOW}Skipping host discovery (requires network connection)${NC}"
            return
        fi
    fi

    # Get network information
    local gateway=$(ip route | grep default | grep "$INTERFACE" | awk '{print $3}')
    local ip_addr=$(ip addr show "$INTERFACE" | grep "inet " | awk '{print $2}')

    if [[ -z "$gateway" ]]; then
        echo -e "${YELLOW}No gateway found. Skipping host discovery.${NC}"
        return
    fi

    echo -e "${CYAN}=== Network Information ===${NC}"
    echo -e "IP Address:    ${GREEN}$ip_addr${NC}"
    echo -e "Gateway:       ${GREEN}$gateway${NC}"
    echo ""

    # Calculate network range
    local network=$(echo "$ip_addr" | sed 's/\.[0-9]*\//.0\//')

    echo -e "${BLUE}Scanning network $network for active hosts...${NC}"

    local nmap_file="${OUTPUT_DIR}/network-hosts-$(date +%Y%m%d-%H%M%S).txt"
    sudo nmap -sn "$network" -oN "$nmap_file"

    echo ""
    echo -e "${GREEN}✓ Host discovery complete${NC}"
    echo -e "${CYAN}Results saved to: $nmap_file${NC}"

    # Show summary
    local host_count=$(grep "Nmap scan report for" "$nmap_file" | wc -l)
    echo -e "${GREEN}Found $host_count active hosts${NC}"
}

################################################################################
# Cleanup Function for Monitor Mode
################################################################################
cleanup_monitor_mode() {
    local mon_interface="${INTERFACE}mon"

    if ip link show "$mon_interface" >/dev/null 2>&1; then
        echo ""
        echo -e "${YELLOW}Cleaning up monitor mode...${NC}"
        airmon-ng stop "$mon_interface" >/dev/null 2>&1
        systemctl restart NetworkManager >/dev/null 2>&1
        sleep 2
        echo -e "${GREEN}✓ Monitor mode disabled${NC}"
    fi
}

################################################################################
# Monitor Mode Scan with aircrack-ng
################################################################################
monitor_scan() {
    echo -e "${CYAN}=== Monitor Mode WiFi Analysis ===${NC}"
    echo ""

    # Check for root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: Monitor mode requires root privileges${NC}"
        exit 1
    fi

    local mon_interface="${INTERFACE}mon"
    local capture_prefix="${OUTPUT_DIR}/wifi-capture-$(date +%Y%m%d-%H%M%S)"
    local target_channel=""
    local target_bssid=""
    mkdir -p "$OUTPUT_DIR"

    # Set up trap to ensure cleanup on exit/interrupt
    trap cleanup_monitor_mode EXIT INT TERM

    # Check if monitor mode is already enabled
    if iw dev | grep -q "$mon_interface"; then
        echo -e "${GREEN}✓ Monitor mode already enabled: $mon_interface${NC}"
    else
        echo -e "${BLUE}Enabling monitor mode on $INTERFACE...${NC}"

        # Check and kill interfering processes
        airmon-ng check kill >/dev/null 2>&1

        # Start monitor mode
        airmon-ng start "$INTERFACE" >/dev/null 2>&1
        sleep 2

        if ! iw dev | grep -q "$mon_interface"; then
            echo -e "${RED}Error: Failed to enable monitor mode${NC}"
            exit 1
        fi

        echo -e "${GREEN}✓ Monitor mode enabled: $mon_interface${NC}"
    fi
    echo ""

    # If target SSID specified, find its channel first
    if [[ -n "$TARGET_SSID" ]]; then
        echo -e "${BLUE}Locating target network '$TARGET_SSID'...${NC}"

        # Quick 3-second scan to find the target - run in background and monitor
        local quick_scan="/tmp/quick-wifi-scan-$$"

        # Start airodump-ng in background
        airodump-ng "$mon_interface" --band abg --output-format csv --write "$quick_scan" &>/dev/null &
        local quick_pid=$!

        # Wait up to 5 seconds for data
        local waited=0
        while [[ $waited -lt 5 ]]; do
            if [[ -f "${quick_scan}-01.csv" ]] && grep -qi "$TARGET_SSID" "${quick_scan}-01.csv" 2>/dev/null; then
                break
            fi
            sleep 1
            waited=$((waited + 1))
        done

        # Kill the quick scan process
        kill -9 $quick_pid 2>/dev/null || true
        wait $quick_pid 2>/dev/null || true
        sleep 1

        if [[ -f "${quick_scan}-01.csv" ]]; then
            # Extract channel and BSSID for target SSID
            local target_info=$(grep -i "$TARGET_SSID" "${quick_scan}-01.csv" | head -1)

            if [[ -n "$target_info" ]]; then
                target_channel=$(echo "$target_info" | awk -F',' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}')
                target_bssid=$(echo "$target_info" | awk -F',' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}')

                echo -e "${GREEN}✓ Found '$TARGET_SSID' on channel $target_channel (BSSID: $target_bssid)${NC}"
                echo -e "${CYAN}Focusing scan on channel $target_channel only${NC}"
            else
                echo -e "${YELLOW}Warning: '$TARGET_SSID' not found in quick scan${NC}"
                echo -e "${CYAN}Will scan all channels (this may take longer)${NC}"
            fi
            rm -f "${quick_scan}"* 2>/dev/null
        fi
        echo ""
    fi

    # Build airodump-ng command with channel filter if available
    local airodump_cmd="timeout $SCAN_DURATION airodump-ng $mon_interface"

    if [[ -n "$target_channel" && -n "$target_bssid" ]]; then
        # Focus on specific channel and BSSID
        airodump_cmd="$airodump_cmd --channel $target_channel --bssid $target_bssid"
        echo -e "${BLUE}Capturing traffic from '$TARGET_SSID' (channel $target_channel) for ${SCAN_DURATION} seconds...${NC}"
    elif [[ -n "$TARGET_SSID" ]]; then
        # SSID specified but not found, scan all channels but mention target
        airodump_cmd="$airodump_cmd --band abg"
        echo -e "${BLUE}Scanning all channels for '$TARGET_SSID' for ${SCAN_DURATION} seconds...${NC}"
    else
        # No SSID specified, scan everything
        airodump_cmd="$airodump_cmd --band abg"
        echo -e "${BLUE}Scanning all WiFi channels for ${SCAN_DURATION} seconds...${NC}"
    fi

    echo -e "${YELLOW}NOTE: Live display requires proper terminal support. Please wait...${NC}"
    echo -e "${CYAN}The scan is running in the background and will complete in ${SCAN_DURATION} seconds.${NC}"
    echo ""

    # Show progress bar while scanning
    {
        eval "$airodump_cmd --output-format csv --write $capture_prefix" &>/dev/null &

        local airodump_pid=$!
        local elapsed=0

        # Show progress indicator
        echo -ne "${BLUE}Progress: [${NC}"
        while kill -0 $airodump_pid 2>/dev/null && [ $elapsed -lt $SCAN_DURATION ]; do
            sleep 2
            elapsed=$((elapsed + 2))
            echo -ne "${GREEN}▓${NC}"
        done
        echo -e "${BLUE}] Complete${NC}"

        # Ensure process is killed
        if kill -0 $airodump_pid 2>/dev/null; then
            kill -9 $airodump_pid 2>/dev/null || true
        fi
        wait $airodump_pid 2>/dev/null || true
    }

    echo ""
    echo -e "${GREEN}✓ Capture complete - processing results...${NC}"

    # Stop monitor mode
    echo -e "${BLUE}Disabling monitor mode...${NC}"
    airmon-ng stop "$mon_interface" >/dev/null 2>&1
    systemctl restart NetworkManager >/dev/null 2>&1
    sleep 2

    # Remove trap since we're cleaning up manually here
    trap - EXIT INT TERM

    echo -e "${GREEN}✓ Monitor mode disabled${NC}"

    # Parse results
    if [[ -f "${capture_prefix}-01.csv" ]]; then
        echo ""

        if [[ -n "$target_channel" && -n "$target_bssid" ]]; then
            echo -e "${CYAN}=== Captured Traffic (Focused on '$TARGET_SSID') ===${NC}"
        else
            echo -e "${CYAN}=== Captured Networks ===${NC}"
        fi
        echo ""

        # Count networks in CSV (skip header lines)
        local network_count=$(awk -F',' 'NR>2 && $14 != "" && $14 !~ /SSID/ {print $14}' "${capture_prefix}-01.csv" | sort -u | wc -l)

        if [[ $network_count -eq 0 ]]; then
            echo -e "${YELLOW}No networks captured. This could mean:${NC}"
            if [[ -n "$TARGET_SSID" ]]; then
                echo "  - Target network '$TARGET_SSID' is not in range or is off"
                echo "  - Network may be on 5GHz and adapter only supports 2.4GHz"
                echo "  - Scan duration too short (try --duration 60)"
            else
                echo "  - Scan duration too short (try --duration 60)"
                echo "  - No WiFi networks in range"
                echo "  - Wireless adapter issue"
            fi
            echo ""
            echo -e "${CYAN}Try running a longer scan:${NC}"
            echo "  sudo ./run-assessment.sh wifi --scan-type monitor --duration 60"
        else
            if [[ -n "$target_bssid" ]]; then
                echo -e "${GREEN}Captured traffic from target network${NC}"
            else
                echo -e "${GREEN}Found $network_count network(s)${NC}"
            fi
            echo ""

            # Parse CSV and display results with better formatting
            awk -F',' 'NR>2 && $14 != "" && $14 !~ /SSID/ {
                # Trim whitespace from fields
                gsub(/^[ \t]+|[ \t]+$/, "", $1);  # BSSID
                gsub(/^[ \t]+|[ \t]+$/, "", $4);  # Channel
                gsub(/^[ \t]+|[ \t]+$/, "", $6);  # Encryption
                gsub(/^[ \t]+|[ \t]+$/, "", $9);  # Power
                gsub(/^[ \t]+|[ \t]+$/, "", $14); # SSID

                printf "%-25s  %17s  Ch:%-3s  %8s  %4s dBm\n",
                    $14, $1, $4, $6, $9
            }' "${capture_prefix}-01.csv" | sort -u

            if [[ -n "$TARGET_SSID" ]]; then
                echo ""
                echo -e "${CYAN}=== Detailed Analysis of '$TARGET_SSID' ===${NC}"

                if grep -qi "$TARGET_SSID" "${capture_prefix}-01.csv"; then
                    grep -i "$TARGET_SSID" "${capture_prefix}-01.csv" | head -1 | \
                        awk -F',' '{
                            gsub(/^[ \t]+|[ \t]+$/, "", $1);
                            gsub(/^[ \t]+|[ \t]+$/, "", $4);
                            gsub(/^[ \t]+|[ \t]+$/, "", $6);
                            gsub(/^[ \t]+|[ \t]+$/, "", $7);
                            gsub(/^[ \t]+|[ \t]+$/, "", $8);
                            gsub(/^[ \t]+|[ \t]+$/, "", $9);
                            print "BSSID:       " $1
                            print "Channel:     " $4
                            print "Encryption:  " $6
                            print "Cipher:      " $7
                            print "Auth:        " $8
                            print "Power:       " $9 " dBm"
                        }'
                else
                    echo -e "${YELLOW}Network '$TARGET_SSID' not found in capture${NC}"
                    echo "Try increasing scan duration or check if network is in range"
                fi
            fi
        fi

        echo ""
        echo -e "${GREEN}✓ Capture files saved:${NC}"
        ls -1 "${capture_prefix}"* 2>/dev/null | sed 's/^/  /' || echo "  (no files found)"
    else
        echo ""
        echo -e "${RED}✗ Error: No capture files generated${NC}"
        echo ""
        echo -e "${YELLOW}Troubleshooting:${NC}"
        echo "  1. Verify monitor mode is working: iw dev"
        echo "  2. Check if wireless adapter supports monitor mode"
        echo "  3. Try a different wireless interface"
        echo "  4. Ensure no other processes are using the adapter"
    fi
}

################################################################################
# Generate Security Report
################################################################################
generate_report() {
    echo ""
    echo -e "${CYAN}=== Generating Security Report ===${NC}"

    mkdir -p "$REPORTS_DIR"
    local report_file="${REPORTS_DIR}/wifi-security-report-$(date +%Y%m%d-%H%M%S).md"

    cat > "$report_file" << 'REPORT_HEADER'
# WiFi Security Assessment Report

**Assessment Date:** $(date +"%Y-%m-%d %H:%M:%S")
**Scan Type:** ${SCAN_TYPE}
**Interface:** ${INTERFACE}
$(if [[ -n "$TARGET_SSID" ]]; then echo "**Target SSID:** $TARGET_SSID"; fi)

---

## Executive Summary

This report documents the findings from an automated WiFi security assessment
conducted using the NetSecTap Security Assessment Framework.

## Assessment Scope

REPORT_HEADER

    # Replace variables in header
    sed -i "s/\$(date +\"%Y-%m-%d %H:%M:%S\")/$(date +"%Y-%m-%d %H:%M:%S")/" "$report_file"
    sed -i "s/\${SCAN_TYPE}/$SCAN_TYPE/" "$report_file"
    sed -i "s/\${INTERFACE}/$INTERFACE/" "$report_file"

    if [[ -n "$TARGET_SSID" ]]; then
        sed -i "s/\$(if.*fi)/\*\*Target SSID:\*\* $TARGET_SSID/" "$report_file"
    else
        sed -i "s/\$(if.*fi)//" "$report_file"
    fi

    # Append scan results
    cat >> "$report_file" << 'REPORT_BODY'

- **Scan Duration:** Automated scan completed
- **Tools Used:** nmcli, iw, nmap, aircrack-ng suite
- **Assessment Type:** Network security posture evaluation

## Networks Detected

REPORT_BODY

    # Add latest scan results
    local latest_scan=$(ls -t "$OUTPUT_DIR"/wifi-scan-*.txt 2>/dev/null | head -1)
    if [[ -f "$latest_scan" ]]; then
        echo '```' >> "$report_file"
        cat "$latest_scan" >> "$report_file"
        echo '```' >> "$report_file"
    fi

    # Add recommendations
    cat >> "$report_file" << 'REPORT_FOOTER'

## Security Recommendations

### Critical Priority
- [ ] Upgrade to WPA3 encryption if hardware supports it
- [ ] Disable WPS (WiFi Protected Setup)
- [ ] Use strong passwords (16+ characters with mixed case, numbers, symbols)

### High Priority
- [ ] Enable Protected Management Frames (PMF/802.11w)
- [ ] Change default SSID to non-identifying name
- [ ] Update router firmware to latest version
- [ ] Review and document all connected devices

### Medium Priority
- [ ] Implement network segmentation (main/IoT/guest networks)
- [ ] Enable firewall on router
- [ ] Disable remote administration if not needed
- [ ] Schedule quarterly security assessments

## Conclusion

This automated assessment provides a snapshot of the WiFi security posture.
For comprehensive security analysis, manual review and additional testing
are recommended.

---

**Generated by:** NetSecTap Security Assessment Framework
**Report Version:** 1.0
REPORT_FOOTER

    echo -e "${GREEN}✓ Report generated: $report_file${NC}"

    # Offer to view report
    read -p "View report now? (y/n): " view_choice
    if [[ "$view_choice" =~ ^[Yy]$ ]]; then
        less "$report_file" || cat "$report_file"
    fi
}

################################################################################
# Parse Command Line Arguments
################################################################################
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --interface)
                INTERFACE="$2"
                shift 2
                ;;
            --ssid)
                TARGET_SSID="$2"
                shift 2
                ;;
            --scan-type)
                SCAN_TYPE="$2"
                if [[ ! "$SCAN_TYPE" =~ ^(quick|full|monitor)$ ]]; then
                    echo -e "${RED}Error: Invalid scan type '$SCAN_TYPE'${NC}"
                    echo "Valid types: quick, full, monitor"
                    exit 1
                fi
                shift 2
                ;;
            --duration)
                SCAN_DURATION="$2"
                shift 2
                ;;
            --report)
                GENERATE_REPORT=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                echo -e "${RED}Error: Unknown option '$1'${NC}"
                show_usage
                exit 1
                ;;
        esac
    done
}

################################################################################
# Main Execution
################################################################################
main() {
    # Display banner
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║           WiFi Security Assessment Tool                       ║"
    echo "║           NetSecTap Labs                                      ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    # Parse arguments
    parse_args "$@"

    # Check prerequisites
    check_prerequisites

    # Check interface status
    check_interface

    echo ""

    # Execute scan based on type
    case "$SCAN_TYPE" in
        quick)
            quick_scan
            ;;
        full)
            full_scan
            ;;
        monitor)
            monitor_scan
            ;;
    esac

    # Generate report if requested
    if [[ "$GENERATE_REPORT" == true ]]; then
        generate_report
    fi

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   WiFi Assessment Complete!            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
}

# Run main function
main "$@"
