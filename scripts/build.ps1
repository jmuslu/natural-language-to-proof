<#
    Build and test with a bare GHC bindist -- no cabal, no stack.

    Stage 1 depends only on `base` and `containers`, both of which ship inside a
    GHC bindist, so `ghc --make` is sufficient.

        .\scripts\build.ps1           # build + run tests
        .\scripts\build.ps1 demo      # build + run the demo

    Set $env:GHC_BIN if ghc is not already on PATH.
#>
param(
    [ValidateSet('test', 'demo')]
    [string]$Target = 'test'
)

$ErrorActionPreference = 'Stop'

$root  = Split-Path -Parent $PSScriptRoot
$build = Join-Path $root 'build'

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

Write-Output '== building test suite'
& ghc @srcDirs -outputdir "$build\test" -o "$build\spec.exe" -Wall "$root\test\Spec.hs"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($Target -eq 'demo') {
    Write-Output '== building demo'
    & ghc @srcDirs -outputdir "$build\demo" -o "$build\demo.exe" -Wall "$root\app\Main.hs"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & "$build\demo.exe"
    exit $LASTEXITCODE
}

Write-Output '== running test suite'
& "$build\spec.exe"
exit $LASTEXITCODE
