# nl2proof

Deterministic natural language to checked logical form. Sentences are parsed with
CCG, composed into typed lambda terms, built into DRSs that carry provenance, and
recorded in a derivation graph (Genealogy) where claims are fused and grounded only
by an external oracle. Nothing internal to the system counts as evidence.

`text -> tokens -> CCG derivation -> typed lambda term -> DRS (+provenance) -> claims -> Genealogy -> oracle-gated grounding -> Fusion`

- `src/NL2Proof/Syntax/` - tokenizer, categories, toy lexicon, CCG rules/derivation, CCGbank reader, CKY parser, supertagger
- `src/NL2Proof/Semantics/Lambda.hs` - typed lambda calculus (typing, beta, alpha-equivalence)
- `src/NL2Proof/DRT/` - DRS types, construction, canonical claim form
- `src/NL2Proof/Provenance.hs`, `Trace.hs` - source spans, decisions and diagnostics
- `src/NL2Proof/Pipeline.hs`, `Collapse/Class.hs`, `Fragment.hs` - end-to-end run, logged selection, fixed eval set
- `src/NL2Proof/Verify/` - Oracle (sealed admission), Claims (claim table), External (receipt oracle)
- `src/NL2Proof/Genealogy.hs`, `Fusion.hs`, `Reward.hs` - derivation graph, fusion, grounding score
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

## Next

1. Wire the CCGbank parser (`CCGParse`/`CCGSupertag`) into `Pipeline`.
2. Claims -> graph nodes, forward chaining, retrieval over the graph.
3. ProofWriter benchmark by depth: small-raw / large-raw / small+graph / graph-only.
4. Strength: oracle-grounded vs hearsay.

Tag `pre-cut` holds everything removed (Python corpus/brain, Stage 2, finance, docs).
