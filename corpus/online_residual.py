"""One-step forecasts with delayed outcomes and frozen pre-outcome blend weights.

This is an explicit reconstruction of a missing research component, not a copy
of an unavailable historical learner. Callers supply causal, scaled features and
a declared scalar target. A forecast made at t predicts the target revealed at
t+1. Residuals use that stored forecast before training on the revealed outcome.
Two branches use exponentially weighted ridge regression; inverse past squared
error blends their predictions. No strategy gates, market claims or belief writes.
"""
from __future__ import annotations

from dataclasses import asdict, dataclass
import hashlib
import json
import math


def finite(value):
    try:
        valid = type(value) in (int, float) and math.isfinite(value)
    except OverflowError:
        valid = False
    if not valid:
        raise ValueError("finite numeric values required")
    return float(value)


def solve_spd(matrix, rhs):
    """Cholesky solve; fail explicitly when supplied scales lose positive definiteness."""
    size = len(rhs)
    lower = [[0.] * size for _ in rhs]
    for i in range(size):
        for j in range(i+1):
            value = matrix[i][j] - math.fsum(lower[i][k]*lower[j][k] for k in range(j))
            if i == j:
                if not math.isfinite(value) or value <= 0:
                    raise ValueError("ill-conditioned ridge fit; rescale features")
                lower[i][j] = math.sqrt(value)
            else:
                lower[i][j] = value/lower[j][j]
    forward = []
    for i in range(size):
        forward.append((rhs[i]-math.fsum(lower[i][j]*forward[j] for j in range(i)))/lower[i][i])
    result = [0.] * size
    for i in range(size-1, -1, -1):
        result[i] = (forward[i]-math.fsum(lower[j][i]*result[j] for j in range(i+1,size)))/lower[i][i]
    if any(not math.isfinite(x) for x in result):
        raise ValueError("nonfinite ridge coefficients; rescale features")
    return result


class OnlineRidge:
    """Minimize sum(lambda**age * (y-x beta)**2) + ridge*||beta||**2.

    An intercept is added and penalized too. Forgetting advances with observed
    training pairs, not elapsed bars. Defaults are declared engineering choices.
    """
    def __init__(self, dimensions, *, forgetting=.99, ridge=1.):
        if type(dimensions) is not int or not 1 <= dimensions <= 16:
            raise ValueError("feature dimensions must be in [1,16]")
        self.forgetting, self.ridge = finite(forgetting), finite(ridge)
        if not 0 < self.forgetting <= 1 or self.ridge <= 0:
            raise ValueError("forgetting in (0,1] and positive ridge required")
        self.dimensions = dimensions
        self.count = 0
        size = dimensions+1
        self.matrix = [[self.ridge if i == j else 0. for j in range(size)] for i in range(size)]
        self.rhs = [0.] * size

    def features(self, values):
        values = tuple(finite(x) for x in values)
        if len(values) != self.dimensions:
            raise ValueError("feature dimension mismatch")
        return (1.,) + values

    def predict(self, values):
        features = self.features(values)
        return finite(math.fsum(x*b for x,b in zip(features, solve_spd(self.matrix,self.rhs))))

    def updated(self, values, target):
        """Return staged sufficient statistics; callers commit only after validation."""
        features, target = self.features(values), finite(target)
        decay = self.forgetting
        matrix = [[finite(decay*self.matrix[i][j]+x*y+
                          ((1-decay)*self.ridge if i == j else 0.))
                   for j,y in enumerate(features)] for i,x in enumerate(features)]
        rhs = [finite(decay*b+x*target) for x,b in zip(features,self.rhs)]
        solve_spd(matrix,rhs)
        return matrix,rhs


@dataclass(frozen=True)
class Forecast:
    target_id: str
    made_at: int
    target_time: int
    branch_features: tuple
    branch_predictions: tuple
    weights: tuple
    prediction: float
    labels_seen: int


class ResidualLearner:
    """Clocked two-branch stream; missing labels are skipped, never backfilled.

    Each step emits a matured residual and makes the next forecast. If supplied,
    a session change cancels the cross-session forecast but preserves trained
    coefficients/losses. Instantiate a new learner to reset the fit itself.
    Features' real-world availability is the caller's responsibility; the clock
    enforces ordering, not the truth of externally declared data timestamps.
    """
    def __init__(self, dimensions, *, target_id, forgetting=.99, ridge=1., loss_decay=.95,
                 initial_loss=1., loss_floor=1e-8):
        if not isinstance(target_id,str) or not target_id.strip():
            raise ValueError("explicit target identity required")
        self.target_id = target_id
        if len(dimensions) != 2:
            raise ValueError("exactly two feature branches required")
        self.models = [OnlineRidge(d,forgetting=forgetting,ridge=ridge) for d in dimensions]
        self.loss_decay = finite(loss_decay)
        self.loss_floor = finite(loss_floor)
        initial_loss = finite(initial_loss)
        if not 0 <= self.loss_decay < 1 or self.loss_floor <= 0 or initial_loss <= 0:
            raise ValueError("loss decay in [0,1), positive initial loss and floor required")
        self.losses = [initial_loss,initial_loss]
        self.pending = None
        self.last_time = None
        self.session = None

    def step(self, t, observed_target, branch_features, *, session=None):
        if type(t) is not int or t < 0 or (self.last_time is not None and t != self.last_time+1):
            raise ValueError("clock must advance by exactly one integer step")
        if session is not None and (not isinstance(session,str) or not session):
            raise ValueError("session must be a nonempty string or None")
        target = None if observed_target is None else finite(observed_target)
        if len(branch_features) != 2:
            raise ValueError("exactly two feature branches required")
        features = tuple(tuple(model.features(xs)[1:]) for model,xs in zip(self.models,branch_features))
        pending = self.pending if self.session == session else None
        matured = {"target_id":self.target_id, "available_at":t, "target":target, "prediction":None, "residual":None,
                   "forecast_made_at":None, "status":"no_prior_forecast"}
        staged, losses = [], list(self.losses)
        if pending is not None:
            matured.update(prediction=pending.prediction, forecast_made_at=pending.made_at,
                           weights=pending.weights, branch_predictions=pending.branch_predictions,
                           status="missing_target" if target is None else "observed")
            if target is not None:
                matured["residual"] = finite(target-pending.prediction)
                for model,xs in zip(self.models,pending.branch_features):
                    staged.append(model.updated(xs,target))
                losses = [finite(self.loss_decay*loss+(1-self.loss_decay)*(target-prediction)**2)
                          for loss,prediction in zip(self.losses,pending.branch_predictions)]
        # Stage prediction against the candidate state; numerical/input errors leave
        # the previous clock, pending forecast and both branches intact.
        coefficients = [solve_spd(*(staged[i] if staged else (m.matrix,m.rhs)))
                        for i,m in enumerate(self.models)]
        predictions = tuple(finite(math.fsum(x*b for x,b in zip((1.,)+xs,beta)))
                            for xs,beta in zip(features,coefficients))
        # A common factor cancels; bounded ratios avoid reciprocal overflow for
        # finite positive losses/floors smaller than the normal float range.
        clamped = [max(self.loss_floor,loss) for loss in losses]
        smallest = min(clamped)
        inverse = [smallest/loss for loss in clamped]
        total = math.fsum(inverse)
        weights = tuple(x/total for x in inverse)
        prediction = finite(math.fsum(w*p for w,p in zip(weights,predictions)))
        forecast = Forecast(self.target_id,t,t+1,features,predictions,weights,prediction,
                            self.models[0].count + bool(staged))
        for model,(matrix,rhs) in zip(self.models,staged):
            model.matrix, model.rhs = matrix,rhs
            model.count += 1
        self.losses, self.pending, self.last_time, self.session = losses,forecast,t,session
        return {"matured":matured,"next_forecast":forecast}


def replay_progressive_residual(obs, context_features, *, mus, sd, trans, pi,
                                target_id, lag=1, forgetting=.99, ridge=1.,
                                loss_decay=.95, initial_loss=1., loss_floor=1e-8):
    """Single-session causal reconstruction with caller-supplied context features.

    At t, the target is KL(filter_{t-lag} || smoother_{t-lag|t}). After three
    targets have matured, their level, first difference and second difference
    form the AR branch. The other branch receives context_features[t], which
    the caller must ensure was available at t. Both forecast the target becoming
    available at t+1, using only outcomes available through t. The first matured
    targets warm up differences; they are not invented or backfilled as labels.

    Parameters must have been fitted before this scoring interval. A model hash
    records their identity, not their historical availability or calibration.
    Start a separate replay for a separate session. No gates or returns are used.
    """
    from surprise import progressive_surprise_series

    if type(lag) is not int or not 1 <= lag <= 256:
        raise ValueError("predictive target requires an integer lag in [1,256]")
    obs = tuple(obs)
    contexts = tuple(tuple(finite(value) for value in row) for row in context_features)
    if len(contexts) != len(obs):
        raise ValueError("one context feature row is required for each observation")
    dimensions = len(contexts[0]) if contexts else 1
    if any(len(row) != dimensions for row in contexts):
        raise ValueError("context feature dimensions must remain fixed")
    parameters = {"mus":[finite(x) for x in mus], "sd":finite(sd),
                  "trans":[[finite(x) for x in row] for row in trans],
                  "pi":[finite(x) for x in pi]}
    revisions = progressive_surprise_series(obs, **parameters, lag=lag)
    learner = ResidualLearner((3,dimensions), target_id=target_id, forgetting=forgetting,
                              ridge=ridge, loss_decay=loss_decay, initial_loss=initial_loss,
                              loss_floor=loss_floor)
    encoded = json.dumps(parameters,sort_keys=True,separators=(",",":"),allow_nan=False).encode()
    rows, history = [], []
    for t,(revision,context) in enumerate(zip(revisions,contexts)):
        target = revision["revision_kl"]
        row = {**revision, "ar_features":None, "matured":None, "next_forecast":None,
               "status":"unavailable_target" if target is None else "warming_up"}
        if target is not None:
            history.append(target)
            history = history[-3:]
            if len(history) == 3:
                oldest,previous,current = history
                features = (current,current-previous,current-2*previous+oldest)
                result = learner.step(t,target,(features,context))
                row.update(ar_features=features, matured=result["matured"],
                           next_forecast=asdict(result["next_forecast"]), status="forecasting")
        rows.append(row)
    return {"target_id":target_id, "lag":lag, "model_fingerprint":"sha256:"+hashlib.sha256(encoded).hexdigest(),
            "target_definition":"KL(filter_(t-lag) || smoother_(t-lag|t)), available at t",
            "configuration":{"forgetting":learner.models[0].forgetting, "ridge":learner.models[0].ridge,
                             "loss_decay":learner.loss_decay, "initial_loss":finite(initial_loss),
                             "loss_floor":learner.loss_floor, "ar_warmup_targets":3},
            "rows":rows}


class PastEventMedian:
    """Threshold available before the current event is added to a bounded history."""
    def __init__(self, *, window=100, minimum=20):
        if type(window) is not int or type(minimum) is not int or not 1 <= minimum <= window <= 10000:
            raise ValueError("integer history limits 1 <= minimum <= window <= 10000 required")
        self.window, self.minimum, self.history = window,minimum,[]

    def observe(self,value):
        value = finite(value)
        ordered = sorted(self.history)
        n = len(ordered)
        threshold = None if n < self.minimum else (ordered[(n-1)//2]/2 + ordered[n//2]/2)
        self.history = (self.history+[value])[-self.window:]
        return threshold
