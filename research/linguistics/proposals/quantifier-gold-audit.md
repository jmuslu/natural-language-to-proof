# Quantifier gold: four-inventory audit against frozen173

Audit reads input inventory aggregates and independent gold only, with no parser
observation or source/model execution. Snapshot: coordinator
`research/runs/expanded173-baseline/cases.jsonl`,173 rows, SHA256
`327dd14c96bb4e2c375f4f9f46025de28dfc7fca9b9e149c85f986345d1d1f3a`.
This ignored file includes six everyone controls queued beyond this branch's
accepted research2d1cae6. Membership is frozen explicitly rather than assumed from
the branch's file listing. No result status is used to choose examples.

## What two-per-label actually establishes

| Gold construction or meaningful split | Frozen membership | Requirement assessment |
|---|---|---|
| Pronto every / each | pronto-every-1/2; pronto-each-1/2 | Two per lexical determiner. Each has one adjective and one nominal complement; not two per complement subtype. Every has one nominal and one negative adjective. |
| Pronto bare plural | pronto-bare-1/2/3 | Three, spanning nominal/adjective/negative; two per subtype not established. |
| ProofWriter all with modified restriction | pw-universal-explicit-1/2 | Two, one negated consequent. Distinct person/thing heads expose domain and modifier order. |
| ProofWriter bare plural | pw-universal-bare-1/2 | Two, one versus two modifiers; no independent negative matrix pair. |
| FOLIO all nominal classification | folio-extended-universal-1/2/3 | Three; class inclusion with no existential import. |
| FOLIO some / some-not / no | folio-some-2/3; folio-some-not-1/2; folio-no-1/2 | Two for each force/scope contract. Label no_universal is historical: gold is negated existential, not universal-negative serialization. |
| Prover a/an subject | prover-existential_nominal-1/2 | Two lexical indefinite intransitives; not generic indefinite rules. |
| FOLIO at least one | folio-atleast-one-1/2 | Two surfaces differing only John/Mary; narrow one-child relational existential control, no cardinal comparative generalization. |
| Something conditional | pw-cond-generic-1/2; pw-cond-generic-coord-1/2 | Two per simple/conjoined rule shape, unrestricted antecedent binder; no standalone existential import. |
| Someone conditional | pw-binding-someone-1/2/3; pw-binding-relation-1/2/3 | Three per broad family, strict person, relational binding separately represented. |
| Standalone someone | prover-person-pronoun-3/4 | Two total, one positive and one negative. Each polarity still lacks a second independent sentence. |
| Standalone strict everyone | authored-everyone-closed-1/2/3, plus prover-person-pronoun-1/2 connective rows | Three atomic controls (two positive, one negative); two connective cases differ inclusive/exclusive scope. No two-per-connective-type claim. |
| Strict everyone who | prover-who-restriction-1/2 plus authored-everyone-closed-4/5/6 | Five; only one negative restrictor and no independent pair of negative matrix who scopes. |
| Something standalone | none | Exact gap: neither positive existential nor existential-over-negation has standalone controls. Four authored controls below address these two shapes only. |
| Any/anyone polarity and free choice | none specifically isolated | Gap; cannot fill by assigning context-free universal force. Need explicit licensing/reading policy first. |
| Negative-relative restrictor + all/some/no | folio-mixed-relative-neg-1/2/3 | Three labels conceal one example per force. Each force still lacks second example; all also combines matrix negation. |
| Object relative + every/some/no | authored-object-relative-universal/-negated-gap/-negative-determiner | Three umbrella rows, one per force/gap-polarity combination; no two-per-subconstruction proof. |
| There-existential, graded quantity, generic indefinite | no dedicated labels | Existing at-least-one possessive and a/an intransitives do not fill these gaps. Interpretation work required first. |

Pronto relative conjunction/disjunction restrictions have two each; nested
conjunction/disjunction with conjunction consequence have three each; negative
relative consequence has four. These broad labels still combine nominal and
adjectival leaves. Prover universal_nominal has two examples but they are one
transitive Every-bird and one modified All-frogs: two names in a bucket do not
establish two independent realizations of either syntactic subtype. Likewise
for_topic has two human/either examples but is not direct NP determiner coverage.

## Frequency-guided next needs, without invented token counts

Within ProofWriter's all110 files, generic conditionals1,001,985 and conjoined
conditionals915,052 are highest-frequency relevant families. Their existing
something rules and newer person someone rules should remain separate; expanding
generic binding beyond controlled scope needs its own interpretation. Bare
universals597,392 and explicit all590,281 next motivate repeated adjective/
nominal/negative and modifier-head controls, not a new all quantifier meaning.
Natural-language generic indefinites28,126 and quantified paraphrases4,822 remain
broad unresolved surface families, not covered by the two Prover indefinites.

Pronto every/each185,426, bare plurals184,577 and restricted everything176,850 are
all represented at broad family level. Exact direct Every/Each N is a/an N has
86,788 occurrence opportunities (1,402 surfaces), independently counted in
pronto-nominal-coverage.json. Noun POS eligibility is a lexical-evidence issue;
it is not permission to weaken existential/quantifier gold or treat nonce words
as names. Every versus each subcounts and per-polarity totals are not established
by these aggregate tables; do not invent a ranking between them.

Owner-focus Prover quantified-pronoun/relative983, universal nominal418 and
initial indefinite24 highlight strict person restriction and force-specific
relative controls. The overlapping someone/anyone/somebody/anybody antecedent
cue504 cannot yield an anyone token frequency or prove a universal meaning.
The initial if outer family5,279 cannot be counted as quantifier coverage.

The FOLIO120-record sample has universal nominal117, existential nominal47,
negative quantifier23, quantified pronoun/relative11 and there-existential5
outer occurrences; these sample counts cannot extrapolate to the full corpus.
Mixed negative restrictor force and existential there remain specific gaps.
Across benchmarks these are different populations, not additive priority weights.
References: sections/proofwriter.md, prontoqa.md, proverqa.md and folio.md.

## Domain and scope contracts: do not pool incompatible meanings

Historical starter everyone rows prover-quantified_pronoun_or_relative-1/2 use
unrestricted everyone; new strict-person everyone/who rows add person. Preserve
historical bytes and compare under explicit partitions; adding both alternatives
to a single gold array would hide the disagreement. Someone's strict person
restriction does not justify adding person to something. Existing conditional
something and Pronto everything use unrestricted individuals with written
properties only; no silent thing atom. Conversely an ordinary strict-English
thing/nonperson interpretation would need a new coherent contract, not a
retroactive change justified by a closed lexical template.

For `Something is not quiet`, intended controlled meaning is
exists x.not quiet(x), not not exists x.quiet(x). The witness remains top-level;
only the not condition is Asserted and quiet is Embedded. A conditional
`If something is red then it is quiet` has an antecedent-local binder accessible
to the consequent and asserts only implication. No witness is asserted in the
main box. These are distinct constructions despite the same lexical pronoun.

## Four new independent authored controls, not benchmark recovery

`quantifier-gap-controls.jsonl` contains positive Something-is-quiet/red (two)
and negative Something-is-not-quiet/red (two), under explicitly declared
controlled-entity-existential-v1. They use no source-derived counts and are not
added to frozen173. Their simple contrast is intentionally isolated from names,
plural lemmatization and nominal v2 policy. Gold was authored before any parser
observation and schema-validated only; no fidelity outcome is claimed.

Unit2: lexical NP for something, AP `S[adj]\NP` predicate, copular
`(S[dcl]\NP)/(S[adj]\NP)`, optional VP-negation endomodifier. Unit3:
something is lambda P.exists x.P(x); negative VP is lambda Q.Q(lambda x.not
quiet(x)), so final backward application keeps existential outside negation.
Unit4 positive DRS [x|quiet(x)] has quiet Asserted; negative [x|not[|quiet(x)]]
has not Asserted and quiet Embedded, no Reported/Presupposed/OR metadata.
No predicted first parser divergence is asserted: a future Explain audit should
check lexical pronoun force/domain first, then VP-negation scope, then claims.

Boxer2008 category/lexical selection versus resolution distinction supports
keeping domain choices separate from scope composition. Pinned ccg2lambda2015
quantifier templates distinguish universal/existential force, but neither source
makes our controlled empty-domain restriction the uniquely correct ordinary
English reading. As documented in QUANTIFIER_PRIORITIES, preserve negated-
existential no serialization rather than its truth-equivalent universal-negative
variant; context-free universal any remains rejected as a general rule. This
is a design comparison, not an upstream parser run or an oracle label.

The owner's two-to-three requirement is met for several broad constructions,
not exhaustively for each quantified subtype or all input families. Fill the
high-frequency meaningful splits first; do not grow tiny authored panels to
claim population fidelity or open the model/benchmark gate.
