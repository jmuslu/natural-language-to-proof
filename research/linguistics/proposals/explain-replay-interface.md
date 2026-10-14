# Minimal selected-derivation evidence interface

Proposal against accepted82efe8d. This extends the reviewed943060c compatible
replay plan; it does not authorize a source refactor. The earlier plan can share
semantic seeds/guards and produce a **compatible reconstruction**. It cannot
recover the particular internal lexical choices that production discarded.
The additional capability proposed here is an optional retained witness attached
to the actual winning candidate, with a read-only renderer. No new grammar,
semantic admission, root filtering, selection, DRS or gold policy is proposed.

## Why an extra payload is necessary

`CCGSemParse.hs:632–674` stores root state but no child derivation tree.
`packCell:677–681` retains one actual SSign per current key, highest score first
and earlier on a tie. `Pipeline.hs:259–264` projects that root to Sign and finds
notes/score again using root provenance and term. That lookup is not a unique
internal-derivation identity. `backEnd:373–380` translates candidates in their
existing order; selected form/DRS come from the first reading.

The corpus-free controls in ExplainReplayInterfaceSpec test production particle
meaning, direct projection loss, and exact tie/score provenance behavior:6/6pass.
They demonstrate constraints on a proposed payload, not that witness retention is
implemented. Pipeline already restores notes and scores into trace/rrScore; the
projection controls do **not** claim those are missing from every final reading.
The missing guarantee is an occurrence-exact child tree with chosen lexical
origins and constructor decisions, not the final root formula or diagnostic text.

## One optional tree, not a second parser

Illustrative private representation:

```haskell
data EvidenceMode = WithoutEvidence | RetainEvidence
-- Constructor private to the semantic parser; no deserializer or admission API.
data DerivationEvidence = Evidence NodeView [DerivationEvidence]

-- Read-only observation of the actual constructed result. No SSign pointer:
-- avoid a cycle from a sign to its witness back to the sign.
data NodeView = NodeView
  { nodeCategory :: CCat
  , nodeMeaning :: Term
  , nodeProvenance :: Prov
  , nodeScore :: Double
  , nodeStep :: StepView
  , nodeOrigin :: OriginView
  , nodeState :: StateView
  }
```

`StepView` is a tagged union, never a Show-string parser: lexical choice,
licensed span seed, recorded unary transition, recorded binary combinator.
`OriginView` preserves source occurrences/categories and actual lexical origin;
`StateView` is a read-only snapshot of relevant existing typed state, including
list/fused/reflexive/conditional and nominal roles. It confers no capability to
construct a sign or bypass a guard. Reuse existing immutable certificate values
internally; expose narrow views rather than duplicating their semantics.

The minimal parser addition is an optional evidence field on SSign, excluded
from key/comparison/score and not forced in WithoutEvidence mode. Existing
`semParse` remains a WithoutEvidence wrapper; an explicit diagnostic entry point
requests evidence. Each successful existing constructor attaches its operation,
result category/meaning/provenance and selected child evidence. No reconstruction
or alternative enumeration happens during attachment. Do not allocate a global
ID arena, cache the whole chart in Pipeline, or rerun the parser after selection.
Children can be shared immutable tree references. Do not retain whole models,
lexical dictionaries, original charts or context closures in a node.

Exact means the retained **normalized semantic derivation** chosen by this run.
The parser normalizes terms at construction, so this does not recover every
beta-reduction intermediate, a unique theoretical CCG derivation, or search
alternatives pruned earlier. The renderer must not claim any of those.

## Origin requirements that cannot be postponed

- **Names:** capture the chosen `LexicalOrigin` from `lexicalChoices` before it
  is consumed, including NameLexOrigin written/effective forms, casing choice,
  source category, category step and the evidence used for licensing. Show source
  and internal categories distinctly; do not infer rigid-name origin from an
  entity constant in the root term. Existing nominal name certificates remain
  the authority for construction admission.
- **Nominals:** preserve the actual NominalRole transition and noun origin,
  including known versus context-licensed evidence and parser policy in the run
  envelope. Source NP[nb]/N article and nominal copula categories must remain
  distinguishable from internal N/N and VP/N. Pending and discharged roles are
  recorded after the existing transition, not reconstructed from a noun string.
- **Particles:** represent particle-lexeme:give_up as a **span seed**, with both
  original lexical occurrences, offered categories/scores and declared lexical
  sense. Its evidence children are source observations, not ordinary semantic
  leaf derivations that allegedly combined by a binary CCG combinator. A distinct
  SeedSource view inside StepView avoids falsely claiming up had a standalone
  admitted meaning. The output VP is one semantic node.
- **Lists/fused/reflexives:** retain actual constructor state and paired source
  identity. A final-OR list may recompose an earlier provisional conjunction;
  label that certified semantic operation rather than redrawing its child as if
  it had always been OR. Reflexive lexical-governor and conditional-raised states
  must come from the actual successful path, not root-term equality.

Origin display can remain compact. Retaining a witness is not permission to
publish licensed dictionary dumps; only source-local evidence for this reading
belongs in a diagnostic artifact.

## Carry the winner through Pipeline without a join by meaning

Keep packing exactly as written: payload travels with the chosen SSign. Never
merge payloads, prefer a prettier tree, or add witness identity to chart keys.
On ties, the earlier candidate's **entire** payload wins. No witness registry
indexed by `(category,term)` or `(term,provenance)` can safely replace this rule.

At the roots→parses boundary retain an ordered parallel payload list, one entry
for every root. `backEnd` currently maps translate over parses without filtering
or reordering. The smallest Pipeline bridge is to attach evidence to resulting
ReadingResults by this same index, retaining entries for type-check failures.
Add `rrDerivationEvidence :: Maybe DerivationEvidence` or an equivalent internal
wrapper consumed by Explain. Assert equal lengths before attaching; on mismatch
fail diagnostic attachment rather than borrow another root's evidence. If future
backend code filters/reorders candidates, it must carry an opaque per-run ordinal
through that operation instead of a post-hoc zip. Do not change existing notes,
score, type/DRS processing or selection in this evidence-only change.

A root may be rejected by sentence-level guards and never enter this list. Its
trace remains a rejection trace; no “selected derivation” witness is invented.
Hand-fragment roots can initially have Nothing and keep their current renderer.
The selected witness is the first reading's payload because the existing
selection chooses that reading, not because a renderer searched for a matching
formula. DRS/anaphora/presupposition transformations remain separate stages:
this witness records the semantic parse, not a claim that later DRSs were its
literal node terms.

## Rendering contract

Prefer retained evidence when present and internally consistent with that exact
reading's root category/provenance/normalized term. That consistency check detects
attachment bugs; it does not certify arbitrary caller-authored evidence as genuine.
Only parser-private constructors establish origin. If missing, label the existing
path “compatible reconstruction”; if reconstruction fails, retain raw provenance
and Pipeline form/DRS/claims. Do not silently relabel old replay output as witness.
A corrupt/incomplete witness produces a diagnostic and honest fallback, never a
new parse, changed meaning, omitted reading or asserted claim.

Leaf/source display must distinguish a real semantic lexical node from a source
observation inside a multi-token seed. First-divergence reports can now identify
the selected categories and constructors; determining mismatch against English
still requires independent gold. A faithful trace of a wrong parse stays wrong.

## Required implementation controls and sequence

The included six checks are baseline observations, all green on unchanged source.
They are not mock witness tests. Before source implementation, add tests against
the actual proposed public read-only accessor for these independent outcomes:

1. WithoutEvidence and RetainEvidence produce identical ordered root/reading
   projections, scores, traces, forms, DRSs and claims, including failures. Test
   both noun policies and ambiguous same-key tie candidates; only evidence differs.
2. Competing equal-root lexical origins retain the chosen leaf category and name
   source origin, never a compatible alternative. Reversing a genuine tie changes
   the witness exactly as current packCell changes the winner; adding evidence
   does not change either winner.
3. Positive and negated particles expose two original source occurrences under
   one span seed, no forged combinator; original scores and lexical sense survive.
4. Known and context-licensed nominal cases preserve distinct typed origins and
   actual policy. Names preserve written/effective category changes. Failed roots
   and missing entries cannot shift later payloads by one index.
5. Certified final-OR lists, fused pairs, local reflexive and conditional paths
   show their actual accepted steps. Reuse the four existing forged-replay
   negatives; payload creation is inaccessible for those nonproduction paths.
6. Renderer distinguishes retained witness, compatible reconstruction and raw
   fallback; none changes authoritative Pipeline output or semantic admission.

Review the concrete parser-only attachment diff first, including every SSign
constructor/update and root packing. Review the Pipeline carrier separately, then
renderer use. Do not combine this with semantic-helper extraction or new language
rules. Run normal gates and frozen fidelity between stages. Before enabling
corpus diagnostics, measure memory/time with and without evidence on authorized
workloads; tree retention adds memory even with shared children. No new CCGbank
load is authorized by this proposal, and no memory benefit is claimed unmeasured.

This is larger than compatible replay because the discarded information must be
retained at its creation. It is bounded to optional diagnostic evidence and its
carrier; global chart-witness arenas, exact beta traces, public certificate
constructors and proof/admission APIs are explicitly unnecessary.
