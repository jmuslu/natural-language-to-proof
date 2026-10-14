# Consolidated inventory audit

Audited accepted astra/research f8871d5 using committed compact artifacts only.
No dataset extraction, source hashing rerun, SQLite scan, corpus/model load,
parser launch or gold modification. Result: **no numerical correction needed**.
The four benchmark sections are consolidated accurately, with the qualifications
below needed to distinguish finished frequency recovery from unfinished semantics.

## Reconciliation evidence

| Acquisition | Files | Records | Presented units/sentences | Distinct surfaces | Check |
| --- | ---: | ---: | ---: | ---: | --- |
| ProverQA local dev | 3 | 1,500 | 17,345 | 17,285 | Exclusive family and role totals agree with other-counts.json |
| ProofWriter stored release | 110 | 702,271 | 13,247,543 | 172,834 | Manifest/family/role/layer/partition totals agree |
| ProntoQA extracted acquisition | 80 | 65,600 | 819,128 | 177,560 | File/family/role totals and 47 joint profiles agree |
| FOLIO committed sample | 1 | 120 | 744 | 439 | Exclusive family and role totals agree with other-counts.json |

Twenty-five independent arithmetic/schema assertions pass over
proofwriter-counts.json, prontoqa-inventory.json and other-counts.json. For
ProofWriter, all 110 paths are unique and each has a syntactically valid stored
SHA256; per-file record sums equal 702,271. Occurrence sums agree by file, family,
role, layer, variant, world and split. Family unique counts sum to 172,834 because
classification is deterministic per string; unique counts across files/worlds
are overlapping and must not be summed. Source units total 13,240,413, and the
7,130 expansion difference exactly matches the documented sentence total.

These checks validate the committed extraction manifest's internal conservation,
not fresh agreement with every current byte on disk. Existing reproduction
notes already state that hashes were retained rather than recomputed. All110
file coverage is documented for that acquisition; semantic completeness is not.
No worktree or dataset change is inferred from historical hashes alone.

CONSTRUCTIONS.md contains the ProverQA, ProntoQA and FOLIO section text exactly.
ProofWriter differs only by the correct link rewrite from
`../proofwriter-counts.json` in sections/proofwriter.md to
`proofwriter-counts.json` in the consolidated file. No table entry was lost or
silently edited during assembly. The separate ProverQA residual refinement and
ProofWriter residual follow-up are linked and their numerical reconciliations
are correct: 249+3,542=3,791 and 247+3,526=3,773; 36+48+72=156 and 6+5+1=12.

## Exact wording improvements proposed to coordinator

These are proposed edits, not changes made to the shared deliverable.

1. Opening paragraph: replace “Frequencies include nested constructions;
   exclusive outer buckets and overlapping cues have different denominators.”
   with “Counts cover exclusive outer surface buckets and overlapping lexical
   cues. A cue may occur inside a larger construction, but does not by itself
   establish nested attachment, scope or a semantic template.” This avoids
   overstating the extraction as fully recovered nested constructions. Both
   tables actually use sentence occurrence counts; their membership/overlap,
   rather than an unexplained different denominator, is the key distinction.
2. Summary before the ProverQA residual-refinement paragraph: replace “3,791
   lexical/frame occurrences remain unresolved” with “The original outer
   recognizer retains 3,791 lexical/frame occurrences; the linked refinement
   assigns 249 to narrow surface-tail families, without certifying semantics.”
   Retain the following 3,542/3,526 numbers. The old wording is defensible at the
   semantic-template level but reads like the later refinement never happened.
3. In the copied ProverQA “Explicit unmatched audit,” replace “All 3,791 therefore
   remain unresolved at the construction-template level” with “All 3,791 remain
   unresolved as semantic templates; the later residual-frame refinement below
   the summary provides a narrower surface classification for 249 occurrences.”
   Apply corresponding wording in sections/proverqa.md to prevent future merge
   drift. Do not relabel them as 249 semantically recovered cases.
4. In ProofWriter “Reproduction and integrity,” replace “The current manifest
   exactly matches all110 local JSONL paths” with “The extraction/recovery audit
   recorded an exact match to all110 local JSONL paths.” Keep the explicit
   retained-hash qualification. This distinguishes historical audit evidence
   from a perpetual current-filesystem assertion without changing its result.

No proposed change to source count, sampling scope, category claim, or fidelity
gate follows. Whitespace between counts and prose can be normalized separately.

## Completion obligations and remaining limits

The requested four-way inventory deliverable exists with all110 ProofWriter
files and occurrence frequencies, distinct counts, source hashes/manifests and
reproduction paths. It is finished at the **presented-input frequency and stated
surface-classification level**. ProntoQA's zero unmatched is expressly limited
to anchored local generated forms; the generator revision is supporting evidence,
not provenance proof for every file. The 79 archive copies are excluded rather
than double-counted, and paired theory/query record counts must not be added.

FOLIO remains a 120-item sample, with 238/137 unclassified occurrences/surfaces
and 22 selected exact exemplars. Those exemplar counts are not construction-wide
frequencies. ProverQA has no local training partition; ProofWriter's staged,
abductive, world and paraphrase repetitions are physical occurrences, not
independent language examples. These qualifications are already present.

The documents consistently identify lexical cues, recognizer precedence,
unsupported semantic distinctions and proposed rather than observed categories.
CCG categories, Montague meanings, DRS/claim barriers and first Explain divergences
belong to DESIGN and per-family proposals; a high-frequency bucket does not
prove an actual offered category or a successful interpretation. No additional
unqualified category-attestation claim was found in the consolidated inventory.

Full nested semantic recovery remains unfinished for ProverQA residual frames,
ProofWriter natural-language paraphrases and FOLIO. Independent 2–3 cases per
validated construction and exact/wrong-typed/no-parse measurements are separate
requirements. Neither 110-file accounting nor arithmetic conservation releases
the ProverQA fidelity gate. Do not add cue frequencies or pool benchmark totals
to manufacture a completion percentage.
