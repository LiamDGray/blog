#!/usr/bin/env bash
# scripts/send-sub-confirmation.sh — Send a subscription confirmation/welcome email
# via Brevo API v3. Can be used standalone to re-send confirmations or test.
#
# Usage:
#   bash scripts/send-sub-confirmation.sh [--welcome|--confirm] [--from <email>] <recipient-email>
#
# Reads BREVO_API_KEY from env or ~/secrets.enc.env (via sops).

set -euo pipefail

FROM_EMAIL="blog@liamdgray.com"
FROM_NAME="Liam D Gray"
BREVO_API_BASE="https://api.brevo.com/v3"
ORIGIN="${ORIGIN:-https://blog.liamdgray.com}"
MODE="welcome"
EMAIL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --welcome) MODE="welcome"; shift ;;
    --confirm) MODE="confirm"; shift ;;
    --from) FROM_EMAIL="$2"; shift 2 ;;
    --help|-h) echo "Usage: $0 [--welcome|--confirm] [--from <email>] <email>"; exit 0 ;;
    *)
      if [[ -z "$EMAIL" ]]; then EMAIL="$1"; shift
      else echo "Unknown: $1"; exit 1
      fi
      ;;
  esac
done

if [[ -z "$EMAIL" ]]; then
  echo "Usage: $0 [--welcome|--confirm] <email>"
  exit 1
fi

# Get API key
API_KEY="${BREVO_API_KEY:-}"
if [[ -z "$API_KEY" ]] && command -v sops &>/dev/null && [[ -f "$HOME/secrets.enc.env" ]]; then
  API_KEY=$(sops -d "$HOME/secrets.enc.env" 2>/dev/null | grep '^BREVO_API_KEY=' | cut -d= -f2 || true)
fi
if [[ -z "$API_KEY" ]]; then
  echo "ERROR: BREVO_API_KEY not set and could not decrypt from sops"
  exit 1
fi

echo "── Sending $MODE email to $EMAIL from $FROM_EMAIL ──"

# Build subject and HTML
if [[ "$MODE" == "confirm" ]]; then
  SUBJECT="Please confirm your subscription"
  HTML=$(cat <<EOF
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family:sans-serif;max-width:600px;margin:2em auto;">
<h2>Confirm your subscription</h2>
<p>Thanks for subscribing! Please confirm your email address by clicking the link below:</p>
<p style="text-align:center;margin:2em 0;">
  <a href="${ORIGIN}/confirm?email=${EMAIL}"
     style="display:inline-block;padding:12px 24px;background:#2563eb;color:#fff;text-decoration:none;border-radius:6px;">
    Confirm Subscription
  </a>
</p>
<p>If you didn't sign up, you can ignore this email.</p>
<hr style="margin-top:2em;">
<p style="font-size:0.85em;color:#666;">
  <a href="${ORIGIN}/unsubscribe?email=${EMAIL}" style="color:#666;">Unsubscribe</a>
</p>
</body></html>
EOF
)
else
  SUBJECT="Welcome to Liam D Gray's blog!"
  HTML=$(cat <<EOF
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family:sans-serif;max-width:600px;margin:2em auto;">
<h2>Welcome to the blog!</h2>
<p>Thanks for subscribing, ${EMAIL}.</p>
<p>You'll now receive updates when I publish new posts.</p>
<hr style="margin-top:2em;">
<p style="font-size:0.85em;color:#666;">
  <a href="${ORIGIN}/unsubscribe?email=${EMAIL}" style="color:#666;">Unsubscribe</a>
</p>
</body></html>
EOF
)
fi

# Build JSON payload safely via Python (avoids shell quoting hell)
PAYLOAD=$(python3 -c "
import json, os
html = os.environ['EMAIL_HTML']
payload = {
    'sender': {'name': '${FROM_NAME}', 'email': '${FROM_EMAIL}'},
    'to': [{'email': '${EMAIL}'}],
    'subject': '${SUBJECT//\'/\\'}',
    'htmlContent': html,
    'tags': ['subscription', '${MODE}']
}
print(json.dumps(payload))
")

# Send via curl
RESP=$(curl -s -w "\n%{http_code}" \
  -X POST "${BREVO_API_BASE}/smtp/email" \
  -H "api-key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "$PAYLOAD")

HTTP_CODE=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | sed '$d')

if [[ "$HTTP_CODE" == "201" ]]; then
  MSG_ID=$(echo "$BODY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('messageId','?'))" 2>/dev/null)
  echo "✅ Email sent! MessageId: $MSG_ID"
else
  echo "❌ Failed (HTTP $HTTP_CODE):"
  echo "$BODY" | head -c 500
  exit 1
fi
