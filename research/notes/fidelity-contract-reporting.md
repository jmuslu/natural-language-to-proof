# Public semantic-contract reporting

Full-access shell verified on astra/fidelity-contract-reporting. Own scorer,
README, new test_semantics_contracts.py and this note only. No gold, Haskell,
parser, model or benchmark changes/launches.

Prediction before tests: existing scorer lacks metadata validation, result IDs
and summary partitioning; new independent tests should fail for those omissions,
while id/text-only request projection remains unchanged. Proposed representation:
optional string or object with nonempty id normalized to semantics_contract_id;
unversioned rows use JSON null, never a collision-prone reserved string.
by_semantics_contract is an ordered list of partition objects (null legacy first),
each retaining all six statuses and construction counts. Aggregate is diagnostic
only, explicitly identifying mixed, legacy, single-declared or empty scope.

Red result: seven new methods ran; request projection passed while five methods
raised absent-field errors and invalid-metadata subtests failed as predicted.
Then implemented metadata validation/normalization, result propagation and
summary partitions without changing comparisons, statuses or numeric contracts.
README identifies legacy ambiguity, exact exit-code versus panel certification,
and limitations versus the full sidecar proposal.

Green result: `python3 -m unittest discover -s test/fidelity -p 'test_*.py'`
ran49 checks:47 passed and the same two documented expected failures remain.
Original42 comprise40passes+2xfail, preserved; seven new methods pass.
No parser/model/corpus process ran. Coordinator must obtain independent review,
run integration gates and commit/push accepted merged result.
