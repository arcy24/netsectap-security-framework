# WiFi Security Assessment Toolkit

Comprehensive wireless network security assessment tool with three scan modes for authorized testing.

## Overview

The WiFi Security Assessment Toolkit provides automated wireless network security testing capabilities, including interface management, network reconnaissance, encryption analysis, and vulnerability assessment.

## Features

- **Three Scan Modes**: Quick, Full, and Monitor mode scans
- **Interface Management**: Automatic monitor mode setup and cleanup
- **Encryption Analysis**: WPA2/WPA3 security assessment using aircrack-ng
- **Network Reconnaissance**: Host discovery and network mapping
- **Security Reporting**: Automated report generation with recommendations
- **Safety Features**: Interface state recovery and graceful cleanup

## Quick Start

### Basic Usage

```bash
# Quick scan (no root required)
./wifi-scan.sh --scan-type quick

# Full scan with host discovery
./wifi-scan.sh --scan-type full --ssid "NetworkName" --report

# Monitor mode analysis (requires root)
sudo ./wifi-scan.sh --scan-type monitor --ssid "NetworkName" --duration 60 --report
```

### Via Main Launcher

```bash
# From security-assessments directory
cd ..
./run-assessment.sh wifi --scan-type quick
```

## Scan Types

### 1. Quick Scan
- **Purpose**: Fast network discovery
- **Tools**: nmcli, iw
- **Root Required**: No
- **Use Case**: Quick WiFi network enumeration

```bash
./wifi-scan.sh --scan-type quick
```

### 2. Full Scan
- **Purpose**: Comprehensive network analysis with host discovery
- **Tools**: nmcli, iw, nmap
- **Root Required**: No (but requires network connection for host discovery)
- **Use Case**: In-depth network reconnaissance

```bash
./wifi-scan.sh --scan-type full --ssid "MyNetwork" --report
```

### 3. Monitor Scan
- **Purpose**: Advanced packet capture and encryption analysis
- **Tools**: aircrack-ng suite (airmon-ng, airodump-ng)
- **Root Required**: Yes
- **Use Case**: Deep security analysis and encryption assessment

```bash
sudo ./wifi-scan.sh --scan-type monitor --ssid "MyNetwork" --duration 60 --report
```

## Command-Line Options

```
--interface <iface>    Wireless interface to use (default: wlan0)
--ssid <ssid>          Target SSID to analyze
--scan-type <type>     Scan type: quick, full, monitor
--duration <seconds>   Scan duration for monitor mode (default: 30)
--report               Generate security assessment report
--help                 Display help message
```

## Prerequisites

### Required Tools

```bash
# Basic tools (required for all scans)
sudo apt install network-manager iw

# For full scans with host discovery
sudo apt install nmap

# For monitor mode scans
sudo apt install aircrack-ng
```

### Wireless Adapter Requirements

- For **Quick** and **Full** scans: Any WiFi adapter
- For **Monitor** scans: WiFi adapter with monitor mode support

Check monitor mode support:
```bash
iw list | grep -A 10 "Supported interface modes"
```

## Usage Examples

### Example 1: Quick Network Discovery
```bash
./wifi-scan.sh --scan-type quick
```
**Output**: List of all visible WiFi networks with signal strength and encryption

### Example 2: Targeted Network Analysis
```bash
./wifi-scan.sh --scan-type full --ssid "TargetNetwork" --report
```
**Output**:
- Detailed network information
- Connected host discovery
- Security assessment report

### Example 3: Deep Security Analysis
```bash
sudo ./wifi-scan.sh --scan-type monitor --ssid "TargetNetwork" --duration 120 --report
```
**Output**:
- Packet capture (CSV format)
- Encryption details (WPA2/WPA3, CCMP/TKIP)
- Signal strength and channel information
- Security report with recommendations

### Example 4: Custom Interface
```bash
./wifi-scan.sh --interface wlan1 --scan-type quick
```

## Output Files

All scan results are saved in the `output/` directory:

```
output/
├── wifi-scan-YYYYMMDD-HHMMSS.txt       # Quick scan results
├── wifi-detail-YYYYMMDD-HHMMSS.txt     # Detailed iw scan
├── wifi-capture-YYYYMMDD-HHMMSS-01.csv # Monitor mode captures
└── network-hosts-YYYYMMDD-HHMMSS.txt   # Host discovery results
```

Reports are saved in the `reports/` directory:

```
reports/
└── wifi-security-report-YYYYMMDD-HHMMSS.md
```

## Security Report

When the `--report` flag is used, a comprehensive security report is generated including:

- **Executive Summary**: Overall security posture
- **Networks Detected**: List of discovered networks
- **Security Analysis**: Encryption strength, vulnerabilities
- **Recommendations**: Prioritized security improvements
  - Critical Priority (immediate action)
  - High Priority (near-term fixes)
  - Medium Priority (ongoing improvements)

## Troubleshooting

### Interface Stuck in Monitor Mode

If your interface gets stuck in monitor mode (shows as `wlan0mon`):

```bash
sudo airmon-ng stop wlan0mon
sudo systemctl restart NetworkManager
```

The script includes automatic recovery for this scenario.

### No Networks Found

Possible causes:
- WiFi is blocked by rfkill: `sudo rfkill unblock wifi`
- Interface is down: `sudo ip link set wlan0 up`
- Scan duration too short (for monitor mode): Increase `--duration`
- Target network out of range or powered off

### Permission Denied Errors

Monitor mode requires root privileges:
```bash
sudo ./wifi-scan.sh --scan-type monitor --ssid "Network"
```

## Security and Legal Considerations

### ⚠️ Important Legal Notice

**Only perform WiFi security assessments on networks you own or have explicit written authorization to test.**

- ✅ **Authorized**: Your own WiFi networks, client engagements with written permission
- ❌ **Unauthorized**: Neighbor's WiFi, public WiFi without permission, any network without authorization

Unauthorized WiFi scanning and penetration testing may be illegal in your jurisdiction and violate:
- Computer Fraud and Abuse Act (CFAA) - USA
- Computer Misuse Act - UK
- Similar laws in other countries

### Ethical Use Guidelines

1. **Authorization**: Always obtain written permission before testing
2. **Scope**: Stay within the agreed-upon scope of testing
3. **Disclosure**: Report findings responsibly to network owners
4. **Privacy**: Protect any sensitive information discovered
5. **Disruption**: Avoid causing service disruption or excessive traffic

## Comprehensive Methodology Guide

For a detailed step-by-step WiFi security assessment methodology, see:

**[WiFi-Security-Assessment-Guide.md](WiFi-Security-Assessment-Guide.md)**

This guide includes:
- Phase-by-phase assessment methodology
- Manual commands and detailed explanations
- Security scoring framework
- Password strength analysis
- Common vulnerability assessment
- Best practices and recommendations
- Legal and ethical considerations

## Integration with Main Framework

This toolkit is integrated into the NetSecTap Security Assessment Framework:

```bash
# Run from main security-assessments directory
./run-assessment.sh wifi [OPTIONS]

# Run all assessments (web + network + wifi)
./run-assessment.sh all
```

See main framework documentation: [../README.md](../README.md)

## Support and Contributions

- **Issues**: Report bugs and feature requests on GitHub
- **Documentation**: See comprehensive guide for detailed methodology
- **Contributions**: Pull requests welcome for enhancements

## Related Tools

Other NetSecTap security assessment tools:
- **Web Assessment**: Application security testing (SSL/TLS, OWASP)
- **Network Assessment**: Infrastructure scanning (nmap, CVE lookup)

## License

This toolkit is provided as-is for educational and authorized security testing purposes.

---

**Version**: 1.0
**Last Updated**: January 18, 2026
**Author**: NetSecTap Labs

**⚠️ Remember**: Always obtain proper authorization before performing security assessments. Ethical hacking requires permission.
