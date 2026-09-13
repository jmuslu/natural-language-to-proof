#!/usr/bin/env python3
"""Build the curated-corpus records (schema v2) for the adversarial epistemic
suite described in HANDOFF-corpus-adversarial.md.

Reproducible: this script is the transformation, run it to regenerate
`corpus/record_schema.json` and `corpus/records/record_00X.json` from the source
data below and the raw transcripts at `~/corpus/raw/` (kept OUTSIDE the repo,
mirroring the ~/ccgbank pattern, because third-party transcripts/articles carry
ToS/copyright exposure).

What this does and — importantly — does NOT do. The agent structures the corpus
(normalising fields, decomposing per-claim, tracking the confounds the handoff
asks for) which is squarely on the "data in, structure applied" side the handoffs
say agents belong on. It does NOT decide whether any claim is factually
consistent: every claim's `checkable_reference` and `consistency_verdict` are left
null for the owner or an external reference to fill, and `verification_status`
stays "not_performed". Deciding a claim's truth is the one thing the handoffs
forbid an agent from doing here.

Schema v2 vs the original `record_schema.json`. The original was a minimal stub
(video_id/title/channel/url/segments/notes) that the four collected records had
already outgrown inconsistently — articles carried `media_type`, only 001 tracked
word count, only 003/004 flat `key_claims_surface`, 002 had no claim
decomposition at all. v2 unifies video + article, and adds the fields the handoff
calls for: `format` and `length` (confound tracking), a structured `owner_label`
with a `confidence` level factored out of the label string, a `risk_quality` axis
kept SEPARATE from factual consistency (record 003 explicitly needed this), and a
`claims[]` array with per-claim attribution + null verification slots.
"""
import json
import os
from pathlib import Path

RAW = Path.home() / "corpus" / "raw"
OUT = Path(__file__).resolve().parent
SCHEMA_VERSION = "2.0"

# Controlled vocabularies (documented; not enforced in code).
CLASS_VALUES      = ["unlabeled", "consistent", "inconsistent", "ambiguous"]
CONFIDENCE_VALUES = ["none", "uncertain", "tentative", "firm"]
CLAIM_TYPES = [
    "factual_quantitative",  # a specific number/statistic that can be checked
    "factual_qualitative",   # a checkable qualitative fact or dated event
    "definitional",          # a stated definition or identity
    "methodological",        # a claim about whether an approach/method is valid
    "recommendation",        # advice / heuristic offered to the audience
    "prediction",            # forward-looking or self-reported track record
    "opinion",               # subjective, not straightforwardly checkable
]


def word_count(raw_name):
    p = RAW / raw_name
    if not p.exists():
        return None
    return len(p.read_text(encoding="latin-1").split())


def claim(cid, text, domain, ctype, segment_id=None):
    """One per-claim record. The three verification fields are deliberately left
    empty — they are the owner's / an external reference's to fill, never the
    structuring agent's."""
    return {
        "claim_id": cid,
        "segment_id": segment_id,
        "claim_text": text,
        "domain": domain,
        "claim_type": ctype,
        # --- left null on purpose: filled by owner/external check, not the agent ---
        "checkable_reference": None,
        "consistency_verdict": None,      # one of consistent | inconsistent | unresolved
        "verification_status": "not_performed",
    }


def base(record_id, media_type, fmt, title, source, urls, dates, raw_name,
         owner_label, risk_quality, claims, segments=None, source_metadata=None,
         access_note=None, notes=None, extra=None, agent_label=None,
         word_count_override=None):
    wc = word_count_override if word_count_override is not None else word_count(raw_name)
    rec = {
        "record_id": record_id,
        "schema_version": SCHEMA_VERSION,
        "media_type": media_type,                       # youtube_video | substack_article | ...
        "format": fmt,                                  # video_transcript | article  (confound field)
        "title": title,
        "source": source,                               # {name, kind}
        "urls": urls,
        "dates": dates,
        "length": {                                     # confound field
            "raw_word_count": wc,
            "segment_count": len(segments) if segments else 0,
            "claim_count": len(claims),
        },
        "owner_label": owner_label,                     # {class, confidence, is_adversarial_bucket, reasoning}
        # agent-proposed record-level label (reference-backed, pending owner
        # confirmation) for records the owner has not labeled -- kept DISTINCT
        # from owner_label so the two never get conflated. None => none proposed.
        "agent_label": agent_label,
        "risk_quality": risk_quality,                   # separate axis from factual consistency
        "segments": segments or [],
        "claims": claims,
        "verification_status": "NOT PERFORMED -- data collection + structuring only; "
                               "no per-claim source-checking done.",
        "provenance": {
            "label_source": "owner",                    # class/confidence/reasoning are the owner's
            "structure_source": "agent",                # field normalisation + per-claim decomposition
            "raw_transcript_path": f"~/corpus/raw/{raw_name}",   # OUTSIDE the repo
            "schema_version": SCHEMA_VERSION,
        },
        "source_metadata": source_metadata or {},
        "access_note": access_note,
        "notes": notes,
    }
    if extra:
        rec.update(extra)
    return rec


def owner_label(cls, confidence, reasoning, adversarial=False):
    assert cls in CLASS_VALUES and confidence in CONFIDENCE_VALUES
    return {"class": cls, "confidence": confidence,
            "is_adversarial_bucket": adversarial, "reasoning": reasoning}


def agent_label(cls, confidence, reasoning):
    """A reference-backed, agent-PROPOSED record-level label (bootstrapping only;
    pending owner confirmation before the live system trusts it). Distinct from
    owner_label so provenance is never lost."""
    assert cls in CLASS_VALUES and confidence in CONFIDENCE_VALUES
    return {"class": cls, "confidence": confidence, "source": "agent_proposed",
            "status": "pending_owner_confirmation", "reasoning": reasoning}


def risk_quality(assessed, assessment=None, reasoning=None):
    """The risk/quality axis, kept distinct from factual consistency: a source can
    be factually accurate yet promote a poor risk-adjusted strategy, or vice
    versa. Populated only where the owner actually assessed it."""
    return {"assessed": assessed, "assessment": assessment, "reasoning": reasoning}


# ---------------------------------------------------------------------------
# record 001 -- youtube video, compilation, owner left UNLABELED
# ---------------------------------------------------------------------------
r001_segments = [
    {"segment_id": "001-1", "topic": "P/E ratio valuation"},
    {"segment_id": "001-2", "topic": "EV/EBITDA valuation"},
    {"segment_id": "001-3", "topic": "Fed policy rate & balance sheet, 4-quadrant liquidity framework"},
    {"segment_id": "001-4", "topic": "10 macro indicators to monitor"},
    {"segment_id": "001-5", "topic": "Investment strategy framework: 4 hypothetical stocks mapped to liquidity quadrants"},
    {"segment_id": "001-6", "topic": "Investor mindset (5 principles)"},
    {"segment_id": "001-7", "topic": "'5 metrics to time the market' with historical case studies"},
]
r001_claims = [
    claim("001-1-a", "P/E = market cap / net income", "equity_valuation", "definitional", "001-1"),
    claim("001-1-b", "low P/E is not inherently better; future earnings growth matters more than the current multiple", "equity_valuation", "opinion", "001-1"),
    claim("001-1-c", "recommends regression of P/E vs forward EPS growth within an industry, ~10 comparables, R-squared > 0.8 as a confidence threshold", "equity_valuation", "recommendation", "001-1"),
    claim("001-1-d", "recommends forward P/E (next-FY expected earnings) over trailing P/E", "equity_valuation", "recommendation", "001-1"),
    claim("001-2-a", "EV = market cap + total debt + preferred stock + minority interest - cash", "equity_valuation", "definitional", "001-2"),
    claim("001-2-b", "EBITDA = operating income + depreciation & amortization", "equity_valuation", "definitional", "001-2"),
    claim("001-2-c", "EV/EBITDA is useful for comparing companies regardless of capital structure, esp. capital-intensive/leveraged/manufacturing businesses", "equity_valuation", "factual_qualitative", "001-2"),
    claim("001-2-d", "for low-growth companies (<10% revenue growth) prefer historical EV/EBITDA; for high-growth prefer forward EV/EBITDA", "equity_valuation", "recommendation", "001-2"),
    claim("001-3-a", "low rate + increasing Fed balance sheet = most-liquid regime, favors high-growth unprofitable companies", "monetary_policy", "methodological", "001-3"),
    claim("001-3-b", "high rate + decreasing balance sheet = least-liquid regime, favors high-margin low-valuation traditional sectors", "monetary_policy", "methodological", "001-3"),
    claim("001-3-c", "cites 2008 and 2020 as balance-sheet-increase episodes; 2018-2019 and 2022-present as decrease episodes", "monetary_policy", "factual_qualitative", "001-3"),
    claim("001-3-d", "cites 2004 and 2022 as policy-rate-increase episodes; 2008 and 2020 as decrease episodes", "monetary_policy", "factual_qualitative", "001-3"),
    claim("001-4-a", "lists 10 macro indicators (unemployment, jobless claims, NFP, YoY CPI, core CPI, MoM PPI, ISM mfg PMI, ISM non-mfg PMI, Chicago PMI, consumer confidence) as covering ~80-90% of the macro economy", "macro_indicators", "factual_quantitative", "001-4"),
    claim("001-4-b", "asserts specific numeric thresholds (unemployment <4% strong / 4-5.5% ok / >5.5% weak; Fed inflation target 2%; PMI neutral 50; consumer confidence neutral 100)", "macro_indicators", "factual_quantitative", "001-4"),
    claim("001-4-c", "asserts non-manufacturing PMI covers ~70% of the US economy, manufacturing ~10-12%", "macro_indicators", "factual_quantitative", "001-4"),
    claim("001-4-d", "asserts core PCE is the Fed's preferred inflation gauge over core CPI", "monetary_policy", "factual_qualitative", "001-4"),
    claim("001-5-a", "constructs 4 hypothetical companies varying by revenue/earnings growth, forward P/E, debt/EBITDA", "portfolio_construction", "methodological", "001-5"),
    claim("001-5-b", "maps each hypothetical to a preferred liquidity-quadrant fit", "portfolio_construction", "methodological", "001-5"),
    claim("001-5-c", "explicit personal risk-sizing rules by quadrant (e.g. not >20% of cash in least-liquid quadrant, up to 100%+ leverage in most-liquid)", "risk_management", "recommendation", "001-5"),
    claim("001-6-a", "5 investor-mindset principles (own principle, ignore noise, review regularly, remove emotional attachment, don't discuss positions)", "investor_psychology", "recommendation", "001-6"),
    claim("001-6-b", "personal anecdotes: ~15 years in IB/PE, didn't invest for ~10 years before late 2019, prior video about losing $100k in one day", "biographical", "factual_qualitative", "001-6"),
    claim("001-7-a", "self-reported buy calls (Apr 2025, Mar 2026) each coincided with VIX>30, Fed not signaling hikes, declining FINRA margin debt, a clear leading sector, and EPS/rev beats in that sector", "market_timing", "prediction", "001-7"),
    claim("001-7-b", "claims Apr 2025 call up ~75-80%, Mar 2026 call up ~20-25% / 40-45% by sub-allocation", "market_timing", "prediction", "001-7"),
    claim("001-7-c", "claims the 5-metric setup 'worked' in 1997 Asia crisis, 2011 euro crisis/US downgrade, 2018 Powell-hike panic, 2020 COVID crash", "market_timing", "factual_qualitative", "001-7"),
    claim("001-7-d", "claims the 5-metric setup 'failed' in 2000-01 dot-com, 2002 accounting scandals, 2008 GFC, 2022 inflation, 1973 OPEC embargo", "market_timing", "factual_qualitative", "001-7"),
    claim("001-7-e", "specific historical figures (Fed funds ~6.5%->1.75% in 2001; margin debt ~$300B->$140B in 2001; VIX ~40 in 2002, ~83 in 2020; current YoY CPI ~3.3%)", "market_timing", "factual_quantitative", "001-7"),
    claim("001-7-f", "names new Fed chair 'Kevin Worsh' (likely intends Kevin Warsh) commenting on rate cuts", "monetary_policy", "factual_qualitative", "001-7"),
    claim("001-7-g", "proposes BofA US High Yield spread as a false-positive check; cites normal junk spread 8-10% vs 15-20%+ in a credit crunch", "credit_markets", "factual_quantitative", "001-7"),
]

# ---------------------------------------------------------------------------
# record 002 -- youtube video, owner label INCONSISTENT (adversarial bucket)
# claims extracted by the structuring agent from the raw transcript.
# ---------------------------------------------------------------------------
r002_claims = [
    claim("002-a", "builds an LSTM trained on price history, sentiment, and technical features to predict next-day stock direction/return", "ml_methodology", "methodological"),
    claim("002-b", "acknowledges any exploitable pattern in public price/sentiment data is likely already priced in by faster, better-capitalized institutional actors (market efficiency)", "market_efficiency", "factual_qualitative"),
    claim("002-c", "compares the ML model against both a buy-and-hold S&P benchmark and a band of random buy/sell portfolios; the model must beat the random noise band to be considered working", "ml_methodology", "methodological"),
    claim("002-d", "reports the model still cannot clearly beat the random-portfolio noise band", "ml_methodology", "factual_qualitative"),
    claim("002-e", "adds early stopping (halt after 10-15 epochs without validation improvement) to reduce overfitting/training time", "ml_methodology", "methodological"),
    claim("002-f", "switches the target from binary up/down to next-day log return, to rank opportunities by expected magnitude", "ml_methodology", "methodological"),
    claim("002-g", "adds permutation importance for feature importance and time-decayed features", "ml_methodology", "methodological"),
]

# ---------------------------------------------------------------------------
# record 003 -- substack article, owner label AMBIGUOUS + explicit risk_quality axis
# ---------------------------------------------------------------------------
r003_claims = [
    claim("003-a", "stablecoin-pair (e.g. BUSD/USDT) market making returned ~29%/year unleveraged, 2021-early 2022", "crypto_market_making", "factual_quantitative"),
    claim("003-b", "with 5-10x leverage, annualized returns exceeded 200%", "crypto_market_making", "factual_quantitative"),
    claim("003-c", "strategy has since decayed to ~10% unleveraged (implying it no longer clears leverage costs)", "crypto_market_making", "factual_quantitative"),
    claim("003-d", "typical tick spread on these pairs ~0.0001 (1 bp per round trip)", "market_microstructure", "factual_quantitative"),
    claim("003-e", "major exchanges charge zero maker fees on stablecoin pairs regardless of fee tier", "market_microstructure", "factual_qualitative"),
    claim("003-f", "competition is 'queue time' rather than price/skill, because the minimum tick prevents spread compression below the tick", "market_microstructure", "methodological"),
    claim("003-g", "estimates ~1 fill/hour at peak, ~16 hours/day, 8 round trips/day, 8 bps/day, ~29.2%/year unleveraged (arithmetic, not compounded)", "crypto_market_making", "factual_quantitative"),
]

# ---------------------------------------------------------------------------
# record 004 -- substack article, same source as 003, owner label TENTATIVELY CONSISTENT
# ---------------------------------------------------------------------------
r004_claims = [
    claim("004-a", "cites an unnamed 'recent industry survey' (linked to exabel.com): 71% of investment managers say combining data from different sources is their most frustrating challenge but highest-payoff task", "alt_data", "factual_quantitative"),
    claim("004-b", "alternative-data market spending projected to surpass $15 billion in 2025", "alt_data", "factual_quantitative"),
    claim("004-c", "95% of buyers plan to increase alternative-data budgets further", "alt_data", "factual_quantitative"),
    claim("004-d", "alpha half-life from a novel alternative dataset dropped from ~36 months a decade ago to ~18 months today (unsourced in the free portion)", "alt_data", "factual_quantitative"),
    claim("004-e", "combining multiple low-correlation datasets reduces portfolio variance without sacrificing expected return (standard diversification/uncorrelated-signal argument)", "portfolio_theory", "factual_qualitative"),
    claim("004-f", "promises a dataset-by-dataset breakdown of a 28-dataset library, NOT visible in the captured free portion (paywalled)", "alt_data", "factual_qualitative"),
]


r005_claims = [
    claim("005-a", "a decline from $100k to $78k is a real $22k loss in current value whether or not the position is sold (mark-to-market)", "investing_principles", "factual_qualitative"),
    claim("005-b", "selling forgoes future appreciation/income while also avoiding further potential loss (opportunity cost is symmetric)", "investing_principles", "factual_qualitative"),
    claim("005-c", "selling changes tax status (realizes a gain/loss) but that is separate from whether value was actually lost", "taxation", "factual_qualitative"),
    claim("005-d", "the phrase encourages anchoring to purchase price rather than market price (anchoring bias)", "investor_psychology", "factual_qualitative"),
    claim("005-e", "believing losses aren't real until sale makes investors hold underperformers longer, risking deeper losses", "investor_psychology", "opinion"),
    claim("005-f", "the mindset discourages tax-loss harvesting that could cut taxes while keeping market exposure", "taxation", "factual_qualitative"),
]


def build():
    records = []

    records.append(base(
        record_id="001", media_type="youtube_video", fmt="video_transcript",
        title="Full course on stock investing (2 hours)",
        source={"name": "Defiant Gatekeeper", "kind": "youtube_channel"},
        urls={"url": None, "url_note": "NOT PROVIDED; description links referenced but URL not captured."},
        dates={"published": "2026-07-04", "captured": None},
        raw_name="001_full_transcript.txt",
        owner_label=owner_label("unlabeled", "none",
            "Owner left this record unlabeled -- collected as data only. A held-out, "
            "as-yet-unlabeled example, not assigned to either bucket."),
        risk_quality=risk_quality(False),
        claims=r001_claims, segments=r001_segments,
        source_metadata={
            "channel_subscribers": "112K", "views_at_capture": 70005,
            "channel_description": "Ex-investment banker and current credit private "
                                   "equity/hedge fund investor",
            "structure": "compilation assembled from the channel's own prior individual "
                         "videos, each introduced with a short bridging comment",
            "raw_transcript_source": "manually retyped from user-pasted transcript "
                                     "(flagged for possible minor transcription drift)",
        },
        notes="Numerous specific, independently checkable claims (definitions, historical "
              "figures, macro thresholds). Pure data collection -- no consistency verdicts.",
    ))

    records.append(base(
        record_id="002", media_type="youtube_video", fmt="video_transcript",
        title="Letting My Viewers Fix My Stock Prediction Program | Python LSTM Stock Predictor",
        source={"name": "LosingLoonies", "kind": "youtube_channel"},
        urls={"url": "https://www.youtube.com/watch?v=q24MVGCUr4w"},
        dates={"published": "2025-10-10", "captured": None},
        raw_name="002_raw_upload.txt",
        owner_label=owner_label("inconsistent", "firm",
            "Deliberately chosen as the adversarial/bad-bucket example. The approach "
            "(LSTM/tree ML on price history, sentiment, technical features to predict "
            "next-day returns) is undermined by market efficiency: any exploitable pattern "
            "in public price/sentiment data is already priced in by faster, better-"
            "capitalized institutional actors. The incremental fixes (early stopping, "
            "log-return targets, permutation importance, time-decayed features) are "
            "legitimate ML engineering but do not address why the strategy can't work -- "
            "the model backtests against random-portfolio noise bands and reportedly still "
            "can't clear them.",
            adversarial=True),
        risk_quality=risk_quality(False),
        claims=r002_claims,
        source_metadata={
            "channel_subscribers": "53.2K", "views_at_capture": 66784,
            "series_context": {
                "prior_video_title": "Can AI Predict Tomorrow's Stock Price? | Python LSTM Stock Predictor",
                "prior_video_url": "https://www.youtube.com/watch?v=aiFpAl3mgGk"},
            "raw_transcript_source": "user upload (loon.txt), copied byte-exact",
        },
        notes="Owner-supplied label/reasoning recorded as-is (owner, not agent). Claims "
              "here were decomposed by the structuring agent from the transcript; none are "
              "verdict-assigned. Note the video itself uses a random-portfolio null band -- "
              "a methodologically sound instinct -- yet is labeled inconsistent on the "
              "market-efficiency ground, i.e. the label is about the approach, not the ML "
              "technique.",
    ))

    records.append(base(
        record_id="003", media_type="substack_article", fmt="article",
        title="The Dumbest Strategy That Returned 200% a Year",
        source={"name": "paperswithbacktest (Edouard d'Archimbaud)", "kind": "substack_publication",
                "publication": "Algo Trading & AI"},
        urls={"url_as_given": "https://substack.com/home/post/p-192536034",
              "canonical_url": "https://blog.paperswithbacktest.com/p/the-dumbest-strategy-that-returned"},
        dates={"published": "2026-05-03", "captured": None},
        raw_name="003_raw_article.txt",
        owner_label=owner_label("ambiguous", "uncertain",
            "Owner's own words: 'not sure if this is really all that good but it's not "
            "blatantly wrong... in the metrics of actual alpha its probably bad because "
            "its just frontloading disproportionate risk for a relatively low gain compared "
            "to the risk.' The owner is not disputing the article's facts; the concern is a "
            "risk-adjusted-return quality judgment -- recorded on the separate risk_quality "
            "axis, not forced into consistent/inconsistent."),
        risk_quality=risk_quality(True,
            assessment="poor-risk-adjusted",
            reasoning="Leverage on a queue-priority-dependent, thin-edge strategy front-loads "
                      "tail risk that may not be compensated by the raw return figure. This is "
                      "a quality/risk judgment, explicitly distinct from whether the article's "
                      "stated facts are correct."),
        claims=r003_claims,
        source_metadata={"raw_transcript_source": "web_fetch of canonical URL, free portion only (paywall)"},
        access_note="PAYWALLED past 'The Leverage Multiplier'. Only the free portion is "
                    "captured. Owner confirmed acceptable: the general-principle inference "
                    "(queue-priority, tick-constrained spread economics) is drawable from the "
                    "free portion without the paywalled leverage/risk detail.",
        notes="Plausible, technically-grounded microstructure narrative, but 'plausible and "
              "fluent' is not 'checked'. Paywall cutoff means the corpus is missing the "
              "leverage/risk section most relevant to the owner's risk concern.",
    ))

    records.append(base(
        record_id="004", media_type="substack_article", fmt="article",
        title="28 Datasets, One Edge: Building Multi-Signal Trading Strategies",
        source={"name": "paperswithbacktest (Edouard d'Archimbaud)", "kind": "substack_publication",
                "publication": "Algo Trading & AI"},
        urls={"url_as_given": "https://substack.com/home/post/p-191784926",
              "canonical_url": "https://blog.paperswithbacktest.com/p/28-datasets-one-edge-building-multi"},
        dates={"published": "2026-03-29", "captured": None},
        raw_name="004_raw_article.txt",
        owner_label=owner_label("consistent", "tentative",
            "Owner's own words: 'this one looks decent.' Provisional -- recorded as tentative "
            "rather than upgraded to a firm verdict on the owner's behalf."),
        risk_quality=risk_quality(False),
        claims=r004_claims,
        source_metadata={"raw_transcript_source": "web_fetch of canonical URL, free portion only (paywall)",
                         "same_source_as": "003 (paperswithbacktest / Edouard d'Archimbaud, same publication)"},
        access_note="PAYWALLED right before 'What 28 Datasets Actually Cover' -- cut off where "
                    "the promised dataset breakdown would begin. Only the setup/framing is captured.",
        notes="Core mechanism (uncorrelated signals reduce variance) is standard portfolio "
              "theory -- structurally sound without an external check; the specific statistics "
              "(71%, $15B, 95%, 36->18mo half-life) are asserted without visible sourcing and "
              "need per-claim checking. HALO-EFFECT WARNING: same author as 003; this must NOT "
              "get lighter scrutiny for that reason -- each claim gets its own check.",
    ))

    records.append(base(
        record_id="005", media_type="web_article", fmt="article",
        title="Why \"You Don't Lose Money Until You Sell\" Is Bunk",
        source={"name": "The White Coat Investor", "kind": "blog"},
        urls={"url": "https://www.whitecoatinvestor.com/why-you-dont-lose-money-until-you-sell-is-bunk/"},
        dates={"published": None, "captured": "2026-09-13"},
        raw_name="005_raw_article.txt", word_count_override=1100,
        owner_label=owner_label("unlabeled", "none",
            "Not yet reviewed by the owner. Agent-collected (WebFetch) during "
            "bootstrapping; see agent_label for the reference-backed proposal."),
        agent_label=agent_label("consistent", "firm",
            "Reference-backed (agent-proposed, pending owner confirmation): the "
            "article's claims are standard, correct finance principles -- "
            "mark-to-market defines a real unrealized loss, opportunity cost is "
            "symmetric, tax realization is distinct from value change, anchoring "
            "bias and tax-loss harvesting are well-established. See "
            "verdicts_agent_proposed.json for per-claim verdicts."),
        risk_quality=risk_quality(False),
        claims=r005_claims,
        source_metadata={"raw_transcript_source": "WebFetch (agent), URL + extracted claims only (not verbatim; ToS)"},
        notes="Agent-collected to grow the corpus during bootstrapping. Adds a "
              "consistent ARTICLE -- note this worsens the format/label balance "
              "(more articles on the consistent side); confound_check reports the "
              "resulting imbalance honestly. Clearing the confound needs balanced "
              "collection incl. inconsistent sources and videos, not padding.",
    ))

    return records


def main():
    (OUT / "records").mkdir(exist_ok=True)
    # write the v2 schema descriptor
    schema = {
        "schema_version": SCHEMA_VERSION,
        "description": "Curated corpus record for the adversarial epistemic suite. "
                       "Structured by an agent; factual-consistency verdicts are the "
                       "owner's / an external reference's, never the agent's.",
        "controlled_vocabularies": {
            "owner_label.class": CLASS_VALUES,
            "owner_label.confidence": CONFIDENCE_VALUES,
            "claims[].claim_type": CLAIM_TYPES,
            "format": ["video_transcript", "article"],
        },
        "fields": {
            "record_id": "string",
            "media_type": "youtube_video | substack_article | ...",
            "format": "confound field: video_transcript | article",
            "title": "string",
            "source": "{name, kind, [publication]}",
            "urls": "{...} format-specific url fields",
            "dates": "{published, captured}",
            "length": "confound field: {raw_word_count, segment_count, claim_count}",
            "owner_label": "{class, confidence, is_adversarial_bucket, reasoning}  (owner-sourced)",
            "agent_label": "{class, confidence, source, status, reasoning} or null  -- "
                           "reference-backed agent proposal for owner-unlabeled records "
                           "(bootstrapping; pending owner confirmation); kept DISTINCT from owner_label",
            "risk_quality": "{assessed, assessment, reasoning}  -- axis SEPARATE from factual consistency",
            "segments": "[{segment_id, topic}]  (video/compilation structure; may be empty)",
            "claims": "[{claim_id, segment_id, claim_text, domain, claim_type, "
                      "checkable_reference:null, consistency_verdict:null, verification_status}]",
            "verification_status": "top-level; NOT PERFORMED at collection time",
            "provenance": "{label_source, structure_source, raw_transcript_path, schema_version}",
            "source_metadata": "format-specific extras (subscribers/views | author/publication)",
            "access_note": "paywall / capture caveats",
            "notes": "free-text",
        },
    }
    (OUT / "record_schema.json").write_text(json.dumps(schema, indent=2) + "\n")

    for rec in build():
        path = OUT / "records" / f"record_{rec['record_id']}.json"
        path.write_text(json.dumps(rec, indent=2) + "\n")
        wc = rec["length"]["raw_word_count"]
        print(f"wrote {path.name}: format={rec['format']:16} "
              f"label={rec['owner_label']['class']}/{rec['owner_label']['confidence']:9} "
              f"words={wc} claims={rec['length']['claim_count']}")


if __name__ == "__main__":
    main()
