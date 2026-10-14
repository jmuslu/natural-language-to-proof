# Independent give_up fidelity gold

Prediction recorded before validation or parser observation: three schema-valid
cases with unique IDs and texts; one exact input-cache source sentence and two
explicitly AUTHORED controls. No prediction of parser coverage is made.

## Frozen meaning contract

This set adopts the reviewed c69ec8e intransitive lexical sense: cessation of
trying at a contextually fixed effort, abstracting from tense/aspect. The unary
predicate `give_up` names that sense; it is not a conjunction of `give` and `up`,
a directional relation, a habitual/dispositional reading, or unrestricted
present-tense English. Names denote constants. No event or object referent is
invented. These assumptions are part of gold admission, not a consequence of
any parser output.

The exact source anchor is `Raul gives up.` from the input-only cache
`research/runs/linguistics/other-refresh/proverqa-unique.jsonl`, coordinate
`proverqa/dev/easy.json/222`, role query, index 0. The sentence is unchanged.
`Ada gives up.` and `Raul does not give up.` are AUTHORED controls, not ProverQA
sentences or frequencies. Ada independently checks lexical-name substitution;
the negative checks scope over the entire lexical predicate and the base form.

Positive DRS and independently authored claims contain only the corresponding
unary atom as Asserted. Negative DRS contains negation of that atom; the whole
negation is Asserted and the atom is Embedded. Reported and Presupposed remain
empty. No provider proof, generated answer, Explain result or claim splitter was
used to derive either interface.

Directional PP, early/easily event or disposition modifiers, transitive
relinquishment, separated particles and ambiguous senses remain unresolved.
They are not converted into guessed gold or used as coverage claims here.

## Checks and review boundary

Checks passed: `fidelity.validate_case` accepts all three rows; all IDs and texts
are unique across current JSONL fixtures; the exact source coordinate/text
matches the input-only cache; exactly two origins are AUTHORED controls.
`git diff --check` passed. Independent review is required before parser observation. No parser, corpus load, model or
answer benchmark is launched by this task.
