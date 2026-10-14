"""Prompt consumes narrative fields only; structured fixtures and gold stay private."""
LABELS = ('Established', 'WeakOnly', 'Unsupported', 'Conflict')
STRATA = ('alternatives', 'conjunction', 'cycles', 'rules', 'reports', 'factive',
          'contradictions', 'translated')
STRATUM_NAME = 'family'
PROTOCOL = """Track evidence after withdrawals using these rules. A verification by a named
oracle establishes its content. An unconfirmed assertion, report, factive
presupposition (including 'knows'), or model translation provides weak evidence,
never oracle evidence. Evidence retains its document and all named reporting
speakers. A rule requires every stated premise and its own source if one is named;
a logical rule explicitly described as fixed is available without another source.
Alternative derivations are independent. Cycles and duplicate testimony create no
new evidence. Withdrawing a document, oracle, or speaker removes all evidence
requiring it, including its derived consequences. Other support survives.
For the query AFTER withdrawals, output exactly one label:
Conflict: both the query and its explicit negation retain evidence, even if weak.
Established: the query has an all-oracle derivation and its negation has no evidence.
WeakOnly: the query has evidence but no all-oracle derivation, and no contrary evidence.
Unsupported: the query has no evidence (its negation may have evidence).
Conflict flags source disagreement; it does not turn weak evidence into truth or
allow unrelated conclusions. A rule applies only in its stated direction.
"""

def prompt_body(x):
    return PROTOCOL + '\nScene:\n' + x['context'] + '\n\nQuery: ' + x['statement'] + '\nLabel:'
