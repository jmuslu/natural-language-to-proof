# Proper-name meaning: N and NP are separate from name evidence

This repair concerns lexical meaning availability. It does **not** solve the
general problem of recognizing people's names from capitalization. In particular,
the intended name reading of benchmark *Legend* remains a known wrong-but-typed
case at sentence start. Its fidelity gold must remain the rigid individual.

## Observed default-corpus behavior

The pre-repair Explain batch used the default model, including truecasing and
smoothing, without POS backoff. One load read39604 training trees in83.5s. Inputs
are compact, hand-authored controls around benchmark names; *Abdullah explores
cultures* also occurs in the inspected ProverQA cache. Full outputs remain ignored
at `research/runs/linguistics-names/explain-before.log`.

| Input | Selected meaning before this repair | Other evidence and first divergence |
| --- | --- | --- |
| `Legend is red.` | `∀x(legend(x)→red(x))` | No rigid name reading. Initial truecasing consults the attested common noun; `N` receives `λx.legend(x)`, then generic `N→NP`. The lexical choice is already wrong for the benchmark entity. |
| `If Legend is red then Legend is big.` | `red(Legend)→big(Legend)` | Noninitial capitalization permits the name reading. The same surface has inconsistent lexical treatment across positions. |
| `Brecken is red.` | `red(Brecken)` | A second returned meaning is `∀x(brecken(x)→red(x))`. Name availability succeeds; ambiguity remains. |
| `Abdullah is red.` | `red(Abdullah)` | Also retains the generic common-noun alternative. |
| `Abdullah explores cultures.` | `∀y(cultures(y)→explore(Abdullah,y))` | Four returned readings. The selected name is rigid, but the object receives the current generic bare-NP interpretation; another reading universalizes Abdullah too. This is not evidence of complete sentence fidelity. |
| `Legend wakes up.` | A generic subject with an inappropriate adjective-style analysis | Both the name and particle/VP construction require work; this repair claims neither solved. |
| `White things are cold.` / `Cats are red.` | Generic ordinary-noun readings | The initial capitals are typography; no rigid White/Cats is justified by these contexts. Preserve that protection. |

These observations do not show that direct `NP` omission caused the Legend,
Brecken or Abdullah examples. The separate source defect is narrower:
`lexicalSigns` previously offered a proper-name term only when a name's offered
category was `N`. An already offered `NP` was dropped even when the dictionary's
majority POS was `NNP`. Hand-authored dictionaries isolate that defect without
depending on whether a particular benchmark name has this corpus tag.

## Derivation and intended representation — Units2/3/4

Take a POS-licensed name *Iris*, offered as `NP`, in *Iris is red*.

1. **Unit2, categories.** `Iris:NP`; `is:(S[dcl]\NP)/(S[adj]\NP)`;
   `red:S[adj]\NP`. Forward application yields `is red:S[dcl]\NP`;
   backward application with Iris yields `S[dcl]`. Final punctuation preserves
   that sentence. No learned `N→NP` is needed for an already-NP token.
2. **Unit3, types and terms.** Let `P=e→t`, `Q=P→t`.
   `Iris = λP.P(Iris):Q`; `red = λQ.Q(λx.red(x)):Q→t`;
   `is = λV.V:(Q→t)→(Q→t)`. Applications normalize to `red(Iris):t`.
   If the licensed name is offered as `N`, lexical lifting instead provides the
   same `NP` term before composition; it must not create `iris(x)` and a generic
   quantifier. Type-changing a common noun is a different semantic operation.
3. **Unit4, DRS.** `[ | red(Iris)]`: an empty universe and a rigid constant in
   the atomic condition, not `[x | iris(x),red(x)]`. Repeated mentions of Iris
   use the same constant. `Iris likes Iris` therefore gives `like(Iris,Iris)`.
4. **Claims.** The positive sentence has exactly one Asserted condition,
   `red(Iris)`, with no Reported, Presupposed or Embedded condition. Negating the
   VP gives `[ | ¬[ | red(Iris)]]`: the whole negation is Asserted and its atom
   is Embedded. Name recognition does not bypass claim scope or confirm a fact.

Relevant study sections: [Unit2](../../STUDY_PLAN.md#unit-2-ccg-and-ccgbank-weeks-23-the-biggest-gap),
[Unit3](../../STUDY_PLAN.md#unit-3-the-syntaxsemantics-interface-week-4),
[Unit4](../../STUDY_PLAN.md#unit-4-discourse-representation-theory-week-5).

## Chosen rule and why it is bounded

The source comparison motivates **POS-sensitive name meaning**, not treating
every `N` or `NP` as a name. ccg2lambda2015 has a
[POS-conditioned N-to-NP proper-name rule](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L37-L46).
We adapt that distinction to the existing rigid-name generalized quantifier;
we do not import its extra NP continuation or equality-bound witness. Bos2008
§3.2 likewise distinguishes category/type from POS-selected lexical meaning;
see [REFERENCES](REFERENCES.md).

The minimal implementation in
[CCGSemParse](../../src/NL2Proof/Syntax/CCGSemParse.hs) is:

- Ask the existing `nameStatus` policy whether a name candidate is licensed.
  A seen form uses majority POS `NNP/NNPS`; an unseen capital uses the existing
  positional casing policy. Unseen initial capitals remain `NameOrOther`, not
  certain names. Initial lower-case dictionary evidence still takes precedence.
- For that licensed candidate, an offered `N` lifts to ordinary `NP`; an offered
  plain `NP` or `NP[nb]` receives the same `nameItem` meaning directly. Preserve
  its score and the `nb` feature.
- Do not reinterpret `NP[expl]`, `NP[thr]` or `NP[conj]` as standalone names.
  Those features encode an expletive, dummy there, or unfinished coordination.
  The category alone is not evidence that an individual was named.
- Add a `name-lexicon` Decision explaining POS evidence or capitalization
  fallback. Its alternatives list contains the actually offered open lexical
  meanings for `NameOrOther`, and is empty for forced `NameOnly`. These lexical
  candidates need not all produce complete sentence readings; parse selection
  records that later distinction. Explain's source label previously said every name had POS-NNP
  evidence; it now refers to the actual POS/casing policy and that decision.

There is no entity-name list and no sentence-specific branch. `Pipeline`'s
shared type checking, normalization, DRS conversion and claim extraction are
unchanged. This closes a no-meaning hole for licensed NP tokens; it does not
justify increasing a reported English-fidelity score for Legend.

## Test-first evidence

[NameSemSpec](../../test/NameSemSpec.hs) was written before the implementation.
Its first run passed15/26 and failed11: direct NP/NP[nb]/NNPS lexical candidates,
subject/object/repeated-name composition, all-reading denotation, rigid DRS and
claim scope. Existing `N` lifting and all casing/common-word controls passed.
The controls include an initial adjective, an ordinary plural, a proper/common
homograph, an unseen initial capital, and forbidden NP features. The unchanged
intended Legend gold belongs in the construction fidelity set, not as an
incorrect expected universal in this regression file.

After the repair the focused suite passes26/26; existing semantic-repair29/29
and CCGSem89/89 checks also pass. This verifies the bounded implementation, not
the unresolved benchmark name-recognition cases.

Reproduction commands and before/after results are appended to
[LOG](../LOG.md). Optional `name-sem --corpus` checks compact default-dictionary
controls with a single local model load; no corpus lexicon or tree is committed.

## Later proposal: document-level entity evidence

The observed `If Legend ...` contrast suggests a useful **hypothesis**, not a
completed repair. A separate pass could collect a document-local name license
from a noninitial capital in a syntactically complete NP position, then offer
the same rigid alternative for its initial occurrences. It must retain where
the license came from and whether it is actual POS evidence or only the casing
heuristic. An uncertain hypothesis cannot be relabelled verified identity.

Before adopting it, specify and test these conditions:

- The evidence must come from the input's lexical/syntactic analysis, never
  benchmark entity lists, labels, a solver answer, or the desired gold formula.
- A selected guess cannot recursively reinforce itself across sentences.
  Record the original independent occurrence and each affected occurrence;
  conflicting common-noun uses keep the document ambiguous or unresolved.
- Do not transfer semantic referents out of negated/attitude/conditional boxes.
  Learning that a surface is used as a name is different from asserting its
  properties or making an inaccessible existential antecedent accessible.
- Test capitalized common nouns, sentence-initial *White*, titles, quoted names,
  person/common-word homographs, and multiple entities with the same spelling.
  `Dr.`/`Mr.` tokenization must be corrected separately before treating fragmented
  title/name strings as reliable evidence.
- Evaluate both added exact readings and new wrong-but-typed readings. Propagate
  a lexical alternative first; choosing it as the sole interpretation requires
  a declared disambiguation rule and evidence that beats the current failure.

No such pass is implemented in this change. If all occurrences are ambiguous
sentence-initial capitals, this proposal has no independent evidence to use.

## Independent continuation review

The resumed review reproduced all26 existing checks, then found a trace-only
defect: every name listed a hypothetical common-noun alternative, including
`NameOnly` tokens with no open lexical candidate. Four new controls cover factual
alternatives, dictionary evidence and unchanged category score. The two new
alternative checks failed before the metadata correction (28/30 passed). The
correction does not change categories, ranking, lambda terms or claim status.

After the metadata correction the focused suite passes30/30; `git diff --check`
is clean. Full build and release gates remain the coordinator's responsibility.
