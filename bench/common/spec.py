"""Per-benchmark prompt + label set. Sample rows share one schema:
id, context, statement, label, stratum (hop count or difficulty bucket, as a string), plus source fields."""
import importlib.util, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

TOOLS_PREAMBLE = ("Do NOT use any tools, do NOT run commands, and do NOT read any files. "
                  "This is a pure reading-comprehension logic question; answer from the text below only.\n\n")

def load(bench):
    """Import bench/<bench>/spec.py (defines LABELS, STRATA, prompt_body(x))."""
    p = os.path.join(ROOT, bench, 'spec.py')
    sp = importlib.util.spec_from_file_location(f'spec_{bench}', p)
    m = importlib.util.module_from_spec(sp); sp.loader.exec_module(m)
    m.DIR = os.path.join(ROOT, bench)
    return m

def prompt(S, x, tools_preamble):
    return (TOOLS_PREAMBLE if tools_preamble else '') + S.prompt_body(x)
