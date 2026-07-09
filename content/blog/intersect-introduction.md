+++
title = "Introducing Intersect: an Interest Intersection Engine for Research Discovery"
date = 2026-07-09T22:00:00Z
tags = ["intersect", "research", "tools", "discovery"]
draft = false
+++

Every day, interesting research appears on arXiv. Every day, someone posts a fascinating paper on Hacker News, Lobste.rs, or GitHub. The problem isn't scarcity — it's signal-to-noise. The papers that would genuinely excite you are out there, but they're buried in a firehose of incremental work.

I built **Intersect** to solve this for myself, and I'm making it available as a free tool for the HN community.

## How it works

Intersect takes a social profile URL (HN, Lobste.rs, GitHub, GitLab, Codeberg, or SourceForge) and does three things:

1. **Collects** your public posts, comments, and repos from that platform
2. **Analyzes** the collection using an LLM to produce a structured "interest intersection" — a summary of the converging threads that define your research taste
3. **Cross-references** those interests against recent papers on arXiv, trending code on GitHub, and models on HuggingFace

What comes back is a personal research radar: a page showing what you actually care about, and what's new in those spaces.

## Why "intersection"?

When I ran this on my own HN submissions, the result was striking. I had submitted papers on associative memory, symbolic regression, algorithm unrolling, holographic representations, and energy-based models — seemingly separate topics, but with a clear intersection:

> **Putting algorithmic structure into neural networks** — bridging classical computation (iterative optimization, symbolic reasoning, associative memory) with deep learning, motivated by biological cognition and interpretability.

I hadn't articulated that to myself before. The tool saw the pattern in my submissions that I'd been living but not naming.

## Free for the HN community

Intersect is available now at **[intersect.liamdgray.com](https://demo.liamdgray.com/intersect/)**. Try it with your own HN username (or anyone else's).

Currently supported platforms:
- **Hacker News** — via the Algolia API (your submissions and comments)
- **Lobste.rs** — via the JSON API
- **GitHub** — via the REST API (your repos and READMEs)
- **GitLab** — via the API
- **Codeberg** — via the Gitea API
- **SourceForge** — via scraping

Each platform produces a slightly different analysis (HN surfaces the papers you share, GitHub surfaces the projects you build), but the intersection engine is the same.

## What's next

The engine is brand new. I'd love to know: does it find your interests accurately? What platforms would you add? What papers did it miss?

Try it: **[intersect.liamdgray.com](https://demo.liamdgray.com/intersect/)** — submit your profile and see your intersection.

---

*This post was written by an [AI agent](https://github.com/LiamDGray) and edited by a human.*
