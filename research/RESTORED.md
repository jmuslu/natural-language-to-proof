# Restored modules: evidence and integration decision

Keep `Discourse/SDRT` and `Discourse/Threading` out of the default Pipeline. In ten handcrafted discourse probes, they introduced unresolved pronouns and produced no improvement over flat threading. Keep `Readings/Alternatives` as an explicit candidate-generation experiment; its limited scope permutations work on the tested forms, but modifier fusion does not yet identify noun phrases reliably. Merely wiring `Readings/Modifier` annotations would not repair lexical meanings.

These are deliberately small capability probes, not corpus accuracy estimates. They use the hand lexicons and local authored extensions, load no licensed corpus, use no gold benchmark labels, and do not admit facts through an oracle. Production defaults are unchanged.

## Discourse comparison

Reproduce from the repository root:

```sh
runghc -isrc research/probe-threading.hs > research/runs/phase-g/threading.jsonl
```

All 27 sentences parsed. There are 12 pronouns across ten texts; the final chain has three. Flat threading resolves ten and leaves the two intended negation/report barriers unresolved. Committed resolves three; Permissive resolves five. Thus Committed loses seven resolutions across six texts, and Permissive loses five across five texts. Neither resolves an additional pronoun. Counting a resolution does not prove its linguistic correctness; the table records exact outputs and the intended diagnostic contrast.

| Case / exact text | Flat unresolved | Committed unresolved | Permissive unresolved |
|---|---:|---:|---:|
| A student arrived. She smiles. | 0 | 0 | 0 |
| John smiles. He sleeps. | 0 | 1 | 1 |
| The cat sleeps. It walks. | 0 | 1 | 1 |
| A student arrived. Every professor smiles. She sleeps. | 0 | 1 | 0 |
| A student arrived. Every professor smiles. Every dragon sleeps. She walks. | 0 | 1 | 1 |
| A student arrived. A professor walks. She smiles. | 0 | 0 | 0 |
| No student sleeps. She smiles. | 1 | 1 | 1 |
| John says that a student sleeps. It walks. | 1 | 1 | 1 |
| John smiles. Mary sleeps. She walks. | 0 | 1 | 1 |
| A student arrived. He smiles. He sleeps. He walks. | 0 | 2 | 1 |

The definite example uses an explicitly declared generalized-quantifier definite determiner and a `cat` noun added to the hand lexicon. It exercises discourse handling of the same constant-valued definite representation used in Phase B; it is not a separate CCGbank coverage result.

The causes are visible in the interfaces. `Ranked.rkRef` admits only `Ref`, while flat Phase B antecedents include named/definite `DConst` values. Both SDRT policies therefore lose those candidates. Committed's coordinating default closes the previous unit; resolved pronouns do not introduce a fresh universe member, so a pronoun chain starves. Permissive only varies the latest relation edge, keeping earlier attachments committed; by the fourth sentence, it can also lose a still-needed antecedent. Existing `fullLicensingAt` explores labelings of one committed topology, not all attachment structures, and explicitly refuses excessive enumeration.

The Phase B barriers remain intact in these probes: neither policy recovers an entity introduced inside negation or a report. That safety is necessary but does not offset the regressions. Integration would need a candidate type supporting constants, propagation of discourse referents through anaphoric units, and an explicit treatment of earlier edge uncertainty, followed by a paired corpus evaluation. No weight adjustment alone fixes all three issues.

## Scope and modifier alternatives

Reproduce:

```sh
runghc -isrc research/probe-alternatives.hs > research/runs/phase-g/alternatives-seven.jsonl
```

All returned terms in these seven cases were closed and type `t`.

| Text | Scope readings | Combined alternatives | Finding |
|---|---:|---:|---|
| Every student reads a book. | 2 | 2 | Surface and inverse quantifier scope generated. |
| Every student who reads a book smiles. | 1 | 1 | Restrictor-internal existential stays inside the relative clause. |
| No student sleeps. | 1 | 1 | No permutation through negation. |
| An ancient Chinese red dragon sleeps. | 1 | 1 | No modifier fusion generated. |
| A fake gun sleeps. | 1 | 1 | Surface intersective fixture retained. |
| John sees an ancient Chinese red dragon. | 1 | 4 | Surface plus ancient_dragon, chinese_dragon, red_dragon; only the Chinese fusion is class-licensed. |
| John sees a fake gun. | 1 | 2 | Surface plus fake_gun; fake defaults to Intersective, fusion unlicensed. |

The subject-stack result falsified the initial prediction of four alternatives. `modifierChains` collects all unary predicates on a variable and treats the last as the noun head. In a subject followed by an intransitive verb, that last predicate is `sleep`; the real noun then fails the “all preceding predicates are modifiers” test. Moving the same noun phrase into a transitive object's position restores the four candidates. Candidate generation is therefore sensitive to unrelated predicate structure, not just the modifier phrase.

The fake/gun examples use an explicitly intersective `adjEntry "fake"` fixture to test whether the restored classification repairs or rejects that representation. It does neither: the classifier table contains only red, ancient, young, chinese and old; all unknown words, including fake, default to Intersective. `Privative` and `Subsective` constructors exist, but exposing these types is not evidence of working lexical coverage. A fused predicate string is also a hypothesis, not an established lexical meaning or inference rule.

The safe result here is bounded: the scope generator's two tested restrictions held. It does not justify enabling every generated alternative by default, or attaching truth strength to class labels. Retain the probes and documented limitations; leave these modules opt-in until they improve a measured task.

## Ranking experiment boundary

Phase D exports every returned typed candidate through the same backend as the selected reading, including its CCG ranking score, scope-preserving DRS and decisions. The benchmark runner can compare top-ranked, skeptical, credulous and cumulative-score-mass policies on identical items without changing fact admission. A softmax of corpus frequency scores is a search distribution, not calibrated truth confidence. Discarding low-score meanings changes the ambiguity policy and must be reported as such.

Do not call an untruncated Cartesian product exhaustive English ambiguity: the CCG chart already has a beam. Combination-cap truncation forces skeptical/credulous abstention; residual unsupported content remains visible. Compare answer coverage, selective accuracy, wrong positive/negative conclusions and complete-Unknown decisions separately. Use paired records and the same split/denominator; choose thresholds on development data and disclose them before any held-out evaluation. The current hand probes supply no evidence that a new probabilistic ranking layer improves benchmark reasoning, so no such default integration is recommended from them.

## Connections to the other seams

The probes reinforce the distinction between a well-typed structure and a correct meaning: all generated alternatives type-check, yet unsupported modifier fusions and scope-sensitive antecedent losses remain. Phase B established the separate claim-table and intensional boundaries; Phase D preserves those boxes for the solver rather than flattening them. Partial-theory monotonic proofs, complete-Unknown requirements, semiring strength propagation and the assertion-witness oracle boundary are evaluated in their respective implementation tests and benchmark runs. Discourse cue scores and parser scores have no authority to bypass those boundaries.
