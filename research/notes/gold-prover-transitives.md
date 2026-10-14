# ProverQA transitive, possessive and negative nominal gold

2026-10-14. Shell/pwd and branch verified in the isolated full-access worktree
`gold-prover-transitives`, branch `astra/gold-prover-transitives`. Own only this
note and `test/fidelity/proverqa-transitives.jsonl`; no shared files edited.

## Prediction before checks

Predict nine authored rows (three per construction) pass structural scope/claim
schema and input-only locator checks. This predicts format consistency, not parser
accuracy. Author meanings solely from isolated English inputs in the root ignored
`research/runs/linguistics/other-refresh/proverqa-unique.jsonl`; no parser outputs,
labels, hidden formulas, proofs or model calls consulted. No parser experiment.
Every row preserves its exact source wording. The source cache index is zero-based
within its extracted theory sentences or query; role-to-field mapping is explicit.

## Intended meanings and scope

Negative transitives select the ordinary nonspecific indefinite reading:
`Anne does not lead a project` is NOT `[x | project(x),lead(Anne,x)]`.
The relation has two ordered arguments; the object witness is bound INSIDE NOT.
Only the entire NOT condition is Asserted. Noun and relation are Embedded;
Reported and Presupposed are empty. Specific/wide-scope indefinite readings and
contextual reference are outside this diagnostic fragment, not proven impossible.
Charles's negative-have row connects this scope check to possessive have without
turning have into an auxiliary or collapsing it into its object noun.

Positive possessive have binds a root witness: `Clay has a beard` gives
`[x | beard(x),have(Clay,x)]`. Both conditions are Asserted in that shared context.
The same witness fills the second argument; the first is the rigid written name.
No ownership relation stronger than lexical have is inferred. Body-part stinger,
beard and proboscis objects are concrete count nouns; abstract possession,
inalienability and light-verb paraphrases remain outside these cases.

Negative predicative nominals directly classify the subject under negation:
`Nora is not a dancer` gives NOT `[ | dancer(Nora)]`. Do not introduce a second
individual, identity claim or an asserted existence condition. Only NOT is
Asserted, its classifier Embedded. Lexical negation in words such as nonconformist
is deliberately not conflated with sentential not. All examples use explicit not.

Noun predicates precede their associated binary relations, following the declared
canonical convention. Root/embedded universes and independently written claim
lists are mandatory. No OR occurs, so disjunction marker lists are explicitly empty.

## Units 2, 3 and 4

Unit2: intended CCGbank-compatible categories, not a claim of observed tags:
name NP; does `(S[dcl]\NP)/(S[b]\NP)`; not `(S\NP)\(S\NP)`;
lead/receive/have `(S[b]\NP)/NP`; has `(S[dcl]\NP)/NP`; a/an `NP[nb]/N`;
project/award/pet/beard/stinger/proboscis N. Article consumes noun, verb consumes
object, negation combines at VP, auxiliary restores declarative feature, and
subject backward-applies. Punctuation is structural.

Unit3: let p=e→t, q=p→t, lift(a)=λP.P(a), V=q→t. Indefinite
`λN P.∃y(N(y)∧P(y))`; transitive `λO Q.Q(λx.O(λy.R(x,y)))`;
VP not `λV Q.Q(λx.¬V(lift(x)))`; auxiliary identity. Composing them yields
`¬∃y(project(y)∧lead(Anne,y))`, preserving argument order and scope.
Possessive has uses the same binary template with lexical lemma have, not ha.

For nominal predication, the syntactic NP complement must receive its property
interpretation in copular context. Intended standard category is
`is:(S[dcl]\NP)/NP`; semantic obligation is predication `λP Q.Q(P)` after
licensed predicative-NP interpretation, not a universal identity meaning for
all articles. Gold requires a licensed lexical predicative interpretation before DRS construction.
Static truth equivalence with an existential identity analysis does not authorize
global equality contraction or removal of alias/discourse witnesses. This is a design obligation,
not a claim that an arbitrary NP has a recoverable property or that the current
parser realizes this derivation. Negation then scopes over that subject property.

Unit4 checks binder accessibility and claim classification independently of term
typing. A typed term that leaks the project witness or asserts lead is wrong.
No nested atom is separately confirmable merely because the whole NOT is asserted.

## Boxer / ccg2lambda comparison

Following [Bos2008](https://aclanthology.org/W08-2222/), adopt compositional lexical
meaning plus scoped DRS construction and keep resolution distinct. Adapt the
binary predicate diagnostic to this project's declared extensional fragment;
Boxer's event/role machinery is not automatically equivalent to our binary JSON.
No tense/event coverage claim follows from these time-abstracted gold readings.

The pinned [ccg2lambda2015 English templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml)
use continuation-sensitive negation and a richer NP restriction interface. Adopt
subject-wide VP negation and preserve the object restriction inside its scope;
adapt their two-slot NP types coherently rather than paste terms into one-slot q.
Reject treating well-typed output or upstream coverage as independent fidelity
proof. See the already-audited `research/linguistics/REFERENCES.md` and operator/
quantifier proposals for source details; neither upstream system was executed.

## Coverage limits

These nine intentional acceptance cases address three missing obligations in
FIDELITY_COVERAGE. They are not a random sample, a new answer benchmark, an estimate
of construction frequency, or evidence that the >=90% gate is met. No current
Explain/first-divergence claim is available until reviewer-approved measurement.
Source-only schema validation cannot establish parser behavior. Reviewer approval
must precede coordinator integration and any parse scoring.

Checks: all9 schemas pass (three per family); all9 exact source text, file/item,
field and zero-based sentence locators match the input-only cache. No texts duplicate
existing worktree fidelity fixtures. Independently specified claim lists contain
only the expected scoped atoms/operators; no production claim traversal supplied
them. Prediction held for schema/locator consistency; parser fidelity unmeasured.
