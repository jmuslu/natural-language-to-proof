#!/usr/bin/env python3
"""Seeded synthetic scenes with gold from template case analysis, not graph closure."""
import argparse
import json
from pathlib import Path
import random

FAMILIES = ('alternatives', 'conjunction', 'cycles', 'rules', 'reports', 'factive',
            'contradictions', 'translated')


def evidence(kind, source, holders=()):
    sources = [source]
    if kind == 'oracle':
        sources.append('oracle:' + source)
    if kind == 'reported':
        sources.extend('speaker:' + name for name in holders)
    return {'sources': sorted(set(sources)), 'classes': [kind]}


def required(*items):
    """Spell one known sufficient environment; no proof search or alternatives."""
    return {'sources': sorted({s for item in items for s in item['sources']}),
            'classes': sorted({c for item in items for c in item['classes']})}


def expected(query_envs, opposite_envs=()):
    q = sorted(query_envs, key=lambda e: (e['sources'], e['classes']))
    n = sorted(opposite_envs, key=lambda e: (e['sources'], e['classes']))
    qg = any(e['classes'] == ['oracle'] for e in q)
    ng = any(e['classes'] == ['oracle'] for e in n)
    label = 'Conflict' if q and n else 'Established' if qg else 'WeakOnly' if q else 'Unsupported'
    return dict(label=label, query_supported=bool(q), query_grounded=qg,
                opposite_supported=bool(n), opposite_grounded=ng,
                query_environments=q, opposite_environments=n)


class Scene:
    def __init__(self, entity):
        self.entity = entity
        self.nodes, self.seeds, self.edges, self.withdraw, self.text = [], [], [], [], []

    def node(self, atom, negative=False):
        i = len(self.nodes)
        self.nodes.append(dict(id=i, atom=atom, negative=negative))
        return i

    def phrase(self, node):
        n = self.nodes[node]
        return f"{self.entity} is {'not ' if n['negative'] else ''}{n['atom']}"

    def seed(self, node, kind, source, holders=()):
        self.seeds.append(dict(node=node, kind=kind, source=source, holders=list(holders)))
        content = self.phrase(node)
        if kind == 'oracle':
            self.text.append(f"Oracle {source} verifies that {content}; its record is document {source}.")
        elif kind == 'reported':
            chain = ' says that '.join(holders)
            self.text.append(f"Document {source} reports that {chain} says that {content}.")
        elif kind == 'presupposed':
            self.text.append(f"Document {source} says that Iona knows that {content}; the embedded content is a factive presupposition, not oracle verified.")
        elif kind == 'asserted':
            self.text.append(f"Document {source} asserts without verification that {content}.")
        else:
            self.text.append(f"A language-model translation in document {source} proposes that {content}; no oracle has checked it.")
        return evidence(kind, source, holders)

    def edge(self, target, antecedents, source=None, weak=False):
        needs = list(antecedents)
        premise_text = ' and '.join(self.phrase(i) for i in antecedents)
        if source:
            rule = len(self.nodes)
            self.nodes.append(dict(id=rule, rule=dict(target=target, antecedents=list(antecedents))))
            kind = 'translated' if weak else 'oracle'
            self.seeds.append(dict(node=rule, kind=kind, source=source, holders=[]))
            needs.append(rule)
            self.text.append(f"{'A model proposes' if weak else 'Oracle '+source+' verifies'} the rule in document {source}: if {premise_text}, then {self.phrase(target)}.")
            env = evidence(kind, source)
        else:
            self.text.append(f"Fixed logical rule: if {premise_text}, then {self.phrase(target)}.")
            env = None
        self.edges.append(dict(target=target, antecedents=needs))
        return env

    def revoke(self, *sources):
        self.withdraw.extend(sources)
        for source in sources:
            if source.startswith('speaker:'):
                self.text.append(f"Now discredit speaker {source[8:]}; withdraw every report requiring that speaker.")
            else:
                self.text.append(f"Now discredit document {source}; withdraw every item depending on it.")

    def fixture(self, query, opposite):
        return dict(entity=self.entity, nodes=self.nodes, seeds=self.seeds, edges=self.edges,
                    withdraw=self.withdraw, query=query, opposite=opposite)


def template(family, variant, rng):
    entity = rng.choice(['Ada', 'Mira', 'Tari', 'Niko', 'Sami', 'Lena']) + str(rng.randrange(1000))
    suffix = str(rng.randrange(100000))
    a, b, c = ['doc-' + x + '-' + suffix for x in 'ABC']
    s = Scene(entity)
    q, neg = s.node('warm', variant >= 4), s.node('warm', variant < 4)
    mode = variant % 4
    qenv, nenv = [], []
    if family == 'alternatives':
        ea = s.seed(q, 'oracle', a)
        eb = s.seed(q, 'reported' if mode == 3 else 'oracle', b, ['Bob'])
        if mode == 0: qenv = [ea, eb]
        elif mode == 1: s.revoke(a); qenv = [eb]
        elif mode == 2: s.revoke(a, b)
        else: s.revoke(a); qenv = [eb]
    elif family == 'conjunction':
        p, r = s.node('bright'), s.node('swift')
        ea = s.seed(p, 'oracle', a)
        eb = s.seed(r, 'asserted' if mode == 3 else 'oracle', b)
        s.edge(q, [p, r])
        if mode in (0, 3): qenv = [required(ea, eb)]
        elif mode == 1: s.revoke(a)
        else:
            ec = s.seed(q, 'oracle', c); s.revoke(a); qenv = [ec]
    elif family == 'cycles':
        p = s.node('bright')
        s.edge(q, [p]); s.edge(p, [q])
        if mode:
            ea = s.seed(p, 'reported' if mode == 3 else 'oracle', a, ['Bob'])
            if mode == 2: s.revoke(a)
            else: qenv = [ea]
    elif family == 'rules':
        p = s.node('bright')
        ea = s.seed(p, 'oracle', a)
        er = s.edge(q, [p], b, weak=mode == 3)
        if mode in (0, 3): qenv = [required(ea, er)]
        elif mode == 1: s.revoke(b)
        else:
            er2 = s.edge(q, [p], c); s.revoke(b); qenv = [required(ea, er2)]
    elif family == 'reports':
        ea = s.seed(q, 'reported', a, ['Anne', 'Bob'])
        if mode == 0:
            s.seed(q, 'reported', a, ['Anne', 'Bob']); qenv = [ea]
        elif mode == 1: s.revoke('speaker:Bob')
        elif mode == 2:
            eb = s.seed(q, 'reported', b, ['Cara']); s.revoke('speaker:Anne'); qenv = [eb]
        else:
            eb = s.seed(q, 'reported', b, ['Anne', 'Bob']); s.revoke(a); qenv = [eb]
    elif family == 'factive':
        ea = s.seed(q, 'presupposed', a)
        if mode == 0: qenv = [ea]
        elif mode == 1: s.revoke(a)
        elif mode == 2:
            eb = s.seed(q, 'oracle', b); qenv = [ea, eb]
        else:
            eb = s.seed(neg, 'reported', b, ['Bob']); qenv, nenv = [ea], [eb]
    elif family == 'contradictions':
        ea = s.seed(q, 'oracle', a)
        eb = s.seed(neg, 'reported' if mode == 1 else 'oracle', b, ['Bob'])
        if mode in (0, 1): qenv, nenv = [ea], [eb]
        elif mode == 2: s.revoke(b); qenv = [ea]
        else: s.revoke(a); nenv = [eb]
    elif family == 'translated':
        ea = s.seed(q, 'translated', a)
        if mode == 0:
            s.seed(q, 'translated', a); qenv = [ea]
        elif mode == 1: s.revoke(a)
        elif mode == 2:
            eb = s.seed(q, 'oracle', b); s.revoke(b); qenv = [ea]
        else:
            eb = s.seed(neg, 'translated', b); qenv, nenv = [ea], [eb]
    gold = expected(qenv, nenv)
    return dict(context='\n'.join(s.text), statement=s.phrase(q), label=gold['label'],
                stratum=family, fixture=s.fixture(q, neg), expected=gold)


def generate(seed=20261013):
    rng = random.Random(seed)
    rows = []
    for family in FAMILIES:
        for variant in range(8):
            row = template(family, variant, rng)
            row['id'] = f'retraction-{seed}-{family}-{variant:02d}'
            rows.append(row)
    rng.shuffle(rows)
    return rows


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--seed', type=int, default=20261013)
    parser.add_argument('--output', type=Path, default=Path(__file__).with_name('sample.jsonl'))
    args = parser.parse_args()
    args.output.write_text(''.join(json.dumps(x, sort_keys=True)+'\n' for x in generate(args.seed)))
