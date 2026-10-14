# Minimal shared production replay interface

Updated against accepted research `59955b6`, following the reviewed
[replay audit](EXPLAIN_LIST_REPLAY.md). This change is not implemented here.
Independent tests of the **current** production and renderer code now establish
six concrete failures without a corpus/model load. No new parser grammar,
semantic template, public claim type or solver behavior is proposed.

## Measured starting contract

`python3 test/run-explain-replay-proposal.py` runs18 corpus-free checks:12pass,
6fail. Its temporary Explain copy changes only the module declaration to expose
private functions. A small authored tag/POS model supplies all lexical observations;
no CCGbank files are read. Expected meanings and forbidden provenance trees are
hand-specified, not generated from renderer outputs.

| Scenario | Production fixture | Current Explain |
|---|---|---|
| Ordinary unary predicate | Intended meaning | Replays |
| Three-member comma/final-OR list | Intended OR meaning | No replay |
| Everything + restrictive that | Intended universal restriction | No replay |
| Positive/negative adjacent give-up span seeds | Intended lexical meaning and negation | No replay |
| Local direct-object reflexive | Intended diagonal relation | Replays |
| Ordinary comma conditional | Intended implication | Replays |
| Forged comma coordination of conditional and then operators | Path absent from production | Accepts forged target/path |
| Forged does+defend composition before reflexive application | Path absent from production | Accepts forged path with same final meaning as a legal path |

The forged targets are renderer contract tests, **not observed parser outputs**.
In particular, this does not claim the current production parser returned the
conditional duplication. The reflexive test isolates the stronger issue: equality
of the final relation does not establish the governor's required lexical status.

## One context, existing chart state, four shared operations

Keep the implementation in `CCGSemParse.hs`; no new parser/replay subsystem or
large derivation-witness refactor is required. Factor pure pieces that already
exist, without changing decisions. Proposed names/signatures are illustrative
but precise about inputs and outputs:

```haskell
-- Constructor private; contains references to model/source/tokens, annotated
-- leaves and the meaningful unary list calculated once for this sentence.
data SemContext
prepareSemContext :: SemModel -> SourceId -> [Token] -> SemContext

-- Raw annotated alternatives before usefulAt/beam pruning, including licensed
-- multi-token seeds with original token provenance. Span is the existing source span.
semanticSeeds :: SemContext -> Span -> [SSign]

-- Applies the existing guarded unary constructor for a recorded output category.
-- May return more than one compatible source-category candidate.
semanticUnary :: SemContext -> CCat -> SSign -> [SSign]

-- Rechecks pair/combinator/output licensing, then invokes existing semCombine.
semanticBinary :: SemContext -> Combinator -> CCat
               -> SSign -> SSign -> Maybe SSign

-- Root category/type/discharged-state checks; share the existing predicate.
semanticRoot :: SemContext -> SSign -> Bool
```

`SemContext` is not another model load. It holds the supplied immutable model and
the same per-sentence preparation already used by `semParse`. No dataset, lexical
expansion, stochastic step, extra full parse or inferred certificate is involved.
No abstract term→certificate conversion is exposed.

The production chart must call these helpers too. Exporting duplicate “equivalent”
helpers while leaving its current paths intact defeats the point of the refactor.
Keep category forward/backward pruning, beam packing, scoring and root selection
inside the existing parser; they are search operations, not renderer semantics.

### Exact extraction boundaries

1. Move the current `ordinary`, `fusedPairs`, `annotated`, `mkLeaf`, `meaningful`
   and selective `clusterCoord` preparation into the shared context preparation.
   Keep `spLexical` as a projection of those annotated entries. `semanticSeeds`
   returns the same prepared signs before chart-specific `usefulAt` filtering.
   Source IDs/spans come from the original sentence's tokens, not from display
   text. Do not use ordinary `lexicalSigns` alone for fused forms.
2. Factor the existing `unaries` expression, including pending-reflexive rejection,
   `fusedUnaryAllowed`, conditional-raised propagation and stipulation/provenance
   creation. Selecting a recorded target must not bypass its `meaningful` list
   or enable raising that this model/sentence does not permit.
3. Factor a thin binary wrapper around existing `fusedSeenPair`, the required
   `combineNamed` result and `semCombine`. It must verify `(comb,out)` is one of
   the actual category combination outputs. Do not expose raw `semCombine` as
   the whole safe interface: it assumes syntactic eligibility supplied by its
   caller. `semCombine` itself continues to own list/reflexive/fused/conditional
   transitions and intensional type checks unchanged.
4. Factor the existing root conditions: ordinary S-compatible category, TyT,
   no pending coordinator/structural item and discharged fused and nominal states. Preserve
   sentence-wide root safety checks (including quotation/nonrestrictive policies)
   where production applies them; the renderer must not claim a candidate is a
   production-admissible root based solely on this local predicate. Its input is
   an already retained Pipeline root; test fabricated targets as negative probes,
   not another route to admission. If sharing sentence-wide root filtering becomes
   necessary, expose that existing pure predicate separately rather than rerun
   selection. Do not quietly change public `semanticRoot` into answer admission.

Keep the two-round chart unary closure as it is; a provenance replay follows its
recorded finite tree, not a fresh closure search. Legal semantic reconstruction
is weaker than proving a candidate survived every operational beam/pruning choice.
That limit must remain explicit even after shared transitions are installed.

## Replace the renderer state, not the grammar

Explain's candidate should contain the actual production `SSign` plus display
children, replacing its duplicate cat/term/coord/struct semantic fields:

```haskell
data Cand = Cand { cSign :: SSign, cTree :: DT }
```

Seed lookup calls `semanticSeeds` and restricts provenance to the exact recorded
source/span/word. Unary and binary replay enumerate only operations named by the
recorded `ProvRule`, using the shared functions above. The tree's term/category
come from the returned `SSign`; the renderer never recomputes `coordTerm` itself.
`mkReading` continues to use Pipeline `rrForm`/`rrDRS` unchanged.

Expose one opaque packing identity accessor (e.g. `semanticIdentity`) or shared
stable deduplication over candidate keys; include **all** current chart identity
fields, notably list and fused certificates and conditional-raised state. Do not
return only a hash without collision handling. Existing `packCell` is not an
innocent deduplicator: its beam truncates and sorts scores, so reusing it with an
arbitrary replay beam could silently lose valid explanations. Prefer a shared
exact identity key while preserving replay's existing deterministic choice order.
No full rendered tree is added to every production chart sign.

The final root must still match recorded provenance and canonical root meaning.
Use source/category state, not a search for a lexical string such as “everything”
or the presence of an OR in the reduced term, to authorize a transition.

## Read-only evidence views for rendering

`CoordList` is currently internal. Provide a **read-only view**, not a public
constructor for fabricating certificates. Suggested fields are resulting category,
optional overt operator, ordered `(member term, provenance)` pairs and ordered
`(edge word, provenance)` pairs. This view is obtained only from a production
sign after a valid shared transition. Public fields need not grant a way to place
arbitrary evidence back into `SSign`.

Render certified recomposition as an explicit semantic step. If an earlier
comma subtree was provisionally AND but a later final OR licenses recomposition,
retain the child shown as built and label the parent list operation, its covered
member spans and which comma edges changed interpretation. A normalized n-ary
view may supplement the binary provenance tree; never label it an original
ordinary binary-coordination derivation. Explicit incompatible AND/OR subtrees
stay atomic members, matching the production certificate.

Fused views display the offered source categories, replacement categories,
paired source spans and successful discharge point. Reflexive views show the
local lexical verb/operator pair and identification of its subject/object slots.
These facts must come from transition state and structured provenance. Human-
readable `Stipulation` text may be printed, but not parsed as a certificate format.
Shared state prevents replay from inventing a certificate because a root happens
to have the expected universal or diagonal meaning.

## Compatible reconstruction is not an original witness

The small refactor above yields **rule-compatible reconstruction constrained by
recorded provenance and root meaning**. It does not promise the exact lexical
choices of the original selected derivation. `Pipeline.toSign` currently erases
internal categories and lifecycle evidence; multiple compatible reconstructions
can share its `(root category, term, provenance)`. A good label is:
“compatible reconstruction of the selected reading”.

Do not add a new “exact witness” claim based on term equality, score re-ranking,
first compatible replay, or successful tests. True original witness retention
would require selecting/storing internal lexical alternatives/categories and
semantic-step evidence with each chosen root before that information is erased.
That is a separate change with memory measurements and lifecycle tests. It is
explicitly excluded from this minimal proposal.

## Failure and first-divergence behavior

Keep raw-provenance fallback and authoritative selected form/DRS/claims. Improve
the diagnostic from “could not replay” to the earliest recorded node whose
compatible candidate set becomes empty, recording span, rule, attempted category
pairs and a reason class (leaf preparation, guarded unary, guarded binary, root
mismatch). Report multiple competing reasons when ambiguity prevents uniqueness.
This is a **replay failure boundary**, not the semantic pipeline's first deviation
from independent gold. Do not manufacture lexical leaf terms to fill the display
when a certificate cannot be reconstructed.

## Acceptance and implementation sequence

1. Reviewer approves this refactor contract and the18 current checks. Preserve
   their independent meanings and forbidden paths when adding the shared interface.
2. Extract preparation/transitions without policy edits; existing parser/claim
   suites and frozen deterministic fixture outputs must remain unchanged. Add
   direct lifecycle controls for paired sources, pending unary rejection and
   list identity deduplication at the shared helper boundary.
3. Switch Explain to the shared calls and retire its copied `semComb` logic.
   All18 owned proposal checks should pass. Add list punctuation/mixed-edge,
   fused wrong-pair/source, raised conditional and forged reflexive controls from
   the original audit. Add a root-mismatch fallback check preserving Pipeline
   DRS/claims and a wording check for compatible-reconstruction terminology.
4. Run full release gates and fidelity before coordinator integration/push.
   A documentation/test branch containing expected-red unregistered controls is
   not an approved production change or evidence of general English fidelity.

The included test runner is temporary proposal instrumentation. Production test
registration should target a proper library replay adapter or an explicit testing
interface, avoiding a permanent module-header rewrite. No test expects the parser
to accept forged roots, and no test constructs or forges a `CoordList` certificate.

## Accepted nominal and particle extraction requirements

Reviewer requirements are part of this contract: preparation, transitions and
identity must include the current nominal roles and every guard, including
future reviewed v2 changes; this plan does not freeze the older leaf-only state.
`semanticSeeds(context, span)` returns licensed single-token and multi-token
seeds. The accepted adjacent give-up construction spans two original tokens,
keeps both lexical source leaves and its explicit construction provenance, and
starts NominalPlain. Replay first matches a complete seed's recorded provenance
and span; it must not pretend the seed is an ordinary binary CCG rule or mint
its lexical sense from final term equality. Display the construction operation
and original source categories separately from normal combinators.

`semanticRoot` above is a LOCAL transition-compatibility check unless all
sentence-wide admission policies are shared too. To label a reconstruction
production-admissible, factor and apply the existing quotation/nonrestrictive
and other sentence-level checks; fabricated-target tests must exercise these.
Beam survival and exact original derivation remain distinct claims.

Added public parser/renderer tests use independently specified positive and
negative give_up meanings with a tiny authored observed-tag model, not corpus
outputs. They require every retained real multi-token root to reconstruct.
No fabricated binary operation stands in for a lexical span seed. Extraction
must preserve scoring, ordering, packing and the two unary rounds exactly.
First land and review the source-only extraction; switch renderer separately.

## Frozen-binary particle observation

Accepted59955b6 Explain (manifest verified, one globally token-limited load)
processed only the three frozen particle texts. Each has the intended final
formula/DRS/claim status and no Pipeline failure; all three derivation sections
explicitly fall back to raw provenance, and lambda leaf tables are empty.
Positive gives-up source is S[dcl]\NP, negative give-up source S[b]\NP,
with offered up:(S\NP)\(S\NP). Raw provenance retains both original
leaves under particle-lexeme:give_up. The earliest identified unsupported replay
node is this construction: Explain's two-child branch only recognizes named
CCG combinators, so no seed candidate can survive. This is source-supported
localization of observed fallback, not an existing renderer diagnostic.
No deviation from the three independent declared meanings was observed.
The proposed span-seed accessor fixes the abstraction boundary; manufacturing
a binary rule or certifying a seed from root equality would misrepresent it.
See own notes for preserved evidence and the frozen binary digest.
