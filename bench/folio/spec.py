LABELS = ('True', 'False', 'Uncertain')
STRATA = ('2-4', '5', '6-9')
STRATUM_NAME = 'premises'
def prompt_body(x):
    return (f"Premises:\n{x['context']}\n\nQuestion: Based only on the premises above, is the following statement true, false, or uncertain?\n"
            f"Statement: {x['statement']}\n\n"
            "Answer with exactly one word: True, False, or Uncertain. Uncertain means it cannot be proven true or false "
            "from the given premises.")
