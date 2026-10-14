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
