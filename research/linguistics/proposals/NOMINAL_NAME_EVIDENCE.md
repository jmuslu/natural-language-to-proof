# Name evidence audit and structural origin recipe

Follow-up to `NOMINAL_NAME_LICENSING.md` (`c77ad00`). Initial cache audit
was design-only; the authorized streaming follow-up below now recovers actual
dictionary evidence. No production source edit, full model load or benchmark
run was performed. Working base is `990760f`; nominal-v1 remains gated.

## Initial cache-only audit: unknown, not ineligible

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

## Authorized streaming result supersedes cache-only uncertainty

`research/tools/NominalNameEvidence.hs` now implements the bounded extractor.
It imports the actual partition and accepted-line parsing functions, retains
only six keys, and passed 16 independent synthetic controls before the scan.
It creates no SemModel or English chart. Dataset reads were explicitly
reauthorized; the completed scan used the shared CCGbank token wrapper.

| Written/effective key | Unpruned POS | Unpruned categories | Lowercase evidence | c77ad00 dictionary predicate on observed inputs |
| --- | --- | --- | --- | --- |
| Abraham | NNP:4 | N:2, N/N:2 | None | Pass |
| Alyssa | None | None | None | Fail: lacks positive dictionary evidence |
| Amiyah | None | None | None | Fail: lacks positive dictionary evidence |

The scenario is explicitly `initial=True, truecase=True`. These are selected
audit parameters matching the inspected default loader clients, not newly
observed runtime flags. All lowercase tag keys are absent, so effective forms
remain written forms. By actual nameStatus logic Abraham is dictionary-backed
NameOnly, while Alyssa and Amiyah are initial NameOrOther casing alternatives.
The observed Abraham N category and sealed N→NP display support investigating
the existing name repair route; N/N alone would not supply this certificate.
Do not infer a runtime typed origin object from that display.

The scan read 1875 files, recorded 125 missing candidate paths, and found zero
unreadable/changed files. It accepted 39604 trees (matching the prior sealed
loader total), rejected zero lines, and skipped 39604 ID/blank lines. Both this
extractor and loadSemModel enumerate 2000 candidate paths and skip absent files;
thus these are counts for the observed loader inputs. The matching total is
corroboration, not proof that the licensed installation is complete. The 125
missing paths prevent an unconditional complete-corpus absence or unopposed
claim. Abraham's pass is conditional on this observed dictionary; the other
two lack the required positive support in it. No count is a universal English
name classification.

No full-clause eligibility is established: complement lexical-N certification,
structural subject origin and root-envelope gates still apply. In particular,
this result does not predict a recovered Abraham gold sentence and cannot
justify fabricating name certificates for Alyssa or Amiyah. It supports a
bounded structural-origin experiment for dictionary-backed names only.

Execution command, source/output/ordered-manifest digests and resource results
are recorded in `research/notes/nominal-name-evidence.md`. No raw training lines,
bulk dictionary or complete path manifest are committed.
