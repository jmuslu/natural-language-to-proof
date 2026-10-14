# Proposal: negation, conditionals and disjunction

Status: design for independent review; no production implementation in this change.
Owner: design-operators, branch `astra/design-operators`. This contributes to
[DESIGN.md](../DESIGN.md) and uses the frequencies in
[CONSTRUCTIONS.md](../CONSTRUCTIONS.md). The operator family is not disjoint from
names, predicates, relatives or coordination. A frequent *if* frame does not imply
that *if* itself is broken: its constituent predicates may already be wrong.

Read this as three linked exercises from [STUDY_PLAN](../../../STUDY_PLAN.md):
Unit 2 determines category, features and attachment; Unit 3 determines the typed
term; Unit 4 checks scope, reference accessibility and claim status. A category
below is an intended CCGbank-compatible analysis unless labelled observed. A new
category/reanalysis must be logged and tested; it is not evidence that the corpus
already licenses that tag for that token.

## 1. Typed interface and commitment convention

Let `P=e→t`, `Q=P→t`, `V=Q→t`, and `lift(a)=λP.P(a)`. The current interface maps
`N↦P`, `NP↦Q`, `S[dcl]↦t`, and `S[em]↦s→t`. Both slash directions have the same
function-type translation, but require arguments on different sides in a CCG
proof. The literal English semantics retains person/thing restrictions; removing
those restrictions for a controlled dataset is a separate domain policy.

A DRS `[x | C]` binds x in C. A main-box negation, implication or disjunction is
Asserted as a **whole condition**; its nested conditions are Embedded. No atoms
inside those operators become asserted premises. Reported and Presupposed are
empty in the simple extensional cases below. A quantified subject may bind a
witness outside an operator, but a witness introduced inside one disjunct or a
negated box cannot escape. Claim tables preserve binder context and multiplicity;
a top-level atom with a main-box existential reference is contextual, not a closed
oracle claim about a globally named `r0`.

## 2. Negation: scope the predicate without duplicating the subject

### Categories and derivation — Unit 2

For `Bob does not like the cat`:

```text
Bob: NP
does: (S[dcl]\NP)/(S[b]\NP)
not: (S\NP)\(S\NP)
like: (S[b]\NP)/NP
the: NP[nb]/N
cat: N
```

`the cat` combines by forward application. `like` consumes that object, giving
`S[b]\NP`. Negation and the auxiliary compose/apply with feature matching;
backward crossed composition may combine *does not* first. The final VP must
retain `[dcl]`. Backward application to Bob gives a sentence. Final punctuation
is structural. The precise selected tree is an observation, not part of this
proposal's acceptance criterion; equivalent licensed trees may share a meaning.

### Terms and scope — Unit 3

The auxiliary is `λV.V`. A transitive verb is
`λO Q.Q(λx.O(λy.like(x,y))) : Q→V`. Use the existing subject-wide VP negation:

```text
not = λV Q.Q(λx.¬V(lift(x))) : V→V
```

This gives `¬like(Bob,ιcat)` for the named example. It gives
`∃x(cat(x)∧¬sleep(x))` for `A cat does not sleep`, not
`¬∃x(cat(x)∧sleep(x))`. The distinction is substantive: one nonsleeping cat
suffices for the former, while the latter says no cat sleeps. Keep the existing
`scope` Decision and test both quantifier environments.

### Boxes and claims — Unit 4

```text
Bob does not like the cat:
[ | ¬[ | like(Bob,cat)]]
A = {¬[ | like(Bob,cat)]}; E = {like(Bob,cat)}

A cat does not sleep:
[x | cat(x), ¬[ | sleep(x)]]
A = {cat(x), ¬[ | sleep(x)]}; E = {sleep(x)}
```

The `cat` constant in the first case follows the project's explicitly stipulated
unique-name treatment of definite descriptions. In the second case x is a
reference, and the two asserted conditions depend on one shared witness.

**Proposed extension boundary:** lexical *never* is not automatically a timeless
`not`. The saved FOLIO failure turns it into a positive predicate, which is wrong;
replacing that with ordinary negation is only justified for a declared time-free
fragment. Literal never needs an event/time domain and quantification over relevant
occasions. Reserve unsupported logical modifiers against open-template fallback
without claiming an unsupported interpretation is solved.

**Required hand controls before a repair:** named negative transitive, existential
subject negative VP, universal subject negative VP. Add a positive near-neighbor
and an inner negation under an outer report to ensure no source/status leak.
These are proposed controls, not new observations or gold files in this commit.

## 3. Conditionals: direction and accessible antecedent referents

### Ground clauses

Fronted `if:(S/S)/S[dcl]` consumes antecedent p by `>`, producing a forward
sentence modifier that consumes consequent q. `then:S/S` contributes identity.
The closed term is `λp q.p→q : t→t→t`.

```text
If Bob is red then Bob is big:
if + red(Bob) → S/S: λq.red(Bob)→q
then + big(Bob) → S[dcl]: big(Bob)
forward application → red(Bob)→big(Bob)
```

Postposed `Bob is big if Bob is red` instead requires a backward sentence modifier:
`if:(S\S)/S[dcl]`. It consumes the right-hand antecedent p first and then the
left-hand consequent q. The term is still `λp q.p→q`; the direction of syntactic
application changes, not implication direction. Do not implement it as q→p merely
because the consequent precedes the connective in the surface string.

```text
[ | [ | red(Bob)] ⇒ [ | big(Bob)]]
A = {the implication}; E = {red(Bob), big(Bob)}
```

**Static gap:** the current closed table supplies only the fronted category.
This is static table evidence in `src/NL2Proof/Semantics/CCGSem.hs`,
not a completed postposed-if diagnostic. A new postposed meaning should reuse
the established term at its proper category, with directional controls and full
sentence diagnostics; category availability and meaning availability must be
checked separately.

### Indefinites and pronouns inside a rule

For `If someone is red and young then they are big`, the indefinite introduces a
referent into the antecedent box; a consequent pronoun can access it:

```text
[ | [x | person(x),red(x),young(x)] ⇒ [ | big(x)]]
A = {the implication}; E = {person(x),red(x),young(x),big(x)}
```

The truth condition is universal over assignments satisfying the antecedent. It
is not a globally universal lexical meaning for *someone*: the assertion
`Someone is red` still introduces an existential. A dynamic box constructor must
preserve this binder across the implication; writing a free x in the FOL term
`(∃x.person(x)∧red(x))→big(x)` does not implement that obligation.

Conjoined antecedent predicates must share the intended subject. Independent
indefinites such as `someone likes someone` must not collapse their witnesses.
Sortal person/thing conditions stay in strict English gold; a domain-adapted
ProofWriter score is reported separately.

### Connectives that must remain distinct

| Form, with proposition letters in surface order | Time-abstracted candidate meaning | Additional obligation |
| --- | --- | --- |
| `p if q` | q→p | Postposed category, reverse surface order |
| `p only if q` | p→q | Necessity, not sufficiency |
| `p if and only if q` | (p→q)∧(q→p) | Two top implication conditions |
| `p unless q` | ¬q→p | Weak material reading; exclusivity is not automatic |
| `when/whenever/once p, q` | Not automatically plain p→q | Temporal/generic force must be represented or explicitly abstracted |
| `q because p` | Not merely p→q | Causal relation and commitment of each clause need a separate analysis |

For material conditions, A contains the whole implication(s), while E contains
nested negative conditions and their descendants as appropriate. The table is a
specification of bounded readings, not implementation status. In particular the
material *unless* reading is not a license to flatten all NatLang paraphrases.

**Required controls:** fronted/postposed equivalent pair, only-if reversal, and an
antecedent existential with a consequent pronoun. Include negated/conjoined
antecedents before extending to a frequency-leading rule family.

## 4. Disjunction: distinguish inclusive OR, exclusion and correlative scope

### Categories and λ-terms

`or:conj` forms a coordinated constituent from category-compatible children. At
sentence type the semantic operation is `λp q.p∨q`. At VP type it is:

```text
λV W Q.Q(λx.V(lift(x))∨W(lift(x)))
```

This scopes one quantified subject over the alternatives. Applying each VP to the
subject independently could duplicate witnesses or change a quantified reading.
A correlative *either* marks the coordinated constituent; it must not introduce
an ordinary predicate `either(x)`.

A narrow useful proposal is to license documented correlative modifier categories
with identity meaning **only when paired with a licensed OR coordination**, and to
carry its actual constituent span into provenance/annotations. The 2015 source
supplies `(S\NP)/(S\NP)` and `N/N` identities, but these are not enough to claim a
sentence-initial pattern's derivation. Record the offered categories and candidate
whole derivation before adding a sentence modifier or reanalysis. Unconditional
identity for any token *either* would also erase determiner/choice uses.

The existing exporter identifies *either* by provenance leaves. Multiple OR nodes
sharing full-sentence provenance cause an ambiguity residual. Preserve that guard;
a new marker must attach to its own coordination constituent, not every OR in the
sentence. A marker records form/scope, not a universal English XOR truth condition.

### DRS and independent claim tables

Ordinary disjunction:

```text
Bob is red or Bob is big:
[ | ([ | red(Bob)] ∨ [ | big(Bob)])]
A = {OR}; E = {red(Bob),big(Bob)}
```

Explicit *but not both* adds a second condition:

```text
[ | ([ | red(Bob)] ∨ [ | big(Bob)]), ¬[ | red(Bob),big(Bob)]]
A = {OR, NOT}; E = {red(Bob),big(Bob),red(Bob),big(Bob)}
```

The repetition in E records the distinct scoped occurrences; the structural gold
must not deduplicate them. XOR is true in exactly the two mixed truth assignments.
Bare *mutually exclusive* expresses the NOT-conjunction condition without requiring
OR; it allows both false. *Neither p nor q* instead gives two top negations,
`¬[ | p]` and `¬[ | q]`, and is true only when both are false.

For a quantified restrictor `Everything that P or Q is R`, use:

```text
[ | [x | ([ | P(x)]∨[ | Q(x)])] ⇒ [ | R(x)]]
```

The x binder belongs to the antecedent outside the internal OR, so it is accessible
in the consequent. Introducing separate x binders inside the alternatives and
then referring to an unbound x in R is invalid. A contains the implication;
E includes the OR condition, P(x), Q(x), R(x) in traversal order.

### Surface wording versus ProverQA convention

The inventory includes *not necessarily both*, *not necessary that ... both*,
*mutually exclusive*, and explicit *not both*. Those are not synonyms. In
particular `¬□(p∧q)` does not imply `¬(p∧q)` in the actual world. Literal *not
necessarily both* therefore cannot be translated to XOR merely because the dataset
uses an exclusivity convention. Nor does plain *either ... or* universally entail
exclusivity in English.

Keep literal-surface fidelity separate from a declared dataset-convention score.
Annotate convention-dependent cases, preserve the mismatch and do not quietly
exclude them from the denominator. This is a gate-design issue requiring review:
a solver can perfectly satisfy benchmark labels while the English translation is
wrong. No labels/proofs may determine lexical logical force.

**Required controls:** inclusive p∨q with both true; explicit not-both with both
true; mutually-exclusive with both false; not-necessarily-both contrast; nested
multiple ORs with exactly one either marker. Three-way OR gold must state allowed
binary associations before parser inspection because the current structural
scorer preserves nesting.

## 5. Observed first divergences and limits

Root-approved hand diagnostic prediction was written before execution. The frozen
Explain binary SHA256 is
`701f94da16be317c070765c7002a8460e55497a41b48bf0bcfa5027deb84b07d`.
Ignored root artifacts: `research/runs/linguistics-design/input.txt`,
`explain.log`, `binary.sha256`, `explain-frozen`. The preexisting binary was copied
before execution; current source hashes do not establish its compiled snapshot.
The process finished with exit 0. No answer benchmark, solver or model was run.

| Input | Observed selected result | First divergence / interpretation |
| --- | --- | --- |
| `If Bob is red then Bob is big.` | red(Bob)→big(Bob); A implication, E its two atoms | No divergence for this ground control; fronted if category and λ-term are correct |
| `Bob does not like the cat.` | ¬like(Bob,cat); A negation, E atom | No divergence under declared definite convention; subject-wide negation Decision retained |
| `Bob is red and big.` | red(Bob)∧big(Bob) | No divergence for named-subject conjunction; does not test quantified witness sharing |
| `Either Bob is red or Bob is big.` | No semantic root; category-only grammar reaches S | Either's offered VP/NP modifier categories lack meanings; N/N/N open predicates survive. This is a lexical-semantic gap visible before final parse failure; possible search effects are not experimentally separated |
| `Everything that is red is big.` | ∀x(everything(x)∧red(x)→big(x)) | Everything receives N-property meaning instead of unrestricted quantified-pronoun meaning; not an implication-lowering failure |

Saved FOLIO evidence in [SEAMS](../../SEAMS.md) additionally has positive `never(x)`
in *A hawk never lands*. It is a historical trace, not a rerun against the frozen
binary. No new measurement was made here for postposed if, unless, only-if,
neither/nor, quantified VP negation or literal exclusivity paraphrases. Their
required tests remain review obligations. The observed ground controls cannot
justify a claim of full operator-family fidelity.

## 6. Primary-source decisions

[Bos 2008](https://aclanthology.org/W08-2222.pdf), §§2–3, supports compositional
λ-DRSs with nested negation/implication/disjunction and antecedent accessibility.
**Adopt** operator boxes and category/type versus lexical-meaning separation.
**Adapt** event treatment if needed for temporal never. **Reject** any inference
from reported parse coverage to independently validated English fidelity; the
paper's discussion explicitly lacks semantic gold and records shallow analyses.

[Mineshima et al. 2015](https://aclanthology.org/D15-1244.pdf), §2/Fig.3, supports
an additional NP restriction slot for CCGbank post-NP modifiers. **Adapt** that
architecture only coherently across the interface; it is not a local OR-rule
patch. **Adopt** barriers against actual-world inference from modal/attitude
contexts. **Reject** flattening their complement because a bounded evaluator
lacks modal representation.

Pinned [2015 English YAML](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml)
provides directly inspectable decisions: lines 468–480 scope not/never below the
subject; lines 589–591 give fronted if; lines 609–617 make selected either
categories identity. **Adapt** these individually with local types and scope
licensing. **Reject** the sentence-or entry at lines 102–106, which uses conjunction,
and reject copying the when-as-if abstraction without declaring its limits.
The [event YAML](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_event.yaml#L1518-L1521)
instead scopes never outside the subject and comments the alternative. These two
choices differ for quantifiers; publication does not decide our gold. See the
existing [comparison](../TEMPLATE_COMPARISON.md) and [references](../REFERENCES.md)
for full source context. Neither upstream system was installed or run.

## 7. Review gate and implementation recommendation

Review this proposal before any source edits. First establish independent operator
gold covering scope/direction contrasts, then prioritize failing subconstruction
frequencies from the inventory. Preserve working fronted-if and VP-not rules;
repair closed-class availability and correlative scope with the smallest coherent
rule. Do not add sentence-specific ProverQA mappings or convert literal modal
wording into XOR to improve label agreement.

After each approved change, score full selected DRS plus independently authored
claim table: exact, wrong-but-typed, no-parse, with technical/incomplete outcomes
still in the denominator. Report any-reading exact separately and inspect wrong
retained alternatives. An exact ground example must not conceal untested dynamic
binding or quantifier scope. The ProverQA ≥90% exact / near-zero wrong-but-typed
resume gate remains unproven by this proposal.

## 8. Independent gold crosswalk at recovery

This is a read-only comparison with transferred hand gold, not a parse score or
an authorization to adjust gold to match the implementation. The gold authors
own those files; reviewer approval and integrated gates are still required.

| Gold IDs / family | What this proposal must preserve | Remaining test gap |
| --- | --- | --- |
| Prover `subject_do-1/2` | Named VP negation: top NOT, nested work atom | Existential/universal subject scope controls |
| Prover `conditional_initial-1/2` | Antecedent indefinite accessibility; named he reference | Ground-if success does not establish either anaphora case |
| Prover `conditional_final-1/2` | Surface consequent precedes antecedent; implication direction remains antecedent→consequent | Closed entry and pronoun binding both need evaluation |
| Prover `vp_either_or-1/2` | Inclusive structural OR plus a scoped either marker | No explicit NOT-both may be invented from dataset convention |
| Prover `sentence_either_or-1/2` | Explicit NOT-both is a second asserted condition; repeated embedded atoms retained | Marker attachment and elliptical predicate coordination |
| FOLIO `some-not-1/2` | One existential witness outside NOT | Negative nominal copula shares witness; no universal strengthening |
| FOLIO `or-1/2` | Inclusive predicate OR, invariant to predicate ordering in truth conditions | Structural order is still preserved by the scorer |
| ProofWriter `pw-cond-generic-1/2`, `pw-cond-generic-coord-1/2` | Accessible antecedent witness, shared across conjoined properties | Preserve unrestricted something under the documented fragment convention; explicit people/things sortals remain distinct; pronoun accessibility still needs validation |
| Pronto `pronto-restrict-or-1/2` | Restrictor OR stays inside universal antecedent | Everything lexical meaning and relative attachment are separate earlier seams |
| Pronto `pronto-ground-or-1/2/3` | Three alternatives share the named subject | Review accepted structural associations independently of parser ranking |

The transferred sets do not yet cover only-if, unless, neither/nor, modal
not-necessarily-both, or nested multiple either/OR attachment. Keep those listed
as missing coverage, never as passed cases. Predictions for future repairs belong
in the coordinator's LOG before execution. No new fidelity run was launched by
this specialist; this crosswalk checks intended meanings, not observed accuracy.
