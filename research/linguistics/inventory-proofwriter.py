#!/usr/bin/env python3
"""Text-only inventory of local ProofWriter inputs; raw text stays in --work.

This is a surface inventory, not a parser or a semantics/accuracy evaluation.
Gold answers, logical representations, proof fields and inference targets are
never used. Each stored input unit is counted once per physical record; dataset
variants deliberately remain separate, while global unique strings are deduped.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import sqlite3


# These are surface grammar patterns; a match does not certify the intended
# implication, factual force, or coreference. In particular NatLang quantifiers,
# modals, idioms and reporting must not silently inherit the synthetic gold.
ADJ = r"(?:big|blue|cold|furry|green|kind|nice|quiet|red|rough|round|smart|white|young|black|abnormal|wounded|flying)"
ADJS = rf"{ADJ}(?:(?:, | and ){ADJ})*"
NP = r"(?:the [a-z]+(?: [a-z]+)?|someone|something|they|it|[a-z]+)"
COP = re.compile(rf"^({NP}) (is|are) (not )?(?:(a|an) )?([a-z]+)$")
REL = re.compile(rf"^({NP}) ((?:does|do) not )?(chases?|eats?|likes?|needs?|sees?|visits?|has|have|includes?|runs? through) ({NP})$")
INTR = re.compile(rf"^({NP}) ((?:does|do) not )?(flies|fly)$")
MODAL = re.compile(rf"^({NP}) (can|cannot|can not) fly$")
GENERIC = re.compile(rf"^(all )?({ADJS}) (people|things) are (not )?({ADJ})$")


def term_shape(term):
    if term in {"someone", "something", "they", "it"}:
        return term
    return "the <ENTITY>" if term.startswith("the ") else "<NAME>"


def atom(text):
    if m := COP.fullmatch(text):
        subject, copula, neg, article, _ = m.groups()
        return ("nominal" if article else "copular", f"{term_shape(subject)} {copula} {neg or ''}{article + ' <NOUN>' if article else '<ADJ>'}", bool(neg))
    if m := REL.fullmatch(text):
        subject, neg, verb, obj = m.groups()
        prep = " through" if verb.endswith(" through") else ""
        return "transitive", f"{term_shape(subject)} {neg or ''}<VERB>{prep} {term_shape(obj)}", bool(neg)
    if m := INTR.fullmatch(text):
        subject, neg, _ = m.groups()
        return "intransitive", f"{term_shape(subject)} {neg or ''}<VERB>", bool(neg)
    if m := MODAL.fullmatch(text):
        subject, modal = m.groups()
        return "modal", f"{term_shape(subject)} {modal} <VERB>", modal != "can"
    return None


TEMPLATES = {
    "PW.ATOM.COPULAR": "Ground/name subject + copula + adjective (positive)",
    "PW.ATOM.COPULAR.NEG": "Ground/name subject + copula + not + adjective",
    "PW.ATOM.NOMINAL": "Ground subject + copula + indefinite nominal predicate",
    "PW.ATOM.NOMINAL.NEG": "Ground subject + copula + not + indefinite nominal predicate",
    "PW.ATOM.TRANSITIVE": "Ground subject + transitive verb + ground object",
    "PW.ATOM.TRANSITIVE.NEG": "Ground subject + do-support negation + transitive predicate",
    "PW.ATOM.INTRANSITIVE": "Ground subject + intransitive verb",
    "PW.ATOM.INTRANSITIVE.NEG": "Ground subject + do-support negation + intransitive predicate",
    "PW.ATOM.MODAL": "Ground subject + can + intransitive predicate (birds variant)",
    "PW.ATOM.MODAL.NEG": "Ground subject + cannot + intransitive predicate (birds variant)",
    "PW.COND.GENERIC": "If generic someone/something antecedent, then consequent",
    "PW.COND.GENERIC.COORD": "If generic antecedent conjunction, then consequent",
    "PW.COND.GROUND": "If ground antecedent, then ground consequent",
    "PW.COND.GROUND.COORD": "If ground antecedent conjunction, then consequent",
    "PW.UNIVERSAL.EXPLICIT": "All adjective(s) people/things are adjective",
    "PW.UNIVERSAL.BARE": "Bare adjective(s) people/things are adjective",
    "PW.NL.CONDITIONAL.FRONT": "Paraphrase with fronted if/when/whenever/once condition",
    "PW.NL.CONDITIONAL.POST": "Paraphrase with noninitial if/when/whenever/unless condition",
    "PW.NL.ATTRIBUTION": "Paraphrase with explicit speech/belief/knowledge/evidential wording",
    "PW.NL.CAUSAL": "Paraphrase with because/since/causal connective",
    "PW.NL.RELATIVE": "Paraphrase containing who/that/which relative-like dependency",
    "PW.NL.QUANTIFIED": "Paraphrase beginning an explicit universal/negative quantifier",
    "PW.NL.GENERIC.PLURAL": "Paraphrase with a bare plural person/thing/individual subject",
    "PW.NL.GENERIC.INDEFINITE": "Paraphrase with an indefinite person/thing/individual subject",
    "PW.NL.COORDINATION": "Other paraphrase with and/but/yet/or or comma coordination cue",
    "PW.NL.MODAL.HABITUAL": "Other paraphrase with modal/frequency/tendency wording",
    "PW.NL.COPULAR": "Other paraphrase containing finite copular predication",
    "PW.NL.NONCOPULAR": "Other paraphrase with an identifiable finite lexical-verb frame",
    "UNCLASSIFIED": "Input outside the explicit surface patterns; manual review required",
}


def features(text):
    s = text.lower()
    patterns = {
        "negation": r"\b(?:not|cannot|no|never|neither|nor|nobody|nothing)\b|n['’]t\b",
        "explicit_quantifier": r"\b(?:all|every|each|anyone|everyone|anything|everything|nobody|nothing|none)\b",
        "existential_wording": r"\b(?:some|someone|something|somebody|there is|there are)\b",
        "coordination_and": r"\band\b",
        "coordination_other": r"\b(?:but|yet|or|nor)\b",
        "comma": r",",
        "relative_cue": r"\b(?:who|whom|whose|which)\b|\bthat (?:is|are|has|have|can|will|was|were|left)\b",
        "pronoun": r"\b(?:it|they|he|she|him|her|them|their|his|its|we|you)\b",
        "reflexive": r"\b(?:himself|herself|itself|themselves|yourself)\b",
        "conditional": r"\b(?:if|when|whenever|unless)\b",
        "generic_human_variable": r"\bsomeone\b",
        "generic_thing_variable": r"\bsomething\b",
        "adjective_coordination_ellipsis": rf"\b(?:is|are) (?:not )?{ADJ} and (?:not )?{ADJ}\b",
        "clause_coordination": rf"\band {NP} (?:is|are|does|do|chases?|eats?|likes?|needs?|sees?|visits?|has|have|includes?|runs?)\b",
        "sortal_people_things": r"\b(?:people|things)\b",
        "multiword_entity": r"\b(?:bald eagle|light bulb)\b",
        "relational_preposition": r"\bruns? through\b",
        "transitive_lexicon": r"\b(?:chases?|eats?|likes?|needs?|sees?|visits?|includes?|has|have)\b",
        "modal": r"\b(?:can|cannot|could|may|might|must|should|would|will|shall)\b",
        "habitual_or_hedged": r"\b(?:always|usually|often|sometimes|tends?|seems?|apparently|almost|probably)\b",
        "attribution": r"\b(?:said|says?|told|claims?|knows?|known|thinks?|thought|believes?|considered|noticed|seems?|appears?)\b",
        "comparative_or_degree": r"\b(?:more|most|less|very|too|quite|rather|extremely|really)\b",
        "causal": r"\b(?:because|since|therefore|hence|causes?|causing)\b",
        "multi_sentence_unit": r"[.!?]\s+\S",
        "parenthesis_or_quote": r"[()\"“”]",
    }
    return {key for key, pattern in patterns.items() if re.search(pattern, s)}


def lexical_skeleton(text):
    s = text.lower().strip().rstrip(".")
    s = re.sub(r"\b(?:alan|anne|bob|charlie|dave|eric|erin|fiona|fred|gary|harry)\b", "<NAME>", s)
    s = re.sub(rf"\b{ADJ}\b", "<ADJ>", s)
    s = re.sub(r"\b(?:bald eagle|light bulb|bear|cat|cow|dog|lion|mouse|rabbit|squirrel|tiger)\b", "<ENTITY>", s)
    return s


def classify(text):
    s = text.lower().strip().rstrip(".")
    if m := GENERIC.fullmatch(s):
        explicit, adjectives, sortal, neg, _ = m.groups()
        skeleton = ("all " if explicit else "") + re.sub(ADJ, "<ADJ>", adjectives) + f" {sortal} are {neg or ''}<ADJ>"
        return "PW.UNIVERSAL.EXPLICIT" if explicit else "PW.UNIVERSAL.BARE", skeleton
    if s.startswith("if ") and " then " in s:
        antecedent, consequent = s[3:].split(" then ", 1)
        pieces = antecedent.split(" and ")
        head = atom(consequent)
        shapes = []
        previous_copula = False
        for piece in pieces:
            parsed = atom(piece)
            if parsed:
                shapes.append(parsed[1])
                previous_copula = parsed[0] in {"copular", "nominal"}
            elif previous_copula and re.fullmatch(rf"(?:not )?{ADJ}", piece):
                shapes.append(("not " if piece.startswith("not ") else "") + "<ADJ>")
            else:
                break
        if head and len(shapes) == len(pieces):
            generic = bool(re.search(r"\b(?:someone|something)\b", antecedent))
            key = "PW.COND." + ("GENERIC" if generic else "GROUND") + (".COORD" if len(pieces) > 1 else "")
            return key, "if " + " and ".join(shapes) + " then " + head[1]
    if a := atom(s):
        return "PW.ATOM." + a[0].upper() + (".NEG" if a[2] else ""), a[1]
    fs = features(text)
    # Ordered diagnostic grouping only. Overlap remains in orthogonal features;
    # this is deliberately not a claim of exact syntactic or semantic recovery.
    if re.match(r"^(?:if|when|whenever|once)\b", s):
        key = "CONDITIONAL.FRONT"
    elif "conditional" in fs:
        key = "CONDITIONAL.POST"
    elif "attribution" in fs:
        key = "ATTRIBUTION"
    elif "causal" in fs:
        key = "CAUSAL"
    elif "relative_cue" in fs:
        key = "RELATIVE"
    elif re.match(r"^(?:all|every|each|anyone|everyone|anything|everything|no|nobody|nothing)\b", s):
        key = "QUANTIFIED"
    elif re.match(r"^(?:[a-z]+[ ,]+){0,8}(?:people|persons|things|individuals|folks)\b", s):
        key = "GENERIC.PLURAL"
    elif re.match(r"^(?:(?:a|an|the) (?:[a-z]+[ ,]+){0,7}(?:person|individual|man|woman|guy|one)|someone|somebody|something)\b", s):
        key = "GENERIC.INDEFINITE"
    elif fs & {"coordination_and", "coordination_other", "comma"}:
        key = "COORDINATION"
    elif fs & {"modal", "habitual_or_hedged"}:
        key = "MODAL.HABITUAL"
    elif re.search(r"\b(?:is|are|was|were|am)\b|\b(?:he|she|it|that|there|who|alan|anne|bob|charlie|dave|eric|erin|fiona|fred|gary|harry)['’]s\b", s):
        key = "COPULAR"
    elif re.search(r"\b(?:has|have|had|looks?|feels?|gets?|makes?|becomes?|wears?|wearing|acts?|acted|resembles?|remains?|keeps?|goes|comes?|calls?|called|gives?|turns?|took|found|finds?|enjoys?|loves?|hates?|lacks?|demonstrates?|displays?|possesses?|exhibits?|sports?|shows?)\b", s):
        key = "NONCOPULAR"
    else:
        return "UNCLASSIFIED", lexical_skeleton(text)
    return "PW.NL." + key, lexical_skeleton(text)


def norm(text):
    return " ".join(text.split())


def kind(path):
    return "stage" if "-stage-" in path.name else "abduct" if "-abduct-" in path.name else "standard"


def inputs(record):
    """Yield (text, role, surface layer, field locator), without gold lookups."""
    entries = {**record.get("triples", {}), **record.get("rules", {})}
    sentences = record.get("sentences")
    if sentences is not None:
        # NatLang's mapping dictionary sometimes replaces periods by semicolons.
        # Preserve authoritative presented theory punctuation, never infer it
        # from a blanket replacement (many semicolons really are semicolons).
        presented = norm(record.get("theory", ""))
        position = 0
        inverse = defaultdict(list)
        for key, sid in record.get("mappings", {}).items():
            if key in entries:
                inverse[sid].append("rule" if key.startswith("rule") else "fact")
        for sid, text in sentences.items():
            text = norm(text)
            if presented:
                pattern = re.escape(text).replace(";", "[;.]" ).replace(r"\.", "[;.]")
                match = re.match(pattern, presented[position:])
                if match is None:
                    raise ValueError(f"Cannot align presented theory text for {record.get('id')}:{sid}")
                text = match.group()
                position += len(text)
                while position < len(presented) and presented[position].isspace():
                    position += 1
            roles = set(inverse[sid])
            role = "premise_" + (next(iter(roles)) if len(roles) == 1 else "mixed" if roles else "unmapped")
            yield text, role, "paraphrase", "sentences." + sid
        if presented and position != len(presented):
            raise ValueError(f"Unconsumed theory suffix for {record.get('id')}")
        # A stage can add a synthetic fact; retain any unmapped new input.
        for key, value in entries.items():
            if key not in record.get("mappings", {}):
                yield norm(value["text"]), "premise_" + ("rule" if key.startswith("rule") else "fact"), "controlled", key + ".text"
    else:
        for key, value in entries.items():
            yield norm(value["text"]), "premise_" + ("rule" if key.startswith("rule") else "fact"), "controlled", key + ".text"
    for key, value in record.get("questions", {}).items():
        yield norm(value["question"]), "question", "controlled", "questions." + key
    for key, value in record.get("abductions", {}).items():
        yield norm(value["question"]), "abduction_question", "controlled", "abductions." + key


def extract(args):
    args.work.mkdir(parents=True, exist_ok=True)
    dbpath = args.work / "sentences.sqlite3"
    if dbpath.exists():
        raise SystemExit("Refusing to overwrite existing inventory DB; use a fresh work directory.")
    db = sqlite3.connect(dbpath)
    db.execute("CREATE TABLE occurrences (text TEXT, file TEXT, role TEXT, layer TEXT, n INTEGER, source TEXT, PRIMARY KEY(text,file,role,layer))")
    metadata = {"root": str(args.root.resolve()), "created_utc": datetime.now(timezone.utc).isoformat(), "files": [], "exceptions": Counter()}
    anomalies = (args.work / "extraction-exceptions.jsonl").open("w")
    for path in sorted(args.root.rglob("*.jsonl")):
        rel = str(path.relative_to(args.root))
        counts, first = Counter(), {}
        roles, layers = Counter(), Counter()
        records = 0
        digest = hashlib.sha256()
        with path.open("rb") as handle:
            for lineno, raw in enumerate(handle, 1):
                digest.update(raw)
                record = json.loads(raw)
                records += 1
                units = list(inputs(record))
                premises = [text for text, role, _, _ in units if role.startswith("premise_")]
                if "theory" in record and norm(record["theory"]) != norm(" ".join(premises)):
                    metadata["exceptions"]["theory_reconstruction_mismatch"] += 1
                    anomalies.write(json.dumps({"file": rel, "line": lineno, "id": record["id"], "theory": record["theory"], "extracted": premises}) + "\n")
                for text, role, layer, locator in units:
                    if not text:
                        metadata["exceptions"]["empty_input_text"] += 1
                    key = text, role, layer
                    counts[key] += 1
                    first.setdefault(key, f"{rel}:{lineno}:{record['id']}:{locator}")
                    roles[role] += 1
                    layers[layer] += 1
        db.executemany("INSERT INTO occurrences VALUES (?,?,?,?,?,?)", ((text, rel, role, layer, n, first[text, role, layer]) for (text, role, layer), n in counts.items()))
        db.commit()
        info = {"path": rel, "world": path.parts[-3], "bucket": path.parts[-2], "variant": kind(path), "split": path.stem.split("-")[-1], "bytes": path.stat().st_size, "sha256": digest.hexdigest(), "records": records, "sentence_occurrences": sum(counts.values()), "unique_sentences": len({key[0] for key in counts}), "roles": dict(roles), "surface_layers": dict(layers)}
        metadata["files"].append(info)
        print(json.dumps({"file": rel, "records": records, "occurrences": info["sentence_occurrences"], "unique": info["unique_sentences"]}), flush=True)
    anomalies.close()
    db.execute("CREATE INDEX sentences_text ON occurrences(text)")
    db.commit()
    db.close()
    (args.work / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")


def repair_surface(args):
    """Repair the initial exploratory extraction using validated text alignment.

    A fresh `extract` already uses the corrected alignment. This command exists
    to keep the initial audit and correction reproducible without hiding it.
    """
    metadata = json.loads((args.work / "metadata.json").read_text())
    affected = {json.loads(line)["file"] for line in (args.work / "extraction-exceptions.jsonl").read_text().splitlines()}
    db = sqlite3.connect(args.work / "sentences.sqlite3")
    corrected = 0
    for info in metadata["files"]:
        rel = info["path"]
        if rel not in affected:
            continue
        counts, first, roles, layers = Counter(), {}, Counter(), Counter()
        with (args.root / rel).open() as handle:
            for lineno, raw in enumerate(handle, 1):
                record = json.loads(raw)
                units = list(inputs(record))
                if "theory" in record:
                    actual = norm(" ".join(t for t, r, _, _ in units if r.startswith("premise_")))
                    if norm(record["theory"]) != actual:
                        raise ValueError(f"Unresolved theory reconstruction: {rel}:{lineno}")
                for text, role, layer, locator in units:
                    key = text, role, layer
                    counts[key] += 1
                    first.setdefault(key, f"{rel}:{lineno}:{record['id']}:{locator}")
                    roles[role] += 1
                    layers[layer] += 1
        db.execute("DELETE FROM occurrences WHERE file=?", (rel,))
        db.executemany("INSERT INTO occurrences VALUES (?,?,?,?,?,?)", ((t, rel, r, l, n, first[t, r, l]) for (t, r, l), n in counts.items()))
        db.commit()
        info["sentence_occurrences"] = sum(counts.values())
        info["unique_sentences"] = len({key[0] for key in counts})
        info["roles"], info["surface_layers"] = dict(roles), dict(layers)
        corrected += 1
        print(json.dumps({"repaired_file": rel, "records": info["records"]}), flush=True)
    metadata["exceptions"]["initial_theory_mismatches_repaired"] = metadata["exceptions"].pop("theory_reconstruction_mismatch", 0)
    metadata["exceptions"]["remaining_theory_reconstruction_mismatch"] = 0
    metadata["surface_repair_files"] = corrected
    (args.work / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    db.close()


def split_source_units(db):
    """Split the few multi-sentence paraphrase fields, retaining their raw audit.

    Count punctuation-delimited sentences, not mapping dictionary keys. Keep
    sentence fragments, since excluding them would hide a real input challenge.
    This transformation is idempotent and does not revisit labels/proof fields.
    """
    db.execute("CREATE TABLE IF NOT EXISTS expanded_units (text TEXT,file TEXT,role TEXT,layer TEXT,n INTEGER,source TEXT,parts INTEGER)")
    candidates = list(db.execute("SELECT * FROM occurrences WHERE text LIKE '%. %' OR text LIKE '%! %' OR text LIKE '%? %'"))
    for text, file, role, layer, n, source in candidates:
        parts = re.split(r"(?<=[.!?])\s+", text)
        if len(parts) < 2:
            continue
        db.execute("INSERT INTO expanded_units VALUES (?,?,?,?,?,?,?)", (text, file, role, layer, n, source, len(parts)))
        db.execute("DELETE FROM occurrences WHERE text=? AND file=? AND role=? AND layer=?", (text, file, role, layer))
        for index, part in enumerate(parts):
            db.execute("INSERT INTO occurrences VALUES (?,?,?,?,?,?) ON CONFLICT(text,file,role,layer) DO UPDATE SET n=n+excluded.n", (part, file, role, layer, n, source + f":sentence{index + 1}"))
    db.execute("CREATE INDEX IF NOT EXISTS occurrences_file ON occurrences(file,text)")
    db.commit()
    return dict(zip(["unique_source_units", "source_unit_occurrences", "additional_sentence_occurrences"], db.execute("SELECT COUNT(DISTINCT text),COALESCE(SUM(n),0),COALESCE(SUM(n*(parts-1)),0) FROM expanded_units").fetchone()))


def summarize(args):
    db = sqlite3.connect(args.work / "sentences.sqlite3")
    metadata = json.loads((args.work / "metadata.json").read_text())
    expansions = split_source_units(db)
    db.execute("DROP TABLE IF EXISTS classified")
    db.execute("CREATE TABLE classified (text TEXT PRIMARY KEY, construction TEXT, skeleton TEXT, features TEXT)")
    constructions, feature_counts, skeletons = {}, {}, {}
    examples = defaultdict(list)
    sample_counts, sample_unique, sample_records = Counter(), set(), 0
    sample = Path(__file__).resolve().parents[2] / "bench/proofwriter/sample.jsonl"
    if sample.exists():
        for line in sample.read_text().splitlines():
            item = json.loads(line)
            sample_records += 1
            for role, texts in [("premise", re.split(r"(?<=[.!?])\s+", item["theory"])), ("question", [item["question"]])]:
                for text in texts:
                    key, _ = classify(text)
                    sample_counts[key] += 1
                    sample_unique.add(text)
                    if len(examples[key]) < 3 and text not in {x["text"] for x in examples[key]}:
                        examples[key].append({"text": text, "source": "bench/proofwriter/sample.jsonl:" + str(item["id"]), "role": role})
    unresolved = (args.work / "unclassified.jsonl").open("w")
    controlled_unexpected = (args.work / "controlled-unexpected.jsonl").open("w")
    pending, multi_units = [], Counter()
    for text, n, source, role, layers in db.execute("SELECT text,SUM(n),MIN(source),MIN(role),GROUP_CONCAT(DISTINCT layer) FROM occurrences GROUP BY text"):
        key, skeleton = classify(text)
        fs = features(text)
        pending.append((text, key, skeleton, json.dumps(sorted(fs))))
        c = constructions.setdefault(key, {"id": key, "template": TEMPLATES[key], "count": 0, "unique_count": 0})
        c["count"] += n
        c["unique_count"] += 1
        sk = skeletons.setdefault((key, skeleton), [0, 0])
        sk[0] += n
        sk[1] += 1
        for feature in fs:
            fc = feature_counts.setdefault(feature, {"count": 0, "unique_count": 0})
            fc["count"] += n
            fc["unique_count"] += 1
        example = {"text": text, "source": source, "role": role}
        if len(examples[key]) < 3 and text not in {x["text"] for x in examples[key]}:
            examples[key].append(example)
        if key == "UNCLASSIFIED":
            unresolved.write(json.dumps({**example, "count": n, "layers": layers}) + "\n")
        if "controlled" in layers and (key == "UNCLASSIFIED" or key.startswith("PW.NL.")):
            controlled_unexpected.write(json.dumps({**example, "count": n, "construction": key}) + "\n")
        if "multi_sentence_unit" in fs:
            multi_units["unique_units"] += 1
            multi_units["unit_occurrences"] += n
            multi_units["extra_boundary_occurrences"] += n * len(re.findall(r"[.!?]\s+\S", text))
        if len(pending) >= 5000:
            db.executemany("INSERT INTO classified VALUES (?,?,?,?)", pending)
            pending.clear()
    db.executemany("INSERT INTO classified VALUES (?,?,?,?)", pending)
    db.commit()
    unresolved.close()
    controlled_unexpected.close()
    with (args.work / "skeletons.jsonl").open("w") as handle:
        for (key, skeleton), (count, unique) in sorted(skeletons.items(), key=lambda x: (x[0][0], -x[1][0], x[0][1])):
            handle.write(json.dumps({"construction": key, "skeleton": skeleton, "count": count, "unique_count": unique}) + "\n")
    files = metadata["files"]
    for f in files:
        f["source_unit_occurrences"] = f["sentence_occurrences"]
        f["unique_source_units"] = f["unique_sentences"]
        f["sentence_occurrences"], f["unique_sentences"] = db.execute("SELECT SUM(n),COUNT(DISTINCT text) FROM occurrences WHERE file=?", (f["path"],)).fetchone()
    class_roles = defaultdict(dict)
    class_layers = defaultdict(dict)
    for key, role, count in db.execute("SELECT construction,role,SUM(n) FROM occurrences JOIN classified USING(text) GROUP BY construction,role"):
        class_roles[key][role] = count
    for key, layer, count in db.execute("SELECT construction,layer,SUM(n) FROM occurrences JOIN classified USING(text) GROUP BY construction,layer"):
        class_layers[key][layer] = count
    for c in constructions.values():
        key = c["id"]
        c["examples"] = examples[key]
        c["roles"] = class_roles[key]
        c["surface_layers"] = class_layers[key]
        sks = [(s, n, u) for (k, s), (n, u) in skeletons.items() if k == key]
        c["skeleton_count"] = len(sks)
        # Full paraphrase skeletons may retain raw lexical text; keep those local.
        if not key.startswith("PW.NL") and key != "UNCLASSIFIED":
            c["top_skeletons"] = [{"skeleton": s, "count": n, "unique_count": u} for s, n, u in sorted(sks, key=lambda row: (-row[1], row[0]))[:12]]
    # Keep an explicit empty bucket: pattern coverage is not semantic coverage.
    constructions.setdefault("UNCLASSIFIED", {"id": "UNCLASSIFIED", "template": TEMPLATES["UNCLASSIFIED"], "count": 0, "unique_count": 0, "examples": [], "roles": {}, "surface_layers": {}, "skeleton_count": 0})
    datasets = []
    for world, bucket, variant in sorted({(f["world"], f["bucket"], f["variant"]) for f in files}):
        subset = [f for f in files if (f["world"], f["bucket"], f["variant"]) == (world, bucket, variant)]
        names = [f["path"] for f in subset]
        where = "file IN (" + ",".join("?" for _ in names) + ")"
        unique = db.execute(f"SELECT COUNT(DISTINCT text) FROM occurrences WHERE {where}", names).fetchone()[0]
        by_class = dict(db.execute(f"SELECT construction,SUM(n) FROM occurrences JOIN classified USING(text) WHERE {where} GROUP BY construction", names))
        datasets.append({"world": world, "bucket": bucket, "variant": variant, "files": len(subset), "records": sum(f["records"] for f in subset), "sentence_occurrences": sum(f["sentence_occurrences"] for f in subset), "unique_sentences": unique, "constructions": by_class})
    totals = db.execute("SELECT SUM(n),COUNT(DISTINCT text) FROM occurrences").fetchone()
    partitions = {}
    for field in ["variant", "world", "split"]:
        partitions[field] = {}
        for value in sorted({f[field] for f in files}):
            subset = [f for f in files if f[field] == value]
            names = [f["path"] for f in subset]
            where = "file IN (" + ",".join("?" for _ in names) + ")"
            unique = db.execute(f"SELECT COUNT(DISTINCT text) FROM occurrences WHERE {where}", names).fetchone()[0]
            partitions[field][value] = {"files": len(subset), "records": sum(f["records"] for f in subset), "sentence_occurrences": sum(f["sentence_occurrences"] for f in subset), "unique_sentences": unique}
    output = {
        "schema": "proofwriter-surface-inventory-v1",
        "scope": "All local V2020.12.3 JSONL files, including repeated augmented/staged/abductive variants; surface text only.",
        "unit": "One punctuation-delimited sentence inside a source premise text unit or question. The few multi-sentence paraphrases split at [.?!] followed by whitespace; fragments are retained. Original source-unit counts remain per file.",
        "classification": "Exact surface templates for controlled text; ordered lexical-cue grouping for paraphrases, not a semantic parser or proof of correct meaning.",
        "excludes": ["answers/labels", "logical representations", "proof text", "allInferences", "abduction answer facts", "synthetic NatLang paraphrases replaced by presented sentences"],
        "datasets": datasets,
        "files": [{k: v for k, v in f.items() if k not in {"roles", "surface_layers"}} for f in files],
        "records": sum(f["records"] for f in files),
        "sentence_occurrences": totals[0],
        "unique_sentences": totals[1],
        "roles": dict(db.execute("SELECT role,SUM(n) FROM occurrences GROUP BY role")),
        "surface_layers": dict(db.execute("SELECT layer,SUM(n) FROM occurrences GROUP BY layer")),
        "partitions": partitions,
        "existing120sample": {"source": "bench/proofwriter/sample.jsonl", "records": sample_records, "sentence_occurrences": sum(sample_counts.values()), "unique_sentences": len(sample_unique), "constructions": dict(sample_counts)},
        "constructions": sorted(constructions.values(), key=lambda c: (-c["count"], c["id"])),
        "orthogonal_features": feature_counts,
        "exceptions": {**metadata["exceptions"], "multi_sentence_source_units_split": expansions, "remaining_multi_sentence_units": dict(multi_units), "unclassified_unique": constructions["UNCLASSIFIED"]["unique_count"], "unclassified_occurrences": constructions["UNCLASSIFIED"]["count"], "coverage_limit": "Natural-language families are overlapping surface diagnostics assigned by documented precedence. Zero UNCLASSIFIED does not mean zero semantic exceptions or complete construction recovery."},
        "local_audit": {"database": str(args.work / "sentences.sqlite3"), "all_skeletons": str(args.work / "skeletons.jsonl"), "source_manifest": str(args.work / "metadata.json")},
    }
    assert sum(c["count"] for c in output["constructions"]) == totals[0]
    assert sum(c["unique_count"] for c in output["constructions"]) == totals[1]
    assert sum(f["sentence_occurrences"] for f in files) == totals[0]
    args.output.write_text(json.dumps(output, indent=2) + "\n")
    print(json.dumps({"files": len(files), "records": output["records"], "occurrences": totals[0], "unique": totals[1], "constructions": len(constructions), "exceptions": output["exceptions"]}, indent=2))
    db.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("extract")
    p.add_argument("--root", type=Path, required=True)
    p.add_argument("--work", type=Path, required=True)
    p.set_defaults(func=extract)
    p = sub.add_parser("repair-surface")
    p.add_argument("--root", type=Path, required=True)
    p.add_argument("--work", type=Path, required=True)
    p.set_defaults(func=repair_surface)
    p = sub.add_parser("summarize")
    p.add_argument("--work", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    p.set_defaults(func=summarize)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
