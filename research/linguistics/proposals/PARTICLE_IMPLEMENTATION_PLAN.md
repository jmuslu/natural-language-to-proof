# Concrete adjacent particle lexeme integration plan

Proposal only. Builds on PARTICLE_LICENSING.md (c69ec8e), the accepted offered
head audit (adab222), and independently frozen give_up contract gold. The
standalone `test/ParticleLicensingProposalSpec.hs` is deliberately red against
accepted source: 15/22 pass, seven expected construction failures. No shared
source changes, CCGbank loads or new parser-output gold are included.

## Smallest source change

Keep the new construction local to lexical span creation, rather than adding
an ordinary semantic combination for every VP modifier. Two existing modules
are plausible owners: lexical sense data/template in CCGSem; certificate and
chart insertion in CCGSemParse. Do not expose private chart functions for tests.

1. Define a small English lexical record for the intransitive give + up sense,
   independent of names, datasets and answers. The record specifies finite
   gives and base give morphology, adjacent particle up, unary valency and
   `intransitive-give-up-fixed-effort-v1`. Past/participle/separated variants are
   outside the initial record. Use the existing unary VP lambda template with
   predicate give_up; never rewrite an existing give term or drop an argument.
2. In semParse, next to `ordinary`/`fusedPairs`, construct immutable candidate
   spans from ORIGINAL adjacent tokens and `offeredTags`. Require precisely
   `S[dcl]\NP` or `S[b]\NP` at the head and `(S\NP)\(S\NP)` at up, with
   ordinary unfeatured NP arguments. Match finite/base form with its feature.
   No borrowing from synthesized name/reflexive/relative candidates, composed
   signs, PR, adjective/passive heads or transitive-only alternatives. Record
   token indices, source spans, categories, lexical identity and both scores.
   The particle can lack an individual interpretable meaning: offeredTags is
   the syntactic evidence, and the licensed pair supplies the lexical meaning.
3. Make one span seed for each valid certificate, keyed by `(i,i+2)`, with
   ordinary output VP category and score equal to the two offered log scores.
   No name-dependent bonus or unconditional ranking promotion. Construct a
   `ProvRule` with BOTH original `ProvLex` children and a lexical-construction
   stipulation recording sense, categories and abstraction contract. Initialize
   the normal SSign fields like an ordinary nonstructural unary lexeme; no
   pending identity marker and no extra all-sign payload are needed.
4. Refactor `catCell` to union span-seed categories with its existing ordinary
   leaf/binary categories BEFORE closeCats. The current wider-cell branch only
   combines children; adding semantic seeds alone would lose them in usefulAt.
   Preserve ordinary/fused category-pair checks for other combinations.
5. Refactor semantic `cell` to union certified span signs with its existing
   ordinary leaves/binary combinations, filter seeds through usefulAt, then
   pack and closeUnary once. Backward usefulness may stop at an atomic span
   seed: its two evidence leaves need not have standalone useful semantics.
   Do not call mkLeaf(up) to manufacture an identity term. The certificate is
   built independently of leafSigns, preventing a pruning circular dependency.
6. Preserve ordinary alternatives and chart packing; existing key/category/term
   packing suffices for a completed VP with no future obligations. The selected
   provenance retains its certificate. The raw `syntacticParse` diagnostic
   already admits the observed ordinary IV+modifier combination and needs no
   invented particle category. Its unmodified offered-category result remains
   source evidence, while semParse's internal category table gains span seeds.

The source audit offers gives IV at -4.23 and give IV at -4.35, and modifier up
at -0.56. Stronger ordinary transitive tags must not be relabeled IV. Missing
IV elsewhere still fails this certificate. A separate MWE-owned category
reanalysis would need separate review; it is not this change.

## Public-API red controls and remaining proof obligations

The miniature models set smoothing to zero to isolate actual offered categories.
Tests assert named and independently renamed predicates, quantified subject
scope, negative base-form scope, and success when the constituent pair was not
in learned seen rules. Two positive tests require exact original leaf/source/
span conservation including punctuation; they cannot pass vacuously on no-parse.
All retained root meanings must agree with the independently authored expected
lambda term in these controlled models. Ordinary walk remains unchanged.

Fourteen negative controls prohibit any completed give_up reading when the
particle is absent/wrong, the lemma is wrong, morphology is unlicensed, an NP
intervenes, an NP/PP or unsupported event adverb would be deleted, or offered
head/particle categories are incompatible. These tests do not prohibit other
legitimate independent readings. For the present unsupported-adverb model no
complete reading with give_up is justified; future event semantics would require
a separately reviewed test update, not silent modifier loss.

Before accepting source, extend checks for competing IV/transitive offers and
score/provenance selection, doubled/reversed tokens, a clause boundary between
head and particle, repeated occurrences with distinct spans, and feature-bearing
NP/VP mismatches. Inspect the implementation to ensure all certificate checks
happen before seeding both charts. Surface conservation alone cannot prove
category provenance; inspect the recorded certificate and test mismatch models.
A correct mini success is not evidence of full-corpus beam survival or absence
of wrong retained alternatives. Coordinator alone runs the fresh frozen suite
and required gates after review; evaluate all three frozen cases and preserved
exact panels without changing their gold.

## Linguistic boundary

Unit 2 uses an attested original modifier category and explicit lexical span;
it does not migrate to rebanked PR. Unit 3 instantiates the general unary
lexeme template with an independently licensed sense. Unit 4 preserves the
fixed-effort, time-abstracted DRS and negative claim barrier already frozen.
Boxer/ccg2lambda comparisons and primary citations remain in the licensing
proposal: an event-based PR treatment does not justify identity up or synonym
conjunction in the current direct-unary contract. Directional PP, relinquished
objects, easily/early modifiers and unresolved senses remain outside this rule.
