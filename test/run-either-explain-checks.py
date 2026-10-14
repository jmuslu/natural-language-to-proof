#!/usr/bin/env python3
"""Check actual Explain options/configuration/rendering; no corpus/model load.

GHCI runs the real module's private option parser on an authored miniature
model. A temporary compiled CLI checks invalid combinations exit before loading.
No repository sources are rewritten and no parser logic is mirrored in Python.
"""
from pathlib import Path
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = r'''
:set prompt ""
:set prompt-cont ""
:load tools/Explain.hs
:module *Main *NL2Proof.Pipeline
:module + NL2Proof.Syntax.CCGSupertag NL2Proof.Syntax.CCGBank Data.Set
let rejected xs=case parseOpts xs of {Left _ -> True; Right _ -> False}
let policy xs=case parseOpts xs of {Right o -> oEitherPolicy o; Left _ -> Nothing}
print (policy []==Nothing,policy ["--either-policy=legacy-disabled"]==Just EitherLegacyDisabled,policy ["--either-policy=surface-inclusive-v1"]==Just EitherSurfaceInclusiveV1)
print (all rejected [["--either-policy=wrong"],["--either-policy="],["--either-policy=surface-inclusive-v1","--either-policy=surface-inclusive-v1"],["--either-policy=legacy-disabled","--either-policy=surface-inclusive-v1"],["--hand","--either-policy=legacy-disabled"],["--either-policy=surface-inclusive-v1","--hand"]])
let Right omitted=parseOpts []
let Right disabled=parseOpts ["--either-policy=legacy-disabled"]
let Right enabled=parseOpts ["--either-policy=surface-inclusive-v1"]
let cc=either error id . parseCCGCat
let entries=[("Bob","NP","NNP"),("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ"),("either","(S[adj]\\NP)/(S[adj]\\NP)","RB"),("red","S[adj]\\NP","JJ"),("big","S[adj]\\NP","JJ"),("or","conj","CC"),(".",".",".")]
let model=(defaultSemModel(buildTagModel[(w,cc c)|(w,c,_)<-entries])(buildPOSModel[(w,p)|(w,_,p)<-entries])(Rules [] [])Data.Set.empty){smAlpha=0,smSeenRules=False}
let activeModel=configureModel enabled model
print (smEitherPolicy(configureModel omitted model)==EitherLegacyDisabled,smEitherPolicy(configureModel disabled model)==EitherLegacyDisabled,smEitherPolicy activeModel==EitherSurfaceInclusiveV1)
let ordinaryText="Bob is red or big."
let legacyOutput=explain(CCGBankParser(configureModel omitted model))omitted ordinaryText
print (legacyOutput==explain(CCGBankParser(configureModel disabled model))disabled ordinaryText)
let output=explain(CCGBankParser activeModel)enabled "Bob is either red or big."
print ("either-policy: surface-inclusive-v1" `isInfixOf` output,"1. TOKENS" `isInfixOf` output,"2. DERIVATION" `isInfixOf` output,"3. LAMBDA" `isInfixOf` output,"4. DRS" `isInfixOf` output)
print (not("either-policy:" `isInfixOf` explain(CCGBankParser model)enabled ordinaryText),"either-policy:" `isInfixOf` explain(CCGBankParser activeModel)omitted "Bob is either red or big.")
let [sr]=prSentences(runPipelineWith(CCGBankParser activeModel)(SourceId "input")"Bob is either red or big.")
print (fmap canonicalAC(srForm sr)==Just(canonicalAC(TOr(App(pred1 "red")(entity "Bob"))(App(pred1 "big")(entity "Bob")))))
print (all (\st -> "either-policy:" `isInfixOf` explain(CCGBankParser activeModel)enabled{oStage=Just st}"Bob is either red or big.") [STags,SDeriv,SLambda,SDrs,SClaims])
let actualRoot=head(spRoots(semParse activeModel (SourceId "input") (srTokens sr)))
let stale=actualRoot{ssSem=TAnd(ssSem actualRoot)(App(pred1 "calm")(entity "Bob"))}
let backend=BackEnd "test-order" (const M.empty) (\_ d -> (d,mempty)) (const mempty) (const Nothing)
let sign=H.Sign S (ssSem stale)(ssProv stale)
let (chosen,form,drs,readings,tr)=backEnd backend (SourceId "input") (srSentence sr) True [ccgCandidateFor activeModel stale sign]
let failed=sr{srParses=[sign],srChosen=chosen,srForm=form,srDRS=drs,srReadings=readings,srTrace=tr}
let failureOutput=unlines(seFailures(explainSentence(CCGBankParser activeModel)enabled failed))
print (isJust form,isNothing drs,"stage: origin lowering" `isInfixOf` failureOutput,"OrSnapshotMismatch" `isInfixOf` failureOutput,not("does not have its category" `isInfixOf` failureOutput))
:quit
'''.replace(':module + NL2Proof.Syntax.CCGSupertag', ':module + Data.List Data.Maybe NL2Proof.Syntax.CCGSupertag')
EXPECTED = [
    '(True,True,True)', 'True', '(True,True,True)', 'True',
    '(True,True,True,True,True)', '(True,True)', 'True', 'True',
    '(True,True,True,True,True)',
]
INVALID = [
    ['--either-policy=bad'],
    ['--either-policy='],
    ['--either-policy=surface-inclusive-v1', '--either-policy=surface-inclusive-v1'],
    ['--either-policy=legacy-disabled', '--either-policy=surface-inclusive-v1'],
    ['--hand', '--either-policy=legacy-disabled'],
    ['--either-policy=surface-inclusive-v1', '--hand'],
]

def run(args, **kwargs):
    return subprocess.run(args, cwd=ROOT, capture_output=True, text=True,
                          timeout=180, **kwargs)

def main():
    result = run(['ghci', '-v0', '-isrc'], input=SCRIPT)
    lines = [line.strip() for line in result.stdout.splitlines() if line.strip()]
    if result.returncode or lines != EXPECTED or 'error:' in result.stderr:
        raise SystemExit(result.stdout + result.stderr + '\nExplain module checks failed')
    with tempfile.TemporaryDirectory(prefix='either-explain-checks-') as directory:
        binary = str(Path(directory) / 'explain')
        build = run(['ghc', '-O0', '-isrc', '-outputdir', directory,
                     'tools/Explain.hs', '-o', binary])
        if build.returncode:
            raise SystemExit(build.stdout + build.stderr)
        for arguments in INVALID:
            result = run([binary, *arguments],
                         env={**os.environ, "CCGBANK_DIR": str(Path(directory) / "absent")})
            if result.returncode == 0 or 'loading CCGbank' in result.stderr:
                raise SystemExit('Invalid policy reached model load: ' + repr(arguments))
    print('Explain actual parser/model/report checks passed; 6 CLI rejections before load')

if __name__ == '__main__':
    main()
