# Architecture

Reference document for the text-to-logic pipeline. This is the spec; the code
implements it stage by stage.

## Goal

Convert natural language text into discrete, checkable logical / proof-theoretic
representations, with an explicit, *separated* layer for handling ambiguity and
pragmatics probabilistically before collapsing to a final form.

Two tracks off the same underlying augmentation stage. Each has two names, used
interchangeably throughout this document:

| Track | Also called | Character |
|---|---|---|
| **epistemic** | **truth-mode** | lossy canonical compression |
| **letra** | **provenance-mode** | derivation-preserving |

A third track, **conversational**, is described below. It has no second name.

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

## epistemic (truth-mode) vs. letra (provenance-mode)

> `truth-mode` **is** the epistemic track and `provenance-mode` **is** letra —
> the same two things under two sets of names, not modes feeding tracks. The
> branch names came first; the track names name them better. Both are kept
> because the branch names are what is checked out and pushed.
>
> Extended by [Three tracks](#three-tracks-epistemic-conversational-letra) below,
> which adds the third track and the axes all three differ on.

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

The augmentation/generation stage is **identical** for both tracks. Only the
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

- **epistemic**, a.k.a. **truth-mode** (*firm domain oracle*) — has a domain
  verifier. Closed-world, mechanical. Must collapse to a single proposition to
  hand to the checker.
- **conversational** (*probabilistic domain oracle*) — live cross-lingual
  interpretation. Propagates pragmatics probabilistically, steered by inline
  edits to a streamed best-effort translation. Session-scoped in the strong
  sense: nothing machine-readable survives the conversation. Sits between the
  other two.
- **letra**, a.k.a. **provenance-mode** (*provenance, no oracle*) — preserves
  **genealogy and provenance** as it retains from individual graphs and nodes.
  Not necessarily any domain verifier. Does not start from nothing: it retrieves
  from stored state and builds progressively.

The ordering is not arbitrary. The tracks differ by **how firm their warrant
is**, and conversational is literally in between:

| | epistemic<br>(truth-mode) | conversational | letra<br>(provenance-mode) |
|---|---|---|---|
| Oracle | firm, binary | **probabilistic, graded** | none |
| Collapse | must, then verify | **provisional, revisable** | must not |
| State lifetime | per-run | **per-conversation** | persistent, accumulating |
| `Prov` used for | traceability to spans | **dependency tracking for rollback** | genealogy / lineage |
| Rejected candidates | dropped after verify | **retained in-session, then dropped** | retained indefinitely |
| Core invariant | well-typedness | **calibration + revisability** | lineage reachability |
| Uses Stage 2 | yes | yes, and cannot work without it | yes |
| Uses Stage 3 | when rollback is wanted | cannot work without it | open |

Stage 4 (epistemic graphs) sits on the epistemic track. The branch `truth-mode`
**is** the epistemic track and the branch `provenance-mode` **is** letra — same
things, two naming schemes, not modes that feed tracks. The conversational track
has a branch, `conversational`, but no code yet.

### Augmentation is general, not a per-track option

An earlier version of the table above marked Stage 2 as "optional / essential /
maybe" across the tracks. That was wrong, and the error mattered.

**Augmentation is useful in every case.** It is always worth understanding a
statement from every angle before collapsing, because the additional angles
*derive additional insight* — and because the augmentation layer's real job is to
make sure the signals are not lost before anything commits. A track that collapses
straight off Stage 1 has thrown away information it never looked at.

What differs between tracks is **what each does with the augmented candidate
set**, not whether it wants one:

| Track | What it does with the candidate set |
|---|---|
| epistemic | collapses it canonically, then verifies the survivor |
| conversational | keeps it live and reweights it as the conversation proceeds |
| letra | retains it, with each candidate's lineage intact |

All three need the set generated and scored first. Only the disposition differs.
This is the same shape as the collapse seam: shared machinery, divergent use.

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

The language-to-formal-representation theme is the **same** as the other tracks'.
This is another implementation of that theme for a specific use case where it is
genuinely useful — not a different project wearing the same vocabulary.

**Read this section as a scaffold, not a closed design.** Tensions are recorded
where they are still tensions, on the expectation that building will make the
resolutions obvious and they get filled in then. A tension written down and left
open is more useful here than one closed prematurely by deferring to whatever the
literature happens to do — see the note on how to read the prior-art table below.

Four things follow, and three of them are already specified elsewhere in this
document:

1. **The soft oracle is RSA.** Stage 2's Rational Speech Act layer is Bayesian
   listener/speaker reasoning over candidate readings — graded warrant over
   intended meaning, which is exactly a probabilistic domain oracle. This track
   is the first that *requires* Stage 2 rather than treating it as enrichment.

2. **The steering function is Stage 3's rollback trigger.** Stage 3 already
   specifies "commit to the highest-confidence reading, proceed, but keep a path
   to unwind and re-derive if later context contradicts an earlier pragmatic
   inference." A steering input — an inline edit to the streamed translation,
   supplied mid-conversation — *is* a later-context contradiction. In RSA terms
   it is a prior update: the human pins part of the mapping and the posterior
   over every downstream reading is reweighted. Propagation falls out of that;
   it does not need separate machinery.

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
  contradict, so later must win. Note this is *within* the live joint thread
  only — see the state model below, which removed the persistent substrate that
  would have made this letra's supersession problem.
- **The two speakers are not symmetric.** Pragmatic expectations differ per
  participant. Note that the state-model decision below removed per-speaker
  *persistent* profiles; whether asymmetry needs representing *within* a session
  is open.

#### Turn cycle

Two-party, L1 ↔ L2:

```
L1E (utterance) → L2S (translate 1→2) → L2E (reply)
→ L1S (translate reply back) → L1E (responds) → L2S → ...
```

Every human turn (`E`) is followed by a system translation turn (`S`) targeting
the other party. Standard interpreter-mediated shape — no open questions here.

#### State model: fully session-scoped, no persistence

**This supersedes any earlier description of this track borrowing persistent
per-speaker state.**

An earlier plan had three graph scopes — an L1 profile, an L2 profile, and a
joint thread — with entrainment edges promoting session content into persistent
per-speaker profiles at teardown. **That is reversed.**

Rationale: the system's purpose is to help people build their own pragmatic
competence, not to get quietly better at not needing them to. A persistent
profile graph that auto-resolves recurring ambiguity is a permanent crutch — the
better it works, the less the human ever needs to learn.

- No L1 profile graph, no L2 profile graph. Nothing persists as
  **machine-readable** state across sessions.
- Only the joint thread exists, and it lives and dies with one conversation, in
  full. No deferred-commit step, no entrainment promotion, nothing carried
  forward.
- Each new session starts from the same graph-free footing as the first one ever
  run for that pair. Intentional, not a limitation to fix later.

Two consequences, both of which supersede the tier map below:

1. This track **no longer borrows letra's tier 2** in the way that map
   originally described. With no persistent substrate there is nothing to borrow
   retrieval semantics from, so the two tracks are more cleanly separated than
   implied.
2. Because nothing crosses into persistent state, this track **never needs
   letra's not-yet-built supersession mechanism** ("belief updated at T, prior
   not deleted"). Rollback only ever touches the live joint thread, which is
   discarded at teardown anyway. That gap stays real *for letra*; conversational
   no longer supplies a second reason to build it.

**Three things to hold onto about the rationale** — concerns, not decisions:

- **`machine-readable` is load-bearing.** Read literally, "nothing persists"
  would forbid the post-session artifact, which is the feature that actually
  serves the pedagogical goal — spaced repetition works by persisting what you
  got wrong. Human-readable persistence is not excluded and should not later be
  read as excluded.
- **No-persistence does not by itself remove the crutch.** The wrapped MT engine
  is an enormous persistent store of pragmatic defaults. The session starts
  graph-free; the *system* starts heavily pre-loaded. "Each session starts from
  the same footing as the first" is true of this track's own state and false of
  the system as a whole. Worth stating accurately so the pedagogical claim is not
  over-trusted.
- **L1 and L2 need not both be learners.** Blanket no-persistence treats them
  symmetrically, but a language learner and a shopkeeper are not in the same
  position. Open.

#### Steering is internal, probabilistic, and under the hood

**The primary mechanism is the system steering itself** — propagating pragmatic
constraints through its own state, probabilistically, without a human
intervening. External steering (the inline edit described next) is a *corrective
channel*, not the control path. Getting the internal propagation right is the
goal; the edit path exists because the internal mechanism will sometimes be
wrong.

One unifying consequence, worth stating because it collapses a lot of apparent
complexity: **an edit and an ordinary following utterance are the same kind of
thing to the machinery** — an observation that updates the distribution over
readings. They differ in confidence, not in kind. CRSA's belief terms already
work this way: `B_L,t` and `B_S,t` update from utterance history with no human in
the loop. An edit is simply a high-confidence observation entering the same
update.

That reframing demotes several questions that look blocking if you treat the
human edit as the control path — including "who performs the edit" below. It does
not eliminate them; it puts them in the right place.

#### Interaction posture: autocomplete, not clarification

The actual differentiator. It **resolves** the earlier open question of whether a
steering input binds a term-pair or a full reading — by not requiring the human
to state a correction in the abstract at all.

- The system streams its best-effort translation inline, ghost-text style, rather
  than pausing to ask a disambiguating question.
- The human either keeps talking (implicit accept — the majority case, zero
  interaction cost) or makes a small inline edit (implicit correction).
- **The steering signal is the diff** between proposed and human-retained text,
  not a separately elicited statement. Term / sense / reading scope is *inferred
  from the diff* rather than declared.
- This is the **IMTLab** interaction model — keep / insert / replace / delete /
  blank-fill, plus prefix-constrained decoding — **not** the CSLT
  clarification-dialogue model.
- **Do not build a clarifying-question flow on the live path.** It costs a
  conversational turn and works directly against the fluidity goal. CSLT-style
  clarification, if wanted at all, belongs in the post-session path.
- Do not rebuild the MT engine or the constrained decoding. Wrap an existing
  engine; wrap IMTLab or an equivalent for the edit-operation harness. Already in
  the non-goals, and it binds harder now that the interaction model is pinned to
  edit-diffs specifically.

##### Open, and secondary: who performs the edit?

IMTLab's edit model assumes a **bilingual translator** editing target text.
Neither participant here is that. For the `L2S` turn:

- L1 produced the utterance but cannot read L2, so cannot judge the proposal.
- L2 can read the proposal but does not know what L1 meant.

Three candidate resolutions, none costless:

1. **Edit the back-translation.** Show L1 a round-trip into L1 and let them edit
   that; the diff steers the forward translation. Keeps operation monolingual and
   reuses the round-trip machinery already specified as the evaluation method.
   Cost: back-translation is lossy, so an edit to the round-trip does not
   uniquely determine the intended change to the forward text — you are steering
   through a noisy channel.
2. **Edit the source.** L1 sees their own transcribed utterance with ambiguity
   marked, and rephrases. Monolingually safe, but this is *not* the IMTLab
   target-edit model: the diff is in L1 and the constrained-decoding hook is a
   different one.
3. **Recipient-side edit.** L2 edits the L2 text, signalling "this did not parse
   / I think you meant X." Monolingually coherent, and well motivated by
   conversation analysis — *other*-initiated repair is the dominant repair type
   in real conversation, and the recipient is the party actually positioned to
   notice the failure.

Priority note: this was previously recorded as blocking mechanical
specification of the live loop. It is not, given that steering is primarily
internal — the loop is specified by the internal propagation, and the edit path
is a corrective channel layered on it. It still has to be answered before the
*correction* path ships, because it determines where the diff lives and therefore
what edit-to-scope inference operates on. But it does not gate the core.

#### Rollback scope

- **No edit** → commit stands, belief terms update, nothing surfaces.
- **Small edit** → reweighting and invalidation of only what that edit implicates
  downstream, not a full session stop.

This keeps Stage 3's commit-then-unwind design intact. The addition is that
**unwind scope is sized to the edit**, not to the whole thread — otherwise the
correction becomes the fluidity cost it was meant to avoid.

One correction to the no-edit case: **silence is not confirmation.** A non-edit
may mean the human did not notice, did not care, or accepted a wrong reading. If
default-accept is treated as positive evidence, the calibration invariant this
track inherits will drift optimistically. The belief update should read *not
disconfirmed*, not *confirmed*. This is also part of why the
`default-accepted` / `corrected` tag below is worth having.

#### Where CRSA fits

CRSA's belief terms (`B_L,t`, `B_S,t` — each agent's running belief about the
other's private meaning, built from utterance history) are the right shape for
propagating an edit's effect automatically, once the edit is treated as an
observed utterance. Three mismatches to design around rather than assume away:

- **Fixed prior vs. lexicon mutation.** CRSA assumes a fixed prior over private
  meanings and task target for the whole conversation — it models converging
  beliefs about a *static* truth, not renegotiating the truth itself. An edit
  saying "this word maps to that word from here on" is closer to mutating the
  lexicon function than to updating a belief. CRSA does not test this case;
  expect to hand-engineer the lexicon-mutation path the way the paper's own
  `CRSA-W_t` variant hand-encoded one narrow structural rule, rather than finding
  a general mechanism to reuse.

  Sharper: a mid-conversation lexicon mutation also breaks CRSA's **common-ground**
  assumption, not only its prior. If L1 steers a term, that mutation is common
  ground only if L2 knows it happened — and in an interpreter-mediated setting it
  is invisible to L2. The two belief terms then diverge in a way CRSA does not
  model.
- **Unproven at this scale.** CRSA's real-dialogue (LLM-driven) results showed
  the multi-turn belief-sharpening effect barely beating classic single-turn RSA;
  the clean win was only in the closed synthetic reference game. Treat CRSA as
  the right theoretical skeleton, unproven for open-vocabulary live dialogue.
- **Per-turn cost** is `O(K · |M_A| · |M_B| · |Y| · |U_t|)`. That is the number
  to plug into the still-open latency budget once utterance and meaning space
  sizes are bounded for a concrete use case — a coffee order has a small
  effective `|U_t|`; open conversation does not.

  Mitigation worth testing before optimizing anything: cap `K` at 1 (plain
  single-turn RSA) by default and escalate to full CRSA only when the candidate
  set is genuinely contested. That pairs with the surfaced-ambiguity behaviour
  this track already wants, and keeps the expensive path rare.

#### Post-session artifact

Open, and deliberately deprioritized — mechanical correctness of the live loop
comes first.

If built, weight it toward corrected points over accepted-by-default points, per
this document's own principle that disagreements are more valuable than
agreements.

**Required now, even though nothing consumes it yet:** Stage 3 must tag each
resolution `default-accepted` vs `corrected` as it happens. Cheap to add now,
expensive to retrofit — the same argument as provenance tagging from day one.

#### Prior art, and where this track actually differs

Checked against the literature in August 2026 rather than assumed. Two findings,
pointing in opposite directions. Both are recorded, because taking either one
alone gets the design wrong.

##### One: the component mechanisms are mature

Do not rebuild these.

| Mechanism | Prior art |
|---|---|
| Term-pair constraints | lexically constrained decoding: grid beam search, dynamic beam allocation |
| Incremental output | simultaneous MT: wait-*k* policies, re-translation with stability/latency tradeoffs |
| RSA over multi-turn dialogue | Collaborative RSA (2026); RSA already applied to translation, captioning, dialogue |
| Incremental belief propagation over a graph | ReDST's bipartite belief propagator; dialogue state tracking generally |
| Structured dialogue state plus user corrections | MultiWOZ 2.2/2.3, CorrectionLM, ReacTOD's symbolic validator |
| Dependency-tracked invalidation of dependents | Truth Maintenance Systems, dependency-directed backtracking, incremental tabling, incremental chart parsing |
| Harness for building / evaluating / diagnosing IMT systems | IMTLab, open source |
| Monolingual vs bilingual context for dialogue MT disambiguation | BSD-corpus work on speech dialogue translation |

Separately, the **external** steering path — which this track deliberately does
*not* take, and which is the most heavily protected area:

| Mechanism | Prior art |
|---|---|
| Source-side clarification to a monolingual speaker (*"did you mean nail as in 'they used nails to fix the door', or 'she painted her nails red'"*) | interactive conversational spoken language translation (CSLT), *Machine Translation* journal 2015 |
| Ambiguity detection from ASR confidence + hypothesis plausibility + language context | same lineage; US 8214197, and the "Device for extracting information from a dialog" patent family |
| Steering that reweights the model — the selected sense raises that word's translation probability | same |

##### Two: none of that is this track's mechanism

CSLT's internal machinery — confidence scoring, hypothesis plausibility, language
context — exists to decide **when to ask a human**. The resolution itself is
always external. The human is the oracle, which is precisely why it works.

**This track uses the same internal signals to resolve *without* asking.** Same
signal, opposite use, and the difference is not one of degree: removing the human
changes what the system has to do, because there is no longer an oracle to defer
to. The patents claim clarification-dialogue methods. A live path with no
clarifying question is a different mechanism, not a variant of theirs.

**How to read the first table.** It bounds what is already handled *at the decoder
and interaction level*. It does not bound what is worth doing. Every row in it is
lossy at the pragmatic layer, and that lossiness is not incidental — it is the gap
this track exists to fill. Prior art tells you where the current ceiling is; the
points where it leaks are the targets, not reasons to defer.

##### Stating the novelty claim so it survives contact

Stated broadly, "internal probabilistic steering" describes what every NMT decoder
already does — pick a reading silently under uncertainty. Every component above has
prior art, so the broad claim invites the obvious dismissal: *"that is a language
model with a belief tracker."*

The narrow claim does not, and it is the one worth defending:

> **Probabilistic — not boolean — dependency-directed belief revision over
> pragmatic readings, used to resolve internally rather than to trigger
> escalation, in live cross-lingual conversation.**

The load-bearing word is *probabilistic*. Classical TMS justifications are
boolean: an assumption is in or out, and retraction is exact. Pragmatic readings
are graded, so retraction becomes **reweight-and-propagate** rather than
remove-and-recompute.

That combination is the underexplored part, and note *where* it is
underexplored — between two mature fields rather than inside either one:
probabilistic pragmatics without addressable state, symbolic revision without
gradedness. The seam is the opportunity.

##### Where the "wrap, don't rebuild" boundary falls

- **Wrap the decoder.** Surface generation, lexically constrained decoding,
  incremental output policies. Mature; duplicating them buys nothing.
- **Build the pragmatic layer.** This is exactly where existing systems are
  lossy, and the lossiness follows from their architecture: an opaque engine does
  not expose an inference chain, so there is nothing to attach dependency edges
  to and nothing to invalidate. **You cannot add dependency-tracked retraction
  over a black box.**

Stated flat, "wrap, don't rebuild" contradicts the point of the track. The
resolution is the split this repository already has: the engine is a **candidate
generator**, and the DRS plus `Prov` is the **addressable state** that reasoning
and invalidation run over. The engine informs that state; it does not own it.
Same non-goal about LLMs as candidate generators, with the boundary drawn in the
right place.

##### What did not turn up

1. **Dependency-tracked retraction of pragmatic inference chains.** DST
   corrections fix *slot values*; ReacTOD enforces coreference consistency on
   state update. Neither locates and unwinds *every downstream inference that
   rested on a corrected reading*. That is the `Prov`-as-dependency-edges job.
   TMS does do this — boolean-only, which is the port cost noted above.
2. **Repair rate as the evaluation target.** Dialogue repair is well studied as a
   *phenomenon*, and conversational-AI metrics exist, but repair rate and
   time-to-mutual-understanding do not appear to be used as the objective for a
   cross-lingual conversation system. MT metrics score a text; the claim here is
   about a conversation *converging*, which is a different quantity.
3. **A symbolic discourse representation (DRT plus provenance) as the pragmatic
   state**, rather than context-window conditioning or slot filling. Inspectable
   and surgically correctable, not an opaque activation.

##### Constraints that follow

- **Wrap the decoder; build the pragmatic layer.** Per the boundary note above.
  Do not rebuild constrained decoding or a wait-*k* policy. Use an existing
  engine, and IMTLab or equivalent for the edit-operation harness.
- **Measure repair, not BLEU.** Test the premise with a wizard-of-oz comparison
  before building anything.

  One correction to how that test should be set up: the human in the
  wizard-of-oz stands in for the **internal mechanism**, not for a steering UI.
  They act as an oracle performing the pragmatic resolution the system will
  eventually do itself. What is being tested is whether *correct pragmatic
  resolution reduces repair turns at all*, independent of who performs it. If
  repair turns do not drop even with a perfect human oracle in the loop, the
  premise is wrong and no amount of internal machinery will rescue it. That is
  worth learning in a week rather than a year.

##### Non-engineering risk

There are granted patents covering source-side ambiguity resolution in
interactive translation. A freedom-to-operate question for a product rather than
for research; it needs real legal advice rather than a note in a design document,
and it should not be discovered late.

One consequence in this design's favour, and explicitly not legal advice: keeping
clarification off the live path both differentiates the mechanism technically
*and* reduces exposure, since claims directed at clarification methods are much
less likely to read on a system that never clarifies.

### Tier map as of today

| Tier | Shared base | epistemic<br>(truth-mode) | conversational | letra<br>(provenance-mode) |
|---|---|---|---|---|
| 0–2 | `Provenance`, `Trace`, `DRT.Canonical`, `DRT.Types`, `Collapse.Class`, `DRT.Build.Discourse` | | | |
| 3 | | `Syntax/*`, `Semantics.Lambda`, `typeOf` as gate | Stage 2 RSA as soft oracle | genealogy DAG, node identity |
| 4 | | canonical compression, `Collapse.Truth` | Stage 3 speculative commit + rollback | per-individual graphs, retrieval |
| 5 | | Agda/Coq/Lean; Stage 4 Kripke/DEL/AGM | incremental interpretation under a latency budget | supersession, lineage reachability |

Low-tier borrows, in BTD6 terms: **superseded.** This map originally had the
conversational track taking tier-2 letra — session-scoped supersession and
per-speaker state. The state-model decision above removed the persistent
substrate that borrow depended on, so conversational and letra are more cleanly
separated than this map implies: conversational borrows letra's *shape* for
nothing, and needs no part of its supersession machinery. It still shares the
tier 0–2 base with both other tracks.

One boundary worth being aware of: **`Syntax/*` and `Fragment.hs` sit on `main`
but are used only by the epistemic path.** Composition from a closed lexicon is
not something letra needs. That is fine as it stands — `main` is the shared
repository, not a minimal core — but it means "on `main`" and "shared base" are
not the same set, and the tier column above is the authority on which is which.

### Decisions and open questions

**Decided.** The tracks stay as branches in this repo. No module restructure
for now. The branches keep the names `truth-mode` and `provenance-mode`, which
are aliases for epistemic and letra rather than modes of them. The tracks are
built on and extended separately. The conversational track is defined here and
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
6. ~~Conversational: term pair or reading?~~ **Resolved** by the autocomplete
   posture: neither is declared. The steering signal is the edit diff, and scope
   is inferred from it.
7. Conversational: two-party only, or N-party? Everything designed so far — turn
   cycle, belief terms, joint thread — assumes exactly two parties. N > 2 changes
   the shape of the joint thread and the belief-term factorization, not just the
   turn-cycle diagram. It also breaks the ghost-text edit model, since there is
   no longer a single target text to edit.
8. Conversational: **who performs the edit?** Back-translation, source-side, or
   recipient-side — see the subsection above. Gates the *correction* path, not
   the core loop: steering is primarily internal, so the live loop is specified
   by the internal propagation regardless of how this resolves.
9. Conversational: what exactly counts as a **session boundary**? Needs a
   concrete definition (e.g. one conversation-instance identifier) before
   "session-scoped, discarded at teardown" is implementable rather than a stated
   policy. Note the awkward case: a dropped connection resuming 30 seconds later
   should probably not reset to graph-free, which means either a resumption
   window or accepting the reset.
10. Conversational: **edit-to-scope inference.** Given a human's inline edit,
    determine how far downstream to invalidate. The single most load-bearing
    unbuilt piece of the live loop, and unclaimed by anything in the prior-art
    review — ReacTOD and CorrectionLM correct a single slot; neither traces
    dependents.

    Pointer, revised. The closest formalism is a **Truth Maintenance System**,
    specifically an **assumption-based TMS (ATMS)** — which maintains several
    mutually consistent contexts at once, with labels recording which
    assumptions support each. That is a close fit for retaining candidate
    readings alongside their supporting assumptions in-session, which is what
    `selRejected` is for. **Dependency-directed backtracking** is the retraction
    mechanism.

    Secondary: the incremental-computation frameworks (self-adjusting
    computation, Adapton, Salsa, demand-driven build systems) are the same shape
    optimized for exactness and speed rather than for belief — useful for the
    mechanics, less aligned on semantics. Incremental NLP already applies the
    idea in chart parsing: track which parts of the input an output rests on, and
    recompute only the affected region under a non-monotonic change.

    The port is not free. **TMS is boolean; this is graded.** Retraction has to
    become reweight-and-propagate rather than remove-and-recompute, which is the
    novelty claim above and the reason this is a port with real work in it rather
    than a lift.
   That would make the shared base a checked invariant rather than a convention.

## Repository layout

`main` holds everything shared. The track branches only ever touch their own
collapse backend and its tests.

```
main ──┬── Provenance, Syntax (CCG), Semantics (lambda), DRT, Collapse.Class
       │
       ├── truth-mode      = epistemic → NL2Proof/Collapse/Truth.hs      + tests
       ├── provenance-mode = letra     → NL2Proof/Collapse/Provenance.hs + tests
       └── conversational              → docs only, no backend yet

merge direction: main ──> every track branch (never sideways)
```

Shared fixes land on `main` and merge down. Nothing merges between the track
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

Concretely, this cut the coupling case from four generated readings to two:
restricting fusion to classificatory modifiers stopped `ancient_chinese` and
`chinese_red` being proposed as English subkinds. A generator that ignores the
distinction spends the ranking layer's evidence rejecting its own noise.

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

### Stage 4 — Epistemic graph layer (later, separate formalism)

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
