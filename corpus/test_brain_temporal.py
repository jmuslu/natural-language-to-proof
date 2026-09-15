"""Historical queries cannot use future observations for ranking or calibration.

Uses a real libSQL Brain and deterministic offline hashing embeddings. Run with
the corpus virtualenv: python -m unittest discover -s corpus -p test_brain_temporal.py
"""
import json
import tempfile
import unittest
from pathlib import Path

from brain import Brain
from brain_agenda import build_agenda


EARLY = "2026-09-14T12:00:00Z"
CUTOFF = "2026-09-14T21:00:00Z"


class HistoricalBrainTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.past = [
            ("a", "market research alpha signal", .8, EARLY),
            ("b", "market research beta signal", -.7, EARLY),
            ("c", "market research residual corner", 0, EARLY),
            ("d", "historical risk feature experiment", 0, EARLY),
            ("offset", "known observation at the exact boundary", .5, "2026-09-15T01:00:00+04:00"),
        ]
        extra = [("day", "publication date with no intraday timestamp", .3, "2026-09-14"),
                 ("midnight", "observation known next UTC day", 1, "2026-09-15T00:00:00Z"),
                 ("unknown", "observation with unknown publication date", 1, None)]
        extra += [(f"future-{i}", "historical risk feature experiment", 1 if i % 2 else -1,
                   "2026-09-20T00:00:00Z") for i in range(12)]
        self.brain = self.build("all", self.past + extra)
        self.reference = self.build("historical", self.past)

    def build(self, name, facts):
        folder = self.root / name
        folder.mkdir()
        index = {"claims": {cid: {"text": text, "knowable_time": known,
                                 "domain": "alternate" if cid == "offset" else "fixture",
                                 "claim_type": "run_validation" if cid.startswith("validation:")
                                               else "factual_quantitative",
                                 "evidence_basis": "oracle_receipt" if cid.startswith("validation:")
                                                   else "public_reference", "source_id": "fixture"}
                             for cid, text, trust, known in facts}}
        graph = {"nodes": [{"id": "claim:" + cid, "kind": "claim", "trust": trust}
                           for cid, text, trust, known in facts]}
        (folder / "index.json").write_text(json.dumps(index))
        (folder / "graph.json").write_text(json.dumps(graph))
        brain = Brain.build(str(folder / "index.json"), str(folder / "graph.json"),
                            str(folder / "brain.db"), prefer="hashing")
        self.addCleanup(brain.con.close)
        return brain

    def test_build_normalizes_dates_and_offsets_conservatively(self):
        times = dict(self.brain.con.cursor().execute("SELECT id,knowable_time FROM facts").fetchall())
        self.assertEqual(times["day"], "2026-09-14T23:59:59.999999Z")
        self.assertEqual(times["offset"], "2026-09-14T21:00:00.000000Z")
        self.assertIsNone(times["unknown"])

    def test_offset_query_does_not_leak_future_utc_observation(self):
        ids = set(self.brain._all(as_of="2026-09-15T01:00:00+04:00")[0])
        self.assertEqual(ids, {row[0] for row in self.past})
        self.assertNotIn("midnight", ids)
        self.assertNotIn("day", ids)
        self.assertNotIn("unknown", ids)
        self.assertEqual(ids, set(self.brain._all(as_of=CUTOFF)[0]))

    def test_date_includes_its_full_day_but_not_next_midnight(self):
        ids = set(self.brain._all(as_of="2026-09-14")[0])
        self.assertIn("day", ids)
        self.assertNotIn("midnight", ids)
        self.assertNotIn("unknown", ids)
        before_end = set(self.brain._all(as_of="2026-09-14T23:59:59.999998Z")[0])
        self.assertNotIn("day", before_end)

    def test_legacy_database_timestamps_are_normalized_on_read(self):
        self.brain.con.cursor().execute("UPDATE facts SET knowable_time=? WHERE id='day'", ("2026-09-14",))
        self.brain.con.cursor().execute("UPDATE facts SET knowable_time=? WHERE id='offset'",
                                        ("2026-09-15T01:00:00+04:00",))
        self.brain.con.commit()
        self.assertEqual(set(self.brain._all(as_of=CUTOFF)[0]), {row[0] for row in self.past})
        ids = {f.id for f in self.brain.retrieve("market research", k=50, as_of=CUTOFF)}
        self.assertEqual(ids, {row[0] for row in self.past})

    def test_retrieval_and_ann_rank_only_the_historical_snapshot(self):
        for ann in (False, True):
            for weighted in (False, True):
                with self.subTest(ann=ann, weighted=weighted):
                    actual = self.brain.retrieve("historical risk feature experiment", k=5,
                                                as_of=CUTOFF, ann=ann, trust_weighted=weighted)
                    expected = self.reference.retrieve("historical risk feature experiment", k=5,
                                                       as_of=CUTOFF, ann=ann, trust_weighted=weighted)
                    self.assertEqual(actual, expected)
                    self.assertEqual(len(actual), 5)

    def test_calibration_and_inference_license_ignore_future_labels(self):
        actual = self.brain.calibrate(as_of=CUTOFF)
        expected = self.reference.calibrate(as_of=CUTOFF)
        self.assertEqual(actual, expected)
        # Legacy score-only fixtures have no direct observed evidence.
        self.assertEqual(actual["n_checked"], 0)
        self.assertEqual(self.brain.infer_trust("market research signal", as_of=CUTOFF),
                         self.reference.infer_trust("market research signal", as_of=CUTOFF))

    def test_frontier_and_answer_selection_ignore_future_centrality(self):
        for mode in ("gaps", "contested", "all"):
            self.assertEqual(self.brain.explore_frontier(k=100, mode=mode, as_of=CUTOFF),
                             self.reference.explore_frontier(k=100, mode=mode, as_of=CUTOFF))
        actual = self.brain.answer("market research residual corner", k=100, min_sim=0, as_of=CUTOFF)
        expected = self.reference.answer("market research residual corner", k=100, min_sim=0, as_of=CUTOFF)
        self.assertIsNotNone(actual["proposed_next_check"])
        self.assertEqual(actual, expected)

    def test_empty_history_does_not_use_future_calibration(self):
        end = "2020-01-01"
        self.assertEqual(self.brain.retrieve("market research", as_of=end), [])
        self.assertEqual(self.brain.calibrate(as_of=end)["status"], "insufficient")
        self.assertEqual(self.brain.calibrate(as_of=end)["n"], 0)
        self.assertEqual(self.brain.explore_frontier(as_of=end), [])
        result = self.brain.infer_trust("market research", as_of=end)
        self.assertEqual(result["neighbors"], [])
        self.assertIsNot(result["imputation_licensed"], True)

    def test_bridges_learning_curve_and_stats_use_historical_snapshot(self):
        actual = self.brain.bridge_hypotheses(k=100, lo=-1, hi=1, as_of=CUTOFF)
        expected = self.reference.bridge_hypotheses(k=100, lo=-1, hi=1, as_of=CUTOFF)
        self.assertEqual(expected, [])  # no provenance, so no confirmed endpoints
        self.assertEqual(actual, expected)
        self.assertEqual(self.brain.learning_curve(sizes=(1, 2), repeats=4, as_of=CUTOFF),
                         self.reference.learning_curve(sizes=(1, 2), repeats=4, as_of=CUTOFF))
        self.assertEqual(self.brain.stats(as_of=CUTOFF), self.reference.stats(as_of=CUTOFF))

    def test_agenda_has_no_future_facts_or_calibration(self):
        actual = build_agenda(self.brain, k_gaps=100, k_contested=100, k_bridges=100, as_of=CUTOFF)
        expected = build_agenda(self.reference, k_gaps=100, k_contested=100, k_bridges=100, as_of=CUTOFF)
        self.assertTrue(actual["items"])
        self.assertEqual(actual, expected)
        historical_ids = {row[0] for row in self.past}
        for item in actual["items"]:
            self.assertLessEqual(set(item["claim_refs"]), historical_ids)
        self.assertEqual(build_agenda(self.brain, as_of="2020-01-01")["items"], [])

    def test_unknown_statistical_run_requests_receipt_repair(self):
        brain = self.build("receipts", [
            ("validation:pending", "Backtest run pending passed validation gates.", 0, EARLY),
            ("validation:legacy", "Backtest run legacy passed validation gates.", 0, EARLY),
            ("validation:future", "Backtest run future passed validation gates.", 0, "2026-09-20"),
        ])
        # A legacy statistical type must keep this route even without its basis tag.
        brain.con.cursor().execute("UPDATE facts SET evidence_basis='' WHERE id='validation:legacy'")
        brain.con.commit()
        agenda = build_agenda(brain, k_gaps=100, as_of=CUTOFF)
        self.assertEqual(len(agenda["items"]), 2)
        for item in agenda["items"]:
            self.assertEqual(item["kind"], "repair_oracle_receipt")
            self.assertEqual(item["claim_refs_role"], "attribution_only")
            self.assertIn("validation certificate", item["question"])
            self.assertIn("rerun", item["question"])
            self.assertEqual(item["status"], "proposed")
        self.assertNotIn("reverse-propagate", agenda["note"])

    def test_naive_or_malformed_query_timestamp_is_rejected(self):
        for end in ("2026-09-14T21:00:00", "not-a-date"):
            for query in (self.brain._all, self.brain.calibrate, self.brain.explore_frontier):
                with self.assertRaises(ValueError):
                    query(as_of=end)
            with self.assertRaises(ValueError):
                self.brain.retrieve("market", as_of=end)


if __name__ == "__main__":
    unittest.main()
