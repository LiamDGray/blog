# Handoff — blog

`blog.liamdgray.com`. Hugo, deployed to Cloudflare Pages project `blog`.

---

## What this is

The blog is the feed, not the portfolio. Long-form, permanent pieces live on
`liamdgray.com`; the blog carries dated posts, RSS, and the email subscribe form.

**Posts are in `content/blog/`.** `public/` is a build artifact — never edit it,
never commit it.

## Build and deploy

```bash
cd ~/src/apps/blog
git pull --ff-only          # mandatory, see below
~/.local/bin/hugo --gc
CLOUDFLARE_API_TOKEN=$(cat ~/.cf_token) npx wrangler pages deploy --project-name blog
```

`hugo` is at `~/.local/bin/hugo` (v0.170.0, installed 2026-11-15). `just build`
and `just deploy` do the same things if `hugo` is on `PATH`.

## The trap that caused an outage

On 2026-11-15 the site was redeployed from a checkout that was **eight commits
behind `origin/master`**, and because `public/` is a build artifact rather than
source, this republished an old tree: older stylesheet, three posts instead of
four. The site was restored by rolling back the Pages deployment.

**Before every build: `git pull --ff-only` and `git status`.** If the tree is
behind or dirty, stop.

Rollback (needs the **full** deployment UUID; a truncated id is rejected):

```
GET  /accounts/{account}/pages/projects/blog/deployments?per_page=5
POST /accounts/{account}/pages/projects/blog/deployments/{uuid}/rollback
```

## Conventions

- **Nav mirrors the main site**, minus Home (the logo is home), plus RSS:
  Editing · Work · Writing · About · Contact · RSS. All point at
  `https://liamdgray.com/<extensionless-path>`.
- **Styling** comes from `https://liamdgray.com/css/style.css`, with
  `themes/minimal/static/css/style.css` layered on top for blog-specific rules.
  The `?v=` query busts the cache when the local sheet changes.
- **Links inside posts** should use the extensionless form used by the main site.
- **Subscribe** posts to `/api/subscribe` (a Pages Function, Brevo).

## Related

`~/src/apps/liamdgray.com/HANDOFF-PART-7.md` covers the main site: its navigation,
invariants, deploy, and the traps in changing it.
