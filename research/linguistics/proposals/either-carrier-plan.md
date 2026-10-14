# Candidate-local OR evidence through Pipeline and DRS

Design only, against accepted579db46 and unwired kernel9f1a90d plus vertical
plan94bbff4. No runtime integration or corpus authorization follows. This covers
the carrier/lowering seam; lexical pairing, located coordination and protocol
policy remain separately owned and reviewed.

## Candidate carrier: preserve position, not a lookup by formula

Current Pipeline maps SSign roots to Sign then `rootFor` finds the first root
with equal provenance and term to recover score/notes. Enabled mode can retain
distinct roots with different origin maps but identical projections. That lookup
is therefore insufficient. Never encode an origin-map ID in semantic provenance.

Introduce a private backend candidate with accessors; constructors stay within
Pipeline/parser integration:

```haskell
data CandidateId = CandidateId Int  -- sentence-local root list ordinal

data BackendCandidate = BackendCandidate
  { candidateId :: CandidateId
  , candidateSign :: Sign
  , candidateScore :: Maybe Double
  , candidateNotes :: Trace
  , candidateOrigins :: OriginCarrier
  }
data OriginCarrier
  = LegacyCarrier
  | OrdinaryCarrier (Evidence OrOrigin)
  | ActiveCarrier (Evidence OrOrigin)
```

Construct enabled candidates in ONE `zip [0..] roots`. Sign and origin evidence
always come from that exact SSign. Score/notes follow an explicit mode policy:

| Carrier | Score and notes | Origin payload |
| --- | --- | --- |
| LegacyCarrier (omitted/disabled option) | Existing rootFor-derived values, unchanged | None |
| OrdinaryCarrier (enabled but no active pair) | Existing rootFor-derived values, unchanged, even if ambiguous duplicate Sign projections exist | Actual ordered SSign's passive evidence |
| ActiveCarrier | Actual ordered SSign's score and notes; never rootFor | Same actual SSign's active evidence |

The Ordinary asymmetry is deliberate compatibility behavior: passive evidence
belongs to the actual candidate but is not used to relabel its legacy score or
notes, and ordinary lowering stays legacy. Do not advertise ordinary notes as an
exact-origin witness. A future correction of that association is a separate
behavior change with its own review and gates. Active score/notes association is
part of the explicitly enabled active route, not a default behavior change.
Pending is not a carrier constructor:
pending roots must fail existing-plus-pair root admission. Do not recover origin payload or Active score/notes
through `find`, a Map keyed by meaning/provenance, the chosen root, or a second
root traversal with independent filtering. Ordinals do not enter chart packing,
meaning, public source provenance or cross-run identity.

Default/explicit-disabled path builds LegacyCarrier candidates using the existing
rootFor-derived score/notes, preserving even its present behavior. Do not quietly
fix legacy notes/score while claiming byte-identical default behavior. Hand parser
uses LegacyCarrier and rejects the enabled CCG policy at the protocol boundary.
Existing ordinary packing key/tie behavior remains the operator worker's invariant:
the winning sign carries its own complete payload; unavailable passive evidence
cannot cause a losing ordinary sign to win. Active packing includes reviewed origin
identity; the carrier introduces no additional grouping or sorting.

`backEnd` receives `[BackendCandidate]`, projects `candidateSign` only where old
Sign operations need it, and translates each candidate in original list order.
It chooses the first candidate exactly as before. Every candidate has one
ReadingResult, including type/lowering failures; no `mapMaybe`, rescue by the next
successful reading, or successful-only zipper. `srChosen`, `srForm`, `srDRS` and
every `rrSign/rrScore/rrTrace` retain their established ordering relationships.
All post-DRS hooks use this candidate's sign and normal form. The mode-dependent
score/notes policy above applies to every reading, including failures. Default callbacks
and `provIndexFor` stay unchanged; predicate provenance is outside this repair.

## Origin representation and lowering API

The generic kernel checks maps, typing and transport; it cannot certify lexical
origin. `OrOrigin` must be opaque outside the lexical/coordination producer.
Its read-only view exposes one exact OR source occurrence and zero or one licensed
either occurrence, including SourceId and spans. Paired markers are admitted by
reviewed whole-span/category certification, not by this DRS consumer. Ordinary
origins have no marker. A sentence's token table is used only to validate supplied
occurrences, never scanned to discover an either for a formula.

Proposed explicit API (names illustrative, result contract binding):

```haskell
data OriginLoweringFailure
  = EvidenceUnavailable Failure
  | SnapshotMismatch
  | MissingOr Path
  | UnexpectedOrigin Path
  | InvalidOperatorSource Path
  | ReusedPairSource Path Path
  | UnsupportedActiveAttitude Path
  | UnsupportedActiveTerm Path
  deriving (Eq, Show)

lowerWithOrigins :: SourceContext -> ProvIndex -> Prov
                 -> Term -> Evidence OrOrigin
                 -> Either OriginLoweringFailure DRS
```

`SourceContext` is immutable original sentence source/tokens plus explicit policy;
it does not include expected gold or benchmark identity. Failure values identify
structural occurrence paths and reason, never silently pick a different map.

For ActiveCarrier, require available kernel evidence with exact snapshot equal
to the actual normalized semantic term; ordinary formula equality/canonicalAC
is NOT a map join. The exact structural check detects stale attachment, not lexical
licensing. All OR nodes, including plain OR nested alongside a paired one, need
origins. Validate exact source leaves and paired-marker uniqueness according to
the reviewed lexical certificate. Do not infer source from reduced predicate names.
Failure rejects this reading's DRS without erasing its parser candidate.

For OrdinaryCarrier, preserve legacy normalization/toDRS and existing provenance,
including when passive transport is unavailable. This is the vertical plan's
ordinary-mode compatibility promise, not permission to downgrade ActiveCarrier.
There is no Active→Ordinary fallback. LegacyCarrier always calls existing toDRS.
If a future optional route changes ordinary lowering too, that needs a distinct
explicit reviewed compatibility contract; it is not slipped into this proposal.

## Consume all and only the map on the semantic tree

The occurrence-aware lowering walker takes `(path,term,remainingOrigins)` and
returns `(DRS,remainingOrigins)` or a typed failure. It mirrors existing toDRS
box construction, preserving its scoped referents and predicate provenance:

| Term at path p | Child paths / operation |
| --- | --- |
| TOr a b | Lookup and delete **exactly p**; lower a at p+[0], b at p+[1]; form COr with operator-only provenance. |
| TAnd a b | Lower children at p+[0]/p+[1], merge child DRSs in existing order. Do not normalize/reassociate here. |
| TNot a | Child p+[0], preserve negative box. |
| TImp a b | Children p+[0]/p+[1], preserve implication boxes. |
| TExists v ty body | Body p+[0], add v to that box as existing toDRS does. |
| TForall v ty (TImp a b) | Antecedent p+[0,0], consequent p+[0,1]; add v ONLY to antecedent. No flattening shortcut may drop the body's path component. |
| Other TForall v ty body | Body p+[0] as consequent of empty-restrictor implication; v in antecedent. |
| Predicate/equality/constant leaves | Existing direct lowering, no map consumed; reject any unexplained descendant origins. |

An initial exact domain check and terminal empty-map check are both required;
one protects coverage, the other catches a walker branch skipping origins.
A missing entry is MissingOr; leftover path is UnexpectedOrigin. Do not reuse an
origin after deleting it, search by equal subformula, or collect ORs from the DRS
and zip them with a pre-normalization map. Term paths are distinct from DRS paths:
the forall special case makes that distinction observable.

For the first active route, any attitude/world-deindex lowering is explicitly
UnsupportedActiveAttitude; deindexWith rewrites require reviewed path transport.
Do not recurse through it with stale paths or return the legacy opaque
UNSUPPORTED atom on an active origin-bearing unsupported term. Atomic proposition
positions that contain OR beneath an unsupported term must fail before any box
escapes. Supported quantifier/negation lowering is a consumer ability, not proof
that the current chart's pairing rules can derive those constructions.

COr provenance must be `provRule "or-occurrence" [orLeaf]` for plain OR or
`provRule "paired-or-occurrence" [eitherLeaf,orLeaf]` for paired OR, in source
order. Neither contains branch provenance, other ORs, the root fallback or an
unrelated either. Exact source/span leaves are authoritative; the rule label is
display only. Keep branch predicates' ordinary provenance unchanged. Existing
export ambiguity checks stay; valid occurrence-local COr provenance permits
precise flags, but a flag is never NOT(AND) or a claim of exclusivity.

## Failure and result API

Add a typed optional lowering failure alongside ReadingResult (e.g.
`rrOriginFailure :: Maybe OriginLoweringFailure`, Nothing on all legacy paths).
This enables public tests without matching English diagnostic strings. A typed
term with unavailable active origin keeps `rrSign`, `rrScore`, its candidate notes
and `rrForm=Just nf`, with `rrDRS=Nothing` and the typed failure plus diagnostic.
No claims are fabricated. Selected failure leaves selected sentence DRS absent;
a later successful reading remains a later alternative. Existing type-check
failures keep their old representation and must not be reclassified as origin
failure. Error/success exporter responses echo the actual execution policy under
the separately reviewed versioned protocol.

## Concrete public acceptance controls

Proposed public testing surface: a diagnostic miniature Pipeline entry point
with explicit policy, ordinary `ReadingResult` including typed failure, and a
read-only `originOccurrences` projection. Keep OrOrigin constructors private;
negative integration tests obtain producer failures using malformed input/source
certificates at the public producer API, not forgery through renderer constructors.
A separate generic-map validator may accept synthetic map fixtures for path error
unit tests; passing that validator never manufactures a licensed OrOrigin.

Required future executable controls (not yet claimed implemented):

1. TT/TF/FT two-clause equal-formula OR fixtures retain distinct local flags,
   correct source/span leaves and unchanged scoped DRS/claims. Example terms:
   `Imp(Or(P,Q),Not(Or(P,Q)))` and forall wrapping it. Paths are `[0]`/`[1,0]`
   without forall, `[0,0]`/`[0,1,0]` with forall. A global either scan fails TF/FT.
2. Two retained candidates with identical Sign projection but different active
   maps retain their own flags/notes/scores. Their root ordinal remains attached
   through all-reading translation. No equality join or first rootFor match.
3. First candidate type failure, first candidate active lowering failure, and
   later success preserve all positions and selected failure. Same-score packing
   retains earlier payload; higher-score winner carries its own payload.
4. Missing, stale, surplus and reused-pair origins produce the exact typed
   failures above, no DRS. Active attitudes explicitly fail; default attitudes
   remain byte-identical. Test absence of NOT(AND) in the inclusive success case.
5. Every leaf in each COr condition provenance is its own OR or licensed either;
   branch content and another clause's marker must be absent. Equal formula
   branches cannot alias occurrence provenance. Claim scope/multiplicity unchanged.
6. Omitted/disabled policy and enabled-but-ordinary signs preserve exact legacy
   outputs including rootFor-derived notes/score; enabled active mode alone takes
   the new candidate-local lowering. Verify selected and all readings, not only
   the exported selected object. No default or policy/schema drift allowed.

The supplied7 public baseline controls exercise actual toDRS today: forall/OR/NOT
scope is intact, but both equal OR occurrences share fallback provenance. They
are observation controls, not a mock carrier and not passing integration tests.
Their scope assertions should remain unchanged in the new lowerer. Mutation of
any carrier/map association must fail the future controls before source approval.

Review order: carrier-only candidate plumbing with legacy equivalence; independent
located normalization and producer review; occurrence-aware lowerer and all-reading
public fixtures; protocol binding; then coordinator release gates and explicitly
authorized diagnostics. No orphan kernel landing, new root denominator, semantic
shortcut, dataset-based XOR inference or corpus launch is authorized here.

Operator coordination note: subsequent kernel fixtureb7cf68a exercises the actual
`coordTerm` GQ→t shared-subject wrapper, with OR initially at[0,1,0], then root
for a named application or[0,1] under existential/universal subject structure.
The carrier consumes the **final snapshot's** paths; these are not interchangeable
with lexical or pre-normal paths. Its32 kernel controls are transport evidence,
not a substitute for this proposal's final DRS/claim and candidate association tests.
