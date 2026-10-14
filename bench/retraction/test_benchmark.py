"""Independent template expectations checked against the production graph adapter."""
import json
import os
from pathlib import Path
import subprocess
import sys
import unittest

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import generate
import spec
import score


class BenchmarkTests(unittest.TestCase):
    def test_seeded_generation_and_family_balance(self):
        first = generate.generate(20261013)
        self.assertEqual(first, generate.generate(20261013))
        self.assertEqual(64, len(first))
        self.assertEqual(64, len({x["id"] for x in first}))
        self.assertEqual({family: 8 for family in generate.FAMILIES},
                         {family: sum(x["stratum"] == family for x in first)
                          for family in generate.FAMILIES})
        self.assertEqual(set(spec.LABELS), {x["label"] for x in first})
        self.assertNotEqual([x["context"] for x in first],
                            [x["context"] for x in generate.generate(20261014)])

    def test_prompt_has_no_gold_or_structured_fixture_channel(self):
        row = generate.generate(20261013)[0]
        baseline = spec.prompt_body(row)
        changed = dict(row, expected={"label": "SECRET_GOLD"},
                       fixture={"SECRET_FIXTURE": "SECRET_FIXTURE"}, label="SECRET_GOLD")
        self.assertEqual(baseline, spec.prompt_body(changed))
        self.assertNotIn("SECRET", spec.prompt_body(changed))
        self.assertIn(row["context"], baseline)
        self.assertIn(row["statement"], baseline)

    def test_all_templates_against_production_graph(self):
        binary = os.environ.get("RETRACTION_BENCH_BIN")
        self.assertIsNotNone(binary, "set RETRACTION_BENCH_BIN to compiled RetractionBench")
        rows = generate.generate(20261013)
        inputs = [{"id": x["id"], "fixture": x["fixture"]} for x in rows]
        run = subprocess.run([binary], input="".join(json.dumps(x)+"\n" for x in inputs),
                             text=True, capture_output=True, check=True)
        actual = [json.loads(line) for line in run.stdout.splitlines()]
        self.assertEqual(len(rows), len(actual))
        for row, result in zip(rows, actual):
            with self.subTest(item=row["id"]):
                self.assertEqual(row["id"], result.pop("id"))
                self.assertEqual(row["expected"], result)

    def test_four_label_scoring(self):
        self.assertEqual('WeakOnly', score.strict_parse('**WeakOnly**.'))
        self.assertIsNone(score.strict_parse('weakonly'))
        for reply, wanted in [('weakonly', 'WeakOnly'),
                              ('Final answer: Conflict', 'Conflict'),
                              ('Unsupported. Final label: established', 'Established'),
                              ('Established / Unsupported', None),
                              ('Final answer: Established / Unsupported', None),
                              ('No answer available', None)]:
            with self.subTest(reply=reply):
                self.assertEqual(wanted, score.lenient_parse(reply))

    def test_malformed_admission_fails_closed(self):
        binary = os.environ.get("RETRACTION_BENCH_BIN")
        self.assertIsNotNone(binary)
        row = generate.generate(20261013)[0]
        row["fixture"]["seeds"][0]["kind"] = "magic-confirmed"
        run = subprocess.run([binary], input=json.dumps({"id": "bad", "fixture": row["fixture"]})+"\n",
                             text=True, capture_output=True, check=True)
        result = json.loads(run.stdout)
        self.assertIn("error", result)
        self.assertNotIn("label", result)


if __name__ == "__main__":
    unittest.main()
