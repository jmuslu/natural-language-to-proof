#!/usr/bin/env python3
"""Exercise actual private Pipeline candidate failures without exporting test APIs.

Uses chart-minted miniature roots from EitherCarrierSpec, changes their snapshot
or type, then calls the real carrier/backend. No source rewrites or corpus load.
"""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = r""":set prompt ""
:set prompt-cont ""
:load src/NL2Proof/Pipeline.hs test/EitherCarrierSpec.hs
:module *NL2Proof.Pipeline *Main
let root=head fixtureRoots
let sentence=Sentence (Span 0 (length fixtureText)) fixtureText
let backend=BackEnd "test-order" (const M.empty) (\_ d -> (d,mempty)) (const mempty) (const(Just (-999)))
let mk r=ccgCandidateFor fixtureModel r (Sign S (ssSem r) (ssProv r))
let stale=root{ssSem=TAnd(ssSem root)(App(pred1 "calm")(entity "Bob")),ssScore=7}
let (selected,form,drs,readings,tr)=backEnd backend fixtureSource sentence True [mk stale,mk root]
print (fmap sSem selected==Just(ssSem stale),isJust form,isNothing drs,length readings==2)
print (map rrScore readings==[Just 7,Just(ssScore root)],rrOriginFailure(head readings)==Just(ChartOriginFailure OrSnapshotMismatch),isJust(rrDRS(readings!!1)))
print (map diagKind(traceDiagnostics(rrTrace(head readings)))==[OriginLoweringFailure])
let badType=root{ssSem=entity "Bob",ssScore=8}
let (_,typedForm,typedDRS,typedReadings,_)=backEnd backend fixtureSource sentence True [mk badType,mk root]
print (isNothing typedForm,isNothing typedDRS,length typedReadings==2,isNothing(rrOriginFailure(head typedReadings)),isJust(rrDRS(typedReadings!!1)))
let disabled=fixtureModel{smEitherPolicy=EitherLegacyDisabled}
let (_,_,_,legacyReadings,_)=backEnd backend fixtureSource sentence True [ccgCandidateFor disabled root(Sign S(ssSem root)(ssProv root))]
print (rrScore(head legacyReadings)==Just(-999),isNothing(rrOriginFailure(head legacyReadings)))
let plainText="Bob is red or big."
let plainRoot=head(spRoots(semParse fixtureModel fixtureSource(casedTokens 0 plainText)))
let plainSentence=Sentence(Span 0(length plainText))plainText
let (_,_,_,ordinaryReadings,_)=backEnd backend fixtureSource plainSentence True [mk(plainRoot{ssScore=42})]
print (rrScore(head ordinaryReadings)==Just(-999),isNothing(rrOriginFailure(head ordinaryReadings)))
:quit
"""
EXPECTED = [
    "(True,True,True,True)",
    "(True,True,True)",
    "True",
    "(True,True,True,True,True)",
    "(True,True)",
    "(True,True)",
]

def main():
    result = subprocess.run(
        ["ghci", "-v0", "-isrc", "-itest"], input=SCRIPT, text=True,
        cwd=ROOT, capture_output=True, timeout=180)
    lines = [line.strip() for line in result.stdout.splitlines() if line.strip()]
    if result.returncode or lines != EXPECTED or "error:" in result.stderr:
        sys.stderr.write(result.stdout + result.stderr)
        raise SystemExit("private Pipeline carrier invariant checks failed")
    print("either-carrier private production checks: 17/17 passed")

if __name__ == "__main__":
    main()
