# Architecture

Reference document for the text-to-logic pipeline. This is the spec; the code
implements it stage by stage.

## Goal

Convert natural language text into discrete, checkable logical / proof-theoretic
representations, with an explicit, *separated* layer for handling ambiguity and
pragmatics probabilistically before collapsing to a final form.

Two output modes from the same underlying augmentation stage:

- **truth-mode** — lossy canonical compression
- **provenance-mode** — derivation-preserving

Primary language: Haskell (syntax + semantics + DRT core).
Secondary target: Agda/Coq/Lean for proof-checking, once a proposition has been
selected and disambiguated.

## Core architectural principle

Two operations must stay separated and never be conflated.

1. **Search / generation** — producing candidate parses, readings, discourse
   relations, tensor-based similarity scores. Inherently probabilistic,
   open-world, never fully "solved." LLMs, RSA, kernels, and DisCoCat all belong
   here.
2. **Verification** — checking whether a *selected* candidate proposition is
   well-typed / provable. Discrete, closed-world, mechanical
   (type-checking = proof-checking, via Curry–Howard).

No amount of expanding the candidate space (tensors, embeddings, kernels)
substitutes for verification. The system must always explicitly collapse from
(1) to a single selected proposition before handing off to (2).

**That collapse is a decision, not a derivation, and is logged as such.** In code
this is `NL2Proof.Collapse.Class.Selection` — it records the chosen candidate,
how many candidates were in play, the rationale, and the provenance. A decision
with no record of the alternatives it discarded is indistinguishable from a
derivation, which is exactly the conflation this design forbids.

## truth-mode vs. provenance-mode

| | truth-mode | provenance-mode |
|---|---|---|
| What matters | final logical content only | the derivation path |
| Sentences entailing the same proposition | compress/collapse to one canonical form | stay independently traceable |
| Lossy | yes, by design and correctly so | no |
| Feeds | the proof stage | retraction / source-reliability analysis |
| Provenance question | "why" (which sources *could* have produced this) | "how" (full derivation tree) |

`how`-provenance is strictly more informative than `why`-provenance.

Two claims that happen to collapse to the same proposition *right now* must remain
independently traceable back to their source in provenance-mode, in case one
source is later retracted or found unreliable.

### Implication for implementation

The augmentation/generation stage is **identical** for both modes. Only the
compression/collapse step differs.

To avoid re-architecting later, every DRS box, discourse referent, and semantic
condition carries a source/provenance tag **from day one**, even though Stage 1
only exercises the logical-content half. Retrofitting this later is expensive;
including it now is cheap.

This is why `Prov` is a *tree* (`ProvRule` nodes over `ProvLex` leaves) rather
than a flat source tag: truth-mode and provenance-mode are then two different
folds over one shared structure, not two different data models.

## Repository layout

`main` holds everything shared. The two mode branches only ever touch their own
collapse backend and its tests.

```
main ──┬── Provenance, Syntax (CCG), Semantics (lambda), DRT, Collapse.Class
       │
       ├── truth-mode      → NL2Proof/Collapse/Truth.hs      + tests
       └── provenance-mode → NL2Proof/Collapse/Provenance.hs + tests

merge direction: main ──> both branches (never sideways)
```

Shared fixes land on `main` and merge down. Nothing merges between the two mode
branches.

## Stage plan

### Stage 1 — Discrete semantic core (DRT)  ← current

- Compositional syntax→semantics using Montague-style typed lambda calculus
  (types `E`, `T`, generalized quantifiers as higher-order functions).
- Discourse Representation Theory layered on top for cross-sentence reference,
  tense, and discourse-level state (structurally similar to threading a `State`
  monad through interpretation).
- Every DRS box and condition carries a provenance tag alongside its logical
  content.
- Fully deterministic, no probability. A stable, tested baseline before touching
  anything downstream. **Changes to later stages should never require changing
  this one.**

### Stage 2 — Probabilistic augmentation layer

Three complementary mechanisms, explored in parallel against the same
DRT-based test set:

- **SDRT** (Segmented DRT) — discourse relations (Elaboration, Explanation,
  Contrast, Narration, Result…) between DRS segments via a defeasible
  (non-monotonic) glue logic. The structural/relational half of pragmatics.
  Anchors directly onto Stage 1's DRS boxes — no translation layer needed.
- **RSA** (Rational Speech Act) — Bayesian listener/speaker reasoning over
  candidate readings. The quantitative/confidence half: calibrated
  probabilities over which SDRT relation or reading is intended, feeding weights
  into SDRT's defeasible rule selection.
- **DisCoCat** — category-theoretic bridge between distributional word vectors
  and grammatical structure; composition via tensor contraction following the
  same syntax tree as the Montague derivation. Best suited to graded,
  similarity-based disambiguation (word-sense blending, coupling detection).
  Reference implementation: DisCoPy.

Test all three against the same fixed evaluation set, not in isolation.

### Stage 3 — Compiler-theory tooling for error handling / tracing

- Multi-pass resolution modeled on **attribute grammars** with inherited
  attributes (non-local resolution across the tree — analogous to symbol table /
  forward reference resolution in compilers).
- Speculative commit + rollback modeled on **profile-guided optimization / JIT
  deoptimization**: commit to the highest-confidence reading, proceed, keep a
  path to unwind and re-derive if a later discourse segment contradicts an
  earlier pragmatic inference. SDRT's defeasibility is the formal hook.
- Diagnostics modeled on **parser error recovery**: produce best-effort
  structures with attached confidence/ambiguity annotations rather than halting
  on first ambiguity.

### Stage 4 — Epistemic graph layer (later, separate track)

Explicitly **not** a natural continuation of Stages 1–3. A separate formalism
that consumes Stage 1–3 output as input nodes. Needs its own literature:

- Modal/epistemic logic (Kripke structures, accessibility relations;
  reflexivity/transitivity/symmetry determine knowledge vs. belief vs. common
  knowledge).
- Dynamic Epistemic Logic (DEL) for belief update mechanics.
- AGM belief revision postulates for coherent belief-set change.
- Simplicial-complex / topological methods for distributed common-knowledge
  questions (Goubault, Ledent, Rajsbaum lineage) if multi-agent structure is
  needed.
- Reference: Fagin, Halpern, Moses & Vardi, *Reasoning About Knowledge*.

Do not start until Stages 1–3 have a stable, tested output format to consume.

## Methodology discipline

Applies throughout, especially Stages 2–3.

- **Fix a stable evaluation set** of test sentences / short discourses before
  comparing any variant of the augmentation layer. Without this, comparisons are
  vibes, not evidence.
- **Round-trip checking**: formalize → verbalize the candidate logical form back
  into plain language → check mutual entailment (NLI-style) against the
  original. Drift here is *measured* loss, not assumed-away loss.
- **Generate multiple independent candidate formalizations** per input rather
  than one. Agreement across candidates signals the unambiguous core; divergence
  localizes exactly where the ambiguity lives.
- **Log every disagreement** between the augmentation layer's chosen reading and
  the expected/gold reading. Disagreements are more valuable than agreements —
  they are where recurring shapes of failure (fused compounds, cross-segment
  scope ambiguity) become visible and harden into explicit heuristics.
- **State heuristics explicitly** the moment they look stable, even as rough
  rules or decision-tree branches. An un-stated heuristic isn't reusable on the
  next batch of examples.
- **Don't over-generalize one heuristic across domains.** Compound-noun
  coupling, discourse-relation ambiguity, and speech-act interpretation likely
  need separate heuristic sets even if they share underlying machinery.
- **Traceability**: every atomic clause in the formal output should be traceable
  back to its source text span, independent of mode.

## Non-goals / guardrails for this phase

- Do **not** attempt to make pragmatics fully discrete/provable — it is
  structurally open-world and non-monotonic. The target is a well-calibrated
  probabilistic layer with explicit collapse points, not a "pragmatics prover."
- Do **not** trust LLM output as ground truth for parses or proofs without an
  independent symbolic check (parser, type-checker, proof-checker). LLMs are
  candidate generators only; they cannot certify correctness of their own
  output. This is standard practice in autoformalization pipelines: LLM
  proposes, Lean/Isabelle verifies.
- Do **not** conflate "expand the representational space" (tensors, embeddings,
  kernels — useful for search/separability) with "avoid information loss" (a
  separate property; expansion changes *where* loss can occur, it does not
  eliminate it).
- Epistemic-graph work (Stage 4) is out of scope until Stages 1–3 are stable.
