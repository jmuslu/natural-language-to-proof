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
  E. TEMPORAL as-of retrieval (a fact informs a query at T only if knowable_time<=T;
              no lookahead) + the dated external-event store (TEMPORAL.md).
  F. ORACLE   (other repo, private) the statistical validation suite that turns a
              proposed signal into an external verdict, which flows back to B.

The through-line: each stage either produces something externally checkable or
consumes an external check. Nothing in the loop lets a component certify itself.

    python pipeline.py            # run every runnable stage, narrated
    python pipeline.py --quick    # skip the Haskell ingest (fast, brain-only)
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

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
        # consume the machine-readable artifact (a real handoff, not stdout-scraping)
        r = subprocess.run([exe, "--json"], capture_output=True, text=True, timeout=180)
        d = json.loads(r.stdout)
        ok = d["ill_typed"] == 0
        print(f"  distinct (word,category) entries : {d['distinct_entries']:,}")
        print(f"  built well-typed, corpus-attested: {d['built']:,} "
              f"({d['built_pct_types']}% types, {d['built_pct_tokens']}% tokens)")
        print(f"  rule-handled (coordination)      : {d.get('rule_handled', 0)} "
              "(no lexical type, but the tested coordination rule parses them)")
        print(f"  ill-typed skeletons (MUST be 0)  : {d['ill_typed']}"
              f"   <- external check: mechanical type-check")
        print(f"  => ingestion {'SOUND' if ok else 'BROKEN'}: skeletons are type-checked, "
              "provenance-tagged, ready to become claims.")
        return {"stage": "ingest", "status": "ok" if ok else "broken", **d}
    except Exception as e:  # noqa: BLE001
        print(f"  [skip] ingest unavailable: {type(e).__name__}: {e}")
        return {"stage": "ingest", "status": "skipped", "error": str(e)}


def stage_graph(receipts, runtime) -> dict:
    banner("B", "GRAPH -- corpus records + external verdicts -> trust")
    from ingest_outcomes import materialize, graph_document, augmented_index
    graph, _ = materialize(receipts)
    g = graph_document(graph)
    (runtime / "graph.json").write_text(json.dumps(g, indent=2))
    (runtime / "claims_index.json").write_text(json.dumps(augmented_index(receipts), indent=2))
    s = g["summary"]
    claim_trust = [n["trust"] for n in g["nodes"] if n["kind"] == "claim"]
    checked = sum(1 for t in claim_trust if t != 0.0)
    print(f"  nodes {s['nodes']}  edges {s['edges']}  by_kind {s['by_kind']}")
    print(f"  claims with nonzero evidence scores: {checked}/{len(claim_trust)}")
    print("  => oracle receipts concern run-validation propositions only; source references "
          "remain attribution. Existing reference/owner scores retain their provenance.")
    return {"stage": "graph", "status": "ok", "nodes": s["nodes"], "edges": s["edges"],
            "checked": checked, "claims": len(claim_trust)}


def stage_brain(runtime, embedder="model2vec", as_of=None) -> tuple[dict, object]:
    banner("C", "BRAIN -- embed claims into libSQL vector store + grade the manifold")
    from brain import Brain
    brain = Brain.build(str(runtime / "claims_index.json"), str(runtime / "graph.json"),
                        str(runtime / "brain.db"), prefer=embedder)
    st = brain.stats(as_of=as_of)
    cal = brain.calibrate(as_of=as_of)
    lc = brain.learning_curve(as_of=as_of)
    print(f"  {st['n_facts']} facts, dim {st['dim']}, embedder {st['embedder_id']}")
    print(f"  calibration @k={cal.get('preregistered_k')}: skill={cal.get('skill')} "
          f"pearson_r={cal.get('pearson_r')} sign_agreement={cal.get('sign_agreement')}")
    print(f"  imputation licensed? {cal.get('licensed', False)} -- {cal.get('verdict', 'insufficient data')}")
    print(f"  checked-only (n={cal.get('n_checked', 0)}): skill={cal.get('checked_only', {}).get('skill')}")
    print("  learning curve (skill as #external-checks grows; real trust only):")
    for pt in lc["curve"]:
        ms = pt["mean_skill"]
        print(f"      m={pt['m']:>2}  mean_skill={ms:+.4f}" if ms is not None
              else f"      m={pt['m']:>2}  mean_skill=n/a")
    pts = [p["mean_skill"] for p in lc["curve"] if p["mean_skill"] is not None]
    if len(pts) >= 2:
        trend = "rises overall" if pts[-1] > pts[0] else "does not rise"
        strict = " and monotonically" if lc["monotone_up"] else " (not strictly monotone on this small sample)"
        print(f"  skill {trend} ({pts[0]:+.3f} -> {pts[-1]:+.3f}){strict}  => more external "
              "checks tend to make synthetic inference more licensed.")
    return {"stage": "brain", "status": "ok", "calibration": cal, "learning_curve": lc}, brain


def stage_retrieve_explore(brain: Brain, as_of=None) -> dict:
    banner("D", "RETRIEVE + EXPLORE -- semantic recall and directed exploration")
    q = "can machine learning beat the market despite efficiency?"
    print(f"  retrieve (trust-weighted) <- \"{q}\"")
    for f in brain.retrieve(q, k=3, trust_weighted=True, as_of=as_of):
        print(f"      [{f.trust:+.2f} trust | sim {f.similarity:.2f}] {f.text[:66]}")
    print("  explore frontier (gaps: unchecked & central -> highest-leverage checks):")
    for d in brain.explore_frontier(k=3, mode="gaps", as_of=as_of):
        print(f"      [{d['centrality']:.2f} central] {d['text'][:66]}")
    print("  explore frontier (contested: checked, neighbours disagree):")
    for d in brain.explore_frontier(k=2, mode="contested", as_of=as_of):
        print(f"      [{d['trust']:+.2f} trust, var {d['neighbor_trust_var']:.2f}] {d['text'][:60]}")
    print("  bridge hypotheses (two trusted facts, different domains, mid-distance):")
    for p in brain.bridge_hypotheses(k=2, as_of=as_of):
        print(f"      {p['a_domain']} <-> {p['b_domain']} (sim {p['similarity']:.2f}):")
        print(f"        A: {p['a_text'][:60]}")
        print(f"        B: {p['b_text'][:60]}")
    print("  synthesis (answer: retrieval + inference + exploration, cited & gated):")
    for aq in ("can machine learning reliably beat the market?",
               "is a paper loss a real loss even if I do not sell?"):
        a = brain.answer(aq, as_of=as_of)
        print(f"      Q: {aq}")
        print(f"        stance: {a['stance']}  (checked {a.get('n_checked', 0)}/{a.get('n_relevant', 0)} "
              f"relevant, licensed_locally={a.get('licensed_locally', False)})")
        if a.get("proposed_next_check"):
            print(f"        next external check -> {a['proposed_next_check']['text'][:56]}")
    print("  => every item above is a PROPOSAL for an external check, never a verdict.")
    # the loop-closer: exploration becomes a ranked research agenda that feeds the
    # TOP of the loop (each item carries claim_refs so outcomes reverse-propagate).
    from brain_agenda import build_agenda
    ag = build_agenda(brain, as_of=as_of)
    print(f"  research agenda: {ag['count']} proposed items feed back to new hypotheses:")
    for it in ag["items"][:3]:
        print(f"      [{it['priority']:.2f}] {it['kind']} (refs {','.join(it['claim_refs'])})")
    return {"stage": "retrieve_explore", "status": "ok", "agenda_items": ag["count"]}


def stage_temporal(brain: Brain) -> dict:
    banner("E", "TEMPORAL -- as-of retrieval (no lookahead) + the dated event store")
    q = "is a paper loss a real loss even if I do not sell?"
    # record 005 (the mark-to-market source) published 2024-04-17; ask before vs after
    before = brain.answer(q, as_of="2024-03-01")
    after = brain.answer(q, as_of="2024-06-01")
    print(f"  answer as-of 2024-03-01 (before source 005 published): stance "
          f"{before['stance']} ({before.get('n_relevant', 0)} relevant facts knowable)")
    print(f"  answer as-of 2024-06-01 (after 005 published 2024-04-17): stance "
          f"{after['stance']} ({after.get('n_relevant', 0)} relevant facts knowable)")
    print("  => the brain answers 'what did we know as of T' -- knowable_time <= T only.")
    ev = ROOT / "corpus" / "events"
    n_events = 0
    try:
        import sys as _sys
        _sys.path.insert(0, str(ev))
        import build_events  # type: ignore
        events = build_events.load_events()
        n_events = len(events)
        for e in events[:3]:
            print(f"  event {e['event_id']} [{e['ticker']}] knowable {e['knowable_time']}"
                  f" (event {e['event_time']}): {e['description'][:52]}")
        print("  => events carry attested knowable_time; feed event_study.align_to_next_bar")
    except Exception as e:  # noqa: BLE001
        print(f"  [skip] event store: {e}")
    return {"stage": "temporal", "status": "ok", "events": n_events}


def stage_oracle(paths, oracle_repo, runtime, as_of=None):
    from collections import Counter
    from oracle_bridge import ReceiptLedger, load_evaluator, verify_haskell
    from ingest_outcomes import revision_report
    banner("F", "ORACLE -- audit result files, replay revisions, verify Haskell handoff")
    ledger = ReceiptLedger(runtime / "oracle.sqlite")
    try:
        before = ledger.snapshots()
        actions = ledger.ingest_files(paths, load_evaluator(oracle_repo)) if paths else []
        current = ledger.snapshots()
        receipts = ledger.snapshots(as_of)
        hs = verify_haskell(receipts, runtime / "receipts.tsv", ROOT)
        report = {"stage": "oracle", "status": "ok", "input_files": len(paths),
                  "actions": dict(Counter(r["action"] for r in actions)),
                  "verdicts": dict(Counter(r["verdict"] for r in receipts)),
                  "reasons": dict(Counter(r["reason"] for r in receipts)),
                  "support_changes": revision_report(before, current),
                  "as_of": as_of, "haskell": hs}
        print(f"  {len(paths)} files, {len(receipts)} active run receipts; {report['verdicts']}")
        print(f"  journal actions: {report['actions']}; reasons: {report['reasons']}")
        print(f"  Haskell fused claims: {hs['fused_claims']}; reward: {hs['reward']}")
        (runtime / "oracle_report.json").write_text(json.dumps(report, indent=2))
        return report, receipts
    finally:
        ledger.close()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--quick", action="store_true", help="skip the Haskell ingest stage")
    ap.add_argument("--oracle-only", action="store_true", help="run receipt/graph/Haskell integration without embedding dependencies")
    ap.add_argument("--oracle-repo", type=Path, default=Path.home() / "projects")
    ap.add_argument("--results", nargs="*", type=Path, help="explicit result files; no values means replay only")
    ap.add_argument("--results-dir", type=Path, help="read result_*.json from this directory")
    ap.add_argument("--runtime-dir", type=Path, default=HERE / "runtime")
    ap.add_argument("--as-of", help="replay only revisions observed by this UTC date/timestamp")
    ap.add_argument("--embedder", choices=("model2vec", "hashing"), default="model2vec")
    args = ap.parse_args()
    if args.results is not None and args.results_dir is not None:
        ap.error("choose --results or --results-dir")
    runtime = args.runtime_dir.expanduser().resolve()
    runtime.mkdir(parents=True, exist_ok=True)
    directory = args.results_dir or args.oracle_repo / "shared/backtesting/results"
    paths = args.results if args.results is not None else sorted(directory.glob("result_*.json"))
    print("CONNECTED SYSTEM -- end-to-end operational run")
    print("discipline: no component certifies itself; trust comes only from external checks.")
    results = []
    if not args.quick and not args.oracle_only:
        results.append(stage_ingest())
    oracle, receipts = stage_oracle(paths, args.oracle_repo, runtime, args.as_of)
    results.append(oracle)
    results.append(stage_graph(receipts, runtime))
    if not args.oracle_only:
        r_brain, brain = stage_brain(runtime, args.embedder, args.as_of)
        try:
            results.append(r_brain)
            results.append(stage_retrieve_explore(brain, args.as_of))
            if args.as_of is None:
                results.append(stage_temporal(brain))
        finally:
            brain.con.close()
    (runtime / "pipeline_report.json").write_text(json.dumps(results, indent=2))
    print(f"\n{'='*72}\n  RUN COMPLETE -- "
          + ", ".join(f"{r['stage']}:{r['status']}" for r in results)
          + "\n" + "=" * 72)


if __name__ == "__main__":
    main()
