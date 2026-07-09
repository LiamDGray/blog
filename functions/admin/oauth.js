// Decap CMS OAuth proxy — single-user, PAT-based
// Serves as the OAuth endpoint that Decap CMS redirects to.
// Stores the GitHub PAT in an env var, not user-facing.
//
// Environment:
//   GITHUB_PAT — GitHub Personal Access Token with repo scope
//   GITHUB_REPO — repo name (e.g., "LiamDGray/blog")
//
// Decap CMS config should have:
//   backend:
//     name: github
//     repo: liamdgray/blog
//     branch: master
//     base_url: https://blog.liamdgray.com
//     auth_endpoint: /admin/oauth

export async function onRequest(context) {
  const { request, env } = context;
  const url = new URL(request.url);

  // CORS headers for Decap CMS client-side SPA
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };

  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  const pat = env.GITHUB_PAT;

  if (!pat) {
    return new Response(JSON.stringify({ error: 'GITHUB_PAT not configured' }), {
      status: 500,
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    });
  }

  // Decap CMS auth flow:
  // 1. SPA redirects user to /admin/oauth?provider=github
  // 2. We redirect to GitHub's OAuth authorize URL with our PAT
  // 3. GitHub returns a code
  // 4. We exchange the code for a token
  //
  // Simplified for PAT-based single-user:
  // We just return the PAT directly since it's a single-user setup

  if (request.method === 'GET') {
    const provider = url.searchParams.get('provider');

    if (provider === 'github') {
      // Redirect to GitHub to authorize
      // Actually, for PAT-based single-user, we skip the redirect
      // and return the token directly via the callback URL
      return Response.redirect(
        `${url.origin}/admin/oauth/callback?provider=github&code=pat`,
        302
      );
    }

    return new Response(JSON.stringify({ error: 'unknown provider' }), {
      status: 400,
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    });
  }

  if (request.method === 'POST') {
    // Handle the token exchange
    const body = await request.json();

    if (body.provider === 'github') {
      return new Response(JSON.stringify({
        token: pat,
        provider: 'github',
      }), {
        status: 200,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ error: 'unknown provider' }), {
      status: 400,
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    });
  }

  return new Response('Method not allowed', { status: 405, headers: corsHeaders });
}
