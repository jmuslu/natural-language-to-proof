"""Build (or rebuild) the fact brain from the current corpus and epistemic graph.

    python brain_build.py                 # model2vec if available, else hashing
    python brain_build.py --hashing       # force the deterministic offline backend

Writes brain.db (the libSQL vector store, gitignored -- a build artifact) and
brain_manifest.json (committed, human-readable: embedder, dim, counts, and the
calibration result that says whether synthetic inference is licensed).
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from brain import Brain

HERE = Path(__file__).resolve().parent


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--claims", default=str(HERE / "claims_index.json"))
    ap.add_argument("--graph", default=str(HERE / "graph.json"))
    ap.add_argument("--db", default=str(HERE / "brain.db"))
    ap.add_argument("--manifest", default=str(HERE / "brain_manifest.json"))
    ap.add_argument("--hashing", action="store_true",
                    help="force deterministic hashing embedder (offline)")
    args = ap.parse_args()

    brain = Brain.build(args.claims, args.graph, args.db,
                        prefer="hashing" if args.hashing else "model2vec")
    stats = brain.stats()
    cal = brain.calibrate()

    manifest = {"brain": stats, "calibration": cal,
                "inputs": {"claims_index": Path(args.claims).name,
                           "graph": Path(args.graph).name},
                "note": ("Trust is copied verbatim from the epistemic graph "
                         "(external checks only). 'calibration.licensed' says whether "
                         "semantic neighbours predict that trust well enough (honest "
                         "bar in brain.Brain._licensed) to impute trust from topic. "
                         "When false, the brain uses semantics for retrieval and "
                         "exploration only, and refuses to impute trust.")}
    Path(args.manifest).write_text(json.dumps(manifest, indent=2) + "\n")

    print(f"[brain_build] built {stats['n_facts']} facts, dim={stats['dim']}, "
          f"embedder={stats['embedder_id']}")
    print(f"[brain_build] trust range [{stats['trust_min']}, {stats['trust_max']}] "
          f"mean {stats['trust_mean']} across {stats['domains']} domains; "
          f"{cal.get('frac_unchecked')} unchecked (trust==0)")
    print(f"[brain_build] calibration @k={cal.get('preregistered_k')}: "
          f"MAE={cal.get('mae')} vs baseline {cal.get('mae_baseline')} "
          f"(skill={cal.get('skill')}), pearson_r={cal.get('pearson_r')}, "
          f"sign_agreement={cal.get('sign_agreement')}")
    co = cal.get("checked_only", {})
    print(f"[brain_build] checked-only (n={cal.get('n_checked')}): "
          f"skill={co.get('skill')}, pearson_r={co.get('pearson_r')}")
    if cal.get("licensed"):
        print(f"[brain_build] -> trust-imputation LICENSED: {cal.get('verdict')} "
              "(still graded, never decisive).")
    else:
        print(f"[brain_build] -> trust-imputation NOT licensed: {cal.get('verdict')}.")
        print("[brain_build]    brain uses semantics for RETRIEVAL + EXPLORATION only.")
    print(f"[brain_build] manifest -> {args.manifest}")


if __name__ == "__main__":
    main()
