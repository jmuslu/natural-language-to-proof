"""Cross-repository boundary tests. ORACLE_REPO selects the companion checkout.

Fixtures here are explicitly synthetic certificate audits. The final test also
runs the actual statistical validator on planted/noise return series; neither is
evidence for an economic strategy. No live services or market data are used.
"""
import copy
import importlib
import json
import os
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest

from build_graph import build
from ingest_outcomes import (augmented_index, ingest_outcome, materialize,
                             revision_report, support_graph)
from oracle_bridge import ReceiptLedger, checked_receipt, load_evaluator, verify_haskell

HERE = Path(__file__).resolve().parent
QR = Path(os.environ.get("ORACLE_REPO", str(Path.home() / "projects"))).expanduser().resolve()


def completed(rid="synthetic-pass", *, p=.001, oos=True):
    folds = [1., 2., 1.5] if oos else [-1., -2., -1.5]
    return {"status": "completed", "run_id": rid,
            "attribution": {"hypothesis_id": "shared-hypothesis", "claim_refs": ["003-a"]},
            "validation": {"passed": oos and p <= .05, "passed_oos": oos, "passed_null": p <= .05,
                           "alpha": .05, "null_pvalue": p, "random_timing_pvalue": p,
                           "null_n_perm": 2000, "n_obs": 120, "fdr_survivor": None,
                           "walk_forward": {"n_splits": 3, "out_of_sample_sharpe": folds,
                                            "mean_oos_sharpe": 1.5 if oos else -1.5,
                                            "oos_positive_fraction": 1. if oos else 0., "consistent": oos}}}


class OracleBridgeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.evaluate = staticmethod(load_evaluator(QR))
        sys.path.insert(0, str(QR / "shared/backtesting/validation"))
        cls.finalize = staticmethod(importlib.import_module("apply_run_fdr").finalize_results)

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.directory = Path(self.temp.name)
        self.ledger = ReceiptLedger(self.directory / "ledger.sqlite")
        self.addCleanup(self.temp.cleanup)
        self.addCleanup(self.ledger.close)

    def checked(self, **kwargs):
        result = completed(**kwargs)
        self.finalize([result], family_id="synthetic-family")
        return result

    def put(self, result, filename="result.json"):
        path = self.directory / filename
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(result))
        return path

    def test_replay_is_durable_and_does_not_add_edges_or_trust(self):
        result = self.checked()
        path = self.put(result)
        self.assertEqual(self.ledger.ingest_files([path], self.evaluate)[0]["action"], "added")
        first = self.ledger.snapshots()
        self.assertEqual(self.ledger.ingest_files([path, path], self.evaluate)[0]["action"], "unchanged")
        self.assertEqual(first, self.ledger.snapshots())
        graph = build()
        ingest_outcome(graph, result, evaluator=self.evaluate)
        graph.propagate()
        edges, trust = len(graph.edges), graph.trust_of("claim:validation:synthetic-pass")
        ingest_outcome(graph, result, evaluator=self.evaluate)
        graph.propagate()
        self.assertEqual((edges, trust), (len(graph.edges), graph.trust_of("claim:validation:synthetic-pass")))
        reopened = ReceiptLedger(self.ledger.path)
        try:
            self.assertEqual(first, reopened.snapshots())
        finally:
            reopened.close()

    def test_source_attribution_does_not_become_a_truth_verdict(self):
        graph = build()
        initial = graph.trust_of("claim:003-a")
        for result in (self.checked(), self.checked(rid="negative", p=.9)):
            ingest_outcome(graph, result, evaluator=self.evaluate)
        graph.propagate()
        self.assertEqual(graph.trust_of("claim:003-a"), initial)
        self.assertEqual(graph.trust_of("claim:validation:synthetic-pass"), 1.)
        self.assertEqual(graph.trust_of("claim:validation:negative"), -1.)
        self.assertFalse(any(e.kind == "implicates" for e in graph.edges))

    def test_malformed_booleans_and_leg_patterns_cannot_override_oracle(self):
        for value in ("false", 1, None):
            result = self.checked()
            result["validation"]["passed"] = value
            result["grounding"] = [{"effect": 9999, "stderr": .01}]
            self.assertEqual(checked_receipt(result, self.evaluate)["verdict"], "unknown")
        for legs in ([], [{"effect": 9999}], None):
            result = {"run_id": "uncertified", "grounding": legs, "validation": {"passed": True}}
            self.assertEqual(checked_receipt(result, self.evaluate)["verdict"], "unknown")

    def test_revision_removes_old_support_and_preserves_history(self):
        path = self.put(self.checked())
        self.ledger.ingest_files([path], self.evaluate)
        before = self.ledger.snapshots()
        self.put(completed())  # same run now lacks a finalized family
        self.ledger.ingest_files([path], self.evaluate)
        after = self.ledger.snapshots()
        self.assertEqual(after[0]["verdict"], "unknown")
        self.assertEqual(self.ledger.snapshots(before[0]["observed_at"]), before)
        self.assertEqual(self.ledger.snapshots("2000-01-01"), [])
        report = revision_report(before, after)
        self.assertEqual(report["withdrawn"], ["oracle:synthetic-pass", "passes_validation:synthetic-pass"])
        graph, _ = materialize(after)
        self.assertEqual(graph.trust_of("claim:validation:synthetic-pass"), 0.)
        self.assertEqual(augmented_index(after)["claims"]["validation:synthetic-pass"]["knowable_time"], after[0]["observed_at"])

    def test_withdrawal_survives_default_file_replay_and_can_be_explicitly_reinstated(self):
        path = self.put(self.checked())
        self.ledger.ingest_files([path], self.evaluate)
        revision = self.ledger.snapshots()[0]["revision"]
        self.ledger.withdraw("synthetic-pass", "bad measurement")
        self.assertEqual(self.ledger.withdraw("synthetic-pass", "bad measurement")["action"], "unchanged")
        self.assertEqual(self.ledger.ingest_files([path], self.evaluate)[0]["action"], "stale_replay")
        self.assertEqual(self.ledger.snapshots()[0]["verdict"], "unknown")
        self.ledger.reinstate(revision, "measurement independently rechecked")
        self.assertEqual(self.ledger.snapshots()[0]["verdict"], "confirmed")
        self.assertEqual(self.ledger.snapshots()[0]["reinstated_from_revision"], revision)

    def test_stale_certificate_cannot_replace_newer_refutation(self):
        good = self.checked()
        path = self.put(good)
        self.ledger.ingest_files([path], self.evaluate)
        self.put(self.checked(p=.9))
        self.ledger.ingest_files([path], self.evaluate)
        self.put(good)
        self.assertEqual(self.ledger.ingest_files([path], self.evaluate)[0]["action"], "stale_replay")
        self.assertEqual(self.ledger.snapshots()[0]["verdict"], "refuted")

    def test_attribution_edits_cannot_resurrect_withdrawn_evidence(self):
        result = self.checked()
        path = self.put(result)
        self.ledger.ingest_files([path], self.evaluate)
        self.ledger.withdraw("synthetic-pass", "external check withdrawn")
        result["attribution"]["claim_refs"] = ["003-b", "003-a", "003-a"]
        self.put(result)
        self.assertEqual(self.ledger.ingest_files([path], self.evaluate)[0]["action"], "stale_replay")
        self.assertEqual(self.ledger.snapshots()[0]["verdict"], "unknown")

    def test_invalid_replacement_does_not_leave_stale_confirmation(self):
        path = self.put(self.checked())
        self.ledger.ingest_files([path], self.evaluate)
        path.write_text('{"validation": NaN}')
        self.ledger.ingest_files([path], self.evaluate)
        receipt = self.ledger.snapshots()[0]
        self.assertEqual((receipt["run_id"], receipt["verdict"]), ("synthetic-pass", "unknown"))

    def test_conflicting_batch_is_atomic(self):
        good = self.put(self.checked(), "a.json")
        bad = self.put(self.checked(p=.9), "b.json")
        with self.assertRaisesRegex(ValueError, "conflicting"):
            self.ledger.ingest_files([good, bad], self.evaluate)
        self.assertEqual(self.ledger.snapshots(), [])

    def test_distinct_runs_with_same_filename_or_hypothesis_do_not_alias(self):
        files = [self.put(self.checked(rid="a"), "a/result.json"),
                 self.put(self.checked(rid="b", p=.9), "b/result.json")]
        self.ledger.ingest_files(files, self.evaluate)
        self.assertEqual(len(self.ledger.snapshots()), 2)
        graph, _ = materialize(self.ledger.snapshots())
        self.assertEqual(graph.trust_of("claim:validation:a"), 1.)
        self.assertEqual(graph.trust_of("claim:validation:b"), -1.)

    def test_identity_errors_are_not_transport_injection(self):
        result = self.checked(rid="bad\tconfirmed\tinjected")
        receipt = checked_receipt(result, self.evaluate)
        self.assertEqual(receipt["verdict"], "unknown")
        self.assertTrue(receipt["run_id"].startswith("unidentified:"))
        with self.assertRaises(FileNotFoundError):
            load_evaluator(self.directory / "absent")

    def test_python_and_real_haskell_seam_agree_on_all_three_verdicts(self):
        results = [self.checked(rid="yes"), self.checked(rid="no", p=.9), completed("pending")]
        paths = [self.put(result, f"{i}.json") for i, result in enumerate(results)]
        self.ledger.ingest_files(paths, self.evaluate)
        receipts = self.ledger.snapshots()
        hs = verify_haskell(receipts, self.directory / "receipts.tsv", HERE.parent)
        self.assertEqual(hs["fused_claims"], 1)
        self.assertEqual(hs["reward"]["confirmed"], 1)
        self.assertEqual(hs["reward"]["refuted"], 1)
        self.assertEqual(hs["reward"]["unknown"], 1)
        grounded = support_graph(receipts).grounded()
        self.assertEqual({r["run_id"] for r in hs["runs"] if r["grounded"]},
                         {r["run_id"] for r in receipts if "passes_validation:" + r["run_id"] in grounded})

    def test_pipeline_executes_oracle_then_builds_graph(self):
        path = self.put(self.checked())
        runtime = self.directory / "runtime"
        command = [sys.executable, str(HERE / "pipeline.py"), "--oracle-only", "--results", str(path),
                   "--oracle-repo", str(QR), "--runtime-dir", str(runtime)]
        subprocess.run(command, check=True, capture_output=True, text=True, timeout=120)
        report = json.loads((runtime / "pipeline_report.json").read_text())
        self.assertEqual([r["stage"] for r in report], ["oracle", "graph"])
        self.assertEqual(report[0]["haskell"]["fused_claims"], 1)
        subprocess.run(command, check=True, capture_output=True, text=True, timeout=120)
        report = json.loads((runtime / "oracle_report.json").read_text())
        self.assertEqual(report["actions"], {"unchanged": 1})

    def test_actual_statistical_validator_to_disk_to_receipt(self):
        from stats import validate_signal
        rng = random.Random(42)
        market = [rng.gauss(0., .01) for _ in range(360)]
        returns = [max(value, 0.) for value in market]  # explicit planted perfect timing
        certificate = validate_signal("synthetic-perfect-timing", returns, market_returns=market,
                                      n_perm=499, seed=17).to_dict()
        result = {"run_id": "synthetic-engine", "status": "completed", "validation": certificate}
        path = self.directory / "engine.json"
        self.finalize([result], paths=[path], family_id="synthetic-engine-family")
        self.ledger.ingest_files([path], self.evaluate)
        self.assertEqual(self.ledger.snapshots()[0]["verdict"], "confirmed")


if __name__ == "__main__":
    unittest.main()
