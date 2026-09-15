"""Turn the brain's exploration into a research agenda — closing the loop.

The brain's directed exploration (`explore_frontier`, `bridge_hypotheses`) says
what is most worth an external check next. This turns those into a structured,
ranked **research agenda**: candidate hypotheses, each carrying the corpus
`claim_refs` it concerns and the rationale for why it is worth checking now. That
agenda feeds the next research step. A strategy's validation receipt concerns
that run's validation gates; source claim references remain attribution and do
not become factual proofs. Missing receipts request reconstruction or a rerun.
The system proposes its next external checks from its current evidence.

Discipline: every item is `status: proposed`. The brain is a proposer of research
directions, never a decider of truth. Which items become live hypotheses is an
owner/external decision; the oracle and reference verdicts still dispose.

    python brain_agenda.py                 # write brain_agenda.json + summary
    python brain_agenda.py --publish PATH   # also copy it where a consumer reads
"""
from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

from brain import Brain
from oracle_bridge import cutoff

HERE = Path(__file__).resolve().parent


def build_agenda(brain: Brain, *, k_gaps: int = 6, k_contested: int = 3,
                 k_bridges: int = 5, as_of: str | None = None) -> dict:
    as_of = cutoff(as_of)
    items = []

    for d in brain.explore_frontier(k=k_gaps, mode="gaps", as_of=as_of):
        if d.get("evidence_basis") == "oracle_receipt" or d.get("claim_type") == "run_validation":
            items.append({
                "kind": "repair_oracle_receipt", "claim_refs": [d["id"]],
                "claim_refs_role": "attribution_only",
                "priority": round(d["centrality"], 4),
                "question": ("Reconstruct the missing validation certificate from retained "
                             "run artifacts, or rerun the backtest with the current validator: "
                             f"{d['text']}"),
                "rationale": ("This statistical run needs a reproducible validation audit "
                              "before its receipt can be confirmed. Referenced source claims "
                              "remain attribution."),
                "domain": d["domain"], "claim_type": d.get("claim_type"),
                "evidence_basis": d.get("evidence_basis"), "status": "proposed"})
        elif d.get("externally_checkable", True):
            items.append({
                "kind": "verify_claim", "claim_refs": [d["id"]],
                "priority": round(d["centrality"], 4),
                "question": f"Externally verify (cite a reference): {d['text']}",
                "rationale": ("unchecked, central, and factually checkable "
                              "(evidence_basis public_reference) — a reference-backed "
                              "verdict here resolves a dense unknown neighbourhood "
                              "(highest leverage)"),
                "domain": d["domain"], "claim_type": d.get("claim_type"),
                "evidence_basis": d.get("evidence_basis"), "status": "proposed"})
        else:
            # central but not factually checkable (opinion/prediction/methodology):
            # it needs an owner/quality judgment, not an external factual verdict.
            items.append({
                "kind": "owner_judgment", "claim_refs": [d["id"]],
                "priority": round(d["centrality"] * 0.6, 4),  # a weaker call to action
                "question": f"Owner/quality judgment (not factually checkable): {d['text']}",
                "rationale": (f"central but evidence_basis '{d.get('evidence_basis')}' "
                              "(claim_type "
                              f"'{d.get('claim_type')}') cannot get an external factual "
                              "verdict; route to the owner/risk-quality axis rather than "
                              "the consistency oracle"),
                "domain": d["domain"], "claim_type": d.get("claim_type"),
                "evidence_basis": d.get("evidence_basis"), "status": "proposed"})

    for d in brain.explore_frontier(k=k_contested, mode="contested", as_of=as_of):
        items.append({
            "kind": "resolve_contested", "claim_refs": [d["id"]],
            "priority": round(d["explore_score"], 4),
            "question": f"Re-check (neighbours disagree): {d['text']}",
            "rationale": (f"already checked (trust {d['trust']:+.2f}) but its semantic "
                          f"neighbours disagree (trust var {d['neighbor_trust_var']}); "
                          "a tie-breaking external check is informative"),
            "domain": d["domain"], "status": "proposed"})

    for b in brain.bridge_hypotheses(k=k_bridges, as_of=as_of):
        items.append({
            "kind": "test_bridge", "claim_refs": [b["a"], b["b"]],
            "priority": round(b["score"], 4),
            "question": (f"Does a connecting hypothesis hold between "
                         f"[{b['a_domain']}] \"{b['a_text']}\" and "
                         f"[{b['b_domain']}] \"{b['b_text']}\"?"),
            "rationale": (f"two externally-trusted claims in different domains "
                          f"({b['a_domain']} / {b['b_domain']}) are semantically "
                          f"adjacent (sim {b['similarity']}) — candidate synthesis"),
            "domains": [b["a_domain"], b["b_domain"]], "status": "proposed"})

    items.sort(key=lambda it: -it["priority"])
    cal = brain.calibrate(as_of=as_of)
    return {
        "generated_by": "brain",
        "note": ("Proposed research agenda from the fact brain's directed exploration. "
                 "Every item is a candidate for external checking, not a verdict. "
                 "claim_refs record attribution to the claims an item concerns. "
                 "A backtest receipt establishes only its run-validation proposition."),
        "as_of": as_of,
        "brain_state": {"n_facts": cal.get("n_predicted"),
                        "frac_unchecked": cal.get("frac_unchecked"),
                        "imputation_licensed": cal.get("licensed")},
        "count": len(items), "items": items}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default=str(HERE / "brain.db"))
    ap.add_argument("--out", default=str(HERE / "brain_agenda.json"))
    ap.add_argument("--publish", default="", help="also copy the agenda to this path")
    ap.add_argument("--as-of", help="include only facts knowable by this UTC date or zoned timestamp")
    args = ap.parse_args()

    brain = Brain.open(args.db, load_embedder=False)
    agenda = build_agenda(brain, as_of=args.as_of)
    Path(args.out).write_text(json.dumps(agenda, indent=2) + "\n")
    print(f"[brain_agenda] {agenda['count']} proposed research items -> {args.out}")
    for it in agenda["items"][:8]:
        print(f"  [{it['priority']:.2f}] {it['kind']:<16} refs={','.join(it['claim_refs'])}")
        print(f"        {it['question'][:88]}")
    if args.publish:
        shutil.copyfile(args.out, args.publish)
        print(f"[brain_agenda] published -> {args.publish}")


if __name__ == "__main__":
    main()
