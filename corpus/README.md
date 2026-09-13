# Curated corpus for the adversarial epistemic suite

The labeled corpus described in `../HANDOFF-corpus-adversarial.md`: a small,
deliberately-labeled set of sources (YouTube videos and written articles) split
into checkable-and-consistent vs. common-but-inconsistent, to test whether the
epistemic ingestion layer (main handoff Layers 6–8) can tell the two apart —
**before** it is pointed at anything larger or unsupervised.

## The one rule that shapes everything here

An agent may **structure** this corpus (normalise fields, decompose per-claim,
track confounds) — that is retrieval/formatting, the safe side of the
determinism boundary both handoffs draw. An agent must **never** decide whether a
claim is factually consistent. So in every record, each claim's
`checkable_reference` and `consistency_verdict` are **null**, and
`verification_status` is `not_performed`. Those get filled by the owner or an
external, checkable reference — not by an agent's read of whether something
"sounds right." Reputation/fluency is not verification; that is the whole point.

## Layout

```
corpus/
  record_schema.json     schema v2 (controlled vocabularies + field docs)
  records/record_00X.json structured records (in the repo — derived metadata + short claims)
  build_records.py       the reproducible transformation (source data -> records)
  README.md              this file
~/corpus/raw/            raw full transcripts/articles — OUTSIDE the repo
```

**Placement decision** (`[stipulated]`). Structured records live in the repo:
they are derived metadata and short claim statements, the actual deliverable.
Raw full transcripts/articles live **outside** the repo at `~/corpus/raw/`,
mirroring the `~/ccgbank/` pattern, because third-party transcripts/articles
carry ToS/copyright exposure the handoff explicitly flags. `corpus/raw/` is
gitignored as a safety net. (The `files.zip` at the repo root — the owner's
original collection bundle — still contains the raw transcripts; see the findings
log for the recommendation to untrack it to follow the same discipline.)

## Schema v2, and why it differs from the original

The original `record_schema.json` was a minimal stub the four collected records
had already outgrown *inconsistently*: only articles carried `media_type`, only
001 tracked a word count, 001/003/004 had `key_claims_surface` in three different
shapes, and 002 had no claim decomposition at all. v2 unifies video and article
and adds the fields the handoff calls for:

- **`format`** and **`length`** — the two confounds the handoff says to track as
  fields (not verdicts): so that if a future discrimination signal correlates
  with format or sheer length, it is visible and checkable rather than silently
  baked into the labels.
- **`owner_label = {class, confidence, is_adversarial_bucket, reasoning}`** — the
  confidence level is factored *out* of the label string (002 firm / 003
  uncertain / 004 tentative / 001 none), so "tentatively consistent" vs. a firm
  verdict is a structured field, not prose.
- **`risk_quality`** — an axis kept **separate from factual consistency**. Record
  003 forced this: the owner does not dispute the article's facts but judges the
  strategy poor risk-adjusted (leverage front-loading tail risk). That is a
  quality/risk judgment, not a factual-consistency one, and collapsing them would
  corrupt the very axis the adversarial suite is meant to test.
- **`claims[]`** — per-claim decomposition with attribution (`segment_id`), a
  `domain` (for the orthogonality / domain-scoping the handoff asks for), a
  `claim_type`, and the three null verification slots above.
- **`provenance`** — records `label_source: owner` vs `structure_source: agent`,
  making the determinism boundary auditable in the data itself.

## What the corpus is for (and what a good result is *not*)

The deliverable is a standalone verdict artifact + evidence that any
discrimination signal discriminates for the **right reason** (claims check out or
don't), not a spurious correlate (length, format, presenter confidence, writing
style). Per the handoff this is validated the way the Layer 3 statistical suite
was: synthetic/known ground truth first. It is explicitly **not** a graph
integration (that is Layer 5, a separate later job), and a good result here is "a
validated dataset worth handing to Layer 5 and worth growing," not "the epistemic
layer works now."

## Standing confound, visible already at n=4

With only four records, `format` and `length` are badly confounded with the
label: the two not-inconsistent items (003 ambiguous, 004 tentatively consistent)
are both **articles** and **short** (532, 453 words); the inconsistent item (002)
is a **video**; the unlabeled item (001) is a **22,394-word** video — 42× longer
than 004. Any discrimination signal built on this set today would key off
article-vs-video or short-vs-long, not epistemic content. This is not a defect in
any record; it is the mechanical reason the corpus must **grow and stay balanced
across classes on both format and length** before any discrimination result is
trustworthy rather than anecdotal. It is recorded here so the confound is
measured, not assumed away.
