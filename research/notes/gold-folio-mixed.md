# FOLIO restrictive-negative and mixed-predicate gold

2026-10-14 full-access shell verified in assigned clean gold-folio-mixed worktree.
Read audited120sample inventory and existing FOLIO/extended fixture texts to avoid
duplication. Prediction before input inspection: source relative-negative wording
exists but tense/number/subsective/definite issues may require explicitly labelled
adaptations; mixed lexical/copular VP cases may likewise need bounded adaptations.
No parser, output-fitted gold, labels/formulas/proofs, model or benchmark launches.
Own JSONL and these notes only; strict-English semantics_contract on every row.

## Input attestation and adaptation boundary

Five rows authored:3 FOLIO.RELATIVE.NEGATIVE.RESTRICTOR and2
FOLIO.MIXED.LEXICAL.COPULAR.VP. Four distinct input locations verified directly:
folio-val-74 context index1 (plates); folio-val-84 context index2 (restaurants);
folio-val-197 statement (KiKi); folio-val-77 statement (Mary). Only KiKi is an
unchanged source sentence. All changes are explicit in each origin. The No case
is a constructed quantifier contrast from the same restaurant source as Some,
not a third independent corpus occurrence. Neither source labels nor supplied
formulas were accessed. An exploratory read assumed a question key and raised
KeyError; the existing inventory establishes statement as the query field, which
all final locators correctly use.

The plates source has bare-plural generic force, begin-with a numbered expression,
and location predication; the restaurant source has take-out service and many
negative reviews. Their adapted wording deliberately isolates restrictive relative
negation and quantifier scope; it does not recover those removed meanings or count
them as supported. The Mary source adds a picky-eater nominal, vague temporal
quantity, eating/catching-up coordination, a reciprocal/social idiom, friends and
campus location. Replacing it with a short predicate pair is explicitly a scope
diagnostic, not faithful translation of that full sentence. No subsective nominal
is treated as adjective intersection. The audited nested mountain-range relative
remains outside this file: passive donation, location, multiple restrictors and
number/definiteness need separate gold rather than silent flattening.

Every row declares semantics_contract strict-English for the **displayed wording**,
not the unmodified source. Do not silently pool with historical controlled-domain
fixtures or use diagnostic adaptations as a population estimator. These five
cases close narrow scope-control gaps, not the heterogeneous FOLIO relative or
mixed-coordination inventory. They do not satisfy 2–3 independent natural source
sentences for every new quantifier/polarity joint profile.

## Unit2 categories and derivations

Restrictive that is licensed at `(N\N)/(S[dcl]\NP)`, with the current bounded
CCGbank NP-relative→N-relative reanalysis kept explicit. Plural common head nouns
have N category; All/Some/No take NP[nb]/N. A lexical base glow has S[b]\NP;
do-support do:(S[dcl]\NP)/(S[b]\NP) and not produce a negative clause with
one subject gap. That attaches it to the noun **before** the determiner. The
matrix are not red or are quiet then consumes the quantified NP.

No generic NP-level conjunction of a relative with a completed GQ is allowed:
for All it would move the restriction into the consequent. Object gaps,
nonrestrictive relatives and degree/PP meanings are not asserted to be solved.

In the mixed cases, barks/eats:S[dcl]\NP; is:(S[dcl]\NP)/NP for nominal
predication or (S[dcl]\NP)/(S[adj]\NP) for an adjective. Predicative a dog
uses the reviewed nominal-copula convention, with a:NP[nb]/N and dog:N; it
classifies the existing subject. Both completed VPs share S[dcl]\NP for
coordination. NP constants KiKi/Mary are supplied only after composing the VPs.
The inverted order of the Mary pair prevents treating every post-and fragment as
another adjective; its not is local to the copular conjunct in the declared
unmarked reading. These are proposed semantic-category analyses, not observed
parser derivations for this gold file.

## Unit3 terms and Unit4 independent DRS/claim judgments

Let q=(e→t)→t and lift(x)=λP.P(x). The restrictive relative means
λV N x.N(x)∧V(lift(x)) : (q→t)→(e→t)→e→t. Negative glow is
λQ.Q(λx.¬glow(x)) : q→t. All is universal implication, Some existential
conjunction, and No negated existential. These three scopes yield:

- All: ∀x((plate(x)∧¬glow(x))→¬red(x)). DRS root has only the implication;
  its left universe binds x, and both negative boxes and their bodies are Embedded.
- Some: ∃x(restaurant(x)∧¬glow(x)∧quiet(x)). Root universe binds x;
  restaurant, the negative glow box and quiet are Asserted; positive glow Embedded.
- No: ¬∃x(restaurant(x)∧¬glow(x)∧quiet(x)). Root universe empty;
  only the outer negated box Asserted, with the negative-relative box itself
  Embedded alongside all predicates. Do not collapse this into universal
  ¬restaurant or pull the inner negation to the matrix.

There is one x in each description. The inner negative box does not introduce a
second restaurant or plate; its x is bound by the description's containing box.
All's antecedent referent is accessible in its consequent but not the root.

Mixed VP coordination is
λQ.Q(λx.V(lift(x))∧W(lift(x))) : q→t. Thus KiKi gives
bark(KiKi)∧dog(KiKi), and Mary gives ¬quiet(Mary)∧eat(Mary). Predicate a dog
introduces no additional individual or equality. Both top-level KiKi atoms are
Asserted. Mary's negative box and eat atom are Asserted; quiet is Embedded.
No Reported or Presupposed entries occur. The natural-language Mary source can
support richer contextual scope/prosody; this adapted diagnostic declares local
negation and makes no claim that every possible coordination utterance has only
that reading. No parser result was inspected to select allowed readings.

Gold claim arrays were explicitly enumerated according to these judgments,
including negative-box nodes in Embedded traversal; production claimsOfDRS was
not called. Structural helper code wrote the declared terms without computing
claims from the DRS. Plural common nouns use singular lexical predicate lemmas,
consistent with the reviewed FOLIO universal fragment; number is not used to
invent existential commitments for All/No.

## Primary-source comparison

[Bos2008 §§2–3](https://aclanthology.org/W08-2222.pdf) motivates composition into
scoped DRSs and independent accessibility resolution. Adopt scoped negation and
shared arguments; adapt the event/role representation to this declared direct
unary fragment. A coverage claim about Boxer supplies neither these gold meanings
nor evidence that a discarded PP/cardinality/passive construction is understood.

[Mineshima et al.2015 §2/Fig3](https://aclanthology.org/D15-1244.pdf) uses the
extra NP restriction interface needed for CCGbank's NP-attaching relatives. Adapt
that principle coherently: this project's bounded N-level attachment preserves
restriction without pretending the NP types are identical. The pinned
[ccg2lambda2015 templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml)
provide relative and shared-subject VP conjunction comparison points. Adopt shared
binding and reject independent witnesses or all-restrictor properties moved to
nuclear scope. No upstream system was run; existing REFERENCES.md documents the
source inspection, and these meanings were hand-specified from input English.

## Static validation

Four source text assertions pass, five rows validate via validate_case (schema,
reference accessibility, claims shapes and empty disjunction annotations), and
no text duplicates existing folio.jsonl/folio-extended.jsonl. All explicit contract
metadata agree. No parser/evaluator/CCGbank loader ran. git diff --check passes.
Reviewer must approve the narrow semantic contract and adaptations before merge.
