"""Local joins and proof assembly tested independently of any model or gold solver."""
import copy
import json
import unittest

from reasoning.engine import Limits, evaluate
from reasoning.scaffold import Scaffold, ScaffoldLimits, deterministic_search


def atom(p, *args, negated=False):
    return {"predicate": p, "args": list(args), "negated": negated}


def rule(rid, types, body, head):
    return {"id": rid, "var_types": types, "body": body, "head": head}


def fixture():
    task = {"id": "fixture", "entities": {"ana": "person", "bob": "person", "cy": "person", "gear": "machine"},
            "predicates": {**{p: ["person"] for p in ("p", "q", "r", "s", "target")},
                           "uses": ["person", "machine"], "licensed": ["machine"],
                           "attends": ["person", "person"]},
            "facts": [], "rules": [
                rule("pq", {"x": "person"}, [atom("p", "?x")], atom("q", "?x")),
                rule("usepermit", {"x": "person", "m": "machine"},
                     [atom("uses", "?x", "?m"), atom("licensed", "?m")], atom("r", "?x")),
                rule("qs", {"x": "person"}, [atom("q", "?x"), atom("r", "?x")], atom("s", "?x")),
                rule("cycle", {"x": "person"}, [atom("s", "?x")], atom("q", "?x"))],
            "query": atom("s", "ana")}
    receipts = {}
    for fid, a in [("pa", atom("p", "ana")), ("pb", atom("p", "bob")),
                   ("use", atom("uses", "ana", "gear")), ("license", atom("licensed", "gear")),
                   ("link", atom("attends", "ana", "bob"))]:
        add_fact(task, receipts, fid, a)
    return task, receipts


def add_fact(task, receipts, fid, a, verdict="confirmed", eid=None):
    task["facts"].append({"id": fid, "text": "Fixture observation " + json.dumps(a)})
    receipts[fid] = {"atom": a, "verdict": verdict, "evidence_id": eid or "obs-" + fid,
                     "provenance": [eid or "obs-" + fid]}


class ScaffoldTests(unittest.TestCase):
    def setUp(self):
        self.task, self.receipts = fixture()

    def test_view_is_local_and_does_not_apply_rules(self):
        scaffold = Scaffold(self.task, self.receipts)
        view = scaffold.view()
        self.assertEqual({c["rule_id"] for c in view["candidates"]}, {"pq", "usepermit"})
        self.assertFalse(any(k["atom"] == self.task["query"] for k in view["known"]))
        self.assertEqual(scaffold.accounting()["selected_applications"], 0)
        result = scaffold.finish("entailed")
        self.assertFalse(result["check"]["accepted"])
        self.assertEqual(result["check"]["errors"][0]["code"], "missing_conclusion")

    def test_branching_proof_uses_only_selected_candidates(self):
        scaffold = Scaffold(self.task, self.receipts)
        first = scaffold.view()
        selected = [c["id"] for c in first["candidates"] if c["substitution"].get("x") == "ana"]
        self.assertTrue(scaffold.apply({"select": selected})["accepted"])
        second = scaffold.view()
        branch = next(c for c in second["candidates"] if c["rule_id"] == "qs")
        self.assertEqual(len(branch["premises"]), 2)
        scaffold.apply({"select": [branch["id"]]})
        result = scaffold.finish("entailed")
        self.assertTrue(result["check"]["grounded"])
        self.assertEqual(result["work"]["selected_applications"], 3)
        self.assertEqual(result["answer_origin"], "caller")
        # The caller deliberately did not select the valid Bob rule instance.
        self.assertFalse(any(s.get("substitution") == {"x": "bob"} for s in result["proposal"]["steps"]))

    def test_forward_search_is_explicit_and_saturates_cycles(self):
        result = deterministic_search(self.task, self.receipts)
        self.assertEqual(result["check"]["answer"], "entailed")
        self.assertTrue(result["search_complete"])
        self.assertEqual(result["method"], "deterministic_forward_search")
        self.assertEqual(result["answer_origin"], "symbolic_search")
        self.assertEqual(result["model_calls"], 0)
        self.assertEqual(result["work"]["selected_applications"], 5)
        self.assertGreater(result["work"]["atom_match_attempts"], 0)
        self.assertEqual(result["work"]["validation_calls"], 2)

    def test_multivariable_typed_join_preserves_bindings(self):
        self.task["rules"].append(rule("joined", {"x": "person", "y": "person", "m": "machine"},
            [atom("attends", "?x", "?y"), atom("p", "?y"), atom("uses", "?x", "?m"),
             atom("licensed", "?m")], atom("target", "?x")))
        self.task["query"] = atom("target", "ana")
        view = Scaffold(self.task, self.receipts).view()
        joined = [c for c in view["candidates"] if c["rule_id"] == "joined"]
        self.assertEqual([c["substitution"] for c in joined], [{"x": "ana", "y": "bob", "m": "gear"}])
        self.assertEqual(deterministic_search(self.task, self.receipts)["check"]["answer"], "entailed")
        self.receipts["pb"]["atom"] = atom("p", "cy")
        self.assertEqual(deterministic_search(self.task, self.receipts)["check"]["answer"], "unknown")

    def test_repeated_variable_and_constant_constraints(self):
        self.task["rules"] = [rule("self", {"x": "person"}, [atom("attends", "?x", "?x")], atom("target", "?x")),
                              rule("constant", {}, [atom("p", "cy")], atom("target", "ana"))]
        self.task["query"] = atom("target", "ana")
        self.assertEqual(Scaffold(self.task, self.receipts).view()["candidates"], [])
        add_fact(self.task, self.receipts, "self", atom("attends", "ana", "ana"))
        self.assertEqual(deterministic_search(self.task, self.receipts)["check"]["answer"], "entailed")

    def test_unknown_or_refuted_gate_is_not_an_admitted_leaf(self):
        for verdict in ("unknown", "refuted"):
            with self.subTest(verdict=verdict):
                self.receipts["license"]["verdict"] = verdict
                result = deterministic_search(self.task, self.receipts)
                self.assertEqual(result["check"]["answer"], "unknown")
                self.assertTrue(result["search_complete"])
                self.assertNotIn("license", [s.get("fact_id") for s in result["proposal"]["steps"]])

    def test_explicit_signed_negation_and_negated_query(self):
        self.task["rules"] = [rule("negative", {"x": "person"},
            [atom("p", "?x", negated=True)], atom("s", "?x", negated=True))]
        self.assertEqual(deterministic_search(self.task, self.receipts)["check"]["answer"], "unknown")
        add_fact(self.task, self.receipts, "negative", atom("p", "ana", negated=True))
        self.assertEqual(deterministic_search(self.task, self.receipts)["check"]["answer"], "refuted")
        self.task["query"]["negated"] = True
        self.assertEqual(deterministic_search(self.task, self.receipts)["check"]["answer"], "entailed")

    def test_opposing_derived_proofs_abstain_in_complete_search(self):
        self.task["rules"].append(rule("negative", {"x": "person"},
            [atom("p", "?x")], atom("s", "?x", negated=True)))
        result = deterministic_search(self.task, self.receipts)
        self.assertTrue(result["search_complete"])
        self.assertEqual(result["check"]["answer"], "unknown")

    def test_alternative_support_survives_retraction(self):
        add_fact(self.task, self.receipts, "direct-q", atom("q", "ana"))
        result = deterministic_search(self.task, self.receipts)
        check = evaluate(self.task, result["proposal"], self.receipts)
        self.assertTrue(check.grounded)
        self.assertTrue(check.retract_fact("direct-q")["result"]["grounded"])
        # The q<->s cycle cannot support itself once both external q paths vanish.
        self.assertFalse(check.retract_fact("pa")["result"]["grounded"])

    def test_duplicate_leaf_identity_does_not_farm_steps_or_evidence(self):
        base = deterministic_search(self.task, self.receipts)
        add_fact(self.task, self.receipts, "alias", atom("p", "ana"), eid="obs-pa")
        aliased = deterministic_search(self.task, self.receipts)
        self.assertEqual(aliased["work"]["duplicate_leaf_aliases"], 1)
        self.assertEqual(base["work"]["leaf_steps"], aliased["work"]["leaf_steps"])
        self.assertEqual(base["check"]["unique_evidence"], aliased["check"]["unique_evidence"])

    def test_bad_actions_are_atomic_and_stale_ids_rejected(self):
        scaffold = Scaffold(self.task, self.receipts)
        view = scaffold.view()
        cid = view["candidates"][0]["id"]
        before = copy.deepcopy(scaffold.steps)
        for action in ({"select": [cid, "invented"]}, {"select": [cid, cid]},
                       {"select": [False]}, {"select": []}, {"select": [cid], "grounded": True}):
            self.assertFalse(scaffold.apply(action)["accepted"])
            self.assertEqual(scaffold.steps, before)
        scaffold.apply({"select": [cid]})
        self.assertFalse(scaffold.apply({"select": [cid]})["accepted"])

    def test_cached_views_charge_no_extra_join_work(self):
        scaffold = Scaffold(self.task, self.receipts)
        a, b = scaffold.view(), scaffold.view()
        self.assertEqual(a["candidates"], b["candidates"])
        self.assertEqual(a["work"]["atom_match_attempts"], b["work"]["atom_match_attempts"])
        self.assertEqual(b["work"]["view_calls"], 2)
        self.assertEqual(b["work"]["cached_views"], 1)

    def test_match_budget_and_proof_caps_do_not_claim_complete_search(self):
        result = deterministic_search(self.task, self.receipts,
                                      limits=ScaffoldLimits(atom_match_attempts=1))
        self.assertFalse(result["search_complete"])
        self.assertIn("atom_match_attempts", result["work"]["exhausted"])
        self.assertLessEqual(result["work"]["atom_match_attempts"], 1)
        leaves = deterministic_search(self.task, self.receipts, engine_limits=Limits(steps=1))
        self.assertFalse(leaves["search_complete"])
        self.assertLessEqual(leaves["work"]["proof_steps"], 1)
        depth = deterministic_search(self.task, self.receipts, engine_limits=Limits(proof_depth=1))
        self.assertFalse(depth["search_complete"])
        self.assertIn("proof_depth", depth["work"]["exhausted"])

    def test_selection_and_view_budgets_are_explicit(self):
        result = deterministic_search(self.task, self.receipts,
                                      limits=ScaffoldLimits(selected_applications=1))
        self.assertEqual(result["work"]["selected_applications"], 1)
        self.assertFalse(result["search_complete"])
        result = deterministic_search(self.task, self.receipts, limits=ScaffoldLimits(view_calls=1))
        self.assertEqual(result["work"]["view_calls"], 1)
        self.assertIn("view_calls", result["work"]["exhausted"])

    def test_reordered_input_has_identical_search_and_candidate_identities(self):
        base = deterministic_search(self.task, self.receipts)
        self.task["rules"].reverse(); self.task["facts"].reverse()
        self.receipts = dict(reversed(list(self.receipts.items())))
        self.assertEqual(base, deterministic_search(self.task, self.receipts))

    def test_rejects_private_task_fields_and_malformed_types(self):
        self.task["gold_answer"] = "entailed"
        with self.assertRaises(ValueError):
            Scaffold(self.task, self.receipts)
        self.task.pop("gold_answer")
        self.receipts["pa"]["atom"] = atom("p", "gear")
        with self.assertRaises(ValueError):
            Scaffold(self.task, self.receipts)
        with self.assertRaises(ValueError):
            ScaffoldLimits(atom_match_attempts=True)


if __name__ == "__main__":
    unittest.main()
