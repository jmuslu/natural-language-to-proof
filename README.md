# natural-language-to-proof

Converting natural language into discrete, checkable logical forms, with an
explicit and separated layer for handling ambiguity probabilistically **before**
collapsing to a final form.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full design. The short version:

> **Search** (parsing, readings, discourse relations, similarity) is
> probabilistic, open-world, and never finished.
> **Verification** (is this proposition well-typed / provable) is discrete,
> closed-world, and mechanical.
> These must never be conflated. The pipeline always collapses explicitly from
> the first to the second, and **that collapse is a decision, not a derivation,
> so it gets logged as one.**

## Status

**Stage 1 complete: discrete semantic core.** Deterministic, tested, no
probability anywhere. 348 checks passing.

| Stage | What | State |
|---|---|---|
| 1 | Montague lambda calculus + CCG + DRT, provenance-tagged | **done** |
| 2 | SDRT / RSA / DisCoCat augmentation | not started |
| 3 | Attribute grammars, speculative commit + rollback, diagnostics | not started |
| 4 | Epistemic graph layer (separate track) | out of scope |

Stage 1 is meant to stop changing. Later stages consume its output; they should
not require edits to it.

## Branches

```
main ──┬── shared core: Provenance, Syntax (CCG), Semantics (lambda), DRT,
       │                Collapse.Class, Fragment, Pipeline
       │
       ├── truth-mode      → NL2Proof.Collapse.Truth      + its spec
       └── provenance-mode → NL2Proof.Collapse.Provenance  + its spec

merge direction: main ──> both branches (never sideways)
```

The augmentation and derivation stages are **identical** for both modes. Only
the collapse step differs, so only the collapse step is branched. Shared fixes
land on `main` and merge down; nothing merges between the two mode branches.

| | `truth-mode` | `provenance-mode` |
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

The project depends only on `base` and `containers`, both of which ship inside a
GHC bindist. **No cabal or stack required** — a bare unpacked GHC is enough.

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
`demo` to run the demo instead, or `compile` to also produce native binaries. If
`ghc` is already on your PATH, `GHC_BIN` can be skipped. `nl2proof.cabal` is
included for when you do have cabal, but nothing here needs it.

Built and tested with GHC 9.12.4 on Windows.

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
- **`Prov` is a tree, not a flat tag.** That is what makes the two modes two
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
app/Main.hs            demo
test/Spec.hs           348 checks, no test framework dependency
```

## Next

Stage 2, per ARCHITECTURE.md: SDRT, RSA, and DisCoCat evaluated **in parallel
against the same nine cases**, not in isolation. SDRT anchors directly onto the
existing DRS boxes, so no translation layer is needed.

Before that, the two collapse backends on the mode branches should be filled in
against the Stage 1 output that now exists.
