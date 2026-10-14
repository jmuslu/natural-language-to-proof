## C13 extension: natural residual constructions, one obligation at a time

These cards expand the C13 backlog for STUDY_PLAN Units 2 (CCG), 3 (typed
composition) and 4 (DRS/claim status). They are specifications and learning
exercises, **not implemented templates or admitted gold**. All examples marked
*authored* are independent illustrations. Categories below are proposed CCGbank-style
analyses, not observed lexical offers or recovered trees. No new Explain run
was made. A complete typed term can illustrate a proposed contract without
establishing that the source sentence has that unique interpretation.

Write `p=e→t`, `q=p→t`, `lift(a)=λP.P(a)`. For extensional transitive possession
use `have:((S[dcl]\NP)/NP)` with
`λO Q.Q(λx.O(λy.have(x,y))) : q→q→t`. Features and lexical licensing remain
obligations; a category does not decide whether *has* means possession, auxiliary
perfect, obligation, or a light verb. Bracketed DRS sketches below distinguish
referents and conditions; they are explanatory notation, not exporter JSON.

### C13a. Cardinality: count related witnesses, not a numeral property

**Evidence.** The existing FOLIO trace ledger in
[DESIGN](../DESIGN.md#5-observed-behavior-and-first-divergences) records
`folio-val-15`, “All squares have four sides”: a universal sides object with
`four(y)` was the diagnosed bad meaning. This is historical evidence, not a new
execution. FOLIO graded quantity `folio-val-25:premise:5` and currency comparison
`folio-val-93:premise:8` are separate source obligations in
[the input inventory](folio.md); *many*, money, years and measurements are not
automatically cardinal determiners.

**Unit 2.** A candidate numeral phrase can originate at `N/N + N → N`; ordinary
intersective `N/N` cannot supply counting semantics. A bounded cardinal
construction must retain the number and its modifier (`exactly`, `at least`)
until an object quantifier is built. An explicitly proposed internal phrase
`exactly two:NP/N` takes `books:N`, yielding NP; `has` applies forward to this NP,
then the named subject applies backward. This internal phrase category is a
proposed reanalysis, not a claim that those tokens already have that category.
A lexical-origin certificate would have to preserve their original categories,
spans and modifier. No multiword phrase filter is specified or implemented here.

**Unit 3: two worked authored controls.** Let

```
ATLEAST2 = λP R. ∃u v.(u≠v ∧ P(u) ∧ P(v) ∧ R(u) ∧ R(v))
EXACT2   = λP R. ∃u v.(u≠v ∧ P(u) ∧ P(v) ∧ R(u) ∧ R(v)
                      ∧ ∀z.((P(z) ∧ R(z)) → (z=u ∨ z=v)))
```

Both terms have type `p→q`. For *Mira has at least two books*, apply ATLEAST2
to `book`, the resulting NP to `has`, then `lift(mira)` to obtain the first
formula with `R=λy.have(mira,y)`. For *Mira has exactly two books*, the same
derivation uses EXACT2. Neither means that Mira has only two things, nor that
every book in the world belongs to Mira. Four expands to four pairwise-distinct
witnesses; exact four needs the corresponding exhaustive condition. Bare *four*
needs a declared exact-versus-at-least convention before source gold is admitted.

**Unit 4.** The positive at-least DRS is
`[u,v | book(u),book(v),have(m,u),have(m,v),¬[ | u=v]]`.
Exactness adds `[z | book(z),have(m,z)] ⇒ [ | z=u ∨ z=v]`.
At matrix level the existential commitments and possession predicates are
Asserted; inequality is an Asserted negated condition whose equality atom is
Embedded, not asserted equality. The exhaustiveness implication is an Asserted
compound; its antecedent conditions, consequent OR compound, and both equality
children of that OR are Embedded, not independently asserted. Under *Mira does
not have exactly two books*, the **whole** existential/counting box is inside
negation; no particular book witness is promoted. Under *All squares ...*, the
owner is bound in the implication antecedent and side witnesses remain in its
consequent; no unconditional square or side existence follows.

**Missing policy / first-divergence obligation.** Counting assumes countable
individuals, stable equality and a licensed have relation. Plural sums, mass
nouns, measures and collective possession are outside this small contract. The
historical `four(y)` error localizes an inappropriate numeral interpretation;
there is no fresh original derivation witness here. Future controls must verify
distinctness and witness scope, not only that a numeral survives printing.

### C13b. Compounds and nonintersective modifiers: N/N is not one meaning

**Evidence.** Existing C13 uses *football player* and *former president* as
illustrations; they are not newly verified benchmark locators. The residual
ProverQA frames in [proverqa-frames.md](proverqa-frames.md) separately retain
abstract nouns, idioms and light verbs; no compound coverage follows from a noun
or PP cue. Bos's compound example is primary-source methodological evidence,
not proof of an English benchmark entry's correct ontology.

**Units 2/3.** Proposed `football:N/N` followed by `player:N` gives N via forward
application, but `λP x.P(x)∧football(x)` wrongly makes the player a football.
A relation-parametric analysis is
`COMPOUND_R = λM P x.P(x) ∧ ∃y.(M(y) ∧ R(x,y)) : p→p→p`.
The grammar still needs an independently licensed R and appropriate noun senses;
the type cannot infer either. For *football player*, a sport-kind or activity
argument may be appropriate instead of an ordinary football object. No chosen
sport individual or playing relation is silently inserted here.

Three authored contrasts expose the choice:

- *wooden box*: under a declared material reading,
  `λP x.P(x)∧material(x,wood)` applied to box preserves box(x), without wood(x).
- *toy gun*: the modifier must not automatically retain gun(x); an imitation
  operator `TOY:p→p` needs a lexical/intensional contract. This is not an
  instance of COMPOUND_R if gun denotes only functional weapons.
- *former president*: `FORMER:p→p` requires a temporal interpretation, for
  example past satisfaction and present non-satisfaction under a declared time
  policy. Merely `former(x)∧president(x)` loses the contrast.

**Unit 4.** For an authored *Mira owns a wooden box*, under the stated material
and existential-indefinite reading, the proposed matrix DRS is
`[b | box(b),material(b,wood),own(mira,b)]`: these positive conditions are
Asserted. This is a complete extensional illustration, not an implementation
claim about *wooden*. The toy and former examples have **no approved complete
DRS/status contract** here: asserting gun(x) or president-now(x) would be an
unsupported strengthening. If a compound occurs under a universal restrictor,
its restrictions stay in that antecedent; they cannot become free matrix facts.
No new mismatch was measured; the first stage to inspect is lexical meaning
selection at N/N, before blaming combinatory typing.

### C13c. Possession and relational nouns: resolve the owner, preserve the head

**Evidence.** FOLIO `folio-val-106:premise:4` contains possession with
cross-sentence anaphora. ProofWriter's exact *His red cheeks glowed.* contributes
72 occurrences / one surface in the
[complete residual audit](proofwriter-residual.md#f3-possessive-plural-body-part-predication-721).
Its first-source context and per-world/bucket repetition are documented there;
a unique string does not imply one antecedent across all 72 occurrences.
No raw antecedent is reconstructed from the hidden controlled fact.

**Units 2/3.** Proposed `her:NP[nb]/N`, `red:N/N`, `cheeks:N`,
`glowed:S[dcl]\NP` compose the possessed NP before its predicate.
`POSSESS_a = λP R.R(ιx.(P(x)∧possessor(x,a))) : p→q`
is a **partial definite skeleton**, not a total existential approximation.
It requires resolved a, a licensed possession relation and a defined unique or
maximal referent. Cheeks requires plural/group semantics; past glow requires a
time policy. A relational head such as *father* may instead license
`fatherOf(x,a)`; do not replace every lexical relation by ownership.

Two authored singular illustrations isolate the dependencies:

1. In a discourse explicitly identifying one salient key k as belonging to
   Mira, *Her key is red* can resolve `her` to Mira and the definite to k.
   With this supplied context, `POSSESS_mira(key)(red)` gives `red(k)`.
2. Replace only the explicit owner/antecedent with Nora and its salient key j;
   the same surface now gives `red(j)`. The isolated sentence without resolving
   context has no complete definite/anaphoric interpretation in this contract.

**Unit 4.** In those contextual illustrations, existence, keyhood and the
possessor relation are resolved presuppositions (or already given context),
while `red(k)`/`red(j)` is the new Asserted predication. They are not red(mira)
or red(nora). This card does not authorize global accommodation or mark a
presupposition as oracle-confirmed. For the actual cheeks sentence, the required
plural referent C receives red/glow, not the human antecedent; the description's
projection, past time and plural distribution remain explicit missing policy.
No fresh Explain localization exists for this source. Inspect antecedent
resolution and referent identity as well as category composition.

### C13d. Causal and degree wording: retain the relation and scale

**Evidence.** ProofWriter has 20,248 outer `PW.NL.CAUSAL` occurrences / 335
strings; overlapping causal cues cover 23,910 / 407, and degree/comparative cues
74,818 / 1,215. These are distinct diagnostic denominators in
[CONSTRUCTIONS](../CONSTRUCTIONS.md), not verified semantic families. FOLIO's
quantity and currency locators above require scales and comparison standards.

**Units 2/3.** For postposed *P because Q*, a candidate
`because:(S\S)/S` consumes Q then P. A schematic intensional meaning is
`λB A.BECAUSE(effect=A,cause=B)`, with proposition-valued arguments in the selected world/event
model; a truth-functional `λB A.B→A` is not causal meaning. Direct `t` arguments
would identify truth-equivalent propositions and cannot by themselves recover
causal explanations. `very:(S[adj]\NP)/(S[adj]\NP)` can modify a predicative
adjective syntactically, but a scale-aware denotation requires a graded property
interface or lexical operator. Identity and unconditional extra unary *very*
are not adequate default meanings.

Authored diagnostic contrasts, **not complete gold**:

- *Mira left because Nora arrived* needs the two temporally interpreted contents
  plus explanatory/causal linkage, with argument direction preserved.
- *Mira did not leave because Nora arrived* has negation/causal-scope ambiguity;
  denying leaving and denying that arrival explains leaving must not collapse.
- *Mira is very tall* needs a contextual height standard and degree strengthening;
  *Mira is taller than Nora* needs both individuals and comparison on the same
  scale. Neither licenses deleting the modifier or comparison object.

**Unit 4.** No complete causal/degree export contract is admitted here.
Affirmative episodic because ordinarily presents both contents as actual, but
its causal relation and interaction with negation/questions must be represented
explicitly. Do not promote both clauses unconditionally under every embedding.
Likewise tall/very-tall entailments depend on the declared scale contract; a
well-typed opaque atom is not automatically a faithful DRS. First divergence
is unmeasured; lexical/operator selection, attachment and export all need checks.

### C13e. Reporting variants: do not use a cue as a claim-status rule

**Exact input evidence.** The reviewed blocked ledger at commit `801b9a8`,
`research/linguistics/proposals/proofwriter-natlang-attribution-blocked.json`,
records full file hashes, theory spans and mapped/presented context for:

| Exact source sentence | Source locator | Obligation |
|---|---|---|
| Alan is also said to be very kind. | `CWA/NatLang/meta-test.jsonl`, line 288, `AttNonegNatLang-CWA-161`, `sentences.sent1`, presented sentence 2 | Passive report source, additive presupposition and degree scope. |
| Bob is known to be rough and green. | `CWA/NatLang/meta-train.jsonl`, line 60, `AttNonegNatLang-CWA-1374`, `sentences.sent1` | Implicit knowledge holder and factive projection of both conjuncts. |
| A young someone is red in thought but green in ideas. | `CWA/NatLang/meta-train.jsonl`, line 149, `AttNonegNatLang-CWA-647`, `sentences.sent7` | Nominal thought in a PP, age/sortal meaning, metaphor and contrast. |

That ledger is a dependency for source verification; these are not three members
of one reporting family. The 32,684 attribution-cue occurrences / 487 strings
cannot be used as a count of Reported claims.

**Units 2/3.** Proposed `said/known:(S[pss]\NP)/(S[to]\NP)` takes an infinitival
property and shares its subject through a passive auxiliary. Alan/Bob is the
embedded subject, not the reporter/knower. No term is complete until the omitted
holder is specified: anonymous existential, generic community and contextual
source are different interpretations. `also` scopes over alternatives, and
`very` remains inside the reported content. Thought in *in thought* is an NP
complement of a preposition, not a propositional attitude verb.

**Unit 4.** Reported kindness must not become ordinary Asserted kindness.
Factive knowledge requires a matrix knowledge commitment distinct from the
complement's Presupposed status under the project convention; this is a future
passive contract, not an already implemented rule. No empty-holder convention is
approved. Neither rough nor green may disappear. The lexical thought example
licenses no Reported status merely from a word match. These exact sources remain
blocked before gold; replacing them with unmodified *Alan is kind* would sacrifice
fidelity for coverage. No parser divergence has been measured for these inputs.

### What the primary-source comparisons establish

[Bos 2008 §§2–3](https://aclanthology.org/W08-2222/) as summarized in
[REFERENCES](../REFERENCES.md) explicitly distinguishes adjective, numeral and
compound meanings despite shared N/N syntax; its compound illustration introduces
another referent/relation. Adopt that separation for C13a/b, not a universal
intersection fallback. Its construction-versus-anaphora/presupposition-resolution
boundary motivates C13c; event roles motivate preserving causal/report arguments,
but do not supply our missing causal, scale, holder or claim-admission contracts.
Its discussion of measures/shallow lexical readings and lack of semantic gold
precludes citing coverage as evidence these cards are exact. This is use of the
existing paper audit, not a new PDF verification or Boxer execution.

The pinned [ccg2lambda 2015 templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L20-L23)
use two NP predicate slots even for existential N-to-NP conversion. Their
[plural definite rule](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L65-L69)
uses a universal interpretation under its specified child conditions; that is
not our resolved maximal cheeks referent or a drop-in one-slot POSSESS term.
The paper's higher-order/modality treatment motivates typed operator boundaries,
not erasing scales or causes; footnote 4 excludes factive presupposition
projection, so it cannot validate C13e's missing passive-factive contract.
No matching numeral/compound/causal/degree implementation or fidelity guarantee
is claimed from these limited source comparisons. Adapt only after declaring the
NP/event/world interface and independently checking gold. None of these sources
licenses promoting reported/presupposed material into oracle-confirmed evidence.
