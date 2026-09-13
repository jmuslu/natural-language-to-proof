#!/usr/bin/env python3
"""Agent-proposed, reference-backed per-claim verdicts for the corpus.

Correction to an earlier over-reading: the "an agent must never decide whether a
claim is factually consistent" rule is a constraint on the *live, autonomous*
system, not on bootstrapping. During development the agent should do the
verification work — as a *proposer* (the Layer 6 proposer/never-decider role):
check each claim against an external, checkable reference and propose a verdict,
with the reference and reasoning attached, `verdict_source = "agent_proposed"`,
subject to owner/external confirmation before the live system trusts it. What
stays forbidden is the bad kind of "deciding": substituting the agent's own read
of whether something *sounds* right for an actual external check. Every verdict
below cites what it was checked against.

Verdict values: "consistent" | "inconsistent" | "unresolved". "unresolved" is
used honestly and often — specific current statistics, self-reported track
records, and future/uncertain events are left unresolved (they need live data or
a primary source), not guessed. Confidence is the agent's, about how established
the reference is.

Note the useful divergence this surfaces: a per-claim verdict can differ from the
owner's *global* label. Record 002's individual claims (market efficiency,
null-baseline methodology, standard ML fixes) mostly check out even though the
owner labels the *strategy* inconsistent — the global label is about the
endeavour, the per-claim verdicts about the statements. That divergence is
exactly why per-claim decomposition matters.
"""
import glob
import json
import os


def v(claim_id, verdict, confidence, reference, reasoning):
    return {"claim_id": claim_id, "verdict": verdict, "confidence": confidence,
            "checkable_reference": reference, "reasoning": reasoning,
            "verdict_source": "agent_proposed",
            "verification_status": "agent_proposed_pending_owner_confirmation"}


VERDICTS = [
    # ---- record 001: finance-education definitions & facts ----
    v("001-1-a", "consistent", "high", "standard corporate-finance definition (P/E = price/EPS = market cap/net income)",
      "Identity holds: net income / shares = EPS, market cap / shares = price, so market cap / net income = price/EPS = P/E."),
    v("001-1-c", "unresolved", "low", "presenter heuristic (R-squared > 0.8 threshold)",
      "An R^2 > 0.8 'confidence' threshold for a P/E-vs-growth regression is a stipulated rule of thumb, not a checkable fact."),
    v("001-2-a", "consistent", "high", "standard enterprise-value definition",
      "EV = market cap + total debt + preferred stock + minority interest - cash & equivalents is the textbook definition."),
    v("001-2-b", "consistent", "high", "standard EBITDA definition",
      "EBITDA = EBIT + D&A = operating income + depreciation & amortization."),
    v("001-2-c", "consistent", "medium", "microstructure/valuation rationale for EV/EBITDA",
      "EV/EBITDA is capital-structure-neutral (numerator includes debt, denominator is pre-interest), so cross-capital-structure comparison is the standard rationale."),
    v("001-3-c", "consistent", "high", "Federal Reserve H.4.1 balance-sheet history",
      "Fed balance sheet expanded in 2008 (QE1) and 2020 (COVID QE); contracted in 2018-2019 and from mid-2022 (QT). Matches the claim."),
    v("001-3-d", "consistent", "high", "Federal Reserve policy-rate history",
      "Fed funds rose in 2004 (hiking cycle) and 2022 (hiking cycle); cut sharply in 2008 (to ~0) and 2020 (to ~0). Matches."),
    v("001-4-b-target", "consistent", "high", "FOMC longer-run inflation objective; ISM methodology",
      "Fed's 2% inflation target and ISM PMI 50 = expansion/contraction line are both correct."),
    v("001-4-b-cci", "inconsistent", "medium", "Conference Board Consumer Confidence Index methodology (1985=100 base)",
      "The claim treats CCI=100 as a 'neutral' level; 100 is the 1985 base-year index value, not a neutral/expansion line. Minor but a real definitional error."),
    v("001-4-c", "consistent", "medium", "BEA GDP-by-industry shares",
      "Services are roughly ~70-80% of US GDP and manufacturing ~10-11%, consistent with the ~70% / ~10-12% figures."),
    v("001-4-d", "consistent", "high", "FOMC communications on preferred inflation gauge",
      "The Fed's preferred gauge is core PCE, not core CPI. Correct."),
    v("001-7-f", "inconsistent", "medium", "spelling of Kevin Warsh; Fed leadership as of knowledge cutoff",
      "Name is given as 'Kevin Worsh'; the person is Kevin Warsh. Whether he is the 'new Fed chair' is a 2026 event beyond confident verification and is separately unresolved."),
    v("001-7-g", "inconsistent", "medium", "BofA US High Yield Index option-adjusted spread history (FRED: BAMLH0A0HYM2)",
      "Claim calls 8-10% a 'normal' junk spread; historically the normal/calm HY OAS is ~3-5%, with 8-10% already elevated and 15-20%+ in a crisis (2008 ~20%, 2020 ~11%). The 'normal 8-10%' figure is too high."),
    v("001-7-e", "consistent", "medium",
      "Federal Reserve H.15 policy-rate history; Cboe VIX historical series; FINRA/NYSE margin-debt history",
      "Composite of historical figures, checked against external sources. Fed funds ~6.5%->1.75% in 2001: correct (11 FOMC cuts through 2001, target 1.75% by Dec 2001). VIX ~83 in 2020: correct (all-time high close 82.69 on 2020-03-16). VIX ~40 in 2002: approximately right (peaked ~40-45 in 2002). Margin debt ~$300B->$140B: magnitude roughly right (NYSE margin debt peaked ~$278B in early 2000 and fell to ~$130-140B by 2002) but the 'in 2001' timing is imprecise -- the peak was 2000 and the trough 2002, so the decline spanned 2000-2002. 'Current YoY CPI ~3.3%' is relative to the recording date and not independently verifiable as a fixed fact. Net: the checkable historical figures are consistent in magnitude and direction, with a minor margin-debt timing imprecision; hence consistent at medium confidence."),

    # ---- record 002: LSTM predictor (claims mostly sound; owner's global label is about the strategy) ----
    v("002-b", "consistent", "high", "semi-strong efficient-market hypothesis (mainstream finance)",
      "That exploitable patterns in public price/sentiment data are largely arbitraged away by faster institutional actors is the standard semi-strong-EMH position."),
    v("002-c", "consistent", "high", "null-baseline / random-portfolio benchmarking (sound methodology)",
      "Comparing a model against both buy-and-hold and a band of random portfolios, and requiring it to beat the noise band, is a legitimate null-baseline test (the same discipline as the Layer 3 suite)."),
    v("002-e", "consistent", "high", "standard ML practice (early stopping)",
      "Halting after N epochs without validation improvement is textbook early stopping and reduces overfitting/compute."),
    v("002-f", "consistent", "medium", "regression vs classification target choice",
      "Predicting next-day log return (continuous, rankable) rather than binary direction is a reasonable target change; captures magnitude the binary target ignores."),

    # ---- record 003: crypto market making ----
    v("003-f", "consistent", "medium", "market-microstructure theory (tick-constrained spreads, queue priority)",
      "When the minimum tick prevents spread compression, competition shifts to queue priority/time rather than price — a real, documented microstructure phenomenon."),
    v("003-g", "consistent", "medium", "arithmetic check of the stated figures",
      "8 bps/day * 365 = 2920 bps = 29.2%/year (simple, uncompounded) — the arithmetic is internally consistent. The INPUTS (1 fill/hour, 8 round trips/day) are unverified assumptions, left unresolved separately."),
    v("003-a", "unresolved", "n/a", "primary backtest data (not available)",
      "~29%/year unleveraged is a specific historical-performance claim requiring the actual backtest/returns to check; not verifiable from the free article portion."),
    v("003-b", "unresolved", "n/a", "primary backtest data (not available)",
      "The >200% leveraged figure sits behind the paywall and needs the underlying data."),

    # ---- record 004: 28 datasets ----
    v("004-e", "consistent", "high", "modern portfolio theory (diversification of uncorrelated signals)",
      "Combining low-correlation return streams reduces portfolio variance for a given expected return — the standard Markowitz diversification result. Structurally sound without external data."),
    v("004-a", "unresolved", "n/a", "cited industry survey (exabel.com) — primary source not fetched",
      "The 71% figure is attributed to a survey; verifying it needs the primary survey, not the article's paraphrase."),
    v("004-b", "unresolved", "low", "alternative-data market-size forecasts (definition-dependent)",
      "Alt-data market-size estimates vary widely by definition and vendor; '>$15B in 2025' is plausible for some definitions but not confirmable without the specific source."),
    v("004-d", "unresolved", "n/a", "unsourced in the captured portion",
      "The 36mo->18mo alpha-half-life figure is unsourced even in the article's own free portion; needs a primary reference."),

    # ---- record 005: "you don't lose until you sell" is bunk (agent-collected) ----
    v("005-a", "consistent", "high", "mark-to-market accounting; definition of unrealized loss",
      "Current value is the market value; a 100k->78k decline is a real 22k reduction in current value whether or not realized. Standard."),
    v("005-b", "consistent", "high", "opportunity cost (standard microeconomics/finance)",
      "Holding vs selling both have costs: selling forgoes upside/income, holding risks further loss. The symmetry is correct."),
    v("005-c", "consistent", "high", "tax realization rules (realized vs unrealized)",
      "Selling realizes a gain/loss for tax purposes; the tax event is distinct from whether economic value changed. Correct."),
    v("005-d", "consistent", "high", "anchoring bias (behavioral finance, Tversky & Kahneman)",
      "Anchoring to purchase price rather than current market price is a well-documented cognitive bias; the article's use is apt."),
    v("005-f", "consistent", "high", "tax-loss harvesting (established strategy)",
      "Tax-loss harvesting realizes losses to offset gains while maintaining exposure (subject to wash-sale rules); the mindset does discourage it. Correct."),
]


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    # index of claim ids that actually exist in the records, for a sanity check
    known = set()
    for f in glob.glob(os.path.join(here, "records", "*.json")):
        for c in json.load(open(f))["claims"]:
            known.add(c["claim_id"])
    # some verdict ids are sub-claims (e.g. 001-4-b split into -target / -cci);
    # map them back to their parent for the existence check
    def parent(cid):
        return cid.rsplit("-", 1)[0] if cid.rsplit("-", 1)[-1] in ("target", "cci") else cid
    for vd in VERDICTS:
        assert parent(vd["claim_id"]) in known, f"verdict for unknown claim {vd['claim_id']}"

    tally = {}
    for vd in VERDICTS:
        tally[vd["verdict"]] = tally.get(vd["verdict"], 0) + 1
    out = {
        "verdict_source": "agent_proposed",
        "status": "pending_owner_confirmation",
        "note": "Reference-backed proposals made during bootstrapping; the live "
                "autonomous system must not treat these as final without owner or "
                "external confirmation.",
        "tally": tally,
        "verdicts": VERDICTS,
    }
    path = os.path.join(here, "verdicts_agent_proposed.json")
    with open(path, "w") as fh:
        json.dump(out, fh, indent=2)
    print(f"wrote {os.path.basename(path)}: "
          + ", ".join(f"{k}={n}" for k, n in sorted(tally.items())))


if __name__ == "__main__":
    main()
