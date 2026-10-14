# Bounded reflexive implementation — 2026-10-14

Assigned new worktree /home/gram/astra-wt/reflexive-implementation, clean at
start. Own CCGSem.hs, CCGSemParse.hs, ReflexiveProposalSpec.hs and this note;
no cabal/STATE/LOG edits. Reviewed 20-case contract was red on prior production
(8 pass,12 fail). Prediction before edits/tests: the closed diagonal term,
ordinary N/NP reanalysis, lexical-leaf backward-application guard and reservation
will make these 20 corpus-free checks pass without changing conditional roles
or packing keys. All existing registered tests should remain green. No CCGbank
load or gold change authorized/needed. Commands: runghc -isrc -itest
 test/ReflexiveProposalSpec.hs; cabal test all --offline.

Initial implementation passed reviewed20/20. Diff review found corpus seen-pair
pruning would reject the new reflexive category before semantic locality checks.
Added public miniature regression with seen-rules enabled and no learned TV+
reflexive pair; it failed as expected (20/21). Next prediction: explicitly license
only the exact finite/base TV+reflexive category pair at the seenPair layer,
sharing its shape with the stronger lexical-provenance guard, makes21/21 green.
The first cabal test build remains in flight; rerun after final edits to ensure
final source state is the tested state.

Final results: standalone21/21 pass; final-source `cabal test all --offline`
passes all16 registered suites, including conditional-boundary14/14. The new
seen-rules-on check was red before the category-pair license and green after.
Final logs are ignored `research/runs/reflexive-implementation/final-tests.log`
and `reflexive-checks.log`. Required final source rerun completed normally.

Concrete diff reviewed: diagonal binds one subject witness twice; no benchmark
names/verbs appear in production. Reservation eliminates ordinary noun/name
fallback. Lexical repair preserves offered score and records original/target
categories in the note. `localReflexiveVP` licenses only the newly introduced
finite/base/plain-NP category pair for seenPair, while semCombine also demands
both lexical leaves, closed marker at the right leaf, exact resulting VP and
matching types. Pending signs cannot use any other binary rule or unary closure.
Completed VP can then compose with auxiliaries/negation and absorb punctuation.
Existing conditional payload fields and pack keys are untouched. No private
combinator export or new all-sign payload added. `git diff --check` passes.

Limits: singular direct-object itself/himself/herself only; unsupported reserved
reflexives stay no-parse rather than becoming noun predicates. Ordinary NP[nb]
may license reflexive reanalysis, but governor slots use the standard plain NP
transitive category. Plural, PP, intensifier, passive/adjective and composed or
extracted governors remain outside this bounded implementation. No corpus-backed
fidelity measurement performed here. Independent reviewer and coordinator own
corpus fidelity, all remaining release gates and cabal registration before push.
