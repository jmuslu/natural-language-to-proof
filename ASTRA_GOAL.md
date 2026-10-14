# Goal spec: nl2proof open research run

You are running a long, autonomous research and engineering run on this repo. You have broad freedom: you may rewrite, restructure or delete anything on your branch, add tools, change designs and run any experiment you think is worthwhile. The owner will review everything before it reaches `main`.

This is meant to be a "do everything, figure it out" pass. Test the ideas at the intersections described below, find out what actually holds up, and leave behind a clear account of what you learned. Honest negative results are as valuable as positive ones.

---

## 0. Ground rules (non-negotiable)

1. **Work only on branch `astra/research`.** It already exists and holds this file. Commit and push to `origin astra/research` often, at least after every meaningful step, so nothing is lost. **Never push to `main`, never merge into `main`, never force-push `main`, never delete or rewrite tags** (especially `pre-cut`). You may create sub-branches `astra/<topic>` for risky experiments and merge them back into `astra/research`.
2. **Never commit licensed or raw data.** That means:
   - CCGbank (`~/ccgbank`);
   - full benchmark datasets (`~/data/...`);
   - bulk output derived from CCGbank, such as lexicon dumps or trees;
   - anything large.

   Small samples that are already committed (`bench/*/sample.jsonl`) and small hand-written examples are fine.
3. **Secrets.** A Gemini key lives in `~/.config/nl2proof/gemini.env`. Never print, log, copy, echo or commit it. Load it only by sourcing the file inside the process that needs it. Never commit `.env` files, tokens or credentials of any kind. If you find a secret anywhere, do not output it; note its location in the log.
4. **Stage files explicitly.** Never `git add -A` or `git add .`. Check `git status` before every commit.
5. **Usage limits are not a stopping point.** The owner has saved Codex usage resets for this run, so use as many as you need. When you hit a usage limit, wait for the reset and continue. Do not wrap up early, summarize and stop, or ask for permission to continue. Keep `research/STATE.md` (§5) current, so that after any reset or context loss you can resume exactly where you left off.
6. **Do not weaken guarantees to make numbers go up.**
   - Every gate in §2 must pass on every commit you push. If a gate truly needs to change, change it in its own commit, with the reason in the message and in `research/LOG.md`.
   - Never delete a failing test to get green. Fix the code, or mark the test as a known failure with an explanation.
7. **No destructive actions outside the repo.** Don't delete files outside `~/nl2proof`. Don't uninstall system packages. Don't touch other services on this machine. Installing tools (pip packages, cabal packages, solvers) in user space is fine.
8. **Commit messages** end with:
   `Co-Authored-By: Codex Astra` (keep the existing `Co-Authored-By: Claude` lines on older commits intact)

---

## 1. What this project is

nl2proof is a deterministic pipeline that turns English into claims a reasoner can trust:

```
text → CCG parse (CCGbank categories) → typed λ-terms (Montague, Ty2 intensional)
     → DRS (discourse representation structure) → claims typed by epistemic status
     → justification/fusion graph with evidence strength → answers by proof
```

**The thesis.** Reasoning should live in interpretable structures, not inside an LLM. Words combine by type. Only type-`t` terms become statements, and statements fuse into a graph.
- Claims backed by an oracle or real-world evidence fill the graph backwards and fuse strongly.
- Hearsay or ingested testimony "lingers" weakly.

The LLM consumes proof-backed context ("X holds because A [oracle] and B [reported by Bob]") instead of raw retrieved text. It may also act as a fallback translator for what doesn't parse, but anything it produces enters at hearsay strength.

**The claimed value is guarantees, not raw accuracy:**
- provenance;
- hearsay never silently becoming fact;
- retraction: discredit a source, and everything that depends on it falls;
- honest abstention;
- contradiction detection.

Plus one empirical claim to test: **a weaker model with graph reasoning matches or beats a stronger model on raw text.**

The owner's aversions are part of the spec: no stochastic core (probabilistic parts may only rank readings, on top, and never admit facts), no sprawl, and no glue that nobody understands.

### Read first, in this order

1. `STUDY_PLAN.md`: the theory map, the eight seam invariants, and the **Known deviations** table, which doubles as your bug list.
2. `README.md`, `bench/README.md`, `bench/proofwriter/README.md`.
3. `src/NL2Proof/Pipeline.hs`, then `Syntax/CCGSemParse.hs`, `Semantics/CCGSem.hs`, `Semantics/Intensional.hs`, `DRT/*`, `Verify/{Reported,ClaimKind,Oracle}.hs`, `Genealogy.hs`, `Fusion.hs`, `Provenance.hs`.
4. `tools/Explain.hs`. Use the explain tool constantly.

### Environment facts

- **Build:** Haskell, cabal, GHC 9.4.7. `cabal build all`, `cabal test all`.
- **CCGbank:** `~/ccgbank/ccgbank_1_1/data`, or `$CCGBANK_DIR`. Licensed, so never commit it. The manual is at `~/ccgbank/ccgbank_1_1/doc/CCGbankManual.pdf`. Loading the lexicon takes about 80 s, so batch your inputs and use the REPL.
- **Explain tool:**
  - one sentence: `cabal run -v0 nl2proof-explain -- [--stage=tags|deriv|lambda|drs|claims] [--all-readings] [--hand] "sentence"`;
  - with no arguments it starts a REPL, so pipe several lines into it to pay the load cost once.
- **Coverage:** `cabal run -v0 proofwriter-coverage` (see its source for flags).
- **Datasets** (outside the repo; never commit): `~/data/proofwriter/proofwriter-dataset-V2020.12.3`, `~/data/prontoqa`, `~/data/folio`, `~/data/proverqa`.
- **LLM access:**
  - The Codex CLI is logged in through the owner's ChatGPT subscription. Only `gpt-5.5` is available; vary `model_reasoning_effort` (low/medium/high) to get "weaker" vs "stronger" conditions. See `bench/common/run_codex.py` for the isolated invocation (empty dir, `--skip-git-repo-check --ephemeral --sandbox read-only --json -o`). Each call carries about 16.7k tokens of agent prompt overhead.
  - Gemini free tier, via `bench/common/run_gemini.py`. Quotas are tiny (about 20 requests per day per Flash model) and Pro isn't available, so use it only for small confirmations.
  - OpenRouter/MiniMax is dead; don't try it.
- **Solvers:** none are installed. `z3` is not on PATH and the Python module is missing. You may install `z3-solver` with pip (user or venv) and/or build Prover9. Record what you installed in `research/LOG.md`.

---

## 2. Gates (must pass on every pushed commit)

- `cabal build all`
- `cabal test all`: all suites. The current counts are recorded in the commit history; they may grow, and they must not shrink without justification.
- `scripts/check-oracle-boundary.sh`: compile-fail rejections. Only the oracle can create `Confirmed`, and Reported/Presupposed/Embedded claims cannot be confirmed.
- `scripts/check-explain.sh`
- **Invariant 3** (only top-level main-box conditions are asserted) and **invariant 4** (attitude complements are never asserted; factives presuppose) must hold. Treat any regression on these as a release blocker.

---

## 3. The work

These phases are an order, not a cage. If you find something more important, do it and explain why in the log. Each phase lists questions to answer and a definition of done. For every experiment, **write your prediction in `research/LOG.md` before you run it.** Then record the result and whether the prediction held.

### Phase A: Orient (short)

- Build, run all gates, run the explain tool on the sentences in STUDY_PLAN's Known deviations table, and confirm each deviation reproduces.
- Write `research/STATE.md` (§5) and the first entries of `research/LOG.md`.

### Phase B: Make meaning correct on real-text constructions

Fix the deviations that change meaning, each with failing tests written first:
1. **Pronoun resolution.** Definites and names must introduce DRS referents, or be otherwise bindable, so "The cat is red. It is big." yields `big(cat)`. Keep resolution deterministic and log the chosen antecedent as a `Decision` with its alternatives.
2. **Relative clauses.** Give "that"/"which"/"who" as relativizers their meaning, e.g. "Every cat that is red is big."
3. **Non-constituent coordination.** "Bob likes and Anne hates the cat." should parse through `>T` + `>B` + coordination.
4. **Feature drop under composition.** `<Bx` on "is not" loses `[dcl]`.
5. **Factive double listing.** A factive complement should be Presupposed only, not also Reported.
6. **Lemmatization** ("added" → "add"), without breaking the that-clause attestation set.
7. **The oracle loophole.** `confirm` accepts a bare `CanonCond`, so a literal could be extracted from inside a negated claim and confirmed. Close it so that only `Claim 'Asserted` (or an equivalent proof of top-levelness) is confirmable, and add a compile-fail case.
8. **round/kind lexicon gap.** Experiment with a POS-based backoff for predicative adjectives (and generally for open-class words missing from the tag dictionary). Measure ProofWriter coverage before and after, and the number of silent (wrong-but-well-typed) errors. Report the trade-off; this is an open owner decision, so implement it behind a flag.
9. **Quote tagging.** "The cat is red, boasted Bob." currently asserts `red(cat)`. Find a fail-closed fix.

Also check: "Bob sees that the cat is red." Is perception-"see that" factive? Decide using the literature (STUDY_PLAN Unit 5) and the data, and document the choice.

**Done when:** each item is fixed with tests, or written up in the log as not fixable this way and why, and the explain-tool outputs in the Known deviations table are updated to match.

### Phase C: Define the strength algebra (the core thesis)

"Fuse strongly" vs "linger weakly" has to become a definition, not a metaphor.
- Read `Genealogy.hs`, `Fusion.hs`, `Provenance.hs`, and write down what they actually compute today.
- Formalize strength as a **provenance semiring** (Green, Karvounarakis & Tannen 2007): ⊗ along a derivation, ⊕ across alternative derivations. Candidates include Boolean, Viterbi (max, ×), tropical, why-provenance / ATMS-style labels, and a product of an evidence-class lattice with one of these. Pick by argument and experiment, not by taste.
- Prove or property-test the laws: associativity, commutativity, distributivity, the identities, absorption/idempotence of ⊕ where you claim it, and fixpoint termination on cyclic graphs.
- Handle **circular support** as a truth-maintenance system would: no fact may ground itself through a cycle (well-founded support).
- Make **retraction** exact: discredit a source, and every conclusion whose only support runs through it loses that support. Conclusions with independent support survive.
- Fit the evidence classes in: oracle-confirmed, asserted-unconfirmed, reported (with source chain), presupposed, and LLM-translated (hearsay).

**Done when:** `research/STRENGTH.md` states the algebra and why, the laws are property-tested (QuickCheck or similar), and Fusion/Genealogy implement it with no ad hoc numbers left.

### Phase D: Solver and error handling

The owner hasn't decided these yet. **Implement the options behind flags and measure them; don't lock one in.**
- **Solver.** Use a forward chainer for Horn rules with classical negation under the open-world assumption, with True/False/Unknown answers, ProofWriter-style. Add an FOL backend (Z3 and/or Prover9) for disjunction and existentials (ProverQA, FOLIO). Compare their coverage and agreement.
- **Monotonicity rule.** If some sentences failed to parse, a proof found from the rest is sound and may be answered, but "Unknown" from a partial theory must **abstain**.
- **Ambiguity.** Compare these strategies:
  1. top-ranked reading only;
  2. skeptical: answer only what holds in every reading;
  3. credulous.

  Measure answered-precision and coverage for each.
- **Fallback.** For sentences that fail to parse:
  1. an LLM translates them to logic, at hearsay strength;
  2. the raw sentence is passed to the LLM alongside the proven facts;
  3. abstain.
- Report every condition as **coverage, answered-precision and end-to-end accuracy**, with a risk–coverage curve where it makes sense.

### Phase E: Benchmarks, with the conditions that test the thesis

Use `bench/` (ProofWriter OWA d5, ProntoQA, FOLIO, ProverQA, with the existing samples and the strict + lenient scoring). Run these conditions:

| Condition | What it is |
|---|---|
| A | LLM on raw text, at weak and at strong effort (baselines; reuse the existing results where valid) |
| B | parser + solver alone, with abstention; report coverage |
| C | **weak LLM + graph context**: proven facts with provenance and strength, plus residual unparsed sentences |
| D | hybrid: B where it's confident, otherwise C |

- **Priority: ProverQA-hard.** It has the most headroom: gpt-5.5 scores about 75%, and 28 of its 30 errors are "Uncertain" on provable items.
- **Statistics:** Wilson intervals, and **paired** tests (McNemar) on the same items for every A-vs-C or A-vs-D claim.
- **Data hygiene:** note FOLIO's label noise and ProverQA's exclusive reading of "either…or".
- **Larger samples:** draw them if a result hinges on n = 120, with fixed seeds and the sampling scripts committed. Only the sample files (item IDs plus text) go into git.
- **Track cost:** tokens per item for each condition.

### Phase F: The benchmark that tests the guarantees

No standard benchmark tests provenance or retraction, so build a small generated one (`bench/retraction/`), for example:
- Theories where some facts come from named sources and one source is later discredited. Does each system withdraw exactly the dependent conclusions?
- Hearsay traps: "Bob says the cat is red". Does the system treat red(cat) as established?
- Contradictions across documents. Are they detected and attributed?
- Factive vs non-factive verbs, and negation inside reports.

Compare raw-LLM answering against graph-backed answering. Keep the generator deterministic and seeded.

### Phase G: The restored modules and the intersections

`Readings/{Alternatives,Modifier}.hs` and `Discourse/{SDRT,Threading}.hs` were restored but are not wired into the Pipeline. Decide with evidence:
- Does wiring Threading (cross-sentence anaphora) or SDRT relations improve anything measurable, such as Phase B pronouns, FOLIO or the Phase F traps?
- Does a probabilistic ranking layer on top of readings help the skeptical/credulous comparison in Phase D? It must never admit facts.

Wire in what earns its place. For what doesn't, say so plainly; deleting it is acceptable if justified.

Also probe the intersections that STUDY_PLAN calls seams, and write up what you find:
- category → type;
- DRT truth → claim table;
- intensional semantics → epistemic status;
- monotonicity → abstention;
- semiring → fusion;
- types → the oracle lock.

For each one: is the current design correct, and where does it break on real text?

### Phase H: Synthesis

Write `research/FINDINGS.md` for the owner. It should be a decision document, not a diary:
1. **What holds up:** each thesis claim with evidence and numbers, and where it fails.
2. **What doesn't, and should be cut.** Sprawl is the enemy; recommend deletions.
3. **The owner's open decisions:**
   - (a) the round/kind backoff;
   - (b) error handling and the solver;
   - (c) wiring SDRT/Threading;
   - "see that".

   Give a recommendation for each, with the evidence behind it.
4. **The strength algebra,** in one page.
5. **The recommended next three things.**
6. **A merge guide:** the commits grouped by theme, which are safe to merge, which are experimental, and which to drop.

Also update `STUDY_PLAN.md` wherever the system's behaviour changed, especially the Known deviations table, so the owner's study material stays truthful.

---

## 4. How to work

- **Use the explain tool as your debugger.** When behaviour surprises you, find the first stage where it disagrees with the theory.
- **Test first** for every behaviour fix, then implement and commit.
- **Keep the codebase small.** Prefer changing an existing module to adding a parallel one, and delete dead code you create. Every new module needs a header comment saying why it exists.
- **Keep it deterministic.** Any choice among alternatives is a logged `Decision` that records the alternatives it discarded (see `Trace.hs`).
- **Long jobs:** run them in the background and write their output under `research/runs/` (gitignored if large; commit only the summaries).
- **When stuck** for more than a reasonable effort, write down what you tried and why it failed, and move to the next item. Come back later if something you learn elsewhere unblocks it.

## 5. State and logging (required, for resumption)

- **`research/STATE.md`** is always current and short. It holds:
  - the current phase and item;
  - the last commit;
  - the exact next three actions;
  - running background jobs and where their output goes;
  - open questions.

  Update it before every commit and before any long-running command. After a usage reset or context loss, read it first.
- **`research/LOG.md`** is append-only and dated. Each entry records:
  - the prediction, made before the run;
  - what was run (the exact command);
  - the result;
  - the interpretation;
  - the commit.
- **`research/FINDINGS.md`** is the final synthesis (Phase H). Start it early and revise it as you go.

## 6. Definition of done

The run is done when:
- Phases B–H each have a result, or a written reason they can't;
- `research/FINDINGS.md` gives the owner a clear recommendation for every open decision, backed by numbers;
- every gate passes on the branch head;
- everything is pushed to `origin astra/research`.

If you finish early, look for the weakest claim in FINDINGS.md and try to break it.
