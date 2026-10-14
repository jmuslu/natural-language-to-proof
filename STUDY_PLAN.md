# Study plan: the theory under nl2proof

nl2proof is built on six established theories joined at a handful of seams. So far the bugs have come from the seams, not from inside any one theory. The negation leak was a DRT truth-definition question showing up in a claim table. The reported default was an intensional-semantics question showing up in a CCG category. The round/kind failure was a corpus question that looked like a grammar question.

LLMs (and the agents working on this repo) know each theory's textbook statement. They are weak at the seams, because the rules that connect two theories are rarely written down in one place. The goal of this plan is not to make you a semanticist. The goal is that you **own the seam invariants**: you can state them from memory, and you can predict the system's output on a sentence by hand before you run it.

---

## Running the explain tool

Every exercise below ends with "predict by hand, then run the system, then diff". `nl2proof-explain` is the "run the system" half: for one sentence (or a short text) it prints every stage side by side, in the order you would derive them by hand:

1. **TOKENS + SUPERTAGS**: each token's chosen CCGbank category, its supertagger log-probability, and whether its meaning is a closed-class entry, a name or an open-class template.
2. **DERIVATION**: the derivation tree, every node labelled with its rule (`>`, `<`, `>B`, `<B`, `>Bx`, `<Bx`, `>T`, `TC` type-change, `conj`/`coord`, `punct`), its category and its meaning.
3. **LAMBDA**: each leaf's λ-term and Montague type (`catTy`, so `S[em]` is `s->t`), where it came from, and the β-normal form with its type.
4. **DRS**: the box, with negation, `=>`, `OR`, attitude (`K:`) and `PRESUPPOSED:` sub-boxes nested.
5. **CLAIMS**: `splitClaims` grouped into Asserted, Reported (with source chain), Presupposed and Embedded.
6. **FAILURES / NOTES**: which stage failed (lexicon, parse or meaning) and why, the number of readings if the parse is ambiguous, and every logged decision.

First time only, build it (from the repo root):

```
cabal build nl2proof-explain
```

Then:

```
cabal run -v0 nl2proof-explain -- "Bob says that the cat is not red."
cabal run -v0 nl2proof-explain -- --stage=claims "Bob knows that the cat is red."
cabal run -v0 nl2proof-explain -- --all-readings "All cold, green things are quiet."
cabal run -v0 nl2proof-explain -- --hand "John says that Mary does not smile."
cabal run -v0 nl2proof-explain            # REPL: loads the lexicon once, one text per line, :q quits
```

- `--stage=tags|deriv|lambda|drs|claims` prints one section only.
- `--all-readings` prints every reading (the selected one is marked `[SELECTED]`) and every candidate supertag (`*` marks the one the selected derivation used; `---` lines are tags the tagger offered that have no meaning).
- `--hand` uses the hand-written fragment lexicon (`attitudeLexicon`: John, Mary, student, smiles, says, knows, ...) instead of CCGbank. It starts instantly, so it is the quickest way to check a Unit 1 or Unit 3 derivation.
- `--pos-backoff` enables experimental POS-dictionary noun/adjective backoff, off by default. Selected entries log a `pos-backoff` decision; the ranking score is not evidence strength.
- In the REPL, `:all` toggles `--all-readings`, `:stage=deriv` (or `:stage=all`) changes the section, `:help` lists the commands.

The CCGbank lexicon is read from `$CCGBANK_DIR`, else `~/ccgbank/ccgbank_1_1/data`. Loading sections 02-21 (39,604 trees) takes about 80 seconds, so for more than one sentence use the REPL. `scripts/check-explain.sh` is the smoke test.

Historical pre-repair output for "Bob says that the cat is not red." (compare it with your Unit 2 exercise 1). The current parser preserves `[dcl]` through `is not`: its result is `(S[dcl]\NP)/(S[adj]\NP)` and the clause is `S[dcl]`. This transcript is retained as a baseline; regenerate with the command above for current trees, scores and candidate counts:

```
== 1. TOKENS + SUPERTAGS ===================================================
  Bob         NP                        logP  -2.22   [name]
  says        (S[dcl]\NP)/S[em]         logP  -3.29   [open template]
  that        S[em]/S[dcl]              logP  -0.63   [closed]
  the         NP[nb]/N                  logP  -0.01   [closed]
  cat         N                         logP  -1.35   [open template]
  is          (S[dcl]\NP)/(S[adj]\NP)   logP  -1.59   [closed]
  not         (S\NP)\(S\NP)             logP  -0.57   [closed]
  red         S[adj]\NP                 logP  -3.49   [open template]
  .           .                         logP  -0.00   [closed: structural]
  (16 further interpretable categories not shown; --all-readings lists them)

== 2. DERIVATION ===========================================================
  rules: > < forward/backward application, >B <B composition, >Bx <Bx crossed
         composition, >T <T type-raising, TC unary type-change, conj/coord
         coordination, punct punctuation absorption; '= ...' is the node's meaning
  [<] S[dcl]  "Bob says that the cat is not red ."
  |     = say(Bob, \w1:s. ~red_s(w1, iota(\x:e. cat_s(w1, x))))
  +- [lex] NP  "Bob"
  `- [>] S[dcl]\NP  "says that the cat is not red ."
     |     = \S:((e->t)->t). S(\x:e. say(x, \w1:s. ~red_s(w1, iota(\x:e. cat_s(w1, x)))))
     +- [lex] (S[dcl]\NP)/S[em]  "says"
     `- [>] S[em]  "that the cat is not red ."
        |     = \w1:s. ~red_s(w1, iota(\x:e. cat_s(w1, x)))
        +- [lex] S[em]/S[dcl]  "that"
        `- [<] S  "the cat is not red ."
           |     = ~red(iota(\x:e. cat(x)))
           +- [>] NP[nb]  "the cat"
           |  |     = \Q:(e->t). Q(iota(\x:e. cat(x)))
           |  +- [lex] NP[nb]/N  "the"
           |  `- [lex] N  "cat"
           `- [>] S\NP  "is not red ."
              |     = \S:((e->t)->t). S(\x:e. ~red(x))
              +- [<Bx] (S\NP)/(S[adj]\NP)  "is not"
              |  |     = \z:(((e->t)->t)->t). \S:((e->t)->t). S(\x:e. ~z(\P:(e->t). P(x)))
              |  +- [lex] (S[dcl]\NP)/(S[adj]\NP)  "is"
              |  `- [lex] (S\NP)\(S\NP)  "not"
              `- [punct] S[adj]\NP  "red ."
                 |     = \S:((e->t)->t). S(\x:e. red(x))
                 +- [lex] S[adj]\NP  "red"
                 `- [lex] .  "."

== 3. LAMBDA ===============================================================
  leaves (category, Montague type catTy, lexical term, where it came from):
    Bob       NP                      (e->t)->t
      term  \P:(e->t). P(Bob)
      from  proper name (CCGSem.nameItem; POS dictionary says NNP)
    says      (S[dcl]\NP)/S[em]       (s->t)->(((e->t)->t)->t)
      term  \p:(s->t). \S:((e->t)->t). S(\x:e. say(x, p))
      from  open-class template (CCGSem, by category shape): non-factive attitude verb (that-clause)
    that      S[em]/S[dcl]            t->(s->t)
      term  \p:(s->t). p   [term type (s->t)->(s->t): intensional parameter lifted]
      from  closed-class entry (CCGSem table, keyed by word+category): complementiser (declared s->t parameter)
    the       NP[nb]/N                (e->t)->((e->t)->t)
      term  \P:(e->t). \Q:(e->t). Q(iota(P))
      from  closed-class entry (CCGSem table, keyed by word+category): definite determiner
    cat       N                       e->t
      term  \x:e. cat(x)
      from  open-class template (CCGSem, by category shape): noun (template)
    is        (S[dcl]\NP)/(S[adj]\NP) (((e->t)->t)->t)->(((e->t)->t)->t)
      term  \V:(((e->t)->t)->t). V
      from  closed-class entry (CCGSem table, keyed by word+category): copula (predicative adjective)
    not       (S\NP)\(S\NP)           (((e->t)->t)->t)->(((e->t)->t)->t)
      term  \V:(((e->t)->t)->t). \S:((e->t)->t). S(\x:e. ~V(\P:(e->t). P(x)))
      from  closed-class entry (CCGSem table, keyed by word+category): VP negation
    red       S[adj]\NP               ((e->t)->t)->t
      term  \S:((e->t)->t). S(\x:e. red(x))
      from  open-class template (CCGSem, by category shape): one-place predicate (template)
    .         .                       (no type)
      term  (structural: no meaning of its own; the coordination or punctuation rule consumes it)
      from  closed-class (structural): punctuation "."

  β-normal form:
    say(Bob, \w1:s. ~red_s(w1, iota(\x:e. cat_s(w1, x))))
    : t   (category S[dcl])

== 4. DRS (sentence-local, after local anaphora and presupposition projection) ===
  +----------------------+
  |                      |
  +----------------------+
  | say(Bob, K)  K:      |
  |   +----------------+ |
  |   |                | |
  |   +----------------+ |
  |   | NOT:           | |
  |   |   +----------+ | |
  |   |   |          | | |
  |   |   +----------+ | |
  |   |   | red(cat) | | |
  |   |   +----------+ | |
  |   +----------------+ |
  +----------------------+

== 5. CLAIMS (Verify.Reported.splitClaims) =================================
  rule: only top-level conditions of the main box are asserted; whatever sits inside
        ~, =>, OR, an attitude box (K) or a presupposition box is not.
  Asserted:
    say(Bob, [ | ~[ | red(cat)]])
  Reported:
    ~[ | red(cat)]    source chain: say(Bob)
  Presupposed:
    (none)
  Embedded (not asserted, cannot reach an oracle):
    (none)

== 6. FAILURES / NOTES =====================================================
  failures: none (lexicon, parse and meaning all succeeded)
  notes (logged decisions and diagnostics):
  [scope] chose subject > not over 1: not > subject
      why: lexical entry for VP negation gives the subject wide scope; the two readings differ only for a quantified subject
      at:  25:28 "not"
  [definite-in-report] chose de dicto: the description is local to the report over 1: de re (description scoped out of the attitude, asserted)
      why: complements are read de dicto; de re readings are not generated
      at:  0:33 "Bob says that the cat is not red ."
```

Things to notice: *not* attaches to *is* by backward crossed composition (`<Bx`), the that-clause is a proposition (`\w1:s. ...`, type `s->t`), and `red(cat)` sits two boxes down, so it is reported (`say(Bob)`) and never asserted.

### Repaired seams and remaining limits

The table distinguishes bounded repairs from remaining coverage and meaning errors. A passing handwritten regression does not establish coverage of every instance of the construction. The recorded corpus checks and paired coverage experiment are summarized in `research/FINDINGS.md`.

| Unit | Current behavior | Scope or remaining limit |
|---|---|---|
| 2 | Endomorphic modifiers preserve matched features: `is not` retains `[dcl]` through `<Bx`. | This is targeted feature propagation, not a full feature-variable unifier. |
| 2 | Final punctuation may still attach inside the tree (`red .`). | Usually semantically inert; punctuation constructions need their own checks. |
| 2 | The existing type-raising/composition semantics now activate for the recognized argument-cluster coordination pattern, including `Bob likes and Anne hates the cat`. | Raising is not globally enabled. The selected corpus reading is correct, but a second returned reading is `likes(Bob) ∧ hate(Anne,cat)`. The shared indefinite-object regression introduces one existential, not one per conjunct. |
| 2 | An optional `--pos-backoff` uses known NN/NNS/JJ evidence to add missing noun/adjective categories. | Off by default; no invented verb valency or contextual POS tagger. The licensed-model probe repairs round but not kind: round has JJ evidence, whereas kind has none in sections 02–21. On 120 OWA depth-5 dev theories (2,244 theory sentences), exact translation rises from 86.7% to 93.0%; 2,560 question translations rise from 90.5% to 95.6%; whole-theory exactness rises from 32/120 to 65/120. These are translation measurements, not QA accuracy. |
| 3, 4 | Restrictive subject relatives compose at N level, so `Every cat that is red is big` restricts the universal to red cats. | Object-gap relatives remain unsupported. Comma-marked relatives fail closed rather than silently becoming restrictive. Verified on the licensed-model regression. |
| 4 | Main-box named and definite constants can antecede later pronouns, while subordinate content remains inaccessible. | Recency is deterministic and logged; this is not gender/animacy inference. Attitude participants are excluded from the neuter `it` candidate set. |
| 5 | A matrix factive complement is listed as Presupposed, without a duplicate Reported row. | Factive content inside a report retains the enclosing source chain. It is not promoted to assertion. |
| 5 | A conservative inflection table normalizes `added` to `add`, `noted` to `note`, and selected other known forms; reporting attestation uses the same normalization. | This is not a general English lemmatizer. Unsupported past forms are preserved, not guessed. |
| 5 | Recognized comma quotation suffixes retain only an exact matching attribution root; otherwise the sentence abstains, with discarded meanings logged. | Bounded suffix patterns are VERB+NP and NP+VERB with known verb POS and a parsable name/determiner NP. Unknown POS, adverbial tails and general dialogue are outside this guard. The corpus example `The cat is red, boasted Bob` now abstains. |
| 5 | `see that` has a logged unresolved sense choice and defaults to non-factive attribution. | Perceptual `see that` is factive; supervisory `see that` need not be. The system does not yet disambiguate these senses. The corpus example now parses with Reported content only; the baseline failed to parse. |
| — | `Bob likes the cat and the dog` may retain the spurious `cat dog` reading. | No general NP-coordination repair was made in this phase. Check all returned readings, not just the ranked selection. |

The broader ambiguity policy is still a separate inference obligation. Passing the highest-ranked reading does not establish a skeptical conclusion across the parser's bounded candidate set.

---

## The invariants you should be able to state cold

These come at the start because they are the payoff. Each unit below exists to make one or two of them obvious.

| # | Invariant | Theory it comes from | Where it bit us or will bite us |
|---|---|---|---|
| 1 | The category determines the base semantic type; declared intensional parameter lifting is checked separately. Slash direction controls combination, not semantic function type. | CCG + typed λ | `S[em] ↦ s→t`. A wrong category gives a well-typed wrong meaning, which is the "silent" error class. |
| 2 | A small combinator inventory does not make every failure lexical: semantics, features, learned rules, bounded search and safety guards also matter. | CCG / CCGbank | round/kind: desired word/category pairs are missing; only round has adjective POS evidence in the loaded dictionary. |
| 3 | Only the top-level conditions of the main DRS are asserted. Their truth can depend on the main box's witness assignment; a bare condition must bind all its references before independent oracle confirmation. | DRT truth definition | Negation leak: 25,227 → 6,781 facts, including 775 polarity flips. Separately canonicalized existential witnesses also collided at r0 until the closure gate. |
| 4 | An attitude complement is evaluated at another world. Only factives bring it back to the actual world, and then as a presupposition. | Intensional semantics | The reported default, quote categories, "boasted", "sees that". |
| 5 | Classical proof is monotone. A partially parsed theory can prove things, but it can never conclude "Unknown". | Logic / OWA | Error-handling decision (b): abstain and fall back. |
| 6 | Required inference policy: accept a skeptical conclusion only across all admitted readings, and disclose search truncation. The display pipeline still selects one ranked reading. | Nonmonotonic reasoning | The "Bob added" lower-ranked reading that asserts. |
| 7 | Strength is algebra: ⊗ along a chain, ⊕ across alternatives, and no self-support through cycles. | Provenance semirings / TMS | Fusion graph: "fuse strongly" vs "linger". |
| 8 | Only the oracle creates `Confirmed`: an asserted witness is required by the types, and standalone reference closure is checked at runtime. | Type-level programming + binding scope | Raw-condition and coercion/promotion routes are closed. Open contextual claims abstain; caller-authored DRSs and custom oracles remain trust boundaries. |

---

## Order and pacing

Roughly 10 weeks at 6–8 hours a week. Each unit ends with a "predict by hand, then run the system, then diff" exercise.

| Week | Unit | Unlocks |
|---|---|---|
| 1 | 1. Logic and typed λ-calculus | everything |
| 2–3 | 2. CCG and CCGbank | decision (a), round/kind |
| 4 | 3. Syntax–semantics interface, plus 8. Types as guarantees | reading CCGSem.hs and Oracle.hs fluently |
| 5 | 4. DRT (+ SDRT sidebar) | invariant 3, decision (c), wiring SDRT/Threading |
| 6 | 5. Intensionality and attitudes | invariant 4, the Reported/Presupposed design |
| 7 | 6. Inference: what "proved" and "Unknown" mean | decision (b), error handling and solver choice |
| 8–9 | 7. Evidence, belief and the fusion graph | the core thesis, made precise |
| 10 | 9. Evaluation, plus the capstone | defensible benchmark claims |

**Capstone (week 10):** take one ProverQA-hard item and trace it fully by hand: categories, λ-terms, DRS, claim table, proof and strength. Then write a one-page decision memo for (b).

---

## Unit 1: Logic and typed λ-calculus (week 1)

**Why here:** Every later unit is written in this notation. `Semantics/Lambda.hs` is this unit as code.

**Core ideas (only these):**
- Syntax vs. models. Entailment (⊨) vs. provability (⊢), and soundness/completeness, which says the two agree.
- First-order logic is semi-decidable: a prover may never return. That is why "Unknown" has to be engineered.
- Quantifier scope: "every cat chased a dog" has two readings.
- λ-abstraction, β-reduction, currying.
- The types `e` (entity), `t` (truth value) and functions between them.
  - A noun or adjective is `e→t`.
  - A transitive verb is `e→e→t`.
  - A generalized quantifier is `(e→t)→t`.
  - "every" is `(e→t)→(e→t)→t`.

**Exercise:**
1. Give the type and λ-term for *Bob*, *red*, *not*, *every* and *if*.
2. β-reduce "every cat is red" step by step until you reach `∀x(cat(x)→red(x))`.
3. Explain why "Bob" can be typed either `e` or `(e→t)→t` (type raising, which shows up again in Unit 2).
4. Check 1 and 2 with `nl2proof-explain --stage=lambda "Every cat is red."` (or `--hand "Every student smiles."` for the hand fragment's terms).

**You've got it when:** you can read any `Ty` in Lambda.hs and say which English words could have it.

**Read:**
- Coppock & Champollion, *Invitation to Formal Semantics*. Free online; read the chapters on λ-calculus and types.
- Alternative: Heim & Kratzer (1998), *Semantics in Generative Grammar*, chs. 1–4.
- Blackburn & Bos (2005), *Representation and Inference for Natural Language*, chs. 1–2. This is the closest book to what nl2proof *is*, so keep it nearby for the whole plan.

---

## Unit 2: CCG and CCGbank (weeks 2–3). The biggest gap

**Why here:** The parser, the lexicon, coverage, the reported default and decision (a) all depend on it.

**Core ideas:**
- **A category is a directed function type.** `(S[dcl]\NP)/NP` means "give me an NP on the right, then an NP on the left, and I am a declarative sentence."
  - `/` looks right and `\` looks left.
  - The result is always on the left: X/Y reads "X, looking for Y".
- **Atoms and features.**
  - Atoms: `S`, `NP`, `N`, `PP`.
  - The features that matter here:
    - `S[dcl]`: declarative.
    - `S[em]`: embedded "that"-clause.
    - `S[b]`: bare infinitive.
    - `S[to]`: to-infinitive.
    - `S[pss]`: passive.
    - `S[ng]`: -ing form.
    - `S[adj]`: predicative adjective.
    - `NP[nb]`: non-bare NP, as in "the cat".
- **The rules.**
  - Forward and backward application (`>` `<`).
  - Composition (`>B` `<B`) and crossed composition (`<Bx`).
  - Type-raising (`>T`).
  - Coordination.
  - That's essentially the whole grammar.
- **CCGbank adds engineering rules that are not "pure" CCG.** These are unary type-changing rules (for example N→NP for bare plurals) and punctuation rules. They live in `Syntax/CCGTypeChange.hs`. Many oddities come from here.
- **Why composition and raising exist.** Take "Bob likes and Anne hates cats". "Bob likes" must become a constituent of type `S/NP`. The side effect is **spurious ambiguity**: many derivations with the same meaning. That's harmless for meaning but costly for parsing.
- **The lexicon carries much of the language-specific work.** Word/category evidence and closed/open lexical meanings interact with feature-sensitive combinators, learned type changes, construction guards and bounded search. A parse failure may arise at any of these boundaries.
- **Supertagging is "almost parsing"** (Clark & Curran). Choosing each word's category is the hard part; once categories are chosen, combining them is nearly deterministic.
- **CCGbank was derived from Penn Treebank Wall Street Journal text.** Its loaded word/category dictionary lacks the desired predicative tags for round/kind. Optional POS backoff repairs round using observed JJ evidence; kind has no such evidence and remains unsupported. Measure exact translation as well as coverage: a successful parse alone is not validation.
- **The category → type map:**
  - `S[dcl] ↦ t`, `S[em] ↦ s→t`, `NP ↦ (e→t)→t`, `N ↦ e→t`
  - `X/Y` and `X\Y ↦ catTy(Y) → catTy(X)`
  - Direction disappears, so the semantics cannot tell `/` from `\`.
  - Proper-name constants have type `e`, but lexical NP entries lift them to generalized-quantifier type. Declared intensional parameter lifting may give a lexical term a different type from the base category interpretation; composition checks that lifting explicitly.

**Lives in:** `Syntax/Category.hs`, `CCGRules.hs`, `CCGBank.hs` (the `.auto` reader), `CCGSupertag.hs`, `CCGTypeChange.hs`.

**Exercise:**
1. Derive by hand "Bob says that the cat is not red" using the CCGbank categories:
   - *says* `(S[dcl]\NP)/S[em]`
   - *that* `S[em]/S[dcl]`
   - *the* `NP[nb]/N`
   - *cat* `N`
   - *is* `(S[dcl]\NP)/(S[adj]\NP)`
   - *not* `(S\NP)\(S\NP)`
   - *red* `S[adj]\NP`
2. Derive "Bob likes and Anne hates cats". You will need `>T` and `>B`.
3. Open a real `.auto` file under `~/ccgbank/ccgbank_1_1/data/AUTO/00/` and find a "says that" sentence. Read the bracket notation until it looks like your hand derivation.
4. Pick five ProofWriter sentences and predict which word, if any, lacks a category. Then check with `proofwriter-coverage`.
5. Check 1 with `nl2proof-explain --stage=deriv "Bob says that the cat is not red."` (`--stage=tags` for the categories alone). For 4, section 6 of the full output names the failing stage.

**You've got it when:** you can localize a failure to lexical/category coverage, semantic entry, combinator/feature handling, a safety guard or the search bound, and distinguish no parse from a well-typed wrong meaning.

**Read:**
- Steedman & Baldridge (2011), "Combinatory Categorial Grammar", in Borsley & Börjars (eds.), *Non-Transformational Syntax*. These are the best 40 pages on CCG; start here.
- **The CCGbank manual is already on your disk:** `~/ccgbank/ccgbank_1_1/doc/CCGbankManual.pdf`. Read the sections on categories, features and type-changing rules.
- Hockenmaier & Steedman (2007), "CCGbank", *Computational Linguistics* 33(3).
- Clark & Curran (2007), "Wide-coverage efficient statistical parsing with CCG and log-linear models", *Computational Linguistics* 33(4). Read it for the supertagging idea only.
- Reference: Steedman (2000), *The Syntactic Process*.

> **Sidebar on the Lambek calculus.** Lambek is the full *logic* of categories: hypothetical reasoning, an elegant proof theory, and proofs that *are* λ-terms (Curry–Howard). CCG keeps a finite set of combinators from it, which makes it slightly more expressive and efficient to parse. Skip it unless you plan to change formalisms. If you're curious, read Moot & Retoré (2012), *The Logic of Categorial Grammars*, ch. 1.

---

## Unit 3: The syntax–semantics interface (week 4)

**Why here:** This is the seam between Units 1 and 2, and `Semantics/CCGSem.hs` is where it lives. It's also where silent errors are born.

**Core ideas:**
- **Compositionality, rule by rule.** Each combinator is one λ-operation:
  - application is function application;
  - composition `>B` is `λx. f (g x)`;
  - type raising is `λf. f a`.
  So the meaning comes for free from the derivation.
- **Closed-class vs. open-class words.**
  - Closed-class words carry the logic as hand-written λ-terms: *the, every, no, not, if, that, and, or, either*.
  - Open-class words (nouns, verbs, adjectives) get a template chosen by their category.
  - That's why CCGSem keys closed-class entries on the pair (word, category).
- **Where meaning gets lost:** punctuation rules, unary rules, multi-word expressions, and words used in categories the templates never anticipated.
- **The silent-error class.** A parse may succeed and type-check while its meaning is wrong. Report this with a dataset, split, denominator and manual or reference criterion. Parse coverage alone cannot measure semantic precision; the old approximately 0.35% figure is historical, not a current universal error rate.

**Exercise:**
1. Write the open-class templates for `N`, `S[adj]\NP` and `(S[dcl]\NP)/NP`.
2. Show that `>T` followed by `>B` gives the same meaning as two plain applications. This is why spurious ambiguity is semantically harmless.
3. Find one silent error in the coverage output and explain which closed-class entry or template produced it.
4. `--stage=lambda` shows each leaf's term and whether it came from a closed-class entry or an open-class template; use it for 1 and 3.

**Read:**
- Blackburn & Bos (2005), chs. 2–3. It builds exactly this in Prolog.
- Bos (2008), "Wide-coverage semantic analysis with Boxer", *STEP 2008*. This is the closest prior system.
- Mineshima, Martínez-Gómez, Miyao & Bekki (2015), "Higher-order logical inference with compositional semantics", *EMNLP* (ccg2lambda). Compare their template design to CCGSem.

---

## Unit 4: Discourse Representation Theory (week 5)

**Why here:** DRT/*, `Verify/Reported.hs` (`splitClaims`/`topCond`) and the negation bug.

**Core ideas:**
- **A DRS** is a box of discourse referents plus conditions. Complex conditions contain sub-boxes: `¬K`, `K ⇒ K'`, `K ∨ K'`, attitude(K).
- **Truth via embedding.** The main DRS is true iff some assignment of its referents verifies all of its *top-level* conditions. A sub-box is only ever evaluated as part of its parent condition.
  - **This is invariant 3.** The negation leak happened because DRS conditions were flattened as if all boxes were the main box.
  - The assignment matters even for a top-level atom: `[x | P(x)]` asserts an existential, not a standalone P(r0) about a globally named object. The scope audit found that two true documents, `exists x.P(x)` and `exists y.(P(y) implies q)`, could previously yield false q when separate local witnesses both canonicalized to r0. `Oracle.check` now returns Unknown for conditions with free canonical references; contextual claims remain inspectable, and whole-DRS solving retains the box. The reproducible finite-model control is `research/probe-claim-scope.hs`.
- **Accessibility.**
  - A referent introduced in the antecedent of `⇒` is visible in the consequent: "If a farmer owns a donkey, he beats it."
  - Nothing inside `¬` is visible outside.
  - Donkey sentences are the classic test.
  - Main-box names and definite constants can also antecede later pronouns; they are not converted into existential variables. The implementation logs recency and excludes attitude participants from neuter `it` candidates. This is a bounded heuristic, not full salience or animacy inference.
- **Presupposition as anaphora** (van der Sandt). A presupposition tries to bind to something already in context; failing that, it is *accommodated* at the highest box it can reach. That's why "Bob doesn't know that the cat is red" still presupposes red(cat), and why `CPresup` projects through negation.

**Exercise:**
1. Draw the DRSs for "Bob is not big", "If a cat is red, it is big" and "Either the cat is red or Bob is happy". For each, list exactly which atomic facts are entailed. (Answer: none of the atoms.)
2. Draw "Bob doesn't know that the cat is red" and mark what projects to the main box.
3. Compare your answers to the claim table the system produces.
4. `--stage=drs` and `--stage=claims` draw the box and the claim split for each sentence in 1 and 2.

**Read:**
- Kamp, van Genabith & Reyle (2011), "Discourse Representation Theory", in *Handbook of Philosophical Logic*, vol. 15. This is the best single overview.
- Kamp & Reyle (1993), *From Discourse to Logic*, chs. 1–2. Long; skim it for the construction algorithm.
- van der Sandt (1992), "Presupposition projection as anaphora resolution", *Journal of Semantics* 9(4).

> **Sidebar on SDRT (only before wiring `Discourse/SDRT.hs`, decision c).** It covers discourse relations between DRSs (Narration, Elaboration, Contrast, Result) and the right-frontier constraint, which limits what a new sentence can attach to. Read Asher & Lascarides (2003), *Logics of Conversation*, chs. 1–4.

---

## Unit 5: Intensionality and attitudes (week 6)

**Why here:** `Semantics/Intensional.hs`, `CAtt`, `CPresup`, `Verify/ClaimKind.hs`, and the whole Reported/Presupposed design.

**Core ideas:**
- **Extension vs. intension.** An intension is a function from worlds to extensions, of type `s→τ`.
  - Attitude verbs take intensions: "Bob says that P" relates Bob to the *proposition* P, not to P's truth value.
  - That's why `S[em] ↦ s→t`.
- **Opacity.** In opaque contexts you cannot substitute co-referring terms.
  - The test has to use a *contingent* identity, such as "the winner = Anne", rather than a necessary one.
  - That was one of the corrections to the original spec.
- **Ty2 (Gallin)** makes world variables explicit. That's why the code has world-indexed twins `c_s : s→τ`, and why plain `c` means `c_s w0`.
- **Hintikka semantics.** "a believes P" = P holds in every world compatible with a's beliefs. This is the bridge to epistemic logic in Unit 7.
- **Factivity** (Kiparsky & Kiparsky):
  - *know, realize, regret* presuppose their complement.
  - *say, believe, claim* do not.
  - *prove, manage* are implicative, which is a different behaviour.
  - A matrix factive complement is Presupposed only. Inside an outer report, projected factive content retains that outer source chain. Neither case promotes it to an asserted world fact.

**Exercise:** Classify *say, believe, know, see, add, note, boast, regret, claim, prove* as factive, non-factive or implicative. For each, predict whether "Bob V that the cat is red" should report, presuppose or assert red(cat), then check what the system does.
Check each prediction with `nl2proof-explain --stage=claims "Bob V that the cat is red."`: Reported (with its source chain) vs. Presupposed is the answer.

**Sense matters for `see that`:** perceptual `see that P` is factive, while supervisory uses that mean ensuring something is done do not license P as already true. The parser logs `see-sense` and retains an unresolved non-factive attribution. This is a limitation, not a claim that perceptual seeing is non-factive. The baseline corpus example failed to parse; the repaired example is Reported only. See Christina H. Dietz, [“Reasons and factive emotions,” §3](https://link.springer.com/article/10.1007/s11098-017-0929-y), and Vitaly Voinov, [“Seeing is trying”](https://www.cambridge.org/core/journals/language-and-cognition/article/abs/seeing-is-trying-the-relation-of-visual-perception-to-attemptive-modality-in-the-worlds-languages/A0F8846B72AEB95F3A22E02B614CB86B).

**Read:**
- von Fintel & Heim, *Intensional Semantics* (MIT lecture notes, free), chs. 1–3.
- The intensional chapters of Coppock & Champollion.
- Kiparsky & Kiparsky (1970), "Fact".
- Reference only: Gallin (1975), *Intensional and Higher-Order Modal Logic*.

---

## Unit 6: Inference, or what "proved" and "Unknown" mean (week 7)

**Why here:** This unit is decision (b): error handling and the choice of solver.

**Core ideas:**
- **Horn clauses and Datalog.**
  - Forward chaining reaches a fixpoint, and backward chaining reaches the same answers.
  - ProofWriter fits inside Datalog with negation; FOLIO and ProverQA need more.
- **CWA vs. OWA (Reiter).**
  - Under the closed-world assumption (CWA), anything not derivable is false (negation as failure).
  - Under the open-world assumption (OWA), it's Unknown.
  - ProofWriter-OWA has three values: True, False (¬q is derivable) and Unknown.
  - Stratified negation is what keeps negation-as-failure well defined.
- **Monotonicity (invariant 5).** Adding premises never removes classical conclusions.
  - So a proof from a *partial* parse is still sound.
  - But "Unknown" from a partial parse is not: the unparsed sentence might have been the proof.
  - This is the theoretical basis for "abstain, then fall back to the LLM".
- **Skeptical vs. credulous reasoning (invariant 6).** Skeptical: conclusions that hold in all readings. Credulous: conclusions that hold in some reading. "Reason under all readings" is only safe in the skeptical form.
- **Full first-order logic.** Covers resolution, Prover9, and SMT solvers such as Z3 for decidable fragments. You need these once disjunction and existentials appear (FOLIO, ProverQA).

**Exercise:**
1. Hand-run forward chaining on one depth-3 ProofWriter theory.
2. Delete one sentence and show which answers flip True→Unknown, and that none flip True→False.
3. Write down which ProverQA-hard constructs, such as "either…or" and existentials, fall outside Horn clauses. That list decides the solver choice.
4. Run the theory's sentences through `nl2proof-explain --stage=claims`: only the Asserted lines become premises.

**Read:**
- Abiteboul, Hull & Vianu (1995), *Foundations of Databases* (free online as the "Alice book"), Part D, chs. 12–15: Datalog and negation.
- Reiter (1978), "On closed world data bases", in Gallaire & Minker (eds.), *Logic and Data Bases*.
- Huth & Ryan (2004), *Logic in Computer Science*, chs. 1–2, as a refresher.
- The competition, i.e. LLM→logic pipelines:
  - Tafjord, Dalvi & Clark (2021), "ProofWriter", *Findings of ACL*;
  - Pan et al. (2023), "Logic-LM", *Findings of EMNLP*;
  - Olausson et al. (2023), "LINC", *EMNLP*.

---

## Unit 7: Evidence, belief and the fusion graph (weeks 8–9)

**Why here:** `Genealogy.hs`, `Fusion.hs`, `Provenance.hs` and `Verify/Oracle.hs`. This is the most original part of the project and the least formalized, and it's where the "wishy-washy" feeling comes from.

Your informal vocabulary maps onto established formalisms. Pick one formalism for each word, and the vagueness turns into choices you can defend:

| Your word | Formal counterpart | What it gives you |
|---|---|---|
| "graph of justifications", "retraction" | **Truth maintenance**: JTMS (Doyle) and ATMS (de Kleer) | A node is IN iff some justification's premises are all IN. Retraction propagates. Circular support must not ground itself. ATMS labels record the minimal sets of sources a fact depends on. |
| "fuse strongly" / "linger weakly" | **Provenance semirings** (Green, Karvounarakis & Tannen) | ⊗ combines premises along a chain and ⊕ combines alternative derivations. Booleans give provability, counting gives the number of proofs, and (max, ×) gives the strength of the best chain. If strength is a semiring, fixpoints and order-independence come for free. If it's ad hoc numbers, they don't. |
| "backed by evidence", "fill backwards" | **Justification logic** (Artemov) | `t:φ` means "t is evidence for φ". From `s:(φ→ψ)` and `t:φ` you get `(s·t):ψ`. Evidence terms travel with conclusions, which is your backward fill. |
| "Bob believes / says" | **Epistemic logic** (Fagin, Halpern, Moses & Vardi) | `K_a φ` and `B_a φ`, i.e. Kripke semantics for what `CAtt` means. |
| hearsay vs. evidence in conflict | **AGM belief revision**; **Dung argumentation** | Minimal change when retracting. The grounded extension is deterministic and skeptical, which suits your aversion to stochastic methods. |
| (optional) graded uncertainty | Dempster–Shafer / subjective logic | Numeric belief with explicit "don't know" mass. It's stochastic in flavour, so only reach for it if the semiring is not enough. |

**Exercise:**
1. Define strength as the (max, ×) semiring, with oracle = 1.0 and hearsay = 0.3. Compute the strength of a depth-3 conclusion with one hearsay premise. Then add an alternative oracle-backed derivation and recompute.
2. Add the cycle A⇒B, B⇒A with no other support. Under JTMS rules, are A and B IN? (They should be OUT.) Then read `Genealogy.hs` and check that it agrees.
3. In one paragraph, state which semiring nl2proof uses today and whether Fusion actually obeys its laws.
4. `--stage=claims` on "Alice says that Bob believes that the cat is red." shows the source chain a hearsay strength would attach to.

**You've got it when:** "fuse strongly vs. linger" is a definition you could put in the README, not a metaphor.

**Read:**
- Forbus & de Kleer (1993), *Building Problem Solvers*, the JTMS and ATMS chapters. This is the engineering-level treatment; start here.
- Doyle (1979), "A truth maintenance system", *Artificial Intelligence* 12(3).
- de Kleer (1986), "An assumption-based TMS", *Artificial Intelligence* 28(2).
- Green, Karvounarakis & Tannen (2007), "Provenance semirings", *PODS*.
- Artemov (2008), "The logic of justification", *Review of Symbolic Logic* 1(4).
- Fagin, Halpern, Moses & Vardi (1995), *Reasoning About Knowledge*, chs. 1–3.
- Alchourrón, Gärdenfors & Makinson (1985), "On the logic of theory change", *Journal of Symbolic Logic* 50(2).
- Dung (1995), "On the acceptability of arguments…", *Artificial Intelligence* 77(2).

---

## Unit 8: Types as guarantees (interleave with week 4)

**Why here:** `Verify/Oracle.hs`, `Verify/ClaimKind.hs` and the compile-fail tests.

**Core ideas:**
- Phantom types and DataKinds: `Claim 'Asserted` vs `Claim 'Reported`.
- Unexported constructors make `Confirmed` unforgeable outside the module.
- "Parse, don't validate."
- The "Ghosts of Departed Proofs" pattern, a type-level token that proves a check happened. That is exactly `Confirmed`.
- The token-producing oracle accepts only a `Claim 'Asserted` witness obtained structurally from a top-level DRS condition. `Claim` has a nominal role, so `Data.Coerce` cannot relabel Reported or Embedded content. Raw conditions can be checked diagnostically without producing `Confirmed`; public arbitrary promotion is removed.
- The witness certifies top-levelness, not closure. `freeCanonRefs` checks whether the condition contains every binder it needs. `Oracle.covers` and `check` reject open conditions before calling the custom oracle, even when that oracle would accept everything. An implication's antecedent binders scope over its consequent; negation/disjunction binders do not escape. A closed quantified condition may be confirmed, while an atom whose existential binder lives only in the enclosing DRS must abstain at this interface.
- This protects the module boundary, not the truth or provenance of a caller-authored DRS. Source authenticity and semantic correctness remain separate obligations.

**Exercise:**
1. Explain why compile-fail tests, rather than unit tests, are the right tests for the lock.
2. Trace a top-level condition through `assertedClaims`, `splitClaims` and `confirm`; explain why an extracted negated-box literal cannot obtain the same witness. Read the compile-fail cases for raw conditions, nonasserted kinds, constructor forging and coercion.
3. `--stage=claims` shows which kind (Asserted, Reported, Presupposed, Embedded) each condition gets, i.e. what the oracle boundary is checking.
4. Compare the closure of an atom in `[x | P(x)]` with the whole condition `[x | P(x)] implies [ | Q(x)]`. Predict why only the latter can receive a bare-condition token. Run `scope-oracle` and the finite-model probe; explain why runtime scope tests complement the compile-fail lock tests.

**Read:**
- King (2019), "Parse, don't validate" (blog post).
- Noonan (2018), "Ghosts of departed proofs (functional pearl)", *Haskell Symposium*.

---

## Unit 9: Evaluation (week 10, light)

**Core ideas:**
- With n = 120, a Wilson 95% interval is roughly ±8 points, so differences smaller than that are noise.
- "Small model + graph ≥ big model" needs a **paired** test on the same items (McNemar), not two separate accuracy numbers.
- Risk–coverage trade-off. A system that abstains should be reported as coverage × selective accuracy, not folded into one accuracy number.
- Label noise (FOLIO v0.0) and saturation (ProofWriter) limit what any result can show.

**Read:**
- Dror, Baumer, Shlomov & Reichart (2018), "The Hitchhiker's Guide to Testing Statistical Significance in NLP", *ACL*.
- Geifman & El-Yaniv (2017), "Selective classification for deep neural networks", *NeurIPS*. Read it for the risk–coverage idea only.

---

## Deliberately skip (for now)

- **Lambek calculus proof theory.** Only needed if you change formalisms.
- **Montague's full PTQ fragment.** Units 1 and 5 cover what's used.
- **Dynamic Predicate Logic and other dynamic semantics.** DRT is enough.
- **RSA and probabilistic pragmatics.** Only relevant once reading *ranking* matters, and they stay a layer on top in any case.
- **DisCoCat and category-theoretic semantics.**
- **Parser internals** (A* CCG parsing, neural supertaggers). Treat the tagger as a black box with a known error profile.

## Open decisions and the unit that settles each

| Decision | Settled by |
|---|---|
| (a) POS backoff: retain the experimental flag or enable by default based on measured coverage and precision | Unit 2 |
| (b) error handling: all readings, LLM translation at hearsay strength, solver | Units 6 + 7 |
| (c) wire Readings/Discourse into Pipeline | Unit 4 sidebar |
| `see that`: disambiguate perceptual and supervisory senses; retain the logged conservative default meanwhile | Unit 5 |
| oracle boundary: audit structural witnesses and caller-authored DRS trust boundary (raw promotion closed) | Unit 8 |
