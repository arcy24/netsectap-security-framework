#!/usr/bin/env python3
"""
Web Assessment Report Email Sender
Sends security assessment reports via Microsoft Graph API with OAuth2
"""

import json
import sys
import os
import base64
from datetime import datetime
import subprocess
import msal
import requests

class ReportEmailer:
    def __init__(self, config_file='email-config.json'):
        """Initialize with configuration file"""
        self.config = self.load_config(config_file)
        self.access_token = None

    def load_config(self, config_file):
        """Load email configuration from JSON file"""
        config_path = os.path.join(os.path.dirname(__file__), config_file)

        if not os.path.exists(config_path):
            print(f"❌ Configuration file not found: {config_path}")
            print("Please create email-config.json using email-config.example.json as template")
            sys.exit(1)

        with open(config_path, 'r') as f:
            return json.load(f)

    def get_access_token(self):
        """Get OAuth2 access token using MSAL"""
        print(f"🔐 Authenticating with Microsoft Graph API...")

        authority = f"https://login.microsoftonline.com/{self.config['tenant_id']}"

        app = msal.ConfidentialClientApplication(
            self.config['client_id'],
            authority=authority,
            client_credential=self.config['client_secret']
        )

        # Request token with Mail.Send scope
        scopes = ['https://graph.microsoft.com/.default']

        result = app.acquire_token_for_client(scopes=scopes)

        if 'access_token' in result:
            print(f"✅ Authentication successful")
            return result['access_token']
        else:
            print(f"❌ Authentication failed")
            print(f"Error: {result.get('error')}")
            print(f"Description: {result.get('error_description')}")
            sys.exit(1)

    def convert_markdown_to_pdf(self, input_file):
        """Convert markdown file to PDF using pandoc, or use existing PDF"""
        if not os.path.exists(input_file):
            print(f"❌ Input file not found: {input_file}")
            sys.exit(1)

        # If input is already a PDF, return it directly
        if input_file.endswith('.pdf'):
            print(f"📄 Using existing PDF: {os.path.basename(input_file)}")
            return input_file

        # Generate PDF filename
        pdf_file = input_file.replace('.md', '.pdf')

        # Check if PDF already exists
        if os.path.exists(pdf_file):
            print(f"📄 Using existing PDF: {os.path.basename(pdf_file)}")
            return pdf_file

        print(f"📄 Converting {os.path.basename(input_file)} to PDF...")

        try:
            # Check if pandoc is installed
            subprocess.run(['pandoc', '--version'],
                         capture_output=True, check=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("❌ Pandoc is not installed. Install with: sudo apt-get install pandoc")
            print("   Alternative: sudo apt-get install pandoc texlive-latex-base texlive-fonts-recommended")
            sys.exit(1)

        # Convert markdown to PDF with pandoc
        try:
            subprocess.run([
                'pandoc',
                input_file,
                '-o', pdf_file,
                '--pdf-engine=pdflatex',
                '-V', 'geometry:margin=1in',
                '-V', 'fontsize=11pt',
                '--toc',
                '--toc-depth=2'
            ], check=True)

            print(f"✅ PDF created: {os.path.basename(pdf_file)}")
            return pdf_file

        except subprocess.CalledProcessError as e:
            print(f"❌ PDF conversion failed: {e}")
            print("Trying alternative method without LaTeX...")

            # Try without PDF engine (requires wkhtmltopdf)
            try:
                subprocess.run([
                    'pandoc',
                    input_file,
                    '-o', pdf_file,
                    '-t', 'html5',
                    '--metadata', 'title=Security Assessment Report'
                ], check=True)
                print(f"✅ PDF created: {os.path.basename(pdf_file)}")
                return pdf_file
            except subprocess.CalledProcessError:
                print("❌ Could not create PDF. Please install: sudo apt-get install pandoc wkhtmltopdf")
                sys.exit(1)

    def create_email_body(self, domain, report_type="Security Assessment"):
        """Create professional email body"""
        template = self.config.get('email_template', {})

        subject = template.get('subject', f'{report_type} Report - {domain}').replace('{domain}', domain)

        body = f"""
{template.get('greeting', 'Dear Valued Client,')}

{template.get('intro', f'Please find attached the comprehensive {report_type.lower()} report for {domain}.')}

This report includes:
• Executive summary with overall security rating
• Detailed technical analysis of all security layers
• Specific vulnerabilities and recommendations
• Step-by-step implementation guide
• Verification commands and testing procedures
• Cost analysis and timeline estimates

{template.get('action_items', 'We recommend reviewing the priority items in Section 5 and implementing the suggested security improvements.')}

{template.get('closing', 'If you have any questions or need assistance with implementation, please do not hesitate to contact us.')}

Best regards,
{self.config['sender_name']}
{self.config.get('company_name', 'Netsectap Labs')}
{self.config.get('contact_info', 'info@netsectap.com')}

---
This is an automated report delivery system.
Report generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}
        """

        return subject, body.strip()

    def send_email_graph_api(self, recipient, subject, body, attachment_path):
        """Send email via Microsoft Graph API with attachment"""

        # Get access token
        if not self.access_token:
            self.access_token = self.get_access_token()

        # Read PDF file and encode as base64
        try:
            with open(attachment_path, 'rb') as f:
                pdf_content = base64.b64encode(f.read()).decode('utf-8')
        except FileNotFoundError:
            print(f"❌ Attachment not found: {attachment_path}")
            sys.exit(1)

        # Build email message for Graph API
        email_msg = {
            "message": {
                "subject": subject,
                "body": {
                    "contentType": "Text",
                    "content": body
                },
                "toRecipients": [
                    {
                        "emailAddress": {
                            "address": recipient
                        }
                    }
                ],
                "attachments": [
                    {
                        "@odata.type": "#microsoft.graph.fileAttachment",
                        "name": os.path.basename(attachment_path),
                        "contentType": "application/pdf",
                        "contentBytes": pdf_content
                    }
                ]
            },
            "saveToSentItems": "true"
        }

        # Send email via Graph API
        graph_endpoint = f"https://graph.microsoft.com/v1.0/users/{self.config['sender_email']}/sendMail"

        headers = {
            'Authorization': f'Bearer {self.access_token}',
            'Content-Type': 'application/json'
        }

        print(f"📤 Sending email to {recipient} via Microsoft Graph API...")

        try:
            response = requests.post(graph_endpoint, headers=headers, json=email_msg)

            if response.status_code == 202:
                print(f"✅ Email sent successfully to {recipient}")
                return True
            else:
                print(f"❌ Failed to send email")
                print(f"Status Code: {response.status_code}")
                print(f"Response: {response.text}")
                return False

        except requests.exceptions.RequestException as e:
            print(f"❌ Error sending email: {e}")
            return False

    def send_report(self, input_file, recipient=None):
        """Main function to convert and send report"""
        # Extract domain from filename
        basename = os.path.basename(input_file)
        domain = basename.replace('.md', '').replace('.pdf', '').replace('_', '.').replace('-', '.')

        print(f"\n{'='*60}")
        print(f"📊 Web Assessment Report Email Sender (OAuth2)")
        print(f"{'='*60}")
        print(f"Report: {basename}")
        print(f"Domain: {domain}")
        print(f"Sender: {self.config['sender_email']}")
        print(f"Auth: Microsoft Graph API (OAuth2)")
        print(f"{'='*60}\n")

        # Convert markdown to PDF or use existing PDF
        pdf_file = self.convert_markdown_to_pdf(input_file)

        # Create email content
        subject, body = self.create_email_body(domain)

        # Use provided recipient or default from config
        recipient = recipient or self.config['default_recipient']

        # Send email via Graph API
        success = self.send_email_graph_api(recipient, subject, body, pdf_file)

        if success:
            print(f"\n✅ Report delivery complete!")
            print(f"   PDF: {os.path.basename(pdf_file)}")
            print(f"   Sent to: {recipient}")
            print(f"   Method: Microsoft Graph API with OAuth2")
        else:
            print(f"\n❌ Report delivery failed")
            sys.exit(1)


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print("Usage: python3 send-report.py <report-file> [recipient-email]")
        print("\nExample:")
        print("  python3 send-report.py example-domain-com.md")
        print("  python3 send-report.py example-domain-com.pdf")
        print("  python3 send-report.py example-domain-com.pdf client@example.com")
        print("\nNote: Accepts both .md (markdown) and .pdf files")
        sys.exit(1)

    report_file = sys.argv[1]
    recipient = sys.argv[2] if len(sys.argv) > 2 else None

    emailer = ReportEmailer()
    emailer.send_report(report_file, recipient)


if __name__ == '__main__':
    main()
