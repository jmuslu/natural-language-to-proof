# Typed lexical origin for bounded nominal name subjects

Concrete API proposal and independent red controls only. Production source is
unchanged; frozen nominal-v1 (`8e2a6ad`) is read-only and must pass coordinator
integration gates before this extension is considered. This follows reviewed
c77ad00 and the actual dictionary audit7d85eb1, not a request to reopen the old
unrestricted nominal candidate.

## Evidence and scope

Under the declared unopposed singular-name lexical assumption, Abraham's
observed dictionary has NNP4 and N2/N/N2. The lowercase key is absent. Alyssa and
Amiyah have no positive dictionary evidence. These conditional observed-input
facts license investigating only the first class; no unknown-name exception
is proposed. The independent miniature fixtures use Ari with explicit synthetic
NNP support so intended reference is stated before any parse. They do not use
parser observations as gold or claim that the actual dictionary attests Ari.

c77ad00 requires nonempty all-NNP positive written/effective POS evidence,
no contrary lowercase POS, and an actual rigid name lexical choice. NNP majority
with rare NN/JJ is insufficient; NNPS is deferred; NameOnly alone is
insufficient because it can arise from unknown noninitial capitalization.
Inspect complete counts before pruning. Do not filter a contrary POS out and
then certify the remaining NNP. Preserve the existing truecase lookup rule.

## Minimum interface change, not a general provenance framework

The current public `lexicalSigns :: SemModel -> Int -> String -> [LexSign]`
loses the name branch's original category and dictionary origin before
`nominalCapability` sees a final NP. A final NP, term, note or `ProvLex` cannot
recover those decisions. Keep the public function as a projection over a new
private branch-preserving function, instead of adding an optional origin field
to every general chart sign:

```
lexicalChoices :: SemModel -> Int -> String -> [(LexSign, LexicalOrigin)]
lexicalSigns m i w = map fst (lexicalChoices m i w)

LexicalOrigin = OrdinaryOrigin | RigidNameChoice NameLexOrigin
NameLexOrigin = {
  tokenIndex, writtenForm, initialFlag, effectiveForm,
  dictionaryEvidence, originalCategory,
  nameCategoryStep = OrdinaryNP | ExistingNameNRepair,
  rigidIdentity
}
```

These names are proposed API, not present exports. DictionaryEvidence records
the complete inspected written/effective/lowercase counts and immutable model
identity; its checked form can be opaque to callers. The actual name branch
creates `RigidNameChoice` *beside* its existing `nameItem w` call, using the same
identity and original offered category before `nameCategory` changes N to NP.
Unknown/casing-supported choices retain their existing ordinary behavior but
cannot pass the new dictionary certificate. Never reconstruct origin from
`lxItem` gloss, stKind/stWhy, rendered lambda, or category/term equality.

Thread the exact `(LexSign, LexicalOrigin)` pair through the existing
ordinary/fused annotation lists to leaf construction. Bind its original token
index and spelling to that token's exact source/span once. This creates a
nominal-specific subject payload without general per-sign metadata:

```
BoundNameOrigin = { source, tokenIndex, tokenSpan, writtenForm, lexicalOrigin }
NominalRole += NominalNameSubject BoundNameOrigin
NominalSubjectOrigin = UniversalOrigin ... | NamedOrigin BoundNameOrigin
NominalComplete certificate subjectOrigin complementOrigin
```

A named Complete must retain the NamedOrigin payload, not just collapse it to
`ssProv subject`; otherwise origin evidence is erased before root/packing.
The universal constructor can retain all its existing evidence via the typed
sum. This is the only proposed widening of the completion payload. The
coordinator should review exact compatibility with the final landed v1 API
rather than assuming this sketch matches a not-yet-landed source revision.

## Required transitions

1. At lexical mint, only an existing rigid-name choice passing c77ad00 receives
   `NominalNameSubject`. An actual ordinary NP/NP[nb] or the existing lexical
   name N→NP repair is allowed; an arbitrary grammar unary N→NP is not.
2. Direct backward subject application consumes NamedSubject and the existing
   Pending certificate, checks exact source/span/ordering, category, lexical
   origin and ordinary subject type, and creates Complete with NamedOrigin.
   Use the existing named Q on the separately captured noun P. No Q inversion,
   equative fallback, generic-name coercion or global equality contraction.
3. No raising, unary, coordination or composition transition may silently
   preserve/forge the new subject capability. Unrelated ordinary routes can
   remain independently available. Pending/Complete restrictions remain
   mandatory; only reviewed final punctuation preserves Complete to full root.
4. Packing distinguishes identical category/meaning with different checked
   origins. Complete/root verification retains the selected subject identity,
   source and complement origin. Foreign-source or shifted-span payloads fail.
5. A nominal article's special captured-P route cannot alter its independent
   ordinary argument meaning: `Ari sees an animal` retains an existential
   animal witness; `Ari sees Ari` retains the existing rigid-object meaning.

Unit2 concerns the actual name lexical category choice and bounded derivation;
Unit3 is `Q=λk.k(a)` applied once to captured P; Unit4 has one Asserted
classification atom and no added identity witness. Reported or negated uses
are not authorized by this subject extension. As in the Boxer/ccg2lambda
comparison in nominal-licensing, semantic typing cannot settle lexical origin;
the explicit assumption belongs with construction evidence.

## Independent controls and honest baseline

`test/NominalNameControlsSpec.hs` calls the public pipeline with small synthetic
lexicons. The positive fixture checks exact canonical DRS, every returned
reading, and independent Asserted/Embedded allocation for both actual NP and
existing name-N repair choices. V1 is expected to fail all six because it admits
only overt universal subjects. Boundary controls include rare contrary NN/JJ,
unknown initial capital, unknown plural-looking form, bare generic plural,
NNPS, expletive NP, root fragments, unsupported reporting/negation, absent
equative fallback and both ordinary article/object meanings.

The green boundary checks are not proof that the future certificate works:
v1 currently rejects all named nominal routes. They become regression controls
when positives turn green. These tests do not yet exercise a nonexistent typed
origin API. Before implementation approval, add actual internal tests for:

- same category, exact term and rendered notes with distinct lexical origins;
- rejected foreign source, shifted span/index, or mismatched written token;
- name-N repair versus generic unary N→NP with otherwise equal final NP;
- Complete retaining NamedOrigin through punctuation/root and chart packing;
- changing one POS count to a rare contrary tag changes admission, without
  changing ordinary name semantics elsewhere.

Do not replace these with tests of a duplicated Boolean policy or manually
fabricate a certificate and describe it as lexical integration. Default test
execution intentionally includes six known reds; it is not a registered green
release suite. No source changes, corpus load or gain estimate are included.
