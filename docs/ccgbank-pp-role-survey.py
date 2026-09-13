#!/usr/bin/env python3
r"""Layer 1 survey (read-only): what role does the PP atom actually play in
CCGbank, weighted by corpus frequency? This informs whether `catTy PP = tyGQ`
(argument/case-marking reading) or `PP = e->t` (predicative/modifier reading) is
the better default for the core parser.

Reads the extracted lexicon LEX/CCGbank.00-24.lexicon (word, category, count).
For every category mentioning PP, parses it and classifies each PP-atom
occurrence by its structural role, weighting by the entry's corpus count:

  * ARGUMENT  — PP is the argument (right operand) of a slash, i.e. some head
                selects it: `(S\\NP)/PP`, `N/PP`, `(S[adj]\\NP)/PP`. This is the
                complement / case-marking use; PP delivers an argument.
  * RESULT    — PP is the result (left operand / output) of a functor:
                `PP/NP` (a preposition building a PP), `PP` bare. The PP so built
                is then consumed by an ARGUMENT slot elsewhere.
  * MODIFIER  — PP inside a same-category modifier shape `PP/PP` or `PP\PP`.

The semantic question: is PP ever used as a *predicate* (which would want e->t),
or is it uniformly an argument-like constituent (which tyGQ captures)? In
CCGbank, adjunct PPs are typed via prepositions whose *result* is a modifier
category like `(S\\NP)\\(S\\NP)` -- NOT via the PP atom -- so the PP atom should
come out overwhelmingly argument/result, not predicate. This measures whether
that is actually so.
"""
import os, re, collections

LEX = os.path.expanduser("~/ccgbank/ccgbank_1_1/data/LEX/CCGbank.00-24.lexicon")

# --- a small recursive-descent parser for CCGbank category strings ---
ATOM = re.compile(r"[A-Za-z]+|[.,:;]")

class P:
    def __init__(s, t): s.t = t; s.i = 0
    def peek(s): return s.t[s.i] if s.i < len(s.t) else ""
    def cat(s):
        left = s.primary()
        while s.peek() in ("/", "\\"):
            d = s.t[s.i]; s.i += 1
            right = s.primary()
            left = (d, left, right)   # (dir, result, arg)
        return left
    def primary(s):
        if s.peek() == "(":
            s.i += 1
            inner = s.cat()
            if s.peek() == ")": s.i += 1
            s.feats()
            return inner
        m = ATOM.match(s.t, s.i)
        if not m: raise ValueError("parse")
        s.i = m.end(); name = m.group(0)
        s.feats()
        return name  # atom -> just its base name (features dropped)
    def feats(s):
        while s.peek() == "[":
            j = s.t.find("]", s.i)
            if j < 0: break
            s.i = j + 1

def parse(catstr):
    p = P(catstr)
    node = p.cat()
    return node

def classify_pp(node, counter, cnt):
    """Walk the tree; for each PP atom, tally its role by parent context."""
    def walk(n, role):
        if isinstance(n, str):
            if n == "PP":
                counter[role] += cnt
            return
        d, res, arg = n
        # a same-category modifier X|X where X mentions PP at top: mark MODIFIER
        # for the PP atoms inside a PP/PP or PP\PP specifically
        if res == "PP" and arg == "PP":
            counter["MODIFIER"] += cnt        # the whole PP|PP; count once here
            return
        walk(res, "RESULT")   # left operand is the functor's result side
        walk(arg, "ARGUMENT") # right operand is the argument
    # top-level node: if it's a bare atom PP -> BARE(=RESULT-like)
    if isinstance(node, str):
        if node == "PP": counter["BARE"] += cnt
    else:
        walk(node, "RESULT")

roles = collections.Counter()
pp_entries = 0
pp_tokens = 0
total_tokens = 0
parse_fail = 0
top_arg = collections.Counter()
top_res = collections.Counter()

with open(LEX, encoding="latin-1") as f:
    for line in f:
        parts = line.split()
        if len(parts) < 3: continue
        catstr, cnt = parts[1], int(parts[2])
        total_tokens += cnt
        if "PP" not in catstr: continue
        pp_entries += 1
        pp_tokens += cnt
        try:
            node = parse(catstr)
        except Exception:
            parse_fail += 1
            continue
        before = sum(roles.values())
        classify_pp(node, roles, cnt)
        # record top categories by role for inspection
        # (attribute the whole category's count to the dominant role seen)

print(f"total corpus tokens            : {total_tokens}")
print(f"distinct PP-bearing categories : {pp_entries}")
print(f"PP-bearing corpus tokens       : {pp_tokens}  ({100*pp_tokens/total_tokens:.1f}% of all)")
print(f"category parse failures        : {parse_fail}")
print()
print("PP-atom occurrences by structural role (weighted by corpus count):")
tot = sum(roles.values())
for role, n in roles.most_common():
    print(f"  {role:10s} {n:>9}  ({100*n/tot:.1f}%)")
print()
arg = roles.get("ARGUMENT", 0)
nonpred = arg + roles.get("RESULT", 0) + roles.get("BARE", 0)
print(f"argument-like (ARGUMENT+RESULT+BARE) : {nonpred}  ({100*nonpred/tot:.1f}%)")
print(f"modifier                              : {roles.get('MODIFIER',0)}  ({100*roles.get('MODIFIER',0)/tot:.1f}%)")
