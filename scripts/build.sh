#!/usr/bin/env bash
# Typecheck and test with a bare GHC bindist -- no cabal, no stack.
#
# Stage 1 depends only on `base` and `containers`, both of which ship inside a
# GHC bindist, so plain ghc is sufficient. Set GHC_BIN if ghc is not on PATH.
#
#   ./scripts/build.sh            # typecheck with -Wall, then run the tests
#   ./scripts/build.sh demo       # typecheck, then run the demo
#   ./scripts/build.sh compile    # also produce native binaries (see note)
#
# The default path runs through `runghc`, GHC's interpreter, and produces no new
# executable. That is deliberate: Windows application-control policies (Smart App
# Control, WDAC, Device Guard) routinely refuse to execute freshly built unsigned
# binaries, which makes a compile-then-run script fail with "Permission denied"
# for reasons that have nothing to do with the code. Interpreting sidesteps that
# entirely without weakening any policy. Use `compile` if your machine permits
# it and you want the ~20x faster runtime.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Build artifacts go outside the working tree: if the repo lives under OneDrive,
# in-tree object files get cloud-synced. Override with NL2PROOF_BUILD.
BUILD="${NL2PROOF_BUILD:-/tmp/nl2proof-build}"

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

# GHC appends .exe on Windows and nothing on Unix, so resolve at run time.
# Deliberately not `exec`: the compile target runs two suites in sequence.
run_exe() {
  if [ -x "$1.exe" ]; then
    "$1.exe"
  elif [ -x "$1" ]; then
    "$1"
  else
    echo "error: built no executable at $1" >&2
    exit 1
  fi
}

# Extra source dirs let the mode branches drop in a Collapse backend and its
# spec without this script changing.
SRC_DIRS=(-i"$ROOT/src" -i"$ROOT/test" -i"$ROOT/app")

TARGET="${1:-test}"

# Every .hs under src/, so an unreferenced module still gets checked.
mapfile -t SOURCES < <(find "$ROOT/src" -name '*.hs')

# Every spec is its own `module Main`, so each needs a separate invocation.
# Discovering them by glob means a branch can add test/ModeSpec.hs, or a stage
# can add test/Stage2Spec.hs, without this script changing.
mapfile -t SPECS < <(find "$ROOT/test" -maxdepth 1 -name '*Spec.hs' | sort)

echo "== typechecking library (-Wall)"
ghc "${SRC_DIRS[@]}" -outputdir "$BUILD/check-lib" -fno-code -Wall "${SOURCES[@]}"

for spec in "${SPECS[@]}"; do
  name="$(basename "$spec" .hs)"
  echo "== typechecking $name (-Wall)"
  ghc "${SRC_DIRS[@]}" -outputdir "$BUILD/check-$name" -fno-code -Wall "$spec"
done

echo "== typechecking demo (-Wall)"
ghc "${SRC_DIRS[@]}" -outputdir "$BUILD/check-demo" -fno-code -Wall "$ROOT/app/Main.hs"

case "$TARGET" in
  compile)
    echo "== compiling native binaries into $BUILD"
    # Object dirs are prefixed obj- so they cannot collide with the binary
    # names. On Windows the binary gets .exe appended and a collision is
    # invisible; on Unix `-outputdir X -o X` makes the linker try to write over
    # its own object directory.
    for spec in "${SPECS[@]}"; do
      name="$(basename "$spec" .hs)"
      ghc "${SRC_DIRS[@]}" -outputdir "$BUILD/obj-$name" -o "$BUILD/$name" -Wall "$spec"
    done
    ghc "${SRC_DIRS[@]}" -outputdir "$BUILD/obj-demo" -o "$BUILD/demo" -Wall "$ROOT/app/Main.hs"

    for spec in "${SPECS[@]}"; do
      name="$(basename "$spec" .hs)"
      echo
      echo "== running $name"
      run_exe "$BUILD/$name"
    done
    ;;
  demo)
    echo "== running demo"
    exec runghc "${SRC_DIRS[@]}" "$ROOT/app/Main.hs"
    ;;
  test)
    for spec in "${SPECS[@]}"; do
      name="$(basename "$spec" .hs)"
      echo
      echo "== running $name"
      runghc "${SRC_DIRS[@]}" "$spec"
    done
    ;;
  *)
    echo "usage: $0 [test|demo|compile]" >&2
    exit 2
    ;;
esac
