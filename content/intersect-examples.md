+++
title = "Intersect: example output"
date = 2026-11-14T00:00:00Z
+++

[Intersect](/blog/intersect-introduction/) reads a **public** profile — Hacker News, Lobste.rs, GitHub, GitLab, Codeberg, or SourceForge — and returns two things: the intersection of the interests that profile reveals, and recent research in those areas.

Below is real output from two runs. Both are public Hacker News activity; nothing private is involved. If one of these is yours and you would rather not be the example, tell me and I will swap it out.

---

## Example: zdw on Hacker News

**The intersection**

> The user's primary focus is on the practicalities and underlying mechanisms of software and systems, with a strong emphasis on robust, efficient, and often open-source solutions. They frequently critique poor design and advocate for simpler, more reliable approaches in development, networking, and system administration.

**Threads it converged from**

| Thread | What it saw |
| --- | --- |
| Critique of complexity and poor design | Bad schemas, complex contracts, unnecessary system components |
| Advocacy for open and efficient systems | tinydns, OpenBSD, custom kernels, efficient data transfer |
| Deep dives into technical mechanisms | Raw photos, T2 effects, copy protection, kernel boot processes |

**Fields:** software engineering and system administration · networking · information security · hardware

**Papers returned:** *Network Hexagons Under Attack: Secure Crowdsourcing of Geo-Referenced Data* · *Evaluation of Enhanced Security Solutions in 802.11-Based Networks* · *Ontologies for Network Security and Future Challenges*

---

## Example: tptacek on Hacker News

**The intersection**

> Deeply engaged with cybersecurity, focusing on cryptographic integrity, system vulnerabilities, and privacy. Critically examines government influence on technology and open standards.

**Threads it converged from**

| Thread | What it saw |
| --- | --- |
| Security and geopolitics | Technical flaws and crypto backdoors tied to intelligence agencies and policy |
| Open standards and trust | Integrity of internet standards, certificate authorities, cryptographic implementations |
| Vulnerability analysis | Specific exploits, memory leaks, remote code execution |

**Fields:** information security · cryptography · internet governance

**Papers returned:** *Holes in the Geofence: Privacy Vulnerabilities in "Smart" DNS Services* · *Ethical AI for Young Digital Citizens: A Call to Action on Privacy Governance* · *On the Semantics of Differential Privacy: A Bayesian Formulation*

---

## Notes

- Both runs took under a minute, including the LLM analysis and the arXiv lookup.
- The summaries are produced by a language model; the paper search is a separate arXiv query built from the extracted keywords. Neither is infallible.
- Intersect is not publicly hosted. It runs locally, and the LLM calls go through a local router.

## Want yours run?

Send me a note at [liamdgray.com/contact](https://liamdgray.com/contact.html) with the profile URL and I will run it and send back the result.
