### C9. Particles, lexical spans and PP boundaries

**Scope and evidence.** The accepted bounded construction is adjacent
intransitive *give up*, under `intransitive-give-up-fixed-effort-v1`: cessation
of trying at a contextually fixed effort, with tense/aspect abstracted. It is
not a general rule that concatenates any verb and particle, or a claim that
all uses of *give up* have this sense. Independent gold contains one exact
ProverQA sentence, *Raul gives up.*, and two authored name/negation controls.
Accepted59955b6 changed those three from no-parse to exact on frozen167, leaving
all164 other statuses and selected objects unchanged. That checkpoint is a
bounded result, not the current total or population coverage.

**Unit 2: the actual two-token construction.** In the sealed accepted
`expanded-gold167/lexical-alternatives.log`, *gives* offers `S[dcl]\NP` at
logP−4.23, *give* offers `S[b]\NP` at−4.35, and *up* offers
`(S\NP)\(S\NP)` at−0.56. These are offered alternatives; the best interpretable
head tags were transitive. Using only the displayed best tag would incorrectly
suggest that the required intransitive head was absent. Ordinary *up* in that
modifier category had no admitted standalone meaning.

```text
 gives : S[dcl]\NP     up : (S\NP)\(S\NP)
 ───────── certified adjacent lexical span ─────────
               gives up : S[dcl]\NP
 Raul : NP                           │
 ────────────────── < ───────────────┘
                 S[dcl]
```

The top step is a lexical span seed, **not ordinary backward application** of
an identity meaning for *up*. A lexical sense record licenses the two original
adjacent tokens, exact categories, finite/base morphology and unary frame.
Both source leaves and their spans are retained under
`particle-lexeme:give_up`; scores add rather than receiving a name-dependent
bonus. The same certified seeds enter the internal category and semantic charts
before usefulness pruning. Ordinary competing readings remain available. No
category is synthesized from a transitive-only head by deleting its object.
Original CCGbank does not use the rebanked PR subcategorization assumed by some
external templates; its actual offers are the evidence here.

**Unit 3: types and composition.** Write `Q=(e→t)→t`, `V=Q→t`, and
`lift(a)=λP.P(a):Q`. The ordinary unary lexical template gives the complete span
`G=λS:Q.S(λx:e.give_up(x)):V`. Hence
`G(lift(Raul)) → give_up(Raul)`. It does not entail `give(Raul)`, `up(Raul)`,
physical transfer or a synonym such as surrender. Predicate identity is the
reviewed lexical sense, not a rewrite of a previously normalized verb term.

For the negative control, the base span has category `S[b]\NP` and meaning G.
The right-looking negation alternative `(S\NP)/(S\NP)` has
`N=λV:V.λS:Q.S(λx.¬V(lift(x))):V→V`. Applying it to G yields
`λS.S(λx.¬give_up(x))`. Do-support
`does:(S[dcl]\NP)/(S[b]\NP)` contributes the typed VP identity, preserving the
base-to-finite feature transition. Subject application gives `¬give_up(Raul)`.
This is a valid worked composition, not a promise that Explain reconstructed
that exact lexical path in the saved run.

**Unit 4: the independent interface contract.**

| Sentence | Canonical DRS | Asserted | Embedded | Reported / Presupposed |
| --- | --- | --- | --- | --- |
| Raul gives up. | `[ | give_up(Raul)]` | one unary atom | empty | empty / empty |
| Ada gives up. (authored) | `[ | give_up(Ada)]` | one unary atom | empty | empty / empty |
| Raul does not give up. (authored) | `[ | ¬[ | give_up(Raul)]]` | whole negation | inner unary atom | empty / empty |

There is no event witness or comparison/effort witness in this declared unary
contract. A future event representation would bind its event inside the negative
box; it is not structurally equivalent to this gold without a reviewed interface
change.

**Actual Explain limitation, separate from meaning failure.** The sealed
59955b6 diagnostics in the943060c replay audit produced the expected lambda,
DRS and claims for all three controls, but all three used raw-provenance fallback.
The fallback retained both particle leaves; leaf-term tables were empty and tag
rows said “best tag; no selected derivation.” Source inspection locates the
replay obstruction: its two-child rule reconstruction expects an ordinary
combinator name, while `particle-lexeme:give_up` is a lexical seed. Pipeline
meaning succeeded; renderer reconstruction failed. The renderer did not itself
emit a first-node diagnosis. Evidence stdout SHA256 is
`f4184c9a627828c218a841d9b892ee4ad3b5c23a04d661981ece6f977a26997a`.
Do not describe this as a missing semantic parse or claim every displayed tag
was the selected Pipeline derivation. No linguistic divergence from those three
frozen meanings was observed.

**Separate obligations.** *Walks up the hill* has a directional NP-dependent
PP, plausibly `up:((S\NP)\(S\NP))/NP`; the hill and path/goal cannot disappear.
*Picks the box up* requires a licensed separated-particle/object frame and
argument order, outside the adjacent unary license. *Carry out a task* needs an
independent transitive idiom sense, distinct from carrying a box out of a room.
*Wakes up early* and *does not easily give up* require event/time/dispositional
modifier scopes; they are not the simpler unary positive/negative gold.
These category sketches are not measured local tag offers or implemented DRS
contracts. Retain them as unresolved rather than inventing exact outputs.

**Next senses remain separate.** The three reviewed stand-out controls are
AUTHORED under `stand-out-noticeable-fixed-comparison-v1`, with predicate
`stand_out_noticeable`; noticeability is not superiority or posture. They give
no source-fidelity credit or automatic implementation license, and stand/out
category availability remains unmeasured. The more frequent ProverQA
*stand up for* cue (32 occurrences/31 surfaces) is a separate stance/beneficiary
and PP-local-reflexive design problem. Neither sense inherits give-up semantics.

### C10. Local reflexives and ordinary pronouns

**Unit 2: derived category and lexical locality.** Singular *himself*, *herself*
and *itself* can be reanalyzed from an offered ordinary `N`, `NP` or `NP[nb]` into
`(S[f]\NP)\((S[f]\NP)/NP)`, with f exactly dcl or b. This is a logged derived
operator category, not a claim that CCGbank supplied it. The lexical governor
must itself be the direct finite/base transitive leaf; composed, raised,
extracted, passive or punctuation-wrapped governors cannot discharge binding.
The closed reflexive marker, source lexical leaf and matching feature category
are all required; category shape alone is insufficient.

```text
 defends : (S[dcl]\NP)/NP       herself : (S[dcl]\NP)\((S[dcl]\NP)/NP)
 ───────────────────────── guarded < ──────────────────────────────
                         defends herself : S[dcl]\NP
 Amara : NP                                         │
 ─────────────────────────── < ──────────────────────┘
                            S[dcl]
```

A base verb binds its reflexive first in *does not defend herself*. Negation and
auxiliary composition then apply outside the completed VP. This ordering
prevents the binding rule from treating an arbitrary composed transitive
expression as a lexical local governor.

**Unit 3: the diagonal meaning, fully typed.** Let `Q=(e→t)→t`, `V=Q→t`,
`T=Q→Q→t`, and `lift(x)=λP:e→t.P(x):Q`. A transitive verb is object-first:

```text
R = λO:Q.λS:Q.S(λs:e.O(λo:e.defend(s,o))) : T
D = λR:T.λS:Q.S(λx:e.R(lift(x))(lift(x))) : T→V
D(R) → λS:Q.S(λx:e.defend(x,x))          : V
D(R)(lift(Amara)) → defend(Amara,Amara)  : t
```

D is the meaning of the derived reflexive operator. It applies the subject
quantifier once; both argument positions receive the same bound individual.
For `Every cat`, let `A=λP.∀x(cat(x)→P(x)):Q`. Then
`D(groom)(A) → ∀x(cat(x)→groom(x,x))`, without an independently quantified object
or duplicated universal subject. With ordinary VP negation after binding,
`N(D(defend))(lift(Amara)) → ¬defend(Amara,Amara)`.

**Unit 4: witnesses and claim barriers.**

| Form | DRS | Asserted | Embedded |
| --- | --- | --- | --- |
| Amara defends herself. | `[ | defend(Amara,Amara)]` | atom | empty |
| Every cat grooms itself. | `[ | [x | cat(x)]⇒[ | groom(x,x)]]` | whole implication | cat(x), groom(x,x) |
| Amara does not defend herself. | `[ | ¬[ | defend(Amara,Amara)]]` | whole negation | defend(Amara,Amara) |

Reported and Presupposed are empty in all three. In *Anne is red. Amara defends
herself.*, the later reflexive refers locally to Amara, irrespective of earlier
Anne. Binding is not nearest-name substitution. Seven independently frozen
reflexive controls improved wrong-but-typed→exact in the historical121-row
trial; that evidence is not unrestricted anaphora coverage. The earlier failure
could universalize the reflexive as a common noun before DRS construction;
changing claim extraction would not repair that lexical meaning.

**Ordinary pronouns are different.** The ordinary NP term
`λP.P(?it_i):Q` introduces an occurrence-specific unresolved anaphor, not the
closed diagonal operator. A conditional such as *If a cat is red, it is big*
requires DRT antecedent accessibility and an independently checked resolution
choice. Discourse resolution does not license promotion of a negated or
attitude-local referent into a later main clause. The preserved recency resolver
is a heuristic, not a complete English binding theory. No gender is guessed
from a person's name. Plural agreement, reciprocal meaning, intensifiers
(*Bob himself*), PP reflexives (*stands up for herself*), exempt/logophoric
reflexives and nonlocal binding remain outside the implemented singular
coargument license. Unsupported reserved forms must not silently become names
or common-noun universals.

### C9/C10 source comparison: adopt, adapt, reject

[Boxer 2008](https://aclanthology.org/W08-2222/) §2.2 supplies the event/participant
perspective; §§3.2–3.3 distinguish lexical construction from resolution.
Adopt that separation. Adapt local binding to this project's Q-valued NP and
explicit lexical-span interface. The paper's reflexive-trigger discussion in
§3.3 does not establish this diagonal rule or unrestricted binding accuracy;
its §5 lacks semantic gold sufficient to certify our fidelity criterion.
These paper locations follow the retained primary-source account in REFERENCES,
not a new replication or current Boxer execution.

The pinned [ccg2lambda event YAML1153–1190](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_event.yaml#L1153-L1190)
places particle entries under rebanked parses. Its basic PR rules preserve a
shared event and participant roles: adopt that preservation requirement, but
adapt only through a declared event ontology or an independently licensed
lexical frame. They are not drop-in terms for one-slot Q or evidence that
original CCGbank offers PR. Reject the higher-order fallback at1189–1190 as a
general particle solution: it ignores the lexical verb/particle arguments and
returns the supplied VP continuation. The prior audit found no dedicated
reflexive-spelling/reflex entry in the three pinned English YAML files; this
limited search does not prove the whole system lacks reflexive handling.
Neither source supplies this project's Asserted/Reported/Presupposed/Embedded
admission guarantees. Those remain independently checked interface obligations.
