"""retract.py — least-fixed-point grounding + PRECISE retraction, mirroring Genealogy.hs.

The brain's estimand grounding (colimit + multiplicity) and nl2proof's Haskell
`NL2Proof.Genealogy` are the same object seen twice; this makes them talk. Genealogy's
core, faithfully in Python:

  * GROUNDED is a LEAST fixed point — a claim is grounded iff some justification has all
    antecedents grounded, bottoming out in oracle-confirmed premises. Least (not greatest)
    is the anti-self-agreement property: a claim cannot ground itself around a cycle
    (mutual consistency ≠ truth).
  * PRECISE RETRACTION — when the oracle flips a premise, recompute grounded and withdraw
    exactly the set difference. A claim with a SECOND independent derivation (multiplicity
    ≥ 2, in the colimit view) keeps its support; the naive "everything downstream" answer
    over-retracts, and the gap is measurable (Genealogy's retractionReport).

This is what the reverse-propagation story was missing: an oracle changing its mind must
retract precisely, not blanket-withdraw. Domain-general. Dependency-free.
"""
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class Genealogy:
    premises: dict = field(default_factory=dict)      # id -> oracle verdict (bool)
    justifications: list = field(default_factory=list)  # (target, frozenset(antecedents))
    claims: set = field(default_factory=set)

    def add_premise(self, pid, verdict=True): self.premises[pid] = verdict
    def add_claim(self, cid): self.claims.add(cid)
    def justify(self, target, antecedents):
        self.add_claim(target); self.justifications.append((target, frozenset(antecedents)))

    def grounded(self) -> set:
        """Least fixed point: start from oracle-confirmed premises, add any claim with a
        justification whose antecedents are all grounded, iterate to convergence."""
        g = {p for p, v in self.premises.items() if v}
        changed = True
        while changed:
            changed = False
            for target, ante in self.justifications:
                if target not in g and ante <= g:
                    g.add(target); changed = True
        return g

    def dependents(self, pid) -> set:
        """Naive downstream reachability (the OVER-retraction answer)."""
        dep, frontier = set(), [pid]
        while frontier:
            cur = frontier.pop()
            for target, ante in self.justifications:
                if cur in ante and target not in dep:
                    dep.add(target); frontier.append(target)
        return dep

    def retract(self, pid) -> dict:
        """Flip a premise's verdict and return the PRECISE withdrawal (set difference of
        the least fixed points), plus the naive over-retraction and the gap between them."""
        before = self.grounded()
        saved = self.premises[pid]
        self.premises[pid] = False
        after = self.grounded()
        self.premises[pid] = saved
        precise = before - after
        naive = ({pid} | self.dependents(pid)) & before
        return {"precise": precise, "naive": naive, "over_retracted": naive - precise,
                "survivors": (naive - precise) & self.grounded()}


def _selftest():
    g = Genealogy()
    for p in ("P1", "P2", "P3"):
        g.add_premise(p, True)
    g.justify("C", {"P1"})          # C has TWO independent derivations...
    g.justify("C", {"P2"})          # ...J1 from P1, J2 from P2  (multiplicity 2)
    g.justify("D", {"C", "P3"})     # D depends on C
    g.justify("E", {"P1"})          # E depends SOLELY on P1

    before = g.grounded()
    assert {"P1", "P2", "P3", "C", "D", "E"} <= before, before
    print(f"grounded before: {sorted(before)}")

    rep = g.retract("P1")
    print(f"retract P1  -> precise withdrawal: {sorted(rep['precise'])}")
    print(f"            -> naive downstream  : {sorted(rep['naive'])}")
    print(f"            -> over-retracted     : {sorted(rep['over_retracted'])} "
          f"(kept by independent support)")

    # PRECISE: only P1 and E are withdrawn; C survives via its second derivation (P2), and
    # D survives because C does. NAIVE would blanket-withdraw C and D too.
    assert rep["precise"] == {"P1", "E"}, rep["precise"]
    assert "C" not in rep["precise"] and "D" not in rep["precise"]
    assert rep["over_retracted"] == {"C", "D"}, rep["over_retracted"]

    # ANTI-SELF-AGREEMENT: a cycle with no confirmed premise grounds NEITHER node (lfp).
    c = Genealogy()
    c.justify("A", {"B"}); c.justify("B", {"A"})
    assert c.grounded() == set(), c.grounded()
    print("\ncycle A<->B with no confirmed premise: grounded = {} (least fixed point "
          "refuses self-agreement)")

    print("\nretract selftest: PASS — grounding is a least fixed point (anti-self-agreement); "
          "retraction is precise (a claim with a second independent derivation survives, "
          "multiplicity in the colimit view); the naive answer over-retracts by {C,D}. "
          "The brain's grounding now speaks Genealogy's language.")


if __name__ == "__main__":
    _selftest()
