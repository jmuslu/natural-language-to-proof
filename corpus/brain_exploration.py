"""Opt-in mechanism discovery from uncertain premises; never an evidence writer.

Semantic adjacency nominates a chain to investigate. It supplies neither a causal
edge nor a checked conclusion. A condition is a stipulated research scope, not a
fact inferred from a failed unconditional claim. All measurements and contrasts
must be operationalized before testing; no experiment or model is called here.
"""
from __future__ import annotations

import hashlib
import json
import math
import re

from oracle_bridge import cutoff

SCHEMA = "nl2proof.exploratory-composition.v1"
DESIGN_VERSION = "conditional-link-tests.v1"
CONTEXT_HASH_SCHEMA = "nl2proof.proposal-context.v1"


def _digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":"),
                                     ensure_ascii=False, allow_nan=False).encode()).hexdigest()


def _words(text):
    return set(re.findall(r"[a-z0-9]{3,}", text.lower())) - {
        "the", "and", "for", "with", "that", "this", "does", "what", "which", "how",
        "are", "can", "from", "under", "within", "before", "after", "outcome", "observation",
        "mechanism", "links", "missing", "explain", "conditional", "proposed", "test", "tests"}


def _design(premises, condition, similarities):
    links, tests = [], []
    for index, (a, b, sim) in enumerate(zip(premises, premises[1:], similarities)):
        links.append({"from_claim": a["claim_id"], "to_claim": b["claim_id"],
                      "status": "proposed_unknown", "relation": "missing_mechanism_link",
                      "similarity": round(sim, 6), "causal_evidence": False})
        tests.append({"key": f"link:{index}:ablation", "kind": "link_ablation", "link_index": index,
                      "status": "design_required",
                      "question": f"Under '{condition}', does the observable assigned to {a['claim_id']} change the later observable assigned to {b['claim_id']}?",
                      "contrast": {"candidate": "link active within the stipulated condition",
                                   "control": "matched link ablation with the same context and timing"},
                      "discriminates": ["conditional mechanism", "shared context without this link"],
                      "required_design": ["observable mapping", "effect estimand and tolerated margin",
                                          "confounding assumptions or intervention", "decision before outcome timing"]})
    tests.extend([
        {"key": "interaction", "kind": "conditional_interaction", "status": "design_required",
         "question": "Does the proposed chain change the outcome within the stipulated condition compared with a matched condition-off control?",
         "contrast": {"candidate": "joint chain within condition", "control": "condition-off and each marginal alone"},
         "discriminates": ["conditional interaction", "unconditional marginal or selection artifact"],
         "required_design": ["condition defined before outcomes", "full candidate family", "chronological confirmation"]},
        {"key": "negative-control", "kind": "negative_control", "status": "design_required",
         "question": "Does the result disappear when the proposed causal time order is broken while preserving the relevant exposure distribution?",
         "contrast": {"candidate": "declared causal order", "control": "preregistered time-shift or unrelated outcome"},
         "discriminates": ["ordered mechanism", "common trend or leakage"],
         "required_design": ["control eligibility", "lag and exposure matching", "multiple-comparison rule"]}])
    question = "Does the joint ordered mechanism change the outcome only within this stipulated condition?"
    return links, tests, question


def design_hash(version, links, tests, conditional_question):
    """Hash design semantics, excluding generated IDs and retrieval similarity."""
    return _digest({"version": version,
                    "mechanism_links": [{k: v for k, v in link.items() if k not in ("id", "similarity")} for link in links],
                    "tests": [{k: v for k, v in test.items() if k not in ("id", "link_id")} for test in tests],
                    "conditional_question": conditional_question})


def _goal(value):
    if not isinstance(value, dict):
        raise ValueError("discovery_goal must be an explicit object")
    for key in ("id", "question"):
        if not isinstance(value.get(key), str) or not value[key].strip():
            raise ValueError("discovery_goal requires id and question")
    condition = value.get("condition_scope")
    if not isinstance(condition, dict) or not isinstance(condition.get("description"), str) or not condition["description"].strip():
        raise ValueError("discovery requires an explicit condition_scope description")
    refs = value.get("claim_refs", [])
    if not isinstance(refs, list) or any(not isinstance(r, str) or not r for r in refs) or len(refs) != len(set(refs)):
        raise ValueError("goal claim_refs must be unique string identifiers")
    context = value.get("context_refs", [])
    if (not isinstance(context, list) or any(not isinstance(ref, dict)
            or not isinstance(ref.get("artifact"), str) or not ref["artifact"].strip() for ref in context)):
        raise ValueError("context_refs must name context artifacts")
    normalized = {"id": value["id"], "question": value["question"],
                  "condition_scope": {**json.loads(json.dumps(condition, allow_nan=False)),
                                      "status": "stipulated_not_established", "checked": False},
                  "claim_refs": sorted(refs)}
    if context:
        normalized["context_refs"] = [{"artifact": ref["artifact"], "role": "attribution_only", "checked": False}
                                      for ref in context]
    return normalized


def _premise(meta, score):
    verdict = meta["check_verdict"]
    # These are scoped checker labels already supplied by Brain._all(as_of).
    provenance = {"source_id": meta["source_id"], "claim_type": meta["claim_type"],
                  "evidence_basis": meta["evidence_basis"], "knowable_time": meta["knowable_time"],
                  "event_time": meta["event_time"], "verification_status": meta["verification_status"],
                  "check_source": meta["check_source"], "check_evidence_id": meta["check_evidence_id"],
                  "check_observed_at": meta["check_observed_at"]}
    scope = ({"kind": "passes_validation", "run_id": meta["id"].removeprefix("validation:")}
             if meta["claim_type"] == "run_validation" and meta["id"].startswith("validation:")
             else {"kind": "source_proposition", "claim_id": meta["id"]})
    return {"claim_id": meta["id"], "text": meta["text"], "domain": meta["domain"],
            "checked": meta["checked"], "check_verdict": verdict,
            "check_scope": scope, "provenance": provenance,
            "exploratory_score": float(score),
            "use": "counterevidence" if verdict == "refuted" else "candidate_context",
            "assumed_true": False}


def compose_discovery(brain, *, goal, k=5, as_of=None, max_hops=3):
    """Nominate bounded chains, retaining uncertain and refuted premise context.

    ``goal`` needs id/question/condition_scope.description; optional claim_refs
    selects anchors and fails closed if any are unavailable at the cutoff.
    ``max_hops`` is the number of missing links (1..3). Identity depends on the
    goal, ordered premise propositions and test design, not mutable evidence or
    priority. A separate context hash records that evidence snapshot.
    """
    goal = _goal(goal)
    if type(k) is not int or not 0 <= k <= 100 or type(max_hops) is not int or not 1 <= max_hops <= 3:
        raise ValueError("k must be 0..100 and max_hops 1..3")
    as_of = cutoff(as_of)
    ids, vectors, scores, meta = brain._all(as_of=as_of)
    if not set(goal["claim_refs"]) <= set(ids):
        raise ValueError("a requested discovery premise is unavailable at as_of")
    if len(ids) < 2 or k == 0:
        return []
    words = _words(goal["question"])
    relevant = {i: len(words & _words(m["text"])) / max(1, len(words)) for i, m in enumerate(meta)}
    anchors = ([i for i, cid in enumerate(ids) if cid in goal["claim_refs"]] if goal["claim_refs"]
               else [i for i in range(len(ids)) if relevant[i] > 0])
    anchors.sort(key=lambda i: (-relevant[i], ids[i]))
    proposals, seen = [], set()
    # Bound nomination independently of corpus size; at most two continuations
    # per anchor, with no score-based truth threshold or parameter search.
    for anchor in anchors[:max(k * 2, 1)]:
        def neighbors(index, excluded):
            candidates = []
            for j in range(len(ids)):
                if j in excluded:
                    continue
                similarity = float(vectors[index] @ vectors[j])
                if math.isfinite(similarity) and similarity > 0:
                    candidates.append((j, similarity))
            return sorted(candidates, key=lambda pair: (-pair[1], -relevant[pair[0]], ids[pair[0]]))
        for neighbor, similarity in neighbors(anchor, {anchor})[:2]:
            chain, similarities = [anchor, neighbor], [similarity]
            while len(chain) <= max_hops:
                further = neighbors(chain[-1], set(chain))
                if not further:
                    break
                j, sim = further[0]
                chain.append(j); similarities.append(sim)
            order = tuple(ids[i] for i in chain)
            if order in seen:
                continue
            seen.add(order)
            premises = [_premise(meta[i], scores[i]) for i in chain]
            goal_context = {key: goal[key] for key in ("id", "question", "context_refs") if key in goal}
            condition = goal["condition_scope"]["description"]
            links, tests, conditional_question = _design(premises, condition, similarities)
            design_protocol = {"version": DESIGN_VERSION,
                               "sha256": design_hash(DESIGN_VERSION, links, tests, conditional_question)}
            identity = {"schema": SCHEMA, "goal": goal_context,
                        "condition_scope": goal["condition_scope"],
                        "design_protocol": design_protocol,
                        "premises": [{"claim_id": p["claim_id"], "text": p["text"],
                                      "source_id": p["provenance"]["source_id"],
                                      "claim_type": p["provenance"]["claim_type"]} for p in premises]}
            pid = "discovery:" + _digest(identity)[:32]
            for index, link in enumerate(links):
                link["id"] = f"{pid}:link:{index}"
            for test in tests:
                test["id"] = f"{pid}:{test['key']}"
                if "link_index" in test:
                    test["link_id"] = links[test["link_index"]]["id"]
            priority = round((sum(max(0., sim) for sim in similarities) / len(similarities)
                              + relevant[anchor]) / 2, 6)
            proposal = {"schema": SCHEMA, "id": pid, "kind": "explore_mechanism", "status": "proposed",
                        "discovery_only": True, "checked": False, "verdict": "unknown",
                        "claim_refs": list(order), "claim_refs_role": "attribution_only",
                        "goal": goal_context,
                        "condition_scope": goal["condition_scope"], "premises": premises,
                        "mechanism_links": links, "discriminating_tests": tests,
                        "design_protocol": design_protocol, "context_hash_schema": CONTEXT_HASH_SCHEMA,
                        "conditional_hypothesis": {"status": "proposed_unknown",
                            "scope": goal["condition_scope"],
                            "question": conditional_question,
                            "unconditional_claims_asserted": [],
                            "counterevidence_refs": [p["claim_id"] for p in premises if p["check_verdict"] == "refuted"]},
                        "question": f"Which missing links in the proposed chain { ' -> '.join(order) } survive discriminating tests under '{condition}'?",
                        "rationale": "Semantic adjacency nominated these links; each link and the conditional conclusion remain unestablished.",
                        "refuted_premise_policy": "Retain as counterevidence; a conditional alternative must be tested separately and never reinstates the refuted unconditional proposition.",
                        "priority": priority, "priority_basis": "semantic_nomination_not_probability",
                        "relevance": {"basis": "explicit_anchor" if goal["claim_refs"] else "goal_token_overlap",
                                      "anchor_claim": ids[anchor],
                                      "matched_goal_terms": sorted(words & _words(meta[anchor]["text"]))},
                        "as_of": as_of, "historically_preregistered": False,
                        "n_checked_premises": sum(p["checked"] for p in premises)}
            proposal["context_sha256"] = _digest(proposal)
            proposals.append(proposal)
    return sorted(proposals, key=lambda p: (-p["priority"], p["id"]))[:k]
