import copy
import importlib
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from test_oracle_bridge import completed
from oracle_bridge import ReceiptLedger, load_evaluator
from reasoning.ledger import bind_receipts, check_against_ledger


def atom(name, *args):
    return {"predicate": name, "args": list(args), "negated": False}


def task_and_proof():
    task = {"id": "joint-run-review", "entities": {"run-a": "validation_run", "run-b": "validation_run"},
            "predicates": {"passes_validation": ["validation_run"],
                           "jointly_passed": ["validation_run", "validation_run"],
                           "replication_candidate": ["validation_run", "validation_run"]},
            "facts": [{"id": fid, "text": f"Run receipt for {rid}",
                       "oracle": {"kind": "passes_validation", "run_id": rid}}
                      for fid, rid in (("f-a", "run-a"), ("f-b", "run-b"))],
            "rules": [
                {"id": "pair", "var_types": {"x": "validation_run", "y": "validation_run"},
                 "body": [atom("passes_validation", "?x"), atom("passes_validation", "?y")],
                 "head": atom("jointly_passed", "?x", "?y")},
                {"id": "policy", "var_types": {"x": "validation_run", "y": "validation_run"},
                 "body": [atom("jointly_passed", "?x", "?y")],
                 "head": atom("replication_candidate", "?x", "?y")}],
            "query": atom("replication_candidate", "run-a", "run-b")}
    proposal = {"answer": "entailed", "steps": [
        {"id": "s0", "fact_id": "f-a"}, {"id": "s1", "fact_id": "f-b"},
        {"id": "s2", "rule_id": "pair", "substitution": {"x": "run-a", "y": "run-b"}, "premises": ["s0", "s1"]},
        {"id": "s3", "rule_id": "policy", "substitution": {"x": "run-a", "y": "run-b"}, "premises": ["s2"]}],
        "conclusion": "s3"}
    return task, proposal


class LedgerProofTests(unittest.TestCase):
    def setUp(self):
        repo = Path(os.environ.get("ORACLE_REPO", str(Path.home() / "projects"))).resolve()
        self.evaluate = load_evaluator(repo)
        sys.path.insert(0, str(repo / "shared/backtesting/validation"))
        self.finalize = importlib.import_module("apply_run_fdr").finalize_results
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.directory = Path(directory.name)
        self.ledger = ReceiptLedger(self.directory / "oracle.sqlite")
        self.addCleanup(self.ledger.close)

    def checked(self, **kwargs):
        result = completed(**kwargs)
        self.finalize([result], family_id="synthetic-policy-fixture")
        return result

    def put(self, value, name="result.json"):
        path = self.directory / name
        path.write_text(json.dumps(value))
        return path

    def ingest_pair(self):
        paths = [self.put(self.checked(rid=rid), rid + ".json") for rid in ("run-a", "run-b")]
        self.ledger.ingest_files(paths, self.evaluate)
        return paths

    def test_real_checked_receipts_support_two_hop_policy(self):
        self.ingest_pair()
        task, proposal = task_and_proof()
        result = check_against_ledger(task, proposal, self.ledger)
        self.assertTrue(result["check"]["answered"], result)
        self.assertEqual(result["check"]["max_depth"], 2)
        self.assertEqual(result["check"]["unique_evidence"], 2)
        self.assertEqual(len(result["dependencies"]), 2)
        self.assertEqual(result, check_against_ledger(task, proposal, self.ledger))

    def test_missing_run_and_forged_task_receipt_cannot_supply_support(self):
        task, proposal = task_and_proof()
        task["facts"][0]["verdict"] = "confirmed"
        task["facts"][0]["receipt"] = {"verdict": "confirmed", "evidence_id": "made-up"}
        result = check_against_ledger(task, proposal, self.ledger)
        self.assertFalse(result["check"]["answered"])
        self.assertEqual(result["check"]["errors"][0]["code"], "unconfirmed_fact")

    def test_withdrawal_changes_current_proof_and_preserves_historical_replay(self):
        with patch("oracle_bridge.utc_now", return_value="2026-01-01T00:00:00.000000Z"):
            paths = self.ingest_pair()
        task, proposal = task_and_proof()
        initial = check_against_ledger(task, proposal, self.ledger)
        with patch("oracle_bridge.utc_now", return_value="2026-02-01T00:00:00.000000Z"):
            self.ledger.withdraw("run-a", "replication withdrawn")
        self.assertFalse(check_against_ledger(task, proposal, self.ledger)["check"]["answered"])
        historical = check_against_ledger(task, proposal, self.ledger, as_of="2026-01-15")
        self.assertTrue(historical["check"]["answered"])
        self.assertEqual(historical["receipts_sha256"], initial["receipts_sha256"])
        self.ledger.ingest_files(paths, self.evaluate)
        self.assertFalse(check_against_ledger(task, proposal, self.ledger)["check"]["answered"])

    def test_complete_refutation_admits_only_the_signed_run_negative(self):
        self.ledger.ingest_files([self.put(self.checked(rid="run-a", p=.9))], self.evaluate)
        task, _ = task_and_proof()
        task["facts"] = task["facts"][:1]
        task["rules"] = []
        task["query"] = atom("passes_validation", "run-a")
        proposal = {"answer": "refuted", "steps": [{"id": "s0", "fact_id": "f-a"}], "conclusion": "s0"}
        result = check_against_ledger(task, proposal, self.ledger)
        self.assertTrue(result["check"]["answered"])
        self.assertEqual(result["check"]["answer"], "refuted")
        proposal["answer"] = "entailed"
        self.assertFalse(check_against_ledger(task, proposal, self.ledger)["check"]["accepted"])

    def test_claim_attribution_or_readable_text_cannot_change_bound_atom(self):
        self.ingest_pair()
        task, proposal = task_and_proof()
        task["facts"][0]["text"] = "This strategy is guaranteed profitable."
        receipts, _ = bind_receipts(task, self.ledger)
        self.assertEqual(receipts["f-a"]["atom"], atom("passes_validation", "run-a"))
        task["facts"][0]["oracle"]["kind"] = "source_claim_true"
        with self.assertRaises(ValueError):
            check_against_ledger(task, proposal, self.ledger)

    def test_rule_revision_changes_artifact_identity(self):
        self.ingest_pair()
        task, proposal = task_and_proof()
        before = check_against_ledger(task, proposal, self.ledger)
        revised = copy.deepcopy(task)
        revised["rules"][1]["body"].append(atom("passes_validation", "?x"))
        after = check_against_ledger(revised, proposal, self.ledger)
        self.assertNotEqual(before["artifact_id"], after["artifact_id"])
        self.assertFalse(after["check"]["answered"])


if __name__ == "__main__":
    unittest.main()
