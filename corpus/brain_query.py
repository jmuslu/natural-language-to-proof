"""Query the fact brain: retrieval, synthetic inference, and directed exploration.

    python brain_query.py retrieve "does machine learning beat market efficiency?"
    python brain_query.py retrieve "..." --trust-weighted
    python brain_query.py infer    "small-cap value stocks outperform over decades"
    python brain_query.py neighbors 001-1-a
    python brain_query.py explore                 # what to externally check next
    python brain_query.py bridges                 # candidate cross-domain syntheses
    python brain_query.py stats

Retrieval and inference need an embedder for the query text; exploration and
bridges run purely over stored vectors. All exploration output is a PROPOSAL --
the brain surfaces candidates; truth is decided only by external checks.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from brain import Brain

HERE = Path(__file__).resolve().parent
DB = str(HERE / "brain.db")


def _p(obj) -> None:
    print(json.dumps(obj, indent=2, ensure_ascii=False))


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["retrieve", "infer", "neighbors", "explore",
                                    "bridges", "answer", "stats"])
    ap.add_argument("arg", nargs="?", default="")
    ap.add_argument("-k", type=int, default=5)
    ap.add_argument("--mode", choices=["all", "gaps", "contested"], default="all",
                    help="explore: which frontier to show")
    ap.add_argument("--trust-weighted", action="store_true")
    ap.add_argument("--as-of", default=None,
                    help="only use facts knowable by this ISO date (no lookahead)")
    ap.add_argument("--ann", action="store_true", help="use the DiskANN index")
    ap.add_argument("--db", default=DB)
    args = ap.parse_args()

    needs_embedder = args.cmd in ("retrieve", "infer", "answer")
    brain = Brain.open(args.db, load_embedder=needs_embedder)

    if args.cmd == "retrieve":
        facts = brain.retrieve(args.arg, k=args.k, trust_weighted=args.trust_weighted,
                               ann=args.ann, as_of=args.as_of)
        _p([{"id": f.id, "similarity": round(f.similarity, 4),
             "trust": round(f.trust, 4), "domain": f.domain, "text": f.text}
            for f in facts])
    elif args.cmd == "infer":
        _p(brain.infer_trust(args.arg, k=max(args.k, 8), as_of=args.as_of))
    elif args.cmd == "neighbors":
        facts = brain.neighbors(args.arg, k=args.k)
        _p([{"id": f.id, "similarity": round(f.similarity, 4),
             "trust": round(f.trust, 4), "domain": f.domain, "text": f.text}
            for f in facts])
    elif args.cmd == "answer":
        _p(brain.answer(args.arg, k=max(args.k, 8), as_of=args.as_of))
    elif args.cmd == "explore":
        _p(brain.explore_frontier(k=args.k, mode=args.mode))
    elif args.cmd == "bridges":
        _p(brain.bridge_hypotheses(k=args.k))
    elif args.cmd == "stats":
        _p(brain.stats())


if __name__ == "__main__":
    main()
