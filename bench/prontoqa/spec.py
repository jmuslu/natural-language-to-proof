LABELS = ('True', 'False')
STRATA = ('5',)
STRATUM_NAME = 'hops'
def prompt_body(x):
    return (f"Facts and rules:\n{x['context']}\n\nQuestion: Based only on the facts and rules above, is the following statement true or false?\n"
            f"Statement: {x['statement']}\n\n"
            "Answer with exactly one word: True or False.")
