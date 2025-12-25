#!/bin/bash
# Verification script for n8n.netsectap-labs.com security fixes
# Run this after implementing all fixes

DOMAIN="n8n.netsectap-labs.com"
PASSED=0
FAILED=0

echo "============================================================"
echo "Security Fix Verification for $DOMAIN"
echo "============================================================"
echo ""

# Test 1: HSTS Header
echo "[Test 1] Checking HSTS header..."
HSTS=$(curl -sI https://$DOMAIN | grep -i "strict-transport-security")
if [[ ! -z "$HSTS" ]]; then
    echo "✅ PASS: HSTS header present"
    echo "   $HSTS"
    ((PASSED++))
else
    echo "❌ FAIL: HSTS header missing"
    ((FAILED++))
fi
echo ""

# Test 2: CSP Header
echo "[Test 2] Checking Content Security Policy..."
CSP=$(curl -sI https://$DOMAIN | grep -i "content-security-policy")
if [[ ! -z "$CSP" ]]; then
    echo "✅ PASS: CSP header present"
    echo "   ${CSP:0:80}..."
    ((PASSED++))
else
    echo "⚠️  WARNING: CSP header missing (may be in report-only mode)"
    CSP_REPORT=$(curl -sI https://$DOMAIN | grep -i "content-security-policy-report-only")
    if [[ ! -z "$CSP_REPORT" ]]; then
        echo "   Report-Only mode active (testing phase)"
        ((PASSED++))
    else
        echo "❌ FAIL: No CSP header found"
        ((FAILED++))
    fi
fi
echo ""

# Test 3: TLS 1.0 Disabled
echo "[Test 3] Verifying TLS 1.0 is disabled..."
TLS10_TEST=$(openssl s_client -connect $DOMAIN:443 -tls1 </dev/null 2>&1 | grep -E "handshake failure|alert|wrong version")
if [[ ! -z "$TLS10_TEST" ]]; then
    echo "✅ PASS: TLS 1.0 is disabled"
    ((PASSED++))
else
    echo "❌ FAIL: TLS 1.0 is still enabled"
    ((FAILED++))
fi
echo ""

# Test 4: TLS 1.1 Disabled
echo "[Test 4] Verifying TLS 1.1 is disabled..."
TLS11_TEST=$(openssl s_client -connect $DOMAIN:443 -tls1_1 </dev/null 2>&1 | grep -E "handshake failure|alert|wrong version")
if [[ ! -z "$TLS11_TEST" ]]; then
    echo "✅ PASS: TLS 1.1 is disabled"
    ((PASSED++))
else
    echo "❌ FAIL: TLS 1.1 is still enabled"
    ((FAILED++))
fi
echo ""

# Test 5: TLS 1.2 Enabled
echo "[Test 5] Verifying TLS 1.2 is enabled..."
TLS12_TEST=$(openssl s_client -connect $DOMAIN:443 -tls1_2 </dev/null 2>&1 | grep "Verify return code: 0")
if [[ ! -z "$TLS12_TEST" ]]; then
    echo "✅ PASS: TLS 1.2 is enabled and working"
    ((PASSED++))
else
    echo "❌ FAIL: TLS 1.2 connection failed"
    ((FAILED++))
fi
echo ""

# Test 6: CAA Records
echo "[Test 6] Checking DNS CAA records..."
CAA=$(dig netsectap-labs.com CAA +short)
if [[ ! -z "$CAA" ]]; then
    echo "✅ PASS: CAA records found"
    echo "$CAA" | while read line; do echo "   $line"; done
    ((PASSED++))
else
    echo "❌ FAIL: No CAA records found"
    ((FAILED++))
fi
echo ""

# Test 7: All Security Headers
echo "[Test 7] Checking all security headers..."
HEADERS=$(curl -sI https://$DOMAIN | grep -iE "x-frame-options|x-content-type-options|referrer-policy")
HEADER_COUNT=$(echo "$HEADERS" | wc -l)
if [[ $HEADER_COUNT -ge 3 ]]; then
    echo "✅ PASS: Multiple security headers present ($HEADER_COUNT)"
    ((PASSED++))
else
    echo "⚠️  WARNING: Some security headers may be missing"
    ((FAILED++))
fi
echo ""

# Summary
echo "============================================================"
echo "SUMMARY"
echo "============================================================"
echo "Tests Passed: $PASSED"
echo "Tests Failed: $FAILED"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo "🎉 ALL TESTS PASSED!"
    echo "Security score should now be ~92/100 (Grade A)"
    echo ""
    echo "Next steps:"
    echo "1. Verify n8n application still works correctly"
    echo "2. Check browser console for CSP violations"
    echo "3. Run online security scanners:"
    echo "   - https://securityheaders.com/?q=https://$DOMAIN"
    echo "   - https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN"
else
    echo "⚠️  Some tests failed. Please review and fix the issues above."
fi
echo ""
