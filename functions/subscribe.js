// CF Pages Function: Email subscription via Brevo (Sendinblue) API v3
// Expects BREVO_API_KEY environment variable set in Cloudflare Pages dashboard.
// Also expects env.ORIGIN (e.g. "https://blog.liamdgray.com") for CORS.
//
// Flow:
//   1. Validates email
//   2. Creates/updates contact in Brevo (list ID 2 = default; configure as needed)
//   3. Sends a welcome transactional email from blog@liamdgray.com
//   4. Returns success or error response
//
// To use double opt-in, set DOUBLE_OPTIN=true in env; a confirmation link is
// embedded (the subscriber must click it before being marked active in Brevo).
// Single opt-in (default) creates the contact as active immediately.

const BREVO_API_BASE = "https://api.brevo.com/v3";
const FROM_EMAIL = "blog@liamdgray.com";
const FROM_NAME = "Liam D Gray";

// ── Validation ──────────────────────────────────────────────────────
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function validateEmail(email) {
  if (!email || typeof email !== "string") return "Email is required";
  const trimmed = email.trim().toLowerCase();
  if (!EMAIL_RE.test(trimmed)) return "Invalid email address";
  return null;
}

// ── Brevo helpers ───────────────────────────────────────────────────

async function createOrUpdateContact(apiKey, email, doubleOptin) {
  const body = {
    email,
    listIds: [2],        // Default Brevo list ID (adjust as needed)
    updateEnabled: true,  // Update if exists
  };
  if (doubleOptin) {
    // Double opt-in: mark as pending; Brevo sends confirmation
    body.emailBlacklisted = true; // Start as unconfirmed
  }

  const res = await fetch(`${BREVO_API_BASE}/contacts`, {
    method: "POST",
    headers: {
      "api-key": apiKey,
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify(body),
  });

  const data = await res.json().catch(() => null);

  if (!res.ok) {
    // 409 = already exists via updateEnabled, which is fine
    if (res.status === 409) return { ok: true, existed: true };
    const errMsg = data?.message || data?.code || `Brevo API error (${res.status})`;
    throw new Error(errMsg);
  }

  return { ok: true, id: data?.id, existed: false };
}

async function sendWelcomeEmail(apiKey, email, doubleOptin, origin) {
  const subject = doubleOptin
    ? "Please confirm your subscription"
    : "Welcome to Liam D Gray's blog!";

  const htmlContent = doubleOptin
    ? `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family: sans-serif; max-width: 600px; margin: 2em auto;">
  <h2>Confirm your subscription</h2>
  <p>Thanks for subscribing! Please confirm your email address by clicking the link below:</p>
  <p style="text-align: center; margin: 2em 0;">
    <a href="${origin}/confirm?email=${encodeURIComponent(email)}"
       style="display: inline-block; padding: 12px 24px; background: #2563eb; color: #fff; text-decoration: none; border-radius: 6px;">
      Confirm Subscription
    </a>
  </p>
  <p>If you didn't sign up, you can ignore this email.</p>
  <hr style="margin-top: 2em;">
  <p style="font-size: 0.85em; color: #666;">
    <a href="${origin}/unsubscribe?email=${encodeURIComponent(email)}"
       style="color: #666;">Unsubscribe</a>
  </p>
</body>
</html>`
    : `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family: sans-serif; max-width: 600px; margin: 2em auto;">
  <h2>Welcome to the blog!</h2>
  <p>Thanks for subscribing, ${email}.</p>
  <p>You'll now receive updates when I publish new posts.</p>
  <hr style="margin-top: 2em;">
  <p style="font-size: 0.85em; color: #666;">
    <a href="${origin}/unsubscribe?email=${encodeURIComponent(email)}"
       style="color: #666;">Unsubscribe</a>
  </p>
</body>
</html>`;

  const body = {
    sender: { name: FROM_NAME, email: FROM_EMAIL },
    to: [{ email }],
    subject,
    htmlContent,
    tags: ["subscription", doubleOptin ? "confirmation" : "welcome"],
  };

  const res = await fetch(`${BREVO_API_BASE}/smtp/email`, {
    method: "POST",
    headers: {
      "api-key": apiKey,
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify(body),
  });

  const data = await res.json().catch(() => null);

  if (!res.ok) {
    const errMsg =
      data?.message || data?.code || `Brevo SMTP error (${res.status})`;
    throw new Error(errMsg);
  }

  return data?.messageId || "sent";
}

// ── CORS headers ────────────────────────────────────────────────────

const corsHeaders = (origin) => ({
  "Access-Control-Allow-Origin": origin || "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Max-Age": "86400",
});

function corsResponse(body, status, origin) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders(origin),
      "content-type": "application/json",
    },
  });
}

// ── Handler ─────────────────────────────────────────────────────────

export async function onRequest(context) {
  const { request, env } = context;

  const origin = env.ORIGIN || "https://blog.liamdgray.com";
  const apiKey = env.BREVO_API_KEY;
  const doubleOptin = env.DOUBLE_OPTIN === "true";

  // CORS preflight
  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders(origin),
    });
  }

  // Only accept POST
  if (request.method !== "POST") {
    return corsResponse({ error: "Method not allowed" }, 405, origin);
  }

  // Check API key configured
  if (!apiKey) {
    console.error("BREVO_API_KEY not configured");
    return corsResponse(
      { error: "Server configuration error — contact the admin" },
      500,
      origin,
    );
  }

  // Parse email from request body
  let email;
  const contentType = request.headers.get("content-type") || "";

  try {
    if (contentType.includes("application/json")) {
      const body = await request.json();
      email = body?.email;
    } else {
      const formData = await request.formData();
      email = formData.get("email");
    }
  } catch (parseErr) {
    return corsResponse({ error: "Invalid request body" }, 400, origin);
  }

  // Validate email
  const validationError = validateEmail(email);
  if (validationError) {
    return corsResponse({ error: validationError }, 400, origin);
  }

  const emailStr = email.trim().toLowerCase();

  // ── Execute Brevo flow ────────────────────────────────────────────
  console.log(`Processing subscription for ${emailStr} (double-optin=${doubleOptin})`);

  try {
    // Step 1: Create/update contact
    const contactResult = await createOrUpdateContact(apiKey, emailStr, doubleOptin);
    console.log(`Contact ${contactResult.existed ? "updated" : "created"}: ${emailStr}`);

    // Step 2: Send welcome/confirmation email
    const messageId = await sendWelcomeEmail(apiKey, emailStr, doubleOptin, origin);
    console.log(`Email sent: ${messageId}`);

    return corsResponse(
      {
        message: doubleOptin
          ? "Check your inbox to confirm your subscription"
          : "Successfully subscribed — welcome email sent",
        email: emailStr,
      },
      200,
      origin,
    );
  } catch (err) {
    console.error("Brevo subscription failed:", err);

    // Distinguish between Brevo API errors and network errors
    const status = err.message?.includes("Brevo") ? 502 : 503;
    return corsResponse(
      { error: "Failed to complete subscription. Please try again later." },
      status,
      origin,
    );
  }
}
