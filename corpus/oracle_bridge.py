"""Audited receipts for passes_validation(run_id), with durable revision history.

Receipts are recomputed by agentic-qr; embedded verdicts are never trusted.
This audits certificate consistency, not producer authenticity or experimental
independence. Source claim references remain attribution, not logical proofs.
"""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import re
import sqlite3
import subprocess
from datetime import datetime, timezone

SCHEMA = "agentic-qr.oracle-receipt.v1"
IDENTIFIER = re.compile(r"[A-Za-z0-9][A-Za-z0-9._:-]{0,255}\Z", re.ASCII)


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), allow_nan=False)


def digest(value):
    return hashlib.sha256(canonical(value).encode("utf-8")).hexdigest()


def utc_now():
    return datetime.now(timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")


def cutoff(value):
    """An explicit date means the end of that UTC day."""
    if value is None:
        return None
    if len(value) == 10:
        value += "T23:59:59.999999Z"
    dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if dt.tzinfo is None:
        raise ValueError("as-of timestamp must include a timezone")
    return dt.astimezone(timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")


def load_evaluator(repo):
    """Missing companion code is an error, never a legacy pass/fail fallback."""
    path = Path(repo).expanduser().resolve() / "shared/backtesting/validation/oracle_receipt.py"
    if not path.is_file():
        raise FileNotFoundError(f"oracle evaluator missing: {path}; set --oracle-repo to the updated checkout")
    spec = importlib.util.spec_from_file_location("agentic_oracle_receipt", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.evaluate_result


def checked_receipt(result, evaluator):
    receipt = evaluator(result)
    if not isinstance(receipt, dict) or receipt.get("schema") != SCHEMA:
        raise ValueError("unexpected external receipt schema")
    if receipt.get("verdict") not in ("confirmed", "refuted", "unknown"):
        raise ValueError("unexpected external verdict")
    rid = receipt.get("run_id")
    if not isinstance(rid, str) or not IDENTIFIER.fullmatch(rid):
        rid = "unidentified:" + digest(result)
        receipt = {**receipt, "run_id": rid, "verdict": "unknown",
                   "reason": "missing_or_invalid_run_id",
                   "proposition": {"kind": "passes_validation", "run_id": rid}}
    if receipt.get("proposition") != {"kind": "passes_validation", "run_id": rid}:
        raise ValueError("external receipt asserted a different proposition")
    receipt = {**receipt, "claim_refs": sorted(set(receipt.get("claim_refs", [])))}
    eid = receipt.get("evidence_id")
    if not isinstance(eid, str) or not IDENTIFIER.fullmatch(eid):
        raise ValueError("missing or invalid external evidence identity")
    canonical(receipt)
    return receipt


class ReceiptLedger:
    """Append-only observations; latest revision per run is active evidence.

    observed_at records when THIS journal saw a revision. Historical artifacts
    are never backdated from their filenames, mtimes or claimed event dates.
    """
    def __init__(self, path):
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.db = sqlite3.connect(str(self.path))
        self.db.row_factory = sqlite3.Row
        self.db.executescript("""
            CREATE TABLE IF NOT EXISTS revisions (
                revision INTEGER PRIMARY KEY, run_id TEXT NOT NULL,
                fingerprint TEXT NOT NULL, observed_at TEXT NOT NULL,
                source_path TEXT, receipt_json TEXT NOT NULL);
            CREATE INDEX IF NOT EXISTS receipt_run ON revisions(run_id, revision);
            CREATE TABLE IF NOT EXISTS sources (path TEXT PRIMARY KEY, run_id TEXT NOT NULL);
        """)

    def close(self):
        self.db.close()

    def snapshots(self, as_of=None):
        end = cutoff(as_of)
        rows = self.db.execute(
            "SELECT * FROM revisions WHERE revision IN "
            "(SELECT MAX(revision) FROM revisions WHERE (? IS NULL OR observed_at <= ?) GROUP BY run_id) "
            "ORDER BY run_id", (end, end)).fetchall()
        return [{**json.loads(r["receipt_json"]), "observed_at": r["observed_at"],
                 "revision": r["revision"]} for r in rows]

    def _append(self, receipt, source=None, *, reinstate=False):
        rid, fingerprint = receipt["run_id"], digest(receipt)
        old = self.db.execute("SELECT * FROM revisions WHERE run_id=? ORDER BY revision DESC LIMIT 1", (rid,)).fetchone()
        if old is not None and old["fingerprint"] == fingerprint:
            return {"run_id": rid, "action": "unchanged", "revision": old["revision"]}
        historical = self.db.execute("SELECT revision FROM revisions WHERE run_id=? AND fingerprint=? LIMIT 1",
                                     (rid, fingerprint)).fetchone()
        if historical is not None:
            # Re-reading a formerly confirmed file must not reverse a withdrawal
            # or replace newer evidence. Reinstatement is explicit and audited.
            return {"run_id": rid, "action": "stale_replay", "revision": old["revision"]}
        if old is not None and not reinstate:
            active = json.loads(old["receipt_json"])
            if active["evidence_id"] != receipt["evidence_id"]:
                history = self.db.execute("SELECT receipt_json FROM revisions WHERE run_id=?", (rid,))
                if any(json.loads(row[0])["evidence_id"] == receipt["evidence_id"] for row in history):
                    # Attribution edits cannot turn an old certificate into new
                    # evidence or bypass an explicit withdrawal.
                    return {"run_id": rid, "action": "stale_replay", "revision": old["revision"]}
        row = self.db.execute(
            "INSERT INTO revisions(run_id,fingerprint,observed_at,source_path,receipt_json) VALUES (?,?,?,?,?)",
            (rid, fingerprint, utc_now(), source, canonical(receipt)))
        return {"run_id": rid, "action": "revised" if old else "added", "revision": row.lastrowid}

    def ingest_files(self, paths, evaluator):
        """Evaluate all inputs before commit; ambiguous same-run revisions abort.

        A malformed replacement withdraws the file's earlier verdict to Unknown.
        Missing files abort: disappearance alone is not an oracle reversal.
        """
        pending, by_run = [], {}
        for value in paths:
            path = Path(value).expanduser().resolve()
            raw = path.read_text(encoding="utf-8")
            previous = self.db.execute("SELECT run_id FROM sources WHERE path=?", (str(path),)).fetchone()
            try:
                result = json.loads(raw, parse_constant=lambda x: (_ for _ in ()).throw(ValueError(x)))
            except ValueError:
                rid = previous["run_id"] if previous else "unreadable:" + hashlib.sha256(str(path).encode()).hexdigest()
                receipt = {"schema": SCHEMA, "run_id": rid,
                           "proposition": {"kind": "passes_validation", "run_id": rid},
                           "verdict": "unknown", "reason": "invalid_result_json",
                           "evidence_id": "sha256:" + hashlib.sha256(raw.encode()).hexdigest(),
                           "claim_refs": [], "claim_refs_role": "attribution_only", "validation": {}}
            else:
                receipt = checked_receipt(result, evaluator)
            if previous and receipt["run_id"] != previous["run_id"]:
                if receipt["reason"] == "missing_or_invalid_run_id":
                    receipt = {**receipt, "run_id": previous["run_id"],
                               "proposition": {"kind": "passes_validation", "run_id": previous["run_id"]}}
                else:
                    raise ValueError(f"result path changed run identity: {path}; use a distinct file")
            fingerprint, rid = digest(receipt), receipt["run_id"]
            if rid in by_run and by_run[rid] != fingerprint:
                raise ValueError(f"conflicting certificates for run {rid} in one batch")
            by_run[rid] = fingerprint
            pending.append((path, receipt))
        reports = []
        with self.db:
            for path, receipt in pending:
                reports.append(self._append(receipt, str(path)))
                self.db.execute("INSERT OR REPLACE INTO sources VALUES (?,?)", (str(path), receipt["run_id"]))
        return reports

    def withdraw(self, rid, reason):
        if not isinstance(reason, str) or not reason.strip():
            raise ValueError("withdrawal needs an audit reason")
        latest = next((r for r in self.snapshots() if r["run_id"] == rid), None)
        if latest is None:
            raise KeyError(f"unknown run: {rid}")
        if latest.get("withdrawn") and latest["reason"] == "withdrawn: " + reason:
            return {"run_id": rid, "action": "unchanged", "revision": latest["revision"]}
        receipt = {k: v for k, v in latest.items() if k not in ("revision", "observed_at")}
        receipt.update(verdict="unknown", reason="withdrawn: " + reason, withdrawn=True)
        receipt["evidence_id"] = "sha256:" + digest(receipt)
        with self.db:
            return self._append(receipt)

    def reinstate(self, revision, reason):
        """Explicitly restore a historical observation, preserving its audit trail."""
        if not isinstance(reason, str) or not reason.strip():
            raise ValueError("reinstatement needs an audit reason")
        row = self.db.execute("SELECT * FROM revisions WHERE revision=?", (revision,)).fetchone()
        if row is None:
            raise KeyError(f"unknown revision: {revision}")
        receipt = json.loads(row["receipt_json"])
        if receipt["verdict"] == "unknown":
            raise ValueError("cannot reinstate an unknown verdict")
        receipt.update(reinstated_from_revision=revision, reinstatement_reason=reason)
        with self.db:
            return self._append(receipt, reinstate=True)


def write_tsv(receipts, path):
    rows, seen = ["run_id\tverdict\tevidence_id"], set()
    for r in receipts:
        rid, verdict, evidence = (r.get(k) for k in ("run_id", "verdict", "evidence_id"))
        if not isinstance(rid, str) or not IDENTIFIER.fullmatch(rid) or rid in seen:
            raise ValueError("invalid or duplicate run identity for Haskell export")
        if verdict not in ("confirmed", "refuted", "unknown"):
            raise ValueError("invalid verdict for Haskell export")
        if not isinstance(evidence, str) or not IDENTIFIER.fullmatch(evidence):
            raise ValueError("invalid evidence identity for Haskell export")
        seen.add(rid)
        rows.append("\t".join((rid, verdict, evidence)))
    Path(path).write_text("\n".join(rows) + "\n", encoding="utf-8")


def verify_haskell(receipts, path, repo):
    write_tsv(receipts, path)
    command = ["runghc", "-isrc", "tools/ExternalOracle.hs", str(Path(path).resolve())]
    command += [r["run_id"] for r in receipts]
    proc = subprocess.run(command, cwd=repo, capture_output=True, text=True, timeout=120, check=True)
    report = json.loads(proc.stdout)
    expected = {r["run_id"]: r["verdict"] for r in receipts}
    actual = {r["run_id"]: r["verdict"] for r in report["runs"]}
    if actual != expected or len(report["runs"]) != len(expected):
        raise ValueError("Python/Haskell oracle verdict mismatch")
    return report
