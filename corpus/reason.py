"""Structural type composition for the brain's proposed inferences.

The e/t/function algebra mirrors the Haskell semantic types. Matching types
establishes well-formed application, not entailment or the truth of a proposition.
Confidence is metadata, not a calibrated probability; multiplication does not
resolve dependence. Exact signed-claim/rule checking lives in reasoning.engine.
"""
from __future__ import annotations

from dataclasses import dataclass
import math

# --- Ty: mirror of src/NL2Proof/Semantics/Lambda.hs -------------------------- #
@dataclass(frozen=True)
class Ty:
    pass


@dataclass(frozen=True)
class Atom(Ty):
    name: str            # "e" (entity) or "t" (truth value)


@dataclass(frozen=True)
class Fn(Ty):
    dom: Ty
    cod: Ty


TyE, TyT = Atom("e"), Atom("t")
def arrow(a: Ty, b: Ty) -> Fn: return Fn(a, b)     # the ~> constructor
tyPred1 = arrow(TyE, TyT)                            # e~>t
tyGQ = arrow(tyPred1, TyT)                           # (e~>t)~>t


def show(t: Ty) -> str:
    if isinstance(t, Atom):
        return t.name
    inner = show(t.dom)
    if isinstance(t.dom, Fn):
        inner = f"({inner})"
    return f"{inner}~>{show(t.cod)}"


def unify(a: Ty, b: Ty) -> bool:
    """Structural type equality (the argument slot must match the function's domain).
    This establishes structural compatibility, not logical entailment."""
    if isinstance(a, Atom) and isinstance(b, Atom):
        return a.name == b.name
    if isinstance(a, Fn) and isinstance(b, Fn):
        return unify(a.dom, b.dom) and unify(a.cod, b.cod)
    return False


# --- a typed inference (word meaning, proposition, grounded signal, ...) ----- #
@dataclass(frozen=True)
class Inf:
    ty: Ty
    label: str
    conf: float = 1.0                 # bounded metadata; not calibrated by this module
    provenance: frozenset = frozenset()
    grounded: bool = False            # proposals never begin as grounded by default

    def __post_init__(self):
        if not isinstance(self.ty, Ty):
            raise TypeError("ty must be a structural type")
        if type(self.conf) not in (int, float) or not 0 <= self.conf <= 1 or not math.isfinite(self.conf):
            raise ValueError("confidence must be a finite number in [0,1]")
        if type(self.grounded) is not bool:
            raise TypeError("grounded must be a boolean")
        if isinstance(self.provenance, (str, bytes)):
            raise TypeError("provenance must be a collection of source identifiers")
        provenance = frozenset(self.provenance)
        if any(not isinstance(p, str) or not p for p in provenance):
            raise ValueError("provenance identifiers must be nonempty strings")
        object.__setattr__(self, "provenance", provenance)

    def __repr__(self):
        g = "" if self.grounded else " (ungrounded)"
        return f"{self.label}:{show(self.ty)}@{self.conf:.2f}{g}"


class TypeError_(TypeError):
    pass


def apply(f: Inf, x: Inf) -> Inf:
    """Forward/backward application: f : A~>B applied to x : A yields B. The category
    Rejects structural mismatches. Confidence metadata multiplies, provenance unions,
    and grounding metadata is conjunctive. This does not prove an arbitrary A entails B."""
    if not isinstance(f.ty, Fn):
        raise TypeError_(f"{f.label} is not a function ({show(f.ty)})")
    if not unify(f.ty.dom, x.ty):
        raise TypeError_(f"cannot apply {f.label}:{show(f.ty)} to {x.label}:{show(x.ty)} "
                         f"(domain {show(f.ty.dom)} ≠ {show(x.ty)})")
    return Inf(f.ty.cod, f"({f.label} {x.label})", f.conf * x.conf,
               f.provenance | x.provenance, f.grounded and x.grounded)


def compose(f: Inf, g: Inf) -> Inf:
    """Function composition B~>C ∘ A~>B = A~>C (the CCG composition combinator)."""
    if not (isinstance(f.ty, Fn) and isinstance(g.ty, Fn)):
        raise TypeError_("compose needs two functions")
    if not unify(f.ty.dom, g.ty.cod):
        raise TypeError_(f"cannot compose {show(f.ty)} ∘ {show(g.ty)}")
    return Inf(Fn(g.ty.dom, f.ty.cod), f"({f.label}∘{g.label})", f.conf * g.conf,
               f.provenance | g.provenance, f.grounded and g.grounded)


def from_grounding(label, result, provenance):
    """Adapt a checked GroundingResult supplied by a trusted caller.

    Bare scores are not certificates. This adapter supplies no external check of
    its own; the receipt/proof checker must bind the result to a specific claim.
    Empty, refused and zero-multiplicity results remain ungrounded.
    """
    from estimand import GroundingResult
    if not isinstance(result, GroundingResult):
        raise TypeError("from_grounding requires a GroundingResult, not a bare score")
    if isinstance(provenance, (str, bytes)):
        raise TypeError("provenance must be a collection of source identifiers")
    provenance = frozenset(provenance)
    usable = (result.grounded is True and result.multiplicity > 0
              and result.edge_weight > 0 and bool(provenance))
    return Inf(TyT, label, abs(result.verdict), provenance, grounded=usable)


def _selftest():
    from estimand import Leg, colimit
    p = Inf(TyT, "proposal", conf=0.9)
    r = Inf(arrow(TyT, TyT), "proposed-rule", conf=0.8)
    out = apply(r, p)
    assert unify(out.ty, TyT) and not out.grounded
    assert abs(out.conf - 0.72) < 1e-12
    try:
        apply(Inf(tyPred1, "predicate"), p)
        raise AssertionError("structural mismatch accepted")
    except TypeError_:
        pass
    for invalid in (-0.1, 1.1, float("nan"), float("inf"), True):
        try:
            Inf(TyT, "invalid", conf=invalid)
            raise AssertionError("invalid confidence accepted")
        except ValueError:
            pass
    checked = colimit("fixture", [Leg("leg", "prediction", 3.0, 1.0, frozenset({"fixture"}))])
    assert from_grounding("fixture", checked, {"fixture"}).grounded
    assert not from_grounding("empty", colimit("empty", []), set()).grounded
    assert not from_grounding("missing-source", checked, set()).grounded
    try:
        from_grounding("bare-score", 0.99, {"invented"})
        raise AssertionError("bare score grounded")
    except TypeError:
        pass
    print("reason selftest: PASS — structural composition, bounded confidence, "
          "ungrounded defaults; exact entailment requires reasoning.engine.")


if __name__ == "__main__":
    _selftest()
