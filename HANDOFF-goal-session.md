# Handoff: the shape of the problem, layer by layer

This is not a task list with a completion order. It's a description of one
connected system as it actually stands right now, split into layers by how
abstract each tension is — from "a type is missing a constructor" up to
"how does an autonomous knowledge base avoid becoming an echo chamber." All
of it is live for this session. Nothing here is deferred, someday, or out
of scope — some layers are just more tractable *today* because they have
more concrete data sitting under them (CCGbank) and others are more
tractable *later* because they need something built at a lower layer first
(a working reward mechanism before a graph-trust mechanism can borrow its
answer). That's a dependency, not a priority ranking, and it's expected
that work will move up and down this stack rather than clearing it bottom
to top.

The throughline across every layer, stated once so it doesn't need
restating at each one: **a system cannot use its own internal consistency
as the check on the step that produced the thing being checked.** That
sentence is `Reward.hs`'s own opening line, but it's not scoped to that
file — every layer below is a fresh instance of the identical structural
question: is there something *external* doing the checking here, or is
this layer quietly grading its own homework? Some layers already have a
real answer (CCG's `typeOf`, for lexicon content). Some have a candidate
answer that needs hardening (a backtester, if its statistical suite is
rigorous). Some have no answer yet and shouldn't pretend otherwise (raw
news claims). Track which is which as you move through this, because
conflating "checked" with "internally consistent" is the one mistake this
whole stack exists to prevent.

## Layer 0 — what's physically true right now, confirmed this session

- Server: `gram@100.96.227.128`. `~/nl2proof/` (this repo) and `~/ccgbank/`
  (the LDC2005T13 corpus, extracted to `~/ccgbank/ccgbank_1_1/`) sit as
  siblings. `~/nl2proof/` showed no `.git/` in a `tree` listing — confirm
  whether this checkout is actually a git working copy before assuming
  commits work here.
- `~/ccgbank/ccgbank_1_1/data/` has confirmed `TGREP2/` and `RAW/`
  subdirectories; `AUTO/`/`PARG/` subdirs are described in the manual
  (`doc/AUTO.readme`, `doc/PARG.readme`) but weren't enumerated this
  session — confirm the exact path before writing an ingestion pass.
- A separate, unrelated workspace `~/projects/` sits alongside both,
  containing a trading/agent-pipeline system (`strategy-core`, `quant-lib`,
  `shared/backtesting/` with real accumulating results, a hypothesis
  pipeline) and an epistemic/knowledge-graph skeleton
  (`shared/context_graph/`, schemas, a distillation pipeline). The owner
  describes the epistemic-graph piece as trivial and slated for a complete
  overhaul, not incremental extension.
- A second, separately hosted repo, `aiqs-org/agentic-qr` on GitHub, is
  described as "connected" to this work. The exact relationship (shared
  library? fork? parallel concern under the same account?) hasn't been
  established — ask rather than assume conventions carry over between the
  two.
- `nl2proof`'s current code, read directly this session:
  - `Cat` (`Syntax/Category.hs`) is bare — `S`, `NP`, `N`, and slash
    constructors only. No feature annotations, no `PP`.
  - `Ty` (`Semantics/Lambda.hs`) has exactly two primitives: `TyE`, `TyT`.
  - `signWellTyped`/`typeOf` is the one real mechanical gate that exists
    today: an entry is admissible iff its meaning inhabits the type its
    category demands.
  - `fragmentLexicon` is a hand-authored 9-case fixture. Two known defects
    (an inert SDRT frontier, an unsound DRS merge) and two unreachable test
    properties exist *because* the corpus is too small to discriminate
    them — this is documented in the repo's own words as "a green suite
    means no case exercises this, not that it works."
  - `Reward.hs`'s `rwScore` — the field the module's own header calls "the
    reward" — sums only `wConfirmed`, `wEntailed`, `wRefuted`,
    `wUncovered`. It computes `nCorroborated`/`nNovel` faithfully but never
    includes them in the sum. Detail in Layer 4.
  - Composition rules (`fwdComp`/`bwdComp`) exist in code but aren't used
    by the default parser.

## Operating conventions for this session

**Commit and push freely, within `~/nl2proof`.** No need to pause for
approval to commit or push changes to this repo — that includes schema
decisions made under the Layer 1 autonomy grant below. This does **not**
extend to `~/projects` (the trading system) or anything capital-relevant or
externally destructive — those still require explicit confirmation before
acting, per Layer 3/9's scope boundary. One thing worth a deliberate check
before any push, given Layer 0's note on CCGbank's LDC licensing: confirm
no raw or bulk-derived CCGbank data is being committed to what may be a
public repo — the corpus stays at `~/ccgbank/`, outside the repo, on
purpose.

**Use the status-tag convention from the first findings log as the
standard**, not an improvisation specific to that pass: `[proved]`
(theorem of the calculus), `[checked]` (asserted in a test suite),
`[measured]` (came out of a run), `[conjectured]` (believed, unverified),
`[stipulated]` (chosen, not derived), `[structural]` (the object or its use
is wrong, and no amount of data fixes it). Apply it consistently across
every layer's findings, not just Layers 0–2.

**Verify a claim against actual tool/repo state before writing it into the
findings log — don't describe an action from memory.** This isn't
hypothetical caution: the first findings log stated "nothing committed this
session" while a commit sat at `HEAD` with a clean working tree. Before
logging that something was committed, built, tested, or measured, actually
run `git status`/`git log`, the build, or the test suite and read its real
output, rather than narrating what was intended to happen.

**Overturning a previous `[stipulated]` decision is itself a logged act,
never a silent replacement.** If a later pass changes an earlier schema
choice, the findings log entry for that change should name what it's
overturning and why, so the history of *why* the schema looks the way it
does stays legible across sessions.

**Don't end a session just because one thread hit a legitimate pause.**
Per the handoff's own "move up and down the stack" instruction: if a task
is genuinely blocked (needs review, needs an oracle that doesn't exist yet,
needs data not yet available), that's a reason to shift to a different
layer, not a reason to stop. A session ending early because it only worked
one connected thread top-to-bottom is the exact pattern flagged as
questionable in this project's own history — don't repeat it.

## Layer 1 — the syntactic substrate: `Cat` and `Ty` can't represent what CCGbank says

CCGbank's `.auto` derivations carry feature-annotated categories —
`S[dcl]`, `S[adj]`, `S[b]`, `NP[nb]`, `NP[conj]`, a bare `PP` — that the
repo's `Cat` type has no constructor for at all, and even where a feature
could be added structurally, `catTy` still has to map it into a `Ty`, which
currently only distinguishes entities from truth-values. This means an
ingestion pass fed real CCGbank lines will fail constantly, for two
different reasons that are currently indistinguishable: a genuinely
malformed entry, or a legitimate construction the type system has no
primitive for yet. That ambiguity is the same silent-failure-vs-real-failure
problem the whole codebase is built to keep visible, now inside the type
system itself.

This is the layer with the most immediate, concrete traction: survey
CCGbank's actual feature tags and their frequencies (read-only, no code
changes yet), and let *that survey* — not speculation — determine what
`Ty` needs to distinguish (tense? aspect? something that doesn't need a new
primitive at all?) before writing a single new constructor. Category/schema
design here is manually authored and not internally verifiable by the
system's own machinery — the same standing principle as everywhere else —
so this needs real scrutiny per construction, not brute force.

**A category's credibility is scoped to the corpus that attested it, and
this doesn't inherit automatically across sources.** CCGbank's categories
are trustworthy specifically because they're linguist-annotated over real
sentences — that's not a weakness of the corpus, it's exactly why category
*invention* stops being a self-agreement problem for anything CCGbank
covers (see Layer 2). But CCGbank is WSJ text, a specific register (late
80s/early 90s financial journalism). Planned additional sources —
Substack, YouTube transcripts — are different registers (conversational,
informal, contemporary slang/acronyms), and CCGbank's validation doesn't
extend to constructions it never saw. For any word/construction that also
appears in CCGbank, the credibility carries over. For anything genuinely
novel to those other sources, it's back in Layer 2's original
no-external-check position — the credibility has to be re-earned per
source, not inherited once and assumed to travel with the pipeline.

**Amendment — autonomy grant for schema-level decisions within this
layer.** An earlier draft of this document implied schema choices (feature
representation on `Cat`, the semantic type for `PP`, unification strategy
for `fwdApp`/`bwdApp`) needed to pause for synchronous human review before
proceeding. That's revised: **the agent should make these calls directly
and keep moving, not block waiting for sign-off.** What still matters, and
isn't relaxed, is how the decision is carried afterward:

- Log it under the same status-tag discipline the findings log already
  uses (`[stipulated]` for a choice made, not derived; `[structural]` where
  the reasoning behind it matters as much as the choice) — with the
  reasoning and the alternatives considered, not just the conclusion.
- Keep it visibly provisional. A `[stipulated]` schema choice never
  upgrades itself to `[checked]` or `[proved]` by virtue of having been
  logged carefully, or by other work building on top of it without
  incident. It stays open to being overturned on later review, and
  anything built on top of it should be able to point back to the
  specific stipulation it depends on.
- This is a grant of autonomy for **making one reasoned decision at the
  point it's needed**, not a license to brute-force or swarm-search across
  many candidate schemas and keep whichever looks best by the system's own
  metric — that remains exactly the trap Layer 5 describes, and this
  amendment doesn't touch it. One agent reasoning through one fork and
  logging it is a different act from many agents searching a space of
  forks without an external check on which one is right.

## Layer 2 — what "the generator" actually builds, once Layer 1 has traction

Two things the repo's own docs both call "the generator," and they're not
the same operation, though they can share infrastructure:

- **Lexicon/category growth from CCGbank.** Once Layer 1 can represent a
  target feature set, a `(word, category)` pair from a CCGbank line becomes
  a candidate entry, gated by `typeOf` exactly as hand-written entries are
  today. This part is genuinely brute-force-able — cheap, mechanically
  checkable, converges to robust, no controversy, the same shape as
  everything `typeOf` already gates.
- **A test-case generator over real sentences**, replacing combinatorial
  synthesis over the 9-case fixture with real CCGbank sentences as the
  corpus — specifically useful for finding the two known-unreachable
  properties (a divergence needing 3 discourse segments; a referent
  collision needing a same-shaped existential pair), since a hand-written
  9-case fixture structurally cannot produce either.

Keep the two visibly separate in whatever comes out of this: entries that
slot into already-representable categories vs. entries that required
extending `Cat`/`Ty`. Blending them into one "N entries added" count
recreates the well-typed-but-not-faithful trap at the reporting layer.

**A third source, planned but not yet designed: an LLM API pass-through for
words CCGbank doesn't cover clearly** — acronyms, jargon, contemporary
slang from the Substack/YouTube material. This is a good instinct for
coverage, and it's also exactly where this project's central discipline is
most tempting to let slide, because a fluent LLM guess doesn't *feel*
like an invention the way a hand-authored new combinator does. It is one,
structurally, and needs the same treatment:

- An LLM-guessed `(word, category, meaning)` still has to clear `typeOf`
  like everything else — free, and doesn't need new machinery.
- But `typeOf` only proves internal consistency, never that the guess is
  what the word actually means in English. There is no CCGbank-style
  external validation for an LLM-proposed category the way there is for one
  lifted directly from the corpus — this is the vector-DB "proposer, never
  decider" principle (Layer 6) recurring at the lexicon layer instead of the
  retrieval layer.
- These entries need **provenance tagging**: corpus-attested vs.
  LLM-proposed, kept visibly distinct — the same three-way split this
  layer already needs (representable-as-is / required a schema extension /
  now also: guessed by an LLM with no corpus attestation at all), not
  folded into one undifferentiated lexicon-growth count.
- For genuinely unclear cases, the existing project answer is the right
  one: an explicit `ambiguous`/low-confidence flag rather than forcing a
  classification, so an LLM-guessed entry doesn't quietly inherit the same
  trust level as a CCGbank-attested one just because it also type-checks.

## Layer 3 — the oracle question, and a real candidate that already exists

Stage 3 needs an external oracle for the RL loop to close at all — nothing
above this layer means anything without one. `~/projects/` already has a
live candidate: a backtesting system with accumulating real results. This
turns "plug in one real oracle" from an abstract README bullet into an
actual, adjacent, partially-built system.

But a backtest is only a real oracle — not a self-agreement trap wearing an
oracle costume — if its statistical suite genuinely falsifies things:
out-of-sample/walk-forward splits, multiple-comparisons correction (many
candidate strategies will be tried; some look good by chance alone), and a
null-model baseline (an Error@0-style floor — what a naive or random
strategy scores, so a candidate is judged against that, not against zero).

**This suite is not assumed to already exist in adequate form — building
it out is itself part of this session's scope, not a one-time check against
existing infrastructure.** `~/projects/shared/backtesting/` has real
accumulated results, but whether its current methodology already includes
walk-forward splits, multiple-comparisons correction, and a proper null
baseline — or whether those need to be designed and added — wasn't
established this session and shouldn't be assumed either way. Treat
developing/hardening this suite as an ongoing deliverable the goal session
actively builds, the same as everything else in this stack, not as a
prerequisite someone else already finished. Until it demonstrably has all
three properties, don't let anything route through it as ground truth,
because a weak statistical suite here is worse than no oracle at all — it
would poison every claim downstream while looking exactly like the real
thing was working.

**Scope note, established this session**: this whole research layer is not
a replacement for compliance, deployment infrastructure, or live
capital-safety controls — those live in a separate trading server this
system hands validated signals to. This layer's job is generating and
rigorously validating candidate alpha signals; treating "what an experiment
that's actually realistic to validate looks like" as the specific property
being exploited here. That scoping is deliberate and correct, and it sharpens
rather than removes one requirement: since a downstream system will trust
whatever this layer hands it, the suite's construction has to be
independent of the agents proposing candidate signals, or the trading
server has no way to tell "genuinely validated" apart from "validated by a
process the signal-generator helped shape" — a failure that would be
invisible from the downstream side, because the output would still look
like a properly-run experiment.

**How the suite should mostly be built, per this session**: deterministic
properties wherever possible — the suite generates plausible candidate
signals through mechanical, repeatable filtering (walk-forward splits,
ablations, null baselines, cross-instrument checks, the technique
inventory in Layer 3.5) rather than soft, agent-tunable judgment calls.
Most of the heavy lifting — narrowing a large candidate space down to
signals worth digging through further — happens through this deterministic
prefiltering, not through an agent's discretion about what counts as
promising. This is itself a partial, structural answer to the
construction-independence concern above: a suite built mostly from fixed,
mechanical properties has much less surface for the agent population to
quietly shape than a suite built from adjustable soft criteria — the same
"mechanical gate over discretionary judgment" preference this document
applies everywhere else (`typeOf` over `LLM says it's fine`).

**The export boundary to the trading server**: an artifact — the validated
signal itself — plus enough accompanying information to understand what's
actually being handed over: which tests it cleared, what its
validation trail looks like, enough context for a later decision about
when to retire it. This is a natural extension of the provenance discipline
used everywhere else in this document, and it's the concrete thing that
determines whether the trading server's own downstream controls have
something real to condition on.

**Explicitly deferred, not a current priority**: P&L feeding back into this
research layer to further refine or retrain signals. This is plausible
future work (and connects to Layer 7/8's calibration discussion), but the
alpha-generation capability on its own is considered valuable and worth
building now independent of whether that feedback loop ever closes — don't
let a future session treat the feedback loop as a blocking prerequisite for
this layer's value.

## Layer 3.5 — signal-hierarchy tracking: the concrete shape the statistical suite needs, and where epistemics actually plugs in

A worked example is worth keeping attached to Layer 3, abstracted properly
rather than treated as a specific strategy to adopt: an NQ mean-reversion
strategy shared this session (`Strategy__1_.pdf`) builds a genuine *signal
hierarchy*, not one signal — raw price/volume, a derived regime
classification (HMM) on top of it, a divergence measuring how wrong the
regime classifier's real-time belief was relative to its own
after-the-fact revision (KL divergence between filtered and smoothed
estimates), an online predictor of *that* divergence, and finally — the
load-bearing piece — the *residual structure* of that predictor's errors,
not its point forecasts. Each layer captures something the layer below
structurally cannot see. And each layer's independent contribution is
tested directly: swapping the KL-predictor residuals for the nearest raw
equivalent and watching the edge collapse to noise is a per-layer
ablation, not a whole-pipeline sanity check. Cross-instrument specificity
(works on NQ, fails on ES/YM/RTY in the direction the thesis predicts) and
a hold-period robustness sweep (15–60 minutes) round out the validation —
worth citing as concrete technique names when the statistical suite gets
built, not as a strategy to copy.

**The abstracted requirement this points to**: the statistical suite needs
to track, for any signal at any level of derivation, whether *that specific
layer* is contributing independently — not just whether the end-to-end
pipeline's output looks good. This is the same discipline this whole
handoff already applies to derivation provenance (`Genealogy.hs`) and to
the reward manifold's coordinates (Layer 4) — track contribution
per-layer, don't trust an aggregate because the whole thing type-checks or
back-tests well. A human team can build and validate one such hierarchy by
hand, carefully, over months. What makes AI-driven, automated pursuit of
this different in kind — not just faster — is running that same
layer-contribution discipline continuously across far more signal
hierarchies, instruments, and domains than a human team could sustain
manually, at a scale where the real constraint becomes compute and data
availability rather than labor.

**Where epistemics (Layer 7/8) actually connects to this, beyond delayed
verification**: news/world-knowledge synthesis isn't only useful for the
attribution-logging story in Layer 7 — it's also what turns signal-hierarchy
search from blind combinatorial search into *directed* search. World
knowledge (macro narrative, sector context, what's actually happening right
now) should narrow which layers/features are worth building and testing
next, the way a good prior narrows experimental design — except here the
prior is itself continuously updated from real synthesis rather than fixed
at the start. And this directional knowledge shouldn't be siloed per
strategy or per instrument: an insight about signal-hierarchy structure
discovered in one domain should be available to redirect search in
another, through the shared substrate — this is the concrete cash-value of
"share a brain" the owner described, and it's the connective tissue between
Layer 3's statistical-maturity requirement and Layer 7/8's epistemic layer,
not two unrelated tracks.

**A resource to build the testing-suite methodology against**: the owner
plans to draw on *An Introduction to Statistical Learning* for concrete
testing/validation technique choices (cross-validation schemes, resampling,
model-selection criteria) — a good, standard reference for filling out what
"statistically mature" actually means in Layer 3's suite, rather than
reinventing validation methodology from scratch.

## Layer 4 — the reward manifold has a structural gap, not just a missing weight

`Reward.hs`'s `rwScore` excludes `nCorroborated`/`nNovel` entirely, despite
the module's own prose arguing corroboration is the one non-gameable signal
this architecture has. Simply adding weights for them doesn't fix it: the
two are anti-correlated by construction (a heavily corroborated claim is,
near-definitionally, one already implied by the rest of the base; a
genuinely novel claim structurally can't be corroborated yet). Any fixed
positive weight on both creates a corner solution — whichever is cheaper to
farm dominates. This is linear scalarization instability under conflicting
objectives, and it isn't fixed by finding better numbers; the linear-sum
structure itself is the defect.

Real directions, not a prescribed answer — this needs literature review:

- **Constrained RL / Lagrangian methods** (Achiam et al., Constrained
  Policy Optimization) — corroboration/novelty as constraints with adaptive
  dual-variable multipliers, not stipulated weights. `wUncovered` already
  behaves like this (pinned to zero, not tunable) — the precedent already
  exists in this file.
- **Pareto-frontier / vector-valued RL** — don't collapse to a scalar;
  train toward the frontier, defer scalarization. The module's prose
  already half-gestures at this ("the coordinates are reported separately
  and they are the object") without anything downstream actually doing it.
- **Fit the combination function against held-out, oracle-checked
  outcomes** rather than stipulating or brute-forcing weights — keeps an
  external check on the weight-selection problem itself, consistent with
  the no-self-verification rule everywhere else in this system.
- **Ruled out, despite surface appeal**: natural-gradient/trust-region
  methods (TRPO/PPO's Fisher-information machinery) solve a different
  problem — how fast a policy moves per update — not a reward whose
  objectives are structurally anti-correlated.
- Search terms: reward hacking under linear scalarization of conflicting
  objectives; Amodei et al. "Concrete Problems in AI Safety"; DeepMind's
  specification-gaming catalog.

## Layer 5 — the graph-trust mechanism is the same open question, one layer up

The epistemic graph needs some mechanism for how a node's trust changes
when something downstream of it gets an oracle-checked outcome — candidate
shapes discussed: edge-weight updates, edge existence (create/prune),
node-level trust propagated through something like `grounded`'s
least-fixed-point, or a single continuous topology (inert by default,
threshold-gated fusion, signed-magnitude updates once proven) that
subsumes all three as parameter settings.

The distinction that matters: searching *parameter values* within one fixed
topology (thresholds, magnitudes) is legitimate brute-force-plus-verify
territory, the same shape as Layer 2's lexicon growth. Searching or
brute-forcing *which mechanism shape is correct* is not — nothing but the
system's own internal metric would be judging that choice, which recreates
the category-invention self-agreement trap one layer up. This needs the
same kind of external fitness function Layer 4 is looking for — and it's
worth explicitly checking whether solving Layer 4 well (a real,
non-self-referential way to combine anti-correlated signals) directly
answers Layer 5 too, since they're structurally the same problem at two
altitudes, not two separate research tracks.

## Layer 6 — the vector database is a proposer, not a decider (resolved, keep it that way)

This one has an answer, reached this session, and shouldn't be re-opened:
similarity search surfaces candidates, it does not itself judge agreement,
contradiction, or independence — that stays `Genealogy.hs`'s job.
Embeddings are candidate generators, never certifiers, the same principle
as everywhere else a probabilistic proposer sits next to a discrete
verifier in this system.

## Layer 7 — news/knowledge ingestion has no direct oracle, and two things are missing before the indirect one works

The owner's position, reached this session: news claims don't get checked
directly, but claims that get incorporated into something that *is*
eventually checked (a strategy that gets backtested) create a delayed,
indirect verification signal — an outcome should propagate back to
implicate the claims that fed it, the same shape as `Genealogy`'s
retraction propagation, stretched across a much longer and fuzzier chain.

Two things this requires, neither designed yet:

1. **Attribution logging** — "this strategy leaned on facts X, Y, Z" has to
   be recorded at generation time. It isn't free the way exact derivation
   dependency is in `Genealogy.hs` today. Without it, a failed backtest
   teaches you "something in the chain was wrong" and nothing more
   specific — not a usable signal.
2. **A large permanent-`Unknown` remainder is the expected outcome, not a
   gap to close.** Most ingested content will never touch something
   backtestable. It should sit in the same zero-scored, unpenalized bucket
   `rwUncovered` already uses, for the same reason: penalizing
   uninstrumented content trains the policy away from the tooling gap, not
   away from an actual error.

Also carried forward: P&L alone is a noisy verification signal (a strategy
can fail for reasons unrelated to whether an underlying claim was true).
The agreed fix is measuring **calibration** — does confidence correlate
with how often things resolve correctly, across many independent
oracle-checked instances — rather than raw P&L. This is the same
calibration idea Layer 4's "fit against held-out outcomes" direction needs
anyway; they're likely one build, not two.

## Layer 8 — "removing entropy from the system": one version is sound, one is a trap

The owner's framing of accumulated knowledge's value as entropy reduction
is legitimate *only* if the entropy being measured is anchored to
eventually-oracle-checked outcomes (calibration improving over time against
real resolutions — Version A). It is not legitimate if "entropy" ends up
measured as coherence within the accumulated knowledge base itself,
independent of whether any of it is ever checked (Version B) — that's an
echo chamber that can look like steady improvement while drifting further
from true, and it's worse than a noisy-but-real signal because nothing in
it ever disagrees with the system. Treat any proposed entropy/coherence
metric in this system as Version B until it's demonstrably routed through
Layer 3's or Layer 7's real oracle-checked resolutions.

## Layer 9 — `agentic-qr` is legacy scaffolding around the kernel, not a peer system

This resolves what an earlier draft of this document left as an open
question ("relationship not established, ask rather than assume"). It's
now established: **`nl2proof` is the main project. `agentic-qr` is an
accessory** — the multi-agent runtime that will actually host the agents
doing all of the above, but subordinate to `nl2proof`, not a parallel
concern of equal weight.

The reason `nl2proof` has to be the anchor rather than one participant
among several: a multi-agent loop where many agents concurrently propose
claims, strategies, retrieved facts into shared state has a failure mode
worse than any single-agent version of the self-agreement trap this whole
document is about — agents can converge with each other on something
ungrounded and mistake mutual agreement for verification, distributed
across many agents instead of one system talking to itself. Without a
deterministic core underneath it, an unverified claim from one agent gets
picked up by another, refined, handed to a third, and several hops later
it's load-bearing for a real decision, with no mechanical way to trace
whether any of it ever touched an oracle. `nl2proof` is what prevents that:
a single deterministic gate every claim passes through regardless of which
agent or mechanism produced it (`typeOf`, the oracle-verdict split,
`Genealogy`'s grounded-support computation), a shared provenance format so
failures propagate back to the specific claims — and by extension the
specific agents — that fed them, and the admissibility discipline
preventing agent outputs from scoring well merely for being mutually
consistent. Every layer of rigor elsewhere in this document (the `Cat`/`Ty`
correctness, the reward manifold's anti-gaming discipline, the graph-trust
mechanism's external-fitness requirement) is a precondition for
`agentic-qr` being viable as a multi-agent system at all — not a parallel
hardening track that could happen afterward.

**What survives from `agentic-qr` as-is, and what doesn't.** The owner's
assessment: `agentic-qr` already has some strong separations between
agents — real architectural instincts worth preserving, not accidental. But
everything else about it can be completely overhauled to conform to
`nl2proof`'s discipline rather than negotiated with as an equal partner.
Concretely, this means: survey `agentic-qr`'s existing agent-boundary
design specifically for what already reflects good separation-of-concerns
before touching anything else in it, keep that pattern, and treat the rest
of it — including anything that currently lets agents write to shared
state without passing through a deterministic gate — as legacy to be
brought up to `nl2proof`'s standard, not as a design to accommodate.

**Still open, not yet surveyed this session**: whether the actual
integration is a literal service boundary (agents in `agentic-qr` call into
`nl2proof`'s pipeline directly) or `nl2proof`'s pattern gets replicated as
the design discipline `agentic-qr`'s own machinery follows without a shared
call path. Given "legacy, subordinate, overhaul to fit" as the framing just
established, the literal-service-boundary version is the more consistent
reading — `agentic-qr` agents route through `nl2proof` rather than
re-implementing its discipline in parallel — but this should be confirmed
once `agentic-qr`'s actual code is in front of an agent session, the same
way this document only started saying anything precise about `nl2proof`
once its actual files were read rather than assumed from memory.

## A general note on everything in this stack that's described as "already exists"

This document names several partially-built systems along the way —
`~/projects/shared/backtesting/`, `~/projects/shared/context_graph/`,
`~/projects/intake/`, `agentic-qr` itself. None of them should be read as
"done, just verify it." The pattern established explicitly for the
statistical suite in Layer 3 generalizes to all of them: a lot of this has
been started, and the actual long-standing goal for the agent session is to
go test, harden, and build all of it out properly — not audit a finished
artifact and report back whether it passes. Where this document says
something like "wasn't established this session," read that as "starting
point, not a verified baseline" — the default assumption should be that
existing infrastructure is a scaffold to build on and interrogate, not a
foundation to trust because it's already running and producing output.
Producing output is not the same as being correct; that's the premise this
entire document is built on, and it applies as much to the owner's existing
systems as to anything an agent proposes fresh during the session.

## How to actually move through this stack

Not top to bottom, and not by clearing one layer before touching the next.
Layers 4 and 5 are very likely the same unsolved problem — expect solving
one to move the other. Layer 3's oracle-hardening and Layer 7's calibration
idea are also likely one build. Layer 1 is the one piece of genuine
low-level, concrete, data-backed traction available immediately (CCGbank is
sitting on disk right now), so it's a reasonable place to start generating
real momentum — but finding it easiest to start there isn't the same as
placing it "first" in an order the rest waits on. Move up and down as
partial answers at one layer unlock traction at another, and log which
layer any given finding actually belongs to rather than letting insights
bleed across layers without attribution — the same discipline this whole
system already demands of derivation provenance, just applied to the
research process itself.

## A closing point about why this is laid out as barriers rather than as one hard problem

None of the individual problems in this stack are actually hard, taken one
at a time — a type extension, a corpus survey, a provenance tag, an
ablation test, an admissibility check. What's hard, and what this document
exists to prevent, is quietly collapsing two of them together, or
promoting an internally-consistent result to a verified one without
noticing the gap. That's precisely why this handoff is written as a stack
of explicit, separately-named barriers rather than as one large ambiguous
mandate: **the barriers are what make it safe for an agent working inside
this system to do good, narrow, correct work without needing to hold the
entire system's soundness in view at once.** An agent extending the
lexicon only needs to know "does this clear `typeOf`, and is it tagged with
the right provenance" — it doesn't need to have independently reasoned its
way to why self-verification is unsound, because the barrier already
encodes that lesson. An agent proposing a topology parameter only needs to
know "is this being scored against something that eventually gets checked" —
it doesn't need to have rediscovered why linear scalarization fails. Stay
inside the barrier that's already been defined for the layer you're
working at, and the work is genuinely tractable even without re-deriving
the reasoning behind it. The risk this whole document is written against is
an agent — or a session — deciding a barrier is inconvenient and stepping
around it "just this once," because that's the one move that actually
reintroduces every failure mode this stack was built to keep out.
