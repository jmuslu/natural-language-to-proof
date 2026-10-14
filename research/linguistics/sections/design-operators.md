<!-- Ready to include after, or in place of the worked portions of DESIGN C4/C5/C7.
     Evidence checkpoint d83adaa. No new parser measurements. -->

### C4 worked supplement: do-support preserves the base VP and negation scope

This connects [Unit2](../../../STUDY_PLAN.md#unit-2-ccg-and-ccgbank-weeks-23-the-biggest-gap)'s category derivation to [Unit3](../../../STUDY_PLAN.md#unit-3-the-syntaxsemantics-interface-week-4)'s typed meanings and [Unit4](../../../STUDY_PLAN.md#unit-4-discourse-representation-theory-week-5)'s scoped claims. Write `Q=(e→t)→t`, `V=Q→t`, and `lift(a)=λP.P(a)`. Categories distinguish `S[b]` from `S[dcl]` even though both map to type `t`.

**Status:** the current closed table implements `does/do:(S[dcl]\NP)/(S[b]\NP)` with VP identity, and `not` at featureless forward/backward VP-modifier categories plus an adjective forward modifier. `closedEntries` requires exact category equality; it does **not** instantiate an arbitrary feature variable. Thus the explicitly base-featured `not` below is a **proposed licensed variant**, not an observed or already admitted lexical entry. No corpus parse is claimed for this tree. A featureless offer may participate in unification, but is not evidence that a feature-preserving `S[b]` derivation has been recovered.

For `Bob does not like Anne`, use these entries in the proposed tree:

| Token | Category | Meaning |
| --- | --- | --- |
| Bob | NP | `B=lift(Bob):Q` |
| does | `(S[dcl]\NP)/(S[b]\NP)` | `D=λV:V.V` |
| not | `(S[b]\NP)/(S[b]\NP)` | `N=λV:V.λS:Q.S(λx.¬V(lift(x)))` |
| like | `(S[b]\NP)/NP` | `L=λO:Q.λS:Q.S(λx.O(λy.like(x,y)))` |
| Anne | NP | `A=lift(Anne):Q` |

The complete Unit2/3 application sequence is:

```text
like + Anne     >  S[b]\NP       L A = λS.S(λx.like(x,Anne))
not + (like Anne)
                >  S[b]\NP       N(L A) = λS.S(λx.¬like(x,Anne))
does + (not like Anne)
                >  S[dcl]\NP     D(N(L A)) = λS.S(λx.¬like(x,Anne))
Bob + (does not like Anne)
                <  S[dcl]         D(N(L A)) B = ¬like(Bob,Anne)
```

The auxiliary changes the syntactic feature, not the relation's arguments or scope. Unit4 yields `[ | NOT [ | like(Bob,Anne)]]`: Asserted contains the single NOT condition; Embedded contains `like(Bob,Anne)`; Reported and Presupposed are empty. The relation is not independently asserted.

For a quantified subject, `Some cat does not like Anne` gives `∃x(cat(x)∧¬like(x,Anne))`, DRS `[x | cat(x), NOT [ | like(x,Anne)]]`. Asserted contains contextual `cat(x)` and NOT; Embedded contains the relation. It does not give `¬∃x(cat(x)∧like(x,Anne))`. This subject-wide choice is an explicit existing `negScope` stipulation, not a claim that English allows no other scope. A nonspecific object stays inside negation: `Bob does not like a cat` gives `[ | NOT [y | cat(y),like(Bob,y)]]`, not a root witness. Specific-object readings need a separate declared scope contract.

**Possession is a different lexical question.** For the declared ordinary possession sense, `has:(S[dcl]\NP)/NP` can use `λO S.S(λx.O(λy.have(x,y)))`; `a dog:Q=λP.∃y(dog(y)∧P(y))` produces `[y | dog(y),have(Bob,y)]`, two contextual Asserted atoms sharing one witness. Neither the category nor the lemma alone licenses that sense for *has to leave*, *has left*, *has lunch*, or *has integrity*. Perfect, modal, light-verb and abstract-object interpretations remain separate obligations.

**Where to look for a first divergence.** Inspect the actually offered `not` category, closed-entry lookup and preserved feature before beta reduction. If no matching entry exists, that is a lexical-admission gap; if a reconstructed Explain tree uses another category, it is not proof of the original lexical path. A wrong scope after a valid entry is a different failure. This supplement is a source audit and derivation, not a new measured diagnosis. Keep positive/negative, subject/object order, quantified subject and object controls separate.

### C5 worked supplement: a conditional does not itself bind a pronoun

The ground fronted construction has implemented entries `if:(S/S)/S[dcl]`, `λp:t.λq:t.p→q`, and `then:S/S`, `λq.q`. After its antecedent combines by `>`, `if A:S/S` combines with `then B:S` by `>`, yielding `A→B`. A postposed `B if A` needs the **proposed**, presently absent closed entry `(S\S)/S[dcl]` with the same semantic argument order: consume following A first, then preceding B. Its result is still `A→B`, not `B→A`.

Now consider the controlled generic rule `If someone is red and young, then they are big`. The following is a compositional specification using existing lexical meanings and existing DRT accessibility; it is **not** a claim that this whole surface derivation has been observed exact. Commas and offered categories can independently block it.

1. Unit2: `red,young:S[adj]\NP`; `and:conj` marks the right VP; same-category coordination forms `red and young:S[adj]\NP`. The copula `(S[dcl]\NP)/(S[adj]\NP)` supplies the finite VP; `someone:NP` combines on its left. `they:NP` combines with `are big:S[dcl]\NP` in the consequent. Fronted if/then combines these two clauses as above. Each application must retain category features; arbitrary `N/N` or sentence-modifier substitutes are not licensed by this sketch.
2. Unit3: shared-subject coordination forms `V=λQ.Q(λx.red(x)∧young(x))`, not two independent applications of someone. Current strict-person `someone` means `λP.∃x(person(x)∧P(x))`; applying V gives `∃x(person(x)∧red(x)∧young(x))`. Consequent `they` initially denotes a position-indexed anaphor constant `aᵢ`, so its formula is `big(aᵢ)`. The syntax yields `Imp(Exists(x,person(x)∧red(x)∧young(x)),big(aᵢ))`.
3. Unit4 lowering introduces x **inside the antecedent**: `[ | [x | person(x),red(x),young(x)] ⇒ [ | big(aᵢ)]]`. This is not a closed FOL encoding of the intended generic rule yet. In particular, writing `(∃x.R(x))→big(x)` as ordinary FOL would leave the consequent x free.
4. `resolveLocalAnaphora` descends into a conditional's consequent with the enclosing environment **plus the antecedent's top-level universe**. It requires a candidate's introducing provenance to precede the pronoun and chooses the latest accessible candidate; the decision records rejected alternatives. With the single candidate here it replaces `aᵢ` by x, yielding `[ | [x | person(x),red(x),young(x)] ⇒ [ | big(x)]]`. The duplex condition corresponds to `∀x((person(x)∧red(x)∧young(x))→big(x))`. It does not assert that any such person exists.
5. Asserted is the one whole implication. Embedded, in preorder, contains `person(x),red(x),young(x),big(x)`. Reported and Presupposed are empty. The conditional does not assert its antecedent or consequent separately; x does not become a root discourse witness.

Accessibility has boundaries. A witness nested only inside antecedent NOT is not in its top-level universe and cannot license the consequent pronoun. An OR branch's private witness cannot escape its branch or bind a sibling. The current local resolver observes these box boundaries, but uses recency **without agreement features**; with multiple accessible candidates, correct intended identity remains a separate gold obligation. Missing usable provenance leaves the anaphor unresolved rather than proving a binding.

Keep contracts explicit: the example above uses the person restriction of someone. The older controlled ProofWriter *something* gold intentionally uses an unrestricted domain with **no** `thing(x)` predicate. Current literal lexical something contributes thing; an unrestricted benchmark adapter and strict lexical output are different contracts, not interchangeable exact readings. Explicit *things* and *people* retain their sortal predicates. Neither generic-rule handling nor a benchmark convention may turn an isolated existential fact into a universal.

The implemented conditional comma guard blocks one known duplicated-consequent construction; it does not prove all binding, direction or scope problems solved. Historical crossed-composition reversal remains a separate issue. *Only if*, *unless*, and temporal *when/whenever/once* require their own argument/scope analyses, not blanket replacement by if.

### C7 worked supplement: OR, XOR and neither are different scoped structures

Let `P=red(Bob)`, `Q=big(Bob)`, and `VP(X)=S[X]\NP`. Implemented `or:conj` first makes a marked right constituent through `CoordMark`; `CoordApply` combines it with a matching left category. For adjective alternatives, `red + (or big)` yields `VP(adj)` and the copula yields `VP(dcl)`; applying Bob yields S[dcl]. At semantic type `V=Q→t`, the shared-subject operator is `λV W S.S(λx.V(lift(x))∨W(lift(x)))`. It preserves a single existential subject witness. Clause OR operates on `t,t`; these are not interchangeable category cases.

| Construction contract | Scoped DRS | Asserted | Embedded (preorder, with multiplicity) |
| --- | --- | --- | --- |
| inclusive OR | `[ | [ | P] OR [ | Q]]` | OR | P, Q |
| explicit OR plus not-both | `[ | [ | P] OR [ | Q], NOT [ | P,Q]]` | OR, NOT | P, Q, P, Q |
| not-both alone | `[ | NOT [ | P,Q]]` | NOT | P, Q |
| neither P nor Q, chosen fixed representation | `[ | NOT [ | P], NOT [ | Q]]` | NOT P, NOT Q | P, Q |

All four rows have empty Reported/Presupposed partitions. The two-NOT representation of neither is the fixed structural gold contract; logical equivalence to NOT(OR) is not permission to change its DRS shape after seeing parser output. OR permits both true; OR-plus-not-both rejects both true and both false; not-both permits both false; neither requires both false. *Not necessarily both* is modal and does not entail not-both. *Mutually exclusive* supplies at-most-one, not existence of an alternative.

**Either: proposed pairing, unresolved end-to-end interface.** There is currently no closed lexical entry/reservation for either. A restricted **proposed** `either:VP(f)/VP(f)` can only receive a marker role paired with the same-category direct explicit OR edge; it cannot be admitted as an unconditional identity. An implemented ordinary OR derivation is not already an implemented either/or derivation. The candidate sequence is `either + leftVP → pending-leftVP`, then `pending-leftVP + (or rightVP) → marked coordinated VP`; a pending marker cannot become a root, close on AND/comma, or pair with an arbitrary descendant OR. A sentence-initial `either:S/S` is not established by the historical VP/N/N offers. Determiner/choice *either book/on either side*, repeated markers, mixed lists, and raised/composed alternatives remain separate cases.

Even this pairing sketch needs a second interface before implementation. `DRT.Build.toDRS` currently assigns every OR full-sentence fallback provenance. The exporter detects repeated shared either-bearing provenance and marks `either_scope_ambiguous=true` rather than pretending to know which OR is marked. A lexical identity or SSign boolean cannot repair this: operator occurrence identity must survive normalization and lowering. Equal formulas in different clauses cannot be distinguished by a map keyed on formula equality. Until a reviewed occurrence-preserving interface exists, do not invent precise provenance or relax the abstention safeguard.

For `If Mira is either tall or quiet, then Mira is red or young`, intended markers are antecedent=true, consequent=false. The root implication alone is Asserted; Embedded preorder is antecedent OR, tall, quiet, consequent OR, red, young. The independent TT/TF/FT marker gold fixes each clause separately. Those seven operator controls were frozen outside173 and later proposed for separately frozen190; their membership is not a source-fidelity claim. Explicit benchmark mode may interpret a surface either flag as XOR; the linguistic inclusive DRS and marker do not universally entail XOR. Keep literal-English, benchmark-convention and incomplete-marker outcomes separate.

**Neither/nor and explicit not-both: semantic targets, not completed lexical templates.** The two-NOT row has the typed desired VP operation `λV W S.S(λx.¬V(lift(x))∧¬W(lift(x)))`. A paired construction could consume two same-category VPs and produce one, but no complete closed category/feature and occurrence-guard design is accepted here. In particular, replacing *nor* by OR and *neither* by free negation risks wrong attachment and witness scope. The explicit not-both row requires independently licensed Boolean conjunction under NOT; anaphoric *both* in *but not both* needs access to the actual two alternatives, not a guessed pair from term shape. The corrective *not P but Q* outer-negation counterexample blocks a broad but-as-AND repair. No such lexical shortcut follows from these desired formulas.

**Evidence and next divergence checks.** The accepted selected cache `research/runs/everyone-closed-integration/fresh.json` has no-parse for the two VP-either, two sentence-either and nested Prover OR/XOR pairs. Historical Explain descriptions in the operator proposal identify missing usable meanings, but a reconstructed tree is not an original retained derivation witness. The separate corpus-free either-interface proposal has 7/11 checks passing and four explicit red obligations (two paired positives, reservation, local lowering information). Neither those synthetic controls nor this card measures representative construction fidelity. Inspect admission, pairing, scope and occurrence export separately before attributing a mismatch to a single token.

### Source comparisons for C4/C5/C7

The [retained source map](../REFERENCES.md) and [comparison audit](../proposals/DESIGN_COMPARISON_AUDIT.md) distinguish primary implementation inspection from prior paper accounts. Bos2008 §§2–3 motivates category/lexical construction followed by separate anaphora resolution; its documented unresolved cases and lack of semantic gold do not establish our auxiliary, pronoun or correlative fidelity. Adopt that separation, adapt it to the project's explicit claim partitions, and reject coverage alone as semantic validation. The audit checked consistency with prior paper retrieval, not a new PDF replication.

At pinned ccg2lambda `a68cb264413791150011c347c64a7b35e2f7270d`, the retained 2015 YAML's negation entries (around469–476) give subject-wide negation using its two-slot NP continuation; adapt the type interface rather than copying into project Q. Its if entry (around589–591) supplies implication, not by itself a proof of pronoun resolution. Shared-subject VP conjunction (87–90) supports the shared-witness distinction. Selected VP/N/N either identities (609–617) omit the required pairing guarantee. The sentence-or template (102–106) literally uses AND; reject that template as a meaning oracle. These are exact implementation comparisons, not claims about all upstream derivations. No Boxer or ccg2lambda execution, new corpus load, source change or gold mutation accompanied this section.
