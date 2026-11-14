+++
title = "What I check in an API reference"
date = 2026-11-13T17:00:00Z
tags = ["editing", "api", "documentation"]
+++

An API reference is not prose about an API. It is the contract the client is coded against. When it is wrong, the failure does not look like a documentation problem — it looks like an integration that worked on Friday and broke without anyone touching it.

So when I review a reference, I am not reading for style first. I am reading for whether the document and the code still agree on the same facts. Here is the list I work through, in roughly the order the failures cost money.

## 1. Do the endpoints exist, with the same paths and methods?

This sounds like it cannot fail. It fails constantly — a route renamed, a method widened from `POST` to `GET, POST`, a trailing slash introduced by a framework change. The document keeps the old shape because nobody re-read it after the refactor.

## 2. Do the parameters match — names, types, requiredness, defaults?

The expensive ones are the silent ones:

- A parameter that became required but is still documented as optional. The client omits it, and the error surfaces somewhere unhelpful.
- A default that changed. The document says `limit=100`; the code says `25`. Every integration is now surprised.
- A type that changed quietly. `grade_level` documented as an integer, sent as a string, accepted because someone added a coercion — and now the reference lies about the contract even though the code works.

## 3. Are the status codes the ones the handler actually returns?

This is the check I would keep if I could only keep one. Documented status codes drift because nobody exercises them:

- The happy path says `200` but returns `201`.
- The document promises `404` for a missing record; the handler returns an empty `200`.
- The document promises `429` for rate limiting; the limit is enforced by a gateway that returns `503`.
- Field validation returns `400` with an error shape the document never describes.

A client that codes to the documented status codes is coding to a fiction.

## 4. Does the error shape match?

Most references describe errors in one line: "Returns an error on failure." That is not a shape. If the document does not tell a client what a failure looks like, the client will `try`/`catch` around the wrong boundary and swallow the message.

## 5. Do the examples run?

Examples are the most-copied text in any reference, and the least-tested. I check that the URL is a real host, the payload has no missing required fields, and the response in the example is the shape the handler returns — not the shape it returned two versions ago.

## 6. Are authentication, scopes, and rate limits described as they are enforced?

Where the credential goes, whether it is a header or a query parameter, what happens when it is absent versus invalid — `401` and `403` are routinely used interchangeably in docs and not in code. Rate limits are frequently mentioned without a number, which is worse than not mentioning them, because it implies the reader should already know.

## 7. Is the vocabulary consistent with itself?

If the reference says "workspace" in one section and "project" in another, one of them is wrong, and the reader has to guess which. Terminology drift is the earliest visible symptom of a document that stopped being maintained.

## 8. Is anything deprecated actually marked, with a replacement?

A reference that keeps a dead endpoint without a deprecation notice turns a maintenance problem into a support problem.

---

## Why this order

Because the failures are ordered by cost. A clumsy sentence costs the reader a minute. A wrong status code costs a developer a day, and costs the team a support thread that ends with someone reading the source to find out what the document meant.

That is also why I do not start with style. Improving the sentences in a reference that contradicts the implementation produces a document that is easier to read and still wrong — which is worse, because it is now convincing. Clarity is the second pass. Truth is the first.

If you want a worked example of the first pass, there is one [here](https://liamdgray.com/editing-sample.html) — a getting-started section with a change log that shows each decision, including the place where the honest answer was a question rather than an invented number.
