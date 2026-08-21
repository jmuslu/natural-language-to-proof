#!/usr/bin/env bash
# Build and test with a bare GHC bindist -- no cabal, no stack.
#
# Stage 1 depends only on `base` and `containers`, both of which ship inside a
# GHC bindist, so `ghc --make` is sufficient. Set GHC_BIN if ghc is not on PATH.
#
#   ./scripts/build.sh            # build + run tests
#   ./scripts/build.sh demo       # build + run the demo
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build"

if [ -n "${GHC_BIN:-}" ]; then
  export PATH="$GHC_BIN:$PATH"
fi

if ! command -v ghc >/dev/null 2>&1; then
  echo "error: ghc not found on PATH." >&2
  echo "       Set GHC_BIN to your bindist's bin directory, e.g.:" >&2
  echo "       export GHC_BIN=\"\$LOCALAPPDATA/ghc/ghc-9.12.4-x86_64-unknown-mingw32/bin\"" >&2
  exit 1
fi

mkdir -p "$BUILD"

# Extra source dirs let the mode branches drop in a Collapse backend and its
# spec without this script changing.
SRC_DIRS="-i$ROOT/src -i$ROOT/test -i$ROOT/app"

echo "== building test suite"
ghc $SRC_DIRS -outputdir "$BUILD/test" -o "$BUILD/spec" -Wall "$ROOT/test/Spec.hs"

if [ "${1:-test}" = "demo" ]; then
  echo "== building demo"
  ghc $SRC_DIRS -outputdir "$BUILD/demo" -o "$BUILD/demo-exe" -Wall "$ROOT/app/Main.hs"
  exec "$BUILD/demo-exe"
fi

echo "== running test suite"
exec "$BUILD/spec"
