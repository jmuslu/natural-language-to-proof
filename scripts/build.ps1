<#
    Typecheck and test with a bare GHC bindist -- no cabal, no stack.

    Stage 1 depends only on `base` and `containers`, both of which ship inside a
    GHC bindist, so plain ghc is sufficient.

        .\scripts\build.ps1              # typecheck with -Wall, then run tests
        .\scripts\build.ps1 demo         # typecheck, then run the demo
        .\scripts\build.ps1 compile      # also produce native binaries (see note)

    The default path runs through `runghc`, GHC's interpreter, and produces no
    new executable. That is deliberate: Windows application-control policies
    (Smart App Control, WDAC, Device Guard) routinely refuse to execute freshly
    built unsigned binaries, which makes a compile-then-run script fail with
    "Permission denied" for reasons that have nothing to do with the code.
    Interpreting sidesteps that without weakening any policy. Use `compile` if
    your machine permits it and you want the much faster runtime.

    Set $env:GHC_BIN if ghc is not already on PATH.
#>
param(
    [ValidateSet('test', 'demo', 'compile')]
    [string]$Target = 'test'
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

# Build artifacts go outside the working tree: if the repo lives under OneDrive,
# in-tree object files get cloud-synced. Override with $env:NL2PROOF_BUILD.
if ($env:NL2PROOF_BUILD) {
    $build = $env:NL2PROOF_BUILD
} else {
    $build = Join-Path $env:TEMP 'nl2proof-build'
}

if ($env:GHC_BIN) {
    $env:PATH = "$($env:GHC_BIN);$($env:PATH)"
}

if (-not (Get-Command ghc -ErrorAction SilentlyContinue)) {
    Write-Error @'
ghc not found on PATH. Set GHC_BIN to your bindist's bin directory, e.g.:

  $env:GHC_BIN = "$env:LOCALAPPDATA\ghc\ghc-9.12.4-x86_64-unknown-mingw32\bin"
'@
}

New-Item -ItemType Directory -Force -Path $build | Out-Null

# Extra source dirs let the mode branches drop in a Collapse backend and its
# spec without this script changing.
$srcDirs = @("-i$root\src", "-i$root\test", "-i$root\app")

# Every .hs under src\, so an unreferenced module still gets checked.
$sources = Get-ChildItem -Path "$root\src" -Filter *.hs -Recurse |
    ForEach-Object { $_.FullName }

# Spec.hs and Main.hs both declare `module Main`, so they cannot be checked in
# the same invocation.
Write-Output '== typechecking library (-Wall)'
& ghc @srcDirs -outputdir "$build\check-lib" -fno-code -Wall @sources
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Output '== typechecking test suite (-Wall)'
& ghc @srcDirs -outputdir "$build\check-test" -fno-code -Wall "$root\test\Spec.hs"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Output '== typechecking demo (-Wall)'
& ghc @srcDirs -outputdir "$build\check-demo" -fno-code -Wall "$root\app\Main.hs"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Extension point for the mode branches. A branch adds test\ModeSpec.hs and its
# Collapse backend as *new files only*, so merging main down into it never
# touches a shared file and never conflicts.
$modeSpec = Join-Path $root 'test\ModeSpec.hs'
if (Test-Path $modeSpec) {
    Write-Output '== typechecking mode spec (-Wall)'
    & ghc @srcDirs -outputdir "$build\check-mode" -fno-code -Wall $modeSpec
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

switch ($Target) {
    'compile' {
        Write-Output "== compiling native binaries into $build"
        & ghc @srcDirs -outputdir "$build\test" -o "$build\spec.exe" -Wall "$root\test\Spec.hs"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        & ghc @srcDirs -outputdir "$build\demo" -o "$build\demo.exe" -Wall "$root\app\Main.hs"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Write-Output '== running test suite'
        & "$build\spec.exe"
    }
    'demo' {
        Write-Output '== running demo'
        & runghc @srcDirs "$root\app\Main.hs"
    }
    'test' {
        Write-Output '== running test suite'
        & runghc @srcDirs "$root\test\Spec.hs"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        if (Test-Path $modeSpec) {
            Write-Output ''
            Write-Output '== running mode-specific suite'
            & runghc @srcDirs $modeSpec
        }
    }
}

exit $LASTEXITCODE
