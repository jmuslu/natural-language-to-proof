"""Deterministic research backends over scoped DRS JSON, never over gold logic.

Horn is signed, function-free forward chaining; Z3 is classical first-order logic.
Proofs establish entailment from text assertions, not oracle-confirmed world truth.
Unsupported scopes become residuals. A partial theory may prove a literal, but may
not certify Unknown. This module exists to measure the two solver policies without
adding a Python dependency to the Haskell library or weakening its oracle boundary.
"""
import re
import time


class Unsupported(ValueError):
    pass


def symbol(s):
    if not isinstance(s, str) or not re.fullmatch(r"[\w][\w '-]*", s) or 'UNSUPPORTED' in s:
        raise Unsupported('unsupported or unresolved symbol')
    return s


def parts(d):
    if not isinstance(d, dict) or not isinstance(d.get('universe'), list) or not isinstance(d.get('conditions'), list):
        raise Unsupported('malformed DRS')
    us = d['universe']
    if len(us) != len(set(us)) or not all(isinstance(x, str) for x in us):
        raise Unsupported('invalid universe')
    return us, d['conditions']


def result(value=None, reason='unsupported', **kwargs):
    return {'answer': value, 'reason': reason, 'strength': 'asserted-unconfirmed', **kwargs}


def minimal(envs):
    ordered = sorted(set(envs), key=lambda x: (len(x), sorted(x)))
    out = []
    for env in ordered:
        if not any(x <= env for x in out):
            out.append(env)
    return frozenset(out)


def multiply(a, b):
    return minimal(x | y for x in a for y in b)


def labels_json(label):
    return sorted((sorted(x) for x in label), key=lambda x: (len(x), x))


def literal(c, bound):
    sign = True
    if c.get('tag') == 'not':
        us, cs = parts(c['body'])
        if us or len(cs) != 1 or cs[0].get('tag') != 'pred':
            raise Unsupported('Horn negation must be one literal')
        sign, c = False, cs[0]
    if c.get('tag') != 'pred':
        raise Unsupported('outside signed Horn fragment')
    args = []
    for t in c['args']:
        if set(t) == {'const'}:
            args.append(('const', symbol(t['const'])))
        elif set(t) == {'ref'} and t['ref'] in bound:
            args.append(('ref', t['ref']))
        else:
            raise Unsupported('free or malformed term')
    return sign, symbol(c['name']), tuple(args)


def ground(lit, env):
    s, p, args = lit
    return s, p, tuple(env[v] if k == 'ref' else v for k, v in args)


def parse_horn(drs):
    us, cs = parts(drs)
    if us:
        return {}, [], ['existential theory outside Horn fragment']
    facts, rules, residual = {}, [], []
    for i, c in enumerate(cs):
        token = f'p{i}'
        label = frozenset([frozenset([token])])
        try:
            if c.get('tag') == 'imp':
                vars_, left = parts(c['left'])
                right_vars, right = parts(c['right'])
                if right_vars or not left or not right:
                    raise Unsupported('existential or empty Horn rule')
                body = [literal(x, set(vars_)) for x in left]
                heads = [literal(x, set(vars_)) for x in right]
                used = {v for _, _, args in body for k, v in args if k == 'ref'}
                if any(v not in used for _, _, args in heads for k, v in args if k == 'ref'):
                    raise Unsupported('unsafe Horn rule')
                rules.extend((body, head, label) for head in heads)
            else:
                fact = ground(literal(c, set()), {})
                facts[fact] = minimal(facts.get(fact, frozenset()) | label)
        except (Unsupported, KeyError, TypeError) as e:
            residual.append({'condition': token, 'reason': str(e)})
    return facts, rules, residual


def horn(drs, query, complete, timeout_ms):
    deadline = time.monotonic() + timeout_ms / 1000
    qu, qc = parts(query)
    if qu or len(qc) != 1:
        raise Unsupported('Horn query must be one ground literal')
    q = ground(literal(qc[0], set()), {})
    facts, rules, residual = parse_horn(drs)
    changed = True
    while changed:
        changed = False
        for body, head, rule_label in rules:
            if time.monotonic() > deadline:
                return result(reason='resource-limit', residuals=residual)
            matches = [({}, rule_label)]
            for sign, pred, args in body:
                nxt = []
                for env, label in matches:
                    for (fs, fp, fa), support in list(facts.items()):
                        if (fs, fp, len(fa)) != (sign, pred, len(args)):
                            continue
                        binding = dict(env)
                        for (kind, value), actual in zip(args, fa):
                            if kind == 'const' and value != actual:
                                break
                            if kind == 'ref':
                                if value in binding and binding[value] != actual:
                                    break
                                binding[value] = actual
                        else:
                            nxt.append((binding, multiply(label, support)))
                matches = nxt
            for env, support in matches:
                fact = ground(head, env)
                old = facts.get(fact, frozenset())
                new = minimal(old | support)
                if new != old:
                    facts[fact] = new
                    changed = True
            if len(facts) > 100000 or sum(len(v) for v in facts.values()) > 100000:
                return result(reason='resource-limit', residuals=residual)
    clashes = [f for f in facts if f[0] and (False, f[1], f[2]) in facts]
    if clashes:
        return result(reason='contradiction', contradictions=[{'predicate': f[1], 'args': f[2],
                      'positive': labels_json(facts[f]), 'negative': labels_json(facts[(False, f[1], f[2])])} for f in clashes])
    opposite = (not q[0], q[1], q[2])
    value = 'True' if q in facts else 'False' if opposite in facts else 'Unknown'
    if value == 'Unknown' and (not complete or residual):
        value = None
    return result(value, 'partial-theory' if value is None else 'forward-closure', residuals=residual,
                  support=labels_json(facts.get(q if value == 'True' else opposite, frozenset())),
                  support_kind='all-minimal-environments',
                  facts=[{'negative': not s, 'name': p, 'args': list(a), 'support': labels_json(l)}
                         for (s, p, a), l in sorted(facts.items())])


class FOL:
    def __init__(self, or_semantics):
        import z3
        self.z = z3
        self.entity = z3.DeclareSort('Entity')
        self.consts, self.preds = {}, {}
        self.counter = 0
        self.or_semantics = or_semantics

    def variable(self, name):
        self.counter += 1
        return self.z.Const(f'v!{self.counter}!{name}', self.entity)

    def term(self, t, env):
        if set(t) == {'const'}:
            name = symbol(t['const'])
            if name not in self.consts:
                self.consts[name] = self.z.Const('c!' + name, self.entity)
            return self.consts[name]
        if set(t) == {'ref'} and t['ref'] in env:
            return env[t['ref']]
        raise Unsupported('free or malformed term')

    def bind(self, names, env):
        extended = dict(env)
        vs = [self.variable(x) for x in names]
        extended.update(zip(names, vs))
        return vs, extended

    def box(self, d, env):
        us, cs = parts(d)
        vs, env = self.bind(us, env)
        content = self.z.And([self.condition(c, env) for c in cs])
        return self.z.Exists(vs, content) if vs else content

    def condition(self, c, env):
        z = self.z
        tag = c.get('tag')
        if tag == 'pred':
            name = symbol(c['name'])
            args = [self.term(t, env) for t in c['args']]
            key = (name, len(args))
            if key not in self.preds:
                self.preds[key] = z.Function(f'p!{len(args)}!{name}', *([self.entity] * len(args)), z.BoolSort())
            return self.preds[key](*args)
        if tag == 'eq':
            return self.term(c['left'], env) == self.term(c['right'], env)
        if tag == 'not':
            return z.Not(self.box(c['body'], env))
        if tag == 'or':
            if self.or_semantics == 'proverqa' and c.get('either_scope_ambiguous', False):
                raise Unsupported('ambiguous either/or scope')
            a, b = self.box(c['left'], env), self.box(c['right'], env)
            return z.Xor(a, b) if self.or_semantics == 'proverqa' and c.get('either', False) else z.Or(a, b)
        if tag == 'imp':
            us, left = parts(c['left'])
            vs, inner = self.bind(us, env)
            formula = z.Implies(z.And([self.condition(x, inner) for x in left]), self.box(c['right'], inner))
            return z.ForAll(vs, formula) if vs else formula
        raise Unsupported('attitude, presupposition or unknown condition: ' + str(tag))


def fol(drs, query, complete, timeout_ms, or_semantics):
    f = FOL(or_semantics)
    z = f.z
    s = z.Solver()
    s.set(timeout=timeout_ms, random_seed=0)
    us, cs = parts(drs)
    # Existential top-level witnesses are shared fresh constants across assertions.
    # This is equisatisfiable Skolemization; a query never gains access to them.
    _, env = f.bind(us, {})
    residual = []
    for i, c in enumerate(cs):
        try:
            formula = f.condition(c, env)
            s.assert_and_track(formula, z.Bool(f'p{i}'))
        except (Unsupported, KeyError, TypeError) as e:
            residual.append({'condition': f'p{i}', 'reason': str(e)})
    q = f.box(query, {})
    consistent = s.check()
    if consistent == z.unsat:
        return result(reason='contradiction', support=[sorted(str(x) for x in s.unsat_core())])
    if consistent != z.sat:
        return result(reason='solver-unknown', detail=s.reason_unknown())
    statuses, cores, reasons = [], [], []
    for proposition in (z.Not(q), q):
        s.push()
        s.add(proposition)
        status = s.check()
        statuses.append(status)
        cores.append(sorted(str(x) for x in s.unsat_core()) if status == z.unsat else [])
        reasons.append(s.reason_unknown() if status == z.unknown else None)
        s.pop()
    if statuses[0] == z.unsat and statuses[1] == z.unsat:
        return result(reason='contradiction')
    if z.unsat in statuses:
        ix = statuses.index(z.unsat)
        return result('True' if ix == 0 else 'False', 'fol-entailment', support=[cores[ix]],
                      support_kind='one-unsat-core', residuals=residual)
    if z.unknown in statuses:
        return result(reason='solver-unknown', detail=reasons, residuals=residual)
    return result('Unknown' if complete and not residual else None,
                  'two-countermodels' if complete and not residual else 'partial-theory', residuals=residual)


def answer(drs, query, *, backend='horn', complete=True, timeout_ms=2000, or_semantics='inclusive'):
    if backend not in ('horn', 'z3') or or_semantics not in ('inclusive', 'proverqa'):
        raise ValueError('unknown backend or disjunction policy')
    try:
        if backend == 'horn':
            return horn(drs, query, complete, timeout_ms)
        return fol(drs, query, complete, timeout_ms, or_semantics)
    except (Unsupported, KeyError, TypeError, ValueError) as e:
        return result(reason='unsupported', detail=str(e))


def aggregate(results, strategy, *, truncated=False):
    if strategy not in ('top', 'skeptical', 'credulous'):
        raise ValueError('unknown reading policy')
    if not results:
        return result(reason='no-reading')
    if strategy == 'top':
        return dict(results[0], reading_policy='top', truncated=truncated)
    if truncated:
        return result(reason='reading-cap', reading_policy=strategy)
    values = [r['answer'] for r in results]
    if strategy == 'skeptical':
        value = values[0] if values[0] is not None and all(x == values[0] for x in values) else None
    else:
        proofs = set(values) & {'True', 'False'}
        value = next(iter(proofs)) if len(proofs) == 1 else None
        if any(r.get('reason') == 'contradiction' for r in results):
            value = None
    return result(value, 'reading-agreement' if value is not None else 'reading-disagreement',
                  reading_policy=strategy, reading_answers=values)
