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

> Further defined by [Three tracks](#three-tracks-epistemic-conversational-letra)
> below. These two names describe *output modes*; that section names the two
> *tracks* they are the entry points of. It sharpens this distinction rather than
> replacing it — the split described here is unchanged.

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

## Three tracks: epistemic, conversational, letra

A lot of the middle is shared; the outer paths diverge.

The working analogy is a Bloons TD6 tower. **The base upgrades are the same. The
special powers and the specialization diverge.** And — the part of the analogy
that carries real weight — you cannot max two paths on one tower. You can take
the low tiers of a second path, but not both top tiers. A tower has exactly
three paths, which is how many tracks there are.

- **epistemic** (*firm domain oracle*) — has a domain verifier. Closed-world,
  mechanical. Must collapse to a single proposition to hand to the checker.
- **conversational** (*probabilistic domain oracle*) — live cross-lingual
  interpretation. Propagates pragmatics probabilistically, steered by direct
  source-language-to-target-language input. Session-scoped: it lasts as long as
  one conversation and no longer. Sits between the other two.
- **letra** (*provenance, no oracle*) — preserves **genealogy and provenance**
  as it retains from individual graphs and nodes. Not necessarily any domain
  verifier. Does not start from nothing: it retrieves from stored state and
  builds progressively.

The ordering is not arbitrary. The tracks differ by **how firm their warrant
is**, and conversational is literally in between:

| | epistemic | conversational | letra |
|---|---|---|---|
| Oracle | firm, binary | **probabilistic, graded** | none |
| Collapse | must, then verify | **provisional, revisable** | must not |
| State lifetime | per-run | **per-conversation** | persistent, accumulating |
| `Prov` used for | traceability to spans | **dependency tracking for rollback** | genealogy / lineage |
| Rejected candidates | dropped after verify | **retained in-session, then dropped** | retained indefinitely |
| Core invariant | well-typedness | **calibration + revisability** | lineage reachability |
| Needs Stage 2 | optional | **essential** | maybe |
| Needs Stage 3 | nice to have | **essential** | open |

Stage 4 (epistemic graphs) sits on the epistemic track. `truth-mode` and
`provenance-mode` are the tier-3 entry points of the epistemic and letra tracks
respectively — their names describe outputs, not tracks. The conversational
track has a branch, `conversational`, but no code yet.

### Provenance and genealogy are two axes, not one

The shared vocabulary hides a real distinction:

| | Provenance | Genealogy |
|---|---|---|
| Question | how was this node's *content* derived | what does this node *descend from* |
| Shape | derivation tree | ancestry DAG (revisions, forks, merges) |
| Time | none — immutable, within one run | the whole point |
| Implemented | yes, `NL2Proof.Provenance` | **no** |

Letra needs both. The current code has only the first.

### What the current `Prov` cannot do

```haskell
data Prov = ProvLex SourceId Span String   -- leaves are text spans
          | ProvRule RuleName [Prov]        -- a TREE
```

1. **The leaves are wrong for letra.** Its leaves are nodes in an individual's
   graph, not spans in a document — and those nodes have their own lineage, so
   provenance becomes **transitive across retrieval**, bottoming out late or
   never. In this pipeline `provLeaves` always terminates at a `ProvLex`.
2. **A tree cannot express a merge.** Genealogy with two parents is a DAG. A
   tree duplicates shared ancestry instead of sharing it, which over many
   revisions is exponential, not merely inelegant. Letra needs **addressable
   node identity**, which `Prov` deliberately does not have.
3. **Genealogy is a third fold class.** `how` (derivation tree) and `why`
   (source set) both exist. Lineage — "descends from X via Y" — is *paths*, and
   is neither.
4. **Retraction is not supersession.** `retractSource` on the provenance-mode
   branch *drops* every fact touching a source. Letra needs "this belief about
   individual X was updated at T", where the prior fact is not wrong-and-deleted
   but historical. Only the first is implemented.

So `NL2Proof.Provenance` transfers to letra **as a design, not as a type**.
`Trace` (Decision/Diagnostic) and `DRT.Canonical` (claim identity across
retrievals) transfer much closer to as-is.

### Where the tracks genuinely conflict

`NL2Proof.Collapse.Class.Selection`.

The epistemic track *must* collapse — a verifier demands one proposition. Letra
must *not* — the retained branch space is the product, and "the wider space of
what everything could have looked like" **is** genealogy: abandoned branches kept
as first-class nodes. `truth-mode` destroys exactly that.

This is the "cannot max both paths" constraint in concrete form. A track can
borrow the other's low tiers — letra using a type check for strict-basis
admission, the epistemic track carrying provenance tags for traceability — but
not both tier-5s.

The conversational track takes a third position on the same field: it collapses,
but **provisionally**. `selRejected` matters *during* the session, because
rollback needs the discarded readings to re-derive from, and is dropped when the
conversation ends. So it needs `Selection` to be revisable rather than final —
neither the epistemic track's collapse-then-verify nor letra's refusal to
collapse.

### Different warrant, therefore different core invariant

With no domain verifier, letra substitutes **verification by lineage for
verification by proof**. The epistemic track asks "is this well-typed"; letra
asks "can I trace where this came from". Credibility is reconstructed from
descent rather than checked mechanically.

That inverts the failure mode, and so the tests:

- epistemic track fails by **admitting an ill-typed thing** → assert
  well-typedness (what the current 348 checks do)
- conversational fails by **being confidently wrong, or by failing to revise**
  → assert **calibration** (stated confidence tracks observed accuracy) and
  **revisability** (a steering input actually invalidates every inference that
  depended on it)
- letra fails by **losing lineage** → assert **reachability**: every node traces
  to its roots, no orphans, no severed edges

Lineage reachability is testable without any verifier. So is revisability.
Calibration is not — it needs an offline gold set, which is why the
conversational track's evaluation problem is the hardest of the three.

### The conversational track

Two people who do not share a language. Pragmatics get confused, and
conversational fluidity is capped by the app interface sitting between them. The
bet is that propagating pragmatics probabilistically — with a steering function
for correction — buys a degree of fluidity that is otherwise unavailable.

**Not** about genealogy or provenance inherently. Provenance appears only in
service of *the expectation of understanding context*.

Four things follow, and three of them are already specified elsewhere in this
document:

1. **The soft oracle is RSA.** Stage 2's Rational Speech Act layer is Bayesian
   listener/speaker reasoning over candidate readings — graded warrant over
   intended meaning, which is exactly a probabilistic domain oracle. This track
   is the first that *requires* Stage 2 rather than treating it as enrichment.

2. **The steering function is Stage 3's rollback trigger.** Stage 3 already
   specifies "commit to the highest-confidence reading, proceed, but keep a path
   to unwind and re-derive if later context contradicts an earlier pragmatic
   inference." A steering input — a direct source-to-target pairing supplied
   mid-conversation — *is* a later-context contradiction. In RSA terms it is a
   prior update: the human pins part of the mapping and the posterior over every
   downstream reading is reweighted. Propagation falls out of that; it does not
   need separate machinery.

3. **`Prov` acquires a third job: dependency tracking for invalidation.** Not
   span traceability (epistemic) and not lineage (letra), but the edges needed
   to locate and unwind an inference when steering contradicts it. You cannot
   invalidate what you cannot locate. This is the attribute-grammar and
   symbol-table side of Stage 3, not the audit-trail side.

4. **The state model exists; the pipeline shape does not.**
   `NL2Proof.DRT.Build.Discourse` is already session-scoped — it accumulates
   across utterances within one run and is then discarded, which is precisely
   the required lifetime. But `NL2Proof.Pipeline` is **batch**:
   `splitSentences :: String -> [Sentence]` wants the whole text up front. Live
   conversation needs *incremental* interpretation — emit a best-effort reading
   mid-utterance and revise as more arrives. That is Stage 3's "best-effort
   structures with attached confidence rather than halting on first ambiguity",
   and this is the only track with a hard real-time requirement.

#### Constraints specific to this track

- **Latency is a first-class constraint.** Full RSA is nested recursion over a
  candidate set and may not fit a conversational budget. The epistemic track is
  batch and letra is retrieval-driven; neither cares. This one does, and it caps
  how much of Stage 2 can actually run live. Decide this early rather than
  discovering it.
- **No gold reading at runtime.** Round-trip checking transfers unusually well
  here: formalize → verbalize → check mutual entailment is essentially
  back-translation, already a standard MT evaluation technique. Live, the
  round-trip is the only available signal; calibration needs an offline set of
  transcripts with annotated intended readings.
- **Steering inputs will conflict with each other.** Two corrections can
  contradict, so later must supersede earlier. That is a session-scoped,
  degenerate form of letra's temporal axis — needed *without* needing genealogy.
- **The two speakers are not symmetric.** Pragmatic expectations differ per
  participant, so per-speaker state within the session is likely required: a
  session-scoped version of letra's per-individual profiles.

#### Prior art, and the reinvention tension

Checked against the literature in August 2026 rather than assumed. **Most of this
track's mechanism already exists, and the novelty is narrower than the initial
framing suggested.** Recording that here so it does not get re-litigated
optimistically later.

Already built, published, and in places patented — do not rebuild:

| Mechanism | Prior art |
|---|---|
| Source-side clarification to a monolingual speaker (*"did you mean nail as in 'they used nails to fix the door', or 'she painted her nails red'"*) | interactive conversational spoken language translation (CSLT), *Machine Translation* journal 2015 |
| Ambiguity detection from ASR confidence + hypothesis plausibility + language context | same lineage; US 8214197, and the "Device for extracting information from a dialog" patent family |
| Steering that reweights the model — the selected sense raises that word's translation probability | same |
| Term-pair constraints | lexically constrained decoding: grid beam search, dynamic beam allocation |
| Incremental output | simultaneous MT: wait-*k* policies, re-translation with stability/latency tradeoffs |
| RSA over multi-turn dialogue | Collaborative RSA (2026); RSA already applied to translation, captioning, dialogue |
| Structured dialogue state plus user corrections | dialogue state tracking: MultiWOZ 2.2/2.3, CorrectionLM, ReacTOD's symbolic validator |
| Harness for building/evaluating/diagnosing IMT systems | IMTLab, open source |
| Monolingual vs bilingual context for dialogue MT disambiguation | BSD-corpus work on speech dialogue translation between speakers of different languages |

So "propagate pragmatics probabilistically and let the speaker steer it" is
solved enough that it shipped and was patented. That is bad news (not novel) and
good news (the premise is not speculative) at the same time.

**What did not turn up — where this track's contribution has to live:**

1. **Dependency-tracked retraction of pragmatic inference chains.** DST
   corrections fix *slot values*; ReacTOD enforces coreference consistency on
   state update. Neither locates and unwinds *every downstream inference that
   rested on a corrected reading*. That is the `Prov`-as-dependency-edges job,
   and it is the piece existing systems structurally do not do.
2. **Repair rate as the evaluation target.** Dialogue repair is well studied as a
   *phenomenon*, and conversational-AI metrics exist, but repair rate and
   time-to-mutual-understanding do not appear to be used as the objective for a
   steered bilingual conversation system. MT metrics score a text; the claim here
   is about a conversation *converging*, which is a different quantity.
3. **A symbolic discourse representation (DRT plus provenance) as the pragmatic
   state**, rather than context-window conditioning or slot filling. Inspectable
   and surgically correctable, not an opaque activation.

**Two constraints that follow. Do not re-litigate these.**

- **Wrap, don't rebuild.** An MT engine is a candidate generator — which the
  non-goals below already say is all an LLM may be trusted as. Building
  constrained decoding or a wait-*k* policy from scratch would be precisely the
  "expand the representational space" versus "avoid information loss" conflation
  those guardrails warn against. Use an existing engine; use IMTLab for
  harnessing.
- **Measure repair, not BLEU.** Test the premise with a wizard-of-oz comparison
  — plain engine versus engine plus a human simulating the steering loop —
  *before* building anything. If repair turns do not drop, the premise is wrong,
  and that is worth learning in a week rather than a year.

**Non-engineering risk.** There are granted patents covering source-side
ambiguity resolution in interactive translation. That is a freedom-to-operate
question for a product rather than for research, it needs actual legal advice
rather than a note in a design document, and it should not be discovered late.

### Tier map as of today

| Tier | Shared base | epistemic | conversational | letra |
|---|---|---|---|---|
| 0–2 | `Provenance`, `Trace`, `DRT.Canonical`, `DRT.Types`, `Collapse.Class`, `DRT.Build.Discourse` | | | |
| 3 | | `Syntax/*`, `Semantics.Lambda`, `typeOf` as gate | Stage 2 RSA as soft oracle | genealogy DAG, node identity |
| 4 | | `truth-mode` canonical form | Stage 3 speculative commit + rollback | per-individual graphs, retrieval |
| 5 | | Agda/Coq/Lean; Stage 4 Kripke/DEL/AGM | incremental interpretation under a latency budget | supersession, lineage reachability |

Low-tier borrows, in BTD6 terms: the conversational track takes **tier-2 letra**
— session-scoped supersession and per-speaker state — without the persistence or
the lineage DAG. It does not take letra's tier 5, and letra does not take its.

One boundary worth being aware of: **`Syntax/*` and `Fragment.hs` sit on `main`
but are used only by the epistemic path.** Composition from a closed lexicon is
not something letra needs. That is fine as it stands — `main` is the shared
repository, not a minimal core — but it means "on `main`" and "shared base" are
not the same set, and the tier column above is the authority on which is which.

### Decisions and open questions

**Decided.** The tracks stay as branches in this repo. No module restructure
for now; `truth-mode` and `provenance-mode` keep their names. The tracks are
built on and extended separately. The conversational track is defined here but
has a branch, `conversational`, but no code yet — deliberately, see the prior-art
section above.

**Open — do not resolve these by assumption.**

1. When letra says *individual* graphs: individual **people** (per-person
   profiles) or individual **entities/nodes** in one graph? Determines whether
   genealogy crosses graph boundaries — one DAG, or many with foreign
   references.
2. Does letra ingest natural language, or already-structured nodes? If
   structured, `Syntax/*` and `Semantics.Lambda` do not transfer and the shared
   surface is only `Provenance`, `Trace`, and `Canonical`.
3. Does letra ultimately live in this repo or its own? One practical
   constraint on the current dev machine: there is no cabal/stack/ghcup, so
   there is **no way to share a Haskell library across two repos** short of a
   submodule or a vendored copy. That argues for one repo, against the fact that
   this repo's *name* is epistemic-path-specific.
4. Whether to eventually hoist the divergence into `NL2Proof.Core.*` vs
   path-specific modules, with a test asserting the base never imports a path.
5. Conversational: what is the latency budget per utterance? That number, more
   than any design preference, decides how much RSA can run live and whether
   incremental interpretation is required from the start or can be deferred.
6. Conversational: does a steering input bind a *term pair* (this word maps to
   that word) or a *reading* (this utterance meant that)? Term pairs are cheap
   and local; readings are what actually propagate, and are much harder to
   elicit from a user mid-conversation.
7. Conversational: two-party only, or N-party? Per-speaker state and pairwise
   language mapping both change shape at N > 2.
   That would make the shared base a checked invariant rather than a convention.

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
