"""Versioned generated-world multi-hop benchmark, with an independent reference.

The reference exhaustively evaluates finite Horn worlds. It does not import the
step checker or infer truth from a proposed proof. Gold labels/witnesses are kept
out of public prompts. These are controlled reasoning tasks, not measurements of
market discovery, unconstrained language extraction, or frontier parity.
"""
from __future__ import annotations

import argparse
import hashlib
import itertools
import json
from pathlib import Path
import random

VERSION = "typed-worlds-v2"


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def fingerprint(value):
    return hashlib.sha256(canonical(value).encode()).hexdigest()


def atom(predicate, *args, negated=False):
    return {"predicate": predicate, "args": list(args), "negated": negated}


def key(value):
    return value["predicate"], tuple(value["args"]), value.get("negated", False)


def instantiate(value, binding):
    return (value["predicate"], tuple(binding[a[1:]] if a.startswith("?") else a for a in value["args"]),
            value.get("negated", False))


def reference(task, receipts):
    """Exhaustive finite-world closure, separately implemented from proof checking.

    Returns a minimum-depth witness for testing the checker, never for model
    feedback. Explicit negative predicates are ordinary signed atoms; absence
    alone cannot establish a negative claim.
    """
    known = {}
    for fid, receipt in sorted(receipts.items()):
        if receipt["verdict"] == "confirmed":
            known.setdefault(key(receipt["atom"]), (0, ("fact", fid)))
    changed = True
    while changed:
        changed = False
        for rule in task["rules"]:
            names = sorted(rule["var_types"])
            candidates = [[e for e, ty in task["entities"].items() if ty == rule["var_types"][v]] for v in names]
            for values in itertools.product(*candidates):
                binding = dict(zip(names, values))
                antecedents = tuple(instantiate(a, binding) for a in rule["body"])
                if not all(a in known for a in antecedents):
                    continue
                conclusion = instantiate(rule["head"], binding)
                depth = 1 + max(known[a][0] for a in antecedents)
                if conclusion not in known or depth < known[conclusion][0]:
                    known[conclusion] = depth, ("rule", rule["id"], binding, antecedents)
                    changed = True
    query = key(task["query"])
    opposite = query[0], query[1], not query[2]
    if query in known and opposite in known:
        raise ValueError("benchmark world derives both query polarities")
    target = query if query in known else opposite if opposite in known else None
    label = "entailed" if target == query else "refuted" if target == opposite else "unknown"
    steps, emitted = [], {}

    def emit(goal):
        if goal in emitted:
            return emitted[goal]
        evidence = known[goal][1]
        if evidence[0] == "fact":
            step = {"fact_id": evidence[1]}
        else:
            step = {"rule_id": evidence[1], "substitution": evidence[2],
                    "premises": [emit(a) for a in evidence[3]]}
        sid = f"s{len(steps)}"
        steps.append({"id": sid, **step})
        emitted[goal] = sid
        return sid

    conclusion = emit(target) if target is not None else None
    return {"answer": label, "minimum_depth": known[target][0] if target else None,
            "proof": {"answer": label, "steps": steps, "conclusion": conclusion},
            "closure_size": len(known)}


def statement(value):
    args = ", ".join(value["args"])
    text = f"{value['predicate']}({args})"
    return f"not {text}" if value.get("negated", False) else text


def make_episode(seed, split, index, depth, topology, outcome):
    rng = random.Random(f"{VERSION}:{seed}:{split}:{index}")
    rid = lambda prefix: prefix + rng.randbytes(4).hex()
    task_id = rid("episode-")
    domain = rng.choice(("person", "device", "specimen"))
    names = rng.sample(["ada", "bela", "cyra", "dion", "evan", "fara", "gael", "hana"], 4)
    subject, helper, decoy, other = names
    entities = {n: domain for n in names}
    entities["wrong_sort"] = "other_type"
    target = rid("target_")
    predicates = {target: [domain]}
    facts, receipts, rules = [], {}, []

    def add_fact(value, verdict="confirmed", evidence=None):
        fid = rid("f-")
        evidence = evidence or rid("e-")
        facts.append({"id": fid, "text": statement(value)})
        receipts[fid] = {"atom": value, "verdict": verdict, "evidence_id": evidence,
                         "provenance": [rid("world-source-")]}
        return fid

    # Both polarities always have equally long derivations. Every world has
    # exactly two unavailable gates, balanced across subject/decoy bindings.
    # Counting negatives, unknown facts, or inspecting a distinguished root
    # cannot identify the answer. The blocker can be anywhere in either path.
    for negative in (False, True):
        stages = [rid("state_") for _ in range(depth)] + [target]
        predicates.update({name: [domain] for name in stages})
        roots = [add_fact(atom(stages[0], entity)) for entity in (subject, decoy)]
        active = (outcome == "refuted") if negative else (outcome == "entailed")
        blocked_entity = decoy if active else subject
        blocked_position = rng.randrange(depth)
        for position in range(depth):
            body = [atom(stages[position], "?x")]
            variables = {"x": domain}
            if position == blocked_position:
                gate = rid("permit_")
                predicates[gate] = [domain]
                body.append(atom(gate, "?x"))
                for entity in (subject, decoy):
                    add_fact(atom(gate, entity), "unknown" if entity == blocked_entity else "confirmed")
                # Balance unavailable evidence per entity with a dead-end rule.
                # A classifier must establish query relevance before using the
                # gate statuses; total/per-entity missing counts are identical.
                detached, sink = rid("permit_"), rid("state_")
                predicates[detached] = predicates[sink] = [domain]
                for entity in (subject, decoy):
                    add_fact(atom(detached, entity), "confirmed" if entity == blocked_entity else "unknown")
                rules.append({"id": rid("r-"), "var_types": {"x": domain},
                              "body": [atom(detached, "?x")], "head": atom(sink, "?x")})
            if topology in ("branch", "relational", "alternate") and position % 3 == 1:
                gate = rid("gate_")
                predicates[gate] = [domain]
                if topology == "relational":
                    relation = rid("rel_")
                    predicates[relation] = [domain, domain]
                    variables["y"] = domain
                    body.extend([atom(relation, "?x", "?y"), atom(gate, "?y")])
                    add_fact(atom(relation, subject, helper))
                    add_fact(atom(gate, helper))
                    add_fact(atom(gate, other))
                    add_fact(atom(relation, decoy, other))
                else:
                    body.append(atom(gate, "?x"))
                    for entity in (subject, decoy):
                        add_fact(atom(gate, entity))
            rules.append({"id": rid("r-"), "var_types": variables, "body": body,
                          "head": atom(stages[position + 1], "?x",
                                       negated=negative and position == depth - 1)})
        if topology == "alternate":
            alternative = rid("alt_")
            predicates[alternative] = [domain]
            for entity in (subject, decoy):
                add_fact(atom(alternative, entity))
            rules.append({"id": rid("r-"), "var_types": {"x": domain},
                          "body": [atom(alternative, "?x")], "head": atom(stages[0], "?x")})
        if topology == "cycle":
            cycle_pred = rid("cycle_")
            predicates[cycle_pred] = [domain]
            terminal = atom(target, "?x", negated=negative)
            rules.extend([
                {"id": rid("r-"), "var_types": {"x": domain}, "body": [terminal], "head": atom(cycle_pred, "?x")},
                {"id": rid("r-"), "var_types": {"x": domain}, "body": [atom(cycle_pred, "?x")], "head": terminal},
            ])
        # A repeated observation is an alias, never independent evidence.
        if index % 2 == 0:
            for root in roots:
                duplicate = rid("f-")
                facts.append({"id": duplicate, "text": statement(receipts[root]["atom"])})
                receipts[duplicate] = dict(receipts[root])
    # Mapping insertion order must not expose the subject or chain order.
    rng.shuffle(rules); rng.shuffle(facts)
    entity_items, predicate_items = list(entities.items()), list(predicates.items())
    rng.shuffle(entity_items); rng.shuffle(predicate_items)
    entities, predicates = dict(entity_items), dict(predicate_items)
    task = {"id": task_id, "entities": entities, "predicates": predicates,
            "facts": facts, "rules": rules, "query": atom(target, subject)}
    gold = reference(task, receipts)
    if gold["answer"] != outcome or (outcome != "unknown" and gold["minimum_depth"] != depth):
        raise AssertionError("generator outcome/depth disagrees with independent closure")
    return {"task": task, "receipts": receipts, "gold": gold,
            "metadata": {"split": split, "episode_id": task_id, "depth": depth,
                         "topology": topology, "domain": domain,
                         "task_sha256": fingerprint(task)}}


def suite(seed="2026-09-15-frozen-v1", split="test", count=45):
    # Development contains shorter chains; test compositions introduce longer
    # depth plus multi-variable joins, alternate supports, and unsupported cycles.
    depths = (2, 3) if split == "dev" else (4, 6, 8)
    topologies = ("chain", "branch") if split == "dev" else ("chain", "branch", "relational", "alternate", "cycle")
    # A 15-episode test pilot already spans every topology, answer, and depth;
    # the full 45 enumerates every topology/answer/depth combination once.
    depth_index = lambda i: ((i // 3 + i % 3) % 3 if split == "test"
                             else (i // (3 * len(topologies))) % len(depths))
    episodes = [make_episode(seed, split, i, depths[depth_index(i)],
                             topologies[(i // 3) % len(topologies)], ("entailed", "refuted", "unknown")[i % 3])
                for i in range(count)]
    return {"schema": VERSION, "seed": seed, "split": split, "episodes": episodes,
            "manifest_sha256": fingerprint([e["metadata"] for e in episodes])}


def public_task(episode):
    task, receipts = episode["task"], episode["receipts"]
    return {"id": task["id"], "entities": task["entities"], "predicates": task["predicates"],
            "facts": [{**f, "verification": receipts[f["id"]]["verdict"]} for f in task["facts"]],
            "rules": [{"id": r["id"], "variables": r["var_types"],
                       "statement": "If " + " and ".join(statement(a) for a in r["body"]) + " then " + statement(r["head"])}
                      for r in task["rules"]],
            "question": "Is " + statement(task["query"]) + " entailed, explicitly refuted, or unknown?"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--split", choices=("dev", "test"), default="test")
    parser.add_argument("--seed", default="2026-09-15-frozen-v1")
    parser.add_argument("--count", type=int, default=45)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    data = suite(args.seed, args.split, args.count)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, indent=2))
    print(json.dumps({"episodes": len(data["episodes"]), "split": args.split,
                      "manifest_sha256": data["manifest_sha256"]}))


if __name__ == "__main__":
    main()
