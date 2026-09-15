"""multihop.py — multi-hop reasoning + synthetic inference for the discovery brain.

Builds on estimand.py (the reverse-prop mechanics). Two capabilities the goal names
directly:

  * SYNTHETIC INFERENCE — the brain generates a *new* candidate signal by abstraction
    from a grounded METHOD-CLASS (an invariant distilled across trajectories, i.e. a
    higher colimit). The proposal is tagged `proposed-not-grounded`: it enters the
    exploration frontier for free (a promising corner is never pruned) but earns no
    belief until its own legs are externally checked.

  * MULTI-HOP REASONING — composing a chain of typed hops (grounding → coercion →
    portfolio value) with uncertainty propagating honestly, under a two-gate guard:
    *exploration* traverses through ungrounded nodes (flagged), *belief* refuses to.

Demonstrated on a NEUROMORPHIC signal (a market-as-excitable-dynamical-system,
bifurcation-proximity reversal) proposed by abstraction from the Futures-Reversal
method-class — showing the SAME mechanics host a signal from a different domain, and a
method-class grows more trusted as it grounds across INDEPENDENT domains (the
Multiplicity Principle, one level up). Dependency-free. Run: python3 multihop.py
"""
from __future__ import annotations

import math
import os
import sys
from dataclasses import dataclass, field, replace

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estimand import Quantity, Leg, colimit, Hop, compose_chain, GroundingResult


# --------------------------------------------------------------------------- #
# Method-classes: the invariant across trajectories (a higher colimit).
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class LegSlot:
    """An unmeasured leg — a check the method-class REQUIRES, before any data."""
    name: str
    kind: str                 # 'prediction' | 'necessity' | 'specificity'
    direction: int = +1
    present: bool = True


@dataclass(frozen=True)
class MethodClass:
    name: str
    applicability: str        # when this method is licensed to be proposed
    template: tuple           # tuple[LegSlot] — the checks it entails
    realizations: tuple = ()  # apex names that have GROUNDED via this class

    def trust(self) -> float:
        """Rises with the number of provenance-INDEPENDENT grounded realizations — a
        method earns trust by working across domains, not by assertion. Saturating."""
        return 1.0 - math.exp(-len(self.realizations) / 2.0)

    def realized_by(self, apex: str) -> "MethodClass":
        if apex in self.realizations:
            return self
        return replace(self, realizations=self.realizations + (apex,))


@dataclass
class CandidateApex:
    """A proposed signal: legs are slots until measured. Never gains trust while
    `status == 'proposed-not-grounded'`."""
    name: str
    context: str
    method: str
    slots: tuple
    status: str = "proposed-not-grounded"
    result: GroundingResult | None = None

    def measure(self, effects: dict) -> GroundingResult:
        """Fill each slot from `effects[name] = (effect, stderr, provenance)` and run
        the colimit. Missing measurements leave a slot unbindable (the apex stays
        ungrounded) — you cannot ground what you have not checked."""
        legs = []
        for s in self.slots:
            if s.name not in effects:
                # unmeasured -> a deliberately non-binding leg (huge stderr)
                legs.append(Leg(s.name, s.kind, 0.0, 1e9, frozenset(), s.direction, s.present))
                continue
            eff, se, prov = effects[s.name]
            legs.append(Leg(s.name, s.kind, eff, se, frozenset(prov), s.direction, s.present))
        r = colimit(self.name, legs)
        self.result = r
        self.status = "grounded" if r.grounded else "refused"
        return r


# --------------------------------------------------------------------------- #
# Synthetic inference: propose a new apex by abstraction from a method-class.
# --------------------------------------------------------------------------- #
def propose(method: MethodClass, apex_name: str, context: str) -> CandidateApex:
    """The discovery move. Instantiate the method's template of required checks into a
    new candidate in a new context — WITHOUT any measurement. This is the brain
    reusing a grounded method (learning without weights); the candidate is a question,
    not an answer."""
    return CandidateApex(apex_name, context, method.name, tuple(method.template))


# --------------------------------------------------------------------------- #
# Multi-hop reasoning with the two-gate guard.
# --------------------------------------------------------------------------- #
def belief_chain(apex: CandidateApex, base_units: str, hops: list[Hop]):
    """BELIEF traversal: refuses to compose through an ungrounded apex. Returns
    (Quantity, note) or (None, reason). Confidence degrades honestly across hops."""
    if apex.status != "grounded" or apex.result is None:
        return None, f"refused: apex '{apex.name}' is {apex.status} (belief gate is strict)"
    r = apex.result
    # seed a quantity from the grounded verdict; sigma from multiplicity (more
    # independent bindings -> tighter start).
    sigma0 = 1.0 / math.sqrt(max(1, r.multiplicity))
    base = Quantity(r.verdict, sigma0, base_units)
    out, contractive = compose_chain(base, hops)
    return out, f"grounded (multiplicity {r.multiplicity}); contractive={contractive}"


def explore_chain(apex: CandidateApex, base_units: str, hops: list[Hop]):
    """EXPLORATION traversal: proceeds regardless of grounding, flagged — a promising
    corner is never pruned, but the result is explicitly not-yet-belief."""
    verdict = apex.result.verdict if apex.result else 0.0
    base = Quantity(verdict, 1.0, base_units)   # wide, since unproven
    out, _ = compose_chain(base, hops)
    return out, f"EXPLORATION ONLY (apex {apex.status}) — not belief"


# --------------------------------------------------------------------------- #
# self-test / demonstration — the neuromorphic signal by synthetic inference.
# --------------------------------------------------------------------------- #
def _selftest():
    def line(t): print(f"\n{'-'*70}\n{t}\n{'-'*70}")

    # The method-class distilled from Futures-Reversal: a latent regime process with a
    # deliberately-weak predictor whose RESIDUAL carries the edge (dead marginal,
    # beautiful corner), validated by mechanism-ablation + cross-sectional specificity.
    method = MethodClass(
        name="regime_attractor_residual",
        applicability=("a latent excitable/regime process with a filtering-vs-smoothing "
                       "surprise, where a weak predictor's residual is the signal"),
        template=(
            LegSlot("edge_present", "prediction", direction=+1),
            LegSlot("mechanism_ablation_collapses", "necessity"),
            LegSlot("specificity_present", "specificity", direction=+1, present=True),
        ),
        realizations=("futures_reversal_nq",),   # already grounded once (the fixture)
    )
    line("METHOD-CLASS (grounded once, by Futures-Reversal)")
    print(f"{method.name}: realizations={method.realizations}  trust={method.trust():.3f}")

    line("1. SYNTHETIC INFERENCE — propose a NEUROMORPHIC signal by abstraction")
    neuro = propose(method, "bifurcation_reversal_nq",
                    context=("market microstructure as an excitable dynamical system near a "
                             "subcritical Andronov-Hopf bifurcation; surprise = KL(filter‖smooth) "
                             "analog; the signal fires by topological proximity to the bifurcation, "
                             "NOT by the (deliberately weak) forecast"))
    print(f"proposed apex : {neuro.name}\ncontext       : {neuro.context}")
    print(f"status        : {neuro.status}  (enters the frontier free; earns no belief yet)")
    assert neuro.status == "proposed-not-grounded"

    line("2. TWO-GATE GUARD — belief refuses the ungrounded apex; exploration may roam")
    hops = [Hop(1.0 / math.sqrt(0.05), 0.05, "coerce->deployed"),
            Hop(0.5, 0.3, "->portfolio-marginal")]
    q_bel, note_bel = belief_chain(neuro, "sharpe", hops)
    q_exp, note_exp = explore_chain(neuro, "sharpe", hops)
    print(f"belief:      {note_bel}")
    print(f"exploration: value≈{q_exp.value:+.2f} ± {q_exp.sigma:.2f}  ({note_exp})")
    assert q_bel is None and q_exp is not None    # generous exploration, strict belief

    line("3. CHECK ITS LEGS (the oracle measures) — SAME estimand/colimit mechanics")
    # bifurcation-proximity edge is real; ablating it to raw volatility collapses it;
    # present in the excitable regime (independent regime study).
    r = neuro.measure({
        "edge_present": (3.1, 1.1, ["NQ_bifurcation"]),           # t≈2.8
        "mechanism_ablation_collapses": (0.1, 1.0, ["NQ_bif_abl"]),  # t≈0.1 collapses
        "specificity_present": (2.6, 1.0, ["regime_study"]),     # t≈2.6, independent prov
    })
    print(f"status={neuro.status}  grounded={r.grounded}  multiplicity={r.multiplicity}  "
          f"verdict={r.verdict:+.3f}  edge_weight={r.edge_weight:.3f}")
    assert r.grounded and r.multiplicity == 2

    line("4. NOW belief traversal composes (honest uncertainty across hops)")
    q_bel2, note_bel2 = belief_chain(neuro, "sharpe", hops)
    print(f"belief: value≈{q_bel2.value:+.2f} ± {q_bel2.sigma:.2f}  SNR {q_bel2.snr():.2f}  ({note_bel2})")
    assert q_bel2 is not None and q_bel2.sigma > 1.0 / math.sqrt(2)   # widened by the noisy hops

    line("5. THE METHOD GROWS — trust rises as it grounds across INDEPENDENT domains")
    before = method.trust()
    method2 = method.realized_by("bifurcation_reversal_nq")
    print(f"realizations {method.realizations} (trust {before:.3f})  ->  "
          f"{method2.realizations} (trust {method2.trust():.3f})")
    assert method2.trust() > before   # a second independent grounding strengthens the method

    print("\nmultihop selftest: PASS — synthetic inference proposed a neuromorphic signal "
          "by abstraction, the two gates held (roam in exploration, refuse in belief), the "
          "SAME colimit grounded it once its legs were checked, multi-hop uncertainty stayed "
          "honest, and the method-class strengthened by grounding in a second domain.")


if __name__ == "__main__":
    _selftest()
