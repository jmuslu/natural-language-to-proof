# The temporal layer: valid-time, as-of correctness, and no lookahead

Status: **design thread** (`[structural]` unless a claim is tagged otherwise). Opened
when the corpus grew a use case that makes time load-bearing: coinciding external
event timelines (clinical-trial readouts, drug approvals, journal publications, SEC
filings) with market movements, and propagating the result through the epistemic
graph, the brain, and the oracle. The moment facts carry dates and we ask "did X
precede Y," the system inherits the single hardest discipline in empirical finance —
**no lookahead** — and it must be enforced structurally, not trusted to a model.

This document reasons about the architecture before building it, per the request. It
is written in the same discipline as the rest of the system: time is *external,
attested metadata*, never something a component infers about itself.

## 1. Why time is not one number

A fact has several distinct times, and conflating any two of them is a bug that
usually manifests as spurious predictive power (i.e. cheating). The model is
**bitemporal, plus two derived stamps**:

| Stamp | Meaning | Load-bearing for |
|---|---|---|
| **event_time** (valid time) | when the thing the claim is *about* actually held (trial completed 2023-06-01; earnings occurred in Q2) | causal ordering, event studies |
| **knowable_time** (disclosure time) | the earliest a party could have *acted* on it — journal publication, results posted to ClinicalTrials.gov, 8-K filing, conference presentation | **no-lookahead** — the one that prevents cheating |
| **ingestion_time** (transaction time) | when *our* system recorded it | auditing, reproducing "what we believed then" after later revision |
| **decision_time** (as-of) | the moment a hypothesis/strategy is evaluated | the query-time filter |

The rule that falls out, and that everything else serves:

> **A fact may inform a decision at time `T` only if `knowable_time ≤ T`.**

Note it is `knowable_time`, not `event_time`. A Phase 3 trial that *completed* in June
but whose results were *posted* in October is not usable in July, even though the
event already "happened." The classic traps are all instances of using the wrong
stamp: using a paper's *study period* instead of its *publication date*; using an
earnings *period* instead of its *release*; using a restated figure at its original
date. Each leaks the future.

## 2. How LLMs handle this (they mostly don't)

Worth stating plainly, because the instinct is to let the model reason about time:

- An LLM has a single coarse **training cutoff** — a global knowable_time for
  everything it saw. It has **no per-fact valid-time**: it cannot tell you when a fact
  became true, or when it learned it.
- It **leaks future knowledge**. A model trained through 2025 already "knows" a 2024
  approval outcome, so asking it to "predict" a 2023 readout is hindsight, not
  prediction — the canonical LLM-backtesting contamination.
- It **conflates event with publication**: given "the trial showed benefit," it does
  not separate when the benefit occurred, when it was written up, and when it was
  indexed.
- Systems that get this right push time **outside** the model: timestamp every
  document, filter retrieval by an as-of date, and use temporal/bitemporal knowledge
  graphs with valid-time edges. The model is stateless about time; the scaffolding
  enforces it.

Conclusion, and it is the same conclusion this whole system already reached about
truth: **do not trust the model to track time.** Impose valid-time as external
provenance and enforce as-of filtering at retrieval, inference, and evaluation. The
temporal layer is the "external checks only" discipline applied to the time axis.

## 3. Architecture: time threaded through the existing pieces

Nothing here is a new subsystem; each piece is an existing one gaining a time stamp
and an as-of filter.

### 3.1 Provenance gains time (the corpus + graph)
Every claim/source/event node carries `{event_time, knowable_time, ingestion_time}`
(any may be an interval or carry an uncertainty flag; `knowable_time` is required for
anything used in a temporal test). Sources are external and attested: trial posting
dates, DOI publication dates, filing timestamps, price-bar timestamps — exactly what
the research/clinical-trial/article tools return. This extends `evidence_basis`:
a temporal claim is `public_reference` only if its dates are externally attested.

### 3.2 As-of retrieval and inference (the brain)
`retrieve` / `answer` / `infer_trust` gain an `as_of` parameter: facts with
`knowable_time > as_of` are invisible. The brain can then answer *"what did we know at
time T,"* which is the only honest basis for historical hypothesis testing. Default
`as_of = now`. This is a filter on the fact set before the existing vector search — a
small, local change with a large correctness payoff.

### 3.3 Walk-forward becomes literally temporal (calibration + oracle)
The brain's calibration currently uses a random train/test split. The temporal
version splits on `knowable_time` — train on the past, test on the future — which is a
strictly stronger, honest test of *predictive* (not merely interpolative) structure,
and it mirrors the oracle's existing walk-forward/OOS. Same for any event-study: the
model is fit only on data knowable before the window it is scored on.

### 3.4 Temporal consistency: a new kind of external check
A claim asserting a timeline ("approved in 2019," "readout preceded the selloff") is
checkable against an external event timeline (ClinicalTrials.gov dates, FDA calendars,
the price series itself). Verdict `temporally_consistent | inconsistent | unresolved`,
reference-backed, same provenance discipline as the existing consistency verdicts. A
claimed date that contradicts the attested date is `inconsistent`. This is the
temporal sibling of the reference verdicts already in `verdicts_agent_proposed.json`.

### 3.5 Event–market alignment (the new use case, done honestly)
To coincide a medical event with a price move:
1. Anchor on `knowable_time`, mapped forward to the next **tradeable** moment (a
   readout posted after the close acts at the next open; respect the trading calendar).
2. Measure the reaction in a forward window `[t, t+Δ]` — never a window that straddles
   `t` backward.
3. Test the effect against the oracle's existing nulls: **sign-flip** and especially
   the **random-timing** null (does the reaction beat the same window placed at random
   dates?), then **Benjamini–Hochberg FDR** across the many events tested, and the
   **regime/rotation null** so a few flattering windows cannot carry the result.

The event study is thus not a new statistical engine — it is the existing oracle suite
pointed at event-anchored windows, which is exactly why the temporal layer belongs to
this system rather than beside it.

### 3.6 The loop, temporally grounded
A hypothesis ("positive Phase 3 readouts precede abnormal returns") → an event set
with attested `knowable_time`s → aligned forward price windows → oracle validation
(nulls + FDR) → a certificate → reverse-propagation to the corpus claim, with the
as-of discipline preserved end to end. The brain's exploration can then propose the
next event class to test, and its calibration must be walk-forward in time.

## 4. Traps to keep measured, not assumed away

- **Lookahead via the wrong stamp** — the whole reason for §1; enforce `knowable_time`.
- **Selection / survivorship** — testing only trials that reported, or firms still
  trading, biases the event set. Record the universe as-of, including the ones that
  later disappeared.
- **Restatement / revision** — a result can be corrected later. Bitemporal storage
  (valid-time + transaction-time) lets us ask "what did we believe about event E as of
  T" even after a revision, instead of silently back-patching history.
- **Trading-calendar / timezone mapping** — `knowable_time → next tradeable time` is a
  real transform, not a rounding.
- **Embargo / leak** — the true knowable_time can precede formal publication
  (conference talk, rumor). Prefer the latest *defensible* knowable_time and flag the
  uncertainty rather than pretend precision.
- **Multiple-comparisons over event classes** — FDR across the classes tested, the
  same way run-level FDR already gates strategy batches.

## 5. What to build first (incremental, each externally checkable)

1. **Schema**: add `event_time` / `knowable_time` / `ingestion_time` to the claim
   schema (nullable; required for temporal claims), attested via `evidence_basis`.
2. **As-of filter** in the brain (one predicate before vector search) + an `as_of`
   flag on `answer`/`retrieve`; add a temporal-split option to `calibrate`.
3. **Temporal-consistency verdicts**: verify a handful of dated claims against attested
   external dates (the research tools), reference-backed, owner-confirmable.
4. **Event-study driver**: align an event set's `knowable_time`s to forward price
   windows and run the *existing* validation suite (nulls + FDR) — no new statistics.
5. Only then, the medical-timeline ↔ market use case end to end, with the as-of
   discipline and the traps above enforced and logged.

The through-line, unchanged: the system does not decide *when* something was true or
knowable any more than it decides *whether* it is true — both come from external,
attested sources, and every temporal claim is a proposal until an external timeline
confirms it.
