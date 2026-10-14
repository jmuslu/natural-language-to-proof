# Frozen167 wrong-but-typed repair audit

This audit preserves all26 recorded wrong-but-typed statuses in the sealed
[expanded167 report](../runs/expanded-gold167/fresh.json), cases hash
`27e2f67dbf30397ca62345363bcb503d676297bbcd078d9d4da6685b019e92f6`.
It compares selected DRSs against existing independent gold; no gold, score or
parser is changed. Current source trials must obtain fresh evidence; these are
historical observations, not predictions of their results.

The26 rows represent25 distinct English texts: Gorpuses coordination appears in
two fixture IDs. Six disjoint primary clusters account for every row below.
Cluster membership describes the visible mismatch, not a proved parser cause.
Secondary morphology defects overlap the bare-plural and modifier clusters.

## Complete case accounting

| Primary cluster | IDs | Rows | Visible selected mismatch / harm |
|---|---|---:|---|
| Bare plural interpreted as name | pronto-bare-1/-2/-3; pronto-rule-and-2; pronto-nested-plural-and-1/-2/-3 | 7 | Jompuses/Wumpuses/Gorpuses/Impuses/Dumpuses become rigid constants; root property assertions replace generic implications. Six unique texts. Several also retain plural predicate spelling |
| Proper name interpreted as common-noun universal | prover-subject_do-1; pw-atom-transitive-neg-2 | 2 | Dean/Bill become dean(x)/bill(x) restrictors, replacing named negation with a general rule. False extension to other individuals is possible |
| Quantifier word lexicalized as property | prover-quantified_pronoun_or_relative-1/-2; prover-who-restriction-1 | 3 | everyone(x) restrictor appears. It is neither historical empty restriction nor strict person(x), so domain-policy disagreement does not excuse this output |
| Something domain-policy mismatch | pw-cond-generic-coord-1/-2 | 2 | Extra thing(x) restricts coordinated antecedent; gold explicitly chooses unrestricted something. This is a declared domain-contract discrepancy, with otherwise corresponding adjective/binder structure |
| Morphological predicate identity | prover-existential_nominal-1; folio-some-2/-3; folio-some-not-2; folio-no-1/-2; folio-extended-universal-1/-3 | 8 | excels versus excel; birds/hawks, pets/cows, animals/alligators, humans, monkeys/mammals retain inflection in predicates. Quantifier/negation structure is retained but logical predicate identity is wrong under declared lemma convention |
| Nominal restriction ordering | prover-universal_nominal-2; pw-universal-bare-2; pw-universal-explicit-1/-2 | 4 | Modifier-first restrictions violate independent head-first structural convention. Three PW rows preserve same conjunctive predicates; Prover frogs also has a lemma mismatch |

No cluster is relabeled exact or removed from the denominator. In particular,
three pure PW order differences are structural exactness failures, not demonstrated
truth-condition failures. Their lower semantic harm should inform repair priority,
not alter the frozen metric. Predicate lemma differences can disconnect inference
across singular/plural forms even when English meaning appears otherwise intact.

## First-divergence evidence boundary

The first *observed semantic discrepancy* is in the selected DRS for every row.
An observed ground constant versus implication is not, on its own, an Explain
trace proving where the derivation first diverged.

The accepted expanded167 Explain batch has an explicit13-ID manifest covering
new positive nominals, standalone strict-person cases, object relatives and
particles. None of these26 IDs appears in that manifest. It therefore cannot
supply their token/category/lambda first divergences. The older
prover-meaning-audit Explain log covers different historical probes; no exact
case-index/source binding for these26 was established in this audit. DESIGN's
Jompuses entry expressly calls its analysis static DRS/source-policy diagnosis,
not a recorded Explain derivation. No rejected nominal-candidate Explain output
is used as accepted-parser evidence.

Consequently the precise earliest token/category/combinator stage is **unknown
from the accepted Explain caches inspected here** for all six clusters. The likely
lexical/category/normalization seams below are implementation hypotheses based
on visible errors and existing reviewed proposals, not newly verified traces.
Do not convert “likely lexical morphology” into “Explain proved lemmatizer bug.”
No new parse is needed to recognize the output discrepancy; an implementation
must later establish its licensing and fresh fidelity evidence.

## Contract discrepancy is not an alternate answer

The historical everyone pair stipulates unrestricted quantification, while the
strict who pair retains person. These policies require versioned panels, but
observed everyone(x) satisfies neither. A strict-person repair may remain wrong
against historical empty-restriction gold; report that honestly, retaining the
old evidence rather than adding both readings to the old gold.

The something pair deliberately omits thing(x); a source-level policy decision
must cover standalone and coordinated/restricted something coherently. Keep
lexical noun things distinct: removing thing from genuine noun restrictions
would be a new error. No blanket dropping of sortals is licensed. Similarly,
head-first order must be implemented locally without sorting arbitrary claims,
deduplicating conditions, or corrupting nominal compound identity.

## Next three implementable improvement clusters

1. **Licensed noun/verb lemma normalization: eight primary cases, plus secondary
   defects.** Preserve lexical category, POS and origin distinctions while
   normalizing supported inflections at lexical interpretation, not by editing
   exported gold-shaped DRSs. Test singular/plural identity and negative/existential
   scope, irregulars, proper-name collisions, unknown words and compounds. Avoid
   blanket suffix deletion: fictional nouns and words ending s need separately
   justified evidence. This is a bounded implementation target with existing
   semantic controls; do not promise all eight exact before fresh verification.
2. **Proper-name versus generic nominal origin: nine rows/eight texts.** Repair
   category/meaning licensing, not capitalization alone. Pronto's generated bare
   plurals require generic restriction, while Dean/Bill require named constants.
   Existing reviewed name-ambiguity and nominal-envelope proposals offer guard
   obligations; preserve genuine common noun dean/bill readings in appropriate
   contexts and block unlicensed fallback rather than globally preferring names.
   Root assertion versus quantified rule is high semantic harm, so this cluster
   outranks cosmetic structural order despite harder disambiguation.
3. **Closed person/thing quantifier semantics: five rows, explicit panel policy.**
   Ensure lexical everyone cannot fall through as an ordinary property; preserve
   the person guard in strict-person panels and quantify the correct binder once.
   Resolve something's intended domain locally before coordination, keeping noun
   things untouched. Use already independent standalone/person and relative gold,
   plus existing generic something controls. Exact historical everyone success is
   not the objective if it conflicts with the adopted strict-English contract.

Frequency context supports these choices but cannot estimate their benefit:
ProofWriter positive copular5,689,297 and transitive2,162,712 outer occurrences
make NP/category integrity high leverage; its bare/explicit universal families
597,392/590,281 and generic coordinated915,052 make sortal/binder/order obligations
material. Prover quantified-pronoun+who959 and initial-if5,279 prioritize closed
quantification; its residual3,791 is not covered by a name/unary catch-all. Pronto
predicate-AND149,937 and relative restriction-AND128,988 cues emphasize preserving
shared binding. These buckets/cues overlap and are not counts of current errors.

Modifier-order repair is a separate lower-harm follow-up with three pure-order
and one mixed morphology/order case. The independently reviewed modifier-order
proposal must preserve compound lexical identity (bald eagle is not eagle bald),
restriction-only reordering and claim preorder. Do not use global canonical sort
as a shortcut. All candidate repairs require independent review, full release
gates and fresh fixed-panel fidelity; a wrong→no-parse move is reported as such,
not an exact gain. The ProverQA gate remains closed.
