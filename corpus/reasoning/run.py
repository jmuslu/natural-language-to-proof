"""Measured non-frontier proposing with independent typed proof checking.

Run from the repository: PYTHONPATH=corpus python3 -m reasoning.run --help
All prompts concern generated worlds. Gold labels are read only for scoring,
never sent to the proposer or used as repair feedback. No generated code runs.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import sys
import time

from reasoning import benchmark
from reasoning.engine import evaluate

PROMPT_VERSION = "proof-proposer-v1"
RUN_SCHEMA = "reasoning-run-v2"
SYSTEM = """You reason in a finite typed world, using only the supplied facts and universally quantified rules.
Negation is explicit: missing evidence does NOT mean false. A fact with verification unknown/refuted cannot be a premise. Only confirmed signed facts may be cited.
Return ONLY one JSON object, no explanation outside it:
{"answer":"entailed|refuted|unknown","steps":[...],"conclusion":"step_id or null"}.
For a confirmed fact use {"id":"s0","fact_id":"the supplied fact id"}.
For a rule use {"id":"s1","rule_id":"the supplied rule id","substitution":{"x":"entity"},"premises":["s0",...]}. Include every variable declared by that rule, and cite premises in rule body order. Variables use ?x in rules but x in substitutions. Refer only to earlier steps. Each rule instance must match exact predicate, arguments, types and explicit negation of its premises. Do not invent facts, rule IDs or entities.
For entailed, conclusion names a step deriving the queried signed atom. For refuted, it names a step deriving its explicit opposite. For unknown, use steps [] and conclusion null. Unknown is an honest abstention when neither side has support. Multiple independent derivations may be retained as separate steps. Only include proof-relevant steps; no confidence fields.
All facts and rules are provided in the task. Statements such as p(?x) mean predicate p applied to x, not a propositional variable. Reason carefully about exact argument bindings and conjunctions."""


def load_client(repo):
    path = Path(repo).resolve() / "shared/reasoning/client.py"
    if not path.is_file():
        raise FileNotFoundError(f"missing proposer client: {path}")
    spec = importlib.util.spec_from_file_location("qr_reasoning_client", path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module, path


def parse_proposal(text):
    if not isinstance(text, str):
        raise ValueError("response is not text")
    stripped = text.strip()
    if stripped.startswith("```json\n") and stripped.endswith("```"):
        stripped = stripped[8:-3].strip()
    elif stripped.startswith("```\n") and stripped.endswith("```"):
        stripped = stripped[4:-3].strip()
    value = json.loads(stripped)
    if not isinstance(value, dict):
        raise ValueError("proposal must be a JSON object")
    return value


def check_text(episode, text):
    try:
        proposal = parse_proposal(text)
    except (ValueError, TypeError):
        return None, {"accepted": False, "answer": "unknown", "answered": False,
                      "errors": [{"code": "invalid_json_response", "step": None,
                                  "message": "Return exactly the requested JSON object."}]}
    result = evaluate(episode["task"], proposal, episode["receipts"])
    return proposal, result.to_dict()


def initial_messages(episode):
    return [{"role": "system", "content": SYSTEM},
            {"role": "user", "content": json.dumps(benchmark.public_task(episode), indent=2)}]


def refinement_feedback(arm, checked):
    if arm == "verified_repair":
        return {"checker_errors": checked["errors"],
                "instruction": "Repair the proof using the original facts/rules, or abstain if unsupported. Return the full replacement JSON."}
    return {"instruction": "Independently review your previous answer, all bindings and every premise against the original task. Correct any errors. Return the full replacement JSON."}


def transport_hash(value):
    """Match the transport's UTF-8 canonical JSON hashing, including Unicode."""
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()).hexdigest()


def attempt_episode(episode, arm, client, budget):
    """one_shot, self_refine and verified_repair share prompt and resource caps.

    self_refine gets a generic review request; verified_repair gets only checker
    errors. Both may call again within the same caps. one_shot is a cheaper
    reference. These are matched ceilings, not claims of equal tokens consumed.
    """
    messages = initial_messages(episode)
    attempts = []
    while True:
        response = client.propose(messages, budget)
        proposal, checked = check_text(episode, response.get("text"))
        attempts.append({"response": response, "proposal": proposal, "check": checked})
        if response["status"] != "completed" or arm == "one_shot":
            break
        if arm == "verified_repair" and checked.get("accepted"):
            break
        if budget.snapshot()["exhausted"]:
            break
        messages.append({"role": "assistant", "content": response["text"]})
        messages.append({"role": "user", "content": json.dumps(refinement_feedback(arm, checked))})
    return score_attempts(episode, arm, attempts, attempts[-1]["response"]["budget"])


def score_attempts(episode, arm, attempts, budget):
    """Deterministic scoring, shared by live runs and offline replay."""
    if not attempts:
        raise ValueError("an episode result must contain an attempt")
    # A transport/budget failure during optional refinement must not erase an
    # earlier syntactically usable answer. Selection never consults correctness
    # or checker validity, which would give the baseline a hidden verifier.
    selectable = [i for i, a in enumerate(attempts) if isinstance(a["proposal"], dict)
                  and a["proposal"].get("answer") in ("entailed", "refuted", "unknown")]
    selected = selectable[-1] if selectable else len(attempts) - 1
    final = attempts[selected]
    raw_answer = (final["proposal"] or {}).get("answer")
    gold = episode["gold"]["answer"]  # Used only after generation/verification.
    return {"episode_id": episode["task"]["id"], "metadata": episode["metadata"], "arm": arm,
            "gold_answer": gold, "raw_answer": raw_answer, "answer": final["check"].get("answer", "unknown"),
            "raw_correct": raw_answer == gold,
            "supported_correct": bool(final["check"].get("answered") and raw_answer == gold),
            "answered": bool(final["check"].get("answered")),
            "raw_false_assertion": raw_answer in ("entailed", "refuted") and raw_answer != gold,
            "certified_false_assertion": bool(final["check"].get("answered") and raw_answer != gold),
            "repaired": bool(final["check"].get("answered") and not attempts[0]["check"].get("answered")),
            "attempts": attempts, "selected_attempt": selected, "budget": budget}


def aggregate(rows):
    arms = {}
    for arm in sorted({r["arm"] for r in rows}):
        group = [r for r in rows if r["arm"] == arm]
        n = len(group)
        tokens = sum(r["budget"]["tokens_charged"] for r in group)
        calls = sum(r["budget"]["calls_used"] for r in group)
        supported = sum(r["supported_correct"] for r in group)
        arms[arm] = {"episodes": n, "raw_answer_accuracy": sum(r["raw_correct"] for r in group) / n,
                     "answer_coverage": sum(r["answered"] for r in group) / n,
                     "supported_correct": supported, "raw_false_assertions": sum(r["raw_false_assertion"] for r in group),
                     "certified_false_assertions": sum(r["certified_false_assertion"] for r in group),
                     "correct_unknowns": sum(r["raw_answer"] == r["gold_answer"] == "unknown" for r in group),
                     "repairs": sum(r["repaired"] for r in group), "tokens": tokens, "calls": calls,
                     "supported_correct_per_1000_tokens": 1000 * supported / tokens if tokens else None,
                     "elapsed_seconds": sum(r["budget"]["elapsed_seconds"] for r in group),
                     "budget_overruns": sum(r["budget"]["overrun"] for r in group),
                     "final_transport_statuses": dict(Counter(r["attempts"][-1]["response"]["status"] for r in group))}
    paired = {}
    if "verified_repair" in arms:
        verified = {r["episode_id"]: r for r in rows if r["arm"] == "verified_repair"}
        for baseline in ("one_shot", "self_refine"):
            base = {r["episode_id"]: r for r in rows if r["arm"] == baseline}
            common = base.keys() & verified.keys()
            if common:
                paired[baseline] = {"episodes": len(common),
                    "verified_only_raw_correct": sum(verified[k]["raw_correct"] and not base[k]["raw_correct"] for k in common),
                    "baseline_only_raw_correct": sum(base[k]["raw_correct"] and not verified[k]["raw_correct"] for k in common)}
    return {"arms": arms, "paired": paired,
            "interpretation": "Exploratory generated-world results under matched budget ceilings. Actual token use is reported. No frontier-model or economic-performance comparison."}


def source_hashes(client_path):
    here = Path(__file__).resolve()
    paths = (here, here.with_name("engine.py"), here.with_name("benchmark.py"),
             here.parent.parent / "reason.py", here.parent.parent / "retract.py", Path(client_path))
    return {p.name: benchmark.fingerprint(p.read_text()) for p in paths}


def read_jsonl(path):
    """Partial lines are errors: silently dropping them could hide a paid call."""
    path = Path(path)
    if not path.exists():
        return []
    try:
        return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]
    except (ValueError, UnicodeError) as exc:
        raise ValueError(f"invalid or incomplete ledger: {path.name}") from exc


def atomic_json(path, value):
    path = Path(path)
    temporary = path.with_name(path.name + ".tmp")
    with temporary.open("w") as stream:
        stream.write(json.dumps(value, indent=2))
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)


def reconcile_transport(rows, ledger):
    """Require every durable dispatch to have an exactly matching result record.

    A crash can leave a paid request without response text. Refuse further calls
    instead of silently granting that episode a fresh budget. This is integrity
    checking of local records, not authentication of provider billing.
    """
    reserved, finished, terminal = {}, {}, []
    for event in ledger:
        if event.get("schema") != "reasoning.attempt.v1":
            raise ValueError("unexpected event in transport ledger")
        rid = event.get("reservation_id")
        if event.get("status") == "reserved":
            if not rid or rid in reserved or rid in finished:
                raise ValueError("duplicate or malformed transport reservation")
            reserved[rid] = event
        else:
            if rid:
                if rid not in reserved or rid in finished:
                    raise ValueError("terminal event lacks a unique prior reservation")
                for key in ("reserved_tokens", "input_estimate", "output_limit", "request_sha256", "prompt_sha256"):
                    if event.get(key) != reserved[rid].get(key):
                        raise ValueError("transport reservation/terminal identity mismatch")
                finished[rid] = event
            elif event.get("status") != "budget_exhausted":
                raise ValueError("unreserved transport terminal event")
            terminal.append(event)
    if reserved.keys() != finished.keys():
        raise ValueError("orphan transport reservation: reconcile the interrupted paid attempt before resuming")
    recorded = [event for row in rows for attempt in row["attempts"]
                for event in attempt["response"]["attempts"]]
    if Counter(map(benchmark.fingerprint, recorded)) != Counter(map(benchmark.fingerprint, terminal)):
        raise ValueError("orphan or mismatched transport event: every paid attempt needs a durable episode result")


def validate_run(directory, dataset, settings, rows):
    if settings.get("schema") != RUN_SCHEMA:
        raise ValueError("unsupported run schema; old runs require a separate legacy audit")
    if settings.get("prompt_version") != PROMPT_VERSION or settings.get("prompt_sha256") != benchmark.fingerprint(SYSTEM):
        raise ValueError("prompt version/hash differs from current replay code")
    if settings.get("code_sha256") != source_hashes(settings["client_code_path"]):
        raise ValueError("code/dependency hashes differ from recorded run")
    if settings.get("dataset_sha256") != benchmark.fingerprint(dataset):
        raise ValueError("private dataset hash mismatch (including receipts and gold)")
    if settings.get("manifest_sha256") != dataset["manifest_sha256"] or dataset["manifest_sha256"] != benchmark.fingerprint([e["metadata"] for e in dataset["episodes"]]):
        raise ValueError("dataset manifest hash mismatch")
    episodes = {e["task"]["id"]: e for e in dataset["episodes"]}
    if len(episodes) != len(dataset["episodes"]):
        raise ValueError("duplicate episode identities in dataset")
    for episode in episodes.values():
        if episode["metadata"]["task_sha256"] != benchmark.fingerprint(episode["task"]):
            raise ValueError("task content hash mismatch")
        if episode["gold"] != benchmark.reference(episode["task"], episode["receipts"]):
            raise ValueError("recorded gold differs from independent finite-world reference")
    seen = set()
    for row in rows:
        pair = (row["episode_id"], row["arm"])
        if pair in seen or pair[0] not in episodes or pair[1] not in settings["arms"]:
            raise ValueError("duplicate or out-of-run episode/arm record")
        seen.add(pair)
        if row.get("run_config_sha256") != benchmark.fingerprint(settings):
            raise ValueError("result/config hash mismatch")
    reconcile_transport(rows, read_jsonl(Path(directory) / "transport.jsonl"))
    return episodes


def replay(directory):
    """Reconstruct proof checks, selected answers, scores and costs without calls."""
    directory = Path(directory)
    differences, rows = [], []
    report = {"records": 0, "verification_differences": differences, "integrity_errors": [], "summary": None}
    try:
        dataset = json.loads((directory / "benchmark_private.json").read_text())
        settings = json.loads((directory / "run_config.json").read_text())
        rows = read_jsonl(directory / "results.jsonl")
        report["records"] = len(rows)
        episodes = validate_run(directory, dataset, settings, rows)
        reconstructed = []
        for row in rows:
            episode, attempts = episodes[row["episode_id"]], []
            messages = initial_messages(episode)
            def difference(field, index=None):
                differences.append({"episode": row["episode_id"], "arm": row["arm"], "attempt": index, "field": field})
            for index, attempt in enumerate(row["attempts"]):
                proposal, check = check_text(episode, attempt["response"].get("text"))
                events = attempt["response"]["attempts"]
                if not events:
                    raise ValueError("proposal response lacks transport accounting")
                for event in events:
                    if event.get("prompt_sha256") != transport_hash(messages) or event.get("system_prompt_sha256") != transport_hash([SYSTEM]):
                        raise ValueError("transport prompt hash differs from reconstructed public-only prompt")
                if events[-1].get("response_sha256") is not None and events[-1]["response_sha256"] != transport_hash(attempt["response"].get("text")):
                    raise ValueError("response text differs from transport hash")
                if proposal != attempt["proposal"]:
                    difference("proposal", index)
                if check != attempt["check"]:
                    difference("check", index)
                attempts.append({"response": attempt["response"], "proposal": proposal, "check": check})
                messages.append({"role": "assistant", "content": attempt["response"].get("text")})
                messages.append({"role": "user", "content": json.dumps(refinement_feedback(row["arm"], check))})
            budget = dict(attempts[-1]["response"]["budget"])
            events = [event for a in attempts for event in a["response"]["attempts"]]
            calls = [event for event in events if event.get("reservation_id")]
            if len({event["reservation_id"] for event in calls}) != len(calls):
                raise ValueError("paid transport attempt reused across proposal calls")
            charged = []
            for event in calls:
                tokens = event.get("charged_tokens")
                if type(tokens) is not int or tokens < 0:
                    raise ValueError("invalid token accounting in transport event")
                charged.append(tokens)
            budget.update(tokens_charged=sum(charged), calls_used=len(calls), tokens_reserved=0)
            for key in ("max_total_tokens", "max_calls", "max_output_tokens", "max_elapsed_seconds"):
                expected = settings[{"max_total_tokens": "max_tokens", "max_elapsed_seconds": "max_seconds"}.get(key, key)]
                if budget.get(key) != expected:
                    raise ValueError("transport budget differs from configured caps")
            fresh = score_attempts(episode, row["arm"], attempts, budget)
            for key, value in fresh.items():
                if key != "attempts" and row.get(key) != value:
                    difference(key)
            reconstructed.append(fresh)
        report["summary"] = aggregate(reconstructed)
    except (ValueError, KeyError, TypeError, OSError) as exc:
        report["integrity_errors"].append(str(exc))
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--oracle-repo", type=Path, default=Path.home() / "projects")
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--split", choices=("dev", "test"), default="dev")
    parser.add_argument("--count", type=int, default=6)
    parser.add_argument("--seed", default="2026-09-15-frozen-v1")
    parser.add_argument("--arms", nargs="+", choices=("one_shot", "self_refine", "verified_repair"), default=["one_shot", "verified_repair"])
    parser.add_argument("--service", help="explicit running Docker service supplying connection configuration")
    parser.add_argument("--role", choices=("generator", "analyst", "qwen"), default="generator")
    parser.add_argument("--max-tokens", type=int, default=16000)
    parser.add_argument("--max-output-tokens", type=int, default=3072)
    parser.add_argument("--max-calls", type=int, default=2)
    parser.add_argument("--max-seconds", type=float, default=90.)
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--replay", action="store_true")
    args = parser.parse_args()
    if args.replay:
        report = replay(args.run_dir)
        print(json.dumps(report, indent=2))
        if report["verification_differences"] or report["integrity_errors"]:
            raise SystemExit(1)
        return
    if args.count < 1 or len(set(args.arms)) != len(args.arms):
        parser.error("positive count and distinct arms required")
    client_module, client_path = load_client(args.oracle_repo)
    config = (client_module.load_running_service_config(args.service, args.role, "explicit-research-proposer", timeout_seconds=60.)
              if args.service else client_module.ClientConfig.from_env())
    dataset = benchmark.suite(args.seed, args.split, args.count)
    settings = {"schema": RUN_SCHEMA, "prompt_version": PROMPT_VERSION, "prompt_sha256": benchmark.fingerprint(SYSTEM),
                "manifest_sha256": dataset["manifest_sha256"], "dataset_sha256": benchmark.fingerprint(dataset),
                "model": config.public_identity(), "client_code_path": str(client_path.resolve()),
                "arms": args.arms, "max_tokens": args.max_tokens, "max_output_tokens": args.max_output_tokens,
                "max_calls": args.max_calls, "max_seconds": args.max_seconds,
                "code_sha256": source_hashes(client_path)}
    directory = args.run_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    config_path = directory / "run_config.json"
    result_path = directory / "results.jsonl"
    if config_path.exists():
        if not args.resume or json.loads(config_path.read_text()) != settings:
            parser.error("run already exists or resume settings/code differ; choose a fresh run directory")
    else:
        if result_path.exists() or (directory / "transport.jsonl").exists():
            parser.error("run records exist without config; reconcile before creating a new run")
        atomic_json(directory / "benchmark_private.json", dataset)
        atomic_json(config_path, settings)
    try:
        rows = read_jsonl(result_path)
        saved_dataset = json.loads((directory / "benchmark_private.json").read_text())
        validate_run(directory, saved_dataset, settings, rows)
        if args.resume:
            audit = replay(directory)
            if audit["integrity_errors"] or audit["verification_differences"]:
                raise ValueError("resume replay differs from saved evidence/metrics; inspect offline replay before further calls")
    except (ValueError, KeyError, TypeError, OSError) as exc:
        parser.error(str(exc))
    done = {(r["episode_id"], r["arm"]) for r in rows}
    client = client_module.ProposerClient(config, ledger_path=directory / "transport.jsonl")
    for episode_index, episode in enumerate(dataset["episodes"]):
        # Rotate arm order by episode to reduce fixed-order service/cache effects.
        offset = episode_index % len(args.arms)
        order = args.arms[offset:] + args.arms[:offset]
        for arm in order:
            if (episode["task"]["id"], arm) in done:
                continue
            budget = client_module.Budget(args.max_tokens, args.max_calls, args.max_output_tokens, args.max_seconds)
            row = attempt_episode(episode, arm, client, budget)
            row["run_config_sha256"] = benchmark.fingerprint(settings)
            with result_path.open("a") as stream:
                stream.write(json.dumps(row) + "\n")
                stream.flush()
                os.fsync(stream.fileno())
            rows.append(row)
            atomic_json(directory / "summary.json", aggregate(rows))
            print(json.dumps({"episode": episode_index + 1, "arm": arm, "raw_correct": row["raw_correct"],
                              "answered": row["answered"], "tokens": row["budget"]["tokens_charged"],
                              "calls": row["budget"]["calls_used"], "status": row["attempts"][-1]["response"]["status"]}), flush=True)
    print(json.dumps(aggregate(rows), indent=2))


if __name__ == "__main__":
    main()
