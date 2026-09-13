# natural-language-to-proof

Turning natural language into discrete logical claims that an **external domain
oracle** can confirm or refute — so the result is usable as a reinforcement-learning
reward signal without the system supplying its own grounding.

| Document | What it is for |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | the design, the four stages, the standing limitations |
| [TRACE.md](TRACE.md) | one scenario through every layer: the object, the state, and the checkable propositions |

The short version:

> This is **not** meaning extraction in general. An LLM does that with broader
> coverage and lower cost. What an LLM cannot do is hand back a claim together
> with a checkable certificate that the claim is true — and that certificate is
> the output this substrate is for.

And the constraint the whole design is organised around:

> **A system cannot use its own internal consistency checks as the reward signal
> for the step that produces the claims in the first place.**
>
> Type-checking and provability are internal. Rewarding either measures
> self-agreement, not truth, and an RL policy will find and exploit the gap.
> Truth enters at exactly one place: an oracle that is not part of the system.

## The four stages

```
1. INITIAL SPACE     text -> CCG -> lambda -> typeOf -> DRS -> candidate readings
                     search; commits to nothing

2. VERIFICATION      claims + full derivations retained
                     -> external oracle -> Confirmed | Refuted | Unknown
                     -> recorded in a genealogy DAG

3. FUSION            oracle-confirmed claims only -> dedup
                     safe here and nowhere earlier

4. REWARD            confirmed claims + mechanical consequences -> score
                     never "did it typecheck", never "was a proof found"
```

Two properties are enforced by types rather than by discipline:

- **`Verify.Oracle.Confirmed` has no exported constructor.** `confirm` is the only
  way to obtain one, so feeding unverified claims to fusion is a type error.
- **`Reward.score` never sees a `Term`.** It takes a `Fused` and a `Genealogy`, so
  it *cannot* consult `typeOf` and there is no proof search available to it.

And one is enforced by a fixed-point choice:

- **A claim cannot ground itself.** `Genealogy.grounded` is the *least* fixed
  point of "has a justification whose antecedents are all grounded". A ring of
  mutually-justifying claims satisfies the greatest fixed point — they are
  mutually consistent — and the least fixed point not at all. Mutual consistency
  is exactly the self-agreement that must not be mistaken for truth.

### `Unknown` is not `Refuted`

Oracle coverage is binary per domain. A physics engine settles trajectories and
has nothing to say about monetary policy, so `Verdict` has three cases and
uncovered claims score **zero in both directions** — penalising them would train
the policy away from domains that merely lack instrumentation; rewarding them
would invent evidence.

Where no oracle exists for a domain, this design cannot ground it. That is
inherent, and `Verify.Oracle.coverage` reports the uncovered share so the size of
the remainder stays visible.

## Status

**Stage 1: complete.** Deterministic Montague/CCG/DRT core, no probability
anywhere. 386 checks.

**Stage 2 (candidate generation and ranking): in progress.** Scope permutation,
modifier–noun fusion, structural fingerprints, finite models, RSA, SDRT and
SDRT-aware discourse threading. 239 checks.

**Substrate (verification, genealogy, fusion, reward): first cut built.** 114
checks, and they assert design constraints rather than linguistic behaviour — the
self-grounding and self-agreement checks are the load-bearing ones. The reward is
now also treated as a **vector** (`rewardCoordinates`/`dominates`/`paretoFrontier`)
that exposes the anti-correlated corroboration/novelty coordinates `rwScore`
collapses away, and defers scalarization to an external fitness function — see
`FINDINGS-goal-session.md`, Layer 4.

**CCGbank ingestion (Stage 1 scaling): underway.** Parsing and classifying
CCGbank's feature-annotated categories, feature-unifying combinators validated
against the corpus's own GRAMMAR, `.auto` derivation reconstruction, a
train/test-measured type-changing rule class, and provenance-tagged lexical-entry
ingestion (99.9% of the 83,540-entry lexicon, 0 ill-typed skeletons). 89 checks.
See `FINDINGS-goal-session.md` for the measured results.

| Suite | Checks | What it pins |
|---|---|---|
| `test/Spec.hs` | 386 | the discrete core, and discourse-merge soundness |
| `test/Stage2Spec.hs` | 239 | candidate generation, ranking, SDRT threading |
| `test/SubstrateSpec.hs` | 114 | oracle boundary, grounded support, precise retraction, reward admissibility + Pareto frontier |
| `test/CCGBankSpec.hs` | 89 | CCGbank category parsing, feature unification, `.auto` reconstruction, type-change induction, entry ingestion |
| **total** | **828** | |

What the substrate has and has not:

| Built | Not built |
|---|---|
| oracle interface with a three-valued verdict and a type-level confirmation gate | any **real** oracle — the ones in the suite are plumbing, not physics |
| genealogy DAG: node identity, justifications, least-fixed-point support | supersession (revision-with-history) as distinct from retraction |
| precise retraction as a difference of fixed points | AGM-style minimal revision when a reversal creates inconsistency |
| cross-derivation convergence detection | a corpus long enough to exercise any of it |
| reward with an executable admissibility check | learned weights; the current ones are stipulated |
| modus ponens over the confirmed base, with its soundness side condition | anything stronger, deliberately — see below |

### Precise retraction, measured

The reason the genealogy is a DAG and not a tree. Two confirmed premises `n0` and
`n1`; `n2` derived independently from each; `n3` derived from `n0` alone.
Retracting `n0`:

| answer | result |
|---|---|
| coarse — everything downstream (`dependents`) | `n2`, `n3` |
| precise — lost all grounded support (`retract`) | `n0`, `n3` |
| difference | `n2`, which `n1` still supports |

The precise answer is the difference of the grounded sets before and after, which
is *why* it is precise. `retractionReport` reports the gap, and `rrSurvived` names
exactly what a coarse retraction would have destroyed.

### Reward: internal coherence is worth nothing

Asserted, not remarked. A chain of 5 perfectly well-formed, mutually-justifying
claims with no oracle beneath it scores `0.0`. So does a chain of 50. The
admissibility check has teeth too: a weight table that pays anything for
uncovered claims, or fails to penalise refutation, or values inherited grounding
above direct confirmation, is reported inadmissible.

## Properties worth knowing

#### SDRT threading

`Stage2.Threading` resolves each sentence's pronouns against the right frontier
rather than against a flat merge. Two consequences follow from the structure
rather than from the implementation.

**It can only ever remove antecedents.** The frontier's referents are a subset of
the flat merge's. So this is not a free improvement — it is a filter, and on this
fragment the filter is driven by *stipulated* cue weights. Hence two policies:

| policy | what it does | on `"A student arrived. Mary smiles. She reads a book."` |
|---|---|---|
| flat (Stage 1) | whole accumulated universe | resolves `she` → `x` |
| `Committed` | argmax relation, then its frontier | **fails** — `Continuation` closed `K1` |
| `Marginal` | union over positive-mass relations, graded | resolves `she` → `x` at mass **0.488** |

`Marginal`'s guarantee stops at one uncertain edge. At **four** segments it
offers nothing for `K4` while the full marginal keeps the referent at **0.488**:
the one-edge truncation holds every earlier edge at a committed value, and so
reintroduces the hard commitment the policy exists to avoid. `fullMarginalAt`
measures the gap.

**The least committal relation is not the least committal for accessibility.**
`glue`'s no-cue default is `Continuation` because it commits to the least *about
the discourse* — but it is coordinating, so it is the most restrictive choice for
*anaphora*. With no cues firing, `Committed` closes every parent and accessibility
collapses to the previous sentence alone. `Marginal` is the policy that fits the
standing principle: `Elaboration` always keeps positive mass, so the referent is
never deleted, only ranked. The 0.488 above is exactly the subordinating mass of
that edge's relation distribution — measured, not assigned.

On the nine-case fragment **both policies diverge from flat on nothing**, because
both multi-sentence cases are two sentences long and a two-unit structure has one
edge whose parent is always on the pre-attachment frontier. Asserted as a check,
which says two things at once: threading is safe to run on the existing corpus,
*and* the corpus is too short to exercise it.

Known over-restriction, stated rather than patched: a resolved pronoun adds no
referent to its unit's universe, so under `Committed` a chain of coordinating
relations starves. Real SDRT percolates referents up the graph; this does not, and
`Marginal` hides the symptom without addressing the cause.

#### Discourse referents are unique, and the merge depends on it

`mergeDRS` is sound only when the two universes are **disjoint** — the standard
side condition on DRS merge. Referent names come from the lambda terms, so two
sentences of the same shape arrive with the same names, and something has to
discharge the precondition:

```
"A student arrived. A professor walks."
  +---------------+
  | x x2          |
  +---------------+
  | student(x)    |
  | arrive(x)     |
  | professor(x2) |     two individuals, not one
  | walk(x2)      |
  +---------------+
```

`DRT.Types.freshenAgainst` does it at the merge, applied in `extendDiscourse` and
in `Stage2.Threading` — the two places that combine boxes from different
sentences. Without it both existentials share `x` and the box asserts one
individual is both a student and a professor.

Two properties make that the cheap enforcement point. The renaming is
**alpha-conversion**: mechanical, so nothing is logged, and `mapRefs` carries each
referent's provenance through, so a renamed referent still traces to the words
that introduced it. And it happens **at the merge, not in `toDRS`**, so
sentence-local boxes are untouched and a sentence read on its own reads the same.

##### What that settles about the frontier mass

`Ref` is discourse-unique, so `(Label, Ref)` buys nothing and the frontier can do
its job — telling "`x` from a closed unit" apart from "`x` from an open unit".
Measured on the colliding text:

| free edges | focal sets | nested? |
|---|---|---|
| 1 | 2 | **yes** — a theorem, not a measurement |
| 2 | 4 | **no** — `[x2]` crosses `[x]` |

`frontier(subordinating) = frontier(coordinating) ∪ {parent}`, so one free edge
gives exactly two focal sets, nested by construction. At two they cross. The
implementation runs at one free edge, so it sits in the *only* regime where the
possibility-measure reading is available — **and that regime is the truncation.**
The truncation has to go, because it deletes referents, so the possibility reading
goes with it. The two stand or fall together.

The mass is also barely graded at one free edge — two values only. At two it is
genuinely graded: `x2` (from `K2`) at **0.488**, `x` (from `K1`) at **0.435**, with
the truncated implementation offering only the first.

Stage 1 is meant to stop changing. Later stages consume its output; they should
not require edits to it.

## Building

Two supported paths. **cabal is the primary one**; the scripts exist for
machines with no package manager.

### With cabal

```bash
cabal build all
cabal test all
cabal run nl2proof-demo
```

`cabal.project` sets `active-repositories: none`, because the project uses only
`base` and `containers` — both bundled with GHC — so no package index is ever
needed. That makes the build work offline, and makes the dependency-free
constraint enforceable rather than merely stated: adding a Hackage dependency
fails the build instead of silently succeeding.

`cabal test all` runs all four suites: the discrete core, candidate generation,
the substrate, and CCGbank ingestion. The `tools/` executables (`ccgbank-report`,
`ccg-grammar-coverage`, `ccg-reconstruct`, `ccg-typechange-coverage`,
`ccg-parse-coverage`, `ccg-supertag-parse`, `ccg-lexicon-ingest`) are research
drivers over the CCGbank corpus — run e.g. `cabal run ccgbank-report`; they read
`~/ccgbank/` at runtime and commit no corpus data. `ccg-parse-coverage` measures
whole-sentence bottom-up parse coverage: it folds the combinators and the learned
type-change inventory into one CKY parse and reports how often the grammar derives a
real sentence's gold root from its gold *supertags* (99.1% on a section-00 sample).
`ccg-supertag-parse` goes one rung further — a frequency supertagger offers each raw
word its top-k categories and the chart combines them, reporting OOV, oracle
inclusion@k (the ceiling), and from-words parse-to-gold-root coverage (70% on the
same sample with a tiny training split; the supertagger is the standard lexical
baseline, and the number rises with more training data and a stronger tagger).

<details>
<summary>If cabal complains about <code>root.json</code> signatures</summary>

Ubuntu 24.04's cabal 3.8.1 ships stale Hackage TUF root keys, so it errors with
`<repo>/root.json does not have enough signatures signed with the appropriate
keys` even when no index is needed. One-time fix — comment out the
`repository hackage.haskell.org` stanza in `~/.cabal/config`:

```bash
sed -i '/^repository hackage.haskell.org/,/^$/ s/^/-- /' ~/.cabal/config
```

Safe here precisely because nothing is fetched from Hackage. Undo by
uncommenting, or install a newer cabal via ghcup.
</details>

### Without cabal

The project depends only on `base` and `containers`, both of which ship inside a
GHC bindist, so **a bare unpacked GHC is enough**.

```bash
export GHC_BIN="$LOCALAPPDATA/ghc/ghc-9.12.4-x86_64-unknown-mingw32/bin"
./scripts/build.sh
```

PowerShell:

```powershell
$env:GHC_BIN = "$env:LOCALAPPDATA\ghc\ghc-9.12.4-x86_64-unknown-mingw32\bin"
.\scripts\build.ps1
```

Both scripts typecheck everything with `-Wall` and then run the suite. Pass
`demo` to run the demo instead, or `compile` to build and run native binaries.
If `ghc` is already on your PATH, `GHC_BIN` can be skipped.

Built and tested on **GHC 9.4.7 / Ubuntu 24.04** (compiled)
and **GHC 9.12.4 / Windows** (interpreted). Compiled runs are roughly 90x faster
than `runghc` — 0.05s versus 4.56s for the core suite — so compiling is worth it
wherever the platform allows it.

**Why the default path interprets rather than compiles.** The scripts run the
suite through `runghc`, so no new executable is produced. Windows
application-control policies (Smart App Control, WDAC, Device Guard) routinely
refuse to execute freshly built unsigned binaries, which makes a
compile-then-run script fail with `Permission denied` for reasons that have
nothing to do with the code. Interpreting avoids that without weakening any
policy. Use `compile` if your machine permits it and you want the faster
runtime. Build artifacts also default to a temp directory rather than the
working tree, so an OneDrive-synced checkout does not upload object files.

## What Stage 1 does

Pipeline: text → sentences → a lattice of candidate lexical units
(exact spans) → CCG derivations →
lambda terms → type check → DRS boxes → discourse merge with anaphora
resolution → `Selection` handed to a collapse strategy.

```
$ ./scripts/build.sh demo

anaphora  [cross-sentence pronoun]
text: "A student arrived. She smiles."

  [0:18] words: a student arrived
      derivations: 1
      form: exists x. student(x) & arrive(x)
      provenance of first condition: cond("student"@demo[2:9])
  [19:30] words: she smiles
      derivations: 1
      form: smile(?she)

discourse DRS (after anaphora resolution):
  +------------+
  | x          |
  +------------+
  | student(x) |
  | arrive(x)  |
  | smile(x)   |
  +------------+

-- decisions (1)
[anaphora] chose x (forced, no alternatives)
    why: most recently introduced accessible referent, by surface position
    at:  19:29 "she smiles"
```

Change the first sentence to `No student sleeps.` and the pronoun correctly
*fails* to resolve — the referent is inside a negated box and DRT accessibility
blocks it — producing an `UnresolvedAnaphor` diagnostic instead of a guess.

### The evaluation set

Nine cases in [`NL2Proof.Fragment`](src/NL2Proof/Fragment.hs), fixed before any
Stage 2 comparison so that comparisons are evidence rather than vibes. They live
in the library, not the test file, because Stage 2 has to import them.

| Case | Covers |
|---|---|
| `transitive` | simple transitive, two proper names |
| `intransitive` | intransitive, proper name subject |
| `quantified` | quantified subject + indefinite object |
| `negative-quantifier` | negative determiner, referent trapped under negation |
| `negation` | verbal negation via a multi-word lexical entry |
| `relative-clause` | subject relative clause, gap as a generalized quantifier |
| `anaphora` | cross-sentence pronoun, resolved |
| `blocked-anaphora` | cross-sentence pronoun, correctly *not* resolved |
| `coupling` | `"an ancient Chinese red dragon"` — stacked modifiers |

### Design decisions worth knowing

- **All NPs are generalized quantifiers**, `(e -> t) -> t`, including proper
  names. That uniformity is what lets `"John"` and `"every student"` share one
  verb entry.
- **The parser returns every derivation, not the first.** Parsing is search;
  collapsing the candidate set is a separate, logged step. A parser that
  silently returns its first parse has already made that decision and destroyed
  the record of it.
- **`Prov` is a tree, not a flat tag.** That is what makes the two tracks two
  folds over one data model instead of two data models.
- **Composition is type-*checked*, not just performed.** `catTy` states the
  semantic type each category demands, and the suite verifies every lexical
  entry inhabits it. This is Curry–Howard at the smallest available scale.
- **`Selection` carries the rejected candidates.** A function
  `[DRS] -> DRS` cannot honour "log the collapse" — it discards the alternatives
  as it runs, leaving its output indistinguishable from a derived result.
- **Word-level provenance without polluting the lambda calculus.** A side index
  from constant names to lexical spans (`ProvIndex`) gives conditions
  word-level traceability; `NL2Proof.Semantics.Lambda` never learns that
  provenance or anaphora exist.

### Known Stage 1 limitations, on purpose

These are recorded rather than patched, because patching them in a hand-written
lexicon would put Stage 2's job in the wrong place:

- **Scope is fixed** at subject-wide in the transitive verb entry. The inverse
  reading of `"Every student reads a book"` is not generated. Scope alternation
  is candidate generation — Stage 2.
- **Anaphora resolution is "most recent accessible referent"**, where recent
  means latest surface position, and nothing else:
  no gender or number agreement, no salience, no world knowledge. Deliberately
  weak, and every application is logged with the alternatives it passed over, so
  its failures are visible instead of silent. That log is Stage 2's input.
- **Modifier stacks are flagged, not resolved.** `"ancient Chinese red dragon"`
  gets the iterated-intersection reading plus a `ModifierCoupling` diagnostic.
  Deciding whether a modifier has fused with the noun into a lexicalized subkind
  needs graded similarity judgements — Stage 2's DisCoCat/kernel work.
  Localizing an ambiguity and resolving it are different jobs.

## Layout

```
src/NL2Proof/
  Provenance.hs        source ids, spans, how-provenance trees, folds
  Trace.hs             Decision and Diagnostic logs
  Semantics/Lambda.hs  typed lambda calculus, type checker, normalizer
  Syntax/Category.hs   CCG categories (with features + PP), category -> type,
                       feature unification (catUnify)
  Syntax/Lexicon.hs    the fragment's vocabulary
  Syntax/Tokenize.hs   sentence splitting, spans, the lexical lattice
  Syntax/CCG.hs        signs, combinators (feature-unifying), CKY parser
  Syntax/CCGBank.hs    parse + classify CCGbank feature-annotated categories
  Syntax/CCGRules.hs   feature-unifying combinatory rules over CCGbank categories
  Syntax/CCGDeriv.hs   parse .auto derivation trees; reconstruction check
  Syntax/CCGTypeChange.hs  type-changing rule class, learned train/test
  Syntax/CCGLexicon.hs  CCGbank (word,category) -> provenance-tagged Entry + skeleton
  DRT/Types.hs         DRS boxes, conditions, accessibility, rendering
  DRT/Build.hs         term -> DRS, anaphora resolution, discourse threading
  DRT/Canonical.hs     provenance-free view: claim identity
  Collapse/Class.hs    the seam: Selection, chosen reading plus rejected fiber
  Fragment.hs          the fixed evaluation set
  Pipeline.hs          text -> DRS, wiring it together
  Stage2/
    Distribution.hs    finite distributions on the simplex
    Modifier.hs        modifier classes by resolution layer
    Alternatives.hs    generates the readings Stage 1 declined to
    Fingerprint.hs     structural fingerprints + similarity kernel
    Model.hs           finite models, entailment, informativity
    RSA.hs             literal/pragmatic listener, speaker
    SDRT.hs            discourse relations, right frontier, glue
    Threading.hs       the frontier drives anaphora; two policies
    Pipeline.hs        Stage 2 end to end
  Verify/Oracle.hs     stage 2: Verdict, Oracle, Confirmed (abstract)
  Verify/Claims.hs     stage 2: claims with derivations retained, no dedup
  Genealogy.hs         stage 2: the DAG, grounded support, precise retraction
  Fusion.hs            stage 3: dedup of oracle-confirmed claims only
  Reward.hs            stage 4: the RL signal, its admissibility check, and the
                       vector-valued reward (rewardCoordinates/dominates/paretoFrontier)
app/Main.hs            demo
tools/CCGBankReport.hs        representability of the CCGbank lexicon (over LEX)
tools/CCGGrammarCoverage.hs   combinator coverage vs CCGbank GRAMMAR
tools/CCGReconstruct.hs       whole-sentence reconstruction over real .auto files
tools/CCGTypeChangeCoverage.hs  type-change coverage, held-out train/test
tools/CCGLexiconIngest.hs     ingest the CCGbank lexicon into provenance-tagged entries
test/Harness.hs        shared assert scaffolding, no framework dependency
test/Spec.hs           386 discrete-core checks
test/Stage2Spec.hs     239 candidate-generation checks
test/SubstrateSpec.hs  114 substrate checks (incl. Pareto reward frontier)
test/CCGBankSpec.hs    89 CCGbank parse / unification / reconstruction / ingestion checks
corpus/               the adversarial epistemic corpus + graph (see corpus/README.md)
docs/                  standalone probes and CCGbank feature surveys (read-only)
```

The `tools/` executables are research drivers, not part of the library or its
test suites. They read the CCGbank corpus from `~/ccgbank/` at runtime; no
corpus-derived data is committed to this repository (LDC2005T13 licensing).

## Next

In order, and the order matters.

1. **Decide, per intended domain, whether an external oracle actually exists.**
   This determines whether the RL loop closes at all for that domain, and no
   amount of pipeline work substitutes for it. Everything below is wasted effort
   in a domain with no oracle.
2. **Plug in one real oracle** and replace a whitelist with it. The seam is
   `Verify.Oracle.Oracle`; the toy oracles in the suite exist only to exercise
   the plumbing. *Partly underway for the trading domain, not yet wired into this
   seam — see `FINDINGS-goal-session.md`.* A real statistical oracle for trading
   signals (walk-forward/OOS, permutation + random-timing nulls,
   multiple-comparisons correction, regime-conditional evaluation) is now built
   and hardened in `agentic-qr` and runs on every backtest; what remains here is
   routing a real oracle into `nl2proof`'s own `Verify.Oracle` seam rather than
   the toy ones.
3. **Build a generator over the lexicon and the CCG rules.** *Substantially
   built — see `FINDINGS-goal-session.md`.* CCGbank (LDC2005T13) is the corpus:
   `Syntax/CCGBank` parses and classifies its feature-annotated categories;
   `Syntax/CCGLexicon` turns `(word, category)` pairs into provenance-tagged
   `Entry` values (**99.9% of the 83,540-entry lexicon** built as corpus-attested,
   well-typed entries after the feature migration; 0 ill-typed skeletons);
   `Syntax/CCGRules` supplies feature-unifying combinators (99.8% of GRAMMAR rule
   firings); `Syntax/CCGDeriv` parses `.auto` derivations (~96% reconstruct);
   `Syntax/CCGTypeChange` learns the type-changing rule class train/test (0.01%
   residue); `Syntax/CCGParse` folds combinators + type-change into one CKY that
   parses whole sentences (99.1% derive the gold root from gold supertags); and
   `Syntax/CCGSupertag` drives it from raw words (a frequency β-beam supertagger;
   ~70–87% from-words root coverage). The core parser (`Syntax/CCG`) combines by
   feature unification. Still to do: a schematic/polymorphic `conj` for the
   coordination-function tail, and feeding real reconstructed sentences through the
   DRT/SDRT stages as test cases — the nine-case corpus has already hidden two real
   defects (an inert SDRT frontier, an unsound DRS merge), so a green suite still
   means "no case exercises this".
4. **Drop the one-edge marginalisation truncation** in `Stage2.Threading`. It is
   the common cause of four separate symptoms; `fullMarginalAt` measures the gap
   but does not close it.
5. **Make antecedent choice an alternative** so the frontier mass becomes a prior
   over readings in the same `Dist Int` space everything else uses.

Not next, and deliberately: growing the lexicon toward arbitrary text. That is a
separate and separately unbounded problem from the truth problem, and the current
type system (`Ty = TyE | TyT`) has no events, times or degrees, so real-world
prose is out of reach for reasons a bigger lexicon does not touch.

## Companion track: the adversarial epistemic corpus

`corpus/` holds a small, deliberately-labeled corpus (YouTube + articles) for
testing whether the epistemic ingestion layer can tell checkable-and-consistent
from common-but-inconsistent sources, per `HANDOFF-corpus-adversarial.md`. It is
data + structure only: an agent decomposes claims and tracks confounds, but never
decides a claim's factual consistency (every verdict slot is null, filled by the
owner or an external reference). See `corpus/README.md`. Raw transcripts stay
outside the repo at `~/corpus/raw/`, the same way CCGbank does.

The corpus now also carries a **fact brain** (`corpus/brain*.py`): a libSQL vector
store (the Rust fork of SQLite, native vector search) that embeds the epistemic
graph's claims so they are retrievable and *explorable by meaning*. Embeddings
position facts; trust is copied verbatim from the graph (external checks only). It
supports semantic retrieval, directed exploration (`explore_frontier`,
`bridge_hypotheses`), query-driven synthesis (`answer`), and grades itself against
the graph's real trust (`calibrate` — honestly returning *not licensed* to impute
trust from topic on the current corpus). `corpus/pipeline.py` runs the whole chain
end-to-end (Haskell ingest → graph → brain → retrieve/explore → oracle loop).
