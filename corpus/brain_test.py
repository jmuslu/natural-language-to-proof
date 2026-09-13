"""Tests for the fact brain. Uses the deterministic hashing embedder so the whole
suite runs offline with no model download -- the model2vec path is exercised
separately by `brain_build.py`. Run: `.venv/bin/python brain_test.py`.

These are external checks on the brain code: that it copies trust verbatim from the
graph (never inventing it), that retrieval/neighbours/bridges obey their contracts,
that calibration reports the honest licensing verdict, and that builds are
reproducible. If any assertion trips, the brain is not behaving as documented.
"""
from __future__ import annotations

import json
import tempfile
from pathlib import Path

import numpy as np

from brain import Brain

HERE = Path(__file__).resolve().parent
CLAIMS = str(HERE / "claims_index.json")
GRAPH = str(HERE / "graph.json")
_checks = 0


def check(cond, msg):
    global _checks
    assert cond, "FAIL: " + msg
    _checks += 1


def _build(tmp) -> Brain:
    return Brain.build(CLAIMS, GRAPH, str(Path(tmp) / "t.db"), prefer="hashing")


def main() -> None:
    ci = json.loads(Path(CLAIMS).read_text())["claims"]
    graph = json.loads(Path(GRAPH).read_text())
    trust_by_id = {n["id"].split(":", 1)[1]: float(n["trust"])
                   for n in graph["nodes"] if n["kind"] == "claim"}

    with tempfile.TemporaryDirectory() as tmp:
        b = _build(tmp)
        st = b.stats()

        # --- build / trust provenance ---
        check(st["n_facts"] == len(ci), f"n_facts {st['n_facts']} != {len(ci)}")
        check(st["embedder_id"].startswith("hashing"), "expected hashing embedder")
        ids, E, trusts, meta = b._all()
        check(E.shape == (len(ci), st["dim"]), f"emb shape {E.shape}")
        check(np.allclose(np.linalg.norm(E, axis=1), 1.0, atol=1e-4), "vectors not unit-norm")
        # trust must equal the graph verbatim -- the brain never invents trust
        for cid, tr in zip(ids, trusts):
            check(abs(tr - trust_by_id[cid]) < 1e-9,
                  f"trust for {cid} = {tr} != graph {trust_by_id[cid]}")

        # --- retrieval: a claim's own text retrieves that claim first ---
        probe = ids[3]
        top = b.retrieve(meta[3]["text"], k=1)
        check(top and top[0].id == probe, f"self-retrieval got {top[0].id if top else None} != {probe}")
        check(0.0 <= top[0].similarity <= 1.0001, "similarity out of range")

        # --- neighbours: excludes self, k distinct ---
        nb = b.neighbors(probe, k=5)
        check(len(nb) == 5 and probe not in {f.id for f in nb}, "neighbours bad")
        check(len({f.id for f in nb}) == 5, "neighbours not distinct")

        # --- inference: labelled conjecture, carries the licensing caveat ---
        inf = b.infer_trust("machine learning predicts stock returns", k=8)
        check(inf["status"] == "conjectured", "inference not labelled conjecture")
        check("imputation_licensed" in inf and "caveat" in inf, "inference missing caveat")
        check(isinstance(inf["predicted_trust"], float), "predicted_trust not float")

        # --- answer: grounded synthesis obeys the discipline ---
        ans = b.answer(meta[3]["text"], k=8)  # a claim's own text -> guaranteed matches
        allowed = {"supported_by_checked_evidence", "contradicted_or_cautioned",
                   "mixed_or_weak", "insufficiently_checked", "unknown_no_checked_evidence",
                   "no_relevant_facts"}
        check(ans["stance"] in allowed, f"bad stance {ans['stance']}")
        check("caveat" in ans, "answer missing caveat")
        if ans["stance"] != "no_relevant_facts":
            check(all(f["trust"] > 0 for f in ans["supporting"]), "supporting not all trust>0")
            check(all(f["trust"] < 0 for f in ans["cautioning"]), "cautioning not all trust<0")
            check(all(f["trust"] == 0 for f in ans["unchecked_relevant"]), "unchecked not all 0")
            cited = ans["supporting"] + ans["cautioning"] + ans["unchecked_relevant"]
            check(all(f["similarity"] >= ans["min_sim"] for f in cited),
                  "a cited fact is below the relevance floor")
            if ans["licensed_locally"]:
                check(ans["n_checked"] >= 2 and ans["checked_fraction"] >= 0.6,
                      "licensed_locally without >=2 checked and majority")
        # a query that matches nothing returns the honest empty stance
        none_ans = b.answer("zzqx wuvt gibberish nonexistent token cluster", k=8)
        check(none_ans["stance"] in ("no_relevant_facts", "unknown_no_checked_evidence",
                                     "insufficiently_checked"),
              f"nonsense query gave {none_ans['stance']}")

        # --- temporal: knowable_time stored; as-of retrieval has no lookahead ---
        check(all("knowable_time" in m for m in meta), "facts missing knowable_time")
        # every fact carries a knowable_time (from its source's publication date)
        kts = [m["knowable_time"] for m in meta if m["knowable_time"]]
        check(len(kts) == len(meta), "some fact has no knowable_time")
        latest = max(kts)
        earliest = min(kts)
        probe_q = meta[0]["text"]
        # as-of before the earliest source: nothing is knowable yet
        before = b.retrieve(probe_q, k=10, as_of="1900-01-01")
        check(before == [], "as-of before all sources leaked a fact (lookahead!)")
        # as-of at the latest date: everything visible; equals no-filter count
        allf = b.retrieve(probe_q, k=54)
        asof_all = b.retrieve(probe_q, k=54, as_of=latest)
        check(len(asof_all) == len(allf), "as-of at latest date should see all facts")
        # every fact returned under an as-of query is genuinely knowable by then
        mid = b.retrieve(probe_q, k=54, as_of=earliest)
        check(all(f.id for f in mid), "as-of query returned malformed facts")
        idkt = {m["id"]: m["knowable_time"] for m in meta}
        check(all(idkt[f.id] <= earliest for f in mid), "as-of returned a future fact")
        # answer carries the as_of it was given
        ans_t = b.answer(probe_q, as_of=latest)
        check(ans_t.get("as_of") == latest, "answer did not record as_of")

        # --- calibration: honest verdict + frac_unchecked matches the field ---
        cal = b.calibrate()
        exp_unchecked = round(float(np.mean(trusts == 0.0)), 4)
        check(cal["frac_unchecked"] == exp_unchecked, "frac_unchecked mismatch")
        check(isinstance(cal["licensed"], bool), "licensed not bool")
        check("verdict" in cal and "checked_only" in cal, "calibration missing fields")
        # the licensing bar must actually gate: verify it agrees with the metrics
        lic, _ = Brain._licensed(cal)
        check(lic == cal["licensed"], "licensed flag disagrees with _licensed()")

        # --- exploration frontier: modes obey their contracts ---
        gaps = b.explore_frontier(k=6, mode="gaps")
        check(all(not d["checked"] for d in gaps), "gaps mode returned a checked fact")
        check(all(d["trust"] == 0.0 for d in gaps), "gaps mode fact had nonzero trust")
        contested = b.explore_frontier(k=6, mode="contested")
        check(all(d["checked"] for d in contested), "contested mode returned unchecked")
        check(all(d["status"] == "proposed_to_check" for d in gaps + contested),
              "frontier not labelled proposal")

        # --- bridges: cross-domain, both endpoints trusted, mid-distance ---
        br = b.bridge_hypotheses(k=8, trust_min=0.3, lo=0.25, hi=0.75)
        for p in br:
            check(p["a_domain"] != p["b_domain"], "bridge within one domain")
            check(0.25 < p["similarity"] < 0.75, "bridge similarity outside band")
            check(p["min_trust"] >= 0.3, "bridge endpoint below trust_min")
            check(p["status"] == "proposed_hypothesis", "bridge not labelled proposal")

        # --- research agenda: closes the loop, obeys the proposer discipline ---
        from brain_agenda import build_agenda
        ag = build_agenda(b, k_gaps=5, k_contested=3, k_bridges=5)
        check(ag["generated_by"] == "brain", "agenda not attributed to brain")
        check(ag["count"] == len(ag["items"]), "agenda count mismatch")
        prios = [it["priority"] for it in ag["items"]]
        check(prios == sorted(prios, reverse=True), "agenda not sorted by priority")
        known = set(ids)
        for it in ag["items"]:
            check(it["status"] == "proposed", "agenda item not a proposal")
            check(it["kind"] in {"verify_claim", "resolve_contested", "test_bridge",
                                 "owner_judgment"}, f"bad agenda kind {it['kind']}")
            check(it["claim_refs"] and all(r in known for r in it["claim_refs"]),
                  "agenda item cites unknown claim ref")
            if it["kind"] == "test_bridge":
                check(len(it["claim_refs"]) == 2, "bridge item must cite two claims")
            # checkability routing is by evidence_basis (public_reference == checkable),
            # orthogonal to claim_type: factual gaps -> verify_claim, others -> owner_judgment
            if it["kind"] == "verify_claim" and "evidence_basis" in it:
                check(it["evidence_basis"] == "public_reference",
                      f"verify_claim routed non-public_reference {it['evidence_basis']}")
            if it["kind"] == "owner_judgment":
                check(it["evidence_basis"] != "public_reference",
                      f"owner_judgment routed a public_reference claim")

    # --- reproducibility: hashing build is deterministic ---
    with tempfile.TemporaryDirectory() as t1, tempfile.TemporaryDirectory() as t2:
        _, E1, tr1, _ = _build(t1)._all()
        _, E2, tr2, _ = _build(t2)._all()
        check(np.allclose(E1, E2) and np.allclose(tr1, tr2), "hashing build not reproducible")

    print(f"brain_test: PASS ({_checks} checks)")


if __name__ == "__main__":
    main()
