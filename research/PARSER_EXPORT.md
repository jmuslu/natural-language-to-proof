# Parser JSONL protocol (schema 1)

`nl2proof-parse-json` loads the local CCGbank model once, then accepts one JSON object per line and emits one JSON object per line. Model progress goes to stderr. `--hand` uses the miniature attitude lexicon; `--pos-backoff` enables the experimental lexical option. `--max-combinations N` accepts 1–64, default 64.

Requests have exactly these fields; unknown or repeated keys are rejected:

```json
{"id":"example","context":["John smiles."],"statement":"John smiles."}
```

`context` may be one string or an ordered string array. An array is joined with newlines before sentence splitting. Its exported character spans refer to that joined text. `statement` must parse as exactly one sentence for the initial query interface. No gold logical forms, labels or answers enter this process.

The response contains `id`, `schema`, `context`, `statement`, `theories`, `truncated`, `search`, and `residuals`. Each document contains text, sentence results, the ordinary selected discourse DRS, and its trace. Each sentence contains every returned candidate's category, normal form, type-validation result, local DRS, score, trace, provenance and residuals. Scores rank parser search; they are not probabilities of truth or evidence strengths.

Each `theories` entry has:

- `choice_indices`: zero-based reading index for each context sentence (`-1` means no reading).
- `drs`: the complete scoped discourse box for that combination, using the shared Haskell freshening and anaphora operations.
- `complete`, `residuals`, and `trace`: completeness is relative to this exported first-order fragment, not a semantic correctness guarantee.
- `queries`: query readings resolved against this particular context combination. Query conditions are never merged into the premise box. Each query has its own `choice_indices`, `drs`, `complete`, `residuals`, and `trace`.

The Cartesian limit applies to theory/query pairs together. Enumeration probes one extra pair to set `truncated`. A skeptical or credulous result over all returned alternatives must abstain if this cap truncated enumeration. The separate `search.beam_limited` flag discloses the CCG chart bound; even an untruncated export does not enumerate all possible English interpretations. The ordinary highest-ranked pipeline result remains available in each document's `selected_drs`.

A box is `{universe:["x"], universe_provenance:[...], conditions:[...]}`. Universes bind existential referents; an implication's antecedent universe binds its antecedent and consequent. Terms are `{ref:"x"}` or `{const:"John"}`. Conditions retain their complete scopes:

| tag | fields |
|---|---|
| `pred` | `name`, `args` |
| `eq` | `left`, `right` terms |
| `not` | `body` box |
| `imp`, `or` | `left`, `right` boxes |
| `att` | `verb`, `holders`, `body` box |
| `presup` | `body` box |

Every condition has `prov` with sources, covering span, rule names, and lexical leaves (`source`, `span`, `text`). Attitude and presupposition contents remain marked; they are not flattened into asserted predicates.

An `or` condition also has `either` and `either_scope_ambiguous`. The current DRT translator gives disjunctions sentence-wide fallback provenance. If multiple disjunctions share provenance containing *either*, it cannot localize that marker: `either` is false, ambiguity is true, and the box records `xor_residuals`. Inclusive semantics remains available. A benchmark-specific exclusive interpretation must treat that ambiguity as a residual for the whole enclosing condition; it must not guess which disjunction is exclusive.

`UNSUPPORTED` conditions, function-form stringified arguments, unresolved anaphors and unbound references are residuals. Plain multiword rigid names such as `bald eagle` are accepted. A query pronoun that resolves to a context existential produces an unbound query reference and is residual, because this first interface does not export shared variable assignments. Missing context sentences produce explicit incomplete variants instead of silently making an empty premise set complete.

These safeguards expose parser and representation limitations. They do not certify lexical senses, antecedent choices, or a returned reading's truth. The benchmark runner must keep those uncertainties separate from solver outcomes.
