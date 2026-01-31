# NetSecTap Security Assessment Framework

A comprehensive security assessment framework providing **Web Application**, **Network Infrastructure**, and **WiFi Security** assessments.

## Overview

This unified framework combines three powerful security assessment toolkits:

- **Web Assessment**: Web application security testing (SSL/TLS, OWASP, headers, vulnerabilities)
- **Network Assessment**: Network infrastructure scanning (port scanning, CVE lookup, hygiene checks)
- **WiFi Assessment**: Wireless network security analysis (encryption, monitor mode, packet capture)

## Quick Start

### Interactive Mode

Simply run the launcher script to access the interactive menu:

```bash
cd security-assessments
./run-assessment.sh
```

This will present you with options to choose:
1. Web Application Security Assessment
2. Network Infrastructure Security Assessment
3. WiFi Security Assessment
4. All Assessments (Web + Network + WiFi)
5. Help
6. Exit

### Command-Line Mode

Run specific assessments directly:

```bash
# Web assessment
./run-assessment.sh web --target https://example.com --automated

# Network assessment
./run-assessment.sh network --target 192.168.1.0/24 --type vuln --cve

# WiFi assessment
./run-assessment.sh wifi --scan-type quick

# All assessments
./run-assessment.sh all
```

## Directory Structure

```
security-assessments/
├── run-assessment.sh           # Unified launcher script
├── README.md                   # This file
├── web/                        # Web Application Security Assessment
│   ├── README.md               # Web assessment documentation
│   ├── run-assessment.sh       # Automated web assessment workflow
│   ├── send-report.py          # Email report delivery
│   ├── Web-Assessment.md       # Assessment template/guide
│   ├── AUTOMATED-WORKFLOW.md   # Workflow documentation
│   └── *.md, *.pdf             # Assessment reports
├── network/                    # Network Infrastructure Security Assessment
│   ├── README.md               # Network assessment documentation
│   ├── scripts/                # Assessment scripts
│   │   ├── network-scan.sh     # Network scanning wrapper
│   │   ├── cve-lookup.sh       # CVE vulnerability lookup
│   │   ├── hygiene-check.sh    # Security hygiene checker
│   │   ├── generate-report.sh  # Report generation
│   │   └── lib/                # Shared library functions
│   ├── config/                 # Configuration files
│   ├── scans/                  # Scan results storage
│   ├── reports/                # Generated reports
│   └── templates/              # Report templates
└── Wifi/                       # WiFi Security Assessment
    ├── README.md               # WiFi assessment documentation
    ├── wifi-scan.sh            # WiFi security scanning script
    ├── WiFi-Security-Assessment-Guide.md  # Comprehensive methodology guide
    ├── output/                 # Scan results and captures
    └── reports/                # Generated security reports
```

## Assessment Types

### Web Application Security Assessment

**Purpose**: Comprehensive security testing of web applications and websites

**Key Features**:
- SSL/TLS configuration analysis (testssl.sh)
- HTTP security headers evaluation
- OWASP Top 10 vulnerability checks
- Technology fingerprinting (WhatWeb)
- DNS and WHOIS information gathering
- Automated report generation (Markdown/PDF)
- Email delivery system for reports

**Use Cases**:
- Web application penetration testing
- Security compliance assessments
- Pre-deployment security validation
- Regular security monitoring

**Documentation**: See [web/README.md](web/README.md)

### Network Infrastructure Security Assessment

**Purpose**: Network security scanning and vulnerability assessment

**Key Features**:
- Multiple scan profiles (quick, full, vuln, service, discovery)
- CVE vulnerability lookup (NIST NVD API integration)
- Security hygiene checking with risk scoring
- Automated nmap-based scanning
- Service version detection
- Report generation (Markdown/HTML)
- Smart caching for CVE data

**Use Cases**:
- Network infrastructure assessments
- Vulnerability scanning
- Security hygiene monitoring
- Compliance and audit support

**Documentation**: See [network/README.md](network/README.md)

### WiFi Security Assessment

**Purpose**: Wireless network security analysis and vulnerability assessment

**Key Features**:
- Three scan modes (quick, full, monitor)
- Interface management and monitor mode support
- Network reconnaissance with host discovery
- Encryption analysis with aircrack-ng suite
- Security scoring and vulnerability assessment
- Automated report generation
- Support for WPA2/WPA3 security analysis

**Scan Types**:
- **Quick**: Fast WiFi scan using nmcli/iw (no monitor mode)
- **Full**: Comprehensive scan with network reconnaissance and host discovery
- **Monitor**: Advanced packet capture and analysis using aircrack-ng

**Use Cases**:
- WiFi security audits
- Encryption strength assessment
- Rogue access point detection
- Network penetration testing (authorized)
- Security compliance validation

**Documentation**: See [Wifi/README.md](Wifi/README.md) and [Wifi/WiFi-Security-Assessment-Guide.md](Wifi/WiFi-Security-Assessment-Guide.md)

## Usage Examples

### Web Assessment Examples

```bash
# Basic web assessment with automated workflow
./run-assessment.sh web --target https://www.example.com --automated

# Web assessment with report delivery via email
./run-assessment.sh web --target https://api.example.com --send-report

# Generate report from existing assessment
./run-assessment.sh web --report-only --target https://example.com
```

### Network Assessment Examples

```bash
# Quick scan of a single host
./run-assessment.sh network --target 192.168.1.10 --type quick

# Full vulnerability scan with CVE lookup
./run-assessment.sh network --target 192.168.1.0/24 --type vuln --cve --report

# Service detection with hygiene check
./run-assessment.sh network --target 10.0.0.1 --type service --hygiene-check

# Discovery scan of network range
./run-assessment.sh network --target 192.168.0.0/16 --type discovery
```

### WiFi Assessment Examples

```bash
# Quick WiFi network scan
./run-assessment.sh wifi --scan-type quick

# Full scan of specific network with report
./run-assessment.sh wifi --scan-type full --ssid "MyNetwork" --report

# Monitor mode capture and analysis (requires root)
sudo ./run-assessment.sh wifi --scan-type monitor --ssid "MyNetwork" --duration 60 --report

# Quick scan on specific interface
./run-assessment.sh wifi --interface wlan1 --scan-type quick

# Focused monitor mode scan with custom duration
sudo ./run-assessment.sh wifi --scan-type monitor --ssid "TargetNetwork" --duration 120 --report
```

### Comprehensive Assessment

```bash
# Run all assessments (web, network, and WiFi)
./run-assessment.sh all

# Or run them separately in sequence
./run-assessment.sh web --target https://example.com
./run-assessment.sh network --target example.com --type vuln --cve
./run-assessment.sh wifi --scan-type full --report
```

## Prerequisites

### Web Assessment Requirements

- **testssl.sh**: SSL/TLS testing
- **whatweb**: Technology fingerprinting
- **dig**: DNS queries
- **whois**: Domain information
- **curl**: HTTP requests
- **Python 3**: Report delivery system
- **wkhtmltopdf**: PDF generation

Installation:
```bash
# Install tools
sudo apt install dnsutils whois curl python3 python3-pip wkhtmltopdf

# Install testssl.sh
cd /opt
sudo git clone https://github.com/drwetter/testssl.sh.git

# Install whatweb
sudo apt install whatweb
```

### Network Assessment Requirements

- **nmap**: Network scanner
- **curl**: CVE API queries
- **xmllint**: XML parsing
- **pandoc** (optional): HTML report generation
- **masscan** (optional): Fast port scanning

Installation:
```bash
# Install required tools
sudo apt install nmap curl libxml2-utils

# Install optional tools
sudo apt install pandoc masscan
```

### WiFi Assessment Requirements

- **nmcli**: Network Manager CLI
- **iw**: Wireless tools
- **aircrack-ng suite**: Monitor mode and packet capture (for monitor scans)
- **nmap**: Host discovery (for full scans)
- **Root privileges**: Required for monitor mode scans only

Installation:
```bash
# Install Network Manager and wireless tools
sudo apt install network-manager iw wireless-tools

# Install aircrack-ng suite (for monitor mode)
sudo apt install aircrack-ng

# Install nmap (for host discovery in full scans)
sudo apt install nmap

# Verify wireless interface supports monitor mode (optional check)
iw list | grep -A 10 "Supported interface modes"
```

## Configuration

### Web Assessment Configuration

Configure email delivery in `web/email-config.json`:
```json
{
  "smtp_server": "smtp.gmail.com",
  "smtp_port": 587,
  "sender_email": "your-email@example.com",
  "sender_password": "your-app-password",
  "recipient_email": "recipient@example.com"
}
```

### Network Assessment Configuration

Configure CVE lookup in `network/config/cve-config.conf`:
```bash
# NVD API Configuration
NVD_API_KEY=""                    # Optional: Get from https://nvd.nist.gov/
CACHE_TTL_DAYS=7                  # Cache duration
RATE_LIMIT_DELAY=6                # Seconds between API calls
```

### WiFi Assessment Configuration

WiFi assessment works out of the box with default settings:

```bash
# Default settings (can be overridden via command-line)
INTERFACE="wlan0"                 # Wireless interface
SCAN_TYPE="quick"                 # quick, full, or monitor
SCAN_DURATION=30                  # Seconds for monitor mode
```

**No additional configuration files required.** All options are passed via command-line arguments.

## Report Formats

### Web Assessment Reports

**All reports are automatically saved in both formats:**
- **Markdown** (`.md`): Human-readable, GitHub-compatible, version-controlled
- **PDF** (`.pdf`): Professional reports for client delivery
- **Sections**: Executive Summary, SSL/TLS Analysis, Headers, DNS/WHOIS, Findings, Recommendations

Both `.md` and `.pdf` files are tracked in git for historical record and archival purposes.

### Network Assessment Reports

- **Markdown** (`.md`): Detailed scan results with CVE data
- **HTML** (`.html`): Web-viewable reports with formatting
- **Text** (`.txt`): Plain text summaries
- **Scan Outputs**: `.nmap`, `.xml`, `.gnmap` formats

### WiFi Assessment Reports

- **Markdown** (`.md`): Security assessment reports with recommendations
- **Scan Results**: Network lists, encryption details, signal strength
- **Capture Files**: `.csv`, `.cap`, `.pcap` (for monitor mode scans)
- **Sections**: Executive Summary, Networks Detected, Security Analysis, Recommendations

## Workflow Integration

### Automated Web Assessment Workflow

The web assessment includes an automated workflow that:
1. Runs all security tools in sequence
2. Generates comprehensive markdown report
3. Converts report to PDF
4. Optionally delivers via email

See [web/AUTOMATED-WORKFLOW.md](web/AUTOMATED-WORKFLOW.md) for details.

### Network Scanning Workflow

Typical network assessment workflow:
1. Run initial scan (quick/discovery)
2. Perform detailed vulnerability scan with CVE lookup
3. Run security hygiene check
4. Generate comprehensive report
5. Store results for historical comparison

### WiFi Assessment Workflow

Typical WiFi security assessment workflow:
1. Quick scan to discover available networks
2. Full scan with host discovery (if connected to network)
3. Monitor mode scan for encryption analysis (requires root)
4. Generate security report with recommendations
5. Review and implement security improvements

**Three Scan Modes:**
- **Quick**: Fast network discovery (no root required)
- **Full**: Network reconnaissance + host discovery (requires connection)
- **Monitor**: Deep packet analysis with encryption assessment (requires root)

## Security Considerations

### Legal and Ethical Use

⚠️ **IMPORTANT**: Only perform security assessments on systems you own or have explicit written permission to test.

- ✅ Authorized penetration testing
- ✅ Security research on your own infrastructure
- ✅ Compliance and audit assessments
- ❌ Unauthorized scanning is illegal and unethical

### Data Sensitivity

- Scan results may contain sensitive information
- Store results securely with appropriate access controls
- Do not commit sensitive scan data to public repositories
- Use `.gitignore` to exclude sensitive files

### Rate Limiting

- Be considerate of network bandwidth and system resources
- Use appropriate timing for scans (avoid aggressive scanning on production)
- Respect CVE API rate limits (NVD: 5 requests/30s without API key)

## Troubleshooting

### Common Issues

**Permission Denied:**
```bash
# Make scripts executable
chmod +x run-assessment.sh
chmod +x web/run-assessment.sh
chmod +x network/scripts/*.sh
```

**Tools Not Found:**
```bash
# Verify tool installation
which nmap testssl.sh whatweb

# Check PATH
echo $PATH
```

**CVE API Errors:**
```bash
# Check internet connectivity
curl -I https://services.nvd.nist.gov/

# View cache stats
./network/scripts/cve-lookup.sh --stats
```

## Documentation

- **Web Assessment**: [web/README.md](web/README.md)
- **Network Assessment**: [network/README.md](network/README.md)
- **WiFi Assessment**: [Wifi/README.md](Wifi/README.md)
- **WiFi Assessment Guide**: [Wifi/WiFi-Security-Assessment-Guide.md](Wifi/WiFi-Security-Assessment-Guide.md)
- **Automated Workflow**: [web/AUTOMATED-WORKFLOW.md](web/AUTOMATED-WORKFLOW.md)
- **Report Delivery**: [web/REPORT-DELIVERY-OPTIONS.md](web/REPORT-DELIVERY-OPTIONS.md)

## Contributing

Contributions are welcome! Areas for enhancement:
- Additional assessment types (mobile, API, cloud)
- Enhanced reporting formats
- Integration with SIEM systems
- Automated remediation suggestions
- CI/CD pipeline integration
- WiFi security automation enhancements

## Support

For issues, questions, or contributions:
- GitHub Issues: https://github.com/arcy24/netsectap-security-framework/issues
- Documentation: See individual toolkit READMEs

## Related Projects

This framework is part of the NetSecTap Labs ecosystem:
- **Web Assessment**: Application security testing
- **Network Hygiene**: Infrastructure security monitoring
- **WiFi Security**: Wireless network security assessment
- **Security Research**: Vulnerability research and analysis

## License

This project is provided as-is for educational and authorized security testing purposes.

---

**Last Updated**: January 18, 2026

**⚠️ Disclaimer**: This framework is for authorized security testing only. Always obtain proper authorization before assessing networks or applications. Unauthorized testing may be illegal in your jurisdiction.
