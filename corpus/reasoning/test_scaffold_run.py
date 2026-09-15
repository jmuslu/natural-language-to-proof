"""Offline transport fixtures for durable scaffold evaluation; no service calls."""
import contextlib
import copy
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from reasoning import benchmark, run, scaffold_run as driver


class DriverTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.module, cls.client_path = run.load_client(
            Path(os.environ.get("ORACLE_REPO", str(Path.home() / "projects"))))

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.dataset = benchmark.suite("offline-scaffold-fixture", "dev", 3)
        self.config = self.module.ClientConfig("https://fixture.invalid/v1", "fixture-not-a-key",
                                               "fixture-model", reasoning_effort="medium", timeout_seconds=60.)
        self.payloads = []
        self.replies = None

    def scripted_transport(self, method, url, headers, payload, timeout):
        self.payloads.append(copy.deepcopy(payload))
        if self.replies is not None:
            reply = self.replies.pop(0)
            if type(reply) is int:
                return self.module.HTTPResponse(reply, None)
        elif payload["messages"][0]["content"] == driver.SYSTEM:
            view = json.loads(payload["messages"][-1]["content"])["local_tool"]
            known = [k["atom"] for k in view["known"]]
            query = view["query"]
            opposite = {**query, "negated": not query["negated"]}
            positive, negative = query in known, opposite in known
            if positive or negative:
                reply = {"finish": "entailed" if positive and not negative else "refuted" if negative and not positive else "unknown"}
            elif view["candidates"]:
                reply = {"select": [c["id"] for c in view["candidates"][:32]]}
            else:
                reply = {"finish": "unknown"}
        else:
            reply = {"answer": "unknown", "steps": [], "conclusion": None}
        return self.module.HTTPResponse(200, {"model": self.config.model,
            "choices": [{"finish_reason": "stop", "message": {"content": json.dumps(reply)}}],
            "usage": {"prompt_tokens": 30, "completion_tokens": 20, "total_tokens": 50,
                      "completion_tokens_details": {"reasoning_tokens": 7}}})

    def settings(self, arms=None, **caps):
        return driver.settings_for(self.dataset, self.config.public_identity(), self.client_path,
                                   list(arms or driver.ARMS), **caps)

    def execute(self, settings=None, *, resume=False):
        settings = settings or self.settings()
        client = self.module.ProposerClient(self.config, transport=self.scripted_transport,
                                           ledger_path=self.directory / "transport.jsonl")
        def budget():
            return self.module.Budget(settings["max_tokens"], settings["max_calls"],
                                      settings["max_output_tokens"], settings["max_seconds"])
        with contextlib.redirect_stdout(io.StringIO()):
            return driver.execute(self.directory, self.dataset, settings, client, budget, resume=resume)

    def rows(self):
        return run.read_jsonl(self.directory / "results.jsonl")

    def write_rows(self, rows):
        (self.directory / "results.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rows))

    def test_all_arms_replay_exactly_with_explicit_effort_and_no_network(self):
        summary = self.execute()
        report = driver.replay(self.directory)
        self.assertEqual(report["records"], 12)
        self.assertEqual(report["verification_differences"], [])
        self.assertEqual(report["integrity_errors"], [])
        self.assertEqual(report["summary"], summary)
        self.assertTrue(all(p["reasoning_effort"] == "medium" for p in self.payloads))
        self.assertEqual(summary["arms"]["deterministic_search"]["calls"], 0)
        self.assertEqual(summary["arms"]["scaffold"]["supported_correct"], 2)
        self.assertEqual(summary["arms"]["scaffold"]["correct_unknowns"], 1)
        self.assertEqual(summary["arms"]["scaffold"]["complete_symbolic_searches"], 0)
        self.assertGreater(summary["arms"]["scaffold"]["reported_reasoning_tokens"], 0)

    def test_prompts_contain_only_public_task_and_local_observations(self):
        self.execute()
        for payload in self.payloads:
            for message in payload["messages"]:
                self.assertNotIn('"gold"', message["content"])
                self.assertNotIn('"gold_answer"', message["content"])
                self.assertNotIn('"proof"', message["content"])
                self.assertNotIn('"receipts"', message["content"])
        scaffold = next(p for p in self.payloads if p["messages"][0]["content"] == driver.SYSTEM)
        content = json.loads(scaffold["messages"][1]["content"])
        self.assertEqual(set(content), {"task", "local_tool"})

    def test_each_scaffold_prompt_keeps_current_state_without_repeated_history(self):
        self.dataset = benchmark.suite("compact-prompt-fixture", "dev", 1)
        self.execute(self.settings(["scaffold"]))
        self.assertGreater(len(self.payloads), 2)
        observations = []
        for payload in self.payloads:
            self.assertEqual([m["role"] for m in payload["messages"]], ["system", "user"])
            observation = json.loads(payload["messages"][1]["content"])
            self.assertEqual(observation["task"], benchmark.public_task(self.dataset["episodes"][0]))
            observations.append(observation)
        self.assertNotIn("last_action_result", observations[0])
        attempts = self.rows()[0]["attempts"]
        for i, observation in enumerate(observations[1:], 1):
            self.assertEqual(observation["last_action_result"], attempts[i - 1]["feedback"])
            self.assertGreaterEqual(len(observation["local_tool"]["known"]),
                                    len(observations[i - 1]["local_tool"]["known"]))
        self.assertEqual(driver.replay(self.directory)["verification_differences"], [])

    def test_paired_metrics_count_both_directions_and_only_matched_episodes(self):
        self.execute(self.settings(["scaffold"]))
        template = self.rows()[0]
        rows = []
        for i, (left, right) in enumerate(((True, True), (True, False),
                                         (False, True), (False, False))):
            for arm, correct in (("scaffold", left), ("one_shot", right),
                                 ("verified_repair", right)):
                rows.append({**template, "episode_id": str(i), "arm": arm,
                             "raw_correct": correct, "supported_correct": correct and i != 0})
        rows.append({**template, "episode_id": "unmatched", "arm": "scaffold"})
        paired = driver.aggregate(rows)["paired"]
        for comparison in paired.values():
            self.assertEqual(comparison["paired_episodes"], 4)
            self.assertEqual(comparison["unpaired_scaffold_episodes"], 1)
            self.assertEqual(comparison["unpaired_plain_episodes"], 0)
            self.assertEqual(comparison["raw_correct"],
                             {"both": 1, "scaffold_only": 1, "plain_only": 1, "neither": 1})
            self.assertEqual(comparison["supported_correct"],
                             {"both": 0, "scaffold_only": 1, "plain_only": 1, "neither": 2})
        with self.assertRaisesRegex(ValueError, "duplicate"):
            driver.aggregate(rows + [rows[0]])

    def test_resume_does_not_repeat_completed_calls(self):
        settings = self.settings()
        self.execute(settings)
        before = len(self.payloads)
        self.execute(settings, resume=True)
        self.assertEqual(len(self.payloads), before)

    def test_orphan_dispatch_refuses_resume_before_any_more_calls(self):
        settings = self.settings(["one_shot"])
        self.execute(settings)
        ledger = self.directory / "transport.jsonl"
        reserved = next(e for e in run.read_jsonl(ledger) if e["status"] == "reserved")
        reserved = {**reserved, "reservation_id": "orphan-fixture"}
        with ledger.open("a") as stream:
            stream.write(json.dumps(reserved) + "\n")
        before = len(self.payloads)
        with self.assertRaisesRegex(ValueError, "orphan"):
            self.execute(settings, resume=True)
        self.assertEqual(len(self.payloads), before)

    def test_orphan_records_without_config_refuse_new_run(self):
        (self.directory / "transport.jsonl").write_text("")
        with self.assertRaisesRegex(ValueError, "orphan"):
            self.execute()
        self.assertEqual(self.payloads, [])

    def test_tampered_actions_scores_and_local_work_are_recomputed(self):
        self.execute(self.settings(["scaffold"]))
        rows = self.rows()
        rows[0]["raw_correct"] = not rows[0]["raw_correct"]
        rows[0]["tool_result"]["work"]["atom_match_attempts"] += 1
        rows[0]["attempts"][0]["action"] = {"finish": "unknown"}
        self.write_rows(rows)
        report = driver.replay(self.directory)
        self.assertEqual(report["integrity_errors"], [])
        self.assertTrue({"raw_correct", "tool_result", "attempts"} <=
                        {d["field"] for d in report["verification_differences"]})

    def test_modified_response_text_fails_transport_hash(self):
        self.execute(self.settings(["scaffold"]))
        rows = self.rows()
        rows[0]["attempts"][0]["response"]["text"] = '{"finish":"unknown"}'
        self.write_rows(rows)
        self.assertTrue(driver.replay(self.directory)["integrity_errors"])

    def test_dataset_code_prompt_or_config_tampering_fails_closed(self):
        self.execute(self.settings(["one_shot"]))
        path = self.directory / "run_config.json"
        original = json.loads(path.read_text())
        for change in ("code_sha256", "prompt_sha256", "dataset_sha256", "max_rounds", "model"):
            with self.subTest(change=change):
                bad = copy.deepcopy(original)
                if change == "model":
                    bad["model"]["requested_reasoning_effort"] = "none"
                elif change == "max_rounds":
                    bad[change] += 1
                else:
                    bad[change] = "tampered"
                run.atomic_json(path, bad)
                self.assertTrue(driver.replay(self.directory)["integrity_errors"])
        run.atomic_json(path, original)

    def test_round_limit_abstention_is_not_model_unknown_or_complete_search(self):
        self.dataset = benchmark.suite("round-budget-fixture", "dev", 1)
        self.execute(self.settings(["scaffold"], max_rounds=1))
        row = self.rows()[0]
        self.assertIsNone(row["raw_answer"])
        self.assertFalse(row["raw_correct"])
        self.assertEqual(row["answer"], "unknown")
        self.assertEqual(row["tool_result"]["answer_origin"], "bounded_policy_abstention")
        self.assertNotIn("search_complete", row["tool_result"])
        self.assertEqual(driver.replay(self.directory)["verification_differences"], [])

    def test_transport_failure_does_not_trigger_hidden_execution(self):
        self.dataset = benchmark.suite("transport-fixture", "dev", 1)
        self.replies = [503]
        self.execute(self.settings(["scaffold"]))
        row = self.rows()[0]
        self.assertEqual(len(self.payloads), 1)
        self.assertEqual(row["stop_reason"], "transport_error")
        self.assertEqual(row["tool_result"]["work"]["selected_applications"], 0)
        self.assertEqual(driver.replay(self.directory)["integrity_errors"], [])

    def test_symbolic_baseline_needs_no_client_or_budget_and_replays(self):
        settings = self.settings(["deterministic_search"])
        with contextlib.redirect_stdout(io.StringIO()):
            summary = driver.execute(self.directory, self.dataset, settings, None,
                                     lambda: self.fail("symbolic arm created paid budget"))
        self.assertEqual(self.payloads, [])
        self.assertFalse((self.directory / "transport.jsonl").exists())
        self.assertEqual(summary["arms"]["deterministic_search"]["complete_symbolic_searches"], 3)
        self.assertEqual(driver.replay(self.directory)["integrity_errors"], [])

    def test_writer_lock_and_changed_supplied_dataset_prevent_calls(self):
        lock = self.directory / ".writer.lock"
        lock.write_text('{"pid": 1}')
        with self.assertRaisesRegex(ValueError, "writer lock"):
            self.execute()
        self.assertEqual(self.payloads, [])
        lock.unlink()
        settings = self.settings()
        self.dataset["episodes"][0]["task"]["id"] = "changed-after-freeze"
        with self.assertRaisesRegex(ValueError, "supplied dataset"):
            self.execute(settings)
        self.assertEqual(self.payloads, [])
        self.assertFalse(lock.exists())

    def test_mismatched_client_or_budget_prevents_dispatch(self):
        settings = self.settings(["scaffold"])
        wrong = copy.deepcopy(settings)
        wrong["model"]["requested_reasoning_effort"] = "none"
        with self.assertRaisesRegex(ValueError, "client identity"):
            self.execute(wrong)
        client = self.module.ProposerClient(self.config, transport=self.scripted_transport,
                                           ledger_path=self.directory / "transport.jsonl")
        with self.assertRaisesRegex(ValueError, "dispatch budget"):
            driver.execute(self.directory, self.dataset, settings, client,
                           lambda: self.module.Budget(1000, 1, 128, 10.))
        self.assertEqual(self.payloads, [])

    def test_authentication_or_credit_refusal_stops_every_remaining_pair(self):
        for status in (401, 402, 403):
            with self.subTest(status=status):
                self.directory = Path(self.temp.name) / str(status)
                self.payloads = []
                self.replies = [status]
                settings = self.settings()
                summary = self.execute(settings)
                self.assertEqual(len(self.payloads), 1)
                self.assertEqual(len(self.rows()), 1)
                self.assertEqual(summary["completion"]["status"], "interrupted")
                self.assertFalse(summary["completion"]["complete"])
                self.assertEqual(summary["completion"]["expected_pairs"], 12)
                self.assertEqual(summary["completion"]["recorded_pairs"], 1)
                self.assertEqual(summary["completion"]["unattempted_pair_count"], 11)
                self.assertEqual(set(summary["arms"]), {"one_shot"})
                self.assertEqual(summary["arms"]["one_shot"]["pairs_with_completed_model_response"], 0)
                self.assertEqual(summary["completion"]["by_arm"]["scaffold"]["recorded_pairs"], 0)
                marker = json.loads((self.directory / "interruption.json").read_text())
                self.assertEqual(marker["http_status"], status)
                self.assertEqual(marker["run_instance_id"], settings["run_instance_id"])
                self.assertFalse(marker["resume_allowed"])
                report = driver.replay(self.directory)
                self.assertEqual(report["integrity_errors"], [])
                self.assertEqual(report["verification_differences"], [])
                self.assertEqual(report["summary"], summary)
                with self.assertRaisesRegex(ValueError, "resume is forbidden"):
                    self.execute(settings, resume=True)
                self.assertEqual(len(self.payloads), 1)

    def test_prior_deterministic_and_model_results_remain_without_later_slots(self):
        self.replies = [{"answer": "unknown", "steps": [], "conclusion": None}, 402]
        summary = self.execute(self.settings(["deterministic_search", "one_shot", "scaffold"]))
        self.assertEqual(len(self.payloads), 2)
        self.assertEqual([r["arm"] for r in self.rows()], ["deterministic_search", "one_shot", "scaffold"])
        self.assertEqual(summary["completion"]["expected_pairs"], 9)
        self.assertEqual(summary["completion"]["unattempted_pair_count"], 6)
        self.assertEqual(summary["arms"]["deterministic_search"]["episodes"], 1)
        self.assertEqual(summary["arms"]["one_shot"]["pairs_with_completed_model_response"], 1)
        self.assertEqual(summary["paired"]["scaffold_vs_one_shot"]["paired_episodes"], 1)

    def test_refusal_during_repair_retains_earlier_response_but_never_claims_completion(self):
        self.dataset = benchmark.suite("refused-repair-fixture", "dev", 1)
        self.replies = [{"answer": "entailed", "steps": [], "conclusion": None}, 403]
        summary = self.execute(self.settings(["verified_repair"]))
        self.assertEqual(len(self.payloads), 2)
        self.assertEqual(self.rows()[0]["selected_attempt"], 0)
        self.assertEqual(self.rows()[0]["raw_answer"], "entailed")
        self.assertTrue(summary["completion"]["all_planned_pairs_recorded"])
        self.assertFalse(summary["completion"]["complete"])
        self.assertEqual(summary["completion"]["unattempted_pair_count"], 0)
        self.assertEqual(summary["arms"]["verified_repair"]["pairs_with_completed_model_response"], 1)
        self.assertEqual(driver.replay(self.directory)["verification_differences"], [])

    def test_missing_or_tampered_marker_cannot_bypass_retained_fatal_refusal(self):
        self.replies = [402]
        settings = self.settings()
        self.execute(settings)
        marker = self.directory / "interruption.json"
        marker.unlink()
        with self.assertRaisesRegex(ValueError, "resume is forbidden"):
            self.execute(settings, resume=True)
        self.assertTrue(marker.is_file())
        saved = json.loads(marker.read_text())
        run.atomic_json(marker, {**saved, "http_status": 200})
        with self.assertRaisesRegex(ValueError, "interruption report differs"):
            self.execute(settings, resume=True)
        self.assertEqual(len(self.payloads), 1)
        self.assertTrue(driver.replay(self.directory)["integrity_errors"])

    def test_resume_finds_refusal_when_either_durable_copy_is_missing(self):
        for missing in ("results.jsonl", "transport.jsonl"):
            with self.subTest(missing=missing):
                self.directory = Path(self.temp.name) / missing.replace(".", "-")
                self.payloads = []; self.replies = [401]
                settings = self.settings()
                self.execute(settings)
                (self.directory / missing).unlink()
                (self.directory / "interruption.json").unlink()
                with self.assertRaisesRegex(ValueError, "resume is forbidden"):
                    self.execute(settings, resume=True)
                self.assertEqual(len(self.payloads), 1)
                summary = json.loads((self.directory / "summary.json").read_text())
                self.assertEqual(summary["completion"]["status"], "interrupted")
                self.assertEqual(summary["completion"]["unreconciled_dispatches"], 1)
                self.assertIsNone(summary["completion"]["unattempted_pair_count"])
                self.assertTrue(driver.replay(self.directory)["integrity_errors"])

    def test_crash_after_refusal_row_before_marker_still_blocks_resume(self):
        self.replies = [403]
        settings = self.settings()
        original = driver.checked_interruption
        def fail_marker(directory, config, rows, ledger, **kwargs):
            if driver.interruption_for(config, rows, ledger):
                raise OSError("fixture crash before interruption marker")
            return original(directory, config, rows, ledger, **kwargs)
        with mock.patch.object(driver, "checked_interruption", side_effect=fail_marker):
            with self.assertRaisesRegex(OSError, "fixture crash"):
                self.execute(settings)
        self.assertEqual(len(self.rows()), 1)
        with self.assertRaisesRegex(ValueError, "resume is forbidden"):
            self.execute(settings, resume=True)
        self.assertEqual(len(self.payloads), 1)
        self.assertEqual(driver.replay(self.directory)["integrity_errors"], [])

    def test_fatal_recovery_withholds_corrupt_scores_and_mismatched_events(self):
        for corruption in ("scores", "same_reservation_event"):
            with self.subTest(corruption=corruption):
                self.directory = Path(self.temp.name) / corruption
                self.payloads = []; self.replies = [402]
                settings = self.settings()
                self.execute(settings)
                rows = self.rows()
                if corruption == "scores":
                    rows[0].update(raw_correct=True, supported_correct=True, answered=True)
                else:
                    rows[0]["attempts"][0]["response"]["attempts"][0]["http_status"] = 403
                self.write_rows(rows)
                with self.assertRaisesRegex(ValueError, "resume is forbidden"):
                    self.execute(settings, resume=True)
                self.assertEqual(len(self.payloads), 1)
                summary = json.loads((self.directory / "summary.json").read_text())
                self.assertEqual(summary["arms"], {})
                self.assertEqual(summary["paired"], {})
                self.assertFalse(summary["integrity"]["verified"])
                self.assertTrue(summary["integrity"]["errors"] or summary["integrity"]["verification_differences"])
                self.assertFalse(summary["completion"]["complete"])
                self.assertIsNone(summary["completion"]["unattempted_pair_count"])

    def test_http_words_in_model_text_do_not_trigger_endpoint_refusal(self):
        answer = {"answer": "unknown", "steps": [], "conclusion": None, "comment": "HTTP 401 402 403"}
        self.replies = [answer, answer, answer]
        summary = self.execute(self.settings(["one_shot"]))
        self.assertTrue(summary["completion"]["complete"])
        self.assertEqual(len(self.payloads), 3)
        self.assertFalse((self.directory / "interruption.json").exists())

    def test_new_run_gets_new_identity_and_old_refused_identity_remains_stopped(self):
        settings = self.settings(["one_shot"])
        self.replies = [402]
        self.execute(settings)
        self.directory = Path(self.temp.name) / "fresh-after-external-resolution"
        self.replies = None
        fresh = self.settings(["one_shot"])
        self.assertNotEqual(settings["run_instance_id"], fresh["run_instance_id"])
        self.assertTrue(self.execute(fresh)["completion"]["complete"])

    def cli(self, *, resume=False):
        args = ["scaffold_run", "--run-dir", str(self.directory), "--seed", "offline-scaffold-fixture",
                "--count", "3", "--connection-service", "fixture", "--reasoning-effort", "medium",
                "--arms", "one_shot"] + (["--resume"] if resume else [])
        real_client = self.module.ProposerClient
        def client(config, **kwargs):
            return real_client(config, transport=self.scripted_transport, **kwargs)
        with mock.patch("sys.argv", args), mock.patch.object(driver.run, "load_client", return_value=(self.module, self.client_path)), \
                mock.patch.object(self.module, "load_running_service_config", return_value=self.config), \
                mock.patch.object(self.module, "ProposerClient", side_effect=client), contextlib.redirect_stdout(io.StringIO()):
            driver.main()

    def test_cli_exits_nonzero_for_interruption(self):
        self.replies = [402]
        with self.assertRaises(SystemExit) as raised:
            self.cli()
        self.assertEqual(raised.exception.code, 2)
        self.assertEqual(len(self.payloads), 1)

    def test_cli_normal_resume_preserves_saved_instance_identity(self):
        self.cli()
        saved = (self.directory / "run_config.json").read_bytes()
        count = len(self.payloads)
        self.cli(resume=True)
        self.assertEqual((self.directory / "run_config.json").read_bytes(), saved)
        self.assertEqual(len(self.payloads), count)

    def test_legacy_artifacts_are_rejected_without_rewriting_them(self):
        settings = self.settings(["one_shot"])
        self.execute(settings)
        legacy = {**settings, "schema": "reasoning.scaffold-run.v1"}
        legacy.pop("run_instance_id")
        run.atomic_json(self.directory / "run_config.json", legacy)
        before = {p.name: p.read_bytes() for p in self.directory.iterdir() if p.is_file()}
        count = len(self.payloads)
        with self.assertRaisesRegex(ValueError, "unsupported scaffold run"):
            self.execute(legacy, resume=True)
        self.assertEqual({p.name: p.read_bytes() for p in self.directory.iterdir() if p.is_file()}, before)
        self.assertEqual(len(self.payloads), count)


if __name__ == "__main__":
    unittest.main()
