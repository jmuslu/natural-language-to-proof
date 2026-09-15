"""Deterministic checks of supplied proofs; no reference-answer solver."""
import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from reasoning.engine import evaluate, Limits
from reason import Inf, TyT, from_grounding
from estimand import colimit


def a(predicate, entity="alice", negated=False):
    return {"predicate": predicate, "args": [entity], "negated": negated}


def rule(rid, predicates, head):
    return {"id": rid, "var_types": {"x": "person"},
            "body": [a(p, "?x") for p in predicates], "head": a(head, "?x")}


def fixture():
    task = {
        "id": "world-1",
        "entities": {"alice": "person", "bob": "person", "asset": "instrument"},
        "predicates": {p: ["person"] for p in ["p", "q", "r", "s"]},
        "facts": [{"id": fid, "text": text} for fid, text in [
            ("f1", "Alice has p."), ("f2", "An independent observation says Alice has q."),
            ("fb", "Bob has p."), ("fn", "Alice does not have r."),
            ("fd", "A duplicate of the first observation.")]],
        "rules": [rule("pq", ["p"], "q"), rule("qr", ["q"], "r"),
                  rule("rs", ["r", "p"], "s")],
        "query": a("s"),
    }
    def receipt(atom, eid):
        return {"atom": atom, "verdict": "confirmed", "evidence_id": eid, "provenance": [eid]}
    receipts = {
        "f1": receipt(a("p"), "obs-1"),
        "f2": receipt(a("q"), "obs-2"),
        "fb": receipt(a("p", "bob"), "obs-b"),
        "fn": receipt(a("r", negated=True), "obs-neg"),
        "fd": receipt(a("p"), "obs-1"),
    }
    receipts["fn"]["verdict"] = "unknown"
    proof = {"answer": "entailed", "steps": [
        {"id": "s0", "fact_id": "f1"},
        {"id": "s1", "rule_id": "pq", "substitution": {"x": "alice"}, "premises": ["s0"]},
        {"id": "s2", "rule_id": "qr", "substitution": {"x": "alice"}, "premises": ["s1"]},
        {"id": "s3", "rule_id": "rs", "substitution": {"x": "alice"}, "premises": ["s2", "s0"]},
    ], "conclusion": "s3"}
    return task, proof, receipts


class EngineTests(unittest.TestCase):
    def setUp(self):
        self.task, self.proof, self.receipts = fixture()

    def check(self, **kwargs):
        return evaluate(self.task, self.proof, self.receipts, **kwargs)

    def reject(self, code):
        result = self.check()
        self.assertFalse(result.accepted, result.to_dict())
        self.assertFalse(result.grounded)
        self.assertEqual(result.verdict, "unknown")
        self.assertEqual(result.errors[0]["code"], code)
        return result

    def test_valid_multihop_and_exact_query(self):
        result = self.check()
        self.assertTrue(result.accepted, result.to_dict())
        self.assertTrue(result.answered)
        self.assertEqual(result.verdict, "entailed")
        self.assertEqual(result.to_dict()["max_depth"], 3)
        self.assertEqual(result.to_dict()["unique_evidence"], 1)

    def test_wrong_rule(self):
        self.proof["steps"][1]["rule_id"] = "qr"
        result = self.reject("premise_mismatch")
        self.assertEqual(result.errors[0]["step"], "s1")

    def test_wrong_entity_same_type(self):
        self.proof["steps"][1]["substitution"]["x"] = "bob"
        self.reject("premise_mismatch")

    def test_wrong_type(self):
        self.proof["steps"][1]["substitution"]["x"] = "asset"
        self.reject("type_mismatch")

    def test_substitution_must_be_complete_and_exact(self):
        for sub in ({}, {"x": "alice", "y": "bob"}):
            with self.subTest(sub=sub):
                self.proof["steps"][1]["substitution"] = sub
                self.reject("invalid_substitution")

    def test_unconfirmed_never_enters(self):
        for verdict in ("unknown", "refuted", True, "true"):
            with self.subTest(verdict=verdict):
                self.receipts["f1"]["verdict"] = verdict
                # Remove the alias so this tests admission, not conflicting duplicates.
                self.receipts.pop("fd", None)
                self.reject("unconfirmed_fact" if verdict in ("unknown", "refuted") else "invalid_receipt")

    def test_text_and_model_booleans_are_not_receipts(self):
        self.receipts = {}
        self.reject("unconfirmed_fact")
        self.proof["steps"][0]["grounded"] = True
        self.reject("invalid_step")

    def test_unknown_is_accepted_abstention_not_negative(self):
        self.proof = {"answer": "unknown", "steps": [], "conclusion": None}
        result = self.check()
        self.assertTrue(result.accepted)
        self.assertTrue(result.abstained)
        self.assertFalse(result.answered)
        self.assertFalse(result.grounded)
        self.assertEqual(result.to_dict()["validated_steps"], 0)

    def test_no_proof_is_not_refutation(self):
        self.proof = {"answer": "refuted", "steps": [], "conclusion": None}
        self.reject("missing_conclusion")

    def test_explicit_negative_proves_refutation(self):
        self.receipts["fn"]["verdict"] = "confirmed"
        self.task["query"] = a("r")
        self.proof = {"answer": "refuted", "steps": [{"id": "negative", "fact_id": "fn"}],
                      "conclusion": "negative"}
        self.assertEqual(self.check().verdict, "refuted")
        self.proof["answer"] = "entailed"
        self.reject("wrong_conclusion")

    def test_negated_query_reverses_target_exactly(self):
        self.receipts["fn"]["verdict"] = "confirmed"
        self.task["query"] = a("r", negated=True)
        self.proof = {"answer": "entailed", "steps": [{"id": "negative", "fact_id": "fn"}],
                      "conclusion": "negative"}
        self.assertEqual(self.check().verdict, "entailed")
        self.proof["answer"] = "refuted"
        self.reject("wrong_conclusion")

    def test_negative_premise_cannot_match_positive_body(self):
        self.receipts["f1"]["atom"] = a("p", negated=True)
        self.receipts.pop("fd")
        self.reject("premise_mismatch")

    def test_unknown_does_not_launder_invalid_steps(self):
        self.proof["answer"] = "unknown"
        self.proof["conclusion"] = None
        self.proof["steps"][1]["rule_id"] = "invented"
        self.reject("unknown_rule")

    def test_cycles_and_forward_references_rejected(self):
        for ref in ("s1", "s2", "not-supplied"):
            with self.subTest(ref=ref):
                self.proof["steps"][1]["premises"] = [ref]
                self.reject("nonchronological_reference")

    def test_missing_edge_and_wrong_premise_order(self):
        self.proof["steps"][3]["premises"] = ["s2"]
        self.reject("missing_premise")
        self.proof["steps"][3]["premises"] = ["s0", "s2"]
        self.reject("premise_mismatch")

    def test_duplicate_step_ids_rejected(self):
        self.proof["steps"].append({"id": "s0", "fact_id": "f1"})
        self.reject("duplicate_step_id")

    def test_duplicate_evidence_cannot_farm_support(self):
        self.proof["steps"].append({"id": "duplicate", "fact_id": "fd"})
        result = self.check()
        self.assertEqual(result.to_dict()["unique_evidence"], 1)
        self.assertEqual(result.to_dict()["provenance_sources"], ["obs-1"])
        update = result.retract_fact("f1")
        self.assertEqual(update["affected_aliases"], ["f1", "fd"])
        self.assertFalse(result.grounded)

    def test_alternative_path_preserves_old_terminal_atom(self):
        self.task["query"] = a("r")
        self.proof["steps"] = self.proof["steps"][:3] + [{"id": "independent", "fact_id": "f2"}]
        self.proof["conclusion"] = "s2"
        result = self.check()
        self.assertTrue(result.grounded)
        result.retract_fact("f1")
        self.assertTrue(result.grounded, result.to_dict())
        result.retract_fact("f2")
        self.assertFalse(result.grounded)
        self.assertEqual(result.verdict, "unknown")
        self.assertEqual(result.support_status, "withdrawn")

    def test_grounded_cycle_cannot_survive_root_retraction(self):
        self.task["rules"].append(rule("qp", ["q"], "p"))
        self.task["query"] = a("p")
        self.proof["steps"] = self.proof["steps"][:2] + [
            {"id": "back", "rule_id": "qp", "substitution": {"x": "alice"}, "premises": ["s1"]}]
        self.proof["conclusion"] = "back"
        result = self.check()
        self.assertTrue(result.grounded)
        result.retract_fact("f1")
        self.assertFalse(result.grounded)

    def test_conflicting_submitted_support_abstains(self):
        self.receipts["fn"]["verdict"] = "confirmed"
        self.task["query"] = a("r")
        self.proof["steps"] = self.proof["steps"][:3] + [{"id": "opposite", "fact_id": "fn"}]
        self.proof["conclusion"] = "s2"
        result = self.check()
        self.assertEqual(result.support_status, "conflicting")
        self.assertFalse(result.grounded)
        self.assertEqual(result.verdict, "unknown")

    def test_malformed_rules_rejected_before_proof(self):
        for mutate, code in [
            (lambda r: r.update(body=[]), "empty_rule_body"),
            (lambda r: r["var_types"].update(y="person"), "unused_variable"),
            (lambda r: (r["var_types"].update(y="person"), r.update(head=a("q", "?y"))), "unsafe_rule"),
            (lambda r: r.update(head=a("q", "?missing")), "unbound_variable"),
        ]:
            with self.subTest(code=code):
                self.task, self.proof, self.receipts = fixture()
                mutate(self.task["rules"][0])
                self.reject(code)

    def test_fact_rule_and_predicate_schema_validation(self):
        self.task["facts"].append(copy.deepcopy(self.task["facts"][0]))
        self.reject("duplicate_fact_id")
        self.task, self.proof, self.receipts = fixture()
        self.task["rules"].append(copy.deepcopy(self.task["rules"][0]))
        self.reject("duplicate_rule_id")
        self.task, self.proof, self.receipts = fixture()
        self.task["query"]["args"] = []
        self.reject("arity_mismatch")

    def test_receipt_provenance_and_conflicts(self):
        self.receipts["f1"]["provenance"] = []
        self.reject("invalid_receipt")
        self.task, self.proof, self.receipts = fixture()
        self.receipts["fd"]["verdict"] = "refuted"
        self.reject("conflicting_receipt")

    def test_caps(self):
        for limit in (Limits(steps=3), Limits(proof_depth=2), Limits(bytes=10), Limits(body=1)):
            with self.subTest(limit=limit):
                result = self.check(limits=limit)
                self.assertFalse(result.accepted)
                self.assertEqual(result.errors[0]["code"], "resource_limit")

    def test_non_finite_input_fails_closed(self):
        self.proof["confidence"] = float("nan")
        self.reject("invalid_json")

    def test_omitting_direct_opposite_receipt_cannot_hide_conflict(self):
        self.receipts["fn"]["verdict"] = "confirmed"
        self.task["query"] = a("r")
        self.proof["steps"] = self.proof["steps"][:3]
        self.proof["conclusion"] = "s2"
        result = self.check()
        self.assertEqual(result.support_status, "conflicting")
        self.assertFalse(result.grounded)
        result.retract_fact("fn")
        self.assertTrue(result.grounded)

    def test_binary_predicate_and_two_variable_binding(self):
        self.task["predicates"]["linked"] = ["person", "person"]
        self.task["facts"].append({"id": "fl", "text": "Alice is linked to Bob."})
        relation = {"predicate": "linked", "args": ["alice", "bob"], "negated": False}
        self.receipts["fl"] = {"atom": relation, "verdict": "confirmed",
                               "evidence_id": "link-observation", "provenance": ["link-data"]}
        self.task["rules"].append({
            "id": "join", "var_types": {"x": "person", "y": "person"},
            "body": [{"predicate": "linked", "args": ["?x", "?y"]}, a("p", "?x")],
            "head": a("q", "?y")})
        self.task["query"] = a("q", "bob")
        self.proof = {"answer": "entailed", "steps": [
            {"id": "link", "fact_id": "fl"}, {"id": "source", "fact_id": "f1"},
            {"id": "joined", "rule_id": "join", "substitution": {"x": "alice", "y": "bob"},
             "premises": ["link", "source"]}], "conclusion": "joined"}
        self.assertTrue(self.check().grounded)
        self.proof["steps"][-1]["substitution"] = {"x": "bob", "y": "alice"}
        self.reject("premise_mismatch")

    def test_malformed_json_values_return_feedback_not_exceptions(self):
        for value in (None, [], 0, True, "bad", {"bad": "shape"}):
            for field in ("entities", "predicates", "facts", "rules", "query"):
                with self.subTest(field=field, value=value):
                    task = copy.deepcopy(self.task)
                    task[field] = value
                    result = evaluate(task, self.proof, self.receipts)
                    self.assertFalse(result.accepted, result.to_dict())
                    self.assertTrue(result.errors)
                    self.assertFalse(result.to_dict()["grounded"])

    def test_confidence_and_grounding_helper(self):
        self.assertFalse(Inf(TyT, "proposal").grounded)
        for value in (float("nan"), float("inf"), -1, 2, True, "0.9"):
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    Inf(TyT, "bad", conf=value)
        with self.assertRaises(TypeError):
            from_grounding("unchecked", 0.99, {"claimed"})
        self.assertFalse(from_grounding("empty", colimit("empty", []), set()).grounded)


if __name__ == "__main__":
    unittest.main()

