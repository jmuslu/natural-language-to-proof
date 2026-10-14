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

1. Actual offered category is exactly `CAtom "N" []`. No features, N/N, NP,
   S[adj] or verbal/event categories qualify. Closed-class/name paths untouched.
2. Original surface is a single lowercase ASCII alphabetic word of length at
   least4. Last character is s. Reject suffixes `es`, `ss`, `us`, `is`, `ews`.
   Formally: `length w >= 4 && all (\c -> 'a' <= c && c <= 'z') w &&
   last w == 's' && not (any (\suffix -> suffix isSuffixOf w)
   ["es","ss","us","is","ews"])`. This prose pseudocode defines the exact
   spelling envelope; implementation must use ordinary Haskell function syntax.
   It deliberately rejects **all** -es forms, including valid crane+s, avoiding
   axes/base(s)/species ambiguity rather than inferring uniqueness from dictionary
   membership. The conservative -ews exclusion rejects news even if a synthetic
   dictionary incorrectly offers it only as NNS plus a base new tagged NN;
   legitimate -ews plurals are deferred too. Multiword/hyphenated compounds and
   capitalized surfaces are excluded, without rewriting bald-eagle identity.
3. `posCounts` for the original surface has exactly the POS support set `{NNS}`;
   counts may vary but no competing NN, NNP/NNPS, JJ or verb evidence is allowed.
   The candidate base `init w` has exactly `{NN}` support. Empty or ambiguous
   support preserves original lexical interpretation. Dictionary POS is not
   contextual proof; this rule's conservative envelope is a declared lexical
   policy, not a theorem of unique singular interpretation in all English.
4. Log original spelling, offered N, both POS support sets, candidate base and
   rule version in a lexical stipulation. Change only predicate spelling for this
   candidate; not token text, scores, names, category inventory or ranking.

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

`test/NounLemmaProposalSpec.hs` uses authored lantern/garden vocabulary and current
public lexical APIs. Two checks are red: base-attested NNS nouns retain their
plural predicate. Twenty-four preservation checks pass: singular/no-base/NN-only/verb-POS
cases, glass, existing excels verbal lemma, unchanged adjective spelling, and
explicit-that attestation key stability. A first run compared bound variable
names too literally in the adjective control; corrected it to alpha-normalized
term equality, without changing the expected predicate or production source.

These tests are a proposal suite, not registered in shared cabal. Run standalone
with `runghc -isrc -itest test/NounLemmaProposalSpec.hs`; no model loads occur.
Before a production patch, add category/NP/name-conflict, ambiguous POS/base,
reserved quantifier and compound rejection controls against the chosen helper,
plus the exact existing that-clause regression suites. Do not call the present
26 tests a complete proof of the new morphology rule's safety.

After independent review and implementation, coordinator runs full gates and
fresh fixed gold with hashes. Predict improvement only for candidates whose
selected noun category and lexical evidence actually satisfy the rule; inspect
all newly typed/wrong alternatives. The excels row remains a separate diagnosis
until accepted Explain evidence locates its category. No global rule should
force adjectival excels to a verbal lemma to make this one case pass.


## Review refinement and target scope

The original wording was too permissive: axes may correspond to axe/ax/axis and
bases to base/basis even with NN evidence. The exact exclusion envelope above
supersedes it; the old cranes positive control is now a conservative no-change
control. Added negative controls cover competing singulars, synthetic news,
species, multiword/hyphenated compounds, capitalization, minority proper-name POS,
and conflicting singular/adjective/verb evidence.

Birds/hawks/pets/cows/animals/alligators/humans/monkeys/mammals satisfy the spelling
shape, but their actual POS/base evidence and selected lexical category are still
unknown here. No seven-row gain is promised. Unknown/nonqualifying evidence must
not be relaxed to chase that number. The test suite exercises the minimal actual
`lexicalSigns` hook, not a disconnected replacement lemmatizer.
