"""Public synthetic designs, never private strategy conditions or data."""
import copy
import unittest

from mechanism_spec import SCHEMA, assess, fingerprint

CONTEXT = [{"artifact": "synthetic-lab-protocol"}]
INVENTORY = {"lab-events": {"status": "available", "fields": ["constraint", "flow", "price"],
                            "data_kind": "synthetic", "scope": {"environment": "synthetic-lab"}}}


def fixture():
    variables = [{"id": vid, "role": role, "description": description,
                  "construct": construct, "actor_refs": ["robot"],
                  "observable_ref": vid + "-obs", "source_refs": ["synthetic-lab-protocol"]}
                 for vid, role, description, construct in (
                     ("constraint", "constraint", "Synthetic robot capacity limit", "constraint"),
                     ("flow", "flow", "Logged synthetic aggressor flow", "aggressive_flow"),
                     ("price", "outcome", "Subsequent synthetic exchange price", "price"))]
    return {"schema": SCHEMA, "id": "synthetic-mechanism", "question": "Does a logged capacity intervention change subsequent prices through measured flow?",
            "actors": [{"id": "robot", "role": "Synthetic lab trading robot", "source_refs": ["synthetic-lab-protocol"]}],
            "variables": variables,
            "observables": [{"id": v["observable_ref"], "kind": "direct", "data_kind": "synthetic",
                             "data_ref": "lab-events", "required_fields": [v["id"]],
                             "data_scope": {"environment": "synthetic-lab"},
                             "measurement": "Read the named event field at its declared event timestamp.",
                             "units": "synthetic units", "available_after_seconds": 0} for v in variables],
            "links": [{"id": lid, "from": a, "to": b, "sign": "increase", "lag_seconds": [1, 5],
                       "rationale": why, "source_refs": ["synthetic-lab-protocol"]}
                      for lid, a, b, why in (("constraint-flow", "constraint", "flow", "Robot capacity changes its permitted signed order quantity."),
                                            ("flow-price", "flow", "price", "The matching engine consumes quotes in the logged order direction."))],
            "contrasts": [{"id": "lab-comparison", "edge_refs": ["constraint-flow", "flow-price"],
                           "kind": "intervention", "exposure_variable": "constraint", "exposure": "Randomly enabled capacity change at event zero.",
                           "control": "Identical simulated event seed with capacity unchanged.",
                           "outcome_variable": "price", "estimand": "Mean paired price difference at the declared horizon.",
                           "margin": .1, "margin_units": "synthetic units", "condition": "Synthetic laboratory session.",
                           "decision_time": "Event zero after exposure fields are available.",
                           "exposure_window_seconds": [-5, 0], "outcome_window_seconds": [2, 10],
                           "assumptions": ["The lab controller logs the randomized assignment.", "No unlogged actor changes between the paired worlds."]}]}


class MechanismSpecTests(unittest.TestCase):
    def check(self, spec=None, inventory=None, premises=()):
        return assess(fixture() if spec is None else spec, context_refs=CONTEXT,
                      data_inventory=INVENTORY if inventory is None else inventory, premises=premises)

    def test_explicit_synthetic_design_is_runnable_but_never_identified_or_checked(self):
        result = self.check()
        self.assertEqual(result["design_gaps"], [])
        self.assertTrue(result["mechanism_design_complete"])
        self.assertEqual(result["runnable_contrasts"], ["lab-comparison"])
        self.assertFalse(result["checked"])
        self.assertFalse(result["mechanism_identified"])
        self.assertFalse(result["execution_requested"])
        self.assertEqual(result["verdict"], "unknown")

    def test_data_availability_is_separate_from_design_and_identity(self):
        available, missing = self.check(), self.check(inventory={})
        self.assertEqual(available["spec_sha256"], missing["spec_sha256"])
        self.assertTrue(missing["mechanism_design_complete"])
        self.assertTrue(missing["contrasts"][0]["design_complete"])
        self.assertFalse(missing["contrasts"][0]["data_ready"])
        self.assertFalse(missing["contrasts"][0]["runnable"])
        self.assertEqual(missing["status"], "specified_contrasts_data_missing")
        self.assertNotEqual(fingerprint(available), fingerprint(missing))

    def test_self_declared_availability_and_missing_inventory_fields_do_not_admit(self):
        spec = fixture()
        spec["observables"][0]["available"] = True
        result = self.check(spec, inventory={})
        self.assertFalse(result["runnable_contrasts"])
        self.assertIn("unexpected_field", {g["code"] for g in result["design_gaps"]})
        result = self.check(inventory={"lab-events": {"status": "available", "fields": ["price"]}})
        self.assertFalse(result["contrasts"][0]["data_ready"])

    def test_wrong_instrument_interval_clock_or_coverage_cannot_supply_bar_data(self):
        spec = fixture()
        observation = spec["observables"][2]
        spec["variables"][2]["actor_refs"] = []
        observation.update(data_kind="ohlcv", data_scope={"instrument": "SYNTHETIC", "interval_seconds": 60,
            "timestamp_semantics": "bar_close", "timezone": "UTC", "price_basis": "raw-single-contract",
            "contract_basis": "individual-contract", "publication_delay_seconds": 0,
            "coverage_start": "2020-01-02", "coverage_end": "2020-01-03"}, data_ref="synthetic-bars")
        inventory = copy.deepcopy(INVENTORY)
        inventory["synthetic-bars"] = {"status": "available", "fields": ["price"], "data_kind": "ohlcv",
            "scope": {**observation["data_scope"], "coverage_start": "2020-01-01", "coverage_end": "2020-01-05"}}
        self.assertTrue(self.check(spec, inventory)["contrasts"][0]["data_ready"])
        self.assertFalse(self.check(spec, inventory)["contrasts"][0]["runnable"])
        self.assertIn("bar_resolution_mismatch", {g["code"] for g in self.check(spec, inventory)["design_gaps"]})
        self.assertIn("historical_availability_unverified", {g["code"] for g in self.check(spec, inventory)["design_gaps"]})
        for key, value in (("instrument", "OTHER"), ("interval_seconds", 86400),
                           ("timestamp_semantics", "bar_open"), ("timezone", "unknown"),
                           ("contract_basis", "unexplained-continuous-roll"), ("publication_delay_seconds", 2),
                           ("price_basis", "unexplained-continuous-series"), ("coverage_end", "2020-01-02")):
            with self.subTest(key=key):
                bad = copy.deepcopy(inventory); bad["synthetic-bars"]["scope"][key] = value
                self.assertFalse(self.check(spec, bad)["contrasts"][0]["data_ready"])
        changed = copy.deepcopy(inventory); changed["synthetic-bars"]["sha256"] = "different-raw-file"
        self.assertEqual(self.check(spec, inventory)["spec_sha256"], self.check(spec, changed)["spec_sha256"])
        self.assertNotEqual(self.check(spec, inventory)["data_inventory_sha256"], self.check(spec, changed)["data_inventory_sha256"])

    def test_bars_cannot_be_relabelled_as_participants_or_closing_positions(self):
        for construct in ("participant_identity", "position_change", "forced_closing", "aggressive_flow", "aggressive_order_flow"):
            for kind in ("direct", "proxy"):
                with self.subTest(construct=construct, kind=kind):
                    spec = fixture()
                    spec["variables"][1]["construct"] = construct
                    spec["observables"][1].update(data_kind="ohlcv", kind=kind)
                    result = self.check(spec)
                    self.assertFalse(result["mechanism_design_complete"])
                    self.assertFalse(result["runnable_contrasts"])
                    self.assertIn("bars_do_not_identify_participants", {g["code"] for g in result["design_gaps"]})

    def test_a_price_contrast_can_be_specified_while_participant_chain_is_latent(self):
        spec = fixture()
        state = copy.deepcopy(spec["variables"][2])
        state.update(id="past-price", role="state", observable_ref="past-price-obs", actor_refs=[])
        spec["variables"].append(state)
        observation = copy.deepcopy(spec["observables"][2]); observation["id"] = "past-price-obs"
        spec["observables"].append(observation)
        spec["variables"][0]["observable_ref"] = None
        spec["variables"][1]["observable_ref"] = None
        link = copy.deepcopy(spec["links"][1]); link.update(id="conditional-price", **{"from": "past-price"})
        spec["links"].append(link)
        contrast = spec["contrasts"][0]
        contrast.update(edge_refs=["conditional-price"], kind="conditional_association", exposure_variable="past-price", outcome_window_seconds=[1, 5])
        result = self.check(spec, inventory={})
        self.assertFalse(result["mechanism_design_complete"])
        self.assertEqual(result["testable_edges"], ["conditional-price"])
        self.assertEqual(result["latent_edges"], ["constraint-flow", "flow-price"])
        self.assertTrue(result["contrasts"][0]["design_complete"])
        self.assertFalse(result["contrasts"][0]["runnable"])
        self.assertIn("does not establish participant", result["contrasts"][0]["interpretation"])

    def test_artifact_or_biography_sources_cannot_supply_causal_variables(self):
        for premise in ({"claim_id": "validation:run", "provenance": {"claim_type": "run_validation"}},
                        {"claim_id": "biography", "domain": "biographical"}):
            spec = fixture()
            spec["variables"][0]["source_refs"] = [premise["claim_id"]]
            result = self.check(spec, premises=[premise])
            self.assertFalse(result["mechanism_design_complete"])
            self.assertFalse(result["runnable_contrasts"])
            self.assertIn("artifact_as_causal_source", {g["code"] for g in result["design_gaps"]})

    def test_actor_ids_unknown_refs_and_duplicate_ids_fail_closed(self):
        for change in ("actor_edge", "unknown_source", "duplicate", "unbound_variable", "bad_fields"):
            with self.subTest(change=change):
                spec = fixture()
                if change == "actor_edge": spec["links"][0]["from"] = "robot"
                elif change == "unknown_source": spec["links"][0]["source_refs"] = ["invented"]
                elif change == "duplicate": spec["variables"].append(copy.deepcopy(spec["variables"][0]))
                elif change == "unbound_variable": spec["links"][0]["from"] = ["invalid"]
                else: spec["variables"][0]["role"] = ["constraint"]
                result = self.check(spec)
                self.assertFalse(result["mechanism_design_complete"])

    def test_malformed_and_unbounded_input_returns_gaps(self):
        for spec in (None, [], {"schema": SCHEMA}, {"x": float("nan")}, {"x": "x" * 140000}):
            result = assess(spec)
            self.assertFalse(result["mechanism_design_complete"])
            self.assertFalse(result["runnable_contrasts"])
            self.assertTrue(result["design_gaps"])

    def test_exposure_and_observation_must_precede_decision(self):
        spec = fixture(); spec["contrasts"][0]["exposure_window_seconds"] = [-1, 1]
        self.assertFalse(self.check(spec)["runnable_contrasts"])
        spec = fixture(); spec["observables"][0]["available_after_seconds"] = 1
        result = self.check(spec)
        self.assertFalse(result["runnable_contrasts"])
        self.assertIn("observation_after_decision", {g["code"] for g in result["design_gaps"]})
        spec["contrasts"][0]["exposure_window_seconds"] = [-5, -1]
        spec["contrasts"][0]["outcome_window_seconds"] = [1, 9]
        self.assertTrue(self.check(spec)["runnable_contrasts"])

    def test_lags_upstream_outcomes_and_unrelated_edges_do_not_define_a_ready_contrast(self):
        spec = fixture()
        for link in spec["links"]: link["lag_seconds"] = [3600, 7200]
        result = self.check(spec)
        self.assertFalse(result["runnable_contrasts"])
        self.assertIn("contrast_lag_mismatch", {g["code"] for g in result["design_gaps"]})
        spec = fixture(); spec["contrasts"][0]["outcome_variable"] = "constraint"
        self.assertFalse(self.check(spec)["runnable_contrasts"])

    def test_bar_open_timestamps_include_full_bar_duration_before_availability(self):
        spec = fixture()
        spec["variables"][2]["actor_refs"] = []
        spec["observables"][2].update(data_kind="ohlcv", data_scope={"instrument": "SYNTHETIC", "interval_seconds": 60,
            "timestamp_semantics": "bar_open", "timezone": "UTC", "price_basis": "raw",
            "contract_basis": "individual-contract", "publication_delay_seconds": 0,
            "coverage_start": "2020-01-01", "coverage_end": "2020-01-02"})
        result = self.check(spec)
        self.assertIn("understated_observation_delay", {g["code"] for g in result["design_gaps"]})
        spec = fixture(); spec["contrasts"][0]["exposure_variable"] = "flow"
        self.assertFalse(self.check(spec)["runnable_contrasts"])

    def test_disconnected_roles_and_incomplete_estimand_are_explicit_gaps(self):
        spec = fixture(); spec["links"] = spec["links"][1:]
        self.assertIn("disconnected_mechanism", {g["code"] for g in self.check(spec)["design_gaps"]})
        spec = fixture(); del spec["contrasts"][0]["estimand"]
        self.assertFalse(self.check(spec)["runnable_contrasts"])


if __name__ == "__main__":
    unittest.main()
