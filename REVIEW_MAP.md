# Review map: what Astra changed (`main...astra/research`)

405 files, +61,516 / −792 lines. **About 76% of it is research notes.** The code that changes behaviour is roughly 2,800 lines.

| Part | What | Files | Lines added | Share |
|---|---|---:|---:|---:|
| 1 | Behaviour code (`src/`, `tools/`, cabal, scripts) | ~30 | ~3,100 | 5% |
| 2 | Tests and gold data (`test/`) | 110 | ~8,400 | 14% |
| 3 | Benchmark harnesses (`bench/reasoning`, `bench/retraction`) | 18 | ~2,300 | 4% |
| 4 | **Research notes** (`research/`, `proposals/`, goal/study docs) | ~247 | ~47,400 | 76% |

These counts describe Astra's final commit, `2cfb3a0`. Part 4d has since been removed (see below), which leaves about 8,000 lines of research notes.

View the whole thing on GitHub: <https://github.com/jmuslu/natural-language-to-proof/compare/main...astra/research>

---

## Part 1: Behaviour code (read this first)

Listed in reading order. Each file is followed by what its changes were for, taken from the commit messages.

### 1a. Parser and lexicon: the meaning fixes

| File | +/− | Changes |
|---|---|---|
| `src/NL2Proof/Syntax/CCGSemParse.hs` | +1252 / −51 | **The bulk of it.** Name licensing (a capital letter is not enough; needs majority-NNP evidence), "Everyone" as a person NP, particle spans, plural normalization, nominal negation ("is not a bird"), an optional inclusive-"either" chart, punctuation admission, the `--pos-backoff` flag |
| `src/NL2Proof/Semantics/CCGSem.hs` | +181 / −24 | Closed-class entries: some/no/each, reflexives bound to their local subject, relatives after quantified pronouns, definite identity, rejection of punctuation meanings for non-punctuation words |
| `src/NL2Proof/Semantics/OrOccurrence.hs` | +175 (new) | Bookkeeping for which "or" or "either" produced each disjunction |
| `src/NL2Proof/Syntax/CCGRules.hs` | +31 / −10 | Keep features such as `[dcl]` through composition (the "is not" bug) |
| `src/NL2Proof/Syntax/Tokenize.hs` | +29 / −18 | Numeric punctuation, exact sentence spans |
| `src/NL2Proof/DRT/Build.hs` | +159 / −51 | Shared DRS lowering, carrying "or" provenance, the semantic-seam repairs |
| `src/NL2Proof/Pipeline.hs` | +144 / −48 | Threading the either-policy and "or" origins through candidate selection |

### 1b. Soundness and the oracle lock

| File | +/− | Changes |
|---|---|---|
| `src/NL2Proof/Verify/Oracle.hs` | +17 / −16 | Only top-level assertion witnesses can be confirmed; conditions with free references are refused (the `r0` false-proof bug) |
| `src/NL2Proof/DRT/Canonical.hs` | +27 | Detecting free canonical references |
| `src/NL2Proof/Verify/{ClaimKind,Claims,Reported,External}.hs` | ~+60 / −40 | The matching API tightening |
| `scripts/check-oracle-boundary.sh` | +6 | More compile-fail rejections |

### 1c. Strength algebra and retraction (Phase C)

| File | +/− | Changes |
|---|---|---|
| `src/NL2Proof/Genealogy.hs` | +225 / −336 | Rewritten: support stored as minimal sets of sources (ATMS-style antichains), exact retraction, cycle handling |
| `src/NL2Proof/Fusion.hs` | +53 / −32 | Per-claim oracle alternatives; refuses to flatten existential consequents |
| `src/NL2Proof/Provenance.hs` | +59 | Evidence classes on support paths |

Explained in `research/STRENGTH.md`.

### 1d. Plumbing and tools

| File | +/− | Changes |
|---|---|---|
| `src/NL2Proof/Bench/Export.hs`, `Bench/JSON.hs`, `tools/ParseJSON.hs` | +344 | Export parses as JSON for the Python solvers and the fidelity scorer |
| `tools/RetractionBench.hs` | +195 | Driver for the retraction benchmark (Phase F) |
| `tools/Explain.hs` | +50 / −37, then the support-graph section | `--pos-backoff`, `--either-policy` and `--nominal-policy` flags; section 7 (`--stage=graph`), the support graph built with the existing Genealogy/Fusion APIs, with `--oracle=none\|confirm-asserted` (in-process test oracle through `Oracle.confirm`) and repeatable `--retract=sN` (`Genealogy.withdrawSource`); REPL `:oracle` and `:retract`. Checked by `scripts/check-explain.sh` (hand lexicon and a miniature CCGbank model, no corpus needed) |
| `nl2proof.cabal` | +305 | Registers about 25 new test suites |
| `scripts/with-ccgbank-slot.py` | +35 | Lock that limits concurrent CCGbank loads (only needed for parallel agents) |

---

## Part 2: Tests and gold data

- **`test/fidelity/`** (45 files, +2,857): **the hand-checked gold meanings**, 208 sentences with expected DRS and claims across ProverQA, ProntoQA, ProofWriter and FOLIO, plus the scorer (`fidelity.py`) and exporter. This is the most reusable piece Astra produced.
- **53 new `test/*Spec.hs` suites.** 21 of them are named `*ProposalSpec.hs`: tests written for proposals. Some were accepted, some only partly. They're worth an audit, since some may test code paths that are behind flags or only in proposals.
- `test/compile-fail/`, `compile-pass/`: extra oracle-lock cases.

---

## Part 3: Benchmark harnesses (paused before the redirect)

- `bench/reasoning/` (11 files, +1,691): the Python Horn and Z3 solvers, the runner, the LLM caller. This is the code for the parser+solver condition and the weak-model-plus-graph condition. Uncommitted extensions of it were discarded with `final-wip`.
- `bench/retraction/` (7 files, +572): the generated 64-case retraction and hearsay benchmark.

---

## Part 4: Research notes

About 47,000 lines. Grouped by how much they're worth your time.

### 4a. Read these: the decision documents

| Doc | Lines | What it is |
|---|---:|---|
| `research/FINDINGS.md` | 267 | Overall findings (partly stale: written before the linguistics redirect) |
| `research/linguistics/FINDINGS_LINGUISTICS.md` | 175 | The linguistics-phase synthesis and its decisions |
| `research/linguistics/DESIGN.md` | 1,051 | The 13 construction cards: categories, λ-terms, DRS for each construction |
| `research/linguistics/CONSTRUCTIONS.md` | 577 | Sentence-pattern inventory of the four benchmarks |
| `research/linguistics/NAMES.md` | 153 | The names bug, traced end to end. A good worked example |
| `research/linguistics/TEMPLATE_COMPARISON.md` | 217 | Comparison with Boxer and ccg2lambda templates |
| `research/STRENGTH.md` | 363 | The strength algebra and retraction, with proof sketches |
| `research/SEAMS.md` | 77 | Audit of the study-plan seam invariants |
| `research/RESTORED.md` | 70 | Why SDRT and Threading weren't wired in |
| `research/linguistics/REFERENCES.md` | 75 | Sources used |

### 4b. Per-fix results: read only when reviewing that fix

`EITHER_POLICY_RESULT.md`, `NOMINAL_NEGATION_RESULT.md`, `NOMINAL_POLICY_RESULT.md`, `WRONG_FIRST_DIVERGENCE.md`, `WRONG_TYPED_167.md`, `GOLD_GAPS_167.md`, `FIDELITY_COVERAGE.md`, `PROVER_GOLD.md`, `PROVER_ACCEPTANCE.md`, `SEMANTIC_CONTRACTS.md`, `gold-construction-matrix.md`, `research/PARSER_EXPORT.md` (all under `research/linguistics/` except the last). Each is 60–200 lines.

### 4c. Logs and state: reference only

- `research/LOG.md` (2,960 lines): every prediction, command and result, in order. Use it to look things up, not to read through.
- `research/STATE.md`: Astra's working memory at the end.
- `ASTRA_GOAL.md` (330): the goal spec plus the redirect amendments.

### 4d. Process material: **removed in `258468b`**

These were deleted from the branch (211 files, about 39,000 lines). They're still in git history; for example, `git show 2cfb3a0:research/notes/<file>` shows a file as it was before the removal.

| Folder | Files | Lines | What it is |
|---|---:|---:|---|
| `research/notes/` | 118 | 6,703 | Per-worker scratch notes |
| `research/linguistics/proposals/` | 58 | 9,359 | Design proposals; accepted ones are reflected in code and DESIGN.md |
| `research/linguistics/sections/` | 13 | 2,279 | Per-benchmark inventory sections, merged into CONSTRUCTIONS.md |
| `research/tools/`, `research/linguistics/*.py`, `*.json` | ~25 | ~15,000 | Inventory scripts and their count outputs (data, regenerable) |
| `proposals/adjective-admission-plan.md` | 1 | 220 | An unimplemented plan |

---

## A suggested way to take it apart

1. Read **1a–1c** with `NAMES.md` and the matching DESIGN.md cards open. These are the only parts that change behaviour.
2. Run the fidelity gold set (`test/fidelity/`) yourself to check the numbers: about 70 exact, 36 wrong-but-typed and 101 no-parse out of 208.
3. Decide which fixes to keep. Each is a small number of commits in `CCGSemParse.hs` / `CCGSem.hs`.
4. Keep `test/fidelity/` whatever you decide, plus DESIGN.md and CONSTRUCTIONS.md as reference.
5. 4d is already gone. Next candidates: most of the `*ProposalSpec.hs` suites.
