"""Tool-assisted local Horn applications, with an explicit search baseline.

A model selects enabled rule-instance IDs. This module performs typed local
joins over already admitted atoms and constructs chronological engine steps.
It does not apply an unselected rule or choose the model's final answer.
``deterministic_search`` deliberately does both: it is a symbolic solver
baseline, not evidence of model reasoning ability. Neither path imports a
benchmark generator, reference answer, or model client.

Rules remain task assumptions; only separately supplied confirmed receipts
admit leaves. Missing/unknown/refuted receipts are not negative facts. The
frozen engine checks the final proof and retains alternative support paths.
"""
from __future__ import annotations

from dataclasses import asdict, dataclass
import hashlib
import json

from . import engine

SCHEMA = "reasoning.scaffold.v1"


@dataclass(frozen=True)
class ScaffoldLimits:
    rule_scans: int = 10000
    atom_match_attempts: int = 100000
    candidate_instances: int = 4096
    selected_applications: int = 256
    action_calls: int = 64
    selections_per_action: int = 32
    view_calls: int = 128

    def __post_init__(self):
        if any(type(v) is not int or v < 1 for v in asdict(self).values()):
            raise ValueError("scaffold limits must be positive integers")


class WorkLimit(Exception):
    pass


def _canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), allow_nan=False)


def _copy(value):
    return json.loads(_canonical(value))


def _candidate_id(rule_id, substitution):
    raw = _canonical([rule_id, substitution]).encode()
    return "c-" + hashlib.sha256(raw).hexdigest()


class Scaffold:
    """One immutable task/receipt snapshot and a monotonically growing proof.

    ``view()`` exposes only currently enabled one-step applications. ``apply``
    accepts ``{"select": [candidate_id, ...]}``; selections must come from the
    latest view. ``finish(answer)`` returns proof, frozen-engine check, and work
    accounting. Replay a transcript by repeating the same view/action sequence.
    A new snapshot is required after receipt revisions; final proof retraction
    is available through engine.evaluate(...).retract_fact(...).
    """

    def __init__(self, task, receipts, *, limits=None, engine_limits=None):
        self.limits = limits or ScaffoldLimits()
        self.engine_limits = engine_limits or engine.Limits()
        if not isinstance(task, dict) or set(task) - {
                "id", "entities", "predicates", "facts", "rules", "query"}:
            raise ValueError("scaffold requires a public task, without private evaluation fields")
        # Validate JSON size and the authoritative snapshot before any joining.
        initial = engine.evaluate(task, {"answer": "unknown", "steps": [], "conclusion": None},
                                  receipts, limits=self.engine_limits)
        if not initial.accepted:
            raise ValueError("invalid scaffold input: " + _canonical(initial.errors))
        self.task, self.receipts = _copy(task), _copy(receipts)
        self.ctx = engine.context(self.task, self.engine_limits)
        self.trusted = engine.receipt_snapshot(self.receipts, self.ctx, self.engine_limits)
        self.steps, self.known, self.depths = [], {}, {}
        self.applied, self._seen_candidates = set(), set()
        self._menu, self._cache_version = {}, None
        self.version, self.finished = 0, False
        self.exhausted = set()
        self.work = {"validation_calls": 1, "leaf_receipts_inspected": len(self.trusted),
                     "leaf_steps": 0, "duplicate_leaf_aliases": 0,
                     "rule_scans": 0, "atom_match_attempts": 0,
                     "candidate_instances": 0, "selected_applications": 0,
                     "action_calls": 0, "rejected_actions": 0,
                     "view_calls": 0, "cached_views": 0}
        self._frontier_complete = False
        identities = set()
        for fid in sorted(self.trusted):
            a, verdict, eid, _ = self.trusted[fid]
            if verdict != "confirmed":
                continue
            identity = (eid, a)
            if identity in identities:
                self.work["duplicate_leaf_aliases"] += 1
                continue
            if len(self.steps) >= self.engine_limits.steps:
                self.exhausted.add("proof_steps")
                break
            identities.add(identity)
            sid = self._next_step_id()
            self.steps.append({"id": sid, "fact_id": fid})
            self.known.setdefault(a, sid)
            self.depths[sid] = 0
            self.work["leaf_steps"] += 1

    def _next_step_id(self):
        return "s" + str(len(self.steps))

    def _spend(self, kind):
        if self.work[kind] >= getattr(self.limits, kind):
            self.exhausted.add(kind)
            raise WorkLimit(kind)
        self.work[kind] += 1

    def _join(self, rule, available):
        """Enumerate local body joins only; no recursive rule application."""
        def walk(position, substitution, premises):
            if position == len(rule.body):
                yield substitution, premises
                return
            pattern = rule.body[position]
            for candidate in available.get((pattern.predicate, pattern.negated), ()):
                self._spend("atom_match_attempts")
                updated = dict(substitution)
                for expected, actual in zip(pattern.args, candidate.args):
                    if expected.startswith("?"):
                        variable = expected[1:]
                        if variable in updated and updated[variable] != actual:
                            break
                        # Context and admitted atoms are already typed, but keep
                        # the local join boundary explicit for future adapters.
                        if self.ctx.entities[actual] != rule.var_types[variable]:
                            break
                        updated[variable] = actual
                    elif expected != actual:
                        break
                else:
                    yield from walk(position + 1, updated,
                                    premises + [self.known[candidate]])
        yield from walk(0, {}, [])

    def _frontier(self):
        if self._cache_version == self.version:
            self.work["cached_views"] += 1
            return
        available = {}
        for a in sorted(self.known, key=lambda a: a.key()):
            available.setdefault((a.predicate, a.negated), []).append(a)
        menu, complete = {}, True
        try:
            for rid in sorted(self.ctx.rules):
                self._spend("rule_scans")
                rule = self.ctx.rules[rid]
                for substitution, premises in self._join(rule, available):
                    cid = _candidate_id(rid, substitution)
                    if cid in self.applied:
                        continue
                    depth = 1 + max(self.depths[p] for p in premises)
                    if depth > self.engine_limits.proof_depth:
                        self.exhausted.add("proof_depth")
                        complete = False
                        continue
                    if cid not in self._seen_candidates:
                        self._spend("candidate_instances")
                        self._seen_candidates.add(cid)
                    head = engine.instantiate(rule.head, substitution)
                    menu[cid] = {"id": cid, "rule_id": rid,
                                 "substitution": substitution, "premises": premises,
                                 "body": [engine.instantiate(a, substitution).to_dict() for a in rule.body],
                                 "head": head.to_dict(), "depth": depth,
                                 "adds_new_atom": head not in self.known}
        except WorkLimit:
            complete = False
        self._menu = menu
        self._frontier_complete = complete
        self._cache_version = self.version

    def accounting(self):
        return {**self.work, "proof_steps": len(self.steps), "known_atoms": len(self.known),
                "limits": asdict(self.limits), "engine_limits": asdict(self.engine_limits),
                "exhausted": sorted(self.exhausted)}

    def view(self):
        if self.finished:
            raise ValueError("scaffold already finished")
        try:
            self._spend("view_calls")
        except WorkLimit:
            return {"schema": SCHEMA, "version": self.version, "query": self.ctx.query.to_dict(),
                    "known": [], "candidates": [], "frontier_complete": False,
                    "status": "budget_exhausted", "work": self.accounting()}
        self._frontier()
        return {"schema": SCHEMA, "version": self.version, "query": self.ctx.query.to_dict(),
                "known": [{"step_id": sid, "atom": a.to_dict(), "depth": self.depths[sid]}
                          for a, sid in sorted(self.known.items(), key=lambda pair: pair[0].key())],
                "unavailable_fact_ids": sorted(fid for fid, r in self.trusted.items() if r[1] != "confirmed"),
                "candidates": [_copy(c) for c in self._menu.values()],
                "frontier_complete": self._frontier_complete,
                "status": "ready" if self._menu else "saturated" if self._frontier_complete and not self.exhausted else "budget_exhausted",
                "work": self.accounting()}

    def apply(self, action):
        if self.finished:
            raise ValueError("scaffold already finished")
        def reject(code, message):
            self.work["rejected_actions"] += 1
            return {"accepted": False, "errors": [{"code": code, "message": message}],
                    "version": self.version, "work": self.accounting()}
        try:
            self._spend("action_calls")
        except WorkLimit:
            return reject("resource_limit", "action call budget exhausted")
        if (not isinstance(action, dict) or set(action) != {"select"}
                or not isinstance(action["select"], list)
                or not action["select"]
                or len(action["select"]) > self.limits.selections_per_action):
            return reject("invalid_action", "select a nonempty bounded list of candidate IDs")
        selected = action["select"]
        if any(not isinstance(cid, str) for cid in selected) or len(set(selected)) != len(selected):
            return reject("invalid_action", "candidate IDs must be distinct strings")
        if self._cache_version != self.version or any(cid not in self._menu for cid in selected):
            return reject("unknown_candidate", "select only IDs from the current view")
        if self.work["selected_applications"] + len(selected) > self.limits.selected_applications:
            self.exhausted.add("selected_applications")
            return reject("resource_limit", "selected application budget exhausted")
        if len(self.steps) + len(selected) > self.engine_limits.steps:
            self.exhausted.add("proof_steps")
            return reject("resource_limit", "proof step budget exhausted")
        # Validate the whole action before mutating the proof. Every candidate's
        # premises predate this action, even when several candidates are selected.
        added = []
        for cid in selected:
            c = self._menu[cid]
            sid = self._next_step_id()
            step = {"id": sid, "rule_id": c["rule_id"],
                    "substitution": dict(c["substitution"]), "premises": list(c["premises"])}
            self.steps.append(step)
            head = engine.instantiate(self.ctx.rules[c["rule_id"]].head, c["substitution"])
            self.depths[sid] = c["depth"]
            if head not in self.known or c["depth"] < self.depths[self.known[head]]:
                self.known[head] = sid
            self.applied.add(cid)
            self.work["selected_applications"] += 1
            added.append({"candidate_id": cid, "step_id": sid, "head": head.to_dict()})
        self.version += 1
        return {"accepted": True, "errors": [], "added": added,
                "version": self.version, "work": self.accounting()}

    def finish(self, answer):
        if self.finished:
            raise ValueError("scaffold already finished")
        if answer not in ("entailed", "refuted", "unknown"):
            raise ValueError("answer must be entailed, refuted, or unknown")
        target = self.ctx.query if answer == "entailed" else self.ctx.query.opposite()
        proposal = {"answer": answer, "steps": _copy(self.steps),
                    "conclusion": None if answer == "unknown" else self.known.get(target)}
        checked = engine.evaluate(self.task, proposal, self.receipts, limits=self.engine_limits)
        self.work["validation_calls"] += 1
        self.finished = True
        return {"schema": SCHEMA, "method": "model_selected_local_applications",
                "proposal": proposal, "check": checked.to_dict(), "work": self.accounting(),
                "frontier_complete": self._cache_version == self.version and self._frontier_complete,
                "saturated": (self._cache_version == self.version and self._frontier_complete
                              and not self._menu and not self.exhausted),
                "answer_origin": "caller", "rules_role": "task_assumptions"}


def deterministic_search(task, receipts, *, limits=None, engine_limits=None):
    """Explicit bounded forward search using exactly the same local tool.

    All reachable rule instances, including alternative supports and cycles,
    are considered until saturation or budget exhaustion. Any reported answer
    comes from this symbolic search and the checker, not from a model.
    """
    scaffold = Scaffold(task, receipts, limits=limits, engine_limits=engine_limits)
    while True:
        view = scaffold.view()
        candidates = view["candidates"]
        if not candidates:
            break
        remaining = min(scaffold.limits.selections_per_action,
                        scaffold.limits.selected_applications - scaffold.work["selected_applications"],
                        scaffold.engine_limits.steps - len(scaffold.steps))
        if remaining <= 0:
            scaffold.exhausted.add("selected_applications" if scaffold.work["selected_applications"] >=
                                   scaffold.limits.selected_applications else "proof_steps")
            break
        if not scaffold.apply({"select": [c["id"] for c in candidates[:remaining]]})["accepted"]:
            break
    positive = scaffold.ctx.query in scaffold.known
    negative = scaffold.ctx.query.opposite() in scaffold.known
    answer = "entailed" if positive and not negative else "refuted" if negative and not positive else "unknown"
    result = scaffold.finish(answer)
    result.update(method="deterministic_forward_search", answer_origin="symbolic_search",
                  search_complete=result["saturated"], model_calls=0)
    return result
