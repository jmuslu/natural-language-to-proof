LABELS = ('True', 'False', 'Uncertain')
STRATA = ('3-6', '7', '8-9')
STRATUM_NAME = 'steps'
def prompt_body(x):
    return (f"Facts and rules:\n{x['context']}\n\nQuestion: Based only on the facts and rules above, is the following statement true, false, or uncertain?\n"
            f"Statement: {x['statement']}\n\n"
            "Answer with exactly one word: True, False, or Uncertain. Uncertain means it cannot be proven true or false "
            "from the given facts and rules.")
