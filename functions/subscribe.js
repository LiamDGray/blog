// CF Pages Function: Email subscription
// Validates email and stores in D1 database.
// Expects D1 binding named "DB" configured in Cloudflare dashboard.

export async function onRequest(context) {
  const { request, env } = context;

  // Only accept POST
  if (request.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // Parse form data or JSON body
  let email;
  const contentType = request.headers.get("content-type") || "";

  if (contentType.includes("application/json")) {
    const body = await request.json();
    email = body?.email;
  } else {
    const formData = await request.formData();
    email = formData.get("email");
  }

  // Validate email
  if (!email || typeof email !== "string") {
    return new Response(JSON.stringify({ error: "Email is required" }), {
      status: 400,
      headers: { "content-type": "application/json" },
    });
  }

  const emailStr = email.trim().toLowerCase();
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (!emailRegex.test(emailStr)) {
    return new Response(JSON.stringify({ error: "Invalid email address" }), {
      status: 400,
      headers: { "content-type": "application/json" },
    });
  }

  // Store in D1
  if (!env || !env.DB) {
    console.warn("D1 binding 'DB' not configured — email not stored");
    return new Response(JSON.stringify({ message: "Subscribed (storage unavailable)", email: emailStr }), {
      status: 202,
      headers: { "content-type": "application/json" },
    });
  }

  try {
    const createdAt = new Date().toISOString();
    await env.DB.prepare(
      "INSERT INTO subscribers (email, created_at) VALUES (?1, ?2) ON CONFLICT(email) DO NOTHING"
    ).bind(emailStr, createdAt).run();

    return new Response(JSON.stringify({ message: "Successfully subscribed", email: emailStr }), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  } catch (err) {
    console.error("D1 insert failed:", err);
    return new Response(JSON.stringify({ error: "Failed to store subscription" }), {
      status: 500,
      headers: { "content-type": "application/json" },
    });
  }
}
