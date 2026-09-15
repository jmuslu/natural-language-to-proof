import json
import os
from pathlib import Path
import tempfile
import unittest

from reasoning.benchmark import fingerprint, suite
from reasoning.run import (PROMPT_VERSION, RUN_SCHEMA, SYSTEM, attempt_episode, aggregate,
                           atomic_json, load_client, parse_proposal, read_jsonl, replay,
                           reconcile_transport, source_hashes)


class RunnerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.module, cls.client_path = load_client(Path(os.environ.get("ORACLE_REPO", str(Path.home() / "projects"))))

    def invoke(self, arm, replies, ledger_path=None):
        episode = suite(split="dev", count=1)["episodes"][0]
        payloads = []
        def transport(method, url, headers, payload, timeout):
            payloads.append(payload)
            reply = replies.pop(0)
            if type(reply) is int:
                return self.module.HTTPResponse(reply, None)
            return self.module.HTTPResponse(200, {"model": "fixture-model",
                "choices": [{"finish_reason": "stop", "message": {"content": json.dumps(reply)}}],
                "usage": {"prompt_tokens": 20, "completion_tokens": 20, "total_tokens": 40}})
        config = self.module.ClientConfig("https://example.test/v1", "test-key", "fixture-model")
        client = self.module.ProposerClient(config, transport=transport, ledger_path=ledger_path)
        budget = self.module.Budget(100000, 2, 512, 10.)
        row = attempt_episode(episode, arm, client, budget)
        return row, payloads

    def test_verified_repair_uses_checker_error_without_gold_answer(self):
        episode = suite(split="dev", count=1)["episodes"][0]
        wrong = {"answer": "entailed", "steps": [{"id": "s0", "fact_id": "invented"}], "conclusion": "s0"}
        row, payloads = self.invoke("verified_repair", [wrong, episode["gold"]["proof"]])
        self.assertTrue(row["repaired"])
        self.assertTrue(row["supported_correct"])
        feedback = json.loads(payloads[1]["messages"][-1]["content"])
        self.assertEqual(set(feedback), {"checker_errors", "instruction"})
        self.assertFalse(any("gold" in msg["content"] for msg in payloads[0]["messages"]))

    def test_self_refine_gets_no_checker_feedback(self):
        proof = suite(split="dev", count=1)["episodes"][0]["gold"]["proof"]
        row, payloads = self.invoke("self_refine", [proof, proof])
        self.assertTrue(row["supported_correct"])
        self.assertEqual(len(payloads), 2)
        self.assertEqual(set(json.loads(payloads[1]["messages"][-1]["content"])), {"instruction"})

    def test_refinement_failure_preserves_prior_answer_and_accounts_cost(self):
        proof = suite(split="dev", count=1)["episodes"][0]["gold"]["proof"]
        row, _ = self.invoke("self_refine", [proof, 503])
        self.assertTrue(row["raw_correct"])
        self.assertEqual(row["selected_attempt"], 0)
        self.assertEqual(row["budget"]["calls_used"], 2)
        self.assertGreater(row["budget"]["tokens_charged"], 40)

    def test_unknown_is_abstention_not_a_grounded_answer(self):
        row, payloads = self.invoke("verified_repair", [{"answer": "unknown", "steps": [], "conclusion": None}])
        self.assertEqual(len(payloads), 1)
        self.assertFalse(row["answered"])
        self.assertFalse(row["raw_correct"])
        self.assertEqual(aggregate([row])["arms"]["verified_repair"]["answer_coverage"], 0.)

    def test_one_shot_does_not_use_unused_budget_as_hidden_retries(self):
        row, payloads = self.invoke("one_shot", [{"answer": "unknown", "steps": [], "conclusion": None}])
        self.assertEqual(len(payloads), 1)
        self.assertEqual(row["budget"]["calls_used"], 1)

    def test_parser_accepts_only_complete_json_and_optional_fence(self):
        self.assertEqual(parse_proposal('```json\n{"answer":"unknown"}\n```'), {"answer": "unknown"})
        with self.assertRaises(ValueError):
            parse_proposal('I think so: {"answer":"entailed"}')

    def recorded_run(self, directory, arm="one_shot"):
        directory = Path(directory)
        dataset = suite(split="dev", count=1)
        proof = dataset["episodes"][0]["gold"]["proof"]
        replies = [proof, proof] if arm == "self_refine" else [proof]
        row, _ = self.invoke(arm, replies, directory / "transport.jsonl")
        settings = {"schema": RUN_SCHEMA, "prompt_version": PROMPT_VERSION,
                    "prompt_sha256": fingerprint(SYSTEM), "manifest_sha256": dataset["manifest_sha256"],
                    "dataset_sha256": fingerprint(dataset), "client_code_path": str(self.client_path.resolve()),
                    "code_sha256": source_hashes(self.client_path), "arms": [arm],
                    "max_tokens": 100000, "max_calls": 2, "max_output_tokens": 512, "max_seconds": 10.}
        row["run_config_sha256"] = fingerprint(settings)
        atomic_json(directory / "benchmark_private.json", dataset)
        atomic_json(directory / "run_config.json", settings)
        (directory / "results.jsonl").write_text(json.dumps(row) + "\n")
        return row, dataset, settings

    def test_offline_replay_reconstructs_valid_proof_and_accounting(self):
        for arm in ("one_shot", "self_refine", "verified_repair"):
            with self.subTest(arm=arm), tempfile.TemporaryDirectory() as temp:
                row, _, _ = self.recorded_run(temp, arm)
                report = replay(temp)
                self.assertEqual(report["integrity_errors"], [])
                self.assertEqual(report["verification_differences"], [])
                self.assertEqual(report["summary"], aggregate([row]))

    def test_replay_reports_tampered_scores_and_uses_reconstructed_summary(self):
        with tempfile.TemporaryDirectory() as temp:
            row, _, _ = self.recorded_run(temp)
            row.update(raw_correct=False, supported_correct=False, selected_attempt=99, gold_answer="refuted")
            row["budget"]["tokens_charged"] = 0
            (Path(temp) / "results.jsonl").write_text(json.dumps(row) + "\n")
            report = replay(temp)
            self.assertEqual(report["integrity_errors"], [])
            changed = {diff["field"] for diff in report["verification_differences"]}
            self.assertTrue({"raw_correct", "supported_correct", "selected_attempt", "gold_answer", "budget"} <= changed)
            arm = report["summary"]["arms"]["one_shot"]
            self.assertEqual((arm["raw_answer_accuracy"], arm["supported_correct"], arm["tokens"]), (1., 1, 40))

    def test_replay_rejects_receipt_or_gold_tampering_even_when_task_unchanged(self):
        for change in ("receipt", "gold"):
            with self.subTest(change=change), tempfile.TemporaryDirectory() as temp:
                _, dataset, _ = self.recorded_run(temp)
                episode = dataset["episodes"][0]
                if change == "receipt":
                    next(iter(episode["receipts"].values()))["verdict"] = "refuted"
                else:
                    episode["gold"]["answer"] = "refuted"
                atomic_json(Path(temp) / "benchmark_private.json", dataset)
                report = replay(temp)
                self.assertTrue(report["integrity_errors"])
                self.assertIsNone(report["summary"])

    def test_replay_rejects_prompt_or_dependency_hash_changes(self):
        for change in ("prompt", "dependency"):
            with self.subTest(change=change), tempfile.TemporaryDirectory() as temp:
                _, _, settings = self.recorded_run(temp)
                if change == "prompt":
                    settings["prompt_sha256"] = "changed"
                else:
                    settings["code_sha256"]["retract.py"] = "changed"
                atomic_json(Path(temp) / "run_config.json", settings)
                self.assertTrue(replay(temp)["integrity_errors"])

    def test_orphan_dispatch_or_completed_call_refuses_resume_reconciliation(self):
        with tempfile.TemporaryDirectory() as temp:
            row, _, _ = self.recorded_run(temp)
            ledger = read_jsonl(Path(temp) / "transport.jsonl")
            reconcile_transport([row], ledger)
            with self.assertRaisesRegex(ValueError, "orphan transport reservation"):
                reconcile_transport([], ledger[:1])
            with self.assertRaisesRegex(ValueError, "orphan or mismatched"):
                reconcile_transport([], ledger)

    def test_partial_transport_line_is_not_silently_discarded(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "transport.jsonl"
            path.write_text('{"schema":"reasoning.attempt.v1"')
            with self.assertRaisesRegex(ValueError, "incomplete ledger"):
                read_jsonl(path)

    def test_replay_rejects_row_from_unrelated_run(self):
        with tempfile.TemporaryDirectory() as temp:
            row, _, _ = self.recorded_run(temp)
            row["run_config_sha256"] = "different-config"
            (Path(temp) / "results.jsonl").write_text(json.dumps(row) + "\n")
            self.assertTrue(replay(temp)["integrity_errors"])

    def test_replay_rejects_response_text_changed_after_transport(self):
        with tempfile.TemporaryDirectory() as temp:
            row, _, _ = self.recorded_run(temp)
            row["attempts"][0]["response"]["text"] = '{"answer":"unknown","steps":[],"conclusion":null}'
            (Path(temp) / "results.jsonl").write_text(json.dumps(row) + "\n")
            report = replay(temp)
            self.assertTrue(any("transport hash" in error for error in report["integrity_errors"]))


if __name__ == "__main__":
    unittest.main()
