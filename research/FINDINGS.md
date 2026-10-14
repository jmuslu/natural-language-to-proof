# Research findings — working decision document

Status: Phase B measured; C–H in progress. This is not the final synthesis.
Results are from branch `astra/research`; commands/predictions are in `LOG.md`.

## Meaning and oracle admission

Bounded semantic repairs hold on 29 hand-written tests and the licensed-model
probes: restrictive subject relatives, argument-cluster coordination's selected
meaning, endomorphic feature preservation, named/definite antecedents, normalized
reporting verbs, and factive complements listed only as Presupposed. The full
suite grew from 1,016 to 1,063 checks across nine suites; no existing assertion was
removed to hide a failure. The discourse fixture changed its middle sentence to
preserve its original frontier comparison, while a new check retains the original
Mary example and exposes the restored Ref-only Threading limitation.

Only top-level DRS assertion witnesses may request token-producing confirmation.
Raw conditions, removed promotion functions, altered Fact content and phantom-index
coercion are rejected. This establishes a structural API boundary. It does not
establish source authenticity or correctness of a caller-authored DRS.

The comma-quotation guard rejects extensional readings of recognized VERB+NP or
NP+VERB suffixes. `The cat is red, boasted Bob` now abstains on the real model;
it does not assert red(cat). Named/definite speakers and ordinary adjective lists
have regressions. Arbitrary quotation punctuation, adverbial tails and dialogue
remain outside this bounded guard.

Some well-typed meanings are still wrong. `Bob likes and Anne hates the cat` has
a correct selected reading and a second reading with intransitive likes(Bob).
`Bob likes the cat and the dog` retains a spurious cat dog alternative. Ranked
selection is a hypothesis; neither typing nor high score proves meaning fidelity.

## POS backoff: measurable gain, incomplete repair

The paired experiment uses the **first 120 OWA depth-5 development theories**:
2,244 theory sentence occurrences (2,124 distinct) and 2,560 questions. This is a
fixed diagnostic prefix, not a representative random sample or a held-out final test.
All conditions use the same items and default search settings.

| Measure | Baseline | Repaired default | Optional POS backoff |
|---|---:|---:|---:|
| Exact theory sentence coverage | 86.7% | 86.7% | 93.0% |
| Exact question coverage | 90.5% | 90.5% | 95.6% |
| Entire theory exact | 32/120 | 32/120 | 65/120 |
| No-root failures, 4,804 occurrences | 524 | 524 | 255 |
| Typed DRSs rejected by reference conversion | 16 | 16 | 16 |
| Converted-but-wrong meanings | 0 | 0 | 0 |

Percentages are the coverage driver's rounded output, not reconstructed exact
numerators. Eight rejected DRSs mix a conditional with a spurious top-level fact;
eight have an incorrect nested-conditional shape. Zero converted-but-wrong outputs
must not be confused with zero wrong well-typed meanings.

The loaded dictionary has adjective evidence for round, but none for kind. The
flag therefore repairs round and leaves kind unsupported. This contradicts the
initial prediction that both words would be repaired. Known NN/NNS/JJ evidence
adds missing noun/adjective categories; it does not infer an unseen word's POS,
contextual word sense or verb valency. Search scores rank these candidates without
conferring evidence strength.

**Current recommendation:** keep `--pos-backoff` opt-in. The gain is useful on this
slice, but evidence does not justify a blanket default or nominal-to-adjective
coercion for kind. Reproduce with `bash research/run-phase-b.sh`; local raw outputs
remain ignored under `research/runs/phase-b/`.

## See-that: retain a logged conservative sense policy

Perceptual see-that is factive; supervisory/ensure readings need not be. A global
lemma-level switch would conflate them. The default remains attributed and logs
`see-sense`, with the factive alternative visible. The original real-model example
failed to parse; the repaired complement-category attestation now parses it as
see(Bob, [red(cat)]) with red(cat) Reported, never asserted.

**Current recommendation:** retain this conservative unresolved default until a
sense distinction is supported by data. This is a limitation in disambiguation,
not a claim that perception is non-factive. Primary sources: [Dietz, §3](https://link.springer.com/article/10.1007/s11098-017-0929-y)
and [Voinov 2013](https://www.cambridge.org/core/journals/language-and-cognition/article/abs/seeing-is-trying-the-relation-of-visual-perception-to-attemptive-modality-in-the-worlds-languages/A0F8846B72AEB95F3A22E02B614CB86B).

## Remaining decisions and evidence

- Strength/retraction: finite antichain prototype laws pass; production integration
  and final results remain pending. See `STRENGTH.md`.
- Solver/error handling: pinned Z3 environment installed; 31 Horn/FOL contract tests
  pass, including partial-theory abstention and scope. Corpus benchmark results pending.
- Graph-context thesis: saved high-effort results use the same item IDs, but CLI
  prompt overhead has changed. Fresh low baselines are running; a contemporaneous
  high ProverQA run will check the primary comparison. Low/high are effort settings
  of gpt-5.5, not different model sizes.
- Guarantee benchmark, restored modules, seam audit, merge guide and final next
  three recommendations: pending Phases F–H.
