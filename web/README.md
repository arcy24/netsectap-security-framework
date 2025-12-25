# Web Application Security Assessment

> Part of the [NetSecTap Security Assessment Framework](../README.md)
> For unified assessment launcher, see: `../run-assessment.sh`

This toolkit provides comprehensive web application security testing including SSL/TLS analysis, OWASP vulnerability checks, HTTP headers evaluation, and automated report generation with email delivery.

## Part of Unified Framework

This is the **Web Assessment** component of the NetSecTap Security Assessment Framework. You can:
- Run web assessments directly from this folder (see below)
- Use the unified launcher: `cd .. && ./run-assessment.sh web`
- Run both web and network assessments: `cd .. && ./run-assessment.sh both`

For network infrastructure assessments, see: [../network/README.md](../network/README.md)

## Contents

- **Web-Assessment.md** - Template for creating new security assessment reports
- **send-report.py** - Automated email delivery script (OAuth2/Graph API)
- **email-config.json** - Email configuration (not committed to git)
- **email-config.example.json** - Example configuration file
- **[domain].md** - Assessment reports in Markdown format (tracked in git)
- **[domain].pdf** - Assessment reports in PDF format (tracked in git)

**Note:** All assessment reports are saved in both `.md` (Markdown) and `.pdf` (PDF) formats for maximum compatibility and archival purposes.

## Quick Start

### 1. First-Time Setup

#### Install Required Dependencies

```bash
# Install Python packages for OAuth2 and Microsoft Graph API
pip3 install msal requests --break-system-packages

# Install Pandoc and LaTeX for PDF conversion
sudo apt-get update
sudo apt-get install pandoc texlive-latex-base texlive-fonts-recommended texlive-latex-extra wkhtmltopdf

# Verify installation
pandoc --version
python3 -c "import msal; print('MSAL installed successfully')"
```

#### Configure Azure App Registration

This system uses **OAuth2 with Microsoft Graph API** for secure, modern authentication (no passwords needed).

**Step 1: Create Azure App Registration**

1. Go to Azure Portal: https://portal.azure.com
2. Navigate to **Azure Active Directory** → **App registrations**
3. Click **+ New registration**
4. Enter:
   - **Name**: "Netsectap Email Automation" (or your preferred name)
   - **Supported account types**: "Accounts in this organizational directory only"
   - **Redirect URI**: Leave blank
5. Click **Register**
6. Note down:
   - **Application (client) ID**
   - **Directory (tenant) ID**

**Step 2: Create Client Secret**

1. In your App Registration, go to **Certificates & secrets**
2. Click **+ New client secret**
3. Enter:
   - **Description**: "Email automation secret"
   - **Expires**: Choose duration (recommended: 24 months)
4. Click **Add**
5. **IMPORTANT**: Copy the **Value** immediately (you can only see it once)

**Step 3: Configure API Permissions**

1. In your App Registration, go to **API permissions**
2. Click **+ Add a permission**
3. Select **Microsoft Graph**
4. Select **Application permissions** (NOT Delegated)
5. Search for and add: **Mail.Send**
6. Click **Add permissions**
7. **CRITICAL**: Click **Grant admin consent for [your tenant]**
8. Verify the status shows a green checkmark ✅

**Step 4: Configure Email Settings**

```bash
# Navigate to Web-assessment folder
cd /root/netsectap-labs-site/Web-assessment

# Copy example config (if needed)
cp email-config.example.json email-config.json

# Edit configuration with your Azure credentials
nano email-config.json
```

**Required Settings:**
```json
{
  "auth_method": "oauth2",
  "client_id": "your-client-id-from-azure",
  "client_secret": "your-client-secret-value",
  "tenant_id": "your-tenant-id-from-azure",
  "sender_email": "your-email@yourdomain.com",
  "sender_name": "Your Name or Team Name",
  "default_recipient": "client@example.com"
}
```

**Security Notes:**
- Client secrets are more secure than passwords
- Rotate secrets before expiration
- Never commit email-config.json to git (already in .gitignore)
- OAuth2 tokens are automatically managed and expire after 1 hour

### 2. Send Assessment Report

#### Basic Usage (Use Default Recipient)

```bash
cd /root/netsectap-labs-site/Web-assessment
python3 send-report.py openllm.netsectap-labs-com.md
```

#### Send to Specific Client

```bash
python3 send-report.py openllm.netsectap-labs-com.md client@example.com
```

### 3. What Happens

The script will:
1. ✅ Convert markdown report to professional PDF (using Pandoc)
2. ✅ Authenticate with Microsoft Graph API using OAuth2
3. ✅ Create professional email with summary
4. ✅ Attach PDF report
5. ✅ Send via Microsoft Graph API
6. ✅ Confirm delivery

**Example Output:**
```
============================================================
📊 Web Assessment Report Email Sender (OAuth2)
============================================================
Report: openllm.netsectap-labs-com.md
Domain: openllm.netsectap.labs.com
Sender: rcaparros@netsectap-labs.com
Auth: Microsoft Graph API (OAuth2)
============================================================

📄 Converting openllm.netsectap-labs-com.md to PDF...
✅ PDF created: openllm.netsectap-labs-com.pdf
🔐 Authenticating with Microsoft Graph API...
✅ Authentication successful
📤 Sending email to client@example.com via Microsoft Graph API...
✅ Email sent successfully to client@example.com

✅ Report delivery complete!
   PDF: openllm.netsectap-labs-com.pdf
   Sent to: client@example.com
   Method: Microsoft Graph API with OAuth2
```

## Assessment Tools

### Overview: Three-Tier Assessment Approach

Netsectap Labs uses a tiered assessment methodology to ensure appropriate scope and authorization:

**Tier 1: Non-Intrusive Assessment (Default)**
- Passive reconnaissance only
- No client authorization required
- Safe to use on any publicly accessible site
- Tools: DNS enumeration, HTTP header inspection, technology detection

**Tier 2: Light Active Scanning (Future)**
- Requires written client authorization
- Port scanning, vulnerability detection
- Tools: nmap, nuclei, OWASP ZAP passive mode

**Tier 3: Full Penetration Testing (Future)**
- Requires signed SOW and authorization letter
- Comprehensive security testing
- Tools: Nikto, Burp Suite, exploit frameworks

### Tier 1 Tools Installation

**Technology Detection: whatweb**

Identifies CMS platforms, web frameworks, server software, and security headers.

```bash
# Install whatweb
sudo apt-get update
sudo apt-get install whatweb

# Test installation
whatweb --version
```

**SSL/TLS Analysis: testssl.sh**

Comprehensive SSL/TLS configuration testing including cipher suites, protocols, and vulnerabilities.

```bash
# Install testssl.sh
cd /opt
sudo git clone --depth 1 https://github.com/drwetter/testssl.sh.git
sudo chmod +x /opt/testssl.sh/testssl.sh

# Install required dependency
sudo apt-get install bsdmainutils

# Test installation
/opt/testssl.sh/testssl.sh --version
```

### Tier 1 Tool Usage Examples

**Technology Detection with whatweb:**

```bash
# Basic scan
whatweb https://example.com

# Detailed output with no color (for logs)
whatweb --color=never https://example.com

# Example output:
# https://www.netsectap.com [200 OK]
# Cloudflare[104.21.92.127,172.67.193.75]
# Country[UNITED STATES][US]
# HTML5
# HTTPServer[cloudflare]
# Strict-Transport-Security[max-age=31536000; includeSubDomains]
```

**SSL/TLS Analysis with testssl.sh:**

```bash
# Full SSL/TLS scan (comprehensive)
/opt/testssl.sh/testssl.sh https://example.com

# Quick check (protocols and ciphers only)
/opt/testssl.sh/testssl.sh --fast https://example.com

# Check specific aspects
/opt/testssl.sh/testssl.sh --protocols https://example.com
/opt/testssl.sh/testssl.sh --server-defaults https://example.com

# Output to file for report inclusion
/opt/testssl.sh/testssl.sh --htmlfile example-ssl-report.html https://example.com
```

**Combined Assessment Workflow:**

```bash
# Run complete Tier 1 assessment
TARGET="https://example.com"

echo "=== Tier 1 Assessment: $TARGET ==="

# 1. Technology Detection
echo "[*] Running technology detection..."
whatweb --color=never $TARGET

# 2. DNS Information
echo "[*] Gathering DNS information..."
dig $(echo $TARGET | sed 's|https://||' | sed 's|/.*||') +short

# 3. Security Headers
echo "[*] Checking security headers..."
curl -sI $TARGET | grep -iE "x-frame|x-content|strict-transport|referrer|permissions|content-security"

# 4. SSL/TLS Quick Check
echo "[*] Running SSL/TLS analysis..."
/opt/testssl.sh/testssl.sh --fast $TARGET

# 5. WHOIS Information
echo "[*] Domain registration info..."
whois $(echo $TARGET | sed 's|https://||' | sed 's|/.*||') | grep -iE "registrar:|creation|expiry"
```

### Integration with Assessment Reports

When creating assessment reports, include Tier 1 tool outputs in the following sections:

**1. Initial Assessment (Technology Stack):**
```markdown
**Technology Detection:**
```bash
$ whatweb --color=never https://client-site.com
[Include output here]
```
```

**2. SSL/TLS Configuration:**
```markdown
**Detailed SSL/TLS Analysis:**
```bash
$ testssl.sh --protocols --server-defaults https://client-site.com
[Include relevant sections]
```
```

**3. Infrastructure Section:**
- Use `dig` output for IP addresses and nameservers
- Use `whois` output for domain registration details
- Use `whatweb` for CDN and hosting provider identification

### Tool Output Parsing Tips

**Extracting Key Information:**

```bash
# Get just the security headers from whatweb
whatweb --color=never https://example.com | grep -oP '(?<=\[)[^\]]*(?=\])' | grep -i "security\|frame\|content-type"

# Get TLS version and cipher from testssl.sh
/opt/testssl.sh/testssl.sh --protocols https://example.com | grep -E "TLS 1\.[23]|Cipher"

# Get certificate expiry
openssl s_client -connect example.com:443 -servername example.com </dev/null 2>/dev/null | openssl x509 -noout -dates
```

## Email Template Customization

Edit `email-config.json` to customize the email template:

```json
{
  "email_template": {
    "subject": "Security Assessment Report - {domain}",
    "greeting": "Dear Valued Client,",
    "intro": "Please find attached...",
    "action_items": "We recommend reviewing...",
    "closing": "If you have any questions..."
  }
}
```

The `{domain}` placeholder will be automatically replaced with the domain name from the report filename.

## Workflow: Creating and Sending a New Assessment

### Step 1: Create New Assessment Report

```bash
# Copy template
cp Web-Assessment.md new-client-domain-com.md

# Edit with assessment details
nano new-client-domain-com.md
```

### Step 2: Conduct Assessment

Use the template sections to document:
- Executive Summary
- Security Headers Analysis
- SSL/TLS Configuration
- Vulnerability Assessment
- Protection Layers
- Implementation Plan
- Cost Analysis

### Step 3: Send Report to Client

```bash
# Send report
python3 send-report.py new-client-domain-com.md client@clientdomain.com

# Or use default recipient from config
python3 send-report.py new-client-domain-com.md
```

### Step 4: Commit Report to Repository

```bash
cd /root/netsectap-labs-site
git add Web-assessment/new-client-domain-com.md
git commit -m "Add security assessment for new-client-domain.com"
git push
```

**Note:** The PDF and email-config.json are in `.gitignore` and won't be committed.

## Troubleshooting

### Problem: "Pandoc is not installed"
**Solution:**
```bash
sudo apt-get install pandoc texlive-latex-base texlive-fonts-recommended texlive-latex-extra wkhtmltopdf
```

### Problem: "Authentication failed" or "Access is denied"
**Possible Causes:**
1. Incorrect Client ID, Client Secret, or Tenant ID
2. Mail.Send permission not configured in Azure
3. Admin consent not granted
4. Permissions still propagating (can take 5-15 minutes)

**Solution:**
```bash
# Verify Azure App Registration settings:
# 1. Check API permissions page in Azure Portal
# 2. Ensure Mail.Send (Application) permission is added
# 3. Verify "Granted for [tenant]" shows green checkmark
# 4. Wait 5-15 minutes for permissions to propagate
# 5. Verify credentials in email-config.json match Azure Portal

# Test OAuth2 token acquisition:
python3 -c "
import msal, json
config = json.load(open('email-config.json'))
app = msal.ConfidentialClientApplication(
    config['client_id'],
    authority=f\"https://login.microsoftonline.com/{config['tenant_id']}\",
    client_credential=config['client_secret']
)
result = app.acquire_token_for_client(scopes=['https://graph.microsoft.com/.default'])
print('Success!' if 'access_token' in result else f'Error: {result}')
"
```

### Problem: "Configuration file not found"
**Solution:**
```bash
cp email-config.example.json email-config.json
nano email-config.json  # Add your Azure credentials
```

### Problem: PDF conversion fails
**Solution:**
The script has built-in fallback. If LaTeX fails, it automatically tries wkhtmltopdf:
```bash
# Install alternative PDF generator
sudo apt-get install wkhtmltopdf

# For Unicode support (emojis), install additional packages
sudo apt-get install texlive-latex-extra
```

### Problem: "ErrorAccessDenied" (HTTP 403)
**Cause:** Mail.Send permission not properly configured

**Solution:**
1. Go to Azure Portal → App registrations → Your app
2. Click "API permissions"
3. Verify "Mail.Send" shows as "Application" type (NOT Delegated)
4. Click "Grant admin consent for [tenant]" if not already granted
5. Wait 5 minutes for propagation
6. Retry sending email

### Problem: "ModuleNotFoundError: No module named 'msal'"
**Solution:**
```bash
pip3 install msal requests --break-system-packages
```

## Security Best Practices

1. **Never commit email-config.json** - Contains sensitive OAuth2 credentials (already in .gitignore)
2. **Rotate client secrets before expiration** - Azure lets you set expiration dates (recommended: 24 months)
3. **Use Application permissions** - More secure than Delegated permissions for automation
4. **Limit API permissions** - Only grant Mail.Send, not broader permissions like Mail.ReadWrite
5. **Limit recipient access** - Only send reports to authorized contacts
6. **Review PDFs before sending** - Ensure no sensitive internal data is included
7. **Monitor Azure sign-in logs** - Check for unusual authentication activity
8. **Use separate App Registration** - Don't reuse OAuth2 apps across different services

## File Structure

```
Web-assessment/
├── README.md                          # This file
├── Web-Assessment.md                  # Template for new reports
├── send-report.py                     # Email automation script
├── email-config.json                  # Your credentials (not in git)
├── email-config.example.json          # Example configuration
├── .gitignore                         # Excludes sensitive files
├── openllm.netsectap-labs-com.md     # Example: OpenLLM assessment
├── www.netsectap.com-assessment.md   # Example: Main site assessment
└── [future-reports].md               # Additional client reports
```

## Command Reference

```bash
# Send with default recipient
python3 send-report.py report.md

# Send to specific recipient
python3 send-report.py report.md client@example.com

# Test PDF conversion only (manual)
pandoc report.md -o report.pdf --pdf-engine=pdflatex -V geometry:margin=1in

# View configuration (without sensitive data)
cat email-config.json | grep -v client_secret

# Test OAuth2 authentication only
python3 -c "
import msal, json
config = json.load(open('email-config.json'))
app = msal.ConfidentialClientApplication(
    config['client_id'],
    authority=f\"https://login.microsoftonline.com/{config['tenant_id']}\",
    client_credential=config['client_secret']
)
result = app.acquire_token_for_client(scopes=['https://graph.microsoft.com/.default'])
print('✅ OAuth2 authentication successful!' if 'access_token' in result else f'❌ Error: {result}')
"

# Make script executable (optional)
chmod +x send-report.py
./send-report.py report.md
```

## Support

For issues or questions:
- **Email:** rcaparros@netsectap-labs.com
- **GitHub:** https://github.com/arcy24/netsectap-labs-site
- **Company:** https://www.netsectap.com

---

**© 2025 Netsectap Labs** - A part of Netsectap LLC
