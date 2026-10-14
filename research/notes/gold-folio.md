# FOLIO gold specialist record

2026-10-14. Branch `astra/gold-folio`; isolated worktree
`/home/gram/astra-wt/gold-folio`. Owned artifacts are this record,
`test/fidelity/folio.jsonl`, and `test/fidelity/folio-notes.md` only. Other copied
uncommitted work is left untouched and unstaged.

Prediction before checks: the 12 manual cases will pass schema validation and
have unique IDs, six groups with two cases each, ten valid sample source locators
(two verbatim and eight explicitly adapted), and two authored controls without
sample provenance. Explicit disjunction paths should target the intended root
OR; every expected claim table has a root universe equal to its DRS universe.
Source verification will inspect only sample IDs and English context, never
labels, formalizations, or proofs. No parser/model/benchmark runs are authorized
in this check. No exact-fidelity result is claimed.

Independent semantic review: existential subjects share their witness across
restrictor and property; negative existentials bind outside the negative box;
at-least-one child uses existential introduction with no uniqueness; negative
universals have no existential import; disjunction branches are embedded; speech
contents are reported with the source chain. The source sentence indices are
zero-based. Adapted examples are deliberately not claimed as source assertions.

Commands planned: import `test/fidelity/fidelity.py` for `validate_case`, check
case counts and IDs, read context lines through each recorded origin, compare
verbatim cases, and compare each adapted locator with the independently recorded
English source sentence. Run `git diff --check` on owned paths, then explicitly
stage and commit only the three owned files. Root runs integration gates before
any push; this worker will not push.

Independent reviewer feedback before any parser observation: align lowercase
predicate `american` with lemma conventions, and explicitly enumerate both
standard negative-quantifier DRT forms. DESIGN's primary negated-existential form
and the universal-negative form each receive their own hand-specified claim
table. Prediction for repeated schema check: all 12 cases remain valid, with
14 allowed full meanings; both no-universal cases have two readings.

Coordinator/reviewer direction supersedes the dual representation proposal:
use only design's negated-existential convention for no. The prior 12-case /
14-reading schema check passed, but those dual gold forms were not retained.
Prediction for final check: 12 cases / 12 meanings, two no cases with root
negation and existential body, and the previously verified locators unchanged.

Results: schema/source validation PASS (12 cases, six groups with two cases,
2 exact / 8 adapted / 2 authored). Final schema PASS with 12 full meanings and
no represented solely as negated existential. No parser or external model run.
