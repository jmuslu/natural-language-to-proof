# Fused-relative proposal notes

2026-10-14 — Full-access shell verified on astra/fused-relatives. Read root STATE,
committed construction/design/gold, source subjectRelative and pronoun entries,
and cached pinned ccg2lambda2015 relative and everyone entries. No licensed
corpus loaded or benchmark/model launched. Existing nestedPronto baseline has
nine relative no-parses; nominal copula quarantined separately.

Prediction before corpus-free checks: independently specified adjective-only
Everything/Something/Someone relative readings will fail, because the current
noun-relative reanalysis exposes no quantifier restriction on an existing NP.
Everything is additionally not closed-class. The existing Every cat that ...
control should pass; malformed head+noun must remain rejected. Tests specify
full canonical DRS and independent Asserted/Embedded rows, with3cases per fused
head. Something uses DESIGN's controlled unrestricted-domain convention; Someone
retains person. Gold fixtures and shared source remain untouched.

Proposed route is explicit paired reanalysis from source NP head + NP-relative
to quantifying NP/N head + N/VP property relative. Categories are a bounded
internal representation, not a claim of observed CCGbank tags. Pending provenance
must distinguish property-relative restriction from arbitrary ordinary N; feature
labels alone cannot enforce this. Reviewer required before implementation.

First run:3/22 checks passed; all9 scoped DRS and all9 independent claim checks
failed because no selected parse, plus Everything closed-class failure. Existing
ordinary noun relative and2rejection controls passed, as predicted. Before the
second check, added all-returned-readings scope checks (not only top selection);
predict3/31pass and28fail until the missing construction is implemented.

Second run matches prediction: all-returned-readings checks included,3/31pass
and28fail (all9cases no selected parse, plus missing Everything reservation).
Ignored output research/runs/fused-relatives/controls.log. Proposal explicitly
marks category reanalysis and required paired-origin guards; source NP* route
compared. Something sortal mismatch with existing standalone entry is an explicit
review decision, not silently repaired. No source/gold/cabal changes.
