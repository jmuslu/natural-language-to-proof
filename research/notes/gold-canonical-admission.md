# Gold canonical admission audit

Isolated astra/gold-canonical-admission from accepted b2e5dc4, full-access shell
verified. Own unique proposal, independent test prototype and this note only;
fidelity.py and existing test_scope_contract_review.py remain unchanged.

Inspected actual allRefsIn/canonicalize and Python gold validation/scoring call
boundaries. Proposed first-occurrence numbering plus unique declarations in each
gold DRS, explicitly stricter than actual canonicalizer output. Corpus-free
Haskell control confirms duplicate declaration is exported unchanged modulo
renaming. Claims copies are not independently traversed; alternatives reset state.

Read-only audit:20tracked JSONLs177rows185readings and frozen190198readings all
admit without mutation. Frozen cases hash matches ee8f3aef...e564. Original two
expected failures retained. Independent controls include observations staying
wrong-but-typed rather than becoming errors. No source/fixture/semantic changes,
corpus loads or parser observations. Full test result recorded after completion.
Ignored audit bundle includes input hashes and duplicate-export witness.

Validation completed: full Python discovery111tests,107pass,2skipped and the
original2expected failures. The14new prototype controls pass. Haskell synthetic
canonicalizer witness confirms nested repeated r0 declaration survives. All
fixture hashes rechecked unchanged after tests; frozen190 hash explicitly checked
against freeze.json. No gold production policy is claimed implemented.

## Authorized production candidate

Review approved d1ef6a9; root explicitly authorized gold-only helper wiring.
Added validate_gold_references after existing validate_meaning in validate_case.
No observation/scoring/exporter changes. Called both original xfail test methods
directly; unchanged assertions pass. Removed exactly their2decorators. Unique
14controls now call production validator, no recursive prototype; noncanonical
and duplicate observed structures remain wrong-but-typed.

Full111/111tests pass with accepted NOMINAL_PROTOCOL_EXPORTER, zero skips/xfail.
Exporter SHA5fb8272a294621f315df69a168f2ec340930f26710648701c55b607b9bb0dba5
verified against accepted report. All audited fixture hashes unchanged; all
worktree/root20files177rows185readings plus frozen190198readings admit unchanged.
No CCG loads. Root will need its integration gates/fresh190 after source hashes
change; this local result is not authorization to reuse stale execution seals.
