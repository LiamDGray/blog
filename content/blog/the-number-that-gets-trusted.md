+++
title = "The number that gets trusted"
date = 2026-11-14T09:20:00Z
tags = ["editing", "documentation", "risk"]
+++

There is a sentence I have now removed from three different drafts, in three different organisations. It goes like this:

> Rate limits are enforced, and users who exceed them may experience errors.

It is not false. It is not even badly written. It is useless, and worse than useless, because it occupies the place where a fact should be.

## Two ways to be wrong

Documentation fails in two directions, and they are not equally expensive.

**A gap** — the document does not say what the limit is. The reader notices, asks, or tests. The cost is a support ticket and an afternoon.

**A plausible wrong number** — the document says sixty requests per minute and the gateway allows thirty. The reader does not test, because the document answered the question. The failure arrives in production, at the worst volume, and the document is the reason nobody looked.

The gap gets fixed. The number gets trusted. That asymmetry should govern how you edit technical documents.

## Why editors fill the gap

The pressure to invent is real and it is structural. A paragraph with a specific number reads better than a paragraph with a bracket in it. It looks finished. Reviewers approve it because it looks finished too.

And if you are editing with a language model in the loop — which I am, for first passes — the pressure gets worse. A model asked to improve that sentence will supply a number with total confidence. It is very good at producing the sentence that should have been a question.

The number it invents will be plausible. Plausible is the problem.

## What to do instead

Write the question into the document, in the place the number belongs, in a form the author cannot miss:

> Requests are rate-limited. `[QUERY: the draft says users "may experience errors" but gives no limit and no status code. What is the limit, and what does the API return when it is exceeded?]`

This feels unfinished. That is correct — it *is* unfinished, and the unfinished state is the true state. Shipping a sentence that pretends otherwise is not finishing the document, it is hiding the hole.

Then put the query in the change log, so the person who can answer it knows it is waiting on them.

## The general rule

Any claim in a technical document should be traceable to a source: the code, the schema, the paper, the person who owns the number. If it is not traceable, it is not a claim, it is a guess wearing a claim's clothes.

That rule is the whole discipline. Everything else — the style guide, the terminology list, the preferred tense — is downstream of it.

I put it on the front of what I do because it is the hardest part to fake. Reading for clarity is a skill. Refusing to invent a number when a number would read better is a decision, and it is the one that protects the reader.
