"""Semantic retrieval with separate exploratory scores and observed evidence.

Graph ``trust`` is an exploratory score and may include pending agent proposals.
Only direct observed receipt metadata supplies checked labels. Embeddings and
score propagation never establish facts. Retrieval coverage is descriptive;
similarity-weighted neighbors do not prove an answer to a user's question.
"""
from __future__ import annotations

import json
import time
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Sequence, Tuple

import numpy as np

import libsql_experimental as libsql

from brain_embed import get_embedder, vec_literal
from oracle_bridge import cutoff
from brain_evidence import direct_evidence, fields as evidence_fields

HERE = Path(__file__).resolve().parent


# What can receive an external FACTUAL consistency verdict. The precise signal is
# `evidence_basis` (orthogonal to claim_type; see record_schema.json): only
# `public_reference` claims are checkable against a citable source. self_reported /
# unquantifiable / not_applicable claims need an owner/quality judgment instead (the
# risk_quality axis), not the consistency oracle. CHECKABLE_TYPES is the coarser
# claim_type fallback used only when evidence_basis is absent (older claims_index).
CHECKABLE_TYPES = {"definitional", "factual_qualitative", "factual_quantitative"}


def _is_checkable(claim_type: str, evidence_basis: str = "") -> bool:
    if evidence_basis:
        return evidence_basis == "public_reference"
    return claim_type in CHECKABLE_TYPES


@dataclass
class Fact:
    id: str
    text: str
    domain: str
    claim_type: str
    source_id: str
    trust: float
    similarity: float = 0.0
    checked: bool = False
    check_verdict: str = "unknown"
    check_value: Optional[float] = None
    check_evidence_id: Optional[str] = None
    check_observed_at: Optional[str] = None
    check_source: Optional[str] = None
    verification_status: str = "unverified"

    @property
    def exploratory_score(self):
        return self.trust


class Brain:
    def __init__(self, con, dim: int, embedder=None, embedder_id: str = ""):
        self.con = con
        self.dim = dim
        self.embedder = embedder
        self.embedder_id = embedder_id
        # Old databases remain readable, with no fabricated evidence provenance.
        self._columns = {r[1] for r in con.cursor().execute("PRAGMA table_info(facts)").fetchall()}

    def _extra_columns(self, prefix=""):
        return ",".join(prefix + name if name in self._columns else "NULL"
                        for name in ("check_provenance", "verification_status"))

    @staticmethod
    def _fact(meta, trust, similarity):
        return Fact(meta["id"], meta["text"], meta["domain"], meta["claim_type"],
                    meta["source_id"], float(trust), similarity=float(similarity),
                    **{key: meta[key] for key in ("checked", "check_verdict", "check_value",
                       "check_evidence_id", "check_observed_at", "check_source", "verification_status")})

    @staticmethod
    def _labels(meta):
        return np.asarray([m["check_value"] if m["checked"] else np.nan for m in meta], dtype=float)

    # ---- construction -------------------------------------------------------
    @classmethod
    def build(cls, claims_index_path: str, graph_path: str, db_path: str,
              *, prefer: str = "model2vec") -> "Brain":
        """(Re)build the brain DB from the current claims index and epistemic graph.

        The join is claims_index key `001-1-a` <-> graph node `claim:001-1-a`. Only
        claims present in the graph get a trust; anything missing is skipped and
        reported rather than silently defaulted. Scores are preserved for exploration;
        only a matching direct receipt observation contributes checked evidence.

        Date-only knowable times mean the end of that UTC day: a publication date
        does not establish intraday availability. Offset timestamps are normalized
        to UTC, matching receipt-journal cutoffs. Unknown times remain unknown.
        """
        ci = json.loads(Path(claims_index_path).read_text())["claims"]
        graph = json.loads(Path(graph_path).read_text())
        trust_by_id = {n["id"].split(":", 1)[1]: float(n["trust"])
                       for n in graph["nodes"] if n["kind"] == "claim"}

        embedder = get_embedder(prefer=prefer)
        dim = embedder.dim

        facts, texts, missing = [], [], []
        for cid, c in ci.items():
            if cid not in trust_by_id:
                missing.append(cid)
                continue
            facts.append((cid, c["text"], c.get("domain", ""),
                          c.get("claim_type", ""), c.get("source_id", ""),
                          trust_by_id[cid], c.get("evidence_basis", ""),
                          cutoff(c.get("knowable_time")), c.get("event_time"),
                          json.dumps(direct_evidence(cid, c, graph)),
                          c.get("verification_status", "unverified")))
            texts.append(c["text"])
        if missing:
            print(f"[brain] {len(missing)} claim(s) had no graph trust, skipped: "
                  f"{missing[:5]}{'...' if len(missing) > 5 else ''}")

        embs = embedder.encode(texts) if texts else np.zeros((0, dim), np.float32)

        p = Path(db_path)
        if p.exists():
            p.unlink()
        con = libsql.connect(str(p))
        cur = con.cursor()
        cur.execute(f"""CREATE TABLE facts (
            id TEXT PRIMARY KEY, text TEXT, domain TEXT, claim_type TEXT,
            evidence_basis TEXT, source_id TEXT, trust REAL,
            knowable_time TEXT, event_time TEXT, emb F32_BLOB({dim}),
            check_provenance TEXT, verification_status TEXT)""")
        cur.execute("CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT)")
        for (cid, text, dom, ct, sid, tr, eb, kt, et, cp, vs), row in zip(facts, embs):
            cur.execute(
                "INSERT INTO facts(id,text,domain,claim_type,evidence_basis,source_id,"
                "trust,knowable_time,event_time,emb,check_provenance,verification_status)"
                " VALUES (?,?,?,?,?,?,?,?,?,vector32(?),?,?)",
                (cid, text, dom, ct, eb, sid, tr, kt, et, vec_literal(row), cp, vs))
        for k, v in {"embedder_id": embedder.id, "dim": str(dim),
                     "n_facts": str(len(facts)),
                     "built_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                     "claims_index": str(claims_index_path),
                     "graph": str(graph_path), "evidence_schema": "direct-observation-v1"}.items():
            cur.execute("INSERT INTO meta(key,value) VALUES (?,?)", (k, v))
        # ANN index for scalable retrieval (brute-force cosine is exact and used by
        # default on this small corpus; the index is here for when it grows).
        cur.execute("CREATE INDEX facts_ann ON facts(libsql_vector_idx(emb))")
        con.commit()
        return cls(con, dim, embedder, embedder.id)

    @classmethod
    def open(cls, db_path: str, *, load_embedder: bool = True) -> "Brain":
        con = libsql.connect(str(db_path))
        cur = con.cursor()
        meta = {k: v for k, v in cur.execute("SELECT key,value FROM meta").fetchall()}
        dim = int(meta.get("dim", "0"))
        embedder = None
        eid = meta.get("embedder_id", "")
        if load_embedder:
            prefer = "model2vec" if eid.startswith("model2vec") else "hashing"
            embedder = get_embedder(prefer=prefer, dim=dim)
            if embedder.id != eid:
                print(f"[brain] warning: query embedder '{embedder.id}' != build "
                      f"embedder '{eid}'; query vectors may be incomparable")
        return cls(con, dim, embedder, eid)

    # ---- internal readback --------------------------------------------------
    def _all(self, as_of: Optional[str] = None
             ) -> Tuple[List[str], np.ndarray, np.ndarray, List[dict]]:
        """All facts, optionally filtered to those knowable as of a date (no
        lookahead): a fact is visible only if knowable_time <= as_of. A fact with an
        unknown knowable_time is excluded under an as-of query (we cannot prove it was
        knowable) -- the conservative, no-lookahead-safe choice. See TEMPORAL.md."""
        as_of = cutoff(as_of)
        rows = self.con.cursor().execute(
            "SELECT id,text,domain,claim_type,evidence_basis,source_id,trust,"
            "knowable_time,event_time,emb," + self._extra_columns() + " FROM facts"
        ).fetchall()
        ids, meta, trusts, embs = [], [], [], []
        for r in rows:
            # Normalize on read too, for legacy DBs with dates or offset times.
            knowable_time = cutoff(r[7])
            if as_of is not None and (knowable_time is None or knowable_time > as_of):
                continue
            check = evidence_fields(r[10], as_of)
            status = r[11] or "unverified"
            if as_of is not None and status == "observed_oracle_receipt" and not check["check_source"]:
                status = "unverified_as_of"
            ids.append(r[0])
            meta.append({"id": r[0], "text": r[1], "domain": r[2],
                         "claim_type": r[3], "evidence_basis": r[4] or "",
                         "source_id": r[5], "knowable_time": knowable_time, "event_time": r[8],
                         "verification_status": status,
                         **check})
            # Graph proposal scores have no observation history. Do not backdate
            # the current scalar into historical rankings or reports. The only
            # dated score available here is the direct observed signed verdict.
            trusts.append(float(r[6]) if as_of is None else (check["check_value"] or 0.0))
            embs.append(np.frombuffer(r[9], dtype=np.float32))
        E = np.vstack(embs) if embs else np.zeros((0, self.dim), np.float32)
        return ids, E, np.asarray(trusts, dtype=np.float64), meta

    def _embed_query(self, text: str) -> np.ndarray:
        if self.embedder is None:
            raise RuntimeError("no embedder loaded; open with load_embedder=True")
        return self.embedder.encode([text])[0]

    # ---- retrieval ----------------------------------------------------------
    def retrieve(self, query: str, k: int = 5, *, trust_weighted: bool = False,
                 ann: bool = False, as_of: Optional[str] = None) -> List[Fact]:
        """Semantic nearest claims with exploratory scores and direct evidence.

        `trust_weighted=True` re-ranks by similarity*(0.5+0.5*trust), using the
        exploratory graph score. This ranking does not confer checked status. `ann=True` uses the DiskANN index (approximate, for scale);
        default is exact brute-force cosine. `as_of` restricts to facts knowable by
        that date (knowable_time <= as_of; no lookahead -- see TEMPORAL.md).

        Historical queries rank only eligible facts with exact vector comparison,
        including when ``ann=True``: future facts cannot influence candidate selection.
        Dates include the full UTC day; timestamps must include their timezone.
        Historical scores use only then-observed direct verdicts, because proposal
        scores have no observation journal and cannot safely be backdated.
        """
        qv = self._embed_query(query)
        as_of = cutoff(as_of)
        kk = max(k * 3, k)
        if as_of is not None:
            # Filter before ranking, including for ANN requests. Future facts must
            # not affect candidate selection or crowd known facts out of a query.
            ids, E, trusts, meta = self._all(as_of=as_of)
            sims = E @ qv
            order = np.argsort(-sims, kind="stable")[:kk]
            facts = [self._fact(meta[j], trusts[j], sims[j]) for j in order]
            if trust_weighted:
                facts.sort(key=lambda f: -(f.similarity * (0.5 + 0.5 * f.trust)))
            return facts[:k]
        cur = self.con.cursor()
        qlit = vec_literal(qv)
        if ann:
            params = (qlit, qlit, kk)
            rows = cur.execute(
                "SELECT f.id,f.text,f.domain,f.claim_type,f.source_id,f.trust,"
                " vector_distance_cos(f.emb, vector32(?)) AS dist," + self._extra_columns("f.") + " "
                "FROM vector_top_k('facts_ann', vector32(?), ?) AS v "
                "JOIN facts f ON f.rowid=v.id ORDER BY dist", params).fetchall()
        else:
            params = (qlit, kk)
            rows = cur.execute(
                "SELECT id,text,domain,claim_type,source_id,trust,"
                " vector_distance_cos(emb, vector32(?)) AS dist," + self._extra_columns() + " "
                "FROM facts ORDER BY dist LIMIT ?", params).fetchall()
        facts = [Fact(r[0], r[1], r[2], r[3], r[4], float(r[5]),
                      similarity=1.0 - float(r[6]), **evidence_fields(r[7]),
                      verification_status=r[8] or "unverified") for r in rows]
        if trust_weighted:
            facts.sort(key=lambda f: -(f.similarity * (0.5 + 0.5 * f.trust)))
        return facts[:k]

    def neighbors(self, fact_id: str, k: int = 5) -> List[Fact]:
        """The k semantically nearest OTHER facts to a stored fact (graph-like walk)."""
        ids, E, trusts, meta = self._all()
        if fact_id not in ids:
            raise KeyError(fact_id)
        i = ids.index(fact_id)
        sims = E @ E[i]
        order = np.argsort(-sims)
        out = []
        for j in order:
            if j == i:
                continue
            m = meta[j]
            out.append(self._fact(m, trusts[j], sims[j]))
            if len(out) >= k:
                break
        return out

    # ---- synthetic inference ------------------------------------------------
    @staticmethod
    def _predict_from(sims: np.ndarray, trusts: np.ndarray, k: int,
                      floor: float = 0.0) -> Tuple[float, float]:
        """Similarity-weighted trust of the top-k neighbours. Returns (pred, mass)."""
        order = np.argsort(-sims)[:k]
        w = np.clip(sims[order] - floor, 0.0, None)
        mass = float(w.sum())
        if mass <= 1e-9:
            return float("nan"), 0.0
        return float((w * trusts[order]).sum() / mass), mass

    def infer_trust(self, query: str, k: int = 8, *, with_caveat: bool = True,
                    as_of: Optional[str] = None) -> dict:
        """Conjecture a signed receipt outcome from checked neighbors only.

        Leave-one-out diagnostics describe this local dataset; they neither
        establish out-of-distribution confidence nor prove an arbitrary query.
        """
        qv = self._embed_query(query)
        ids, E, trusts, meta = self._all(as_of=as_of)
        labels = self._labels(meta)
        checked = np.where(~np.isnan(labels))[0]
        sims = E[checked] @ qv
        pred, mass = self._predict_from(sims, labels[checked], k)
        order = checked[np.argsort(-sims)[:k]]
        out = {"query": query, "predicted_trust": None if np.isnan(pred) else pred, "support_mass": mass,
               "k": k, "status": "conjectured", "prediction_confidence": None,
               "neighbors": [{"id": ids[j], "similarity": float(E[j] @ qv),
                              "trust": float(trusts[j]), "exploratory_score": float(trusts[j]),
                              "text": meta[j]["text"],
                              **{key: meta[j][key] for key in ("checked", "check_verdict", "check_value",
                                 "check_evidence_id", "check_observed_at", "check_source")}}
                             for j in order]}
        if with_caveat:
            cal = self.calibrate(as_of=as_of)
            out["imputation_licensed"] = False
            out["loo_signal_detected"] = cal.get("loo_signal_detected", False)
            out["caveat"] = cal.get("verdict")
        return out

    @staticmethod
    def _licensed(m: dict) -> Tuple[bool, str]:
        """Honest bar for whether naive trust-imputation is warranted.

        A fractionally-positive skill alone is noise. Require the predictor to beat
        the mean by a real margin AND rank-correlate positively AND get the sign
        right more often than a coin. Anything less is reported as a null.
        """
        sk = m.get("skill")
        r = m.get("pearson_r")
        sg = m.get("sign_agreement")
        if sk is None:
            return False, "skill unavailable"
        if sk >= 0.05 and (r is not None and r >= 0.15) and (sg is not None and sg >= 0.5):
            return True, (f"skill={sk} with pearson_r={r}, sign_agreement={sg}: "
                          "semantic neighbours carry trust signal")
        return False, (f"skill={sk}, pearson_r={r}, sign_agreement={sg}: within noise "
                       "of the mean baseline -- trust is not semantically smooth "
                       "(it is earned per-claim by external check), so the brain "
                       "does NOT impute trust from topic")

    def calibrate(self, k: Optional[int] = None, *, as_of: Optional[str] = None) -> dict:
        """Leave-one-out diagnostic on direct observed +/-1 labels only.

        Missing evidence is excluded, never treated as a zero-valued label.
        Graph proposal scores are not calibration targets. The fixed k rule and
        sweep report local fit; no held-out prediction-risk license is asserted.
        """
        ids, E, scores, meta = self._all(as_of=as_of)
        n = len(ids)
        trusts = self._labels(meta)
        checked_idx = np.where(~np.isnan(trusts))[0]
        k_reg = k if k is not None else max(2, round(len(checked_idx) ** 0.5))
        if not isinstance(k_reg, int) or k_reg < 1:
            raise ValueError("k must be a positive integer")

        def calc(idx: np.ndarray, kk: int) -> dict:
            sub_t = trusts[idx]
            sub_E = E[idx]
            m = len(idx)
            if m < 3:
                return {"k": kk, "n_predicted": 0, "skill": None}
            Ss = sub_E @ sub_E.T
            np.fill_diagonal(Ss, -np.inf)
            preds = np.array([self._predict_from(Ss[i], sub_t, kk)[0] for i in range(m)])
            ok = ~np.isnan(preds)
            if not ok.any():
                return {"k": kk, "n_predicted": 0, "skill": None}
            a, p = sub_t[ok], preds[ok]
            base = np.array([np.delete(sub_t, i).mean() for i in range(m)])[ok]
            mae = float(np.mean(np.abs(p - a)))
            mae_base = float(np.mean(np.abs(base - a)))
            corr = (float(np.corrcoef(p, a)[0, 1])
                    if len(a) > 2 and np.std(p) > 1e-9 and np.std(a) > 1e-9 else float("nan"))
            sign = float(np.mean(np.sign(p) == np.sign(a)))
            return {"k": kk, "n_predicted": int(ok.sum()), "mae": round(mae, 4),
                    "mae_baseline": round(mae_base, 4),
                    "skill": round(1.0 - mae / mae_base, 4) if mae_base > 1e-9 else None,
                    "pearson_r": None if np.isnan(corr) else round(corr, 4),
                    "sign_agreement": round(sign, 4)}

        headline = calc(checked_idx, k_reg)
        headline.update({"n": n, "n_checked": int(len(checked_idx)),
                         "status": "ok" if len(checked_idx) >= 3 else "insufficient",
                         "preregistered_k": k_reg,
                         "frac_unchecked": round(1 - len(checked_idx) / n, 4) if n else None,
                         "label_basis": "direct_observed_receipts"})
        headline["sweep"] = [calc(checked_idx, kk) for kk in sorted({3, 5, 8, 12, k_reg})
                             if kk < len(checked_idx)]
        headline["checked_only"] = calc(checked_idx, k_reg)
        signal, why = self._licensed(headline)
        headline["loo_signal_detected"] = signal
        headline["licensed"] = False
        headline["verdict"] = ("Checked-label leave-one-out diagnostic: " + why +
                               ". This does not establish held-out prediction confidence or query entailment.")
        return headline

    # ---- directed exploration (proposals) ----------------------------------
    def explore_frontier(self, k: int = 5, knn: int = 8, mode: str = "all", *,
                         as_of: Optional[str] = None) -> List[dict]:
        """Rank stored facts by how informative an external check on them would be.

        Active-inference flavour, tuned to what this trust field actually looks like
        (mostly unchecked, not semantically smooth):

          * UNCHECKED (no direct observed verdict) and CENTRAL -> high leverage: an external check here
            resolves a dense, currently-unknown neighbourhood. This is the primary
            frontier, since most claims are unchecked.
          * CHECKED and ISOLATED -> worth corroboration: a lone trusted/distrusted
            claim with little nearby support.
          * CHECKED with DISAGREEING neighbours -> contested: worth a tie-breaking check.

        `mode` selects which frontier: 'gaps' (unchecked-and-central only),
        'contested' (checked with differing nearby checked verdicts), or 'all'
        (also includes checked-isolated suggestions, ranked together -- note contested
        scores tend to dominate, so use 'gaps' to see the unchecked opportunity that
        makes up most of the corpus). `reason` names which applies. Output is a
        PROPOSED to-check list -- what an external checker should look at next --
        never a judgement on the facts.
        With ``as_of``, future facts contribute neither candidates nor centrality.
        """
        ids, E, trusts, meta = self._all(as_of=as_of)
        n = len(ids)
        S = E @ E.T
        np.fill_diagonal(S, -np.inf)
        labels = self._labels(meta)
        checked = ~np.isnan(labels)
        out = []
        for i in range(n):
            order = np.argsort(-S[i])[:knn]
            w = np.clip(S[i][order], 0.0, None)
            mass = float(w.sum())
            centrality = float(mass / max(knn, 1))
            isolation = float(1.0 / (1.0 + mass))
            # neighbourhood trust disagreement, over CHECKED neighbours only
            cn = order[checked[order]]
            wcn = np.clip(S[i][cn], 0.0, None)
            if wcn.sum() > 1e-9:
                mean = float((wcn * labels[cn]).sum() / wcn.sum())
                var = float((wcn * (labels[cn] - mean) ** 2).sum() / wcn.sum())
            else:
                var = 0.0
            if not checked[i]:
                score = centrality            # unchecked: value rises with centrality
                reason = "unchecked_and_central"
            else:
                score = 0.5 * isolation + var  # checked: isolation and/or contestation
                reason = "checked_contested" if var > 0.05 else "checked_isolated"
            ctype = meta[i]["claim_type"]
            ebasis = meta[i]["evidence_basis"]
            out.append({"id": ids[i], "text": meta[i]["text"], "domain": meta[i]["domain"],
                        "claim_type": ctype, "evidence_basis": ebasis,
                        "externally_checkable": _is_checkable(ctype, ebasis),
                        "trust": float(trusts[i]), "exploratory_score": float(trusts[i]),
                        **{key: meta[i][key] for key in ("checked", "check_verdict", "check_value",
                           "check_evidence_id", "check_observed_at", "check_source", "verification_status")},
                        "centrality": round(centrality, 4), "isolation": round(isolation, 4),
                        "neighbor_trust_var": round(var, 4), "neighbor_checked_verdict_var": round(var, 4),
                        "explore_score": round(score, 4), "reason": reason,
                        "status": "proposed_to_check"})
        if mode == "gaps":
            out = [d for d in out if not d["checked"]]
        elif mode == "contested":
            out = [d for d in out if d["reason"] == "checked_contested"]
        out.sort(key=lambda d: -d["explore_score"])
        return out[:k]

    def bridge_hypotheses(self, k: int = 5, *, trust_min: float = 0.3,
                          lo: float = 0.25, hi: float = 0.75,
                          as_of: Optional[str] = None) -> List[dict]:
        """Propose syntheses: two credible facts, different domains, mid-distance.

        Both endpoints need directly confirmed receipts plus an exploratory score
        >= trust_min; they must sit in
        DIFFERENT domains; and be semantically adjacent but not near-duplicate
        (lo < cosine < hi). Such pairs are candidate connective hypotheses worth
        forming and then checking -- the generative, exploratory edge of the brain.
        Proposals only; forming/deciding the hypothesis is downstream and external.
        """
        ids, E, trusts, meta = self._all(as_of=as_of)
        n = len(ids)
        pairs = []
        for i in range(n):
            if meta[i]["check_verdict"] != "confirmed" or trusts[i] < trust_min:
                continue
            for j in range(i + 1, n):
                if (meta[j]["check_verdict"] != "confirmed" or trusts[j] < trust_min
                        or meta[i]["domain"] == meta[j]["domain"]):
                    continue
                sim = float(E[i] @ E[j])
                if lo < sim < hi:
                    pairs.append({"a": ids[i], "a_text": meta[i]["text"],
                                  "a_domain": meta[i]["domain"],
                                  "b": ids[j], "b_text": meta[j]["text"],
                                  "b_domain": meta[j]["domain"],
                                  "a_evidence_id": meta[i]["check_evidence_id"],
                                  "b_evidence_id": meta[j]["check_evidence_id"],
                                  "similarity": round(sim, 4),
                                  "min_trust": round(float(min(trusts[i], trusts[j])), 4),
                                  "score": round(sim * float(min(trusts[i], trusts[j])), 4),
                                  "status": "proposed_hypothesis"})
        pairs.sort(key=lambda d: -d["score"])
        return pairs[:k]

    def answer(self, question: str, k: int = 8, min_sim: float = 0.25,
               as_of: Optional[str] = None) -> dict:
        """Return cited related claims and their evidence coverage.

        Confirmed/refuted describes each cited proposition, not its relation of
        entailment to the question. Semantic similarity cannot infer that relation.
        """
        retrieved = self.retrieve(question, k=k, as_of=as_of)
        facts = [f for f in retrieved if f.similarity >= min_sim]

        def cite(f):
            return {"id": f.id, "similarity": round(f.similarity, 4),
                    "trust": round(f.trust, 4), "exploratory_score": round(f.trust, 4),
                    "domain": f.domain, "text": f.text,
                    **{key: getattr(f, key) for key in ("checked", "check_verdict", "check_value",
                       "check_evidence_id", "check_observed_at", "check_source", "verification_status")}}

        confirmed = [f for f in facts if f.check_verdict == "confirmed"]
        refuted = [f for f in facts if f.check_verdict == "refuted"]
        unchecked = [f for f in facts if not f.checked]
        checked = confirmed + refuted
        coverage = round(len(checked) / len(facts), 4) if facts else None
        next_check = None
        if unchecked:
            frontier = self.explore_frontier(k=200, mode="gaps", as_of=as_of)
            rank = {d["id"]: d for d in frontier}
            best = max(unchecked, key=lambda f: rank.get(f.id, {}).get("centrality", 0.0))
            next_check = {"id": best.id, "text": best.text, "domain": best.domain,
                          "centrality": rank.get(best.id, {}).get("centrality"),
                          "why": "no direct observed verdict; relevant to this question"}
        stance = ("no_relevant_facts" if not facts else
                  "unknown_no_checked_evidence" if not checked else "related_checked_evidence")
        return {"question": question, "stance": stance, "answer_status": "not_inferred",
                "proof_entailment": False, "prediction_confidence": None,
                "checked_fraction": coverage, "checked_retrieval_coverage": coverage,
                "licensed_locally": False, "stance_score": None,
                "min_sim": min_sim, "as_of": as_of, "n_retrieved": len(retrieved),
                "n_relevant": len(facts), "n_checked": len(checked),
                "confirmed_related": [cite(f) for f in confirmed],
                "refuted_related": [cite(f) for f in refuted],
                "unchecked_relevant": [cite(f) for f in unchecked],
                "proposed_next_check": next_check,
                "caveat": ("This is a retrieval report. Confirmed/refuted applies only to each "
                           "cited proposition. Coverage is the fraction with direct observed evidence; "
                           "it is neither proof of an answer nor calibrated prediction confidence. "
                           "Graph scores remain exploratory, including pending reference proposals.")}

    def learning_curve(self, sizes: Sequence[int] = (5, 10, 15, 20),
                       k: int = 5, repeats: int = 40, seed: int = 0, *,
                       as_of: Optional[str] = None) -> dict:
        """Resampling diagnostic using direct observed receipt labels only.

        More observed labels can improve this local prediction diagnostic; the
        curve is not evidence of future efficacy or a confidence guarantee.
        """
        ids, E, scores, meta = self._all(as_of=as_of)
        trusts = self._labels(meta)
        checked = np.where(~np.isnan(trusts))[0]
        if len(checked) < max(sizes) + 1:
            sizes = tuple(s for s in sizes if s < len(checked))
        rng = np.random.default_rng(seed)
        Ec, tc = E[checked], trusts[checked]
        nc = len(checked)
        curve = []
        for m in sizes:
            skills = []
            for _ in range(repeats):
                known = rng.choice(nc, size=m, replace=False)
                held = np.setdiff1d(np.arange(nc), known)
                if len(held) < 2:
                    continue
                errs, base_errs = [], []
                base = float(tc[known].mean())
                for h in held:
                    sims = Ec[known] @ Ec[h]
                    pred, mass = self._predict_from(sims, tc[known], k)
                    if np.isnan(pred):
                        pred = base
                    errs.append(abs(pred - tc[h]))
                    base_errs.append(abs(base - tc[h]))
                mae, maeb = float(np.mean(errs)), float(np.mean(base_errs))
                if maeb > 1e-9:
                    skills.append(1.0 - mae / maeb)
            mean_skill = round(float(np.mean(skills)), 4) if skills else None
            curve.append({"m": int(m), "mean_skill": mean_skill,
                          "n_samples": len(skills)})
        pts = [c["mean_skill"] for c in curve if c["mean_skill"] is not None]
        return {"checked_n": int(nc), "k": k, "repeats": repeats, "curve": curve,
                "monotone_up": all(pts[i] <= pts[i + 1] + 1e-9 for i in range(len(pts) - 1))
                               if len(pts) > 1 else None}

    def stats(self, *, as_of: Optional[str] = None) -> dict:
        ids, E, trusts, meta = self._all(as_of=as_of)
        doms = {}
        for m, t in zip(meta, trusts):
            doms.setdefault(m["domain"], []).append(t)
        return {"embedder_id": self.embedder_id, "dim": self.dim, "n_facts": len(ids),
                "trust_mean": round(float(trusts.mean()), 4) if len(ids) else None,
                "trust_min": round(float(trusts.min()), 4) if len(ids) else None,
                "trust_max": round(float(trusts.max()), 4) if len(ids) else None,
                "domains": len(doms), "n_checked": sum(m["checked"] for m in meta),
                "score_basis": "exploratory_graph_score"}
