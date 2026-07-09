// Email Worker — forwards incoming email to liamdgray@gmail.com
// Routes: subscribe@liamdgray.com → forwarded to personal inbox
//
// Deploy: wrangler deploy
// Then set up routing rule in CF Dashboard: Email → Routing → Routes

export default {
  async email(message, env, ctx) {
    const from = message.from;
    const to = message.to;
    const subject = message.headers.get("subject") || "(no subject)";

    console.log(`Received email from ${from} to ${to}: ${subject}`);

    // Forward to personal inbox
    await message.forward("liamdgray@gmail.com");
  },
};
