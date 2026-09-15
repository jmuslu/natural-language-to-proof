"""Durable paired evaluation of plain proofs and explicit local reasoning tools.

No model calls occur on import or replay. Gold is accessed only by scoring and
dataset integrity checks. Model messages contain public task statements and
local scaffold observations; symbolic search is a separately labeled baseline.
"""
from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import asdict, replace
import json
import math
import os
from pathlib import Path
from uuid import UUID, uuid4

from reasoning import benchmark, run
from reasoning.scaffold import Scaffold, ScaffoldLimits, deterministic_search

SCHEMA = "reasoning.scaffold-run.v2"
INTERRUPTION_SCHEMA = "reasoning.scaffold-interruption.v1"
FATAL_HTTP_STATUSES = (401, 402, 403)
PROMPT_VERSION = "local-applications-v2"
ARMS = ("one_shot", "verified_repair", "scaffold", "deterministic_search")
SYSTEM = """You plan reasoning in a finite typed world using a local rule-application tool.
The tool has admitted only separately confirmed signed facts. It lists currently enabled single-rule applications with exact bindings and all required premises. Unknown/refuted verification does not supply a negative premise. Explicitly negative atoms have negated=true.
Return only one JSON action:
{"select":["candidate ID", ...]} to apply one or more currently listed applications (maximum32), or
{"finish":"entailed"} / {"finish":"refuted"} / {"finish":"unknown"} to stop.
Select applications that establish the queried signed atom or its explicit opposite, considering branches, shared-variable joins, gates and alternative supports. The tool resolves step IDs and verifies the final proof; it does not apply unselected rules. New enabled applications appear after selections. Do not invent IDs or add proof syntax.
Finish entailed only after known contains the exact query; finish refuted only after known contains its explicit opposite. If both have support, abstain unknown. Unknown is abstention, not a proof that no derivation exists. A finite round or work limit can prevent completion. You choose when to finish; the tool will not silently select the answer for you."""


def limits_for(rounds):
    return ScaffoldLimits(action_calls=rounds, view_calls=rounds + 1)


def messages_for(episode, view, feedback=None):
    # Each observation is self-contained. Known atoms and the enabled frontier
    # retain proof state without repeatedly charging for earlier full views.
    content = {"task": benchmark.public_task(episode), "local_tool": view}
    if feedback is not None:
        content["last_action_result"] = feedback
    return [{"role": "system", "content": SYSTEM},
            {"role": "user", "content": json.dumps(content, sort_keys=True)}]


def score_tool(episode, arm, attempts, result, budget, raw_answer, stop_reason):
    gold = episode["gold"]["answer"]  # Evaluation only, after all actions.
    checked = result["check"]
    return {"episode_id": episode["task"]["id"], "metadata": episode["metadata"], "arm": arm,
            "gold_answer": gold, "raw_answer": raw_answer, "answer": checked["answer"],
            "raw_correct": raw_answer == gold,
            "supported_correct": bool(checked["answered"] and checked["answer"] == gold),
            "answered": bool(checked["answered"]),
            "raw_false_assertion": raw_answer in ("entailed", "refuted") and raw_answer != gold,
            "certified_false_assertion": bool(checked["answered"] and checked["answer"] != gold),
            "attempts": attempts, "budget": budget, "tool_result": result, "stop_reason": stop_reason}


def attempt_scaffold(episode, client, budget, *, rounds, limits):
    tool = Scaffold(episode["task"], episode["receipts"], limits=limits)
    view, attempts = tool.view(), []
    messages = messages_for(episode, view)
    raw_answer, result, stop_reason = None, None, "round_limit"
    for _ in range(rounds):
        response = client.propose(messages, budget)
        action, feedback = None, None
        if response["status"] == "completed":
            try:
                action = run.parse_proposal(response.get("text"))
                if set(action) == {"finish"} and action["finish"] in ("entailed", "refuted", "unknown"):
                    raw_answer = action["finish"]
                    result = tool.finish(raw_answer)
                    feedback = {"accepted": True, "finished": True}
                    stop_reason = "caller_finish"
                else:
                    feedback = tool.apply(action)
            except (ValueError, TypeError):
                feedback = {"accepted": False, "errors": [{"code": "invalid_action_json",
                            "message": "Return one select or finish JSON action."}]}
        attempts.append({"response": response, "action": action, "feedback": feedback})
        if result is not None:
            break
        if response["status"] != "completed":
            stop_reason = "transport_" + response["status"]
            break
        if budget.snapshot()["exhausted"]:
            stop_reason = "transport_budget"
            break
        view = tool.view()
        messages = messages_for(episode, view, feedback)
    if result is None:
        result = tool.finish("unknown")
        result["answer_origin"] = "bounded_policy_abstention"
    return score_tool(episode, "scaffold", attempts, result, attempts[-1]["response"]["budget"],
                      raw_answer, stop_reason)


def attempt_episode(episode, arm, client, budget, settings):
    if arm in ("one_shot", "verified_repair"):
        return run.attempt_episode(episode, arm, client, budget)
    limits = ScaffoldLimits(**settings["scaffold_limits"])
    if arm == "scaffold":
        return attempt_scaffold(episode, client, budget, rounds=settings["max_rounds"], limits=limits)
    if arm != "deterministic_search":
        raise ValueError("unknown evaluation arm")
    result = deterministic_search(episode["task"], episode["receipts"], limits=limits)
    zero = {"max_total_tokens": settings["max_tokens"], "max_calls": settings["max_calls"],
            "max_output_tokens": settings["max_output_tokens"], "max_elapsed_seconds": settings["max_seconds"],
            "tokens_charged": 0, "tokens_reserved": 0, "calls_used": 0, "elapsed_seconds": None,
            "overrun": False, "elapsed_source": "not_measured; see explicit local work counters"}
    return score_tool(episode, arm, [], result, zero, result["proposal"]["answer"], "symbolic_search")


def aggregate(rows):
    groups = {}
    for arm in sorted({r["arm"] for r in rows}):
        group = [r for r in rows if r["arm"] == arm]
        n = len(group)
        events = [event for r in group for a in r["attempts"] for event in a["response"]["attempts"]]
        reasoning = [(event.get("usage") or {}).get("reasoning_tokens") for event in events]
        work = Counter()
        for row in group:
            for key, value in (row.get("tool_result") or {}).get("work", {}).items():
                if type(value) is int:
                    work[key] += value
        groups[arm] = {"episodes": n, "raw_answer_accuracy": sum(r["raw_correct"] for r in group) / n,
                       "outcome_denominator": "recorded episode/arm pairs, including transport failures; unattempted pairs are excluded",
                       "dispatched_pairs": sum(r["budget"]["calls_used"] > 0 for r in group),
                       "pairs_with_completed_model_response": sum(any(a["response"]["status"] == "completed" for a in r["attempts"]) for r in group),
                       "answer_coverage": sum(r["answered"] for r in group) / n,
                       "supported_correct": sum(r["supported_correct"] for r in group),
                       "correct_unknowns": sum(r["raw_answer"] == r["gold_answer"] == "unknown" for r in group),
                       "raw_false_assertions": sum(r["raw_false_assertion"] for r in group),
                       "certified_false_assertions": sum(r["certified_false_assertion"] for r in group),
                       "calls": sum(r["budget"]["calls_used"] for r in group),
                       "tokens": sum(r["budget"]["tokens_charged"] for r in group),
                       "reported_reasoning_tokens": sum(v for v in reasoning if type(v) is int) if any(type(v) is int for v in reasoning) else None,
                       "reasoning_usage_events": sum(type(v) is int for v in reasoning),
                       "transport_elapsed_seconds": sum(r["budget"]["elapsed_seconds"] or 0 for r in group) if events else None,
                       "budget_overruns": sum(r["budget"]["overrun"] for r in group),
                       "local_work": dict(work),
                       "complete_symbolic_searches": sum(bool((r.get("tool_result") or {}).get("search_complete")) for r in group),
                       "final_transport_statuses": dict(Counter(r["attempts"][-1]["response"]["status"] if r["attempts"] else "no_model_calls" for r in group))}
    paired = {}
    indexed = {(r["episode_id"], r["arm"]): r for r in rows}
    if len(indexed) != len(rows):
        raise ValueError("duplicate episode/arm rows in aggregate")
    scaffold_ids = {episode for episode, arm in indexed if arm == "scaffold"}
    for plain in ("one_shot", "verified_repair"):
        plain_ids = {episode for episode, arm in indexed if arm == plain}
        common = sorted(scaffold_ids & plain_ids)
        if not common:
            continue
        comparison = {"paired_episodes": len(common),
                      "unpaired_scaffold_episodes": len(scaffold_ids - plain_ids),
                      "unpaired_plain_episodes": len(plain_ids - scaffold_ids)}
        for metric in ("raw_correct", "supported_correct"):
            counts = Counter()
            for episode in common:
                left = bool(indexed[episode, "scaffold"][metric])
                right = bool(indexed[episode, plain][metric])
                counts["both" if left and right else "scaffold_only" if left
                       else "plain_only" if right else "neither"] += 1
            comparison[metric] = {key: counts[key] for key in
                                 ("both", "scaffold_only", "plain_only", "neither")}
        paired["scaffold_vs_" + plain] = comparison
    return {"arms": groups, "paired": paired,
            "interpretation": "Matched ceilings, different policies and actual resource use. Local joins/search are explicit computational assistance. Unknown is abstention; only deterministic search_complete records exhausted finite closure. No frontier parity or economic efficacy is established."}


def fatal_refusal(event):
    """Inspect retained endpoint metadata, never model text or proof fields."""
    return (event.get("schema") == "reasoning.attempt.v1" and event.get("status") == "error"
            and bool(event.get("reservation_id")) and type(event.get("http_status")) is int
            and event["http_status"] in FATAL_HTTP_STATUSES)


def row_events(rows):
    return [event for row in rows for attempt in row["attempts"] for event in attempt["response"]["attempts"]]


def interruption_for(settings, rows, ledger):
    """Reconstruct the stop from either durable copy if its marker is missing."""
    event = next((e for e in list(ledger) + row_events(rows) if fatal_refusal(e)), None)
    if event is None:
        return None
    rid = event["reservation_id"]
    row = next((r for r in rows if any(e.get("reservation_id") == rid for e in row_events([r]))), None)
    return {"schema": INTERRUPTION_SCHEMA, "status": "interrupted", "reason": "unrecoverable_endpoint_refusal",
            "run_instance_id": settings["run_instance_id"], "run_config_sha256": benchmark.fingerprint(settings),
            "http_status": event["http_status"], "reservation_id": rid,
            "event_sha256": benchmark.fingerprint(event),
            "episode_id": row["episode_id"] if row else None, "arm": row["arm"] if row else None,
            "result_row_durable": row is not None, "resume_allowed": False,
            "local_work_policy": "stop all remaining pairs, including deterministic work",
            "next_step": "Resolve the external endpoint issue, then explicitly start a fresh run directory and identity. This run cannot resume."}


def checked_interruption(directory, settings, rows, ledger, *, persist=False):
    path = Path(directory) / "interruption.json"
    expected = interruption_for(settings, rows, ledger)
    if path.exists():
        if json.loads(path.read_text()) != expected:
            raise ValueError("interruption report differs from retained endpoint refusal; no further dispatch is permitted")
    elif expected is not None:
        if not persist:
            raise ValueError("retained fatal refusal lacks its durable interruption report")
        run.atomic_json(path, expected)
        # The report must survive a crash after rename, before any later work.
        if os.name == "posix":
            descriptor = os.open(path.parent, os.O_RDONLY)
            try:
                os.fsync(descriptor)
            finally:
                os.close(descriptor)
    return expected


def summarize_run(dataset, settings, rows, ledger, interruption=None):
    """Partial denominators never manufacture results for unvisited pairs."""
    summary = aggregate(rows)
    expected = [(e["task"]["id"], arm) for e in dataset["episodes"] for arm in settings["arms"]]
    recorded = {(r["episode_id"], r["arm"]) for r in rows}
    missing = [{"episode_id": eid, "arm": arm} for eid, arm in expected if (eid, arm) not in recorded]
    represented = {e.get("reservation_id") for e in row_events(rows) if e.get("reservation_id")}
    dispatched = {e.get("reservation_id") for e in ledger if e.get("reservation_id")}
    unreconciled = len(dispatched ^ represented)
    completed = not missing and not unreconciled and interruption is None
    by_arm = {}
    for arm in settings["arms"]:
        group = [r for r in rows if r["arm"] == arm]
        by_arm[arm] = {"expected_pairs": len(dataset["episodes"]), "recorded_pairs": len(group),
                       "dispatched_pairs": sum(r["budget"]["calls_used"] > 0 for r in group),
                       "pairs_with_completed_model_response": sum(any(a["response"]["status"] == "completed" for a in r["attempts"]) for r in group),
                       "deterministic_completed_pairs": len(group) if arm == "deterministic_search" else 0,
                       "unattempted_pairs": len(dataset["episodes"]) - len(group) if not unreconciled else None}
    summary["completion"] = {"run_instance_id": settings["run_instance_id"],
        "status": "interrupted" if interruption else "complete" if completed else "partial",
        "complete": completed, "expected_pairs": len(expected), "recorded_pairs": len(rows),
        "all_planned_pairs_recorded": not missing, "unrecorded_pair_count": len(missing),
        "unattempted_pair_count": len(missing) if not unreconciled else None,
        "unattempted_pairs": missing if not unreconciled else None,
        "unreconciled_dispatches": unreconciled, "by_arm": by_arm,
        "accounting_note": "Unattempted slots have no result row and are excluded from accuracy and paired comparisons. Unreconciled dispatches make their exact count unknown."}
    summary["interruption"] = interruption
    return summary


def unverified_recovery_summary(dataset, settings, rows, ledger, interruption, audit):
    """Expose corrupt/orphan accounting without endorsing stored outcome scores."""
    represented = {e.get("reservation_id") for e in row_events(rows) if e.get("reservation_id")}
    dispatched = {e.get("reservation_id") for e in ledger if e.get("reservation_id")}
    return {"arms": {}, "paired": {}, "interruption": interruption,
            "completion": {"run_instance_id": settings["run_instance_id"], "status": "interrupted",
                "complete": False, "expected_pairs": len(dataset["episodes"]) * len(settings["arms"]),
                "recorded_pairs": len(rows), "record_count_basis": "unverified local rows",
                "unattempted_pair_count": None, "unattempted_pairs": None,
                "unreconciled_dispatches": len(dispatched ^ represented)},
            "integrity": {"verified": False, "errors": audit["integrity_errors"],
                          "verification_differences": audit["verification_differences"]},
            "interpretation": "Fatal refusal retained; resume is forbidden. Outcome scores and paired comparisons are withheld because offline integrity verification failed."}


def source_hashes(client_path):
    hashes = run.source_hashes(client_path)
    for name in ("scaffold_run.py", "scaffold.py"):
        hashes[name] = benchmark.fingerprint(Path(__file__).with_name(name).read_text())
    return hashes


def settings_for(dataset, identity, client_path, arms, *, max_tokens=96000,
                 max_calls=16, max_output_tokens=4096, max_seconds=180., max_rounds=16,
                 run_instance_id=None):
    if any(type(v) is not int or v < 1 for v in (max_tokens, max_calls, max_output_tokens, max_rounds)):
        raise ValueError("positive integer token/call/round caps required")
    if type(max_seconds) not in (int, float) or not math.isfinite(max_seconds) or max_seconds <= 0:
        raise ValueError("positive finite elapsed cap required")
    if not arms or len(set(arms)) != len(arms) or any(arm not in ARMS for arm in arms):
        raise ValueError("distinct supported arms required")
    run_instance_id = str(uuid4()) if run_instance_id is None else run_instance_id
    if not isinstance(run_instance_id, str) or str(UUID(run_instance_id)) != run_instance_id:
        raise ValueError("a canonical UUID run instance identity is required")
    return {"schema": SCHEMA, "prompt_version": PROMPT_VERSION, "run_instance_id": run_instance_id,
            "fatal_http_statuses": list(FATAL_HTTP_STATUSES),
            "prompt_sha256": {"plain": benchmark.fingerprint(run.SYSTEM), "scaffold": benchmark.fingerprint(SYSTEM)},
            "dataset_sha256": benchmark.fingerprint(dataset), "manifest_sha256": dataset["manifest_sha256"],
            "model": identity, "client_code_path": str(Path(client_path).resolve()), "arms": list(arms),
            "max_tokens": max_tokens, "max_calls": max_calls, "max_output_tokens": max_output_tokens,
            "max_seconds": max_seconds, "max_rounds": max_rounds,
            "scaffold_limits": asdict(limits_for(max_rounds)), "code_sha256": source_hashes(client_path)}


def validate_run(directory, dataset, settings, rows):
    if settings.get("schema") != SCHEMA or settings.get("prompt_version") != PROMPT_VERSION:
        raise ValueError("unsupported scaffold run schema/prompt version")
    if (not isinstance(settings.get("run_instance_id"), str)
            or str(UUID(settings["run_instance_id"])) != settings["run_instance_id"]
            or settings.get("fatal_http_statuses") != list(FATAL_HTTP_STATUSES)):
        raise ValueError("invalid run identity or fatal refusal policy")
    if settings.get("prompt_sha256") != {"plain": benchmark.fingerprint(run.SYSTEM), "scaffold": benchmark.fingerprint(SYSTEM)}:
        raise ValueError("prompt hashes differ from frozen run")
    if settings.get("code_sha256") != source_hashes(settings["client_code_path"]):
        raise ValueError("code/dependency hashes differ from frozen run")
    if settings.get("dataset_sha256") != benchmark.fingerprint(dataset):
        raise ValueError("private dataset hash differs")
    if settings.get("manifest_sha256") != dataset["manifest_sha256"] or dataset["manifest_sha256"] != benchmark.fingerprint([e["metadata"] for e in dataset["episodes"]]):
        raise ValueError("dataset manifest hash differs")
    episodes = {e["task"]["id"]: e for e in dataset["episodes"]}
    if len(episodes) != len(dataset["episodes"]):
        raise ValueError("duplicate task IDs")
    for episode in episodes.values():
        if episode["metadata"]["task_sha256"] != benchmark.fingerprint(episode["task"]):
            raise ValueError("task hash differs")
        if episode["gold"] != benchmark.reference(episode["task"], episode["receipts"]):
            raise ValueError("gold differs from independent reference")
    seen = set()
    for row in rows:
        pair = (row["episode_id"], row["arm"])
        if pair in seen or pair[0] not in episodes or pair[1] not in settings["arms"]:
            raise ValueError("duplicate or out-of-run row")
        seen.add(pair)
        if row.get("run_config_sha256") != benchmark.fingerprint(settings):
            raise ValueError("result/config hash differs")
    ledger = run.read_jsonl(Path(directory) / "transport.jsonl")
    run.reconcile_transport(rows, ledger)
    for index, row in enumerate(rows):
        if any(fatal_refusal(e) for e in row_events([row])) and index != len(rows) - 1:
            raise ValueError("a result was recorded after the fatal run-wide refusal")
    for index, event in enumerate(ledger):
        if fatal_refusal(event) and index != len(ledger) - 1:
            raise ValueError("transport continued after the fatal run-wide refusal")
    return episodes


class ReplayBudget:
    def __init__(self):
        self.latest = None

    def snapshot(self):
        if self.latest is None:
            raise ValueError("replay budget accessed before response")
        return self.latest


class ReplayClient:
    """Validate reconstructed prompts and return retained responses, never dispatch."""
    def __init__(self, attempts, settings):
        self.attempts, self.settings, self.index = attempts, settings, 0

    def propose(self, messages, budget):
        if self.index >= len(self.attempts):
            raise ValueError("recorded run ends before its policy terminates")
        response = self.attempts[self.index]["response"]
        self.index += 1
        events = response["attempts"]
        if not events:
            raise ValueError("response lacks transport accounting")
        identity = self.settings["model"]
        payload = {"model": identity["model"], "messages": messages,
                   "max_tokens": self.settings["max_output_tokens"], "stream": False}
        effort = identity.get("requested_reasoning_effort")
        if effort is not None:
            payload["reasoning_effort"] = effort
        for event in events:
            if any(event.get(key) != value for key, value in identity.items()):
                raise ValueError("transport model/effort/endpoint/timeout identity differs")
            if (event.get("prompt_sha256") != run.transport_hash(messages)
                    or event.get("system_prompt_sha256") != run.transport_hash([m["content"] for m in messages if m["role"] == "system"])):
                raise ValueError("transport prompt differs from reconstructed public-only messages")
            if event.get("reservation_id") and event.get("request_sha256") != run.transport_hash(payload):
                raise ValueError("transport request hash differs, including explicit reasoning effort")
        if events[-1].get("response_sha256") is not None and events[-1]["response_sha256"] != run.transport_hash(response.get("text")):
            raise ValueError("response text hash differs")
        budget.latest = response["budget"]
        return response


def reaccount(row, settings):
    if row["arm"] == "deterministic_search":
        if row["attempts"]:
            raise ValueError("symbolic baseline cannot contain paid attempts")
        return row
    events = [e for a in row["attempts"] for e in a["response"]["attempts"] if e.get("reservation_id")]
    if len({e["reservation_id"] for e in events}) != len(events):
        raise ValueError("paid attempt reused")
    if any(type(e.get("charged_tokens")) is not int or e["charged_tokens"] < 0 for e in events):
        raise ValueError("invalid charged tokens")
    budget = dict(row["budget"])
    for key, setting in (("max_total_tokens", "max_tokens"), ("max_calls", "max_calls"),
                         ("max_output_tokens", "max_output_tokens"), ("max_elapsed_seconds", "max_seconds")):
        if budget.get(key) != settings[setting]:
            raise ValueError("transport budget cap differs")
    budget.update(tokens_charged=sum(e["charged_tokens"] for e in events), calls_used=len(events), tokens_reserved=0)
    return {**row, "budget": budget}


def replay(directory):
    directory = Path(directory)
    report = {"records": 0, "verification_differences": [], "integrity_errors": [], "summary": None}
    try:
        dataset = json.loads((directory / "benchmark_private.json").read_text())
        settings = json.loads((directory / "run_config.json").read_text())
        rows = run.read_jsonl(directory / "results.jsonl")
        report["records"] = len(rows)
        episodes = validate_run(directory, dataset, settings, rows)
        ledger = run.read_jsonl(directory / "transport.jsonl")
        interruption = checked_interruption(directory, settings, rows, ledger)
        fresh_rows = []
        for row in rows:
            client = ReplayClient(row["attempts"], settings)
            fresh = attempt_episode(episodes[row["episode_id"]], row["arm"], client, ReplayBudget(), settings)
            if client.index != len(row["attempts"]):
                raise ValueError("extra attempts after policy termination")
            fresh = reaccount(fresh, settings)
            fresh["run_config_sha256"] = benchmark.fingerprint(settings)
            for key in sorted(set(fresh) | set(row)):
                if fresh.get(key) != row.get(key):
                    report["verification_differences"].append({"episode": row["episode_id"], "arm": row["arm"], "field": key})
            fresh_rows.append(fresh)
        report["summary"] = summarize_run(dataset, settings, fresh_rows, ledger, interruption)
    except (OSError, ValueError, KeyError, TypeError) as error:
        report["integrity_errors"].append(str(error))
    return report


def execute(directory, dataset, settings, client, budget_factory, *, resume=False):
    """Persist/reconcile before dispatch; interrupted paid work requires recovery."""
    directory = Path(directory)
    directory.mkdir(parents=True, exist_ok=True)
    lock = directory / ".writer.lock"
    try:
        descriptor = os.open(lock, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    except FileExistsError:
        raise ValueError("run writer lock exists; verify the previous process stopped before recovering the retained lock") from None
    try:
        with os.fdopen(descriptor, "w") as stream:
            json.dump({"pid": os.getpid()}, stream)
            stream.flush()
            os.fsync(stream.fileno())
        return _execute_locked(directory, dataset, settings, client, budget_factory, resume=resume)
    finally:
        lock.unlink()


def _execute_locked(directory, dataset, settings, client, budget_factory, *, resume):
    if benchmark.fingerprint(dataset) != settings["dataset_sha256"]:
        raise ValueError("supplied dataset differs from frozen settings")
    paid = any(arm != "deterministic_search" for arm in settings["arms"])
    if paid and (client.config.public_identity() != settings["model"]
                 or settings["model"].get("requested_reasoning_effort") is None):
        raise ValueError("client identity/explicit effort differs from frozen settings")
    config_path, result_path = directory / "run_config.json", directory / "results.jsonl"
    if config_path.exists():
        if not resume or json.loads(config_path.read_text()) != settings:
            raise ValueError("existing run or changed resume settings; use a fresh directory")
    else:
        if result_path.exists() or (directory / "transport.jsonl").exists() or (directory / "interruption.json").exists():
            raise ValueError("orphan run records without config; reconcile before dispatch")
        run.atomic_json(directory / "benchmark_private.json", dataset)
        run.atomic_json(config_path, settings)
    rows = run.read_jsonl(result_path)
    ledger = run.read_jsonl(directory / "transport.jsonl")
    interruption = checked_interruption(directory, settings, rows, ledger, persist=True)
    if interruption is not None:
        # Reconstruct a missing marker even after a crash before the result row.
        # Orphan accounting remains explicit, and this identity never dispatches.
        audit = replay(directory)
        summary = (audit["summary"] if not audit["integrity_errors"] and not audit["verification_differences"]
                   else unverified_recovery_summary(dataset, settings, rows, ledger, interruption, audit))
        run.atomic_json(directory / "summary.json", summary)
        raise ValueError("run interrupted by fatal endpoint refusal; resume is forbidden, use a fresh run directory and identity after resolving the external issue")
    saved_dataset = json.loads((directory / "benchmark_private.json").read_text())
    validate_run(directory, saved_dataset, settings, rows)
    if resume:
        audit = replay(directory)
        if audit["integrity_errors"] or audit["verification_differences"]:
            raise ValueError("resume replay failed; reconcile before any further model calls")
    done = {(row["episode_id"], row["arm"]) for row in rows}
    for i, episode in enumerate(dataset["episodes"]):
        offset = i % len(settings["arms"])
        order = settings["arms"][offset:] + settings["arms"][:offset]
        for arm in order:
            if (episode["task"]["id"], arm) in done:
                continue
            budget = None if arm == "deterministic_search" else budget_factory()
            if budget is not None:
                snapshot = budget.snapshot()
                expected = {"max_total_tokens": settings["max_tokens"], "max_calls": settings["max_calls"],
                            "max_output_tokens": settings["max_output_tokens"], "max_elapsed_seconds": settings["max_seconds"],
                            "max_retries": 0, "calls_used": 0, "tokens_charged": 0, "tokens_reserved": 0}
                if any(snapshot.get(key) != value for key, value in expected.items()):
                    raise ValueError("fresh dispatch budget differs from frozen caps")
            row = attempt_episode(episode, arm, client, budget, settings)
            row["run_config_sha256"] = benchmark.fingerprint(settings)
            with result_path.open("a") as stream:
                stream.write(json.dumps(row, allow_nan=False) + "\n")
                stream.flush()
                os.fsync(stream.fileno())
            rows.append(row)
            ledger = run.read_jsonl(directory / "transport.jsonl")
            interruption = checked_interruption(directory, settings, rows, ledger, persist=True)
            summary = summarize_run(dataset, settings, rows, ledger, interruption)
            run.atomic_json(directory / "summary.json", summary)
            print(json.dumps({"episode": i + 1, "arm": arm, "answered": row["answered"],
                              "raw_correct": row["raw_correct"], "calls": row["budget"]["calls_used"],
                              "tokens": row["budget"]["tokens_charged"]}), flush=True)
            if interruption is not None:
                print(json.dumps({"status": "interrupted", "http_status": interruption["http_status"],
                                  "recorded_pairs": len(rows), "resume_allowed": False}), flush=True)
                return summary
    return summarize_run(dataset, settings, rows, ledger)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--oracle-repo", type=Path, default=Path.home() / "projects")
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--split", choices=("dev", "test"), default="dev")
    parser.add_argument("--seed")
    parser.add_argument("--count", type=int, default=6)
    parser.add_argument("--arms", nargs="+", choices=ARMS, default=list(ARMS))
    parser.add_argument("--connection-service")
    parser.add_argument("--model")
    parser.add_argument("--reasoning-effort", choices=("none", "minimal", "low", "medium", "high", "xhigh", "max"))
    parser.add_argument("--request-timeout", type=float, default=60.)
    parser.add_argument("--max-tokens", type=int, default=96000)
    parser.add_argument("--max-output-tokens", type=int, default=4096)
    parser.add_argument("--max-calls", type=int, default=16)
    parser.add_argument("--max-seconds", type=float, default=180.)
    parser.add_argument("--max-rounds", type=int, default=16)
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--replay", action="store_true")
    args = parser.parse_args()
    if args.replay:
        report = replay(args.run_dir)
        print(json.dumps(report, indent=2))
        if report["integrity_errors"] or report["verification_differences"]:
            raise SystemExit(1)
        return
    if args.count < 1:
        parser.error("positive count required")
    if not args.seed:
        parser.error("an explicit fresh --seed is required")
    module, client_path = run.load_client(args.oracle_repo)
    paid = any(arm != "deterministic_search" for arm in args.arms)
    if paid:
        if args.reasoning_effort is None:
            parser.error("explicit --reasoning-effort required for matched model comparisons")
        config = (module.load_running_service_config(args.connection_service, "generator", "scaffold-comparison")
                  if args.connection_service else module.ClientConfig.from_env())
        config = replace(config, model=args.model or config.model, reasoning_effort=args.reasoning_effort,
                         timeout_seconds=args.request_timeout)
        identity = config.public_identity()
        client = module.ProposerClient(config, ledger_path=args.run_dir / "transport.jsonl")
    else:
        identity, client = {"model": None, "requested_reasoning_effort": None}, None
    dataset = benchmark.suite(args.seed, args.split, args.count)
    run_instance_id = None
    if args.resume:
        try:
            run_instance_id = json.loads((args.run_dir / "run_config.json").read_text())["run_instance_id"]
        except (OSError, ValueError, KeyError, TypeError):
            parser.error("resume requires this run's saved instance identity; legacy frozen runs require their original source checkpoint")
    settings = settings_for(dataset, identity, client_path, args.arms, max_tokens=args.max_tokens,
                            max_calls=args.max_calls, max_output_tokens=args.max_output_tokens,
                            max_seconds=args.max_seconds, max_rounds=args.max_rounds, run_instance_id=run_instance_id)
    def budget_factory():
        return module.Budget(args.max_tokens, args.max_calls, args.max_output_tokens, args.max_seconds,
                             max_retries=0)
    try:
        summary = execute(args.run_dir, dataset, settings, client, budget_factory, resume=args.resume)
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.error(str(error))
    print(json.dumps(summary, indent=2))
    if not summary["completion"]["complete"]:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
