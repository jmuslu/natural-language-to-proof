# Bare plurals and names: lexical evidence before ranking

This proposal explains three independently authored ProntoQA failures without
adding a benchmark vocabulary or changing their gold. It does not implement a
repair. Preserve the licensed N/NP name repair; its defect here is an unsupported
choice between meanings, not failure to construct the generic alternative.

## What the sealed observations establish

The input-only inventory counts184,577 bare-plural rule occurrences. The three
new gold cases are exact isolated source sentences, not a random sample:

| Source input | Intended reading | Selected frozen reading |
|---|---|---|
| Gorpuses are lorpuses and wumpuses. | forall x. gorpus(x) -> lorpus(x) & wumpus(x) | lorpuses(Gorpuses) & wumpuses(Gorpuses) |
| Impuses are metallic and sterpuses. | forall x. impus(x) -> metallic(x) & sterpus(x) | metallic(Impuses) & sterpuses(Impuses) |
| Dumpuses are lempuses and jompuses. | forall x. dumpus(x) -> lempus(x) & jompus(x) | lempuses(Dumpuses) & jompuses(Dumpuses) |

Source references and complete independent DRS/claims are in
`test/fidelity/prontoqa-nested.jsonl`, commit77e9338. Sealed evidence is under
`research/runs/nested-prontoqa/` in the author worktree, with `SHA256.json`.
The frozen binary SHA256 is
`5b3f5e9fe4fbe58928bd6d43facc8657cf344c80a55fd06afc8b79f27dc7f035`.

All three observations contain two typed readings. The selected name reading's
trace explicitly says **unseen sentence-initial capital**, `rigid name from N`;
the alternative has `bare-np: generic (forall)` and unary NP provenance. For the
first sentence the name score is -12.449580512679047 and generic score is
-13.449580512679047. The exactly1.0 difference agrees with the current default
unary penalty: lexical name lifting preserves the N category's score, whereas
generic N-to-NP pays1.0. This is an architectural preference for a cheaply
introduced rigid constant, not evidence that Gorpuses names an individual.
Neither alternative is exact: the generic reading still uses plural predicate
spellings. Recovering the right quantification and normalizing nouns are separate
obligations.

## First divergences and remaining evidence limits

1. `lookupForm`/`nameStatus` in `CCGSemParse.hs` finds no dictionary POS for
   these initial forms and returns `NameOrOther`. The sealed trace proves this
   branch; no corpus reload is needed to infer it. Offering both interpretations
   is defensible as ambiguity, but capitalization is not a name license.
2. `lexicalSigns` converts the offered N into NP with `nameItem` at the original
   score. The common-noun interpretation instead reaches NP through `unarySem`.
   Both are typed. Their asymmetric structural costs determine the selected
   denotation before DRS construction. This is the first unsupported commitment
   in these traces; the common-noun option was not absent or pruned.
3. `openTemplateWith` maps nominal predicate spelling to lowercase only. The
   generic alternative thus has `gorpuses`, not the independently specified
   singular lemma `gorpus`. This lexical-meaning mismatch persists even if the
   correct quantifier is selected.
4. DRS construction/claim splitting faithfully reflect the wrong selected
   name meaning: two top-level Asserted predicates. The intended implication
   would be Asserted with its restriction/consequence atoms Embedded. Repairing
   claim splitting cannot turn these constants into bound variables soundly.

The exporter saves forms, categories, scores, traces and meanings, not the full
supertagger count tables or every discarded derivation. The three logs do not
establish a calibrated OOV POS model, singular-lemma evidence, or that agreement
alone proves a common noun. No new tags/deriv/lambda run has been made. The noun
source code was inspected at the current root, whereas actual baseline behavior
is identified by its frozen executable hash. Performance of later nominal
copula work is outside this evidence.

## Proposed general resolution

Keep `N : e -> t` distinct from `NP : (e -> t) -> t`. Carry lexical evidence
alongside each candidate: original form, lookup form, attested POS alternatives,
category, lemma evidence and provenance. A category alone never certifies NNP;
an OOV global-prior N is not an observed NN or NNS. Majority POS is useful
ranking evidence but must not erase an actually attested proper/common homograph.

For known forms, preserve the existing licensed name meaning for NNP/NNPS
(`lambda P. P(Name)`) through N-to-NP and direct ordinary NP. Preserve proper
plural names such as the existing Roberts/NNPS control. Conversely, genuinely
attested NNS supports a common-noun candidate even at sentence start. Preserve
common/adjectival White and Cats controls. Do not globally force all capitalized
NPs to names, or suppress all names followed by `are`.

For unknown initial forms, keep explicit name/common ambiguity. Remove the
accidental free structural advantage: account for comparable N-to-NP operations
consistently across lexical name lifting and generic unary lifting, and record
which candidates this changes. Cost parity alone is **not a disambiguation
algorithm**: an equal-score tie must not silently settle denotation by candidate
insertion order. Require independently supported lexical/POS evidence to choose
between different denotations; otherwise propagate unresolved readings to the
existing ambiguity policy. Do not relabel a typed ambiguous output no-parse to
improve the wrong-but-typed metric.

A local POS constraint layer can use general evidence available in the input:
article+noun positions, inflected copula agreement, and repeated singular/plural
forms in nominal positions. Evidence must have an independent source occurrence,
not originate in the selected name/common reading it is being asked to justify.
`are` supports plural number but does not distinguish NNS from NNPS: family and
organization names can be plural. Do not claim that `-s`/`-es` plus `are` proves
common-noun identity. Contextual nominal evidence may rank or restrict candidates;
its unsupported cases remain explicit. No benchmark ID, fiction-word list,
answer label, gold formula, or generated proof may feed this analysis.

Normalize common nouns only from a declared morphology analysis. In a full
input, independently licensed singular nominal occurrences can support a
productive inflection pairing; dictionary singular/plural evidence can do so
for known words. Preserve provenance and competing analyses. Do not strip every
final s/es (`news`, proper Roberts) or invent an arbitrary singular solely because
the gold has one. These three **isolated** OOV sentences do not themselves fix
every singular lemma. A general productive OOV morphology component requires its
own independently reviewed positive/negative controls and explicit ambiguity;
there is no honest assertion that POS/ranking changes alone solve these fixtures.

The controlled ontology reading can license the generic lift
`lambda P. lambda Q. forall x.(P(x) -> Q(x))`; it is already the existing recorded
stipulation. General English `Dogs are barking` also permits an existential
reading. Number does not supply quantificational force. Retain that distinction
rather than globally treating all bare plurals as universal truths.

## Preserve actual names, including Legend

The reviewed `NAMES.md` shows the opposite error for initial **Legend**: truecase
lookup finds a common noun and suppresses the intended rigid alternative. Lowercase
common evidence and name evidence must coexist when both are independently
licensed; a spelling-only default cannot resolve the homograph in either direction.
The preserved name repair constructs the right meaning once licensed; it should
not be reverted to solve unknown plural subjects.

Document-local name evidence proposed in `NAMES.md` can supply an additional
candidate from an independent occurrence, with no self-reinforcing propagation.
Noninitial capitalization is still a hypothesis, not conclusive identity. Transfer
lexical candidates, not referents or asserted predicates from embedded/negated
boxes. An isolated initial `Legend is red` without independent name evidence
remains unresolved. Do not “fix” it with a Legend exception or by forcing every
initial common noun into a name. A name must retain written identity, including
NNPS names ending in s; nominal lemmatization never rewrites the rigid constant.

## Units2/3/4 and source comparison

Unit2 supplies categories plus lexical/POS evidence; Unit3 assigns the predicate
or name generalized quantifier and records the ambiguous choice; Unit4 projects
its scope into an implication or ground atom without promoting inner conditions.
A generic subject and coordinated predicate compose as
`G(N)(lambda x.(P(x) & Q(x)))`. Its DRS is an implication with x bound in the
antecedent, shared by both consequent atoms. Only the implication is Asserted.
A real named subject composes with the same property conjunction using
`lambda R.R(Name)`, so both top-level atoms are Asserted. The difference must be
settled before claim admission, not repaired by flattening DRS conditions.

Bos2008 §§2–3 separates CCG categories from lexical choices conditioned on POS,
word form and morphology; adopt that interface, not an assumed oracle for unknown
words. The locally inspected pinned ccg2lambda2015 unary templates at lines37–46
condition name lifting on child NNP, distinct from generic/common noun meanings.
Adapt that POS sensitivity, preserving this project's rigid constants and
provenance. Do not copy its existential/equality name representation or common
noun existential default merely to change a score. Neither source justifies
forcing an OOV initial capital to a person or a plural-looking word to NNS.
See `research/linguistics/REFERENCES.md` and `NAMES.md` for pinned sources and
explicit differences; neither external implementation was executed here.

## Review and acceptance before implementation

Use independent miniature dictionaries to separate evidence from incidental
licensed-corpus frequencies. Preserve all current direct NP, NNP/NNPS, repeated
name, White/Cats, forbidden NP-feature, and ambiguity trace controls. Add paired
known NNS/NNPS tests with identical spelling patterns; inspect every returned
reading and ensure a structural tie cannot be mistaken for POS evidence. Add
common/proper homographs, a genuine plural proper name before `are`, an OOV noun
with independent input singular evidence, an OOV name ending in s, and an
isolated unresolved capitalized form. Test morphology separately from generic
quantification and noun-predicate coordination. Keep Legend's intended name gold
unchanged while reporting unresolved ambiguity truthfully.

Re-score all existing and nested fidelity sets after each independently reviewed
change; compare exact, wrong-but-typed and no-parse without dropping ambiguous
cases. Require the same claim-status checks for alternatives. These controls
must precede implementation; this proposal makes no success-rate prediction for
unimplemented morphology or contextual evidence. It identifies why a score-only
fix would fail the requested fidelity criterion and the evidence needed for a
general repair. Reviewer approval is required before integrating semantic changes.
