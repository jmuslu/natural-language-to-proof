#!/usr/bin/env bash
# Smoke test for nl2proof-explain: runs the CLAIMS stage on a few sentences and
# checks the claim split. Only top-level main-box conditions are asserted, so
# red(cat) must never be asserted by a negation, a conditional, a report or a
# factive report (for "knows" it is presupposed and reported, not asserted).
#
# The CCGbank part needs the licensed corpus ($CCGBANK_DIR, else
# ~/ccgbank/ccgbank_1_1/data) and is skipped without it; it loads the lexicon
# once (about a minute and a half). The --hand part needs no data.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
cabal build -v0 nl2proof-explain
BIN="$(cabal list-bin nl2proof-explain)"

fails=0
ok()   { echo "ok   explain: $1"; }
fail() { echo "FAIL explain: $1" >&2; fails=$((fails + 1)); }

# group BLOCK NAME: the lines of one claim group (Asserted, Reported, ...).
group() {
  printf '%s\n' "$1" | awk -v g="  $2" '
    index($0, g) == 1 && $0 ~ /:/ { on = 1; next }
    on && /^  [A-Z]/ { on = 0 }
    on && /^    / && $0 !~ /\(none\)/ { sub(/^    /, ""); print }'
}

# check LABEL BLOCK: run assertions given as remaining "kind:group:regex" args.
#   has:G:RE   some line of group G matches RE
#   not:G:RE   no line of group G matches RE
check() {
  local label="$1" block="$2"; shift 2
  local spec kind g re lines good=1
  if ! printf '%s\n' "$block" | grep -q "5. CLAIMS"; then
    fail "$label: no CLAIMS section"; printf '%s\n' "$block" >&2; return
  fi
  for spec in "$@"; do
    kind="${spec%%:*}"; spec="${spec#*:}"; g="${spec%%:*}"; re="${spec#*:}"
    lines="$(group "$block" "$g")"
    case "$kind" in
      has) printf '%s\n' "$lines" | grep -Eq -- "$re" || { fail "$label: $g has no line matching /$re/"; good=0; } ;;
      not) if printf '%s\n' "$lines" | grep -Eq -- "$re"; then fail "$label: $g has a line matching /$re/"; good=0; fi ;;
    esac
  done
  if [ "$good" = 1 ]; then ok "$label"; else printf '%s\n' "$block" >&2; fi
}

# run FLAGS... : feed stdin lines to the REPL, print one block per input,
# separated by NUL.
run_blocks() {
  "$BIN" --stage=claims "$@" 2>/dev/null | awk '
    /^explain> / { if (n++) printf "%c", 0; sub(/^explain> /, "") } { print }'
}

# --- hand lexicon (no data needed) -----------------------------------------
mapfile -d '' H < <(printf '%s\n' \
  "Mary does not smile." \
  "John says that Mary smiles." \
  "John knows that Mary smiles." \
  ":q" | run_blocks --hand)
check "hand: negation"  "${H[0]:-}" 'has:Asserted:^~\[' 'not:Asserted:^smile\(' 'has:Embedded:^smile\(mary\)$'
check "hand: says"      "${H[1]:-}" 'has:Asserted:^say\(john' 'not:Asserted:^smile\(' 'has:Reported:^smile\(mary\) .*say\(john\)' 'not:Presupposed:smile'
check "hand: knows"     "${H[2]:-}" 'has:Asserted:^know\(john' 'not:Asserted:^smile\(' 'has:Presupposed:^smile\(mary\)$'

# --- section 7: support graph ----------------------------------------------
# want LABEL BLOCK [+|-]FIXED...: +S the block contains the fixed string S,
# -S it does not.
want() {
  local label="$1" block="$2" spec good=1; shift 2
  for spec in "$@"; do
    case "$spec" in
      +*) printf '%s\n' "$block" | grep -Fq -- "${spec#+}" || { fail "$label: missing '${spec#+}'"; good=0; } ;;
      -*) if printf '%s\n' "$block" | grep -Fq -- "${spec#-}"; then fail "$label: unexpected '${spec#-}'"; good=0; fi ;;
    esac
  done
  if [ "$good" = 1 ]; then ok "$label"; else printf '%s\n' "$block" >&2; fi
}
# node LINE-PREFIX BLOCK: the header line of a node and its detail lines.
nodeblk() {
  printf '%s\n' "$2" | awk -v p="$1" '
    index($0, p) { on = 1; print; next }
    on && /^          / { print; next }
    { on = 0 }'
}
before() { printf '%s\n' "$1" | sed '/-- after withdrawing/,$d'; }
after()  { printf '%s\n' "$1" | sed -n '/-- after withdrawing/,$p'; }

# Hand lexicon, real CLI: hearsay never grounds; withdrawal keeps independent
# support; the REPL commands reach the same code.
G1="$("$BIN" --hand --stage=graph --oracle=confirm-asserted "John says that Mary smiles." 2>&1)"
want "hand graph: reported content is never grounded" "$(nodeblk "smile(mary)   [" "$G1")" \
  "+smile(mary)   [WEAK]" "+reported, source chain say(john)" "+{s1, speaker:john}" "-GROUNDED"
want "hand graph: the asserted report itself is confirmable" "$G1" "+say(john, [ | smile(mary)])   [GROUNDED]"
G2="$("$BIN" --hand --stage=graph --retract=s1 "Mary smiles. John walks. Mary smiles." 2>&1)"
want "hand graph: independent support survives --retract=s1" "$(after "$G2")" \
  "+smile(mary)   [WEAK]  <- SURVIVED (independent support)" "+walk(john)   [WEAK]" "+support   {s3}"
want "hand graph: no oracle grounds nothing" "$G2" "+oracle: none" "-[GROUNDED]"
G3="$(printf '%s\n' ":stage=graph" ":oracle confirm-asserted" ":retract 1" "Mary smiles. John walks." ":q" | "$BIN" --hand 2>&1)"
want "hand graph: REPL :oracle and :retract" "$G3" "+oracle confirm-asserted" "+retract: s1" \
  "+smile(mary)   [UNSUPPORTED]  <- LOST SUPPORT" "+walk(john)   [GROUNDED]"
G4="$("$BIN" --hand --stage=graph "Mary smiles. Zorg blargs." 2>&1)" || fail "hand graph: unparsed sentence exits non-zero"
want "hand graph: an unparsed sentence leaves a partial graph" "$G4" \
  "+UNPARSED" "+conclusions below are partial" "+smile(mary)   [WEAK]"

# Invalid flag combinations exit before any corpus load.
for args in "--hand --nominal-policy=known-only" "--nominal-policy=context-unknown --hand" \
            "--nominal-policy=bogus" "--nominal-policy=known-only --nominal-policy=known-only" \
            "--oracle=maybe" "--oracle=none --oracle=none" "--retract=x" "--retract=s0" \
            "--retract=s1 --retract=1" "--stage=nope"; do
  # shellcheck disable=SC2086
  if out="$(CCGBANK_DIR=/nonexistent "$BIN" $args "Mary smiles." 2>&1)" || printf '%s' "$out" | grep -q "loading CCGbank"; then
    fail "rejects '$args' before loading"
  else ok "rejects '$args' before loading"; fi
done

# Miniature hand-tagged CCGbank model (no corpus): the real explain function
# and option parser through GHCi, on the CCGbank code path with conditionals.
MINI="$(cabal repl -v0 nl2proof-explain 2>&1 <<'GHCI'
:set prompt ""
:set prompt-cont ""
:module + *Main NL2Proof.Pipeline NL2Proof.Syntax.CCGSemParse NL2Proof.Syntax.CCGSupertag NL2Proof.Syntax.CCGBank NL2Proof.Syntax.CCGParse
import qualified Data.Set
let cc = either error id . parseCCGCat
let obs = [("The","NP[nb]/N","DT"),("the","NP[nb]/N","DT"),("cat","N","NN"),("Bob","NP","NNP"),("is","(S[dcl]\\NP)/(S[adj]\\NP)","VBZ"),("red","S[adj]\\NP","JJ"),("happy","S[adj]\\NP","JJ"),("If","(S/S)/S[dcl]","IN"),("then","S/S","RB"),("says","(S[dcl]\\NP)/S[em]","VBZ"),("that","S[em]/S[dcl]","IN"),(".",".",".")]
let model = (defaultSemModel (buildTagModel [(w,cc c) | (w,c,_) <- obs]) (buildPOSModel [(w,p) | (w,_,p) <- obs]) (Rules [] []) Data.Set.empty) { smAlpha = 0, smSeenRules = False }
let out args txt = either ("REJECTED " ++) (\o -> explain (CCGBankParser (configureModel o model)) o txt) (parseOpts args)
let block label args txt = putStr ("@@@ " ++ label ++ "\n" ++ out args txt)
let rule = "The cat is red. If the cat is red then Bob is happy."
block "a-none" ["--stage=graph"] rule
block "a-oracle" ["--stage=graph", "--oracle=confirm-asserted"] rule
block "b-retract" ["--stage=graph", "--retract=s1"] rule
block "b-retract-oracle" ["--stage=graph", "--oracle=confirm-asserted", "--retract=s1"] rule
block "c-report" ["--stage=graph", "--oracle=confirm-asserted"] "Bob says that the cat is red."
block "e-independent" ["--stage=graph", "--oracle=confirm-asserted", "--retract=s2"] "If the cat is red then Bob is happy. Bob is happy. The cat is red."
let policy xs = either (const Nothing) (Just . oNominalPolicy) (parseOpts xs)
let rejected xs = either (const True) (const False) (parseOpts xs)
let texts = ["The cat is red.", rule, "Bob says that the cat is red.", "If the cat is red then Bob is happy. Bob is happy."]
putStrLn "@@@ d-nominal"
print (policy [] == Just Nothing, policy ["--nominal-policy=known-only"] == Just (Just KnownNounsOnly), policy ["--nominal-policy=context-unknown"] == Just (Just ContextUnknownNouns))
print (all rejected [["--nominal-policy="], ["--nominal-policy=x"], ["--hand", "--nominal-policy=known-only"], ["--nominal-policy=known-only", "--nominal-policy=context-unknown"]])
print (map (\xs -> either (const Nothing) (\o -> Just (smNominalPolicy (configureModel o model))) (parseOpts xs)) [[], ["--nominal-policy=known-only"], ["--nominal-policy=context-unknown"]] == [Just KnownNounsOnly, Just KnownNounsOnly, Just ContextUnknownNouns])
print (all (\t -> out [] t == out ["--nominal-policy=known-only"] t) texts)
print (all (\t -> not ("EXECUTION POLICY" `Data.List.isInfixOf` out [] t)) texts, "nominal-policy: context-unknown" `Data.List.isInfixOf` out ["--nominal-policy=context-unknown"] rule)
:quit
GHCI
)"
mini() { printf '%s\n' "$MINI" | awk -v l="@@@ $1" '$0 == l { on = 1; next } /^@@@ / { on = 0 } on'; }
want "mini graph (a): happy(Bob) derived from {s1,s2}, weak with no oracle" "$(nodeblk "happy(Bob)   [" "$(mini a-none)")" \
  "+n2  happy(Bob)   [WEAK]" "+from      n1 (rule) + n0" "+support   {s1, s2}"
want "mini graph (a): grounded with --oracle=confirm-asserted" "$(nodeblk "happy(Bob)   [" "$(mini a-oracle)")" \
  "+happy(Bob)   [GROUNDED]" "+support   {s1, s2}" "+{n0:oracle@s1, n1:oracle@s2}"
want "mini graph (a): Fusion agrees with the graph" "$(mini a-oracle)" "+happy(Bob)   entailed" "-NOTE: Fusion and the graph disagree"
want "mini graph (b): --retract=s1 removes happy(Bob)'s support" "$(after "$(mini b-retract)")" \
  "+lost all support:               n0 red(cat), n2 happy(Bob)" "+happy(Bob)   [UNSUPPORTED]  <- LOST SUPPORT" \
  "+[ | red(cat)] => [ | happy(Bob)]   [WEAK]"
want "mini graph (b): with the oracle too" "$(after "$(mini b-retract-oracle)")" \
  "+happy(Bob)   [UNSUPPORTED]  <- LOST SUPPORT" "-happy(Bob)   entailed" "-NOTE: Fusion"
want "mini graph (c): a report never grounds red(cat), even with confirm-asserted" "$(mini c-report)" \
  "+red(cat)   [WEAK]" "-red(cat)   [GROUNDED]" "+{s1, speaker:Bob}" "+say(Bob, [ | red(cat)])   [GROUNDED]" "-red(cat)   confirmed"
want "mini graph: independent derivation survives withdrawal of the direct assertion" "$(after "$(mini e-independent)")" \
  "+happy(Bob)   [GROUNDED]  <- SURVIVED (independent support)" "+support   {s1, s3}"
want "mini (d): --nominal-policy parses, configures, default = known-only output" "$(mini d-nominal)" \
  "+(True,True,True)" "-False" "-rror"
[ "$(mini d-nominal | grep -c True)" = 5 ] || fail "mini (d): expected 5 result lines"

# --- CCGbank parser --------------------------------------------------------
DATA="${CCGBANK_DIR:-$HOME/ccgbank/ccgbank_1_1/data}"
if [ ! -d "$DATA/AUTO" ]; then
  echo "skip explain: no CCGbank at $DATA (set CCGBANK_DIR); CCGbank checks not run"
else
  # Byte-identity of the default against --nominal-policy=known-only, loaded
  # concurrently with the claim checks below (two loads, one wall-clock wait).
  KO_TEXTS=("The cat is red. If the cat is red then Bob is happy." "Bob says that the cat is not red." "All red things are big.")
  KO_DIR="$(mktemp -d)"; trap 'rm -rf "$KO_DIR"' EXIT
  printf '%s\n' "${KO_TEXTS[@]}" ":q" > "$KO_DIR/in"
  "$BIN" --nominal-policy=known-only < "$KO_DIR/in" > "$KO_DIR/known-only" 2>/dev/null &
  KO_PID=$!
  "$BIN" < "$KO_DIR/in" > "$KO_DIR/default" 2>/dev/null &
  DF_PID=$!
  mapfile -d '' C < <(printf '%s\n' \
    "The cat is not red." \
    "If the cat is red then Bob is happy." \
    "Bob says that the cat is red." \
    "Bob knows that the cat is red." \
    "All red things are big." \
    ":stage=graph" \
    "The cat is red. If the cat is red then Bob is happy." \
    ":oracle confirm-asserted" \
    "The cat is red. If the cat is red then Bob is happy." \
    "Bob says that the cat is red." \
    ":retract 1" \
    "The cat is red. If the cat is red then Bob is happy." \
    ":q" | run_blocks)
  check "ccg: The cat is not red." "${C[0]:-}" \
    'has:Asserted:^~\[ \| red\(cat\)\]$' 'not:Asserted:^red\(' 'has:Embedded:^red\(cat\)$' 'not:Reported:.' 'not:Presupposed:.'
  check "ccg: If the cat is red then Bob is happy." "${C[1]:-}" \
    'has:Asserted:red\(cat\).*=>.*happy\(Bob\)' 'not:Asserted:^red\(' 'not:Asserted:^happy\(' 'has:Embedded:^red\(cat\)$'
  check "ccg: Bob says that the cat is red." "${C[2]:-}" \
    'has:Asserted:^say\(Bob, ' 'not:Asserted:^red\(' 'has:Reported:^red\(cat\) .*source chain: say\(Bob\)$' 'not:Presupposed:.'
  check "ccg: Bob knows that the cat is red." "${C[3]:-}" \
    'has:Asserted:^know\(Bob, ' 'not:Asserted:^red\(' 'has:Presupposed:^red\(cat\)$'
  check "ccg: All red things are big." "${C[4]:-}" \
    'has:Asserted:red\(r0\).*=>.*big\(r0\)' 'not:Asserted:^red\(' 'not:Asserted:^big\(' 'not:Reported:.'
  # C[5], C[7], C[10] are the replies to :stage, :oracle and :retract.
  want "ccg graph (a): happy(Bob) derived from {s1,s2}, weak with no oracle" "$(nodeblk "happy(Bob)   [" "${C[6]:-}")" \
    "+happy(Bob)   [WEAK]" "+support   {s1, s2}"
  want "ccg graph (a): grounded with --oracle=confirm-asserted" "$(nodeblk "happy(Bob)   [" "${C[8]:-}")" \
    "+happy(Bob)   [GROUNDED]" "+support   {s1, s2}"
  want "ccg graph (c): a report never grounds red(cat)" "${C[9]:-}" "+red(cat)   [WEAK]" "-red(cat)   [GROUNDED]"
  want "ccg graph (b): --retract=s1 removes happy(Bob)'s support" "$(after "${C[11]:-}")" \
    "+happy(Bob)   [UNSUPPORTED]  <- LOST SUPPORT"
  wait "$KO_PID" "$DF_PID" || true
  if [ -s "$KO_DIR/default" ] && cmp -s "$KO_DIR/default" "$KO_DIR/known-only"; then
    ok "ccg (d): default output is byte-identical to --nominal-policy=known-only"
  else
    fail "ccg (d): default output differs from --nominal-policy=known-only"
    diff "$KO_DIR/default" "$KO_DIR/known-only" | head -20 >&2 || true
  fi
fi

if [ "$fails" -gt 0 ]; then
  echo "check-explain: $fails failure(s)" >&2
  exit 1
fi
echo "check-explain: all passed"
