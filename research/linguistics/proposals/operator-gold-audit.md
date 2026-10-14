# Operator inventory → gold audit, with contract boundaries

Snapshot2d1cae6 plus separately frozen Everyone gold/candidate0475ad8/ecd75dd.
This is coverage accounting, not a scored fidelity or population estimate. All
four inventory sections and committed test/fidelity JSONL rows were inspected;
no datasets, parser models or answer benchmarks were loaded. The later NP-only
trial report belongs to the coordinator; it did not supply any new gold here.

## What “2–3 examples” does and does not mean

Count different sentence texts within a semantic construction and contract.
Repeated IDs, reordered predicates from one authored scenario, or two different
operator subtypes hidden under one label do not establish independent source
coverage. An authored adversarial control can certify a regression obligation,
but cannot fill an attested-source quota for ProverQA/FOLIO/etc. Inventory cues
are presence counts with overlap, not a semantic-family denominator.

Sources: [ProverQA](../sections/proverqa.md),
[ProntoQA](../sections/prontoqa.md), [ProofWriter](../sections/proofwriter.md),
[FOLIO](../sections/folio.md). Gold links below point to current source-controlled
fixtures; their `origin.adaptation` and per-case notes matter as much as labels.

## ProverQA: pairs exist for narrow scopes; high-frequency joint gaps remain

Inventory17,345 occurrences/17,285 surfaces. Initial-if5279; explicit not-both4146
(in initial-if2836); or-both776 (inside-if302); not-necessarily-both145; mutually
exclusive57. Either without recognized explicit exclusion1468 is a lexical audit
bucket, not proof every sentence has the same interpretation. Counts overlap.

| Semantic slice | Existing independent text coverage | Remaining obligation |
|---|---|---|
| Ground either predicate | vp_either_or-1/2:2 | One mixed nominal/adjective, one adjective pair; not2of each subtype |
| Ground fronted either + explicit exclusion | sentence_either_or-1/2:2 | Named predicates; does not test ordinary inclusive fronted either |
| Conditional consequent explicit XOR | nested-xor-1/2:2 | Both named subjects; quantified/indefinite binder + XOR still needs2–3 |
| Conditional consequent inclusive either | nested-or-1/2:2 | One named, one adapted person+nominal antecedent; subtype counts thin |
| Conditional overt or-both | overt-or-both-1/2:2 | Controlled contract version explicit; no modal hedge inference |
| Conditional AND antecedent | nested-and-1/2:2 | One adjectival, one nominal/mixed; OR-adapted contrasts are not original OR frequency evidence |
| Conditional OR antecedent | nested-ante-or-1/2:2 | Explicitly adapted from AND inputs; not2attested original OR examples |
| Initial/final conditional binding | initial-1/2, nested-binding-1/2, final-1/2 | Cat sentence appears twice across labels; two IDs are one text; named and indefinite binders separate |
| Topical universal XOR | for_topic-1/2:2 | Explicit human restriction; property reading of born/unborn is declared; not unrestricted temporal/event evidence |
| Strict Everyone connective | person-pronoun-1/2:2 aggregate | Only1inclusive-or-both and1XOR: each subtype fails2minimum |
| Legacy Everyone OR | quantified_pronoun_or_relative-1/2:2 | Empty restriction convention; not interchangeable with strict-person gold |
| Modal not-necessarily-both / mutually-exclusive paraphrase | 0 agreed gold families | Preserve unresolved status; never coerce hedge to literal NOT-both |
| Nested independent either/OR marker attachment | 0 existing JSONL cases | New authored controls below are diagnostics, not source-population coverage |

See [base](../../../test/fidelity/proverqa.jsonl),
[nested](../../../test/fidelity/proverqa-nested.jsonl),
[strict person](../../../test/fidelity/proverqa-person-pronouns.jsonl),
[relatives](../../../test/fidelity/proverqa-relatives.jsonl). Existing standalone
Everyone six-case gold separately supplies person+relative/negative scope, not new
XOR examples. No permissive but conjunction repair is implied: the prior but plan
was deferred after an external-not bracketing counterexample.

## ProntoQA: location matters more than a single coordination label

Inventory819,128 occurrences/177,560 surfaces. Predicate AND149,937; relative
restriction AND128,988; restriction OR47,862; predicate negation47,529; predicate
OR17,932; sentence AND5516. Internal commas54,022 (restriction28,166,
predicate25,430,sentence798); mixed AND/OR somewhere862. These are overlapping
presence counts. No sentence-level OR, explicit existential or attitude complement
was observed in this acquisition's anchored surface families.

| Semantic slice | Existing text count | Audit |
|---|---:|---|
| Ground predicate AND | 2 | Nominal predicates, not2per lexical subtype |
| Universal predicate AND | 3 | Includes Gorpuses repeated in nested-plural-and-1; count text once globally |
| Ground predicate OR | 3 | Only1comma-OR list, not2–3comma cases |
| Restriction AND / OR | 2 / 2 | Binary mixed noun/adjective controls; insufficient comma-list restriction coverage |
| Relative OR restriction + AND consequence | 3 | Two operator positions independently represented |
| Relative AND restriction + AND consequence | 3 | Does not certify arbitrary mixed operator precedence |
| Relative negative consequence | 4 |2OR restrictions,2AND restrictions across files; check subtypes separately |
| Bare-plural coordinated consequence | 3 | Controlled generic reading, not global English bare-plural semantics |
| Sentence AND distinct subjects | 3 | Full clauses, not shared-subject VP evidence |
| Sentence comma-AND with negative final clause | 3 | Full clauses; no implied comma-OR coverage |

[Base](../../../test/fidelity/prontoqa.jsonl),
[nested](../../../test/fidelity/prontoqa-nested.jsonl),
[clause lists](../../../test/fidelity/prontoqa-coordination.jsonl).
Priority gaps:2–3original restriction comma-OR sentences,2–3predicate comma-OR
sentences beyond the current singleton, and explicit mixed-edge grouping controls.
Do not pretend the three nested OR→AND examples prove all862mixed-cue sentences.
Controlled nominal predication, unrestricted Everything and generic plurals are
explicit benchmark language contracts; importing a ProverQA answer policy to make
or exclusive would be an error.

## ProofWriter: controlled fragment coverage is not NatLang coverage

All110files inventory13,247,543 occurrences/172,834 surfaces. Generic conditional
1,001,985; generic conjunctive antecedent915,052; ground conditional367,824;
ground conjunctive antecedent321,762. Copular negation829,487; transitive
negation372,811. NatLang coordination bucket91,240; overlapping coordination-other
cue45,348, attribution32,684, causal23,910. Neither bucket is a separate count
of inclusive OR, exceptive but or literal XOR.

| Semantic slice | Existing text count | Audit |
|---|---:|---|
| Ground positive/negative copular and transitive atoms | 2 per subtype | Controlled canonical forms, not paraphrase semantics |
| Ground if / conjunctive antecedent | 2 / 2 | Includes explicit negative predicate, but only narrow binder patterns |
| Generic something if / conjunctive antecedent | 2 / 2 | Historical unrestricted-something convention; not strict-English sortal certification |
| Strict someone/they conditional | 3 | person restriction retained; positive/negative and conjunction variation |
| Strict relational binding conditional | 3 | Co-reference and argument order, not arbitrary existential scope |
| Bare/explicit adjective people/things universals | 2 / 2 | Genuine sortal restriction versus dataset convention must remain visible |
| NatLang OR/but/yet/causal/attribution operator families | 0 complete2–3-per-family coverage | Do not assign hidden controlled-fact meaning to the presented paraphrase |

[Controlled gold](../../../test/fidelity/proofwriter.jsonl),
[strict binding](../../../test/fidelity/proofwriter-binding.jsonl).
OWA/CWA answer policy does not change explicit not into failure-to-prove, nor
license dropping report/causal/modal operators. Existing generic something gold
intentionally has no thing predicate; strict someone gold has person. Preserve
both contracts as they stand rather than “repairing” gold to the current parser.

## FOLIO sample: most operator families remain uncovered

Sample744 occurrences/439 surfaces, not the whole release. Conditional initial
114 (65unique), final17 (8unique); VP either19 (13unique), initial either4
(2unique), VP neither/nor10 (7unique); biconditional outer bucket3 (1unique), cue4
(2unique). OR cue72 (40unique), AND85 (49unique), negation159 (100unique).

| Semantic slice | Existing text count | Audit |
|---|---:|---|
| Ordinary ground OR | 2 | Same authored Yuri/tall/American pair with order reversed; one scenario, zero verbatim OR source assertions |
| Negative existential some | 2 | Definite shared-witness scope, explicit adaptation notes |
| No quantifier | 2 | Fixed negated-existential representation, not any equivalent implication |
| Conditional indefinite object anaphora | 2 | Bind antecedent witness into object; includes negative consequent |
| Mixed lexical/copular VP AND | 2 | Only1negative-left example, not ambiguity-exhaustive scope certification |
| Negative relative restrictions | 3 | All/Some/No each1; aggregate3does not give2per quantifier type |
| Either, neither/nor, biconditional, only-if/unless joint scopes | 0complete source-derived2–3-per-family coverage | Sample cues demand inspection, not forced Boolean flattening |

[Base](../../../test/fidelity/folio.jsonl),
[extended](../../../test/fidelity/folio-extended.jsonl),
[mixed](../../../test/fidelity/folio-mixed.jsonl).
The FOLIO OR pair is useful as an order/claim regression, not a representative
source pair. Source-adapted provenance may explicitly mean authored vocabulary
reuse; origin.benchmark alone does not certify an original source sentence.

## Contract boundary corrections needed in shared documentation

These are findings for coordinator integration; no shared file was edited.

1. fidelity/README currently says inclusive disjunction requires either=false.
   Existing Prover VP/nested inclusive gold correctly uses canonical inclusive OR
   **and either=true** to retain the written marker. Proposed wording: “Plain OR
   without a written either marker requires either=false; written either is a
   surface annotation and does not itself add exclusion. Literal not-both must
   appear in DRS semantics.” Preserve current gold; do not change it to fit the
   overbroad README sentence.
2. Pronto inventory's phrase “ProverQA's exclusive either...or policy” must be
   qualified as a benchmark convention where explicitly selected, not universal
   English meaning or the current strict-surface gold policy. Both systems'
   presented English requires retaining explicit exclusion and hedge wording.
3. scope_ambiguous is not permission to drop an OR marker. Current exporter uses
   shared full-sentence fallback provenance, so several ORs with either can be
   marked ambiguous. This is an implementation limitation, not proof the English
   sentence has ambiguous marker attachment. New authored targets below require
   local attachment; no producer result was used to set their flags.
4. Missing semantics_contract metadata means “read row/README conventions,” not
   automatically unrestricted, strict-English, or benchmark-exclusive. Do not
   pool all legacy rows into one semantic population. Keep immutable historical
   panel membership and report any new strict contract separately.

## New independent diagnostics:7authored, not population examples

[operator-gap-controls.jsonl](../../../test/fidelity/operator-gap-controls.jsonl)
uses contract operator-surface-scope-v1:

-2explicit full-property not-both controls: ¬(P∧Q), **no OR**. These admit neither
 predicate and expose an implementation that confuses exclusion alone with XOR.
 Both properties are overt; they do not solve the short elliptical tail but not both.
-2neither/nor controls: two asserted NOT boxes, each positive atom Embedded.
 The fixed structural encoding is independently chosen; logically equivalent
 NOT-OR is not silently accepted. They address a missing Boolean construction,
 but do not fill the7unique FOLIO source examples' attestation quota.
-3conditional OR-marker controls: either in both clauses, only antecedent, only
 consequent. DRS asserts one implication; both ORs and their branches are Embedded.
 Each OR remains inclusive; clause-local marker flags differ by written occurrence.
 There is no anaphora, quantifier import, XOR, or modal inference in these controls.

No gold supplied for not-necessarily-both, exceptive but, corrective not-X-but-Y,
modal/frequency operators, until their contract is settled. Their omission remains
a gap, not a parse failure silently excluded from the acceptance denominator.

For Units2/3/4, category coordination must preserve the two original conjuncts,
Montague meaning determines AND/OR/NOT/implication scope, and DRS claims distinguish
asserted whole operators from embedded branch content. The locally audited
Boxer2008 composition/resolution split and ccg2lambda2015 per-category templates
support that workflow, not copying their coverage numbers or sentence-or-as-AND
entry. See [references](../REFERENCES.md) and [comparison](../TEMPLATE_COMPARISON.md).

Validation: all7new rows pass schema/scope checks and exact OR-path enumeration;
all texts are new relative to committed gold. No parser run or fidelity score.
Review before admitting these rows to any future source trial; keep them a separate
authored diagnostic panel, never a ProverQA population denominator.
