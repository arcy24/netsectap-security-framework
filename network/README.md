# Network Infrastructure Security Assessment

> Part of the [NetSecTap Security Assessment Framework](../README.md)
> For unified assessment launcher, see: `../run-assessment.sh`

A comprehensive shell-based toolkit for network security assessments and hygiene monitoring. This project provides automated scanning, reporting, and security hygiene checking capabilities.

## Part of Unified Framework

This is the **Network Assessment** component of the NetSecTap Security Assessment Framework. You can:
- Run network assessments directly from this folder (see below)
- Use the unified launcher: `cd .. && ./run-assessment.sh network`
- Run both web and network assessments: `cd .. && ./run-assessment.sh both`

For web application security assessments, see: [../web/README.md](../web/README.md)

## Overview

This toolkit wraps existing network scanning tools (primarily nmap) with user-friendly scripts for:
- **Automated network scanning** with multiple scan profiles
- **CVE vulnerability lookup** from NIST National Vulnerability Database
- **Report generation** from scan results in markdown/HTML format
- **Security hygiene checking** to identify common misconfigurations and CVEs
- **Organized storage** of scan results and reports

## Project Structure

```
network-hygiene/
├── scripts/              # Automation scripts
│   ├── network-scan.sh   # Network scanning wrapper
│   ├── cve-lookup.sh     # CVE vulnerability lookup tool
│   ├── generate-report.sh # Report generation tool
│   ├── hygiene-check.sh  # Security hygiene checker
│   └── lib/              # Shared library functions
│       ├── cve-lib.sh    # Core CVE query functions
│       ├── cache-lib.sh  # Caching utilities
│       └── cpe-builder.sh # CPE name construction
├── config/               # Configuration files
│   └── cve-config.conf   # CVE lookup configuration
├── cache/                # CVE query cache (7-day TTL)
│   └── cve/              # Cached CVE data
├── scans/                # Scan output storage
│   ├── nmap/             # Nmap scan results
│   ├── masscan/          # Masscan results
│   └── custom/           # Other scan outputs
├── reports/              # Generated reports
├── templates/            # Report templates
├── docs/                 # Additional documentation
└── README.md             # This file
```

## Prerequisites

### Required Tools
- **nmap** - Network scanner
  ```bash
  sudo apt install nmap
  ```
- **curl** - HTTP client for CVE API queries
  ```bash
  sudo apt install curl
  ```
- **xmllint** - XML parsing for nmap results
  ```bash
  sudo apt install libxml2-utils
  ```

### Optional Tools
- **masscan** - Fast port scanner
  ```bash
  sudo apt install masscan
  ```
- **xsltproc** - Additional XML processing
  ```bash
  sudo apt install xsltproc
  ```
- **pandoc** - For HTML report conversion
  ```bash
  sudo apt install pandoc
  ```
- **NVD API Key** - Optional, for higher rate limits (50 req/30s vs 5 req/30s)
  - Get free API key at: https://nvd.nist.gov/developers/request-an-api-key
  - Configure in `config/cve-config.conf`

## Installation

1. **Clone or navigate to the project:**
   ```bash
   cd /path/to/netsectap/network-hygiene
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x scripts/*.sh
   ```

3. **Verify installation:**
   ```bash
   ./scripts/network-scan.sh --help
   ```

## Usage

### Network Scanning

The `network-scan.sh` script provides multiple scan profiles:

#### Quick Scan (Common 1000 ports)
```bash
./scripts/network-scan.sh 192.168.1.1
```

#### Full Port Scan (1-65535)
```bash
./scripts/network-scan.sh --type full 192.168.1.1
```

#### Vulnerability Scan
```bash
./scripts/network-scan.sh --type vuln 192.168.1.0/24
```

#### Vulnerability Scan with CVE Lookup
```bash
# Automatically query CVE database for detected services
./scripts/network-scan.sh --type vuln --cve 192.168.1.1
```

#### Service Detection
```bash
./scripts/network-scan.sh --type service --ports 80,443,8080 example.com
```

#### Host Discovery
```bash
./scripts/network-scan.sh --type discovery 192.168.1.0/24
```

#### Custom Named Scan
```bash
./scripts/network-scan.sh --name "gateway-audit" --type full 192.168.1.1
```

### CVE Vulnerability Lookup

Query the NIST National Vulnerability Database (NVD) for known CVEs:

#### Standalone CVE Research
```bash
# Query CVEs for specific product/version
./scripts/cve-lookup.sh Apache 2.4.49
./scripts/cve-lookup.sh OpenSSH 7.4
./scripts/cve-lookup.sh nginx 1.18.0

# Query from nmap XML scan results
./scripts/cve-lookup.sh --xml scans/nmap/scan.xml

# Force cache refresh
./scripts/cve-lookup.sh --no-cache Apache 2.4.49

# Filter by severity
./scripts/cve-lookup.sh --severity HIGH Apache 2.4.49

# Save to file
./scripts/cve-lookup.sh --output cve-report.json Apache 2.4.49
```

#### Retroactive CVE Analysis
```bash
# Analyze existing scans for CVEs
./scripts/cve-lookup.sh --xml scans/nmap/old_scan_20241201.xml

# Re-run hygiene check with new CVE data
./scripts/hygiene-check.sh scans/nmap/old_scan_20241201.nmap
```

#### Cache Management
```bash
# View cache statistics
./scripts/cve-lookup.sh --stats

# Clear cache
./scripts/cve-lookup.sh --clear-cache
```

**Features:**
- 🔍 Queries NIST NVD API 2.0 (free, no API key required)
- 💾 Smart caching (7-day TTL) to minimize API calls
- ⚡ Rate limiting (respects NVD limits: 5 req/30s)
- 🎯 25+ product mappings (Apache, nginx, OpenSSH, MySQL, etc.)
- 📊 CVSS-based severity scoring
- 🔄 Automatic service version extraction from nmap XML

### Report Generation

Generate markdown reports from scan results:

```bash
# Auto-detect latest scan
./scripts/generate-report.sh scans/nmap/latest_scan.xml

# Specify output file
./scripts/generate-report.sh -o reports/gateway-report.md scans/nmap/gateway.xml

# Generate HTML report (requires pandoc)
./scripts/generate-report.sh --format html scans/nmap/scan.xml
```

**Example Report:**
See [`reports/example_report.md`](reports/example_report.md) for a sample generated report.

### Security Hygiene Checks

Analyze scan results for security issues:

```bash
# Check most recent scan (includes CVE checks)
./scripts/hygiene-check.sh

# Check specific scan
./scripts/hygiene-check.sh scans/nmap/192.168.1.1_quick_20250101.nmap

# Skip CVE vulnerability checks (faster)
./scripts/hygiene-check.sh --skip-cve scans/nmap/scan.nmap

# Check all scans
./scripts/hygiene-check.sh --all

# Save report to file
./scripts/hygiene-check.sh --report hygiene-report.txt
```

**CVE Risk Scoring:**
The hygiene checker automatically integrates CVE findings into risk assessment:
- 🔴 **CRITICAL CVEs**: +15 points each (CVSS 9.0-10.0)
- 🟠 **HIGH CVEs**: +10 points each (CVSS 7.0-8.9)
- 🟡 **MEDIUM CVEs**: +5 points each (CVSS 4.0-6.9)
- 🟢 **LOW CVEs**: +2 points each (CVSS 0.1-3.9)

## Scan Types

| Type | Description | Use Case | Speed |
|------|-------------|----------|-------|
| `quick` | Common 1000 ports | Fast reconnaissance | ⚡⚡⚡ |
| `full` | All 65535 ports | Comprehensive scan | ⚡ |
| `vuln` | Vulnerability scanning | Security assessment | ⚡ |
| `service` | Service version detection | Service enumeration | ⚡⚡ |
| `discovery` | Host discovery only | Network mapping | ⚡⚡⚡ |

## Hygiene Checks Performed

The hygiene checker analyzes scans for:

### Critical Issues
- ❌ **CVE Vulnerabilities** - CRITICAL and HIGH severity from NVD
- ❌ Telnet (port 23) - Unencrypted remote access
- ❌ Anonymous FTP access
- ❌ Outdated/vulnerable SSH versions

### High Priority
- ⚠️ **Known CVEs** - Medium severity vulnerabilities
- ⚠️ FTP (port 21) - Unencrypted file transfer
- ⚠️ RDP (port 3389) - Brute-force target
- ⚠️ SMB (port 445) - Ransomware target
- ⚠️ Database ports exposed (3306, 5432, 27017)

### Medium Priority
- ⚠️ HTTP without HTTPS
- ⚠️ Unnecessary legacy services
- ⚠️ Excessive open ports

### Information
- ℹ️ Service versions and CVE associations
- ℹ️ Default web pages
- ℹ️ Open port count

## Output Formats

### Scan Outputs
- `.nmap` - Human-readable format
- `.xml` - Machine-parseable XML
- `.gnmap` - Greppable format for scripts

### Reports
- **Markdown** - Default format, GitHub-compatible
- **HTML** - Web-viewable (requires pandoc)
- **Text** - Plain text summary

## Examples

### Complete Workflow

```bash
# 1. Run a vulnerability scan with CVE lookup
./scripts/network-scan.sh --type vuln --cve --name "prod-network" 10.0.0.0/24

# 2. Generate a report (includes CVE section)
./scripts/generate-report.sh scans/nmap/prod-network_vuln_*.xml

# 3. Check security hygiene (includes CVE risk scoring)
./scripts/hygiene-check.sh scans/nmap/prod-network_vuln_*.nmap

# 4. Review results
cat reports/prod-network_vuln_*_report_*.md
```

### CVE-Focused Workflow

```bash
# 1. Run service detection scan with CVE analysis
./scripts/network-scan.sh --type service --cve 192.168.1.10

# 2. Manual CVE research for specific services
./scripts/cve-lookup.sh Apache 2.4.49
./scripts/cve-lookup.sh --severity CRITICAL OpenSSH 7.4

# 3. View cache statistics
./scripts/cve-lookup.sh --stats

# 4. Analyze all services from scan
./scripts/cve-lookup.sh --xml scans/nmap/192.168.1.10_service_*.xml
```

### Automated Daily Scans

Create a cron job for daily scanning:

```bash
# Add to crontab (crontab -e)
0 2 * * * /path/to/network-hygiene/scripts/network-scan.sh --type quick --name "daily-scan" 192.168.1.0/24
0 3 * * * /path/to/network-hygiene/scripts/hygiene-check.sh --report /path/to/reports/daily-hygiene.txt
```

## Security Considerations

### Permissions
- Many scan types require **root/sudo** privileges
- RDP scans, OS detection, and some NSE scripts need elevated access

### Legal and Ethical Use
- ✅ **Only scan networks you own or have explicit permission to test**
- ✅ Authorized penetration testing
- ✅ Security research on your own infrastructure
- ❌ Unauthorized scanning is illegal and unethical

### Rate Limiting
- Use appropriate timing templates (`-T0` to `-T5`)
- Be considerate of network bandwidth
- Avoid aggressive scans on production systems

### Data Sensitivity
- Scan results may contain sensitive network information
- Store results securely
- **Do not commit scan results with sensitive data to public repositories**

### CVE Data Privacy
- CVE queries send **product names and versions** to NVD API (e.g., "Apache 2.4.49")
- **No IP addresses** are sent to NVD
- Shodan integration (optional) will send IP addresses if enabled
- CVE cache stored locally in `cache/cve/` (not committed to git)
- Review `config/cve-config.conf` for privacy settings

## Integration with GitHub

This project is designed to integrate with your **Network Hygiene** GitHub repository:

```bash
# Initialize git (if not already done)
cd network-hygiene
git init

# Add remote
git remote add origin https://github.com/[your-username]/network-hygiene.git

# Create .gitignore to exclude sensitive scan data
cat > .gitignore << 'EOF'
# Exclude actual scan results (may contain sensitive data)
scans/nmap/*.nmap
scans/nmap/*.xml
scans/nmap/*.gnmap
scans/masscan/*
scans/custom/*

# Exclude CVE cache (may reveal internal software versions)
cache/cve/*.json

# Exclude generated reports with sensitive data
reports/*_report_*.md
reports/*.html

# Keep directory structure
!scans/nmap/.gitkeep
!scans/masscan/.gitkeep
!scans/custom/.gitkeep
!reports/.gitkeep
!cache/cve/.gitkeep

# Include example/template files
!scans/nmap/example_scan.nmap
!reports/example_report.md
EOF

# Commit and push
git add .
git commit -m "Initial commit: Network Hygiene Assessment Toolkit"
git push -u origin main
```

## Troubleshooting

### Permission Denied Errors
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Or run specific scans with sudo
sudo ./scripts/network-scan.sh --type full 192.168.1.1
```

### XML Parsing Errors
```bash
# Install required XML tools
sudo apt install libxml2-utils xsltproc
```

### No Scan Results
```bash
# Check if target is reachable
ping -c 3 <target>

# Verify nmap is installed
nmap --version

# Check firewall rules
sudo iptables -L
```

### Hygiene Check Shows No Scans
```bash
# Verify scans directory
ls -la scans/nmap/

# Run a test scan first
./scripts/network-scan.sh 127.0.0.1
```

## Roadmap

### Completed Features ✅
- [x] **CVE vulnerability database integration** (December 2025)
  - NVD API 2.0 integration
  - Smart caching (7-day TTL)
  - CVSS-based risk scoring
  - 25+ product mappings
  - Integration with hygiene checks and reports

### Planned Features
- [ ] Masscan integration for faster scanning
- [ ] Compare scan results (diff functionality)
- [ ] Database storage for scan history
- [ ] Web dashboard for visualization
- [ ] Automated remediation suggestions
- [ ] Enhanced CVE features:
  - [ ] EPSS (Exploit Prediction Scoring) integration
  - [ ] CISA KEV (Known Exploited Vulnerabilities) catalog
  - [ ] Automatic exploit availability checking
  - [ ] CVE trending and statistics
- [ ] Slack/Email notifications for critical findings
- [ ] Docker container support

### Future Integrations
- [ ] Enhanced Shodan CLI integration for CVE cross-referencing
- [ ] VirusTotal scanning for suspicious services
- [ ] SIEM export formats (Splunk, ELK)

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is provided as-is for educational and authorized security testing purposes.

## Acknowledgments

- **nmap** - The Network Mapper (https://nmap.org/)
- **masscan** - Fast port scanner (https://github.com/robertdavidgraham/masscan)
- OWASP for security testing methodologies

## Support

For issues, questions, or contributions:
- GitHub Issues: https://github.com/[your-username]/network-hygiene/issues
- Documentation: See `docs/` directory

## Related Projects

This toolkit integrates with other tools in the netsectap workspace:
- **VirusTotal CLI** - File/URL/domain analysis
- **Shodan CLI** - Internet-connected device search
- **theZoo** - Malware analysis (use with extreme caution)

---

**⚠️ Disclaimer:** This toolkit is for authorized security testing only. Always obtain proper authorization before scanning networks. Unauthorized scanning may be illegal in your jurisdiction.

**Last Updated:** December 23, 2025
