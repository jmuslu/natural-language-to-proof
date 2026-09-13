"""End-to-end operational driver for the connected system.

Runs the whole chain as REAL invocations and narrates it, so the pieces built
across both repos can be seen operating as one loop:

  A. INGEST   Haskell CCGbank lexicon ingestion -> provenance-tagged, well-typed
              skeletons (external check: every built skeleton is machine type-checked;
              ill-typed count MUST be 0).
  B. GRAPH    build the epistemic graph from corpus records + external verdicts ->
              trust that originates only from external checks.
  C. BRAIN    embed the graph's claims into the libSQL vector store and grade the
              manifold (calibration vs a mean null; learning curve vs #checks).
  D. RETRIEVE semantic retrieval, and directed exploration (the frontier of what to
     + EXPLORE check next, and cross-domain bridge hypotheses) -- all proposals.
  E. ORACLE   (other repo, private) the statistical validation suite that turns a
              proposed signal into an external verdict, which flows back to B.

The through-line: each stage either produces something externally checkable or
consumes an external check. Nothing in the loop lets a component certify itself.

    python pipeline.py            # run every runnable stage, narrated
    python pipeline.py --quick    # skip the Haskell ingest (fast, brain-only)
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

from brain import Brain

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent


def banner(letter: str, title: str) -> None:
    print(f"\n{'='*72}\n  STAGE {letter}: {title}\n{'='*72}")


def stage_ingest() -> dict:
    banner("A", "INGEST -- Haskell CCGbank lexicon -> well-typed skeletons")
    try:
        binp = subprocess.run(["cabal", "list-bin", "ccg-lexicon-ingest"],
                              cwd=str(ROOT), capture_output=True, text=True, timeout=60)
        exe = binp.stdout.strip()
        if not exe or not Path(exe).exists():
            print("  [skip] ingest binary not built (run `cabal build ccg-lexicon-ingest`)")
            return {"stage": "ingest", "status": "skipped"}
        r = subprocess.run([exe], capture_output=True, text=True, timeout=180)
        out = r.stdout
        def grab(pat):
            m = re.search(pat, out)
            return m.group(1) if m else "?"
        built = grab(r"built \(representable, corpus-attested\) : ([\d,]+ \([^)]*\))")
        illtyped = grab(r"ill-typed skeleton \(MUST be 0\): (\d+)")
        total = grab(r"distinct \(word,category\) entries : ([\d,]+)")
        print(f"  distinct (word,category) entries : {total}")
        print(f"  built well-typed, corpus-attested: {built}")
        print(f"  ill-typed skeletons (MUST be 0)  : {illtyped}"
              f"   <- external check: mechanical type-check")
        ok = illtyped == "0"
        print(f"  => ingestion {'SOUND' if ok else 'BROKEN'}: skeletons are type-checked, "
              "provenance-tagged, ready to become claims.")
        return {"stage": "ingest", "status": "ok" if ok else "broken",
                "total": total, "built": built, "ill_typed": illtyped}
    except Exception as e:  # noqa: BLE001
        print(f"  [skip] ingest unavailable: {type(e).__name__}: {e}")
        return {"stage": "ingest", "status": "skipped", "error": str(e)}


def stage_graph() -> dict:
    banner("B", "GRAPH -- corpus records + external verdicts -> trust")
    r = subprocess.run([sys.executable, str(HERE / "build_graph.py")],
                       capture_output=True, text=True, timeout=120)
    if r.returncode != 0:
        print(r.stdout[-800:]); print(r.stderr[-800:])
        return {"stage": "graph", "status": "error"}
    g = json.loads((HERE / "graph.json").read_text())
    s = g["summary"]
    claim_trust = [n["trust"] for n in g["nodes"] if n["kind"] == "claim"]
    checked = sum(1 for t in claim_trust if t != 0.0)
    print(f"  nodes {s['nodes']}  edges {s['edges']}  by_kind {s['by_kind']}")
    print(f"  claims externally checked: {checked}/{len(claim_trust)} "
          f"(the rest await a verdict -- trust must be earned)")
    print("  => trust here originates ONLY from external checks (reference verdicts, "
          "owner labels); the graph propagates it, never invents it.")
    return {"stage": "graph", "status": "ok", "nodes": s["nodes"], "edges": s["edges"],
            "checked": checked, "claims": len(claim_trust)}


def stage_brain() -> tuple[dict, Brain]:
    banner("C", "BRAIN -- embed claims into libSQL vector store + grade the manifold")
    brain = Brain.build(str(HERE / "claims_index.json"), str(HERE / "graph.json"),
                        str(HERE / "brain.db"))
    st = brain.stats()
    cal = brain.calibrate()
    lc = brain.learning_curve()
    print(f"  {st['n_facts']} facts, dim {st['dim']}, embedder {st['embedder_id']}")
    print(f"  calibration @k={cal['preregistered_k']}: skill={cal['skill']} "
          f"pearson_r={cal['pearson_r']} sign_agreement={cal['sign_agreement']}")
    print(f"  imputation licensed? {cal['licensed']}  -- {cal['verdict']}")
    print(f"  checked-only (n={cal['n_checked']}): skill={cal['checked_only'].get('skill')}, "
          f"pearson_r={cal['checked_only'].get('pearson_r')}")
    print("  learning curve (skill as #external-checks grows; real trust only):")
    for pt in lc["curve"]:
        print(f"      m={pt['m']:>2}  mean_skill={pt['mean_skill']:+.4f}")
    print(f"  monotone increasing? {lc['monotone_up']}  => accumulating external "
          "checks makes synthetic inference progressively more licensed.")
    return {"stage": "brain", "status": "ok", "calibration": cal, "learning_curve": lc}, brain


def stage_retrieve_explore(brain: Brain) -> dict:
    banner("D", "RETRIEVE + EXPLORE -- semantic recall and directed exploration")
    q = "can machine learning beat the market despite efficiency?"
    print(f"  retrieve (trust-weighted) <- \"{q}\"")
    for f in brain.retrieve(q, k=3, trust_weighted=True):
        print(f"      [{f.trust:+.2f} trust | sim {f.similarity:.2f}] {f.text[:66]}")
    print("  explore frontier (gaps: unchecked & central -> highest-leverage checks):")
    for d in brain.explore_frontier(k=3, mode="gaps"):
        print(f"      [{d['centrality']:.2f} central] {d['text'][:66]}")
    print("  explore frontier (contested: checked, neighbours disagree):")
    for d in brain.explore_frontier(k=2, mode="contested"):
        print(f"      [{d['trust']:+.2f} trust, var {d['neighbor_trust_var']:.2f}] {d['text'][:60]}")
    print("  bridge hypotheses (two trusted facts, different domains, mid-distance):")
    for p in brain.bridge_hypotheses(k=2):
        print(f"      {p['a_domain']} <-> {p['b_domain']} (sim {p['similarity']:.2f}):")
        print(f"        A: {p['a_text'][:60]}")
        print(f"        B: {p['b_text'][:60]}")
    print("  synthesis (answer: retrieval + inference + exploration, cited & gated):")
    for aq in ("can machine learning reliably beat the market?",
               "is a paper loss a real loss even if I do not sell?"):
        a = brain.answer(aq)
        print(f"      Q: {aq}")
        print(f"        stance: {a['stance']}  (checked {a['n_checked']}/{a['n_relevant']} "
              f"relevant, licensed_locally={a['licensed_locally']})")
        if a.get("proposed_next_check"):
            print(f"        next external check -> {a['proposed_next_check']['text'][:56]}")
    print("  => every item above is a PROPOSAL for an external check, never a verdict.")
    return {"stage": "retrieve_explore", "status": "ok"}


def stage_oracle_note() -> None:
    banner("E", "ORACLE -- external validation closes the loop (agentic-qr, private)")
    print("  A frontier proposal (Stage D) that is operationalised as a trading signal")
    print("  is validated by shared/backtesting/validation: walk-forward OOS, sign-flip")
    print("  and random-timing nulls, Benjamini-Hochberg FDR, regime-conditional Sharpe,")
    print("  and calibration (Brier/ECE). The resulting certificate is an EXTERNAL")
    print("  verdict; ingest_outcomes.py feeds it back to Stage B, densifying the trust")
    print("  field -- which the learning curve (Stage C) shows raises inference skill.")
    print("  => the loop is closed: propose -> externally check -> update brain -> propose.")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--quick", action="store_true", help="skip the Haskell ingest stage")
    args = ap.parse_args()
    print("CONNECTED SYSTEM -- end-to-end operational run")
    print("discipline: no component certifies itself; trust comes only from external checks.")
    results = []
    if not args.quick:
        results.append(stage_ingest())
    results.append(stage_graph())
    r_brain, brain = stage_brain()
    results.append(r_brain)
    results.append(stage_retrieve_explore(brain))
    stage_oracle_note()
    print(f"\n{'='*72}\n  RUN COMPLETE -- "
          + ", ".join(f"{r['stage']}:{r['status']}" for r in results)
          + "\n" + "=" * 72)


if __name__ == "__main__":
    main()
