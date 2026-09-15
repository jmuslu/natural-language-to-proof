"""Delayed-label order, numerical fit, prefix invariance and no-current-event gates."""
from dataclasses import asdict
from copy import deepcopy
import math
import random
import unittest

from online_residual import OnlineRidge, ResidualLearner, PastEventMedian, replay_progressive_residual
from surprise import progressive_surprise_series, filter_smooth, kl


class ProgressiveTests(unittest.TestCase):
    args = ((0.,2.), .6, [[.95,.05],[.05,.95]], [.5,.5])
    obs = [0.,.2,-.2,.1,1.,2.,2.1,1.8]

    def test_fixed_lag_equals_smoothing_only_the_available_prefix(self):
        for lag in (0,1,2,4):
            rows = progressive_surprise_series(self.obs,*self.args,lag=lag)
            for t,row in enumerate(rows):
                self.assertEqual(row["available_at"],t)
                if t < lag:
                    self.assertIsNone(row["revision_kl"])
                    self.assertIsNone(row["state_time"])
                else:
                    filtered,smoothed = filter_smooth(self.obs[:t+1],*self.args)
                    self.assertAlmostEqual(row["revision_kl"],kl(filtered[t-lag],smoothed[t-lag]),places=12)
                    self.assertEqual(row["state_time"],t-lag)
        self.assertEqual([r["revision_kl"] for r in progressive_surprise_series(self.obs,*self.args,lag=0)], [0.]*len(self.obs))

    def test_future_suffix_never_rewrites_an_available_diagnostic(self):
        full = progressive_surprise_series(self.obs,*self.args,lag=2)
        for cutoff in range(len(self.obs)+1):
            self.assertEqual(progressive_surprise_series(self.obs[:cutoff],*self.args,lag=2),full[:cutoff])
        changed = progressive_surprise_series(self.obs[:4]+[100.,-100.,100.],*self.args,lag=2)
        self.assertEqual(changed[:4],full[:4])
        self.assertTrue(all(r["revision_kl"] is None or math.isfinite(r["revision_kl"]) for r in changed))
        for lag in (-1,True,257,1.5):
            with self.assertRaises(ValueError):
                progressive_surprise_series(self.obs,*self.args,lag=lag)


class DelayedResidualTests(unittest.TestCase):
    def learner(self,**kwargs):
        return ResidualLearner((1,1),target_id="synthetic next scalar",**kwargs)

    def test_ridge_matches_independent_two_by_two_batch_solution(self):
        model = OnlineRidge(1,forgetting=.7,ridge=2.)
        pairs = [(-1.,3.),(2.,-2.),(.5,4.),(1.,2.)]
        for x,y in pairs:
            model.matrix,model.rhs = model.updated([x],y)
            model.count += 1
        # Closed-form 2x2 inverse, independently accumulating weighted observations.
        a,c,d,u,v = 2.,0.,2.,0.,0.
        for age,(x,y) in enumerate(reversed(pairs)):
            weight = .7**age
            a += weight
            c += weight*x
            d += weight*x*x
            u += weight*y
            v += weight*x*y
        intercept,slope = (d*u-c*v)/(a*d-c*c),(a*v-c*u)/(a*d-c*c)
        self.assertAlmostEqual(model.predict([3.]),intercept+3*slope,places=12)

    def test_label_uses_stored_features_and_pre_outcome_prediction(self):
        model = self.learner(forgetting=1.,ridge=1.)
        first = model.step(0,None,([1.],[2.]))["next_forecast"]
        second = model.step(1,4.,([10.],[20.]))
        self.assertEqual(second["matured"]["prediction"],first.prediction)
        self.assertEqual(second["matured"]["residual"],4.)
        self.assertEqual(second["matured"]["forecast_made_at"],0)
        self.assertEqual(second["next_forecast"].labels_seen,1)
        # First branch solves ridge on [intercept=1, feature=1], not current x=10.
        self.assertAlmostEqual(second["next_forecast"].branch_predictions[0],44/3)

    def test_current_error_cannot_change_the_weights_of_its_prediction(self):
        model = self.learner(loss_decay=0.)
        model.step(0,None,([1.],[2.]))
        forecast = model.step(1,2.,([3.],[-2.]))["next_forecast"]
        observed = forecast.branch_predictions[0]
        result = model.step(2,observed,([1.],[1.]))
        self.assertEqual(result["matured"]["weights"],forecast.weights)
        self.assertAlmostEqual(result["matured"]["residual"],observed-forecast.prediction)
        self.assertGreater(result["next_forecast"].weights[0],.99)

    def test_bad_step_is_atomic_and_missing_labels_are_never_backfilled(self):
        model = self.learner()
        first = model.step(0,None,([1.],[1.]))["next_forecast"]
        for t,y,xs in ((2,2.,([1.],[1.])),(1,float('nan'),([1.],[1.])),(1,3.,([1.],[1.,2.]))):
            with self.assertRaises(ValueError):
                model.step(t,y,xs)
            self.assertEqual(model.pending,first)
            self.assertEqual(model.models[0].count,0)
            self.assertEqual(model.last_time,0)
        self.assertEqual(model.step(1,None,([2.],[2.]))["matured"]["status"],"missing_target")
        self.assertEqual(model.models[0].count,0)
        model.step(2,3.,([1.],[1.]))
        self.assertEqual(model.models[0].count,1)

    def test_session_change_cancels_previous_session_forecast(self):
        model = self.learner()
        model.step(0,None,([1.],[1.]),session="A")
        result = model.step(1,999.,([1.],[1.]),session="B")
        self.assertIsNone(result["matured"]["residual"])
        self.assertEqual(model.models[0].count,0)

    def test_whole_stream_and_changed_future_have_identical_prior_forecasts(self):
        rows = [(None,([1.],[2.])),(1.,([2.],[-1.])),(3.,([1.],[.5])),(-2.,([0.],[1.]))]
        def run(values):
            model = self.learner()
            return [model.step(t,y,xs) for t,(y,xs) in enumerate(values)]
        full = run(rows)
        for cutoff in range(1,len(rows)+1):
            self.assertEqual(run(rows[:cutoff]),full[:cutoff])
        self.assertEqual(run(rows[:2]+[(1000.,([0.],[0.]))])[:2],full[:2])
        self.assertEqual(asdict(full[-1]["next_forecast"])["target_id"],"synthetic next scalar")

    def test_event_threshold_uses_only_previous_events_and_bounded_window(self):
        median = PastEventMedian(window=3,minimum=2)
        self.assertIsNone(median.observe(1.))
        self.assertIsNone(median.observe(3.))
        self.assertEqual(median.observe(1000.),2.)
        self.assertEqual(median.observe(-1000.),3.)
        self.assertEqual(median.observe(4.),3.)

    def test_blend_remains_finite_for_positive_subnormal_losses(self):
        model = self.learner(initial_loss=1e-320,loss_floor=1e-320)
        forecast = model.step(0,None,([1.],[2.]))["next_forecast"]
        self.assertEqual(forecast.weights,(.5,.5))
        self.assertEqual(forecast.prediction,0.)

    def test_second_branch_numerical_failure_cannot_partly_commit(self):
        model = self.learner()
        model.step(0,None,([1.],[1e200]))
        def state():
            return ([(m.matrix,m.rhs,m.count) for m in model.models],
                    model.losses,model.pending,model.last_time,model.session)
        before = deepcopy(state())
        with self.assertRaises(ValueError):
            model.step(1,3.,([1.],[1.]))
        self.assertEqual(state(),before)
        with self.assertRaises(ValueError):
            model.step(1,10**1000,([1.],[1.]))
        self.assertEqual(state(),before)


class ConnectedReplayTests(unittest.TestCase):
    parameters = {"mus":(-.75,.75), "sd":1., "trans":((.94,.06),(.06,.94)), "pi":(.5,.5)}

    def observations(self,n=90):
        rng, state = random.Random(19501),0
        values = []
        for _ in range(n):
            if rng.random() > .94:
                state = 1-state
            values.append(rng.gauss(self.parameters["mus"][state],1.))
        return values

    def replay(self,obs,**kwargs):
        # A generic bounded observation feature, with no financial meaning.
        context = [(math.tanh(value),) for value in obs]
        return replay_progressive_residual(obs,context,**self.parameters,
                    target_id="synthetic fixed-model one-lag KL",forgetting=.97,ridge=.7,
                    loss_decay=.8,**kwargs)

    def test_joint_stream_matches_independent_probability_and_batch_regression(self):
        obs = self.observations()
        rows = self.replay(obs)["rows"]
        # Direct probability-space Bayes calculation, no surprise.py helpers.
        alpha, targets = list(self.parameters["pi"]),[]
        for t,value in enumerate(obs):
            emission = [math.exp(-.5*(value-mu)**2) for mu in self.parameters["mus"]]
            likelihood = [sum(a*b for a,b in zip(row,emission)) for row in self.parameters["trans"]]
            gamma = [p*b for p,b in zip(alpha,likelihood)]
            gamma = [p/sum(gamma) for p in gamma]
            targets.append(None if t == 0 else max(0.,sum(p*math.log(p/q) for p,q in zip(alpha,gamma))))
            predictive = (list(self.parameters["pi"]) if t == 0 else
                          [sum(alpha[i]*self.parameters["trans"][i][j] for i in range(2)) for j in range(2)])
            updated = [p*e for p,e in zip(predictive,emission)]
            alpha = [p/sum(updated) for p in updated]

        def batch_predict(pairs,features):
            # Rebuild weighted normal equations from all past pairs, then use
            # pivoted Gaussian elimination rather than the learner's Cholesky.
            x = (1.,)+features
            n = len(x)
            matrix = [[.7 if i == j else 0. for j in range(n)] for i in range(n)]
            rhs = [0.]*n
            for age,(xs,y) in enumerate(reversed(pairs)):
                z,weight = (1.,)+xs,.97**age
                for i in range(n):
                    rhs[i] += weight*z[i]*y
                    for j in range(n):
                        matrix[i][j] += weight*z[i]*z[j]
            augmented = [row+[b] for row,b in zip(matrix,rhs)]
            for j in range(n):
                pivot = max(range(j,n),key=lambda i:abs(augmented[i][j]))
                augmented[j],augmented[pivot] = augmented[pivot],augmented[j]
                divisor = augmented[j][j]
                augmented[j] = [v/divisor for v in augmented[j]]
                for i in range(n):
                    if i != j:
                        multiplier = augmented[i][j]
                        augmented[i] = [a-multiplier*b for a,b in zip(augmented[i],augmented[j])]
            return sum(v*row[-1] for v,row in zip(x,augmented))

        pairs,losses,previous = [[],[]],[1.,1.],None
        independent_errors,actual_errors = [],[]
        for t,row in enumerate(rows):
            if t == 0:
                self.assertIsNone(row["revision_kl"])
            else:
                self.assertAlmostEqual(row["revision_kl"],targets[t],places=11)
            if t < 3:
                self.assertIsNone(row["next_forecast"])
                continue
            features = ((targets[t],targets[t]-targets[t-1],targets[t]-2*targets[t-1]+targets[t-2]),
                        (math.tanh(obs[t]),))
            if previous:
                for branch in range(2):
                    pairs[branch].append((previous["features"][branch],targets[t]))
                    losses[branch] = .8*losses[branch]+.2*(targets[t]-previous["predictions"][branch])**2
                expected = targets[t]-previous["prediction"]
                self.assertAlmostEqual(row["matured"]["residual"],expected,places=10)
                self.assertEqual(row["matured"]["forecast_made_at"],t-1)
                independent_errors.append(expected**2)
                actual_errors.append(row["matured"]["residual"]**2)
            predictions = tuple(batch_predict(sample,xs) for sample,xs in zip(pairs,features))
            inverse = [1/max(1e-8,loss) for loss in losses]
            weights = tuple(v/sum(inverse) for v in inverse)
            prediction = sum(w*p for w,p in zip(weights,predictions))
            forecast = row["next_forecast"]
            self.assertEqual(forecast["target_time"],t+1)
            self.assertEqual(forecast["labels_seen"],len(pairs[0]))
            self.assertAlmostEqual(forecast["prediction"],prediction,places=10)
            for actual,expected in zip(forecast["branch_predictions"],predictions):
                self.assertAlmostEqual(actual,expected,places=10)
            previous = {"features":features,"predictions":predictions,"prediction":prediction}
        self.assertGreater(sum(independent_errors),0.)
        self.assertAlmostEqual(sum(actual_errors),sum(independent_errors),places=10)

    def test_connected_prefix_warmup_identity_and_alignment_contract(self):
        obs = self.observations(30)
        full = self.replay(obs)
        for cutoff in (0,1,2,3,4,15,30):
            prefix = self.replay(obs[:cutoff])
            self.assertEqual(prefix["rows"],full["rows"][:cutoff])
            self.assertEqual(prefix["model_fingerprint"],full["model_fingerprint"])
        self.assertEqual(self.replay(obs[:15]+[20.,-20.,20.])["rows"][:15],full["rows"][:15])
        lagged = self.replay(obs,lag=2)
        self.assertTrue(all(row["next_forecast"] is None for row in lagged["rows"][:4]))
        self.assertEqual(lagged["rows"][4]["next_forecast"]["made_at"],4)
        self.assertEqual(lagged["rows"][5]["matured"]["forecast_made_at"],4)
        # Context x_t participates in forecasting t+1, never in the t forecast.
        contexts = [(math.tanh(value),) for value in obs]
        contexts[15] = (100.,)
        changed = replay_progressive_residual(obs,contexts,**self.parameters,
                    target_id=full["target_id"],forgetting=.97,ridge=.7,loss_decay=.8)
        self.assertEqual(changed["rows"][:15],full["rows"][:15])
        self.assertEqual(changed["rows"][15]["matured"],full["rows"][15]["matured"])
        self.assertNotEqual(changed["rows"][15]["next_forecast"],full["rows"][15]["next_forecast"])
        with self.assertRaises(ValueError):
            self.replay(obs,lag=0)
        with self.assertRaises(ValueError):
            replay_progressive_residual(obs,contexts[:-1],**self.parameters,target_id="x")
        with self.assertRaises(ValueError):
            replay_progressive_residual(obs,[()] * len(obs),**self.parameters,target_id="x")


if __name__ == "__main__":
    unittest.main()
