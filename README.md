# NetSecTap Security Assessment Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status: Private Development](https://img.shields.io/badge/Status-Private%20Development-orange)](https://github.com/arcy24/netsectap-security-framework)

A comprehensive, open-source security assessment framework that combines **web application** and **network infrastructure** security testing into a unified, easy-to-use toolkit.

## 🎯 Overview

NetSecTap Security Framework provides automated security assessments for:
- **Web Applications**: SSL/TLS, security headers, OWASP Top 10, vulnerability scanning
- **Network Infrastructure**: Port scanning, CVE lookups, security hygiene, vulnerability assessment

### Key Features

✨ **Unified Interface**
- Single command-line tool for all assessments
- Interactive menu or direct CLI commands
- Consistent workflow across assessment types

📊 **Comprehensive Reporting**
- Risk evaluation with severity ratings (Critical/High/Medium/Low)
- Both Markdown and PDF formats
- Actionable recommendations with implementation guidance
- Professional reports suitable for client delivery

📧 **Intelligent Email Delivery**
- Optional email delivery with command-line control
- OAuth2/Microsoft Graph API integration
- Automatic or manual sending modes
- Helpful setup prompts for configuration

🔒 **Security-First Design**
- Automated security best practices validation
- OWASP methodology integration
- CVE database integration (NIST NVD)
- Privacy-focused (no data sent externally except optional CVE lookups)

## 🚀 Quick Start

### Prerequisites

**Required:**
- Bash shell (Linux/macOS)
- Python 3.6+
- Basic network tools (curl, dig, openssl)

**Optional (for enhanced features):**
- nmap (network scanning)
- pandoc/wkhtmltopdf (PDF generation)
- whatweb (technology detection)

### Installation

```bash
# Clone the repository
git clone https://github.com/arcy24/netsectap-security-framework.git
cd netsectap-security-framework

# Make scripts executable
chmod +x run-assessment.sh
chmod +x web/run-assessment.sh
chmod +x network/scripts/*.sh
```

### Basic Usage

#### Interactive Mode
```bash
./run-assessment.sh
```

#### Web Assessment
```bash
# Basic assessment with report preview
./run-assessment.sh web --target https://example.com

# Assessment with email delivery
./run-assessment.sh web --target https://example.com --send-report
```

#### Network Assessment
```bash
# Quick port scan
./run-assessment.sh network --target 192.168.1.10 --type quick

# Vulnerability scan with CVE lookup
./run-assessment.sh network --target 192.168.1.0/24 --type vuln --cve
```

## 📚 Documentation

### Assessment Types

#### Web Application Security
Evaluates web application security posture including:
- HTTP security headers (HSTS, CSP, X-Frame-Options, etc.)
- SSL/TLS configuration and certificate validation
- Technology stack fingerprinting
- DNS and WHOIS information
- OWASP Top 10 security controls

[Full Web Assessment Documentation](web/README.md)

#### Network Infrastructure Security
Comprehensive network security scanning including:
- Port scanning (quick, full, vulnerability modes)
- Service version detection
- CVE vulnerability lookup from NIST NVD
- Security hygiene scoring
- Risk-based prioritization

[Full Network Assessment Documentation](network/README.md)

### Report Structure

All reports include:
1. **Executive Summary** - Overall risk rating and key findings
2. **Security Findings Table** - Categorized by severity
3. **Detailed Analysis** - Specific vulnerabilities and issues
4. **Recommendations** - Prioritized action items with implementation steps
5. **Technical Details** - Raw assessment data
6. **Next Steps** - Remediation guidance

## ⚙️ Configuration

### Email Delivery Setup

To enable automated report delivery via email:

```bash
# Copy example configuration
cp web/email-config.example.json web/email-config.json

# Edit with your credentials
nano web/email-config.json
```

Supports:
- Microsoft Graph API with OAuth2 (recommended)
- Azure App Registration authentication

[Email Setup Guide](web/README.md#email-configuration)

### Assessment Preferences

Configure default behavior in `web/assessment-config.json`:
```json
{
  "assessment_preferences": {
    "auto_send_report": false,
    "report_delivery_method": "email"
  }
}
```

## 🎨 Examples

### Complete Web Assessment Workflow
```bash
# Run assessment
./run-assessment.sh web --target https://example.com

# Output:
# ✓ Report preview displayed on screen
# ✓ Markdown saved: example.com.md
# ✓ PDF saved: example.com.pdf
```

### Network Vulnerability Assessment
```bash
# Comprehensive vulnerability scan
./run-assessment.sh network --target 10.0.0.0/24 --type vuln --cve --report

# Generates:
# - Port scan results
# - Service detection
# - CVE vulnerability mappings
# - Risk scoring
# - Remediation recommendations
```

### Automated Assessment + Email
```bash
# Web assessment with automatic email delivery
./run-assessment.sh web --target https://example.com --send-report

# Network assessment with hygiene check
./run-assessment.sh network --target 192.168.1.10 --type quick --hygiene-check
```

## 🛠️ Advanced Usage

### Custom Scan Profiles

Network scanning supports multiple profiles:
- `quick` - Top 1000 ports (fast)
- `full` - All 65535 ports (comprehensive)
- `vuln` - Vulnerability-focused scan
- `service` - Service version detection
- `discovery` - Host discovery only

### CVE Integration

Automatic CVE lookup from NIST National Vulnerability Database:
```bash
./run-assessment.sh network --target example.com --type service --cve
```

Features:
- Smart caching (7-day TTL)
- Rate limiting (respects NVD API limits)
- CVSS-based severity scoring
- 25+ product mappings

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Areas where we'd love help:
- Additional assessment modules
- Enhanced reporting templates
- CI/CD integrations
- Docker containerization
- Additional security checks

## 📋 Requirements

### System Requirements
- Linux or macOS
- 512MB RAM minimum
- 100MB disk space

### Tool Requirements

| Tool | Purpose | Required | Install Command |
|------|---------|----------|----------------|
| bash | Shell scripting | ✅ Yes | Pre-installed |
| python3 | Report delivery | ✅ Yes | `apt install python3` |
| curl | HTTP requests | ✅ Yes | `apt install curl` |
| nmap | Network scanning | ⚠️ Network only | `apt install nmap` |
| pandoc | PDF generation | ❌ Optional | `apt install pandoc` |
| whatweb | Tech detection | ❌ Optional | `apt install whatweb` |

## 🔒 Security & Privacy

### Data Handling
- **No telemetry**: No data sent to external servers
- **Local processing**: All analysis done locally
- **Optional CVE lookups**: Only product names/versions sent to NIST (no IPs)
- **Configurable**: Full control over external API usage

### Legal Notice

⚠️ **Important**: Only perform security assessments on systems you own or have explicit written permission to test. Unauthorized scanning may be illegal in your jurisdiction.

**Appropriate Use Cases:**
- ✅ Your own infrastructure
- ✅ Authorized penetration testing
- ✅ Security research with permission
- ✅ Compliance and audit activities

**Prohibited Uses:**
- ❌ Unauthorized scanning
- ❌ Attacking systems without permission
- ❌ Violating computer fraud laws

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Built with these excellent open-source tools:
- [nmap](https://nmap.org/) - The Network Mapper
- [testssl.sh](https://testssl.sh/) - SSL/TLS testing
- [whatweb](https://github.com/urbanadventurer/WhatWeb) - Technology fingerprinting
- [NIST NVD](https://nvd.nist.gov/) - CVE vulnerability database

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/arcy24/netsectap-security-framework/issues)
- **Discussions**: [GitHub Discussions](https://github.com/arcy24/netsectap-security-framework/discussions)
- **Documentation**: See `docs/` directory

## 🗺️ Roadmap

### Current Features (v1.0)
- ✅ Web application security assessment
- ✅ Network infrastructure scanning
- ✅ CVE vulnerability lookup
- ✅ Risk-based reporting
- ✅ Email delivery system

### Planned Features (v2.0)
- [ ] API security testing
- [ ] Cloud infrastructure assessment (AWS, Azure, GCP)
- [ ] Container security scanning
- [ ] Continuous monitoring mode
- [ ] Web dashboard
- [ ] REST API interface
- [ ] GitHub Actions integration

## 📊 Project Status

**Current Version**: 1.0.0 (Private Development)
**Status**: Active Development
**Stability**: Beta

This project is currently in private development. It will be made public once it reaches production-ready status.

---

**Made with ❤️ by the NetSecTap Security Team**

*Empowering security professionals with powerful, accessible tools.*
