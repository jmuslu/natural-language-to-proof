"""The fact brain: a semantic-trust manifold over the corpus, in a libSQL vector DB.

WHAT IT IS. Every corpus claim becomes a *fact node*: its text embedded to a unit
vector (geometry) plus its trust taken verbatim from the epistemic graph (an
externally-anchored scalar this module never edits). Stored in libSQL -- the Rust
SQLite fork with native vector search -- so nearest-neighbour retrieval and
directed exploration run as first-class DB operations.

THE DISCIPLINE, restated so it cannot drift:
  * Embeddings position facts; they never create trust.
  * Trust comes only from `epistemic_graph.py`, which grants it only from external
    checks. The brain reads that field; it does not write to it.
  * Synthetic inference (predicting a fact's trust from its semantic neighbours) is
    a CONJECTURE. Its only warrant is `calibrate()`: leave-one-out prediction graded
    against the graph's real trust, versus a mean-trust null -- the same "skill vs
    null" test the backtest oracle uses. If it beats the null, the manifold carries
    trust-relevant structure and inference is licensed; if not, the brain says so.
  * Exploration outputs (`explore_frontier`, `bridge_hypotheses`) are PROPOSALS for
    what to check next, never verdicts.

So the brain proposes (retrieval, inference, exploration); external checks dispose.
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

HERE = Path(__file__).resolve().parent


@dataclass
class Fact:
    id: str
    text: str
    domain: str
    claim_type: str
    source_id: str
    trust: float
    similarity: float = 0.0  # populated by retrieval / neighbour queries


class Brain:
    def __init__(self, con, dim: int, embedder=None, embedder_id: str = ""):
        self.con = con
        self.dim = dim
        self.embedder = embedder
        self.embedder_id = embedder_id

    # ---- construction -------------------------------------------------------
    @classmethod
    def build(cls, claims_index_path: str, graph_path: str, db_path: str,
              *, prefer: str = "model2vec") -> "Brain":
        """(Re)build the brain DB from the current claims index and epistemic graph.

        The join is claims_index key `001-1-a` <-> graph node `claim:001-1-a`. Only
        claims present in the graph get a trust; anything missing is skipped and
        reported rather than silently defaulted (trust must be earned externally).
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
                          trust_by_id[cid]))
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
            source_id TEXT, trust REAL, emb F32_BLOB({dim}))""")
        cur.execute("CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT)")
        for (cid, text, dom, ct, sid, tr), row in zip(facts, embs):
            cur.execute(
                "INSERT INTO facts(id,text,domain,claim_type,source_id,trust,emb)"
                " VALUES (?,?,?,?,?,?,vector32(?))",
                (cid, text, dom, ct, sid, tr, vec_literal(row)))
        for k, v in {"embedder_id": embedder.id, "dim": str(dim),
                     "n_facts": str(len(facts)),
                     "built_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                     "claims_index": str(claims_index_path),
                     "graph": str(graph_path)}.items():
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
    def _all(self) -> Tuple[List[str], np.ndarray, np.ndarray, List[dict]]:
        rows = self.con.cursor().execute(
            "SELECT id,text,domain,claim_type,source_id,trust,emb FROM facts"
        ).fetchall()
        ids, meta, trusts, embs = [], [], [], []
        for r in rows:
            ids.append(r[0])
            meta.append({"id": r[0], "text": r[1], "domain": r[2],
                         "claim_type": r[3], "source_id": r[4]})
            trusts.append(float(r[5]))
            embs.append(np.frombuffer(r[6], dtype=np.float32))
        E = np.vstack(embs) if embs else np.zeros((0, self.dim), np.float32)
        return ids, E, np.asarray(trusts, dtype=np.float64), meta

    def _embed_query(self, text: str) -> np.ndarray:
        if self.embedder is None:
            raise RuntimeError("no embedder loaded; open with load_embedder=True")
        return self.embedder.encode([text])[0]

    # ---- retrieval ----------------------------------------------------------
    def retrieve(self, query: str, k: int = 5, *, trust_weighted: bool = False,
                 ann: bool = False) -> List[Fact]:
        """Semantic nearest facts to `query`, each carrying its external trust.

        `trust_weighted=True` re-ranks by similarity*(0.5+0.5*trust) so a query
        surfaces facts that are both on-topic and externally credible rather than
        merely on-topic. `ann=True` uses the DiskANN index (approximate, for scale);
        default is exact brute-force cosine.
        """
        qv = self._embed_query(query)
        cur = self.con.cursor()
        if ann:
            rows = cur.execute(
                "SELECT f.id,f.text,f.domain,f.claim_type,f.source_id,f.trust,"
                " vector_distance_cos(f.emb, vector32(?)) AS dist "
                "FROM vector_top_k('facts_ann', vector32(?), ?) AS v "
                "JOIN facts f ON f.id=v.id ORDER BY dist",
                (vec_literal(qv), vec_literal(qv), max(k * 3, k))).fetchall()
        else:
            rows = cur.execute(
                "SELECT id,text,domain,claim_type,source_id,trust,"
                " vector_distance_cos(emb, vector32(?)) AS dist "
                "FROM facts ORDER BY dist LIMIT ?",
                (vec_literal(qv), max(k * 3, k))).fetchall()
        facts = [Fact(r[0], r[1], r[2], r[3], r[4], float(r[5]),
                      similarity=1.0 - float(r[6])) for r in rows]
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
            out.append(Fact(m["id"], m["text"], m["domain"], m["claim_type"],
                            m["source_id"], float(trusts[j]), similarity=float(sims[j])))
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

    def infer_trust(self, query: str, k: int = 8, *, with_caveat: bool = True) -> dict:
        """CONJECTURE a trust for arbitrary text from its nearest facts' trust.

        This is synthetic inference: it interpolates the externally-anchored trust
        field at a new point. It is only as trustworthy as `calibrate()` says the
        field is, so by default it carries that verdict inline -- a predicted trust
        must never travel without the caveat that says whether imputation is even
        licensed on this corpus. The result is a proposal for an external check to
        confirm or refute, never a decision.
        """
        qv = self._embed_query(query)
        ids, E, trusts, meta = self._all()
        sims = E @ qv
        pred, mass = self._predict_from(sims, trusts, k)
        order = np.argsort(-sims)[:k]
        out = {"query": query, "predicted_trust": pred, "support_mass": mass,
               "k": k, "status": "conjectured",
               "neighbors": [{"id": ids[j], "similarity": float(sims[j]),
                              "trust": float(trusts[j]), "text": meta[j]["text"]}
                             for j in order]}
        if with_caveat:
            cal = self.calibrate()
            out["imputation_licensed"] = cal.get("licensed")
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

    def calibrate(self, k: Optional[int] = None) -> dict:
        """External check on the brain: does semantic structure predict trust?

        Leave-one-out -- predict each fact's trust from its neighbours (excluding
        itself), compare to the graph's real trust. Headline uses a pre-registered
        k = round(sqrt(n)) so k is not tuned to flatter the result; a small sweep is
        reported alongside for transparency, not for cherry-picking. Baseline is the
        leave-one-out global mean (the trivial predictor). `skill` = 1 - MAE/MAE_base.
        `licensed` applies an honest bar (see `_licensed`): a fractionally positive
        skill is NOT enough. We also report `frac_unchecked` (claims at trust==0, not
        yet externally checked) and a `checked_only` re-run over trust!=0 claims,
        because a field dominated by unknowns is the usual reason imputation fails.
        """
        ids, E, trusts, _ = self._all()
        n = len(ids)
        if n < 3:
            return {"status": "insufficient", "n": n}

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

        all_idx = np.arange(n)
        checked_idx = np.where(trusts != 0.0)[0]
        k_reg = k if k is not None else max(2, round(n ** 0.5))

        headline = calc(all_idx, k_reg)
        headline["preregistered_k"] = k_reg
        headline["frac_unchecked"] = round(float(np.mean(trusts == 0.0)), 4)
        headline["n_checked"] = int(len(checked_idx))
        headline["sweep"] = [calc(all_idx, kk) for kk in sorted({3, 5, 8, 12, k_reg}) if kk < n]
        headline["checked_only"] = calc(checked_idx, min(k_reg, max(2, len(checked_idx) - 1)))
        lic, why = self._licensed(headline)
        headline["licensed"] = lic
        headline["verdict"] = why
        return headline

    # ---- directed exploration (proposals) ----------------------------------
    def explore_frontier(self, k: int = 5, knn: int = 8, mode: str = "all") -> List[dict]:
        """Rank stored facts by how informative an external check on them would be.

        Active-inference flavour, tuned to what this trust field actually looks like
        (mostly unchecked, not semantically smooth):

          * UNCHECKED (trust==0) and CENTRAL -> high leverage: an external check here
            resolves a dense, currently-unknown neighbourhood. This is the primary
            frontier, since most claims are unchecked.
          * CHECKED and ISOLATED -> worth corroboration: a lone trusted/distrusted
            claim with little nearby support.
          * CHECKED with DISAGREEING neighbours -> contested: worth a tie-breaking check.

        `mode` selects which frontier: 'gaps' (unchecked-and-central only),
        'contested' (checked only), or 'all' (both, ranked together -- note contested
        scores tend to dominate, so use 'gaps' to see the unchecked opportunity that
        makes up most of the corpus). `reason` names which applies. Output is a
        PROPOSED to-check list -- what an external checker should look at next --
        never a judgement on the facts.
        """
        ids, E, trusts, meta = self._all()
        n = len(ids)
        S = E @ E.T
        np.fill_diagonal(S, -np.inf)
        checked = trusts != 0.0
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
                mean = float((wcn * trusts[cn]).sum() / wcn.sum())
                var = float((wcn * (trusts[cn] - mean) ** 2).sum() / wcn.sum())
            else:
                var = 0.0
            if trusts[i] == 0.0:
                score = centrality            # unchecked: value rises with centrality
                reason = "unchecked_and_central"
            else:
                score = 0.5 * isolation + var  # checked: isolation and/or contestation
                reason = "checked_contested" if var > 0.05 else "checked_isolated"
            out.append({"id": ids[i], "text": meta[i]["text"], "domain": meta[i]["domain"],
                        "trust": float(trusts[i]), "checked": bool(checked[i]),
                        "centrality": round(centrality, 4), "isolation": round(isolation, 4),
                        "neighbor_trust_var": round(var, 4),
                        "explore_score": round(score, 4), "reason": reason,
                        "status": "proposed_to_check"})
        if mode == "gaps":
            out = [d for d in out if not d["checked"]]
        elif mode == "contested":
            out = [d for d in out if d["checked"]]
        out.sort(key=lambda d: -d["explore_score"])
        return out[:k]

    def bridge_hypotheses(self, k: int = 5, *, trust_min: float = 0.3,
                          lo: float = 0.25, hi: float = 0.75) -> List[dict]:
        """Propose syntheses: two credible facts, different domains, mid-distance.

        Both endpoints must be externally trusted (>= trust_min); they must sit in
        DIFFERENT domains; and be semantically adjacent but not near-duplicate
        (lo < cosine < hi). Such pairs are candidate connective hypotheses worth
        forming and then checking -- the generative, exploratory edge of the brain.
        Proposals only; forming/deciding the hypothesis is downstream and external.
        """
        ids, E, trusts, meta = self._all()
        n = len(ids)
        pairs = []
        for i in range(n):
            if trusts[i] < trust_min:
                continue
            for j in range(i + 1, n):
                if trusts[j] < trust_min or meta[i]["domain"] == meta[j]["domain"]:
                    continue
                sim = float(E[i] @ E[j])
                if lo < sim < hi:
                    pairs.append({"a": ids[i], "a_text": meta[i]["text"],
                                  "a_domain": meta[i]["domain"],
                                  "b": ids[j], "b_text": meta[j]["text"],
                                  "b_domain": meta[j]["domain"],
                                  "similarity": round(sim, 4),
                                  "min_trust": round(float(min(trusts[i], trusts[j])), 4),
                                  "score": round(sim * float(min(trusts[i], trusts[j])), 4),
                                  "status": "proposed_hypothesis"})
        pairs.sort(key=lambda d: -d["score"])
        return pairs[:k]

    def answer(self, question: str, k: int = 8, min_sim: float = 0.25) -> dict:
        """Query-driven synthesis: what do the EXTERNALLY-CHECKED facts say here?

        The capstone that ties retrieval + inference + exploration together. It
        retrieves the semantically relevant facts, drops those below `min_sim` (a
        relevance gate so the stance is not driven by loosely-related facts; the
        default suits the model2vec embedder's similarity scale), splits the rest by
        external trust into supporting / cautioning / still-unchecked, and reports a
        stance that is the similarity-weighted trust of the *checked* relevant facts
        only. Crucially it never claims the answer is true: it reports what the
        checked corpus supports, how well-checked this corner of the corpus is
        (`checked_fraction` -- a query-local calibration), and the single external
        check that would most resolve the question (the most central unchecked
        relevant fact). Every element cites claim ids and trust. Proposal, not verdict.
        """
        retrieved = self.retrieve(question, k=k)  # by similarity
        facts = [f for f in retrieved if f.similarity >= min_sim]
        if not facts:
            return {"question": question, "stance": "no_relevant_facts",
                    "min_sim": min_sim, "n_retrieved": len(retrieved),
                    "caveat": (f"nothing cleared the relevance floor ({min_sim}); "
                               "the corpus has no sufficiently on-topic facts")}

        def cite(f: "Fact") -> dict:
            return {"id": f.id, "similarity": round(f.similarity, 4),
                    "trust": round(f.trust, 4), "domain": f.domain, "text": f.text}

        support = [f for f in facts if f.trust > 0]
        caution = [f for f in facts if f.trust < 0]
        unchecked = [f for f in facts if f.trust == 0.0]
        checked = support + caution
        checked_frac = round(len(checked) / len(facts), 4)

        if checked:
            wsum = sum(f.similarity for f in checked) or 1.0
            stance_score = round(sum(f.similarity * f.trust for f in checked) / wsum, 4)
        else:
            stance_score = None

        # query-local licensing: a stance is only meaningful if this corner of the
        # corpus is actually checked. Mirror the global honesty at the query level.
        # A single fact is not a body of evidence, and a large mass of relevant but
        # UNCHECKED facts (which by discipline cannot drive the stance) means the
        # question is genuinely under-checked -- so require >=2 checked facts AND a
        # clear checked majority. On a 43%-checked corpus most questions land here,
        # which is the honest state, and makes `proposed_next_check` the real payoff.
        licensed_locally = bool(len(checked) >= 2 and checked_frac >= 0.6
                                and stance_score is not None)
        if stance_score is None:
            stance = "unknown_no_checked_evidence"
        elif not licensed_locally:
            stance = "insufficiently_checked"
        elif stance_score >= 0.3:
            stance = "supported_by_checked_evidence"
        elif stance_score <= -0.3:
            stance = "contradicted_or_cautioned"
        else:
            stance = "mixed_or_weak"

        # the most informative next external check for THIS question: the most
        # central unchecked relevant fact (verifying it resolves the biggest gap).
        next_check = None
        if unchecked:
            frontier = self.explore_frontier(k=200, mode="gaps")
            rank = {d["id"]: d for d in frontier}
            best = max(unchecked, key=lambda f: rank.get(f.id, {}).get("centrality", 0.0))
            nc = rank.get(best.id, {})
            next_check = {"id": best.id, "text": best.text, "domain": best.domain,
                          "centrality": nc.get("centrality"),
                          "why": "unchecked and central to this question"}

        return {"question": question, "stance": stance, "stance_score": stance_score,
                "checked_fraction": checked_frac, "licensed_locally": licensed_locally,
                "min_sim": min_sim, "n_relevant": len(facts), "n_checked": len(checked),
                "supporting": [cite(f) for f in support],
                "cautioning": [cite(f) for f in caution],
                "unchecked_relevant": [cite(f) for f in unchecked],
                "proposed_next_check": next_check,
                "caveat": ("stance reflects what externally-CHECKED corpus facts imply, "
                           "weighted by relevance -- NOT a claim of ground truth. "
                           "Unchecked facts are shown but excluded from the stance.")}

    def learning_curve(self, sizes: Sequence[int] = (5, 10, 15, 20),
                       k: int = 5, repeats: int = 40, seed: int = 0) -> dict:
        """Empirical payoff of the feedback loop: does inference improve as more
        claims get externally checked?

        Over the CHECKED claims only (real external trust, nothing fabricated), for
        each reference-set size m: repeatedly sample m checked claims as the "known"
        set, predict every other checked claim's trust from that set by
        similarity-weighted kNN, and score skill against the known-set mean baseline.
        A rising skill-vs-m curve is direct evidence that accumulating external
        checks -- the frontier `explore_frontier` proposes -- makes synthetic
        inference progressively more licensed. No trust is invented; unknown claims
        are simply excluded, exactly as they are in the live field.
        """
        ids, E, trusts, _ = self._all()
        checked = np.where(trusts != 0.0)[0]
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
            curve.append({"m": int(m), "mean_skill": round(float(np.mean(skills)), 4),
                          "n_samples": len(skills)})
        return {"checked_n": int(nc), "k": k, "repeats": repeats, "curve": curve,
                "monotone_up": all(curve[i]["mean_skill"] <= curve[i + 1]["mean_skill"] + 1e-9
                                   for i in range(len(curve) - 1)) if len(curve) > 1 else None}

    def stats(self) -> dict:
        ids, E, trusts, meta = self._all()
        doms = {}
        for m, t in zip(meta, trusts):
            doms.setdefault(m["domain"], []).append(t)
        return {"embedder_id": self.embedder_id, "dim": self.dim, "n_facts": len(ids),
                "trust_mean": round(float(trusts.mean()), 4) if len(ids) else None,
                "trust_min": round(float(trusts.min()), 4) if len(ids) else None,
                "trust_max": round(float(trusts.max()), 4) if len(ids) else None,
                "domains": len(doms)}
