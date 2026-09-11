param([Parameter(Mandatory)][string]$Snapshot,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$d3Worker=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$d3Out=[IO.Path]::GetFullPath($Output)
if (-not $d3Out.StartsWith((Join-Path $d3Worker 'build/art07/d3')+[IO.Path]::DirectorySeparatorChar)) { throw 'Output must remain in the D3 build tree.' }
if (Test-Path -LiteralPath $d3Out) { throw 'Use fresh sim output.' }
New-Item -ItemType Directory $d3Out | Out-Null
$d3Compiler=Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/g++.exe'
$d3PriorPath=$env:PATH
try {
    $env:PATH=(Split-Path $d3Compiler)+';'+$env:PATH
    $d3Sources=@((Join-Path $Snapshot 'tests/sim/test_main.cpp'))+@(Get-ChildItem -LiteralPath (Join-Path $Snapshot 'sim/src') -Filter '*.cpp' | ForEach-Object FullName)
    & $d3Compiler -std=c++17 -Wall -Wextra -Werror -O1 -I (Join-Path $Snapshot 'sim/include') @d3Sources -o "$d3Out/sim_tests.exe" *> "$d3Out/compile.log"
    if ($LASTEXITCODE -ne 0) { throw 'Current sim compilation failed.' }
    & "$d3Out/sim_tests.exe" (Join-Path $Snapshot 'data/tuning') *> "$d3Out/tests.log"
    if ($LASTEXITCODE -ne 0) { throw 'Current sim tests failed.' }
    Get-Content "$d3Out/tests.log" -Tail 4
} finally { $env:PATH=$d3PriorPath }
