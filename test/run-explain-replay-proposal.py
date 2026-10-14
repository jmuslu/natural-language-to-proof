#!/usr/bin/env python3
"""Expose current Explain's private replay for an independent corpus-free test.

Only the module declaration of a temporary source copy changes. Production files
and lexical/combinatory implementations are untouched. Expected red failures are
proposal evidence, not a registered release suite. No dataset or model is loaded.
"""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'tools/Explain.hs').read_text()
header = 'module Main (main) where'
if source.count(header) != 1:
    raise SystemExit('Explain module header changed: review test exposure explicitly')
with tempfile.TemporaryDirectory(prefix='explain-replay-proposal-') as path:
    work = Path(path)
    exposed = work / 'ExplainReplayUnderTest.hs'
    exposed.write_text(source.replace(header, 'module ExplainReplayUnderTest where', 1))
    exe = work / 'checks'
    subprocess.run(['ghc', '-v0', '-O0', '-isrc', '-itest', '-i'+str(work),
                    '-outputdir', str(work), '-main-is', 'ExplainReplayProposalSpec.main',
                    str(ROOT/'test/ExplainReplayProposalSpec.hs'), str(exposed),
                    '-o', str(exe)], cwd=ROOT, check=True)
    raise SystemExit(subprocess.run([str(exe)], cwd=ROOT).returncode)
