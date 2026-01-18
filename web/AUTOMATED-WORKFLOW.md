# Automated Web Security Assessment Workflow

## Quick Start (Zero Prompts)

To run a fully automated assessment with no prompts:

```bash
# Simple one-liner
claude "assess https://www.example.com and send report"
```

That's it! Claude will:
1. ✅ Run the assessment
2. ✅ Generate the report
3. ✅ Send via email automatically
4. ✅ No prompts or questions

---

## 🎯 Keywords I Understand - Quick Reference

**Use these commands for instant results:**

| You Say | I Do |
|---------|------|
| `assess [domain]` | Uses config default (cli/email/both) |
| `assess [domain] --cli-only` | Terminal output only |
| `assess [domain] and send report` | Email delivery |
| `assess [domain] --format summary` | Summary CLI format |
| `assess [domain] --to email@example.com` | Custom recipient |

**Examples:**
```bash
# Quick CLI check
assess app.example.com --cli-only

# Send to client
assess client-site.com and send report --to client@example.com

# Detailed terminal output
assess api.example.com --format detailed
```

---

## Configuration File

The assessment behavior is controlled by `assessment-config.json`:

```json
{
  "assessment_preferences": {
    "auto_send_report": true,          ← Send report automatically
    "prompt_for_confirmation": false,  ← No prompts, just do it
    "auto_fix_suggestions": false,     ← Don't auto-apply fixes
    "assessment_tier": "tier1"         ← Default tier level
  }
}
```

### Key Settings:

| Setting | Value | Behavior |
|---------|-------|----------|
| `auto_send_report` | `true` | Automatically send report after generation |
| `prompt_for_confirmation` | `false` | Don't ask for confirmation, just proceed |
| `auto_fix_suggestions` | `false` | Generate recommendations, but don't apply |
| `assessment_tier` | `"tier1"` | Use Tier 1 (non-intrusive) tools only |

---

## Usage Patterns

### Pattern 1: Fully Automated (Recommended)

**Command:**
```
assess app.example.com and send report
```

**What Happens:**
1. Claude reads config → sees `auto_send_report: true`
2. Runs assessment tools automatically
3. Generates markdown report
4. Converts to PDF
5. Sends email to default recipient
6. Confirms completion

**No prompts. No questions. Done.**

---

### Pattern 2: Assess Only (No Send)

**Command:**
```
assess app.example.com (don't send)
```

**What Happens:**
1. Runs assessment
2. Generates report
3. Saves to file
4. Waits for manual send command

---

### Pattern 3: Assess Multiple Sites

**Command:**
```
assess all domains in config
```

**What Happens:**
1. Reads domains from `assessment-config.json`
2. Runs assessment for each
3. Generates individual reports
4. Sends all reports (if auto_send enabled)

---

### Pattern 4: Assess and Fix

**Command:**
```
assess and fix app.example.com
```

**What Happens:**
1. Runs assessment
2. Generates report with recommendations
3. Waits for approval to apply fixes
4. Applies fixes in Cloudflare
5. Re-assesses to verify
6. Sends before/after report

---

## 🔑 Complete Keywords Reference

Claude will automatically recognize these keywords and act accordingly:

### 📊 Assessment Commands
| Keyword | Action |
|---------|--------|
| `assess [domain]` | Run full assessment |
| `assess [domain] --cli-only` | Terminal output only |
| `assess [domain] and send report` | Email delivery |
| `assess all sites` | Batch assessment of all configured domains |

### 📝 Report Format Options
| Keyword | Action |
|---------|--------|
| `--format summary` | Summary CLI format (default) |
| `--format detailed` | Detailed CLI format |
| `--format minimal` | Minimal/CSV format for scripting |

### 📧 Delivery Options
| Keyword | Action |
|---------|--------|
| `and send report` | Auto-send after completion |
| `--to email@example.com` | Custom recipient |
| `don't send` or `--cli-only` | No email delivery |

### ⚙️ Behavior Modifiers
| Keyword | Action |
|---------|--------|
| `don't prompt` or `no prompts` | Use config defaults, no questions |
| `and fix` | Generate remediation plan |
| `verify fixes` | Re-run assessment to check improvements |
| `re-assess` | Run assessment again for comparison |

---

## Default Behavior (Based on Config)

With `prompt_for_confirmation: false`, Claude will:

✅ **Automatically:**
- Run reconnaissance tools
- Analyze security headers
- Check SSL/TLS configuration
- Generate comprehensive report
- Create PDF
- Send email (if auto_send enabled)

❌ **Won't Prompt For:**
- Recipient email (uses default from config)
- Report format (uses template)
- Tool selection (uses tier1)
- Confirmation before sending

✅ **Will Still Ask For:**
- Authorization for Tier 2/3 assessments (security requirement)
- Confirmation before applying fixes to production
- Clarification if domain is ambiguous

---

## Example Workflows

### Workflow 1: New Site Assessment
```bash
# You say:
assess api.example.com and send report

# Claude does (no prompts):
1. Runs DNS, SSL, headers, tech detection
2. Generates report → api-example-com.md
3. Creates PDF → api-example-com.pdf
4. Sends to: security@example.com
5. Confirms: "Report sent! Score: 85/100 (B+)"
```

### Workflow 2: Re-Assessment After Fixes
```bash
# You say:
re-assess app.example.com and send report

# Claude does:
1. Runs assessment again
2. Compares to previous score
3. Shows improvements
4. Sends updated report
```

### Workflow 3: Bulk Assessment
```bash
# You say:
assess all sites and send reports

# Claude does:
1. Reads domains from config
2. Assesses each in parallel
3. Generates all reports
4. Sends all via email
5. Summary: "3 reports sent, avg score: 88/100"
```

---

## Customizing the Config

Edit `assessment-config.json` to change behavior:

### More Control (Ask Before Sending)
```json
{
  "assessment_preferences": {
    "auto_send_report": false,        ← Changed to false
    "prompt_for_confirmation": true   ← Changed to true
  }
}
```

### Different Recipient
```json
{
  "assessment_preferences": {
    "default_recipient": "security@example.com"
  }
}
```

### Auto-Fix (Experimental)
```json
{
  "assessment_preferences": {
    "auto_fix_suggestions": true      ← Enable auto-fix
  },
  "thresholds": {
    "minimum_acceptable_score": 90    ← Only fix if below 90
  }
}
```

---

## Shell Script Alternative

If you prefer shell scripts, use the included script:

```bash
# Make executable (one-time)
chmod +x run-assessment.sh

# Run assessment
./run-assessment.sh app.example.com --auto-send

# Then tell Claude:
"Generate report from the collected data and send it"
```

---

## Tips for Zero-Prompt Workflow

1. **Use clear domain names:**
   - ✅ Good: `assess app.example.com`
   - ❌ Ambiguous: `assess myapp`

2. **Be explicit about sending:**
   - ✅ Good: `assess [domain] and send report`
   - ⚠️ Will ask: `assess [domain]` (unclear if you want it sent)

3. **Override config when needed:**
   - `assess [domain] but don't send` (overrides auto_send)
   - `assess [domain] and ask for confirmation` (overrides no-prompt)

4. **Set up email config once:**
   - Ensure `email-config.json` is properly configured
   - Test with one manual send first
   - Then enable auto-send in assessment-config.json

---

## Troubleshooting

**Problem:** Claude still asks questions

**Solution:** Check these settings in `assessment-config.json`:
- `prompt_for_confirmation` should be `false`
- `auto_send_report` should be `true`
- Say explicitly: "don't prompt me for anything"

**Problem:** Reports not sending automatically

**Solution:**
- Verify `email-config.json` is configured
- Check `auto_send_report: true` in assessment-config.json
- Test email system manually: `python3 send-report.py test.md`

**Problem:** Claude asks about tier level

**Solution:** Specify in command or config:
- Command: `run tier1 assessment on [domain]`
- Config: `"assessment_tier": "tier1"`

---

## Security Notes

**Important:** Auto-fix is disabled by default for safety.

- ✅ **Safe:** Auto-assess and auto-send reports (read-only)
- ⚠️ **Requires approval:** Applying fixes to production systems
- 🔒 **Never automated:** Tier 2/3 assessments (active scanning)

Even with `prompt_for_confirmation: false`, Claude will still ask before:
- Making changes to Cloudflare settings
- Modifying DNS records
- Applying security fixes to production
- Running active vulnerability scans (Tier 2/3)

This is a safety feature to prevent unintended changes.

---

## Future Enhancements

Planned improvements:
- [ ] Scheduled assessments (cron integration)
- [ ] Slack/Teams notifications
- [ ] Automated fix application (with approval workflow)
- [ ] Comparison reports (monthly trends)
- [ ] API integration for CI/CD pipelines

---

## Summary

**Zero-Prompt Command:**
```
assess [domain].example.com and send report
```

**Config File:** `assessment-config.json`

**Key Setting:** `prompt_for_confirmation: false`

**Result:** Fully automated assessment with no questions asked.

---

**Last Updated:** December 20, 2025
**Version:** 1.0
**Author:** Netsectap Labs
