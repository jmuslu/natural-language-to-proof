#!/usr/bin/env bash
# Negative compilation checks: exported accessors must not permit token
# mutation, and a reported (attributed) claim must not be forgeable, launderable
# or confirmable as if it were an asserted claim, and a condition from under a
# negation, conditional or disjunction must not be confirmable directly.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="${NL2PROOF_BUILD:-/tmp/nl2proof-build}/oracle-boundary"
mkdir -p "$BUILD"

# Establish valid consumers first, so a missing GHC/package/import cannot pass
# a negative check merely by preventing compilation.
for pass in OracleAccessors ReportedAccessors; do
  ghc -fno-code -i"$ROOT/src" -outputdir "$BUILD/positive-$pass" \
    "$ROOT/test/compile-pass/$pass.hs" > "$BUILD/positive-$pass.log" 2>&1
done

for name in ConfirmedClaimUpdate ConfirmedOracleUpdate ConfirmedConstructor FusedConstructor FusedClaimUpdate FusedOracleUpdate ReportedConstructor ReportedChainUpdate ReportedConfirm PresupposedConfirm EmbeddedConfirm ClaimKindConstructor; do
  log="$BUILD/$name.log"
  if ghc -fno-code -i"$ROOT/src" -outputdir "$BUILD/$name" \
    "$ROOT/test/compile-fail/$name.hs" > "$log" 2>&1; then
    echo "FAIL oracle boundary: $name unexpectedly compiled" >&2
    exit 1
  fi
  case "$name" in
    *Constructor) expected="Data constructor not in scope|Illegal term-level use of the type constructor" ;;
    ReportedConfirm) expected="A reported claim cannot be confirmed" ;;
    PresupposedConfirm) expected="A presupposed claim cannot be confirmed" ;;
    EmbeddedConfirm) expected="An embedded claim cannot be confirmed" ;;
    *) expected="not a record selector" ;;
  esac
  # Messages span lines; match against the log with newlines folded.
  if ! tr "\n" " " < "$log" | grep -Eq "$expected"; then
    echo "FAIL oracle boundary: $name failed for an unexpected reason" >&2
    cat "$log" >&2
    exit 1
  fi
  echo "ok   oracle boundary: $name rejected"
done
