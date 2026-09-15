import copy
from collections import Counter
import unittest

from reasoning.benchmark import make_episode, public_task, reference, suite
from reasoning.engine import evaluate


class BenchmarkTests(unittest.TestCase):
    def test_independent_reference_witnesses_pass_checker(self):
        for split, count in (("dev", 12), ("test", 45)):
            data = suite(split=split, count=count)
            for episode in data["episodes"]:
                result = evaluate(episode["task"], episode["gold"]["proof"], episode["receipts"])
                with self.subTest(split=split, metadata=episode["metadata"]):
                    self.assertTrue(result.accepted, result.to_dict())
                    self.assertEqual(result.verdict, episode["gold"]["answer"])

    def test_test_split_covers_heldout_depths_and_relational_topologies(self):
        dev, test = suite(split="dev", count=12), suite(count=45)
        self.assertEqual({e["metadata"]["depth"] for e in dev["episodes"]}, {2, 3})
        self.assertEqual({e["metadata"]["depth"] for e in test["episodes"]}, {4, 6, 8})
        self.assertEqual({e["metadata"]["topology"] for e in test["episodes"]},
                         {"chain", "branch", "relational", "alternate", "cycle"})
        self.assertFalse({e["task"]["id"] for e in dev["episodes"]} & {e["task"]["id"] for e in test["episodes"]})
        combinations = {(e["metadata"]["depth"], e["metadata"]["topology"], e["gold"]["answer"])
                        for e in test["episodes"]}
        self.assertEqual(len(combinations), 45)
        for label in ("entailed", "refuted", "unknown"):
            self.assertEqual({e["metadata"]["depth"] for e in test["episodes"][:15]
                              if e["gold"]["answer"] == label}, {4, 6, 8})

    def test_gold_labels_and_receipt_internals_are_excluded_from_prompts(self):
        for episode in suite(count=6)["episodes"]:
            prompt = public_task(episode)
            self.assertEqual(set(prompt), {"id", "entities", "predicates", "facts", "rules", "question"})
            self.assertNotIn("gold", prompt)
            self.assertNotIn("answer", prompt)
            self.assertNotIn("receipts", prompt)
            self.assertFalse(any("body" in rule or "head" in rule for rule in prompt["rules"]))

    def test_reference_changes_when_authoritative_leaf_is_withdrawn(self):
        episode = suite(count=1)["episodes"][0]
        receipts = copy.deepcopy(episode["receipts"])
        for receipt in receipts.values():
            receipt["verdict"] = "unknown"
        self.assertEqual(reference(episode["task"], receipts)["answer"], "unknown")
        self.assertEqual(episode["gold"]["answer"], "entailed")

    def test_reference_and_manifest_are_deterministic(self):
        a, b = suite(count=9), suite(count=9)
        self.assertEqual(a, b)
        self.assertNotEqual(a["manifest_sha256"], suite(seed="new-seed", count=9)["manifest_sha256"])

    def test_counterfactual_labels_share_structure_and_shallow_statistics(self):
        for topology in ("chain", "branch", "relational", "alternate", "cycle"):
            episodes = [make_episode("paired", "test", 7, 6, topology, label)
                        for label in ("entailed", "refuted", "unknown")]
            self.assertEqual({e["gold"]["answer"] for e in episodes},
                             {"entailed", "refuted", "unknown"})
            # Same task graph and facts, differing only which evidence is usable.
            self.assertTrue(all(e["task"] == episodes[0]["task"] for e in episodes))
            def shallow(e):
                return Counter((r["verdict"], tuple(r["atom"]["args"]))
                               for r in e["receipts"].values())
            self.assertTrue(all(shallow(e) == shallow(episodes[0]) for e in episodes))


if __name__ == "__main__":
    unittest.main()
