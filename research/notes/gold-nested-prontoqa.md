# Nested ProntoQA gold notes

2026-10-14 — Independent input-only authorship. Read root STATE, goal redirect,
and fidelity representation contract. Selected twelve exact isolated sentences
from local ProntoQA test_example.question fields, recording source/item/index.
No answer, proof, parser output, sealed observation, or model was used to choose
expected meanings. JSON containers are decoded to access input fields only.

Prediction before schema/source checks: three examples each of relative OR
restriction + AND consequence, relative AND restriction + AND consequence,
relative restriction + negative consequence, and bare-plural coordinated
consequence will validate. Three-way OR has two acceptable binary associations,
both specified before any parser run. Inclusive OR markers cover every nested
OR node in preorder. Everything ranges unrestrictedly, without thing(x).
Only each full implication is Asserted; all nested atoms/operators are Embedded,
in depth-first surface order. No condition is Reported or Presupposed.

Scope correction sent to coordinator: requested bare-plural coordinated nominal
restriction has no exact source in the recovered inventory: all bare-plural
subjects are one word. Supply attested coordinated nominal consequences instead;
do not manufacture an exact-source provenance for absent multi-modifier input.
Bare-plural ontology nouns use singular predicate lemmas. Restrictor conjunctions
here are all explicit copular relative predicates, whose order is their written
surface order; noun-head+prenominal-modifier ordering is not exercised.

These diagnostic gold cases are not a population sample or gate certification.
Coordinator owns parser scoring, review integration and release gates.

Result: all12 cases /17 explicit readings passed `fidelity.validate_case`; all12
texts match their exact referenced input-field sentence. IDs unique. Prediction
held. Coordinator confirmed coordinated consequences are the correct attested
replacement for the absent coordinated bare-plural restriction request.
Independent reviewer notified before integration. No parser observation used.

Independent reviewer approved all12 meanings/17 readings before observation.
Coverage caveat: mixed adjective+nominal bare-plural consequence has1 case;
negative OR versus AND restriction subfamilies have2/1 cases. Three per coarse
family does not certify every finer profile. Gold commit77e9338 remains frozen.

Prediction before parser diagnostic: nested restriction coordination will remain
a major failure, so fewer than6/12 selected meanings will be exact. Expected
failures include no-parse and wrong-but-typed; successful single-word bare-plural
subjects may still produce the wrong generic reading. Run only the existing
frozen parser binary through the shared CCG slot wrapper, parser=default;
no model API, solver or answer benchmark. Gold SHA256:
`23c17010af94fae6f5cad66fe109995c2e4af373171b912280e6b16e699b9025`.
Command:
`python3 /home/gram/nl2proof-astra/scripts/with-ccgbank-slot.py python3 test/fidelity/run.py --cases test/fidelity/prontoqa-nested.jsonl --binary /home/gram/nl2proof-astra/research/runs/integration-fidelity/fidelity-frozen --parser default --output research/runs/nested-prontoqa/default-report.json --timeout-seconds 600`.

Diagnostic result (frozen default parser,87.54 seconds excluding lock wait):

| Construction | exact | wrong-but-typed | no-parse |
|---|---:|---:|---:|
| Relative disjunction + conjunctive consequence |0|0|3|
| Relative conjunction + conjunctive consequence |0|0|3|
| Relative negative consequence |0|0|3|
| Bare-plural coordinated consequence |0|3|0|
| Total |0|3|9|

No type failures, incomplete documents or instrumentation errors. No alternative
reading matched any case. Prediction held. All three bare-plural outputs assert
two predicates of capitalized name constants (`Gorpuses`, `Impuses`, `Dumpuses`),
retain plural noun predicate strings, and lack the expected universal implication.
This is meaning/status corruption, not coverage success. All nine nested relative
inputs have no selected parse; this output alone cannot locate their earlier
lexical/category divergence. Gold remained byte-identical to the pre-run hash.

Frozen binary SHA256:
`5b3f5e9fe4fbe58928bd6d43facc8657cf344c80a55fd06afc8b79f27dc7f035`.
Sealed ignored cache directory:
`/home/gram/astra-wt/gold-nested-prontoqa/research/runs/nested-prontoqa/`.
Files: `default-report.json`, `default-report.observations.jsonl`,
`default-report.stderr.log`, `SHA256.json` (hash manifest).
These must be preserved by coordinator before worktree cleanup. Source hashes in
the report describe the worktree at observation; the binary hash identifies the
actual compiled parser. This is a frozen-foundation baseline, not proof that later
unmerged proposed repairs have these results. Only notes changed after observing.

Bare-plural/name follow-up (read-only analysis, no fresh parser launch): inspected
sealed trace plus current root nameStatus/lexicalSigns/unarySem/openTemplate.
Trace proves unseen initial NameOrOther, selected rigid name fromN, and existing
generic alternative. First case has exactly1.0 name/generic score gap, matching
free lexical name lift versus penalized generic unary. Nominal predicates remain
plural in both alternatives. Proposal `proposals/bare-plural-names.md` separates
candidate evidence, structural cost parity, actual lexical disambiguation,
unknown morphology and generic force; preserves NNP/NNPS and Legend ambiguity.
Prediction before static review: proposal and notes only will be staged; no gold
or shared source changes, and sealed caches remain unchanged. Reviewer requested.
Static checks passed: all sealed manifest hashes match, gold is unchanged since
77e9338, and all three name/generic score gaps independently recompute to1.0.
No semantic code edited; proposal awaits independent review before implementation.
