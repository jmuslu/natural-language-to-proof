# Scoped parser and reasoning experiments

These drivers measure conditional logical consequences of parser-produced DRSs.
They do not verify that English was translated correctly, and neither a solver
answer nor a model translation creates an oracle confirmation. Dataset labels and
gold formulas are excluded from parser requests and model prompt projections.

Install the optional FOL solver in the ignored research environment:

```sh
python3 -m venv research/.venv
research/.venv/bin/pip install -r bench/reasoning/requirements.txt
cabal build nl2proof-parse-json
research/.venv/bin/python bench/reasoning/run.py parse --bench all --limit 120 --binary "$(cabal list-bin nl2proof-parse-json)" --output research/runs/parses.jsonl
research/.venv/bin/python bench/reasoning/matrix.py --parses research/runs/parses.jsonl --out-dir research/runs/matrix
```

The parser loads CCGbank once per process. `--pos-backoff` is a separate parse
condition; the flag is off by default. Caches include input/configuration/binary
hashes. Seal a completed cache before evaluating it: its file hash identifies the
experiment. Never commit parser caches, licensed data or bulk result files.

`run.py evaluate` selects `--backend horn|z3`, `--readings top|skeptical|credulous`,
`--or-semantics inclusive|proverqa`, and `--min-top-mass`. `matrix.py` solves each
returned theory/query combination once and reuses the results for all three
reading policies and top-mass thresholds0,.5,.8,.95. These thresholds are fixed
operational probes, not calibrated confidence or tuned held-out thresholds.
Its recorded latency includes all variants shared across policies; it is not
standalone top-policy deployment latency. Parse latency is reported separately.

The signed Horn backend has explicit positive and negative atoms, conjunction and
range-restricted function-free rules. It does not use contraposition. It returns
all minimal support environments, with top-condition IDs including rule sources.
Cooperative time checks run inside joins and support operations;100000-entry caps
bound intermediates. Hitting a budget abstains without truncating supports into
an answer. This is not a hard real-time scheduler guarantee.

Z3 handles scoped classical first-order logic, equality, disjunction and
existentials. It assumes a nonempty domain, without domain closure or unique names.
Each box binds existential referents; implication antecedent referents are
universally quantified over antecedent and consequent. A proof includes one
sufficient unsat core, not all independent supports. Z3 unknown and timeout mean
abstention, not logical Unknown. The budget is per solver check; consistency and
the two entailment directions can each use it. Quantified FOL is incomplete.

Both backends first reject an inconsistent accepted theory. A proof from supported
premises may answer despite residual sentences; an Unknown answer requires the
whole theory and query to be supported. This monotonic guarantee is conditional
on the accepted premises being faithful. Reports and presuppositions are residual
scopes, never silently asserted as their contents. Logical Unknown maps to the
benchmark's third label; on binary ProntoQA it abstains.

General DRS semantics retains person/thing guards. The opt-in
`--domain-policy proofwriter` is allowed only with `--bench proofwriter` (or
`matrix.py --benches proofwriter`). It removes narrowly localized bound sortal
guards from flat Horn antecedents, matching the benchmark's unsorted-variable
convention. It **strengthens** those rules and is not a general English rewrite.
Every removal carries a decision and the original provenance. The default is
`strict`; no query, ground fact, nested scope or reported condition is rewritten.
Use separate output directories for the two policies.

The ProverQA disjunction option treats a locally unambiguous lexical either/or as
exclusive. Ambiguous localization remains unsupported; plain or stays inclusive.
This is a benchmark convention, not a general claim that English either is always
exclusive. FOLIO annotations include known noise. Neither benchmark is a direct
measure of source authenticity or evidence withdrawal.

Top uses the first returned theory/query. Skeptical requires identical non-abstain
answers on every returned combination. Credulous accepts a single proved polarity
with no opposite proved polarity or detected contradiction; it does not infer
Unknown from failure to prove. A combination cap forces both non-top policies to
abstain. Even an untruncated result is limited by the upstream CCG chart beam.
Top-mass is the product of softmax top scores within each sentence's returned
readings. It only filters answers and never admits a fact.

The experimental `llm.py` driver implements graph-context condition C and residual
translation. `prepare` writes inspectable prompts, `call` uses the unchanged
isolated common Codex runner, and `score` joins labels after inference. Use
`--mode graph|translate`; all inference and prompt configuration hashes must
match when resuming or scoring. Translation accepts only requested residual IDs
and a failed query, validates scopes and resource bounds, removes partial
contributions from replaced sentences, freshens variables, and records
LLMTranslated strength. Accepted parsed sentences are retained, including any
undetected semantic errors. These remain untrusted assumptions.

`llm.py hybrid --b B.jsonl --c C.jsonl --fallback residual|translate|abstain`
implements D: a non-abstain B answer, otherwise the selected fallback. IDs and
input hashes must match. Routed deployment cost charges C only on routed items;
full experimental collection cost is separate. Retries may expose only the final
attempt's usage; incomplete accounting is flagged rather than invented.

Check the Python inference and isolation boundaries with:

```sh
research/.venv/bin/python -m unittest discover -s bench/reasoning -p 'test_*.py'
```

Production Haskell gates remain independent. The generated withdrawal benchmark
is documented in `bench/retraction/README.md` and exercises production Genealogy
with authored structured fixtures, not this English parser.
