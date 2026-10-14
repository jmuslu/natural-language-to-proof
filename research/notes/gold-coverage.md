# Independent gold coverage audit (2026-10-14)

Scope: static audit of English fixtures and their independently written meanings;
no parser, corpus load, solver, answer benchmark or model was run. Full-access
shell reads succeeded. The coordinator owns integration and release gates.
This note adds no semantic expectations derived from system outputs or labels.

Snapshot: root `astra/research` at `d88b1e5`; reviewed gold commits
`7331468` (ProofWriter), `43ac355` (ProverQA), `169165e` (FOLIO).
Counts below describe files visible in root at audit time, including explicitly
transferred work; they do not assert all those files were committed on that head.
Inventory evidence is the specialist sections on `astra/inventory-proverqa`
(`b6278c2`), `astra/inventory-proofwriter` (`4f14434`), and
`astra/inventory-folio` (`634bc10`). The ProntoQA specialist inventory remains
pending; no complete ProntoQA denominator is inferred from its existing gold.

## Minimum counts versus semantic coverage

| Benchmark | Cases | Named gold groups | Groups with at least two | What this establishes |
|---|---:|---:|---:|---|
| ProverQA | 24 | 12 | 12 | Two diagnostics per selected outer bucket; not two per nested construction |
| ProofWriter | 24 | 12 | 12 | Controlled-fragment families, with some original definite NPs adapted to names |
| ProntoQA | 25 | 11 | 11 | Selected nominal, universal and coordination/relative cases |
| FOLIO | 12 | 6 | 6 | Five sample-derived groups plus one wholly authored speech-control group |

These 85 cases are not 85 independent construction observations. Two FOLIO
speech controls are not benchmark-derived, and substitutions/simplifications
have their own explicit provenance. At least two cases bearing a family string
is a necessary bookkeeping check, not proof of the requested 2–3 cases per
semantic construction. Nor do these counts measure exact/wrong-but-typed/no-parse:
that requires the independently reviewed runner and actual parser observations.

Status vocabulary below: **bounded** means a stated reading has at least two
fixtures; **thin** means a relevant contrast has fewer than two independent
instances; **missing** means no appropriate fixture; **contract** means a
representation/reading decision must precede trustworthy canonical gold.

## Cross-benchmark construction matrix

| Construction and scope | ProverQA | ProofWriter | ProntoQA | FOLIO |
|---|---|---|---|---|
| Name + unary adjective | Bounded, simple names | Bounded | Bounded | Only inside other groups; no dedicated pair |
| Predicative a/an + noun, no identity witness | Missing dedicated pair (one mixed either case) | Bounded positive and negative | Bounded positive and negative | Missing dedicated pair |
| Lexical intransitive vs true transitive argument order | Intransitive bounded; transitive universal only one | Transitive positive/negative bounded; plain atomic intransitives inventory zero | Missing relation gold | Possessive child relation bounded, not arbitrary verbs |
| Multiword/titled name; possessive nominal subject | Missing | Missing; definite animals were adapted away | Missing | Missing |
| Ground do-negation | Bounded intransitive only | Bounded transitive | Missing | Missing |
| Initial/final ground if; pronoun identity | One initial name-pronoun case; final bounded | Initial bounded but repeated names; no final cases | Missing | Missing |
| Generic conditional binder shared into consequent | One initial cat/it case (thin) | Bounded something/it; someone/they missing | Missing | Missing |
| Conditional + conjunctive antecedent, negation and relational arguments | Missing | Conjunctive adjective cases bounded; one negative conjunct; relations missing | Missing | Missing |
| Conditional + inclusive OR or explicit XOR consequent | Missing | Missing | Missing | Missing |
| Every/all/each restriction versus consequent | Two Prover universal rows have different constructions (transitive, modified copular): thin for each | Bounded all + modified sortal; bare generics bounded | Every/each/bare bounded | Missing |
| Subject relative restrictor versus consequent; object-gap contrast | Missing despite quantified-pronoun bucket | Missing despite large NatLang relative bucket | Bounded subject relative with conjunctive/disjunctive restrictors; object-gap missing | Missing |
| Existential subject and negation scope | Positive singular indefinite bounded under declared episodic reading; negative missing | Missing | Missing | Bounded some and some-not; no bounded not-some contrast |
| No N / negative existential; nested relative under no | Missing | Missing | Missing | Simple no bounded; nested missing |
| Inclusive OR, explicit not-both, hedged not-necessarily-both | Simple either and explicit XOR bounded separately; hedge contract/missing | Missing | Three-way ordinary OR bounded; explicit XOR missing | Ordinary OR bounded; either/neither missing |
| Same-witness conjunction by category: N/NP/VP/S | Missing dedicated pairs | Antecedent adjective/S patterns bounded; other levels missing | Nominal predicate and universal consequent bounded | Missing; mixed lexical/copular VP coordination needed |
| Reflexive local binding; distractor/embedded subject | Missing | Repeated-name object is not a reflexive test | Missing | Missing |
| Particle versus directional/argument PP; separated particle | Missing | Missing | Missing | Missing |
| Passive, reduced passive relative; gerund versus proper name | Missing/contract | Missing/contract | Missing | Missing/contract |
| Attribution/factivity: reported versus presupposed, never asserted complement | Missing | Missing | Missing | Authored say pair only; no sample-derived attitude/factive pair |
| Modality, habituality, temporal recurrence, mass nouns | Contract | Contract | No completeness evidence | Contract |
| Cardinality/only/biconditional/definiteness discourse | Missing/contract | Definiteness missing/contract | Missing | Missing/contract |
| Punctuation: lists versus attribution/nonrestrictive/fragment | Missing | Comma adjectival lists only | Three-way list OR bounded | Missing |

A matrix cell never transfers coverage from another benchmark automatically.
Shared general rules may pass shared controls, but input provenance, actual
lexical frame and interpretation must still match the target construction.

## Frequency-led next independent groups

1. **ProverQA initial conditionals and binding.** The inventory has 5,279
   initial-if occurrences; 2,836 contain an explicit not-both cue, 5,160 a
   he/she/they cue, and 455 match if-someone/anyone/somebody/anybody. These overlap
   and are not semantic counts. Author 2–3 input-derived cases each for named
   pronoun binding, indefinite antecedent binding, inclusive disjunctive
   consequent, and explicit XOR consequent. Preserve implication scope and the
   full exclusion conjunction; no branch atom is Asserted. Inspect English to
   distinguish genuine binding from incidental pronouns before assigning groups.
2. **ProverQA relative restriction and lexical arity.** 959 quantified-pronoun
   plus who cues currently have no relative gold. Add subject-relative cases
   with negation/coordination contrast, then separately attest object relatives.
   The 3,791 residual outer occurrences cannot inherit the two matures controls:
   split actual transitive, PP, particle and name frames by English inspection.
   Copula+a/an occurs 1,180 times, including 654 inside initial-if; add a nominal
   predicate pair and a conditional nominal pair without introducing identity.
3. **ProofWriter retained NP and relational binding.** Positive transitive
   family frequency is 2,162,712; generic conditionals are 1,001,985 and generic
   coordinated conditionals 915,052. Existing adjective-only generic controls
   miss relational argument sharing and someone/they. Add those groups after
   agreeing human-sort restrictions. Recover original definite animal NPs as a
   distinct gold group; proper-name substitutions do not validate definiteness.
4. **ProofWriter NatLang and FOLIO relatives/coordination.** ProofWriter relative
   outer bucket has 102,260 occurrences and coordination 91,240; FOLIO has 83
   relative cues and 85 and-cues, not complete construction counts. Prioritize
   independently identified restrictive relatives, mixed VP coordination and
   negation scope. FOLIO `folio-val-74:premise:1` identifies relative+negation;
   `folio-val-197:query:0` identifies mixed VP coordination. Inspect only English
   and locate a second appropriate example rather than treating duplicate input
   occurrences as additional gold coverage.
5. **Protection against assertion promotion.** ProofWriter attribution has
   32,684 cue occurrences; ProverQA broad attitude/report cue count is 406.
   Add independent explicit speech, belief and factive contrasts after examining
   their English. The FOLIO say controls are useful cross-benchmark regression
   checks but establish no FOLIO attitude frequency. Extend beyond these to
   infinitival desire/control only after the contract is settled.
6. **Lower-frequency but distinct bindings.** ProverQA reflexive cues number
   117 and narrow give-up candidates eight; ProofWriter reflexive cues number
   1,564. Author named/universal local-binding contrasts and particle/PP contrasts
   from attested English, then distracting-subject negatives. Do not replace a
   reflexive by a repeated name and call the construction tested.

Frequency order remains provisional where only lexical cues exist. Raw cue
counts cannot choose an implementation without the finer input audit; no large
bucket may be marked covered by a small convenient subclass.

## Contracts that must not be guessed to fill gold

- **Can/might/allowed and not necessarily both:** the canonical modal operator
  is absent. Ability does not assert the action; failure of necessity is not
  negated conjunction. Neither ordinary attitude-source encoding nor a silently
  flattened can_fly atom supplies strict modal semantics. Keep these accounted
  for as missing/unsupported; do not remove them from the gate denominator.
- **Temporal never, once a day, habitual frequency:** require event/time scope.
  FOLIO never and recurrence examples are not covered by ordinary negation or
  at-least-one-individual controls.
- **Passives, reduced relatives, S[ng] and infinitival control:** specify role
  preservation, unexpressed agents, event/aspect abstraction and attitude
  barriers. An ontology choice is not permission to drop semantic participants.
- **Definites, bare generics, everyone and mass nouns:** declare uniqueness,
  presupposition/domain and kind/mereology conventions. Existing everyone gold
  uses a domain-wide diagnostic convention; ProofWriter people/things gold
  retains sortal restrictions. Those choices cannot silently migrate between
  constructions or erase a disagreement with the English.
- **Numerals, scalar comparisons, many and only:** distinguish explicit
  distinctness/cardinality from opaque entity constants and arbitrary adjective
  intersection. Some cardinality is representable with equality; schema capacity
  alone does not establish the intended interpretation.

## Review and gate checklist

Use the existing `TEMPLATE_COMPARISON.md` as a proposal-review crosswalk, not as
independent truth: determiners and shared-subject coordination need scoped
meaning; ccg2lambda NP* relative entries cannot be pasted into the current Q
interface; the cited sentence-or conjunction and flat-modal templates are
counterexamples to copying published templates unchecked. Boxer distinctions
between semantic resolution, modification and construction roles motivate
separate gold rather than validating an unexamined output. The independent
reviewer should check each new branch against those source comparisons and its
hand-specified DRS/claim tables before implementation or integration.

For each validated construction retain 2–3 distinct English cases and record
category/derivation, Montague template, intended scope and claim statuses. Add a
positive instance, a meaningful scope/binding contrast and, where appropriate,
a blocking neighbor. State every adaptation; stripped complexity stays missing.
Check both selected reading and retained wrong alternatives. Report exact,
wrong-but-typed, no-parse and harness/schema failures separately with explicit
case and construction denominators. Do not infer the ProverQA >=90% release gate
from a perfect starter-file score. Modal/unresolved constructions and nested
subfamilies remain outstanding until independently reviewed evidence covers them.

Validation: static Python count over root's four JSONL files produced
25/24/24/12 cases and 11/12/12/6 groups respectively, each group at least two.
Manual inspection of all fixture texts and limitations produced the matrix.
No experimental performance or fidelity claim is made by this note.
