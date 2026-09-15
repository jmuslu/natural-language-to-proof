"""The retrieval store cannot promote proposals or attribution into evidence."""
import copy
import json
import tempfile
import unittest
from pathlib import Path

from brain import Brain
from brain_agenda import build_agenda
from brain_evidence import observation, validation_text
from epistemic_graph import EpistemicGraph
from ingest_outcomes import augmented_index, graph_document, ingest_receipt, materialize
from oracle_bridge import ReceiptLedger, SCHEMA

EARLY = "2026-09-14T12:00:00Z"
LATE = "2026-09-15T12:00:00Z"


def receipt(rid, verdict="confirmed", observed=EARLY):
    # An independently stipulated receipt fixture, not a model-produced verdict.
    return {"schema": SCHEMA, "run_id": rid, "verdict": verdict,
            "proposition": {"kind": "passes_validation", "run_id": rid},
            "evidence_id": "fixture:" + rid, "observed_at": observed,
            "reason": "fixture", "claim_refs": ["source-claim"]}


def snapshot(receipts, *, pending=True):
    graph = EpistemicGraph()
    index = {"claims": {}}
    if pending:
        graph.add_node("claim:source-claim", "claim", {"verification_status": "not_performed"})
        graph.add_node("ref:proposal", "reference",
                       {"verification_status": "agent_proposed_pending_owner_confirmation"}, seed=.9)
        graph.add_edge("ref:proposal", "claim:source-claim", "supports")
        index["claims"]["source-claim"] = {
            "text": "Backtest run source-claim passed its declared validation gates.",
            "source_id": "source", "claim_type": "factual_quantitative",
            "evidence_basis": "public_reference", "domain": "source",
            "knowable_time": EARLY, "verification_status": "not_performed"}
    for r in receipts:
        ingest_receipt(graph, r)
        rid = r["run_id"]
        index["claims"]["validation:" + rid] = {
            "text": validation_text(rid), "source_id": "oracle:" + rid,
            "claim_type": "run_validation", "evidence_basis": "oracle_receipt",
            "domain": "fixture-" + rid, "knowable_time": EARLY,
            "check_provenance": observation(r), "verification_status": "observed_oracle_receipt"}
    graph.propagate()
    return index, graph_document(graph)


class EvidenceBoundaryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.serial = 0

    def build(self, index, graph):
        self.serial += 1
        folder = self.root / str(self.serial)
        folder.mkdir()
        for name, value in (("index", index), ("graph", graph)):
            (folder / (name + ".json")).write_text(json.dumps(value))
        brain = Brain.build(str(folder / "index.json"), str(folder / "graph.json"),
                            str(folder / "brain.db"), prefer="hashing")
        self.addCleanup(brain.con.close)
        return brain

    def test_pending_scores_remain_exploratory_everywhere(self):
        brain = self.build(*snapshot([]))
        fact = brain.retrieve("Backtest", k=10)[0]
        self.assertAlmostEqual(fact.trust, .9)
        self.assertFalse(fact.checked)
        result = brain.answer("Backtest", k=10, min_sim=0)
        self.assertEqual(result["n_checked"], 0)
        self.assertEqual(result["checked_retrieval_coverage"], 0)
        self.assertEqual(result["stance"], "unknown_no_checked_evidence")
        self.assertEqual(result["unchecked_relevant"][0]["exploratory_score"], .9)
        self.assertEqual(brain.calibrate()["n_checked"], 0)
        self.assertFalse(brain.calibrate()["licensed"])
        self.assertEqual(brain.learning_curve()["checked_n"], 0)
        self.assertEqual(brain.infer_trust("Backtest")["neighbors"], [])
        self.assertEqual(brain.bridge_hypotheses(lo=-1, hi=1.1), [])
        self.assertEqual(brain.explore_frontier(mode="contested"), [])
        agenda = build_agenda(brain)
        self.assertEqual([i["kind"] for i in agenda["items"]], ["verify_claim"])

    def test_current_corpus_proposals_supply_no_checked_labels(self):
        graph, _ = materialize([])
        brain = self.build(augmented_index([]), graph_document(graph))
        self.assertTrue(any(brain._all()[2] != 0))
        self.assertEqual(brain.stats()["n_checked"], 0)
        self.assertEqual(brain.calibrate()["n_checked"], 0)

    def test_direct_verdicts_do_not_propagate_to_attributed_source(self):
        brain = self.build(*snapshot([receipt("pass"), receipt("fail", "refuted"),
                                      receipt("pending", "unknown")]))
        facts = {f.id: f for f in brain.retrieve("Backtest", k=10)}
        self.assertEqual(facts["validation:pass"].check_value, 1)
        self.assertEqual(facts["validation:fail"].check_value, -1)
        self.assertFalse(facts["validation:pending"].checked)
        self.assertFalse(facts["source-claim"].checked)
        self.assertEqual(brain.stats()["n_checked"], 2)
        self.assertEqual(facts["validation:pass"].check_source, "oracle_receipt")
        self.assertEqual(facts["validation:pass"].check_evidence_id, "fixture:pass")

    def test_checked_retrieval_does_not_assert_entailment_or_confidence(self):
        brain = self.build(*snapshot([receipt("a"), receipt("b")], pending=False))
        result = brain.answer("Do these runs make all future investments profitable?", min_sim=0)
        self.assertEqual(result["checked_retrieval_coverage"], 1)
        self.assertEqual(result["stance"], "related_checked_evidence")
        self.assertFalse(result["proof_entailment"])
        self.assertFalse(result["licensed_locally"])
        self.assertIsNone(result["prediction_confidence"])
        self.assertEqual(result["answer_status"], "not_inferred")
        self.assertEqual(len(result["confirmed_related"]), 2)
        self.assertNotIn("supporting", result)

    def test_zero_or_inverted_graph_score_cannot_change_direct_label(self):
        index, graph = snapshot([receipt("a")], pending=False)
        for score in (0, -1, .9):
            graph["nodes"][1]["trust"] = score  # claim node after outcome
            brain = self.build(index, graph)
            fact = brain.retrieve("Backtest", k=10)[0]
            self.assertEqual(fact.check_value, 1)
            self.assertEqual(fact.trust, score)

    def test_copied_check_metadata_cannot_promote_arbitrary_claim(self):
        index, graph = snapshot([receipt("a")])
        index["claims"]["source-claim"]["check_provenance"] = observation(receipt("a"))
        brain = self.build(index, graph)
        self.assertFalse(next(f for f in brain.retrieve("Backtest", k=10)
                              if f.id == "source-claim").checked)

    def test_stale_index_or_missing_direct_edge_fails_closed(self):
        for change in ("index", "edge", "duplicate", "text", "scope"):
            with self.subTest(change=change):
                index, graph = snapshot([receipt("a")], pending=False)
                if change == "index":
                    index["claims"]["validation:a"]["check_provenance"]["verdict"] = "refuted"
                elif change == "edge":
                    graph["edges"][0]["kind"] = "corroborates"
                elif change == "duplicate":
                    graph["nodes"].append(copy.deepcopy(graph["nodes"][0]))
                elif change == "text":
                    index["claims"]["validation:a"]["text"] = "All investments will succeed."
                else:
                    graph["nodes"][0]["attrs"]["proposition"]["run_id"] = "different"
                self.assertEqual(self.build(index, graph).stats()["n_checked"], 0)

    def test_missing_unknown_or_malformed_observation_fails_closed(self):
        for observed in (None, "2026-09-14", "2026-09-14T12:00:00", "not-a-date", 3):
            with self.subTest(observed=observed):
                self.assertIsNone(observation(receipt("a", observed=observed)))
        for verdict in (True, 1, "consistent", None):
            r = receipt("a"); r["verdict"] = verdict
            self.assertIsNone(observation(r))

    def test_future_check_is_masked_but_earlier_text_remains_visible(self):
        brain = self.build(*snapshot([receipt("a", observed=LATE)], pending=False))
        before = brain.retrieve("Backtest", as_of=EARLY)[0]
        self.assertEqual(before.id, "validation:a")
        self.assertFalse(before.checked)
        self.assertIsNone(before.check_evidence_id)
        self.assertEqual(before.verification_status, "unverified_as_of")
        self.assertEqual(before.trust, 0)
        historical_answer = brain.answer("Backtest", min_sim=0, as_of=EARLY)
        self.assertEqual(historical_answer["unchecked_relevant"][0]["verification_status"], "unverified_as_of")
        self.assertEqual(brain.calibrate(as_of=EARLY)["n_checked"], 0)
        self.assertEqual(brain.explore_frontier(mode="contested", as_of=EARLY), [])
        after = brain.retrieve("Backtest", as_of=LATE)[0]
        self.assertTrue(after.checked)
        self.assertEqual(after.verification_status, "observed_oracle_receipt")

    def test_old_databases_without_provenance_fail_closed(self):
        brain = self.build(*snapshot([receipt("a")], pending=False))
        brain.con.cursor().execute("ALTER TABLE facts DROP COLUMN check_provenance")
        brain.con.cursor().execute("ALTER TABLE facts DROP COLUMN verification_status")
        brain.con.commit()
        legacy = Brain(brain.con, brain.dim, brain.embedder, brain.embedder_id)
        self.assertEqual(legacy.stats()["n_checked"], 0)
        for ann in (False, True):
            self.assertFalse(legacy.retrieve("Backtest", ann=ann)[0].checked)

    def test_withdrawal_clears_evidence_and_replay_does_not_restore_it(self):
        ledger = ReceiptLedger(self.root / "journal.sqlite")
        self.addCleanup(ledger.close)
        r = receipt("a")
        ledger._append(r)
        self.assertTrue(self.build(*snapshot(ledger.snapshots(), pending=False)).retrieve("Backtest")[0].checked)
        ledger.withdraw("a", "fixture withdrawal")
        ledger._append(r)
        withdrawn = self.build(*snapshot(ledger.snapshots(), pending=False))
        self.assertFalse(withdrawn.retrieve("Backtest")[0].checked)
        self.assertEqual(withdrawn.calibrate()["n_checked"], 0)

    def test_calibration_targets_are_receipt_labels_not_graph_scores(self):
        index, graph = snapshot([receipt("a"), receipt("b", "refuted"), receipt("c")], pending=False)
        baseline = self.build(index, graph)
        for n in graph["nodes"]:
            n["trust"] = .17
        changed = self.build(index, graph)
        self.assertEqual(baseline.calibrate(), changed.calibrate())
        self.assertEqual(baseline.learning_curve(sizes=(1,), repeats=3),
                         changed.learning_curve(sizes=(1,), repeats=3))
        self.assertEqual(changed.calibrate()["n_checked"], 3)
        self.assertFalse(changed.calibrate()["licensed"])

    def test_uniform_checked_verdicts_are_not_contested(self):
        for verdict in ("confirmed", "refuted"):
            with self.subTest(verdict=verdict):
                brain = self.build(*snapshot([receipt(rid, verdict) for rid in ("a", "b", "c")],
                                             pending=False))
                self.assertEqual(brain.explore_frontier(mode="contested"), [])
                self.assertNotIn("resolve_contested", [i["kind"] for i in build_agenda(brain)["items"]])
                general = brain.explore_frontier(mode="all")
                self.assertTrue(general)
                self.assertTrue(all(item["reason"] == "checked_isolated" for item in general))
                self.assertTrue(all(item["neighbor_checked_verdict_var"] == 0 for item in general))

    def test_differing_checked_neighborhood_can_be_contested(self):
        brain = self.build(*snapshot([receipt("a"), receipt("b", "refuted"), receipt("c")],
                                     pending=False))
        contested = brain.explore_frontier(mode="contested")
        self.assertTrue(contested)
        self.assertTrue(all(item["checked"] and item["neighbor_checked_verdict_var"] > .05
                            for item in contested))
        self.assertIn("resolve_contested", [i["kind"] for i in build_agenda(brain)["items"]])


if __name__ == "__main__":
    unittest.main()
