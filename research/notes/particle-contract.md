# Particle contract investigation — 2026-10-14

Shell verified clean assigned /home/gram/astra-wt/particle-contract worktree.
Own only this note and proposals/particle-contract.md. Read STATE, existing
particle/source comparisons, ProverQA section and input-only unique cache.
Inspected context/question fields only from1500 original ProverQA items; no
answers, reasoning or FOL used as semantic evidence. No parser/model/benchmark.

Identified three full source-derived lexical-particle candidate sentences and
three directional-PP candidates with exact coordinates. No modifiers deleted;
semantic uncertainty makes most unsuitable for frozen canonical gold yet.
Input search independently confirms zero carry-out forms, agreeing with prior
inventory. Carry-out therefore appears only as an explicitly authored lexical
contrast, never falsely as a ProverQA source sentence.

Existing local PDF conversion unavailable (pdftotext and PDF Python packages
absent); no install attempted. Read the primary hosted CCGbank manual instead:
https://shannon.cs.illinois.edu/Papers/CCGbank/CCGbankManual.pdf §3.7.6. Its explicit
absence of particle subcategorization matters: PR entries in the locally pinned
ccg2lambda event YAML belong to rebanked parsers, not original CCGbank attestation.
No input-specific offered-category claim made without parser/tagger evidence.

Prediction before final source-coordinate check: six chosen cache coordinates
and texts match exactly; proposal keeps each complete sentence. No inference
about frequency or parse performance follows. Validate by read-only JSONL lookup,
then git diff --check. Most meaning sketches are deliberately deferred contracts,
not canonical gold or asserted equivalences between direct and event encodings.

Result: all six source coordinate/text checks passed; complete source sentences
appear unchanged in the proposal. git diff --check passed. No source/gold/parser
behavior changed. Proposal separates original CCGbank, actual upstream rebanked
PR templates, and unverified intended analyses for the six inputs. Independent
review must choose lexical/event contracts before new gold authoring.
