# Coordination diagnosis — 2026-10-14

Full-access shell/pwd verified in coordination-diagnosis on its own branch.
Own this note and test/CoordinationDiagnosisSpec.hs only. No production edits.

Read sealed root conditional-integration/fresh.observations.jsonl and prior
relatives-coordination proposal. Nested Pronto nominal controls mostly fail before
S; that evidence alone cannot attribute failure to coordination rather than
nominal-copula/quantified-pronoun dependencies. Successful plural controls instead
select a named-subject reading; they do not prove a coordination failure.
Prover nested XOR also lacks he/but lexical meanings. Keep those seams separate.

Prediction before miniature run: plain adjective AND/OR and repeated explicit OR
work; comma-separated AND works; comma-separated OR has wrong-but-typed mixed
AND/OR readings because comma currently supplies conjunction regardless of the
list's overt final operator. Quantified/relative controls isolate the same list
problem without nominal copulas. Hand-written dictionary assigns only licensed
closed/article/copula categories and simple adjective categories; no corpus load.
Command: `runghc -isrc -itest test/CoordinationDiagnosisSpec.hs`.
Expected terms are authored from the stated list interpretation, not parser output.
For three OR alternatives both binary associations are accepted in advance.

First run:4/8 pass; all four predicted comma-OR cases fail with mixed AND/OR,
including under existential and universal-relative scopes. No no-parse in these
controls. Hand-chart provenance proves CoordApply of comma introduces AND at
`S[adj]\NP`, either above an already built OR or below the final OR. Unit3 first
divergence therefore precedes DRS/claims and is independent of nominal copulas.
A temporary source-only provenance renderer confirmed both associations; no corpus.

Before repeat, add two explicit mixed-connective near-neighbors. Prediction:
these pass unchanged, while four list cases remain red. Explicit and/or edges
must never be reinterpreted merely to make the final connective uniform.

## Proposed next general repair: retain comma-list evidence until overt operator

This is a proposal/red-test change only, not source authorization. Existing
`ssCoord` records only the pending token and loses list structure after CoordApply.
Extend that existing coordination state with a bounded, packing-visible list
certificate on same-category constituents. Do not recover lists by pattern-matching
normalized TAnd/TOr: that would confuse lexical meanings, negation/attitude scopes
and overt mixed coordination with punctuation-created lists.

Suggested certificate consists of ordered member signs' terms/provenance, the
category they coordinate at, and coordinator edges with their token provenance
and kind (comma placeholder versus explicit and/or). It is created only by actual
CoordMark/CoordApply rules, never from the words somewhere inside an arbitrary
constituent. Members are atomic unless they themselves carry a compatible same-
category certificate. Include the certificate's canonical terms, edge kinds and
relevant spans in the chart packing key; identical currently evaluated terms with
different unresolved list edges must not erase each other.

Bounded operator resolution:

1. A comma-only chain retains unresolved comma edges. Existing default AND can be
   used for a completed asyndetic reading, but the certificate must survive while
   it is still a coordinate constituent, so this provisional choice is revisable.
2. When that chain meets an explicit final and/or at the same category, resolve
   only its comma-placeholder edges to that operator. For the other binary parse,
   a comma joining A to an explicit B-or-C chain inherits that chain's OR for the
   adjacent comma edge. Both yield three alternatives for A,B,or C.
3. Never relabel an explicit AND/OR edge. Treat an incompatible already explicit
   subtree as an atomic member, preserving its scope. Genuine mixed attachment
   alternatives remain distinct; no global English and/or precedence is assumed.
4. Application, composition and unary changes seal/reset the certificate at their
   boundary; a list nested inside their semantic argument cannot become a sibling
   list by looking through a term. Punctuation absorption may preserve a same-
   category certificate (including the Oxford comma), but does not itself invent
   a coordinate edge. Keep the conditional-boundary guard before any comma edge.
5. Rebuild only the licensed coordinate constituent with existing `coordTerm` at
   its category type. This preserves subject-GQ witness sharing; do not call each
   predicate with the original existential subject separately. Preserve member
   provenance and operator spans so scoped either markers cannot migrate to an
   unrelated OR. Correlative/exclusive marker propagation is not certified by these
   controls and must be separately tested before extending this bounded repair.

This is a small extension to existing coordination evidence, not a general delayed
semantic engine or a sentence-specific template. The proposal intentionally does
not choose between precise certificate encodings before reviewer assessment.
A minimal implementation can normalize homogeneous chains to one deterministic
binary association already licensed by independently authored gold; it must retain
explicit mixed subtrees and their boundaries. No raw lookahead for 'any or later'
and no TAnd→TOr global rewrite are acceptable.

## Learner derivation and independent intended claims

Unit2: red/big/young each `S[adj]\NP`; comma and `or:conj` introduce/consume the
same category's pending coordination. `is` consumes the resulting predicate;
Bob:NP supplies its subject. No predicative article or NP→property bridge occurs,
so nominal-copula failure cannot explain these diagnostic results.

Unit3: each adjective `λQ.Q(λx.P(x))`; the whole OR list is
`λQ.Q(λx.red(x)∨big(x)∨young(x))`. Existential subject `a cat` supplies one x:
`∃x(cat(x)∧(red(x)∨big(x)∨young(x)))`. This differs from both measured mixed
connective readings and from independently quantifying each alternative.

Unit4, named list: Asserted contains only OR; Embedded has the inner OR (for the
chosen association) and three adjective atoms. Existential list additionally has
root cat(x) Asserted and a shared root x; no individual disjunct is asserted.
Relative universal: `[ | [x | cat(x), OR(red(x),big(x),young(x))] => [ | kind(x)]]`.
Only implication Asserted; inner ORs and all classifier atoms Embedded. Reported/
Presupposed remain empty. Nesting/claim multiplicity and marker paths must match
one independently admitted OR association, not a flattened set of labels.

The current fixture module checks λ-meanings for precise first-divergence isolation;
future production acceptance must additionally use independent DRS/claim gold.
The sealed `pronto-ground-or-2` already has an actual nominal comma-OR input but is
no-parse in the frozen cache. Its eventual recovery is a joint nominal/list claim
that cannot be inferred from these adjective controls.

## Frequency, comparison and review boundary

Pronto inventory records47,862 relative-restriction OR occurrences and17,932
predicate OR; comma-list cues occur28,166 times in restrictions and25,430 in
predicates. These overlap and are not a measured comma-OR intersection or expected
repair count. This prioritizes checking the construction; it does not certify
population coverage or satisfy the closed ProverQA launch gate.

Follow [Bos2008](https://aclanthology.org/W08-2222/) separation of syntax-driven
construction, scoped DRS and subsequent resolution: adopt category/provenance
licensed list formation, adapt representation to existing non-event predicates,
reject coverage as meaning gold. The pinned [ccg2lambda English templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml)
have category/rule/lexical-token-specific coordination matching; adopt that
structural discrimination, not every table's connective choice (the audited
sentence-or entry uses conjunction). Existing `coordTerm` already correctly scopes
GQ arguments and should remain the semantic combinator. Both systems' reported
coverage is insufficient to validate a new list-provenance certificate.

Reviewer should approve a concrete minimal certificate and boundary controls
before implementation. Preserve ordinary comma coordination of completed sentences,
conditional delimiters, explicit mixed groups, reporting/negation barriers and
scoped markers. Root owns shared source, current nominal trials and integration.

Final diagnostic run:6/10 pass, four intended red comma-OR failures. Both explicit
mixed-edge controls pass. No production, parser binary, gold fixture or cabal file
changed; no corpus load/model/answer benchmark. `git diff --check` is clean.
