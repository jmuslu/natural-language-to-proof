# Curated corpus for the adversarial epistemic suite

The labeled corpus described in `../HANDOFF-corpus-adversarial.md`: a small,
deliberately-labeled set of sources (YouTube videos and written articles) split
into checkable-and-consistent vs. common-but-inconsistent, to test whether the
epistemic ingestion layer (main handoff Layers 6–8) can tell the two apart —
**before** it is pointed at anything larger or unsupervised.

## The rule that shapes everything here (corrected)

The "an agent must never decide whether a claim is factually consistent"
constraint is scoped to the **live, autonomous** system — not to bootstrapping.
During development the agent should do the verification work, as a **proposer**
(the Layer 6 proposer/never-decider role): check each claim against an external,
checkable reference and *propose* a verdict, with the reference and reasoning
attached and `verdict_source = "agent_proposed"`, subject to owner/external
confirmation before the autonomous system trusts it. What stays forbidden is the
*bad* kind of deciding — substituting the agent's own read of whether something
"sounds right" for an actual external check. Reputation/fluency is not
verification; a cited external reference is.

Two layers, kept physically separate by provenance:

- **structure** (`records/`, owner-labeled + agent-structured): sources, claims,
  domains, confounds. Each claim's `consistency_verdict`/`checkable_reference` are
  null *here* — this layer asserts no verdicts.
- **agent-proposed verification** (`verdicts_agent_proposed.json`): reference-backed
  verdicts (`consistent`/`inconsistent`/`unresolved`), each with the reference and
  reasoning, marked `pending_owner_confirmation`. `unresolved` is used honestly and
  often (specific current statistics, self-reported track records, future events
  are not guessed).

An earlier version of this README said the agent "must never" fill verdicts and
left them all null; that over-read the live-system rule and is corrected here.

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

## The epistemic graph (`epistemic_graph.py`, `build_graph.py`, `graph.json`)

The corpus is not just a flat list of records — it is a **graph**, and
information propagates **both ways** along it. `build_graph.py` assembles it from
the records + agent-proposed verdicts:

- **Nodes:** `source`, `claim`, `domain`, `reference` (an external check),
  `owner_label` (the owner's per-source judgment), and — once real backtests
  exist — `outcome`.
- **Edges:** `source --asserts--> claim`, `claim --in_domain--> domain`
  (structural); `reference/owner_label --supports|contradicts--> claim/source`
  (external checks that originate trust); `claim --corroborates--> claim`
  (amplifier); and, for reverse propagation, `claim --feeds--> outcome` with
  `outcome --implicates--> claim` once the outcome is checked.

Two disciplines are built into the propagation (`epistemic_graph.propagate`),
both directly from the main handoff:

1. **Trust originates only from external checks** (Layer 8 Version A). References,
   owner labels and outcomes are the only trust *sources*; corroboration between
   claims can amplify externally-rooted trust but a mutually-corroborating cluster
   with **no** external check stays at zero. The echo chamber gets nothing. (On
   the current corpus, 30 of 48 claims have no external check yet and sit at
   trust 0 — correctly.)
2. **Information propagates both ways.** Forward: support/corroboration flow to
   claims and (descriptively) to sources. Backward: an oracle-checked `outcome`
   implicates the claims that fed it (`implicate_from_outcome`) — the same shape
   as `Genealogy.hs`'s retraction propagation, which is how a future Layer-5
   trust-update mechanism (kept open, not brute-forced here) plugs in.

Both `epistemic_graph.py` and `confound_check.py` validate themselves on
synthetic ground truth first (`python3 corpus/epistemic_graph.py`), the same
"prove the checker on known answers" discipline as the Layer 3 suite.

**Closing the loop (live, not a demo).** `export_claims_index.py` →
`claims_index.json` publishes the stable claim ids an upstream stage cites;
`strategy-core` records those on each backtest result as `attribution.claim_refs`;
and `ingest_outcomes.py RESULT.json` reads a real result (attribution + validation
certificate) and reverse-propagates the oracle-checked verdict to the cited
claims. Verified end-to-end with a real nautilus backtest. A useful behaviour
falls out: a failed backtest on a strategy that leaned on a *well-referenced*
claim only modestly dents it (direct references dominate the noisy indirect
signal), whereas the same failure drives an otherwise-*unresolved* claim negative
(the backtest is its only external check). The one remaining gap is upstream —
hypotheses don't yet populate `claim_refs`; until they do, real results carry
empty refs.

A concrete finding the graph already surfaces: a per-claim verdict can diverge
from the owner's global label. Source 002's individual claims (market efficiency,
null-baseline methodology, standard ML fixes) are individually consistent, yet
the owner's firm "inconsistent" label about the *strategy* pulls the source's
net trust negative. The graph shows the tension rather than falsely resolving it.

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

`confound_check.py` measures this continuously as the corpus grows: for each
confound feature it reports a permutation p-value for whether that feature alone
separates the adversarial buckets, and refuses a discrimination verdict until
there are enough labeled records per bucket. It is validated on synthetic ground
truth (`python3 corpus/confound_check.py --selftest`: it flags a corpus where
format perfectly predicts the label, clears a balanced one, and reports NOT READY
at tiny n) — the same "prove the checker on known answers first" discipline as the
Layer 3 statistical suite. On the current four records it correctly returns NOT
READY (1 pos / 1 neg once `ambiguous` and `unlabeled` are set aside).
