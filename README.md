# nl2proof

Deterministic natural language to checked logical form. Sentences are parsed with
CCG, composed into typed lambda terms, built into DRSs that carry provenance, and
recorded in a derivation graph (Genealogy) where claims are fused and grounded only
by an external oracle. Nothing internal to the system counts as evidence.

`text -> tokens -> CCG derivation -> typed lambda term -> DRS (+provenance) -> claims -> Genealogy -> oracle-gated grounding -> Fusion`

- `src/NL2Proof/Syntax/` - tokenizer, categories, toy lexicon, CCG rules/derivation, CCGbank reader, CKY parser, supertagger
- `src/NL2Proof/Semantics/` - typed lambda calculus; `Intensional` (Ty2: world-indexed twins `c_s`, propositions `\w. P_w`, attitude verbs, fail-safe for unlisted reporting verbs: that-clauses and fronted quotes always reported, bare complements only for lemmas CCGbank attests with a that-clause, derived at load); `CCGSem` meanings for CCGbank categories
- `src/NL2Proof/Bench/` - ProofWriter gold parser and DRS -> triple/rule conversion
- `src/NL2Proof/DRT/` - DRS types, construction, canonical claim form
- `src/NL2Proof/Provenance.hs`, `Trace.hs` - source spans, decisions and diagnostics
- `src/NL2Proof/Pipeline.hs`, `Collapse/Class.hs`, `Fragment.hs` - end-to-end run, logged selection, fixed eval set
- `src/NL2Proof/Verify/` - Oracle (sealed admission), ClaimKind (Asserted/Reported/Presupposed/Embedded phantom index; `confirm` takes asserted only), Claims (facts are the main box's top-level conditions only: a negation, conditional or disjunction is one fact, whole; what is inside it is Embedded), Reported (attitude content with source chains, never a premise), External
- `src/NL2Proof/Genealogy.hs`, `Fusion.hs`, `Reward.hs` - derivation graph, fusion, grounding score
- `Readings/Alternatives.hs` - scope permutations and modifier-coupling candidates (restored; not yet wired into Pipeline)
- `Readings/Modifier.hs` - modifier classes and the layer each resolves at (restored; not yet wired into Pipeline)
- `Discourse/SDRT.hs` - SDRT relations, right frontier, cue-ranked glue (restored; not yet wired into Pipeline)
- `Discourse/Threading.hs` - frontier-aware anaphora threading, Committed/Permissive (restored; not yet wired into Pipeline)
- The probabilistic modules (RSA, Distribution, Model, Fingerprint) stay in tag `pre-cut`: planned as an optional ranking layer on top of these discrete readings, never admitting facts.
- `tools/` - CCGbank measurement drivers; `app/` - demo; `scripts/` - no-cabal build, oracle boundary check
- `test/` - specs; `test/compile-fail` + `compile-pass` prove the Oracle admission lock

## Build and test

```sh
cabal build all
cabal test all
bash scripts/check-oracle-boundary.sh
cabal run nl2proof-demo
```

Only `base` and `containers` are used; `scripts/build.sh` works with bare GHC.

CCGbank (LDC2005T13, licensed, never committed): `~/ccgbank/ccgbank_1_1/data/`, or set `CCGBANK_DIR`.
ProofWriter V2020.12.3 (CC BY 4.0, never committed): `~/data/proofwriter/`, or `PROOFWRITER_DIR`;
`cabal run proofwriter-coverage -- --split dev --split test --questions`.

## Next

1. Done: `CCGBankParser` in `Pipeline`. ProofWriter CWA depth-5, frozen on train: test sentences
   85.4% exact (facts 89.4%, rules 79.8%), whole theories 24.6%. The blocker is the WSJ lexicon:
   `round`/`kind` never get a predicative-adjective category; without them 99.8% / 94.9%.
2. Claims -> graph nodes, forward chaining, retrieval over the graph.
3. ProofWriter benchmark by depth: small-raw / large-raw / small+graph / graph-only.
4. Strength: oracle-grounded vs hearsay (hearsay is now representable: `Verify/Reported`).

Tag `pre-cut` holds everything removed (Python corpus/brain, Stage 2, finance, docs).
