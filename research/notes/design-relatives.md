# design-relatives worker notes

2026-10-14 full-access restart: shell works in /home/gram/astra-wt/design-relatives,
branch astra/design-relatives. Read coordinator STATE then ASTRA_GOAL. Copied dirty
snapshot contains unrelated work; none staged. No prior own proposal/notes existed.

Owned delivery: research/linguistics/proposals/relatives-coordination.md. No source,
STATE, LOG, cabal, gold, or other worker file edited. No new CCGbank load, model,
answer benchmark or implementation. Reviewed source, SemanticRepairSpec, Pronto and
Prover gold, cached ccg2lambda EMNLP2015 templates, sealed phase-b and linguistics
Explain logs, and Bos2008 primary publication record.

Findings: existing subject-relative N attachment and shared-GQ coordination are
sound on their narrow controls. Everything-as-N remains a false restrictor;
Prover rows called quantified_pronoun_or_relative do not yet contain relatives.
Selected argumentcluster output conceals an intransitive-likes alternative. NP
conjunction's “cat dog” alternative begins with cat:N/N and coordinates incomplete
determiners. Reviewer should not approve a blanket functor-coordination ban.
Cached ccg2lambda contains a sentence-or conjunction term: copying templates
without semantic checks is unsafe. Production implementation requires review.

Validation: source/log cross-check and git diff --check only, appropriate to a
design-only contribution. Coordinator owns merged-result fidelity and release gates.
