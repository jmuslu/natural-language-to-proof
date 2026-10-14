# ProverQA gold review (2026-10-14)

Prediction before validation: all 24 rows should pass the copied hardened gold
schema, with two examples in each of 12 outer surface families. Every source
reference should be corroborated by the existing input-only unique-sentence
inventory cache, unless that cache retains a different occurrence of a repeated
sentence. No parser/corpus model or benchmark is launched. Semantic expectations
were authored before any parser observation. Source-reference validation will
read only root's existing inventory cache, not labels, proofs, or raw datasets.

Planned checks: import `test/fidelity/fidelity.py`, run `validate_case` on each
row, count cases per construction, and compare source file/item/role/index against
`/home/gram/nl2proof-astra/research/runs/linguistics/other/proverqa-unique.jsonl`.

Result: all 24 rows passed `validate_case`; 12 families each contain exactly two
cases. All 24 file/item/role/index references matched the existing input-only
inventory cache. Fourteen sentences are unchanged; ten are explicitly adapted.
Manual inspection of those ten source/fixture pairs confirmed the recorded edits.
No source references were missing. The prediction held.

Semantic review: explicit `not both` remains a negated conjunction in addition to
OR, preserving duplicate embedded predicates; pronouns in the controlled examples
reuse the proper-name constant or conditional antecedent binder. The gold has no
reported/presupposed claims. Independent reviewer `/root/fidelity_review` previously
checked all 24 structures and found them consistent with their stated fragment
conventions. Current notes clarify that ProverQA is LLM-verbalized, not a finite
controlled grammar, and domain-wide *everyone* is a diagnostic convention rather
than an established property of every verbalization.

Limitations remain material: no modal gold, only lexical intransitives in the
unclassified bucket, no relative-clause quantified-pronoun controls, and lexical
simplification in ten rows. Schema success is not parser fidelity, population
accuracy, complete construction coverage, or permission to resume benchmarks.

Follow-up prediction (before validation): align the thriving-frogs case with the
independently chosen shared head-first nominal convention. Both DRS and manually
listed asserted/embedded conditions should now contain frog before thriving,
without changing truth conditions, source text, or claim status. The convention
uses nominal head identity as a stable anchor across pre/postnominal modifiers;
it was selected before parser results, not fitted to an observed derivation.
Schema validation should still pass for all 24 cases; all 24 source-reference
keys should still be present in the existing input-only cache.

Follow-up result: 24 schema passes, 24 source-reference matches; explicit checks
confirmed frog/thriving restrictor order and frog/thriving/resilient embedded
order. Prediction held. No parser invocation or new corpus/model load.
