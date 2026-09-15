#!/usr/bin/env bash
# Negative compilation checks: exported accessors must not permit token mutation.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="${NL2PROOF_BUILD:-/tmp/nl2proof-build}/oracle-boundary"
mkdir -p "$BUILD"

# Establish a valid consumer first, so a missing GHC/package/import cannot pass
# a negative check merely by preventing compilation.
ghc -fno-code -i"$ROOT/src" -outputdir "$BUILD/positive" \
  "$ROOT/test/compile-pass/OracleAccessors.hs" > "$BUILD/positive.log" 2>&1

for name in ConfirmedClaimUpdate ConfirmedOracleUpdate ConfirmedConstructor FusedConstructor FusedClaimUpdate FusedOracleUpdate; do
  log="$BUILD/$name.log"
  if ghc -fno-code -i"$ROOT/src" -outputdir "$BUILD/$name" \
    "$ROOT/test/compile-fail/$name.hs" > "$log" 2>&1; then
    echo "FAIL oracle boundary: $name unexpectedly compiled" >&2
    exit 1
  fi
  case "$name" in
    *Constructor) expected="Data constructor not in scope|Illegal term-level use of the type constructor" ;;
    *) expected="not a record selector" ;;
  esac
  if ! grep -Eq "$expected" "$log"; then
    echo "FAIL oracle boundary: $name failed for an unexpected reason" >&2
    cat "$log" >&2
    exit 1
  fi
  echo "ok   oracle boundary: $name rejected"
done
