# Particle head evidence and bounded next step

This audit settles the outstanding head-availability question in
[PARTICLE_LICENSING.md](PARTICLE_LICENSING.md), commit c69ec8e. It licenses no
source edit. The actual offered alternatives include the required finite and
base intransitive heads. A missing-IV repair is therefore unnecessary for these
observed contexts.

## Sealed evidence

Root's accepted diagnostic batch is `research/runs/expanded-gold167/explain.log`;
the focused offered-alternatives batch is `lexical-alternatives.log` in that
same ignored run directory. This worker read existing logs and launched no
parser or corpus load. The Explain manifest records source commit
`183f0ec3c3f6bdca0be57592a74ec7899738eeb8` and binary SHA256
`a3a2191ae7d6bd4ba46d559eed8d441b21399531f150e851e77e4dac7c0f5bf3`.
The focused log SHA256 at inspection is
`8697b32ee6a7ec1c293b0f6f41b0a0ba9edbadbcf3010b0b285bbda4c456a7ab`.
The focused batch ends after four completed diagnostics at the Explain prompt.

| Input/token | Offered category | logP | Semantic admission |
| --- | --- | ---: | --- |
| Raul gives up. / gives | `S[dcl]\NP` | -4.23 | open template alternative |
| same / gives | `(S[dcl]\NP)/NP` | -2.35 | best interpretable tag, open template |
| same / gives | `((S[dcl]\NP)/NP)/NP` | -0.58 | offered, dropped for no meaning |
| Raul does not give up. / give | `S[b]\NP` | -4.35 | open template alternative |
| same / give | `(S[b]\NP)/NP` | -1.82 | best interpretable tag, open template |
| same / give | `((S[b]\NP)/NP)/NP` | -0.76 | offered, dropped for no meaning |
| both / up | `(S\NP)\(S\NP)` | -0.56 | offered, dropped for no meaning |
| both / up | `(S[adj]\NP)/NP` | -3.03 | best interpretable tag, open template |

These are offered lexical choices, not selected derivations. Explain explicitly
says no selected derivation. The focused display abbreviates some other dropped
tags; it suffices to establish presence of the required alternatives, not an
exhaustive absence claim about all remaining categories. The full 13-input
batch also observes Ada gives up. failing, but the focused batch does not
independently list Ada's complete alternatives. No universal contextual or
morphological availability claim follows.

All three pre-frozen particle gold rows have baseline NO-PARSE. Gold was frozen
in b77a588/b649e61, with contract `intransitive-give-up-fixed-effort-v1`, before
this observation. No meaning or annotation is revised from the output.

## First divergence and Units 2/3/4

Unit 2: finite/base IV heads are available and semantically admitted; the
original modifier-shaped up category is offered but has no admitted meaning.
Category-only parsing reaches S, while no semantic derivation reaches S. This
locates a lexical-construction gap before final DRS/claim scoring, though it
does not prove that adding one entry alone survives chart pruning or ranking.

Unit 3: use the reviewed adjacent two-token lexical certificate and the existing
unary template `lambda S.S(lambda x.give_up(x))`. The IV evidence is syntactic
licensing, not a derivation of the idiomatic sense from ordinary give. Preserve
both original leaf spans and offered categories, sense/valency record, scores
and finite/base feature. Do not apply the transitive give meaning to fewer
arguments or assign up an identity function. A lexeme-span construction must be
recognized in category feasibility as well as semantic chart seeding. The
lower-scored IV path must remain reachable; neither beam success nor selected
meaning correctness has yet been tested.

Unit 4: subject composition yields the already frozen unary claim for Raul or
Ada; ordinary negation encloses the entire predicate in the negative case.
The scope and fixed-effort/time-abstraction contract remain unchanged. Directional
PP, transitive relinquishment and event/disposition modifiers have no new
meaning license; preserving every token is mandatory. Existing alternative
readings are not silently erased to force selection of the new sense.

## If an IV is absent elsewhere: separate reanalysis, not argument deletion

A language MWE lexicon can legitimately declare a complete expression's own
valency independently of its component word's ordinary valency. Such a future
entry would carry lexical identity, sense evidence, morphology, token-span
pattern and an explicit finite/base output category. Its provenance would say
MWE category reanalysis, recording unavailable or incompatible component
categories, rather than pretending original CCGbank offered an IV. This differs
from taking an existing transitive semantic term and deleting its unsatisfied
object: a new complete lexical sense has its own independently justified frame.

That broader policy is not needed or authorized here. Before adopting it, require
independent category-reanalysis controls, complete NP/PP continuation tests,
negative and quantified scope, inflection tests, and preservation of competing
ordinary senses. No arbitrary head-plus-up concatenation, name/item whitelist,
text replacement or generic identity-up is permissible. If evidence or frame
selection is unsettled, retain failure rather than invent a category repair.

## Comparison and review gate

The original CCGbank particle analysis and Boxer/ccg2lambda comparison remain
those documented with primary-source citations in PARTICLE_LICENSING.md:
original categories do not require rebanked PR subcategorization; Boxer motivates
lexical and event-participant information, while ccg2lambda's rebanked PR event
entries do not provide this idiomatic direct-unary meaning. Their event design
cannot be copied as an identity modifier or asserted equivalent to this contract.
No new claim about those external systems is inferred from these local logs.

The next reviewable candidate is exactly the existing observed-category lexical
span certificate, with independent corpus-free positive/negative scope and
span-conservation tests before source changes. Required rejection controls
include absent/wrong particle, wrong lemma, NP/PP continuation, separated tokens,
unsupported modifier deletion, and unseen morphology. Test category-chart
pruning and alternative rankings explicitly. Run the whole frozen fidelity set
only through the coordinator's authorized gated process. This evidence settles
one precondition, not overall implementation approval or the ProverQA gate.
