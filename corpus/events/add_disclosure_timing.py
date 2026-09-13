#!/usr/bin/env python3
"""Add `disclosure_timing` (+ source) to each event -- idempotent migration.

WHEN within the trading day a disclosure landed decides which session's bar captures
the reaction: pre_market/intraday -> same session; after_close -> next session. With
date-only knowable_time, the event study cannot place the window correctly without
this. Timings are set from DISCLOSURE evidence (press-release time / procedure), NOT
from the price reaction (that would be circular). Each carries a source noting whether
it is timestamp-verified or from disclosure/procedure norms -- the honest distinction,
and the remaining temporal-consistency refinement is to timestamp-verify every one.
"""
import glob
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))

TIMING = {
    "EVT-001": ("pre_market", "Merck press release timestamped 2018-04-09 05:45 EDT (verified) -- before the open."),
    "EVT-002": ("pre_market", "Biogen/Eisai discontinuation press release issued pre-market 2019-03-21 (widely reported; the stock gapped down at the open). Disclosure-timing, not price-derived."),
    "EVT-003": ("intraday", "FDA accelerated approval announced intraday 2021-06-07; company release same session. (FDA approvals land during/after the session -- procedural.)"),
    "EVT-004": ("after_close", "FDA advisory-committee vote concluded late in the 2016-04-25 public meeting; actionable the next session. (Adcom procedure -- all-day meeting ending late afternoon.)"),
    "EVT-005": ("intraday", "FDA approval 2019-10-21 announced during/after the session (procedural)."),
    "EVT-006": ("pre_market", "Lilly SURMOUNT-1 topline press release 2022-04-28, released pre-market (Lilly convention for material topline data; date verified, exact time not timestamp-checked)."),
    "EVT-007": ("pre_market", "Novo Nordisk SELECT topline company announcement 2023-08-08, released pre-market ET (Copenhagen morning; date verified, exact time not timestamp-checked)."),
}


def main():
    changed = 0
    for f in sorted(glob.glob(os.path.join(HERE, "EVT-*.json"))):
        e = json.load(open(f))
        eid = e.get("event_id")
        if eid in TIMING:
            t, src = TIMING[eid]
            if e.get("disclosure_timing") != t or e.get("disclosure_timing_source") != src:
                e["disclosure_timing"] = t
                e["disclosure_timing_source"] = src
                with open(f, "w") as fh:
                    json.dump(e, fh, indent=2)
                    fh.write("\n")
                changed += 1
    from collections import Counter
    dist = Counter(v[0] for v in TIMING.values())
    print(f"disclosure_timing migration: updated {changed} event(s); distribution {dict(dist)}")


if __name__ == "__main__":
    main()
