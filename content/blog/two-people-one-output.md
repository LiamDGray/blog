+++
title = "Two people, one output"
date = 2026-11-14T09:40:00Z
tags = ["editing", "evidence", "llm"]
+++

I built a small tool that reads a public profile — Hacker News, GitHub, that kind of thing — and summarises what the person is actually interested in. The idea was to answer a question I could not answer about myself: what is the through-line across the things I read and post?

I ran it on two people with almost nothing in common.

One writes about system administration, open-source infrastructure, and why most software is too complicated. The other writes about cryptography, security vulnerabilities, and the politics of internet standards. Different domains, different vocabulary, different instincts.

The tool returned the same output for both. Not similar. Identical.

## Why it failed

The first version extracted keywords from whatever the person had posted, counted them, and asked a language model to summarise the result. Keywords are not evidence. They are a bag of words with the structure thrown away.

So "security" and "cloud" and "go" floated to the top for both people — because those words are common in technical writing, not because they meant the same thing in each case. The summary was fluent, confident, and about nobody.

The failure was not in the model. The model wrote a good paragraph. The failure was that nothing in the paragraph was required to point at anything.

## The fix is the same as the fix for documents

Once the summary was required to attach evidence to every claim — this thread, that comment, these three posts — the two profiles separated immediately. The output got shorter and less elegant. It also became true.

That is the same trade I make when I edit a technical document. A claim that cannot point at its source is not a claim. It is a guess with good grammar.

The parallel is exact:

- A summary that cannot cite its sources will describe everyone the same way.
- A reference that is not checked against the implementation will describe an API that does not exist.
- A report that does not trace its numbers will agree with whatever you already believed.

In each case the document reads well, and the reading is the problem.

## What good output costs

Evidence-grounding has a visible cost. The prose gets more specific and less smooth. There are citations where a sentence would have flowed better, and questions where an answer would have been more satisfying.

I think that trade is almost always worth making, and I think most people make it in the wrong direction. The pleasure of a finished-sounding paragraph is immediate and private. The cost of a confident wrong sentence is delayed and public.

## The test I use

For any sentence in a technical document, I ask: *if this were challenged, what would I point at?*

If the answer is a file, a line, a source, or a named person who owns the number — the sentence stays.

If the answer is "it sounded right" — it becomes a question, addressed to whoever can answer it.

That is the whole method. It does not require better vocabulary. It requires being willing to leave a bracket in the document and let someone else fill it.
