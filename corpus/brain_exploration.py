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
from mechanism_spec import assess as assess_mechanism, causal_premise

SCHEMA = "nl2proof.exploratory-composition.v1"
DESIGN_VERSION = "explicit-mechanism-or-retrieval.v2"
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
                      "status": "proposed_unknown", "relation": "retrieval_association",
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


def design_hash(version, links, tests, conditional_question, mechanism_spec=None):
    """Hash design semantics, excluding generated IDs and retrieval similarity."""
    semantics = {"version": version,
                    "mechanism_links": [{k: v for k, v in link.items() if k not in ("id", "similarity")} for link in links],
                    "tests": [{k: v for k, v in test.items() if k not in ("id", "link_id")} for test in tests],
                    "conditional_question": conditional_question}
    if mechanism_spec is not None:
        semantics["mechanism_spec"] = mechanism_spec
    return _digest(semantics)


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
    if "mechanism_spec" in value:
        normalized["mechanism_spec"] = json.loads(json.dumps(value["mechanism_spec"], allow_nan=False))
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


def compose_discovery(brain, *, goal, k=5, as_of=None, max_hops=3, data_inventory=None):
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
    if k == 0:
        return []
    words = _words(goal["question"])
    relevant = {i: len(words & _words(m["text"])) / max(1, len(words)) for i, m in enumerate(meta)}
    eligible = {i for i, m in enumerate(meta) if causal_premise(m)}
    context = [i for i, cid in enumerate(ids) if cid in goal["claim_refs"] and i not in eligible]
    anchors = ([i for i, cid in enumerate(ids) if cid in goal["claim_refs"] and i in eligible] if goal["claim_refs"]
               else [i for i in eligible if relevant[i] > 0])
    anchors.sort(key=lambda i: (-relevant[i], ids[i]))
    nominations, seen = [], set()
    # Bound nomination independently of corpus size; at most two continuations
    # per anchor, with no score-based truth threshold or parameter search.
    for anchor in anchors[:max(k * 2, 1)]:
        def neighbors(index, excluded):
            candidates = []
            for j in range(len(ids)):
                if j in excluded or j not in eligible:
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
            nominations.append((chain, similarities))
    explicit_spec = goal.get("mechanism_spec")
    if explicit_spec is not None:
        # Explicit designs produce one hypothesis. Retrieval never supplies or
        # reorders its variables, signed edges, estimand or private conditions.
        nominations = [([i for i in anchors if ids[i] in goal["claim_refs"]], [])]
    elif not nominations and context:
        nominations = [([], [])]
    proposals = []
    for chain, similarities in nominations:
        anchor = chain[0] if chain else None
        order = tuple(ids[i] for i in chain + context)
        premises = [_premise(meta[i], scores[i]) for i in chain + context]
        causal_premises = [_premise(meta[i], scores[i]) for i in chain]
        goal_context = {key: goal[key] for key in ("id", "question", "context_refs") if key in goal}
        condition = goal["condition_scope"]["description"]
        assessment = assess_mechanism(explicit_spec, premises=premises,
                                     context_refs=goal.get("context_refs", []), data_inventory=data_inventory)
        links, tests, conditional_question = _design(causal_premises, condition, similarities)
        if explicit_spec is not None and isinstance(explicit_spec, dict):
            raw_links = explicit_spec.get("links", [])
            raw_tests = explicit_spec.get("contrasts", [])
            links = [{**link, "spec_link_id": link.get("id"), "status": "proposed_unknown", "causal_evidence": False}
                     for link in raw_links if isinstance(link, dict)] if isinstance(raw_links, list) else []
            # Completeness and data availability stay in the context-only
            # assessment. Stable design slots never imply executed tests.
            tests = [{**test, "key": "contrast:" + str(test.get("id")), "status": "specified_untested"}
                     for test in raw_tests if isinstance(test, dict)] if isinstance(raw_tests, list) else []
            conditional_question = explicit_spec.get("question", goal["question"])
        design_protocol = {"version": DESIGN_VERSION,
                           "sha256": design_hash(DESIGN_VERSION, links, tests, conditional_question, explicit_spec)}
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
        priority = round((sum(max(0., sim) for sim in similarities) / max(1, len(similarities))
                          + (relevant[anchor] if anchor is not None else 0)) / 2, 6)
        proposal = {"schema": SCHEMA, "id": pid, "kind": "explore_mechanism", "status": "proposed",
                    "discovery_only": True, "checked": False, "verdict": "unknown",
                    "claim_refs": list(order), "claim_refs_role": "attribution_only",
                    "goal": goal_context,
                    "condition_scope": goal["condition_scope"], "premises": premises,
                    "composition_role": "explicit_mechanism_design" if explicit_spec is not None else "retrieval_design_candidate",
                    "mechanism_spec": explicit_spec, "mechanism_assessment": assessment,
                    "mechanism_ready": assessment["mechanism_design_complete"] and bool(assessment["contrasts"]) and all(c["runnable"] for c in assessment["contrasts"]),
                    "design_gaps": assessment["design_gaps"],
                    "causal_premise_refs": [p["claim_id"] for p in causal_premises],
                    "evidence_context_refs": [ids[i] for i in context],
                    "mechanism_links": links, "discriminating_tests": tests,
                    "design_protocol": design_protocol, "context_hash_schema": CONTEXT_HASH_SCHEMA,
                    "conditional_hypothesis": {"status": "proposed_unknown",
                        "scope": goal["condition_scope"],
                        "question": conditional_question,
                        "unconditional_claims_asserted": [],
                        "counterevidence_refs": [p["claim_id"] for p in premises if p["check_verdict"] == "refuted"]},
                    "question": conditional_question if explicit_spec is not None else f"Which explicit variables and measurements, if any, could turn these retrieved source claims into a testable design under '{condition}'?",
                    "rationale": "An explicit untested design was supplied; each causal assertion remains unestablished." if explicit_spec is not None else "Semantic adjacency retrieved source context; it supplies no participant mechanism or operational test.",
                    "refuted_premise_policy": "Retain as counterevidence; a conditional alternative must be tested separately and never reinstates the refuted unconditional proposition.",
                    "priority": priority, "priority_basis": "explicit_design_not_probability" if explicit_spec is not None else "semantic_nomination_not_probability",
                    "relevance": {"basis": "explicit_anchor" if goal["claim_refs"] else "goal_token_overlap",
                                  "anchor_claim": ids[anchor] if anchor is not None else None,
                                  "matched_goal_terms": sorted(words & _words(meta[anchor]["text"])) if anchor is not None else []},
                    "as_of": as_of, "historically_preregistered": False,
                    "n_checked_premises": sum(p["checked"] for p in premises)}
        proposal["context_sha256"] = _digest(proposal)
        proposals.append(proposal)
    return sorted(proposals, key=lambda p: (-p["priority"], p["id"]))[:k]
