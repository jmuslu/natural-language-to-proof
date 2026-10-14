# Name evidence audit and structural origin recipe

Design-only follow-up to `NOMINAL_NAME_LICENSING.md` (`c77ad00`). No CCGbank
load, source edit or model/benchmark run was performed. Working base is
`990760f`; nominal-v1 integration remains independently gated.

## Audit result: unknown, not ineligible

| Written form | Sealed lexical evidence | c77ad00 dictionary criterion |
| --- | --- | --- |
| Abraham | Best interpreted NP/name; all-readings cache shows offered N repaired to NP | Unknown |
| Alyssa | Best interpreted NP/name; no all-readings entry in inspected cache | Unknown |
| Amiyah | Best interpreted NP/name; all-readings cache exposes scored alternatives | Unknown |

The ordinary Explain artifact explicitly says “best tag; no selected
derivation.” Its first three inputs all fail to derive semantic S. The
all-readings artifact contains Abraham and Amiyah, not Alyssa; despite its
name, this is a scored/pruned category display, not an unpruned POS export.
The positive-nominals baseline observations contain NoParse diagnostics and
no selected lexical evidence. None establishes that any name is unseen,
NNP-only, or opposed by a rare NN/JJ reading. No eligibility or gain count can
be derived from these artifacts.

Inspected source confirms `nameStatus` reads ranked `posCounts` only at the
first entry, whereas `lookupForm` can switch to a lowercase dictionary form
based on `tmWord` membership. The required audit therefore needs both POS
counts and tag-table membership. It cannot reconstruct one from the other or
from equal NP log scores. No serialized POS model was located in the inspected
repository cache paths; this is a bounded search result, not proof none exists
elsewhere on the machine. Reading raw training files to reconstruct counts
would be a new corpus audit and was not performed.

## Small reproducible evidence extraction, proposed only

The preferred next opportunity is an already authorized single model load:
inspect the existing immutable SemModel before parsing, emit only the three
requested forms plus their lowercase keys, then reuse that same model for any
separately authorized work. Do not add a second CCGbank-loading process or dump
the dictionary. Record the source commit, options including truecase, corpus
sections, successful tree count and a model/input manifest identifier.

For each occurrence, emit a compact JSON record:

```
{ written, initial, lowercase,
  written_tag_member, lowercase_tag_member, effective_form,
  written_pos_counts, effective_pos_counts, lowercase_pos_counts,
  actual_name_status, offered_original_categories,
  certificate_decision, failed_conditions }
```

POS arrays must be complete `posCounts` outputs, before beta/cap/smoothing;
empty arrays mean zero available dictionary evidence, not NNP-only. The
original category list is separately labeled as offered/pruned. Export the
actual runtime initial flag and options rather than guessing effective form.
Include zero/negative-count rejection and singular NNP versus NNPS distinction
from c77ad00. Never include bulk lexical entries or source corpus sentences.

If a full model is otherwise unnecessary, a later approved streaming extractor
could retain counts only for these six keys. To match `loadSemModel`, it must
use exactly `ccgbankTrainFiles`, skip identical blank/ID lines, apply the same
`parseAuto` acceptance test, accumulate POS from accepted lines' `leafHeaders`,
and tag membership from accepted trees' `leafPairs`. A regex over all leaf
headers, including rejected trees, is not equivalent. Record missing files
and rejected-line totals: the loader currently skips unreadable/invalid input,
so an apparent absence without manifest completeness cannot prove unopposed
support. Validate extractor versus in-memory `posCounts` on synthetic accepted
and rejected fixtures before allowing any corpus read. This is a design, not
an executed extractor or authorization for a new load.

## Structural origin: mint at construction, not from output

A reliable certificate cannot be recovered from `stWhy`, a `name-lexicon` note,
`ProvLex` alone, or a term resembling `λk.k(a)`. The current LexSign exposes
category/item/score; a direct lexical provenance leaf does not retain the
source category or the evidence branch that constructed its meaning.

For a future bounded implementation, attach a typed origin to the *specific*
lexical alternative at the point where `lexicalSigns` invokes `nameItem`:

```
RigidNameOrigin {
  occurrence: source + token index + exact span + written form,
  lookup: initial flag + effective key + model identity,
  evidence: checked complete dictionary evidence,
  sourceCategory,
  categoryTransition: OrdinaryNP | ExistingNameNToNP,
  rigidIdentity: identity supplied to the existing name constructor
}
```

Names here are illustrative, not new production types. The origin is created
in the same branch and operation as the lexical meaning, then carried into
`mkLeaf`; it must not be attached by comparing an independently reconstructed
term or by matching a token spelling afterward. Unknown-capital name branches
can retain their existing behavior while carrying no optional nominal-name
certificate. The narrow admission predicate examines this origin's evidence.
Do not conflate source-category N repair with generic grammar unary N→NP.

Extend the nominal subject role with a typed named alternative whose sole
constructor consumes that checked origin. Direct subject application records
this role in Complete; all existing full-root, source, span, punctuation,
packing and unsupported-embedding checks remain mandatory. Hash/compare the
origin in any chart identity that distinguishes certified from uncertified
items. If integration would require a general optional payload on every sign,
first consider carrying the typed origin only alongside the existing lexical
assignment-to-leaf boundary and in the nominal role that consumes it. Do not
claim notes or structural provenance already supply missing information.

The captured complement property remains independent and is still used as
`Q(P)`. No Q inversion, equative fallback or global name policy change follows
from this recipe. A correct name certificate does not certify the complement
noun, the whole clause, or a downstream reported assertion.

## Review controls before implementation

Use synthetic dictionary models to separate actual NNP-only support, NNP+rare
NN/JJ, unknown capital, NNPS and truecased lowercase opposition. Two candidates
with identical NP category, term and rendered notes but different typed origins
must differ in capability and packing. A licensed name N repair must preserve
its source category; arbitrary unary N→NP must not forge that origin. A wrong
source/model/token occurrence must fail. Finally test complete root versus
embedded/negated/relative uses through actual chart transitions. c77ad00's
remaining controls apply. No executable source tests are claimed in this audit.
