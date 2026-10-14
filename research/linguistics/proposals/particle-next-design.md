# Stand-out lexical span: bounded design after sealed190

Proposal only; reviewed gold7594867 is immutable. The three authored controls
use `stand-out-noticeable-fixed-comparison-v1`, not unrestricted English or
ProverQA source acceptance. No source/gold edit or corpus load is authorized
by this document.

## What the actual observations establish

Evidence: root `research/runs/expanded190-baseline/fresh.observations.jsonl`,
SHA256 `7217d0d7872bcc920c9ea1bf8957500f469d1d0347a6a8a589a14b60ac52f724`.
The seal reports complete execution and unchanged inputs/sources; the binary
SHA256 is `5fb8272a294621f315df69a168f2ec340930f26710648701c55b607b9bb0dba5`.

| Frozen input | Selected actual formula | Source/provenance evidence |
| --- | --- | --- |
| Mira stands out. | `forall x.(mira(x) & stands(x) -> out(x))` | Root S[adj]; bare-NP decision spans Mira0:4 and stands5:11, with FwdApp then unary NP |
| Noel stands out. | `forall y.(out(y) -> stand(Noel,y))` | Root S[dcl]; Noel is a dictionary-NNP name; bare-NP decision at out12:15 |
| Mira does not stand out. | `not forall y.(out(y) -> stand(Mira,y))` | Root S[dcl]; Mira name-from-N choice; ordinary negative scope; bare-NP out20:23 |

All are wrong-but-typed relative to the independent unary noticeability gold.
The first divergence is before claim splitting: the lambda already contains an
invented noun restriction/object or name-as-property analysis. The first row
supports an N/N-plus-N route followed by generic N→NP and adjectival out as a
**source-informed reconstruction**. The latter two support the ordinary
transitive stand plus generic out-object route. The cache records formulas,
root categories and decision subtrees, not a complete leaf-category derivation.
Do not claim an exact selected lexical tree, IV absence, or an offered out
VP-modifier from this evidence. The give/up category cache proves only give/up.

## Smallest candidate and its closed origin gate

Reuse the existing completed two-token lexical seed mechanism. Refactor its
one give/up sense into explicit English lexical sense data, preserving that
existing record unchanged. Add stand/out only after independent category
inspection confirms the required source offers. Proposed record:

- finite surface stands and base surface stand, with exact dcl/b features;
- adjacent out with original `(S\NP)\(S\NP)` category;
- unary noticeability predicate `stand_out_noticeable`, fixed comparison/time
  contract, not superiority or literal standing;
- source head exactly `S[dcl]\NP` or `S[b]\NP`, ordinary unfeatured NP.

The guard is closed over the licensed lexical record AND original token
occurrences/categories. It does not authorize a term because its predicate
string resembles stand, because a tag is type-compatible, or because a nearby
out exists. Source evidence comes from offeredTags before lexical repairs;
never from an N/N or transitive semantic sign coerced to IV. Preserve both
original leaves, exact spans, scores and a construction key/sense record in
provenance. One immutable seed list must feed category and semantic charts.
No generic out identity, transitive argument deletion, source-text rewrite or
benchmark/name whitelist is allowed. The miniature tests stipulate these
source offers for independent controls; they do not establish corpus offers.

Unit2 is the already reviewed two-token span followed by NP/VP application.
Unit3 instantiates `lambda S:Q.S(lambda x.stand_out_noticeable(x)) : Q→t`.
Unit4 produces the fixed gold's unary atom or whole negation, with the inner
negative atom Embedded, not Asserted. The existing three authored gold rows
supply independent DRS and claim expectations; they are not replaced by the
parser's transitive formula.

## A correct candidate is not yet an exact selected repair

Retain ordinary competing readings and their scores. Adding a lexical sense
may leave higher-scored wrong roots, especially Mira's separate name/N ambiguity.
The observed Noel error shows that fixing name status alone is insufficient.
Do not hide old readings or raise the new score until it wins. No evidence in
this audit licenses a general ban on ordinary out nouns, stand transitives,
Mira common-noun interpretations or adjective roots.

A claimed exact correction requires fresh selected-meaning and retained-reading
review. If actual IV/category offers are absent, stop at that gap; MWE-owned
category reanalysis is a separate policy requiring independent tests. If the
new valid reading loses selection, report the remaining ambiguity rather than
install a gold-driven tie-break. A future closed-origin *elimination* guard
would need independently justified lexical/POS/context restrictions applying
to ordinary homographs too. The present origin gate controls admission of the
new lexeme; it does not silently grant that broader suppression authority.

## Escape controls and frequency order

The standalone public-parser suite has three expected red construction controls
and thirteen preservation/rejection controls. It tests absent/wrong particle,
wrong head, unsupported past morphology, intervening object, comparison PP,
transitive-only or nominal head, nominal/PR/directional particle categories,
and incompatible adjective features. A literal directional PP or *stand out
from Ada* cannot become the simpler unary gold by losing its dependent. Neither
separated particles nor *stand up for herself* inherits this record. Before a
source candidate, extend checks for actual nonzero scores, both source leaves,
original categories, DRS/status, clause boundaries and mixed offered alternatives
as done for give-up; preserve the existing35 give-up controls.

The input-only priority audit7594867 records ProverQA stand-up32/31 and
stand-out15/15 occurrences/surfaces, plus ProofWriter stand-out84/5 physical
occurrences/strings with causal/pronominal context. Stand-up-for remains the
higher-frequency stance/PP-reflexive design priority; the bounded stand-out
sense is a smaller lexical-control task. These are not frequencies of already
validated meanings and not promises that15 or84 cases improve. No new dataset
extraction was performed here.

## Prior-system comparison and next gate

Adopt lexical/category/resolution separation from [Boxer2008](https://aclanthology.org/W08-2222/)
§§2–3; adapt through the declared direct-unary sense instead of copying event
roles into the current Q interface. Neither Boxer nor the lexical spelling
chooses noticeability over superiority for all contexts.
The pinned [ccg2lambda event PR entries](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_event.yaml#L1153-L1190)
use rebanked categories and event continuations. Adopt preservation of lexical
content and participants; reject the1189–1190 higher-order identity fallback
as a generic solution. Those entries do not certify original stand/out offers
or the project's claim-status barriers. Detailed source qualifications remain
in the accepted particle licensing and learner C9/C10 sections.

Next: independent review of this record and guard, then coordinator-provided
sealed offered-category evidence if authorized. No implementation is justified
by the current observations alone; no CCGbank/model/answer benchmark launched.
