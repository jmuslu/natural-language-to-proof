# Names, common nouns, and N→NP: learner-facing design review

The accepted repair supplies a rigid meaning for **names licensed by the existing POS/casing policy**
whose offered category is N, NP or NP[nb]. It does not recognize every benchmark
name. In particular, initial `Legend` remains a wrong-but-typed failure under the
observed default corpus policy. Preserve its intended rigid gold; a universal
reading is not an acceptable substitute. This proposal adds no source changes.

## Unit 2: a category is a composition contract, not identity evidence

For `Iris is red`, use these CCGbank-style lexical categories:

```
Iris              is                         red
NP                (S[dcl]\NP)/(S[adj]\NP)   S[adj]\NP
                  ------------------------------- >
                  S[dcl]\NP
------------------------------------------------- <
S[dcl]
```

The backward slash marks an argument to the left. Final punctuation preserves
the sentence category and meaning. Forward application combines the copula with
its adjective predicate; backward application supplies the subject.

CCGbank may instead offer N for a name and use a unary N→NP step. That syntactic
shape is shared with bare common nouns; it does **not** determine a common meaning.
Compare three cases:

| Evidence and category | Chosen meaning operation | What it does not license |
|---|---|---|
| Name evidence; offered N | Lexically supply rigid NP | Generic predicate `iris(x)` |
| Name evidence; offered NP or NP[nb] | Keep category and score; supply rigid NP meaning | Dropping an already-NP token |
| Common noun N with bare N→NP | Current explicit generic stipulation | A rigid constant for every capitalized noun |

Expletive NP[expl], dummy-there NP[thr] and pending-conjunction NP[conj] are not
ordinary name NPs. The repair rejects those candidates rather than erasing their
features. NP[nb] is the accepted non-bare feature; the code accepts plain NP or
NP whose listed features are all `nb`.

## Unit 3: same final type, different truth conditions

In the local extensional notation let `P = e→t` and `Q = P→t`. The wider pipeline
retains its existing intensional machinery; this illustration does not change it.

- `Iris : Q = λK.K(Iris)`, using a rigid entity constant.
- `red : Q→t = λN.N(λx.red(x))`.
- Adjectival `is : (Q→t)→(Q→t) = λV.V`.

Composition normalizes to `red(Iris)`. The proper-name meaning is `nameItem`;
licensed N→NP supplies that same meaning before ordinary composition. For a
common noun `cat : P = λx.cat(x)`, current `unarySem` instead produces
`λK.∀x(cat(x)→K(x)) : Q`. Applied to red it yields
`∀x(cat(x)→red(x))`. Both meanings type-check, but they make different claims.
That is why successful typing is insufficient to certify a name repair.

Bare plural subjects can support a generic reading; bare plural objects can have
other readings. The current universal N→NP choice is a recorded stipulation,
not a general theory of English bare nouns. It must not silently justify
`Abdullah explores cultures` as universal quantification over all cultures.

## Unit 4: rigid identity, DRS scope, and claims

| Input/operation | Intended DRS | Claim status |
|---|---|---|
| `Iris is red.` | `[ | red(Iris)]` | Only `red(Iris)` Asserted |
| `Iris likes Iris.` | `[ | like(Iris,Iris)]` | One Asserted atom with the same constant twice |
| Negated red VP | `[ | ¬[ | red(Iris)]]` | Whole negation Asserted; atom Embedded |
| Generic `Cats are red.` under the current stipulation | `[ | [x | cat(x)] ⇒ [ | red(x)]]` | Whole implication Asserted; its conditions Embedded |

These controls have no Reported or Presupposed claims. “Asserted” means eligible
as an unconfirmed top-level claim, never oracle-confirmed merely because a name
was recognized. Rigid constants also do not create an existential discourse
referent by themselves; cross-sentence anaphora is a separate binding problem.

## Current Explain evidence: locate the first divergence

The recorded default-corpus batch in [NAMES](../NAMES.md) predates the bounded
repair and isolates failures that the repair does not claim to solve. This review
reuses those cached observations, rather than claiming a fresh corpus run.

| Example | Cached behavior / first divergence | Required interpretation |
|---|---|---|
| `Legend is red.` | Initial truecasing sees common noun; N gets `legend(x)`, then generic N→NP | Rigid benchmark entity; divergence begins at lexical selection |
| `If Legend is red then Legend is big.` | Noninitial casing permits rigid Legend | Entire implication Asserted; its atoms Embedded |
| `Brecken is red.` | Rigid reading available alongside a generic alternative | Availability is not disambiguation or all-reading fidelity |
| `Abdullah explores cultures.` | Subject can be rigid; bare object is universalized | Separate object-NP problem; do not credit full sentence fidelity |
| `Legend wakes up.` | Name and particle/VP analyses both diverge | Separate construction gold is required |
| `White things are cold.` / `Cats are red.` | Capitalization is typography | Preserve ordinary adjective/noun meanings |

The actual repaired defect is narrower than Legend: previously, a licensed name
already offered as NP could lose its meaning because only offered N received
`nameItem`. Hand-built POS/category dictionaries isolate that defect independently
of whichever CCGbank tag a particular benchmark entity receives.

## General rule and independent implementation review

`nameStatus` consults majority POS after initial truecasing. Attested NNP/NNPS
licenses NameOnly; other attested POS gives NotName. An unseen initial capital
receives NameOrOther; unseen noninitial capitals receive NameOnly under the
existing heuristic. These last cases are casing policies, not verified identity.

`lexicalSigns` then supplies the name meaning only for licensed N/ordinary NP.
It preserves offered score and NP[nb]. NameOrOther also retains actual open-class
lexical candidates. The trace lists those candidates, rather than invented
common-noun alternatives for NameOnly. A lexical alternative need not survive
into a complete sentence reading, so the two counts must remain distinct.

This source inspection supports the bounded repair and its trace correction.
It does not support changing truecasing wholesale, adding benchmark entity lists,
or claiming that every rigid reading is selected correctly.

## Boxer 2008 and ccg2lambda: adopt, adapt, reject

**Adopt:** Bos 2008 §3.2 separates category/type constraints from POS- and
word-sensitive lexical meaning. This supports using name evidence alongside N/NP,
not interpreting categories as identity labels. Its construction/resolution
separation also argues against smuggling anaphora or claim confirmation into
lexical name selection. See the primary-source map in [REFERENCES](../REFERENCES.md).

**Adapt:** the pinned ccg2lambda 2015 English templates, lines 37–46, condition a
proper-name N→NP rule on NNP. Their NP term has two predicate continuations and
an equality-bound existential witness. Our NP has one continuation and uses a
rigid constant. Retain the evidence-sensitive distinction while translating the
meaning into the local type and DRS contract; their full term is not a drop-in
replacement. [Pinned template](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L37-L46).

**Reject for this patch:** copying upstream NP representation wholesale, treating
all N→NP as rigid names, and adding existential witnesses merely to mimic an
external output format. No upstream execution or claim-status guarantee is
inferred from reading those sources.

## Independent gold and scoring boundary

The benchmark gold fixes identity before examining parser output. In
[test/fidelity/proverqa.jsonl](../../../test/fidelity/proverqa.jsonl),
`prover-subject_copula-1` (`Cruz is wise.`) requires `[ | wise(Cruz)]` and
`prover-subject_copula-2` (`Ali is gentle.`) requires `[ | gentle(Ali)]`.
Each has one Asserted atom and no Embedded, Reported or Presupposed conditions.
These are two independent meaning controls for named copular predication;
the dictionary-driven Iris tests separately isolate category availability.

`prover-vp_either_or-1` requires the **same rigid Legend** in both alternatives
of `Legend is either a champion or fast.` The disjunction's reading policy and
claim boundary belong to the operator proposal; the name rule may not replace
Legend by a universally quantified common noun to make that control pass.
The full DRS, claim groups and disjunction metadata must agree with gold.

Score a well-typed generic replacement as **wrong-but-typed**, an empty accepted
parse set as **no-parse**, and a complete match under the fidelity scorer's
selected-reading contract as **exact**. Merely returning one rigid alternative
among other readings is not evidence that the selected reading is exact.
These are acceptance criteria, not new measured corpus results. The 30 focused
checks below are unit regressions; they do not establish a ProverQA exact rate or
release the 90% construction-fidelity gate.

## Acceptance evidence and remaining proposal

Existing NameSemSpec has 30 controls covering direct NP/NP[nb]/NNPS, N lifting,
subject/object/repeated-name composition, rigid DRS, negation scope, category
scores, trace alternatives, ordinary capitals, homographs and excluded features.
The original history records 15/26 before semantic repair and 26/26 after; the
trace controls then yielded 28/30 before correction and 30/30 after. This review
independently reruns only the final focused suite; see [notes](../../notes/design-names.md).
No extra mirrored test file is needed.

A future document-local name license could use independently observed noninitial
NP evidence, while retaining its origin and ambiguity. It must not use labels,
answer formulas, benchmark name lists, or circularly reinforce its own guess.
It must not move referents or facts out of negated, conditional or attitude boxes.
Test titled names, common-word homographs, quoted names, multiple same-spelling
entities and capitalized adjectives first. With only ambiguous initial occurrences,
there may be no independent evidence: honest abstention remains preferable to
claiming a solved name. This future rule is not implemented or fidelity-validated.
