"""Real offline Brain snapshots can propose tests without inventing evidence."""
import copy
import importlib.util
import json
import os
from pathlib import Path
import unittest
from unittest import mock

from brain_agenda import build_agenda
from brain_exploration import compose_discovery
import brain_exploration as exploration
import test_brain_evidence as support
from test_mechanism_spec import fixture as mechanism_fixture, CONTEXT, INVENTORY

EARLY, LATE, receipt, snapshot = support.EARLY, support.LATE, support.receipt, support.snapshot

GOAL = {"id": "synthetic-mechanism", "question": "Which mechanism links explain the backtest observation?",
        "condition_scope": {"description": "synthetic condition declared before outcome", "constraints": ["one full observation delay"]}}


class DiscoveryTests(unittest.TestCase):
    def setUp(self):
        support.EvidenceBoundaryTests.setUp(self)

    def brain(self, receipts=(), *, pair=False):
        index, graph = snapshot(receipts)
        if pair:
            index["claims"]["other-claim"] = dict(index["claims"]["source-claim"],
                text="Backtest observation follows a synthetic mechanism signal.", domain="other")
            graph["nodes"].append({"id": "claim:other-claim", "kind": "claim", "trust": -.8})
        return support.EvidenceBoundaryTests.build(self, index, graph)

    def test_pending_and_negative_exploratory_scores_propose_but_never_check(self):
        brain = self.brain(pair=True)
        before = brain.con.cursor().execute("SELECT * FROM facts").fetchall()
        proposals = compose_discovery(brain, goal=GOAL)
        self.assertTrue(proposals)
        self.assertTrue(any(p["exploratory_score"] != 0 for p in proposals[0]["premises"]))
        self.assertTrue(all(p["n_checked_premises"] == 0 and p["checked"] is False for p in proposals))
        self.assertEqual(brain.calibrate()["n_checked"], 0)
        self.assertEqual(brain.bridge_hypotheses(lo=-1, hi=1.1), [])
        self.assertEqual(before, brain.con.cursor().execute("SELECT * FROM facts").fetchall())
        self.assertFalse(any(i["kind"] == "explore_mechanism" for i in build_agenda(brain)["items"]))
        self.assertTrue(any(i["kind"] == "explore_mechanism" for i in build_agenda(brain, discovery_goal=GOAL)["items"]))

    def test_mixed_premises_keep_scoped_counterevidence_and_missing_links(self):
        brain = self.brain([receipt("pass"), receipt("fail", "refuted"), receipt("pending", "unknown")], pair=True)
        goal = dict(GOAL, claim_refs=["source-claim", "validation:pass", "validation:fail", "validation:pending"])
        proposal = compose_discovery(brain, goal=goal, k=1)[0]
        premises = {p["claim_id"]: p for p in proposal["premises"]}
        self.assertEqual({p["check_verdict"] for p in premises.values()}, {"confirmed", "refuted", "unknown"})
        failed = premises["validation:fail"]
        self.assertEqual(failed["use"], "counterevidence")
        self.assertFalse(failed["assumed_true"])
        self.assertEqual(failed["check_scope"], {"kind": "passes_validation", "run_id": "fail"})
        self.assertEqual(failed["provenance"]["check_evidence_id"], "fixture:fail")
        self.assertEqual(proposal["condition_scope"]["constraints"], GOAL["condition_scope"]["constraints"])
        self.assertTrue(all(link["status"] == "proposed_unknown" for link in proposal["mechanism_links"]))
        self.assertEqual({t["kind"] for t in proposal["discriminating_tests"]},
                         {"link_ablation", "conditional_interaction", "negative_control"})
        self.assertTrue(all(t["status"] == "design_required" for t in proposal["discriminating_tests"]))
        self.assertFalse(proposal["checked"])
        self.assertEqual(proposal["conditional_hypothesis"]["unconditional_claims_asserted"], [])
        self.assertEqual(proposal["conditional_hypothesis"]["counterevidence_refs"], ["validation:fail"])
        self.assertEqual(set(proposal["causal_premise_refs"]), {"source-claim", "other-claim"})
        self.assertEqual(set(proposal["evidence_context_refs"]), {"validation:pass", "validation:fail", "validation:pending"})
        self.assertFalse(proposal["mechanism_ready"])
        self.assertEqual(proposal["composition_role"], "retrieval_design_candidate")
        self.assertTrue(proposal["design_gaps"])
        self.assertFalse(any(link["from_claim"].startswith("validation:") or link["to_claim"].startswith("validation:")
                             for link in proposal["mechanism_links"]))
        self.assertEqual(brain.stats()["n_checked"], 2)

    def test_future_evidence_is_masked_and_unavailable_anchor_fails_closed(self):
        brain = self.brain([receipt("future-check", observed=LATE)], pair=True)
        scoped_goal = dict(GOAL, claim_refs=["source-claim", "validation:future-check"])
        proposals = compose_discovery(brain, goal=scoped_goal, as_of=EARLY)
        self.assertTrue(proposals)
        self.assertTrue(all(p["n_checked_premises"] == 0 for p in proposals))
        future = next(p for p in proposals[0]["premises"] if p["claim_id"] == "validation:future-check")
        self.assertIsNone(future["provenance"]["check_evidence_id"])
        self.assertEqual(future["provenance"]["verification_status"], "unverified_as_of")
        brain.con.cursor().execute("UPDATE facts SET knowable_time=NULL WHERE id='other-claim'")
        brain.con.commit()
        goal = dict(GOAL, claim_refs=["other-claim"])
        with self.assertRaises(ValueError):
            compose_discovery(brain, goal=goal, as_of=EARLY)
        brain.con.cursor().execute("UPDATE facts SET knowable_time=? WHERE id='other-claim'", (LATE,))
        brain.con.commit()
        self.assertNotIn("other-claim", {cid for p in compose_discovery(brain, goal=GOAL, as_of=EARLY) for cid in p["claim_refs"]})

    def test_identity_ignores_scores_but_changes_for_new_condition(self):
        brain = self.brain(pair=True)
        before = compose_discovery(brain, goal=GOAL)
        brain.con.cursor().execute("UPDATE facts SET trust=0.123")
        brain.con.commit()
        after = compose_discovery(brain, goal=GOAL)
        self.assertEqual([p["id"] for p in before], [p["id"] for p in after])
        self.assertNotEqual(before[0]["context_sha256"], after[0]["context_sha256"])
        changed = copy.deepcopy(GOAL)
        changed["condition_scope"]["description"] = "a different stipulated regime"
        self.assertTrue(set(p["id"] for p in before).isdisjoint(p["id"] for p in compose_discovery(brain, goal=changed)))

    def test_missing_condition_or_bad_bounds_are_not_silently_defaulted(self):
        brain = self.brain(pair=True)
        for goal in ({}, dict(GOAL, condition_scope={}), dict(GOAL, claim_refs=["missing"])):
            with self.assertRaises(ValueError):
                compose_discovery(brain, goal=goal)
        for kwargs in ({"k": -1}, {"max_hops": 10}, {"as_of": "2026-09-14T00:00:00"}):
            with self.assertRaises(ValueError):
                compose_discovery(brain, goal=GOAL, **kwargs)

    def test_private_context_reference_is_attribution_only_and_not_a_new_premise(self):
        goal = dict(GOAL, context_refs=[{"artifact": "runtime/private/source-audit.md", "checked": True}])
        proposal = compose_discovery(self.brain(pair=True), goal=goal, k=1)[0]
        self.assertEqual(proposal["goal"]["context_refs"], [{"artifact": "runtime/private/source-audit.md",
                                                          "role": "attribution_only", "checked": False}])
        self.assertEqual(set(proposal["claim_refs"]), {"source-claim", "other-claim"})

    def test_unrelated_goal_has_no_topical_nominations_without_explicit_anchor(self):
        brain = self.brain(pair=True)
        goal = dict(GOAL, question="Which photosynthesis chlorophyll mechanism explains botanical leaf growth?")
        self.assertEqual(compose_discovery(brain, goal=goal), [])
        self.assertEqual(build_agenda(brain, discovery_goal=goal)["discovery_status"], "no_eligible_topical_chain")
        goal["claim_refs"] = ["source-claim"]
        proposals = compose_discovery(brain, goal=goal)
        self.assertTrue(proposals)
        self.assertEqual(proposals[0]["relevance"]["basis"], "explicit_anchor")

    def test_design_revision_changes_ids_and_evidence_revision_preserves_them(self):
        brain = self.brain([receipt("pending", "unknown")], pair=True)
        before = compose_discovery(brain, goal=GOAL)
        original = exploration._design
        def changed(*args):
            links, tests, question = original(*args)
            tests[0]["contrast"]["control"] = "a different stipulated matched ablation"
            return links, tests, question
        with mock.patch.object(exploration, "_design", side_effect=changed):
            changed_design = compose_discovery(brain, goal=GOAL)
        self.assertTrue(set(p["id"] for p in before).isdisjoint(p["id"] for p in changed_design))
        brain.con.cursor().execute("UPDATE facts SET verification_status='pending_revision' WHERE id='source-claim'")
        brain.con.commit()
        after = compose_discovery(brain, goal=GOAL)
        self.assertEqual([p["id"] for p in before], [p["id"] for p in after])
        self.assertNotEqual(before[0]["context_sha256"], after[0]["context_sha256"])

    def test_observed_verdict_revision_updates_counterevidence_without_new_proposition(self):
        goal = dict(GOAL, claim_refs=["source-claim", "validation:changing"])
        pending = compose_discovery(self.brain([receipt("changing", "unknown")], pair=True), goal=goal)
        refuted = compose_discovery(self.brain([receipt("changing", "refuted")], pair=True), goal=goal)
        self.assertEqual([p["id"] for p in pending], [p["id"] for p in refuted])
        self.assertNotEqual(pending[0]["context_sha256"], refuted[0]["context_sha256"])
        self.assertEqual(pending[0]["conditional_hypothesis"]["counterevidence_refs"], [])
        self.assertEqual(refuted[0]["conditional_hypothesis"]["counterevidence_refs"], ["validation:changing"])

    def test_offline_agenda_to_qr_hypothesis_preserves_proposal(self):
        qr = Path(os.getenv("AGENTIC_QR_ROOT", Path(__file__).resolve().parents[2] / "agentic-qr"))
        path = qr / "shared/corpus/brain_agenda_intake.py"
        if not path.is_file():
            self.skipTest("set AGENTIC_QR_ROOT to run the cross-repository adapter test")
        spec = importlib.util.spec_from_file_location("fixture_agenda_intake", path)
        intake = importlib.util.module_from_spec(spec); spec.loader.exec_module(intake)
        agenda = build_agenda(self.brain(pair=True), discovery_goal=GOAL)
        output = self.root / "agenda.json"
        output.write_text(json.dumps(agenda))
        tasks = intake.candidate_tasks(path=output, kinds=["explore_mechanism"])
        self.assertTrue(tasks)
        hypothesis = intake.to_hypothesis(tasks[0])
        self.assertEqual(hypothesis["discovery_context"], tasks[0]["proposal"])
        self.assertEqual(hypothesis["claim_refs"], tasks[0]["claim_refs"])
        self.assertEqual(hypothesis["execution_status"], "not_requested")
        empty_brain = mock.Mock()
        empty_brain._all.return_value = ([], [], [], [])
        explicit = dict(GOAL, context_refs=CONTEXT, mechanism_spec=mechanism_fixture())
        proposal = compose_discovery(empty_brain, goal=explicit, data_inventory=INVENTORY)[0]
        self.assertEqual(proposal["claim_refs"], [])
        output.write_text(json.dumps({"items": [proposal]}))
        task = intake.candidate_tasks(path=output)[0]
        self.assertEqual(intake.to_hypothesis(task)["claim_refs"], [])
        self.assertTrue(task["proposal"]["mechanism_ready"])
        self.assertNotIn("validation", hypothesis)
        self.assertNotIn("oracle_receipt", hypothesis)
        self.assertEqual(hypothesis["id"], intake.to_hypothesis(tasks[0])["id"])
        self.assertFalse(hypothesis["mechanism_ready"])
        explicit = dict(GOAL, claim_refs=["source-claim"], context_refs=CONTEXT, mechanism_spec=mechanism_fixture())
        proposal = compose_discovery(self.brain(pair=True), goal=explicit, data_inventory=INVENTORY)[0]
        output.write_text(json.dumps({"items": [proposal]}))
        task = intake.candidate_tasks(path=output)[0]
        hypothesis = intake.to_hypothesis(task)
        self.assertTrue(hypothesis["mechanism_ready"])
        self.assertFalse(hypothesis["checked"])
        self.assertEqual(hypothesis["execution_status"], "not_requested")

    def test_biography_and_receipts_never_supply_causal_nodes(self):
        brain = self.brain([receipt("failed", "refuted")], pair=True)
        brain.con.cursor().execute("UPDATE facts SET domain='biographical' WHERE id='other-claim'")
        brain.con.commit()
        goal = dict(GOAL, claim_refs=["validation:failed", "other-claim"])
        proposal = compose_discovery(brain, goal=goal)[0]
        self.assertEqual(proposal["causal_premise_refs"], [])
        self.assertEqual(proposal["mechanism_links"], [])
        self.assertEqual(set(proposal["evidence_context_refs"]), {"validation:failed", "other-claim"})
        self.assertFalse(proposal["mechanism_ready"])

    def test_explicit_spec_changes_semantic_identity_but_inventory_changes_only_context(self):
        brain = self.brain(pair=True)
        goal = dict(GOAL, claim_refs=["source-claim"], context_refs=CONTEXT, mechanism_spec=mechanism_fixture())
        missing = build_agenda(brain, k_gaps=0, k_contested=0, k_bridges=1,
                               discovery_goal=goal, discovery_data_inventory={})["items"][0]
        available = build_agenda(brain, k_gaps=0, k_contested=0, k_bridges=1,
                                 discovery_goal=goal, discovery_data_inventory=INVENTORY)["items"][0]
        self.assertEqual(missing["id"], available["id"])
        self.assertNotEqual(missing["context_sha256"], available["context_sha256"])
        self.assertFalse(missing["mechanism_ready"])
        self.assertTrue(available["mechanism_ready"])
        self.assertFalse(available["checked"])
        self.assertEqual(available["composition_role"], "explicit_mechanism_design")
        self.assertEqual(available["question"], goal["mechanism_spec"]["question"])
        changed = copy.deepcopy(goal); changed["mechanism_spec"]["contrasts"][0]["margin"] *= 2
        self.assertNotEqual(missing["id"], compose_discovery(brain, goal=changed)[0]["id"])
        self.assertEqual(brain.stats()["n_checked"], 0)


if __name__ == "__main__":
    unittest.main()
