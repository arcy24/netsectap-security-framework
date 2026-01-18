# Report Delivery Options

## Configuration Options

### Option 1: CLI Report (Terminal Output Only)

**Config Setting:**
```json
{
  "assessment_preferences": {
    "report_delivery_method": "cli",
    "auto_send_report": false
  },
  "report_settings": {
    "cli_report_format": "summary"
  }
}
```

**Command:**
```
assess app.example.com
```

**Output (in terminal):**
```
============================================================
Web Security Assessment - app.example.com
============================================================
Score: 90/100 (Grade A)

Critical Issues: 0
High Priority: 0
Medium Priority: 2
  - TLS 1.0/1.1 still enabled
  - No CAA records

Recommendations:
1. Disable TLS 1.0 and 1.1
2. Add DNS CAA records

Full report saved: app-example-com.md
============================================================
```

---

### Option 2: Email Report (PDF via Email)

**Config Setting:**
```json
{
  "assessment_preferences": {
    "report_delivery_method": "email",
    "auto_send_report": true,
    "default_recipient": "security@example.com"
  },
  "report_settings": {
    "auto_generate_pdf": true
  }
}
```

**Command:**
```
assess app.example.com and send report
```

**Output:**
```
✅ Assessment complete: 90/100 (A)
✅ PDF generated: app-example-com.pdf
✅ Email sent to: security@example.com
```

---

### Option 3: Both (CLI + Email)

**Config Setting:**
```json
{
  "assessment_preferences": {
    "report_delivery_method": "both",
    "auto_send_report": true,
    "default_recipient": "security@example.com"
  },
  "report_settings": {
    "cli_report_format": "summary",
    "auto_generate_pdf": true
  }
}
```

**Command:**
```
assess app.example.com
```

**Output:**
1. Shows summary in terminal
2. Sends full PDF via email

---

## CLI Report Formats

You can customize the CLI output format:

### Format: `summary` (Default)
**Best for:** Quick overview
```
Score: 90/100 (A)
Critical: 0, High: 0, Medium: 2
Top issues:
  - TLS 1.0/1.1 enabled
  - No CAA records
```

### Format: `detailed`
**Best for:** Full analysis without opening PDF
```
Score: 90/100 (A)

Security Headers: 25/25 (A+)
  ✅ HSTS: enabled
  ✅ CSP: enabled
  ✅ X-Frame-Options: SAMEORIGIN
  ...

SSL/TLS: 15/20 (B+)
  ✅ TLS 1.2: enabled
  ✅ TLS 1.3: enabled
  ⚠️ TLS 1.0: enabled (deprecated)
  ⚠️ TLS 1.1: enabled (deprecated)

[Full detailed breakdown...]
```

### Format: `minimal`
**Best for:** Automation/scripting
```
app.example.com,90,A,0,0,2
```
(CSV format: domain, score, grade, critical, high, medium)

---

## Command-Line Overrides

You can override the config for individual assessments:

### Force CLI Output (even if email is default)
```
assess app.example.com --cli-only
```

### Force Email (even if CLI is default)
```
assess app.example.com --send-email
```

### Specify Format
```
assess app.example.com --format detailed
```

### Specify Recipient
```
assess app.example.com --to security@example.com
```

---

## Usage Examples

### Example 1: Quick Check (CLI Only)
**Goal:** Quickly check a site without creating/sending a report

**Command:**
```
assess api.example.com --cli-only --format summary
```

**Result:** Shows score and issues in terminal, no email, no PDF

---

### Example 2: Client Report (Email Only)
**Goal:** Professional report for client, no terminal clutter

**Command:**
```
assess client-site.com --send-email --to client@example.com
```

**Result:** Generates PDF, sends email, minimal terminal output

---

### Example 3: Internal Review (Both)
**Goal:** See results now, have PDF for records

**Command:**
```
assess app.example.com --format detailed
```

**Result:** Full analysis in terminal + PDF sent to default recipient

---

### Example 4: Automation/Scripting (Minimal)
**Goal:** Parse results in scripts

**Command:**
```
assess site.com --format minimal --cli-only
```

**Result:** CSV output (parseable)

---

## Configuration Reference

```json
{
  "assessment_preferences": {
    "report_delivery_method": "cli" | "email" | "both"
  },
  "report_settings": {
    "cli_report_format": "summary" | "detailed" | "minimal"
  }
}
```

---

## Keywords Claude Understands

| Keyword | Action |
|---------|--------|
| `--cli-only` or `show in terminal` | CLI output only |
| `--send-email` or `and send report` | Email delivery |
| `--format summary` | Summary CLI format |
| `--format detailed` | Detailed CLI format |
| `--format minimal` | CSV/minimal format |
| `--to email@example.com` | Override recipient |

---

## Tips

1. **For daily checks:** Use `cli` mode with `summary` format
2. **For client reports:** Use `email` mode
3. **For yourself:** Use `both` mode to see results immediately and keep PDF
4. **For automation:** Use `cli` mode with `minimal` format

---

## Examples by Use Case

### Daily Security Monitoring
```json
{
  "report_delivery_method": "cli",
  "cli_report_format": "summary"
}
```
Command: `assess all sites`

### Monthly Client Reports
```json
{
  "report_delivery_method": "email",
  "auto_generate_pdf": true
}
```
Command: `assess client-site.com and send report`

### Post-Fix Verification
```json
{
  "report_delivery_method": "both",
  "cli_report_format": "detailed"
}
```
Command: `re-assess app.example.com`

---

**Last Updated:** December 20, 2025
**Version:** 1.0
