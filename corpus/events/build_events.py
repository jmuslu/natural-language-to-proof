#!/usr/bin/env python3
"""Validate and load the dated event store for the temporal / event-study track.

Each event carries externally-attested bitemporal stamps (TEMPORAL.md). This script
validates them against the schema's controlled vocabularies, checks the dates are
ISO and that the load-bearing `knowable_time` is present, and exposes `load_events`
/ `as_of_events` for the event-study driver (agentic-qr `event_study.py`) to consume
under the no-lookahead discipline. Pure standard library.

    python build_events.py            # validate + summarise
    python build_events.py --selftest # prove the validator + as-of filter
"""
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ISO = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def _schema():
    return json.load(open(os.path.join(HERE, "event_schema.json")))


def load_events():
    return [json.load(open(f))
            for f in sorted(glob.glob(os.path.join(HERE, "EVT-*.json")))]


def validate(events, schema):
    vocab = schema["controlled_vocabularies"]
    errs = []
    for e in events:
        eid = e.get("event_id", "?")
        for field in ("event_id", "description", "source", "sponsor", "event_type",
                      "event_time", "knowable_time", "evidence_basis"):
            if not e.get(field):
                errs.append(f"{eid}: missing {field}")
        if e.get("event_type") not in vocab["event_type"]:
            errs.append(f"{eid}: bad event_type {e.get('event_type')}")
        if e.get("evidence_basis") not in vocab["evidence_basis"]:
            errs.append(f"{eid}: bad evidence_basis {e.get('evidence_basis')}")
        for d in ("event_time", "knowable_time"):
            if e.get(d) and not ISO.match(e[d]):
                errs.append(f"{eid}: {d} not ISO ({e[d]})")
        # knowable_time is load-bearing: without it the event cannot enter an as-of
        # study at all. It must be attested (evidence_basis public_reference).
        if e.get("knowable_time") and e.get("evidence_basis") != "public_reference":
            errs.append(f"{eid}: knowable_time present but evidence_basis not public_reference")
    return errs


def as_of_events(as_of, events=None):
    """Events knowable by `as_of` (knowable_time <= as_of); the no-lookahead filter
    the event study applies before aligning to price windows."""
    events = events if events is not None else load_events()
    return [e for e in events
            if e.get("knowable_time") and e["knowable_time"] <= as_of]


def main():
    schema = _schema()
    events = load_events()
    errs = validate(events, schema)
    if "--selftest" in sys.argv:
        assert not errs, f"validation errors: {errs}"
        assert events, "no events to test"
        import datetime as _dt
        e0 = events[0]
        kt = e0["knowable_time"]
        assert as_of_events("1900-01-01", events) == [], "as-of before all events leaked one"
        assert e0 in as_of_events(kt, events), "event not visible on its knowable date"
        # no lookahead: the event is invisible the day before it became knowable.
        # Use real date arithmetic (string slicing breaks on the 1st of a month).
        before = (_dt.date.fromisoformat(kt) - _dt.timedelta(days=1)).isoformat()
        assert e0 not in as_of_events(before, events), "event visible before it was knowable!"
        print(f"build_events selftest: PASS ({len(events)} events valid; "
              "as-of filter enforces no lookahead)")
        return
    if errs:
        print("VALIDATION ERRORS:")
        for e in errs:
            print("  -", e)
        sys.exit(1)
    print(f"event store: {len(events)} event(s), all valid")
    from collections import Counter
    print("by type:", dict(Counter(e["event_type"] for e in events)))
    print("tickers:", sorted({e.get("ticker") for e in events if e.get("ticker")}))
    for e in events:
        print(f"  {e['event_id']}  {e['ticker'] or '-':<6} knowable {e['knowable_time']}"
              f"  event {e['event_time']}  {e['event_type']}")


if __name__ == "__main__":
    main()
