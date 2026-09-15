"""Candidate templates and conditional numerical propagation.

Exploration can instantiate a template without measurements. Coherence of supplied
legs is a local diagnostic, not external verification. Numerical propagation needs
an explicitly identified Quantity with its own estimate and uncertainty; qualitative
grounding scores never become numerical effects. None of these helpers writes trust
or supplies the external validation receipt required by the ingestion boundary.
"""
from __future__ import annotations

from dataclasses import dataclass, replace

from estimand import (EstimandIdentity, Quantity, Leg, colimit, Hop, compose_chain,
                      GroundingResult, Z_SIGNIF)


@dataclass(frozen=True)
class LegSlot:
    """A proposed check, with null margin fixed before measuring the candidate."""
    name: str
    kind: str
    direction: int = +1
    present: bool = True
    equivalence_margin: float | None = None
    equivalence_z: float = Z_SIGNIF

    def __post_init__(self):
        # Validate the proposed schema without treating it as measured evidence.
        Leg(self.name, self.kind, 0, 1, frozenset(), self.direction, self.present,
            equivalence_margin=self.equivalence_margin, equivalence_z=self.equivalence_z)


@dataclass(frozen=True)
class MethodClass:
    name: str
    applicability: str
    template: tuple
    realizations: tuple = ()  # inventory labels only; neither validation nor independence

    def trust(self) -> None:
        """Legacy accessor: unknown. Names/counts do not estimate method performance.

        Calibrated method accuracy requires independently scored predictions with
        a sampling/selection protocol; no such observations live in this record.
        """
        return None

    def realized_by(self, apex: str) -> "MethodClass":
        """Record an inventory label idempotently; never increase trust or precision."""
        if not isinstance(apex, str) or not apex.strip():
            raise ValueError("apex must be a nonempty inventory label")
        return self if apex in self.realizations else replace(self, realizations=self.realizations + (apex,))


@dataclass
class CandidateApex:
    name: str
    context: str
    method: str
    slots: tuple
    status: str = "proposed-not-grounded"
    result: GroundingResult | None = None
    estimand_identity: EstimandIdentity | None = None

    def measure(self, effects: dict) -> GroundingResult:
        """Check supplied (effect, stderr, provenance) triples against frozen slots.

        These are caller-supplied measurements; this method does not authenticate
        them. Missing slots/margins remain nonbinding. Status is explicitly local
        coherence, not an assertion of an external oracle outcome.
        """
        legs = []
        for slot in self.slots:
            effect, stderr, provenance = effects.get(slot.name, (0., 1., frozenset()))
            legs.append(Leg(slot.name, slot.kind, effect, stderr, provenance,
                            slot.direction, slot.present,
                            equivalence_margin=slot.equivalence_margin, equivalence_z=slot.equivalence_z))
        self.result = colimit(self.name, legs)
        self.status = "coherent-unverified" if self.result.grounded else "incomplete-or-incoherent"
        return self.result


def propose(method: MethodClass, apex_name: str, context: str, *,
            estimand_identity: EstimandIdentity | None = None) -> CandidateApex:
    """Instantiate proposed checks freely; no data, precision, or trust is created."""
    return CandidateApex(apex_name, context, method.name, tuple(method.template),
                         estimand_identity=estimand_identity)


def _base(apex, base):
    if base is None:
        return None
    if not isinstance(base, Quantity):
        raise TypeError("supply a Quantity with an actual numerical estimate/uncertainty, not a units string")
    if apex.estimand_identity is None or base.identity != apex.estimand_identity:
        raise TypeError("candidate and numerical base require matching explicit estimand identities")
    return base


def belief_chain(apex: CandidateApex, base: Quantity | None, hops: list[Hop]):
    """Legacy-named conditional numerical calculation; does not grant belief.

    Requires coherent legs and a separately supplied measured Quantity for the
    named target. Provenance/sample count permit local checks, not authentication.
    External validation remains the receipt evaluator's job. No numerical base
    means no numerical result, even when qualitative checks pass.
    """
    base = _base(apex, base)
    if base is None:
        return None, "numerical estimate and uncertainty unavailable; qualitative verdict cannot supply them"
    if apex.result is None or not apex.result.grounded:
        return None, f"supplied checks for {apex.name!r} are incomplete or incoherent"
    if not base.support.get("provenance") or not base.support.get("n"):
        return None, "numerical measurement needs its own declared provenance and sample count"
    out, local_gain_snr_ok = compose_chain(base, hops)
    return out, (f"conditional calculation from supplied measurement; local_gain_snr_ok={local_gain_snr_ok}; "
                 "external validation remains required before belief changes")


def explore_chain(apex: CandidateApex, base: Quantity | None, hops: list[Hop]):
    """Propagate an explicit numerical scenario, independent of grounding status.

    A candidate without a numeric scenario remains explorable as a template. The
    absence of a numeric output does not prune its proposal or manufacture numbers.
    """
    base = _base(apex, base)
    if base is None:
        return None, "exploration template retained; no numerical scenario supplied"
    out, _ = compose_chain(base, hops)
    return out, "EXPLORATION SCENARIO; caller-supplied values, not validated belief"


def _selftest():
    target = EstimandIdentity("generator response", "synthetic population", "one step", (),
                              "response_units", "raw", "mean")
    method = MethodClass("conditional_residual", "proposed conditional mechanism", (
        LegSlot("edge", "prediction"),
        LegSlot("matched_control", "necessity", equivalence_margin=.5)))
    candidate = propose(method, "synthetic_candidate", "illustrative generator", estimand_identity=target)
    # Explicit scenario exists independently of the qualitative checks.
    base = Quantity(3., 1., "response_units", identity=target,
                    support={"n": 100, "provenance": {"synthetic-measurement"}})
    hops = [Hop(.5, .1, "declared linear response model")]
    assert belief_chain(candidate, base, hops)[0] is None
    assert explore_chain(candidate, base, hops)[0] is not None
    assert explore_chain(candidate, None, hops)[0] is None
    result = candidate.measure({"edge": (3., 1., {"synthetic-measurement"}),
                                "matched_control": (0., .1, {"synthetic-control"})})
    assert result.grounded and candidate.status == "coherent-unverified"
    assert belief_chain(candidate, None, hops)[0] is None
    propagated, note = belief_chain(candidate, base, hops)
    assert propagated.value == 1.5 and propagated.sigma > .5
    named = method.realized_by("same-data-renamed").realized_by("another-name")
    assert named.trust() is None and method.trust() is None
    print("multihop selftest: PASS; template exploration, measured numeric base, margin-based controls; "
          "inventory names grant no trust; all measurements here are synthetic")
    print(note)


if __name__ == "__main__":
    _selftest()
