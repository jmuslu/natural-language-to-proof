# Strength: exact support before numerical confidence

Status: Phase C implemented, 2026-10-13 New York (2026-10-14 UTC). The tested candidate is integrated into
Provenance, Genealogy, Fusion, and the typed Claims bridge after the Phase B
checkpoint. The production-facing Strength suite passes 53/53 and the existing Substrate
suite passes 114/114 against the integrated sources. The verdict-forgery compile
negative rejects the expected type mismatch. All mandatory combined gates passed (1,138 checks across eleven suites). Scratch
experiments live in the ignored `research/runs/strength-design/`; production uses
only the existing modules, with no parallel subsystem.

## Decision

Use a finite antichain of sets of evidence tokens for each claim. An environment
is one sufficient set of evidence; different environments are alternative proofs.
Combine premises by union inside an environment and alternatives by union of the
labels, removing redundant supersets. Every token retains its evidence class and
source dependencies. A claim is strongly supported when some surviving environment
uses only oracle evidence. A report can remain available as attributed evidence
without becoming an asserted or oracle-confirmed fact.

This is a deterministic support definition, not a probability estimate. Duplication,
long chains, and circular agreement cannot manufacture oracle evidence. Independent
support survives source withdrawal. A class belongs to an evidence path: it must not
be stored as a separate, permanently maximal attribute of the claim.

## A concrete class-correlated example

Suppose p has an oracle confirmation a and a report from Bob b; q has oracle
confirmation c. A confirmed rule r establishes p AND q implies z. Then:

```
support(p) = atom(a) + atom(b)                 = {{a}, {b}}
support(q) = atom(c)                          = {{c}}
support(z) = atom(r) * support(p) * support(q) = {{r,a,c}, {r,b,c}}
```

Initially z is **grounded** (some environment is entirely oracle evidence) and
**supported** (some environment exists). Withdrawing a leaves `{{r,b,c}}`: z
remains supported testimony but loses grounded status. Withdrawing c removes both
environments, so z becomes unsupported. Duplicating Bob's report changes nothing.
No number represents truth probability; the surviving token classes explain why
the distinction holds. The `supportPlus`, `supportTimes`, `supportEnvironments`,
and `withdrawSource` APIs implement these operations. Source-dependent rules such
as r must appear among the antecedents of a graph justification.

## What the repository computes before this change

`Provenance.Prov` is the lexical/semantic derivation tree. `provSources` unions its
source leaves into flat lineage; it loses the distinction between conjunctive and
alternative support. Keep this tree for traceability. Do not claim that this fold
alone implements source-sensitive alternative derivations.

`Genealogy.grounded` computes Boolean support: AND across a justification's
antecedents, OR across justifications, iterated from the empty set. Only an empty-
antecedent premise with verdict `Confirmed` seeds this closure. It already prevents
an unseeded cycle from grounding itself. `retract` flips a node verdict and computes
the difference between old and new closures, preserving independently grounded
conclusions. These are real existing guarantees under the graph's input assumptions.

`independentSupports` is only structural ancestry: it unions every ancestral premise
for each immediate justification, ignores current verdicts, and merges nested
alternatives. `rrSurvived` also counts never-grounded downstream nodes, while
`survivesRetractionOf` says an absent node survives. Five scratch regressions reproduce
these problems (0/5 pass before a fix).

`Fusion.fuse` sorts and deduplicates `Confirmed` canonical conditions and retains a
global oracle-name list. It does not retain per-claim alternative evidence.
`entailedFrom` computes a small material-implication closure without proof labels.
Neither it nor Genealogy currently supplies numerical confidence. Reward weights
in `Reward.hs` are stipulated optimization weights, not evidence-strength values.

## Algebra

Let E be a finite set of immutable evidence-token identities. A label L is an
antichain of subsets of E under subset inclusion. Write min(A) for the distinct
subset-minimal members of a family A.

```
0       = {}                    no sufficient environment
1       = {{}}                  no evidence required
atom(e) = {{e}}
L + M   = min(L union M)
L * M   = min({a union b : a in L, b in M})
```

Examples: `{{a},{a,b}}` normalizes to `{{a}}`; `{{a},{b}}` retains two alternatives;
`{{a}} * {{b},{c}}` is `{{a,b},{a,c}}`. The distinction between 0 and 1 is essential.

This is PosBool(E) represented as a minimal positive disjunctive normal form, also
an ATMS-style minimal-support label. It is deliberately less informative than the
polynomial semiring N[E]: it forgets proof counts and repeated use of an input. Green,
Karvounarakis and Tannen's framework motivates the two operations; their positive-
Boolean instance and finite-lattice treatment are the relevant specialization.
[Green et al. 2007, §§3, 5, 8](https://www.cs.ucdavis.edu/~green/papers/pods07.pdf).

A proof of the laws follows from the interpretation
`U(L) = {active subsets V of E : some a in L is a subset of V}`. Minimal antichains
are a unique representation of these upward-closed sets. Under U, addition is set
union and multiplication is set intersection. Hence both operations are associative,
commutative and idempotent; multiplication distributes over addition; 0 and 1 are
identities for addition and multiplication; 0 annihilates multiplication; both lattice
absorption laws hold. These are properties of this chosen algebra, not of every
semiring. Its natural order is `L <= M iff L + M = M`, not ordinary inclusion of
antichain members: an update can replace a larger environment with a smaller one.

De Kleer's labels similarly retain minimal environments and combine antecedent labels
by all unions of one environment from each antecedent, then remove supersets. The
full ATMS also removes inconsistent environments and manages nogoods. This proposal
initially adopts its support labels, not every ATMS feature.
[de Kleer 1986, §§4.3, 4.7–4.9](https://dekleer.org/Publications/An%20Assumption-Based%20TMS.pdf).

## Evidence and admission

Each token is identified by its immutable tuple of node ID, exact claim, evidence
class, sorted source dependencies, and extraction provenance. Repeating the same
tuple is idempotent. Required classes are:

- Oracle evidence: can only be minted from a `Confirmed` capability; retains the
  exact confirmed claim and oracle identity. It does not mint new capabilities.
- Asserted-unconfirmed evidence: a top-level assertion, with source provenance.
- Reported evidence: the complete ordered attribution chain, including nested holders.
- Presupposed evidence: keeps that status; accommodation does not certify truth.
- LLM-translated evidence: model/request identity and original sentence; always hearsay.

Do not impose an arbitrary numeric ordering on presupposition versus reporting.
For each environment, retain the set of non-oracle classes it uses. Across alternatives,
keep these classifications tied to their actual token environments. A separate pair
`(maximum class, source label)` is incorrect: removing the oracle path could leave
its class attached to a surviving report.

Generic functions, placed in existing `Provenance.hs`, are an abstract
`Support a`, `supportZero`, `supportOne`, `supportAtom`, `supportPlus`, `supportTimes`,
`supportEnvironments`, `supportFromEnvironments`, `supportHolds`, and `supportWithout`. The constructor stays hidden so every
value is normalized. Evidence metadata and graph interpretation belong in Genealogy,
which already imports Oracle; avoid making Provenance import Oracle and creating a
module dependency cycle.

Oracle evidence is created only by a function accepting `Confirmed`, deriving the
claim from `confClaim` or checking exact equality against the destination. A bare
`Verdict.Confirmed` is not a capability. The current public graph constructors and
`setVerdict` can manufacture Boolean groundedness; no new certified output may trust
that route. Migration must separate raw verdict bookkeeping from capability-bearing
seeds, and protect token-to-claim binding against record updates.

`Fused` remains a certified base whose constructor is hidden. Weak labels do not enter
`fusedClaims`. A logical consequence receives proof support, not a new `Confirmed`
capability. A solver proving a consequence of asserted-unconfirmed premises verifies
conditional entailment, not the real-world truth of those premises.

Evidence-source dependencies are explicit. The current admission functions treat
every `provSources` leaf as required, conservatively: they do not distinguish a
textual mention from a trust dependency within one supplied provenance tree. An
independent oracle confirmation survives document withdrawal only if its supplied
provenance does not depend on that document. Oracle and speaker dependencies use
reserved `oracle:<name>` and `speaker:<rendered holder>` source namespaces; callers
must not reuse those names for document IDs. Retraction of a speaker applies to
every holder in the complete nested report chain, not just the outermost holder.

## Graph evaluation and exact withdrawal

For a finite graph and its fixed finite token inventory, start every label at 0 and
iterate:

```
L_next(n) = seed(n) + sum_j(product_p(L(p)))
                       j targets n, p ranges over j's antecedents
```

Only explicit admissible evidence contributes seeds. The current empty-antecedent
`premise` convention does not imply the empty product 1: otherwise every unconfirmed
premise would become unconditional. Logical axioms, if introduced, need a separate
explicitly justified representation. A source-dependent rule contributes its own
evidence token; a string-valued rule name is not sufficient to make rules retractable.

The operator is monotone in the natural order. There are finitely many positive
Boolean functions on E and finitely many graph nodes, so iteration from 0 terminates
at the least fixed point. Every nonzero environment corresponds to a finite derivation
from seeds. An unseeded cycle remains 0. A seeded cycle can transmit the seed but cannot
make evidence disappear. This proof relies on a finite fixed token set; unrestricted
function symbols or generation of fresh tokens during closure invalidate that premise.

For disabled tokens D define `R_D(L) = {a in L : a intersects D = {}}`.
Remove complete environments; never delete just the disabled atom from an environment.
`R_D` preserves 0, 1, addition and multiplication. For these finite positive support
equations, filtering the completed labels therefore agrees with recomputing the least
fixed point with disabled seeds. This is the exactness criterion the implementation
and generated retraction benchmark must test.

Graph API: `withdrawSource :: SourceId -> Genealogy -> (Genealogy, SupportChange)`.
Record revocations in the returned graph, disable every affected seed, recompute from
0, and report (a) all-support losses, (b) losses of oracle-only support, and (c) still-
supported affected conclusions. Node-level `retract` remains distinct and disables all direct evidence at that
node, leaving independent derived support intact. More selective per-token
withdrawal is not exposed yet. A subject survives only when it was supported
before withdrawal and remains supported afterwards. A source withdrawal is not itself
a proof of the negation of the withdrawn claim.

For Fusion, a claim-to-label map sums confirmation identities `(oracle name,
exact canonical claim)`, preserving the abstract certified boundary. Two genuine
oracles with the same name are deliberately indistinguishable in this map; callers
requiring independent withdrawal must give them distinct names. Mechanical detachment multiplies the implication's label with all
antecedent labels, then adds alternative derivations. Claims supported only by weak
classes remain available in attributed graph context, outside the certified base.

## Candidate comparison and experiments

The design does not reject Boolean or Viterbi as invalid algebras. Boolean supports
existing exact graph recomputation but forgets which evidence suffices. Viterbi
(max, multiplication) and tropical (minimum, addition) retain a best weight/cost and
likewise require additional provenance or graph recomputation for source withdrawal.
Neither supplies calibrated source reliability by itself. Full polynomial provenance
preserves multiplicities but cyclic derivations can require infinite series, excessive
for the present retraction requirement.

The scratch fixtures use weight 1 for an oracle and 3/10 for a report solely to compare
representations. These numbers are not proposed production parameters.

| Fixture | Boolean | Viterbi | Token antichain |
|---|---|---|---|
| Oracle a AND report b | supported | 3/10 | `{{a,b}}`, weak |
| Oracle a OR report b | supported | 1 | `{{a},{b}}`, oracle alternative exists |
| Withdraw a from previous row | supported after recomputation | 3/10 after recomputation | `{{b}}`, report only |
| Duplicate report b | supported | 3/10 | `{{b}}`, unchanged |
| Oracle a versus independent oracle c | same scalar | same scalar | distinct retractable dependencies |

The strongest-class/source-label product counterexample is tested explicitly: its
retained strongest class remains oracle after removing a, while the correlated token
label correctly reports only b. Boolean and Viterbi are compared at the scalar boundary;
a full graph can repair their information loss by recomputation.

Exact commands and predictions were recorded before execution in `research/LOG.md`.
The prototype exhaustively checks all 20 antichains over three tokens, 8,000 triples
for each ternary law, 400 pairs for binary laws, and all eight token valuations.
Graph checks enumerate all 512 directed three-node unary graphs (including self-loops),
eight seed sets and eight valuations/withdrawal sets: 32,768 configurations for each
closure/retraction property. A separate fixture checks conjunction plus an independent
alternative. A scratch-only missing test type annotation caused the first algebra run
to fail compilation and was fixed before executing the unchanged assertions.

Final prototype results: 27/27 checks pass. The first run's harness-only type error
was corrected without changing assertions; the rerun exited 0. All 32,768 valuation
cases and all 32,768 withdrawal cases pass; all 4,096 graph/seed pairs agree when edge
order is reversed. These finite tests complement, rather than replace, the proofs
above. The five pre-migration Genealogy regressions all fail as predicted.

A targeted additional comparison passes 3/3 checks: reusing one report token gives
`atom(b) * atom(b) = atom(b)`, while direct Viterbi multiplication gives
`(3/10)*(3/10) = 9/100`. Consequently a best per-environment weight calculated from
antichains is not a general Viterbi-semiring homomorphism. The table's particular
oracle/report fixtures agree with direct Viterbi values, but this agreement must not
be generalized to multiplicity-sensitive calculations. Exact command:
`runghc -iresearch/runs/strength-design research/runs/strength-design/CandidateComparisonSpec.hs`.

The first production-facing candidate run passed 45/45 checks against isolated
copies of the three existing modules. This repeats the laws and graph enumeration
using the actual proposed public interfaces, covers the five pre-migration defects,
and adds admission/class/source and Fusion detachment checks. A compile-fail fixture
rejects passing `Verdict.Confirmed` to `addConfirmedNode` (which requires an abstract
`Confirmed` token). The expanded run passed 53/53, including shared-speaker/document distinctions,
multiple oracle alternatives at one node, stale incident-edge invalidation, and
exact withdrawal reports. The existing Substrate suite passed 114/114 with typed
confirmation fixtures and the revised Claims bridge. The optimized 53-check suite
took 6.62 seconds wall time and 21,760 KiB maximum RSS on this shared run host;
concurrent activity and build optimization affect that measurement. All mandatory
gates remain required before claiming Phase C complete.

## Integration and trust boundary

`Genealogy` and `Evidence` have hidden positional constructors. Graph accessors
return immutable snapshots; exporting a descriptive `OracleConfirmed` class enum
does not provide an admission function that accepts that enum. `addConfirmedNode`
derives its claim from the actual token; `addNode` and `setVerdict` only record
diagnostic verdicts. Replacing node content removes its direct evidence and all
incident justifications. Refuting or uncovering a node removes its oracle evidence;
subsequently assigning a bare Confirmed verdict cannot resurrect it. Only a fresh
capability-backed admission can do so.

Same-claim admissions accumulate alternatives at one node. `addAssertedNode` needs
a structurally extracted assertion witness; `addReportedNode` and
`addPresupposedNode` preserve their typed status; `addTranslatedNode` accepts bare
logical output only into the explicitly weak translation class. Their model label
and provenance must be supplied by the translation caller. The legacy
`Claims.genealogyOf` bridge admits confirmed facts through `confirm` and preserves
unconfirmed/refuted facts as weak assertions. It continues to exclude reported and
presupposed content; explicit callers can add those with the new typed APIs.

`independentSupports` retains its premise-node return type, now calculated from
minimal oracle environments instead of structural ancestry. Its independence means
resilience to node retraction, not independent document sources: two nodes can share
a source. Exact source dependencies are available through `supportOf` and each
`Evidence` token. No graph label can construct a certified `Fused` value. Graph
justifications are still trusted inputs; an arbitrary asserted rule name is not an
entailment certificate. Source-dependent rule evidence must be an explicit
antecedent, as tested by the weak translated-rule fixture.

`Fusion.entailedWithSupport` multiplies each implication's confirmation dependencies
with all antecedent supports and adds alternative proof environments. The existing
material-implication reasoner cannot flatten an existential consequent into free
literals; both antecedent and consequent universes must be empty. Quantified rules
remain a scoped solver's responsibility.

## Limits and integration tests

Finite termination does not mean polynomial cost. A label can contain an exponential
number of pairwise incomparable environments, up to the largest antichain of subsets
of E. Record runtime and label sizes. Any implementation cap must mark provenance
incomplete and cannot preserve an unconditional exact-retraction claim.

Measured label growth matches that limit. For `product_i(atom(2i) + atom(2i+1))`,
with n independent pairs, the candidate produces the following complete labels:

| n | Minimal environments | Tokens per environment | CPU seconds |
|---:|---:|---:|---:|
| 1 | 2 | 1 | 0.000201 |
| 2 | 4 | 2 | 0.000037 |
| 4 | 16 | 4 | 0.000130 |
| 6 | 64 | 6 | 0.000789 |
| 8 | 256 | 8 | 0.006453 |
| 10 | 1,024 | 10 | 0.076034 |

The small times include first-use/runtime noise and are not scaling estimates.
The environment counts are exact; the same family has 1,048,576 alternatives at
n=20 without needing an empirical run to establish that combinatorial bound. The
current implementation recomputes labels on graph queries and uses simple subset
normalization; large graphs need measured engineering work. No truncation is hidden.
Scratch measurement command and fixture are recorded in LOG C5.

Support bookkeeping assumes justifications are valid inferences supplied by a trusted
reasoner. A public arbitrary `derivation` constructor does not prove its named rule.
Classical negation is not negation-as-failure. Track positive and negative claims with
separate labels and attribute both sides of contradictions; do not silently explode
or delete inconsistent support without a documented reasoning policy.

Required migration tests include: unseeded and seeded cycles; withdrawing the sole seed;
independent surviving alternatives; withdrawing rule evidence; same-speaker different-
document dependencies; full nested attribution chains; an oracle path withdrawn while
hearsay remains; duplicated hearsay; absent/never-grounded survival; typed rejection of
manufactured oracle evidence; and exact comparison with deletion plus recomputation.
The five original graph regressions are now covered by the production StrengthSpec suite; all pass.
