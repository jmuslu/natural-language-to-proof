# natural-language-to-proof

Converting natural language into discrete, checkable logical forms, with an
explicit and separated layer for handling ambiguity probabilistically **before**
collapsing to a final form.

| Document | What it is for |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | the design, the three tracks, standing principles |
| [MATH-TRACE.md](MATH-TRACE.md) | the mathematical object at each layer, and where it is wrong |
| [WALKTHROUGH.md](WALKTHROUGH.md) | one sentence as explicit state plus checkable propositions |

The short version of the design:

> **Search** (parsing, readings, discourse relations, similarity) is
> probabilistic, open-world, and never finished.
> **Verification** (is this proposition well-typed / provable) is discrete,
> closed-world, and mechanical.
> These must never be conflated. The pipeline always collapses explicitly from
> the first to the second, and **that collapse is a decision, not a derivation,
> so it gets logged as one.**

## Status

**Stage 1 complete: discrete semantic core.** Deterministic, tested, no
probability anywhere. 348 shared checks.

**Stage 2 in progress: probabilistic augmentation.** 170 checks, in its own suite
so Stage 1's number stays a stable signal.

What Stage 2 has and has not:

| Built | Not built |
|---|---|
| candidate generation: scope permutation, modifier-noun fusion | connectives in the lexicon (blocks layer-1 SDRT cues) |
| structural fingerprints + similarity kernel | distributional vectors (no data wired in) |
| RSA: literal/pragmatic listener, speaker, depth-parametric | learned priors or costs |
| finite model enumeration, entailment, informativity | domain sizes much above 3 |
| **SDRT**: relations, right frontier, glue logic | SDRT wired into discourse threading |

Check counts are **per checkout**, since nothing merges between track branches:

| branch | Stage 1 | Stage 2 | track | total |
|---|---|---|---|---|
| `main` | 348 | 170 | — | **518** |
| `conversational` | 348 | 170 | — (docs only) | **518** |
| `truth-mode` | 348 | 170 | 23 | **541** |
| `provenance-mode` | 348 | 170 | 38 | **556** |

There is no meaningful project-wide total. An earlier version of this section
claimed a single project-wide figure, which sums — the sum across *both* track
branches. No single checkout contains that, because the tracks never merge into
each other.

Stage 1 is meant to stop changing. Later stages consume its output; they should
not require edits to it.

### Stages are per-track, not a global roadmap

There is no single linear plan. The three tracks share Stage 1 and then need
different things — reading the stage numbers as one sequence is the mistake this
table exists to prevent.

| Stage | epistemic<br>(truth-mode) | conversational | letra<br>(provenance-mode) |
|---|---|---|---|
| **1** — Montague + CCG + DRT, provenance-tagged | **done**, shared | **done**, shared | **done**, shared |
| **2** — augmentation: alternatives, fingerprints, RSA, models | **in progress**, shared | **in progress**, shared | **in progress**, shared |
| **2b** — SDRT: relations, right frontier, glue | **in progress**, shared | **in progress**, shared | **in progress**, shared |
| **3** — attribute grammars, speculative commit + rollback | when rollback is wanted | **cannot work without it** | open |
| **4** — epistemic graph layer: Kripke, DEL, AGM | epistemic **only** | n/a | n/a |

**Augmentation is shared, and general.** Stage 2 is not a per-track option. It is
always worth understanding a statement from every angle before collapsing —
the extra angles derive additional insight, and the layer's job is to keep signals
from being lost before anything commits. What differs is what each track *does*
with the candidate set: epistemic collapses it, conversational reweights it live,
letra retains it with lineage. All three need it built first.

**On the name collision.** Stage 4 is called the "epistemic graph layer" and it
does sit on the epistemic track — but *Stage 4 is not what makes that track
epistemic*. The track is epistemic because it has a **firm domain verifier**;
Stage 4 is one later formalism built on it, and the track is fully usable without
it. Likewise letra is not "epistemic minus Stage 4" — it has no verifier at all.

Each track's own trajectory lives on its branch in `MODE.md`.

## Branches

```
main ──┬── shared core: Provenance, Syntax (CCG), Semantics (lambda), DRT,
       │                DRT.Canonical, Collapse.Class, Fragment, Pipeline
       │                                                   348 checks
       ├── truth-mode      = epistemic → NL2Proof.Collapse.Truth      + 23 checks
       ├── provenance-mode = letra     → NL2Proof.Collapse.Provenance + 38 checks
       └── conversational              → docs only, no backend yet

merge direction: main ──> every track branch (never sideways)
```

**`truth-mode` is the epistemic track and `provenance-mode` is letra** — the same
things under two naming schemes, not modes that feed tracks. The branch names
came first and are what you check out; the track names name them better. See
[ARCHITECTURE.md](ARCHITECTURE.md) for the third track, **conversational**, which
sits between the two on how firm its oracle is.

The augmentation and derivation stages are **identical** across tracks. Only the
collapse step differs, so only the collapse step is branched. Shared fixes land
on `main` and merge down; nothing merges between track branches.

Each branch adds its backend, its `test/ModeSpec.hs`, and a `MODE.md` — all new
files — plus a few additive lines in `nl2proof.cabal` to register them with cabal.

### Why branches rather than modules

The branch layout is **deliberate, and it is about separability.** A branch is a
complete tree, so porting a track to its own repository is
`git push newremote truth-mode:main` — and a cross-track import is
*physically impossible* rather than merely discouraged. Modules plus a lint test
would be a weaker guarantee: a test can be deleted, a branch boundary cannot be
accidentally crossed. The goal is to stay separable by construction rather than
becoming inseparable by default.

Note what branches do **not** provide: access control. Anyone who can clone the
repository can check out any branch. Isolation happens at port time, not at
repository-access time.

**One real cost.** `nl2proof.cabal` is a shared edit point and does conflict.
Adding Stage 2 to `main` appended a `test-suite` stanza at end-of-file, and both
mode branches had appended theirs in the same place, so all three merges
conflicted. Trivial to resolve — keep both stanzas — but real, and
an earlier version of this README wrongly promised merges would always be clean.

**Specced, not yet done.** Give each branch its own package directory registered
through `cabal.project`'s `optional-packages`, which is ignored when the directory
is absent. A branch would then add *only new files* and never edit a shared one,
removing the conflict without weakening separability.

The build scripts already have no such problem: they discover `test/*Spec.hs` by
glob, so the no-package-manager path needs no branch edits at all.

| | `truth-mode` = epistemic | `provenance-mode` = letra |
|---|---|---|
| Keeps | final logical content | the derivation path |
| Same proposition, two sources | merged into one canonical form | two independently traceable facts |
| Lossy | yes, deliberately | no |
| Provenance question | "why" (which sources *could* have) | "how" (full derivation tree) |
| Supports retraction | no | yes |

Both are folds over the *same* `Prov` tree — which is why provenance tagging had
to exist from day one rather than being retrofitted. `main` defines the contract
in [`NL2Proof.Collapse.Class`](src/NL2Proof/Collapse/Class.hs); neither
implementation lives there.

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

On a mode branch, `cabal test all` runs the shared core suite **and** that
branch's own suite.

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

Built and tested on **GHC 9.4.7 / Ubuntu 24.04** (compiled, all four branches)
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

Pipeline: text → sentences → tokens (exact spans) → CCG derivations →
lambda terms → type check → DRS boxes → discourse merge with anaphora
resolution → `Selection` handed to a collapse strategy.

```
$ ./scripts/build.sh demo

anaphora  [cross-sentence pronoun]
text: "A student arrived. She smiles."

  [0:18] tokens: a student arrived
      derivations: 1
      form: exists x. student(x) & arrive(x)
      provenance of first condition: cond("student"@demo[2:9])
  [19:30] tokens: she smiles
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
    why: most recently introduced accessible referent
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
- **Anaphora resolution is "most recent accessible referent"** and nothing else:
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
  Syntax/Category.hs   CCG categories, category -> semantic type
  Syntax/Lexicon.hs    the fragment's vocabulary
  Syntax/Tokenize.hs   sentence splitting, tokens with exact spans
  Syntax/CCG.hs        signs, combinators, CKY parser
  DRT/Types.hs         DRS boxes, conditions, accessibility, rendering
  DRT/Build.hs         term -> DRS, anaphora resolution, discourse threading
  DRT/Canonical.hs     provenance-free view, shared by both collapse modes
  Collapse/Class.hs    the seam: Selection and CollapseStrategy
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
    Pipeline.hs        Stage 2 end to end
app/Main.hs            demo
test/Harness.hs        shared assert scaffolding, no framework dependency
test/Spec.hs           348 Stage 1 checks
test/Stage2Spec.hs     170 Stage 2 checks
docs/                  standalone probes, not wired into a suite
```

## Next

Stage 2, per ARCHITECTURE.md: SDRT, RSA, and DisCoCat evaluated **in parallel
against the same nine cases**, not in isolation. SDRT anchors directly onto the
existing DRS boxes, so no translation layer is needed.

Before that, the two collapse backends on the track branches should be filled in
against the Stage 1 output that now exists.
