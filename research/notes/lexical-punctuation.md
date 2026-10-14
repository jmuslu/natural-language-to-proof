# Lexical punctuation surface contract — 2026-10-14

Assigned isolated worktree verified clean; shell works. Own CCGSem.hs,
LexicalPunctuationSpec.hs and this note only. Read current closedEntries,
isPunct categories and case-preserving tokenizer; no corpus/model runs.

Prediction before red tests: closedEntries accepts alphabetic/numeric surfaces
under a punctuation category, including reserved uppercase OR. A miniature
`Bob is red, OR big.` with OR offered only punctuation can silently discard it
and produce all-AND. A correct admission boundary must reject that interpretation;
if no lexical OR analysis is available, no parse is preferable to deleting it.
Positive controls retain uppercase/lowercase explicit conj meanings and actual
punctuation surfaces. Corpus-free command:
`runghc -isrc -itest test/LexicalPunctuationSpec.hs`.

Proposed minimal guard sent to reviewer before source edit: nonempty surface,
all characters Unicode punctuation according to Data.Char.isPunctuation. It is
not all-nonalphanumeric: whitespace, mathematical/currency symbols, combining
marks and emoji must not become discardable punctuation. Preserve current
punctuation-category assignment; mapping comma to comma versus full-stop category
is a separate tagger/attachment issue. Do not manufacture a per-word blacklist.

Red result:24/139 pass,115 fail, including the miniature uppercase-OR erasure.
Reviewer approved nonempty all-isPunctuation boundary before implementation,
requesting literal PTB-alias handling to follow actual tokenizer contract. Source
inspection finds no -LRB-/-RRB- surface normalization in casedTokens: actual
parentheses are separate tokens; literal -LRB- is not a punctuation-only input.
Reject that literal while preserving category LRB for actual '(' and '['.

Next prediction: minimal guard makes139/139 pass and leaves registered test suites
green. The contract excludes '$', mathematical symbols and emoji from generic
structural deletion; this does not preclude future lexical meanings for them.
Typographic quotes/dashes retain existing structural eligibility, not a new claim
that quotation/attribution is semantically erasable in every syntax context.

Scope clarification: Unicode quote/dash controls exercise closedEntries directly.
They do not claim every such token is routed to closedEntries by the current
ASCII-oriented lexicalSigns punctuation test, nor new corpus tag coverage. This
candidate changes only the admission boundary when closedEntries is called.
Unicode general-category punctuation is eligible; Unicode Symbol categories
(currency/math/other symbols) are not. This is a character-class boundary, not
a claim that every colloquially named "symbol" lacks punctuation classification.

Final results:139/139 standalone controls pass; cabal test all --offline completes
successfully with all17 registered suites passing. Logs under ignored
research/runs/lexical-punctuation/{red,green,all-tests}.log. Source diff is limited
to importing isPunctuation and requiring nonempty punctuation-only surface in
closedEntries; ordinary closedTable/intensionalTable lookup remains unchanged.
No per-word blacklist, parser/category rule, or gold edit. git diff --check passes.
Reviewer received the concrete live diff; coordinator retains responsibility for
independent final review, cabal registration and full integration/fidelity gates.
