#!/usr/bin/env python3
"""Add `evidence_basis` to every claim in the records (idempotent migration).

`evidence_basis` is ORTHOGONAL to `claim_type`: claim_type is the claim's FORM,
evidence_basis is what would VERIFY it. A `factual_quantitative` claim can be
`public_reference` (Fed funds history) or `self_reported` (the source's own strategy
return) -- and only `public_reference` claims belong on the consistency-verify
frontier. This encodes that distinction as DATA rather than a text heuristic, so the
brain's exploration routes each claim to the right kind of check.

Assignment = a principled default by claim_type, then explicit per-claim overrides
for claims that are self-reported (the source's own bio/track record/results) or
unquantifiable (no well-defined metric). The overrides are the auditable judgment;
they are listed here, not hidden. Re-runnable: only writes a record if it changed.
"""
import glob
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))

# Default: what usually verifies a claim of this form.
DEFAULT_BY_TYPE = {
    "definitional": "public_reference",      # standard definitions are checkable
    "factual_quantitative": "public_reference",
    "factual_qualitative": "public_reference",
    "methodological": "not_applicable",      # describes the source's own process
    "recommendation": "not_applicable",      # advice -> risk_quality axis, not consistency
    "prediction": "self_reported",           # self-reported calls / forecasts
    "opinion": "unquantifiable",
}

# Overrides: claims whose evidence_basis differs from the type default. Each is the
# source's OWN bio/track record/results (self_reported) or a vague assertion with no
# well-defined metric (unquantifiable) -- so they cannot get an external factual
# consistency verdict, however "factual" their form looks.
OVERRIDES = {
    "001-4-a": "unquantifiable",   # "these 10 indicators cover ~80-90% of the macro economy"
    "001-6-b": "self_reported",    # personal anecdotes: ~15y in IB/PE, etc.
    "001-7-c": "self_reported",    # own 5-metric setup "worked" in past crises
    "001-7-d": "self_reported",    # own 5-metric setup "failed" in past crises
    "002-d":   "self_reported",    # own model still can't beat the noise band
    "003-c":   "self_reported",    # own strategy has decayed to ~10% unleveraged
}


def basis_for(claim: dict) -> str:
    cid = claim["claim_id"]
    if cid in OVERRIDES:
        return OVERRIDES[cid]
    return DEFAULT_BY_TYPE.get(claim["claim_type"], "public_reference")


def main() -> None:
    changed_files = 0
    counts = {}
    for f in sorted(glob.glob(os.path.join(HERE, "records", "*.json"))):
        rec = json.load(open(f))
        dirty = False
        for c in rec.get("claims", []):
            b = basis_for(c)
            counts[b] = counts.get(b, 0) + 1
            if c.get("evidence_basis") != b:
                c["evidence_basis"] = b
                dirty = True
        if dirty:
            with open(f, "w") as fh:
                json.dump(rec, fh, indent=2)
                fh.write("\n")
            changed_files += 1
    print(f"evidence_basis migration: updated {changed_files} record file(s)")
    print("distribution:", ", ".join(f"{k}={n}" for k, n in sorted(counts.items())))


if __name__ == "__main__":
    main()
