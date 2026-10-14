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

Independent reviewer approved f4150f8 proposal and red controls, not source
implementation. Confirmed restriction/property scope, OR accessibility and
claim tables. Preserve person for someone; something may be unrestricted only
under an explicit coherent domain policy covering standalone and restricted
forms. Before implementation, spell out propagation through coordination,
composition and chart packing, and add raised/unary/mixed-origin negative
controls. Feature-only licensing is insufficient. No existing gold was changed.

2026-10-14 follow-up before checks: isolate Everything and strict-person Someone
as initial implementation scope. Retain Something authored controls byte-semantics
unchanged behind `--deferred-something`; this records the unresolved policy,
not a changed gold or a claim of completion. Add public chart negatives for
unary/raising, pending coordination, mixed noun/relative property, forged source
origins and composition; add an aggressive-unary valid positive. Prediction:
existing missing construction still fails all6 scoped controls and reservation;
negative cases mostly reject. Direct future role/packing tests remain required
because public chart behavior cannot inspect a certificate not yet implemented.

First expanded run13/33pass20fail. Before rerun removed a proposed *whole-sentence*
negative `Everything and someone who is red is big`: it can coordinate two
completed ordinary NPs, so using sentence rejection would be an unsound global
restriction. Its intended protection is instead in the explicit transition-level
pending-CoordApply contract. This is correction of an invalid new test before
implementation, not deletion of a production failure. Predict12/32pass20fail;
Something deferred run0/9pass, retained original intended structures.
Added one positive public provenance check after the scope checks: on the
unambiguous Everything relative, retained roots must not directly compose its
pending lexical head/relativizer before discharge. This is a partial external
check, not a replacement for actual certificate-state unit tests. Final default
prediction12/33pass21fail; all positive obligations remain red pending repair.

Final corpus-free checks matched predictions: default Everything/Someone+
certificate-boundary controls12/33pass21fail; deferred Something0/9pass9fail.
All new selected-DRS and independent claim requirements remain unmet; boundary
rejections alone are not counted as linguistic success. Runs exited1 as expected.
No shared source, cabal or committed fidelity gold changed. Static diff check
passed after removing one extra trailing blank line. Reviewer requested before
source implementation; the contract now specifies packing identity and source
seen-pair/prepass obligations rather than relying on category labels alone.
