# Handoff: curated video corpus + adversarial suite for the epistemic layer

This is a companion to `HANDOFF-goal-session.md`, not a replacement for it —
it exists because this is a genuinely separate task (data curation and
adversarial testing methodology) that happens to feed directly into that
document's Layers 6–8 (vector DB as proposer, news/knowledge ingestion,
entropy Version A vs B). Read this alongside that document, not instead of
it, and carry forward its operating conventions (status tags, commit/push
freely, verify claims against real state before logging them, don't stop
early) unless told otherwise for this specific track.

**Where agents belong in this specific task, stated up front.** Agents are
non-deterministic, so they should never be doing the actual reasoning or
consistency-verification work this project's deterministic core exists to
do — the target end-state, per the main handoff's Layer 2, is that the
linguistic engine is a complete substitute for LLM judgment, not a
permanent partner to it. But agents are genuinely well suited to work
where non-determinism doesn't compound into an error: retrieval, transcript
collection, formatting records, structuring the corpus itself. Everything
in this handoff — collecting sources, building records, running the
adversarial suite's mechanics — sits correctly on that safe side. The one
thing that must stay off it: an agent should never be the one deciding
whether a claim is factually consistent. That judgment either comes from
the owner directly (as with the four records already collected) or from an
actual external, checkable reference — never from an agent's own read of
whether something sounds right.

## What this actually is

Building a small, deliberately labeled corpus from YouTube content the
owner already has views on: some videos where the content is internally
consistent with checkable, real-world data and findings, and some where the
content reflects a common take that doesn't actually hold up against what's
checkable. The purpose isn't to build a large general ingestion pipeline
yet — it's to get a first real test case for whether the epistemic
ingestion machinery (Layers 6–8 of the main handoff) can tell these two
classes apart at all, before it's pointed at anything larger or
unsupervised.

## The labeling question, and why it needs to be more precise than "good/bad"

The instinct behind "good" and "bad" here is sound, but the label needs to
be built on a check that's external to the owner's own prior beliefs, or
the whole exercise risks measuring agreement with the owner rather than
correspondence with reality — exactly the Version A/Version B distinction
already established in the main handoff's Layer 8 (entropy reduction is
only meaningful if it's anchored to something that gets checked; coherence
with an existing belief system is not the same thing, and is the failure
mode this document is built to keep out).

**The label that should actually get recorded, per video, is not "I agree
with this" or "I don't."** It's closer to: which specific factual claims
does this video make, and for each one, what independent source (a study,
a dataset, a report, a documented event) can be checked against it, and did
it hold up. A video can then be labeled *consistent* or *inconsistent* per
claim, with the source cited — not globally liked or disliked. This is
more work per video than a thumbs up/down, but it's the difference between
building a real adversarial test set and building a mirror.

**A practical middle ground, if per-claim sourcing for every video is too
much overhead to start**: at minimum, log *why* a video was judged
consistent or inconsistent in a sentence or two referencing something
checkable, not just a label. "This claim matches [X dataset/finding]" or
"this claim is contradicted by [Y]" is enough to keep the label
falsifiable later, even if it isn't formally footnoted at ingestion time.

## A source getting many orthogonal facts right is different evidence than one fact right — track it, but never let it shortcut per-claim verification

One correct fact from a source is weak evidence of reliability — it could
be luck, or a fact that's common knowledge and easy to get right regardless
of rigor. Many correct facts across genuinely **orthogonal** domains —
facts that don't share a common cause, that could each independently be
wrong for unrelated reasons — is structurally different: the odds of that
happening by chance drop multiplicatively with each additional independent
fact. This is the same mathematical shape as `rwCorroborated` in the main
handoff's Layer 4 — independent convergence being the one hard-to-fake
signal — just one level up: independent *correctness across domains* for a
source, rather than independent *derivation paths* for a single claim.

**"Orthogonal" has to be earned, not assumed, or the signal is fake.**
Many correct facts from one source are only strong evidence if they're
actually independent of each other — not many restatements of one
underlying claim, and not many facts that all happen to share a single
common cause (a source that's genuinely rigorous about one narrow subject
will look impressively "always right" purely within that subject, which
says nothing about its reliability elsewhere). Before treating a source's
track record as meaningful, check that the facts being aggregated don't
secretly correlate with each other.

**Track this, but only as a descriptive/diagnostic signal — never as
something that reduces scrutiny on a source's next claim.** The failure
mode to guard against explicitly: once a source has a good track record,
there's pressure to verify its next claim less carefully just because of
who said it, not because that specific claim checks out. That's a halo
effect, and it's structurally identical to the trap this whole project
exists to prevent — letting reputation substitute for verification is the
same move as letting internal consistency substitute for an oracle, just
relocated to the source layer. So: every claim, from every source,
regardless of that source's history, goes through the same per-claim
checkable-reference process from the section above. A source's past
correctness can inform *understanding* the corpus after the fact — why a
source is reliable, how broad or narrow its correctness is — but it should
never feed forward into lighter-touch treatment of anything that source
says next.

**Score it domain-scoped, not as one global reputation number.** A
source's track record in one area shouldn't quietly confer trust in an
unrelated area — that's the same halo effect in a different guise. If
source-level correctness is tracked at all, it should be broken out by
the domains it's actually been checked in, not collapsed into a single
score that could get treated as a blanket credibility rating.

## Two confounds to track as the corpus grows, not verdicts on any specific record

**Format mix is now confirmed intentional** — the corpus includes both
YouTube video transcripts and written articles, not video alone. That's a
legitimate scope decision, and it comes with a compatibility factor worth
having on record: articles and video transcripts differ structurally (no
spoken filler or back-references in an article, generally denser prose per
word, no channel/subscriber/upload-date metadata equivalent, typically one
continuous argument rather than a compilation of prior segments). A shared
schema needs to accommodate both shapes rather than stretching one to fit
the other, and format itself should be tracked as a field — not because
either format is better or worse, but so that if a future discrimination
signal ever correlates with format, that's visible and checkable rather
than silently baked into "which source got labeled which way."

**Length is a parallel factor, by the identical logic.** A longer source
mechanically produces more segments, more individual claims, and more
surface area — which means more chances to be right, more chances to be
wrong, and more raw material for a future discrimination signal to
correlate with sheer length rather than with whatever length happens to
correlate with in a small sample. This isn't a comment on any specific
record's length — it's the same category of confound as format, and it
should get the same treatment: track it as a field, watch whether it
predicts the label on its own once there's enough corpus to check, and
don't let it go unmeasured just because it's harder to see than a topic or
a channel name.

## What the corpus is actually for: an adversarial suite for the ingestion layer

This should be built and used the same way the Layer 3 statistical suite
was validated before being trusted on real data — synthetic ground truth
first, real data second. The Layer 3 suite proved itself by checking that
a planted signal survives against noise decoys and that pure noise gets
correctly rejected at a bounded false-discovery rate; this corpus is the
equivalent ground truth for the ingestion/epistemic layer. Concretely:

- Feed both classes (checkable-and-consistent, common-but-inconsistent)
  through whatever ingestion/retrieval/corroboration machinery exists at
  the time.
- The real test isn't "does the system produce plausible-sounding output
  for good videos" — it's **does the system's own confidence/corroboration/
  entropy-contribution metric actually discriminate between the two
  classes**, and does it discriminate for the right reason (because the
  claims check out or don't) rather than a spurious one (writing style,
  presenter confidence, video length, production quality — any surface
  feature correlated with the label by coincidence in a small hand-picked
  corpus).
- That last point is a real risk worth taking seriously precisely because
  this corpus is small and hand-picked by one person: a small labeled set
  is exactly the setting where a system can learn to key off an incidental
  correlate of the label rather than the actual epistemic property the
  label was meant to represent. Whatever discriminates the two classes
  should be checked against *why* it discriminates, not just *that* it
  does — the same "ablation before you trust a result" discipline from
  Layer 3.5 of the main handoff, applied here to features/embeddings
  instead of trading signals.
- Expect to need more than a handful of videos per class before any
  discrimination result is trustworthy rather than anecdotal — this is a
  place where the corpus is likely to need to grow before conclusions
  should be drawn from it, and that growth should stay balanced between
  classes rather than accumulating one faster than the other.

## Reverse-propagation: this splits into two separable jobs, and only one is this handoff's job

The instinct to keep these separate is correct and worth stating plainly:
**reverse propagation from labeled data doesn't have to fuse into the
epistemic graph right away.** It can exist as an independent artifact —
something produced now, on its own, that the graph-side mechanism consumes
later, whenever Layer 5's mechanism question actually gets resolved. Split
that way, this handoff only owns the first half:

**This handoff's job: produce a clean, standalone verdict output — not
wire anything into a graph.** For each claim extracted from a labeled
video, the output should be a self-contained record: the claim itself,
which video/source it came from, what independent reference it was checked
against, the consistency verdict, and (once the adversarial suite exists)
whatever discrimination confidence the system assigned it. This is data,
full stop — it doesn't need an opinion about edge weights, node existence,
or fixed-point propagation to be useful. It should be possible to produce
and validate this entire artifact with zero lines of graph-integration
code.

**A separate, later job, explicitly not this handoff's scope: the system
figuring out mechanically how to consume that artifact.** That's Layer 5
of the main handoff — whether trust updates are edge weights, edge
existence, or node-level propagation through something like `grounded`'s
fixed point — and it stays exactly as unresolved and exactly as
not-to-be-brute-forced as it already was. The point of keeping these
decoupled: this session's data/labeling/adversarial-suite work can proceed
and produce something genuinely useful *regardless of* whether Layer 5 ever
gets resolved, and Layer 5's eventual mechanism (whatever it turns out to
be) gets a real, already-validated dataset to consume and test against the
moment it exists, instead of the two having to be designed together and
each waiting on the other.

**What still carries over from the earlier framing, because it doesn't
depend on which side of the split it's on**: attribution still has to be
real, not assumed — the verdict record has to name the specific claim and
specific source it's about, or there's nothing for a future consumer
(whatever mechanism it uses) to attach a trust update to. That requirement
belongs to the data-side artifact, produced now, not deferred to the
graph-side mechanism later.

## What "testing and seeing if it works well" should mean in practice

Given the corpus is small and labeled, the honest first milestone is
narrow: does the system's discrimination signal on this corpus correlate
with the labels, and does it survive an ablation check on *why*. That's
the actual deliverable of this handoff — the standalone verdict artifact
plus evidence it discriminates for the right reason. It does not need to
include a working graph-propagation mechanism to be a real result; per the
split above, testing whether a mechanism moves trust correctly on this
dataset is a separate later milestone, owned by whoever eventually resolves
Layer 5, not a bar this session needs to clear. It is also not yet evidence
that the discrimination signal will generalize to an open, unlabeled
news/YouTube stream at scale — that's a further, later claim, and this
handoff shouldn't be read as authorizing that jump once the small corpus
looks good. Treat a good result here as "a validated dataset worth handing
to Layer 5 whenever that's ready, and worth growing further," not as "the
epistemic layer works now."

## Open questions worth resolving early, not mid-build

- Where does this corpus actually live — a new directory in `nl2proof`, in
  `agentic-qr` alongside the validation suite, or somewhere new? Given the
  main handoff's `~/ccgbank`-outside-the-repo pattern for licensed corpus
  data, consider whether video transcripts (which may carry their own
  copyright/ToS considerations depending on source) belong inside a repo
  at all, or alongside it the same way CCGbank does.
- Transcripts only, or also other extractable features (audio prosody,
  view counts, comments)? Starting with transcript text only keeps this
  aligned with the rest of `nl2proof`'s text-first pipeline and avoids
  adding surface-feature confounds (see the ablation point above) before
  the text-only signal is even established.
- Who else, if anyone, should review the per-claim consistency judgments
  before they're treated as labels an adversarial suite is built against?
  A single curator's checkable-claim judgments are a real external check
  relative to the system being built, but they're not infallible, and
  logging the specific source checked against (per the labeling section
  above) is what makes a later second look possible at all.
