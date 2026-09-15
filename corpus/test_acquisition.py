"""Independent finite policy-tree values, budget/likelihood contracts and annotation."""
from copy import deepcopy
from dataclasses import replace
from itertools import product
import math
import random
import unittest

from acquisition import (Experiment,Model,BellmanPlanner,PlanningBudgetExceeded,scores,choose,
                         update,entropy,distribution,annotate_proposals,annotation_matches,POLICIES)
from acquisition_evaluation import scenarios,evaluate_case


def example():
    return Model("two-tests",("bad","good"),(.8,.2),("abstain","deploy"),((0.,0.),(-50.,50.)),
                 (Experiment("informative",("negative","positive"),((.8,.2),(.2,.8)),1),
                  Experiment("noise",("negative","positive"),((.5,.5),(.5,.5)),1)),"synthetic units")


class AcquisitionTests(unittest.TestCase):
    def test_bellman_matches_independent_enumeration_of_all_tiny_policy_trees(self):
        model = example()
        def trees(budget,depth):
            result = [("terminal",i) for i in range(len(model.decisions))]
            if depth:
                for i,action in enumerate(model.experiments):
                    if action.cost <= budget:
                        children = trees(budget-action.cost,depth-1)
                        result.extend(("experiment",i,branches) for branches in product(children,repeat=len(action.outcomes)))
            return result
        def conditional_value(tree,state):
            if tree[0] == "terminal":
                return model.utilities[tree[1]][state]
            action = model.experiments[tree[1]]
            return -action.cost+sum(p*conditional_value(child,state) for p,child in zip(action.likelihood[state],tree[2]))
        # Direct likelihood products through complete policies, with no Bayesian
        # update/terminal-decision/planner function in the reference calculation.
        values = [sum(p*conditional_value(tree,state) for state,p in enumerate(model.prior)) for tree in trees(2,2)]
        planner = BellmanPlanner(model)
        self.assertAlmostEqual(planner.plan(model.prior,2,2)["value"],max(values),places=12)
        self.assertAlmostEqual(max(values),3.48,places=12)
        self.assertEqual(planner.plan(model.prior,2,2)["action_id"],"informative")
        # One observation cannot change the decision; two positives can. This
        # makes myopic stopping suboptimal under this declared finite model.
        self.assertIsNone(choose(model,model.prior,2,2,policy="decision_value"))
        self.assertEqual(planner.plan(model.prior,2,1)["value"],0.)

    def test_expected_information_is_not_random_outcome_entropy(self):
        model = example()
        by_id = {row["test_id"]:row for row in scores(model,model.prior,2)}
        self.assertAlmostEqual(by_id["noise"]["expected_information_gain"],0.,places=12)
        self.assertAlmostEqual(by_id["informative"]["expected_information_gain"],entropy((.68,.32))-entropy((.8,.2)),places=12)
        self.assertEqual(choose(model,model.prior,2,2,policy="eig"),"informative")
        self.assertEqual(choose(model,model.prior,2,2,policy="last_entropy_drop"),"noise")

    def test_planning_work_exhaustion_has_no_provisional_optimal_result(self):
        model = example()
        planner = BellmanPlanner(model,max_work=4)
        with self.assertRaises(PlanningBudgetExceeded) as error:
            planner.plan(model.prior,2,2)
        self.assertEqual((error.exception.work_used,error.exception.work_limit),(4,4))
        self.assertEqual(error.exception.reason,"planning_work_budget_exhausted")
        self.assertFalse(hasattr(error.exception,"action_id"))
        self.assertFalse(hasattr(error.exception,"value"))
        with self.assertRaises(PlanningBudgetExceeded):
            planner.plan(model.prior,2,2)

    def test_exact_cached_answers_survive_exhaustion_but_recomputation_is_charged(self):
        model = example()
        planner = BellmanPlanner(model,max_work=1)
        expected = planner.plan(model.prior,2,0)
        self.assertEqual(planner.plan(model.prior,2,0),expected)
        with self.assertRaises(PlanningBudgetExceeded):
            planner.plan(model.prior,2,1)
        self.assertEqual(planner.plan(model.prior,2,0),expected)
        planner._solve.cache_clear()  # Same invariant as eviction of this entry.
        with self.assertRaises(PlanningBudgetExceeded):
            planner.plan(model.prior,2,0)

    def test_model_branching_has_explicit_input_caps(self):
        with self.assertRaises(ValueError):
            replace(example(),states=(str(i) for i in range(1000000)))
        with self.assertRaises(ValueError):
            Experiment("too-many-outcomes",tuple(str(i) for i in range(9)),((1/9,)*9,)*2,1)

    def test_zero_budget_and_finite_horizon_stop_all_policies(self):
        model = example()
        for policy in POLICIES:
            for budget,steps in ((0,2),(2,0)):
                self.assertIsNone(choose(model,model.prior,budget,steps,policy=policy,rng=random.Random(1),fixed_schedule=("informative",)))
        for budget in (-1,True,.5):
            with self.assertRaises(ValueError):
                scores(model,model.prior,budget)

    def test_impossible_observation_is_explicit_and_inputs_are_immutable(self):
        model = Model("zero-support",("a","b"),(.5,.5),("abstain",),((0.,0.),),
                      (Experiment("certain",("yes","no"),((1.,0.),(1.,0.)),1),),"units")
        prior = model.prior
        with self.assertRaises(ValueError):
            update(model,prior,"certain","no")
        self.assertEqual(model.prior,prior)
        with self.assertRaises(ValueError):
            Experiment("bad",("a","b"),((.2,.2),),1)
        with self.assertRaises(ValueError):
            Experiment("free",("a",),((1.,),),0)

    def test_proposal_scores_preserve_unknown_trust_and_missing_models(self):
        model = example()
        proposal = {"id":"discovery:x","kind":"explore_mechanism","status":"proposed", "priority":7,
                    "discovery_only":True,"checked":False,"verdict":"unknown",
                    "claim_refs_role":"attribution_only","mechanism_links":[{"id":"link","status":"proposed_unknown"}],
                    "discriminating_tests":[{"id":"informative","status":"design_required"},{"id":"not_modeled"}]}
        before = deepcopy(proposal)
        annotated = annotate_proposals([proposal],model,model.prior,1)[0]
        self.assertEqual(proposal,before)
        for key,value in before.items():
            self.assertEqual(annotated[key],value)
        self.assertEqual(annotated["acquisition"]["basis"],"stipulated_likelihoods")
        self.assertEqual(annotated["acquisition"]["tests"][1],{"test_id":"not_modeled","status":"unmodeled"})
        self.assertEqual(annotated["acquisition"]["temporal_status"],"undated_design_only")
        self.assertIsNone(annotated["acquisition"]["eligible_at_as_of"])
        self.assertTrue(annotation_matches(annotated,model))
        self.assertFalse(annotation_matches(annotated,model,as_of="2020-01-02"))

    def test_historical_scores_require_model_and_observation_availability(self):
        model = example()
        proposal = {"id":"discovery:dated","as_of":"2020-01-02","historically_preregistered":False,
                    "checked":False,"verdict":"unknown","discriminating_tests":[{"id":"informative"}]}
        for kwargs in ({}, {"model_as_of":"2020-01-01"},
                       {"model_as_of":"2026-01-01","posterior_as_of":"2020-01-01"},
                       {"model_as_of":"2020-01-01","posterior_as_of":"2026-01-01"}):
            annotated = annotate_proposals([proposal],model,model.prior,2,**kwargs)[0]
            record = annotated["acquisition"]
            self.assertFalse(record["eligible_at_as_of"])
            self.assertIsNone(record["posterior"])
            self.assertNotIn("net_decision_value",record["tests"][0])
            self.assertEqual(record["tests"][0]["status"],"temporally_ineligible")
            self.assertFalse(annotation_matches(annotated,model))
        valid = annotate_proposals([proposal],model,model.prior,2,
                  model_as_of="2020-01-01T19:00:00-05:00",posterior_as_of="2020-01-02T12:00:00Z")[0]
        self.assertTrue(valid["acquisition"]["eligible_at_as_of"])
        self.assertEqual(valid["acquisition"]["model_as_of"],"2020-01-02T00:00:00.000000Z")
        self.assertTrue(annotation_matches(valid,model,as_of="2020-01-02"))
        self.assertFalse(annotation_matches(valid,model,as_of="2020-01-01"))
        self.assertEqual(valid["as_of"],proposal["as_of"])
        self.assertFalse(valid["historically_preregistered"])
        self.assertFalse(valid["checked"])

    def test_stricter_history_request_excludes_future_and_undated_proposals(self):
        model = example()
        for proposal in ({"as_of":"2020-01-03"},{"as_of":None}):
            proposal["discriminating_tests"] = [{"id":"informative"}]
            record = annotate_proposals([proposal],model,model.prior,2,model_as_of="2019-01-01",
                                       posterior_as_of="2019-01-01",as_of="2020-01-02")[0]["acquisition"]
            self.assertFalse(record["eligible_at_as_of"])
            self.assertNotIn("net_decision_value",record["tests"][0])
        with self.assertRaises(ValueError):
            annotate_proposals([],model,model.prior,2,model_as_of="2020-01-01T12:00:00")

    def test_score_model_posterior_and_proposal_bindings_reject_stale_annotation(self):
        model = example()
        proposal = {"id":"discovery:x","as_of":"2020-01-02","priority":1,
                    "discriminating_tests":[{"id":"informative"}]}
        annotated = annotate_proposals([proposal],model,model.prior,2,
                  model_as_of="2020-01-01",posterior_as_of="2020-01-01")[0]
        altered_model = replace(model,utilities=((0.,0.),(-10.,10.)))
        self.assertEqual(altered_model.id,model.id)
        self.assertFalse(annotation_matches(annotated,altered_model))
        for change in ("score","posterior","proposal","time"):
            bad = deepcopy(annotated)
            if change == "score": bad["acquisition"]["tests"][0]["net_decision_value"] = 999.
            elif change == "posterior": bad["acquisition"]["posterior"] = [.1,.9]
            elif change == "proposal": bad["priority"] = 9
            else: bad["acquisition"]["model_as_of"] = "2026-01-01"
            self.assertFalse(annotation_matches(bad,model),change)

    def test_normalization_is_idempotent_for_retained_posterior_bindings(self):
        for seed in (26,248,270,364,513):
            rng = random.Random(seed)
            raw = [rng.random() for _ in range(16)]
            belief = tuple(x/sum(raw) for x in raw)
            normalized = distribution(belief)
            self.assertEqual(math.fsum(normalized),1.)
            self.assertEqual(distribution(normalized),normalized)
            model = Model("sixteen",tuple(map(str,range(16))),belief,("none",),((0.,)*16,),(),"units")
            annotated = annotate_proposals([{"id":"proposal"}],model,belief,1)[0]
            self.assertTrue(annotation_matches(annotated,model))

    def test_malformed_retained_annotations_fail_closed(self):
        model = example()
        for proposal in (None,[],"bad",{}, {"acquisition":None},{"acquisition":[]},{"acquisition":"bad"}):
            self.assertFalse(annotation_matches(proposal,model))
        annotated = annotate_proposals([{"discriminating_tests":[{"id":"informative"}]}],model,model.prior,1)[0]
        annotated["discriminating_tests"] = [None]
        self.assertFalse(annotation_matches(annotated,model))

    def test_dead_marginal_fixture_preserves_conditional_effect(self):
        model = scenarios()[0]["model"]
        marginal = model.action("test:marginal_payoff")
        conditional = model.action("test:conditional_payoff")
        self.assertEqual({row[1] for row in marginal.likelihood},{.5})
        for state in (1,3):
            self.assertAlmostEqual(.5*conditional.likelihood[state][1]+.5*.2,.5)
            self.assertAlmostEqual(40*(2*conditional.likelihood[state][1]-1-.3),model.utilities[1][state])
        self.assertEqual(scores(model,model.prior,6)[2]["expected_information_gain"],0.)

    def test_evaluation_retains_all_policies_and_reports_paired_uncertainty(self):
        case = next(case for case in scenarios() if case["name"] == "budget_one")
        report = evaluate_case(case,6,45101)
        self.assertEqual(set(report["policies"]),set(POLICIES))
        for policy in POLICIES:
            metrics = report["policies"][policy]
            self.assertLessEqual(metrics["cost"]["mean"],1.)
            self.assertLessEqual(metrics["experiments"]["mean"],1.)
            self.assertEqual(metrics["realized_utility"]["n"],6)
            self.assertTrue(math.isfinite(metrics["realized_utility"]["mc_se"]))
            self.assertEqual(report["selected_test_counts"][policy]["test:costly_payoff_measurement"],0)
        self.assertEqual(report["paired_policy_minus_bellman"]["bellman"]["realized_utility"]["mc_se"],0.)
        self.assertEqual(report["policies"]["stop"]["cost"]["mean"],0.)
        self.assertEqual(report,evaluate_case(case,6,45101))


if __name__ == "__main__":
    unittest.main()
