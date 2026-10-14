# Bounded noun-lemma diagnosis and proposed lexical rule

Scope: the eight primary morphological mismatches in frozen167, as enumerated
in WRONG_TYPED_167.md. This proposal contains independent red tests, not a
production repair. No gold or parser output is rewritten and no corpus is loaded.

## Actual source explains two different mechanisms

In `CCGSem.hs`, `openTemplateWith` maps category N directly to predicate `lw`
(lowercase surface); N/N likewise preserves the surface. One-place and transitive
verbal categories use `predName`: S[adj] preserves lw, while other S features call
`verbLemma`. `verbLemma` handles known inflections and then `lemma3sg`, which
already maps excels to excel. `CCGSemParse.lexicalSigns` passes word/category into
that function without nominal morphology evidence. The model's explicit-that
attestation set independently uses `reportingLemma`; that shared key must remain
unchanged. There is no separate Lemma module in this source snapshot.

| Frozen wrong cases | Observed predicate mismatch | Bounded causal conclusion |
|---|---|---|
| folio-some-2/-3, folio-some-not-2, folio-no-1/-2 | birds/hawks, pets/cows, animals/alligators versus singulars | N lexical template definitely lacks normalization; exact selected category/POS of each occurrence unknown from inspected accepted Explain caches |
| folio-extended-universal-1/-3 | humans, monkeys/mammals versus singulars | Same noun-template gap is a candidate cause, not proof all predicate occurrences use N |
| prover-existential_nominal-1 | excels versus excel | Not missing verb suffix normalization: direct verbLemma already returns excel. Could be adjectival/category selection or another path; earliest stage unknown |

Seven FOLIO rows share an apparent nominal mismatch, but some predicate nominals
may have been offered as S[adj] and will intentionally remain outside the rule
below. Do not promise seven exact gains. Thriving frogs and fictional Pronto
plurals also have morphology symptoms, but modifier-order/name/generic defects
make them separate compound failures. These are not person-domain contract
mismatches: existing gold consistently requires singular predicate identity.

## General rule proposal: supported regular plural noun at category N only

At lexical candidate construction, normalize an ordinary N candidate only when:

1. Its actual offered category is plain N, not N/N, NP, S[adj] or a verbal/event
   category. Closed-class and proper-name paths remain untouched.
2. The lookup surface has unambiguous NNS dictionary evidence: no competing NN,
   NNP/NNPS, JJ or verb POS evidence. Dictionary counts are evidence, not contextual
   certainty; ambiguous evidence preserves the original conservative behavior.
3. Removing one final s yields a nonempty base with unambiguous NN dictionary
   evidence. Limit the initial productive rule to plain appended-s shapes; do not
   handle ies/es/doubling/irregulars or ss/us/is-looking endings by blind stripping.
   The inverse spelling must be exactly base+s. Require independent base evidence,
   not a benchmark noun list or a guessed absent singular.
4. Emit a lexical stipulation with original word, offered category, POS/base
   evidence and normalized predicate. Do not change token text, tag scores,
   capitalization, proper-name constants, category inventory or parse ranking.

Implementation location is the open candidate branch of lexicalSigns, where both
POS model and offered category are available. Pass the justified normalized word
to the N template only; retain original spelling for diagnostics/stipulations.
A small pure helper may compute this evidence/result for testing. Do not broaden
openTemplate globally: it has no POS evidence and legitimately receives nouns,
adjectives and synthetic words that resemble verb inflections. Do not normalize
whole DRSs after composition or alter the scorer's predicate comparisons.

The initial rule deliberately handles supported plural restriction nouns first.
It does not license a plural noun offered as an adjective, invent category N for
it, normalize compounds, resolve fictional nouns absent from the dictionary,
change generic NP force, or interpret name Dean as a noun. Further coverage needs
its own origin-sensitive category rule and independent controls. Unsupported words
remain visible failures rather than guessed benchmark-specific lemmas.

## Independent controls and required follow-up

`test/NounLemmaProposalSpec.hs` uses authored lantern/crane vocabulary and current
public lexical APIs. Two checks are red: base-attested NNS nouns retain their
plural predicate. Ten preservation checks pass: singular/no-base/NN-only/verb-POS
cases, glass, existing excels verbal lemma, unchanged adjective spelling, and
explicit-that attestation key stability. A first run compared bound variable
names too literally in the adjective control; corrected it to alpha-normalized
term equality, without changing the expected predicate or production source.

These tests are a proposal suite, not registered in shared cabal. Run standalone
with `runghc -isrc -itest test/NounLemmaProposalSpec.hs`; no model loads occur.
Before a production patch, add category/NP/name-conflict, ambiguous POS/base,
reserved quantifier and compound rejection controls against the chosen helper,
plus the exact existing that-clause regression suites. Do not call the present
12 tests a complete proof of the new morphology rule's safety.

After independent review and implementation, coordinator runs full gates and
fresh fixed gold with hashes. Predict improvement only for candidates whose
selected noun category and lexical evidence actually satisfy the rule; inspect
all newly typed/wrong alternatives. The excels row remains a separate diagnosis
until accepted Explain evidence locates its category. No global rule should
force adjectival excels to a verbal lemma to make this one case pass.
