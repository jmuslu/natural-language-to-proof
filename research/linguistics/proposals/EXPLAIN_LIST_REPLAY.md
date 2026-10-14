# Explain replay for certified coordination lists

Static audit,2026-10-14. Explain baseline is `c409f22`; pending coordination source
is merge commit `4c37c66`. No parser/corpus/model/benchmark was run. This proposes
an implementation and tests, not a verified runtime repair.

## Finding

`tools/Explain.hs` cannot generally reconstruct the pending parser's comma-list
semantics. Its local `Cand` keeps category, term, pending coordinator, structural
word and display tree; its `semComb CoordApply` immediately calls `coordTerm` with
`coordinatorOp word`. A comma therefore always applies AND during replay. The
parser now carries `ssList :: Maybe CoordList`, with member terms/provenances,
edge words/provenances, category and overt-operator evidence. Its `coordinateList`
can recompose certified comma edges as OR after an overt right-closing OR arrives.

The difference is semantic state, not a missing display label. For an authored
three-member list `A, B or C`, a chart subtree can initially contain `A∧B` and
later become `A∨(B∨C)` through a certified list operation. Naively replaying its
binary children retains `(A∧B)∨C`, or `A∧(B∨C)` under the other attachment. Neither
is the intended certified list. `canonicalAC` cannot equate AND and OR.

Explain currently insists on equality with the selected root's own term and emits
raw provenance if none matches. This is honest and must remain the failure mode.
`mkReading` still takes its normal form and DRS from the shared Pipeline reading;
it does not substitute replay semantics into the solver/exporter. Therefore an
unreplayed tree is **not** evidence that the parser's reported DRS was computed
from the wrong fallback. It is a missing explanation. On fallback, the lambda
leaf table can also be empty because it depends on `rdTree`.

## Other state already missing from Explain

| Parser evidence | Current replay omission | Consequence |
|---|---|---|
| `CoordList` certificate and `pendingCoordinator` edge recovery | No list field; unconditional comma AND | A valid OR-list reading can have no matching replay. |
| Conditional `ssOpenConditional` and `ssConditionalRaised` | No obligations or pending-modifier guard | Replay can admit a grammar path production rejects; root equality alone does not establish licensed internal choices. |
| `FusedCertificate` and `FusedRole` | Leaves use `lexicalSigns` individually, not sentence-local paired reanalysis | Fused head/relative leaves are absent, so valid restricted-pronoun derivations can fail replay before composition. |
| `fusedSeenPair`, `fusedTransition`, unary/root discharge guards | No transition checks | Adding only fused-looking categories would not prove they belong to the same input pair. |
| Reflexive local lexical provenance plus `reflexive-local-binding` note | Term/category may reconstruct, but local-binding guard and pending-unary guard absent | A matching reflexive root does not certify the actual local licensing checks. |

Fused reanalysis is minted from adjacent tokens and **offered source categories**
inside `semParse`, not from the printed target category alone. Certificates include
source ID, head/relative indices, spans, words and original categories. The two
valid internal applications check exact role identity; pending roles cannot pass
through punctuation, coordination, composition, raising or roots. Preserve those
facts in explanation; never reconstruct a certificate by parsing a trace's Show
string or searching for “everything” anywhere in the input.

The reflexive repair has a different lifecycle: a lexical operator is supplied
through `lexicalSigns`, so Explain may obtain its term today. Production nonetheless
checks that both adjacent binder operands are lexical, the right one has its own
local-binding stipulation, the left category licenses the local reflexive VP,
and the terms have the required types. The renderer's plain backward application
is not the same contract. Merely obtaining the same diagonal relation at the
root does not prove local anaphor binding was licensed.

## Recommended minimal maintainable implementation

Keep the current Pipeline as the only source of selected terms, DRSs and claims.
Replace Explain's duplicate semantic transition implementation with a small shared
**replay interface in CCGSemParse**, reusing the chart's actual constructors and
checks. Do not copy `coordinateList` into Explain or introduce a second list
recognizer. The library needs three reusable operations, factored from existing
code without changing their policies:

1. Sentence lexical preparation: given model, source and tokens, return the same
   annotated lexical alternatives used by `semParse`, including fused pairs and
   their provenance. Ordinary lexical views can project these alternatives;
   Explain must not mint a second, approximately matching fused certificate.
2. Legal unary step: given the actual chart state and recorded target category,
   apply the same meaningful-unary set and reflexive/fused/conditional lifecycle
   checks as production. Preserve the model's selective type-raising policy.
3. Legal binary step: given model, combinator, output category and two chart
   states, use the same seen-pair/source-pair check and `semCombine`. Let production
   compute the new term, list certificate, notes and obligations. Its punctuation
   transitions carry state; ordinary application/composition clears only what the
   production constructor clears.

A replay candidate can wrap the production chart state plus its display tree,
rather than mirror every `ss*` field independently. Each replay node enumerates
only alternatives consistent with its recorded provenance rule. Candidate packing
must include the same semantic/certificate identity as production; do not retain
Explain's old category/term/coord/struct-only key. A helper that exposes an opaque
identity or lawful deduplication is preferable to exporting all certificate
constructors solely for the tool. Scores may order compatible reconstructions,
but must not change selected Pipeline meaning or masquerade as a new parse.

This is a bounded refactor of existing leaf/unary/binary construction. It requires
no second CCGbank load and no rerun of the full parser just for a tree. It avoids
storing full rendered trees on every chart candidate, whose memory cost has not
been measured. Do not widen exported APIs beyond what replay/tests require.

### Be precise about “selected derivation”

Pipeline currently turns an `SSign` into `H.Sign` using category, term and
provenance; it does not retain every internal category or certificate. A root
term/provenance match proves a **compatible reconstruction**, not that each
lexical/category alternative is uniquely the one selected originally. Shared
transitions improve legality, but do not recover information already discarded.
Label the result accordingly while this representation remains in place.

If the product requires the **exact original** certificate/derivation rather than
a licensed root-compatible reconstruction, retain a compact production derivation
witness through `SentenceResult`/`ReadingResult` (or a root-keyed sidecar) before
information is discarded. It must identify lexical alternatives, internal output
categories and semantic-step certificates, including fused and list operations.
The chosen root should carry its own witness; matching a global bag by root term
alone is insufficient when several legal derivations share that term. This is a
larger evidence-retention change with memory/lifecycle tests, not something an
Explain-only term rewrite can honestly promise.

## Render the list repair as an actual semantic step

A certified list step may deliberately change the earlier comma interpretation.
Do not redraw it as ordinary `coord` over immediate child normal forms. Show:

- actual span, resulting category and resolved operator;
- ordered member spans and operator-token spans;
- which comma edges inherit the right-closing overt OR;
- the recomposed term, marked as the certified list semantic operation;
- explicit mixed-operator subtrees as atomic operands, retaining their own tree.

For the earlier-AND subtree case, leave that child visible and show the parent's
list reinterpretation. Alternatively display a normalized n-ary list view **in
addition to**, clearly distinguished from, the binary CCG chart tree. A normalized
view must not be labelled an original application/composition derivation.
Fused lexical reanalysis similarly needs original and replacement categories,
paired input spans, and the discharge point. Reflexive binding should name its
local operator/verb pair and argument identification, not claim a generic
latest-antecedent resolution.

## Honest fallback and first divergence

Retain raw provenance fallback whenever replay fails. Improve its explanation by
reporting the earliest node where legal reconstruction candidates become empty,
or where surviving nodes cannot extend to the root target. Distinguish:

- an unavailable sentence-local lexical certificate;
- a rejected unary/binary lifecycle transition;
- a valid chart operation unsupported by the renderer;
- root semantic mismatch after otherwise complete reconstruction.

These are **replay divergence** diagnoses. They are not the linguistic pipeline's
first divergence against independently authored gold. Print selected term, DRS
and trace unchanged, and explicitly label reconstructed versus authoritative
information. If several internal alternatives fail for different reasons, report
that uncertainty rather than invent one definitive lexical blame. Even before
the shared interface is implemented, list/fused/reflexive trace notes can explain
why raw fallback is expected, but cannot replace a missing derivation certificate.

## Corpus-free acceptance plan

Use small hand-built tag/POS models and the same production parse functions; no
licensed corpus is necessary. Predictions must precede actual test execution.

1. Three clauses with comma + final OR: selected root remains OR across all three;
   replay target equality holds and display labels comma reinterpretation.
2. A comma-only list remains AND; `A or B, C` is not retroactively flattened to
   all-OR by an earlier OR. Explicit mixed `and`/`or` subtrees remain atomic.
3. List state survives licensed right punctuation but not arbitrary application;
   two otherwise-equal candidates with different certificates do not collapse.
4. An ordinary conditional separator does not obtain a new comma conjunction path
   through Explain, including raised modifiers and complete discharged clauses.
5. Fused `everything that` / `someone who` paired alternatives replay through their
   own two applications; wrong source/span/pair, dangling role and unary escape
   are rejected. A source-category-only fallback must not impersonate reanalysis.
6. Local reflexive verb/operator pair replays; composite/nonlocal operands and
   pending-reflexive raising remain rejected. Compare original versus shown local
   binder, not only equality of a simplified root relation.
7. Force a replay mismatch and confirm fallback retains authoritative Pipeline
   term/DRS/claims, prints an explicit explanation failure, and never fabricates
   lexical leaves. Existing ordinary simple-sentence tree behavior remains intact.

For exact-witness retention, additionally create two same-term/same-provenance
lexical alternatives with distinct categories/certificates and verify the chosen
witness survives selection without being replaced by the first compatible replay.
This test distinguishes the stronger claim from ordinary root-compatible replay.
