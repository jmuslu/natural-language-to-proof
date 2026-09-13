#!/usr/bin/env python3
"""Export a lightweight, referenceable index of corpus claims.

For the Layer 7 loop to become live, an upstream stage (the researcher / a
hypothesis) has to be able to cite *which corpus claims* a strategy leans on, by
stable id, without loading the full records. This writes `corpus/claims_index.json`:
claim_id -> {text, domain, claim_type, source_id, source_title}. Those ids are
exactly what a hypothesis's `claim_refs` (and a backtest result's
`attribution.claim_refs`) point at, and what `ingest_outcomes.py` resolves when a
checked outcome propagates back.
"""
import glob
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))


def main():
    index = {}
    for f in sorted(glob.glob(os.path.join(HERE, "records", "*.json"))):
        rec = json.load(open(f))
        for c in rec["claims"]:
            index[c["claim_id"]] = {
                "text": c["claim_text"],
                "domain": c["domain"],
                "claim_type": c["claim_type"],
                "source_id": rec["record_id"],
                "source_title": rec["title"],
            }
    out = {
        "note": "Stable claim ids for citation by upstream stages (hypothesis "
                "claim_refs, backtest attribution.claim_refs). Generated from "
                "corpus/records; regenerate with export_claims_index.py.",
        "count": len(index),
        "claims": index,
    }
    path = os.path.join(HERE, "claims_index.json")
    with open(path, "w") as fh:
        json.dump(out, fh, indent=2)
    print(f"wrote {os.path.basename(path)}: {len(index)} claims")


if __name__ == "__main__":
    main()
