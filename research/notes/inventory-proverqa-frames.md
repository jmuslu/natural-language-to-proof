# ProverQA residual-frame refinement

2026-10-14 prediction before inspection/counting: most of the 3,791 unresolved
occurrences have lexical verbs, but PP attachment, nominal objects and lexicalized
predicate phrases will split this sharply. Anchored narrow patterns with reviewed
representatives should certify only a subset of outer syntactic frames; all
remaining rows remain unresolved, not semantic successes. Input-only sealed cache
is read-only; no labels, proof fields or parser outputs will be read. No CCGbank,
model, solver or answer benchmark runs. Commit only own script, section and notes.

Read-only command: `python3 research/linguistics/inventory-proverqa-frames.py --cache
/home/gram/nl2proof-astra/research/runs/linguistics/other-refresh/proverqa-unique.jsonl`.
It reproduces 17,345 total /17,285 distinct, 3,791 residual /3,773 distinct.
Final anchored audit covers249 occurrences/247 surfaces, leaves3542/3526 explicit.
Candidates611 PP/particle,360 coordination,133 titles,12 possessive subjects;
these overlap. Prediction held: name+verb shapes do not determine constructions.

Reviewed finite predicate-tail types and compact input-only representatives before
writing anchored patterns. Distinguish this from auditing all249 full sentences or
certifying their semantics. Source entrypoint/source README were inspected via web,
not run. The local README read initially included its example schema with labelled
fields; these were incidental documentation exposure and were not used for any
classification or gold. No dataset answer/proof/nl2fol fields were accessed; no
parser results or gold files informed this refinement. Further source inspection
used entrypoint code rather than dataset examples.

Script asserts exclusive audit partition and preserves multiplicities. Negative
controls check that a valid tail extended with coordination, negation, a relative,
or an extra PP does not receive its simple-pattern label; title and possessive
controls check subject structure. All validation commands exit0; git diff --check
passes. Coordinator retains release gates and push ownership.

2026-10-14 follow-up proposal task, after independent inventory commit5bec6b0:
full-access shell confirmed, clean branch. Read sealed initial85 observations and
source to propose next repairs; this follow-up legitimately uses parser outputs
and does not retroactively inform the already committed input-only audit.
No new parser/model/benchmark runs. Added residual-priority.md only. First repair:
conditional separator licensing to eliminate selected(A→B)∧B; trace directly
proves lambda-stage error, comma/operator chart path explicitly remains a hypothesis
pending focused Explain. Second: POS/category-licensed lemma identity, has→have
and plural common nouns, preserving name/adj forms. Counts only set priority;
no recovery gains predicted from unrepresentative85controls. Each proposal has
three authored expectations, DRS/status, current-source evidence and pinned sources.
