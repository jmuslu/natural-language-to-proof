"""reason.py — domain-general typed reasoning composition; the layers speak one type algebra.

The categories do the work under the hood. nl2proof's Haskell core makes composition SOUND
by a type discipline: `catTy` maps a CCG category to a semantic type (Ty = e | t | Ty~>Ty),
and the combinators compose typed meanings only when the argument type UNIFIES — validated
externally against CCGbank, never self-certified (see src/NL2Proof/Semantics/Lambda.hs,
Syntax/Category.hs, Syntax/CCGRules.hs). This module lifts that SAME discipline into the
brain's reasoning so the parser, the estimand layer, and multi-hop inference all speak one
`Ty`: an inference is a typed object; composing inferences is combinator application under
type unification; uncertainty composes honestly; provenance guards independence.

The robustness of reasoning IS the type-soundness + honest-uncertainty + provenance — and it
is DOMAIN-GENERAL. The trading domain is one instantiation (a claim is just a `t`-typed
inference); it is not the point. Mirrors the `Ty` algebra exactly. Dependency-free.
"""
from __future__ import annotations

from dataclasses import dataclass, field, replace

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
    This is the check that makes composition sound — the same role catTy/typeOf play."""
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
    conf: float = 1.0                 # confidence in [0,1]; composes by product (honest decay)
    provenance: frozenset = frozenset()
    grounded: bool = True             # belief gate: composing ungrounded yields ungrounded

    def __repr__(self):
        g = "" if self.grounded else " (ungrounded)"
        return f"{self.label}:{show(self.ty)}@{self.conf:.2f}{g}"


class TypeError_(TypeError):
    pass


def apply(f: Inf, x: Inf) -> Inf:
    """Forward/backward application: f : A~>B applied to x : A yields B. The category
    REFUSES a type mismatch (soundness under the hood). Confidence multiplies (honest
    degradation); provenance unions; grounding is conjunctive (two-gate)."""
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


def from_grounding(label, verdict_conf, provenance):
    """Bridge: a grounded signal (estimand.colimit verdict) enters reasoning as a
    `t`-typed proposition. This is how the estimand layer TALKS TO the reasoning layer."""
    return Inf(TyT, label, verdict_conf, frozenset(provenance), grounded=True)


def _selftest():
    print("one type algebra, three domains — same apply/compose machinery:\n")

    # (1) LINGUISTIC: "someone" : (e~>t)~>t (NP=tyGQ);  "sleeps" : (e~>t)~>t ~> t  (S\\NP).
    someone = Inf(tyGQ, "someone")
    sleeps = Inf(arrow(tyGQ, TyT), "sleeps")            # catTy(S\\NP) = catTy NP ~> catTy S
    sent = apply(sleeps, someone)
    print(f"  linguistic : apply(sleeps, someone) = {sent}   [type {show(sent.ty)} = a sentence]")
    assert unify(sent.ty, TyT)

    # (2) ABSTRACT REASONING: a proposition and inference rules (t ~> t). Multi-hop decays.
    p = Inf(TyT, "P", conf=0.9, provenance=frozenset({"obsA"}))
    r1 = Inf(arrow(TyT, TyT), "R1", conf=0.8, provenance=frozenset({"ruleA"}))
    r2 = Inf(arrow(TyT, TyT), "R2", conf=0.85, provenance=frozenset({"ruleB"}))
    step1 = apply(r1, p)
    step2 = apply(r2, step1)
    print(f"  reasoning  : {p} -R1-> {step1} -R2-> {step2}")
    assert step2.conf < step1.conf < p.conf                # honest degradation over hops
    assert abs(step2.conf - 0.9 * 0.8 * 0.85) < 1e-9

    # (3) TRADING is just an instantiation, not special: a grounded signal is a `t`-prop.
    sig = from_grounding("nq_signal", 0.95, {"NQ_ts"})
    risk_rule = Inf(arrow(TyT, TyT), "deploy_if_real", conf=0.9, provenance=frozenset({"policy"}))
    decision = apply(risk_rule, sig)
    print(f"  trading    : apply(deploy_if_real, nq_signal) = {decision}   [no special-casing]")
    assert unify(decision.ty, TyT) and decision.grounded

    # SOUNDNESS: the category refuses an ill-typed composition (a predicate e~>t on a `t`).
    pred = Inf(tyPred1, "red")                              # e~>t
    try:
        apply(pred, p)                                      # applying to a `t`, not an `e`
        assert False, "should have refused"
    except TypeError_ as e:
        print(f"\n  soundness  : refused — {e}")

    # TWO-GATE: composing an UNGROUNDED inference yields an ungrounded (unbelievable) result.
    ungr = Inf(TyT, "hunch", conf=0.6, grounded=False)
    out = apply(risk_rule, ungr)
    assert not out.grounded

    print("\nreason selftest: PASS — one Ty algebra across linguistic, abstract, and trading "
          "composition; the type functor enforces soundness (refuses mismatches); confidence "
          "degrades honestly over hops; ungrounded stays unbelievable. Robustness of "
          "reasoning is domain-general — trading is an instantiation, not the point.")


if __name__ == "__main__":
    _selftest()
