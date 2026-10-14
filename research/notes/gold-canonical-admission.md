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
