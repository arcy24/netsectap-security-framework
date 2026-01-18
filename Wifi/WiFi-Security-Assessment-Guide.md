# WiFi Security Assessment: A Comprehensive How-To Guide

## Overview

This guide provides a systematic approach to assessing the security posture of WiFi networks using common Linux tools. This methodology covers interface configuration, network reconnaissance, encryption analysis, and vulnerability assessment.

**Target Audience:** Network administrators, security professionals, and ethical hackers performing authorized security assessments.

**Legal Disclaimer:** Only perform security assessments on networks you own or have explicit written authorization to test. Unauthorized network scanning and penetration testing is illegal in most jurisdictions.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Phase 1: Interface Setup and Network Connection](#phase-1-interface-setup-and-network-connection)
3. [Phase 2: Network Reconnaissance](#phase-2-network-reconnaissance)
4. [Phase 3: Encryption Analysis with aircrack-ng](#phase-3-encryption-analysis-with-aircrack-ng)
5. [Phase 4: Security Analysis and Scoring](#phase-4-security-analysis-and-scoring)
6. [Phase 5: Reporting and Recommendations](#phase-5-reporting-and-recommendations)
7. [Common WiFi Security Issues](#common-wifi-security-issues)
8. [Best Practices and Recommendations](#best-practices-and-recommendations)

---

## Prerequisites

### Required Tools

```bash
# Check if tools are installed
command -v nmcli && echo "nmcli: installed" || echo "nmcli: NOT installed"
command -v iw && echo "iw: installed" || echo "iw: NOT installed"
command -v nmap && echo "nmap: installed" || echo "nmap: NOT installed"
command -v aircrack-ng && echo "aircrack-ng: installed" || echo "aircrack-ng: NOT installed"
command -v airodump-ng && echo "airodump-ng: installed" || echo "airodump-ng: NOT installed"
command -v airmon-ng && echo "airmon-ng: installed" || echo "airmon-ng: NOT installed"
```

### Install Missing Tools (Debian/Ubuntu/Kali)

```bash
# Network Manager CLI
sudo apt install network-manager

# Wireless tools
sudo apt install iw wireless-tools

# Nmap for network scanning
sudo apt install nmap

# Aircrack-ng suite
sudo apt install aircrack-ng
```

### Required Permissions

- Root/sudo access for monitor mode and packet capture
- A wireless adapter that supports monitor mode (check compatibility)

---

## Phase 1: Interface Setup and Network Connection

### Step 1.1: Identify Wireless Interface

```bash
# List all network interfaces
ip link show

# List only wireless interfaces
iw dev

# Check interface status
ip link show wlan0
```

**Expected Output:**
```
3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DORMANT group default qlen 1000
```

### Step 1.2: Enable Wireless Interface

If the interface shows `state DOWN`, enable it:

```bash
# Bring interface up
sudo ip link set wlan0 up

# Verify interface is UP
ip link show wlan0 | grep -o "state [A-Z]*"
```

### Step 1.3: Check for RF Blocks

```bash
# Check if WiFi is blocked by rfkill
rfkill list

# Unblock WiFi if necessary
sudo rfkill unblock wifi
```

### Step 1.4: Scan for Available Networks

```bash
# Scan for WiFi networks
nmcli device wifi list

# Rescan to refresh results
nmcli device wifi rescan
nmcli device wifi list
```

**Sample Output:**
```
IN-USE  BSSID              SSID            MODE   CHAN  RATE        SIGNAL  BARS  SECURITY
        C2:A5:11:A9:EF:07  Birokadyan      Infra  3     270 Mbit/s  82      ****  WPA2
        14:C1:4E:B3:E8:05  Google-Home     Infra  6     270 Mbit/s  67      ***   WPA2
```

### Step 1.5: Connect to Target Network

```bash
# Connect to network with password
nmcli device wifi connect "NetworkName" password "YourPassword"

# Verify connection
nmcli connection show --active

# Check IP address assignment
ip addr show wlan0 | grep "inet "

# Test connectivity
ping -c 3 google.com
```

### Step 1.6: Gather Connection Details

```bash
# View detailed connection info
nmcli connection show "NetworkName"

# Extract security settings
nmcli connection show "NetworkName" | grep -E "802-11-wireless-security|encryption"

# Get gateway/router information
ip route | grep default
```

---

## Phase 2: Network Reconnaissance

### Step 2.1: Gateway Identification

```bash
# Identify default gateway
ip route | grep default

# Example output: default via 172.16.70.1 dev wlan0 proto dhcp metric 600
```

### Step 2.2: Scan Network with iw

```bash
# Detailed WiFi scan with encryption info
sudo iw dev wlan0 scan | grep -E "SSID|signal|WPA|WEP|freq|DS Parameter set"

# Filter for specific network
sudo iw dev wlan0 scan | grep -A 20 "SSID: YourNetworkName"
```

**Key Information to Extract:**
- SSID (network name)
- BSSID (MAC address of access point)
- Frequency/Channel
- Signal strength
- Authentication type (WPA2-PSK, WPA3-SAE)
- Encryption cipher (CCMP, TKIP)
- WPS status
- PMF (Protected Management Frames) support

### Step 2.3: Host Discovery Scan

```bash
# Determine your subnet
ip addr show wlan0 | grep "inet "
# Example: inet 172.16.70.134/24

# Ping scan to discover active hosts (no port scan)
sudo nmap -sn 172.16.70.0/24 -oN network_hosts.nmap

# View results
cat network_hosts.nmap
```

**Sample Output Analysis:**
```
Nmap scan report for 172.16.70.1
Host is up (0.11s latency).
MAC Address: 90:EC:77:5B:AF:AA (silicom)

Nmap scan report for 172.16.70.101
Host is up (0.017s latency).
MAC Address: BC:A5:11:AF:87:52 (Netgear)
```

### Step 2.4: Identify Unknown Devices

Create an inventory of discovered hosts:

```bash
# Extract MAC addresses and vendors
grep "MAC Address:" network_hosts.nmap | awk '{print $3, $4}' | sort -u
```

**Device Classification:**
- Gateway/Router
- Access Points
- IoT devices (Nest, Amazon Echo, Google Home)
- Computers/Laptops
- Mobile devices
- Unknown/Unidentified (security concern)

---

## Phase 3: Encryption Analysis with aircrack-ng

### Step 3.1: Enable Monitor Mode

```bash
# Check for conflicting processes
sudo airmon-ng check

# Kill interfering processes (optional but recommended)
sudo airmon-ng check kill

# Enable monitor mode
sudo airmon-ng start wlan0

# Verify monitor interface created
iw dev
# Should show wlan0mon in monitor mode
```

### Step 3.2: Capture WiFi Traffic

```bash
# Scan all 2.4GHz and 5GHz channels, save to CSV
sudo timeout 30 airodump-ng wlan0mon --band abg --output-format csv --write /tmp/wifi_scan

# Or scan specific channel only
sudo timeout 30 airodump-ng wlan0mon --channel 3 --output-format csv --write /tmp/wifi_scan

# For live viewing (no timeout)
sudo airodump-ng wlan0mon --band bg
```

**Key Observations:**
- PWR (power): Signal strength (closer to 0 is stronger)
- Beacons: Number of announcement frames sent by AP
- CH (Channel): Operating channel
- MB: Maximum speed
- ENC: Encryption type (WPA2, WPA3, WEP, OPN)
- CIPHER: Encryption cipher (CCMP, TKIP)
- AUTH: Authentication method (PSK, MGT, SAE)

### Step 3.3: Analyze Scan Results

```bash
# Parse CSV file for your target network
grep "TargetSSID" /tmp/wifi_scan-01.csv

# Example output:
# C2:A5:11:A9:EF:07, 2026-01-04 19:27:16, 2026-01-04 19:27:27,  3, 360, WPA2, CCMP, PSK, -61, 14, 0, 0.0.0.0, 10, Birokadyan,
```

**Encryption Analysis:**

| Encryption | Cipher | Auth | Security Level | Notes |
|------------|--------|------|----------------|-------|
| WPA3 | CCMP | SAE | Excellent | Latest standard, resistant to offline attacks |
| WPA2 | CCMP | PSK | Good | Vulnerable to handshake capture + brute force |
| WPA2 | TKIP | PSK | Fair | Deprecated cipher, known vulnerabilities |
| WPA | CCMP/TKIP | PSK | Poor | Outdated protocol, should not be used |
| WEP | WEP | Open | Critical | Broken encryption, cracks in seconds |
| OPN | None | None | Critical | No encryption whatsoever |

### Step 3.4: Disable Monitor Mode

```bash
# Stop monitor mode
sudo airmon-ng stop wlan0mon

# Restart Network Manager if needed
sudo systemctl restart NetworkManager

# Reconnect to network
nmcli device wifi connect "NetworkName" password "YourPassword"
```

---

## Phase 4: Security Analysis and Scoring

### Security Assessment Checklist

#### 1. Encryption Strength
- [ ] WPA3 enabled (10 points)
- [ ] WPA2 with CCMP/AES (7 points)
- [ ] WPA2 with TKIP (4 points)
- [ ] WPA only (2 points)
- [ ] WEP or Open (0 points - critical)

#### 2. Authentication Security
- [ ] WPA3-SAE (10 points)
- [ ] WPA2-PSK with strong password (7 points)
- [ ] WPA2-PSK with weak password (4 points)
- [ ] WPA2-Enterprise/802.1X (10 points)

#### 3. Advanced Security Features
- [ ] Protected Management Frames (PMF/802.11w) enabled (+2 points)
- [ ] WPS disabled (+1 point)
- [ ] 5GHz band available (+1 point)
- [ ] 802.11w mandatory (+1 point)
- [ ] Strong SSID (not default) (+1 point)

#### 4. Network Configuration
- [ ] Guest network isolation configured (+1 point)
- [ ] Hidden SSID (debatable, +0.5 points)
- [ ] MAC filtering enabled (+0.5 points, false security)
- [ ] Firewall present and configured (+2 points)

#### 5. Password Strength Analysis

Use these criteria to evaluate password strength:

```python
# Password Entropy Calculation
import math

def calculate_entropy(password):
    charset_size = 0
    if any(c.islower() for c in password): charset_size += 26
    if any(c.isupper() for c in password): charset_size += 26
    if any(c.isdigit() for c in password): charset_size += 10
    if any(not c.isalnum() for c in password): charset_size += 33

    entropy = len(password) * math.log2(charset_size)
    return entropy

# Example
password = "1l0k0$n0rt32023!"
entropy = calculate_entropy(password)
print(f"Password entropy: {entropy:.1f} bits")
# Output: ~80-90 bits (strong)
```

**Password Strength Guidelines:**
- **< 40 bits**: Weak (crackable in hours/days)
- **40-60 bits**: Moderate (crackable in months)
- **60-80 bits**: Good (crackable in years)
- **80-100 bits**: Strong (crackable in centuries)
- **> 100 bits**: Very Strong (practically uncrackable)

#### 6. Vulnerability Assessment

Common WiFi vulnerabilities to check:

```bash
# Check for WPS vulnerability
# WPS PIN can be brute-forced with tools like reaver
sudo wash -i wlan0mon

# Check for outdated firmware (requires router access)
# Look for:
# - KRACK vulnerability (CVE-2017-13077)
# - FragAttacks (CVE-2020-24586 series)
# - WPA3 Dragonblood (CVE-2019-13377)
```

### Sample Security Score Calculation

**Example Network: Birokadyan**

| Category | Score | Max | Details |
|----------|-------|-----|---------|
| Encryption | 7 | 10 | WPA2-CCMP (no WPA3) |
| Authentication | 7 | 10 | Strong PSK password |
| Advanced Features | 1 | 5 | WPS disabled, no PMF |
| Network Config | 2 | 4 | pfSense firewall present |
| **Total** | **17** | **29** | **58.6%** |
| **Adjusted Score** | **7.5** | **10** | **Good** |

**Risk Classification:**
- **9-10**: Excellent (minimal risk)
- **7-8.9**: Good (low risk)
- **5-6.9**: Fair (moderate risk)
- **3-4.9**: Poor (high risk)
- **0-2.9**: Critical (severe risk)

---

## Phase 5: Reporting and Recommendations

### Security Report Template

```markdown
# WiFi Security Assessment Report

**Network Name:** [SSID]
**Assessment Date:** [Date]
**Assessor:** [Your Name]

## Executive Summary

[Brief overview of security posture]

## Network Information

- **SSID:** [Network Name]
- **BSSID:** [MAC Address]
- **Channel:** [Channel Number]
- **Frequency:** [2.4 GHz / 5 GHz]
- **Encryption:** [WPA2/WPA3]
- **Cipher:** [CCMP/TKIP]
- **Authentication:** [PSK/SAE/Enterprise]
- **Router/Gateway:** [Make/Model]
- **Active Hosts:** [Number]

## Security Strengths

- [List positive security findings]

## Security Weaknesses

### Critical
- [Critical vulnerabilities requiring immediate attention]

### High
- [High-priority security issues]

### Medium
- [Moderate security concerns]

### Low
- [Minor security observations]

## Security Score

**Overall Score:** X.X / 10

[Scoring breakdown]

## Recommendations

### Immediate Actions (Critical)
1. [Action item 1]
2. [Action item 2]

### Short-term (High Priority)
1. [Action item 1]
2. [Action item 2]

### Long-term (Medium Priority)
1. [Action item 1]
2. [Action item 2]

## Conclusion

[Summary and final recommendations]
```

---

## Common WiFi Security Issues

### Issue 1: WPA2 KRACK Vulnerability

**Description:** Key Reinstallation Attacks allow attackers to intercept and decrypt WPA2 traffic.

**Detection:**
```bash
# Check router firmware date
# If < October 2017, likely vulnerable
```

**Mitigation:**
- Update router firmware
- Enable WPA3 if available
- Use VPN for sensitive traffic

### Issue 2: WPS PIN Brute Force

**Description:** WPS PIN authentication can be brute-forced in 4-10 hours.

**Detection:**
```bash
sudo wash -i wlan0mon
# Check if WPS is enabled
```

**Mitigation:**
- Disable WPS in router settings
- Use WPA2/WPA3-PSK only

### Issue 3: Weak Passwords

**Description:** Short or dictionary-based passwords are vulnerable to brute force attacks.

**Detection:**
Test password strength manually or use password auditing tools.

**Mitigation:**
- Use passwords with 15+ characters
- Mix uppercase, lowercase, numbers, symbols
- Avoid dictionary words
- Consider passphrases: "correct-horse-battery-staple"

### Issue 4: No WPA3 Support

**Description:** WPA2 is vulnerable to offline dictionary attacks via handshake capture.

**Detection:**
```bash
sudo iw dev wlan0 scan | grep -A 10 "SSID: YourNetwork" | grep SAE
# If no SAE, WPA3 is not supported
```

**Mitigation:**
- Upgrade router/AP firmware
- Purchase WPA3-capable hardware
- Ensure clients support WPA3

### Issue 5: Unidentified/Rogue Devices

**Description:** Unknown devices on network may indicate unauthorized access.

**Detection:**
```bash
sudo nmap -sn 192.168.1.0/24 | grep "Unknown"
```

**Mitigation:**
- Identify all legitimate devices
- Investigate unknown MAC addresses
- Implement network access control (NAC)
- Consider MAC filtering (limited effectiveness)

---

## Best Practices and Recommendations

### 1. Encryption and Authentication

**Recommended Configuration:**
```
Encryption: WPA3-Personal (SAE)
Fallback: WPA2-Personal (CCMP/AES)
Password: 16+ characters, mixed case, numbers, symbols
```

**Commands to check current settings:**
```bash
nmcli connection show "NetworkName" | grep -E "802-11-wireless-security"
sudo iw dev wlan0 scan | grep -A 15 "SSID: NetworkName"
```

### 2. Router/AP Hardening

- [ ] Change default admin password
- [ ] Update firmware regularly
- [ ] Disable WPS
- [ ] Enable WPA3 + PMF
- [ ] Use strong WiFi password
- [ ] Change default SSID
- [ ] Disable remote administration
- [ ] Enable firewall
- [ ] Disable UPnP if not needed
- [ ] Review guest network isolation

### 3. Network Segmentation

**Create separate networks for:**
- Main user devices (laptops, phones)
- IoT devices (smart home, cameras)
- Guest access (visitors)

**Implementation:**
```bash
# Use VLANs for isolation
# Main network: 192.168.1.0/24 (VLAN 10)
# IoT network: 192.168.2.0/24 (VLAN 20)
# Guest network: 192.168.3.0/24 (VLAN 30)
```

### 4. Monitoring and Auditing

**Regular Security Checks:**
```bash
# Monthly: Review connected devices
nmcli device wifi list
sudo nmap -sn 192.168.1.0/24

# Quarterly: Full security assessment
sudo airodump-ng wlan0mon --band abg

# Annually: Password rotation
# Update WiFi password

# Monitor for rogue APs with same SSID
sudo airodump-ng wlan0mon --band abg | grep "YourSSID"
```

### 5. Defense Against Common Attacks

**Evil Twin/Rogue AP Detection:**
```bash
# Look for duplicate SSIDs with different BSSIDs
sudo airodump-ng wlan0mon | grep -A 2 "YourSSID"
```

**Deauthentication Attack Mitigation:**
- Enable PMF (802.11w) - prevents deauth attacks
- Monitor for excessive deauth frames

**KRACK Attack Mitigation:**
- Update all devices to patched versions
- Enable WPA3 if possible

### 6. Password Management

**Generate Strong WiFi Passwords:**
```bash
# Generate 20-character random password
openssl rand -base64 20

# Generate memorable passphrase
shuf -n 5 /usr/share/dict/words | tr '\n' '-' | sed 's/-$//'
```

**Password Storage:**
- Use password manager (KeePassXC, Bitwarden)
- Never share via unsecured channels
- Rotate annually or after suspected compromise

### 7. Additional Tools for Advanced Assessment

**WiFi Security Scanning:**
```bash
# Kismet - WiFi detection and IDS
kismet

# Wireshark - Packet analysis
wireshark -i wlan0mon

# Bettercap - Network attack framework
sudo bettercap -iface wlan0

# Hcxdumptool - Capture WPA handshakes
sudo hcxdumptool -i wlan0mon -o capture.pcapng
```

**Password Cracking (for authorized testing only):**
```bash
# Hashcat - GPU-accelerated password cracking
hashcat -m 22000 capture.hc22000 wordlist.txt

# Aircrack-ng - CPU-based cracking
aircrack-ng -w wordlist.txt -b [BSSID] capture.cap
```

---

## Legal and Ethical Considerations

### Authorization Requirements

**You MUST have explicit written authorization before:**
- Scanning WiFi networks you don't own
- Capturing network traffic
- Testing for vulnerabilities
- Attempting to crack passwords

**Unauthorized activities may violate:**
- Computer Fraud and Abuse Act (CFAA) - USA
- Computer Misuse Act - UK
- Similar laws in other jurisdictions

### Responsible Disclosure

If you discover vulnerabilities:
1. Document findings professionally
2. Notify network owner immediately
3. Provide reasonable time for remediation
4. Do not publicly disclose until patched

### Professional Ethics

- Only test networks you own or are authorized to test
- Protect confidential information discovered
- Provide actionable recommendations
- Avoid causing service disruption
- Maintain professional liability insurance

---

## Conclusion

WiFi security assessment is an essential part of maintaining a secure network environment. By following this methodology, you can:

1. Identify encryption weaknesses
2. Discover unauthorized devices
3. Assess password strength
4. Detect common vulnerabilities
5. Implement security improvements

**Key Takeaways:**
- WPA3 is the current security standard
- Strong passwords are critical (16+ characters)
- Regular audits help maintain security posture
- Defense-in-depth: combine multiple security measures
- Always stay updated on emerging threats

### Next Steps

After completing your assessment:
1. Document all findings
2. Prioritize remediation efforts
3. Implement recommendations
4. Schedule regular follow-up assessments
5. Stay informed about new vulnerabilities

---

## References and Resources

**Official Documentation:**
- [WiFi Alliance - WPA3 Specification](https://www.wi-fi.org/discover-wi-fi/security)
- [NIST SP 800-153: Guidelines for Securing Wireless Local Area Networks](https://csrc.nist.gov/publications/detail/sp/800-153/final)
- [RFC 4186: Extensible Authentication Protocol (EAP)](https://tools.ietf.org/html/rfc4186)

**Security Research:**
- [KRACK Attack Details](https://www.krackattacks.com/)
- [Dragonblood: WPA3 Vulnerabilities](https://wpa3.mathyvanhoef.com/)
- [FragAttacks](https://www.fragattacks.com/)

**Tools Documentation:**
- [Aircrack-ng Documentation](https://www.aircrack-ng.org/documentation.html)
- [Nmap Documentation](https://nmap.org/docs.html)
- [iw/wireless-tools Documentation](https://wireless.wiki.kernel.org/en/users/documentation/iw)

---

**Document Version:** 1.0
**Last Updated:** January 4, 2026
**Author:** Network Security Assessment Team
**License:** MIT License - Free to use with attribution

---

## Appendix: Quick Reference Commands

```bash
# Interface Management
sudo ip link set wlan0 up
sudo ip link set wlan0 down
rfkill list
rfkill unblock wifi

# Network Connection
nmcli device wifi list
nmcli device wifi connect "SSID" password "PASSWORD"
nmcli connection show --active
nmcli device disconnect wlan0
nmcli device connect wlan0

# Scanning
sudo iw dev wlan0 scan
sudo nmap -sn 192.168.1.0/24
nmcli device wifi rescan

# Monitor Mode
sudo airmon-ng check kill
sudo airmon-ng start wlan0
sudo airmon-ng stop wlan0mon
sudo systemctl restart NetworkManager

# Traffic Capture
sudo airodump-ng wlan0mon --band abg
sudo airodump-ng wlan0mon --channel 6 -w output

# Network Information
ip addr show wlan0
ip route
ping -c 3 8.8.8.8
```

---

**Happy (Authorized) Hacking!**
