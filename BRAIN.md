# Fact brain: operating contract and research frontier

The goal is reliable reasoning that a modest proposer can participate in: generate
alternatives, check them independently, preserve their dependencies, and learn
from failures. A larger collection of demonstrations is not evidence that this
goal has been reached. The integration and evaluation boundaries below define
what currently works and what remains to be established.

## What is connected

`pipeline.py` now performs the oracle handoff instead of printing a description:

```
agentic-qr completed result + explicit FDR family
  -> independently recomputed certificate audit
  -> append-only receipt journal (three-valued, timestamped, replayable)
  -> run-scoped propositions in the epistemic graph and retrieval index
  -> Haskell Verify.Oracle -> confirmation -> genealogy -> fusion -> reward
```

The proposition is **`passes_validation(run_id)`**. A passing backtest does not
prove the mechanism in its prose, its extraction, or the source claims it cited.
Those references remain attribution edges. Statistical failure refutes only the
run-validation proposition; missing or malformed evidence is **Unknown**.

See [ORACLE_BRIDGE.md](ORACLE_BRIDGE.md) for executable commands, protocol,
revision semantics, and measured integration checks.

## Evidence and revision

- Replaying the same run replaces its graph contribution; it cannot accumulate
  duplicate support. Independent run identities cannot share attribution by
  accidentally reusing a hypothesis node.
- A changed certificate produces a journal revision. Withdrawal removes only
  the support actually lost. Re-reading old files cannot undo a withdrawal;
  reinstatement is an explicit, reason-bearing operation.
- Every run receipt gets the time this journal first observed it. Historical
  filenames and event dates cannot backdate newly discovered evidence.
- The Haskell confirmation token and fused set are abstract, immutable values.
  Constructors and record updates cannot insert unconfirmed claims. Compilation
  checks exercise both bypasses.
- A certificate audit establishes consistency of the recorded checks. It does
  not authenticate the producer, establish that the experimental family is
  complete, or prove that training and test data were independent.

## Research modules and their limits

| Modules | Useful mechanism | Evidence still required |
|---|---|---|
| `reason.py` | Typed application and composition | End-to-end extraction fidelity; type correctness alone is not semantic correctness |
| `retract.py` | Least-fixed-point support and precise persistent revisions | Integration with richer generated proof graphs, beyond scoped run receipts |
| `estimand.py` | Units/basis checks and conservative provenance handling | Externally checked measurements; provenance labels are not proof of statistical independence |
| `multihop.py` | Separate proposal and belief paths | Held-out, multi-step tasks with verifier rejection, repair, and resource accounting |
| `abstain.py` | Refuse unsupported labels | Calibration on independently labeled data; a stipulated threshold is not calibrated confidence |
| `selector.py`, `alternates.py`, `metalearn.py` | Compare methods and learn escalation from disagreement | Held-out tasks and equal-budget baselines; avoid learning the benchmark generator |
| `grok.py`, `discover.py` | Distill an invariant and propose new combinations | Transfer outside the shared hand-written feature rule; synthetic accuracy is not frontier capability |
| `regime_estimand.py`, `surprise.py` | Track changing quantities and diagnose residuals | Real measurement identity, revision handling, and prospectively evaluated change detection |

`Leg` describes a measurement pattern; constructing one is not an external
check. Empty or null-only patterns cannot ground. Repeated or overlapping
provenance cannot increase pooled precision, and a correctly predicted negative
effect supports its hypothesis rather than counting against it. Multiplicity is
a count of disjoint *declared* provenance groups, with a stipulated weight.
It is not a derived posterior probability or a proof of a categorical universal
property. The function name `colimit` remains a research analogy.

## Evaluation priorities

1. Run a non-frontier proposer against problems with independently computable
   answers and retained proof steps. Compare direct answers, typed checking,
   oracle checking, and correction at matched token/tool budgets.
2. Hold out rule compositions, graph topologies and surface forms. A renamed
   domain sharing the training label rule is insufficient transfer evidence.
3. Measure false acceptance, coverage under abstention, proof validity, repair
   success, retraction correctness, latency and cost. Report failures as well as
   successful examples.
4. Turn residuals into explicit next experiments, with versioned hypotheses and
   immutable evaluation splits. Repeatedly optimizing against the same test set
   would defeat the external-check discipline.
5. Connect DRT alternatives, typed proof composition, the oracle, and reward
   through these experiments. Keep confidence estimation distinct from the
   discrete proof/verification boundary.

## Current empirical ceiling

The 2026-09-15 audit found **32 historical result files**, of which 9 recorded
completed runs. None carried the validation certificate and stable run identity
needed by the bridge. All 32 therefore remained Unknown and earned zero Haskell
reward. This is a useful recovery result, not a positive economic finding.

The existing semantic trust-imputation calibration remains unlicensed on the
small corpus. Frontier-level reasoning from a weaker proposer is the objective,
not a result established by the current synthetic demonstrations.
