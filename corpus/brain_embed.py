"""Pluggable, provenance-tagged text embedder for the fact brain.

An embedder turns a claim's text into a fixed-dimension unit vector. That vector
is *geometry only* -- a position in semantic space. It never carries or creates
trust. Trust in this system originates solely from external checks, propagated by
the epistemic graph (`epistemic_graph.py`); the brain merely *organises* facts by
meaning so retrieval and directed exploration become possible over that
externally-anchored trust field. Keeping embedding and trust strictly separate is
what lets the brain propose without ever deciding truth.

Two backends, chosen at build time and recorded in the brain manifest so every
vector's provenance is known (same discipline as claim/verdict provenance):

  * Model2VecEmbedder -- static distilled sentence embeddings (real semantics,
    deterministic, CPU-only, no torch). Preferred. Needs the model cached once.
  * HashingEmbedder   -- deterministic signed character n-gram hashing. No model,
    no network, always available. Captures lexical, not deep semantic, similarity;
    labelled as such so results are never over-read. Guarantees the brain and its
    selftests remain functional fully offline.

Both return L2-normalised float32 rows, so cosine similarity == dot product and
libSQL's `vector_distance_cos` agrees with our own numpy math during calibration.
"""
from __future__ import annotations

import hashlib
from typing import List, Sequence

import numpy as np

DEFAULT_MODEL = "minishlab/potion-base-8M"


def _l2_normalise(m: np.ndarray) -> np.ndarray:
    m = np.asarray(m, dtype=np.float32)
    if m.ndim == 1:
        m = m[None, :]
    norms = np.linalg.norm(m, axis=1, keepdims=True)
    norms[norms == 0.0] = 1.0
    return (m / norms).astype(np.float32)


class HashingEmbedder:
    """Deterministic signed character-trigram hashing into a fixed dimension.

    No dependencies beyond numpy + stdlib and no network, so it is the guaranteed
    fallback. It measures lexical overlap (shared character trigrams), which is a
    weaker signal than a trained model -- honestly labelled in `.id`.
    """

    def __init__(self, dim: int = 256, ngram: int = 3):
        self.dim = int(dim)
        self.ngram = int(ngram)
        self.id = f"hashing-char{self.ngram}gram-d{self.dim}"

    def _one(self, text: str) -> np.ndarray:
        v = np.zeros(self.dim, dtype=np.float32)
        s = f" {(text or '').lower().strip()} "
        n = self.ngram
        if len(s) < n:
            grams = [s]
        else:
            grams = [s[i:i + n] for i in range(len(s) - n + 1)]
        for g in grams:
            h = hashlib.blake2b(g.encode("utf-8"), digest_size=8).digest()
            idx = int.from_bytes(h[:4], "little") % self.dim
            sign = 1.0 if (h[4] & 1) else -1.0
            v[idx] += sign
        return v

    def encode(self, texts: Sequence[str]) -> np.ndarray:
        return _l2_normalise(np.vstack([self._one(t) for t in texts]))


class Model2VecEmbedder:
    """Static distilled sentence embeddings (real semantics, deterministic)."""

    def __init__(self, model_name: str = DEFAULT_MODEL):
        from model2vec import StaticModel  # imported lazily; optional dependency
        self._m = StaticModel.from_pretrained(model_name)
        probe = self._m.encode(["dimension probe"])
        self.dim = int(np.asarray(probe).shape[1])
        self.model_name = model_name
        self.id = f"model2vec:{model_name}-d{self.dim}"

    def encode(self, texts: Sequence[str]) -> np.ndarray:
        return _l2_normalise(np.asarray(self._m.encode(list(texts))))


def get_embedder(prefer: str = "model2vec", *, dim: int = 256):
    """Return the best available embedder, falling back gracefully.

    `prefer='model2vec'` tries the trained backend and drops to hashing if the
    package or its cached model is unavailable (e.g. offline first run). Callers
    read `.id` to record which backend actually produced the vectors.
    """
    if prefer == "hashing":
        return HashingEmbedder(dim=dim)
    try:
        return Model2VecEmbedder()
    except Exception as e:  # noqa: BLE001 -- any failure means fall back honestly
        print(f"[brain_embed] model2vec unavailable ({type(e).__name__}: {e}); "
              f"falling back to deterministic hashing embedder")
        return HashingEmbedder(dim=dim)


def vec_literal(row: np.ndarray) -> str:
    """Format a vector row as a libSQL vector literal: '[a, b, c, ...]'."""
    return "[" + ",".join(f"{float(x):.7g}" for x in np.asarray(row).ravel()) + "]"


def _selftest():
    for emb in (HashingEmbedder(dim=64), None):
        if emb is None:
            try:
                emb = Model2VecEmbedder()
            except Exception as e:  # noqa: BLE001
                print(f"model2vec selftest: SKIP ({type(e).__name__})")
                continue
        v = emb.encode(["market efficiency and returns", "market efficiency and returns",
                        "a completely unrelated sentence about cooking pasta"])
        n = np.linalg.norm(v, axis=1)
        assert np.allclose(n, 1.0, atol=1e-5), f"{emb.id}: not unit-normalised"
        same = float(v[0] @ v[1])
        diff = float(v[0] @ v[2])
        assert same > diff, f"{emb.id}: identical text not most similar"
        assert abs(same - 1.0) < 1e-4, f"{emb.id}: identical text cos != 1 ({same})"
        print(f"{emb.id}: PASS (identical={same:.4f} > unrelated={diff:.4f})")


if __name__ == "__main__":
    _selftest()
