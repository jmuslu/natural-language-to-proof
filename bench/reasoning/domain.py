"""Explicit benchmark domain conventions over parser-produced DRSs.

General first-order semantics retains person/thing guards. ProofWriter's published
rule format has unsorted variables; the existing Haskell comparison adapter names
antecedent variables from those guards and omits the guards themselves. The opt-in
policy below reproduces a narrower, auditable part of that convention. It
strengthens the formula and is NOT a meaning-preserving English rewrite.

Only top-level flat single-head Horn rules qualify. We omit positive unary guards
on antecedent-bound variables whose own lexical provenance consists of the known
quantifier/sortal cues someone/people or something/things. Bare lexical properties,
ground facts, consequents, negatives, nested scopes, reports and presuppositions
are untouched. Remaining bodies must be nonempty and range-restrict the head.

No label, gold formula, model answer or query is an input. Callers must restrict
this policy to an explicitly selected ProofWriter evaluation; strict is default.
"""
from copy import deepcopy


_CUES = {'person': {'someone', 'people'}, 'thing': {'something', 'things'}}


def _box(value):
    if not isinstance(value, dict):
        return None
    universe, conditions = value.get('universe'), value.get('conditions')
    if not isinstance(universe, list) or not isinstance(conditions, list):
        return None
    if not all(isinstance(v, str) for v in universe) or len(universe) != len(set(universe)):
        return None
    if not all(isinstance(c, dict) for c in conditions):
        return None
    return universe, conditions


def _literal_refs(condition, bound):
    if not isinstance(condition, dict):
        return None
    if condition.get('tag') == 'not':
        parsed = _box(condition.get('body'))
        if parsed is None or parsed[0] or len(parsed[1]) != 1:
            return None
        condition = parsed[1][0]
    if condition.get('tag') != 'pred' or not isinstance(condition.get('name'), str):
        return None
    args = condition.get('args')
    if not isinstance(args, list) or len(args) not in (1, 2):
        return None
    refs = set()
    for term in args:
        if not isinstance(term, dict):
            return None
        if set(term) == {'ref'} and isinstance(term['ref'], str) and term['ref'] in bound:
            refs.add(term['ref'])
        elif set(term) == {'const'} and isinstance(term['const'], str) and term['const']:
            pass
        else:
            return None
    return refs


def _domain_guard(condition, bound):
    if condition.get('tag') != 'pred' or condition.get('name') not in _CUES:
        return False
    args = condition.get('args')
    if not isinstance(args, list) or len(args) != 1 or not isinstance(args[0], dict):
        return False
    if set(args[0]) != {'ref'} or args[0]['ref'] not in bound:
        return False
    provenance = condition.get('prov')
    if not isinstance(provenance, dict):
        return False
    leaves = provenance.get('leaves')
    if not isinstance(leaves, list) or not leaves:
        return False
    # Whole-sentence fallback provenance containing one cue is insufficient:
    # every source leaf of this guard must itself be the local domain cue.
    cues = _CUES[condition['name']]
    return all(isinstance(leaf, dict) and isinstance(leaf.get('text'), str)
               and leaf['text'].lower() in cues for leaf in leaves)


def normalize_theory(drs, policy='strict'):
    """Return (DRS, decisions), preserving input and top-condition proof indices.

    Decisions retain each removed guard including its exact provenance. There is
    no implicit dataset detection and no recursive erasure of person/thing.
    """
    if policy not in ('strict', 'proofwriter'):
        raise ValueError('unknown domain policy')
    if policy == 'strict':
        return drs, []
    top = _box(drs)
    if top is None or top[0]:
        return drs, []
    output, decisions = drs, []
    for i, condition in enumerate(top[1]):
        if condition.get('tag') != 'imp':
            continue
        left, right = _box(condition.get('left')), _box(condition.get('right'))
        if left is None or right is None or not left[0] or right[0] or len(right[1]) != 1:
            continue
        bound = set(left[0])
        body_refs = [_literal_refs(c, bound) for c in left[1]]
        head_refs = _literal_refs(right[1][0], bound)
        if head_refs is None or any(refs is None for refs in body_refs):
            continue
        removed = [j for j, c in enumerate(left[1]) if _domain_guard(c, bound)]
        if not removed:
            continue
        retained = [c for j, c in enumerate(left[1]) if j not in removed]
        retained_refs = set().union(*(refs for j, refs in enumerate(body_refs) if j not in removed))
        if not retained or not head_refs <= retained_refs:
            continue
        if output is drs:
            output = deepcopy(drs)
        output['conditions'][i]['left']['conditions'] = deepcopy(retained)
        for j in removed:
            guard = left[1][j]
            decisions.append({
                'kind': 'domain-policy',
                'policy': 'proofwriter',
                'path': ['conditions', i, 'left', 'conditions', j],
                'choice': 'omit bound domain guard under the ProofWriter convention',
                'alternatives': ['retain the general first-order sortal restriction'],
                'why': 'ProofWriter rules use unsorted variables; this explicit adapter strengthens the rule',
                'removed': deepcopy(guard),
                'prov': deepcopy(guard['prov']),
            })
    return output, decisions
