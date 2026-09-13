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
  record_schema.json          schema v2 (controlled vocabularies + field docs)
  records/record_00X.json     structured records (derived metadata + short claims)
  build_records.py            the reproducible transformation (source data -> records)
  verify_claims.py            agent-proposed, reference-backed per-claim verdicts
                              -> verdicts_agent_proposed.json
  add_evidence_basis.py       migration: tag each claim's evidence_basis (what would
                              VERIFY it) — public_reference / self_reported /
                              unquantifiable / not_applicable
  export_claims_index.py      -> claims_index.json (stable ids upstream stages cite)
  propose_claim_refs.py       deterministic retrieval: hypothesis -> candidate claim_refs
  confound_check.py           format/length confound-ablation (permutation test)
  epistemic_graph.py          the bidirectional trust graph (echo-chamber-guarded)
  build_graph.py              assemble the graph from records + verdicts -> graph.json
  ingest_outcomes.py          reverse-propagate real backtest outcomes into the graph
  reverse_propagation_demo.py worked Layer-7 example on the real corpus
  fit_graph.py                Layer-5: fit trust-update parameters vs held-out
                              external calibration (never internal coherence)
  brain_embed.py              pluggable, provenance-tagged embedder (model2vec /
                              deterministic hashing fallback)
  brain.py                    the fact brain: libSQL vector store + retrieval,
                              synthetic inference, calibration, directed exploration
  brain_build.py              (re)build brain.db + brain_manifest.json from the graph
  brain_query.py              CLI: retrieve / infer / neighbors / explore / bridges / answer
  brain_test.py               offline test suite for the brain (109 checks)
  brain_map.py                render brain.db as an interactive semantic-trust map
                              (brain_map.html; positions=meaning, colour=trust)
  pipeline.py                 end-to-end operational driver (ingest→graph→brain→
                              retrieve/explore→oracle), narrated
  brain_manifest.json         committed calibration record (embedder, dim, skill)
  requirements-brain.txt      brain deps (libsql-experimental, numpy, model2vec)
  README.md                   this file
~/corpus/raw/                 raw full transcripts/articles — OUTSIDE the repo
```

`brain.db` and `.venv/` are gitignored build artifacts — regenerable with
`brain_build.py`; `brain_manifest.json` is the committed, human-readable record.

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
- **`evidence_basis`** — what would *verify* a claim, kept **orthogonal to
  `claim_type`** (its form): `public_reference` (checkable against a citable source),
  `self_reported` (the source's own track record/bio/results — not externally
  verifiable however "factual" it looks), `unquantifiable` (no well-defined metric),
  or `not_applicable` (advice/process, judged on `risk_quality`). Only
  `public_reference` claims belong on the consistency-verify frontier — this is the
  data (not a text heuristic) the brain routes on so "what to check next" proposes
  the right *kind* of check.
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

## The fact brain (`brain.py`, `brain_build.py`, `brain_query.py`)

The graph says *how much to trust* each claim; the brain makes the claims
**retrievable and explorable by meaning**. Each claim becomes a fact node: its
text embedded to a unit vector (geometry) plus its trust copied **verbatim** from
the graph (`brain_build.py` joins `claims_index` key `001-1-a` ↔ graph node
`claim:001-1-a`). Stored in **libSQL** — the Rust fork of SQLite with native
vector search (`F32_BLOB`, `vector_distance_cos`, DiskANN `vector_top_k`) — so
nearest-neighbour retrieval runs as a first-class DB operation.

The discipline is kept sharp by one separation: **embeddings position facts, they
never create trust.** Trust originates only from external checks, via the graph;
the brain reads that field and never writes to it. So the brain can *propose* —
retrieval, inference, exploration — while external checks still *dispose*.

Four capabilities, and the honest limits the brain reports on itself:

- **Retrieval** (`retrieve`) — semantic k-NN over embeddings; `--trust-weighted`
  re-ranks so results are both on-topic *and* externally credible. This is real
  semantic recall (it pulls the ML-vs-efficiency debate together across claims),
  a genuine step up from token-overlap `propose_claim_refs`.
- **Synthetic inference** (`infer_trust`) — interpolates the trust field at a new
  point from its nearest facts. It is emitted as a `conjectured` value that
  **always carries the calibration caveat inline**, so a predicted trust never
  travels without the verdict on whether imputation is even licensed.
- **Calibration** (`calibrate`) — the external check *on the brain itself*.
  Leave-one-out prediction graded against the graph's real trust, versus a
  mean-trust null (the same "skill vs null" test the backtest oracle uses), at a
  pre-registered `k = round(√n)`. On the current corpus it returns **not
  licensed** (skill ≈ 0.02, pearson ≈ 0.10): trust is *not* semantically smooth,
  because it is earned per-claim by external check, and 57% of claims are still
  unchecked. The brain therefore **refuses to impute trust from topic** — the
  discipline working, not a bug. Restricted to the 23 *checked* claims a real
  weak signal appears (skill ≈ 0.15, pearson ≈ 0.24), and `learning_curve` shows
  interpolation skill rising monotonically (+0.04 → +0.16) as the checked set
  grows from 5 to 20 — direct, un-fabricated evidence that **accumulating
  external checks makes synthetic inference progressively licensed.**
- **Directed exploration** (`explore_frontier`, `bridge_hypotheses`) — active
  inference over the manifold: `--mode gaps` surfaces unchecked-but-central claims
  (the highest-leverage next external checks), `--mode contested` surfaces checked
  claims whose neighbours disagree, and `bridge_hypotheses` proposes syntheses
  between two trusted claims in *different* domains at mid semantic distance (e.g.
  mark-to-market loss ↔ tax realization). Every output is a **proposal for an
  external check, never a verdict.**
- **Query-driven synthesis** (`answer`) — the capstone that ties the three
  together. For a question it retrieves the relevant facts (above a relevance
  floor), splits them into supporting / cautioning / still-unchecked by their
  external trust, and reports a stance that is the similarity-weighted trust of the
  *checked* relevant facts **only** — a single fact or a relevant-but-unchecked
  majority yields `insufficiently_checked`, not false confidence. It cites every
  fact with its trust, states how well-checked this corner of the corpus is
  (`checked_fraction`, a query-local calibration), and proposes the one external
  check that would most resolve the question. On this 43%-checked corpus most
  questions honestly land at `insufficiently_checked`, which is what makes the
  proposed-next-check the real payoff. It never claims ground truth — only what the
  externally-checked corpus implies.

`brain_test.py` (102 checks, offline via the hashing embedder) is the external
check on the brain *code*: trust copied verbatim, retrieval/neighbour/bridge
contracts, the licensing gate, and build reproducibility. `pipeline.py` runs the
whole chain — Haskell CCGbank ingestion → graph → brain → retrieve/explore, with
the oracle loop-closure — as one narrated operational run.

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
