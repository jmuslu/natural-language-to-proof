# ProverQA acceptance-panel design

2026-10-14. Shell verified; read root STATE then ASTRA_GOAL. Isolated
astra/prover-panel-design from fedfbfd. Own proposal and notes only.

Prediction before checks: the existing starter gold and overlapping construction
cues cannot certify population fidelity. The existing occurrence strata should
support a fixed probability sample with a separate targeted diagnostic layer;
unknown contracts must remain in its denominator. No sampling of source text,
re-extraction, parser, model, benchmark, or gold observation is authorized here.
Check aggregate reconciliation, current gold membership and finite-population
threshold arithmetic only. Independent review precedes the proposal commit.

Aggregate checks reproduced N=17,345 across all six strata. Seven ProverQA
fixture files contain 56 IDs / 55 texts; 45 lack explicit semantics_contract and
11 use four contract IDs. The first inspection used the singular field spelling
and was corrected to the actual plural schema before interpreting contract counts.
No fixture meanings were altered. Exact integer-combination arithmetic for
n=800 and one-sided alpha=.025 gives E>=737 (tail .020570196; E=736 tail
.027832719); with W=0, K=78 is first rejected at .024932488, leaving upper
77/17345=.00443932. The initially considered n=600 with individual95% bounds
was not retained: the proposal instead provides simultaneous95% Bonferroni bounds.
This was design arithmetic only, with no text draw or producer observations.
Expected strata allocations and local Markdown links verified; diff check clean.
Reviewer requested before commit.

Arithmetic reproduction (no external library or data input):

```python
from math import comb, floor
N, n, alpha = 17345, 800, .025
den = comb(N, n)
K = floor(.9 * N)
def tail(x):
    return sum(comb(K, k) * comb(N-K, n-k)
               for k in range(max(x, n-(N-K)), min(n, K)+1)) / den
print(next(x for x in range(720, n+1) if tail(x) <= alpha))
print(tail(736), tail(737))
first_rejected = next(k for k in range(1, 200)
                      if comb(N-k, n) / den < alpha)
print(first_rejected - 1, (first_rejected - 1) / N)
```

Reviewer approved methodological proposal before commit and independently
recomputed both hypergeometric thresholds. Approval is not draw authorization:
complete strict contract, sealed frame, reviewed sampler and coordinator agreement
on near-zero remain prerequisites. No source text was selected or parsed.
