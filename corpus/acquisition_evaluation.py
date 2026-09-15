"""Synthetic conditional-payoff/flow discrimination, with hidden scoring truth.

This is not financial data. Likelihoods, 40 future payoff opportunities, a .3
per-opportunity deployment hurdle and experiment costs are stipulated units.
The unconditioned gross payoff has zero mean even when a conditional edge exists.
"""
from __future__ import annotations

import argparse
from dataclasses import asdict,replace
import hashlib
import json
import math
from pathlib import Path
import random
import statistics

from acquisition import Model, Experiment, POLICIES, BellmanPlanner, choose, entropy, terminal_decision, update


def binary(name,positive,cost):
    return Experiment(name,("loss","gain"),tuple((1-p,p) for p in positive),cost)


def scenarios():
    actions = (
        binary("test:conditional_payoff",(.5,.8,.5,.8),1),
        binary("test:flow_proxy",(.1,.1,.9,.9),1),
        binary("test:marginal_payoff",(.5,.5,.5,.5),1),
        binary("test:noise_distractor",(.5,.5,.5,.5),1),
        binary("test:null_control",(.5,.5,.5,.5),1),
        binary("test:costly_payoff_measurement",(.02,.98,.02,.98),5),
    )
    model = Model("synthetic-conditional-flow-v1",("null","conditional_only","flow_only","conditional_and_flow"),
                  (.25,.25,.25,.25),("abstain","deploy"),((0.,)*4,(-12.,12.,-12.,12.)),actions,
                  "stipulated synthetic payoff units")
    result = []
    def add(name,assumed=model,truth_prior=None,truth_actions=None,budget=6,description=""):
        result.append({"name":name,"model":assumed,"truth_prior":truth_prior or model.prior,
                       "truth_actions":truth_actions or {a.id:a for a in assumed.experiments},
                       "budget":budget,"horizon":3,"description":description})
    add("calibrated",description="Assumed prior and likelihoods match the generator; flow and conditional payoff are distinct latent bits.")
    add("null_effect",truth_prior=(.5,0.,.5,0.),description="Actual conditional payoff is null; the policy does not know this restriction.")
    add("dead_marginal_interaction",truth_prior=(0.,.5,0.,.5),description="A selected context has positive expected payoff, its complement the opposite; balanced marginal gross payoff is zero.")
    distraction = binary("test:costly_flow_distraction",(.001,.001,.999,.999),5)
    add("costly_distraction",replace(model,id=model.id+":distraction",experiments=actions+(distraction,)),
        description="A costly, informative flow measurement has no payoff information under the factorized prior.")
    wrong = tuple(binary(a.id,(.1,.9,.1,.9),a.cost) if a.id == "test:flow_proxy" else a for a in actions)
    add("wrong_proxy_link",replace(model,id=model.id+":wrong-link",experiments=wrong),
        truth_actions={a.id:a for a in actions},description="The policy incorrectly models a flow proxy as measuring the payoff bit; it actually measures the independent flow bit.")
    add("prior_shift",replace(model,id=model.id+":optimistic-prior",prior=(.05,.45,.05,.45)),
        truth_prior=(.45,.05,.45,.05),description="Policy prior gives conditional edge probability .9; evaluation population gives .1.")
    add("budget_one",budget=1,description="Only one cheap observation is affordable; expensive tests must never run.")
    return result


def seeded(seed,*parts):
    digest = hashlib.sha256(":".join(map(str,(seed,)+parts)).encode()).digest()
    return random.Random(int.from_bytes(digest[:16],"big"))


def sample_index(probabilities,u):
    cumulative = 0.
    for i,p in enumerate(probabilities):
        cumulative += p
        if u < cumulative:
            return i
    return len(probabilities)-1


def mc_summary(values):
    mean = statistics.fmean(values)
    se = statistics.stdev(values)/math.sqrt(len(values)) if len(values)>1 else None
    return {"mean":mean,"mc_se":se,"normal_95_interval":None if se is None else [mean-1.96*se,mean+1.96*se],"n":len(values)}


def evaluate_case(case,replicates,seed):
    model,budget,horizon = case["model"],case["budget"],case["horizon"]
    planner = BellmanPlanner(model)
    records = {policy:[] for policy in POLICIES}
    test_counts = {policy:{a.id:0 for a in model.experiments} for policy in POLICIES}
    fixed = ("test:conditional_payoff","test:flow_proxy","test:conditional_payoff")
    for replicate in range(replicates):
        state = sample_index(case["truth_prior"],seeded(seed,case["name"],replicate,"state").random())
        # All policies receive the same independently generated nth observation
        # of an action and the same independent deployment outcomes.
        streams = {a.id:[seeded(seed,case["name"],replicate,a.id,j).random() for j in range(horizon)] for a in model.experiments}
        positive = .8 if state in (1,3) else .5
        future = [(.7 if seeded(seed,case["name"],replicate,"future",j).random()<positive else -1.3) for j in range(40)]
        true_deployment_mean = 40*(2*positive-1-.3)
        for policy in POLICIES:
            belief,remaining,history = model.prior,budget,[]
            used = {a.id:0 for a in model.experiments}
            rng = seeded(seed,case["name"],replicate,policy,"selection")
            for t in range(horizon):
                # Only the supplied model, belief and past observations enter
                # selection. Hidden state/true likelihood/future payoff do not.
                action_id = choose(model,belief,remaining,horizon-t,policy=policy,history=history,
                                   rng=rng,planner=planner,fixed_schedule=fixed)
                if action_id is None:
                    break
                action = model.action(action_id)
                actual = case["truth_actions"][action_id]
                index = sample_index(actual.likelihood[state],streams[action_id][used[action_id]])
                outcome = actual.outcomes[index]
                posterior = update(model,belief,action_id,outcome)
                history.append({"action_id":action_id,"outcome":outcome,"entropy_drop":entropy(belief)-entropy(posterior)})
                remaining -= action.cost
                assert remaining >= 0
                used[action_id] += 1
                test_counts[policy][action_id] += 1
                belief = posterior
            decision,model_terminal_value = terminal_decision(model,belief)
            spent = budget-remaining
            deployed = decision == "deploy"
            expected = (true_deployment_mean if deployed else 0.)-spent
            realized = (sum(future) if deployed else 0.)-spent
            records[policy].append({"realized_utility":realized,"true_expected_utility":expected,
                "clairvoyant_regret_with_cost":max(0.,true_deployment_mean)-expected,
                "cost":float(spent),"experiments":float(len(history)),"deployment_rate":float(deployed),
                "joint_state_log_loss":-math.log(belief[state]),
                "joint_state_brier":sum((p-float(i==state))**2 for i,p in enumerate(belief)),
                "model_terminal_value_before_cost":model_terminal_value})
    summaries = {policy:{key:mc_summary([row[key] for row in rows]) for key in rows[0]} for policy,rows in records.items()}
    paired = {policy:{key:mc_summary([row[key]-reference[key] for row,reference in zip(records[policy],records["bellman"])])
                      for key in ("realized_utility","true_expected_utility","cost")} for policy in POLICIES}
    return {"name":case["name"],"description":case["description"],"budget":budget,"horizon":horizon,
            "declared_model":asdict(model),"true_likelihoods":{key:action.likelihood for key,action in case["truth_actions"].items()},
            "model_prior":model.prior,"truth_prior":case["truth_prior"],
            "model_optimal_expected_value":planner.plan(model.prior,budget,horizon)["value"],
            "planning_work":{"used":planner.work_used,"limit":planner.work_limit},
            "clairvoyant_expected_value_before_experiment_cost":sum(p*max(0.,u) for p,u in zip(case["truth_prior"],(-12.,12.,-12.,12.))),
            "policies":summaries,"paired_policy_minus_bellman":paired,"selected_test_counts":test_counts}


def evaluate(*,replicates=600,seed=45101):
    if type(replicates) is not int or replicates < 2 or type(seed) is not int:
        raise ValueError("at least two replicates and an integer seed required")
    return {"schema":"synthetic-acquisition-v2","seed":seed,"replicates_per_case":replicates,
            "code_sha256":{name:hashlib.sha256(Path(__file__).with_name(name).read_bytes()).hexdigest()
                           for name in ("acquisition.py","acquisition_evaluation.py","oracle_bridge.py")},
            "stop_policy_semantics":"Stop measurements, then choose the best modeled terminal decision; not forced abstention.",
            "always_abstain_without_research_value":0.,
            "payoff_design":{"future_opportunities":40,"net_gain":.7,"net_loss":-1.3,
                             "conditional_gain_probabilities":(.5,.8,.5,.8),"balanced_marginal_gross_mean":0.,
                             "complement_context_gain_probabilities":(.5,.2,.5,.2)},
            "scope":"Stipulated synthetic hypotheses, likelihoods, costs and payoffs; no financial efficacy or calibration guarantee.",
            "uncertainty":"Replicate-level MC SE and descriptive normal intervals; paired differences share states/outcome streams. Not simultaneous coverage or model-validity guarantees.",
            "protocol":"All cases/policies retained. Bellman optimizes the assumed finite model; hidden truth scores policies separately. No generator or hyperparameter selection from outcomes.",
            "cases":[evaluate_case(case,replicates,seed) for case in scenarios()]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--replicates",type=int,default=600)
    parser.add_argument("--seed",type=int,default=45101)
    parser.add_argument("--output",type=Path)
    args = parser.parse_args()
    result = evaluate(replicates=args.replicates,seed=args.seed)
    if args.output:
        args.output.parent.mkdir(parents=True,exist_ok=True)
        args.output.write_text(json.dumps(result,indent=2,allow_nan=False)+"\n")
    for case in result["cases"]:
        print(json.dumps({"case":case["name"],"model_optimal_expected_value":case["model_optimal_expected_value"],
                          "realized_utility":{policy:metrics["realized_utility"]["mean"] for policy,metrics in case["policies"].items()}}))


if __name__ == "__main__":
    main()
