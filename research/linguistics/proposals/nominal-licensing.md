# Nominal licensing after the failed default activation

Keep `astra/nominal-candidate` experimental. A small **predication fragment** can
be specified, but neither its safe integration nor a recovered exact score is
proved. The sealed run rules out unqualified `(S\NP)/NP` copula activation. The
local typed operator remains useful; a correct local lambda term does not license
every CCG derivation that can feed it.

This proposal inspects the accepted has-integration and rejected
nominal-integration `fresh.json`/`fresh.observations.jsonl` artifacts under root
`research/runs/`. It executes no parser, model or answer benchmark. The manifest
covers all15 no-parse→exact gains,6 exact→wrong regressions and28 newly wrong
cases, not just the easiest examples. See the per-ID audit below.

## What must be distinguished

**Unit 2.** Ordinary nominal classification permits an overt determiner phrase
as a copular complement. That does not imply that every category NP derived by
any unary rule is licensed as an equative complement. A category is a composition
contract; category/type alone does not identify the lexical construction. The
existing generic `N→NP` rule is an explicitly stipulated interpretation, not
English permission to turn any bare adjective or singular count noun into an NP.

**Unit 3.** Bare generic `cats` and explicit `every cat` may both normalize to
`λk.∀x(cat(x)→k(x))`. A Lambda-only rule cannot distinguish these identical terms.
A POS-tagged NP is not sufficient evidence of the required reference either:
selected `American` NPs caused new wrong equalities. The relevant distinction
must be licensed in the derivation before its evidence is erased.

**Unit 4.** Retain the candidate's direct-classification convention for positive
existential predicates, with one subject and no extra identity witness. Keep the
ordinary indefinite argument's witness. Negation, disjunction and quantifier
scope retain the existing independent gold. No global existential/equality
contraction or discourse-reference rewrite is proposed.

The academic comparison remains the same but its limit is now explicit.
Bos2008 §3.2 distinguishes lexical meaning from category/type; §3.3 separates
construction from resolution. The pinned ccg2lambda nominal equality copula
shows a compositional equality interpretation for a supplied NP; it does not
prove that this parser's generic N→NP supplies a faithful NP analysis. Neither
source validates using POS alone to force an adjectival demonym into an equation.
See [REFERENCES](../REFERENCES.md) and the pinned
[copula templates](https://github.com/mynlp/ccg2lambda/blob/a68cb264413791150011c347c64a7b35e2f7270d/en/semantic_templates_en_emnlp2015.yaml#L439-L458).

## Three implementation choices

| Choice | What it knows | Assessment |
|---|---|---|
| Change only COPULA's lambda recognizer | Normalized Q | Cannot separate bare generic from overt universal; insufficient |
| Reject any `bare-np` note, or only a note matching the complement span | Some history/spans | Whole-sentence scan rejects legitimate generic subjects; whole-span scan misses branch-local coordination and confuses nested NPs |
| Construction-local NP/VP license | The actual argument derivation and its allowed continuation | Sufficient information in principle; requires a small explicit propagation contract |

Do not build a general provenance framework. If the existing derivation tree
retains enough categories and lexical decisions, a local proof checker can use
it. Current `Prov` rules/leaves plus freely propagated notes are not automatically
such a checker: rule names do not fully retain the consumed child categories.
A small constructor-indexed license on participating signs is preferable to
reconstructing missing syntax from note spans. Include the license in chart
packing identity, because two identical Q terms can have different permitted
uses. No source implementation is authorized by this document alone.

## A precise staged fragment, not the final coverage target

The minimal candidate worth testing is **overt positive-indefinite predication**.
Keep reference/universal/negative-Q equative fallback available in operator-level
research, but do not expose it as a default lexical route until contextual
reference licensing has been addressed. This leaves `Max is Stella` and
`Max is every cat` unsupported by the staged parser; it does not change their
gold or pretend that equative English is outside the overall goal.

Use the ordinary category derivation, without inventing article identities:
`a/an:NP[nb]/N`, nominal copula `(S[dcl]\NP)/NP`, and NP subject. The a/an meaning
remains `λP k.∃x(P(x)∧k(x))`; COPULA elaborates the licensed complement property
and applies the subject once. The license should certify these exact local steps:

1. **Nominal leaf:** a direct a/an determiner application to a licensed lexical
   N yields a predicative-complement certificate. Initially modified, relative,
   quantified and structurally unknown noun constituents are unsupported. This
   is a declared grammar fragment, not a predicate-word list. Unknown content
   words still require the normal lexical/category evidence; the license cannot
   manufacture nouns to match a benchmark.
2. **Complement coordination:** lexical AND or OR combines two independently
   certified complements, preserving the complete tree and both properties.
   Require every branch. Do not treat a comma as AND in an OR list; comma-list
   structure needs its own reviewed rule. Mixed adjective/nominal coordination,
   relative attachments and type-raised NP analyses are unsupported initially.
3. **Copular VP:** direct lexical copula plus certified complement yields a
   pending nominal VP. Ordinary adjectival copulas remain separate. Preserve
   this capability through exactly the supported VP-negation composition,
   retaining the subject-wide scope rule; do not silently release it as an
   unrestricted VP that can enter relatives or arbitrary crossed composition.
4. **Subject:** accept a directly licensed rigid NP from the existing explicit
   POS name evidence, or an overt supported determiner+lexical-N derivation.
   Do not certify an unseen initial capital merely because a name alternative
   happens to win. Bare generic subjects and relative-modified subjects remain
   pending separate licensing in this staged fragment. In particular, the
   existing bare singular common-N subject is not rescued by a correct object.
5. **Completion:** consume the subject once, producing the independently specified
   DRS/claim meaning. For an initial evaluation confined to simple nominal
   clauses, preserve an explicit construction boundary until the clause is a
   root (ordinary final punctuation may preserve it). Do not let an unsupported
   embedding/relative/conditional analysis erase that boundary. This is an
   intentionally incomplete derivation subgrammar, not a sentence-text guard.

The final clause boundary matters: merely checking subject and complement NPs
while publishing a freely composable VP still admits the observed nested
relative/coordination leaks. A two-stage capability (licensed complement,
pending/completed nominal clause) is enough to *describe* the fragment; it is not
proof that adding it to this chart is small or bug-free. If its interactions
require a second general parser, defer it rather than build parallel grammar.

Ordinary argument indefinites, the existing adjectival route, and existing
licensed parsing continue using their original meanings. “Unsupported” here
means the new nominal route contributes no reading. It must not suppress an
already accepted independent reading of the sentence. Every count must still
include unsupported inputs in the evaluation denominator.

## What the sealed examples actually establish

Fourteen of the fifteen exact gains have selected subjects supported by overt
determiners or dictionary-majority NNP. The remaining gain, `pronto-ground-and-1`
(Fae), uses the explicitly uncertain unseen-initial-capital policy. A stricter
subject license cannot promise to retain that gain. This is evidence for a
possible14-case opportunity, **not a prediction of14 exact outcomes**: other
readings, chart packing and selection have not been tested with the new license.

All six old-exact regressions select an adjective-derived bare-generic NP as an
equative complement. Excluding that new route addresses their first divergence,
but only a fresh unchanged-gold run can establish final selected-reading recovery.

The28 newly wrong cases expose independent blockers: relative attachment and
shared binding, comma/disjunction meaning, demonym/reference ambiguity, names,
bare generic subjects, and nested operators/pronouns. Their exclusion from a
staged fragment is honest abstention, not a claim of fixing those constructions.
The full linguistic-design goal still requires those families to be repaired.

## Sealed case audit

The following labels are judgments about **eligibility for the proposed new
route**, not new parser statuses. No inferred exact/wrong/no-parse totals are
reported for an unimplemented rule.

| ID | Sealed transition | Proposed-route assessment |
|---|---|---|
| `pronto-nominal-1` | no_parse → exact | Potential simple-clause license; not remeasured |
| `pronto-nominal-2` | no_parse → exact | Potential simple-clause license; not remeasured |
| `pronto-negative-1` | no_parse → exact | Potential simple-clause license; not remeasured |
| `pronto-negative-2` | no_parse → exact | Potential simple-clause license; not remeasured |
| `pronto-every-1` | no_parse → exact | Potential simple-clause license; not remeasured |
| `pronto-each-2` | no_parse → exact | Potential simple-clause license; not remeasured |
| `pronto-ground-and-1` | no_parse → exact | Uncertain initial name Fae: stricter subject license does not certify |
| `pronto-ground-and-2` | no_parse → exact | Potential simple-clause license; not remeasured |
| `pronto-rule-and-1` | no_parse → exact | Potential simple-clause license; not remeasured |
| `pronto-rule-and-3` | no_parse → exact | Potential simple-clause license; not remeasured |
| `pronto-ground-or-1` | no_parse → exact | Potential simple-clause license; not remeasured |
| `pronto-ground-or-3` | no_parse → exact | Potential simple-clause license; not remeasured |
| `pw-atom-nominal-1` | no_parse → exact | Potential simple-clause license; not remeasured |
| `pw-atom-nominal-neg-1` | no_parse → exact | Potential simple-clause license; not remeasured |
| `pw-atom-nominal-neg-2` | no_parse → exact | Potential simple-clause license; not remeasured |

| ID | Sealed transition | Proposed-route assessment |
|---|---|---|
| `pronto-adjective-1` | exact → wrong_but_typed | Exclude bare-generic equative complement; retain adjective route |
| `prover-subject_copula-1` | exact → wrong_but_typed | Exclude bare-generic equative complement; retain adjective route |
| `prover-subject_copula-2` | exact → wrong_but_typed | Exclude bare-generic equative complement; retain adjective route |
| `pw-atom-copular-1` | exact → wrong_but_typed | Exclude bare-generic equative complement; retain adjective route |
| `pw-atom-copular-2` | exact → wrong_but_typed | Exclude bare-generic equative complement; retain adjective route |
| `pw-cond-ground-2` | exact → wrong_but_typed | Exclude bare-generic equative complement; retain adjective route |

| ID | Sealed transition | Proposed-route assessment |
|---|---|---|
| `pronto-restrict-and-1` | no_parse → wrong_but_typed | Relative/coordination attachment outside staged clause capability |
| `pronto-restrict-and-2` | no_parse → wrong_but_typed | Relative/coordination attachment outside staged clause capability |
| `pronto-restrict-or-1` | no_parse → wrong_but_typed | Relative/coordination attachment outside staged clause capability |
| `pronto-restrict-or-2` | no_parse → wrong_but_typed | Relative/coordination attachment outside staged clause capability |
| `pronto-ground-or-2` | no_parse → wrong_but_typed | Comma OR-list grammar unsupported; no comma-as-AND license |
| `prover-vp_either_or-2` | no_parse → wrong_but_typed | Bare either/adjective NP has no overt indefinite complement certificate |
| `folio-some-not-1` | no_parse → wrong_but_typed | American/demonym reference ambiguity; no default equative fallback |
| `folio-or-1` | no_parse → wrong_but_typed | American/demonym reference ambiguity; no default equative fallback |
| `folio-or-2` | no_parse → wrong_but_typed | American/demonym reference ambiguity; no default equative fallback |
| `pw-atom-nominal-2` | no_parse → wrong_but_typed | Bill analyzed as bare singular common-N subject: uncertified |
| `pw-cond-ground-coord-1` | no_parse → wrong_but_typed | Conditional/embedded use outside staged capability; independent scope issues |
| `pw-cond-ground-coord-2` | no_parse → wrong_but_typed | Conditional/embedded use outside staged capability; independent scope issues |
| `pw-cond-generic-1` | no_parse → wrong_but_typed | Conditional/embedded use outside staged capability; independent scope issues |
| `pw-cond-generic-2` | no_parse → wrong_but_typed | Conditional/embedded use outside staged capability; independent scope issues |
| `pw-universal-bare-1` | no_parse → wrong_but_typed | Bare generic subject and adjective-as-N complement unsupported |
| `prover-nested-or-1` | no_parse → wrong_but_typed | Conditional/embedded use outside staged capability; independent scope issues |
| `prover-nested-or-2` | no_parse → wrong_but_typed | Conditional/embedded use outside staged capability; independent scope issues |
| `prover-nested-and-2` | no_parse → wrong_but_typed | Conditional/embedded use outside staged capability; independent scope issues |
| `prover-nested-ante-or-2` | no_parse → wrong_but_typed | Conditional/embedded use outside staged capability; independent scope issues |
| `pronto-nested-or-and-1` | no_parse → wrong_but_typed | Relative/coordination attachment outside staged clause capability |
| `pronto-nested-or-and-2` | no_parse → wrong_but_typed | Relative/coordination attachment outside staged clause capability |
| `pronto-nested-or-and-3` | no_parse → wrong_but_typed | Relative/coordination attachment outside staged clause capability |
| `pronto-nested-and-and-1` | no_parse → wrong_but_typed | Relative/coordination attachment outside staged clause capability |
| `pronto-nested-and-and-2` | no_parse → wrong_but_typed | Relative/coordination attachment outside staged clause capability |
| `pronto-nested-and-and-3` | no_parse → wrong_but_typed | Relative/coordination attachment outside staged clause capability |
| `pronto-nested-negative-1` | no_parse → wrong_but_typed | Relative/coordination attachment outside staged clause capability |
| `pronto-nested-negative-2` | no_parse → wrong_but_typed | Relative/coordination attachment outside staged clause capability |
| `pronto-nested-negative-3` | no_parse → wrong_but_typed | Relative/coordination attachment outside staged clause capability |

## Required tests and open decision

Before source work, freeze derivation-level controls with **identical denotations
but different licenses**: bare N→NP versus overt every; lexical rigid NP versus
casing-only alternative; adjective-as-N versus a/an lexical-N complement; and
licensed NP coordination versus one unsupported branch. Check both categories
and consumed constituent origins, not just final lambda forms.

Then test propagation: ordinary argument use is unchanged; a/an plus coordination
retains each property; one existential subject remains shared; negation before
completion has the same scope as negating the completed VP; type raising cannot
launder a bare license; punctuation cannot turn a comma OR-list into AND; internal
bare subjects cannot certify or invalidate the outer NP by accident; packing
never merges competing licenses. A pending nominal capability must not appear in
a final admitted DRS, including under reports/conditionals.

Replay the full114 unchanged cases, not only the49 changed cases, and rerun all
Explain controls and release gates. Compare selected readings, any-reading
availability, and newly wrong cases separately. Preserve the15 gains and6
regressions as measured historical results even if a later fragment abstains.

**Recommendation:** the staged fragment is linguistically interpretable and may
be a useful next implementation experiment, but it is not yet an approved safe
default. Default activation remains deferred. Reviewer should decide whether
this small construction capability is worth implementing now, or whether names,
relative/coordination scope and a reusable local derivation witness should mature
first. Retaining broad equative fallback without that evidence is ruled out by
the sealed run. No production edit, fresh score or parser execution is claimed.
