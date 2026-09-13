#!/usr/bin/env python3
"""Deterministic claim-reference proposer: given a hypothesis, retrieve the corpus
claims it plausibly leans on, so `claim_refs` are populated by retrieval rather
than an LLM guess.

This is the upstream half of the Layer 7 loop, kept firmly on the safe side of the
determinism boundary: it is *retrieval* (find candidate claims by text/domain
overlap), a proposer that surfaces candidates — it does not decide truth and it
does not decide, on its own authority, that a hypothesis "really" used a claim.
The researcher or author confirms/edits the proposed `claim_refs`; the proposer
just makes the candidates cheap to find and keeps them grounded in the actual
corpus (via `claims_index.json`) instead of invented.

Deterministic: pure token/domain overlap, no model call, same input -> same output.

Usage:
  python3 corpus/propose_claim_refs.py "hypothesis text ..." [--k N] [--min S]
  python3 corpus/propose_claim_refs.py --selftest
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

STOP = set("""a an the of to in on for and or but with without within is are was were be been being
this that these those it its as by from at into over under about not no than then so such can could
should would may might will your you we our their they them he she his her using use used based which
what when where how why more most less least each per via across between among only also""".split())


def tokens(text):
    return {w for w in re.findall(r"[a-z][a-z0-9\-]+", (text or "").lower())
            if len(w) > 2 and w not in STOP}


def load_index(path=None):
    path = path or os.path.join(HERE, "claims_index.json")
    return json.load(open(path))["claims"]


def score_claim(hyp_tokens, hyp_instruments, claim):
    """Overlap score between a hypothesis and a claim: shared content tokens
    (Jaccard-ish, biased to the claim so short claims aren't penalised) plus a
    domain-token bonus and an instrument-mention bonus. Transparent and bounded."""
    ct = tokens(claim["text"]) | tokens(claim["domain"].replace("_", " "))
    if not ct:
        return 0.0
    shared = hyp_tokens & ct
    if not shared:
        return 0.0
    overlap = len(shared) / len(ct)                       # fraction of the claim covered
    dom_bonus = 0.15 if hyp_tokens & tokens(claim["domain"].replace("_", " ")) else 0.0
    inst_bonus = 0.15 if any(i.lower() in ct for i in hyp_instruments) else 0.0
    return round(min(1.0, overlap + dom_bonus + inst_bonus), 4)


def propose(hypothesis, index=None, k=5, min_score=0.15):
    """Return ranked candidate claim_refs for a hypothesis dict (uses title,
    description, instruments)."""
    index = index if index is not None else load_index()
    text = " ".join(str(hypothesis.get(f, "")) for f in ("title", "description"))
    hyp_tokens = tokens(text)
    instruments = [str(i) for i in hypothesis.get("instruments", [])]
    scored = []
    for cid, claim in index.items():
        s = score_claim(hyp_tokens, instruments, claim)
        if s >= min_score:
            scored.append((s, cid, claim))
    scored.sort(key=lambda t: (-t[0], t[1]))
    return [{"claim_id": cid, "score": s, "text": c["text"][:70], "domain": c["domain"]}
            for s, cid, c in scored[:k]]


def _selftest():
    index = load_index()
    # a hypothesis about ML stock prediction / market efficiency -> should surface
    # the market-efficiency / null-baseline claims from record 002
    h1 = {"title": "LSTM next-day stock return predictor",
          "description": "predict next-day stock returns from price history and sentiment; "
                         "benchmark against random portfolios and market efficiency",
          "instruments": ["SPY"]}
    r1 = [c["claim_id"] for c in propose(h1, index, k=6)]
    assert any(c.startswith("002-") for c in r1), r1

    # a hypothesis about valuation multiples -> should surface record 001 valuation claims
    h2 = {"title": "EV/EBITDA relative valuation screen",
          "description": "screen companies by EV/EBITDA and forward P/E within an industry",
          "instruments": []}
    r2 = [c["claim_id"] for c in propose(h2, index, k=6)]
    assert any(c.startswith("001-") for c in r2), r2

    # an unrelated hypothesis -> few/no matches (deterministic, not forced)
    h3 = {"title": "weather-based ice cream demand", "description": "temperature vs sales", "instruments": []}
    r3 = propose(h3, index, k=6)
    assert len(r3) <= 2, r3

    # determinism
    assert propose(h1, index) == propose(h1, index)
    print("propose_claim_refs selftest: PASS "
          "(ML/efficiency hyp -> 002 claims; valuation hyp -> 001 claims; unrelated -> few; deterministic)")


def main():
    if "--selftest" in sys.argv:
        _selftest()
        return
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    k = 5
    min_score = 0.15
    if "--k" in sys.argv:
        k = int(sys.argv[sys.argv.index("--k") + 1])
    if "--min" in sys.argv:
        min_score = float(sys.argv[sys.argv.index("--min") + 1])
    if not args:
        print('usage: propose_claim_refs.py "hypothesis text" [--k N] [--min S] | --selftest')
        return
    hyp = {"title": "", "description": args[0], "instruments": []}
    for c in propose(hyp, k=k, min_score=min_score):
        print(f"  {c['score']:.3f}  {c['claim_id']:10} [{c['domain']}] {c['text']}")


if __name__ == "__main__":
    main()
