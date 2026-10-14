# Bounded token boundary implementation

2026-10-14. Full-access shell verified in /home/gram/astra-wt/token-boundaries,
branch astra/token-boundaries. Only Tokenize.hs, TokenBoundarySpec.hs and this
note owned; no cabal or gold changes. Parent owns full fidelity and integration.

Reviewer approved the concrete scanner transitions before source edits:
period internal only with immediately adjacent digits; ?! consumes only
contiguous ?!; trimmed span end is start plus trimmed text length. Cased
word scan adds the same digit-dot-digit case; rawTokens unchanged. Review
requested explicit 1..2, .5, 5. and mixed punctuation controls; included.

Independent fixtures first: initial 33 checks had 21 pass / 12 red. With
reviewer's four controls, before source: 24/37 pass, 13 red. After bounded
source change: 37/37 pass. No parser-derived oracle, corpus, model, CCGbank
loader or benchmark launch. Unit fixture suites are the validation target.

Digit periods are an orthographic convention, not numeric type/meaning or
coverage evidence. This also keeps numeric version components together.
Sentence terminal periods remain separate cased tokens. Titles, initialisms,
quotes, ellipses and numeric forms .5 / 5. receive no new interpretation.
Source slicing remains document-global and exact after trimming. Public
sentence/token interfaces remain unchanged.

Commands:
```
runghc -isrc -itest test/TokenBoundarySpec.hs
cabal test all --offline --test-show-details=failures
```

Validation completed: cabal test all exited 0; all 21 registered suites pass.
Focused standalone suite passes 37/37; git diff --check clean. Reviewer read
and approved the live source diff as a candidate before commit. Coordinator
still must run fresh full fidelity/source-hash checks and remaining integration
gates before landing. No fidelity improvement is inferred from these tests.
