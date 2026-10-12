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

# --- CCGbank parser --------------------------------------------------------
DATA="${CCGBANK_DIR:-$HOME/ccgbank/ccgbank_1_1/data}"
if [ ! -d "$DATA/AUTO" ]; then
  echo "skip explain: no CCGbank at $DATA (set CCGBANK_DIR); CCGbank checks not run"
else
  mapfile -d '' C < <(printf '%s\n' \
    "The cat is not red." \
    "If the cat is red then Bob is happy." \
    "Bob says that the cat is red." \
    "Bob knows that the cat is red." \
    "All red things are big." \
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
fi

if [ "$fails" -gt 0 ]; then
  echo "check-explain: $fails failure(s)" >&2
  exit 1
fi
echo "check-explain: all passed"
