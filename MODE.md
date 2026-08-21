# Branch: `truth-mode`

Lossy canonical compression. Only the final logical content matters.

This file exists on the mode branches only. `main` has no `MODE.md`, so merging
`main` down never touches it.

## What this branch adds

Two files, both new — nothing shared is edited, so `git merge main` here is
always a clean fast-forward or trivial merge:

| File | Role |
|---|---|
| `src/NL2Proof/Collapse/Truth.hs` | the collapse backend |
| `test/ModeSpec.hs` | 23 checks, picked up automatically by the build scripts |

Everything else — tokenizing, CCG derivation, lambda composition, type checking,
DRS construction, anaphora resolution, `DRT.Canonical` — comes from `main`
unchanged and is byte-identical to what `provenance-mode` uses.

## The defining property

> Two independent assertions of the same proposition become **one**.

```haskell
truthOf srcA "John loves Mary. John loves Mary."
-- canonConditionCount (tfForm ...) == 1
-- tfDropped                        == 1
```

And across two documents:

```haskell
collapseTruth (mergedSelection "John loves Mary." "John loves Mary.")
-- one condition
-- tfSources == [A, B]      -- you still know *which* sources
--                          -- but no longer which condition came from which
```

The companion assertion on `provenance-mode` is the exact opposite, run against
the same shared core. **If either branch ever satisfied both properties, the two
modes would have stopped being distinct** — that is the regression these two
suites exist to catch.

## What is discarded, precisely

1. **Derivation trees.** `how`-provenance reduced to `why`: a set of `SourceId`s.
   After this, "these two conditions came from different sentences" is
   unrecoverable.
2. **Duplicate conditions.** Two independent assertions of one proposition become
   one. This is the step that makes retraction impossible, and it is the whole
   reason `provenance-mode` exists as a separate branch.
3. **Condition order.** Sorted into a canonical order, so surface order stops
   being observable.

Retained: `tfSources` (which sources are involved) and `tfDropped` (how many
nodes were removed). The loss is **measured**, not assumed away — per the
methodology note that drift you have measured differs in kind from drift you have
decided not to look at.

## Why lossy is correct here

This is the mode that feeds the proof stage. A proof checker does not care which
document a hypothesis arrived in; it cares whether the proposition is well-typed.
Canonicalizing means two sentences that entail the same thing produce the same
object, which is exactly what you want before handing off to Agda/Coq/Lean.

Use `provenance-mode` instead when you need to retract a source later, or to
audit which derivation produced a claim.

## Running

```bash
export GHC_BIN="$LOCALAPPDATA/ghc/ghc-9.12.4-x86_64-unknown-mingw32/bin"
./scripts/build.sh
```

Runs the shared 348-check core suite, then this branch's 23 mode checks.

## Keeping up to date

```bash
git checkout truth-mode
git merge main
```

Merge direction is **`main` → branch only**. Nothing merges between
`truth-mode` and `provenance-mode`. If a change here needs an edit to anything
upstream of `NL2Proof.Collapse.Class`, that change belongs on `main` — the seam
is in the wrong place, and forking the core to accommodate a mode is the failure
this layout is designed to prevent.
