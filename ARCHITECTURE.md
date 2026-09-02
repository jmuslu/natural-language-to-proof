# Architecture

Reference document for the text-to-logic pipeline. This is the spec; the code
implements it stage by stage.

## Goal

Produce discrete, **oracle-verifiable** logical forms from natural language, so
that the result can serve as a reinforcement-learning reward signal without the
system supplying its own grounding.

Not "extract meaning from text" in general. An LLM already does that, with
broader coverage and at lower cost, and nothing here should try to compete with
it. What an LLM cannot do is hand back a claim together with a *checkable*
certificate that the claim is true. That certificate is the output this substrate
exists to produce.

### The one hard constraint

Everything below is organised around a single constraint:

> A system cannot use its own internal consistency checks as the reward signal
> for the step that produces the claims in the first place.

Type-checking and provability are internal. Rewarding either measures
self-agreement, not truth, and an RL policy will find and exploit the gap — there
is a cheaper path to reward than faithful extraction, namely drifting toward
claims that happen to be easy to type or easy to prove.

So truth enters at exactly one place: an **external domain oracle** — a physics
engine, a backtesting engine, a table of settled measurements — whose answers do
not depend on this pipeline. Everything upstream of the oracle produces
*candidates*. Nothing upstream produces *evidence*.

Where no oracle exists for a domain, this system cannot manufacture
truth-grounding for that domain. That is inherent, not a gap that closes with
more engineering. See [Standing limitations](#standing-limitations).

Primary language: Haskell (syntax, semantics, DRT core, and the substrate).
Secondary target: Agda/Coq/Lean for proof-checking, once a claim has been
selected — and only ever as a *consumer* of oracle-confirmed output, never as a
source of grounding for it.

## The four stages

Four stages, in order. This is a pipeline, not a choice of dispositions — the
earlier "three tracks" framing described a decision the design no longer has to
make, and is [recorded as cut](#what-was-cut-and-why) below.

```
1. INITIAL SPACE                                       (search; commits to nothing)
   text -> tokens -> CCG derivations -> lambda terms -> typeOf -> DRS
        -> candidate readings (scope, coupling), ranked by RSA
   Modules: Syntax.*, Semantics.Lambda, DRT.*, Stage2.*

2. VERIFICATION                                        (retain, trace, allow retraction)
   candidate -> atomic claims with full derivations retained
             -> each claim offered to an EXTERNAL oracle
             -> Confirmed | Refuted | Unknown, recorded in a genealogy DAG
   Modules: Verify.Claims, Verify.Oracle, Genealogy

3. FUSION                                              (collapse; safe only here)
   oracle-CONFIRMED claims only -> canonical form, redundant confirmations deduped
   Modules: Fusion

4. REWARD                                              (the RL signal)
   confirmed claims + mechanical consequences of them -> score
   Never "did this typecheck". Never "was a proof found".
   Modules: Reward
```

| Stage | Disposition | Why it must be there |
|---|---|---|
| 1 | build the space, commit to nothing | a reading never generated cannot be recorded as rejected |
| 2 | **retain everything** | an oracle can reverse its own earlier answer, and the derivation record has to still exist when it does |
| 3 | **collapse** | avoid storing one confirmed fact five times |
| 4 | score | the only two admissible sources are oracle confirmation and mechanical entailment from a confirmed base |

### Why verification precedes fusion, and why that ordering *is* the refactor

Verification and fusion were previously bundled together as "epistemics".
Splitting them was the load-bearing move, because the two need opposite
dispositions:

- **Verification needs retention.** While truth is undecided, independent
  corroboration is information: "two derivations agree" must stay
  distinguishable from "one derivation said it once".
- **Fusion needs collapse.** Once truth is settled, multiplicity is just
  duplicate storage.

And they have to happen in that order. A collapse performed first destroys the
derivation record that retraction depends on, and retraction is not optional once
an external oracle can change its mind.

### What each stage may and may not read

The prohibition is enforced by signature, not by discipline.
`Reward.score` takes a `Fused` and a `Genealogy`. It never sees a
`Semantics.Lambda.Term`, so it *cannot* consult `typeOf`, and there is no proof
search for it to consult either. `Reward.admissibility` then checks the weight
table itself: uncovered claims must score exactly zero, refutation must be
penalised, and direct confirmation must be worth at least as much as inherited
grounding — otherwise the policy is rewarded for laundering claims through
entailment instead of getting them checked.

`Verify.Oracle.Confirmed` is abstract: its constructor is not exported, and
`confirm` is the only way to obtain one. "Fusion only ever sees oracle-confirmed
claims" is therefore a type error to violate rather than a rule to remember.

### `Unknown` is not `Refuted`

Oracle coverage is **binary per domain**. A physics engine settles trajectories
and has nothing to say about monetary policy. Collapsing "outside my domain" into
"false" would manufacture exactly the grounding this design refuses to
manufacture, so `Verdict` has three cases and `Unknown` is a first-class outcome
that scores zero in both directions.

Penalising it would train the policy away from domains that merely lack
instrumentation, which is a fact about the tooling. Rewarding it would invent
evidence. Zero is the only defensible value, and `Reward.rwUncovered` reports the
count so the size of the ungroundable remainder stays visible.

## What was cut, and why

Recorded so it does not have to be re-derived, and so nothing gets quietly
resurrected.

### The conversational track — cut entirely

Its mechanism was a human correcting live output. That is external help by
definition, which contradicts the goal directly. It also addressed an unrelated
problem — real-time cross-lingual interpretation with a human in the loop — that
has no bearing on this pipeline.

There is no partial version worth keeping. The branch is gone, the ~400 lines of
specification are gone, and the "RSA as conversational oracle" framing is
explicitly *not* salvaged: RSA keeps its Stage 1/2 role as a ranker over
well-typed candidates, and that role has nothing to do with a human in a loop.

### The "three tracks on one tower" framing — cut

The tower analogy assumed three genuine alternatives for one disposition
decision. That is no longer the shape of the problem: verification and fusion are
sequential stages. The analogy actively misleads about the current architecture,
so it is not carried forward.

### `truth-mode` as a track — cut; one piece salvaged

`Collapse.Truth.compress` was sold as epistemic verification and is nothing of
the kind. It is `sort` then `dedup` over `CanonCond` — syntactic equality up to
referent renaming — which is strictly finer than "entails the same proposition".
The gap does not close by improving the implementation: `~(P | Q)` and
`~P & ~Q` are logically equivalent, produce different `CanonCond` shapes, and
will never merge. That is asserted as a check in the substrate suite so it cannot
be forgotten a second time.

**Kept:** the dedup logic, repositioned as `Fusion.compress` — post-verification
bookkeeping, safe because truth was already settled upstream.
**Cut:** the epistemic-track framing, and the idempotent-fold-as-verification
framing that went with it.

### `provenance-mode` as a track — cut; the disposition promoted to a stage

`Collapse.Provenance` survives almost unchanged as `Verify.Claims`. What changed
is its position: it was one of three alternatives a caller could pick, and it is
now mandatory, because the stages after it require what it provides. Retention is
no longer a preference to be traded against compactness.

The name *letra* was the informal label for this disposition. It is retired as a
track name; the discipline it named is now simply what stage 2 does.

### Stage 4 (epistemic graph layer) — re-scoped, not deleted

AGM belief revision may well be the right formalism for oracle-reversal
propagation. But it has to be re-derived from *that* motivation rather than
inherited from its old slot "on the epistemic track". Filed as an open question
below, not as a carryover and not as a cut.

## New tensions this design introduces

These did not exist in the three-track framing. They are consequences of the new
one and have to be designed for rather than inherited.

### Genealogy is load-bearing, and it is now built

Previously an open question; now the first thing that had to exist.
`NL2Proof.Genealogy` is the DAG: `NodeId` for addressable identity,
`Justification` for derivation edges, and grounded support computed as a **least
fixed point**.

Taking the least rather than the greatest fixed point is the whole point, and it
is the formal content of the goal's hard constraint:

> A claim cannot ground itself, directly or around a cycle.

A ring of mutually-justifying claims satisfies the greatest fixed point — they
are mutually consistent — and satisfies the least fixed point not at all. Mutual
consistency is exactly the self-agreement that must not be mistaken for truth.
This is asserted, not remarked: see `cycleChecks` in the substrate suite.

**Retraction is a difference of fixed points**, which is what makes it precise.
Flip a premise's verdict, recompute grounded support, return the set difference.
The naive answer — everything transitively downstream, which `dependents`
computes — over-retracts, because a claim with a second independent derivation
keeps its support. `retractionReport` measures the gap between the two, and
`rrSurvived` names exactly what a coarse retraction would have destroyed.

Two granularities are kept deliberately. `Verify.Claims.retractSource` is
source-level and coarse — "this document turned out to be unreliable", where
distrusting everything that used it is the right answer.
`Genealogy.retract` is node-level and precise — "this measurement reversed". A
retracted document and a reversed measurement are different events, and
conflating them would make one of the two answers wrong.

### AGM may fit oracle-reversal propagation — open

Evaluate it against that use case directly: an oracle answer changes, what gets
revised and what survives. The genealogy already answers the *extensional*
question (which claims lose support). What AGM would add is a principled account
of *minimal change* when the reversal creates an inconsistency rather than merely
removing support. Not yet needed, and not yet ruled out.

### Oracle coverage is a hard domain boundary — decide it per domain, first

This design produces truth-grounded reward **only** in domains where an external
oracle exists. Outside those, the system is back to the original problem: no
ground truth, and internal checks cannot supply it however they are combined.

So the first question for any intended application is not "can we parse this
text" but "does an oracle exist for what the text is about". If the answer is no,
the RL loop does not close for that domain and no amount of pipeline work changes
that. `Verify.Oracle.coverage` reports the uncovered share of a claim set, which
is the number to read before committing to a domain.

### Category-schema correctness is structurally unverifiable

The same asymmetry as extraction faithfulness, showing up a third time:

| Layer | What is checked | What is not |
|---|---|---|
| `typeOf` | conformance to a category | whether the category is the right one |
| proof search | that a statement is derivable | whether it is faithful to what was claimed |
| `Stage2.Modifier` | that an instance fits its class | whether the class scheme is right |

Once a scheme is fixed, instance-level classification can be automated and
checked against it. **The design of the scheme itself has no internal check at
all**, and this does not close with engineering effort. The existing
`ambiguousModifiers` list is a standing admission of exactly this, not a bug to be
fixed.

Three mitigations, none of them a fix:

1. **Front-load scrutiny on category boundaries** before scaling instance count.
   An error at this layer propagates to every instance built on it.
2. **Keep an explicit ambiguous / low-confidence flag** for instances that do not
   cleanly fit a class, rather than forcing a classification.
3. **Where an oracle exists it will eventually catch a downstream consequence** of
   a bad category choice — but only after the fact, and without identifying which
   category decision caused it. A backstop, not a substitute for design-time
   scrutiny.

## Standing limitations

Stated here rather than buried, because each one is a live way to fool yourself
about what the system has established.

### Well-typed does not mean faithful

Internal coherence of an extracted form says nothing about whether it is what the
source text meant. Multiple mutually-incompatible extractions of one sentence can
all be well-typed — the scope readings in `Stage2.Alternatives` are exactly this
— and `typeOf` cannot break the tie. Typedness is *necessary and not sufficient*:
every claim entering the system must be well-typed, and being well-typed earns it
nothing beyond admission.

### Provable does not mean faithful

A found proof certifies that a statement is derivable, not that it corresponds to
the input. Rewarding "provability of the extracted claim in isolation" gives the
policy a cheaper path to reward than faithful extraction: drift toward statements
that are easy to prove.

If provability is used as a signal at all it must be tied to **cross-derivation
consistency** — independent extraction paths converging on mutually-entailing
forms — and never to a single statement's provability alone. That is what
`Genealogy.convergentNodes` and `hasIndependentSupport` are for, and it is the one
safe use of a provability-shaped signal here.

### No oracle exists for extraction faithfulness itself

The oracle design sidesteps this only for claims that eventually touch a domain
with an external oracle, and even there it bounds the *truth* of the output while
saying nothing about its *correspondence* to the input. A policy that extracts
true-but-unfaithful claims scores well.

This is the limitation that does not close. No internal mechanism in this
codebase — or plausibly in any codebase built this way — supplies it.

### Lexical and grammatical coverage is separately unbounded

Independent of the truth problem, and worth not conflating with it:

- Growing the lexicon **within existing category shapes** is cheap and
  mechanically checkable — `typeOf` gates it for free.
- Growing the **category inventory** (new constructions) is not mechanically
  checkable and needs real design work per construction.

Neither ever reaches "covers arbitrary text" the way an LLM does, and that was
never the goal.

### The corpus is the weakest link in the test suite

Recorded because it has now caused two real defects rather than one. The
nine-case evaluation set has hidden:

1. **SDRT's right frontier being inert** — divergence needs three segments, and
   every multi-sentence case has two.
2. **DRS merge being unsound** — needs two same-shaped existential sentences, and
   no case has them. All 348 checks passed throughout.

A green suite here means "no case exercises this", not "this works". A generator
over the lexicon and the CCG rules would have caught both within a handful of
samples and is still unbuilt.

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

## Provenance, genealogy, and augmentation

### Augmentation is not optional, and never was

An earlier version of this document marked Stage 2 as "optional / essential /
maybe" depending on which track you were on. That was wrong, and the error
mattered — it is what made a candidate-generation layer look like a per-track
luxury instead of a precondition.

**Augmentation is useful in every case.** It is always worth understanding a
statement from every angle before collapsing, because the additional angles
*derive additional insight*, and because the layer's real job is to make sure
signals are not lost before anything commits. Collapsing straight off Stage 1
throws away information that was never looked at.

Under the four-stage pipeline this stops being a question at all. Stage 1
generates the space, stage 2 verifies members of it, and stage 3 collapses only
what an oracle confirmed. There is no path from text to reward that skips
generation, so there is nothing to make optional.

What the stages differ on is **disposition**, and it is exactly two things:

| Stage | Disposition | Because |
|---|---|---|
| 1 | generate, commit to nothing | a reading never generated cannot be recorded as rejected |
| 2 | retain everything, including multiplicity | an oracle can reverse itself, and independent corroboration is information while truth is undecided |
| 3 | collapse | truth is settled, so multiplicity is duplicate storage |

Same machinery throughout, divergent use — the same shape as the collapse seam,
now sequenced rather than chosen between.

### Provenance and genealogy are two axes, not one

The shared vocabulary hides a real distinction:

| | Provenance | Genealogy |
|---|---|---|
| Question | how was this node's *content* derived | what does this node *descend from* |
| Shape | derivation tree | ancestry DAG (revisions, forks, merges) |
| Time | none — immutable, within one run | the whole point |
| Implemented | `NL2Proof.Provenance` | `NL2Proof.Genealogy` |

Both are now built, and they coexist rather than one replacing the other. The
tree is still the right object for "which words produced this"; it is only the
wrong object for reachability and retraction.

### What `Prov` cannot do, and what now covers it

```haskell
data Prov = ProvLex SourceId Span String   -- leaves are text spans
          | ProvRule RuleName [Prov]        -- a TREE
```

| Limitation | Status |
|---|---|
| **A tree cannot express a merge.** Two independent derivations of one claim are two separate trees with nothing relating them, and a tree duplicates shared ancestry instead of sharing it. | **Covered.** `Genealogy` has addressable `NodeId`s and multiple `Justification`s per node. |
| **Lineage is a third fold class.** `how` (derivation tree) and `why` (source set) both exist; "descends from X via Y" is *paths*, and is neither. A fold cannot answer reachability. | **Covered.** `antecedentsOf` / `dependents` / `grounded` are graph computations, not folds. |
| **Retraction is not supersession.** `retractSource` *drops* every fact touching a source. A revision — "this belief was updated at T", where the prior fact is historical rather than wrong — is a different operation. | **Open.** Both retraction granularities exist; supersession does not. This is where AGM would be evaluated. |
| **The leaves are wrong for an individual-graph substrate.** If leaves are nodes in someone's graph rather than spans in a document, those nodes have their own lineage and provenance becomes transitive across retrieval, bottoming out late or never. Here `provLeaves` always terminates at a `ProvLex`. | **Open, and out of scope** until such a substrate exists. |

`NL2Proof.Provenance` therefore transfers to a graph-of-individuals setting **as
a design, not as a type**. `Trace` (Decision/Diagnostic) and `DRT.Canonical`
(claim identity across retrievals) transfer much closer to as-is.

## Repository layout

`main` holds everything shared. The track branches only ever touch their own
collapse backend and its tests.

```
src/NL2Proof/
  Provenance.hs        derivation trees: how a condition was derived
  Trace.hs             Decision / Diagnostic: every collapse, logged
  Semantics/Lambda.hs  simply-typed lambda calculus, typeOf, normalize
  Syntax/              tokenizer, categories, lexicon, CKY parser
  DRT/                 boxes, accessibility, discourse threading, canonical form
  Collapse/Class.hs    Selection: chosen reading + the rejected fiber
  Fragment.hs          the nine-case evaluation set
  Pipeline.hs          stage 1 end to end
  Stage2/              candidate generation, fingerprints, models, RSA, SDRT
  Verify/Oracle.hs     stage 2: Verdict, Oracle, Confirmed (abstract)
  Verify/Claims.hs     stage 2: claims with derivations retained
  Genealogy.hs         stage 2: the DAG, grounded support, precise retraction
  Fusion.hs            stage 3: dedup of oracle-confirmed claims
  Reward.hs            stage 4: the RL signal, and its admissibility check
app/Main.hs            demo
test/Harness.hs        assert scaffolding, no framework dependency
test/Spec.hs           stage 1
test/Stage2Spec.hs     candidate generation and ranking
test/SubstrateSpec.hs  verification, genealogy, fusion, reward
docs/                  standalone probes, not wired into a suite
scripts/               no-cabal build path
```

Shared fixes land on `main` and merge down. Nothing merges between the track
branches.

## Stage plan

### Stage 1 — Discrete semantic core (DRT)

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

#### The SDRT tie-in, and what wiring it up revealed

Building SDRT and *using* SDRT turned out to be different jobs with different
findings. The relations, the right frontier and the glue logic were correct and
inert: nothing consulted `sdrsAccessible`, so anaphora resolution still ran off a
flat `mergeDRS`. `NL2Proof.Stage2.Threading` closes that, and three things came
out of it that belong in the architecture rather than in a module header.

**1. Accessibility flows left-to-right across a relation; the kind governs the
*next* unit.** For `relation(a, b)`, `a`'s referents are available to `b`
whatever the relation is. A coordinating relation closes `a` for whatever attaches
*after* `b`. Getting this off by one would make a coordinating relation block its
own right argument. The consequence is structural: the frontier consulted when
resolving unit *n* is the frontier of the structure through *n-1*, so the
threading loop is inherently one step behind the graph it is building.

**2. The frontier is a filter, so it can only lose coverage.** The frontier's
referents are a subset of the flat merge's — every unit is in the merge, only some
are open. Switching the default from flat to frontier-restricted is therefore a
strict loss, and here it is a loss driven by *stipulated* cue weights. This is the
single most important reason SDRT threading is not simply installed as the Stage 1
default: it would be trading a correct resolution for a guessed number, silently.

**3. The least committal relation is not the least committal for accessibility.**
`glue`'s no-cue default is `Continuation`, chosen because it commits to the least
*about the discourse*. But `Continuation` is coordinating, so it is the most
restrictive choice for *anaphora*. With no cues firing, committing to it closes
every parent and accessibility collapses to the previous sentence alone. Two
notions of "least committal" that look like one and point opposite ways.

So there are two policies rather than one, and the split is the standing principle
applied at this layer:

| policy | frontier from | effect on antecedents |
|---|---|---|
| `Committed` | `argmax` of the relation distribution | hard filter; can delete a correct resolution |
| `Marginal` | every relation with positive mass, weighted | ranking; deletes nothing |

`Marginal` is the one that belongs here. `Elaboration` always retains positive
mass, so a parent is never fully closed, and the frontier contributes a *graded
preference* over antecedents instead of a veto. Collapse stays a separate logged
step, exactly as everywhere else. Measured on
`"A student arrived. Mary smiles. She reads a book."`: flat resolves `she`,
`Committed` fails, `Marginal` resolves it at mass **0.488** — which is exactly the
subordinating mass of that edge's relation distribution, not a tuned constant.

**The marginal is over one edge, not over the structure.** Marginalising over every
relation choice in a discourse means carrying a distribution over *structures*,
whose support is exponential in the number of segments. `Threading` marginalises
over the most recent edge only, holding earlier attachments at their committed
values. That is enough to grade the referent whose reachability the last choice
governs. It is a deliberate truncation, not an approximation with a bound, and if
longer discourses matter it is the first thing that has to change.

**Known over-restriction, recorded rather than patched.** A resolved pronoun adds
no referent to its unit's universe — substitution replaces a constant with an
existing `Ref`. So under `Committed`, a chain of coordinating relations starves:
`"A man walked in. He sat down. He ordered."` has an empty frontier universe at the
third unit. Real SDRT percolates referents up the graph. This does not, and
`Marginal` hides the symptom without addressing the cause.

**And the corpus cannot see any of this.** Both multi-sentence fragment cases are
two sentences long, and a two-unit structure has one edge whose parent is always on
the pre-attachment frontier — so no relation choice can change anything. Both
policies diverge from flat on zero cases. That is asserted as a check rather than
assumed, which makes it say two things at once: the tie-in is safe on the existing
corpus, and the corpus is too short to exercise it. Three segments is the minimum
for this layer to be observable at all.

#### Tracing the frontier mass back down: what it is, and what blocks the question

The tie-in left one question open — what kind of object the graded mass is, and
therefore how it may legitimately combine with the RSA posterior. Tracing it back
down answers it, but not from the direction the question suggests.

**1. The domain was wrong, because of a Stage 1 soundness bug — now fixed.**
`mergeDRS` has an unstated precondition: merge is only sound when the two
universes are disjoint. Referent names come from the lambda terms, so
`"A student arrived. A professor walks."` gave both existentials the referent `x`,
and the merge asserted `student(x) & arrive(x) & professor(x) & walk(x)` — one
individual who is both. Two distinct individuals unsoundly identified. All 348
Stage 1 checks missed it because no fragment case has two same-shaped existential
sentences: the "corpus too short" problem biting a second and worse time.

It blocked the frontier specifically. Distinguishing "`x` from a closed unit"
from "`x` from an open unit" is the frontier's whole purpose, and `Ref` did not
record which unit a referent came from — `accessibleOn`'s `nub` conflated them.

`DRT.Types.freshenAgainst` discharges the precondition, applied in
`extendDiscourse` and in `Stage2.Threading`. Two things make this the cheap option
rather than the invasive one. It is **alpha-conversion**: mechanical, so nothing
is logged, and `mapRefs` carries each referent's provenance through, so a renamed
referent is still traceable to the words that introduced it. And it happens **at
the merge, not in `toDRS`**, so sentence-local DRSs are untouched and a sentence
read on its own reads the same. Stage 1's 348 checks all pass unchanged; 18
regression checks were added, giving 366.

The alternative — indexing accessibility by `(Label, Ref)` and leaving Stage 1
alone — was rejected because it fixes the frontier's symptom while leaving a DRS
that asserts a student is a professor. That is a wrong answer, not a missing
feature.

**2. Consonance was an artefact of that collision, and the correction has a sharp
consequence.** The tempting cheap test is whether the focal family
`{acc(S[e ↦ ρ])}` is nested — if so the mass is a possibility distribution and a
t-norm is licensed. Measured before the fix: `Ref`-indexed gave **2** nested sets,
`(Label, Ref)`-indexed gave **4** and non-nested, crossing at `{(K2,x)}` versus
`{(K1,x)}`. The test would have reported "possibility measure" off a name
collision.

After the fix `Ref` is discourse-unique, `(Label, Ref)` adds nothing, and both
indexings agree — 4 sets, non-nested, crossing `[x2]` versus `[x]`. But the sharp
part is the *structure* of when consonance holds:

> `frontier(subordinating) = frontier(coordinating) ∪ {parent}`

so at **one** free edge there are exactly two focal sets and they are nested **by
construction** — a theorem, not a measurement. At **two** they cross. The
implementation runs at one free edge, which means it sits in the only regime where
the possibility reading is available, **and that regime is the truncation.** Since
the truncation has to go (it deletes referents), the possibility reading goes with
it. They stand or fall together, which retires the whole
possibility-versus-belief-function question rather than answering it.

**3. The semiring is not a free parameter in the regime the code occupies.** The
mass is a semiring-weighted sum — `⊕_ρ P(ρ) ⊗ 1[r ∈ acc(...)]` — so in principle
the semiring is a choice, and different choices give different *kinds* of object
rather than different numbers. Measured, at one free edge:

| semiring | mass of `x` |
|---|---|
| `(+, ×)` — expectation | 0.488 |
| `(max, ×)` — Viterbi | 0.122 |
| `(max, min)` — possibilistic | 0.122 |

The last two **coincide**, because `⊗` is applied to a boolean indicator and
`P ≤ 1`, so `min(P,1) = P × 1 = P`. Four candidate algebras collapse to two
questions: sum over licensors, or max over licensors. They separate only at two
free edges (0.018 versus 0.122) — that is, exactly when the one-edge truncation is
dropped. The freedom the semiring framing promises is real but it is downstream of
the truncation, not available now.

And the Viterbi reading is not MAP. MAP is *argmax the relation, then test*, which
is `Committed` — already implemented. Measured: the overall argmax is `Narration`
(coordinating), which offers nothing.

**4. There is no joint space, which is upstream of every combination rule.** The
mass is indexed by `Ref`. The RSA posterior is indexed by `readingIndex :: Int`
over scope permutations and coupling fusions. `Ref` does not occur anywhere in
`Stage2.Alternatives`, `Stage2.Pipeline` or `Stage2.RSA`. Asking which rule
combines them presupposes a product space that does not exist.

**5. So the native move is not an uncertainty calculus at all.** Make antecedent
choice an *alternative*: a reading becomes `(scope order, coupling, antecedent
assignment)`. Then the frontier mass is a **prior over readings** — the same
`Dist Int` as everything else in Stage 2 — and `Distribution.reweight` already
performs the combination. No belief functions, no t-norms, no new algebra.

This is the same pattern the scope work already follows. Stage 1 collapses to one
antecedent and logs the others *as strings* in `decAlternatives`; Stage 2's job is
to materialise what Stage 1 declined. Anaphora is the one place where that has not
been done, which is why its output had nowhere to go.

**6. Two claims from the tie-in were too strong.** `Marginal` "deletes nothing"
holds at one uncertain edge only: at four segments the implementation offers
nothing for `K4` while the full marginal keeps the referent at 0.488.
`fullMarginalAt` now measures that gap rather than leaving it unstated.

And at one free edge the mass takes only **two** values — 1 for a referent in the
coordinating frontier, `P(subordinating)` for one reachable only subordinately —
so it is a two-tier partition with a single global weight, not a per-referent
grade. That deflation is itself an artifact of the truncation: at two free edges,
measured on the four-segment colliding text, `x2` gets **0.488** and `x` gets
**0.435**, and the truncated implementation offers only `x2`. So the mass is
genuinely graded, and the reason it did not look it is the same reason everything
else in this section collapses — one free edge.

**7. The missing multiset structure and the one-edge truncation are the same
gap.** At one free edge each relation occurs at most once in a licensing witness,
so multiset and set coincide and there is no multiplicity to lose. Multiplicity
first appears at two free edges — measured. So there is no separate "build the
multiset intermediate" task; there is one task, which is dropping the truncation,
and `rkLicensors` already holds the set-level version of it (unconsumed by
`antecedentsFor`).

#### On the absence of a data source

`NL2Proof.Stage2.Fingerprint` currently computes *structural* fingerprints rather
than composing distributional word vectors, and the hand table in
`NL2Proof.Stage2.Modifier` classifies the fragment's five adjectives by hand.

**Both are unwired dependencies, not architectural limits.** Nothing in the design
assumes the absence of a corpus or a lexical resource; the data simply has not been
connected yet. The swap points are named and single:

| What is stubbed | What replaces it | Callers affected |
|---|---|---|
| structural fingerprints | real vectors composed along the CCG derivation, DisCoCat-style | none — `similarity` is the only interface |
| hand modifier table | WordNet-style class data, plus corpus statistics for the layer-2 conventionalization judgement | none — `fragmentModifierClasses` is the only table |

Where the code says something is "not distributional semantics", read that as a
statement about the current wiring, not a claim about what the architecture can
support. The honest version is: this is a placeholder with a named replacement,
and the results it produces should be read as lower bounds.

### Stratification: not all modifiers or relations are one kind of thing

A cross-cutting constraint on Stage 2, learned while building it.

Stage 1 gives every adjective one entry — intersective conjunction — and the first
version of the candidate generator treated every `N/N` word as an equally good
fusion candidate. Both are the same flattening error. **Modifiers differ in how
hard they are to resolve, and treating them uniformly either over-generates
garbage or gets truth conditions wrong.**

`NL2Proof.Stage2.Modifier` stratifies them by resolution layer:

| Layer | Class | Example | Why that layer |
|---|---|---|---|
| 1 | intersective | `red`, `ancient` | conjunction is faithful; decidable from structure alone |
| 2 | classificatory | `chinese`, `nuclear` | may name a lexicalized subkind; needs the head plus a graded conventionalization judgement |
| 3 | subsective | `skilled`, `large` | property is relative to the head; needs a lexical resource |
| 3 | privative | `fake`, `former`, `alleged` | head predicate does **not** hold — a representation error in Stage 1, not an ambiguity to rank |

Concretely, on `"ancient Chinese red dragon"` the classes separate `chinese`
(classificatory, a plausible subkind with `dragon`) from `ancient` and `red`
(intersective, not subkind-forming).

**How that information is used was reversed, and this section originally had it
wrong.** The first implementation applied the stratification as a *filter*,
suppressing non-classificatory fusions and cutting the candidate set from four
readings to two. That looked like a win and was recorded here as one.

It is not. Filtering at generation time is preemptive pruning — see
[Build the space; do not preemptively prune it](#build-the-space-do-not-preemptively-prune-it)
below, which supersedes the earlier framing. The candidate set is back to four,
with the classification attached to each candidate as evidence (`ccClass`,
`ccLicensed`, `ccLayer`) so the ranking layer can down-weight rather than the
generator omit.

The stratification itself was right; only its application was wrong. And the
reversal was vindicated empirically: with real informativity the ranking layer
*does* separate those four readings, so the two that filtering would have deleted
were rankable all along.

**The same stratification applies to SDRT's discourse relations**, and for the
same reason. Some are structurally cued — Narration largely follows from tense
sequence — while others need abstract inference, like Explanation. Those belong at
different layers too.

They should **not** share the modifier type. The stratification *principle* is
common; the classes are not, and collapsing them into one enumeration would repeat
the error at a larger scale.

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

### Stage 4 — Re-scoped: oracle-reversal propagation

**Formerly** "epistemic graph layer", scoped to the epistemic track. That track
no longer exists, so the scope is gone with it and what remains is a question
rather than a plan.

The live question is narrow: when an oracle reverses an answer and the reversal
creates an *inconsistency* rather than merely removing support, what is the
minimal revision? `Genealogy.retract` already answers the extensional part —
which claims lose grounded support — so anything added here has to earn its place
against that baseline.

Formalisms worth evaluating **against that use case specifically**, not inherited
because they were once on a roadmap:

- AGM belief revision postulates, for coherent minimal change.
- Dynamic Epistemic Logic, for update mechanics, if multi-agent structure
  appears.
- Kripke structures, only if the application needs knowledge-vs-belief
  distinctions — nothing currently does.
- Reference: Fagin, Halpern, Moses & Vardi, *Reasoning About Knowledge*.

Do not start until a real oracle exists and has actually reversed something.
## Standing principles

Constraints that came out of building Stage 2, applying to everything after it.

### Build the space; do not preemptively prune it

Half the problem is narrowing the candidate space — but the space has to exist
first, or there is nothing to collapse. **Narrowing is a separate, explicit,
logged mechanism, never a filter applied at generation time.**

A candidate that is never generated cannot be collapsed, cannot be recorded as
rejected, and cannot be recovered when the judgement that excluded it turns out to
be wrong. That is the same failure as a parser returning only its first parse.

Worked example, from getting it wrong: `Stage2.Alternatives` originally
*suppressed* modifier fusions whose modifier was not classificatory, so
`ancient_dragon` and `red_dragon` were never generated for
`"ancient Chinese red dragon"`. The stratification was right; applying it as a
filter was wrong. It is now attached to each candidate as evidence
(`ccClass`, `ccLicensed`, `ccLayer`) and the ranking layer down-weights, rather
than the generator omitting. The space went from 2 candidates back to 4, with the
licensing information still present.

This reverses what
[Stratification](#stratification-not-all-modifiers-or-relations-are-one-kind-of-thing)
above originally claimed as a success, and that section has been corrected to say
so. Subsequent measurement settled it: the ranking layer separates all four
readings on informativity, so the two candidates filtering removed were rankable
and deleting them lost information.

### Spend computation freely

Combinatorial cost is not a reason to narrow a design. If a mechanism needs more
computation, that is rational spending, and the space being large is partly the
point.

Model enumeration scales as `2^(n|unary|) * 2^(n^2|binary|)`. Measured on the
build server:

| domain size | models | surface true in | inverse true in | inverse ⊨ surface |
|---|---|---|---|---|
| 1 | 8 | 5 | 3 | yes |
| 2 | 256 | 137 | 119 | yes |
| 3 | 32,768 | 17,303 | 15,465 | yes |

5.5s and 27 MB for all three, and the entailment is stable across domain sizes
rather than an artifact of a conveniently small one. Go bigger when a question
needs it.

Haskell's laziness makes this cheap to express: `enumerateModels` defines the
whole space and consumers take what they need, so "build the space" costs nothing
until something looks at it.

### What *is* provisional: the corpus, not the compute

The nine-case fragment and the hand-built scenarios are a stand-in for production
data, forced by what is available in this environment — **not** a statement that
toy data is sufficient. Two consequences:

- Results measured on the fragment are **lower bounds and existence proofs**, not
  performance claims. "The entailment holds over all 32,768 models at n=3" is a
  real fact; "scope readings behave like this in English" is not something this
  evaluation set can establish.
- The fixed evaluation set should **grow toward real data**, including chunked
  real corpus text, rather than staying a closed toy set. The methodology note
  below about fixing the set before comparing variants still holds — fix it, then
  extend it deliberately, and re-run the comparisons.

Same shape as the missing distributional resource: an unwired dependency, not an
architectural limit.

### Haskell is the scaffold, not an implementation detail

The type system and functional style **are** the organizing template for the
semantics and the graphs. Designing a discrete formalism on paper and then coding
it separately is redundant: written directly as types, the code *is* the design.

What the language is actually doing here:

- **ADTs are the grammar of the representation.** `Term`, `Cat`, `DRS`, `Prov`,
  `CanonCond`, `ModifierClass` are each a closed statement of what can exist.
- **Exhaustive pattern matching checks the formalism for completeness.** Adding a
  case to `Term` turns every traversal that fails to handle it into a compile
  error. That is coverage checking of the *formalism*, not just the code.
- **The type/category correspondence is machine-checked.** `catTy` states which
  semantic type each syntactic category demands, and the suite verifies every
  lexical entry inhabits it — Curry–Howard at the smallest available scale.
- **Laziness lets an unbounded candidate space be defined and consumed
  incrementally**, which is what makes the no-preemptive-pruning principle cheap.
- **Purity makes provenance honest.** A derivation cannot acquire a dependency
  that is not in its arguments, so a `Prov` tree cannot silently omit a source.

Reaching for another language for a specific job is fine where it is genuinely the
right tool — heavy numeric work on real distributional vectors being the obvious
candidate. The interface stays in Haskell, and the representation of generated
information stays here.

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

## Notes for when compression starts

Parked here because it is not needed yet and will be needed as soon as any
serious compression work begins.

### There are four notions of "same claim", and only two are built

The question "can fusion compress statements that are identical *enough*"
sounds like one question. It is four, and they do not sit on a single dial:

| Notion | Relation | Status |
|---|---|---|
| syntactic canonical equality | finest | **built** — `Fusion.compress`: sort + dedup on `CanonCond` |
| multiset equality (commutative, not idempotent) | coarser | **empty slot** — P5.4, nothing constructs one |
| logical equivalence | coarser still | **not built, and see below** |
| graded similarity | *not an equivalence relation at all* | built, weights stipulated — the fingerprint kernel |

### Fusion's compression is deterministic, and could not be otherwise

`Fusion.compress` is `sort` then `dedup` over `CanonCond`, whose `Ord` is
structural. No threshold, no score, nothing to tune. Two conditions merge exactly
when they are structurally equal after `canonicalize` — which strips provenance
and renames referents, so it is equality-up-to-renaming rather than literal
identity, but still an exact relation.

**And it could not be made probabilistic even in principle.** A similarity score
is not transitive, so no threshold on it induces an equivalence relation, so it
cannot define a quotient. "Merge anything above 0.9 similar" is not well defined:
the result depends on the order you merge in.

That is why the fingerprint kernel cannot become the compression mechanism no
matter how well its weights are fitted. It is the wrong kind of object for the
job — it ranks, it does not quotient.

### The spec overclaims here, and the gap is not closable

The old framing said this step collapses sentences that *entail the same
proposition*, which describes **logical equivalence**. `compress` implements
**syntactic canonical equality**, which is strictly finer. The overclaim is what
retired the "epistemic verification" reading of this module; the operation itself
is fine as post-verification bookkeeping.

Demonstrable: `~(P | Q)` and `~P & ~Q` are logically equivalent and produce
different `CanonCond` shapes — a `CanNot` over a disjunctive box versus two
separate `CanNot` conditions. They will not merge. Asserted as a check in
`SubstrateSpec` so the gap stays visible rather than being rediscovered.

The gap looks closable now that `Stage2.Model.equivalent` exists. It is not:

- The fragment has **binary** predicates (`read`, `see`, `love`), so it is full
  first-order, where validity is **undecidable**. Monadic first-order would be
  decidable; this is not monadic.
- `Stage2.Model.equivalent` checks a *finite* model set. Finding a counterexample
  refutes equivalence soundly. Finding none establishes nothing — two formulas
  may agree at domain size 3 and diverge at 4.

So the model layer is useful in the **opposite** direction from the one that
suggests itself first. It can safely *split* two readings that look the same; it
can never safely *merge* two that look different. Compression's honest ceiling is
a syntactic or multiset quotient, optionally sharpened by finite-model refutation
used to keep things apart.

**The model checker is a splitter, not a merger.** That reframing is the useful
part of this note.

### Adjective ordering: reuses S6's machinery, with three corrections

Conventional adjective order (`"ancient Chinese red dragon"` is natural,
`"red Chinese ancient dragon"` is marked) is a real phenomenon and the machinery
for checking it mostly already exists. Four pieces, of which two are cheap, one is
a named limitation, and one is a genuinely new inference problem.

#### 1. It is a sortedness check, unless the hierarchy is partial

The tempting move is to say this is the same linear-extension test as scope
(P6.2): assign each modifier a rank from a Cinque-style hierarchy (quantity <
subjective quality < size < shape < color < provenance < material) and check
whether the observed sequence is a linear extension of it.

That analogy holds **only if the hierarchy is partial.** The scope poset is
genuinely partial — two quantifiers can be incomparable, which is why counting
linear extensions is non-trivial there. Cinque's hierarchy is usually presented as
**total**, and a total order has exactly one linear extension: itself. The check
then degenerates to *sortedness by rank*, `O(n)`, and "linear extension" is the
wrong frame for it.

**Decide this deliberately.** A partial hierarchy — some adjective classes
genuinely free relative to each other — is the more defensible linguistic
position, and it is the version where S6's machinery is actually reused rather
than merely resembled. Total gives "is this sorted"; partial gives "is this one of
*k* admissible orders". Different question, different code.

#### 2. Order is currently truth-conditionally inert, because fusion targets the head

The natural worry is that order stops being logically free once a classificatory
modifier is in play, since adjacency would determine which fusion is available.

**Not in this implementation.** `couplingCandidates` fuses each modifier with
`headNoun` — the last predicate in the chain — and adjacency plays no role. So
permuting modifiers yields an *identical* candidate set, and adjective order is
truth-conditionally inert for classificatory modifiers just as much as for
intersective ones. Any ordering check here is therefore purely about markedness,
never about logic.

**But that is a limitation, not a result.** Nested fusion is linguistically real:
`"Chinese red-dragon"` and `"Chinese-dragon that is red"` differ. The head-only
rule never produces `chinese_red_dragon`, nor a fusion over an already-fused head,
so it **under-generates**. If nested fusion were added, adjacency would matter,
order would become logically relevant, and the worry above would be correct.

Recorded as a named under-generation so the inertness is not mistaken for a
finding about language.

#### 3. Inversion count, not hashing — and it cancels unless alternatives differ

A hash answers "same or not". The right measure for "how far from conventional
order" is graded: **inversion count**, i.e. Kendall tau distance to the
rank-sorted sequence.

The natural home is the RSA speaker cost, which P8.6 already shows behaving as a
knob (implicature weakens `0.808 → 0.835 → 0.853` as paraphrase cost rises). But
there is a constraint that would otherwise be discovered the hard way:

> In `S(u|m) ∝ exp(α(log L(m|u) − cost(u)))` and `L1(m|u) ∝ prior(m) · S(u|m)`, a
> cost attached to the **observed** utterance is uniform in `m` and therefore
> **cancels in normalization.**

Adding order-markedness cost to the observed utterance alone changes the posterior
over readings by exactly nothing. It does work only if the *alternatives differ*
in order-markedness — if some readings are more naturally expressed with a
different word order, so cost varies across the utterance set. Plausible for
coupled readings, but it has to be built that way on purpose.

Without that, this is an addition that compiles, runs, changes no number, and
takes a while to diagnose.

#### 4. Working backwards is abduction, and there is a cheap first version

"Given an order that violates the hierarchy, infer which class assignment would
make it conform" is genuine abduction: surface order as *evidence* for class
disambiguation, running the check in reverse.

It only has work to do if class assignment is uncertain, and
`fragmentModifierClasses :: M.Map String ModifierClass` is deterministic. The full
version needs that table to become a distribution — the same stipulated-to-be-fitted
shape as the fingerprint weights (P9.4).

**But a cheaper first version already has its hook.** `ambiguousModifiers` exists
and records where the table is *making a choice rather than reporting a fact* —
currently `old`, intersective in `"an old man"` and subsective in
`"an old friend"`. Abduction can run over just the flagged entries, generating
candidates for each admissible class, without converting the whole table to a
distribution first. Consistent with build-the-space, and it reuses something
already present.

### Plural predication is a coverage gap compression will hit

Recorded here because the collective/distributive split produces multiple readings
from one span, which is exactly the situation compression has to adjudicate.

For `"There are 5 monkeys. 5 monkeys ate bananas."` the phenomenon decomposes
into **two** problems living in different places, and conflating them is what
makes it look like one:

| Sub-problem | Where it belongs |
|---|---|
| does the repeated NP corefer, or introduce a fresh group? | discourse level — genuinely SDRT, since the segment relation constrains the right frontier and hence accessibility |
| given a fixed group, collective or distributive? | clause-internal candidate generation, alongside scope permutation |

Both are candidates rather than facts: `"5 monkeys ate bananas"` can describe a
different five, so the space is at least {coreferent, novel} × {collective,
distributive}.

This would be a **better motivating case for SDRT** than anything in the current
fragment. Elaboration or Background favours coreference; Narration more readily
licenses a novel group.

Note what changed since this was written and what did not. The threading tie-in
now has a three-sentence example where the relation does real disambiguating work
(`"A student arrived. Mary smiles. She reads a book."`), so the mechanism is no
longer unexercised. But that example turns on *pronoun* accessibility, which the
frontier already governs. The plural case turns on whether a repeated **full NP**
corefers, which needs NP-level anaphora — prerequisite 3 below, still absent. So
this remains the better case, for a narrower reason than originally stated.

Three prerequisites, none present:

1. **A numeral determiner.** The lexicon has three distinct determiner meanings
   (`every`; `a`/`an`/`some`; `no`) and no numerals or plural morphology. A
   lexicon gap, cheap.
2. **Plural individuals — cheaper than it looks.** Link's mereology does **not**
   add a type. It enriches the domain of `e` into a complete atomic join
   semilattice, so groups are inhabitants of `e` rather than a new sort. `Ty`,
   `catTy` and `Semantics.Lambda` are untouched. What changes is
   `Stage2.Model`'s `modelDomain :: [Int]`, which becomes atom-sets with a
   part-of order — one module, sitting next to the entailment machinery that
   would have to reason about it anyway.
3. **NP-level anaphora.** Deliberately absent: resolution is "most recent
   accessible referent" and nothing else. Recognizing that a repeated full NP
   corefers is a harder matching problem than resolving a pronoun, and none of
   the nine cases exercise it.

It is also a **new stratification class**, closer in spirit to the modifier table
than to the scope code, layered by what settles it:

| Layer | Case | Example |
|---|---|---|
| 1 | explicit cue | `each` forces distributive, `together` forces collective |
| 2 | predicate lexical semantics | `gathered` is obligatorily collective; `smiled` obligatorily distributive |
| 3 | genuinely underdetermined | `ate bananas` |

Layer 2 is the analogue of **privative** modifiers: a class where one candidate is
not merely dispreferred but ungrammatical. `"The monkeys gathered"` has no
distributive reading at all. Generating it is still correct; the ranking layer
must be able to send it to zero rather than merely low.

## Non-goals / guardrails

- Do **not** treat any internal check as evidence. Typedness, canonical equality
  and provability are admission criteria and bookkeeping. Only an external oracle
  produces evidence, and only for the domain it covers.
- Do **not** collapse `Unknown` into `Refuted`, in code or in reporting. Doing so
  manufactures grounding for uncovered domains, which is the specific failure this
  architecture is built to prevent.
- Do **not** fuse before verifying. A collapse performed first destroys the
  derivation record retraction depends on. The stage order is a correctness
  requirement, not a convention.
- Do **not** attempt to make pragmatics fully discrete/provable — it is
  structurally open-world and non-monotonic. The target is a well-calibrated
  probabilistic candidate layer with explicit collapse points, not a "pragmatics
  prover".
- Do **not** trust LLM output as ground truth for parses or proofs without an
  independent symbolic check. LLMs are candidate generators; they cannot certify
  their own output. Standard practice in autoformalization: the model proposes,
  the checker verifies — and here, the oracle grounds.
- Do **not** conflate "expand the representational space" (tensors, embeddings,
  kernels — useful for search and separability) with "avoid information loss".
  Expansion changes *where* loss can occur; it does not eliminate it.
- Do **not** build the epistemic graph layer until an oracle-reversal use case
  actually demands it, and then derive it from that use case.
