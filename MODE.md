# Branch: `conversational` — the **conversational** track

Live cross-lingual interpretation. Probabilistic domain oracle, session-scoped.

> Unlike the other two, this track has only one name. `truth-mode` **is** the
> epistemic track and `provenance-mode` **is** letra; this branch is just
> `conversational`.

This file exists on the track branches only. `main` has no `MODE.md`, so merging
`main` down never touches it.

## Status: no code, deliberately

Unlike `truth-mode` (epistemic) and `provenance-mode` (letra), this branch
carries **no backend and no `ModeSpec.hs`**. That is a decision, not a gap.

`ARCHITECTURE.md` → *Prior art, and the reinvention tension* concludes that most
of this track's mechanism already exists — source-side clarification aimed at a
monolingual speaker, ambiguity detection from confidence and plausibility, and
steering that reweights the model are all published and in places patented, in
the interactive conversational spoken language translation lineage. RSA over
multi-turn dialogue is active current work. Structured dialogue state with user
corrections is well covered by dialogue state tracking.

So the next step is **not** an implementation. It is a wizard-of-oz test:

> Two conversations — (a) a plain MT engine, (b) the same engine plus a human
> simulating the steering loop. Measure **repair turns** ("no, I meant…") and
> time-to-mutual-understanding. Not BLEU, not COMET.

If repair turns do not drop, the premise is wrong and there is nothing for the
machinery to sit on. Writing a backend before that test would be building on an
unvalidated assumption, which is the thing this project's methodology notes exist
to prevent.

The branch exists now so the track has a home, and so that whatever gets built
lands somewhere with the right merge relationship to `main` from the start.

## What would go here, if the test passes

The two contributions that survived the prior-art search:

1. **Dependency-tracked retraction of pragmatic inference chains.** DST
   corrections fix slot values; ReacTOD-style validators enforce coreference
   consistency on update. Neither locates and unwinds *every downstream
   inference that rested on a corrected reading*. This is `Prov` used as
   dependency edges — a third job for it, distinct from span traceability
   (epistemic) and lineage (letra). You cannot invalidate what you cannot
   locate.
2. **Repair rate as the evaluation target**, with a fixed set of conversation
   traces standing in for `Fragment.hs`'s fixed sentence set. Stateful traces —
   sequences of (utterance, steering) pairs — not a set of sentences.

Plus the structural piece: an **incremental** pipeline. `NL2Proof.Pipeline` is
batch (`splitSentences :: String -> [Sentence]` wants the whole text up front),
and this is the only track with a hard real-time requirement.

Reusable from `main` as-is: `Trace` (Decision/Diagnostic — the confidence and
ambiguity annotations are already the right shape), `DRT.Build.Discourse` (already
exactly session-scoped: accumulates across utterances within one run, then is
discarded), and `DRT.Canonical` (claim identity).

`Collapse.Class.Selection` needs to become **revisable** rather than final.
`selRejected` matters *during* the session, because rollback needs the discarded
readings to re-derive from, and is dropped when the conversation ends — neither
the epistemic track's collapse-then-verify nor letra's refusal to collapse.

## Hard constraints, already settled

- **Wrap, don't rebuild.** An MT engine is a candidate generator, which is all
  `ARCHITECTURE.md`'s non-goals permit an LLM to be trusted as. Do not rebuild
  lexically constrained decoding or a wait-*k* policy. Use an existing engine and
  IMTLab for harnessing.
- **Latency is a first-class constraint**, uniquely to this track. Full RSA is
  nested recursion over a candidate set and may not fit a conversational budget.
  That number caps how much of Stage 2 can run live.
- **There are granted patents** covering source-side ambiguity resolution in
  interactive translation. A freedom-to-operate question for a product, needing
  real legal advice rather than a design-doc note. Not one to discover late.

## Running

```bash
export GHC_BIN="$LOCALAPPDATA/ghc/ghc-9.12.4-x86_64-unknown-mingw32/bin"
./scripts/build.sh
```

Runs the shared 348-check core suite. No mode suite yet — the build scripts pick
up `test/ModeSpec.hs` automatically if one appears.

## Keeping up to date

```bash
git checkout conversational
git merge main
```

Merge direction is **`main` → branch only**. Nothing merges between the three
track branches — `truth-mode` (epistemic), `provenance-mode` (letra), and this
one. If a change here needs an edit to anything upstream of
`NL2Proof.Collapse.Class`, that change belongs on `main`.
