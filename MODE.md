# Branch: `provenance-mode`

Derivation-preserving. The derivation path matters, not just the resulting
proposition.

This file exists on the mode branches only. `main` has no `MODE.md`, so merging
`main` down never touches it.

## What this branch adds

Two files, both new — nothing shared is edited, so `git merge main` here is
always clean:

| File | Role |
|---|---|
| `src/NL2Proof/Collapse/Provenance.hs` | the collapse backend |
| `test/ModeSpec.hs` | 38 checks, picked up automatically by the build scripts |

Everything else — tokenizing, CCG derivation, lambda composition, type checking,
DRS construction, anaphora resolution, `DRT.Canonical` — comes from `main`
unchanged and is byte-identical to what `truth-mode` uses.

## The defining property

From ARCHITECTURE.md, and this *is* the whole specification of the module:

> Two claims that happen to collapse to the same proposition right now must
> remain independently traceable back to their source, in case one source is
> later retracted or found unreliable.

`retractSource` is what makes that a specification rather than a preference.
Retraction is only possible if the facts were never merged. So this collapse
**does not deduplicate**, and that is the one thing it must never be "optimized"
into doing.

Two documents asserting the same proposition:

```
provenance-mode form
  facts:     2 (no deduplication)
  sources:   [doc-A,doc-B]

#0  love(john, mary)
      sources: [doc-A]
      derived: cond("loves"@doc-A[5:10], "john"@doc-A[0:4], "mary"@doc-A[11:15])
#1  love(john, mary)
      sources: [doc-B]
      derived: cond("loves"@doc-B[5:10], "john"@doc-B[0:4], "mary"@doc-B[11:15])

  convergent claims (truth-mode would merge these):
    love(john, mary) <- 2 independent derivations from [doc-A,doc-B]
```

Then `doc-A` is found unreliable:

```
--- retract doc-A ---
impact (before, after, lost): (2,1,1)
  facts:     1
  sources:   [doc-B]

#1  love(john, mary)
      sources: [doc-B]
```

**The claim survives on the strength of the remaining source.** That is the
operation `truth-mode` structurally cannot perform: once two assertions have been
merged into one canonical condition, there is no way to withdraw one of them.

The companion assertion on `truth-mode` is the exact opposite, run against the
same shared core. **If either branch ever satisfied both properties, the two
modes would have stopped being distinct** — that is the regression these two
suites exist to catch.

## `how` vs `why` provenance

`how`-provenance (the full derivation tree) is strictly more informative than
`why`-provenance (just which sources could have produced the result). This branch
keeps the former; `truth-mode` keeps only the latter.

The suite pins this down directly: `provSize (factProv f) > length (factSources f)`
for real facts. If a derivation tree ever collapsed to just its source set, this
mode would have silently degraded into `truth-mode`'s provenance handling while
still passing every other test.

## Design notes

- **`factId` exists so convergent facts stay distinguishable.** Without it a
  `[Fact]` would be a set of claims and the whole point would be lost.
- **`factClaim` reuses `DRT.Canonical` as claim *identity*, not as output.**
  Two facts may share a `factClaim` and remain separate. Detecting convergence
  and merging on convergence are different operations, and only the first
  belongs here.
- **`convergentClaims` surfaces corroboration instead of collapsing it.**
  Independent corroboration is *information*: a mode that merges it cannot tell
  "two sources agree" from "one source said it once".
- **Retraction drops facts rather than re-deriving them.** A derivation that
  *used* a retracted source is not trustworthy just because some other
  derivation of the same claim exists — that other derivation is a separate
  `Fact` and survives on its own merits.
- **`collapseProvenance` zips two parallel traversals** (claims from
  `canonicalize`, provenance from `drsConditionProvs`). If those ever walked
  conditions in different orders or counts, the zip would silently truncate and
  facts would get the wrong derivations attached. The suite asserts the counts
  match on every case in the evaluation set.

## Running

```bash
export GHC_BIN="$LOCALAPPDATA/ghc/ghc-9.12.4-x86_64-unknown-mingw32/bin"
./scripts/build.sh
```

Runs the shared 348-check core suite, then this branch's 38 mode checks.

## Keeping up to date

```bash
git checkout provenance-mode
git merge main
```

Merge direction is **`main` → branch only**. Nothing merges between
`truth-mode` and `provenance-mode`. If a change here needs an edit to anything
upstream of `NL2Proof.Collapse.Class`, that change belongs on `main` — the seam
is in the wrong place, and forking the core to accommodate a mode is the failure
this layout is designed to prevent.
