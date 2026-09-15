"""Bounded Horn proof checking; no solver and no access to reference answers.

Task rules are trusted assumptions of the specified benchmark/world, not rules
attested about real markets. Receipts come from a caller's authoritative adapter,
never a model response. Explicit negation needs its own confirmed signed atom.
Unknown is abstention, not a certificate that no proof could exist.
"""
from __future__ import annotations
from dataclasses import dataclass, field
import json
import re

from retract import Genealogy
from reason import Atom as Sort, Fn, Inf, apply


@dataclass(frozen=True)
class Limits:
    entities: int = 256
    predicates: int = 128
    facts: int = 512
    rules: int = 256
    steps: int = 512
    arity: int = 8
    body: int = 16
    variables: int = 16
    proof_depth: int = 64
    bytes: int = 1_000_000


class Invalid(ValueError):
    def __init__(self, code, message, step=None):
        super().__init__(message)
        self.error = {"code": code, "step": step, "message": message}


def fail(code, message, step=None):
    raise Invalid(code, message, step)


def identifier(value, label):
    if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._:-]{0,127}", value):
        fail("invalid_identifier", f"{label} must be a compact identifier")
    return value


def obj(value, label):
    if not isinstance(value, dict):
        fail("invalid_schema", f"{label} must be an object")
    return value


def seq(value, label, maximum):
    if not isinstance(value, list):
        fail("invalid_schema", f"{label} must be a list")
    if len(value) > maximum:
        fail("resource_limit", f"{label} exceeds limit {maximum}")
    return value


@dataclass(frozen=True)
class Atom:
    predicate: str
    args: tuple[str, ...]
    negated: bool = False

    def to_dict(self):
        return {"predicate": self.predicate, "args": list(self.args), "negated": self.negated}

    def key(self):
        return json.dumps(self.to_dict(), sort_keys=True, separators=(",", ":"))

    def opposite(self):
        return Atom(self.predicate, self.args, not self.negated)


@dataclass(frozen=True)
class Rule:
    id: str
    var_types: dict
    body: tuple
    head: Atom


@dataclass
class Context:
    entities: dict
    predicates: dict
    facts: set
    rules: dict
    query: Atom


def atom(raw, entities, predicates, variables, limits):
    obj(raw, "atom")
    if set(raw) - {"predicate", "args", "negated"} or not {"predicate", "args"} <= set(raw):
        fail("invalid_atom", "atom requires predicate,args and optional negated")
    predicate = identifier(raw["predicate"], "predicate")
    if predicate not in predicates:
        fail("unknown_predicate", f"predicate {predicate} is not declared")
    args = seq(raw["args"], "atom.args", limits.arity)
    negated = raw.get("negated", False)
    if type(negated) is not bool:
        fail("invalid_atom", "negated must be a boolean")
    signature = predicates[predicate]
    if len(args) != len(signature):
        fail("arity_mismatch", f"predicate {predicate} has wrong arity")
    for arg, wanted in zip(args, signature):
        if isinstance(arg, str) and arg.startswith("?"):
            name = identifier(arg[1:], "variable")
            if name not in variables:
                fail("unbound_variable", f"variable {name} is not declared here")
            actual = variables[name]
        else:
            identifier(arg, "entity")
            if arg not in entities:
                fail("unknown_entity", f"entity {arg} is not declared")
            actual = entities[arg]
        if actual != wanted:
            fail("type_mismatch", f"argument of {predicate} requires {wanted}, got {actual}")
    return Atom(predicate, tuple(args), negated)


def variables(a):
    return {arg[1:] for arg in a.args if arg.startswith("?")}


def context(task, limits):
    obj(task, "task")
    for key in ("entities", "predicates", "facts", "rules", "query"):
        if key not in task:
            fail("invalid_task", f"task missing {key}")
    entities, predicates = obj(task["entities"], "entities"), obj(task["predicates"], "predicates")
    if len(entities) > limits.entities or len(predicates) > limits.predicates:
        fail("resource_limit", "task entity/predicate limit exceeded")
    for entity, ty in entities.items():
        identifier(entity, "entity"); identifier(ty, "type")
    for predicate, signature in predicates.items():
        identifier(predicate, "predicate")
        for ty in seq(signature, "predicate signature", limits.arity):
            identifier(ty, "type")
    facts = set()
    for fact in seq(task["facts"], "facts", limits.facts):
        obj(fact, "fact")
        fid = identifier(fact.get("id"), "fact id")
        if fid in facts:
            fail("duplicate_fact_id", f"duplicate fact {fid}")
        if not isinstance(fact.get("text"), str):
            fail("invalid_task", "each public fact requires readable text")
        facts.add(fid)
    rules = {}
    for raw in seq(task["rules"], "rules", limits.rules):
        obj(raw, "rule")
        rid = identifier(raw.get("id"), "rule id")
        if rid in rules:
            fail("duplicate_rule_id", f"duplicate rule {rid}")
        vt = obj(raw.get("var_types"), "var_types")
        if len(vt) > limits.variables:
            fail("resource_limit", "rule variable limit exceeded")
        for name, ty in vt.items():
            identifier(name, "variable"); identifier(ty, "type")
        body_raw = seq(raw.get("body"), "rule body", limits.body)
        if not body_raw:
            fail("empty_rule_body", "rules cannot manufacture unsupported premises")
        body = tuple(atom(a, entities, predicates, vt, limits) for a in body_raw)
        head = atom(raw.get("head"), entities, predicates, vt, limits)
        bv = set().union(*(variables(a) for a in body))
        hv = variables(head)
        if not hv <= bv:
            fail("unsafe_rule", "head variables must occur in the rule body")
        if set(vt) != bv | hv:
            fail("unused_variable", "var_types must exactly name variables used by rule")
        rules[rid] = Rule(rid, dict(vt), body, head)
    query = atom(task["query"], entities, predicates, {}, limits)
    return Context(dict(entities), dict(predicates), facts, rules, query)


def receipt_snapshot(raw, ctx, limits):
    obj(raw, "receipts")
    if len(raw) > limits.facts:
        fail("resource_limit", "receipt count limit exceeded")
    receipts, identities = {}, {}
    for fid, receipt in raw.items():
        identifier(fid, "receipt fact id")
        if fid not in ctx.facts:
            fail("unknown_fact", f"receipt names undeclared fact {fid}")
        obj(receipt, "receipt")
        a = atom(receipt.get("atom"), ctx.entities, ctx.predicates, {}, limits)
        verdict = receipt.get("verdict")
        if verdict not in ("confirmed", "refuted", "unknown"):
            fail("invalid_receipt", f"receipt {fid} has invalid verdict")
        evidence = receipt.get("evidence_id")
        if evidence is not None:
            identifier(evidence, "evidence_id")
        prov = seq(receipt.get("provenance", []), "provenance", limits.facts)
        for source in prov:
            identifier(source, "provenance id")
        prov = frozenset(prov)
        if verdict == "confirmed" and (not evidence or not prov):
            fail("invalid_receipt", f"confirmed fact {fid} needs evidence and provenance")
        identity, signature = (evidence, a), (verdict, prov)
        if evidence and identity in identities and identities[identity] != signature:
            fail("conflicting_receipt", "duplicate evidence identity has inconsistent receipt")
        identities[identity] = signature
        receipts[fid] = (a, verdict, evidence, prov)
    return receipts


def instantiate(a, substitution):
    return Atom(a.predicate, tuple(substitution[x[1:]] if x.startswith("?") else x for x in a.args), a.negated)


def atom_node(a):
    return "atom:" + a.key()


def claim_sort(a):
    # Singleton sorts bind exact signed atom identity. Generic t->t is insufficient.
    return Sort("claim:" + a.key())


@dataclass
class CheckResult:
    accepted: bool
    requested_answer: str = "unknown"
    errors: list = field(default_factory=list)
    genealogy: Genealogy = field(default_factory=Genealogy, repr=False)
    query: Atom | None = None
    target: Atom | None = None
    conclusions: dict = field(default_factory=dict, repr=False)
    fact_nodes: dict = field(default_factory=dict, repr=False)
    evidence: dict = field(default_factory=dict, repr=False)
    depths: dict = field(default_factory=dict, repr=False)
    direct_atoms: dict = field(default_factory=dict, repr=False)
    direct_active: set = field(default_factory=set, repr=False)

    @property
    def support_status(self):
        if not self.accepted:
            return "rejected"
        if self.requested_answer == "unknown":
            return "abstained"
        gr = self.genealogy.grounded()
        if self.target and atom_node(self.target) in gr:
            opposite = self.target.opposite()
            known_opposite = any(self.direct_atoms[node] == opposite for node in self.direct_active)
            return "conflicting" if known_opposite or atom_node(opposite) in gr else "supported"
        return "withdrawn"

    @property
    def grounded(self):
        return self.accepted and self.support_status == "supported"

    @property
    def answered(self):
        return self.grounded

    @property
    def abstained(self):
        return self.accepted and not self.answered

    @property
    def verdict(self):
        return self.requested_answer if self.answered else "unknown"

    def to_dict(self):
        gr = self.genealogy.grounded()
        evidence = {eid for node, (eid, _) in self.evidence.items() if node in gr}
        provenance = set().union(*(prov for node, (_, prov) in self.evidence.items() if node in gr))
        return {
            "accepted": self.accepted, "requested_answer": self.requested_answer,
            "answer": self.verdict, "verdict": self.verdict,
            "answered": self.answered, "grounded": self.grounded,
            "abstained": self.abstained, "support_status": self.support_status,
            "errors": list(self.errors),
            "query": self.query.to_dict() if self.query else None,
            "conclusion": self.target.to_dict() if self.target else None,
            "validated_steps": len(self.conclusions), "max_depth": max(self.depths.values(), default=0),
            "unique_evidence": len(evidence), "provenance_sources": sorted(provenance),
            "grounded_atoms": sorted(node[5:] for node in gr if node.startswith("atom:")),
        }

    def retract_fact(self, fact_id):
        """Persist withdrawal of an evidence identity, including its duplicate aliases."""
        if fact_id not in self.fact_nodes:
            raise KeyError(fact_id)
        node = self.fact_nodes[fact_id]
        self.direct_active.discard(node)
        if node in self.genealogy.premises:
            report = self.genealogy.set_verdict(node, False)
        else:
            report = {"precise": set(), "survivors": set()}
        return {
            "fact_id": fact_id,
            "affected_aliases": sorted(fid for fid, nid in self.fact_nodes.items() if nid == node),
            "withdrawn": sorted(report["precise"]), "survivors": sorted(report["survivors"]),
            "result": self.to_dict(),
        }


def evaluate(task, proposal, receipts, *, limits=None):
    """Check supplied steps only. The separate receipts argument is never model input."""
    limits = limits or Limits()
    result, current_step = CheckResult(False), None
    try:
        try:
            size = len(json.dumps([task, proposal, receipts], ensure_ascii=False, allow_nan=False).encode())
        except (ValueError, TypeError, RecursionError):
            fail("invalid_json", "inputs must be finite JSON values")
        if size > limits.bytes:
            fail("resource_limit", "combined input size limit exceeded")
        ctx = context(task, limits)
        trusted = receipt_snapshot(receipts, ctx, limits)
        # Inspect direct opposing receipts even if the proposer omits their leaves.
        # This is a source conflict check, not search for an opposing derivation.
        for fid, (a, verdict, eid, _) in trusted.items():
            if verdict == "confirmed":
                node = "evidence:" + json.dumps([eid, a.to_dict()], sort_keys=True, separators=(",", ":"))
                result.fact_nodes[fid] = node
                result.direct_atoms[node] = a
                result.direct_active.add(node)
        result.query = ctx.query
        obj(proposal, "proposal")
        if set(proposal) - {"answer", "steps", "conclusion"}:
            fail("invalid_proposal", "proposal contains unsupported fields")
        answer = proposal.get("answer")
        if answer not in ("entailed", "refuted", "unknown"):
            fail("invalid_answer", "answer must be entailed, refuted, or unknown")
        result.requested_answer = answer
        steps = seq(proposal.get("steps"), "steps", limits.steps)
        inferences, identities = {}, {}
        for step in steps:
            obj(step, "step")
            current_step = identifier(step.get("id"), "step id")
            if current_step in result.conclusions:
                fail("duplicate_step_id", f"duplicate step {current_step}")
            keys = set(step)
            if keys == {"id", "fact_id"}:
                fid = identifier(step["fact_id"], "fact id")
                if fid not in ctx.facts:
                    fail("unknown_fact", f"fact {fid} is not declared")
                receipt = trusted.get(fid)
                if receipt is None or receipt[1] != "confirmed":
                    fail("unconfirmed_fact", f"fact {fid} lacks a confirmed receipt")
                a, _, eid, prov = receipt
                identity = (eid, a)
                if identity not in identities:
                    node = "evidence:" + json.dumps([eid, a.to_dict()], sort_keys=True, separators=(",", ":"))
                    identities[identity] = node
                    result.genealogy.add_premise(node, True)
                    result.evidence[node] = (eid, prov)
                    result.genealogy.justify(atom_node(a), {node})
                result.fact_nodes[fid] = identities[identity]
                inf, depth = Inf(claim_sort(a), current_step, 1.0, prov, grounded=True), 0
            elif keys == {"id", "rule_id", "substitution", "premises"}:
                rid = identifier(step["rule_id"], "rule id")
                if rid not in ctx.rules:
                    fail("unknown_rule", f"rule {rid} is not declared")
                rule = ctx.rules[rid]
                sub = obj(step["substitution"], "substitution")
                if set(sub) != set(rule.var_types):
                    fail("invalid_substitution", "bind every declared variable exactly")
                for var, entity in sub.items():
                    identifier(entity, "substituted entity")
                    if entity not in ctx.entities or ctx.entities[entity] != rule.var_types[var]:
                        fail("type_mismatch", f"substitution for {var} has wrong entity type")
                premises = seq(step["premises"], "premises", limits.body)
                if len(premises) != len(rule.body):
                    fail("missing_premise", "one premise id per ordered body atom is required")
                for pid in premises:
                    identifier(pid, "premise id")
                    if pid not in result.conclusions:
                        fail("nonchronological_reference", "premise must name an earlier validated step")
                expected = tuple(instantiate(a, sub) for a in rule.body)
                actual = tuple(result.conclusions[pid] for pid in premises)
                if actual != expected:
                    fail("premise_mismatch", "premise atoms do not match instantiated rule body")
                a = instantiate(rule.head, sub)
                ty = claim_sort(a)
                for body_atom in reversed(expected):
                    ty = Fn(claim_sort(body_atom), ty)
                inf = Inf(ty, f"task-assumption:{rid}", 1.0, frozenset(), grounded=True)
                for pid in premises:
                    inf = apply(inf, inferences[pid])
                if inf.ty != claim_sort(a):
                    fail("type_mismatch", "composed inference has unexpected conclusion sort")
                depth = 1 + max(result.depths[pid] for pid in premises)
                if depth > limits.proof_depth:
                    fail("resource_limit", "proof depth limit exceeded")
                result.genealogy.justify(atom_node(a), {atom_node(x) for x in actual})
            else:
                fail("invalid_step", "step must be exactly a fact leaf or a rule instance")
            result.conclusions[current_step] = a
            result.depths[current_step], inferences[current_step] = depth, inf
        current_step = None
        conclusion = proposal.get("conclusion")
        if answer == "unknown":
            if conclusion is not None:
                fail("invalid_conclusion", "unknown cannot assert a conclusion proof")
        else:
            if not isinstance(conclusion, str) or conclusion not in result.conclusions:
                fail("missing_conclusion", "answered response needs a validated terminal step")
            target = ctx.query if answer == "entailed" else ctx.query.opposite()
            if result.conclusions[conclusion] != target:
                fail("wrong_conclusion", "terminal proof does not establish requested signed query")
            result.target = target
        result.accepted = True
    except Invalid as exc:
        error = dict(exc.error)
        error["step"] = error["step"] or current_step
        result.errors.append(error)
    return result

