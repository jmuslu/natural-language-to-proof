# Next two fidelity repairs after quantifiers and nominal copulas

Proposal only, 2026-10-14. No implementation approval or new parser run. Source:
sealed `research/runs/integration-fidelity/initial-default.json` and its
observations JSONL; executable SHA256
`5b3f5e9fe4fbe58928bd6d43facc8657cf344c80a55fd06afc8b79f27dc7f035`.
The initial85 snapshot scores21 exact /24 wrong-but-typed /40 no-parse; it is a
historical diagnostic, not current-head or dataset-wide fidelity. The input-only
residual inventory was committed independently before this parser-output review.

Use `p=e→t`, `q=p→t`, `lift(a)=λP.P(a)`. Examples below are new authored acceptance
proposals, not measured tests and not additions to independent benchmark gold.
No subsective/adjective-intersection repair is proposed.

## 1. Preserve conditional scope across the separator comma

Why first: initial-if sentences account for5,279 ProverQA occurrences, including
5,160 with personal-pronoun cues and2,836 with `not both`. These overlapping cues
are not numbers fixed by this proposal. They establish priority for conditional
structure. The frozen case `prover-conditional_initial-1` is a concrete violation:

```
If a cat is nimble, then it is agile.
selected lambda: ((exists x.cat(x) & nimble(x)) -> agile(?it_7)) & agile(?it_7)
alternative:      (exists x.cat(x) & nimble(x)) -> agile(?it_7)
```

The selected DRS correctly resolves the consequent's conditional-local anaphor,
but also contains a top-level `agile(?it_7)` with an unresolved anaphor. Its claim
table asserts that extra atom. The first divergence is **already in the selected
lambda**, before DRT anaphora resolution or claim extraction. Fixing pronouns or
filtering claims would conceal the underlying unwanted conjunction. This is
invariant3's input being wrong, not evidence that the main-box classifier broke.

Derivation intended in Unit2:

| Constituent | Category | Typed meaning |
|---|---|---|
| if | `(S/S)/S[dcl]` | `λA B.A→B : t→t→t` |
| antecedent clause A | `S[dcl]` | `A:t` |
| if A | `S/S` | `λB.A→B : t→t` |
| then | `S/S` | `λB.B : t→t` |
| consequent clause B | `S[dcl]` | `B:t` |
| then B | `S` (feature-compatible) | `B:t` |
| if A, then B | `S` | `A→B:t` |

The comma absorbs as a boundary punctuation item; it must not conjoin the two
unsaturated operators `if A:S/S` and `then:S/S`. Generalized pointwise conjunction
of those operators gives `λB.(A→B)∧B`, exactly the bad selected term. Existing
`coordinatorOp "," = and` plus unrestricted functor coordination makes this a
specific derivational hypothesis. The sealed fidelity cache stores lambda choices,
not full lexical derivation trees, so it establishes the semantic divergence but
**does not by itself prove that precise chart path**. Confirm that path with a
reviewer-approved focused Explain test before production integration.

Proposed general repair: distinguish a comma licensed as a **conditional boundary**
from a comma licensed as a **list coordinator**. Carry construction evidence from
the conditional-introducer lexical provenance and category into coordination
eligibility; reject the path that combines an open conditional with its consequent
marker as two coordinate propositions/functions. Keep ordinary punctuation
absorption and the existing conditional application path. This is not a global
ban on `S/S` coordination or a surface rule deleting commas. Nested conditionals
must retain their own introducer/boundary associations. A typed term alone cannot
supply that syntactic association.

Unit4 expected DRS for the cached donkey sentence:
`[ | [x | cat(x),nimble(x)] ⇒ [ | agile(x)]]`.
Only the implication is Asserted; cat/nimble/agile are Embedded. No extra root atom,
no unbound anaphor, and no Reported/Presupposed claims. Scope-dependent anaphora
remains DRT's responsibility after the syntax repair.

Three independently specified acceptance controls:

1. `If Mira is calm, then Mira is patient.` Expected
   `[ | [ | calm(Mira)] ⇒ [ | patient(Mira)]]`; no top-level patient claim.
   Compare comma-free form for the same meaning, and inspect **all** readings.
2. `If a dog is quiet, then it is alert.` Expected
   `[ | [x | dog(x),quiet(x)] ⇒ [ | alert(x)]]`; bind the one antecedent witness
   only inside the implication. No root `alert` atom, even with an unresolved name.
3. `If Mira is calm, then Mira is patient and kind.` Expected one implication
   whose consequent contains patient and kind; list/conjunction still works in
   the consequent and neither conjunct becomes independently Asserted.

Do not claim this solves `he/she` lexical availability, multi-clause conditional
anaphora, final-if, or XOR: the second initial-if gold case has no parse, and this
snapshot cannot identify its missing lexical stage. Those need separate review.

## 2. Normalize lexical predicate identity using POS and category evidence

Why next: short-subject have contributes632 Prover occurrences; the residual
3,791 includes varied lexical predicates, not one intransitive family. The refined
audit independently recovered249 narrow surface instances and left3,542 unresolved.
Lexical-key consistency is a prerequisite for faithful comparisons across
inflections; **none of those counts estimates recoverable exact cases**.

Frozen `prover-subject_have-1/2` produce `ha(Avah,x)` and `ha(Emily,x)` alongside
`degree(x)`, where independently authored gold requires `have`. Source inspection
identifies the cause: `verbLemma` lacks have/has and fallback `lemma3sg` strips s.
Frozen `prover-universal_nominal-2` retains `frogs` while gold uses `frog`; N's
open template currently preserves raw lowercase spelling. This is lexical symbol
identity at Unit3, before DRS construction, not a quantifier or noun-phrase-type
repair.

Proposed general design: a small deterministic, **POS/category-licensed lemma
interface**, shared by lexical predicate construction and attitude-attestation
keys. Retain lexical features needed for tense/aspect/number; do not use the lemma
to erase them. Existing representation already abstracts much tense/number; these
repairs must not pretend that abstraction establishes full English fidelity.

| Licensed input | Category | Meaning after normalization |
|---|---|---|
| possessive `has` with verbal evidence | `(S[dcl]\NP)/NP` | `λO Q.Q(λx.O(λy.have(x,y))) : q→q→t` |
| `have` after do-support | `(S[b]\NP)/NP` | same lexical relation, different syntactic feature |
| plural common `cats` with NNS evidence | `N` | `λx.cat(x) : p` |
| proper-name spelling | `NP` (or licensed name N→NP repair) | `λP.P(Name) : q`, preserving the name constant |

Names and adjectives must never pass
through a noun/verb suffix stripper merely because their spelling ends in s.
For has, add a reviewed irregular verbal mapping rather than a generic
three-letter `-s` exception. For plural nouns, use licensed morphology/POS and
explicit irregular exceptions, retaining ambiguous or unknown forms unchanged
with a decision rather than inventing stems. Singular `news`, `species`, `series`
and `glass`, names such as `James`, and verb/adjective homographs are essential
counterexamples to a universal remove-s rule. Ambiguous status may require
multiple explicitly labelled readings; a POS majority is evidence, not truth.

Unit2 derivation for `Mira has a kite`: `a:NP[nb]/N` applies to `kite:N`, then
`has:(S[dcl]\NP)/NP` applies to the object and the result to Mira. Unit4 result
`[x | kite(x),have(Mira,x)]`, with both conditions Asserted. The auxiliary use
`has left` has a different category and cannot be assigned possessive have.

Three independently specified acceptance controls:

1. `Mira has a kite.` Expect the DRS above; `ha` must not occur in any reading.
   The identical relation should occur in the do-support control
   `Mira does not have a kite`, inside a negated existential box, not Asserted.
2. `All cats are quiet.` Expect `[ | [x | cat(x)] ⇒ [ | quiet(x)]]` under the
   reviewed universal interface. The stem is cat, while number evidence remains
   available; no separate cat-existence assertion is introduced.
3. `James has a glass.` Expect `[x | glass(x),have(James,x)]`, preserving both
   `James` and singular `glass`; never `Jame`, `glas` or `ha`. This tests the
   lexical namespace/POS boundary, not merely two hand-added success mappings.

The cached `An alchemist excels` retains `excels`, despite the verbal fallback
being able to remove final s. It may involve a competing category, since the
adjectival branch deliberately preserves its surface. The cache does not contain
its leaf derivation, so **do not advertise lemma normalization as its proven fix**.
Likewise N/N nominal compounds, mass-noun force, verb+PP valency, particles,
light verbs and adverbs remain outside this repair. Refined residual families
such as `values tradition` cannot be made faithful by collapsing them into
sentence-specific unary predicate names.

## External comparison and acceptance

[Bos2008 §§2–3](https://aclanthology.org/W08-2222.pdf) separates syntax-driven
semantic construction from anaphora resolution and uses lexical/POS/morphological
information. Adopt those separations: fix the conditional's composition before
resolution, and normalize lexical identity with lexical evidence. Adapt its
neo-Davidsonian event/role representation only through a declared representation
change; no such change is proposed here. Reject citing broad coverage as evidence
that these rules are exact.

The pinned [ccg2lambda 2015 templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml)
assign implication to `if` in their Connectives section, while their comma rules
are category-sensitive. Adopt explicit connective meanings and category-sensitive
punctuation licensing, not indiscriminate comma-conjunction. Its two-slot NP
interface ([Mineshima et al.2015 §2/Fig3](https://aclanthology.org/D15-1244.pdf))
requires translating types coherently; these one-slot q terms are not copied YAML.
The pinned [semantic selection implementation](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/scripts/semantic_index.py#L38-L98)
uses lexical base information. Adopt base-vs-surface separation without assuming
that upstream morphology or templates are correct for every form. Current
REFERENCES.md and TEMPLATE_COMPARISON.md document these source inspections; no
upstream executable was run for this proposal.

Reviewer sequence: independently approve expectations and structural licensing;
add red tests; inspect the exact derivation where currently unobserved; implement
one general repair at a time; score exact/wrong-but-typed/no-parse and contamination
by wrong alternatives; run all gates before coordinator integration/push. Preserve
no-parse for unanalysed constructions rather than expanding a permissive lexical
fallback. These two fixes are priorities, not substitutes for the residual-frame
and independent-gold obligations or permission to reopen model benchmarks.


## Bounded has→have implementation request

Broad noun morphology above remains a design proposal and is **deferred** pending
separate rule review. The immediately testable repair is just the missing reviewed
present-tense irregular: add `("have", ["has"])` to `verbLemma`'s existing
`inflections` table in CCGSem.hs. Do not modify `lemma3sg`, nouns, adjectives,
name handling or category selection. This lexical-key repair is shared with
`reportingLemma` exactly as existing irregular verbs already are.

```diff
         , ("go", ["goes", "went", "gone"]), ("do", ["does", "did", "done"])
+        , ("have", ["has"])
```

The actual semantic API receives word and category, not POS. Category-based
`predName` calls `verbLemma` for verbal templates and preserves adjective forms;
N and proper-name paths do not call it. POS evidence belongs upstream in lexical
category/name selection. Consequently this tiny change is **category-gated at its
meaning call sites**, not a new POS disambiguator or guarantee that every offered
verbal category is correct. Tests include real singular-s nouns, a proper name,
and synthetic has-as-N/has-as-adjective controls to expose accidental global
normalization. The synthetic controls are API boundary tests, not English analyses.

`test/HasLemmaProposalSpec.hs` is standalone test-first evidence, with no corpus
loads. Its existential example checks composition with the actual closed
`a:NP[nb]/N`, while the auxiliary-category control ensures no possessive-transitive
meaning is invented for a perfect auxiliary. Preservation of absence is not a
claim to have implemented perfect aspect. The coordinator owns production edit,
reviewed test-suite registration, full fidelity and release gates.
