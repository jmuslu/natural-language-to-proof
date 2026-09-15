"""Assess explicit mechanism designs without inferring facts or running tests.

Actors name context entities. Signed links connect variables, not actor names.
Descriptions and source references are proposed design assumptions, not evidence.
Data inventory is a separate, caller-observed snapshot: changing availability
must not change the semantic specification identity. This checks declared design
completeness and inventory compatibility; it does not validate estimator code,
identify a causal effect, authorize execution, or certify the inventory itself.
"""
from __future__ import annotations

import hashlib
import json
import math
from datetime import datetime, timezone

SCHEMA = "nl2proof.mechanism-spec.v1"
ASSESSMENT_SCHEMA = "nl2proof.mechanism-assessment.v1"
MAX_BYTES = 131072
ROLES = {"constraint", "incentive", "action", "flow", "outcome", "state"}
BAR_CONSTRUCTS = {"open_price", "high_price", "low_price", "close_price", "trade_volume", "price", "price_return", "bar_range", "ohlcv_condition"}
BAR_SCOPE = {"instrument", "interval_seconds", "timestamp_semantics", "timezone", "price_basis", "contract_basis", "publication_delay_seconds", "coverage_start", "coverage_end"}


def fingerprint(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":"),
                                     ensure_ascii=False, allow_nan=False).encode()).hexdigest()


def causal_premise(premise):
    """Administrative receipts and biography cannot supply mechanism variables."""
    provenance = premise.get("provenance", premise)
    return (provenance.get("claim_type") not in ("run_validation", "biographical")
            and premise.get("domain") != "biographical"
            and not str(premise.get("claim_id", premise.get("id", ""))).startswith("validation:"))


def assess(spec, *, premises=(), context_refs=(), data_inventory=None):
    """Return stable design gaps and per-contrast readiness, never a truth label.

    ``data_inventory`` maps each named data_ref to status available/missing/
    unverified, observed fields, data_kind and scope. Self-declared availability inside
    a specification is not accepted. OHLCV cannot identify participant class,
    position changes, forced closing, or aggressor direction by relabeling bars.
    """
    gaps, contrasts = [], []

    def gap(code, path, message, blocks="design"):
        entry = {"code": code, "path": path, "message": message, "blocks": blocks}
        if entry not in gaps:
            gaps.append(entry)

    result = {"schema": ASSESSMENT_SCHEMA, "spec_sha256": None, "checked": False,
              "verdict": "unknown", "mechanism_identified": False,
              "mechanism_design_complete": False, "execution_requested": False,
              "historical_eligibility_established": False, "independence_established": False,
              "contrasts": contrasts, "design_gaps": gaps, "runnable_contrasts": [],
              "testable_edges": [], "latent_edges": [],
              "data_authority": "separately supplied observed inventory; not authenticated by this assessor"}
    if spec is None:
        gap("missing_mechanism_spec", "spec", "Similarity links are retrieval candidates. Supply explicit variables, measurements and contrasts.")
        result["status"] = "design_incomplete"
        return result
    try:
        encoded = json.dumps(spec, allow_nan=False).encode()
        if len(encoded) > MAX_BYTES or not isinstance(spec, dict):
            raise ValueError("bounded object required")
        result["spec_sha256"] = fingerprint(spec)
    except (ValueError, TypeError, OverflowError):
        gap("malformed_spec", "spec", "Supply a finite JSON object of at most 128 KiB.")
        result["status"] = "design_incomplete"
        return result

    def text(value):
        return isinstance(value, str) and bool(value.strip()) and len(value) <= 4096

    def number(value):
        return type(value) in (int, float) and math.isfinite(value) and abs(value) <= 1e9

    def timestamp(value):
        if not isinstance(value, str):
            return None
        try:
            parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
            if len(value) == 10:
                parsed = parsed.replace(tzinfo=timezone.utc)
            return parsed if parsed.tzinfo is not None else None
        except ValueError:
            return None

    def fields(record, required, optional, path):
        if not isinstance(record, dict):
            gap("malformed_record", path, "A JSON object is required.")
            return False
        missing = set(required) - set(record)
        extra = set(record) - set(required) - set(optional)
        for name in sorted(missing):
            gap("missing_field", path + "." + name, "A declared design field is missing.")
        for name in sorted(extra):
            gap("unexpected_field", path + "." + name, "Unknown fields cannot supply evidence or readiness.")
        return not missing and not extra

    def records(name, cap):
        value = spec.get(name)
        if not isinstance(value, list) or len(value) > cap:
            gap("malformed_collection", name, f"Expected a list with at most {cap} records.")
            return {}
        out = {}
        for i, item in enumerate(value):
            if not isinstance(item, dict) or not text(item.get("id")) or len(item["id"]) > 128:
                gap("invalid_id", f"{name}[{i}]", "A short nonempty record ID is required.")
            elif item["id"] in out:
                gap("duplicate_id", f"{name}[{i}]", "Record IDs must be unique within their collection.")
            else:
                out[item["id"]] = item
        return out

    fields(spec, ("schema", "id", "question", "actors", "variables", "observables", "links", "contrasts"), (), "spec")
    if spec.get("schema") != SCHEMA:
        gap("unsupported_schema", "schema", "Use the explicit mechanism specification version.")
    for key in ("id", "question"):
        if not text(spec.get(key)):
            gap("missing_description", key, "A nonempty design description is required.")
    actors, variables = records("actors", 16), records("variables", 32)
    observables, links = records("observables", 64), records("links", 64)
    proposed_contrasts = records("contrasts", 16)
    sources = {p.get("claim_id", p.get("id")): p for p in premises if isinstance(p, dict)
               and text(p.get("claim_id", p.get("id")))}
    artifacts = {r.get("artifact") for r in context_refs if isinstance(r, dict) and text(r.get("artifact"))}
    allowed = set(sources) | artifacts
    inventory = data_inventory if isinstance(data_inventory, dict) else {}
    try:
        result["data_inventory_sha256"] = fingerprint(inventory)
    except (ValueError, TypeError, OverflowError):
        inventory = {}
        result["data_inventory_sha256"] = None
        gap("malformed_inventory", "data_inventory", "Observed inventory must be finite JSON metadata.", "execution")

    def refs(value, path):
        if not isinstance(value, list) or not value or any(not text(r) for r in value):
            gap("missing_attribution", path, "Name source claims or explicitly supplied research artifacts.")
            return
        if len(set(value)) != len(value):
            gap("duplicate_attribution", path, "Attribution IDs must be unique.")
        for ref in value:
            if ref not in allowed:
                gap("unknown_attribution", path, "A source reference is absent from the supplied context.")
            elif ref in sources and not causal_premise(sources[ref]):
                gap("artifact_as_causal_source", path, "Run validation and biography belong in context, not mechanism variables or causal links.")

    for aid, actor in actors.items():
        path = "actors." + aid
        fields(actor, ("id", "role", "source_refs"), (), path)
        if not text(actor.get("role")):
            gap("missing_actor_role", path, "Describe the participant role without asserting an observed identity.")
        refs(actor.get("source_refs"), path + ".source_refs")
    if not actors:
        gap("missing_actor_context", "actors", "A participant mechanism needs explicit actor context.")

    variable_design = {}
    for vid, variable in variables.items():
        path, start = "variables." + vid, len(gaps)
        fields(variable, ("id", "role", "description", "construct", "actor_refs", "observable_ref", "source_refs"), (), path)
        if not isinstance(variable.get("role"), str) or variable["role"] not in ROLES or not text(variable.get("description")) or not text(variable.get("construct")):
            gap("invalid_variable", path, "Declare a variable role, construct and description.")
        ids = variable.get("actor_refs")
        if not isinstance(ids, list) or any(not isinstance(i, str) or i not in actors for i in ids):
            gap("unknown_actor", path + ".actor_refs", "Actor references must name context entities.")
        refs(variable.get("source_refs"), path + ".source_refs")
        variable_design[vid] = not gaps[start:]
    roles = {v.get("role") for v in variables.values() if isinstance(v.get("role"), str)}
    if not roles & {"constraint", "incentive"} or not roles & {"action", "flow"} or "outcome" not in roles:
        gap("missing_mechanism_roles", "variables", "A full mechanism needs constraint/incentive, action/flow and outcome variables.")

    measurement = {}
    for oid, observation in observables.items():
        path = "observables." + oid
        start = len(gaps)
        fields(observation, ("id", "kind", "data_kind", "data_ref", "data_scope", "required_fields", "measurement", "units", "available_after_seconds"), (), path)
        if observation.get("kind") not in ("direct", "proxy", "latent"):
            gap("invalid_measurement_kind", path, "Measurements must be direct, proxy or latent.")
        for key in ("data_kind", "data_ref", "measurement", "units"):
            if not text(observation.get(key)):
                gap("missing_measurement", path + "." + key, "Declare the observable mapping and units.")
        delay = observation.get("available_after_seconds")
        if not number(delay) or delay < 0:
            gap("invalid_availability_delay", path, "Declare a finite nonnegative observation delay.")
        required = observation.get("required_fields")
        if not isinstance(required, list) or not required or any(not text(k) for k in required):
            gap("missing_data_fields", path, "Declare actual required columns or event fields.")
            required = []
        scope = observation.get("data_scope")
        if (not isinstance(scope, dict) or not scope
                or any(not text(k) or not (text(v) or number(v)) for k, v in scope.items())):
            gap("missing_data_scope", path, "Declare dataset identity, resolution, clock and coverage requirements.")
            scope = {}
        if observation.get("data_kind") == "ohlcv" and not BAR_SCOPE <= set(scope):
            gap("incomplete_bar_scope", path, "OHLCV requires instrument, interval, clock/timezone, price and contract/roll basis, publication delay and coverage.")
        if "interval_seconds" in scope and (not number(scope["interval_seconds"]) or scope["interval_seconds"] <= 0):
            gap("invalid_bar_interval", path, "The bar interval must be a positive number of seconds.")
        publication_delay = scope.get("publication_delay_seconds")
        if "publication_delay_seconds" in scope and (not number(publication_delay) or publication_delay < 0
                or not number(delay) or delay < publication_delay):
            gap("understated_observation_delay", path, "Observable availability cannot precede the declared data publication delay.")
        if (observation.get("data_kind") == "ohlcv" and scope.get("timestamp_semantics") == "bar_open"
                and number(scope.get("interval_seconds")) and number(publication_delay) and number(delay)
                and delay < scope["interval_seconds"] + publication_delay):
            gap("understated_observation_delay", path, "A complete bar stamped at its open is unavailable until its duration and publication delay have elapsed.")
        if "coverage_start" in scope or "coverage_end" in scope:
            first, last = timestamp(scope.get("coverage_start")), timestamp(scope.get("coverage_end"))
            if first is None or last is None or first > last:
                gap("invalid_requested_coverage", path, "Declare ordered ISO dates or timezone-aware timestamps.")
        design_ok = not gaps[start:]
        record = inventory.get(observation.get("data_ref"), {}) if isinstance(observation.get("data_ref"), str) else {}
        if not isinstance(record, dict):
            record = {}
        available = isinstance(record, dict) and record.get("status") == "available"
        observed_fields = record.get("fields", []) if isinstance(record, dict) else []
        available = available and isinstance(observed_fields, list) and all(k in observed_fields for k in required)
        observed_scope = record.get("scope", {}) if isinstance(record, dict) else {}
        scope_matches = isinstance(observed_scope, dict) and record.get("data_kind") == observation.get("data_kind")
        if not isinstance(observed_scope, dict):
            observed_scope = {}
        for key, value in scope.items():
            if key in ("coverage_start", "coverage_end"):
                actual, wanted = timestamp(observed_scope.get(key)), timestamp(value)
                scope_matches = scope_matches and actual is not None and wanted is not None
                if actual is not None and wanted is not None:
                    scope_matches = scope_matches and (actual <= wanted if key == "coverage_start" else actual >= wanted)
            else:
                scope_matches = scope_matches and observed_scope.get(key) == value
        if not scope_matches:
            available = False
            gap("data_scope_unverified", path, "Inventory does not establish the requested data kind, instrument, bar clock, price basis or coverage.", "execution")
        if not available:
            gap("data_unavailable", path, "Required observations are not available in the separately supplied inventory.", "execution")
        if observation.get("data_kind") == "ohlcv":
            if record.get("historical_availability_status") != "observed_receipt":
                gap("historical_availability_unverified", path, "Byte validity and current availability do not establish when the data was historically knowable.", "historical_use")
            if record.get("lineage_status") != "known_reuse":
                gap("independence_unestablished", path, "Different or untraced files do not establish independent evidence.", "independence")
            else:
                gap("known_data_reuse", path, "This inventory names reused observations, not an independent sample.", "independence")
        measurement[oid] = {"design": design_ok, "data": available}

    observable_for, identified = {}, {}
    for vid, variable in variables.items():
        path = "variables." + vid
        oid = variable.get("observable_ref")
        obs = observables.get(oid) if isinstance(oid, str) else None
        observable_for[vid] = oid if isinstance(oid, str) else None
        identified[vid] = bool(variable_design[vid] and obs and obs.get("kind") == "direct" and measurement[oid]["design"])
        if obs is None:
            gap("unobserved_variable", path, "This variable has no declared observable mapping.", "identification")
        elif obs.get("kind") in ("latent", "proxy"):
            gap("latent_or_proxy_construct", path, "A proxy is not an identified participant construct; supply a direct measurement or an independent measurement validation.", "identification")
        if obs and obs.get("data_kind") == "ohlcv" and (variable.get("construct") not in BAR_CONSTRUCTS
                if isinstance(variable.get("construct"), str) else True):
            identified[vid] = False
            gap("bars_do_not_identify_participants", path, "Only explicitly named bar-observable constructs can be measured directly from OHLCV; other constructs remain latent.", "identification")
        if obs and obs.get("data_kind") == "ohlcv" and (variable.get("actor_refs") or variable.get("role") not in ("state", "outcome")):
            identified[vid] = False
            gap("bars_do_not_identify_participants", path, "OHLCV does not identify actor-specific constraints, actions or flow; use an observed state/outcome without participant attribution.", "identification")

    edges = {}
    for lid, link in links.items():
        path, start = "links." + lid, len(gaps)
        fields(link, ("id", "from", "to", "sign", "lag_seconds", "rationale", "source_refs"), (), path)
        source, target = link.get("from"), link.get("to")
        if not isinstance(source, str) or not isinstance(target, str) or source not in variables or target not in variables or source == target:
            gap("invalid_link_variables", path, "Links must connect two distinct variables, not actor or artifact IDs.")
        if link.get("sign") not in ("increase", "decrease", "nonmonotone") or not text(link.get("rationale")):
            gap("missing_link_mechanism", path, "Declare a direction and a specific proposed transmission mechanism.")
        lag = link.get("lag_seconds")
        if not isinstance(lag, list) or len(lag) != 2 or any(not number(n) for n in lag) or lag[0] < 0 or lag[1] <= lag[0]:
            gap("invalid_causal_order", path, "Declare nonnegative ordered lag bounds with positive width.")
        refs(link.get("source_refs"), path + ".source_refs")
        design_ok = not gaps[start:]
        edges[lid] = {"design": design_ok, "identified": bool(design_ok and identified.get(source, False) and identified.get(target, False))}
        if not edges[lid]["identified"]:
            result["latent_edges"].append(lid)

    # A full mechanism needs a directed constraint/incentive -> action/flow ->
    # outcome path. Cycles are allowed as hypotheses; reachability is bounded.
    adjacency = {v: [] for v in variables}
    for lid, link in links.items():
        if edges[lid]["design"]:
            adjacency[link["from"]].append(link["to"])
    def reaches(start, targets):
        pending, seen = [start], set()
        while pending:
            node = pending.pop()
            if node in seen:
                continue
            seen.add(node)
            if node in targets and node != start:
                return True
            pending.extend(adjacency[node])
        return False
    starts = [v for v in variables if variables[v].get("role") in ("constraint", "incentive")]
    flows = [v for v in variables if variables[v].get("role") in ("action", "flow")]
    outcomes = {v for v in variables if variables[v].get("role") == "outcome"}
    if not any(reaches(a, {b}) and reaches(b, outcomes) for a in starts for b in flows):
        gap("disconnected_mechanism", "links", "No directed constraint/incentive through action/flow to outcome path is declared.")

    if not proposed_contrasts:
        gap("missing_contrast", "contrasts", "Declare at least one measurable comparison.")
    structural_codes = {"malformed_record", "malformed_collection", "invalid_id", "duplicate_id", "unexpected_field", "unsupported_schema"}
    global_schema_gaps = [g for g in gaps if g["code"] in structural_codes or
                         (g["blocks"] == "design" and g["path"].startswith(("spec", "schema", "observables")))]
    for cid, contrast in proposed_contrasts.items():
        path, start = "contrasts." + cid, len(gaps)
        fields(contrast, ("id", "edge_refs", "kind", "exposure_variable", "exposure", "control", "outcome_variable", "estimand", "margin", "margin_units", "condition", "decision_time", "exposure_window_seconds", "outcome_window_seconds", "assumptions"), (), path)
        for key in ("exposure", "control", "estimand", "margin_units", "condition", "decision_time"):
            if not text(contrast.get(key)):
                gap("incomplete_contrast", path + "." + key, "Specify the measurable comparison before outcomes.")
        if contrast.get("kind") not in ("conditional_association", "intervention"):
            gap("invalid_contrast_kind", path, "Separate observational conditional association from an intervention.")
        if not number(contrast.get("margin")) or contrast["margin"] < 0:
            gap("invalid_effect_margin", path, "Declare a finite nonnegative effect margin with units.")
        assumptions = contrast.get("assumptions")
        if not isinstance(assumptions, list) or not assumptions or any(not text(v) for v in assumptions):
            gap("missing_identification_assumptions", path, "Declare confounding/measurement assumptions and limitations.")
        eids = contrast.get("edge_refs")
        if not isinstance(eids, list) or not eids or any(not isinstance(e, str) or e not in links for e in eids):
            gap("unknown_contrast_edge", path, "Name existing proposed variable links.")
            eids = []
        if len(eids) != len(set(eids)):
            gap("duplicate_contrast_edge", path, "Each tested edge must be named once.")
        used = {v for e in eids if edges[e]["design"] for v in (links[e]["from"], links[e]["to"])}
        if not eids or any(not edges[e]["design"] for e in eids):
            gap("incomplete_tested_link", path, "Every tested edge needs signed, timed variable definitions.")
        exposure = contrast.get("exposure_variable")
        outcome = contrast.get("outcome_variable")
        if not isinstance(outcome, str) or outcome not in used:
            gap("unknown_contrast_outcome", path, "The measured outcome must occur in the tested links.")
        if not isinstance(exposure, str) or exposure not in used or exposure == outcome:
            gap("unknown_contrast_exposure", path, "Name a distinct exposure variable at the start of the tested causal path.")
        selected = {v: [] for v in used}
        reverse = {v: [] for v in used}
        for e in eids:
            if edges[e]["design"]:
                a, b = links[e]["from"], links[e]["to"]
                selected[a].append((b, e)); reverse[b].append(a)
        def closure(start_node, graph):
            pending, seen = [start_node], set()
            while pending:
                node = pending.pop()
                if not isinstance(node, str) or node in seen:
                    continue
                seen.add(node)
                pending.extend(graph.get(node, []))
            return seen
        reachable = closure(exposure, {v: [b for b, _ in selected[v]] for v in used})
        ancestors = closure(outcome, reverse)
        if not isinstance(outcome, str) or outcome not in reachable or any(a not in reachable or b not in ancestors for a in selected for b, _ in selected[a]):
            gap("incoherent_contrast_path", path, "Every tested edge must lie on a directed path from exposure to the declared measured outcome.")
        indegree = {v: len(reverse[v]) for v in used}
        pending = sorted(v for v in used if not indegree[v])
        distances = {exposure: (0, 0)} if isinstance(exposure, str) else {}
        processed = 0
        while pending:
            node = pending.pop(); processed += 1
            for target, e in selected[node]:
                if node in distances:
                    low, high = distances[node]
                    candidate = (low + links[e]["lag_seconds"][0], high + links[e]["lag_seconds"][1])
                    previous = distances.get(target, candidate)
                    distances[target] = (min(previous[0], candidate[0]), max(previous[1], candidate[1]))
                indegree[target] -= 1
                if not indegree[target]:
                    pending.append(target)
        if processed != len(used):
            gap("cyclic_contrast_scope", path, "Select a temporally unrolled acyclic path for this contrast; a feedback cycle cannot supply an unspecified horizon.")
        exposure_window = contrast.get("exposure_window_seconds")
        exposure_valid = (isinstance(exposure_window, list) and len(exposure_window) == 2
                          and all(number(v) for v in exposure_window)
                          and exposure_window[0] < exposure_window[1] <= 0)
        if not exposure_valid:
            gap("invalid_exposure_window", path, "Declare a nonempty exposure interval ending at or before the decision.")
        window = contrast.get("outcome_window_seconds")
        window_valid = isinstance(window, list) and len(window) == 2 and all(number(v) for v in window) and 0 < window[0] < window[1]
        if not window_valid:
            gap("invalid_outcome_window", path, "Declare a strictly future outcome interval after the decision.")
        if window_valid and exposure_valid and isinstance(outcome, str) and outcome in distances:
            low, high = distances[outcome]
            if window[0] < exposure_window[1] + low or window[1] > exposure_window[1] + high:
                gap("contrast_lag_mismatch", path, "The outcome window is incompatible with the cumulative declared causal lags from the exposure.")
        if exposure_valid:
            source_obs = observables.get(observable_for.get(exposure), {}) if isinstance(exposure, str) else {}
            delay = source_obs.get("available_after_seconds")
            if number(delay) and exposure_window[1] + delay > 0:
                gap("observation_after_decision", path, "The exposure observation arrives after the declared decision.")
        for variable, interval, valid in ((exposure, exposure_window, exposure_valid), (outcome, window, window_valid)):
            observation = observables.get(observable_for.get(variable), {}) if isinstance(variable, str) else {}
            bar_seconds = observation.get("data_scope", {}).get("interval_seconds") if isinstance(observation.get("data_scope"), dict) else None
            if valid and observation.get("data_kind") == "ohlcv" and number(bar_seconds) and bar_seconds > 0:
                if any(not math.isclose(value / bar_seconds, round(value / bar_seconds), abs_tol=1e-9) for value in interval):
                    gap("bar_resolution_mismatch", path, "The declared windows require sub-bar observations or undeclared alignment; use explicit bar-aligned endpoints.")
        if any(not identified.get(v, False) for v in used):
            gap("unidentified_contrast_variable", path, "This contrast cannot identify the named construct using its declared measurement.")
        design_complete = not gaps[start:] and not global_schema_gaps
        data_ready = bool(used) and all(measurement.get(observable_for[v], {}).get("data", False) for v in used)
        entry = {"id": cid, "design_complete": design_complete, "data_ready": data_ready,
                 "runnable": design_complete and data_ready,
                 "interpretation": "conditional association does not establish participant mechanism" if contrast.get("kind") == "conditional_association" else "intervention effect under declared assumptions; untested",
                 "edge_refs": eids, "gap_codes": sorted({g["code"] for g in gaps[start:]})}
        contrasts.append(entry)
        if design_complete:
            result["testable_edges"].extend(e for e in eids if e not in result["testable_edges"])
        if entry["runnable"]:
            result["runnable_contrasts"].append(cid)
    for lid in links:
        if not any(c["design_complete"] and lid in c["edge_refs"] for c in contrasts):
            gap("missing_link_contrast", "links." + lid, "This proposed mechanism edge has no fully specified identifying contrast.")
    result["mechanism_design_complete"] = bool(links) and not any(g["blocks"] in ("design", "identification") for g in gaps)
    result["status"] = ("declared_contrasts_runnable" if result["runnable_contrasts"] else
                        "specified_contrasts_data_missing" if any(c["design_complete"] for c in contrasts)
                        else "design_incomplete")
    return result
