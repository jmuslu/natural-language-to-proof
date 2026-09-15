"""Finite Bayesian experiment design under explicitly supplied likelihoods.

Information gain concerns all declared states; decision value concerns the
supplied terminal utilities. Neither authenticates a mechanism or observation.
Costs and utilities must share one stipulated unit. Budgets use integer units.
"""
from __future__ import annotations

from copy import deepcopy
from dataclasses import asdict,dataclass
from functools import lru_cache
from itertools import islice
import math

from oracle_bridge import cutoff,digest

MAX_STATES,MAX_EXPERIMENTS,MAX_OUTCOMES,MAX_DECISIONS = 16,16,8,8


def _bounded(values,limit):
    values = tuple(islice(values,limit+1))
    if len(values)>limit:
        raise ValueError("finite model input size limit exceeded")
    return values


def _finite(value):
    try:
        valid = type(value) in (int,float) and math.isfinite(value)
    except OverflowError:
        valid = False
    if not valid:
        raise ValueError("finite numbers required")
    return float(value)


def _names(values,maximum=MAX_STATES):
    values = _bounded(values,maximum)
    if not values or any(not isinstance(v,str) or not v.strip() for v in values) or len(set(values)) != len(values):
        raise ValueError("distinct nonempty names required")
    return values


def distribution(values, size=None):
    values = tuple(_finite(x) for x in _bounded(values,size if size is not None else MAX_STATES))
    total = math.fsum(values)
    if not values or (size is not None and len(values) != size) or any(x < 0 or x > 1 for x in values) or not math.isclose(total,1.,abs_tol=1e-12,rel_tol=0):
        raise ValueError("normalized nonnegative distribution required")
    if total == 1.:
        return values
    normalized = [x/total for x in values]
    # Make revalidation idempotent: repeated normalization must not drift a
    # retained posterior and invalidate its own reproducibility binding.
    index = max(range(len(normalized)),key=normalized.__getitem__)
    normalized[index] = 1.-math.fsum(x for i,x in enumerate(normalized) if i != index)
    return tuple(normalized)


def entropy(probabilities):
    return -math.fsum(p*math.log(p) for p in probabilities if p)


@dataclass(frozen=True)
class Experiment:
    id: str
    outcomes: tuple
    likelihood: tuple  # one outcome distribution per state
    cost: int

    def __post_init__(self):
        _names((self.id,))
        object.__setattr__(self,"outcomes",_names(self.outcomes,MAX_OUTCOMES))
        object.__setattr__(self,"likelihood",tuple(distribution(row,len(self.outcomes)) for row in _bounded(self.likelihood,MAX_STATES)))
        if type(self.cost) is not int or self.cost <= 0:
            raise ValueError("positive integer experiment cost required")
        _finite(self.cost)


@dataclass(frozen=True)
class Model:
    id: str
    states: tuple
    prior: tuple
    decisions: tuple
    utilities: tuple  # utility[state] for each terminal decision
    experiments: tuple
    cost_units: str

    def __post_init__(self):
        _names((self.id,)); _names((self.cost_units,))
        object.__setattr__(self,"states",_names(self.states))
        object.__setattr__(self,"decisions",_names(self.decisions,MAX_DECISIONS))
        object.__setattr__(self,"prior",distribution(self.prior,len(self.states)))
        utilities = tuple(tuple(_finite(v) for v in _bounded(row,len(self.states)))
                          for row in _bounded(self.utilities,MAX_DECISIONS))
        if len(utilities) != len(self.decisions) or any(len(row) != len(self.states) for row in utilities):
            raise ValueError("one utility per decision and state required")
        object.__setattr__(self,"utilities",utilities)
        experiments = _bounded(self.experiments,MAX_EXPERIMENTS)
        if any(not isinstance(a,Experiment) or len(a.likelihood) != len(self.states) for a in experiments):
            raise ValueError("experiment likelihood must cover every state")
        if len({a.id for a in experiments}) != len(experiments):
            raise ValueError("experiment IDs must be unique")
        object.__setattr__(self,"experiments",experiments)

    def action(self,action_id):
        for action in self.experiments:
            if action.id == action_id:
                return action
        raise ValueError("unknown experiment ID")


def terminal_decision(model, belief):
    belief = distribution(belief,len(model.states))
    values = [math.fsum(p*u for p,u in zip(belief,row)) for row in model.utilities]
    index = max(range(len(values)),key=lambda i:values[i])
    return model.decisions[index],values[index]


def predictive(model,belief,action_id):
    belief = distribution(belief,len(model.states))
    action = model.action(action_id)
    return tuple(math.fsum(p*row[j] for p,row in zip(belief,action.likelihood)) for j in range(len(action.outcomes)))


def update(model,belief,action_id,outcome):
    belief = distribution(belief,len(model.states))
    action = model.action(action_id)
    if outcome not in action.outcomes:
        raise ValueError("unknown outcome")
    j = action.outcomes.index(outcome)
    weights = tuple(p*row[j] for p,row in zip(belief,action.likelihood))
    total = math.fsum(weights)
    if total <= 0:
        raise ValueError("observation is impossible under the declared model; revise it explicitly")
    return tuple(w/total for w in weights)


def _limits(budget,steps=None):
    if type(budget) is not int or budget < 0:
        raise ValueError("nonnegative integer budget required")
    if steps is not None and (type(steps) is not int or not 0 <= steps <= 5):
        raise ValueError("finite planning horizon must be an integer in [0,5]")


def scores(model,belief,budget):
    _limits(budget)
    belief = distribution(belief,len(model.states))
    current = terminal_decision(model,belief)[1]
    rows = []
    for action in model.experiments:
        probabilities = predictive(model,belief,action.id)
        expected_entropy,expected_value = 0.,0.
        for probability,outcome in zip(probabilities,action.outcomes):
            if probability:
                posterior = update(model,belief,action.id,outcome)
                expected_entropy += probability*entropy(posterior)
                expected_value += probability*terminal_decision(model,posterior)[1]
        gain = max(0.,entropy(belief)-expected_entropy)
        improvement = max(0.,_finite(expected_value-current))
        rows.append({"test_id":action.id,"status":"modeled","affordable":action.cost <= budget,
                     "cost":action.cost,"expected_information_gain":gain,"information_per_cost":gain/action.cost,
                     "outcome_entropy":entropy(probabilities),"expected_decision_improvement":improvement,
                     "net_decision_value":improvement-action.cost})
    return rows


class PlanningBudgetExceeded(RuntimeError):
    """No optimal recommendation is available for this unfinished query."""
    def __init__(self,used,limit):
        self.reason,self.work_used,self.work_limit = "planning_work_budget_exhausted",used,limit
        super().__init__(f"{self.reason}: {used}/{limit} work units")


class BellmanPlanner:
    """Exhaustive finite-horizon value under the supplied model, not hidden truth.

    Repeated outcomes are assumed conditionally independent given the fixed
    state. Memoization reuses identical floating-point beliefs; it never rounds
    beliefs into approximate equivalence classes. A lifetime work budget counts
    every uncached state and every action/outcome examined, including recomputation
    after cache eviction. Exhaustion raises without a provisional action/value.
    Previously cached complete answers remain usable; new work requires a new,
    explicitly budgeted planner. Model input caps bound the work within each unit.
    """
    def __init__(self,model,*,max_work=50000):
        if type(max_work) is not int or not 1 <= max_work <= 1000000:
            raise ValueError("planning max_work must be an integer in [1,1000000]")
        self.model = model
        self.work_used,self.work_limit = 0,max_work
        self._solve = lru_cache(maxsize=50000)(self._uncached)

    def _spend(self):
        if self.work_used >= self.work_limit:
            raise PlanningBudgetExceeded(self.work_used,self.work_limit)
        self.work_used += 1

    def _uncached(self,belief,budget,steps):
        self._spend()
        best = terminal_decision(self.model,belief)[1],None
        if not steps:
            return best
        for action in sorted(self.model.experiments,key=lambda a:a.id):
            self._spend()
            if action.cost > budget:
                continue
            value = -float(action.cost)
            for probability,outcome in zip(predictive(self.model,belief,action.id),action.outcomes):
                self._spend()
                if probability:
                    posterior = update(self.model,belief,action.id,outcome)
                    value += probability*self._solve(posterior,budget-action.cost,steps-1)[0]
            if value > best[0]+1e-12:
                best = value,action.id
        return best

    def plan(self,belief,budget,steps):
        _limits(budget,steps)
        value,action = self._solve(distribution(belief,len(self.model.states)),budget,steps)
        return {"value":value,"action_id":action,"basis":"declared_model_finite_horizon",
                "work_used":self.work_used,"work_limit":self.work_limit}


POLICIES = ("eig","eig_per_cost","decision_value","last_entropy_drop","fixed","random","stop","bellman")


def choose(model,belief,budget,steps,*,policy,history=(),rng=None,planner=None,fixed_schedule=()):
    """Choose an experiment ID or stop (None), using no hidden evaluation state.

    The realized-entropy heuristic reuses an action's latest observed entropy
    reduction; untried actions use outcome entropy (which also favors pure noise).
    EIG schedules spend the finite horizon while information remains. Myopic
    decision value stops when every affordable one-step net value is nonpositive.
    """
    _limits(budget,steps)
    if policy not in POLICIES:
        raise ValueError("unknown selection policy")
    if not steps or policy == "stop":
        return None
    if policy == "bellman":
        planner = planner or BellmanPlanner(model)
        if planner.model != model:
            raise ValueError("planner model mismatch")
        return planner.plan(belief,budget,steps)["action_id"]
    available = [row for row in scores(model,belief,budget) if row["affordable"]]
    if not available:
        return None
    if policy == "random":
        if rng is None:
            raise ValueError("random policy requires an explicit RNG")
        return rng.choice(sorted(row["test_id"] for row in available))
    if policy == "fixed":
        if not fixed_schedule:
            raise ValueError("fixed policy requires an explicit schedule")
        action = fixed_schedule[len(history) % len(fixed_schedule)]
        model.action(action)
        return action if any(row["test_id"] == action for row in available) else None
    key = {"eig":"expected_information_gain","eig_per_cost":"information_per_cost",
           "decision_value":"net_decision_value","last_entropy_drop":"heuristic"}[policy]
    if policy == "last_entropy_drop":
        latest = {item["action_id"]:item["entropy_drop"] for item in history}
        for row in available:
            row["heuristic"] = latest.get(row["test_id"],row["outcome_entropy"])/row["cost"]
    best = sorted(available,key=lambda row:(-row[key],row["cost"],row["test_id"]))[0]
    if policy != "last_entropy_drop" and best[key] <= 1e-12:
        return None
    return best["test_id"]


def _cutoff(value):
    if value is not None and not isinstance(value,str):
        raise ValueError("cutoff must be a zoned ISO timestamp or an explicit UTC date")
    return cutoff(value)


def annotate_proposals(proposals,model,posterior,budget,*,model_as_of=None,posterior_as_of=None,as_of=None):
    """Bind design priorities to supplied model, posterior, proposal and dates.

    model_as_of declares when the selected specification/fitted model was
    available, not merely its training-data dates. posterior_as_of declares the
    latest included observation's availability. These are caller declarations,
    not authenticated history or proof of preregistration. A historical proposal
    needs both dates no later than its own cutoff; a stricter caller as_of also
    excludes future/undated proposals. Ineligible tests receive no numeric scores.
    Unbounded current designs can receive explicitly undated design-only scores.
    Consumers must check annotation_matches before using retained scores.
    """
    posterior = distribution(posterior,len(model.states))
    model_date,posterior_date,requested = map(_cutoff,(model_as_of,posterior_as_of,as_of))
    by_id = {row["test_id"]:row for row in scores(model,posterior,budget)}
    model_hash = digest(asdict(model))
    posterior_hash = digest({"model_sha256":model_hash,"posterior":posterior,"observed_at":posterior_date})
    result = deepcopy(list(proposals))
    for proposal in result:
        proposal_date = _cutoff(proposal.get("as_of"))
        effective = proposal_date or requested
        reason = None
        if requested and proposal_date is None:
            reason = "undated_proposal_at_historical_cutoff"
        elif requested and proposal_date > requested:
            reason = "proposal_after_requested_cutoff"
        elif effective and model_date is None:
            reason = "missing_model_availability"
        elif effective and posterior_date is None:
            reason = "missing_posterior_observation_cutoff"
        elif effective and model_date > effective:
            reason = "model_available_after_proposal_cutoff"
        elif effective and posterior_date > effective:
            reason = "posterior_uses_later_observations"
        temporal_status = ("temporally_ineligible" if reason else "eligible_by_declared_provenance" if effective
                           else "undated_design_only" if model_date is None or posterior_date is None
                           else "dated_design_only")
        tests = []
        for test in proposal.get("discriminating_tests",[]):
            test_id = test.get("id")
            if test_id not in by_id:
                tests.append({"test_id":test_id,"status":"unmodeled"})
            elif reason:
                tests.append({"test_id":test_id,"status":"temporally_ineligible","reason":reason})
            else:
                tests.append(deepcopy(by_id[test_id]))
        binding = digest({key:value for key,value in proposal.items() if key != "acquisition"})
        annotation = {"schema":"nl2proof.acquisition.v2","model_id":model.id,"model_sha256":model_hash,
                      "cost_units":model.cost_units,"basis":"stipulated_likelihoods","posterior":None if reason else list(posterior),
                      "posterior_sha256":posterior_hash,"proposal_sha256":binding,
                      "model_as_of":model_date,"posterior_as_of":posterior_date,"requested_as_of":requested,
                      "effective_as_of":effective,"temporal_status":temporal_status,
                      "eligible_at_as_of":False if reason else True if effective else None,
                      "establishes_preregistration":False,"remaining_budget":budget,"tests":tests}
        annotation["annotation_sha256"] = digest(annotation)
        proposal["acquisition"] = annotation
    return result


def annotation_matches(proposal,model,*,as_of=None):
    """Check reproducibility bindings before using scores; this is not authenticity.

    Supplying a historical as_of additionally requires declared historical
    eligibility and a proposal snapshot no later than the requested cutoff.
    Undated design annotations can match structurally but never historically.
    """
    try:
        if not isinstance(proposal,dict) or not isinstance(proposal.get("acquisition"),dict):
            return False
        record = proposal["acquisition"]
        requested = _cutoff(as_of)
        if record.get("temporal_status") == "temporally_ineligible":
            return False
        expected = annotate_proposals([proposal],model,record["posterior"],record["remaining_budget"],
                       model_as_of=record["model_as_of"],posterior_as_of=record["posterior_as_of"],
                       as_of=record["requested_as_of"])[0]["acquisition"]
        if record != expected:
            return False
        return requested is None or (record["eligible_at_as_of"] is True
                    and record["effective_as_of"] is not None and record["effective_as_of"] <= requested)
    except (AttributeError,KeyError,TypeError,ValueError,OverflowError):
        return False
