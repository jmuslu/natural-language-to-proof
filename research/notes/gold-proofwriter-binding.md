# ProofWriter conditional binding gold

2026-10-14 full-access shell confirmed; clean assigned worktree/branch. Read
FIDELITY_COVERAGE, fidelity README/schema, and existing ProofWriter convention
notes. Author six input-derived controls, three someone/they adjective rules and
three relational rules. Prediction before source inspection: saved110-file
text-only inventory contains explicit if-someone antecedents with they-consequents
and relation arguments, not root existential assertions. No parser observations,
labels, hidden formulas, proofs, model or benchmark runs. Own JSONL and notes only.

## Scope and source evidence

Six rows now authored:3 PW.COND.SOMEONE.THEY and3 PW.COND.RELATIONAL.BINDING.
The first three are unchanged source rules; the relational three consistently
replace definite animal NPs by Mira/Nora, explicitly excluding definiteness from
coverage. Relation2 retains negation and same object; relation3 retains a named
subject in a second antecedent clause so a latest-mentioned-name heuristic cannot
silently replace the generic subject. This is compact diagnostic gold, not a
probability sample or a population fidelity estimate.

All6 stored source file/line/id/rules.ruleN.text references were read directly and
matched exactly before adaptation. Rule role and explicit if...then text establish
the controlled exceptionless rule context; no label, hidden representation or
proof was inspected. One original record supplies a theory field, whose literal
membership also matches. The other5 staged/abductive records omit theory; their
presented rules[*].text are authoritative inputs. Initial verification incorrectly
assumed every record had theory and raised KeyError before any file was written;
revised check preserves this real schema distinction rather than manufacturing
context. The rule's input slot is not a hidden logical interpretation.

## Independent meaning decisions (Units2/3/4)

Use q=(e→t)→t. Unit2 categories: someone:NP;
is:(S[dcl]\NP)/(S[adj]\NP); they:NP; are the corresponding copula;
if:(S/S)/S[dcl]; then:S/S. Adjective coordination combines compatible predicates;
it is not NP coordination of separate people. Relational chases:(S[dcl]\NP)/NP
and bare chase/like/visit:(S[b]\NP)/NP retain subject/object order.
Do-support does/do supplies its licensed finite feature, and not scopes over the
VP. Singular they may pair with plural-shaped are/do morphologically; its resolved
semantic referent remains the one antecedent person, not a newly introduced group.

Unit3 someone is λP.∃x(person(x)∧P(x)): existential lexical force, not a universal
pronoun. The conditional is λA B.A→B; then is identity. They supplies a pronoun
placeholder resolved only under DRT accessibility, not a globally fixed name.
Transitives are λO S.S(λx.O(λy.R(x,y))). All names retain written case.
Conjoined predicates share x. Source someone retains the strict person restriction
as specified in DESIGN and existing Prover nested gold; do not erase it to imitate
an unrestricted synthetic domain adapter. No claim is made that a benchmark's
hidden entity ontology enforces this natural-language restriction.

Unit4 DRS antecedent [x|person(x),...], consequent [|...x...] yields the generic
rule reading: for every assignment making the antecedent true, its consequent
must hold. It does not assert that someone exists, assert the antecedent, or let x
escape to the root universe. This resolves the apparent existential/generic
contrast without changing someone lexically. Under negated consequents, the
negative box is inside the implication; both it and its positive body are Embedded.
Only the whole implication is Asserted, with no Reported or Presupposed entries.
All claim tables were specified explicitly from those judgments; no production
claim splitter or parser supplied them. Shared serialization helpers merely avoid
copying literal condition dictionaries and do not compute a claim traversal.

The three relational cases are, in conventional notation:
∀x(person(x)∧chase(x,Mira) → chase(x,Nora));
∀x(person(x)∧chase(x,Mira) → ¬like(x,Mira));
∀x(person(x)∧chase(x,Mira)∧chase(Mira,Nora) → visit(x,Nora)).
In the last, Mira is a distractor matrix subject but not the antecedent of generic
they. No new existential is introduced by either name.

## Boxer / ccg2lambda comparison

[Bos2008 §§2–3](https://aclanthology.org/W08-2222.pdf) separates semantic
construction and anaphora resolution and represents implication through scoped
DRSs. Adopt antecedent-to-consequent accessibility and separate construction from
resolution. Adapt event-role representations to this declared direct-predicate
fragment; no Boxer executable result or gold claim is inferred from its coverage.
Reject promoting an antecedent variable or predicate to a main-box assertion.

[Mineshima et al.2015 §2/Fig3](https://aclanthology.org/D15-1244.pdf) gives a
richer two-slot NP interface; the pinned [2015 English templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml)
include explicit implication for if and shared-subject VP coordination. Adopt
compositional implication and shared binders, adapt to the project's one-slot q and
DRT accessibility, and reject treating copied templates or fresh existential
consequents as independent gold. Upstream systems were not run. REFERENCES.md
records the existing primary-source inspection.

## Validation

Static validation contract: all6 meanings satisfy JSON/schema/ref scope,
and r0 appears only in the antecedent universe with consequent accessibility.
Ran validate_case only (not fidelity.run/evaluate/parser) and extra authored
binder-placement/asserted-implication checks:6/6 pass. All6 input locator checks
pass. No disjunction occurs, so every reading explicitly includes disjunctions:[];
no modal/definite-description claims are hidden by these adaptations. git diff
--check passes. Reviewer must independently approve before coordinator integration.
