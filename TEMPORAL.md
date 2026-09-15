# The temporal discipline: valid-time, as-of correctness, no lookahead

A design note on the one temporal rule the system needs. It is **system-general** —
the "external checks only" discipline applied to the time axis. (The event-study use
case that first motivated it is an implemented but *accessory* consumer; its specifics
live in `agentic-qr:shared/backtesting/` and are not a priority here.)

## Time is not one number

A fact carries several times, and conflating any two is usually how lookahead (i.e.
cheating) creeps in:

- **event_time** (valid time) — when the thing the claim is *about* actually held.
- **knowable_time** (disclosure) — the earliest it could be *acted on* (publication,
  filing, readout posting). **The load-bearing stamp.** It can *precede* event_time
  (an interim result disclosed before the registry milestone) or follow it.
- **ingestion_time** (transaction) — when we recorded it.
- **as_of** — the decision moment a query is evaluated against.

The rule everything serves: **a fact may inform a decision at `T` only if
`knowable_time ≤ T`.** Not `event_time` — using when the thing *happened* instead of
when it became *knowable* is the classic leak (study period vs. publication date;
earnings period vs. release; a restated figure at its original date). At sub-day
granularity a `disclosure_timing` flag (pre-market / after-close) decides which
session first makes a fact actionable.

## Why the scaffolding must own time, not the model

An LLM has one coarse training cutoff, no per-fact valid-time, and *leaks* post-cutoff
outcomes as hindsight — so it cannot be trusted to reason about "what was knowable
when." The fix is the same move this system already makes for truth: push time outside
the model, as external, attested provenance plus an as-of filter. Do not ask the model
when something was true; stamp it and filter.

## How it threads through the existing pieces

- **Provenance gains time.** Each claim/source carries the stamps above, from attested
  sources (publication/filing/posting dates), same discipline as `evidence_basis`.
- **As-of retrieval.** The brain's `retrieve`/`answer`/`infer_trust` take an `as_of`
  date; a fact with `knowable_time > as_of` (or unknown) is invisible — so the brain
  answers *what was knowable then*, with no lookahead. One predicate before the vector
  search.
- **Walk-forward calibration.** The honest version of the brain's self-grading splits
  train/test on `knowable_time` (past → future), a strictly stronger test of predictive
  (not merely interpolative) structure than a random split.
- **Temporal-consistency as a new external check.** A claim asserting a timeline is
  checkable against an external event timeline; a claimed date contradicting the
  attested one is `inconsistent` — the temporal sibling of the reference verdicts.

That is the whole discipline. Anything domain-specific (aligning events to price
windows, survivorship in an event set, trading-calendar mapping) belongs to whichever
consumer uses it, not here.
