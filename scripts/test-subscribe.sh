#!/usr/bin/env bash
# scripts/test-subscribe.sh — Local test for the Brevo subscription flow
# Tests: (1) contact creation, (2) welcome email send
#
# Usage:
#   export BREVO_API_KEY="xkeysib-..."
#   bash scripts/test-subscribe.sh subscriber@example.com
#
# Or with sops:
#   bash scripts/test-subscribe.sh subscriber@example.com
#
# Options:
#   --double-optin   Use double opt-in (send confirmation, mark as pending)

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────
FROM_EMAIL="liam@liamdgray.com"
FROM_NAME="Liam D Gray"
BREVO_API_BASE="https://api.brevo.com/v3"
ORIGIN="${ORIGIN:-https://blog.liamdgray.com}"

# ── Colors ───────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ── Helpers ──────────────────────────────────────────────────────────
info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail()  { echo -e "${RED}[FAIL]${NC}  $*"; exit 1; }

usage() {
  echo "Usage: BREVO_API_KEY=... bash $0 [--double-optin] <email>"
  exit 1
}

# ── Parse args ───────────────────────────────────────────────────────
DOUBLE_OPTIN=false
EMAIL=""

for arg in "$@"; do
  case "$arg" in
    --double-optin) DOUBLE_OPTIN=true ;;
    --help|-h) usage ;;
    *)
      if [ -n "$EMAIL" ]; then
        echo "Error: unexpected argument '$arg'"
        usage
      fi
      EMAIL="$arg"
      ;;
  esac
done

if [ -z "$EMAIL" ]; then
  usage
fi

# ── Get API key ──────────────────────────────────────────────────────
API_KEY="${BREVO_API_KEY:-}"

if [ -z "$API_KEY" ]; then
  # Try sops
  if command -v sops &>/dev/null && [ -f "$HOME/secrets.enc.env" ]; then
    info "Reading BREVO_API_KEY from sops..."
    API_KEY=$(sops -d "$HOME/secrets.enc.env" 2>/dev/null | grep '^BREVO_API_KEY=' | cut -d= -f2 || true)
  fi
fi

if [ -z "$API_KEY" ]; then
  fail "BREVO_API_KEY not set. Export it or ensure ~/secrets.enc.env is present and decryptable."
fi

# Basic validation
if [[ ! "$API_KEY" =~ ^xkeysib- ]]; then
  warn "API key doesn't start with 'xkeysib-' — might be wrong or from old Brevo account"
fi

info "Testing subscription for: $EMAIL"
info "Double opt-in: $DOUBLE_OPTIN"
echo ""

# ── Step 1: Create/Update Contact ────────────────────────────────────
echo "─────────────────────────────────────────────"
echo -e "${CYAN}Step 1: Create/Update contact in Brevo${NC}"
echo "─────────────────────────────────────────────"

CONTACT_BODY=$(cat <<JSON
{
  "email": "$EMAIL",
  "listIds": [2],
  "updateEnabled": true,
  "emailBlacklisted": $DOUBLE_OPTIN
}
JSON
)

CONTACT_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "${BREVO_API_BASE}/contacts" \
  -H "api-key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "$CONTACT_BODY")

CONTACT_HTTP_CODE=$(echo "$CONTACT_RESPONSE" | tail -1)
CONTACT_BODY=$(echo "$CONTACT_RESPONSE" | sed '$d')

echo "HTTP $CONTACT_HTTP_CODE"
echo "Response: $CONTACT_BODY" | head -c 500
echo ""

if [ "$CONTACT_HTTP_CODE" = "201" ]; then
  ok "Contact created"
elif [ "$CONTACT_HTTP_CODE" = "204" ]; then
  ok "Contact updated (already existed)"
elif [ "$CONTACT_HTTP_CODE" = "409" ]; then
  ok "Contact already exists (409 — handled by updateEnabled)"
else
  fail "Contact creation failed (HTTP $CONTACT_HTTP_CODE)"
fi

# ── Step 2: Send transactional email ────────────────────────────────
echo ""
echo "─────────────────────────────────────────────"
echo -e "${CYAN}Step 2: Send transactional email${NC}"
echo "─────────────────────────────────────────────"

SUBJECT="[TEST] Welcome to Liam D Gray's blog!"
HTML_CONTENT=$(cat <<HTML
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family: sans-serif; max-width: 600px; margin: 2em auto;">
  <h2>$([ "$DOUBLE_OPTIN" = true ] && echo "Confirm your subscription" || echo "Welcome to the blog!")</h2>
  <p>Hi $EMAIL,</p>
  <p>$([ "$DOUBLE_OPTIN" = true ] && \
    echo "Please confirm your email by clicking the link below. If you didn't sign up, ignore this." || \
    echo "You're now subscribed. You'll get updates when I publish new posts."
  )</p>
  <hr style="margin-top: 2em;">
  <p style="font-size: 0.85em; color: #666;">
    <a href="${ORIGIN}/unsubscribe?email=${EMAIL}" style="color: #666;">Unsubscribe</a>
  </p>
</body>
</html>
HTML
)

SMTP_BODY=$(cat <<JSON
{
  "sender": {
    "name": "${FROM_NAME}",
    "email": "${FROM_EMAIL}"
  },
  "to": [
    {
      "email": "${EMAIL}"
    }
  ],
  "subject": "${SUBJECT}",
  "htmlContent": $(echo "$HTML_CONTENT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "tags": ["test", "subscription", "$([ "$DOUBLE_OPTIN" = true ] && echo "confirmation" || echo "welcome")"]
}
JSON
)

SMTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "${BREVO_API_BASE}/smtp/email" \
  -H "api-key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "$SMTP_BODY")

SMTP_HTTP_CODE=$(echo "$SMTP_RESPONSE" | tail -1)
SMTP_BODY=$(echo "$SMTP_RESPONSE" | sed '$d')

echo "HTTP $SMTP_HTTP_CODE"
echo "Response: $SMTP_BODY" | head -c 500
echo ""

if [ "$SMTP_HTTP_CODE" = "201" ]; then
  MESSAGE_ID=$(echo "$SMTP_BODY" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("messageId","unknown"))' 2>/dev/null || echo "unknown")
  ok "Transactional email sent! MessageId: ${MESSAGE_ID}"
else
  fail "Email sending failed (HTTP $SMTP_HTTP_CODE): $SMTP_BODY"
fi

echo ""
echo "─────────────────────────────────────────────"
echo -e "${GREEN}✅  Test complete!${NC}"
echo "─────────────────────────────────────────────"
echo "If you received the email at $EMAIL, the integration works."
echo "To deploy: npx wrangler pages deploy public --project-name blog"
